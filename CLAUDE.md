# hdhr_VCR Project Guide

Smart VCR for HDHomeRun devices. Records TV shows on macOS with guide-based, zero-setup scheduling.

---

## Core Architecture

**Files:**
- `hdhr_VCR.applescript` (190KB) - Main app with UI and recording logic (51 handlers)
- `hdhr_VCR_lib.applescript` (80KB) - Shared library utilities
- Config: `~/Documents/hdhr_VCR-{hostname}.json` (shows stored as JSON)
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

**Flow from Guide (most common):**
1. Click "Add" in main dialog
2. **Select channel** (shows available channels/tuners)
3. **Select show from guide grid** (auto-populated with guide data)
4. **Confirm Single/Series** (shows title, synopsis, times from guide)
   - If Series: Select type (DateTime / SeriesID(Channel) / SeriesID(All))
5. **Prompt for days** (if DateTime or Single only; auto-set to all days for SeriesID modes)
6. **Prompt for transcode settings** (if tuner supports it)
7. **Choose folder**

**Result after guide selection:**
- Title, time, length, show_next, show_end: **auto-filled from guide**
- SeriesID, logo, show_url: **auto-filled from guide**
- Days: **user-selected (DateTime/Single) or auto-set (SeriesID)**
- Channel: **user-selected or guide-detected**

**Flow for Manual Add (rare):**
1. Click "Add" → Select channel → Click "Manual Add" button
2. **Enter title**, click "Single" or "Series"
3. If **Single**: Enter time, length, day, transcode, folder
4. If **DateTime Series**: Enter time, length, days, transcode, folder
5. SeriesID modes not available in manual add; use guide selection instead

**Key Difference from Edit:**
- Adding always shows guide data first (channel → guide grid → series type decision)
- Editing works on existing show record; may require re-prompting based on state changes

### Editing a Show

- Show title dialog always appears first
- User can switch Series/Single via Series Type dialog
- If user changes Series/Single status, `validate_show_info` recalculates state and resets fields accordingly
- **For SeriesID(Channel):** Only prompts for channel if missing/invalid
- **For SeriesID(All):** Skips channel prompt entirely; days auto-set to all 7
- **For DateTime/Single:** Prompts for days, time, length (based on should_edit flag and state)
- **State transitions trigger re-prompts:** Changing from DateTime → SeriesID(Channel) skips time/length; Changing SeriesID → DateTime re-prompts for all fields
- Folder selection always prompted if missing or when explicitly editing

---

## Recording Lifecycle

