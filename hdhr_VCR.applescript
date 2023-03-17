
(*

Add indication if show_list data has been updatted, or if its the old show information
We need to be able to know how many total tuners we have.
 then run mytimeslot_build(num_of_tuners)
 We can start with marking the existing shows in showlist
--Added ability to fix invalid show directory on launch.

Fix issue where selecting  multipe shows may cause an issue with is_sport popup

Todo:
NEED option to quit after recording is complete. 
NEED Prompt user to update show with a valid tuner.
--add display on main screen to show next recording.  Check that time, and see if multiple shows are being recorded at the time. -Done
--This may just evolve into a futurerecording search, which we could use to not over book recording times. -In Progress
--rewrite next_show to be more like recording_now 

tell application "JSON Helper"  
	fetch JSON from "http://10.0.1.101/discover.json"
		--> {ModelNumber:"HDTC 2US", UpgradeAvailable:"20210624", BaseURL:"http://10.0.1.101:80", FirmwareVersion:"20210210", DeviceAuth:"nrwqkmEpZNhIzf539VfjHyYP", FirmwareName:"hdhomeruntc_atsc", FriendlyName:"HDHomeRun EXTEND", LineupURL:"http://10.0.1.101:80/lineup.json", TunerCount:2, DeviceID:"105404BE"}
end tell 
*)

--First variable sets capitalization  

--on recording_search(caller,start_time, end_time, hdhr_model)
--This would return the number of shows being recorded at the time 
--I can use JSONHelper to make a config file, but items need to be a number, a string, or a boolen.  We may need to stringify anything else, to get it to save, This is pretty consistant, but if we hit an error, we really blow up

(*
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see https://www.gnu.org/licenses/.
	
I hope this software can used as much as a teaching aid, as it can be for its primary function.
If you would like to contact me with questions about copyright, please file an issue at the github page
* https://github.com/identd113/hdhr_VCR-AS/issues
-identd113
*)

global Local_env
global Show_info
global Locale
global Channel_list
global HDHR_DEVICE_LIST
global Idle_timer
global Idle_timer_default
global Idle_count
global Version_local
global Version_remote
global Version_url
global Online_detected
global Hdhr_detected
global Hdhr_config
global Hdhr_setup_folder
global Notify_upnext
global Notify_recording
global Hdhr_setup_ran
global Configfilename
global Configfilename_json
global Logfilename
global Time_slide
global Dialog_timeout
global Temp_dir
global Config_dir
global Log_dir
global Idle_timer_dateobj
global Back_channel
global Config_version
--Icons
global Play_icon
global Record_icon
global Tv_icon
global Plus_icon
global Single_icon
global Series_icon
global Inactive_icon
global Edit_icon
global Soon_icon
global Disk_icon
global Update_icon
global Stop_icon
global Up_icon
global Up2_icon
global Check_icon
global Uncheck_icon
global Calendar_icon
global Calendar2_icon
global Hourglass_icon
global Film_icon
global Back_icon
global Done_icon
global Running_icon
global Add_icon
global Futureshow_icon
global Lf
global Logger_levels
global Loglines_written
global Loglines_max
global Missing_tuner_retry_count
global Timeslot
global Check_after_midnight_time

## Since we use JSON helper to do some of the work, we should declare it, so we dont end up having to use tell blocks everywhere.  If we declare 1 thing, we have to declare everything we are using.
use AppleScript version "2.4"
use scripting additions
use application "JSON Helper"
--use framework "Foundation" 

-- {hdhr_lineup_update:missing value, hdhr_guide_update:missing value, discover_url:"http://10.0.1.101/discover.json", lineup_url:"http://10.0.1.101/lineup.json", device_id:"XX105404BE", does_transcode:0, hdhr_lineup:missing value, hdhr_guide:missing value, hdhr_model:missing value}

