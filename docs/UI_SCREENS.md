# hdhr_VCR Complete UI Screens Reference

**Implementation catalog: Every dialog that exists in the code, with exact line numbers, mockups, button labels, validation rules, and skip conditions. Use this to implement or debug specific dialogs.**

> **Related Docs:** [UI_EXPECTATIONS.md](UI_EXPECTATIONS.md) — Design specification and workflows · [CLAUDE.md](../CLAUDE.md) — Architecture and data model

---

## Initialization Screens

### 1. Library Load Error Dialog
**When:** hdhr_VCR_lib.scpt cannot be found or loaded  
**Code:** Line 75-77  
**Behavior:**
```
┌──────────────────────────────────────────┐
│ hdhr_VCR                                 │
├──────────────────────────────────────────┤
│ Unable to load hdhr_VCR_lib, quitting... │
│ [error message]                          │
│                                          │
│ Path: /Users/.../Documents/hdhr_VCR_lib │
│                                          │
├──────────────────────────────────────────┤
│ [🛑 Quit]                                │
└──────────────────────────────────────────┘
```
- **Action:** Only "Quit" button (app exits)
- **Timeout:** 10 seconds (auto-dismisses with Quit)
- **Result:** App terminates

---

### 2. Locale Compatibility Dialog
**When:** System locale is not en_US or en_GB  
**Code:** Line 270  
**Behavior:**
```
┌──────────────────────────────────────────┐
│ Unsupported Locale                       │
├──────────────────────────────────────────┤
│ Due to poor planning on my part, only    │
│ en_US and en_GB regions are supported.   │
│ Locale: [current_locale]                 │
├──────────────────────────────────────────┤
│ [OK]                                     │
└──────────────────────────────────────────┘
```
- **Consequence:** App may have date/time formatting issues
- **Result:** Continues anyway (user proceeds at own risk)

---

## Main Screen Interactions

### 3. Quit Confirmation Dialog
**When:** User clicks "Run" while recordings are in progress  
**Code:** Line 625-630  
**Behavior:**
```
┌────────────────────────────────────────────────┐
│ Confirm Quit                                   │
├────────────────────────────────────────────────┤
│ Do you want to cancel these recordings         │
│ already in progress?                           │
│                                                │
│ • Show Title 1 (ch 5.4)                       │
│ • Show Title 2 (ch 11.1)                      │
│ • Show Title 3 (ch 7.1)                       │
│                                                │
├────────────────────────────────────────────────┤
│ [Go Back]  [Yes]  [No - Force Quit]           │
└────────────────────────────────────────────────┘
```
- **Buttons:**
  - **Go Back:** Return to main screen, recordings continue
  - **Yes:** Cancel recordings, kill processes, quit app
  - **No (default):** Force quit immediately, recordings aborted
- **Shows:** List of all shows currently recording
- **Icon:** ⚠️ Caution

---

### 4. Deactivate Dialog (Active Show)
**When:** User selects a show and clicks "Edit" while it's active  
**Code:** Line 1334  
**Behavior:**
```
┌────────────────────────────────────────────────┐
│ Show Control                                   │
├────────────────────────────────────────────────┤
│ [Show Logo]                                    │
│                                                │
│ Would you like to deactivate:                 │
│ "The FBI Files S03E07"                        │
│                                                │
│ Deactivated shows will be removed on the      │
│ next save/load                                 │
│                                                │
│ Next Showing: Friday, May 1 at 7:00 PM       │
│                                                │
├────────────────────────────────────────────────┤
│ [🏃 Run]  [✗ Deactivate]  [✏️ Edit..]        │
└────────────────────────────────────────────────┘
```
- **Buttons:**
  - **Run:** Cancel, return to list (show stays active)
  - **Deactivate:** Mark inactive, will be removed on next save
  - **Edit.. (default):** Enter edit workflow to modify show
- **Shows:** Show logo, title, next air date
- **Icon:** Show logo

---

### 5. Failed Show Reset Dialog
**When:** Show has failed 3+ times and user tries to edit it  
**Code:** Line 1321-1327  
**Behavior:**
```
┌────────────────────────────────────────────────┐
│ Recording Failed                               │
├────────────────────────────────────────────────┤
│ [Show Logo]                                    │
│                                                │
│ This show has failed more than 3 times        │
│                                                │
│ Would you like to reset the current failed    │
│ count, last error:                            │
│ [error reason, e.g., "Tuner unavailable"]    │
│                                                │
├────────────────────────────────────────────────┤
│ [🏃 Run]  [↻ Reset]                          │
└────────────────────────────────────────────────┘
```
- **Buttons:**
  - **Run:** Cancel (show stays paused, fail_count unchanged)
  - **Reset (default):** Clear fail_count to 0, show reactivates
