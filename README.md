# hdhr_VCR
A pretty damn good VCR "plus" script that works on all HDHomeun devices.
A faceles 

Why?
I wanted to allow a quick way to record a TV show, without needing to setup a large system like Plex or HDHomeRuns own DVR software.
I call it a VCR app, as while it does use guide data to pull name / season / episode number / episode name / show length, it does not present like a normal DVR.  It is more of a Smart VCR

Requirements
1. Requires JSONHelper, avilable for free at https://apps.apple.com/us/app/json-helper-for-applescript/id453114608

Features
Support multipe tuners on the network!
Uses built-in guide data, to automatically name the shows you are recording. 
  The free guide data is only for the next 4-6 hours.  Special considerations have been made to allow you to add a recording outside of this time frame, and still end up with a correctly named file.

Written in AppleScript. This script uses the idle() handler, so the script itself uses almost no CPU.
  The "heavy lifting" is done with curl, which downloads the data to a local drive.  The script manages the show and device logic.

Special considerations
When the app is opened, you will be presented with options to add a show, edit a show, or run
  If you choose "run", the UI will disappear, and we will run in the background. If you click the app again in the dock (a reopen event), you will be presented with the UI again.
When you enter the time to start a recording, it is done a bit strangly. For example, if you wanted to record a show at 6:45 PM, you would enter 18.75.
  We use 24 hour decimel time.  .5 of an hour, is 30 minutes.  .75 of an hour is 45 minutes.
If you have a HDHomerun Extend device, this will allow you to set a transcode level per show.  A future version will allow a deatult for all shows
Uses caffentite to kick off the recording
  This prevents the device from going to sleep.
If there are multiple HDHR device on the network, you will be asked which one you want to use.
  I am trying ot figure out how to make this better, but as is, asks.
Heavily use notifications to pass along information to the user, as we run more or less faceless.  Future versions will allow you to specify you get a mesage such as:
  Shows that are scheduled in the future "Up Next"
  Starting recording
  Recording in progress
  End recording.
  Tuner and Lineup updates (On launch, and every two hours.)
  
  I want to make this better as well, but AppleScript has very limited ways to interact with the user.  Notifications make sense to me, as the app is faceless/background app
When adding channels, you are presented with a list of avilable channels, with station name, example:
  2.1 TPT2
  2.3 TPTLife
  ...
  ...
  
When adding a show, we will attempt ot write a test file to that location (and remove it) right away, so we can get through any of the OSX disk access prompts.

I hope this can be colabortive project, so other options that you use can be added.


