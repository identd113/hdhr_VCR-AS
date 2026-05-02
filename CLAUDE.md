# hdhr_VCR Project Guide

Smart VCR for HDHomeRun devices. Records TV shows on macOS with guide-based, zero-setup scheduling.

---

## Core Architecture

**Files:**
- `hdhr_VCR.applescript` (184KB) - Main app with UI and recording logic
- `hdhr_VCR_lib.applescript` (66KB) - Shared library utilities
- Config: `~/Documents/hdhr_VCR-{hostname}.json` (25+ shows stored as JSON)
- Logs: `~/Library/Logs/hdhr_VCR.log`

**Languages:** AppleScript, JSON, shell scripts (curl, bash)

**Execution Model:**
- AppleScript app with UI dialogs
- Runs idle loop every ~10 seconds
- Uses curl for HDHomeRun API calls
- `caffeinate` to prevent sleep during recording

---

## The 4-State Show Model (CRITICAL)

> **📖 Authoritative source:** [SHOW_STATUS.md](docs/SHOW_STATUS.md) — Read for state table and validation rules.

Shows are ONE of 4 states, determined by `is_series`, `use_seriesid`, `use_seriesid_all`:

- **Single**: Record 1 episode (user specifies day/time/channel)
- **DateTime**: Record specific days/times on 1 channel (manual schedule)
- **SeriesID(Channel)**: Record all episodes on 1 channel (guide-driven)
- **SeriesID(All)**: Record all episodes on all channels (guide-driven)

**Critical Enforcement in validate_show_info:**
- Series button → Always show series type dialog
- Single button → Reset all series flags
- Filter prompts by state (see Prompt Filtering Logic below)

---

## User Workflows

> **📖 UI/UX Details:** [UI_EXPECTATIONS.md](docs/UI_EXPECTATIONS.md) — Dialog layouts, status icons, cancellation behavior, error states, and complete user interaction flows.

### Adding a Show

**Single Episode:**
1. Choose tuner
2. Enter title, click "Single"
3. Pick day (1 only)
4. Pick channel
5. Enter time (0-24 decimal)
6. Enter length (minutes)
7. Choose folder

**DateTime Series:**
1. Choose tuner
2. Enter title, click "Series" → "DateTime"
3. Pick days (multiple allowed)
4. Pick channel
5. Enter time (0-24 decimal)
6. Enter length (minutes)
7. Choose folder

**SeriesID(Channel):**
1. Choose tuner
2. Enter title, click "Series" → "SeriesID(Channel)"
3. Pick channel (ONLY prompt)
4. [No time/days/length prompts - auto from guide]
5. Choose folder

**SeriesID(All):**
1. Choose tuner
2. Enter title, click "Series" → "SeriesID(All)"
3. [No channel/time/days/length - all auto]
4. Choose folder

### Editing a Show

- Show title dialog always appears
- If user changes Series/Single status, recalculate state and reset fields
- SeriesID shows only ask for channel (if SeriesID(Channel)) on edit
- All other prompts conditional on current state
- Changing SeriesID(Channel) to DateTime must re-prompt for days/time/length
- Changing DateTime to SeriesID(Channel) skips days/time/length prompts

---

## Recording Lifecycle