- **Shows:** fail_count, last error reason
- **Result:** If reset, show returns to recording on next idle cycle

---

### 6. Tuner Offline Dialog
**When:** Show's assigned tuner is no longer active  
**Code:** Line 1329-1330  
**Behavior:**
```
┌────────────────────────────────────────────────┐
│ Device Unavailable                             │
├────────────────────────────────────────────────┤
│ [🛑 Stop]                                      │
│                                                │
│ The tuner, 105404BE is not currently active,  │
│ the show should be deactivated                │
│                                                │
│ Deactivated shows will be removed on the      │
│ next save/load                                │
│                                                │
├────────────────────────────────────────────────┤
│ [🏃 Run]  [✗ Deactivate]  [Next]             │
└────────────────────────────────────────────────┘
```
- **Buttons:**
  - **Run:** Cancel (try to keep using offline tuner)
  - **Deactivate (default):** Mark inactive for removal
  - **Next:** Skip for now, retry on next idle

---

### 7. Activate Dialog (Inactive Show)
**When:** User selects a deactivated show and clicks "Edit"  
**Code:** Line 1355-1356  
**Behavior:**
```
┌────────────────────────────────────────────────┐
│ Reactivate Show                                │
├────────────────────────────────────────────────┤
│ [Show Logo]                                    │
│                                                │
│ Would you like to activate:                   │
│ "The Rifleman S02E11"                         │
│                                                │
│ Active shows can be edited                    │
│                                                │
├────────────────────────────────────────────────┤
│ [🏃 Run]  [✓ Activate]                       │
└────────────────────────────────────────────────┘
```
- **Buttons:**
  - **Run:** Cancel (show stays inactive)
  - **Activate (default):** Reactivate and proceed to edit
- **Result:** show_active set to true, enters edit flow

---

## Guide Browser Screen

### 8. Channel Selection (Add Show)
**When:** User clicks "Add.." or "Edit" and guide-based mode is triggered  
**Code:** Line 2008  

![Channel Selection](../channel_list.png)

**Behavior:**
```
┌──────────────────────────────────────────────────┐
│ Channel Selection                                │
├──────────────────────────────────────────────────┤
│ What channel does this show air on?             │
│ Tuner: 105404BE (1 of 1 tuners available)       │
│ 119 channels                                     │
│                                                  │
│ Legend: 🎬 Recording  ⚠ Error  🎬 <1h  📈 <4h  │
│         📊 >4h  🌟 Recorded today               │
│                                                  │
│ ⊙ 2.1   Channel 2.1                            │
│ ○ 4.1   WCCO-DT [NBC]                          │
│ ○ 5.3   Channel 5.3                            │
│ ○ 5.4   GREAT                                   │
│ ○ 7.1   KSTW [CBS]                             │
│ ○ 9.2   KSTP [ABC]                             │
│ ○ 11.1  KARE-HD [NBC]                          │
│ ... [119 total, scrollable] ...                │
│                                                  │
├──────────────────────────────────────────────────┤
│ [🏃 Run]  [Next..]                             │
└──────────────────────────────────────────────────┘
```
- **Shows:** Device ID, total channel count, icon legend
- **Selection:** Single channel (one row)
- **Buttons:**
  - **Run:** Cancel entire add flow
  - **Next..: (default)** Proceed to guide browser for selected channel

---

### 9. Guide Browser (hdhrGRID)
**When:** User selects channel and app fetches guide data  
**Code:** Line 734-746  

![HDHR Guide Browser](../hdhrGRID.png)

**Behavior:**
```
┌──────────────────────────────────────────────────┐
│ Guide Browser - Channel 11.3 (NBC)              │
├──────────────────────────────────────────────────┤
│ Current Time: Friday 5:00 PM CDT                │
│                                                  │
│ Legend: 🎬 Recording  ⚠ Error  🎬 <1h  📈 <4h  │
│         📊 >4h  🌟 Recorded today              │
│                                                  │
│ [🔴] Saturday Night Live S51E18   🎬            │
│      Sat 5/2 10:49 PM - Sun 5/3 12:00 AM       │
│                                                  │
│ [📺] The Tonight Show S11E105                  │
│      Sun 5/3 11:35 PM - Mon 5/4 12:07 AM       │
│                                                  │
│ [📺] Late Night with Seth S13E86               │
│      Mon 5/4 12:37 AM - 1:37 AM                │
│                                                  │
│ ... 41 more shows on this channel ...           │
│                                                  │
├──────────────────────────────────────────────────┤
│ [Back to Channel List]  [Select]  [Cancel]     │
└──────────────────────────────────────────────────┘
```
- **Multi-Select:** Users can select multiple shows
  - Checkboxes visible when hovering over rows
