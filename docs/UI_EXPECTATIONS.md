# hdhr_VCR UI/UX Expectations

**Complete reference for user-facing dialogs, interactions, status states, and error flows.**

> **Related Docs:** [WORKFLOWS.md](WORKFLOWS.md) — User workflows · [SHOW_STATUS.md](SHOW_STATUS.md) — State reference · [ADVANCED_PROCESSES.md](ADVANCED_PROCESSES.md) — Technical implementation

---

## Date/Time Architecture

**Storage:** All dates are stored as **UTC epoch integers in string format** in the config file
```json
{
  "show_next": "1777762800",
  "show_end": "1777766400",
  "show_last": "1777248000"
}
```
This format is **timezone-portable** — the config works correctly when moved between timezones or when traveling.

**Display:** All dates shown to users in **local time** via logs and UI elements
- Main screen: `"Next: 05/02 6:00 PM"` (local time)
- Edit dialog: `"Next Showing: Thursday, May 2, 2026 6:00 PM CDT"` (local time)
- Logs: `"show_next: Thursday, May 2, 2026 6:00 PM CDT"` (local time)

**Conversion:**
- **Storage → Display:** `epoch2datetime()` converts UTC epoch → local date object → `short_date()` formats for display
- **Display → Storage:** User selects local time → converted to date object → `datetime2epoch()` converts to UTC epoch → stored

---

## Main Screen - Show List

### Layout
```
┌────────────────────────────────────────────┐
│ hdhr_VCR                                   │
├────────────────────────────────────────────┤
│ ☐ Show Title                     [Status]  │
│ ☐ Next: MM/DD HH:MM              [●●●]    │
│ ☐ (Recorded: MM/DD HH:MM)        [!]      │
│                                            │
│ ☐ Another Show S01E05            [RECORD] │
│ ☐ Next: MM/DD HH:MM              [●●●]    │
│                                            │
├────────────────────────────────────────────┤
│ [Add] [Edit] [Remove] [Run] [Settings]   │
└────────────────────────────────────────────┘
```

### Status Icons & Legends

| Icon | Meaning | Color | Condition |
|------|---------|-------|-----------|
| ✓ | Active/Recording | Green | `show_active = true` AND tuner in use |
| ⚠ | Warning | Yellow | Recording failed, retry pending, or paused after 3 failures |
| ✗ | Paused | Gray | `show_active = false` (stopped after too many failures) |
| ● | Signal strength | Green/Red | Tuner signal quality during recording |
| ⓘ | Info | Blue | Recently recorded, guide data gap, or title variation |
| 🔄 | Refreshing | Blue | SeriesID show queued for guide scan |
| ⏱ | Time warning | Orange | Recording starts within 15 minutes |
| 📡 | Device offline | Red | HDHomeRun device not detected |

### Show List Entry Anatomy

```
Title Line:
  [checkbox] Show Title [S##E##] [ICON_STATUS]
  
Subtitle (always visible):
  Next Air:  MM/DD HH:MM  (or "Passed" if show_next < now)
  Type:      Single | DateTime | SeriesID | SeriesID(All)
  
Optional Tertiary (conditional):
  Recorded:  MM/DD HH:MM  (if show_recorded_today = true)
  Last:      MM/DD HH:MM  (if show_last > 0)
```

### Show Title Format Examples

| Type | Format | Example |
|------|--------|---------|
| Single | `Show Name` | `Seinfeld` |
| DateTime | `Show Name` | `60 Minutes` |
| SeriesID | `Show Name S##E##` | `The Late Show S11E105` |
| SeriesID(All) | `Show Name S##E##` | `The Rifleman S02E11` |

**Note:** Title updates automatically when guide discovers new episode. Old title may briefly show during update.

---

## Add Show Workflow

### Step 1: Show Type Selection
```
┌─────────────────────────────────────────────┐
│ What type of show do you want to add?       │
├─────────────────────────────────────────────┤
│ ⊙ Single Episode                            │
│ ○ Series (Multiple Episodes)                │
├─────────────────────────────────────────────┤
│ [Cancel] [OK]                               │
└─────────────────────────────────────────────┘
```

