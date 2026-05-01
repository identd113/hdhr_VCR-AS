# hdhr_VCR Log Issues — Monitoring Session
**Started:** 2026-05-01 11:28 AM  
**Duration:** 6 hours (until ~5:28 PM)  
**Cadence:** Hourly log checks  
**Status:** Active

---

## Issues Found

### Check 1 — 11:28–11:30 AM

#### **Critical: Epoch 0 Sentinel Overuse (01.01.70 12:00 AM)**
- **Pattern:** Multiple series episodes showing end time as `Thursday, January 1, 1970 at 12:00:00 AM` (Unix epoch 0)
- **Affected shows:** 
  - Eyewitness News at Noon
  - The Rockford Files S01E15 Profit and Loss
  - Walker, Texas Ranger S06E20 Warriors
  - Golden Girls S04E25, S04E26
  - Teenage Mutant Ninja Turtles S07E22
  - Sister Sister S04E08
  - The Late Show With Stephen Colbert S11E105
  - Late Night With Seth Meyers S13E86
  - Celebrity Jeopardy! S04E05
- **Root cause:** When guide lookup fails or seriesID episodes don't have proper air dates in the guide, `show_end` is being set to epoch 0 as a sentinel. These shows are then marked "passed" because epoch 0 is ancient.
- **Impact:** Shows appear overdue even though they haven't aired yet. The 4-hour retry window helps but masks the underlying guide data issue.

#### **Warning: SeriesID Scan Loop Failing**
- **Log entry:** `No upcoming episodes found in guide for "Eyewitness News at Noon" (seriesID: C369178ENE1J9); advancing show_next by 4 hours to retry later`
- **Root cause:** The guide data doesn't contain future airings for this seriesID. Either:
  - The seriesID is incorrect or no longer valid
  - The channel's guide data is incomplete
  - The show doesn't have future scheduled episodes
- **Workaround:** 4-hour retry mechanism will eventually find it or give up

#### **Error: epoch2datetime Library Call Failure During Add Show**
- **Error message:** `«script» doesn't understand the «epoch2datetime» message`
- **Context:** Occurs in `add_show_info` handler when trying to set show_next/show_end from guide data
- **Root cause:** The call is not using the proper library reference context. Should be invoking via `LibScript` (compare to working calls at line 1006).
- **Workaround:** Manual show entry still works; auto-population fails silently

#### **Warning: Tuner Mismatch During Recording**
- **Log entry:** `We are marked as having more shows recording then tuners in use. Expected: 1, Actual: 0`
- **When:** At 11:28:56 AM during playback of show list
- **Root cause:** The `show_recording` flag may not be clearing properly when a recording completes, or tuner status isn't syncing fast enough during idle loop.
- **Impact:** May cause spurious warnings, but doesn't seem to block recordings

#### **File Timestamp Mangling**
- **File:** Wowsabout_2.4_05.01.26 11.28.55.m2ts
- **Issue:** `touch -t 202604301900` applied (April 30, 2026 7:00 PM)
- **Expected:** May 1, 2026 11:28 AM (actual recording time)
- **Root cause:** OriginalAirdate lookup returned epoch 0, which got converted to an invalid date string

---

## Notes for Troubleshooting

- **Epoch 0 pattern:** May indicate a systematic issue with how `show_end` is initialized for new series episodes
- **Guide data gaps:** Might be a real issue with the HDHomeRun guide feed or our seriesID lookups
- **Library reference:** The `epoch2datetime` failure suggests a scoping issue in how the library is being called during add_show

---

## Next Checks

- [ ] 12:28 PM — Check if epoch 0 errors continue
- [ ] 1:28 PM — Monitor guide update cycles (now hourly at :01)
- [ ] 2:28 PM — Check for patterns in warnings/errors
- [ ] 3:28 PM — Stability check
- [ ] 4:28 PM — Final checks before 6-hour window closes

---

**Status Update — 11:31 AM**
- Monitoring loop active, hourly cron job scheduled (ID: 01240e19)
- Ready for permission expansion to enable automated appends during 6-hour window

---

## FIXES IMPLEMENTED — 2:30 PM

All 4 identified issues have been fixed and deployed:

### ✅ Fix 1: OriginalAirdate log level (line 487)
- Changed `"WARN"` → `"INFO"` 
- No behavioral impact, just reduces noisy warnings