- **Shows:** Logo, title, S##E##, air times
- **Sorting:** Chronological order
- **Buttons:**
  - **Back:** Return to channel selection
  - **Select (default):** Proceed with selected show(s)
  - **Cancel:** Abort guide browser (but channel stays selected)

**If Multiple Shows Selected:**
```
┌──────────────────────────────────────────────────┐
│ Multi-Show Confirmation                          │
├──────────────────────────────────────────────────┐
│ You are adding multiple shows. Do you wish to    │
│ use the same settings for all shows?            │
│                                                  │
├──────────────────────────────────────────────────┤
│ [No]  [Yes (default)]                          │
└──────────────────────────────────────────────────┘
```
- **Yes:** Validate workflow repeats once, settings applied to all
- **No:** Validate workflow repeats for each show individually

---

## Manual Add/Edit Workflow Dialogs

### 10. Title & Series Type Dialog
**When:** Adding show or editing with missing/invalid title  
**Code:** Line 1379  

![Add Show Dialog](../title.png)

**Behavior:**
```
┌────────────────────────────────────────────────┐
│ Show Title & Type                              │
├────────────────────────────────────────────────┤
│ What is the title of this show, and is it a   │
│ series??                                       │
│                                                │
│ Next Showing: Thursday, May 2, 2026 6:00 PM   │
│ SeriesID: [blank or existing ID]              │
│                                                │
│ Title: [The FBI Files S03E07____________]     │
│                                                │
├────────────────────────────────────────────────┤
│ [🏃 Run]  [📺 Series]  [🎬 Single]           │
└────────────────────────────────────────────────┘
```
- **Input Field:** Text entry for show title
- **Default Button:** Series (if show_is_series=true), Single otherwise
- **Shows:** Next air date, current SeriesID (if any)
- **Buttons:**
  - **Run:** Cancel, discard all data
  - **Series:** Mark as series, show type selection next
  - **Single:** Mark as single, skip to days selection

---

### 11. Series Type Selection Dialog
**When:** User clicks "Series" in title dialog  
**Code:** Line 1403  
**Behavior:**
```
┌────────────────────────────────────────────────┐
│ Series Type Selection                          │
├────────────────────────────────────────────────┤
│ [Show Logo]                                    │
│                                                │
│ What kind of series?                           │
│                                                │
├────────────────────────────────────────────────┤
│ [📅 Date/Time]  [📺 SeriesID(Channel)]  [🌐 SeriesID(All)]
└────────────────────────────────────────────────┘
```
- **Selection:** Single button click, no multi-select
- **Shows:** Show logo
- **Buttons:**
  - **📅 Date/Time:** Manual schedule (days/times entered by user)
  - **📺 SeriesID(Channel):** Guide-driven, one channel
  - **🌐 SeriesID(All):** Guide-driven, all channels
- **Default:** Last selected type for this show

---

### 12. Days Selection Dialog
**When:** Adding DateTime or Single show  
**Code:** Line 1453 (multi) or 1463 (single)  
**Behavior:**

**For DateTime Series:**
```
┌────────────────────────────────────────────────┐
│ Days Selection                                 │
├────────────────────────────────────────────────┤
│ Select the days you wish to record             │
│ This is a series, so you can select multiple   │
│ days                                           │
│                                                │
│ ☑ Sunday    ☐ Monday    ☐ Tuesday             │
│ ☐ Wednesday ☐ Thursday  ☐ Friday              │
│ ☐ Saturday                                     │
│                                                │
├────────────────────────────────────────────────┤
│ [🏃 Run]  [Next..]                            │
└────────────────────────────────────────────────┘
```

**For Single Show:**
```
┌────────────────────────────────────────────────┐
│ Day Selection                                  │
├────────────────────────────────────────────────┤
│ Select the day you wish to record              │
│ This is a single, you can only select 1 day   │
│                                                │
│ ⊙ Wednesday                                    │
│ ○ Thursday   ○ Friday   ○ Saturday            │
│ ○ Sunday     ○ Monday   ○ Tuesday             │
│                                                │
├────────────────────────────────────────────────┤
│ [🏃 Run]  [Next..]                            │
└────────────────────────────────────────────────┘
```