### Step 2: For Series - Sub-type Selection
```
┌─────────────────────────────────────────────┐
│ What kind of series?                        │
├─────────────────────────────────────────────┤
│ ⊙ DateTime (Specific days/times)            │
│ ○ SeriesID (All episodes, one channel)      │
│ ○ SeriesID (All episodes, all channels)     │
├─────────────────────────────────────────────┤
│ [Cancel] [Back] [OK]                        │
└─────────────────────────────────────────────┘
```

### Step 3: Tuner/Device Selection
```
┌─────────────────────────────────────────────┐
│ Select tuner device:                        │
├─────────────────────────────────────────────┤
│ ⊙ HDHomeRun (105404BE)                      │
│ ○ [Other device if multiple tuners]         │
├─────────────────────────────────────────────┤
│ [Cancel] [Back] [OK]                        │
└─────────────────────────────────────────────┘
```

### Step 4: Show Title
```
┌─────────────────────────────────────────────┐
│ Enter show name:                            │
├─────────────────────────────────────────────┤
│ [____________________________]               │
│                                             │
│ Suggestion: [Use Guide] (if from search)   │
├─────────────────────────────────────────────┤
│ [Cancel] [Back] [OK]                        │
└─────────────────────────────────────────────┘
```

### Step 5: Channel Selection (if applicable)
```
┌─────────────────────────────────────────────┐
│ Select channel:                             │
├─────────────────────────────────────────────┤
│ ⊙ 4.1  WCCO-DT (NBC)                        │
│ ○ 5.3  Channel 5.3                          │
│ ○ 11.1 KARE-HD (NBC)                        │
│ ... [scrollable list of 119 channels] ...   │
├─────────────────────────────────────────────┤
│ [Cancel] [Back] [OK]                        │
└─────────────────────────────────────────────┘
```

### Step 6: Schedule Details (DateTime shows only)
```
Select Days:
  ☐ Sunday    ☐ Monday    ☐ Tuesday   ☐ Wednesday
  ☐ Thursday  ☐ Friday    ☐ Saturday

Enter Time (24-hour decimal):
  [__:__] (e.g., 20.5 for 8:30 PM)

Enter Duration:
  [___] minutes
```

### Step 7: Guide Browser (if channel selected)
```
┌─────────────────────────────────────────────┐
│ Browse shows on channel 11.3                │
├─────────────────────────────────────────────┤
│ [Show Logo]  Show Title S##E##              │
│ Start: MM/DD HH:MM  End: MM/DD HH:MM       │
│                                             │
│ [Show Logo]  Show Title S##E##              │
│ Start: MM/DD HH:MM  End: MM/DD HH:MM       │
│                                             │
│ ... 41 more shows on this channel ...       │
├─────────────────────────────────────────────┤
│ [Back] [Select] [Cancel]                    │
└─────────────────────────────────────────────┘
```

**Note:** hdhrGRID browser shows:
- Show logos (cached from guide API)
- Title and episode number
- Start/end times from guide
- Automatically extracts seriesID and show length if selected

### Step 8: Auto-Population (SeriesID shows)
```
After selecting from guide:

(Auto) show name: The FBI Files S03E07 Millionaire Murder
(Auto) show_length: 60 minutes
(Auto) show_next: Friday, May 1, 2026 at 7:00:00 PM
(Auto) show_end: Friday, May 1, 2026 at 8:00:00 PM
(Auto) show_channel: 11.3
(Auto) SeriesID: C505353ENSB1X
```

### Step 9: Folder Selection
```
┌─────────────────────────────────────────────┐
│ Select folder for recordings:               │
├─────────────────────────────────────────────┤
│ [Raid6] [DVR Tests] ▶ [shows...]            │
│                                             │
│ Current: Raid6:DVR Tests:                   │
│ Space: 87% full (7.8 GB free)               │
│                                             │
│ ⚠ Warning: >93% full would prevent recording
├─────────────────────────────────────────────┤
│ [Cancel] [Choose] [Use Last]                │
└─────────────────────────────────────────────┘
```

### Step 10: Show Confirmation
```
┌─────────────────────────────────────────────┐
│ New Show Added                              │
├─────────────────────────────────────────────┤
│ ✓ The FBI Files S03E07 Millionaire Murder   │
│   Type: SeriesID(Channel) on 11.3           │
│   First Air: Friday, May 1, 2026 at 7:00 PM│
│   Duration: 60 minutes                      │
│   Location: Raid6:DVR Tests:                │
│                                             │
│ [Logo] [Channel Icon] [SeriesID Badge]      │
├─────────────────────────────────────────────┤
│ [OK]                                        │
└─────────────────────────────────────────────┘
```

