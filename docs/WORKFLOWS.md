# hdhr_VCR Workflows

Guide to adding, editing, and managing shows with the 4-state recording system.

---

## Overview: The 4 Recording States

Every show is in exactly ONE of these states, determined by 3 variables:

```
show_is_series        | show_use_seriesid | show_use_seriesid_all | State
---------------------|-------------------|----------------------|------------------
false                 | false             | false                | SINGLE
true                  | false             | false                | DATETIME SERIES
true                  | true              | false                | SERIESID(CHANNEL)
true                  | true              | true                 | SERIESID(ALL)
```

---

## State Details

### 1. SINGLE
Record ONE specific episode on a specific day, time, and channel.

**Use when:** You want to record a one-time event (movie, special episode)

**Prompts during Add:**
- ✅ Show title
- ✅ Single or Series? → Choose **Single**
- ✅ Which day? (1 day only)
- ✅ What channel?
- ✅ What time?
- ✅ How long?
- ✅ Recording folder

**Prompts during Edit:**
- ✅ Show title (can change to Series)
- ✅ Day (can change to different day)
- ✅ Channel
- ✅ Time
- ✅ Length

---

### 2. DATETIME SERIES
Record specific days/times on a specific channel using manual scheduling.

**Use when:** A show airs on the same days/times every week (old-school DVR)
- Example: "Monday, Wednesday, Friday at 8pm on channel 5"

**Prompts during Add:**
- ✅ Show title
- ✅ Single or Series? → Choose **Series**
- ✅ Series type? → Choose **DateTime**
- ✅ Which days? (multiple allowed)
- ✅ What channel?
- ✅ What time?
- ✅ How long?
- ✅ Recording folder

**Prompts during Edit:**
- ✅ Show title (can change to Single or pick different series type)
- ✅ Days (can add/remove days)
- ✅ Channel (can change)
- ✅ Time (can change)
- ✅ Length

**Fields in Config:**
```json
{
  "show_is_series": true,
  "show_use_seriesid": false,
  "show_use_seriesid_all": false,
  "show_air_date": ["Monday", "Wednesday", "Friday"],
  "show_channel": "5.4",
  "show_time": 20,
  "show_length": 60
}
```

---

### 3. SERIESID(CHANNEL)
Record all episodes of a series on ONE specific channel using SeriesID matching.

**Use when:** A show airs on the same channel with different times
- Example: "Record all episodes of The Office on channel 5, whenever they air"

**Prompts during Add:**
- ✅ Show title
- ✅ Single or Series? → Choose **Series**
- ✅ Series type? → Choose **SeriesID(Channel)**
- ✅ What channel?
- ❌ Days? (auto-set to all 7 days)
- ❌ Time? (determined by guide data)
- ❌ Length? (determined by guide data)
- ✅ Recording folder

**Prompts during Edit:**
- ✅ Show title (can change to Single or pick different series type)
- ✅ Channel (can change which channel to record on)
- ❌ Days (auto all 7)
- ❌ Time (guided)
- ❌ Length (guided)

**Fields in Config:**
```json
{
  "show_is_series": true,
  "show_use_seriesid": true,
  "show_use_seriesid_all": false,
  "show_air_date": ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
  "show_channel": "5.4",
  "show_time": 0,
  "show_length": 0
}
```

---

### 4. SERIESID(ALL)
Record all episodes of a series on ANY/ALL channels using SeriesID matching.

**Use when:** A show airs on multiple channels and you want to catch it whenever/wherever
- Example: "Record all episodes of Friends, on any channel, any time"

**Prompts during Add:**
- ✅ Show title
- ✅ Single or Series? → Choose **Series**
- ✅ Series type? → Choose **SeriesID(All)**
- ❌ Channel? (records all channels)
- ❌ Days? (auto-set to all 7 days)
- ❌ Time? (determined by guide data)
- ❌ Length? (determined by guide data)
- ✅ Recording folder

**Prompts during Edit:**
- ✅ Show title (can change to Single or pick different series type)
- ❌ Channel (not applicable)
- ❌ Days (auto all 7)
- ❌ Time (guided)
- ❌ Length (guided)

**Fields in Config:**
```json
{
  "show_is_series": true,
  "show_use_seriesid": true,
  "show_use_seriesid_all": true,
  "show_air_date": ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
  "show_channel": "0",
  "show_time": 0,
  "show_length": 0
}
```

---

## Step-by-Step: Adding a Show

### Common Steps for All Types

1. **Open hdhr_VCR app**
   - Click dock icon or launch from Applications

2. **Click "Add"**
   - Dialog: "What tuner?"
   - Select the HDHomeRun device
   - Click "OK"

3. **Enter Show Title**
   - Dialog: "What is the title of this show, and is it a series?"
   - Type the show name
   - Three buttons: **Series** | **Single** | (Run to cancel)