- **Multi-select (DateTime):** ☐ Checkboxes, select 1+ days
- **Single-select (Single):** ⊙ Radio buttons, select exactly 1 day
- **Default:** Previously selected days (or all for Series)
- **Skipped if:** SeriesID mode (auto all 7 days)

---

### 13. Channel Selection Dialog
**When:** Adding DateTime/Single or SeriesID(Channel) show, or tuner available  
**Code:** Line 1482  
**Behavior:**
```
┌────────────────────────────────────────────────┐
│ Channel Selection                              │
├────────────────────────────────────────────────┤
│ What channel does this show air on?            │
│                                                │
│ ⊙ 4.1   WCCO-DT [NBC]                         │
│ ○ 5.3   Channel 5.3                           │
│ ○ 5.4   GREAT                                 │
│ ○ 7.1   KSTW [CBS]                            │
│ ○ 9.2   KSTP [ABC]                            │
│ ○ 11.1  KARE-HD [NBC]                         │
│ ... [119 channels, scrollable] ...            │
│                                                │
├────────────────────────────────────────────────┤
│ [🏃 Run]  [Next..]                            │
└────────────────────────────────────────────────┘
```

- **Selection:** Single channel only
- **Shows:** All 119 channels from tuner lineup
- **Skipped if:** SeriesID(All) mode (auto-detects all channels)
- **Default:** Last selected channel or previously used channel

---

### 14. Time Selection Dialog
**When:** Adding DateTime or Single show  
**Code:** Line 1505  
**Behavior:**
```
┌────────────────────────────────────────────────┐
│ Time Entry                                     │
├────────────────────────────────────────────────┤
│ What time does this show air?                 │
│ (0-24, use decimals, ie 9.5 for 9:30)        │
│                                                │
│ Time: [20.5________________]                  │
│                                                │
├────────────────────────────────────────────────┤
│ [🏃 Run]  [Next..]                            │
└────────────────────────────────────────────────┘
```

- **Input:** Decimal time (0-24), e.g., 9.5 = 9:30 AM, 20.5 = 8:30 PM
- **Validation:** Must be numeric, 0-24 range
- **Skipped if:** SeriesID mode (time from guide)
- **Default:** Last entered time for this show

---

### 15. Duration Selection Dialog
**When:** Adding DateTime or Single show  
**Code:** Line 1518  
**Behavior:**
```
┌────────────────────────────────────────────────┐
│ Duration Entry                                 │
├────────────────────────────────────────────────┤
│ How long is this show? (minutes)              │
│                                                │
│ Duration: [60______________]                  │
│                                                │
├────────────────────────────────────────────────┤
│ [🏃 Run]  [Next..]                            │
└────────────────────────────────────────────────┘
```

- **Input:** Minutes (numeric only)
- **Skipped if:** SeriesID mode (from guide)
- **Default:** Last entered duration, or 60 minutes

---

### 16. Folder Selection Dialog
**When:** Final step before show is saved  
**Code:** Line 1541  
**Behavior:**
```
┌────────────────────────────────────────────────┐
│ Recording Folder Selection                     │
├────────────────────────────────────────────────┤
│ Select shows Directory for "The FBI Files..."  │
│                                                │
│ 📁 Raid6                                       │
│    📁 DVR Tests                                │
│       📁 Archive                               │
│       📁 shows                                 │
│                                                │
│ Current: Raid6:DVR Tests:                      │
│ Space: 78% full (1.3 GB free) ✓ OK            │
│                                                │
│ ⚠ Folders >93% full cannot record             │
│                                                │
├────────────────────────────────────────────────┤
│ [🏃 Run]  [Choose]  [Use Last]                │
└────────────────────────────────────────────────┘
```

- **Selection:** Folder browser dialog
- **Shows:** Current folder, disk usage %, free space
- **Validation:**
  - Folder must exist and be writable
  - Disk usage must be < 93%
- **Buttons:**
  - **Run:** Cancel (keep previous folder or missing value)
  - **Choose:** Browse and select folder
  - **Use Last (default):** Use folder from previous show added
- **Error States:**
  - Not writable → Dialog: "Permission denied"
  - >93% full → Dialog: "Warning: Folder is XX% full. Minimum YY% required"

---

## Setup/Settings Screens