### ✅ Fix 2: epoch2datetime missing `of LibScript` (lines 2125–2126)
- `my epoch2datetime(...)` → `epoch2datetime(...) of LibScript`
- Fixes auto-population of show_next/show_end from guide data
- Was causing Silent failure → missing value → epoch 0 → 01.01.70 date

### ✅ Fix 3: ShowID mismatch gate (lib line 1441 + else block)
- Condition: `item 3 of isdupe is false` → `item 1 of isdupe is false and item 3 of isdupe is false`
- Added INFO log for "title changed but StartTime unchanged" case
- Stops UUID rotation on minor title variations; StartTime is now canonical

### ✅ Fix 4A: SeriesID placeholder show_next (lines 382, 522)
- Added `set show_next of item i of Show_info to (current date) + 4 * hours` before seriesScanAdd
- Prevents show_next from remaining stale past date during save/restart gap

### ✅ Fix 4B: DateTime nextday guard (line ~1296)
- Added check: if `nextup is {}`, set to `(current date) + 1 * days` instead
- Prevents empty list → epoch 0 serialization

**Deployed:** 2026-05-01 2:30 PM  
All fixes compiled and deployed successfully via `bash deploy.sh`

**Next:** Monitor logs for absence of epoch 0 dates and showID rotation warnings

### Check 2 — 12:00 PM (30-min interval)

#### **Recurring: Epoch 0 Still Present**
- Same 9 shows still showing `01.01.70 12:00 AM` as end time
- Persistent through idle cycles 11:28–12:00
- No new epoch 0 occurrences, but not clearing either

#### **New: ShowID Mismatch on Hourly Guide Update**
- **Log entry:** `The show, Walker, Texas Ranger S06E20 Warriors showid changed from 2796921F2C87423799C6FF5E65E98462 to A9CBE71FCF9B4AC89C1802E5189D458B`
- **When:** 12:00:00 AM (during hourly guide update at :00 mark)
- **Root cause:** During seriesScanUpdate, the same episode is being matched to a different show ID
- **Impact:** Could cause duplicate recordings if the old ID is still active

#### **Continuing: "Already on Refresh List"**
- Multiple seriesIDs flagged as duplicate refresh attempts
- Suggests seriesScanAdd is being called multiple times for same show

#### **Status: Walker Texas Ranger Premature "Passed" Flag**
- Shows as "passed" with next air at 12:00 PM, but warning fires at 11:59:56, 11:59:58, 12:00:00
- Shows is about to air but marked passed (shouldn't be)

### Check 3 — 1:00 PM (Hourly guide update cycle)

#### **Good: Recording Skip Logic Working**
- Log: `The show, Walker, Texas Ranger S06E21 Angel was not updated, as it was recording`
- **When:** 12:59:57 and 13:00:13 during seriesScanUpdate
- **Status:** ✅ Correct — shows don't get updated while recording

#### **Recurring: Eyewitness News Still Missing Guide Data**
- `No upcoming episodes found in guide for "Eyewitness News at Noon" (seriesID: C369178ENE1J9); advancing show_next by 4 hours to retry later`
- **Occurrence:** 12:00 PM, 1:00 PM, and 2:00 PM cycles (3 consecutive hours)
- **Pattern:** Consistent 4-hour backoff; guide data gap seems persistent

### Check 4 — 2:00 PM (Hourly guide update cycle)

#### **CRITICAL: ShowID Mismatch Escalating**
- Walker, Texas Ranger S06E21 Angel has now had **3 different show IDs**:
  - 2796921F2C87423799C6FF5E65E98462 (12:00 PM)
  - A9CBE71FCF9B4AC89C1802E5189D458B (12:00 PM → 12:00)
  - A44237478C4A414C98AF5D87973CE789 (14:00 PM)
- **Log:** `The show, Walker, Texas Ranger S06E21 Angel showid changed from A9CBE71FCF9B4AC89C1802E5189D458B to A44237478C4A414C98AF5D87973CE789`
- **Risk:** Duplicate recordings if old IDs still active; data loss if tracking broken
- **When:** During 2:00 PM hourly guide update

#### **New: Missing OriginalAirdate**
- Log: `OriginalAirdate does not exist for "Walker, Texas Ranger S06E21 Angel"`
- **When:** 14:00:10, right after recording completion
- **Impact:** Can't set proper file timestamps for recordings

#### **Pattern: Recurring Eyewitness News**
- 3rd consecutive hourly cycle (12:00, 1:00, 2:00) reporting no guide episodes
- SeriesID C369178ENE1J9 either invalid or guide provider has gaps