---

### Path A: Adding a SINGLE Show

After "Enter Show Title" above:

4. **Click "Single"**

5. **Select the day**
   - Dialog: "Select the day you wish to record"
   - Only 1 day can be selected
   - Choose the day the episode airs

6. **Select the channel**
   - Dialog: "What channel does this show air on?"
   - Pick from channel list

7. **Enter the time**
   - Dialog: "What time does this show air? (0-24, use decimals, ie 9.5 for 9:30)"
   - Example: 20 for 8pm, 20.5 for 8:30pm

8. **Enter the length**
   - Dialog: "How long is this show? (minutes)"
   - Example: 60 for 1 hour, 30 for 30 minutes

9. **Select recording folder**
   - Dialog: "Select shows Directory"
   - Pick where to save recordings

10. **Done!**
    - Show added as SINGLE
    - App returns to idle/run screen

---

### Path B: Adding a DATETIME SERIES

After "Enter Show Title" above:

4. **Click "Series"**

5. **Choose series type**
   - Dialog: "What kind of series?"
   - Three options:
     - **DateTime**: Exact time & channel
     - **SeriesID(Channel)**: All SeriesID on one channel
     - **SeriesID(All)**: All SeriesID on all channels
   - Click **"DateTime"**

6. **Select the days**
   - Dialog: "Select the days you wish to record"
   - Message: "This is a series, so you can select multiple days"
   - Select all days the show airs
   - Example: Monday, Wednesday, Friday
   - Click "Next.."

7. **Select the channel**
   - Dialog: "What channel does this show air on?"
   - Pick from channel list
   - Click "Next.."

8. **Enter the time**
   - Dialog: "What time does this show air?"
   - Example: 20 for 8pm, 20.5 for 8:30pm
   - Click "Next.."

9. **Enter the length**
   - Dialog: "How long is this show? (minutes)"
   - Example: 60 for 1 hour
   - Click "Next.."

10. **Select recording folder**
    - Dialog: "Select shows Directory"
    - Pick where to save recordings

11. **Done!**
    - Show added as DATETIME SERIES
    - App returns to idle/run screen

---

### Path C: Adding a SERIESID(CHANNEL) Series

After "Enter Show Title" above:

4. **Click "Series"**

5. **Choose series type**
   - Dialog: "What kind of series?"
   - Click **"SeriesID(Channel)"**

6. **Select the channel**
   - Dialog: "What channel does this show air on?"
   - Pick from channel list
   - Click "Next.."
   - Note: Days, time, length are AUTO-DETERMINED from guide

7. **Select recording folder**
   - Dialog: "Select shows Directory"
   - Pick where to save recordings

8. **Done!**
   - Show added as SERIESID(CHANNEL)
   - Will record all episodes on that channel automatically
   - Times pulled from guide data

---

### Path D: Adding a SERIESID(ALL) Series

After "Enter Show Title" above:

4. **Click "Series"**

5. **Choose series type**
   - Dialog: "What kind of series?"
   - Click **"SeriesID(All)"**

6. **Select recording folder**
   - Dialog: "Select shows Directory"
   - Pick where to save recordings
   - Note: Channel, days, time, length are ALL AUTO
   - Will record on ANY channel, ANY day, using guide data

7. **Done!**
   - Show added as SERIESID(ALL)
   - Will record all episodes on all channels automatically

---

## Step-by-Step: Editing a Show

### Starting Edit Mode

1. **Open hdhr_VCR app**
   - If app is already running, click dock icon
   - App will show "Edit/Remove" menu

2. **Click "Edit"**
   - Shows list with all configured shows
   - Select the show you want to edit
   - Click "OK"

3. **Choose what to edit**
   - Dialog: "What would you like to do?"
   - Click "Edit" to modify the show

---

### Editing a SINGLE Show

4. **Show title dialog**
   - Current title displayed
   - You can:
     - Change the title
     - Click "Single" to keep it as single
     - Click "Series" to convert to series

5. **If you kept it Single:**
   - Dialog: "Select the day you wish to record"
   - You can pick a different day
   - Click "OK"

6. **Select channel** (if needed)
   - May ask if channel changed
   - Pick new channel if desired

7. **Enter time** (if needed)
   - Update the air time if it changed

8. **Enter length** (if needed)
   - Update the duration if it changed

9. **Done!**
   - Changes saved immediately
   - Updated notification sent

---

### Editing a DATETIME SERIES Show

4. **Show title dialog**
   - Current title displayed
   - You can:
     - Change the title
     - Click "Single" to convert to single
     - Click "Series" to keep as series (re-asks for type)