---

## Manual Add Workflow (validate_show_info path)

**When:** User clicks "Add.." button directly, or edits existing show without guide data

**Code Path:** `validate_show_info()` handler (hdhr_VCR.applescript:1307+)

### Step 1: Title & Series Type Dialog
```
┌──────────────────────────────────────────────────┐
│ What is the title of this show, and is it a    │
│ series??                                         │
├──────────────────────────────────────────────────┤
│ Title: [____________________________________]    │
│                                                  │
│ Next Showing: Thursday, May 2, 2026 at 6:00 PM  │
│ SeriesID: [empty for manual add]                 │
├──────────────────────────────────────────────────┤
│  [🏃 Run]  [📺 Series]  [🎬 Single]             │
└──────────────────────────────────────────────────┘
```

**Behavior:**
- **Run button:** Cancel entire workflow, return to main list
- **Single:** Record one episode only → Skip to Step 3
- **Series:** Show type selection (Step 2)

---

### Step 2: Series Type Selection (Series only)
```
┌──────────────────────────────────────────────────┐
│ What kind of series?                            │
├──────────────────────────────────────────────────┤
│  [📅 Date/Time]  [📺 SeriesID(Channel)]  [🌐 SeriesID(All)]
└──────────────────────────────────────────────────┘
```

**Selection → State Flags:**

| Button | is_series | use_seriesid | use_seriesid_all | Result |
|--------|-----------|--------------|------------------|---------|
| Date/Time | true | false | false | DateTime |
| SeriesID(Channel) | true | true | false | SeriesID(Ch) |
| SeriesID(All) | true | true | true | SeriesID(All) |

---

### Step 3: Days Selection (DateTime & Single only)
```
For DateTime Series:
┌──────────────────────────────────────────────────┐
│ Select the days you wish to record              │
│ This is a series, so you can select multiple    │
├──────────────────────────────────────────────────┤
│ ☑ Sunday    ☐ Monday    ☐ Tuesday  ☐ Wednesday │
│ ☐ Thursday  ☐ Friday    ☐ Saturday             │
├──────────────────────────────────────────────────┤
│  [🏃 Run]  [Next..]                             │
└──────────────────────────────────────────────────┘

For Single:
┌──────────────────────────────────────────────────┐
│ Select the day you wish to record               │
│ This is a single, you can only select 1 day     │
├──────────────────────────────────────────────────┤
│ ⊙ Wednesday                                      │
│ ○ Thursday    ○ Friday    ○ Saturday            │
├──────────────────────────────────────────────────┤
│  [🏃 Run]  [Next..]                             │
└──────────────────────────────────────────────────┘
```

**SKIPPED if:** SeriesID(Channel) or SeriesID(All) — auto-set to all 7 days

---

### Step 4: Channel Selection (all except SeriesID(All))
```
┌──────────────────────────────────────────────────┐
│ What channel does this show air on?             │
├──────────────────────────────────────────────────┤
│ ⊙ 4.1   WCCO-DT [NBC]                          │
│ ○ 5.3   Channel 5.3                             │
│ ○ 7.1   KSTW [CBS]                              │
│ ○ 9.2   KSTP [ABC]                              │
│ ○ 11.1  KARE-HD [NBC]                           │
│ ... [119 channels available] ...                 │
├──────────────────────────────────────────────────┤
│  [🏃 Run]  [Next..]                             │
└──────────────────────────────────────────────────┘
```

**SKIPPED if:** SeriesID(All) — uses all channels

---

### Step 5: Time Selection (DateTime & Single only)
```
┌──────────────────────────────────────────────────┐
│ What time does this show air?                  │
│ (0-24, use decimals, ie 9.5 for 9:30)          │
├──────────────────────────────────────────────────┤
│ Time: [20.5_________________]                   │
├──────────────────────────────────────────────────┤
│  [🏃 Run]  [Next..]                             │
└──────────────────────────────────────────────────┘
```

**Validation:**
- Input must be numeric
- Must be 0-24 range
- Decimals allowed (9.5 = 9:30 AM)

