# Timezone Correction Fix - Test Plan

**Commits:** 0b5b2d3, 548bf9a, 36e860a
**Date:** 2026-05-02  
**Current Time:** 6:36 PM CDT  

## Architecture: All Times Are "Epoch Local Time"

HDHomeRun device returns times as **"epoch local time"** - the epoch value that represents the actual local time (e.g., 6:00 PM CDT is stored as the epoch number for "6:00 PM UTC").

For consistency, **all times stored in config are also in "epoch local time" format**. This is produced by `datetime2epoch()` when storing and requires the `- (time to GMT)` correction when loading or processing with `epoch2datetime()`.

## What Was Fixed

**Five locations corrected:**

1. **seriesScanNext** (lib) - Episode eligibility checks and logging
2. **seriesScanUpdate show_time** (lib) - Setting show_time from guide data  
3. **update_show** (main) - Comparing show times during edits
4. **deserialize_show** (lib) - Loading 5 time fields from config:
   - show_last, show_next, show_end
   - notify_recording_time, notify_upnext_time

All now consistently apply: `getTfromN(epoch) - (time to GMT)` or `(stored_epoch) - (time to GMT)` before conversion.

## Why This Matters

The fix ensures:
- ✓ Times from HDHomeRun guide are correctly interpreted as "epoch local time"
- ✓ Times stored in config preserve the same "epoch local time" format
- ✓ When config is loaded, times are correctly restored to local date objects
- ✓ No 5-hour shifts or other timezone offset errors between HDHomeRun and stored data
- ✓ Recording triggers happen at the correct scheduled time

## Manual Test Scenarios (6:36 PM)

### Test 1: SeriesID Show Scheduling
**Setup:** Create a new SeriesID(All) show for a series that has an episode airing **tonight around 7:00 PM** or **8:00 PM**.

**Test Steps:**
1. Open hdhr_VCR app
2. Add a new show > Series > SeriesID(All)
3. Select a series with a known evening air time
4. Verify in the dialog that "Next Showing" displays the **correct time** (not 5+ hours off)
5. Allow the show to record and verify the recording starts at the **correct time**

**Expected:** Show_next should be close to the actual air time (e.g., 7:00 PM or 8:00 PM), not midnight or early morning.

### Test 2: Edit SeriesID Show
**Setup:** Edit an existing SeriesID show.

**Test Steps:**
1. Open hdhr_VCR and select an existing SeriesID show to edit
2. The edit dialog should show "Next Showing:" with the correct upcoming episode time
3. Confirm the time matches what you see in the guide or HDHomeRun app

**Expected:** Next Showing time should match guide data (with timezone-corrected conversion).

### Test 3: DateTime Series Recording
**Setup:** Create or have a DateTime series that records at a specific time.

**Test Steps:**
1. Watch the idle loop and wait for the recording trigger
2. At ~15.5 minutes before show time, verify notification appears
3. At show time, verify recording starts
4. Check the log file to see the exact times

**Expected:** Recording should start at or very close to the scheduled time, not 5+ hours early or late.

### Test 4: Config Persistence (Critical for consistency)
**Setup:** Create a show, save config, restart app, and verify times are consistent.

**Test Steps:**
1. Create a new SeriesID show with an episode airing at a specific time (e.g., 8:00 PM)
2. Note the "Next Showing" time displayed
3. Close hdhr_VCR and restart it
4. Re-open the show for editing - the "Next Showing" should be the SAME time
5. Verify no 5-hour shift or other offset appears

**Expected:** Times should be identical before and after restart. If they shift by 5+ hours, the config loading is still broken.

### Test 5: Log Inspection
**Check File:** `~/Library/Logs/hdhr_VCR.log`

**Look For:**
- Lines with "seriesScanNext_lib" → should show correctly adjusted start times
- Lines with "seriesScanUpdate_lib" → show_next and show_end should be close to actual times
- Lines with "update_show" → show time comparisons should be reasonable

**Red Flags:**
- Show times that are 5+ hours off from what the guide says
- Episodes being skipped or selected incorrectly
- Notifications appearing at wrong times

## Regression Tests

Verify these existing features still work:

1. **Single Episode Recording** - Add a single episode, verify it records at the right time
2. **DateTime Series** - Manual schedule with specific days/time should still work
3. **Show Editing** - Editing show details should not break scheduling
4. **Multiple Shows** - Multiple shows recording at different times

## Success Criteria

✓ SeriesID episodes show correct times in dialogs  
✓ SeriesID episodes record at the correct scheduled time  
✓ Show time displays in logs are reasonable (within timezone range)  
✓ No regressions in single/DateTime series functionality  
✓ Edit flow shows correct times when updating shows  

## Rollback Plan

If issues occur:
```bash
git revert 0b5b2d3
```

This will remove the timezone correction consistency fixes if they cause unexpected behavior.