### 17. Setup Dialog
**When:** User clicks "Settings" on main screen  
**Code:** Line 1626  
**Behavior:**
```
┌────────────────────────────────────────────────┐
│ hdhr_VCR Setup                                 │
├────────────────────────────────────────────────┤
│ [Settings icon]                                │
│                                                │
├────────────────────────────────────────────────┤
│ [⚙️ Logging]  [📋 Defaults]  [🏃 Run]         │
└────────────────────────────────────────────────┘
```

- **Buttons:**
  - **Logging:** Enter logging settings submenu
  - **Defaults:** Enter defaults/config submenu
  - **Run (cancel):** Return to main screen

---

### 18. Reload Library Dialog
**When:** User enters Settings → Defaults submenu  
**Code:** Line 1630  
**Behavior:**
```
┌────────────────────────────────────────────────┐
│ Library Reload                                 │
├────────────────────────────────────────────────┤
│ Reload hdhr library?                           │
│                                                │
│ (Updates lib functions without restart)       │
│                                                │
├────────────────────────────────────────────────┤
│ [Skip]  [Yes (default)]                       │
└────────────────────────────────────────────────┘
```

- **Yes:** Unload and reload hdhr_VCR_lib.scpt
- **Skip:** Continue without reloading

---

### 19. Guide Hours Configuration
**When:** User selects "Guide" in setup  
**Code:** Line 1649  
**Behavior:**
```
┌────────────────────────────────────────────────┐
│ Guide Data Range                               │
├────────────────────────────────────────────────┤
│ How many hours of guide data to grab?          │
│ 6-24 valid range                              │
│                                                │
│ Hours: [12______________]                     │
│                                                │
├────────────────────────────────────────────────┤
│ [🏃 Run]  [6H (Default)]  [Set]               │
└────────────────────────────────────────────────┘
```

- **Input:** 6-24 hours
- **Buttons:**
  - **Run:** Cancel
  - **6H (Default):** Set to 6 hours minimum
  - **Set (default):** Save entered value

---

### 20. Notifications Permission Dialog
**When:** App detects notifications not enabled  
**Code:** Line 1699-1701  
**Behavior:**
```
┌────────────────────────────────────────────────┐
│ Enable Notifications                           │
├────────────────────────────────────────────────┤
│ We need to allow notifications                │
│ Click "Next" to continue                      │
│                                                │
├────────────────────────────────────────────────┤
│ [Next]                                         │
└────────────────────────────────────────────────┘

(After confirmation:)

┌────────────────────────────────────────────────┐
│ Success!                                       │
├────────────────────────────────────────────────┤
│ Yay! Notifications Enabled!                   │
└────────────────────────────────────────────────┘
```

---

### 21. Up Next Notification Frequency
**When:** Notifications enabled for first time  
**Code:** Line 1701  
**Behavior:**
```
┌────────────────────────────────────────────────┐
│ Up Next Notification Timing                    │
├────────────────────────────────────────────────┤
│ How often to show "Up Next" update            │
│ notifications?                                 │
│                                                │
│ Minutes before show: [35____________]         │
│                                                │
├────────────────────────────────────────────────┤
│ [🏃 Run]  [Skip]  [OK (default)]              │
└────────────────────────────────────────────────┘
```

- **Input:** Minutes before show air time to notify
- **Default:** 35 minutes
- **Buttons:**
  - **Run:** Cancel
  - **Skip:** Use default (35)
  - **OK:** Save entered value

---

## Notification Messages (Non-Interactive)

### 22. Recording Started Notification
**When:** Recording begins  
**Code:** Line 409  
**Behavior:**
```
┌──────────────────────────────────────────┐
│ 🎬 Started Recording (105404BE)          │
├──────────────────────────────────────────┤
│ "Show Title S##E##" on 5.4 (GREAT)      │
│ Ends: Friday 12:00 AM                   │
└──────────────────────────────────────────┘
```

---

### 23. Recording in Progress Notification
**When:** Every idle cycle while recording  
**Code:** Line 445  
**Behavior:**
```
┌──────────────────────────────────────────┐
│ 🎬 Recording in Progress (105404BE)      │
├──────────────────────────────────────────┤
│ "Show Title S##E##" on 5.4 (GREAT)      │
│ Ends: Friday 12:00 AM (35M 5S remaining)│
└──────────────────────────────────────────┘
```

---

### 24. Up Next Notification
**When:** 35 minutes before show air time (configurable)  
**Code:** Line 467  
**Behavior:**
```
┌──────────────────────────────────────────┐
│ 📽️ Next Up (105404BE)                    │
├──────────────────────────────────────────┤
│ "Show Title S##E##" on 5.4 (GREAT)      │
│ Starts: Friday 7:00 PM (in 35M)         │
└──────────────────────────────────────────┘
```

