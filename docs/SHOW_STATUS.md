# Show Status Combinations

Reference for the 4-state show model used throughout hdhr_VCR.

> **📖 See:** [WORKFLOWS.md](WORKFLOWS.md) for user guides and [CLAUDE.md](../CLAUDE.md) for technical architecture.

## The 4 Variables

| Variable | Type | Values | Purpose |
|----------|------|--------|---------|
| `show_is_series` | boolean | true/false | Is this a series or single episode? |
| `show_use_seriesid` | boolean | true/false | Use SeriesID matching (instead of DateTime)? |
| `show_use_seriesid_all` | boolean | true/false | SeriesID across ALL channels? |
| (implied) | | | Days/Channel/Time/Length required |

---

## The 4 Valid Combinations

### 1. DATETIME SERIES
```
show_is_series       = true
show_use_seriesid    = false
show_use_seriesid_all= false
```
**What it does:** Records on specific days, specific time, specific channel
**Prompts needed:**
- ✅ Days (multiple) - "Select the days you wish to record"
- ✅ Channel - "What channel does this show air on?"
- ✅ Time - "What time does this show air?"
- ✅ Length - "How long is this show?"

**Use case:** Old-school DVR recording (e.g., "Record Mondays at 8pm on channel 5")

---

### 2. SERIESID(CHANNEL)
```
show_is_series       = true
show_use_seriesid    = true
show_use_seriesid_all= false
```
**What it does:** Records all SeriesID matches on ONE specific channel
**Prompts needed:**
- ❌ Days (auto-set to all days)
- ✅ Channel - "What channel does this show air on?"
- ❌ Time (determined by guide)
- ❌ Length (determined by guide)

**Use case:** "Record all episodes of this show, but only on channel 5"

---

### 3. SERIESID(ALL)
```
show_is_series       = true
show_use_seriesid    = true
show_use_seriesid_all= true
```
**What it does:** Records all SeriesID matches on ALL channels
**Prompts needed:**
- ❌ Days (auto-set to all days)
- ❌ Channel (records all channels)
- ❌ Time (determined by guide)
- ❌ Length (determined by guide)

**Use case:** "Record all episodes of this show, regardless of which channel they air on"

---

### 4. SINGLE
```
show_is_series       = false
show_use_seriesid    = false
show_use_seriesid_all= false
```
**What it does:** Records ONE specific episode on specific day, time, channel
**Prompts needed:**
- ✅ Day (single day only) - "Select the day you wish to record"
- ✅ Channel - "What channel does this show air on?"
- ✅ Time - "What time does this show air?"
- ✅ Length - "How long is this show?"

**Use case:** "Record this specific episode on Tuesday at 8pm on channel 5"

---

## Invalid Combinations (Should Never Occur)

| show_is_series | show_use_seriesid | show_use_seriesid_all | Status | Reason |
|---|---|---|---|---|
| true | true | false | ✅ Valid | SeriesID(Channel) |
| true | true | true | ✅ Valid | SeriesID(All) |
| true | false | false | ✅ Valid | DateTime Series |
| true | false | true | ❌ INVALID | Can't use SeriesID(All) without SeriesID |
| false | true | false | ❌ INVALID | Can't use SeriesID on a single |
| false | true | true | ❌ INVALID | Can't use SeriesID on a single |
| false | false | false | ✅ Valid | Single |
| false | false | true | ❌ INVALID | Can't use SeriesID(All) on a single |

---

## Transition Rules

When user clicks buttons in edit dialog:

### Clicking "Series" Button
- Set `show_is_series = true`
- Show "What kind of series?" dialog with 3 options:
  1. **DateTime** → `show_use_seriesid = false`, `show_use_seriesid_all = false`
  2. **SeriesID(Channel)** → `show_use_seriesid = true`, `show_use_seriesid_all = false`
  3. **SeriesID(All)** → `show_use_seriesid = true`, `show_use_seriesid_all = true`

### Clicking "Single" Button
- Set `show_is_series = false`
- Set `show_use_seriesid = false`
- Set `show_use_seriesid_all = false`

---

## Validation Logic

For each state, only request prompts for relevant fields:

```
if show_is_series is true:
    if show_use_seriesid_all is true:
        # SeriesID(All)
        auto-set days to all 7 days
        skip channel prompt
        skip time prompt
        skip length prompt
        
    else if show_use_seriesid is true:
        # SeriesID(Channel)
        auto-set days to all 7 days
        ask for channel
        skip time prompt
        skip length prompt
        
    else:
        # DateTime Series
        ask for days (multiple allowed)
        ask for channel
        ask for time
        ask for length
else:
    # Single
    ask for day (single day only)
    ask for channel
    ask for time
    ask for length
```