**SKIPPED if:** SeriesID(Channel) or SeriesID(All)

---

### Step 6: Duration Selection (DateTime & Single only)
```
┌──────────────────────────────────────────────────┐
│ How long is this show? (minutes)                │
├──────────────────────────────────────────────────┤
│ Duration: [60_________________]                  │
├──────────────────────────────────────────────────┤
│  [🏃 Run]  [Next..]                             │
└──────────────────────────────────────────────────┘
```

**SKIPPED if:** SeriesID(Channel) or SeriesID(All) — populated from guide

---

### Step 7: Folder Selection
```
┌──────────────────────────────────────────────────┐
│ Select shows Directory for [show_title]         │
├──────────────────────────────────────────────────┤
│ 📁 Raid6                                         │
│    📁 DVR Tests                                  │
│       📁 shows...                                │
│                                                  │
│ Current: Raid6:DVR Tests:                        │
│ Space: 78% full (1.3 GB free) — ✓ OK           │
│                                                  │
│ ⚠ Warning: >93% full prevents recording         │
├──────────────────────────────────────────────────┤
│  [🏃 Run]  [Choose]  [Use Last]                 │
└──────────────────────────────────────────────────┘
```

**Validation:**
- Folder must exist and be readable
- Folder must be writable
- Disk usage < 93%

---

## Manual Add Workflow — Prompt Summary by State

| Step | Single | DateTime | SeriesID(Ch) | SeriesID(All) |
|------|--------|----------|--------------|---------------|
| 1. Title & Type | ✓ | ✓ | ✓ | ✓ |
| 2. Series Type | — | ✓ | ✓ | ✓ |
| 3. Days | ✓ (1 only) | ✓ (multi) | ✗ skip | ✗ skip |
| 4. Channel | ✓ | ✓ | ✓ | ✗ skip |
| 5. Time | ✓ | ✓ | ✗ skip | ✗ skip |
| 6. Duration | ✓ | ✓ | ✗ skip | ✗ skip |
| 7. Folder | ✓ | ✓ | ✓ | ✓ |

**Key:** ✓ = Shown, ✗ = Skipped, — = N/A

---

## Cancel & Exit Behavior (Manual Add)

Every dialog provides **"Run" button** to cancel:
- Pressing "Run" or clicking Cancel returns to main show list
- **ALL previously entered data is discarded**
- Show is not added to config
- No confirmation prompt

Example abort sequence:
```
Step 1 (Title) → [Run] → Main list
Step 4 (Channel) → [Run] → Main list (data lost)
```

---

## Edit Show Workflow

### Main Edit Dialog

```
┌─────────────────────────────────────────────┐
│ Edit Show: The FBI Files S03E07             │
├─────────────────────────────────────────────┤
│ Title: [The FBI Files S03E07...]            │
│ Type:  ○ Single  ⊙ DateTime  ○ SeriesID    │
│ Active: ☑ (toggle to pause)                │
│                                             │
│ ── Schedule ──────────────────────────────  │
│ Days: [Sun] [Mon] [Tue] [Wed] [Thu] [Fri]  │
│ Time: [19:00]  Duration: [60] min          │
│ Channel: [11.3 - Crime]                     │
│                                             │
│ ── Paths ──────────────────────────────────  │
│ Folder: [Raid6:DVR Tests]  [Change]         │
│ Transcode: [None] ▼                         │
│                                             │
│ ── Status ────────────────────────────────── │
│ Next Air: Friday, May 1 at 7:00 PM          │
│ Last Recorded: Never                        │
│ Failures: 0 (Max 3 before pause)            │
│ SeriesID: C505353ENSB1X [Copy]              │
│                                             │
├─────────────────────────────────────────────┤
│ [Cancel] [Reset] [Save]                     │
└─────────────────────────────────────────────┘
```

### Disabled Fields by Show Type

| Field | Single | DateTime | SeriesID | SeriesID(All) |
|-------|--------|----------|----------|---------------|
| Days | ✓ | ✓ | ✗ disabled | ✗ disabled |
| Time | ✓ | ✓ | ✗ disabled | ✗ disabled |
| Channel | ✓ | ✓ | ✓ | ✗ disabled |
| SeriesID | ✗ hidden | ✗ hidden | ✓ | ✓ |

---