> **📖 See:** [ADVANCED_PROCESSES.md](docs/ADVANCED_PROCESSES.md#recording-lifecycle) for phase details.

**Pre-Recording (idle loop checks):**
- Check if show_next <= now → Show is due
  - If show_end > now: **Start recording** (line 418: `record_start`)
  - If show_end <= now: Show has already passed; handle post-recording
- Check if (show_next - now) <= 35 minutes → Send "Up Next" notification (line 476)

**Recording Phase:**
- Verify tuner available (tuner_status check, line 415)
- Verify disk < 93% full
- Build curl command with headers: show_id, show_end, appname
- Wrap in `caffeinate -i` to prevent sleep
- Log recording path and process ID

**Progress Monitoring:**
- Every idle cycle, verify process still running via PID
- Update guide data every 5 minutes at :00/:30 mark (when guide_refresh is due)
- Monitor for orphaned curl processes that exceed show_end time

**Post-Recording:**
- When show_end <= now and show_recording=true
- Verify file created and non-empty
- For DateTime Series: Calculate show_next via `nextday()` (line 393)
- For Single: Set show_active=false (line 407)
- For SeriesID: Queue `seriesScanAdd()` to find next episode (line 397)

---

## SeriesID Episode Matching

> **📖 See:** [ADVANCED_PROCESSES.md](docs/ADVANCED_PROCESSES.md#seriesid-episode-matching) for detailed matching process.

**SeriesID Acquisition (during Add/Edit):**
- When user adds a show from guide: extract `seriesID` from guide entry (line 2247)
- Store in `show_seriesid` field (e.g., "C472160EN1BDK")
- This enables automatic episode matching in future guide scans

**Episode Discovery (seriesScanRun):**
- Called at startup (line 313) and after recording completes (line 397)
- Scans current guide for entries matching `show_seriesid`
- Filter by recording rules (lines 128-131):
  - **DateTime**: Only match episodes on selected `show_air_date` days
  - **SeriesID(Channel)**: Only match episodes on selected `show_channel`
  - **SeriesID(All)**: Match any episode, any channel, any day
- Queue matching episodes via `seriesScanAdd()` for future recording

**Next Episode Calculation (seriesScanNext):**
- Called after recording completes (line 521) or when no episodes found (line 396)
- Searches guide for next matching episode
- Calculates `show_next` based on first future match
- If no upcoming episodes: Set `show_next = current date + 4 hours` for retry (line 396)

**⚠️ CRITICAL: Epoch Format - UTC Throughout**

The HDHomeRun guide API returns times as **real UTC epochs** (Unix timestamp, seconds since Jan 1 1970 UTC):
- Example: Show scheduled 6:00 PM CDT (UTC-5) → API returns epoch 1777762800 (which is 11:00 PM UTC)
- Config stores all times as epoch integers (not date strings) for **timezone portability**
- Conversion functions:
  - `epoch2datetime()`: UTC epoch → AppleScript local date (handles timezone automatically)
  - `datetime2epoch()`: AppleScript local date → UTC epoch (handles timezone automatically)
- Both functions work correctly without manual timezone adjustments (verified on en_US and en_GB)

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

## Prompt Filtering Logic (validate_show_info handler)

**How prompts are determined by show state:**

1. **Show title + Series/Single decision** (always shown on edit)
2. **If user clicks "Series":** Show "What kind of series?" dialog (line 1413)
   - Sets flags: `show_use_seriesid`, `show_use_seriesid_all`
   - Determines `should_edit` flag based on type (line 1420-1430)
3. **If user clicks "Single":** Reset all series flags, set `should_edit=true`
4. **Calculate show_state** based on flags (lines 1444-1454):
   ```
   if is_series: 
     if use_seriesid_all: state = "SeriesID(All)"
     else if use_seriesid: state = "SeriesID(Channel)"  
     else: state = "DateTime"
   else: state = "Single"
   ```
5. **Filter prompts by state** (lines 1457-1530):
   - **Days:** Prompted if DateTime/Single (line 1462); auto-set Full_week for SeriesID (line 1460)
   - **Channel:** Prompted if NOT SeriesID(All) and missing/invalid (line 1485)
   - **Time:** Prompted only if DateTime/Single (line 1511)
   - **Length:** Prompted only if DateTime/Single (line 1526)
   - **Folder:** Always prompted if missing or when should_edit=true (line 1533)

---

## Config File

**Location:** `~/Documents/hdhr_VCR-{hostname}.json`

**Structure:**
```json
{
  "config": {
    "Notify_recording": 15.5,      // Minutes before recording starts
    "Notify_upnext": 35,           // Minutes before show airs
    "GuideHours": 24,              // How far ahead to fetch guide
    "Config_version": "1"          // Internal version tracking
  },
  "the_shows": [
    {
      "show_id": "unique-uuid",
      "show_title": "Show Name S01E01",
      "show_is_series": true,
      "show_use_seriesid": false,
      "show_use_seriesid_all": false,
      "show_air_date": ["Monday", "Wednesday"],
      "show_channel": "5.4",
      "show_time": 20.5,            // 0-24 decimal (UTC)
      "show_length": 60,            // minutes
      "show_next": "1777953798",    // Unix epoch (UTC) — string format
      "show_end": "1776776580",     // Unix epoch (UTC) — string format
      "show_active": true,
      "hdhr_record": "105404BE",    // Device ID
      "show_url": "http://...",
      "show_seriesid": "C183890ENY0BD", // SeriesID for auto-matching
      "show_fail_count": 0,
      "show_fail_reason": "",
      "show_logo_url": "https://...",   // Show artwork URL
      "show_transcode": "none",         // Transcoding profile
      "show_tags": "Comedy",            // Genre/category from guide
      "show_recording": false,          // Is actively recording
      "show_last": "1776776580",        // Last recorded epoch
      "notify_upnext_time": "missing value",   // Notification time (string or "missing value")
      "notify_recording_time": "1776815791",    // Notification time (string epoch)
      "show_dir": "Raid6:DVR Tests:",   // Recording folder (Mac alias path)
      "show_temp_dir": "Raid6:DVR Tests:"      // Backup folder reference
    }
  ]
}
```

**Notes:**
- All timestamps (`show_next`, `show_end`, `show_last`, etc.) are **stored as epoch integer strings** for timezone portability
- Notification times use string format or the literal string `"missing value"` (not JSON null)
- `show_dir` uses Mac alias paths (colon-separated, e.g. `"Raid6:DVR Tests:"`) for local reference
- Config is automatically backed up before write (`hdhr_VCR-{hostname}.json.bak`)

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
- `run` - Startup (line 219): HDHomeRun discovery, initial setup, config load
- `idle` - Main loop (line 338, every ~10 sec): checks for due shows, handles recordings, monitors progress
- `main` - UI dialog handler: displays tuner list, add/edit dialogs, guide selection
- `validate_show_info` - Edit/add show flow (line 1317): smart prompts based on show state

**Recording:**
- `record_start` - Initiate curl recording (line 1938): builds curl command, wraps in caffeinate, logs PID
- `update_show` - Verify/update show during recording: checks process, monitors disk, handles timeouts
- `recordingnow_main` - Display recording status in main dialog

**Series Management (mostly in lib):**
- `seriesScanRun` - Entry point for series scanning: checks all SeriesID shows for new episodes
- `seriesScanAdd` - Queue a show for scanning: adds to scan queue for batch processing
- `seriesScan` - Core matching logic: find guide entries matching seriesID
- `seriesScanNext` - Calculate next air date: finds next episode after current time
- `seriesScanUpdate` - Update show record after match found: refresh channel/time from guide

**Utility Handlers (hdhr_VCR_lib.applescript):**
- `checkDiskSpace` - Monitor disk usage: returns percent full, absolute free space
- `HDHRShowSearch` / `HDHRDeviceSearch` - Search config for shows/tuners by ID
- `stringlistflip` - Convert between text and list formats
- `logger` - Structured logging with TRACE/DEBUG/INFO/WARN/ERROR/FATAL levels
- `epoch2datetime` / `datetime2epoch` - Timezone-safe date conversion

---

## Testing & Validation

**Config Validation:**
- All shows load without JSON parse errors
- Verify no invalid state combinations (see SHOW_STATUS.md)
- SeriesID shows should have Full_week_days (all 7 days) in show_air_date
- Epoch values are valid Unix timestamps (positive integers as strings)

**Prompt Testing:**
- Add show from guide: verify channel → guide grid → series type flow
- Add show manually: verify manual prompt sequence
- Edit show and change state: verify re-prompting behavior
- Verify skipped prompts don't appear (e.g., no time prompt for SeriesID)
- Test all 4 mode transitions (Single→DateTime, DateTime→SeriesID, etc.)

**Recording Test:**
- Create test show with future show_next time
- Verify "Up Next" notification appears at show_next - 35 minutes (line 476)
- Verify recording starts when show_next <= now (line 374)
- Verify recording stops when show_end <= now (line 389)
- Check `~/Library/Logs/hdhr_VCR.log` for curl command execution
- Verify show_next recalculated after recording completes (line 521)

**Series Scanning Test:**
- Create SeriesID show with valid seriesid from guide
- Verify seriesScanRun finds upcoming episodes
- Verify episodes queue for recording
- Verify channel auto-updates if episode moves channels

**Code Quality:**
- Run `./scripts/run_time_tests.sh` for date/locale handling (en_US, en_GB)
- Check logs for ERROR/WARN levels before release (log level: DEBUG filtered at release)
- Verify disk space checks work: block recording at >93% full or <10GB free

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