5. **If you keep it Series:**
   - Dialog: "What kind of series?"
   - Current type will be highlighted
   - You can pick a different type or keep current
   - If you change type, will skip subsequent prompts

6. **Select days** (if DateTime or changed from other type)
   - Dialog: "Select the days you wish to record"
   - Can add/remove days
   - Click "OK"

7. **Select channel**
   - Update which channel if needed

8. **Enter time**
   - Update the air time if needed

9. **Enter length**
   - Update the duration if needed

10. **Done!**
    - Changes saved
    - Next recording will use new schedule

---

### Editing a SERIESID(CHANNEL) Show

4. **Show title dialog**
   - Current title displayed
   - You can:
     - Change the title
     - Click "Single" to convert to single
     - Click "Series" to keep as series

5. **If you keep it Series:**
   - Dialog: "What kind of series?"
   - Current type: SeriesID(Channel) highlighted
   - You can switch to DateTime or SeriesID(All) if desired
   - If you keep SeriesID(Channel), no more prompts

6. **Select channel** (only if needed to change)
   - Pick different channel to record on

7. **Done!**
   - Days, time, length auto-determined from guide
   - Will continue recording all episodes on new channel

---

### Editing a SERIESID(ALL) Show

4. **Show title dialog**
   - Current title displayed
   - You can:
     - Change the title
     - Click "Single" to convert to single
     - Click "Series" to keep as series

5. **If you keep it Series:**
   - Dialog: "What kind of series?"
   - Current type: SeriesID(All) highlighted
   - You can switch to DateTime or SeriesID(Channel) if desired
   - If you keep SeriesID(All), no more prompts

6. **Done!**
   - No channel, days, or time selection needed
   - Continues recording on all channels

---

## Validation Rules

When editing or adding a show, the system validates:

✅ **SINGLE shows must have:**
- show_is_series = false
- show_use_seriesid = false
- show_use_seriesid_all = false
- show_air_date with 1 day
- Valid channel
- Valid time (0-24)
- Valid length (>0)

✅ **DATETIME SERIES must have:**
- show_is_series = true
- show_use_seriesid = false
- show_use_seriesid_all = false
- show_air_date with 1+ days
- Valid channel
- Valid time (0-24)
- Valid length (>0)

✅ **SERIESID(CHANNEL) must have:**
- show_is_series = true
- show_use_seriesid = true
- show_use_seriesid_all = false
- show_air_date with all 7 days (auto-set)
- Valid channel
- Time/length auto from guide

✅ **SERIESID(ALL) must have:**
- show_is_series = true
- show_use_seriesid = true
- show_use_seriesid_all = true
- show_air_date with all 7 days (auto-set)
- No specific channel
- Time/length auto from guide

---

## Examples

### Example 1: One-time Movie
**Goal:** Record the new Marvel movie on Tuesday at 8pm on channel 6

**Path:** Single
1. Title: "Avengers: Endgame"
2. Single (1 day, specific time, specific channel)
3. Day: Tuesday
4. Channel: 6
5. Time: 20
6. Length: 150 (2.5 hours)

---

### Example 2: Weekly Show (Same Time)
**Goal:** Record The Office every Monday and Thursday at 8:30pm on channel 5

**Path:** DateTime Series
1. Title: "The Office"
2. Series → DateTime
3. Days: Monday, Thursday
4. Channel: 5
5. Time: 20.5
6. Length: 30

---

### Example 3: Show on Multiple Channels (Same Channel)
**Goal:** Record all episodes of Friends, but only on channel 4

**Path:** SeriesID(Channel)
1. Title: "Friends"
2. Series → SeriesID(Channel)
3. Channel: 4
4. (Days, time, length auto from guide)

---

### Example 4: Show on Any Channel
**Goal:** Record all episodes of Seinfeld, on any channel, any time

**Path:** SeriesID(All)
1. Title: "Seinfeld"
2. Series → SeriesID(All)
3. (Channel, days, time, length all auto)

---

## Quick Reference: What Gets Prompted?

| Prompt | Single | DateTime | SeriesID(Ch) | SeriesID(All) |
|--------|--------|----------|--------------|---------------|
| **Title** | ✅ | ✅ | ✅ | ✅ |
| **Series/Single** | ✅ | ✅ | ✅ | ✅ |
| **Series Type** | ❌ | ✅* | ✅* | ✅* |
| **Days** | ✅ | ✅ | ❌ Auto | ❌ Auto |
| **Channel** | ✅ | ✅ | ✅ | ❌ Auto |
| **Time** | ✅ | ✅ | ❌ Guide | ❌ Guide |
| **Length** | ✅ | ✅ | ❌ Guide | ❌ Guide |
| **Folder** | ✅ | ✅ | ✅ | ✅ |

\* Only on initial creation. When editing, series type dialog only appears if you change from Single→Series.