## Cancellation & Rejection Behavior

### Add Show Workflow — Multi-Step Cancellation

The add workflow is a linear progression with **Back** buttons (except Step 1) and **Cancel** buttons at each stage. Canceling at any step discards ALL previously entered data and returns to the main show list.

```
Add Show Cancellation Map:

Step 1 (Type Selection)
  [Cancel] → Back to main list (no data saved)
  [OK] → Step 2 (for Series) or Step 3 (for Single)

Step 2 (Series Sub-type: DateTime/SeriesID/SeriesID(All))
  [Cancel] → Back to main list (no data saved)
  [Back] → Back to Step 1 (no data saved)
  [OK] → Step 3 (device selection)

Step 3 (Device Selection)
  [Cancel] → Back to main list (no data saved)
  [Back] → Back to Step 2 (no data saved)
  [OK] → Step 4 (title entry)

Step 4 (Title Entry)
  [Cancel] → Back to main list (no data saved)
  [Back] → Back to Step 3 (no data saved)
  [OK] → Step 5 (channel if needed) or Step 6+ per type

Step 5+ (Channel / Schedule / Guide / Folder)
  [Cancel] → Back to main list (no data saved)
  [Back] → Back to previous step (no data saved)
  [OK] → Advances toward final confirmation

Final Step (Confirmation Dialog)
  [Cancel] → Back to main list (NOTHING SAVED)
  [OK] → Show added to list + saved to disk
```

**Critical Point:** Canceling at ANY stage — even after 9 of 10 steps — creates **zero artifacts**:
- No orphaned show records in config
- No incomplete entries in memory
- No partial updates to existing shows
- Entire workflow restarts fresh on next "Add"

### Why Cancellation is Safe

The validation flow processes user input entirely in a **temporary buffer** before saving:

1. User enters data → stored in `temp_show_info` (in-memory record)
2. User clicks [Cancel] at any point → `temp_show_info` discarded, never written to config
3. User clicks [OK] at final step → `temp_show_info` copied to main `Show_info` list + saved to disk

**Result:** Config file never sees incomplete or rejected shows.

### Edit Show Workflow — Partial Changes & Reset

Edit mode is different—it works with an **existing show** and must protect current state:

```
Edit Dialog Cancellation:

[Cancel] Button:
  → Discards ALL unsaved changes
  → Returns to main list with original show values
  → Config file unchanged
  
[Reset] Button:
  → Reverts form fields to current saved values only
  → Does NOT close dialog (user can re-edit)
  → Clears any partial edits
  
[Save] Button:
  → Writes changes to config file
  → Updates show on main list immediately
  → Dialog closes, returns to main list
```

**Field Behavior During Edit:**

| Scenario | Behavior |
|----------|----------|
| Change Series type (Single→DateTime) | Enables Days/Time fields, disables SeriesID fields |
| Change DateTime→SeriesID | Clears Days/Time, enables Channel/SeriesID fields |
| Toggle Active checkbox | Pause/resume flag (survives cancellation as display state, but not saved unless [Save]) |
| Manually change show_title | On [Save], triggers title-match check in seriesScanUpdate |

**Example Rejection Sequence:**

```
User: Edit "The FBI Files S03E07"
  → Form shows: Single, Channel 11.3, Time 20:00, Length 60
  
User: Clicks "Series" radio button
  → Form morphs: Now shows Series sub-type options (DateTime/SeriesID)
  → Old fields (Time, Length) hidden
  
User: Realizes this was a mistake, clicks [Cancel]
  → Form closes
  → "The FBI Files S03E07" remains unchanged in list
  → Still shows as Single, Channel 11.3, Time 20:00, Length 60
```

### What Happens When Rejecting Type Changes

When editing and changing a show's type (e.g., Single → DateTime), the validate_show_info handler **conditionally prompts** for missing data:

```
Scenario 1: Single → DateTime (adding schedule)
  User selects "DateTime" → Handler detects type change
  → Prompts for Days (multi-select)
  → Prompts for Time (24-hr decimal)
  → Prompts for Duration (minutes)
  → Then: [Save] writes new config, [Cancel] reverts all

Scenario 2: DateTime → SeriesID (removing schedule)
  User selects "SeriesID" → Handler detects type change
  → Skips Days/Time/Duration prompts
  → Prompts for Channel only (if SeriesID(Channel))
  → Then: [Save] writes, [Cancel] reverts

Scenario 3: User cancels mid-prompt (e.g., hits Escape)
  → Edit dialog closed without saving
  → Original show type + settings preserved
  → No partial state in config
```