---

### 25. Recording Failed Notification
**When:** Recording process exits with error  
**Code:** Line 434  
**Behavior:**
```
┌──────────────────────────────────────────┐
│ ❌ This show has failed to record        │
├──────────────────────────────────────────┤
│ "Show Title S##E##" (105404BE)           │
│ Failure reason: [Tuner unavailable]      │
└──────────────────────────────────────────┘
```

---

### 26. Recording Complete Notification
**When:** Recording finishes successfully  
**Code:** Line 517  
**Behavior:**
```
┌──────────────────────────────────────────┐
│ ✓ Recording Complete                     │
├──────────────────────────────────────────┤
│ "Show Title S##E##" on 5.4 (GREAT)      │
│ Next Showing: Friday, May 3, 7:00 PM    │
└──────────────────────────────────────────┘
```

---

### 27. Show Marked Inactive Notification
**When:** Single show completes recording (marked inactive)  
**Code:** Line 532  
**Behavior:**
```
┌──────────────────────────────────────────┐
│ ✓ Recording Complete                     │
├──────────────────────────────────────────┤
│ "Show Title S##E##" on 5.4 (GREAT)      │
│ Show marked inactive (single episode)    │
└──────────────────────────────────────────┘
```

---

### 28. Show Removed Notification
**When:** User removes show from list  
**Code:** Line 546  
**Behavior:**
```
┌──────────────────────────────────────────┐
│ ✓ Show Removed                           │
├──────────────────────────────────────────┤
│ "Show Title S##E##" removed from list    │
└──────────────────────────────────────────┘
```

---

### 29. Channel No Guide Data Notification
**When:** Selected channel has no guide available  
**Code:** Line 673  
**Behavior:**
```
┌──────────────────────────────────────────┐
│ ⚠️ Channel 11.3 has no guide data        │
├──────────────────────────────────────────┤
│ (105404BE)                               │
└──────────────────────────────────────────┘
```

---

### 30. Device Offline Notification
**When:** HDHomeRun device not detected  
**Code:** System-wide behavior  
**Behavior:**
```
All shows display [📡 OFFLINE] icon
Shows cannot record until device found
Main screen banner: "⚠️ HDHomeRun Device Offline"
```

---

## Error Dialogs

### 31. Folder Permission Error
**When:** Selected recording folder is not writable  
**Code:** Line 1547  
**Behavior:**
```
┌────────────────────────────────────────────────┐
│ Permission Error                               │
├────────────────────────────────────────────────┤
│ Error: The selected folder is not writable.    │
│ Please ensure you have write permissions.      │
│                                                │
├────────────────────────────────────────────────┤
│ [OK]                                           │
└────────────────────────────────────────────────┘
```

---

### 32. Disk Space Warning
**When:** Selected folder is >93% full  
**Code:** Line 1556  
**Behavior:**
```
┌────────────────────────────────────────────────┐
│ Disk Space Warning                             │
├────────────────────────────────────────────────┤
│ Warning: The selected folder is 95% full.     │
│ At least 93% free space is required.          │
│                                                │
│ Please select a different folder or free up   │
│ disk space.                                   │
│                                                │
├────────────────────────────────────────────────┤
│ [OK]                                           │
└────────────────────────────────────────────────┘
```

---

### 33. Save Error Dialog
**When:** Config file write fails  
**Code:** Line 659  
**Behavior:**
```
┌────────────────────────────────────────────────┐
│ Save Failed                                    │
├────────────────────────────────────────────────┤
│ Error occurred while saving,                   │
│ [error message]                                │
│                                                │
├────────────────────────────────────────────────┤
│ [OK]                                           │
└────────────────────────────────────────────────┘
```

---

## Dialog Behaviors Summary

### Timeout Behavior
- Most dialogs: 30 second timeout (giving up button auto-clicks)
- Quit dialog: 30 second timeout (default "No - Force Quit")
- Setup dialogs: vary by function

### Button Conventions
- **Run button (🏃):** Always means "Cancel/Exit this workflow"
- **Next.. button:** Proceed to next step (default in linear workflows)
- **Default button:** Pre-highlighted, can press Enter/Return

### Icon/Color Standards
- 🎬 Recording operations
- ⚠️ Warnings or failures
- ✓ Success states
- ✗ Deactivated/stopped states
- 📡 Device/network issues
- 🏃 Exit/cancel action
