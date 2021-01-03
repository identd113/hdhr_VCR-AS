## hdhr_VCR
A pretty damn good VCR "plus" script that works on all HDHomeRun devices.
A faceless/background script that makes recording TV shows and Movies on HDHomeRun very easy.

#### Why?
I wanted to allow a quick way to record a TV show, without needing to setup a large system like Plex or HDHomeRuns' own DVR software.
I call it a VCR app, as while it does use guide data to pull name / season / episode number / episode name / show length, it does not present like a normal DVR.  It is more of a Smart VCR

#### Requirements
1. JSONHelper is required, available for free at https://apps.apple.com/us/app/json-helper-for-applescript/id453114608

#### Features
* Auto discovery of all HDHomeRun devices on your network
* Uses built-in guide data, to automatically name the shows you are recording. 
* * The free guide data is only for the next 4-6 hours. We will attempt to pull fresh data right before a show starts, so in most cases, the information does get pulled correctly. I believe if you pay for HDHomeRuns own DVR software, the guide data is much longer, and the script would handle that.
* Runs in the background, but allows easy editing of existing saved shows
*Add a show or series in 10 seconds.

#### Written in AppleScript. 
* This script uses the idle() handler, so the script itself uses almost no CPU.
* * The idle handler uses scheduling in the OS, rather than a lazy implementation with a repeat loop.
* * The idle handler is also very touchy.  You can break the idle "ticking" by having a script error occur.  This script uses logic to avoid errors occurring.
* The script uses many of handlers that may be useful to others.  These have been written in a manner that makes their use extremely easy to use in other scripts.
  
## Nitty gritty  
Uses records to store complex data sets. 

This is an example of a what data of a show recording contains:

```
(show_title:In Living Color, show_time:1, show_length:60, show_air_date:Saturday, show_transcode:None, show_temp_dir:alias Backups:, show_dir:alias Backups:, show_channel:5.1, show_active:true, show_id:17420a68e161e3def68e6111876f5dc6, show_recording:false, show_last:date Saturday, December 19, 2020 at 1:03:04 AM, show_next:date Saturday, December 19, 2020 at 1:00:00 AM, show_end:date Saturday, December 19, 2020 at 2:00:00 AM, notify_upnext_time:missing value, notify_recording_time:missing value, hdhr_record:1054271E,show_is_series:missing value)
```

Example of a tuner record:

```
(hdhr_lineup_update:Saturday, December 19, 2020 at 1:21:46 AM, hdhr_guide_update:Saturday, December 19, 2020 at 1:21:48 AM, discover_url:http://10.0.1.101/discover.json, lineup_url:http://10.0.1.101/lineup.json, device_id:1054271E, does_transcode:1, hdhr_lineup:missing value, hdhr_guide:missing value, hdhr_model:"HDTC-2US")
```

The hdhr_guide and hdhr_lineup contain the entire json result of the lineup, and guide data.  We use this as a cache, so we only make a "new" API call every 2 hours, or when a show starts recording.

## Special considerations
* The "heavy lifting" is done with curl, which downloads the data to a local drive.  The script manages the show and device logic.
* When the app is opened, you will be presented with options to add a show, edit a show, or run
* * If you choose "run", the UI will disappear, and we will run in the background. If you click the app again in the dock (a reopen event), you will be presented with the UI again.
*When you enter the time to start a recording, it is done a bit strangely. For example, if you wanted to record a show at 6:45 PM, you would enter 18.75.
* * We use 24 hour decimal time.  .5 of an hour, is 30 minutes.  .75 of an hour is 45 minutes.
* If you have a HDHomeRun Extend device, this will allow you to set a transcode level per show.  A future version will allow a default for all shows
* Uses caffeinate to kick off the recording
* * This prevents the device from going to sleep.
* If there are multiple HDHR device on the network, you will be asked which one you want to use.
* * I am trying to figure out how to make this better, but as is, asks.
* Heavily use notifications to pass along information to the user, as we run more or less faceless.  Future versions will allow you to specify you get a message such as:
* * Shows that are scheduled in the future "Up Next"
* * Starting recording
* * Recording in progress
* * End recording.
* * Tuner and Lineup updates (On launch, and every two hours.)
  
I want to make this better as well, but AppleScript has very limited ways to interact with the user.  Notifications make sense to me, as the app is faceless/background app

When adding channels, you are presented with a list of available channels, with station name, example:
```
  2.1 TPT2
  2.3 TPTLife
  ...
  ...
```

When adding a show, we will attempt to write a test file to that location (and remove it) right away, so we can get through any of the OS X disk access prompts.

I hope this can be collaborative project, so other options that you use can be added.