### Multi-Item List Operations (Bulk Rejection)

When selecting multiple shows via checkboxes and rejecting an operation:

```
Main List with Multiple Selection:
  ☑ Show 1
  ☑ Show 2
  ☑ Show 3
  ☐ Show 4
  
[Remove] button clicked:
  → Confirmation dialog:
     "Remove 3 shows?"
     ☐ Do not show this again
     [Cancel] [Remove]
  
  User clicks [Cancel]:
    → Dialog closes
    → Checkboxes remain selected (state preserved)
    → No deletion occurs
    → User can reselect or deselect and try again

  User clicks [Remove]:
    → All 3 shows deleted from config
    → Checkboxes cleared
    → List refreshes immediately
```

**Multi-Item Rejection Patterns:**

| Operation | Rejection Outcome |
|-----------|-------------------|
| [Remove] 3 selected shows | Cancels all 3 removals; list unchanged |
| [Edit] on multi-select | Usually disabled (edit requires single select) |
| [Run] (force idle update) | Cancels; no side effects |
| [Add] during multi-select | Creates new show independent of selection state |

### Rejection at Guide Browser Step (SeriesID Workflows)

When adding SeriesID show and browsing the guide:

```
Guide Browser (Step 7):
  ┌────────────────────────────────┐
  │ Browse shows on channel 11.3   │
  ├────────────────────────────────┤
  │ ☐ Show A   Start: ... End: ... │
  │ ☑ Show B   Start: ... End: ... │  ← Selected for details
  │ ☐ Show C   Start: ... End: ... │
  ├────────────────────────────────┤
  │ [Back] [Select] [Cancel]       │
  └────────────────────────────────┘

[Cancel] on Browser:
  → Browser closes
  → Returns to Step 5 (channel selection)
  → User can pick different channel or cancel further
  → No guide data cached or auto-populated yet

[Back] on Browser:
  → Returns to Step 5 (channel selection)
  → Same as Cancel (no guide cache)

[Select] on Browser (with Show B highlighted):
  → Auto-populates: seriesID, show_length, show_next, show_end
  → Advances to Step 9 (folder selection)
  → [Cancel] at folder selection discards all auto-populated data
```

### Rejection After Auto-Population (SeriesID Risk)

**Critical scenario:** User adds a SeriesID show up to Step 9, then cancels:

```
Step 8 (Auto-population has occurred):
  (Auto) show_name: The FBI Files S03E07 Millionaire Murder
  (Auto) show_length: 60 minutes
  (Auto) show_next: Friday, May 1, 2026 at 7:00 PM
  (Auto) show_end: Friday, May 1, 2026 at 8:00 PM
  (Auto) show_channel: 11.3
  (Auto) SeriesID: C505353ENSB1X

User clicks [Back] to adjust channel:
  → Returns to Step 5 (channel selection)
  → Auto-populated fields cleared from temp buffer
  → User can re-select guide or different channel
  
User clicks [Cancel] at Step 9 (folder):
  → Dialog closes, all temp data discarded
  → No show added
  → Guide API call already made (cached for 5+ min)
  → Next [Add] for same series can reuse cache
```

### Rejection With Network Failures

If guide API fails during auto-population (Step 8):

```
Scenario: User selects episode from cache, but live refresh fails

Step 8 (Auto-population):
  - System attempts getTfromN(StartTime) → API fails
  - Fallback: Show_next set to (current date) + 4 * hours
  - Logs ERROR: "Failed to convert StartTime"
  - Auto-population still proceeds with fallback values
  
User sees:
  (Auto) show_name: [Correct - from guide]
  (Auto) show_next: [Fallback +4 hours, not from guide]
  (Auto) show_end: [Fallback +1 hour, not from guide]
  
User clicks [Cancel]:
  → All auto-populated data (including fallback) discarded
  → No show added
  → User can retry (cache still valid) or manual entry
  
User clicks [OK] (accepts fallback):
  → Show added with temporary times
  → seriesScanUpdate will correct show_next/show_end on next idle cycle
```

---