-- show_info model: (*show_title:Happy_Holidays_America, show_time:16, show_length:60, show_air_date:Sunday, show_transcode:missing value, show_temp_dir:alias Backups:, show_dir:alias Backups:, show_channel:5.1, show_active:true, show_id:221fbe1126389e6af35f405aa681cf19, show_recording:false, show_last:date Sunday, December 13, 2020 at 4:04:54 PM, show_next:date Sunday, December 13, 2020 at 4:00:00 PM, show_end:date Sunday, December 13, 2020 at 5:00:00 PM, notify_upnext_time:missing value, notify_recording_time:missing value, hdhr_record:XX105404BE,show_is_series:false*

--	set progress description to "Loading ..."
--    set progress additional description to 
--	set progress completed steps to 0 
--	set progress total steps to 1 

##########    These are reserved handlers, we do specific things in them    ##########
on run {}
	set Local_env to (name of current application)
	set Lf to "
"
	--Icons! 
	set Play_icon to character id 9654
	set Record_icon to character id 128308
	set Tv_icon to character id 128250
	set Plus_icon to character id 10133
	set Single_icon to character id {49, 65039, 8419}
	set Series_icon to character id 128257
	set Inactive_icon to character id 9940
	set Edit_icon to character id {9999, 65039}
	set Soon_icon to character id 128284
	set Disk_icon to character id 128190
	set Update_icon to character id 127381
	set Stop_icon to character id 9209
	set Up_icon to character id 128316
	set Up2_icon to character id 9195
	set Check_icon to character id 9989
	set Uncheck_icon to character id 10060
	set Futureshow_icon to character id {9197, 65039}
	set Calendar_icon to character id 128197
	set Calendar2_icon to character id 128198
	set Hourglass_icon to character id 8987
	set Film_icon to character id 127910
	set Back_icon to character id 8592
	set Done_icon to character id 9989
	set Running_icon to character id {127939, 8205, 9794, 65039}
	set Add_icon to character id 127381
	
	set Version_local to "20230316"
	set Config_version to 1
	set progress description to "Loading " & name of me & " " & Version_local
	
	--set globals    
	set Show_info to {}
	set Hdhr_config to {}
	set Notify_upnext to 25
	set Notify_recording to 15.5
	set Locale to user locale of (system info)
	set Hdhr_setup_folder to "Volumes:"
	set Configfilename to (name of me) & ".config" as text
	set Configfilename_json to (name of me) & ".json" as text
	set Logfilename to (name of me) & ".log" as text
	--set quot to "\""
	set Time_slide to 0
	set Dialog_timeout to 60
	set Version_url to "https://raw.githubusercontent.com/identd113/hdhr_VCR-AS/master/version.json"
	set Version_remote to "0"
	set Idle_timer to 6
	set Idle_timer_default to 6
	set Idle_count to 0
	set Temp_dir to alias "Volumes:"
	set Config_dir to path to documents folder
	--set next_save_dt to ((current date) + (random number from 200 to 2000))
	set Online_detected to false
	set Hdhr_detected to false
	--logging    
	set Log_dir to alias ((path to library folder from user domain) & "Logs" as text)
	--set log_dir to path to documents folder
	if Local_env contains "Editor" then
		set Logger_levels to {"INFO", "WARN", "ERROR", "DEBUG"}
	else
		set Logger_levels to {"INFO", "WARN", "ERROR", "NEAT"}
	end if
	set Loglines_written to 0
	set Loglines_max to 100000 as text
	set Back_channel to missing value
	copy (current date) to Idle_timer_dateobj
	set Missing_tuner_retry_count to 0
	set Timeslot to {}
	--my timeslot_firstrun()
	my logger(true, "init", "INFO", "Started " & name of me & " " & Version_local)
	
	--
	-- Esnure that the cache folder for images is created 
	do shell script "mkdir -p ~/Library/Caches/" & (name of me) & "/"
	--	my curl2icon("test", "https://developer.apple.com/ios/images/screen-widget-large_2x.jpg")
	## Lets check for a new version! This will trigger OSX to prompt for confirmation to talk to JSONHelper, the library we use for JSOn related matters.
	my check_version()
	(*
	This really kicks us off.  The will query to see if there are any HDHomeRun devices on the local network.  This script support multiple devices.
	Once we find some devices, we will query them and pull there lineup data.  This tells us what channels belong to what tags, like "2.4 TPTN"
	We will then pull guide data.  It should be said here that this data is only given for 4 hours ahead of current time, some stations maybe 6.  Special considerations have been made in this script to make this work.  We call this handler and specify "run0".  This is just a made up string that we pass to the next handler, so we can see the request came in that broke the script.  This is commonly repeated in my scripts.
	*)
	
	if Locale is not "en_US" then
		display dialog "Due to poor planning, only en_US regions can use this script."
		quit {}
		return
	end if
	
	
	if Online_detected is true then
		my HDHRDeviceDiscovery("run1", "")
	else
		my logger(true, "init", "ERROR", "online_detected is " & Online_detected)
	end if
	
	## Restore any previous state 
	if Online_detected and Hdhr_detected is true then
		my read_data("run()")
		set Hdhr_config to {Notify_upnext:Notify_upnext, Notify_recording:Notify_recording, Hdhr_setup_folder:Hdhr_setup_folder, Config_version:Config_version}
	else
		my logger(true, "init", "ERROR", "hdhr_detected is " & Hdhr_detected)
	end if
	my showPathVerify("run()", "")
	## Dump all show info.  Onlt print when run in debug mode
	my show_info_dump("run3", "", false)
	## Adds X lines to length of log file.  We add 50 lines per show added
	set Loglines_max to Loglines_max + ((length of Show_info) * 100)
	my existing_shows("run()")
	--Test
	## Main is the start of the UI for the user. on main
	my main("run()", "run")
	
	## Make sure the log file doesnt get too big
	if Local_env does not contain "Editor" then
		my rotate_logs("run()", (Log_dir & Logfilename as text))
	end if
end run

## This script will loop through this every 12 seconds, or whatever the return value is, in second is at the bottom of this handler.
on idle
	## We manually called idle() handler before popping any notification windows.  This allows us to start a show that may already be started when openong the app.
	--This should give us an approximate time in seconds the script was launched. 
	if (current date) is greater than Idle_timer_dateobj then
		set Idle_timer to Idle_timer_default
		--my logger(true, "idle(1)", "DEBUG", "idle_timer set to " & Idle_timer_default)
		set Idle_timer_dateobj to current date
	end if
	
	try
		set Idle_count to Idle_count + Idle_timer
		--my logger(true, "idle(1.5)", "DEBUG", "Idle seconds: " & Idle_count)
		copy (current date) to cd
		copy cd + (Idle_timer + 2) to cd_object
		--my logger(true, "idle(2)", "DEBUG", "" & cd)
		--my logger(true, "idle(3)", "DEBUG", "" & cd_object)
		--Re run auto discover every 1 hour, or once we flip past midnight  
		try
			if length of HDHR_DEVICE_LIST is greater than 0 then
				repeat with i2 from 1 to length of HDHR_DEVICE_LIST
					
					if hdhr_guide_update of item i2 of HDHR_DEVICE_LIST is not missing value then
						--log "hdhr_guide_update of item i2 of HDHR_DEVICE_LIST: " & hdhr_guide_update of item i2 of HDHR_DEVICE_LIST
						--log "hdhr_guide_update of item i2 of HDHR_DEVICE: " & item i2 of HDHR_DEVICE_LIST
						if minutes of (cd) is in {15, 45} and ((cd) - (hdhr_guide_update of item i2 of HDHR_DEVICE_LIST)) div 60 is greater than or equal to 15 then
							--if ((cd_object) - (hdhr_guide_update of item i2 of HDHR_DEVICE_LIST)) div 60 is greater than or equal to 60 or date string of (hdhr_guide_update of item i2 of HDHR_DEVICE_LIST) is not date string of (current date) then
							my logger(true, "idle(4)", "INFO", "Periodic update of tuners")
							
							try
								with timeout of 15 seconds
									my HDHRDeviceDiscovery("idle(5)", "")
								end timeout
								my save_data("PostHDHRDeviceDiscovery")
							on error errnum
								--FIX we fail here after awhile, maybe midnight switchover?, likely config file save related
								my logger(true, "idle(6)", "ERROR", "Unable to update HDHRDeviceDiscovery " & errnum)
							end try
							
							my logger(true, "idle(7)", "INFO", "Quarter hour update of tuners complete")
						end if
					end if
				end repeat
			else
				try
					my logger(true, "idle(91)", "WARN", "No HDHR Device Detected")
					my HDHRDeviceDiscovery("idle(5-1)", "")
				end try
			end if
		on error errmsg
			my logger(true, "idle(8)", "ERROR", "An error occured: " & errmsg as text)
		end try
		## If there are any shows to saved, we start working through them
		try
			if length of Show_info is greater than 0 then
				repeat with i from 1 to length of Show_info
					repeat 1 times
						(*
						else if show_is_series of item i of show_info = false then
				if show_end of item i of show_info < (current date) then
					display notification "TEST" 
				end if 
				display dialog show_end of item i of show_info
				display notification "Can we delete " & show_title of item i of show_info
			else
				display notification "show_rec1: " & class of (show_recording of item i of show_info)
				display notification "show_rec2: " & (show_recording of item i of show_info)
				display notification "show_end1:" & class of (show_end of item i of show_info)
				display notification "show_end2:" & (show_end of item i of show_info)
				display notification "is_series1:" & class of (show_is_series of item i of show_info)
				display notification "is_series2:" & (show_is_series of item i of show_info)
			*)
						#	try
						#		if my recorded_today(show_id of item i of show_info) = true then
						#			my logger(true, "idle()", "INFO", show_title of item i of show_info & " was recorded today")
						#		end if
						#	on error
						#		my logger(true, "idle()", "ERROR", "Error in recorded_today")
						#	end try
						
						if show_active of item i of Show_info is true then
							
							if show_next of item i of Show_info is less than or equal to cd_object then
								--if show_next of item i of show_info < cd_object then
								--my logger(true, "idle()", "INFO", "0-0") 
								-- If if a show references a HDHR device that cannot be found, retry here.
								--  We rety al the time here, we need to short circuit this after trying a few times.
								if show_recording of item i of Show_info is false then
									if my HDHRDeviceSearch("idle()", hdhr_record of item i of Show_info) is 0 then
										--We could walk the user through reassigning a tuner.										
										if Missing_tuner_retry_count is less than 3 then
											my logger(true, "idle(8-1)", "WARN", "The tuner, " & hdhr_record of item i of Show_info & ", does not exist, refreshing tuners")
											my HDHRDeviceDiscovery("idle(8-2)", "")
											set Missing_tuner_retry_count to Missing_tuner_retry_count + 1
											-- FIX Add option to reassign tuner
										end if
										exit repeat
									end if
									
									if show_end of item i of Show_info is less than (cd) then
										my logger(true, "idle(9)", "INFO", show_title of item i of Show_info & " ends at " & show_end of item i of Show_info)
										if show_is_series of item i of Show_info is true then
											set show_next of item i of Show_info to my nextday("idle(10)", show_id of item i of Show_info)
											my logger(true, "idle(9-1)", "WARN", show_title of item i of Show_info & " is a series, but passed")
											exit repeat
										else
											set show_active of item i of Show_info to false
											my logger(true, "idle(9-2)", "WARN", show_title of item i of Show_info & " is a single, and passed, so it was deactivated")
											exit repeat
										end if
									end if
									
									--	my logger(true, "idle()", "INFO", "1-1")  
									
									
									--Make sure if we are start early, we dont end early.  This causes us to call the tuner status API every 8 seconds.  Since this call is hosted locally, I suspect there is not APi limit set, as the APi is returning cached data from silicondust
									set show_runtime to (show_end of item i of Show_info) - (cd)
									
									
									--NEW
									if show_is_sport of item i of Show_info is true then
										try
											my logger(true, "idle901()", "INFO", "Setting show run time to an additional 30 minutes")
											set show_runtime to show_runtime + 1800
											
											--NEW Line below should fix issue where a sport show continues recording past old end time, but it doesnt show up on the overview
											set show_end of item i of Show_info to (show_end of item i of Show_info) + 1800
										on error errmsg
											my logger(true, "idle684()", "ERROR", "Unable to extend record time: " & errmsg)
										end try
									end if
									
									set tuner_status_result to my tuner_status2("idle(15)", hdhr_record of item i of Show_info)
									--my logger(true, "idle()", "INFO", "2-1")
									if tunermax of tuner_status_result is greater than tuneractive of tuner_status_result then
										--my logger(true, "idle()", "INFO", "2-2")
										-- If we now have no tuner available, we skip this "loop" and try again later.
										my logger(true, "idle()", "DEBUG", show_title of item i of Show_info)
										my logger(true, "idle()", "DEBUG", show_next of item i of Show_info)
										my logger(true, "idle()", "DEBUG", show_time of item i of Show_info)
										my logger(true, "idle()", "DEBUG", show_end of item i of Show_info)
										--on showid2PID(caller, show_id, kill_pid, logging)
										if item 2 of my showid2PID("idle155", show_id of item i of Show_info, false, true) is {} then
											--if my existing_recordings("idle155", show_id of item i of show_info) = false then --new 
											my record_now("idle(32)", (show_id of item i of Show_info), show_runtime)
											display notification "Ends " & my short_date("rec started", show_end of item i of Show_info, false, false) with title Record_icon & " Started Recording on (" & hdhr_record of item i of Show_info & ")" subtitle quote & show_title of item i of Show_info & quote & " on " & show_channel of item i of Show_info & " (" & my channel2name("idle(16)", show_channel of item i of Show_info as text, hdhr_record of item i of Show_info) & ")"
											set notify_recording_time of item i of Show_info to (cd) + (2 * minutes)
											my logger(true, "idle(17)", "INFO", "Started recording " & quote & show_title of item i of Show_info & quote & " until " & show_end of item i of Show_info & " on channel " & show_channel of item i of Show_info & " using " & hdhr_record of item i of Show_info)
											--display notification show_title of item i of show_info & " on channel " & show_channel of item i of show_info & " started for " & show_runtime of item i of show_info & " minutes."
										else
											my logger(true, "idle(156)", "WARN", "Recording already in progeress, marking " & show_id of item i of Show_info & " as recording")
											set show_recording of item i of Show_info to true
										end if
									else
										display notification Hourglass_icon & " Delaying for " & Idle_timer & " seconds" with title "Tuner unavailable (" & hdhr_record of item i of Show_info & ")" subtitle show_title of item i of Show_info
									end if
									
									--	my logger(true, "idle()", "INFO", "4") 
									
									--NEW 
									(*
									try
										if (notify_upnext_time of item i of show_info is less than (cd) or notify_upnext_time of item i of show_info is missing value) then
											my logger(true, "up_next(1)", "INFO", "1-true")
										else
											my logger(true, "up_next(1)", "INFO", "1-false")
										end if
										if (show_next of item i of show_info) - (cd) is less than or equal to 1 * hours then
											my logger(true, "up_next(1)", "INFO", "2-true")
										else
											my logger(true, "up_next(1)", "INFO", "2-false")
										end if
										if show_recording of item i of show_info = false then
											my logger(true, "up_next(1)", "INFO", "3-true")
										else
											my logger(true, "up_next(1)", "INFO", "3-false")
										end if
									on error errmsg
										my logger(true, "up_next(1)", "WARN", "up_next_info, errmsg: " & errmsg)
									end try
									*)
									
								else --show_recording true 
									--display notification show_title of item i of show_info & " is recording until " & my short_date("recording", show_end of item i of show_info)
									if (show_end of item i of Show_info) - (current date) is less than or equal to Idle_timer * 2 then
										--Fix, we should figure out how to remove this, only reference
										my temp_auto_delay("idle(18)", 1)
									end if
									if notify_recording_time of item i of Show_info is less than (cd) or notify_recording_time of item i of Show_info is missing value then
										display notification "Ends " & my short_date("rec progress", show_end of item i of Show_info, false, false) & " (" & (my ms2time("idle(19)", (show_end of item i of Show_info) - (cd), "s", 3)) & ") " with title Record_icon & " Recording in progress (" & hdhr_record of item i of Show_info & ")" subtitle quote & show_title of item i of Show_info & quote & " on " & show_channel of item i of Show_info & " (" & my channel2name("idle(20)", show_channel of item i of Show_info as text, hdhr_record of item i of Show_info) & ")"
										
										-- display notification "Ends " & my short_date("rec progress", show_end of item i of show_info, false, false) & " (" & (my sec_to_time_OLD((show_end of item i of show_info) - (current date))) & ") " with title record_icon & " Recording in progress on (" & hdhr_record of item i of show_info & ")" subtitle show_title of item i of show_info & " on " & show_channel of item i of show_info & " (" & my channel2name(show_channel of item i of show_info as text, hdhr_record of item i of show_info) & ")"
										--try to refresh the file, so it shows it refreshes finder.
										my logger(true, "idle(21)", "INFO", "Recording in progress for " & quote & (show_title of item i of Show_info & quote & " on " & show_channel of item i of Show_info))
										--my update_folder("idle(22)", show_dir of item i of show_info)
										set notify_recording_time of item i of Show_info to (current date) + (Notify_recording * minutes)
									end if
									set check_showid_recording to item 2 of my showid2PID("idle(check_showid_recording)", show_id of item i of Show_info, false, false)
									
									--NEW FIX 
									if length of check_showid_recording is 0 then
										my logger(true, "idle(21)", "WARN", quote & show_id of item i of Show_info & quote & " is marked as recording, but we do not have a valid PID, setting show_recording to false")
										set show_recording of item i of Show_info to false
									end if
								end if
							else
								--show time has not passed.
								if (notify_upnext_time of item i of Show_info is less than (cd) or notify_upnext_time of item i of Show_info is missing value) and (show_next of item i of Show_info) - (cd) is less than or equal to 1 * hours and show_recording of item i of Show_info = false then
									--my logger(true, "idle()", "INFO", "1-2")
									display notification "Starts: " & my short_date("idle(11)", show_next of item i of Show_info, false, false) & " (" & my ms2time("idle(12)", ((show_next of item i of Show_info) - (cd)), "s", 3) & ")" with title Film_icon & " Next Up on (" & hdhr_record of item i of Show_info & ")" subtitle quote & show_title of item i of Show_info & quote & " on " & show_channel of item i of Show_info & " (" & my channel2name("idle(13)", show_channel of item i of Show_info, hdhr_record of item i of Show_info) & ")"
									
									--display notification "Starts: " & my short_date("is_next", show_next of item i of show_info, false, false) & " (" & my sec_to_time(((show_next of item i of show_info) - (current date))) & ")" with title film_icon & " Next Up on (" & hdhr_record of item i of show_info & ")" subtitle show_title of item i of show_info & " on " & show_channel of item i of show_info & " (" & my channel2name(show_channel of item i of show_info, hdhr_record of item i of show_info) & ")"
									my logger(true, "idle(14)", "INFO", "Next Up: " & quote & show_title of item i of Show_info & quote & " on " & hdhr_record of item i of Show_info)
									set notify_upnext_time of item i of Show_info to (cd) + (Notify_upnext * minutes)
								end if
							end if
						end if
						
						if show_recording of item i of Show_info is true then
							my logger(true, "idle()", "DEBUG", "Show end for " & show_title of item i of Show_info & " is " & show_end of item i of Show_info)
							my logger(true, "idle()", "DEBUG", cd)
							if (show_end of item i of Show_info) is less than or equal to (cd) then
								--my logger(true, "idle()", "INFO", "Recording Ended for " & quote & show_title of item i of show_info & quote)
								set show_last of item i of Show_info to show_end of item i of Show_info
								--set show_next of item i of show_info to my nextday(show_id of item i of show_info)
								set show_recording of item i of Show_info to false
								
								--FIX We can try setting the files date modified to the orginal air date.
								--log my channel_guide("TEST", "105404BE", "4.1", "0")
								-- We dont always get a result.  I was going to use this to determine if the show is a repeat.
								set temp_guide_data to my channel_guide("idle(23 recording_ended)", hdhr_record of item i of Show_info, show_channel of item i of Show_info, show_time of item i of Show_info)
								
								try
									set temp_test to my getTfromN(OriginalAirdate of temp_guide_data)
								on error
									set temp_test to "Failed"
								end try
								my logger(true, "idle(24.5)", "INFO", "OriginalAirdate of " & quote & show_title of item i of Show_info & quote & " " & temp_test)
								
								if show_is_series of item i of Show_info is true then
									set show_next of item i of Show_info to my nextday("idle(24)", show_id of item i of Show_info)
									set show_recorded_today of item i of Show_info to true
									my logger(true, "idle(25)", "INFO", "Recording Complete for " & quote & (show_title of item i of Show_info & quote & " on " & show_channel of item i of Show_info))
									display notification "Next Showing: " & my short_date("idle(26)", show_next of item i of Show_info, false, false) with title Stop_icon & " Recording Complete" subtitle (quote & show_title of item i of Show_info & quote & " on " & show_channel of item i of Show_info & " (" & my channel2name("idle(27)", show_channel of item i of Show_info as text, hdhr_record of item i of Show_info) & ")")
								else
									set show_active of item i of Show_info to false
									my logger(true, "idle(28)", "INFO", "Recording Complete for " & quote & (show_title of item i of Show_info & quote & " on " & show_channel of item i of Show_info & " and marked inactive"))
									display notification "Show marked inactive" with title Stop_icon & " Recording Complete" subtitle (quote & show_title of item i of Show_info & quote & " on " & show_channel of item i of Show_info & " (" & my channel2name("idle(27)", show_channel of item i of Show_info as text, hdhr_record of item i of Show_info) & ")")
								end if
								try
									if show_time_orig of item i of Show_info is not in {missing value, "missing value"} and show_time of item i of Show_info is not show_time_orig of item i of Show_info then
										set show_time of item i of Show_info to show_time_orig of item i of Show_info
										my logger(true, "idle(28.1)", "INFO", "Show " & show_title of item i of Show_info & " reverted to " & show_time_orig of item i of Show_info)
									end if
								on error errmsg
									my logger(true, "idle(28.2)", "WARN", "Show " & show_title of item i of Show_info & " unable to revert to show_time_orig, err: " & errmsg)
								end try
							end if
						else if show_is_series of item i of Show_info is false and show_end of item i of Show_info is less than or equal to (cd) and show_active of item i of Show_info is true then
							set show_active of item i of Show_info to false
							my logger(true, "idle(29)", "INFO", "Show " & show_title of item i of Show_info & " was deactivated, as it is a single, and record time has passed")
							display notification show_title of item i of Show_info & " removed" with title Stop_icon
						end if
					end repeat
				end repeat
			else
				my logger(true, "idle(30)", "WARN", "There are no shows setup for recording.  If you are seeing this message, and wondering if the script is actually working, it is")
				--We set the idle loop to longer, as there is nothing to do
				set Idle_timer to 30
			end if
		on error errmsg
			my logger(true, "idle(31-1)", "ERROR", errmsg)
		end try
		--FIX We can likely remove this, we will just save after the periodic tuner update
		(*
		if next_save_dt is less than (cd) then
			--my logger(true, "idle()", "INFO", "Periodic Save")
			my save_data("PeriodicSave")
			set next_save_dt to ((cd) + (random number from 200 to 2000))
		end if
		*)
	on error errmsg
		my logger(true, "idle(31)", "ERROR", errmsg)
	end try
	if check_after_midnight("idle()") = true then
		repeat with i from 1 to length of Show_info
			set show_recorded_today of item i of Show_info to false
		end repeat
	end if
	
	return Idle_timer
end idle

on temp_auto_delay(caller, thesec)
	set Idle_timer to thesec
	copy ((current date) + thesec) to Idle_timer_dateobj
	my logger(true, "temp_auto_delay(" & caller & ")", "DEBUG", "idle_timer set to " & thesec)
end temp_auto_delay

## This fires when you click the script in the dock.
on reopen {}
	set progress description to name of me & " " & Version_local
	set progress additional description to "Loading Main"
	my logger(true, "reopen()", "INFO", "User clicked in Dock")
	my main("reopen", "reopen()")
end reopen

## Runs when the user attempts to quit the script. 

on quit {}
	my logger(true, "quit()", "INFO", "quit() called.  We have written " & Loglines_written & " lines")
	
	--add check to see if we are recording.  
	set hdhr_quit_record to false
	set hdhr_quit_record_titles to {}
	repeat with i from 1 to length of Show_info
		if show_recording of item i of Show_info is true then
			set hdhr_quit_record to true
			set end of hdhr_quit_record_titles to quote & show_title of item i of Show_info & quote & " on " & show_channel of item i of Show_info
		end if
	end repeat
	if hdhr_quit_record is true then
		my logger(true, "quit()", "INFO", "The following shows are marked as currently recording: " & my listtostring("quit()", hdhr_quit_record_titles, ","))
		-- FIX We need to time out after some time, so if we handle restarts and shutdowns better (while recording)
		set quit_response to button returned of (display dialog "Do you want to cancel these recordings already in progress?" & return & return & my listtostring("quit()", hdhr_quit_record_titles, return) buttons {"Go Back", "Yes", "No"} default button 3 with title my check_version_dialog() giving up after Dialog_timeout with icon caution)
		my logger(true, "quit()", "INFO", "quit() user choice for killing shows: " & quit_response)
	else
		my save_data("quit(noshows)")
		continue quit
	end if
	
	if quit_response is "Yes" then
		
		repeat with i2 from 1 to length of Show_info
			if show_recording of item i2 of Show_info is true then
				set show_recording of item i2 of Show_info to false
				set quit_kill to my showid2PID("quit()", show_id of item i2 of Show_info, true, true)
			end if
		end repeat
		my logger(true, "quit(yes)", "WARN", "start save_data")
		my save_data("quit(yes)")
		my logger(true, "quit(yes)", "WARN", "end save_data")
		continue quit
	end if
	
	if quit_response is "No" then
		my logger(true, "quit(no)", "WARN", "start save_data")
		my save_data("quit(no)")
		my logger(true, "quit(no)", "WARN", "end save_data")
		continue quit
	end if
	
	if quit_response is "Go Back" then
		my main("quit", "quit(home)")
		return
	end if
	
end quit

##########    END of reserved handlers    ##########

##########    These are custom handlers.  These are the heart of the script.    ##########


on hdhrGRID(caller, hdhr_device, hdhr_channel)
	--log "hdhrgrid: " & hdhr_channel
	my logger(true, "hdhrGRID(" & caller & ", " & hdhr_device & ", " & hdhr_channel & ")", "INFO", "Started hdhrGRID")
	set hdhrGRID_sort to {Back_icon & " Back"}
	set hdhrGRID_temp to my channel_guide("hdhrGRID0", hdhr_device, hdhr_channel, "")
	if hdhrGRID_temp is false then
		display notification with title "Channel " & hdhr_channel & " has no guide data" subtitle hdhr_device
		return false
	end if
	try
		my logger(true, "hdhrGRID()", "INFO", "Shows returned: " & length of Guide of hdhrGRID_temp & ", channel: " & hdhr_channel & ", hdhr_device: " & hdhr_device)
	on error
		my logger(true, "hdhrGRID()", "ERROR", "Unable to get a length of hdhrGRID_temp")
	end try
	
	repeat with i from 1 to length of Guide of hdhrGRID_temp
		try
			set temp_title to (title of item i of Guide of hdhrGRID_temp & " " & quote & EpisodeTitle of item i of Guide of hdhrGRID_temp) & quote
		on error
			set temp_title to (title of item i of Guide of hdhrGRID_temp)
		end try
		set end of hdhrGRID_sort to (word 2 of my short_date("hdhrGRID1", my epoch2datetime("hdhrGRID(" & caller & ")", my getTfromN(StartTime of item i of Guide of hdhrGRID_temp)), false, false) & "-" & word 2 of my short_date("hdhrGRID2", my epoch2datetime("hdhr_grid(1)", my getTfromN(EndTime of item i of Guide of hdhrGRID_temp)), false, false) & " " & temp_title)
	end repeat
	set hdhrGRID_selected to choose from list hdhrGRID_sort with prompt "Channel " & hdhr_channel & " (" & GuideName of hdhrGRID_temp & ")" cancel button name "Manual Add" OK button name "Next.." with title my check_version_dialog() default items item 1 of hdhrGRID_sort with multiple selections allowed
	
	--log "hdhrGRID_selected: " & hdhrGRID_selected
	try
		if Back_icon & " Back" is in hdhrGRID_selected then
			my logger(true, "hdhrGRID(" & caller & ")", "INFO", "Back to channel list " & hdhr_channel)
			set Back_channel to hdhr_channel
			return true
		end if
	end try
	--fix If we select multiple shows, we miss this check.  Since we refresh the guide data on the hour, this may not even matter anymore, and we may need to remove it.
	if my epoch2datetime("hdhrGRID(2)", EndTime of item ((my list_position("hdhrGRID1", hdhrGRID_selected, hdhrGRID_sort, false)) - 1) of Guide of hdhrGRID_temp) is less than (current date) then
		my logger(true, "hdhrGRID()", "WARN", "The show time has already passed, returning...")
		display notification "The show has already passed, returning..."
		my HDHRDeviceDiscovery("hdhrGRID", hdhr_device)
		return true
	end if
	if hdhrGRID_selected is not false then
		set list_position_response to {}
		my logger(true, "hdhrGRID(" & caller & ")", "INFO", "Returning guide data for " & hdhr_channel & " on device " & hdhr_device)
		repeat with i from 1 to length of hdhrGRID_selected
			set end of list_position_response to item ((my list_position("hdhrGRID1", item i of hdhrGRID_selected, hdhrGRID_sort, false)) - 1) of Guide of hdhrGRID_temp
			--my logger(true, "hdhrGRID()", "INFO", list_position_response)
		end repeat
		return list_position_response
	else
		my logger(true, "hdhrGRID(" & caller & ")", "INFO", "User exited")
		return {""}
	end if
	
	(*
		if hdhrGRID_selected is not false then
		my logger(true, "hdhrGRID()", "INFO", "Returning guide data for " & hdhr_channel & " on device " & hdhr_device & " from " & caller)
		set list_position_response to item ((my list_position("hdhrGRID1", hdhrGRID_selected, hdhrGRID_sort, false)) - 1) of Guide of hdhrGRID_temp
		--my logger(true, "hdhrGRID()", "INFO", list_position_response)
		return list_position_response
	else
		my logger(true, "hdhrGRID()", "INFO", "User exited" & " from " & caller)
		return false
	end if
	*)
	return false
end hdhrGRID
--return {} --means we want to manually add a show
--return true means we want to go back
--return false means we cancelled out.
--return anything else, and this is the guide data for the channel they are requesting.

on hdhr_quality()
end hdhr_quality

on tuner_overview(caller)
	my logger(true, "tuner_overview(" & caller & ")", "INFO", "START Called")
	--We want to return the tuner names, the number of tuners/in use.  We might as well try to return any shows that are recording
	--display dialog length of HDHR_DEVICE_LIST 
	my tuner_mismatch("tuner_overview(" & caller & ")", "")
	set main_tuners_list to {}
	repeat with i from 1 to length of HDHR_DEVICE_LIST
		set tuner_status2_result to my tuner_status2("tuner_overview(" & caller & ")", device_id of item i of HDHR_DEVICE_LIST)
		if hdhr_model of item i of HDHR_DEVICE_LIST is not missing value then
			set end of main_tuners_list to (hdhr_model of item i of HDHR_DEVICE_LIST & " " & (device_id of item i of HDHR_DEVICE_LIST) & " " & tuneractive of tuner_status2_result & " of " & tunermax of tuner_status2_result & " in use") as text
		else
			set end of main_tuners_list to (device_id of item i of HDHR_DEVICE_LIST & " " & tuneractive of tuner_status2_result & " of " & tunermax of tuner_status2_result & " in use") as text
		end if
	end repeat
	my logger(true, "tuner_overview(" & caller & ")", "INFO", "END Called")
	return main_tuners_list
end tuner_overview

(*
on setDockBadgeString(dockBadgeString)
	set appDockTile to current application's NSApp's dockTile()
	appDockTile's setBadgeLabel:dockBadgeString
end setDockBadgeString
*)
on tuner_end(caller, hdhr_model)
	--Returns the number of seconds to next tuner timeout. 
	set temp to {}
	set lowest_number to 99999999
	if length of Show_info is greater than 0 then
		repeat with i from 1 to length of Show_info
			if show_recording of item i of Show_info is true and hdhr_record of item i of Show_info is hdhr_model then
				set end of temp to ((show_end of item i of Show_info) - (current date))
			end if
		end repeat
		if length of temp is greater than 0 then
			repeat with i2 from 1 to length of temp
				if item i2 of temp is less than lowest_number and item i2 of temp is greater than 0 then
					set lowest_number to item i2 of temp
				end if
			end repeat
		end if
		my logger(true, "tuner_end(" & caller & ")", "INFO", "Next tuner timeout for " & hdhr_model & " estimate (sec): " & lowest_number)
		return lowest_number
	end if
	return 0
end tuner_end

on tuner_status2(caller, device_id)
	--This needs to report back the number of tuners available, and the number in use.
	set tuneractive to 0
	set tuner_offset to my HDHRDeviceSearch("tuner_status2(" & caller & ")", device_id)
	if tuner_offset is 0 then
		my logger(true, "tuner_status2(" & caller & ")", "ERROR", "Tuner " & device_id & " is invalid")
		return {tunermax:0, tuneractive:0}
	end if
	try
		with timeout of 6 seconds
			set hdhr_discover_temp to my hdhr_api("tuner_status2(" & caller & ")", statusURL of item tuner_offset of HDHR_DEVICE_LIST, "", "", "")
		end timeout
	on error
		set hdhr_discover_temp to ""
		return false
	end try
	if hdhr_discover_temp is not "" then
		set tunermax to length of hdhr_discover_temp
		repeat with i from 1 to tunermax
			try
				set temp to SymbolQualityPercent of item i of hdhr_discover_temp
				--log "SymbolQualityPercent"
				--log temp
				set tuneractive to tuneractive + 1
			end try
		end repeat
		my logger(true, "tuner_status2(" & caller & ")", "INFO", device_id & " tunermax:" & tunermax & ", tuneractive:" & tuneractive)
		return {tunermax:tunermax, tuneractive:tuneractive}
	else
		my logger(true, "tuner_status2(" & caller & ")", "WARN", "Did not get a result from " & statusURL of item tuner_offset of HDHR_DEVICE_LIST)
		return {tunermax:0, tuneractive:0}
	end if
end tuner_status2

on tuner_mismatch(caller, device_id)
	my logger(true, "tuner_mismatch(" & caller & ")", "INFO", "Called: " & device_id)
	
	if device_id is "" and length of HDHR_DEVICE_LIST is greater than 0 then
		repeat with i2 from 1 to length of HDHR_DEVICE_LIST
			my tuner_mismatch("tuner_mismatch1(" & caller & ")", device_id of item i2 of HDHR_DEVICE_LIST)
		end repeat
		return
	end if
	
	set tuner_offset to my HDHRDeviceSearch("tuner_mismatch(" & caller & ")", device_id)
	--fix tuner_statuis doesnt take "" as a argument
	set tuner_status2_result to my tuner_status2("tuner_mismatch(" & caller & ")", device_id)
	set temp_shows_recording to 0
	repeat with i from 1 to length of Show_info
		if hdhr_record of item i of Show_info is device_id and show_recording of item i of Show_info is true then
			set temp_shows_recording to temp_shows_recording + 1
		end if
	end repeat
	if temp_shows_recording is not tuneractive of tuner_status2_result then
		--FIX We seem to be reporting this often.
		my logger(true, "tuner_mismatch(" & caller & ")", "WARN", "The number of available tuners on " & device_id & " is not consistent with our current state.  This may occur if a tuner is used outside of this application.  This is just a warning, and we will work as expected")
	else if temp_shows_recording is greater than tuneractive of tuner_status2_result then
		my logger(true, "tuner_mismatch(" & caller & ")", "WARN", "We are marked as having more shows recording then tuners")
	else if temp_shows_recording is less than tuneractive of tuner_status2_result then
		my logger(true, "tuner_mismatch(" & caller & ")", "WARN", "There are more tuners in use then we are using.  Either an error occured when starting a recording, or a tuner is being used outside of this program")
	else if temp_shows_recording is tuneractive of tuner_status2_result then
		my logger(true, "tuner_mismatch(" & caller & ")", "DEBUG", "We match")
	else
		my logger(true, "tuner_mismatch(" & caller & ")", "WARN", "TRACK USE CASE")
	end if
	my logger(true, "tuner_mismatch(" & caller & ")", "INFO", "Expected: " & temp_shows_recording & ", Actual: " & tuneractive of tuner_status2_result)
end tuner_mismatch

on show_info_dump(caller, show_id_lookup, userdisplay)
	--  (*show_title:Happy_Holidays_America, show_time:16, show_length:60, show_air_date:Sunday, show_transcode:missing value, show_temp_dir:alias Backups:, show_dir:alias Backups:, show_channel:5.1, show_active:true, show_id:221fbe1126389e6af35f405aa681cf19, #show_recording:false, show_last:date Sunday, December 13, 2020 at 4:04:54 PM, show_next:date Sunday, December 13, 2020 at 4:00:00 PM, show_end:date Sunday, December 13, 2020 at 5:00:00 PM, notify_upnext_time:missing value, #notify_recording_time:missing value, hdhr_record:XX105404BE,show_is_series:false*
	repeat with i from 1 to length of Show_info
		if Local_env does not contain "Editor" or userdisplay is false then
			my logger(true, "show_info_dump(" & caller & ", " & show_id_lookup & ")", "DEBUG", "show " & i & ", show_title: " & show_title of item i of Show_info & ", show_time: " & show_time of item i of Show_info & ", show_length: " & show_length of item i of Show_info & ", show_air_date: " & show_air_date of item i of Show_info & ", show_transcode: " & show_transcode of item i of Show_info & ", show_temp_dir: " & show_temp_dir of item i of Show_info & ", show_dir: " & show_dir of item i of Show_info & ", show_channel: " & show_channel of item i of Show_info & ", show_active: " & show_active of item i of Show_info & ", show_id: " & show_id of item i of Show_info & ", show_recording: " & show_recording of item i of Show_info & ", show_last: " & show_last of item i of Show_info & ", show_next: " & show_next of item i of Show_info & ", show_end: " & notify_upnext_time of item i of Show_info & ", notify_recording_time: " & notify_recording_time of item i of Show_info & ", hdhr_record: " & hdhr_record of item i of Show_info & ", show_is_series: " & show_is_series of item i of Show_info)
		else
			display dialog return & "show_title: " & show_title of item i of Show_info & return & "show_time: " & show_time of item i of Show_info & return & "show_length: " & show_length of item i of Show_info & return & "show_air_date: " & show_air_date of item i of Show_info & return & "show_transcode: " & show_transcode of item i of Show_info & return & "show_temp_dir: " & show_temp_dir of item i of Show_info & return & "show_dir: " & show_dir of item i of Show_info & return & "show_channel: " & show_channel of item i of Show_info & return & "show_active: " & show_active of item i of Show_info & return & "show_id: " & show_id of item i of Show_info & return & "show_recording: " & show_recording of item i of Show_info & return & "show_last: " & show_last of item i of Show_info & return & "show_next: " & show_next of item i of Show_info & return & "show_end: " & notify_upnext_time of item i of Show_info & return & "notify_recording_time: " & notify_recording_time of item i of Show_info & return & "hdhr_record: " & hdhr_record of item i of Show_info & return & "show_is_series: " & show_is_series of item i of Show_info giving up after Dialog_timeout with icon my curl2icon("show_info_dump(" & caller & ")", "https://raw.githubusercontent.com/identd113/hdhr_VCR-AS/master/app.jpg") default button 2
		end if
	end repeat
	
end show_info_dump

on check_version()
	try
		with timeout of 10 seconds
			set version_response to (fetch JSON from Version_url with cleaning feed)
			set Version_remote to hdhr_version of item 1 of versions of version_response
			set Online_detected to true
			my logger(true, "check_version()", "INFO", "Current Version: " & Version_local & ", Remote Version: " & Version_remote)
			if Version_remote is greater than Version_local then
				my logger(true, "check_version()", "INFO", "Changelog: " & changelog of item 1 of versions of version_response)
			end if
		end timeout
	on error errmsg
		my logger(true, "check_version()", "ERROR", "Unable to check for new versions: " & errmsg)
		set version_response to {versions:{{changelog:"Unable to check for new versions", hdhr_version:"20210101"}}}
		set Version_remote to hdhr_version of item 1 of versions of version_response
	end try
end check_version

on check_version_dialog()
	if Version_remote is greater than Version_local then
		set temp to Version_local & " " & Update_icon & " " & Version_remote
	end if
	if Version_remote is less than Version_local then
		set temp to "Beta " & Version_local
	end if
	if Version_remote is Version_local then
		set temp to Version_local
	end if
	return temp
end check_version_dialog

on build_channel_list(caller, hdhr_device) -- We need to have the two values in a list, so we can reference one, and pull the other, replacing channel2name
	--log "build_channel_list: " & caller
	set channel_list_temp to {}
	try
		if hdhr_device is "" then
			repeat with i from 1 to length of HDHR_DEVICE_LIST
				my build_channel_list("build_channel_list" & i & "(" & caller & ")", device_id of item i of HDHR_DEVICE_LIST)
			end repeat
		else
			
			set tuner_offset to my HDHRDeviceSearch("build_channel_list(" & caller & ")", hdhr_device)
			set temp to hdhr_lineup of item tuner_offset of HDHR_DEVICE_LIST
			--set channel_list to {}
			repeat with i from 1 to length of temp
				try
					if HD of item i of temp is 1 then
						set end of channel_list_temp to GuideNumber of item i of temp & " " & GuideName of item i of temp & " [HD]"
					end if
				on error
					set end of channel_list_temp to GuideNumber of item i of temp & " " & GuideName of item i of temp
				end try
				
				try
					if VideoCodec of item i of temp is not "MPEG2" then
						my logger(true, "build_channel_list_VIDEO_CODEC(" & caller & ")", "NEAT", (last item of channel_list_temp as text) & " is using " & VideoCodec of item i of temp)
					end if
				end try
				
				try
					if AudioCodec of item i of temp is not "AC3" then
						my logger(true, "build_channel_list_AUDIO_CODEC(" & caller & ")", "NEAT", (last item of channel_list_temp as text) & " is using " & AudioCodec of item i of temp)
					end if
				end try
				
			end repeat
			set channel_mapping of item tuner_offset of HDHR_DEVICE_LIST to channel_list_temp
			my logger(true, "build_channel_list(" & caller & ")", "INFO", "Updated Channel list for " & hdhr_device & " length: " & length of channel_list_temp)
		end if
	on error errnum
		my logger(true, "build_channel_list(" & caller & ")", "ERROR", "Unable to build channel list " & errnum)
	end try
	
end build_channel_list

on channel2name(caller, the_channel, hdhr_device)
	my logger(true, "channel2name(" & caller & ")", "DEBUG", the_channel & " on " & hdhr_device)
	set tuner_offset to my HDHRDeviceSearch("channel2name0", hdhr_device)
	if tuner_offset is greater than 0 then
		set channel2name_temp to hdhr_lineup of item tuner_offset of HDHR_DEVICE_LIST
		repeat with i from 1 to length of channel2name_temp
			if GuideNumber of item i of channel2name_temp is the_channel then
				my logger(true, "channel2name(" & caller & ")", "DEBUG", "returned \"" & GuideName of item i of channel2name_temp & "\" station for channel " & the_channel & " on " & hdhr_device)
				return GuideName of item i of channel2name_temp
			end if
		end repeat
		my logger(true, "channel2name(" & caller & ")", "ERROR", "We were not able to pull lineup data for channel " & the_channel & " for device " & hdhr_device)
		--return false
	else
		my logger(true, "channel2name(" & caller & ")", "WARN", "tuner_offset is 0")
		return false
	end if
end channel2name

--show_next should only return the next record time, considering recording and not a list of all record times, if a show is recording, that time should remain as returned
on nextday(caller, the_show_id)
	--	my logger(true, "next_day(" & caller & ")", "INFO", "1")
	copy (current date) to cd_object
	set nextup to {}
	set show_offset to my HDHRShowSearch(the_show_id)
	--log item show_offset of show_info
	--log "length of show info: " & length of show_info
	repeat with i from 0 to 7
		if the_show_id is show_id of item show_offset of Show_info then
			--display dialog "test1"
			--log "Shows match"
			--log ((weekday of (cd_object + i * days)))
			--log (show_air_date of item show_offset of show_info)
			if ((weekday of (cd_object + i * days)) as text) is in (show_air_date of item show_offset of Show_info) then
				--log "1: " & (weekday of (cd_object + i * days)) & " is in " & show_air_date of item show_offset of show_info as text
				--log "2: " & (my time_set((cd_object + i * days), (show_time of item show_offset of show_info))) + ((show_length of item show_offset of show_info) * minutes)
				if cd_object is less than (my time_set("nextday(" & caller & ")", (cd_object + i * days), (show_time of item show_offset of Show_info))) + ((show_length of item show_offset of Show_info) * minutes) then
					set nextup to my time_set("nextday(" & caller & ")", (cd_object + i * days), show_time of item show_offset of Show_info)
					try
						--log "show_next of item show_offset of show_info"
						--log show_next of item show_offset of show_info
						my logger(true, "nextday(" & caller & ")", "INFO", "Show: \"" & show_title of item show_offset of Show_info & "\" Next Up changed to " & my short_date("nextday", show_next of item show_offset of Show_info, true, false))
					on error errmsg
						--log "nextDay: " & errmsg
					end try
					exit repeat
				end if
			end if
		end if
	end repeat
	if show_end of item show_offset of Show_info is not nextup + ((show_length of item show_offset of Show_info) * minutes) then
		set show_end of item show_offset of Show_info to nextup + ((show_length of item show_offset of Show_info) * minutes)
		my logger(true, "nextday(" & caller & ")", "INFO", "Show end of \"" & show_title of item show_offset of Show_info & "\" set to: " & nextup + ((show_length of item show_offset of Show_info) * minutes))
	end if
	
	return nextup
end nextday

on validate_show_info(caller, show_to_check, should_edit)
	--if we return true here, we should re pop the shows list.
	--display dialog show_to_check & " ! " & should_edit
	--(*show_title:news, show_time:12, show_length:30, show_air_date:Monday, Tuesday, Wednesday, Thursday, show_transcode:false, show_temp_dir:alias Macintosh HD:Users:TEST:Dropbox:, show_dir:alias Macintosh HD:Users:TESTl:Dropbox:, show_channel:11.1, show_active:true, show_id:bf4fcd8b7ac428594a386b373ef55874, show_recording:false, show_last:date Tuesday, August 30, 2016 at 11:35:04 AM, show_next:date Tuesday, August 30, 2016 at 12:00:00 PM, show_end:date Tuesday, August 30, 2016 at 12:30:00 PM*)
	set show_active_changed to false
	if show_to_check is "" then
		repeat with i2 from 1 to length of Show_info
			my validate_show_info("validate_show_info" & i2 & "(" & caller & ")", show_id of item i2 of Show_info, should_edit)
		end repeat
	else
		set i to my HDHRShowSearch(show_to_check)
		my logger(true, "validate_show_info(" & caller & ", " & show_to_check & ", " & should_edit & ")", "DEBUG", "Running validate on " & show_title of item i of Show_info & ", should_edit: " & should_edit)
		if should_edit is true then
			if show_active of item i of Show_info is true then
				
				if my HDHRDeviceSearch("validate_show_info()", hdhr_record of item i of Show_info) is 0 then
					set show_deactivate to (display dialog "The tuner, " & hdhr_record of item i of Show_info & " is not currently active, the show should be deactivated" & return & return & "Deactivated shows will be removed on the next save/load" buttons {Running_icon & " Run", "Deactivate", "Next"} cancel button 1 default button 2 with title my check_version_dialog() with icon stop)
				else
					set show_deactivate to (display dialog "Would you like to deactivate: " & return & "\"" & show_title of item i of Show_info & "\"" & return & return & "Deactivated shows will be removed on the next save/load" buttons {Running_icon & "Run", "Deactivate", Edit_icon & " Edit.."} cancel button 1 default button 3 with title my check_version_dialog() with icon caution)
				end if
				
				if button returned of show_deactivate is "Deactivate" then
					set show_active of item i of Show_info to false
					--NEW
					set show_recording of item i of Show_info to false
					my showid2PID("main()", show_id of item i of Show_info, true, true)
					my logger(true, "validate_show_info(" & caller & ")", "INFO", "Deactivated: " & show_title of item i of Show_info)
					return true
					--my main("shows", "Shows")
				else if button returned of show_deactivate contains "Run" then
					my logger(true, "validate_show_info(" & caller & ")", "INFO", "User clicked \"Run\"")
				end if
			else if show_active of item i of Show_info is false then
				set show_deactivate to (display dialog "Would you like to activate: " & return & "\"" & show_title of item i of Show_info & "\"" & return & return & "Active shows can be edited" buttons {Running_icon & " Run", "Activate"} cancel button 1 default button 2 with title my check_version_dialog() with icon caution)
				if button returned of show_deactivate is "Activate" then
					set show_active of item i of Show_info to true
					set show_active_changed to true
					my logger(true, "validate_show_info(" & caller & ")", "INFO", "Reactivated: " & show_title of item i of Show_info)
				else if button returned of show_deactivate contains "Run" then
					my logger(true, "validate_show_info(" & caller & ")", "INFO", "User clicked " & quote & "Run" & quote)
				end if
			end if
		end if
		
		--	my logger(true, "validate_show_info()", "DEBUG", show_title of item i of show_info & " is active? " & show_active of item i of show_info)
		if show_active of item i of Show_info is true and show_active_changed is false then
			if show_title of item i of Show_info is missing value or show_title of item i of Show_info is "" or should_edit is true then
				
				if show_is_series of item i of Show_info is false then
					set show_title_temp to display dialog "What is the title of this show, and is it a series?" & return & "Next Showing: " & my short_date("validate_show", show_next of item i of Show_info, true, false) & return & "SeriesID: " & show_seriesid of item i of Show_info buttons {Running_icon & " Run", Series_icon & " Series", Single_icon & " Single"} default button 3 cancel button 1 default answer show_title of item i of Show_info with title my check_version_dialog() giving up after Dialog_timeout
				else if show_is_series of item i of Show_info is true then
					set show_title_temp to display dialog "What is the title of this show, and is it a series?" & return & "Next Showing: " & my short_date("validate_show", show_next of item i of Show_info, true, false) & return & "SeriesID: " & show_seriesid of item i of Show_info buttons {Running_icon & " Run", Series_icon & " Series", Single_icon & " Single"} default button 2 cancel button 1 default answer show_title of item i of Show_info with title my check_version_dialog() giving up after Dialog_timeout
				end if
				set show_title of item i of Show_info to text returned of show_title_temp
				
				my logger(true, "validate_show_info(" & caller & ")", "INFO", "Show Title prompt: " & text returned of show_title_temp & ", button_pressed: " & button returned of show_title_temp)
				
				if button returned of show_title_temp contains "Series" then
					set show_is_series of item i of Show_info to true
				else if button returned of show_title_temp contains "Single" then
					set show_is_series of item i of Show_info to false
				end if
				
			end if
			
			--repeat until my is_number(show_channel of item i of show_info) or should_edit = true
			if show_channel of item i of Show_info is missing value or my is_number(show_channel of item i of Show_info) is false or should_edit is true then
				
				set temp_tuner to hdhr_record of item i of Show_info
				--display dialog temp_tuner 
				set tuner_offset to my HDHRDeviceSearch("channel2name0", temp_tuner)
				--display dialog "tuner_offset: " & tuner_offset
				--FIX we need to watch for instances of HDHRDeviceSearch returning 0, and gracefully deal with it.
				if tuner_offset is greater than 0 then
					--	set temp_channel_offset to my list_position("validate_show_info1", show_channel of item i of show_info, channel_mapping of item tuner_offset of HDHR_DEVICE_LIST, false)
					--set channel_temp to word 1 of item 1 of (choose from list channel_mapping of item tuner_offset of HDHR_DEVICE_LIST with prompt "What channel does this show air on?" default items item temp_channel_offset of channel_mapping of item tuner_offset of HDHR_DEVICE_LIST with title my check_version_dialog() cancel button name play_icon & " Run" OK button name "Next.." without empty selection allowed)
					--fix new
					
					set default_selection to item (my list_position("validate_show_info1", show_channel of item i of Show_info, channel_mapping of item tuner_offset of HDHR_DEVICE_LIST, false)) of channel_mapping of item tuner_offset of HDHR_DEVICE_LIST
					
					--set temp_channel_offset to my list_position("validate_show_info1", show_channel of item i of show_info, channel_mapping of item tuner_offset of HDHR_DEVICE_LIST, false)
					
					set channel_choice to (choose from list channel_mapping of item tuner_offset of HDHR_DEVICE_LIST with prompt "What channel does this show air on?" default items default_selection with title my check_version_dialog() cancel button name Running_icon & " Run" OK button name "Next.." without empty selection allowed)
					set channel_temp to word 1 of item 1 of channel_choice
					
					--log "channel_choice"
					--log channel_choice
					--log "channel_temp"
					--log channel_temp
					if channel_choice is false then
						my logger(true, "validate_show_info()", "INFO", "User clicked " & quote & "Run" & quote)
					end if
					
				else
					set channel_temp to text returned of (display dialog "What channel does this show air on?" default answer show_channel of item i of Show_info with title my check_version_dialog() giving up after Dialog_timeout)
				end if
				my logger(true, "validate_show_info(" & caller & ")", "INFO", "Channel Prompt returned: " & channel_temp)
				set show_channel of item i of Show_info to channel_temp --set show_channel of item i of show_info to word 1 of item 1 of (choose from list channel_list with prompt "What channel does this show air on?" default items show_channel of item i of show_info without empty selection allowed) 
			end if
			--end repeat   
			
			if show_time of item i of Show_info is missing value or (show_time of item i of Show_info as number) is greater than or equal to 24 or my is_number(show_time of item i of Show_info) is false or should_edit is true then
				set show_time of item i of Show_info to text returned of (display dialog "What time does this show air? " & return & "(0-24, use decimals, ie 9.5 for 9:30)" default answer show_time of item i of Show_info buttons {Running_icon & " Run", "Next.."} with title my check_version_dialog() giving up after Dialog_timeout default button 2 cancel button 1) as number
				set show_time_orig of item i of Show_info to show_time of item i of Show_info
			end if
			if show_length of item i of Show_info is missing value or my is_number(show_length of item i of Show_info) is false or show_length of item i of Show_info is less than or equal to 0 or should_edit is true then
				set show_length of item i of Show_info to text returned of (display dialog "How long is this show? (minutes)" default answer show_length of item i of Show_info with title my check_version_dialog() buttons {Running_icon & " Run", "Next.."} default button 2 cancel button 1 giving up after Dialog_timeout)
			end if
			
			if show_air_date of item i of Show_info is missing value or length of show_air_date of item i of Show_info is 0 or should_edit is true or class of (show_air_date of item i of Show_info) is not list then
				set show_air_date of item i of Show_info to (choose from list {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"} default items show_air_date of item i of Show_info with title my check_version_dialog() OK button name "Next.." cancel button name Running_icon & " Run" with prompt "Select the days you wish to record" & return & "If this is a series, you can select multiple days" with multiple selections allowed without empty selection allowed)
			end if
			if show_dir of item i of Show_info is missing value or (class of (show_temp_dir of item i of Show_info) as text) is not "alias" or should_edit is true then
				
				try
					set show_dir of item i of Show_info to choose folder with prompt "Select shows Directory" default location show_dir of item i of Show_info
				on error errmsg
					set show_dir of item i of Show_info to choose folder with prompt "The show: " & return & show_title of item i of Show_info & return & " has an invalid directory. Please choose another"
					my logger(true, "main()", "WARN", "Invalid path")
				end try
				set show_temp_dir of item i of Show_info to show_dir of item i of Show_info
			end if
			
			if show_next of item i of Show_info is missing value or (class of (show_next of item i of Show_info) as text) is not "date" or should_edit is true then
				if show_is_series of item i of Show_info is true then
					set show_next of item i of Show_info to my nextday("validate_show_info(" & caller & ")", show_id of item i of Show_info)
				end if
			end if
			if should_edit is true then
				set progress description to "This show has been changed!"
				delay 0.1
				display notification with title Edit_icon & " Show Changed! (" & hdhr_record of last item of Show_info & ")" subtitle "" & quote & show_title of last item of Show_info & quote & " at " & show_time of last item of Show_info
			end if
			
			if my HDHRDeviceSearch("validate_show_info(hdhr)", hdhr_record of item i of Show_info) is 0 then
				my logger(true, "validate_show_info(" & caller & ")", "WARN", "The show " & quote & show_title of item i of Show_info & quote & ", will not be recorded, as the tuner " & hdhr_record of item i of Show_info & ", is no longer detected")
				--FIX We need to add a notification with this, as this is an important issue they should know about. 
			end if
		else
			set show_active_changed to false
		end if
	end if
end validate_show_info

on setup()
	
	--loglines_max
	set hdhr_setup_response to (display dialog "hdhr_VCR Setup" buttons {"Defaults", "Run"} default button 1 cancel button 2 with title my check_version_dialog() giving up after Dialog_timeout)
	if button returned of hdhr_setup_response is "Defaults" then
		set Temp_dir to alias "Volumes:"
		--repeat until temp_dir is not alias "Volumes:"
		repeat
			set hdhr_setup_folder_temp to choose folder with prompt "Select default shows directory" default location Temp_dir
			if hdhr_setup_folder_temp is not alias "Volumes:" then
				set Hdhr_setup_folder to hdhr_setup_folder_temp as text
				exit repeat
			end if
		end repeat
		--end repeat
		--write data here   
		display dialog "We need to allow notifications" & return & "Click " & quote & "Next" & quote & " to continue" buttons {"Next"} default button 1 with title my check_version_dialog() giving up after Dialog_timeout
		display notification "Yay!" with title name of me subtitle "Notifications Enabled!"
		
		set Notify_upnext to text returned of (display dialog "How often to show " & quote & "Up Next" & quote & " update notifications?" default answer Notify_upnext)
		set Notify_recording to text returned of (display dialog "How often to show " & quote & "Recording" & quote & " update notifications?" default answer Notify_recording)
		set Hdhr_setup_ran to true
		--			set hdhr_config to {notify_upnext:notify_upnext, notify_recording:notify_recording, hdhr_setup_folder:hdhr_setup_folder}
	end if
	
end setup

on main(caller, emulated_button_press)
	my logger(true, "main(" & caller & ", " & emulated_button_press & ")", "INFO", "Main Called")
	# my show_collision("main(" & caller & ")", "")
	if length of HDHR_DEVICE_LIST is 0 then
		my HDHRDeviceDiscovery("main(no_tuners_found)", "")
	end if
	idle {}
	my logger(true, "main(" & caller & ", " & emulated_button_press & ")", "INFO", "Main screen called")
	--my read_data() 
	(*
	if preferred_tuner_offset = missing value then 
		quit {}
	end if 
	*)
	-- This gets out list of channel and channel names.  There is a better way to do this (from guide data maybe? bit this is a hold over from v1, and it works.
	--This will make sure that data we have stored is valid 
	--my validate_show_info("", false) 
	--my build_channel_list("main0", "")
	--log "tuner_status " & my tuner_status("main", "105404BE") 
	--my tuner_status("main", "105404BE") 
	--This will mark shows as inactive (single show recording that has already passed)
	set show_info_length to length of Show_info
	if show_info_length is greater than 0 then
		repeat with i from 1 to show_info_length
			if show_last of item i of Show_info is not my epoch() and show_is_series of item i of Show_info is false then
				set show_active of item i of Show_info to false
			end if
		end repeat
	end if
	--activate me
	--try
	set show_list_empty to false
	--try
	set next_show_main_temp to my next_shows("main(" & caller & ")")
	
	set next_show_main to my listtostring("main(" & caller & ")", item 2 of next_show_main_temp, return)
	set next_show_main_time to my short_date("main(" & caller & ")", item 1 of next_show_main_temp, false, false)
	set next_show_main_time_real to item 1 of next_show_main_temp
	--	on error
	--	set next_show_main to ""
	--set next_show_main_time to "" 
	--end try
	--on error
	--We likely do not have any shows.  
	--fix
	--set show_list_empty to true   
	--end try 
	if emulated_button_press is not in {"Add", "Shows"} then
		activate me
		if show_list_empty is true then
			set title_response to (display dialog "Would you like to add a show?" & return & return & "Tuner(s): " & return & my listtostring("main(" & caller & ")", my tuner_overview("main(" & caller & ")"), return) buttons {Tv_icon & " Shows..", Plus_icon & " Add..", Running_icon & " Run"} with title my check_version_dialog() giving up after (Dialog_timeout * 0.5) with icon my curl2icon("main(" & caller & ")", "https://raw.githubusercontent.com/identd113/hdhr_VCR-AS/master/app.jpg") default button 2)
			my logger(true, "main(" & caller & ")", "INFO", "EMPTY LIST")
		else
			set title_response to (display dialog "Would you like to add a show?" & return & return & "Tuner(s): " & return & my listtostring("main()", my tuner_overview("main(" & caller & ")"), return) & return & return & my recording_now("main(" & caller & ")") & return & return & Up_icon & " Next Show: " & next_show_main_time & " (" & my ms2time("main(next_show_countdown)", (next_show_main_time_real) - (current date), "s", 2) & ")" & return & next_show_main buttons {Tv_icon & " Shows..", Plus_icon & " Add..", Running_icon & " Run"} with title my check_version_dialog() giving up after (Dialog_timeout * 0.5) with icon my curl2icon("main(" & caller & ")", "https://raw.githubusercontent.com/identd113/hdhr_VCR-AS/master/app.jpg") default button 2)
			my logger(true, "main(" & caller & ")", "INFO", "SHOW LIST")
		end if
	else
		my logger(true, "main(" & caller & ")", "INFO", "ELSE")
		set title_response to {button returned:emulated_button_press}
	end if
	my logger(true, "main(" & caller & ")", "INFO", "Main screen called2 " & quote & emulated_button_press & quote & " " & quote & button returned of title_response & quote)
	--ADD
	if button returned of title_response contains "Add" then
		my logger(true, "main()", "INFO", "UI:Clicked " & quote & "Add" & quote)
		
		if option_down of my isModifierKeyPressed("main_opt", "option", "Reruns HDHRDeviceDiscovery") is true then
			my HDHRDeviceDiscovery("main_opt", "")
			--my update_show("main()", "", true)
		end if
		
		set temp_tuners_list to {}
		if length of HDHR_DEVICE_LIST is greater than 0 then
			repeat with i from 1 to length of HDHR_DEVICE_LIST
				--log item i of HDHR_DEVICE_LIST
				if is_active of item i of HDHR_DEVICE_LIST is true then
					set end of temp_tuners_list to hdhr_model of item i of HDHR_DEVICE_LIST & " " & (device_id of item i of HDHR_DEVICE_LIST)
				else
					set is_active_reason of item i of HDHR_DEVICE_LIST to "Deactivated"
					my logger(true, "main(" & caller & ")", "INFO", "The tuner, " & device_id of item i of HDHR_DEVICE_LIST & " was not added")
				end if
			end repeat
			if length of temp_tuners_list is greater than 1 then
				set preferred_tuner to choose from list temp_tuners_list with prompt "Multiple HDHR Devices found, please choose one" cancel button name Running_icon & " Run" OK button name "Select" with title my check_version_dialog() default items item 1 of temp_tuners_list
				if preferred_tuner is not false then
					my logger(true, "main(" & caller & ")", "INFO", "User clicked " & quote & "Run" & quote)
					set hdhr_device to last word of item 1 of preferred_tuner
				else
					set hdhr_device to missing value
				end if
			else
				set hdhr_device to device_id of item 1 of HDHR_DEVICE_LIST
			end if
			my add_show_info("main(" & caller & ")", hdhr_device)
		else
			try
				with timeout of 15 seconds
					my HDHRDeviceDiscovery("no_devices2", "")
				end timeout
			on error errnum
				my logger(true, "main(" & caller & ")", "INFO", "UI:Clicked " & quote & "Add" & quote)
				my main("main3", "")
			end try
		end if
	end if
	
	--SHOWS
	if button returned of title_response contains "Shows" then
		set progress description to "Loading " & length of Show_info & " shows ..."
		set progress additional description to ""
		set progress completed steps to 0
		set progress total steps to length of Show_info
		if option_down of my isModifierKeyPressed("main()", "option", "Runs Setup") is true then
			my setup()
			return
		end if
		my logger(true, "main()", "INFO", "UI:Clicked \"Shows\"")
		--set show_info to my sort_show_list()
		set show_list to {}
		set show_list_deactive to {}
		set show_list_active to {}
		set show_list_later to {}
		set show_list_recording to {}
		set show_list_up to {}
		set show_list_up2 to {}
		set show_list_length to length of Show_info
		repeat with i from 1 to show_list_length
			set progress completed steps to i
			--set end of show_list to (show_title of item i of show_info & "\" on " & show_channel of item i of show_info & " at " & show_time of item i of show_info & " for " & show_length of item i of show_info & " minutes on " & show_air_date)
			--display notification class of show_recording of item i of show_info
			set progress additional description to show_title of item i of Show_info
			set temp_show_line to " " & (show_title of item i of Show_info & " on " & show_channel of item i of Show_info & " at " & show_time of item i of Show_info & " for " & show_length of item i of Show_info & " minutes on " & my listtostring("main", show_air_date of item i of Show_info, ", "))
			
			if show_is_series of item i of Show_info is true then
				set temp_show_line to Series_icon & temp_show_line
			else
				set temp_show_line to Single_icon & temp_show_line
			end if
			
			if show_active of item i of Show_info is true then
				--set temp_show_line to check_icon & temp_show_line
			else
				set temp_show_line to Uncheck_icon & temp_show_line
			end if
			
			if ((show_next of item i of Show_info) - (current date)) is less than 4 * hours and show_active of item i of Show_info is true and show_recording of item i of Show_info is false then
				if ((show_next of item i of Show_info) - (current date)) is greater than 1 * hours then
					set temp_show_line to Up_icon & temp_show_line
				else
					set temp_show_line to Film_icon & temp_show_line
				end if
			end if
			
			if ((show_next of item i of Show_info) - (current date)) is greater than or equal to 4 * hours and (date (date string of (current date))) is (date (date string of (show_next of item i of Show_info))) and show_active of item i of Show_info is true and show_recording of item i of Show_info is false then
				set temp_show_line to Up2_icon & temp_show_line
			end if
			
			if show_recording of item i of Show_info is true and show_active of item i of Show_info is true then
				set temp_show_line to Record_icon & temp_show_line
			end if
			
			if (date (date string of (current date))) is less than (date (date string of (show_next of item i of Show_info))) and show_active of item i of Show_info is true then
				set temp_show_line to Futureshow_icon & temp_show_line
			end if
			try
				if (show_recorded_today of item i of Show_info) is true then
					set temp_show_line to Done_icon & temp_show_line
				end if
			on error errmsg
				my logger(true, "main_show_sort()", "ERROR", "Error with show_recorded_today, errmsg: " & errmsg)
			end try
			(*
				if (date (date string of (current date))) = (date (date string of (show_last of item i of show_info))) and show_active of item i of show_info = true and (show_last of item i of show_info) < (current date) then
				set temp_show_line to calendar2_icon & temp_show_line
			end if
				*)
			set end of show_list to temp_show_line
			if show_list_length is i then
				set progress additional description to length of Show_info & " shows loaded"
			end if
		end repeat
		if length of show_list is 0 then
			set progress completed steps to -1
			set progress additional description to "No shows to load"
			try
				my logger(true, "main()", "WARN", "There are no shows")
				set hdhr_no_shows to button returned of (display dialog "There are no shows, why don't you add one?" buttons {"Quit", Plus_icon & " Add Show"} default button 2)
				if hdhr_no_shows contains "Add Show" then
					--This should kick us to the adding a show handler.
					my main("main_noshow", "Add")
				end if
				if hdhr_no_shows is "Quit" then
					quit {}
				end if
				--We need a to prompt user for perferred tuner here to make this work. 
			on error
				my logger(true, "main()", "INFO", "User clicked \"Run\"")
				return
			end try
		else if length of show_list is greater than 0 then
			set temp_show_list to (choose from list show_list with title my check_version_dialog() with prompt "" & length of show_list & " shows to edit: " & return & Single_icon & " Single   " & Series_icon & " Series" & "   " & Record_icon & " Recording" & "   " & Uncheck_icon & " Inactive" & return & Film_icon & " Up Next < 1h" & "  " & Up_icon & " Up Next < 4h" & "  " & Up2_icon & " Up Next > 4h" & "  " & Futureshow_icon & " Future Show" & "   " & Done_icon & " Recorded today" OK button name Edit_icon & " Edit.." cancel button name Running_icon & " Run" default items item 1 of show_list with multiple selections allowed without empty selection allowed)
			
			if command_down of my isModifierKeyPressed("main_command3()", "command", "Mass deactivate") is true then
				set mass_deactivate to button returned of (display dialog "Do you wish to activate or deactivate the shows selected?" buttons {Running_icon & " Run", "Activate", "Deactivate"} with title my check_version_dialog() giving up after Dialog_timeout with icon my curl2icon("main(" & caller & ")", "https://raw.githubusercontent.com/identd113/hdhr_VCR-AS/master/app.jpg") default button 1)
				
				if mass_deactivate contains "Deactivate" then
					set de_activate_all to false
				end if
				
				if mass_deactivate contains "Activate" then
					set de_activate_all to true
				end if
				
				if mass_deactivate contains "Run" then
					return
				end if
				
				repeat with i from 1 to length of Show_info
					set show_active of item i of Show_info to de_activate_all
				end repeat
				
				my main("shows", "Shows")
				return
			end if
			
			if temp_show_list is not false then
				repeat with i3 from 1 to length of temp_show_list
					set temp_show_list_offset to (my list_position("main1(" & caller & ")", (item i3 of temp_show_list as text), show_list, true))
					
					--Fix this.  Returning for every show
					--	my show_info_dump("shows(main(" & caller & "))", show_id of item temp_show_list_offset of show_info, true)
					my logger(true, "main(" & caller & ")", "DEBUG", "Pre validate for " & show_title of item temp_show_list_offset of Show_info)
					
					my validate_show_info("main(" & caller & ")", show_id of item temp_show_list_offset of Show_info, true)
					if show_active of item (temp_show_list_offset) of Show_info is true then
						my update_show("main2(" & caller & ")", show_id of item temp_show_list_offset of Show_info, true)
						set show_next of item temp_show_list_offset of Show_info to my nextday("main(" & caller & ")", show_id of item temp_show_list_offset of Show_info)
					end if
					--set (show_next of temp_show_list_offset of show_info) to my nextday(show_id of temp_show_list_offset)
					--fix removed saving data here 
					--my save_data() 
					if i3 is length of temp_show_list then
						my main("shows", "Shows")
						return
					end if
				end repeat
			else
				--FIX, this code path is not likely followed
				my logger(true, "main()", "INFO", "1User clicked \"Run\"")
				return false
			end if
		end if
		
	end if
	if button returned of title_response contains "Run" or gave up of title_response is true then
		my logger(true, "main(" & caller & ")", "INFO", "2User clicked \"Run\"")
		if option_down of my isModifierKeyPressed("main_opt", "option", "Quit?") is true then
			quit {}
		end if
		return
	end if
end main

on add_show_info(caller, hdhr_device)
	set progress additional description to ""
	set progress description to "Adding a show on " & hdhr_device & "..."
	set tuner_status_result to my tuner_status2("add_show(" & caller & ")", hdhr_device)
	set tuner_status_icon to "Tuner: " & hdhr_device
	if tunermax of tuner_status_result is tuneractive of tuner_status_result then
		set tuner_status_icon to hdhr_device & " has no available tuners" & return & "Next timeout: " & my ms2time("add_show_info", my tuner_end("add_show_info()", hdhr_device), "s", 3)
	end if
	set tuner_offset to my HDHRDeviceSearch("add_show_info0(" & caller & ")", hdhr_device)
	set show_channel to missing value
	
	--set temp_show_info to {show_title:missing value, show_time:missing value, show_length:missing value, show_air_date:missing value, show_transcode:missing value, show_temp_dir:missing value, show_dir:missing value, show_channel:missing value, show_active:true, show_id:(do shell script "date | md5") as text, show_recording:false, show_last:my epoch(), show_next:missing value, show_end:missing value, notify_upnext_time:missing value, notify_recording_time:missing value, hdhr_record:hdhr_device, show_is_series:false}
	
	--fix this likely breaks us when a tuner is not detected.
	if hdhr_device is "" then
		if length of HDHR_DEVICE_LIST is 1 then
			set hdhr_device to device_id of item 1 of HDHR_DEVICE_LIST
		else
			return
		end if
	end if
	
	--What channel?  We need at least this to pull a guide. 
	set temp_show_progress to {}
	set hdhrGRID_response to true
	set progress description to "Select a channel on tuner: " & hdhr_device & "..."
	
	repeat until hdhrGRID_response is not true
		if Back_channel is missing value then
			set default_selection to item 1 of channel_mapping of item tuner_offset of HDHR_DEVICE_LIST
		else
			set default_selection to item (my list_position("add_show_info()", Back_channel, channel_mapping of item tuner_offset of HDHR_DEVICE_LIST, false)) of channel_mapping of item tuner_offset of HDHR_DEVICE_LIST
		end if
		set hdhrGRID_list_response to (choose from list channel_mapping of item tuner_offset of HDHR_DEVICE_LIST with prompt "What channel does this show air on?" & return & return & tuner_status_icon with title my check_version_dialog() OK button name "Next.." cancel button name Running_icon & " Run" default items default_selection without empty selection allowed)
		--FIX 
		--display dialog hdhrGRID_list_response
		--FIX offset of hdhrGRID_list_response in channel mapping
		--set temp_channel_offset to my list_position("add_show_info("&caller&")", show_channel of item i of show_info, channel_mapping of item tuner_offset of HDHR_DEVICE_LIST, false)
		--fix get default item to 1 or to the last item selected.
		if hdhrGRID_list_response is not false then
			set show_channel_temp to word 1 of item 1 of hdhrGRID_list_response
			set end of temp_show_progress to "Channel: " & show_channel_temp & " (" & my channel2name("add_show_info(" & caller & ")", show_channel_temp, hdhr_device) & ")"
			set progress additional description to my listtostring("add_show(" & caller & ")", temp_show_progress, return)
			if option_down of my isModifierKeyPressed("add", "option", "Returns false for hdhrGRID_response") is true then
				set hdhrGRID_response to false
			else
				set hdhrGRID_response to my hdhrGRID("add_show_info(" & caller & ")", hdhr_device, show_channel_temp)
			end if
		else
			my logger(true, "add_show_info(" & caller & ")", "INFO", "User clicked \"Run\"")
			error number -128
		end if
	end repeat
	--return true means we want to go back 
	--return false means we cancelled out.
	--return anything else, and this is the guide data for the channel they are requesting.
	
	--The above line pulls guide data.  If we fail this, we will prompt the user to enter the information. 
	--if hdhrGRID_response is not in {true, false} then
	
	--repeat with i3 from 1 to length of hdhrGRID_response
	
	--set default_record_day to (weekday of ((current date) + time_slide * days)) as text
	
	set hdhr_skip_multiple_bool to false
	set temp_show_air_date to missing value
	set temp_show_dir to missing value
	set temp_show_transcode to missing value
	set temp_is_series to missing value
	if hdhrGRID_response is not false then
		if length of hdhrGRID_response is greater than 1 then
			my logger(true, "add_show_info(" & caller & ")", "INFO", "Multiple shows selected for recording on " & hdhr_device)
			set hdhr_skip_multiple to button returned of (display dialog "You are adding multiple shows.  Do you wish to use the same settings for all shows?" buttons {"No", "Yes"} default button 2 with title my check_version_dialog() giving up after Dialog_timeout * 0.5 with icon note)
			if hdhr_skip_multiple is "Yes" then
				set hdhr_skip_multiple_bool to true
			end if
		end if
		repeat with i3 from 1 to length of hdhrGRID_response
			set progress description to "Adding a show on " & hdhr_device & "..."
			set progress total steps to 7
			set progress completed steps to 0
			set temp_show_progress to {}
			repeat 1 times
				set temp_show_info to {show_title:missing value, show_time:missing value, show_length:missing value, show_air_date:missing value, show_transcode:missing value, show_temp_dir:missing value, show_dir:missing value, show_channel:show_channel_temp, show_active:true, show_id:(do shell script "date | md5") as text, show_recording:false, show_last:my epoch(), show_next:missing value, show_end:missing value, notify_upnext_time:missing value, notify_recording_time:missing value, hdhr_record:hdhr_device, show_is_series:false, show_seriesid:"", show_tags:{}, show_time_orig:missing value, show_is_sport:false, show_recorded_today:false}
				if length of hdhrGRID_response is 1 and hdhrGRID_response is {""} then
					my logger(true, "add_show_info()", "INFO", "Manually adding show for " & hdhr_device)
					--title 
					set show_title_temp to display dialog "What is the title of this show, and is it a series?" buttons {Running_icon & " Run", Series_icon & " Series", Single_icon & " Single"} cancel button 1 default button 3 default answer "" with title my check_version_dialog() giving up after Dialog_timeout
					set show_title of temp_show_info to text returned of show_title_temp
					set end of temp_show_progress to "Title: " & show_title of temp_show_info
					set progress additional description to my listtostring("add_show()", temp_show_progress, return)
					my logger(true, "add_show_info(" & caller & ")", "INFO", "(Manual) Show name: " & show_title of temp_show_info)
					set progress completed steps to 1
					--show_is_series
					if button returned of show_title_temp contains "Series" then
						set show_is_series of temp_show_info to true
					else if button returned of show_title_temp contains "Single" then
						set show_is_series of temp_show_info to false
					else
						return
					end if
					set end of temp_show_progress to "Series: " & show_is_series of temp_show_info
					set progress additional description to my listtostring("add_show()", temp_show_progress, return)
					set progress completed steps to 2
					my logger(true, "add_show_info(" & caller & ")", "INFO", "(Manual) show_is_series: " & show_is_series of temp_show_info)
					--time
					repeat until my is_number(show_time of temp_show_info) and show_time of temp_show_info is greater than or equal to 0 and show_time of temp_show_info is less than 24
						set Time_slide to 0
						set show_time_temp to (display dialog "What time does this show air? " & return & "(0-24, use decimals, ie 16.5 for 4:30 PM)" default answer hours of (current date) buttons {Running_icon & " Run", "Next.."} with title my check_version_dialog() giving up after Dialog_timeout default button 2 cancel button 1)
						if (text returned of show_time_temp as number) is less than hours of (current date) then
							set Time_slide to Time_slide + 1
							set default_record_day to (weekday of ((current date) + Time_slide * days)) as text
							my logger(true, "add_show_info(" & caller & ")", "INFO", "default_record_day set to " & default_record_day)
						end if
						set show_time of temp_show_info to text returned of show_time_temp as number
						set show_time_orig of temp_show_info to show_time of temp_show_info
						
					end repeat
					set end of temp_show_progress to "Air time: " & show_time of temp_show_info
					set progress additional description to my listtostring("add_show()", temp_show_progress, return)
					set progress completed steps to 3
					my logger(true, "add_show_info(" & caller & ")", "INFO", "(Manual) show time: " & show_time of temp_show_info)
					--length
					
					repeat until my is_number(show_length of temp_show_info) and show_length of temp_show_info is greater than or equal to 1
						set show_length of temp_show_info to text returned of (display dialog "How long is this show? (minutes)" default answer "30" with title my check_version_dialog() buttons {Running_icon & " Run", "Next.."} default button 2 cancel button 1 giving up after Dialog_timeout)
					end repeat
					
					set end of temp_show_progress to "Length: " & show_length of temp_show_info
					set progress additional description to my listtostring("add_show()", temp_show_progress, return)
					set progress completed steps to 4
					my logger(true, "add_show_info(" & caller & ")", "INFO", "(Manual) show length: " & show_length of temp_show_info)
				else
					
					--We were able to pull guide data auto title
					try
						
						try
							set hdhr_response_channel_title to title of item i3 of hdhrGRID_response
						end try
						
						try
							set hdhr_response_channel_title to hdhr_response_channel_title & " " & EpisodeNumber of item i3 of hdhrGRID_response
						end try
						
						try
							set hdhr_response_channel_title to hdhr_response_channel_title & " " & EpisodeTitle of item i3 of hdhrGRID_response
						end try
						
					on error
						my logger(true, "add_show_info(" & caller & ")", "INFO", "(Auto) Unable to set full show name")
					end try
					
					try
						set default_record_day to (weekday of my epoch2datetime("hdhrGRID(3)", (my getTfromN(StartTime of item i3 of hdhrGRID_response)))) as text
					on error errmsg
						my logger(true, "add_show_info(" & caller & ")", "WARN", "default_record_day failed, errmsg: " & errmsg)
						set default_record_day to weekday of (current date) as text
					end try
					
					set show_title of temp_show_info to hdhr_response_channel_title
					set end of temp_show_progress to "Title: " & hdhr_response_channel_title
					set progress additional description to my listtostring("add_show()", temp_show_progress, return)
					set progress completed steps to 1
					my logger(true, "add_show_info(" & caller & ")", "INFO", "(Auto) Show name: " & show_title of temp_show_info)
					
					--auto length 
					try
						set show_length of temp_show_info to ((EndTime of item i3 of hdhrGRID_response) - (StartTime of item i3 of hdhrGRID_response)) div 60
					on error errmsg
						my logger(true, "add_show_info(" & caller & ")", "ERROR", "(Auto) show length defaulted to 30 minutes, errmsg: " & errmsg)
						set show_length of temp_show_info to 30
					end try
					set end of temp_show_progress to "Length: " & show_length of temp_show_info
					set progress additional description to my listtostring("add_show()", temp_show_progress, return)
					set progress completed steps to 2
					my logger(true, "add_show_info(" & caller & ")", "INFO", "(Auto) show length: " & show_length of temp_show_info)
					
					--auto show_time 
					set show_time of temp_show_info to my epoch2show_time("hdhrGRID(4)", my getTfromN(StartTime of item i3 of hdhrGRID_response))
					set show_time_orig of temp_show_info to show_time of temp_show_info
					my logger(true, "add_show_info(" & caller & ")", "INFO", "(Auto) show time: " & show_time of temp_show_info)
					set end of temp_show_progress to "Air time: " & show_time of temp_show_info
					set progress additional description to my listtostring("add_show()", temp_show_progress, return)
					set progress completed steps to 3
					try
						set synopsis_temp to Synopsis of item i3 of hdhrGRID_response
					on error
						my logger(true, "add_show_info(" & caller & ")", "WARN", "Unable to pull Synopsis")
						set synopsis_temp to "No Synopsis"
					end try
					
					try
						set seriesid_temp to SeriesID of item i3 of hdhrGRID_response
						set show_seriesid of temp_show_info to SeriesID of item i3 of hdhrGRID_response
						my logger(true, "add_show_info(" & caller & ")", "INFO", "Set Series ID:" & SeriesID of item i3 of hdhrGRID_response)
					on error errmsg
						my logger(true, "add_show_info(" & caller & ")", "WARN", "Unable to pull Series ID: " & errmsg)
						set seriesid_temp to "No SeriesID provided"
					end try
					
					
					set temp_icon to my curl2icon("add_show_info(" & caller & ")", ImageURL of item i3 of hdhrGRID_response)
					--force error to test custom icons 
					--error -128
					
					try
						set show_tags of temp_show_info to Filter of item i3 of hdhrGRID_response
					on error
						set show_tags of temp_show_info to {"None"}
					end try
					
					--					set show_tags_text of temp_show_info to my listtostring("add_show_info(" & caller & ")", show_tags of temp_show_info , ", ")
					
					try
						set tags_text to my listtostring("add_show_info(" & caller & ")", show_tags of temp_show_info, ", ")
					on error errmsg
						set tags_text to "ERROR"
						my logger(true, "add_show_info1(" & caller & ")", "ERROR", errmsg)
					end try
					
					set temp_default_button to 3
					if temp_is_series is true then
						set temp_default_button to 2
					end if
					
					try
						set show_originalairdate to OriginalAirdate of item i3 of hdhrGRID_response
						set show_originalairdate_real to my short_date("add_show_info", my epoch2datetime("add_show_info1", show_originalairdate), false, false)
					on error errmsg
						set show_originalairdate_real to "Unknown"
					end try
					
					try
						set temp_show_info_series to (display dialog "Is this a single or a series recording? " & return & return & "Title: " & show_title of temp_show_info & return & "Type: " & tags_text & return & "SeriesID: " & seriesid_temp & return & return & "Synopsis: " & synopsis_temp & return & return & "Start: " & time string of my time_set("add_show_info(" & caller & ")", current date, show_time of temp_show_info) & return & "Length: " & my ms2time("add_show_info2", ((show_length of temp_show_info) * 60), "s", 2) & return & "OriginalAirdate: " & show_originalairdate_real buttons {Running_icon & " Run", Series_icon & " Series", Single_icon & " Single"} default button temp_default_button cancel button 1 with title my check_version_dialog() giving up after Dialog_timeout with icon temp_icon)
						
						--set temp_show_info_series to (display dialog "Is this a single or a series recording? " & return & return & "Title: " & show_title of temp_show_info & return & return & "Synopsis: " & synopsis_temp & return & "Start: " & show_time of temp_show_info & return & "Length: " & show_length of temp_show_info buttons {"Cancel", series_icon & " Series", single_icon & " Single"} default button 3 with title my check_version_dialog() giving up after dialog_timeout with icon note)
						
						if button returned of temp_show_info_series contains "Series" then
							set show_is_series of temp_show_info to true
						else if button returned of temp_show_info_series contains "Single" then
							set show_is_series of temp_show_info to false
						end if
						
						set end of temp_show_progress to "Series: " & show_is_series of temp_show_info
						set progress additional description to my listtostring("add_show(" & caller & ")", temp_show_progress, return)
						set progress completed steps to 4
						my logger(true, "add_show_info(" & caller & ")", "INFO", "(Auto) show_is_series: " & show_is_series of temp_show_info)
					on error errmsg
						my logger(true, "add_show_info(" & caller & ")", "WARN", "(Auto) " & show_title of temp_show_info & " NOT added, errmsg: " & errmsg)
						exit repeat
					end try
				end if
				
				--We are now outside of the maunual/automatic loop.  Thee question below pertain to all shows when being added.
				-- hdhr_skip_multiple_bool 
				
				
				--   set hdhr_skip_multiple_bool to false
				--	set temp_show_air_date to missing value
				--	set temp_show_dir to missing value
				--	set temp_show_transcode to missing value
				
				set Time_slide to 0
				
				if temp_show_air_date is missing value then
					--FIX error "Can't get StartTime of \"\"." number -1728 from StartTime of "" -manually adding a show past grid
					try
						if (weekday of my epoch2datetime("hdhrGRID(" & caller & ")", (my getTfromN(StartTime of item i3 of hdhrGRID_response)))) as text is not (weekday of (current date) as text) then
							set Time_slide to 1
						end if
					on error errmsg
						my logger(true, "add_show_info(" & caller & ")", "WARN", "Time Slide defaulted to 0, errmsg: " & errmsg)
						set Time_slide to 0
						set default_record_day to weekday of (current date) as text
					end try
				else
					set default_record_day to temp_show_air_date
				end if
				
				
				--NEW
				set sports_ball_bool to "No"
				try
					if "Sports" is in show_tags of temp_show_info then
						set sports_ball_bool to button returned of (display dialog quote & show_title of temp_show_info & quote & return & return & "Is listed as a Sport" & return & "Would you like to add an additional 30 minutes past the scheduled time, to ensure the whole game is captured?" buttons {"Run", "No", "Yes"} default button 3 cancel button 1 with title my check_version_dialog() giving up after Dialog_timeout with icon temp_icon)
						if sports_ball_bool is "Yes" then
							set show_is_sport of temp_show_info to true
						end if
					end if
				end try
				
				if show_is_series of temp_show_info is true then
					set show_air_date of temp_show_info to (choose from list {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"} default items default_record_day with title my check_version_dialog() OK button name "Next.." cancel button name Running_icon & " Run" with prompt "Select the days you wish to record." & return & "A \"Series\" can select multiple days." with multiple selections allowed without empty selection allowed)
					my logger(true, "add_show_info()", "INFO", "(Manual) show_air_date: " & my listtostring("add_show", show_air_date of temp_show_info, ","))
				end if
				--choose from list show_air_date of temp_show_info with prompt "Test1"
				if show_air_date of temp_show_info is false then
					return
					--fall back into the idle() loop 
				end if
				if show_is_series of temp_show_info is false then
					if hdhrGRID_response is {""} then
						set show_air_date of temp_show_info to (choose from list {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"} default items default_record_day with title my check_version_dialog() OK button name "Next.." cancel button name Running_icon & " Run" with prompt "Select the day you wish to record." & return & "A \"Single\" can only select 1 day." without empty selection allowed)
						--	choose from list show_air_date of temp_show_info with prompt "test2"
						if show_air_date of temp_show_info is false then
							return
						end if
						--set temp_show_air_date to show_air_date of temp_show_info
						my logger(true, "add_show_info(" & caller & ")", "INFO", "(Manual) show_air_date: " & my listtostring("add_show2()", show_air_date of temp_show_info, ","))
					else
						set show_air_date of temp_show_info to (weekday of (my epoch2datetime("hdhrGRID6(" & caller & ")", (my getTfromN(StartTime of item i3 of hdhrGRID_response)))) as text) as list
						--	choose from list show_air_date of temp_show_info with prompt "Test3"
						my logger(true, "add_show_info(" & caller & ")", "INFO", "(Auto) show_air_date: " & show_air_date of temp_show_info)
					end if
				end if
				
				set end of temp_show_progress to "When: " & my listtostring("add_show_info(show_air_date)", show_air_date of temp_show_info, ", ")
				set progress additional description to my listtostring("add_show_info(" & caller & ")", temp_show_progress, return)
				set progress completed steps to 5
				--else
				--set show_air_date of temp_show_info to temp_show_air_date
				--end if
				--	set temp_show_air_date to show_air_date of temp_show_info
				
				
				if does_transcode of item tuner_offset of HDHR_DEVICE_LIST is 1 then
					--!! temp_show_transcode
					if temp_show_transcode is missing value then
						set show_transcode_response to (choose from list {"None: Does not transcode, will save as MPEG2 stream.", "heavy: Transcode with same settings", "mobile: Transcode not exceeding 1280x720 30fps", "internet720: Low bit rate, not exceeding 1280x720 30fps", "internet480: Low bit rate not exceeding 848x480/640x480 for 16:9/4:3 30fps", "internet360: Low bit rate not exceeding 640x360/480x360 for 16:9/4:3 30fps", "internet240: Low bit rate not exceeding 432x240/320x240 for 16:9/4:3 30fps"} with prompt "Please choose the transcode level on the file" with title my check_version_dialog() default items {"None: Does not transcode, will save as MPEG2 stream."} OK button name "Next" cancel button name Running_icon & " Run")
						try
							set show_transcode of temp_show_info to word 1 of item 1 of show_transcode_response
							--my logger(true, "add_show_info2()", "INFO", word 1 of item 1 of show_transcode_response)
						on error errmsg
							set show_transcode of temp_show_info to "None"
							my logger(true, "add_show_info(" & caller & " transcode)", "INFO", "User clicked \"Run\", errmsg: " & errmsg)
							return false
						end try
					else
						set show_transcode of temp_show_info to temp_show_transcode
					end if
				else
					set show_transcode of temp_show_info to "None"
				end if
				--set temp_show_transcode to show_transcode of temp_show_info
				set end of temp_show_progress to "Transcode: " & show_transcode of temp_show_info
				set progress additional description to my listtostring("add_show_info(" & caller & ")", temp_show_progress, return)
				set progress completed steps to 6
				my logger(true, "add_show_info(" & caller & ")", "INFO", "Transcode: " & show_transcode of temp_show_info)
				
				set model_response to ""
				
				set progress description to "Choose Folder..."
				set Temp_dir to alias "Volumes:"
				set update_folder_result to true
				set failed_showdir to {}
				if temp_show_dir is missing value then
					repeat until Temp_dir is not alias "Volumes:" and update_folder_result = true
						try
							set Temp_dir to show_dir of last item of Show_info
						end try
						try
							if update_folder_result = true then
								set show_dir of temp_show_info to choose folder with prompt "Select Show location" default location Temp_dir
							else if update_folder_result = false then
								set show_dir of temp_show_info to choose folder with prompt "Unable to write to location:" & return & (failed_showdir as text) & return & "Select another location" default location Temp_dir
							end if
						on error errmsg
							my logger(true, "add_show_info(" & caller & ")", "ERROR", "Unable to select show location, errmsg: " & errmsg)
							exit repeat
						end try
						if show_dir of temp_show_info is not Temp_dir then
							set Temp_dir to show_dir of temp_show_info
						end if
						set update_folder_result to my update_folder("add_show_info(" & caller & ")", show_dir of temp_show_info)
						set failed_showdir to show_dir of temp_show_info
					end repeat
				else
					set show_dir of temp_show_info to temp_show_dir
				end if
				--set temp_show_dir to show_dir of temp_show_info
				--FIX We error here if we click "Cancel" in the dialog.  We may need to return out of function if error occurs with the folder selection.
				set end of temp_show_progress to "Where: " & POSIX path of show_dir of temp_show_info
				my logger(true, "add_show_info(" & caller & ")", "INFO", "Show Directory: " & show_dir of temp_show_info)
				set show_temp_dir of temp_show_info to show_dir of temp_show_info
				--	my logger(true, "add_show_info(" & caller & ")", "WARN", show_title of temp_show_info & " VV MATCH?")
				set maybe_dupe_show to false
				repeat with i from 1 to length of Show_info
					--my logger(true, "add_show_info(" & caller & ")", "WARN", show_title of temp_show_info & " TEST")
					if show_title of temp_show_info is show_title of item i of Show_info and show_active of item i of Show_info = true then
						my logger(true, "add_show_info(" & caller & ")", "WARN", show_title of temp_show_info & " may be a dupe")
						set maybe_dupe_show to true
					end if
				end repeat
				if maybe_dupe_show = true then
					set maybe_dupe_show_response to button returned of (display dialog "The show name matches another recording, do you wish to proceed?" buttons {"Abort", "Add Anyways"} default button 1 with title my check_version_dialog() giving up after Dialog_timeout with icon stop)
					if maybe_dupe_show_response is "Abort" then
						exit repeat
					end if
				end if
				--commit the temp_show_info to show_info 
				set end of Show_info to temp_show_info
				
				set progress additional description to my listtostring("add_show(" & caller & ")", temp_show_progress, return)
				set progress completed steps to 7
				if hdhr_skip_multiple_bool is true then
					set temp_show_air_date to show_air_date of temp_show_info
					set temp_show_dir to show_dir of temp_show_info
					set temp_show_transcode to show_transcode of temp_show_info
					set temp_is_series to show_is_series of temp_show_info
				end if
				
				--end repeat 
				--end if
				my logger(true, "add_show_info(" & caller & ")", "DEBUG", "Adding temp_show_info to end of show_info, count: " & length of Show_info)
				--display dialog show_id of last item of show_info
				set show_next of last item of Show_info to my nextday("add_show_info(" & caller & ")", show_id of temp_show_info)
				my validate_show_info("add_show_info(" & caller & ")", show_id of last item of Show_info, false)
				my update_show("add_show_info(" & caller & ")", show_id of last item of Show_info, false)
				my save_data("add_show_info(" & caller & ")")
				--log show_info
				display notification with title Add_icon & " Show Added! (" & hdhr_device & ")" subtitle "" & quote & show_title of last item of Show_info & quote & " at " & show_time of last item of Show_info
				set progress description to "This show has been added!"
				set progress additional description to "Show: " & quote & show_title of last item of Show_info & quote & " at " & show_time of last item of Show_info
				my repeatProgress(0.75, 4)
			end repeat
		end repeat
	else
		return false
	end if
	set hdhr_skip_multiple_bool to false
end add_show_info

on record_now(caller, the_show_id, opt_show_length)
	-- We should do very little validation here, aside from what is required to start a recording.  Qualifers belong in the code block that called us.
	-- FIX We need to return a true/false if this is successful.  We may be able to do this with showid2PID
	--display notification opt_show_length
	set i to my HDHRShowSearch(the_show_id)
	my update_folder("record_now(" & caller & ")", show_dir of item i of Show_info)
	set temp_show_end to my short_date("rec started", show_end of item i of Show_info, true, false)
	my update_show("record_now(" & caller & ")", the_show_id, true)
	set hdhr_device to hdhr_record of item i of Show_info
	set tuner_offset to my HDHRDeviceSearch("record_now(" & caller & ")", hdhr_device)
	if opt_show_length is not missing value then
		set temp_show_length to opt_show_length as number
	else
		set temp_show_length to show_length of item i of Show_info as number
	end if
	--my logger(true, "record_now(" & caller & ")", "ERROR", "hdhr_detected: " & hdhr_detected)
	--my logger(true, "record_now(" & caller & ")", "ERROR", "online_detected: " & online_detected)
	--skip recording, and mark it as complete if < 0
	if temp_show_length is less than 0 then
		my logger(true, "record_now(" & caller & ")", "ERROR", show_title of item i of Show_info & " has a duration of " & temp_show_length)
		--display notification "Negative duration: " & show_title of item i of show_info
	end if
	set checkDiskSpace_percent to 0
	set checkDiskSpace_temp to my checkDiskSpace("record_now(" & caller & ")", (POSIX path of (show_temp_dir of item i of Show_info)))
	set checkDiskSpace_percent to item 2 of checkDiskSpace_temp
	set checkDiskSpace_path to item 1 of checkDiskSpace_temp
	--if checkDiskSpace_percent is 95 then
	if checkDiskSpace_percent is less than or equal to 95 then
		my logger(true, "record_now(" & caller & ")", "INFO", "Path: " & quote & checkDiskSpace_path & quote & " is " & checkDiskSpace_percent & "% full")
		--if checkDiskSpace_percent < 95 then
		if show_transcode of item i of Show_info is missing value or show_transcode of item i of Show_info is "None" then
			--This will not record a show if we are running it in script editor.
			if Local_env does not contain "Editor" then
				do shell script "caffeinate -i curl -H '" & show_id of item i of Show_info & "' -H 'show_end:" & temp_show_end & "' -H 'appname:" & name of me & "' '" & BaseURL of item tuner_offset of HDHR_DEVICE_LIST & ":5004" & "/auto/v" & show_channel of item i of Show_info & "?duration=" & (temp_show_length) & "' -o " & quoted form of (POSIX path of (show_temp_dir of item i of Show_info) & show_title of item i of Show_info & "_" & my short_date("record_now0", current date, true, true) & ".m2ts") & "> /dev/null 2>&1 &"
				
				
				--do shell script "caffeinate -i curl -H '" & show_id of item i of show_info & "' '" & BaseURL of item tuner_offset of HDHR_DEVICE_LIST & ":5004" & "/auto/v" & show_channel of item i of show_info & "?duration=" & (temp_show_length) & "' -o " & quoted form of (POSIX path of (show_temp_dir of item i of show_info) & show_title of item i of show_info & "_" & my short_date("record_now0", current date, true, true) & ".m2ts") & "> /dev/null 2>&1 &" 
				my logger(true, "record_now(" & caller & ")", "DEBUG", "caffeinate -i curl -H '" & show_id of item i of Show_info & "' -H 'show_end:" & temp_show_end & "' -H 'appname:" & name of me & "' '" & BaseURL of item tuner_offset of HDHR_DEVICE_LIST & ":5004" & "/auto/v" & show_channel of item i of Show_info & "?duration=" & (temp_show_length) & "' -o " & quoted form of (POSIX path of (show_temp_dir of item i of Show_info) & show_title of item i of Show_info & "_" & my short_date("record_now0", current date, true, true) & ".m2ts") & "> /dev/null 2>&1 &")
				my logger(true, "record_now(" & caller & ")", "INFO", "\"" & show_title of item i of Show_info & "\" started recording for " & my ms2time("record_now(" & caller & ")", temp_show_length, "s", 3))
				(*
				if (curl_http_return is less than 200) or curl_http_return is greater than or equal to 300 then
				my logger(true, "record_now(" & caller & ")", "WARN", "Curl returned the following code, this is expected: " & curl_http_return)
			end if
		*)
			else
				my logger(true, "record_now(" & caller & ")", "INFO", "Record function surpressed in DEV")
			end if
		else
			if Local_env does not contain "Editor" then
				
				do shell script "caffeinate -i curl -H '" & show_id of item i of Show_info & "' '" & BaseURL of item tuner_offset of HDHR_DEVICE_LIST & ":5004" & "/auto/v" & show_channel of item i of Show_info & "?duration=" & (temp_show_length) & "&transcode=" & show_transcode of item i of Show_info & "' -o " & quoted form of (POSIX path of (show_temp_dir of item i of Show_info) & show_title of item i of Show_info & "_" & my short_date("record_now1", current date, true, true) & ".mkv") & "> /dev/null 2>&1 &"
				
				my logger(true, "record_now(" & caller & ")", "INFO", "caffeinate -i curl -H '" & show_id of item i of Show_info & "' '" & BaseURL of item tuner_offset of HDHR_DEVICE_LIST & ":5004" & "/auto/v" & show_channel of item i of Show_info & "?duration=" & (temp_show_length) & "&transcode=" & show_transcode of item i of Show_info & "' -o " & quoted form of (POSIX path of (show_temp_dir of item i of Show_info) & show_title of item i of Show_info & "_" & my short_date("record_now1", current date, true, true) & ".mkv") & "> /dev/null 2>&1 &")
				my logger(true, "record_now(" & caller & ")", "INFO", "\"" & show_title of item i of Show_info & "\" started recording for " & temp_show_length & " with " & show_transcode of item i of Show_info)
			else
				my logger(true, "record_now(" & caller & ")", "INFO", "Record function surpressed in DEV")
			end if
		end if
		set show_recording of item i of Show_info to true
	else
		my logger(true, "record_now(" & caller & ")", "INFO", "The show " & quote & show_title of item i of Show_info & quote & " can not be recorded. " & quote & checkDiskSpace_path & quote & " is " & checkDiskSpace_percent & " full")
	end if
	if item 2 of my showid2PID("record_now(" & caller & ")", show_id of item i of Show_info, false, true) is {} then
		my logger(true, "record_now(" & caller & ")", "ERROR", quote & show_id of item i of Show_info & quote & " has failed to start recording")
	end if
	--display notification "Recording " & show_title of item i of show_info & " until " & show_end of item i of show_info
	--display dialog show_end of item i of show_info as text 
	--set show_end of item of show_info to (current date) + (show_length of item i of show_info as number)
	
	--	end if 
end record_now

(*  INACTIVE
 on sort_show_list(caller)
	set show_list_deactive to {}
	set show_list_active to {}
	set show_list_later to {}
	set show_list_recording to {}
	set show_list_up to {}
	set show_list_up2 to {}
	set show_list_soon to {}
	my logger(true, "sort_show_list(" & caller & ")", "DEBUG", "show_info length: " & length of show_info)
	repeat with i from 1 to length of show_info
		
		if show_recording of item i of show_info is true then
			set end of show_list_recording to item i of show_info
		end if
		if show_active of item i of show_info is false then
			set end of show_list_deactive to item i of show_info
		end if
		
		if ((show_next of item i of show_info) - (current date)) is less than 4 * hours and show_active of item i of show_info is true and show_recording of item i of show_info is false then
			if ((show_next of item i of show_info) - (current date)) is greater than 1 * hours then
				set end of show_list_up to item i of show_info
			else
				set end of show_list_soon to item i of show_info
			end if
			
		end if
		
		if ((show_next of item i of show_info) - (current date)) is greater than or equal to 4 * hours and (date (date string of (current date))) is (date (date string of (show_next of item i of show_info))) and show_active of item i of show_info is true and show_recording of item i of show_info is false then
			set end of show_list_up2 to item i of show_info
		end if
		
		if (date (date string of (current date))) is less than (date (date string of (show_next of item i of show_info))) and show_active of item i of show_info is true then
			set end of show_list_later to item i of show_info
		end if
		
	end repeat
	set temp_return to show_list_recording & show_list_soon & show_list_up & show_list_up2 & show_list_later & show_list_deactive
	my logger(true, "sort_show_list(" & caller & ")", "DEBUG", "show_info length: " & length of temp_return)
	return temp_return
end sort_show_list
*)

on HDHRShowSearch(the_show_id)
	--log "show_offset: " & the_show_id
	if length of Show_info is greater than 0 then
		repeat with i from 1 to length of Show_info
			if show_id of item i of Show_info is the_show_id then
				--log "show_offset2: " & show_id of item i of show_info
				return i
			end if
		end repeat
		--FIX Added this, so we always return something
		return 0
	end if
end HDHRShowSearch

on HDHRDeviceDiscovery(caller, hdhr_device)
	--log "HDHRDeviceDiscovery: " & caller
	if hdhr_device is not "" then
		set tuner_offset to my HDHRDeviceSearch(caller & "-> HDHRDeviceDiscovery0", hdhr_device)
		--set hdhr_lineup of item tuner_offset of HDHR_TUNERS to my HDHR_api(lineup_url of item tuner_offset of HDHR_TUNERS, "", "", "")
		my logger(true, "HDHRDeviceDiscovery(" & caller & ")", "DEBUG", "Pre getHDHR_Lineup")
		my getHDHR_Lineup("HDHRDeviceDiscovery(" & caller & ")", hdhr_device)
		my logger(true, "HDHRDeviceDiscovery(" & caller & ")", "DEBUG", "Pre getHDHR_Guide")
		my getHDHR_Guide("HDHRDeviceDiscovery(" & caller & ")", hdhr_device)
	else
		set HDHR_DEVICE_LIST to {}
		set progress additional description to "Discovering HDHomeRun Devices"
		set progress completed steps to 0
		my logger(true, "HDHRDeviceDiscovery(" & caller & ")", "INFO", "Pre Discovery")
		set hdhr_device_discovery to my hdhr_api("HDHRDeviceDiscovery(" & caller & ")", "", "", "", "/discover")
		--fix Update to "https://ipv4-api.hdhomerun.com/discover"
		--		--> {ModelNumber:"HDTC-2US", UpgradeAvailable:"20220203", BaseURL:"http://10.0.1.101:80", FirmwareVersion:"20220125", DeviceAuth:"pP60GFYQSja9tKyA4iwcpzcG", FirmwareName:"hdhomeruntc_atsc", FriendlyName:"HDHomeRun EXTEND", LineupURL:"http://10.0.1.101:80/lineup.json", TunerCount:2, DeviceID:"105404BE"}
		
		--set end of hdhr_device_discovery to {{ModelNumber:"HDTC-2US", UpgradeAvailable:"20210624", BaseURL:"http://10.0.1.101:80", FirmwareVersion:"20210210", DeviceAuth:"nrwqkmEpZNhIzf539VfjHyYP", FirmwareName:"hdhomeruntc_atsc", FriendlyName:"HDHomeRun EXTEND", LineupURL:"http://10.0.1.101:80/lineup.json", TunerCount:2, DeviceID:"XX5404BE"}}
		my logger(true, "HDHRDeviceDiscovery(" & caller & ")", "INFO", "POST Discovery, length: " & length of hdhr_device_discovery)
		set progress total steps to length of hdhr_device_discovery
		repeat with i from 1 to length of hdhr_device_discovery
			repeat 1 times
				--Check for legacy devices 
				--set item i of hdhr_device_discovery to item i of hdhr_device_discovery & {Legacy:1}
				set progress completed steps to i
				try
					set is_legacy to true
					log Legacy of item i of hdhr_device_discovery
					my logger(true, "HDHRDeviceDiscovery(" & caller & ")", "WARN", "Unable to add tuner, device is legacy")
				on error errmsg
					set is_legacy to false
				end try
				
				--This is to weed out invalid devices.
				try
					set is_valid to true
					log DeviceID of item i of hdhr_device_discovery
				on error errmsg
					set is_valid to false
					my logger(true, "HDHRDeviceDiscovery(" & caller & ")", "WARN", "Unable to add tuner, device has no DeviceID, err: " & errmsg)
				end try
				if is_valid = false then
					exit repeat
				end if
				
				try
					set tuner_transcode_temp to Transcode of item i of hdhr_device_discovery
				on error errmsg
					my logger(true, "HDHRDeviceDiscovery(" & caller & ")", "WARN", "Unable to determine transcode settings, err: " & errmsg)
					set tuner_transcode_temp to 0
				end try
				
				set end of HDHR_DEVICE_LIST to {hdhr_lineup_update:missing value, hdhr_guide_update:missing value, discover_url:DiscoverURL of item i of hdhr_device_discovery, lineup_url:LineupURL of item i of hdhr_device_discovery, device_id:DeviceID of item i of hdhr_device_discovery, does_transcode:tuner_transcode_temp, hdhr_lineup:missing value, hdhr_guide:missing value, hdhr_model:missing value, channel_mapping:missing value, BaseURL:BaseURL of item i of hdhr_device_discovery, statusURL:(BaseURL of item i of hdhr_device_discovery & "/status.json"), is_active:true, is_active_reason:"Newly Added Tuner"}
				
				--log statusURL of last item of HDHR_DEVICE_LIST
				--log "HDHRDeviceDiscovery25"
				if is_legacy is true then
					my logger(true, "HDHRDeviceDiscovery(" & caller & ")", "WARN", hdhr_device & " is a legacy device, so we will deactivate it.")
					set is_active of last item of HDHR_DEVICE_LIST to false
					set is_active_reason of last item of HDHR_DEVICE_LIST to "Legacy Device"
				else
					my logger(true, "HDHRDeviceDiscovery(" & caller & ")", "INFO", "Added: " & device_id of last item of HDHR_DEVICE_LIST)
				end if
			end repeat
		end repeat
		
		--clear all devices, to see how we react:
		--set HDHR_DEVICE_LIST to {}
		--Add a fake device entry to make sure we dont break this for multiple devices.
		--set end of HDHR_DEVICE_LIST to {hdhr_lineup_update:missing value, hdhr_guide_update:missing value, discover_url:"http://10.0.1.101/discover.json", lineup_url:"http://10.0.1.101/lineup.json", device_id:"XX105404BE", does_transcode:0, hdhr_lineup:missing value, hdhr_guide:missing value, hdhr_model:missing value, channel_mapping:missing value, BaseURL:BaseURL of item 1 of hdhr_device_discovery, statusURL:"http://10.0.1.101/status.json", Legacy:1, is_active:true}
		
		--We now have a list of tuners, via a list of records in HDHR_TUNERS, now we want to pull a lineup, and a guide. 
		
		if length of HDHR_DEVICE_LIST is greater than 0 then
			--if length of hdhr_device_discovery is greater than 0 then 
			repeat with i2 from 1 to length of HDHR_DEVICE_LIST
				my HDHRDeviceDiscovery("HDHRDeviceDiscovery1(" & caller & ")", device_id of item i2 of HDHR_DEVICE_LIST)
				delay 0.1
			end repeat
			my logger(true, "HDHRDeviceDiscovery(" & caller & ", " & hdhr_device & ")", "INFO", "Completed Guide and Lineup Updates")
		else
			activate me
			set HDHRDeviceDiscovery_none to display dialog "No supported HDHR devices can be found" buttons {"Quit", "Rescan"} default button 2 cancel button 1 with title my check_version_dialog() giving up after Dialog_timeout * 0.5 with icon stop
			if button returned of HDHRDeviceDiscovery_none is "Rescan" then
				my logger(true, "HDHRDeviceDiscovery(" & caller & ")", "INFO", "No Devices Added")
				my HDHRDeviceDiscovery("no_devices", "")
			end if
			
			if button returned of HDHRDeviceDiscovery_none is "Quit" then
				if Local_env does not contain "Editor" then
					quit {}
				end if
			end if
		end if
		--Now that we pulled new data, we need to update the shows we have.
		my update_show("HDHRDeviceDiscovery(" & caller & ")", "", true)
		my build_channel_list("HDHRDeviceDiscovery(" & caller & ")", "")
	end if
end HDHRDeviceDiscovery

on HDHRDeviceSearch(caller, hdhr_device)
	--my logger(true, "HDHRDeviceSearch(" & caller & ")", "INFO", "Querying " & hdhr_device & "...")
	--log "HDHRDeviceSearch: " & caller & ":" & hdhr_device
	--We need the ability to know which item offset our device_id lives at, so we can update or pull records appropriately.
	repeat with i from 1 to length of HDHR_DEVICE_LIST
		if (device_id of item i of HDHR_DEVICE_LIST as text) is (hdhr_device as text) and is_active of item i of HDHR_DEVICE_LIST is true then
			--	my logger(true, "HDHRDeviceSearch(" & caller & ")", "DEBUG", hdhr_device & " Match offset: " & i)
			return i
		end if
	end repeat
	my logger(true, "HDHRDeviceSearch(" & caller & ")", "WARN ", "No match for " & hdhr_device & " out of " & length of HDHR_DEVICE_LIST & " possible items")
	return 0
end HDHRDeviceSearch

on hdhr_api(caller, hdhr_ready, hdhr_IP, hdhr_PORT, hdhr_endpoint) --FIX This is kind of a hot mess right now.
	try
		--error -128
		--with timeout of 8 seconds
		set temp_err to "0"
		--log "raw_hdhrapi: " & hdhr_IP & hdhr_PORT & hdhr_endpoint
		if hdhr_IP is in {"", {}, missing value} and hdhr_ready is in {"", {}, missing value} then
			set hdhr_IP to "https://my.hdhomerun.com"
		end if
		--log "raw_hdhrapi2: " & hdhr_IP & hdhr_PORT & hdhr_endpoint
		
		if hdhr_ready is in {"", {}, missing value} then
			set temp_err to "1"
			set temp_endpoint to hdhr_IP & hdhr_PORT & hdhr_endpoint
			set hdhr_api_result to (fetch JSON from hdhr_IP & hdhr_PORT & hdhr_endpoint with cleaning feed)
		else
			--Connection issue here hangs up jsonhelper
			set temp_err to "2"
			set temp_endpoint to hdhr_ready
			set hdhr_api_result to (fetch JSON from hdhr_ready with cleaning feed)
		end if
		--set HDHR_api_result_cached to hdhr_api_result
		--set HDHR_api_result_date_cached to current date
		set temp_err to "3"
		my logger(true, "hdhr_api(" & caller & ")", "DEBUG", "API call: " & temp_endpoint)
		set Hdhr_detected to true
		return hdhr_api_result
		--end timeout
	on error errmsg
		my logger(true, "hdhr_api(" & caller & ")", "ERROR", "API timeout, errmsg: " & errmsg & " at " & hdhr_endpoint)
		set Hdhr_detected to false
		return {}
	end try
end hdhr_api

on getHDHR_Guide(caller, hdhr_device)
	set progress total steps to 1
	set progress completed steps to 0
	set progress additional description to "Guide Refresh: " & hdhr_device
	--log "hdhr_guideCaller: " & caller
	try
		set tuner_offset to my HDHRDeviceSearch("getHDHR_Guide0", hdhr_device)
		--	log "deviceID: " & device_id of item tuner_offset of HDHR_DEVICE_LIST
		--log discover_url of item tuner_offset of HDHR_DEVICE_LIST
		try
			with timeout of 7 seconds
				set hdhr_discover_temp to my hdhr_api("getHDHR_Guide0()", discover_url of item tuner_offset of HDHR_DEVICE_LIST, "", "", "")
			end timeout
		on error
			set hdhr_guide_update of item tuner_offset of HDHR_DEVICE_LIST to ((current date) - 45 * minutes)
			set hdhr_discover_temp to missing value
		end try
		
		--Check to see if the firmware checker is working
		--set temp to hdhr_discover_temp
		--set hdhr_discover_temp to hdhr_discover_temp & {UpgradeAvailable:"20230401"}
		--if hdhr_discover_temp is not in {"", {}, missing value} then
		--display dialog "No HDHR device detected."
		--return false
		--end if
		--log "''''''''''"
		if hdhr_discover_temp is not equal to missing value then
			set device_auth to DeviceAuth of hdhr_discover_temp
			set hdhr_model of item tuner_offset of HDHR_DEVICE_LIST to ModelNumber of hdhr_discover_temp
			set hdhr_update to ""
			try
				set hdhr_update to UpgradeAvailable of hdhr_discover_temp
			on error
				set hdhr_update to false
			end try
			--log hdhr_update
			try
				--log hdhr_discover_temp
			on error errmsg
				--log errmsg
			end try
			if hdhr_update is not false then
				display notification "" with title "Firmware Update Available" subtitle hdhr_model of item tuner_offset of HDHR_DEVICE_LIST & " is ready to update."
			end if
			
			if caps_down of my isModifierKeyPressed("getHDHR_Guide", "caps", "Not in use") is true then
				-- set hdhr_guide_data to select file and read
			else
				set hdhr_guide_data to my hdhr_api("getHDHR_Guide1()", "http://api.hdhomerun.com/api/guide.php?DeviceAuth=" & device_auth, "", "", "")
			end if
			set hdhr_guide of item tuner_offset of HDHR_DEVICE_LIST to hdhr_guide_data
			set hdhr_guide_update of item tuner_offset of HDHR_DEVICE_LIST to current date
			my logger(true, "getHDHR_Guide(" & caller & ")", "INFO", "Updated Guide for " & hdhr_device)
			set progress completed steps to 1
		end if
	on error
		set progress completed steps to -1
		set progress additional description to "ERROR on Guide Refresh: " & hdhr_device
		my logger(true, "getHDHR_Guide(" & caller & ")", "ERROR", "ERROR on Guide Refresh: " & hdhr_device & ", will retry in 10 seconds")
		--my getHDHR_Guide("getHDHR_Guide_error", hdhr_device)
	end try
	--	display notification "Last Updated: " & (my short_date("getHDHR_Guide", current date, false)) with title hdhr_device subtitle "Guide and Lineup Data"
	--display dialog length of hdhr_guide_data
	--each item is a different channel, so we can walk these to pull information.  
end getHDHR_Guide

on getHDHR_Lineup(caller, hdhr_device)
	set progress total steps to 1
	set progress completed steps to 0
	set progress additional description to "LineUP Refresh: " & hdhr_device
	set tuner_offset to my HDHRDeviceSearch("getHDHR_Lineup0", hdhr_device)
	
	if caps_down of my isModifierKeyPressed("getHDHR_Lineup(" & caller & ")", "caps", "Not in use") is true then
		--do stuff
		--FIX  we need to re write the read file handler to allow other filrs to be read
	else
		try
			with timeout of 7 seconds
				set hdhr_lineup of item tuner_offset of HDHR_DEVICE_LIST to my hdhr_api("getHDHR_Lineup(" & caller & ")", lineup_url of item tuner_offset of HDHR_DEVICE_LIST, "", "", "")
				
			end timeout
		on error errmsg
			display dialog errmsg
			set hdhr_lineup of item tuner_offset of HDHR_DEVICE_LIST to missing value
		end try
	end if
	if hdhr_lineup of item tuner_offset of HDHR_DEVICE_LIST is not in {"", {}, missing value} then
		set hdhr_lineup_update of item tuner_offset of HDHR_DEVICE_LIST to current date
		my logger(true, "getHDHR_Lineup(" & caller & ")", "INFO", "Updated Lineup for " & hdhr_device)
		set progress completed steps to 1
		delay 0.1
	else
		my logger(true, "getHDHR_Lineup(" & caller & ")", "ERROR", "Unable to update lineup for " & hdhr_device)
	end if
end getHDHR_Lineup

on channel_guide(caller, hdhr_device, hdhr_channel, hdhr_time)
	my logger(true, "channel_guide()", "INFO", "caller: " & caller & ", hdhr_device: " & hdhr_device & ", hdhr_channel: " & hdhr_channel & ", hdhr_time: " & hdhr_time)
	set Time_slide to 0
	set tuner_offset to my HDHRDeviceSearch("channel_guide0(" & caller & ")", hdhr_device)
	my logger(true, "channel_guide0(" & caller & ")", "DEBUG", "tuner_offset: " & tuner_offset)
	set temp_guide_data to missing value
	set hdhr_guide_temp to {}
	
	if hdhr_time is not "" then
		--fix check for number?
		if (hdhr_time + 1) is less than hours of (current date) then
			set Time_slide to 1
		end if
		
		set hdhr_proposed_time to my datetime2epoch("channel_guide(" & caller & ")", (date (date string of ((current date) + Time_slide * days))) + hdhr_time * hours - (time to GMT)) as number
		set hdhr_proposed_time to my getTfromN(hdhr_proposed_time)
		--my logger(true, "channel_guide()", "INFO", "hdhr_proposed_time1: " & my epoch2show_time("channel_guide(" & caller & ")", my epoch2datetime("channel_guide0(" & caller & ")", hdhr_proposed_time)))
		my logger(true, "channel_guide()", "INFO", "hdhr_proposed_time2: " & my epoch2show_time("channel_guide(" & caller & ")", hdhr_proposed_time))
		--log "hdhr_proposed_time"
		--log hdhr_proposed_time
		--log "---"
	end if
	if HDHR_DEVICE_LIST is not in {missing value, {}, 0, ""} then
		
		--fix Result: error "Can't get length of missing value." number -1728 from length of missing value
		repeat with i from 1 to length of hdhr_guide of item tuner_offset of HDHR_DEVICE_LIST
			if hdhr_channel is GuideNumber of item i of hdhr_guide of item tuner_offset of HDHR_DEVICE_LIST then
				set temp_guide_data to item i of hdhr_guide of item tuner_offset of HDHR_DEVICE_LIST as record
				--log temp_guide_data as record 
			end if
		end repeat
		
		if temp_guide_data is missing value then
			
			--FIX some channels returning nothing.. display notification.
			my logger(true, "channel_guide(" & caller & ")", "ERROR", hdhr_channel & " no longer exists on " & hdhr_device & ", exiting...")
			return false
		end if
		
		if hdhr_time is "" then
			return temp_guide_data as record
		end if
		
		--We need to now parse the json object and try to get the start and end times.
		repeat with i2 from 1 to length of Guide of temp_guide_data
			--log "$1: " & my getTfromN(StartTime of item i2 of Guide of temp_guide_data)
			--log "$2: " & hdhr_proposed_time
			try
				--log "$3 : " & my getTfromN(EndTime of item i2 of Guide of temp_guide_data)
				--log " "
			on error
				my logger(true, "channel_guide()", "ERROR", "Unable to parse: " & EndTime of item i2 of Guide of temp_guide_data)
				--display notification "NOTOK 1: " & EndTime of item i2 of Guide of temp_guide_data as text
			end try
			--log StartTime of item i2 of Guide of temp_guide_data
			--log EndTime of item i2 of Guide of temp_guide_data
			if (hdhr_proposed_time) is greater than or equal to my getTfromN(StartTime of item i2 of Guide of temp_guide_data) and (hdhr_proposed_time) is less than my getTfromN(EndTime of item i2 of Guide of temp_guide_data) then
				--log "11: " & (hdhr_proposed_time) & "=" & my getTfromN(StartTime of item i2 of Guide of temp_guide_data)
				try
					--log "2: " & (hdhr_proposed_time) & "less than or equal to" & my getTfromN(EndTime of item i2 of Guide of temp_guide_data)
					--try
					--log "$Match"
					--end try
					
					return item i2 of Guide of temp_guide_data
					--					end if
				on error
					my logger(true, "channel_guide(" & caller & ")", "ERROR", "Unable to match a show " & i2)
				end try
			end if
		end repeat
		
		--return temp_guide_data
		--if temp_guide_data is not missing value then
		--	repeat with i2 from 1 to length of (Guide of temp_guide_data)
		--		--log "temp_data:"
		--		return i2 of Guide of temp_guide_data
		--log item i2 of Guide of temp_guide_data
		--	end repeat
		--end if
	else
		my logger(true, "channel_guide(" & caller & ")", "ERROR", "HDHR_DEVICE_LIST has an empty value")
	end if
	return {}
end channel_guide

on update_show(caller, the_show_id, force_update)
	if the_show_id is "" then
		repeat with i2 from 1 to length of Show_info
			my update_show("update_show" & i2 & "(" & caller & ")", show_id of item i2 of Show_info, false)
		end repeat
	else
		--	set progress description to "Loading ..."
		--    set progress additional description to 
		--	set progress completed steps to 0 
		set show_offset to my HDHRShowSearch(the_show_id)
		--set i to my HDHRShowSearch(the_show_id)
		set progress description to "Updating Show: " & show_title of item show_offset of Show_info
		set progress total steps to 7
		set time2show_next to (show_next of item show_offset of Show_info) - (current date)
		--We should allow the time we can grab this to the end of the show. VVV
		set progress additional description to "Updating Show: " & show_title of item show_offset of Show_info
		if time2show_next is less than or equal to 5 * hours and time2show_next is greater than or equal to -60 and show_active of item show_offset of Show_info is true or force_update is true then
			my logger(true, "update_show(" & caller & ")", "INFO", "Updating \"" & show_title of item show_offset of Show_info & "\" " & the_show_id)
			set hdhr_response_channel to {}
			set hdhr_response_channel to my channel_guide("update_shows(" & caller & ")", hdhr_record of item show_offset of Show_info, show_channel of item show_offset of Show_info, show_time of item show_offset of Show_info)
			
			--debug trap
			try
				--log hdhr_response_channel
			on error errmsg
				my logger(true, "update_shows(" & caller & ")", "ERROR", errmsg)
			end try
			set progress completed steps to 1
			--	try
			if length of hdhr_response_channel is greater than 0 then
				--try
				
				--on error 
				--	my logger(true, "update_show()", "ERROR", "Unable to set title of show") 
				--end try
				
				
				try
					set hdhr_response_channel_title to title of hdhr_response_channel
				on error errmsg
					my logger(true, "update_shows(" & caller & ")", "WARN", "Unable to set title of show name, ")
				end try
				
				try
					set hdhr_response_channel_title to hdhr_response_channel_title & " " & EpisodeNumber of hdhr_response_channel
				on error errmsg
					my logger(true, "update_shows(" & caller & ")", "WARN", "Unable to set EpisodeNumber of " & quote & hdhr_response_channel_title & quote & ", errmsg: " & errmsg)
				end try
				
				try
					set hdhr_response_channel_title to hdhr_response_channel_title & " " & EpisodeTitle of hdhr_response_channel
				on error errmsg
					my logger(true, "update_shows(" & caller & ")", "WARN", "Unable to set EpisodeTitle of " & quote & hdhr_response_channel_title & quote & ", errmsg: " & errmsg)
				end try
				
				try
					set show_seriesid of item show_offset of Show_info to SeriesID of hdhr_response_channel
				on error errmsg
					my logger(true, "update_shows(" & caller & ")", "WARN", "Unable to set show_seriesid, errmsg: " & errmsg)
				end try
				
				try
					set show_tags of item show_offset of Show_info to Filter of hdhr_response_channel
				on error errmsg
					my logger(true, "update_shows(" & caller & ")", "WARN", "Unable to set show_tags, errmsg: " & errmsg)
				end try
				
				
				set progress completed steps to 2
				if show_title of item show_offset of Show_info is not equal to hdhr_response_channel_title then
					--					my logger(true, "update_showsDEBUG(" & caller & ")", "INFO", "FAIL?")
					my logger(true, "update_shows(" & caller & ")", "INFO", "Title changed from " & quote & show_title of item show_offset of Show_info & quote & " to " & quote & hdhr_response_channel_title & quote)
					set show_title of item show_offset of Show_info to hdhr_response_channel_title
				end if
				set progress completed steps to 3
				try
					if show_is_sport of item show_offset of Show_info = false then
						if (show_length of item show_offset of Show_info as number) is not equal to (((EndTime of hdhr_response_channel) - (StartTime of hdhr_response_channel)) div 60 as number) then
							my logger(true, "update_shows(" & caller & ")", "INFO", "Show length changed to " & ((EndTime of hdhr_response_channel) - (StartTime of hdhr_response_channel)) div 60 & " minutes")
						end if
						set show_length of item show_offset of Show_info to ((EndTime of hdhr_response_channel) - (StartTime of hdhr_response_channel)) div 60
					else
						my logger(true, "update_shows_sport(" & caller & ")", "INFO", "Show length NOT changed. Show is sport")
					end if
				on error
					my logger(true, "update_shows()", "ERROR", "Unable to set length of " & show_title of item show_offset of Show_info)
					--					display notification "3: " & show_title of item i of show_info
				end try
				
				set progress completed steps to 4
				try
					set temp_show_time to my epoch2show_time("hdhrGRID(7)", my getTfromN((StartTime of hdhr_response_channel)))
					
					if (temp_show_time as number) is not equal to (show_time of item show_offset of Show_info as number) then
						my logger(true, "update_shows(" & caller & ")", "INFO", "Show time changed from " & show_time of item show_offset of Show_info & " to " & temp_show_time)
						set show_time of item show_offset of Show_info to my epoch2show_time("hdhrGRID(8)", my getTfromN((StartTime of hdhr_response_channel)))
						
						set show_next of item show_offset of Show_info to my nextday("update_show(" & caller & ")", show_id of item show_offset of Show_info)
						--We may be to run next_day logic  
					end if
				on error errmsg
					my logger(true, "update_shows(" & caller & ")", "ERROR", "Unable to set show_time for this show, error: " & errmsg)
				end try
				set progress completed steps to 5
				--display dialog (show_next of item i of show_info) as text 
				--display dialog (show_length of item i of show_info) as text  
				
				if (show_next of item show_offset of Show_info) + ((show_length of item show_offset of Show_info) * minutes) is not equal to show_end of item show_offset of Show_info then
					set show_end of item show_offset of Show_info to (show_next of item show_offset of Show_info) + ((show_length of item show_offset of Show_info) * minutes)
					--display notification "Show Updated: " & show_title of item i of show_info
					my logger(true, "update_shows(" & caller & ")", "INFO", "Show end changed to " & show_end of item show_offset of Show_info)
				end if
			end if
			set progress completed steps to 6
			--on error errmsg
			--	my logger(true, "update_show()", "ERROR", "Unable to update " & show_title of item i of show_info & " : " & errmsg)
			--	try
			--		my logger(true, "update_show2()", "ERROR", length of show_info) 
			--	on error
			--		my logger(true, "update_show3()", "Unable to get length of show info")
			--	end try
			-- end try
			--my save_data("update_show")
			set progress completed steps to 7
		else
			my logger(true, "update_shows(" & caller & ")", "INFO", "Did not update the show " & show_title of item show_offset of Show_info & ", next_show in " & my ms2time("update_show1", ((show_next of item show_offset of Show_info) - (current date)), "s", 4))
		end if
	end if
end update_show

on save_data(caller)
	my logger(true, "save_data(" & caller & ")", "INFO", "Called")
	copy Show_info to temp_show_info
	if Local_env does not contain "Editor" then
		my show_info_dump("save_data(" & caller & ")", "", false)
	else
		my logger(true, "save_data(" & caller & ")", "INFO", "save_data() not run, we are in DEBUG mode")
		return true
	end if
	try
		if length of Show_info is greater than 0 then
			repeat with i5 from 1 to length of temp_show_info
				if show_active of item i5 of temp_show_info is true then
					set show_dir of item i5 of temp_show_info to (show_dir of item i5 of temp_show_info as text)
					set show_temp_dir of item i5 of temp_show_info to (show_temp_dir of item i5 of temp_show_info as text)
					set show_last of item i5 of temp_show_info to (show_last of item i5 of temp_show_info as text)
					set show_next of item i5 of temp_show_info to (show_next of item i5 of temp_show_info as text)
					set show_end of item i5 of temp_show_info to (show_end of item i5 of temp_show_info as text)
					set notify_recording_time of item i5 of temp_show_info to (notify_recording_time of item i5 of temp_show_info as text)
					set notify_upnext_time of item i5 of temp_show_info to (notify_upnext_time of item i5 of temp_show_info as text)
					
					set show_length of item i5 of temp_show_info to (show_length of item i5 of temp_show_info as number)
					set show_air_date of item i5 of temp_show_info to (show_air_date of item i5 of temp_show_info)
					set show_title of item i5 of temp_show_info to (show_title of item i5 of temp_show_info as text)
					set show_time of item i5 of temp_show_info to (show_time of item i5 of temp_show_info as number)
					set show_channel of item i5 of temp_show_info to (show_channel of item i5 of temp_show_info as text)
					
					try
						set show_seriesid of item i5 of temp_show_info to (show_seriesid of item i5 of temp_show_info as text)
					on error errmsg
						set item i5 of temp_show_info to item i5 of temp_show_info & {show_seriesid:""}
						my logger(true, "save_data_json", "INFO", "Added SeriesID to " & quote & show_title of item i5 of temp_show_info & quote)
					end try
					
					try
						set show_time_orig of item i5 of temp_show_info to (show_time_orig of item i5 of temp_show_info)
					on error errmsg
						set item i5 of temp_show_info to item i5 of temp_show_info & {show_time_orig:show_time of item i5 of temp_show_info as number}
						my logger(true, "save_data_json", "INFO", "Added show_time_orig to " & quote & show_title of item i5 of temp_show_info & quote)
					end try
					
					try
						set show_recorded_today of item i5 of temp_show_info to (show_recorded_today of item i5 of temp_show_info)
					on error errmsg
						set item i5 of temp_show_info to item i5 of temp_show_info & {show_recorded_today:false}
						my logger(true, "save_data_json", "INFO", "Added show_recorded_today to " & quote & show_title of item i5 of temp_show_info & quote)
					end try
					
					
					try
						set show_tags of item i5 of temp_show_info to show_tags of item i5 of temp_show_info as text
					on error errmsg
						set item i5 of temp_show_info to item i5 of temp_show_info & {show_tags:{}}
						my logger(true, "save_data_json", "INFO", "Added show_tags to " & quote & show_title of item i5 of temp_show_info & quote)
					end try
					
					try
						set show_is_sport of item i5 of temp_show_info to show_is_sport of item i5 of temp_show_info
					on error errmsg
						set item i5 of temp_show_info to item i5 of temp_show_info & {show_is_sport:false}
						my logger(true, "save_data_json", "INFO", "Added show_is_sport to " & quote & show_title of item i5 of temp_show_info & quote)
					end try
				else
					set item i5 of temp_show_info to ""
					my logger(true, "save_data_json", "DEBUG", "JSON: Removed a show, as it was deactivated")
				end if
			end repeat
			set temp_show_info to my emptylist(temp_show_info)
			--	set temp_show_info_json to (make JSON from temp_show_info)
			try
				try
					set ref_num to open for access file ((Config_dir) & Configfilename_json as text) with write permission
				on error errmsg
					my logger(true, "save_data(" & caller & ")", "ERROR", "Error reading the file, errmsg: " & errmsg)
				end try
				set eof of ref_num to 0
				set json_temp to {the_shows:temp_show_info, config:Hdhr_config}
				try
					set temp_show_info_json to (make JSON from json_temp)
				on error errmsg
					my logger(true, "save_data(" & caller & ")", "ERROR", "Error convert the file to JSON, errmsg: " & errmsg)
				end try
				if temp_show_info_json is "" then
					my logger(true, "save_data(" & caller & ")", "ERROR", "Error when attempting to save show list. Trying to recover")
					set json_temp to {the_shows:temp_show_info, config:{}}
					set temp_show_info_json to (make JSON from json_temp)
				end if
				my logger(true, "save_data(" & caller & ")", "DEBUG", temp_show_info_json)
				write temp_show_info_json to ref_num
				--write temp_show_info_json to ref_num
				--set x to {shows:{test:"test1", test2:"Test2"}, config:{test3:"test3"}} 
				my logger(true, "save_data(" & caller & ")", "INFO", "Saved " & length of Show_info & " shows to file")
			on error errmsg
				my logger(true, "save_data(" & caller & ")", "ERROR", "Unable to save JSON file: " & errmsg)
			end try
		else
			my logger(true, "save_data(" & caller & ")", "INFO", "No shows to save.")
			return false
		end if
	on error errmsg
		my logger(true, "save_data_end(" & caller & ")", "ERROR", "Unable to save JSON file: " & errmsg)
		try
			set save_data_oops to button returned of (display dialog "We ran into an error when attempting to save the config file" & return & quote & errmsg & quote & return & return & "What would you like to do?" buttons {"Save Again", "Exit without saving"} with title my check_version_dialog() giving up after Dialog_timeout with icon caution)
			if save_data_oops is "Save Again" then
				my save_data("save_data_retry(" & caller & ")")
				return
			end if
			if save_data_oops is "Exit without saving" then
				return false
			end if
		on error errmsg
			my logger(true, "save_data(" & caller & ")", "ERROR", "Much uh oh.  We errored out of another error, errmsg: " & errmsg)
		end try
		
	end try
	try
		close access ref_num
	on error errmsg
		my logger(true, "save_data_end(" & caller & ")", "ERROR", "We attempted to close a handler that was not open")
	end try
end save_data

on showPathVerify(caller, show_id)
	if show_id is "" then
		repeat with i3 from 1 to (length of Show_info)
			my showPathVerify("showPathVerify(" & caller & ")", show_id of item i3 of Show_info)
		end repeat
	else
		set show_offset to my HDHRShowSearch(show_id)
		try
			if my checkfileexists("showPathVerify(" & caller & ")", show_dir of item show_offset of Show_info) is false then
				my logger(true, "showPathVerify(" & caller & ")", "WARN", "The show, " & show_title of item show_offset of Show_info & " has a invalid save directory")
			else
				my logger(true, "showPathVerify(" & caller & ")", "INFO", "The show, " & show_title of item show_offset of Show_info & " has a valid save directory")
			end if
		on error errmsg
			my logger(true, "showPathVerify(" & caller & ")", "ERROR", "An error occured, errmsg: " & errmsg)
		end try
	end if
end showPathVerify
on checkfileexists(caller, filepath)
	try
		my logger(true, "checkfileexists(" & caller & ")", "INFO", filepath as text)
		--if class of filepath is not Çclass furlÈ then
		if class of filepath is not alias then
			my logger(true, "checkfileexists(" & caller & ")", "WARN", "filepath class is " & class of filepath)
			set filepath to POSIX file filepath
			my logger(true, "checkfileexists(" & caller & ")", "DEBUG", "filepath is now posix file")
		end if
		tell application "Finder" to return (exists filepath)
	on error errmsg
		my logger(true, "checkfileexists(" & caller & ")", "ERROR", "Finder reported: " & errmsg)
		return false
	end try
end checkfileexists

on read_data(caller)
	--read .config file, if .json is not available
	set hdhr_vcr_config_file to ((Config_dir) & Configfilename_json as text)
	(*
	if my checkfileexists("read_data(" & caller & ")", hdhr_vcr_config_file) is false and my checkfileexists("read_data(" & caller & ")", (config_dir) & configfilename as text) is true then
		my logger(true, "read_data(" & caller & ")", "INFO", "Using old .config file loader")
		my read_data_old()
		my save_data("read_data(old_config)")
		my read_data("read_data(old_config)")
		--If this works, just wow   
		return
	end if
	*)
	set ref_num to open for access hdhr_vcr_config_file
	try
		set hdhr_vcr_config_data to read ref_num
		set show_info_json to (read JSON from hdhr_vcr_config_data)
		set Show_info to the_shows of show_info_json
		set Hdhr_config to config of show_info_json
		--Try and load the config stuff, and erro gracefully if this fails.
		try
			my logger(true, "read_data(" & caller & ")", "INFO", "Config version: " & Config_version of Hdhr_config)
			
		on error errmsg
			
		end try
		
		my logger(true, "read_data(" & caller & ")", "INFO", "Loading config from \"" & POSIX path of hdhr_vcr_config_file & "\"...")
		repeat with i5 from 1 to length of Show_info
			try
				set show_dir of item i5 of Show_info to (show_dir of item i5 of Show_info as alias)
				set show_temp_dir of item i5 of Show_info to (show_temp_dir of item i5 of Show_info as alias)
			on error errmsg
				set show_dir of item i5 of Show_info to {}
				set show_temp_dir of item i5 of Show_info to {}
				my logger(true, "read_data(" & caller & ")", "ERROR", "A show has an invalid directory")
			end try
			
			set show_last of item i5 of Show_info to date (show_last of item i5 of Show_info as text)
			set show_next of item i5 of Show_info to date (show_next of item i5 of Show_info as text)
			set show_end of item i5 of Show_info to date (show_end of item i5 of Show_info as text)
			
			try
				if notify_recording_time of item i5 of Show_info is "missing value" then
					set notify_recording_time of item i5 of Show_info to missing value
				else
					set notify_recording_time of item i5 of Show_info to (notify_recording_time of item i5 of Show_info as text)
				end if
			on error errmsg
				my logger(true, "read_data()", "WARN", "Unable to change class of notify_recording_time, err: " & errmsg)
			end try
			
			
			try
				if notify_upnext_time of item i5 of Show_info is "missing value" then
					set notify_upnext_time of item i5 of Show_info to missing value
				end if
			on error errmsg
				my logger(true, "read_data()", "WARN", "Unable to change class of notify_upnext_time, err: " & errmsg)
			end try
			
			try
				if show_is_sport of item i5 of Show_info is "false" then
					set show_is_sport of item i5 of Show_info to false
				end if
				if show_is_sport of item i5 of Show_info is "true" then
					set show_is_sport of item i5 of Show_info to true
				end if
			on error errmsg
				my logger(true, "read_data()", "WARN", "Unable to change class of show_is_sport, err: " & errmsg)
			end try
			
			try
				if show_recorded_today of item i5 of Show_info is "false" then
					set show_recorded_today of item i5 of Show_info to false
				end if
				if show_recorded_today of item i5 of Show_info is "true" then
					set show_recorded_today of item i5 of Show_info to true
				end if
			on error errmsg
				my logger(true, "read_data()", "WARN", "Unable to change class of show_recorded_today, err: " & errmsg)
			end try
			
		end repeat
	on error errmsg
		my logger(true, "read_data()", "ERROR", "Unable to read file, err: " & errmsg)
	end try
	close access ref_num
	my validate_show_info("read_data(" & caller & ")", "", false)
end read_data

on recording_now(caller)
	my logger(true, "recording_now(" & caller & ")", "INFO", "Called")
	copy (current date) to cd
	set recording_now_final to {}
	if length of Show_info is greater than 0 then
		
		repeat with i from 1 to length of Show_info
			if show_recording of item i of Show_info is true then
				set recording_end to my ms2time("recording_now(" & caller & ")", (show_end of item i of Show_info) - (cd), "s", 3)
				if show_is_series of item i of Show_info is true then
					set end of recording_now_final to (Series_icon & " " & show_title of item i of Show_info & " on channel " & show_channel of item i of Show_info & " (" & recording_end & ")")
				else
					set end of recording_now_final to (Single_icon & " " & show_title of item i of Show_info & " on channel " & show_channel of item i of Show_info & " (" & recording_end & ")")
				end if
			end if
		end repeat
		if recording_now_final is {} then
			return ("No Shows Recording")
		end if
		return (Record_icon & " Recording" & return & my listtostring("recording_now(" & caller & ")", recording_now_final, return)) as text
	else
		my logger(true, "recording_now(" & caller & ")", "INFO", "No Shows")
		return ("Recording: None")
	end if
	my logger(true, "recording_now(" & caller & ")", "INFO", "No Shows Setup")
	return ("Recording: ?")
end recording_now

on next_shows(caller)
	my logger(true, "next_shows(" & caller & ")", "INFO", "Called")
	copy (current date) to cd
	set soonest_show to 9999999
	set soonest_show_time to cd
	--log "length of showinfo"
	--log length of Show_info
	repeat with i from 1 to length of Show_info
		if ((show_next of item i of Show_info) - (cd)) is less than soonest_show and show_next of item i of Show_info is greater than (cd) and show_active of item i of Show_info is true then
			set soonest_show_time to show_next of item i of Show_info
			set soonest_show to ((show_next of item i of Show_info) - (cd))
		end if
	end repeat
	my logger(true, "next_shows(" & caller & ")", "INFO", "Soonest: " & soonest_show & ": 9999999")
	if soonest_show is less than 9999999 then
		set next_shows_final to {}
		repeat with i2 from 1 to length of Show_info
			if show_next of item i2 of Show_info is soonest_show_time and show_active of item i2 of Show_info is true then
				if show_is_series of item i2 of Show_info is true then
					set end of next_shows_final to (Series_icon & " " & show_title of item i2 of Show_info & " on channel " & show_channel of item i2 of Show_info)
				else
					set end of next_shows_final to (Single_icon & " " & show_title of item i2 of Show_info & " on channel " & show_channel of item i2 of Show_info)
				end if
			end if
		end repeat
		--	log "next_shows"
		--	log soonest_show_time
		--	log next_shows_final
		return {soonest_show_time, next_shows_final}
	else
		return {soonest_show_time, "Nope!"}
	end if
end next_shows

on show_collision(caller, check_show_id)
	if check_show_id is "" then
		repeat with i3 from 1 to (length of Show_info)
			my show_collision("show_collision(" & caller & ")", show_id of item i3 of Show_info)
		end repeat
	else
		set show_offset to my HDHRShowSearch(check_show_id)
		--		log "show_offset: " & show_offset
		
		repeat with i from 1 to (length of Show_info)
			if show_active of item i of Show_info then
				set check_show_id_title to show_title of item i of Show_info
			end if
		end repeat
		
		repeat with i2 from 1 to (length of Show_info)
			my logger(true, "show_collision(" & caller & ")", "WARN", show_title of item i2 of Show_info)
			my logger(true, "show_collision(" & caller & ")", "WARN", check_show_id_title)
			my logger(true, "show_collision(" & caller & ")", "WARN", "- - - -")
			if (show_title of item i2 of Show_info is check_show_id_title) is true and show_id of item i2 of Show_info is not check_show_id then
				my logger(true, "show_collision(" & caller & ")", "WARN", show_id of item i2 of Show_info & " may be a duplicate of " & check_show_id)
			end if
		end repeat
	end if
end show_collision

on create_config_backup(caller)
	--FIX This would run before we save a file
	--if the config file has changed since we read it, save a backup file, appended with the date.
	set posix_update_path to POSIX path of Config_dir
	try
		do shell script "touch \"" & posix_update_path & "hdhr_test_write\""
		delay 0.1
		do shell script "rm \"" & posix_update_path & "hdhr_test_write\""
	on error err_string
		my logger(true, "create_config_backup(" & caller & ")", "ERROR", "Unable to write to " & posix_update_path & ", " & err_string)
	end try
end create_config_backup

on recording_search(caller, start_time, end_time, channel, hdhr_model)
	set temp_hdhr_check to my HDHRDeviceSearch("recording_search", hdhr_model)
	repeat with i from 1 to length of Show_info
		if hdhr_record of item i of Show_info is hdhr_model then
			if channel is show_channel of item i of Show_info then
				
			end if
		end if
	end repeat
end recording_search

##########    These are custom handlers.  They are more like libraries    ##########

on clean_icons()
	--Make sure the cache folder doesnt get too large?
end clean_icons

on curl2icon(caller, thelink)
	set savename to last item of my stringtolist("curl2icon(" & caller & ")", thelink, "/")
	try
		set temp_path to POSIX path of (path to home folder) & "Library/Caches/hdhr_VCR/" & savename as text
		if my checkfileexists("curl2icon(" & caller & ")", temp_path) is true then
			my logger(true, "curl2icon(" & caller & ")", "DEBUG", "File exists")
			try
				do shell script "touch " & temp_path
			on error errmsg
				my logger(true, "curl2icon(" & caller & ")", "WARN", "Unable to update date modified of " & savename)
			end try
		else
			do shell script "curl --silent '" & thelink & "' -o '" & temp_path & "'"
			my logger(true, "curl2icon(" & caller & ")", "INFO", "File does not exist: " & quote & temp_path & quote & ", creating")
		end if
		return POSIX file temp_path
	on error errmsg
		return caution
	end try
end curl2icon

on showid2PID(caller, show_id, kill_pid, logging)
	set showid2PID_result to false
	set showid2PID_perline to {}
	if show_id is "" then
		repeat with i from 1 to length of Show_info
			my showid2PID("showid2PID0(" & caller & ")", show_id of item i of Show_info, kill_pid, logging)
		end repeat
	else
		set show_offset to my HDHRShowSearch(show_id)
		if show_offset is greater than 0 then
			try
				set showid2PID_result to do shell script "ps -Aa|grep " & show_id & "|grep -v 'grep\\|caffeinate'"
				--set showid2PID_result to do shell script "ps -Aa|grep '" & show_id & "'|grep -v 'grep\\|caffeinate'"
			on error errmsg
				--my logger(true, "showid2PID(" & caller & ")", "WARN", errmsg)
				return {show_id, {}}
			end try
			set showid2PID_data_parsed to my stringtolist("showid2PID(" & caller & ")", showid2PID_result, return)
			--choose from list showid2PID_data_parsed
			if length of showid2PID_data_parsed is greater than 0 then
				repeat with i from 1 to length of showid2PID_data_parsed
					set end of showid2PID_perline to word 1 of item i of showid2PID_data_parsed
					if kill_pid = true then
						set show_recording of item show_offset of Show_info to false
						do shell script "kill " & word 1 of item i of showid2PID_data_parsed
						my logger(true, "showid2PID(" & caller & ")", "INFO", "The show " & show_id & " has a PID of " & word 1 of item i of showid2PID_data_parsed & ", and was killed")
						display notification with title Stop_icon & " Recording Stopped! (" & hdhr_record of item show_offset of Show_info & ")" subtitle "" & quote & show_title of item show_offset of Show_info & quote & " at " & show_time of item show_offset of Show_info
					else
						if logging = true then my logger(true, "showid2PID(" & caller & ")", "INFO", "The show " & show_id & " has a PID of " & word 1 of item i of showid2PID_data_parsed)
					end if
				end repeat
				return {show_id, {showid2PID_perline}}
			else
				return {show_id, {}}
			end if
		end if
	end if
end showid2PID

on rotate_logs(caller, filepath)
	set filepath to POSIX path of filepath
	set progress description to "Trimming log to " & Loglines_max & " lines"
	set progress additional description to filepath
	set progress total steps to 0
	set progress completed steps to -1
	--set log_length_now to (do shell script "") 
	delay 0.1
	do shell script "tail -n " & Loglines_max & " '" & filepath & "'>" & filepath & ".temp;mv '" & filepath & ".temp' '" & filepath & "'"
	set progress completed steps to 1
	my logger(true, "rotate_logs(" & caller & ")", "INFO", "Log file " & filepath & " rotated to " & Loglines_max & " lines")
end rotate_logs

on checkDiskSpace(caller, the_path)
	try
		set checkDiskSpace_return to do shell script "df -h '" & the_path & "'"
		set checkDiskSpace_temp1 to item 2 of my stringtolist("checkDiskSpace(" & caller & ")", checkDiskSpace_return, return)
		set checkDiskSpace_temp2 to my emptylist(my stringtolist("checkDiskSpace(" & caller & ")", checkDiskSpace_temp1, space))
		return {the_path, first word of item 5 of checkDiskSpace_temp2 as number}
	on error
		return {the_path, 0}
	end try
end checkDiskSpace

on datetime2epoch(caller, the_date_object)
	--log "datetime2epoch: " & caller & " " & the_date_object
	return my getTfromN(the_date_object - (my epoch()))
end datetime2epoch

on getTfromN(this_number)
	set this_number to this_number as text
	if this_number contains "E+" then
		set x to the offset of "." in this_number
		set y to the offset of "+" in this_number
		set z to the offset of "E" in this_number
		set the decimal_adjust to characters (y - (length of this_number)) thru -1 of this_number as text as number
		if x is not 0 then
			set the first_part to characters 1 thru (x - 1) of this_number as text
		else
			set the first_part to ""
		end if
		set the second_part to characters (x + 1) thru (z - 1) of this_number as text
		set the converted_number to the first_part
		repeat with i from 1 to the decimal_adjust
			try
				set the converted_number to the converted_number & character i of the second_part
			on error
				set the converted_number to the converted_number & "0"
			end try
		end repeat
		return the converted_number
	else
		return this_number
	end if
end getTfromN

on epoch()
	set epoch_time to current date
	
	set day of epoch_time to 1 --added to work around month rolling issue (31/30)
	
	set hours of epoch_time to 0
	set minutes of epoch_time to 0
	set seconds of epoch_time to 0
	
	set year of epoch_time to "1970"
	set month of epoch_time to "1"
	set day of epoch_time to "1"
	return epoch_time
end epoch

on epoch2datetime(caller, epochseconds)
	try
		set unix_time to (characters 1 through 10 of epochseconds) as text
	on error
		set unix_time to epochseconds
	end try
	set epoch_time to my epoch()
	--epoch_time is now current unix epoch time as a date object
	my logger(true, "epoch2datetime(" & caller & ")", "DEBUG", epochseconds)
	set epochOFFSET to (epoch_time + (unix_time as number) + (time to GMT))
	my logger(true, "epoch2datetime(" & caller & ")", "DEBUG", epochOFFSET)
	return epochOFFSET
end epoch2datetime

on epoch2show_time(caller, epoch)
	set show_time_temp to my epoch2datetime("epoch2show_time(" & caller & ")", epoch)
	set show_time_temp_hours to hours of show_time_temp
	set show_time_temp_minutes to minutes of show_time_temp
	if show_time_temp_minutes is not 0 then
		my logger(true, "epoch2show_time(" & caller & ")", "DEBUG", epoch)
		return (show_time_temp_hours & "." & (round (((show_time_temp_minutes / 60 * 100))) rounding up)) as text
		--return (show_time_temp_hours & "." & ((show_time_temp_minutes / 60 * 100) as integer)) as text
	else
		return (show_time_temp_hours)
	end if
end epoch2show_time

on emptylist(klist)
	set nlist to {}
	set dataLength to length of klist
	repeat with i from 1 to dataLength
		if item i of klist is not in {"", {}} then
			set end of nlist to (item i of klist)
		end if
	end repeat
	return nlist
end emptylist

on isModifierKeyPressed(caller, checkKey, desc)
	
	set modiferKeysDOWN to {command_down:false, option_down:false, control_down:false, shift_down:false, caps_down:false, numlock_down:false, function_down:false, help_down:false}
	
	try
		my logger(true, "isModifierKeyPressed(" & caller & ")", "INFO", "isModifierKeyPressed: " & checkKey & ", reason: " & desc)
	on error errmsg
		my logger(true, "isModifierKeyPressed(" & caller & ")", "WARN", "isModifierKeyPressed check failed: " & errmsg)
	end try
	
	if checkKey is in {"", "option", "alt"} then
		--if checkKey is "" or checkKey is  "option" or checkKey  is  "alt" then
		if (do shell script "osascript -l JavaScript -e \"ObjC.import('Cocoa'); ($.NSEvent.modifierFlags & $.NSEventModifierFlagOption)\"") is greater than 1 then
			set option_down of modiferKeysDOWN to true
		end if
	end if
	
	if checkKey is in {"", "command"} then
		if (do shell script "osascript -l JavaScript -e \"ObjC.import('Cocoa'); ($.NSEvent.modifierFlags & $.NSEventModifierFlagCommand)\"") is greater than 1 then
			set command_down of modiferKeysDOWN to true
		end if
	end if
	
	if checkKey is in {"", "shift"} then
		if (do shell script "osascript -l JavaScript -e \"ObjC.import('Cocoa'); ($.NSEvent.modifierFlags & $.NSEventModifierFlagShift)\"") is greater than 1 then
			set shift_down of modiferKeysDOWN to true
		end if
	end if
	
	if checkKey is in {"", "control", "ctrl"} then
		if (do shell script "osascript -l JavaScript -e \"ObjC.import('Cocoa'); ($.NSEvent.modifierFlags & $.NSEventModifierFlagControl)\"") is greater than 1 then
			set control_down of modiferKeysDOWN to true
		end if
	end if
	
	if checkKey is in {"", "caps", "capslock"} then
		if (do shell script "osascript -l JavaScript -e \"ObjC.import('Cocoa'); ($.NSEvent.modifierFlags & $.NSEventModifierFlagCapsLock)\"") is greater than 1 then
			set caps_down of modiferKeysDOWN to true
		end if
	end if
	
	if checkKey is in {"", "numlock"} then
		if (do shell script "osascript -l JavaScript -e \"ObjC.import('Cocoa'); ($.NSEvent.modifierFlags & $.NSEventModifierFlagNumericPad)\"") is greater than 1 then
			set numlock_down of modiferKeysDOWN to true
		end if
	end if
	
	--Set if any key in the numeric keypad is pressed. The numeric keypad is generally on the right side of the keyboard. This is also set if any of the arrow keys are pressed
	if checkKey is in {"", "function", "func", "fn"} then
		if (do shell script "osascript -l JavaScript -e \"ObjC.import('Cocoa'); ($.NSEvent.modifierFlags & $.NSEventModifierFlagFunction)\"") is greater than 1 then
			set function_down of modiferKeysDOWN to true
		end if
	end if
	
	if checkKey is in {"", "help", "?"} then
		if (do shell script "osascript -l JavaScript -e \"ObjC.import('Cocoa'); ($.NSEvent.modifierFlags & $.NSEventModifierFlagHelp)\"") is greater than 1 then
			set help_down of modiferKeysDOWN to true
		end if
	end if
	--Set if any function key is pressed. The function keys include the F keys at the top of most keyboards (F1, F2, and so on) and the navigation keys in the center of most keyboards (Help, Forward Delete, Home, End, Page Up, Page Down, and the arrow keys)
	try
		set temp to modiferKeysDOWN as text
	on error errmsg
		my logger(true, "isModifierKeyPressed(" & caller & ")", "DEBUG", item 2 of my stringtolist("isModifierKeyPressed(" & caller & ")", errmsg, {"{", "}"}))
	end try
	return modiferKeysDOWN
end isModifierKeyPressed

on isModifierKeyPressed2(caller, checkKey)
	
	set modiferKeysDOWN to {command_down:false, option_down:false, control_down:false, shift_down:false, caps_down:false, numlock_down:false, function_down:false}
	
	if (do shell script "/usr/bin/python -c 'import Cocoa; print Cocoa.NSEvent.modifierFlags() & Cocoa.NSAlternateKeyMask'") is 0 then
		return modiferKeysDOWN
	end if
	
	try
		my logger(true, "isModifierKeyPressed(" & caller & ")", "INFO", "isModifierKeyPressed: " & checkKey)
	on error errmsg
		my logger(true, "isModifierKeyPressed(" & caller & ")", "WARN", "isModifierKeyPressed check failed: " & errmsg)
	end try
	
	if checkKey is in {"", "option", "alt"} then
		--if checkKey is "" or checkKey is  "option" or checkKey  is  "alt" then
		if (do shell script "/usr/bin/python -c 'import Cocoa; print Cocoa.NSEvent.modifierFlags() & Cocoa.NSAlternateKeyMask'") is greater than 1 then
			set option_down of modiferKeysDOWN to true
		end if
	end if
	
	if checkKey is in {"", "command"} then
		if (do shell script "/usr/bin/python -c 'import Cocoa; print Cocoa.NSEvent.modifierFlags() & Cocoa.NSCommandKeyMask'") is greater than 1 then
			set command_down of modiferKeysDOWN to true
		end if
	end if
	
	if checkKey is in {"", "shift"} then
		if (do shell script "/usr/bin/python -c 'import Cocoa; print Cocoa.NSEvent.modifierFlags() & Cocoa.NSShiftKeyMask'") is greater than 1 then
			set shift_down of modiferKeysDOWN to true
		end if
	end if
	
	if checkKey is in {"", "control", "ctrl"} then
		if (do shell script "/usr/bin/python -c 'import Cocoa; print Cocoa.NSEvent.modifierFlags() & Cocoa.NSControlKeyMask'") is greater than 1 then
			set control_down of modiferKeysDOWN to true
		end if
	end if
	
	if checkKey is in {"", "caps", "capslock"} then
		if (do shell script "/usr/bin/python -c 'import Cocoa; print Cocoa.NSEvent.modifierFlags() & Cocoa.NSAlphaShiftKeyMask'") is greater than 1 then
			set caps_down of modiferKeysDOWN to true
		end if
	end if
	
	if checkKey is in {"", "numlock"} then
		if (do shell script "/usr/bin/python -c 'import Cocoa; print Cocoa.NSEvent.modifierFlags() & Cocoa.NSNumericPadKeyMask'") is greater than 1 then
			set numlock_down of modiferKeysDOWN to true
		end if
	end if
	--Set if any key in the numeric keypad is pressed. The numeric keypad is generally on the right side of the keyboard. This is also set if any of the arrow keys are pressed
	
	if checkKey is in {"", "function", "func", "fn"} then
		if (do shell script "/usr/bin/python -c 'import Cocoa; print Cocoa.NSEvent.modifierFlags() & Cocoa.NSFunctionKeyMask'") is greater than 1 then
			set function_down of modiferKeysDOWN to true
		end if
	end if
	--Set if any function key is pressed. The function keys include the F keys at the top of most keyboards (F1, F2, and so on) and the navigation keys in the center of most keyboards (Help, Forward Delete, Home, End, Page Up, Page Down, and the arrow keys)
	
	return modiferKeysDOWN
end isModifierKeyPressed2

on time_set(caller, adate_object, time_shift)
	--log adate_object
	log time_shift
	set dateobject to adate_object
	--set to midnight
	set hours of dateobject to 0
	set minutes of dateobject to 0
	set seconds of dateobject to 0
	set dateobject to dateobject + (time_shift * hours)
	my logger(true, "time_set(" & caller & ")", "INFO", dateobject as text)
	return dateobject
end time_set

on padnum(caller, thenum)
	my logger(true, "padnum(" & caller & ")", "DEBUG", thenum)
	if (length of thenum) is 1 then
		set thenum to ("0" & thenum) as text
	else
		return (thenum) as text
	end if
end padnum

on is_number(number_string)
	try
		set number_string to number_string as number
		return true
	on error
		return false
	end try
end is_number

on stringtolist(caller, theString, delim)
	--log "stringtolist: " & the_caller & ":" & theString
	set oldelim to AppleScript's text item delimiters
	set AppleScript's text item delimiters to delim
	set dlist to (every text item of theString)
	set AppleScript's text item delimiters to oldelim
	return dlist
end stringtolist

on listtostring(caller, theList, delim)
	set oldelim to AppleScript's text item delimiters
	set AppleScript's text item delimiters to delim
	set alist to theList as text
	set AppleScript's text item delimiters to oldelim
	return alist
end listtostring

on short_date(the_caller, the_date_object, twentyfourtime, show_seconds)
	
	--log "short_date: " & the_caller & " / " & the_date_object
	
	--	set twentyfourtime to true
	set timeAMPM to ""
	--takes date object, and coverts to a shorter time string
	if the_date_object is not "?" then
		if the_date_object is not "" then
			set year_string to (items -2 thru end of (year of the_date_object as text))
			
			if ((month of the_date_object) * 1) is less than 10 then
				set month_string to ("0" & ((month of the_date_object) * 1)) as text
			else
				set month_string to ((month of the_date_object) * 1) as text
			end if
			
			if day of the_date_object is less than 10 then
				set day_string to ("0" & day of the_date_object) as text
			else
				set day_string to (day of the_date_object) as text
			end if
			
			if minutes of the_date_object is less than 10 then
				set minutes_string to "0" & minutes of the_date_object
			else
				set minutes_string to (minutes of the_date_object) as text
			end if
			
			
			if hours of the_date_object is less than 10 then
				set hours_string to "0" & hours of the_date_object
			else
				set hours_string to (hours of the_date_object) as text
			end if
			if twentyfourtime is false then
				if hours_string is greater than or equal to 12 then
					set timeAMPM to " PM"
					if hours_string is greater than 12 then
						set hours_string to (hours_string - 12)
						if hours_string is 0 then
							set hours_string to "12"
						end if
					end if
				else
					set hours_string to my padnum("short_date(" & the_caller & ")", hours_string)
					set timeAMPM to " AM"
				end if
			end if
			if seconds of the_date_object is less than 10 then
				set seconds_string to "0" & seconds of the_date_object
			else
				set seconds_string to (seconds of the_date_object) as text
			end if
			if Locale is "en_US" then
				if show_seconds is true then
					return (month_string & "." & day_string & "." & year_string & " " & hours_string & "." & minutes_string & "." & seconds_string & timeAMPM) as text
				else
					return (month_string & "." & day_string & "." & year_string & " " & hours_string & "." & minutes_string & timeAMPM) as text
				end if
			else
				if show_seconds is true then
					return (year_string & "/" & month_string & "/" & day_string & " " & hours_string & "." & minutes_string & "." & seconds_string & timeAMPM) as text
				else
					return (year_string & "/" & month_string & "/" & day_string & " " & hours_string & "." & minutes_string & timeAMPM) as text
				end if
			end if
		else
			return ""
		end if
	else
		return "?"
	end if
end short_date

on list_position(caller, this_item, this_list, is_strict)
	my logger(true, "list_position(" & caller & ")", "DEBUG", this_item & ", " & this_list)
	--	log "list_position: " & caller
	--	log "list_position: " & this_item
	--	log "list_position: " & this_list
	--	log "list_position: " & is_strict
	--	display dialog "!list_post: " & this_item 
	--	display dialog "!list_post2: " & this_list
	--	display dialog "!list_post3: " & is_strict
	if this_item is not false then
		repeat with i from 1 to length of this_list
			if is_strict is false then
				if (item i of this_list as text) contains (this_item as text) then
					--display dialog "list_post2: ~" & i 
					return i
				end if
			else
				if (item i of this_list as text) is (this_item as text) then
					--display dialog "list_post2: " & i
					return i
				end if
			end if
		end repeat
	end if
	--	log "list_post3: 0"
	return 0
end list_position

on update_folder(caller, update_path)
	my logger(true, "update_folder(" & caller & ")", "INFO", "\"" & update_path & "\"")
	set posix_update_path to POSIX path of update_path
	try
		do shell script "touch \"" & posix_update_path & "hdhr_test_write\""
		delay 0.1
		do shell script "rm \"" & posix_update_path & "hdhr_test_write\""
		return true
	on error err_string
		my logger(true, "update_folder(" & caller & ")", "ERROR", "Unable to write to " & posix_update_path & ", " & err_string)
		return false
	end try
end update_folder

on logger(logtofile, caller, loglevel, message)
	## logtofile is a boolean that tell us if we want to write this to a file, in addition to logging it out in Script Editor Console.
	## caller is a string that tells us where this handler was called from
	## loglevel is a string that tell us how severe the log line is 
	## message is the actual message we want to log.
	## We cannot do any logging here, or recursion will occur!
	--We dont want to write out everything we write, so lets maintain a buffer.  We can add a hook into the idle() handler to flush the queue. 
	set logger_max_queued to 1
	--if caller is  "init" then
	set queued_log_lines to {}
	--end if  
	set end of queued_log_lines to my short_date("logger", current date, true, true) & " " & Local_env & " " & loglevel & " " & caller & " " & message
	--if length of queued_log_lines is greater than or equal to logger_max_queued or caller is "flush" then
	--end if
	if loglevel is in Logger_levels then
		
		try
			set logfile to open for access file ((Log_dir) & (Logfilename) as text) with write permission
		on error
			set logfile to ""
		end try
		if logfile is not "" then
			repeat with i from 1 to length of queued_log_lines
				set ref_num to get eof of logfile
				--write (item i of queued_log_lines & LF) to logfile starting at ref_num 
				write (item i of queued_log_lines & Lf) as text to logfile starting at (ref_num + 1)
				--write item i of queued_log_lines & LF to logfile starting at ref_num
				
				set Loglines_written to Loglines_written + 1
			end repeat
		else
			display notification "Unable to write to log file. " & caller & ", " & message
		end if
		
		if logfile is not "" then
			close access logfile
		end if
	end if
end logger

on ms2time(caller, totalMS, time_duration, level_precision)
	my logger(true, "ms2time()", "DEBUG", caller & ", " & totalMS & ", " & time_duration & ", " & level_precision)
	set totalMS to totalMS as number
	set temp_time_string to {}
	set numseconds to 0
	set numinutes to 0
	set numhours to 0
	set numdays to 0
	set numyears to 0
	if time_duration is "ms" then
		if totalMS is greater than 0 and totalMS is less than 1000 then
			return ("<1s")
		else
			set numseconds to totalMS div 1000
		end if
	else
		set numseconds to totalMS
	end if
	
	if numseconds is greater than 3153599 then
		set numyears to numseconds div (365 * days)
		set numseconds to numseconds - (numyears * (365 * days))
	end if
	if numseconds is greater than 86400 then
		set numdays to numseconds div days
		set numseconds to numseconds - (numdays * days)
	end if
	if numseconds is greater than 3600 then
		set numhours to numseconds div hours
		set numseconds to numseconds - (numhours * hours)
	end if
	if numseconds is greater than or equal to 60 then
		set numinutes to (numseconds div minutes)
		set numseconds to numseconds - (numinutes * minutes)
	end if
	set temp_time to (numyears & numdays & numhours & numinutes & numseconds)
	--choose from list temp_time
	repeat with i from 1 to length of temp_time
		if item i of temp_time is not in {0, "0", ""} then
			try
				if i is 1 then
					set end of temp_time_string to (item i of temp_time & "Y") as text
				end if
				if i is 2 then
					set end of temp_time_string to (item i of temp_time & "D") as text
				end if
				if i is 3 then
					set end of temp_time_string to (item i of temp_time & "H") as text
				end if
				if i is 4 then
					set end of temp_time_string to (item i of temp_time & "M") as text
				end if
				if i is 5 then
					set end of temp_time_string to (item i of temp_time & "S") as text
				end if
			end try
		end if
	end repeat
	--choose from list temp_time_string
	if level_precision is greater than length of temp_time_string then
		set level_precision to length of temp_time_string
	end if
	if level_precision is not 0 then
		set temp_time_string to items 1 thru (item level_precision) of temp_time_string
	end if
	if length of temp_time_string is not 0 then
		my logger(true, "ms2time(" & caller & ")", "DEBUG", "Result: " & temp_time_string)
		return my listtostring("ms2time(" & caller & ")", temp_time_string, " ")
	else
		my logger(true, "ms2time(" & caller & ")", "DEBUG", "Result: 0ms")
		return my listtostring("ms2time(" & caller & ")", "0ms", " ")
	end if
end ms2time



on timeslot_feed(caller, show_id)
	--goal here is to take a showid, and mark it on the map
	--return true means we were able to mark the time.
	--return false means we were not able to assign the time.  --This should be logged as a WARN, and displayed in a notification
	
end timeslot_feed

----------  NEW --------
on timeslot_firstrun()
	my timeslot_build(2)
	repeat with i from 1 to 2
		--		log "timeslot_firstrun: " & i
		--		log (length of item i of Timeslot as text)
	end repeat
	--We need to feed a showID into something and mark the shows off that are already being tracked.	
end timeslot_firstrun

on timeslot_build(num_of_tuners)
	try
		set Timeslot to {}
		set templist to {}
		--we need one list item per minute of the week, which brings us to 10800 items
		repeat num_of_tuners times
			repeat 10080 times
				set end of templist to false
			end repeat
			set end of Timeslot to templist
			set templist to {}
		end repeat
		--		log "timeslot_build true"
		return true
	on error errnum
		--		log "timeslot_build false"
		return false
	end try
	(*
	repeat with i from 1 to length of timeslot
		choose from list item 1 of timeslot with title i
	end repeat
	*)
	--return false means we errored
	--return true means we built the list
end timeslot_build

on timeslot_range_clear(caller, start_minute, end_minute, ts_tuner)
	if ts_tuner = "" then
		repeat with i from 1 to length of Timeslot
			my timeslot_range_clear("timeslot_range_clear" & i & "(" & caller & ")", start_minute, end_minute, i)
		end repeat
	end if
	repeat with i from start_minute to end_minute
		if item i of item ts_tuner of Timeslot = true then
			--log "timeslot_range_clear, tuner " & ts_tuner & ": false"
			return false
		end if
	end repeat
	--log "timeslot_range_clear, tuner " & ts_tuner & ": true"
	return true
	
	--return false means the range is not avilable
	--return true means the range is avilable.
end timeslot_range_clear

on dayofweek(caller, the_day, next_or_last)
	set valid_days to {"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}
	if the_day is in valid_days then
		set cd to current date
		if next_or_last = "next" then
			set tempcd to 7
			set whichby to 1
		end if
		if next_or_last = "last" then
			set tempcd to -7
			set whichby to -1
		end if
		repeat with i from 0 to tempcd by whichby
			set temp_time to ((cd) + (i * days))
			if (weekday of temp_time) as text = the_day and temp_time is not (current date) then
				return date (date string of temp_time)
			end if
		end repeat
	else
		return false
	end if
end dayofweek

on repeatProgress(loop_delay, loop_total)
	set progress total steps to loop_total
	repeat with i from 1 to loop_total
		set progress completed steps to i
		delay loop_delay
	end repeat
end repeatProgress

on existing_shows(caller)
	try
		set showid2PID_result to do shell script "ps -Aa|grep appname|grep -v 'grep\\|caffeinate'"
	on error errmsg
		set showid2PID_result to ""
		return
	end try
	try
		set showid2PID_result_list to my stringtolist("existing_shows(" & caller & ")", showid2PID_result, return)
		if length of showid2PID_result_list is greater than 0 then
			repeat with i from 1 to length of showid2PID_result_list
				set temp_show_id to item 2 of my stringtolist("existing_shows(" & caller & ")", item i of showid2PID_result_list, " -H ")
				set show_offset to my HDHRShowSearch(temp_show_id)
				if show_recording of item show_offset of Show_info is false then
					set show_recording of item show_offset of Show_info to true
					my logger(true, "existing_shows(" & caller & ")", "WARN", "The show " & show_title of item show_offset of Show_info & " is already recording, so show_recording set to true!")
				end if
			end repeat
		end if
	on error errmsg
		my logger(true, "existing_shows(" & caller & ")", "WARN", "Check for existing_shows() failed, errmsg: " & errmsg)
	end try
end existing_shows

on check_after_midnight(caller)
	set temp_time to day of (current date)
	try
		if Check_after_midnight_time is not temp_time then
			return true
			set Check_after_midnight_time to temp_time
		end if
	on error errmsg
		set Check_after_midnight_time to temp_time
	end try
	return false
end check_after_midnight