> **📖 See:** [ADVANCED_PROCESSES.md](docs/ADVANCED_PROCESSES.md#recording-lifecycle) for phase details.

**Pre-Recording (idle loop):**
- Check if show_next <= now + 35 minutes → Send "Up Next" notification
- Check if show_end <= now and show_active=true → Start recording

**Recording Phase:**
- Verify tuner available and disk < 93% full
- Build curl command with headers: show_id, show_end, appname
- Wrap in `caffeinate -i` to prevent sleep
- Log recording path and process ID

**Progress Monitoring:**
- Every idle cycle, verify process running
- Check tuner signal strength > 75%
- Update guide data every 5 minutes at :00/:30 mark

**Post-Recording:**
- Verify file created and non-empty
- For DateTime Series: Calculate show_next
- For Single: Set show_active=false
- For SeriesID: Queue seriesScanNext to find next episode

---

## SeriesID Episode Matching

> **📖 See:** [ADVANCED_PROCESSES.md](docs/ADVANCED_PROCESSES.md#seriesid-episode-matching) for detailed matching process.

**SeriesID Acquisition:**
- When adding SeriesID show, query guide for matching entries
- Extract and store show_seriesid (e.g., "C472160EN1BDK")

**Episode Discovery (seriesScanRun):**
- Every idle cycle, find guide entries with matching seriesid
- Filter by recording rules:
  - DateTime: Only selected days
  - SeriesID(Channel): Only selected channel
  - SeriesID(All): Any channel, any day
- Queue new episodes for recording

**Next Episode Calculation (seriesScanNext):**
- Find next airing of series
- Calculate days until air date (offset)
- Update show_next

**⚠️ CRITICAL: Guide Data Timezone Interpretation**

The HDHomeRun guide API returns episode times as "local time encoded as UTC epoch":
- Example: Show at 1:30 PM CDT (local) → API returns epoch for "1:30 PM UTC" (not the actual UTC time)
- Without correction: would deserialize to 8:30 AM CDT (5+ hours early), causing premature recording
- **Fix:** When extracting `StartTime`/`EndTime` from guide, subtract `time to GMT` before calling `epoch2datetime()`
- All places where guide times are used must apply this correction (seriesScanUpdate, add_show_info, etc.)

---

## Error Handling

> **📖 See:** [ADVANCED_PROCESSES.md](docs/ADVANCED_PROCESSES.md#error-handling--retry-logic) for detailed error flows.

**Recording Failures:**
- Increment show_fail_count
- After 3 failures: Set show_active=false (pause recording)
- User must edit show to reset fail_count and re-activate

**Guide Updates:**
- Retry failed API calls up to 5 times
- Cache guide for 5+ minutes before refresh
- Log all API errors

**Config Validation:**
- On load: Check file exists, valid JSON, required fields
- On save: Backup before write, verify after
- On edit: Validate state consistency before saving

---

## Prompt Filtering (SMART LOGIC)

**Key Implementation (validate_show_info handler):**

1. Track original `show_is_series` status
2. User selects Series/Single button
3. If Series selected: Show series type dialog (DateTime/SeriesID(Channel)/SeriesID(All))
4. Set flags based on user choice
5. Determine show_state:
   ```applescript
   if is_series == true
     if use_seriesid_all == true: state = "SeriesID(All)"
     else if use_seriesid == true: state = "SeriesID(Channel)"
     else: state = "DateTime"
   else
     state = "Single"
   ```
6. Filter prompts by state:
   - Days: if (state != "SeriesID(All)" && state != "SeriesID(Channel)")
   - Channel: if (state != "SeriesID(All)")
   - Time: if (state == "DateTime" || state == "Single")
   - Length: if (state == "DateTime" || state == "Single")

---

## Config File

**Location:** `~/Documents/hdhr_VCR-{hostname}.json`

**Structure:**
```json
{
  "config": {
    "Notify_recording": 15.5,    // Minutes before to alert
    "Notify_upnext": 35,          // Minutes before to alert
    "GuideHours": 4,              // How far ahead to fetch guide
    "Hdhr_setup_folder": "..."    // Default recording folder
  },
  "the_shows": [
    {
      "show_id": "unique-id",
      "show_title": "Show Name",
      "show_is_series": true,
      "show_use_seriesid": false,
      "show_use_seriesid_all": false,
      "show_air_date": ["Monday", "Wednesday"],
      "show_channel": "5.4",
      "show_time": 20,            // 0-24 decimal
      "show_length": 60,          // minutes
      "show_next": "datetime",
      "show_end": "datetime",
      "show_active": true,
      "hdhr_record": "105404BE",  // Device ID
      "show_url": "http://...",
      "show_seriesid": "...",     // For SeriesID modes
      "show_fail_count": 0,
      "show_fail_reason": ""
    }
  ]
}
```

---

## Important Constants & Defaults

- **Idle timer**: 10 seconds (Idle_timer_default)
- **Max disk usage**: 93% (Max_disk_percentage)
- **Notification delays**: 35 min up-next, 15.5 min recording
- **Fail threshold**: 3 failures before pause (Fail_count)
- **API retry limit**: 5 attempts
- **Guide cache**: 5+ minutes before refresh
- **Log size limit**: 1000 lines, scales with show count

---

## Key Handlers

> **📖 See:** [handler.md](docs/handler.md) for complete handler reference with inputs/returns.

**Main Flow:**
- `run` - Startup, discovery, initial setup
- `idle` - Main loop (every ~10 sec): checks, updates, recordings
- `validate_show_info` - Edit/add show flow with smart prompts

**Recording:**
- `record_start` - Initiate recording with curl
- `update_show` - Verify/update show during recording
- `recording_complete` - Finalize recording

**Series Management:**
- `seriesScanRun` - Find upcoming episodes
- `seriesScanNext` - Calculate next air date
- `seriesScanAdd` - Queue episodes

**Library (hdhr_VCR_lib.applescript):**
- `checkDiskSpace` - Monitor disk usage
- `checkfileexists` - Validate paths
- `stringlistflip` - String/list conversion
- `logger` - Logging with levels

---

## Testing & Validation

**Config Validation:**
- Check all 25 shows load without error
- Verify no invalid state combinations (see SHOW_STATUS.md)
- SeriesID shows should have all 7 days

**Prompt Testing:**
- Add/edit show in each state
- Verify correct prompts appear (use WORKFLOWS.md)
- Verify skipped prompts don't appear
- Test state transitions (Single→DateTime, DateTime→SeriesID, etc)

**Recording Test:**
- Create test show in future time
- Verify notification appears at -35 minutes
- Verify recording starts at -15.5 minutes
- Check logs for curl command execution
- Verify show_next recalculated after recording

**Code Quality:**
- Run `/scripts/run_time_tests.sh` for date/locale handling
- Check logs for ERROR/WARN levels before release
- Verify disk space checks work at > 90% full

---

## Documentation

- **SHOW_STATUS.md** - 4-state model reference, valid/invalid combinations
- **WORKFLOWS.md** - User guides for add/edit workflows
- **ADVANCED_PROCESSES.md** - Technical deep dives on SeriesID, recording lifecycle, etc
- **README.md** - Features and quick start

---

## JSONHelper Behaviour (Verified by Round-Trip Test)

JSONHelper is used via `use application "JSON Helper"` (declared at script top alongside `use scripting additions`). Commands `make JSON from` and `read JSON from` are then available without `tell` blocks. Test script: `scripts/jsonhelper_type_test.applescript`.

### Supported types

| AppleScript type | JSON stored as | Loads back as | Notes |
|---|---|---|---|
| `text` | `"string"` | `text` | Empty string `""` also works |
| `integer` (small, e.g. `42`) | `42` | `integer` | |
| `integer` (epoch-scale, e.g. `1745006400`) | `1745006400` | `real` | AppleScript stores large integers internally as `real` / scientific notation (`1.7450064E+9`); JSON preserves the full integer value — arithmetic still works |
| `real` (e.g. `3.14159`, `20.5`) | `3.14159...` | `real` | Minor float precision expansion in JSON (e.g. `3.1415899999...`) — harmless for show-time decimals |
| `integer 0` | `0` | `integer` | |
| `integer` (large negative, e.g. `-1745006400`) | `-1745006400` | `real` | Same scientific notation behaviour as large positive |
| `boolean true` / `false` | `true` / `false` | `boolean` | |
| `text` containing `"missing value"` | `"missing value"` | `text` | The workaround already used for notify times — reliable |
| `missing value` (raw) | `null` | `class` (not `missing value`) | Loads back as an AppleScript class descriptor, not the original type; the string workaround is safer |
| `record` | `{...}` | `record` | Keys are preserved; nested records work correctly |
| `list` of strings | `["a","b"]` | `list` | |
| `list` of integers | `[1,2,3]` | `list` | |
| `list` with mixed types | `["hello",42,true]` | `list` | Elements retain their types |
| `list` of records | `[{...},{...}]` | `list` | Fully supported, including nested records |
| `list` with `missing value` elements | `[1,null,3]` | `list` | `null` elements load as `class` descriptors — handle with care |
| empty `list` (`{}`) | `[]` | `list` | |
| Unicode text + emoji | `"Héllo wörld 📅"` | `text` | JSON stores correctly; emoji may not display in AppleScript log output but value is preserved |

### NOT supported — fail silently (blank the output file, no error thrown)

| AppleScript type | Behaviour | Workaround |
|---|---|---|
| **`date`** | `make JSON from` silently writes an empty file | Convert to epoch integer using `datetime2epoch()` before saving; convert back with `epoch2datetime()` on load |
| **`alias`** (file path) | Same — silently blanks the file | Convert to `POSIX path of alias` (a text string) before saving |
| **`record` containing a `date`** | Same — the date field inside a record also blanks the file | Pre-convert all date fields to epoch integers before building the record passed to `make JSON from` |

**Critical rule:** Any record that contains a `date` anywhere in its structure — even deeply nested — will cause JSONHelper to blank the file. Scan all fields before saving. This was the root cause of the `show_next`/`show_end`/`show_last` locale bug (now fixed — all date fields use epoch integers).

### Date serialization pattern (correct approach)

```applescript
-- Before make JSON from:
set show_next of item i of temp to my datetime2epoch(cm, show_next of item i of temp)

-- After read JSON from:
set show_next of item i of Show_info to epoch2datetime(cm, show_next of item i of Show_info) of LibScript
```

Dates are stored as epoch integers (`datetime2epoch()` before save, `epoch2datetime()` on load). This is locale-independent and works correctly on both en_US and en_GB. The old workaround stored locale-formatted strings (e.g. `"Thursday, April 23, 2026 at 9:30:00 PM"`) which broke on non-US locales — that approach is no longer used.

### File path note

Use `open for access POSIX file path` (not `open for access file path`) for POSIX-style paths (`/Users/...`). The main script uses Mac alias paths which work with plain `file`; POSIX paths require `POSIX file`.

---

## Known Limitations

- English locales supported: en_US and en_GB
- Requires JSONHelper app
- HDHomeRun device must have static IP
- macOS only
- Single tuner per show (no multi-tuner scheduling)

---

## Development Notes

> **📖 See:** [APPLE_SCRIPT_STYLE.md](docs/APPLE_SCRIPT_STYLE.md) for code conventions and [TESTING.md](docs/TESTING.md) for test procedures.

**Error Handling:**
- try/on error blocks throughout
- All API calls have timeout/retry logic
- Config validates on load; doesn't corrupt on errors
- All user-facing errors include actionable messages

**Performance:**
- Idle loop lightweight: ~1 sec per cycle
- Guide caching prevents repeated API calls
- Lazy loading of config for large show lists
- Efficient string/list operations