## Recording Status Indicators

### During Recording

```
Main Screen Show Entry:
┌────────────────────────────────────────────┐
│ ● The FBI Files S03E07 Millionaire Murder  │
│ Recording: 41M 38S remaining                │
│ Channel: 11.3 | Signal: ████████████ 100%  │
│ File: /Volumes/Raid6/DVR Tests/...m2ts      │
│ Size: 456 MB (of ~900 MB expected)          │
└────────────────────────────────────────────┘
```

### Recording Status in Log
```
RECORD_START: The FBI Files S03E07 Millionaire Murder
  show_id: 43943CACE2D743EE85DCFAD1DEA4ECBB
  duration: 2619s (43M 39S)
  show_end header: 05.01.26 20.00
  transcode: none
```

### Post-Recording

```
Main Screen Show Entry:
┌────────────────────────────────────────────┐
│ ✓ The FBI Files S03E07 Millionaire Murder  │
│ Recorded: 05.01.26 8:00 PM                  │
│ File: /Volumes/Raid6/DVR Tests/...m2ts      │
│ Size: 903 MB (completed)                    │
└────────────────────────────────────────────┘
```

---

## Notification System

### "Up Next" Notification (35 minutes before)

```
┌──────────────────────────────────────────┐
│ 🎬 Up Next                               │
├──────────────────────────────────────────┤
│ The FBI Files S03E07 Millionaire Murder  │
│ Channel 11.3                              │
│ Starts in 35 minutes at 7:00 PM           │
│                                          │
│ [Dismiss] [Details]                      │
└──────────────────────────────────────────┘
```

### "Recording Starting" Notification (15.5 minutes before)

```
┌──────────────────────────────────────────┐
│ 🔴 Recording Starting                    │
├──────────────────────────────────────────┤
│ The FBI Files S03E07 Millionaire Murder  │
│ Channel 11.3                              │
│ Starts in 15 minutes at 7:00 PM           │
│ Ends: 8:00 PM (60 minutes)                │
│                                          │
│ [Dismiss] [Details]                      │
└──────────────────────────────────────────┘
```

### Error Notifications

```
Recording Failed (show_fail_count = 1):
  ⚠ Failed to record: [Show Title]
  Error: [Tuner busy / Signal loss / Disk full]
  Retry: Will try next episode
  
After 3 Failures (show_active set to false):
  ✗ Paused: [Show Title]
  Reason: Recording failed 3 times
  Action: Edit show and click [Resume] to retry
```

---

## Status Icons in Lists

### Icon Positioning
```
Show Title [Status Icon] [Recording Indicator]
  Icon appears to right of title
  Updates every idle cycle (~10 seconds)
  
Examples:
  ✓ The Late Show S11E105 [●] 
    ^ active  ^ recording
    
  ⚠ Golden Girls S04E25 [!]
    ^ warning/paused  ^ info
    
  🔄 Rifleman S02E11 [▲]
    ^ refreshing  ^ queued for scan
```

---

## Guide Data Flow - What User Sees

### Initial State (Manual Entry)
```
User enters: "The FBI Files"
  ↓ (system searches guide for matching SeriesID)
  ↓
[Tuner 105404BE] - Guide fetched for 24 hours
  ↓ (seriesID matched to C505353ENSB1X)
  ↓
hdhrGRID Browser opens with matching channel
  ↓ (user selects episode S03E07 from guide)
  ↓
Auto-populated:
  - show_next: 05.01.26 7:00 PM
  - show_end: 05.01.26 8:00 PM
  - show_length: 60 min
  - show_channel: 11.3
```

### Ongoing Updates (Every Idle Cycle)
```
Every 10 seconds:
  1. Check if show_next ≤ now + 35 min → "Up Next" notification
  2. Check if show_next ≤ now + 15.5 min → "Recording Starting"
  3. Check if show_end ≤ now → Start recording
  
Every hour:
  4. Fetch fresh guide data (24 hours ahead)
  5. For SeriesID shows: scan for new episodes
  6. If new episode found:
     - Update show_title to new episode
     - Update show_next to new air date
     - Update show_end from guide
     - Reset show_fail_count to 0
```

