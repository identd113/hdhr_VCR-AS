# Advanced Processes

Detailed technical documentation for complex workflows in hdhr_VCR.

---

## Table of Contents

1. [SeriesID Episode Matching](#seriesid-episode-matching)
2. [Recording Lifecycle](#recording-lifecycle)
3. [Disk Space Management](#disk-space-management)
4. [Error Handling & Retry Logic](#error-handling--retry-logic)
5. [Guide & Lineup Updates](#guide--lineup-updates)
6. [Multi-Tuner Support](#multi-tuner-support)
7. [Notification System](#notification-system)
8. [Config Persistence](#config-persistence)

---

## SeriesID Episode Matching

### What is SeriesID?

SeriesID is a unique identifier assigned by the HDHomeRun guide to each series. When you use SeriesID matching (SeriesID(Channel) or SeriesID(All)), the app doesn't care about channel/time/day—it just looks for any episode of that series and records it.

### How It Works

#### 1. Series ID Acquisition
When you add a show using SeriesID mode:
1. App queries the HDHomeRun guide for the show
2. Extracts the SeriesID from matching guide entries
3. Stores SeriesID in config: `show_seriesid: "C472160EN1BDK"`

#### 2. Episode Discovery (seriesScanRun)
The app runs a periodic scan (every idle cycle) to find upcoming episodes:

**Process:**
```
For each show with show_use_seriesid = true:
  1. Query HDHomeRun guide for all entries with matching SeriesID
  2. Find episodes NOT yet recorded
  3. Check against recording schedule:
     - DateTime: Only record on selected days
     - SeriesID(Channel): Only on selected channel
     - SeriesID(All): Any channel, any day
  4. Queue matching episodes for recording
```

**Example Flow:**
```
Config has:
  - show_title: "The Office"
  - show_seriesid: "C184094EN5OIH"
  - show_use_seriesid: true
  - show_use_seriesid_all: false  (Channel mode)
  - show_channel: "5.4"

App finds in guide:
  - "The Office S07E05" on channel 5.4 at 8pm tomorrow ✅ Will record
  - "The Office S07E05" on channel 6.1 at 9pm tomorrow ❌ Wrong channel (skip)
  - "The Office S07E04" on channel 5.4 at 10pm tonight ❌ Already recorded (skip)
```

#### 3. Next Episode Calculation (seriesScanNext)
For each discovered episode, the app calculates:
- **Next Air Time**: When the episode next airs
- **Offset**: Days until it airs
- Stores in config: `show_next: "Wednesday, April 15, 2026 at 7:00:00 AM"`

#### 4. Recording Queue (seriesScanAdd)
Episodes matching the recording criteria are added to a task queue:
- Processed at end of idle loop
- Prevents duplicate recordings
- Handles channel/time conflicts
- Ensures proper series ordering

---

## Recording Lifecycle

### Phase 1: Pre-Recording (Idle Loop Cycle)

**Every idle cycle (default 10 seconds):**

```
1. CHECK FOR UPCOMING SHOWS
   - For each show in config
   - Is show_active = true?
   - Is show_next <= now + Notify_upnext?
   
2. SEND "UP NEXT" NOTIFICATION
   - If show_next within 35 minutes (Notify_upnext)
   - Show: "Next Up: [show_title]"
   - Only sent once per show
   
3. CHECK FOR READY-TO-RECORD
   - For each show in config
   - Is show_end <= now?  (Time to start recording)
   - Is show_active = true?
   
4. START RECORDING
   - If yes to #3, move to Phase 2
```

**Key Config Fields Used:**
- `show_next` - When show airs next
- `show_end` - When recording should start
- `show_active` - Should this show be recorded?
- `Notify_upnext` - How many minutes before to notify (default: 35)

---

### Phase 2: Recording (record_start Handler)

**When a show is ready to record:**

```
1. CHECK TUNER AVAILABILITY
   - Is the tuner online?
   - Is the tuner available? (not recording another show)
   - Do we have the right channel?
   
2. CHECK DISK SPACE
   - Get free space on recording folder
   - If disk > 93% full: ABORT (configurable)
   - Calculate space needed for recording
   
3. SEND "RECORDING" NOTIFICATION
   - "Recording Started: [show_title]"
   - Shown 15 minutes before start (Notify_recording)
   
4. EXECUTE RECORDING COMMAND
   - Build curl command to HDHomeRun:
     curl --header "show_id: {id}" \
          --header "show_end: {end_time}" \
          --header "appname: hdhr_VCR" \
          "http://{hdhr_ip}:5004/auto/v{channel}" \
          -o "{recording_path}"
          
5. APPLY TRANSCODE
   - If tuner supports transcoding: use profile
   - Common profiles: "none", "h264", "h265"
   - Default: "none" (raw stream)
   
6. PREVENT SLEEP
   - Wrap recording with: caffeinate -i {command}
   - Keeps Mac awake during recording
   
7. STORE METADATA
   - Recording path in config
   - Recording start time
   - Process ID for monitoring
```

**Recording Command Example:**
```bash
caffeinate -i curl --connect-timeout 10 \
  -H 'show_id:4BA781F1BAA94B8F8C44D3A3339EB2CA' \
  -H "show_end:04.14.26 22.00" \
  -H 'appname:hdhr_VCR' \
  'http://hdhr-105404be.local:5004/auto/v4.3?duration=1795&transcode=none' \
  -o "/Volumes/Raid6/DVR Tests/Girlfriends S02E15_4.3_04.14.26 21.30.06.m2ts" \
  > /dev/null 2>&1 &
```

---

### Phase 3: Recording Progress Monitoring

**Every idle cycle while recording:**

```
1. CHECK RECORDING STATUS
   - Is the recording process still running?
   - Get PID (process ID) from config
   - If process dead: ERROR
   
2. MONITOR TUNER HEALTH
   - Signal strength: Should be > 75%
   - Signal quality: Should be > 75%
   - Symbol quality: Should be 100%
   - If degraded: LOG WARNING
   
3. UPDATE PROGRESS
   - Calculate time remaining
   - Update in logs
   - Example: "Recording in progress for 'Show X', ends in 27M 46S"
   
4. PERIODICALLY CHECK GUIDE
   - Every 5 minutes at :00 or :30
   - Refresh guide data from HDHomeRun
   - Update lineup info
```

---

### Phase 4: Post-Recording

**When recording time expires:**

```
1. VERIFY COMPLETION
   - Recording process should have ended
   - Check output file exists
   - Check file size > 0 bytes
   
2. UPDATE SHOW STATUS
   - For DateTime Series: Calculate next_air_date
   - For Single shows: Set show_active = false
   - For SeriesID: Queue next episode scan
   
3. SEND COMPLETION NOTIFICATION
   - "Recording Complete: [show_title]"
   
4. UPDATE CONFIG
   - Save show_next time
   - Clear show_recording flag
   - Save to disk
   
5. FOR SERIESID SHOWS
   - Trigger seriesScanNext to find next episode
   - Update show_next in config
   - Queue for recording if upcoming
```

---

## Disk Space Management

### Space Checking Strategy

#### Before Recording Starts

**Threshold Check:**
```
IF disk_used_percent >= 93% THEN
  - LOG: "Disk space critical"
  - DO NOT START RECORDING
  - Try next show (may have different folder)
ELSE
  - Proceed to record
```

**Config Setting:**
```json
"Max_disk_percentage": 93  // Configurable
```

#### During Idle Loop

**Periodic Monitoring:**
```
Every idle cycle:
  1. Get disk usage for each recording folder
  2. Log if above 85% (warning threshold)
  3. Calculate space for next show
  4. If next show won't fit: LOG WARNING
```

### How to Check Disk Space (Manual)

**Terminal Command:**
```bash
df -k ~/path/to/recording/folder
```

**Or via Mac GUI:**
- Finder → Click folder → Cmd+I → See "Used" space

**hdhr_VCR Log Entry:**
```
04.14.26 21.30.06 hdhr_VCR INFO update_folder_lib()
"Raid6:DVR Tests:" 84% full, max is 93%
```

---

## Error Handling & Retry Logic

### Recording Failure Detection

**What counts as a failure?**
```
1. Recording process crashed/died
2. Tuner went offline mid-recording
3. Output file not created
4. Output file empty (0 bytes)
5. Network error during download
```

### Retry Logic

#### Single Failure
```
Recording fails on first try:
  1. LOG ERROR with reason
  2. Increment show_fail_count
  3. Set show_fail_reason: "error details"
  4. Try again next scheduled time
```

#### Multiple Failures (Fail_count = 3)
```
After 3 failures:
  1. Set show_active = false (PAUSE recording)
  2. LOG: "Recording paused due to repeated failures"
  3. Send NOTIFICATION: "Recording Paused: [show_title]"
  4. User must manually re-activate
```

**How to Re-activate:**
- Edit the show
- Change any setting (e.g., folder)
- Reset show_fail_count to 0
- Set show_active = true

---

## Guide & Lineup Updates

### Lineup Discovery (HDHRDeviceDiscovery)

**Happens on startup and periodically:**

```
1. SCAN FOR TUNERS
   - Query local network for HDHomeRun devices
   - Endpoint: http://[ip]:5004/discover.json
   - Gets: Device ID, IP, model
   
2. FOR EACH TUNER
   - Query lineup: http://[ip]:5004/lineup.json
   - Gets: Available channels, names, numbers
   
3. FOR EACH CHANNEL
   - Query guide: http://[ip]:5004/guide/channel[number].json
   - Gets: Programs airing on that channel
   - GuideHours config: 4, 12, or 24 hours ahead
   
4. CACHE RESULTS
   - Store in config: channel_mapping, lineup data
   - Reuse for 5+ minutes before refreshing
```

**Example Discovery Response:**
```json
{
  "BaseURL": "http://10.0.2.100:5004/",
  "FriendlyName": "HDHR5-105404BE",
  "ModelNumber": "HDHR5-2US",
  "TunerCount": 2,
  "BaseURL": "http://192.168.1.100:5004/",
  "LineupURL": "http://192.168.1.100:5004/lineup.json"
}
```

### Guide Data Update

**Every 5 minutes at :00 or :30 mark:**

```
IF tuner online AND 5+ minutes since last guide update THEN
  1. Query current guide from HDHomeRun
  2. Parse all programs
  3. Update show_next for each series
  4. If upcoming episode found:
     - Update show_air_date
     - Update show_next
     - Queue for recording
```

**Guide Query:**
```
http://hdhr-{device}.local:5004/guide.json?channels={channel}&hours={GuideHours}
```

---

## Multi-Tuner Support

### Tuner Selection (HDHRDeviceSearch)

**When adding a show:**
```
1. User picks from list of available tuners
2. App stores in config: hdhr_record = "105404BE"
3. All future recordings use that tuner
```

**Config Storage:**
```json
{
  "show_channel": "5.4",
  "hdhr_record": "105404BE",  // Device ID
  "show_url": "http://hdhr-105404be.local:5004/auto/v5.4"
}
```

### Recording Conflict Resolution

**If 2 shows record simultaneously:**
```
1. Both shows reference same tuner
2. First show gets the tuner (already recording)
3. Second show:
   - LOG: "Tuner busy, skipping this recording"
   - Wait for next occurrence
   - Try again at next scheduled time
```

**Prevention:**
- Schedule shows on different channels (if 2 tuners)
- Use SeriesID(All) to record on any available tuner
- Check tuner count: `TunerCount` in device discovery

---

## Notification System

### "Up Next" Notifications

**Trigger:**
```
IF (show_next - now) <= Notify_upnext (default 35 min) THEN
  Send notification
```

**Notification:**
```
Title: [app icon] hdhr_VCR
Subtitle: "Next Up: [show_title]"
```

**Once Per Show:**
- Notification sent only once per show
- Resets when show_next is recalculated
- Prevents spam

### "Recording" Notifications

**Trigger:**
```
WHEN recording starts (Notify_recording default 15.5 min before)
```

**Notification:**
```
Title: [red record icon] Recording
Subtitle: "[show_title] started recording"
```

**Content:**
- Show icon (if logo URL available)
- Show title
- Channel number

### "Recording Complete" Notifications

**Trigger:**
```
WHEN recording finishes successfully
```

**Notification:**
```
Title: [checkmark icon] Recording Complete
Subtitle: "[show_title]"
Body: File path or file size
```

---

## Config Persistence

### Config File Structure

**Location:** `~/Documents/hdhr_VCR-{hostname}.json`

**Structure:**
```json
{
  "config": {
    "Notify_recording": 15.5,      // Minutes before to notify
    "Notify_upnext": 35,            // Minutes before to notify
    "Config_version": 1,            // Schema version
    "GuideHours": 4,                // How far ahead to fetch guide
    "Hdhr_setup_folder": "Volumes:" // Default recording folder
  },
  "the_shows": [
    { show_object_1 },
    { show_object_2 },
    // ... more shows
  ]
}
```

### Show Object Structure

**Required Fields:**
```json
{
  "show_id": "unique_id_string",
  "show_title": "Show Title",
  "show_is_series": true,
  "show_use_seriesid": false,
  "show_use_seriesid_all": false,
  "show_air_date": ["Monday", "Wednesday"],
  "show_channel": "5.4",
  "show_time": 20,
  "show_length": 60,
  "show_dir": "Raid6:DVR Tests:",
  "show_active": true,
  "hdhr_record": "105404BE",
  "show_url": "http://hdhr-105404be.local:5004/auto/v5.4"
}
```

**SeriesID Fields (if applicable):**
```json
{
  "show_seriesid": "C472160EN1BDK",
  "show_use_seriesid": true,
  "show_use_seriesid_all": true
}
```

**Runtime Fields (updated during operation):**
```json
{
  "show_next": "Wednesday, April 15, 2026 at 7:00:00 AM",
  "show_last": "Monday, April 13, 2026 at 7:00:00 AM",
  "show_end": "Wednesday, April 15, 2026 at 7:30:00 AM",
  "show_recording": false,
  "show_fail_count": 0,
  "show_fail_reason": "",
  "show_recording_path": "/Volumes/Raid6/DVR Tests/show_file.m2ts"
}
```

### Save Triggers

**Config is saved when:**
```
1. Show added
2. Show edited
3. Recording starts/ends
4. Failures detected
5. User manually triggers save
6. Settings changed
7. App shutdown (gracefully)
```

### Load/Validate

**On app startup:**
```
1. Check file exists
2. Parse JSON (error if invalid)
3. Validate schema version
4. Check all required fields present
5. If validation fails: LOG ERROR, continue with empty
6. Load shows into memory
7. Recalculate show_next for all
```

---

## Transcode Profiles

### What is Transcoding?

Transcoding converts the video stream on the tuner before downloading:
- **Reduces file size** (important for disk space)
- **Formats for compatibility** (MPEG-2 → H.264)
- **Trades quality for space**

### Available Profiles

**Depends on tuner capability:**

**Check your tuner's transcoding support:**
```
http://hdhr-{device}.local:5004/tuners.json
// Look for: "InternalTranscodeSupported": true
```

**Common Profiles:**
```
none      = No transcoding (raw MPEG-2, ~10GB/hour)
h264      = H.264 codec (~3GB/hour)
h265      = H.265 codec (~1.5GB/hour)
```

### Setting Transcode in Config

**When adding a show:**
- If tuner supports transcoding, you'll be asked
- Option appears during "Add" workflow

**In config:**
```json
{
  "show_transcode": "h264"
}
```

**Check current setting:**
- Edit the show
- Transcode setting shown in logs
- Cannot change during edit (would need to re-add)

---

## Logging

### Log Location
```
~/Library/Logs/hdhr_VCR.log
```

### Log Levels

**Shown by default:**
- INFO - Normal operation
- WARN - Warnings (tuner issues, disk space, etc)
- ERROR - Problems that don't stop recording
- FATAL - App-level failures

**Debug levels (requires debug mode):**
- DEBUG - Detailed diagnostic info
- TRACE - Very verbose function tracing
- NEAT - Structured log output
- JSON - JSON-formatted API responses

### Reading Logs

**Tail live logs:**
```bash
tail -f ~/Library/Logs/hdhr_VCR.log
```

**Search for show:**
```bash
grep "Show Title" ~/Library/Logs/hdhr_VCR.log
```

**Filter by level:**
```bash
grep " ERROR " ~/Library/Logs/hdhr_VCR.log
```

**Format:**
```
MM.DD.YY HH.MM.SS APPNAME LEVEL HANDLER(CALLER) MESSAGE
04.14.26 21.30.06 hdhr_VCR INFO record_start(idle(9675)) Recording started
```

