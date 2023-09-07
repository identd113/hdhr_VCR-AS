## Changes since 20230319

Date:   Thu Sep 7 09:06:16 2023 -0500
    Fixed a bug when editing a manually added show
    Fixed issue when running curl2icon, with no specified URL path
    Cleaned up old code
    Beta: Added some code to re/encode show_id to be useful.  Not yet in place

Date:   Mon Sep 4 13:14:33 2023 -0500
    Fixed error in quit handler

Date:   Mon Sep 4 12:03:36 2023 -0500
    Change: broke out the run handler into multiple, to aid in allowing a config file reload in the future.
    New: If a show is recording, and we attempt to quit the script, we will will show a window, noting we are recording.  This caused an issue when halting a reboot or shutdown.  We can now see if the system is being restarted or shutdown, and skip asking the user.
    New: Added idle_uniq and run_uniq to better track loops.
    New: Added a way to dump detected tuners into the log
    Fix: If a show is recording, and that show has not been added, we now will log a line, and not error out.
    New: Added a few new log levels, to match those used with jlogger.
    New: Added a way to change the log level via setup()
    Fix: Changed =, < and > to words in script.

Date:   Mon Aug 14 02:05:59 2023 -0500    
    Logging Updates

Date:   Fri Aug 11 13:59:57 2023 -0500
    Add: Added unique value per idle loop, making logging a bit better.
    Fix: updated some log lines, to show caller
    Clean: removed redundant record_now option.
    Fix? Made is_sport work better, but still have an incorrect end time in the curl command
    Fix: Updated update_shows

Date:   Wed Aug 9 01:06:07 2023 -0500

    Change: Made it more clear in logs, if we had a mismatch on recording shows and tuners.
    Fix: Fixed error dialog when clicking "Run" when selecting a channel to record on.
    New: Added a record icon on channel list, if we are currently recording a show.
    Change: Removed vaild_channel_list from standard json refresh.  We now run this when the user clicks "Add..."

Date:   Sat Jul 8 12:39:12 2023 -0500    
    Added hostname to config file to allow better compatibility with iCloud syncing

Date:   Tue Jun 6 23:25:44 2023 -0500
    If a show is marked as recorded today, we will not show its "up next" icon, but a check mark
    Added end time to each show in main screen
    Reduced artificial delay when adding a show

Date:   Thu Jun 1 15:08:12 2023 -0500
    Fixed issue when recording transcoded shows
    Fixed issue when attempting to change show creation date
    Removed code we are not going to use

Date:   Fri May 26 09:54:58 2023 -0500
    Fix recording of shows with apostrophes

Date:   Sat May 20 11:19:58 2023 -0500
    Added logging options to setup()
    Added progress window during idle loop, when logging contains DEBUG
    Adding a new handler, with the goal of providing a showid, and getting a record back from the ps command

Date:   Fri May 19 20:41:31 2023 -0500
    broke some things out in separate handlers
    moved the initial run to open handoff, to occur at the end of the current idle loop
    added an additional parameter to record_now, which passes a value to update_shows
    moved some logging to DEBUG

Date:   Thu May 11 19:07:51 2023 -0500
    Added better logging
    removed un needed ismymod key
    handled error when the channel disappears better
    set a very noisy log line to debug
Date:   Wed May 10 01:17:45 2023 -0500
    always give the user sone folder
    removed outdated config loader

Date:   Wed May 10 00:40:44 2023 -0500    
    Added Warning_icon
    Added show_recording_path to show last path of file we recorded.  This could be a list?

Date:   Mon Mar 27 12:21:16 2023 -0500
    Update version.json
    
    New: Stops user if they are not in the en_US region
    New: Recorded today indication in show list
    New: Added appname to curl command
    New: If a show is recording, but the script does not have it marked, we will now mark
    New: Add show recorded today icon in show list.
    New: Added short delay to end of adding show, to confirm a show was added.
    New: Added is_sport, so we can track shows that are sports, and add more time to them.
    New: Added show_time_orig, so we do not "slide" into another timeslot.
    New: Added recording end time to curl request, as a header
    
    Debug: Added more feedback to log lines around isModifierKeyPressed
    Debug: Added more logging to hdhr_api
    Debug: Added more logging to save and read data
    Debug: Removed old unused code
    Debug: Changed global variables to start with a capital letter, for easier identification in the script
    Debug: Added some more logging around saving the config file
    Debug: Removed handler that functionality was duplicated
    
    Fix: Finally(?) fixed up next
    Fix: Script will now prompt, on launch, if the show directory is invalid.
    Fix: make deactivating, and reactivating shows easier
    this on startup
    Fix: show_time_org may have been bad
    Fix: If a user selects a location to save the shows in, but does not have permission, we will now have the user select a new folder
    Fix: Padded numbers less than 10 with a 0.
    Fix: Gave the user some options, if we cannot save the config file.
    Fix: make sure we do not display a up next message, when adding a show that records right away