### What User Sees During Episode Update
```
Before: 
  The FBI Files S03E07 Millionaire Murder
  Next: 05.01.26 7:00 PM
  
[Guide update finds S03E08...]
  
After:
  The FBI Files S03E08 [Different Title]
  Next: 05.02.26 7:00 PM
  
  Status: New episode discovered (may show ⓘ icon)
```

---

## Error States & Recovery

### Show Recording Failed (show_fail_count = 1-2)

```
List Display:
  ⚠ Show Title [!]
  Next: MM/DD HH:MM (unchanged)
  
Edit Dialog:
  Failures: 2 (Max 3 before pause)
  Failure Reason: [Tuner busy / Disk full / Signal lost]
  
Action: Will retry next episode automatically
```

### Show Paused (show_fail_count = 3)

```
List Display:
  ✗ Show Title [✗]
  Next: MM/DD HH:MM (no change)
  Status: PAUSED - Failed 3 times
  
Edit Dialog:
  Active: ☐ (unchecked, show is inactive)
  Failures: 3 / 3
  [Reset to 0 and Resume]
  
User must manually:
  1. Edit the show
  2. Click [Reset Failures]
  3. Click [Save]
  4. Show becomes active again
```

### Tuner Offline

```
Main Screen:
  📡 All shows grayed out
  "No HDHR Device Detected"
  
In Background:
  System continues checking for device
  Retries discovery every idle cycle
  
When Device Returns:
  Shows un-gray
  "Device detected: 105404BE"
  Normal operation resumes
```

---

## Expected Behavior Timeline

### For a New SeriesID(Channel) Show

```
T+0:00    User clicks [Add] → Show wizard
T+0:05    User selects from guide → "The FBI Files S03E07"
T+0:10    App extracts: title, seriesID, show_end, channel
T+0:15    User selects folder → Show added to list
T+0:20    List shows: "✓ The FBI Files S03E07", Next: 05.01.26 7:00 PM
T+0:30    App queues show for SeriesID scan
T+1:00    App scans guide for C505353ENSB1X (first scan)
T+1:05    Found 6 episodes, selects soonest future: S03E07 at 7:00 PM
T+6:25    "Up Next" notification fires (35 min before 7:00 PM)
T+6:45    "Recording Starting" notification (15.5 min before)
T+7:00    Recording begins, show marked as "●" (recording)
T+8:00    Recording ends, file saved, show marked as "✓" (complete)
T+8:05    App queues for next episode scan
T+9:00    Next hour: guide updated, finds S03E08 for next day
T+9:10    Title updates: S03E08, show_next updated, show_end updated
```

---

## What Should NOT Appear

❌ **Never display to user:**
- Raw epoch timestamps (should show formatted dates)
- Internal show_id UUIDs (unless in technical dialog)
- Raw guide API responses
- HTTP headers or curl commands
- Internal flag states (isdupe, channel_record, etc)
- Memory addresses or object references

✓ **Always display as:**
- "Friday, May 1, 2026 at 7:00 PM" (not "1777674900")
- "Channel 11.3" (not "temp_channel")
- "60 minutes" (not "3600 seconds")
- Status icons, not boolean values

---

## SeriesID Metadata Updates - Expected Behavior

**SeriesID updates should ONLY occur for DateTime and Single shows.**

### Expected Log Entries

**For DateTime or Single shows (guide sync):**
```
INFO  SeriesID updated for "Show Title": C505353ENSB1X → C184053ENSZ30
```
This is normal and expected when the guide's SeriesID changes for existing metadata.

### Unexpected/Warning Cases

**SeriesID update attempted on a SeriesID-tracking show:**
```
WARN  Cannot update SeriesID: SeriesID(Channel) and SeriesID(All) shows should never change SeriesID
```
SeriesID is the stable identifier for these shows—if it's changing, the show was misconfigured.

**Blank values rejected:**
```
WARN  Cannot update SeriesID: show_id="", new_seriesid="C505353ENSB1X"
```
Handler validation prevents incomplete updates.

### Why This Matters

- **Single/DateTime shows**: SeriesID is optional metadata from the guide. Updates sync the metadata.
- **SeriesID(Channel) / SeriesID(All) shows**: SeriesID IS the show. Changing it means a different show entirely.

If a SeriesID show's SeriesID is changing, it indicates:
- Wrong SeriesID was stored at add time
- Conflicting shows in guide with same SeriesID
- Guide data corruption
