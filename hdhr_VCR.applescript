(*
Fix: update_folder() now logs more information.  We also fixed some bugs.

*)

global show_info
--global temp_show_info
global locale
global channel_list
global HDHR_DEVICE_LIST
global idle_timer
global idle_count
global version_local
global version_remote
global version_url

global hdhr_setup_folder
global hdhr_setup_transcode
global hdhr_setup_name_bool
global hdhr_setup_length_bool
global notify_upnext
global notify_recording
global hdhr_setup_ran
global configfilename
global logfilename
global time_slide
global dialog_timeout
global temp_dir
global config_dir
global log_dir

--Icons
global play_icon
global record_icon
global tv_icon
global plus_icon
global single_icon
global series_icon
global inactive_icon
global edit_icon
global soon_icon
global disk_icon
global update_icon
global trash_icon
global stop_icon
global up_icon
global up2_icon
global check_icon
global uncheck_icon
global calendar_icon
global calendar2_icon
global hourglass_icon
global film_icon
global back_icon
global done_icon

global LF
global logger_levels

## Since we use JSON helper to do some of the work, we should declare it, so we dont end up having to use tell blocks everywhere.  If we declare 1 thing, we have to declare everything we are using.
use AppleScript version "2.4"
use scripting additions
use application "JSON Helper"

-- {hdhr_lineup_update:missing value, hdhr_guide_update:missing value, discover_url:"http://10.0.1.101/discover.json", lineup_url:"http://10.0.1.101/lineup.json", device_id:"XX105404BE", does_transcode:0, hdhr_lineup:missing value, hdhr_guide:missing value, hdhr_model:missing value}

-- show_info model: (*show_title:Happy_Holidays_America, show_time:16, show_length:60, show_air_date:Sunday, show_transcode:missing value, show_temp_dir:alias Backups:, show_dir:alias Backups:, show_channel:5.1, show_active:true, show_id:221fbe1126389e6af35f405aa681cf19, show_recording:false, show_last:date Sunday, December 13, 2020 at 4:04:54 PM, show_next:date Sunday, December 13, 2020 at 4:00:00 PM, show_end:date Sunday, December 13, 2020 at 5:00:00 PM, notify_upnext_time:missing value, notify_recording_time:missing value, hdhr_record:XX105404BE,show_is_series:false*

-- http://api.hdhomerun.com/api/guide.php?DeviceAuth=IBn9SkGefWcxVTxbQpTBMsuI
--	set progress description to "Loading ..."
--    set progress additional description to
--	set progress completed steps to 0 
--	set progress total steps to 1

##########    These are reserved handlers, we do specific things in them    ##########
on run {}
	set LF to character id {13, 10}
	--Icons!	
	set play_icon to character id {9654, 65039}
	set record_icon to character id 9210
	set tv_icon to character id (128250)
	set plus_icon to character id (10133)
	set single_icon to character id {49, 65039, 8419}
	set series_icon to character id 128257
	set inactive_icon to character id 9940
	set edit_icon to character id {9999, 65039}
	set soon_icon to character id 128284
	set disk_icon to character id 128190
	set update_icon to character id 127381
	set trash_icon to character id {128465, 65039}
	set stop_icon to character id 9209
	set up_icon to character id 128316
	set up2_icon to character id 9195
	set check_icon to character id 9989
	set uncheck_icon to character id 10060
	set calendar_icon to character id 128197
	set calendar2_icon to character id 128198
	set hourglass_icon to character id 8987
	set film_icon to character id 127910
	set back_icon to character id 8592
	set done_icon to character id {9989, 32}
	set version_local to "20210616"
	set progress description to "Loading " & name of me & " " & version_local
	
	--set globals 
	set show_info to {}
	set notify_upnext to 30
	set notify_recording to 15
	set locale to user locale of (system info)
	set hdhr_setup_folder to "Volumes:"
	set hdhr_setup_transcode to "No"
	set hdhr_setup_name_bool to "No"
	set hdhr_setup_length_bool to "No"
	set configfilename to (name of me) & ".config" as text
	set logfilename to (name of me) & ".log" as text
	set time_slide to 0
	set dialog_timeout to 60
	set version_url to "https://raw.githubusercontent.com/identd113/hdhr_VCR-AS/master/version.json"
	set version_remote to "0"
	set idle_timer to 12
	set idle_count to 0
	set temp_dir to alias "Volumes:"
	set config_dir to path to documents folder
	set log_dir to path to documents folder
	--set logger_levels to {"INFO", "WARN", "ERROR", "DEBUG"}
	set logger_levels to {"INFO", "WARN", "ERROR"}
	my logger(true, "init", "INFO", "Started " & name of me & " " & version_local)
	
	## Lets check for a new version!
	my check_version()
	
	(*
	This really kicks us off.  The will query to see if there are any HDHomeRun devices on the local network.  This script support multiple devices.
	Once we find some devices, we will query them and pull there lineup data.  This tells us what channels belong to what tags, like "2.4 TPTN"
	We will then pull guide data.  It should be said here that this data is only given for 4 hours ahead of current time, some stations maybe 6.  Special considerations have been made in this script to make this work.  We call this handler and specify "run0".  This is just a made up string that we pass to the next handler, so we can see the request came in that broke the script.  This is commonly repeated in my scripts.
	*)
	
	
	
	my HDHRDeviceDiscovery("run1", "")
	## Restore any previous state 
	my read_data()
	my show_info_dump("run3", "")
	## Main is the start of the UI for the user. 
	idle {}
	my main("run", "run()")
end run

## This script will loop through this every 12 seconds, or whatever the return value is, in second is at the bottom of this handler.
on idle
	--Fixed We manually called idle() handler before popping any notification windows.  This akllows us to start a show that may already be started when openong the app.
	--This should give us an approximate time in seconds the script was launched. 
	set idle_count to idle_count + idle_timer
	my logger(true, "idle()", "DBEUG", "Idle seconds: " & idle_count)
	--fix This uis a test to see if we can modify a live return value
	--This does work, nice,  We can flip this to run closer to record times so we can try to start and end at exactly the right time.
	--if idle_count > 100 then
	--	set idle_timer to 3
	--end if
	
	
	--display notification time string of (current date)
	set cd_object to (current date) + 10
	
	--Re run auto discover every 1 hour, or once we flip past midnight 
	if length of HDHR_DEVICE_LIST > 0 then
		repeat with i2 from 1 to length of HDHR_DEVICE_LIST
			if ((cd_object) - (hdhr_guide_update of item i2 of HDHR_DEVICE_LIST)) div 60 ³ 60 or date string of (hdhr_guide_update of item i2 of HDHR_DEVICE_LIST) ­ date string of (current date) then
				my logger(true, "idle()", "INFO", "Periodic Update of Tuners")
				try
					my HDHRDeviceDiscovery("idle0", "")
				on error
					my logger(true, "idle()", "ERROR", "Unable to update HDHRDeviceDiscovery")
				end try
				my logger(true, "idle()", "INFO", "Periodic Update of Tuners complete")
			end if
		end repeat
	end if
	
	## If there are any shows to saved, we start working through them
	if length of show_info > 0 then
		repeat with i from 1 to length of show_info
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
				if show_active of item i of show_info = true then
					if show_next of item i of show_info < cd_object then
						--if show_next of item i of show_info < cd_object then
						if show_recording of item i of show_info = false then
							if show_end of item i of show_info < (current date) then
								if show_is_series of item i of show_info = true then
									set show_next of item i of show_info to my nextday(show_id of item i of show_info)
								else
									set show_active of item i of show_info to false
								end if
								exit repeat
							end if
							set show_runtime to (show_end of item i of show_info) - (current date)
							if my tuner_status("idle2", hdhr_record of item i of show_info) is true then
								-- If we now have no tuner avilable, we skip this "loop" and try again later.
								my record_now((show_id of item i of show_info), show_runtime)
								display notification "Ends " & my short_date("rec started", show_end of item i of show_info, false, false) with title record_icon & " Started Recording on (" & hdhr_record of item i of show_info & ")" subtitle show_title of item i of show_info & " on " & show_channel of item i of show_info & " (" & my channel2name(show_channel of item i of show_info as text, hdhr_record of item i of show_info) & ")"
								set notify_recording_time of item i of show_info to (current date) + (2 * minutes)
								my logger(true, "idle()", "INFO", "Started recording " & show_title of item i of show_info & " until " & show_end of item i of show_info & " on channel " & show_channel of item i of show_info & " using " & hdhr_record of item i of show_info)
								--display notification show_title of item i of show_info & " on channel " & show_channel of item i of show_info & " started for " & show_runtime of item i of show_info & " minutes."
							else
								
								display notification hourglass_icon & " Delaying for for 9 seconds" with title "Tuner unavailable (" & hdhr_record of item i of show_info & ")" subtitle show_title of item i of show_info
							end if
						else
							--display notification show_title of item i of show_info & " is recording until " & my short_date("recording", show_end of item i of show_info)
							if notify_recording_time of item i of show_info < (current date) or notify_recording_time of item i of show_info = missing value then
								
								display notification "Ends " & my short_date("rec progress", show_end of item i of show_info, false, false) & " (" & (my sec_to_time((show_end of item i of show_info) - (current date))) & ") " with title record_icon & " Recording in progress on (" & hdhr_record of item i of show_info & ")" subtitle show_title of item i of show_info & " on " & show_channel of item i of show_info & " (" & my channel2name(show_channel of item i of show_info as text, hdhr_record of item i of show_info) & ")"
								--try to refresh the file, so it shows it refreshes finder.
								my logger(true, "idle()", "INFO", "Recording in progress for " & (show_title of item i of show_info & " on " & show_channel of item i of show_info))
								my update_folder(show_dir of item i of show_info)
								set notify_recording_time of item i of show_info to (current date) + (notify_recording * minutes)
							end if
						end if
					end if
				end if
				
				
				if show_recording of item i of show_info = false and show_active of item i of show_info = true then
					--my update_show(show_id of item i of show_info)
					if (notify_upnext_time of item i of show_info < (current date) or notify_upnext_time of item i of show_info = missing value) and (show_next of item i of show_info) - (current date) ² 1 * hours then
						
						--This line is a hot mess, as it reports too often.  Lets try some progress bar hacks.
						--set progress description to "Next up... (" & hdhr_record of item i of show_info & ")"
						--set progress additional description to "Starts: " & my short_date("is_next", show_next of item i of show_info, false)
						
						--We see this message very often, lets make sure we only display up next shows just for today. 
						display notification "Starts: " & my short_date("is_next", show_next of item i of show_info, false, false) & " (" & my sec_to_time(((show_next of item i of show_info) - (current date))) & ")" with title film_icon & " Next Up on (" & hdhr_record of item i of show_info & ")" subtitle show_title of item i of show_info & " on " & show_channel of item i of show_info & " (" & my channel2name(show_channel of item i of show_info, hdhr_record of item i of show_info) & ")"
						my logger(true, "idle()", "INFO", "Next Up: " & show_title of item i of show_info & " on " & hdhr_record of item i of show_info)
						set notify_upnext_time of item i of show_info to (current date) + (notify_upnext * minutes)
					end if
					--end if
					
				end if
				
				if show_recording of item i of show_info = true then
					if show_end of item i of show_info < (current date) then
						set show_last of item i of show_info to show_end of item i of show_info
						--set show_next of item i of show_info to my nextday(show_id of item i of show_info)
						set show_recording of item i of show_info to false
						if show_is_series of item i of show_info = true then
							set show_next of item i of show_info to my nextday(show_id of item i of show_info)
							my logger(true, "idle()", "INFO", "Recording Complete for " & (show_title of item i of show_info & " on " & show_channel of item i of show_info))
							display notification "Next Showing: " & my short_date("rec_end", show_next of item i of show_info, false, false) with title stop_icon & " Recording Complete" subtitle (show_title of item i of show_info & " on " & show_channel of item i of show_info & " (" & my channel2name(show_channel of item i of show_info as text, hdhr_record of item i of show_info) & ")")
						else
							set show_active of item i of show_info to false
							my logger(true, "idle()", "INFO", "Recording Complete for " & (show_title of item i of show_info & " on " & show_channel of item i of show_info & " and marked inactive"))
							display notification "Show marked inactive" with title stop_icon & " Recording Complete" subtitle (show_title of item i of show_info & " on " & show_channel of item i of show_info & " (" & my channel2name(show_channel of item i of show_info as text, hdhr_record of item i of show_info) & ")")
						end if
						
						
						--This needs to happen not in the idle loop.  Since we loop the stored tv shows (show_info), and we are still inside of the repeat loop, we end up trying to walk past the list, kind of a off by 1 error.
						--We can remove these shows on app start, before we start walking the idle loop.  If we want to remove a show, we have to make sure we are not in a loop inside of the idle handler.  We can create an idle lock bit, which can increase the call back time to a much higer number, run our code, and then "unlock" the loop.  This all sounds very sloppy, and i dont like it.  We may just need to mark the show entries as dirty, likely by making making the show_id a missing value.  We would need to clear this out before we get stuck in a repeat loop.  This sounds cleaner.  This also means we need to remove references of the remove_show_info handler,  and stick this in the idle handler, which can have its own host of issues.
					end if
					--else if show_end of item i of show_info < (current date) and show_is_series of item i of show_info = false then 
				else if show_is_series of item i of show_info = false and show_end of item i of show_info < (current date) and show_active of item i of show_info = true then
					set show_active of item i of show_info to false
					my logger(true, "idle()", "INFO", "Show " & show_title of item i of show_info & " as inactive, as it is a single, and record time has passed.")
					display notification show_title of item i of show_info & " removed"
				end if
			end repeat
		end repeat
	end if
	return idle_timer
end idle

## This fires when you click the script in the dock.
on reopen {}
	my logger(true, "reopen()", "INFO", "User clicked in Dock")
	my main("reopen", "reopen()")
end reopen

## Runs when the user attempts to quit the script.
on quit {}
	--add check to see if we are recording.
	set hdhr_quit_record to false
	repeat with i from 1 to length of show_info
		if show_recording of item i of show_info = true then
			my logger(true, "quit()", "INFO", "There is at least one show marked as currently recording, marking quit() dirty")
			set hdhr_quit_record to true
		end if
	end repeat
	if hdhr_quit_record = true then
		--Add currently recorded shows
		set quit_response to button returned of (display dialog "Do you want to cancel recordings already in progress?" buttons {"Go Back", "Yes", "No"} default button 3 with title my check_version_dialog() giving up after dialog_timeout with icon stop)
		my logger(true, "quit()", "INFO", "quit() user choice: " & quit_response)
	else
		my save_data()
		continue quit
	end if
	if quit_response = "Yes" then
		repeat with i from 1 to length of show_info
			set show_recording of item i of show_info to false
		end repeat
		my logger(true, "quit()", "DEBUG", "end repeat")
		--FIX What if we cannot run pkill
		try
			with timeout of 5 seconds
				do shell script "pkill curl"
			end timeout
		on error
			my logger(true, "quit()", "DEBUG", "pkill failed")
		end try
		my logger(true, "quit()", "DEBUG", "end pkill")
		my save_data()
		my logger(true, "quit()", "DEBUG", "end save_data")
		continue quit
		--end try
	end if
	if quit_response = "No" then
		my save_data()
		continue quit
	end if
	if quit_response = "Go Back" then
		my main("quit", "quit()")
	end if
	
end quit

##########    END of reserved handlers    ##########

##########    These are custom handlers.  These are the heart of the script.    ##########
on hdhrGRID(caller, hdhr_device, hdhr_channel)
	log "hdhrgrid: " & hdhr_channel
	my logger(true, "hdhrGRID(" & caller & ", " & hdhr_device & ", " & hdhr_channel & ")", "INFO", "Started hdhrGRID")
	set hdhrGRID_sort to {back_icon & " Back"}
	set hdhrGRID_temp to my channel_guide("hdhrGRID0", hdhr_device, hdhr_channel, "")
	try
		my logger(true, "hdhrGRID()", "INFO", "Shows returned: " & length of Guide of hdhrGRID_temp & ", channel: " & hdhr_channel & ", hdhr_device: " & hdhr_device)
	on error
		my logger(true, "hdhrGRID()", "ERROR", "Unable to get a length of hdhrGRID_temp")
	end try
	repeat with i from 1 to length of Guide of hdhrGRID_temp
		try
			set temp_title to (title of item i of Guide of hdhrGRID_temp & " \"" & EpisodeTitle of item i of Guide of hdhrGRID_temp) & "\""
		on error
			set temp_title to (title of item i of Guide of hdhrGRID_temp)
		end try
		set end of hdhrGRID_sort to (word 2 of my short_date("hdhrGRID1", my epoch2datetime(my getTfromN(StartTime of item i of Guide of hdhrGRID_temp)), false, false) & "-" & word 2 of my short_date("hdhrGRID2", my epoch2datetime(my getTfromN(EndTime of item i of Guide of hdhrGRID_temp)), false, false) & " " & temp_title)
	end repeat
	--fixme  Allow multiple shows to be selected. 
	
	set hdhrGRID_selected to choose from list hdhrGRID_sort with prompt "Channel " & hdhr_channel & " (" & GuideName of hdhrGRID_temp & ")" cancel button name "Manual Add" OK button name "Next.." with title my check_version_dialog() with multiple selections allowed
	log "hdhrGRID_selected: " & hdhrGRID_selected
	try
		if item 1 of hdhrGRID_selected = back_icon & " Back" then
			my logger(true, "hdhrGRID()", "INFO", "Back to channel list" & " from " & caller)
			return true
		end if
	end try
	if my epoch2datetime(EndTime of item ((my list_position("hdhrGRID1", hdhrGRID_selected, hdhrGRID_sort, false)) - 1) of Guide of hdhrGRID_temp) < (current date) then
		my logger(true, "hdhrGRID()", "INFO", "This show time has already passed")
		display notification "The show has already passed, returning..."
		my HDHRDeviceDiscovery("hdhrGRID", hdhr_device)
		return true
	end if
	if hdhrGRID_selected ­ false then
		my logger(true, "hdhrGRID()", "INFO", "Returning guide data for " & hdhr_channel & " on device " & hdhr_device & " from " & caller)
		set list_position_response to item ((my list_position("hdhrGRID1", hdhrGRID_selected, hdhrGRID_sort, false)) - 1) of Guide of hdhrGRID_temp
		--my logger(true, "hdhrGRID()", "INFO", list_position_response)
		return list_position_response
	else
		my logger(true, "hdhrGRID()", "INFO", "User exited" & " from " & caller)
		return false
	end if
	return false
end hdhrGRID
--return true means we want to go back
--return false means we cancelled out.
--return anything else, and this is the guide data for the channel they are requesting.

(*
on is_recording(caller, hdhr_model, show_time_check)
	set is_recording_temp to {}
	set tuner_offset to my HDHRDeviceSearch("hdhrguide", hdhr_model)
	repeat with i from 1 to length of show_info
		if hdhr_record of item i of show_info = hdhr_model then
		end if
	end repeat
end is_recording
*)

on show_info_dump(caller, show_id_lookup)
	#  (*show_title:Happy_Holidays_America, show_time:16, show_length:60, show_air_date:Sunday, show_transcode:missing value, show_temp_dir:alias Backups:, show_dir:alias Backups:, show_channel:5.1, show_active:true, show_id:221fbe1126389e6af35f405aa681cf19, #show_recording:false, show_last:date Sunday, December 13, 2020 at 4:04:54 PM, show_next:date Sunday, December 13, 2020 at 4:00:00 PM, show_end:date Sunday, December 13, 2020 at 5:00:00 PM, notify_upnext_time:missing value, #notify_recording_time:missing value, hdhr_record:XX105404BE,show_is_series:false*
	repeat with i from 1 to length of show_info
		my logger(true, "show_info_dump(" & caller & ", " & show_id_lookup & ")", "INFO", "show " & i & ", show_title: " & show_title of item i of show_info & ", show_time: " & show_time of item i of show_info & ", show_length: " & show_length of item i of show_info & ", show_air_date: " & show_air_date of item i of show_info & ", show_transcode: " & show_transcode of item i of show_info & ", show_temp_dir: " & show_temp_dir of item i of show_info & ", show_dir: " & show_dir of item i of show_info & ", show_channel: " & show_channel of item i of show_info & ", show_active: " & show_active of item i of show_info & ", show_id: " & show_id of item i of show_info & ", show_recording: " & show_recording of item i of show_info & ", show_last: " & show_last of item i of show_info & ", show_next: " & show_next of item i of show_info & ", show_end: " & notify_upnext_time of item i of show_info & ", notify_recording_time: " & notify_recording_time of item i of show_info & ", hdhr_record: " & hdhr_record of item i of show_info & ", show_is_series: " & show_is_series of item i of show_info)
	end repeat
end show_info_dump

on tuner_end(caller, hdhr_model)
	--Returns the number of seconds to next tuner timeout. 
	set temp to {}
	set lowest_number to 99999999
	if length of show_info > 0 then
		repeat with i from 1 to length of show_info
			if show_recording of item i of show_info = true and hdhr_record of item i of show_info = hdhr_model then
				set end of temp to ((show_end of item i of show_info) - (current date))
			end if
		end repeat
		if length of temp > 0 then
			repeat with i2 from 1 to length of temp
				if item i2 of temp < lowest_number and item i2 of temp > 0 then
					set lowest_number to item i2 of temp
				end if
			end repeat
		end if
		my logger(true, "tuner_end()", "INFO", "Next Tuner timeout estimate (sec): " & lowest_number & " from " & caller)
		return lowest_number
	end if
	return 0
end tuner_end

on tuner_status(caller, device_id)
	log "tuner_status: " & caller & " of " & device_id
	set temp_list to {}
	set tuner_offset to my HDHRDeviceSearch("tuner_status", device_id)
	if tuner_offset = 0 then
		return true
	end if
	set hdhr_discover_temp to my hdhr_api(statusURL of item tuner_offset of HDHR_DEVICE_LIST, "", "", "")
	repeat with i from 1 to length of hdhr_discover_temp
		if length of item i of hdhr_discover_temp = 1 then
			my logger(true, "tuner_status()", "INFO", device_id & " currently available")
			return true
		end if
	end repeat
	my logger(true, "tuner_status()", "WARN", device_id & "is currently unavailable")
	return false
end tuner_status

on check_version()
	set version_response to (fetch JSON from version_url)
	set version_remote to hdhr_version of item 1 of versions of version_response
	my logger(true, "check_version()", "INFO", "Current Version: " & version_local & ", Remote Version: " & version_remote)
	if version_remote > version_local then
		my logger(true, "check_version()", "INFO", "Changelog: " & changelog of item 1 of versions of version_response)
	end if
end check_version

on check_version_dialog()
	if version_remote > version_local then
		set temp to version_local & " " & update_icon & " " & version_remote
	end if
	if version_remote < version_local then
		set temp to "Beta " & version_local
	end if
	if version_remote = version_local then
		set temp to version_local
	end if
	return temp
end check_version_dialog

on daysuntil(thisdate)
	log thisdate
	set seed_date to current date
	repeat with i from 0 to 6
		if (weekday of (seed_date + i * days) as text) = thisdate then return i
	end repeat
end daysuntil

on check_offset(the_show_id)
	--log "check_offset: " & the_show_id
	if length of show_info > 0 then
		repeat with i from 1 to length of show_info
			if show_id of item i of show_info = the_show_id then
				--log "check_offset2: " & show_id of item i of show_info
				return i
			end if
		end repeat
	end if
end check_offset

on build_channel_list(caller, hdhr_device) -- We need to have the two values in a list, so we can reference one, and pull the other, replacing channel2name
	log "build_channel_list: " & caller
	set channel_list_temp to {}
	try
		if hdhr_device = "" then
			repeat with i from 1 to length of HDHR_DEVICE_LIST
				my build_channel_list("build_channel_list0", device_id of item i of HDHR_DEVICE_LIST)
			end repeat
		else
			set tuner_offset to my HDHRDeviceSearch("build_channel_list", hdhr_device)
			set temp to hdhr_lineup of item tuner_offset of HDHR_DEVICE_LIST
			--set channel_list to {}
			repeat with i from 1 to length of temp
				try
					if HD of item i of temp = 1 then
						set end of channel_list_temp to GuideNumber of item i of temp & " " & GuideName of item i of temp & " [HD]"
					end if
				on error
					set end of channel_list_temp to GuideNumber of item i of temp & " " & GuideName of item i of temp
				end try
			end repeat
			set channel_mapping of item tuner_offset of HDHR_DEVICE_LIST to channel_list_temp
			my logger(true, "build_channel_list()", "INFO", "Updated Channel list for " & hdhr_device & " length: " & length of channel_list_temp & " from " & caller)
		end if
	on error
		my logger(true, "build_channel_list()", "ERROR", "Unable to build channel list")
	end try
	
end build_channel_list

on channel2name(the_channel, hdhr_device)
	my logger(true, "channel2name()", "DEBUG", the_channel & " on " & hdhr_device)
	set tuner_offset to my HDHRDeviceSearch("channel2name0", hdhr_device)
	set channel2name_temp to hdhr_lineup of item tuner_offset of HDHR_DEVICE_LIST
	repeat with i from 1 to length of channel2name_temp
		if GuideNumber of item i of channel2name_temp = the_channel then
			my logger(true, "channel2name()", "INFO", "returned " & length of GuideNumber of item i of channel2name_temp & " entries for channel " & the_channel & " on " & hdhr_device)
			return GuideName of item i of channel2name_temp
		end if
	end repeat
	--FIXed We need to make things that call this that it may not pull anything, in which case the channnel lineup no longer contains this channel.  We now just skip the show if the channel is no longer in the lineup
	my logger(true, "channel2name()", "ERROR", "We were not able to pull lineup data for channel " & the_channel & " for device " & hdhr_device)
	--return false
end channel2name

--show_next should only return the next record time, considering recording and not a list of all record times, if a show is recording, that time should remain as returned
on nextday(the_show_id)
	set cd_object to current date
	set nextup to {}
	set show_offset to my check_offset(the_show_id)
	--log item show_offset of show_info
	--log "length of show info: " & length of show_info
	repeat with i from 0 to 7
		if the_show_id = show_id of item show_offset of show_info then
			--display dialog "test1"
			--log "Shows match"
			--log ((weekday of (cd_object + i * days)))
			--log (show_air_date of item show_offset of show_info)
			if ((weekday of (cd_object + i * days)) as text) is in (show_air_date of item show_offset of show_info) then
				--log "1: " & (weekday of (cd_object + i * days)) & " is in " & show_air_date of item show_offset of show_info as string
				--log "2: " & (my time_set((cd_object + i * days), (show_time of item show_offset of show_info))) + ((show_length of item show_offset of show_info) * minutes)
				if cd_object < (my time_set((cd_object + i * days), (show_time of item show_offset of show_info))) + ((show_length of item show_offset of show_info) * minutes) then
					--display dialog "test3"
					--end time in future
					set nextup to my time_set((cd_object + i * days), show_time of item show_offset of show_info)
					exit repeat
				end if
			end if
		end if
	end repeat
	--log show_length of item show_offset of show_info
	set show_end of item show_offset of show_info to nextup + ((show_length of item show_offset of show_info) * minutes)
	--log nextup
	return nextup
end nextday

on validate_show_info(caller, show_to_check, should_edit)
	--display dialog show_to_check & " ! " & should_edit
	--(*show_title:news, show_time:12, show_length:30, show_air_date:Monday, Tuesday, Wednesday, Thursday, show_transcode:false, show_temp_dir:alias Macintosh HD:Users:TEST:Dropbox:, show_dir:alias Macintosh HD:Users:TESTl:Dropbox:, show_channel:11.1, show_active:true, show_id:bf4fcd8b7ac428594a386b373ef55874, show_recording:false, show_last:date Tuesday, August 30, 2016 at 11:35:04 AM, show_next:date Tuesday, August 30, 2016 at 12:00:00 PM, show_end:date Tuesday, August 30, 2016 at 12:30:00 PM*)
	
	if show_to_check = "" then
		repeat with i2 from 1 to length of show_info
			my validate_show_info("validate_show_info0", show_id of item i2 of show_info, should_edit)
		end repeat
	else
		set i to my check_offset(show_to_check)
		my logger(true, "validate_show_info(" & caller & ", " & show_to_check & ", " & should_edit & ")", "INFO", "Running validate on " & show_title of item i of show_info & ", should_edit: " & should_edit)
		if should_edit = true then
			--FIX: See if the selected show channel is still listed in the lineup.
			--show_recording of item i of show_info = false and show_end of item i of show_info < (current date) and show_is_series of item i of show_info = false
			if show_active of item i of show_info = true then
				set show_deactivate to (display dialog "Would you like to deactivate: " & return & "\"" & show_title of item i of show_info & "\"" & return & return & "Deactivated shows will be removed on the next save/load" buttons {play_icon & " Run", "Deactivate", "Next"} cancel button 1 default button 3 with title my check_version_dialog() with icon stop)
				if button returned of show_deactivate = "Deactivate" then
					set show_active of item i of show_info to false
					my logger(true, "validate_show_info()", "INFO", "Deactivated: " & show_title of item i of show_info)
					my main("shows", "Shows")
				else if button returned of show_deactivate contains "Run" then
					my logger(true, "validate_show_info()", "INFO", "User clicked \"Run\"")
				end if
			else if show_active of item i of show_info = false then
				set show_deactivate to (display dialog "Would you like to activate: " & return & "\"" & show_title of item i of show_info & "\"" & return & return & "Active shows can be edited" buttons {play_icon & " Run", "Activate"} cancel button 1 default button 2 with title my check_version_dialog() with icon note)
				if button returned of show_deactivate = "Activate" then
					set show_active of item i of show_info to true
					my logger(true, "validate_show_info()", "INFO", "Reactivated: " & show_title of item i of show_info)
				else if button returned of show_deactivate contains "Run" then
					my logger(true, "validate_show_info()", "INFO", "User clicked \"Run\"")
				end if
			end if
		end if
		my logger(true, "validate_show_info()", "DEBUG", show_title of item i of show_info & " is active? " & show_active of item i of show_info)
		if show_active of item i of show_info = true then
			if show_title of item i of show_info = missing value or show_title of item i of show_info = "" or should_edit = true then
				if show_is_series of item i of show_info is false then
					set show_title_temp to display dialog "What is the title of this show, and is it a Series?" & return & "Next Showing: " & my short_date("validate_show", show_next of item i of show_info, true, false) buttons {play_icon & " Run", series_icon & " Series", single_icon & " Single"} default button 3 cancel button 1 default answer show_title of item i of show_info with title my check_version_dialog() giving up after dialog_timeout
				else if show_is_series of item i of show_info is true then
					set show_title_temp to display dialog "What is the title of this show, and is it a Series?" & return & "Next Showing: " & my short_date("validate_show", show_next of item i of show_info, true, false) buttons {play_icon & " Run", series_icon & " Series", single_icon & " Single"} default button 2 cancel button 1 default answer show_title of item i of show_info with title my check_version_dialog() giving up after dialog_timeout
				end if
				my logger(true, "validate_show_info()", "INFO", "Show Title prompt: " & text returned of show_title_temp & ", button_pressed: " & button returned of show_title_temp)
				if button returned of show_title_temp contains "Series" then
					set show_is_series of item i of show_info to true
				else if button returned of show_title_temp contains "Single" then
					set show_is_series of item i of show_info to false
				end if
			end if
			
			--repeat until my is_number(show_channel of item i of show_info) or should_edit = true
			if show_channel of item i of show_info = missing value or my is_number(show_channel of item i of show_info) = false or should_edit = true then
				
				set temp_tuner to hdhr_record of item i of show_info
				--display dialog temp_tuner
				set tuner_offset to my HDHRDeviceSearch("channel2name0", temp_tuner)
				--display dialog "tuner_offset: " & tuner_offset
				set temp_channel_offset to my list_position("validate_show_info1", show_channel of item i of show_info, channel_mapping of item tuner_offset of HDHR_DEVICE_LIST, false)
				set channel_temp to word 1 of item 1 of (choose from list channel_mapping of item tuner_offset of HDHR_DEVICE_LIST with prompt "What channel does this show air on?" default items item temp_channel_offset of channel_mapping of item tuner_offset of HDHR_DEVICE_LIST with title my check_version_dialog() cancel button name play_icon & " Run" OK button name "Next.." without empty selection allowed)
				if channel_temp = false then
					my logger(true, "validate_show_info()", "INFO", "User clicked \"Run\"")
				end if
				my logger(true, "validate_show_info()", "INFO", "Channel Prompt returned: " & channel_temp)
				set show_channel of item i of show_info to channel_temp --set show_channel of item i of show_info to word 1 of item 1 of (choose from list channel_list with prompt "What channel does this show air on?" default items show_channel of item i of show_info without empty selection allowed) 
			end if
			--end repeat  
			
			if show_time of item i of show_info = missing value or (show_time of item i of show_info as number) ³ 24 or my is_number(show_time of item i of show_info) = false or should_edit = true then
				set show_time of item i of show_info to text returned of (display dialog "What time does this show air? " & return & "(0-24, use decimals, ie 9.5 for 9:30)" default answer show_time of item i of show_info buttons {play_icon & " Run", "Next.."} with title my check_version_dialog() giving up after dialog_timeout default button 2 cancel button 1) as number
			end if
			if show_length of item i of show_info = missing value or my is_number(show_length of item i of show_info) = false or show_length of item i of show_info ² 0 or should_edit = true then
				set show_length of item i of show_info to text returned of (display dialog "How long is this show? (in minutes)" default answer show_length of item i of show_info with title my check_version_dialog() buttons {play_icon & " Run", "Next.."} default button 2 cancel button 1 giving up after dialog_timeout)
			end if
			
			if show_air_date of item i of show_info = missing value or length of show_air_date of item i of show_info = 0 or should_edit = true then
				set show_air_date of item i of show_info to (choose from list {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"} default items show_air_date of item i of show_info with title my check_version_dialog() OK button name "Next.." cancel button name play_icon & " Run" with prompt "Select the days you wish to record" & return & "If this is a series, you can select multiple days" with multiple selections allowed without empty selection allowed)
			end if
			
			if show_dir of item i of show_info = missing value or (class of (show_temp_dir of item i of show_info) as text) ­ "alias" or should_edit = true then
				set show_dir of item i of show_info to choose folder with prompt "Select Shows Directory" default location show_dir of item i of show_info
				set show_temp_dir of item i of show_info to show_dir of item i of show_info
			end if
			
			if show_next of item i of show_info = missing value or (class of (show_next of item i of show_info) as text) ­ "date" or should_edit = true then
				if show_is_series of item i of show_info = true then
					set show_next of item i of show_info to my nextday(show_id of item i of show_info)
				end if
			end if
		end if
	end if
end validate_show_info

on setup()
	set hdhr_setup_response to (display dialog "hdhr_VCR Setup" buttons {"Defaults", "Delete", play_icon & " Run"} default button 1 cancel button 3 with title my check_version_dialog() giving up after dialog_timeout)
	if button returned of hdhr_setup_response = "Defaults" then
		set temp_dir to alias "Volumes:"
		repeat until temp_dir ­ alias "Volumes:"
			set hdhr_setup_folder to choose folder with prompt "Select default Shows Directory" default location temp_dir
		end repeat
		--write data here
		display dialog "We need to allow notifications" & return & "Click \"Next\" to continue." buttons {"Next"} default button 1 with title my check_version_dialog() giving up after dialog_timeout
		display notification "Yay!" with title name of me subtitle "Notifications Enabled!"
		--
		
		set hdhr_setup_transcode to button returned of (display dialog "Use transcoding with \"Extend\" devices?" buttons {"Yes", "No"} default button 2)
		set hdhr_setup_name_bool to button returned of (display dialog "Use custom naming?" buttons {"Yes", "No"} default button 2)
		set hdhr_setup_length_bool to button returned of (display dialog "Use custom show length? (minutes)" buttons {"Yes", "No"} default button 2) --default answer "30"
		set notify_upnext to text returned of (display dialog "How often to show \"Up Next\" update notifications?" default answer notify_upnext)
		set notify_recording to text returned of (display dialog "How often to show \"Recording\" update notifications?" default answer notify_recording)
		set hdhr_setup_ran to true
	end if
	if button returned of hdhr_setup_response = "Delete" then
		--Just set the show_active to false
		--  if my remove_show("setup0", "?")
	end if
	
end setup

on main(caller, emulated_button_press)
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
	set show_info_length to length of show_info
	if show_info_length > 0 then
		repeat with i from 1 to show_info_length
			if show_last of item i of show_info ­ my epoch() and show_is_series of item i of show_info = false then
				set show_active of item i of show_info to false
			end if
		end repeat
	end if
	
	activate me
	
	if emulated_button_press is not in {"Add", "Shows"} then
		set title_response to (display dialog "Would you like to add a show?" buttons {tv_icon & " Shows..", plus_icon & " Add..", play_icon & " Run"} with title my check_version_dialog() giving up after (dialog_timeout * 0.5) with icon note default button 2)
	else
		set title_response to {button returned:emulated_button_press}
	end if
	
	
	if button returned of title_response contains "Add" then
		my logger(true, "main()", "INFO", "UI:Clicked \"Add\"")
		set temp_tuners_list to {}
		repeat with i from 1 to length of HDHR_DEVICE_LIST
			
			log "main()"
			log item i of HDHR_DEVICE_LIST
			set end of temp_tuners_list to hdhr_model of item i of HDHR_DEVICE_LIST & " " & (device_id of item i of HDHR_DEVICE_LIST)
		end repeat
		if length of temp_tuners_list > 1 then
			set preferred_tuner to choose from list temp_tuners_list with prompt "Multiple HDHR Devices found, please choose one" cancel button name play_icon & " Run" OK button name "Select" with title my check_version_dialog()
			if preferred_tuner ­ false then
				my logger(true, "main()", "INFO", "User clicked \"Run\"")
				set hdhr_device to last word of item 1 of preferred_tuner
			else
				set hdhr_device to missing value
			end if
		else
			--set hdhr_device to hdhr_model of item 1 of HDHR_DEVICE_LIST
			set hdhr_device to device_id of item 1 of HDHR_DEVICE_LIST
		end if
		my add_show_info(hdhr_device)
	end if
	
	if button returned of title_response contains "Shows" then
		
		if option_down of my isModifierKeyPressed("main_opt", "option") = true then
			my HDHRDeviceDiscovery("main_opt", "")
			my update_show("")
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
		set show_list_length to length of show_info
		repeat with i from 1 to show_list_length
			--set end of show_list to (show_title of item i of show_info & "\" on " & show_channel of item i of show_info & " at " & show_time of item i of show_info & " for " & show_length of item i of show_info & " minutes on " & show_air_date)
			--display notification class of show_recording of item i of show_info
			set temp_show_line to " " & (show_title of item i of show_info & " on " & show_channel of item i of show_info & " at " & show_time of item i of show_info & " for " & show_length of item i of show_info & " minutes on " & my listtostring("main", show_air_date of item i of show_info, ", "))
			
			if show_is_series of item i of show_info = true then
				set temp_show_line to series_icon & temp_show_line
			else
				set temp_show_line to single_icon & temp_show_line
			end if
			
			if show_active of item i of show_info = true then
				--set temp_show_line to check_icon & temp_show_line
			else
				set temp_show_line to uncheck_icon & temp_show_line
			end if
			
			if ((show_next of item i of show_info) - (current date)) < 4 * hours and show_active of item i of show_info = true and show_recording of item i of show_info = false then
				if ((show_next of item i of show_info) - (current date)) > 1 * hours then
					set temp_show_line to up_icon & temp_show_line
				else
					set temp_show_line to film_icon & temp_show_line
				end if
			end if
			
			if ((show_next of item i of show_info) - (current date)) ³ 4 * hours and (date (date string of (current date))) = (date (date string of (show_next of item i of show_info))) and show_active of item i of show_info = true and show_recording of item i of show_info = false then
				set temp_show_line to up2_icon & temp_show_line
			end if
			
			if show_recording of item i of show_info = true and show_active of item i of show_info = true then
				set temp_show_line to record_icon & temp_show_line
			end if
			
			if (date (date string of (current date))) < (date (date string of (show_next of item i of show_info))) and show_active of item i of show_info = true then
				set temp_show_line to calendar_icon & temp_show_line
			end if
			
			if my recorded_today(show_id of item i of show_info) = true then
				set temp_show_line to done_icon & temp_show_line
			end if
			
			## Fix we need to tag a show that completed a record for the day 
			(*
				if (date (date string of (current date))) = (date (date string of (show_last of item i of show_info))) and show_active of item i of show_info = true and (show_last of item i of show_info) < (current date) then
				set temp_show_line to calendar2_icon & temp_show_line
			end if
				*)
			set end of show_list to temp_show_line
		end repeat
		if length of show_list = 0 then
			--	display dialog "2"
			try
				my logger(true, "main()", "WARN", "There are no shows")
				set hdhr_no_shows to button returned of (display dialog "There are no shows, why don't you add one?" buttons {"Quit", plus_icon & " Add Show"} default button 2)
				if hdhr_no_shows contains "Add Show" then
					--This should kick us to the adding a show handler.
					my main("main_noshow", "Add")
				end if
				if hdhr_no_shows = "Quit" then
					quit {}
				end if
				--We need a to prompt user for perferred tuner here to make this work. 
			on error
				my logger(true, "main()", "INFO", "User clicked \"Run\"")
				return
			end try
		else if length of show_list > 0 then
			set temp_show_list to (choose from list show_list with title my check_version_dialog() with prompt "Select show to edit: " & return & single_icon & " Single   " & series_icon & " Series" & "   " & record_icon & " Recording" & "   " & uncheck_icon & " Inactive" & return & film_icon & " Up Next < 1h" & "  " & up_icon & " Up Next < 4h" & "  " & up2_icon & " Up Next > 4h" & "  " & calendar_icon & " Future Show" OK button name edit_icon & " Edit.." cancel button name play_icon & " Run" without empty selection allowed)
			if temp_show_list ­ false then
				set temp_show_list_offset to (my list_position("main1", (temp_show_list as text), show_list, true))
				log "temp_show_list_offset"
				log temp_show_list_offset
				my logger(true, "main()", "DEBUG", "Pre validate for " & show_id of item temp_show_list_offset of show_info)
				my validate_show_info("main", show_id of item temp_show_list_offset of show_info, true)
				if show_active of item (temp_show_list_offset) of show_info = true then
					my update_show(show_id of item temp_show_list_offset of show_info)
					set show_next of item temp_show_list_offset of show_info to my nextday(show_id of item temp_show_list_offset of show_info)
				end if
				--set (show_next of temp_show_list_offset of show_info) to my nextday(show_id of temp_show_list_offset)
				
				my save_data()
			else
				my logger(true, "main()", "INFO", "User clicked \"Run\"")
				return false
			end if
		end if
	end if
end main

on recorded_today(the_show_id)
	---- show_info model: (*show_title:Happy_Holidays_America, show_time:16, show_length:60, show_air_date:Sunday, show_transcode:missing value, show_temp_dir:alias Backups:, show_dir:alias Backups:, show_channel:5.1, show_active:true, show_id:221fbe1126389e6af35f405aa681cf19, show_recording:false, show_last:date Sunday, December 13, 2020 at 4:04:54 PM, show_next:date Sunday, December 13, 2020 at 4:00:00 PM, show_end:date Sunday, December 13, 2020 at 5:00:00 PM, notify_upnext_time:missing value, notify_recording_time:missing value, hdhr_record:XX105404BE,show_is_series:false*
	
	--takes show_id and returns true if the show has already recorded today.
	repeat with i from 1 to length of show_info
		if show_id of item i of show_info = the_show_id then
			if show_last of item i of show_info ² (current date) and date string of show_last of item i of show_info = date string of (current date) and time string of show_last of item i of show_info < time string of (current date) then
				my logger(true, "recorded_today()", "INFO", "show_title: " & show_title of item i of show_info & ", show_last: " & show_last of item i of show_info & ", show_next: " & show_next of item i of show_info)
				return true
			end if
		end if
	end repeat
	return false
end recorded_today

on add_show_info(hdhr_device)
	set tuner_status_result to my tuner_status("add_show", hdhr_device)
	set tuner_status_icon to "Tuner: " & hdhr_device
	
	if tuner_status_result = false then
		set tuner_status_icon to hdhr_device & " has no available tuners" & return & "Next timeout: " & my tuner_end("add_show_info()", hdhr_device)
	end if
	
	set tuner_offset to my HDHRDeviceSearch("add_show_info0", hdhr_device)
	set show_channel to missing value
	set temp_show_info to {show_title:missing value, show_time:missing value, show_length:missing value, show_air_date:missing value, show_transcode:missing value, show_temp_dir:missing value, show_dir:missing value, show_channel:missing value, show_active:true, show_id:(do shell script "date | md5") as text, show_recording:false, show_last:my epoch(), show_next:missing value, show_end:missing value, notify_upnext_time:missing value, notify_recording_time:missing value, hdhr_record:hdhr_device, show_is_series:false}
	
	--set temp_show_info to {show_title:missing value, show_time:missing value, show_length:missing value, show_air_date:missing value, show_transcode:missing value, show_temp_dir:missing value, show_dir:missing value, show_channel:missing value, show_active:true, show_id:(do shell script "date | md5") as text, show_recording:false, show_last:my epoch(), show_next:missing value, show_end:missing value, notify_upnext_time:missing value, notify_recording_time:missing value, hdhr_record:hdhr_device, show_is_series:false}
	
	if hdhr_device = "" then
		if length of HDHR_DEVICE_LIST = 1 then
			set hdhr_device to device_id of item 1 of HDHR_DEVICE_LIST
		end if
	end if
	
	--What channel?  We need at least this to pull a guide. 
	set hdhrGRID_response to true
	repeat until hdhrGRID_response ­ true
		set hdhrGRID_list_response to (choose from list channel_mapping of item tuner_offset of HDHR_DEVICE_LIST with prompt "What channel does this show air on?" & return & return & tuner_status_icon with title my check_version_dialog() OK button name "Next.." cancel button name play_icon & " Run" without empty selection allowed)
		if hdhrGRID_list_response ­ false then
			set show_channel of temp_show_info to word 1 of item 1 of hdhrGRID_list_response
			
			if option_down of my isModifierKeyPressed("add", "option") = true then
				set hdhrGRID_response to false
			else
				set hdhrGRID_response to my hdhrGRID("add_show_info()", hdhr_device, show_channel of temp_show_info)
			end if
		else
			my logger(true, "add_show_info()", "INFO", "User clicked \"Run\"")
			error number -128
		end if
	end repeat
	
	--The above line pulls guide data.  If we fail this, we will prompt the user to enter the information.
	set time_slide to 0
	set default_record_day to (weekday of ((current date) + time_slide * days)) as text
	if hdhrGRID_response = false then
		my logger(true, "add_show_info()", "INFO", "Manually adding show for " & hdhr_device)
		--title
		
		set show_title_temp to display dialog "What is the title of this Show, and is it a series?" buttons {play_icon & " Run", series_icon & " Series", single_icon & " Single"} cancel button 1 default button 3 default answer "" with title my check_version_dialog() giving up after dialog_timeout
		set show_title of temp_show_info to text returned of show_title_temp
		my logger(true, "add_show_info()", "INFO", "(Manual) Show name: " & show_title of temp_show_info)
		--show_is_series
		if button returned of show_title_temp contains "Series" then
			set show_is_series of temp_show_info to true
		else if button returned of show_title_temp contains "Single" then
			set show_is_series of temp_show_info to false
		else
			return
		end if
		my logger(true, "add_show_info()", "INFO", "(Manual) show_is_series: " & show_is_series of temp_show_info)
		--time
		repeat until my is_number(show_time of temp_show_info) and show_time of temp_show_info ³ 0 and show_time of temp_show_info < 24
			set show_time of temp_show_info to text returned of (display dialog "What time does this show air? " & return & "(0-24, use decimals, ie 16.5 for 4:30 PM)" default answer hours of (current date) buttons {play_icon & " Run", "Next.."} with title my check_version_dialog() giving up after dialog_timeout default button 2 cancel button 1) as number
		end repeat
		my logger(true, "add_show_info()", "INFO", "(Manual) show time: " & show_time of temp_show_info)
		--length
		repeat until my is_number(show_length of temp_show_info) and show_length of temp_show_info ³ 1
			set show_length of temp_show_info to text returned of (display dialog "How long is this show? (in minutes)" default answer "30" with title my check_version_dialog() buttons {play_icon & " Run", "Next.."} default button 2 cancel button 1 giving up after dialog_timeout)
		end repeat
		my logger(true, "add_show_info()", "INFO", "(Manual) show length: " & show_length of temp_show_info)
	else
		--We were able to pull guide data 
		--set hdhr_response_channel to hdhrGRID_response
		
		--auto title 
		try
			set hdhr_response_channel_title to title of hdhrGRID_response
			set hdhr_response_channel_title to hdhr_response_channel_title & " " & EpisodeNumber of hdhr_response_channel
			set hdhr_response_channel_title to hdhr_response_channel_title & " " & EpisodeTitle of hdhr_response_channel
		on error
			my logger(true, "add_show_info()", "INFO", "(Auto) Unable to set show name")
		end try
		
		set show_title of temp_show_info to hdhr_response_channel_title
		my logger(true, "add_show_info()", "INFO", "(Auto) Show name: " & show_title of temp_show_info)
		
		--auto length
		try
			set show_length of temp_show_info to ((EndTime of hdhrGRID_response) - (StartTime of hdhrGRID_response)) div 60
		on error
			my logger(true, "add_show_info()", "WARN", "(Auto) show time defaulted to 30")
			set show_length of temp_show_info to 30
		end try
		my logger(true, "add_show_info()", "INFO", "(Auto) show length: " & show_length of temp_show_info)
		
		--auto show_time
		set show_time of temp_show_info to my epoch2show_time(my getTfromN(StartTime of hdhrGRID_response))
		my logger(true, "add_show_info()", "INFO", "(Auto) show time: " & show_time of temp_show_info)
		try
			set synopsis_temp to Synopsis of hdhrGRID_response
		on error
			my logger(true, "add_show_info()", "WARN", "Unable to pull Synopsis")
			set synopsis_temp to "No Synopsis provided"
		end try
		
		set temp_show_info_series to (display dialog "Is this a single or a series recording? " & return & return & "Title: " & show_title of temp_show_info & return & return & "Synopsis: " & synopsis_temp & return & "Start: " & show_time of temp_show_info & return & "Length: " & show_length of temp_show_info buttons {"Cancel", series_icon & " Series", single_icon & " Single"} default button 3 with title my check_version_dialog() giving up after dialog_timeout with icon note)
		
		if button returned of temp_show_info_series contains "Series" then
			set show_is_series of temp_show_info to true
		else if button returned of temp_show_info_series contains "Single" then
			set show_is_series of temp_show_info to false
		end if
		my logger(true, "add_show_info()", "INFO", "(Auto) show_is_series: " & show_is_series of temp_show_info)
	end if
	
	
	
	set time_slide to 0
	--if hdhrGRID_response is not in  {false, true} then
	if show_is_series of temp_show_info = true then
		--set show_air_date of temp_show_info to (choose from list {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"} with prompt "Please choose the days this series airs." default items default_record_day with multiple selections allowed without empty selection allowed)
		
		set show_air_date of temp_show_info to (choose from list {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"} default items default_record_day with title my check_version_dialog() OK button name "Next.." cancel button name play_icon & " Run" with prompt "Select the days you wish to record." & return & "A \"Series\" can select multiple days." with multiple selections allowed without empty selection allowed)
		my logger(true, "add_show_info()", "INFO", "(Manual) show_air_date: " & show_air_date of temp_show_info)
	end if
	if show_is_series of temp_show_info = false then
		if hdhrGRID_response = false then
			set show_air_date of temp_show_info to (choose from list {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"} default items default_record_day with title my check_version_dialog() OK button name "Next.." cancel button name play_icon & " Run" with prompt "Select the day you wish to record." & return & "A \"Single\" can only select 1 day." without empty selection allowed)
			my logger(true, "add_show_info()", "INFO", "(Manual) show_air_date: " & show_air_date of temp_show_info)
		else
			set show_air_date of temp_show_info to weekday of (my epoch2datetime((my getTfromN(StartTime of hdhrGRID_response)))) as text
			my logger(true, "add_show_info()", "INFO", "(Auto) show_air_date: " & show_air_date of temp_show_info)
		end if
	end if
	
	set model_response to ""
	
	set progress description to "Choose Folder..."
	set temp_dir to alias "Volumes:"
	repeat until temp_dir ­ alias "Volumes:"
		set show_dir of temp_show_info to choose folder with prompt "Select Shows Directory" default location temp_dir
		if show_dir of temp_show_info ­ temp_dir then
			set temp_dir to show_dir of temp_show_info
		end if
	end repeat
	my logger(true, "add_show_info()", "INFO", "Show Directory: " & show_dir of temp_show_info)
	my update_folder(show_dir of temp_show_info)
	
	
	if does_transcode of item tuner_offset of HDHR_DEVICE_LIST = 1 then
		set show_transcode_response to (choose from list {"None: Does not transcode, will save as MPEG2 stream.", "heavy: Transcode with same settings", "mobile: Transcode not exceeding 1280x720 30fps", "intenet720: Low bit rate, not exceeding 1280x720 30fps", "internet480: Low bit rate not exceeding 848x480/640x480 for 16:9/4:3 30fps", "internet360: Low bit rate not exceeding 640x360/480x360 for 16:9/4:3 30fps", "internet240: Low bit rate not exceeding 432x240/320x240 for 16:9/4:3 30fps"} with prompt "Please choose the transcode level on the file" with title my check_version_dialog() default items {"None: Does not transcode, will save as MPEG2 stream."} OK button name disk_icon & " Save Show" cancel button name play_icon & " Run")
		try
			set show_transcode of temp_show_info to word 1 of item 1 of show_transcode_response
		on error
			set show_transcode of temp_show_info to "None"
			my logger(true, "add_show_info()", "INFO", "User clicked \"Run\"")
			return false
		end try
	end if
	my logger(true, "add_show_info()", "INFO", "Transcode: " & show_transcode of temp_show_info)
	--	end if
	--commit the temp_show_info to show_info
	set show_temp_dir of temp_show_info to show_dir of temp_show_info
	set end of show_info to temp_show_info
	my logger(true, "add_show_info()", "DEBUG", "Adding temp_show_info to end of show_info, count: " & length of show_info)
	--display dialog show_id of last item of show_info
	set show_next of last item of show_info to my nextday(show_id of temp_show_info)
	my validate_show_info("add_show_info", show_id of last item of show_info, false)
	log show_info
	my save_data()
end add_show_info

on record_now(the_show_id, opt_show_length)
	-- FIX We need to return a true/false if this is successful
	--display notification opt_show_length
	set i to my check_offset(the_show_id)
	my update_show(the_show_id)
	set hdhr_device to hdhr_record of item i of show_info
	set tuner_offset to my HDHRDeviceSearch("HDHRDeviceDiscovery0", hdhr_device)
	if opt_show_length ­ missing value then
		set temp_show_length to opt_show_length as number
	else
		set temp_show_length to show_length of item i of show_info as number
	end if
	
	--skip recording, and mark it as complete if < 0
	if temp_show_length < 0 then
		my logger(true, "record_now()", "INFO", show_title of item i of show_info & " has a duration of " & temp_show_length)
		--display notification "Negative duration: " & show_title of item i of show_info
	end if
	if show_transcode of item i of show_info = missing value or show_transcode of item i of show_info = "None" then
		do shell script "caffeinate -i curl '" & BaseURL of item tuner_offset of HDHR_DEVICE_LIST & ":5004" & "/auto/v" & show_channel of item i of show_info & "?duration=" & (temp_show_length) & "' -o " & quoted form of (POSIX path of (show_temp_dir of item i of show_info) & show_title of item i of show_info & "_" & my short_date("record_now0", current date, true, true) & ".m2ts") & "> /dev/null 2>&1 &"
		my logger(true, "record_now()", "WARN", "caffeinate -i curl '" & BaseURL of item tuner_offset of HDHR_DEVICE_LIST & ":5004" & "/auto/v" & show_channel of item i of show_info & "?duration=" & (temp_show_length) & "' -o " & quoted form of (POSIX path of (show_temp_dir of item i of show_info) & show_title of item i of show_info & "_" & my short_date("record_now0", current date, true, true) & ".m2ts") & "> /dev/null 2>&1 &")
		--on ms2time(caller, totalMS, time_duration, level_precision)
		--		my logger(true, "record_now()", "INFO", show_title of item i of show_info & " started recording for " & temp_show_length)
		my logger(true, "record_now()", "INFO", show_title of item i of show_info & " started recording for " & my ms2time("record_now()", temp_show_length, "s", 3))
		--do shell script "caffeinate -i curl '" & my hdhr_prepare_record(hdhr_device) & ":5004" & "/auto/v" & show_channel of item i of show_info & "?duration=" & (temp_show_length) & "' -o " & quoted form of (POSIX path of (show_temp_dir of item i of show_info) & show_title of item i of show_info & "_" & my short_date("record_now0", current date, true) & ".m2ts") & "> /dev/null 2>&1 &"
	else
		--do shell script "caffeinate -i curl '" & my hdhr_prepare_record(hdhr_device) & ":5004" & "/auto/v" & show_channel of item i of show_info & "?duration=" & (temp_show_length) & "&transcode=" & show_transcode of item i of show_info & "' -o " & quoted form of (POSIX path of (show_temp_dir of item i of show_info) & show_title of item i of show_info & "_" & my short_date("record_now1", current date, true) & ".mkv") & "> /dev/null 2>&1 &"
		do shell script "caffeinate -i curl '" & BaseURL of item tuner_offset of HDHR_DEVICE_LIST & ":5004" & "/auto/v" & show_channel of item i of show_info & "?duration=" & (temp_show_length) & "&transcode=" & show_transcode of item i of show_info & "' -o " & quoted form of (POSIX path of (show_temp_dir of item i of show_info) & show_title of item i of show_info & "_" & my short_date("record_now1", current date, true, true) & ".mkv") & "> /dev/null 2>&1 &"
		my logger(true, "record_now()", "WARN", "caffeinate -i curl '" & BaseURL of item tuner_offset of HDHR_DEVICE_LIST & ":5004" & "/auto/v" & show_channel of item i of show_info & "?duration=" & (temp_show_length) & "&transcode=" & show_transcode of item i of show_info & "' -o " & quoted form of (POSIX path of (show_temp_dir of item i of show_info) & show_title of item i of show_info & "_" & my short_date("record_now1", current date, true, true) & ".mkv") & "> /dev/null 2>&1 &")
		my logger(true, "record_now()", "INFO", show_title of item i of show_info & " started recording for " & temp_show_length & " with " & show_transcode of item i of show_info)
	end if
	
	set show_recording of item i of show_info to true
	--display notification "Recording " & show_title of item i of show_info & " until " & show_end of item i of show_info
	--display dialog show_end of item i of show_info as text 
	--set show_end of item of show_info to (current date) + (show_length of item i of show_info as number)
	
	--	end if 
end record_now

on sort_show_list()
	set show_list_deactive to {}
	set show_list_active to {}
	set show_list_later to {}
	set show_list_recording to {}
	set show_list_up to {}
	set show_list_up2 to {}
	set show_list_soon to {}
	my logger(true, "sort_show_list()1", "DEBUG", "show_info length: " & length of show_info)
	repeat with i from 1 to length of show_info
		if show_recording of item i of show_info = true then
			set end of show_list_recording to item i of show_info
		end if
		if show_active of item i of show_info = false then
			set end of show_list_deactive to item i of show_info
		end if
		
		
		if ((show_next of item i of show_info) - (current date)) < 4 * hours and show_active of item i of show_info = true and show_recording of item i of show_info = false then
			if ((show_next of item i of show_info) - (current date)) > 1 * hours then
				set end of show_list_up to item i of show_info
			else
				set end of show_list_soon to item i of show_info
			end if
			
		end if
		
		if ((show_next of item i of show_info) - (current date)) ³ 4 * hours and (date (date string of (current date))) = (date (date string of (show_next of item i of show_info))) and show_active of item i of show_info = true and show_recording of item i of show_info = false then
			set end of show_list_up2 to item i of show_info
		end if
		
		if (date (date string of (current date))) < (date (date string of (show_next of item i of show_info))) and show_active of item i of show_info = true then
			set end of show_list_later to item i of show_info
		end if
		
	end repeat
	set temp_return to show_list_recording & show_list_soon & show_list_up & show_list_up2 & show_list_later & show_list_deactive
	my logger(true, "sort_show_list()2", "DEBUG", "show_info length: " & length of temp_return)
	return temp_return
end sort_show_list

on HDHRDeviceDiscovery(caller, hdhr_device)
	log "HDHRDeviceDiscovery: " & caller
	if hdhr_device is not "" then
		set tuner_offset to my HDHRDeviceSearch(caller & "-> HDHRDeviceDiscovery0", hdhr_device)
		--We need to move lineup it its own sub routine.
		--set hdhr_lineup of item tuner_offset of HDHR_TUNERS to my HDHR_api(lineup_url of item tuner_offset of HDHR_TUNERS, "", "", "")
		my logger(true, "HDHRDeviceDiscovery()", "DEBUG", "Pre getHDHR_Lineup")
		my getHDHR_Lineup("HDHRDeviceDiscovery0", hdhr_device)
		my logger(true, "HDHRDeviceDiscovery()", "DEBUG", "Pre getHDHR_Guide")
		my getHDHR_Guide("HDHRDeviceDiscovery0", hdhr_device)
		my logger(true, "HDHRDeviceDiscovery(" & caller & ", " & hdhr_device & ")", "INFO", "Completed Guide and Lineup Updates")
	else
		set HDHR_DEVICE_LIST to {}
		set progress additional description to "Discovering HDHomeRun Devices"
		set progress completed steps to 0
		my logger(true, "HDHRDeviceDiscovery()", "DEBUG", "Pre Discovery")
		set hdhr_device_discovery to my hdhr_api("", "", "", "/discover")
		my logger(true, "HDHRDeviceDiscovery()", "DEBUG", "POST Discovery, length: " & length of hdhr_device_discovery)
		set progress total steps to length of hdhr_device_discovery
		repeat with i from 1 to length of hdhr_device_discovery
			set progress completed steps to i
			try
				set tuner_transcode_temp to Transcode of item i of hdhr_device_discovery
			on error
				my logger(true, "HDHRDeviceDiscovery()", "WARN", "Unable to determine transcode settings")
				set tuner_transcode_temp to 0
			end try
			
			set end of HDHR_DEVICE_LIST to {hdhr_lineup_update:missing value, hdhr_guide_update:missing value, discover_url:DiscoverURL of item i of hdhr_device_discovery, lineup_url:LineupURL of item i of hdhr_device_discovery, device_id:deviceid of item i of hdhr_device_discovery, does_transcode:tuner_transcode_temp, hdhr_lineup:missing value, hdhr_guide:missing value, hdhr_model:missing value, channel_mapping:missing value, BaseURL:BaseURL of item i of hdhr_device_discovery, statusURL:(BaseURL of item i of hdhr_device_discovery & "/status.json")}
			--log statusURL of last item of HDHR_DEVICE_LIST
			log "HDHRDeviceDiscovery25"
			log last item of HDHR_DEVICE_LIST
			my logger(true, "HDHRDeviceDiscovery()", "INFO", "Added: " & device_id of last item of HDHR_DEVICE_LIST)
		end repeat
		--Add a fake device entry to make sure we dont break this for multiple devices.
		--set end of HDHR_DEVICE_LIST to {hdhr_lineup_update:missing value, hdhr_guide_update:missing value, discover_url:"http://10.0.1.101/discover.json", lineup_url:"http://10.0.1.101/lineup.json", device_id:"XX105404BE", does_transcode:0, hdhr_lineup:missing value, hdhr_guide:missing value, hdhr_model:missing value, channel_mapping:missing value, BaseURL:BaseURL of item 1 of hdhr_device_discovery, statusURL:"http://10.0.1.101/status.json"}
		
		--We now have a list of tuners, via a list of records in HDHR_TUNERS, now we want to pull a lineup, and a guide.
		
		
		if length of hdhr_device_discovery > 0 then
			repeat with i2 from 1 to length of HDHR_DEVICE_LIST
				my HDHRDeviceDiscovery("HDHRDeviceDiscovery0", device_id of item i2 of HDHR_DEVICE_LIST)
			end repeat
		else
			set HDHRDeviceDiscovery_none to display dialog "No HDHR devices can be found" buttons {"Quit", "Rescan"} default button 2 cancel button 1 with title my check_version_dialog() giving up after dialog_timeout
			if button returned of HDHRDeviceDiscovery_none = "Rescan" then
				my HDHRDeviceDiscovery("no_devices", "")
				my logger(true, "HDHRDeviceDiscovery()", "INFO", "No Devices Added")
			end if
			
			if button returned of HDHRDeviceDiscovery_none = "Quit" then
				quit {}
			end if
		end if
		--Now that we pulled new data, we need to update the shows we have.
		my update_show("")
		my build_channel_list("run2", "")
	end if
end HDHRDeviceDiscovery

on HDHRDeviceSearch(caller, hdhr_device)
	log "HDHRDeviceSearch: " & caller & ":" & hdhr_device
	--We need the ability to know which item offset our device_id lives at, so we can update or pull records appropriately.
	repeat with i from 1 to length of HDHR_DEVICE_LIST
		if (device_id of item i of HDHR_DEVICE_LIST as text) = (hdhr_device as text) then
			log "HDHRDeviceSearch: " & i
			return i
		end if
	end repeat
	log "HDHRDeviceSearch: 0"
	return 0
end HDHRDeviceSearch

on hdhr_api(hdhr_ready, hdhr_IP, hdhr_PORT, hdhr_endpoint)
	log "raw_hdhrapi: " & hdhr_IP & hdhr_PORT & hdhr_endpoint
	if hdhr_IP is in {"", {}, missing value} and hdhr_ready is in {"", {}, missing value} then
		set hdhr_IP to "http://my.hdhomerun.com"
	end if
	log "raw_hdhrapi2: " & hdhr_IP & hdhr_PORT & hdhr_endpoint
	
	if hdhr_ready is in {"", {}, missing value} then
		set hdhr_api_result to (fetch JSON from hdhr_IP & hdhr_PORT & hdhr_endpoint)
	else
		--Connection issue here hangs up jsonhelper
		set hdhr_api_result to (fetch JSON from hdhr_ready)
	end if
	set HDHR_api_result_cached to hdhr_api_result
	set HDHR_api_result_date_cached to current date
	return hdhr_api_result
end hdhr_api

on getHDHR_Guide(caller, hdhr_device)
	set progress total steps to 1
	set progress completed steps to 0
	set progress additional description to "Guide Refresh: " & hdhr_device
	log "hdhr_guideCaller: " & caller
	--lots of work to do.  We need to convert epoch times to a valid date, and compare this with the entered information from the recording.
	try
		set tuner_offset to my HDHRDeviceSearch("getHDHR_Guide0", hdhr_device)
		log "deviceID: " & device_id of item tuner_offset of HDHR_DEVICE_LIST
		log discover_url of item tuner_offset of HDHR_DEVICE_LIST
		set hdhr_discover_temp to my hdhr_api(discover_url of item tuner_offset of HDHR_DEVICE_LIST, "", "", "")
		--if hdhr_discover_temp is not in {"", {}, missing value} then
		--	display dialog "No HDHR device detected."
		--	return false
		--end if
		set device_auth to DeviceAuth of hdhr_discover_temp
		set hdhr_model of item tuner_offset of HDHR_DEVICE_LIST to ModelNumber of hdhr_discover_temp
		set hdhr_guide_data to my hdhr_api("http://api.hdhomerun.com/api/guide.php?DeviceAuth=" & device_auth, "", "", "")
		
		set hdhr_guide of item tuner_offset of HDHR_DEVICE_LIST to hdhr_guide_data
		set hdhr_guide_update of item tuner_offset of HDHR_DEVICE_LIST to current date
		my logger(true, "getHDHR_Guide()", "INFO", "Updated Guide for " & hdhr_device & " called from " & caller)
		set progress completed steps to 1
	on error
		set progress additional description to "ERROR on Guide Refresh: " & hdhr_device
		my logger(true, "getHDHR_Guid()", "ERROR", "ERROR on Guide Refresh: " & hdhr_device & ", will retry in 10 seconds")
		my getHDHR_Guide("getHDHR_Guide_error", hdhr_device)
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
	set hdhr_lineup of item tuner_offset of HDHR_DEVICE_LIST to my hdhr_api(lineup_url of item tuner_offset of HDHR_DEVICE_LIST, "", "", "")
	set hdhr_lineup_update of item tuner_offset of HDHR_DEVICE_LIST to current date
	my logger(true, "getHDHR_Lineup()", "INFO", "Updated lineup for " & hdhr_device & " called from " & caller)
	set progress completed steps to 1
end getHDHR_Lineup

on channel_guide(caller, hdhr_device, hdhr_channel, hdhr_time)
	my logger(true, "channel_guide()", "DEBUG", "caller: " & caller & ", hdhr_device: " & hdhr_device & ", hdhr_channel: " & hdhr_channel & ", hdhr_time: " & hdhr_time)
	set time_slide to 0
	set tuner_offset to my HDHRDeviceSearch("channel_guide0", hdhr_device)
	my logger(true, "channel_guide()", "DEBUG", "tuner_offset: " & tuner_offset)
	set temp_guide_data to missing value
	set hdhr_guide_temp to {}
	
	if hdhr_time ­ "" then
		if (hdhr_time + 1) < hours of (current date) then
			set time_slide to 1
		end if
		
		set hdhr_proposed_time to my datetime2epoch("channel_guide", (date (date string of ((current date) + time_slide * days))) + hdhr_time * hours - (time to GMT)) as number
		set hdhr_proposed_time to my getTfromN(hdhr_proposed_time)
		log "hdhr_proposed_time"
		log hdhr_proposed_time
		log "---"
	end if
	if HDHR_DEVICE_LIST ­ missing value then
		repeat with i from 1 to length of hdhr_guide of item tuner_offset of HDHR_DEVICE_LIST
			if hdhr_channel = GuideNumber of item i of hdhr_guide of item tuner_offset of HDHR_DEVICE_LIST then
				set temp_guide_data to item i of hdhr_guide of item tuner_offset of HDHR_DEVICE_LIST as record
				log "!!!!!"
				log temp_guide_data as record
			end if
		end repeat
		
		if temp_guide_data = missing value then
			my logger(true, "channel_guide()", "ERROR", hdhr_channel & " no longer exists on " & hdhr_device & ", exiting...")
			return false
		end if
		if hdhr_time = "" then
			return temp_guide_data as record
		end if
		--We need to now parse the json object and try to get the start and end times.
		repeat with i2 from 1 to length of Guide of temp_guide_data
			log "$1: " & my getTfromN(StartTime of item i2 of Guide of temp_guide_data)
			log "$2: " & hdhr_proposed_time
			try
				log "$3 : " & my getTfromN(EndTime of item i2 of Guide of temp_guide_data)
				log " "
			on error
				my logger(true, "channel_guide()", "ERROR", "Unable to parse: " & EndTime of item i2 of Guide of temp_guide_data)
				--display notification "NOTOK 1: " & EndTime of item i2 of Guide of temp_guide_data as text
			end try
			--log StartTime of item i2 of Guide of temp_guide_data
			--log EndTime of item i2 of Guide of temp_guide_data
			if (hdhr_proposed_time) ³ my getTfromN(StartTime of item i2 of Guide of temp_guide_data) and (hdhr_proposed_time) < my getTfromN(EndTime of item i2 of Guide of temp_guide_data) then
				log "11: " & (hdhr_proposed_time) & "=" & my getTfromN(StartTime of item i2 of Guide of temp_guide_data)
				try
					log "2: " & (hdhr_proposed_time) & "²" & my getTfromN(EndTime of item i2 of Guide of temp_guide_data)
					--try
					log "$Match"
					--end try
					
					return item i2 of Guide of temp_guide_data
					--					end if
				on error
					my logger(true, "channel_guide()", "ERROR", "Unable to match a show " & i2)
				end try
			end if
		end repeat
		
		--return temp_guide_data
		--if temp_guide_data ­ missing value then
		--	repeat with i2 from 1 to length of (Guide of temp_guide_data)
		--		--log "temp_data:"
		--		return i2 of Guide of temp_guide_data
		--log item i2 of Guide of temp_guide_data
		--	end repeat
		--end if
	else
		my logger(true, "channel_guide()", "INFO", "hdhr list has an empty value")
	end if
	return {}
end channel_guide

on update_show(the_show_id)
	if the_show_id = "" then
		repeat with i2 from 1 to length of show_info
			my update_show(show_id of item i2 of show_info)
		end repeat
	else
		set i to my check_offset(the_show_id)
		set time2show_next to (show_next of item i of show_info) - (current date)
		--We should allow the time we can grab this to the end of the show. VVV
		if time2show_next ² 5 * hours and time2show_next ³ 0 and show_active of item i of show_info = true then
			set hdhr_response_channel to {}
			set hdhr_response_channel to my channel_guide("update_show", hdhr_record of item i of show_info, show_channel of item i of show_info, show_time of item i of show_info)
			try
				if length of hdhr_response_channel > 0 then
					try
						set hdhr_response_channel_title to title of hdhr_response_channel
					on error
						set hdhr_response_channel_title to ""
						my logger(true, "update_show()", "ERROR", "Unable to set title of show")
					end try
					
					try
						set hdhr_response_channel_title to hdhr_response_channel_title & " " & EpisodeNumber of hdhr_response_channel
					end try
					
					try
						set hdhr_response_channel_title to hdhr_response_channel_title & " " & EpisodeTitle of hdhr_response_channel
					end try
					
					set show_title of item i of show_info to hdhr_response_channel_title
					try
						set show_length of item i of show_info to ((EndTime of hdhr_response_channel) - (StartTime of hdhr_response_channel)) div 60
					on error
						my logger(true, "update_show()", "ERROR", "Unable to set length of " & show_title of item i of show_info)
						--					display notification "3: " & show_title of item i of show_info
					end try
					--display dialog (show_next of item i of show_info) as text 
					--display dialog (show_length of item i of show_info) as text
					set show_end of item i of show_info to (show_next of item i of show_info) + ((show_length of item i of show_info) * minutes)
					--display notification "Show Updated: " & show_title of item i of show_info
					my logger(true, "update_show()", "INFO", "Updated " & show_title of item i of show_info)
				end if
			on error errmsg
				my logger(true, "update_show()", "ERROR", "Unable to update " & show_title of item i of show_info & " : " & errmsg)
				try
					my logger(true, "update_show2()", "ERROR", length of show_info)
				on error
					my logger(true, "update_show3()", "Unable to get length of show info")
				end try
			end try
		else
			my logger(true, "update_show()", "WARN", "Did not update the show " & show_title of item i of show_info & ", next_show in " & my ms2time("update_show1", ((show_next of item i of show_info) - (current date)), "s", 4))
		end if
	end if
end update_show

on save_data()
	my show_info_dump("save_data()", "")
	set ref_num to open for access file ((config_dir) & configfilename as text) with write permission
	if length of show_info > 0 then
		set eof of ref_num to 0
		repeat with i from 1 to length of show_info
			(* 
		log "show_title of item i of show_info"
		log class of show_title of item i of show_info 
		log "show_time of item i of show_info"
		log class of show_time of item i of show_info
		log "show_length of item i of show_info"
		log class of show_length of item i of show_info
		log my listtostring(show_air_date of item i of show_info, ", ")
		log class of my listtostring(show_air_date of item i of show_info, ", ")
		log "show_transcode of item i of show_info"
		log class of show_transcode of item i of show_info
		log "show_temp_dir of item i of show_info"
		log class of show_temp_dir of item i of show_info
		log "show_temp_dir of item i of show_info"
		log class of show_temp_dir of item i of show_info
		log "show_dir of item i of show_info "
		log class of show_dir of item i of show_info
		log "show_channel of item i of show_info"
		log class of show_channel of item i of show_info
		log "show_active of item i of show_info"
		log class of show_active of item i of show_info
		log " show_id of item i of show_info"
		log class of show_id of item i of show_info
		log "show_recording of item i of show_info "
		log class of show_recording of item i of show_info
		log "show_last of item i of show_info"
		log class of show_last of item i of show_info
		log "show_next of item i of show_info"
		log class of show_next of item i of show_info
		log "show_end of item i of show_info"
		log class of show_end of item i of show_info
		log "show_is_series of item i of show_info"
		log class of show_is_series of item i of show_info
		log "hdhr_record of item i of show_info"
		log class of hdhr_record of item i of show_info
		*)
			if show_active of item i of show_info = true then
				write ("--NEXT SHOW--" & return & show_title of item i of show_info & return & show_time of item i of show_info & return & show_length of item i of show_info & return & my listtostring("save_data", show_air_date of item i of show_info, ", ") & return & show_transcode of item i of show_info & return & show_temp_dir of item i of show_info & return & show_dir of item i of show_info & return & show_channel of item i of show_info & return & show_active of item i of show_info & return & show_id of item i of show_info & return & show_recording of item i of show_info & return & show_last of item i of show_info & return & show_next of item i of show_info & return & show_end of item i of show_info & return & show_is_series of item i of show_info & return & hdhr_record of item i of show_info & return) to ref_num
			else
				my logger(true, "save_data()", "INFO", "Removed \"" & show_title of item i of show_info & "\"")
			end if
			
		end repeat
		my logger(true, "save_data()", "INFO", "Saved " & length of show_info & " shows to file")
	else
		my logger(true, "save_data()", "ERROR", "Save file protected from being wiped")
	end if
	
	
	close access ref_num
	--display notification disk_icon & " " & length of show_info & " shows saved" 
end save_data

--takes the the data in the filesystem, and writes to to a variable
on read_data()
	--set ref_num to missing value
	set hdhr_vcr_config_file to ((config_dir) & configfilename as string)
	my logger(true, "read_data()", "INFO", "Config loading from \"" & POSIX path of hdhr_vcr_config_file & "\"")
	set ref_num to open for access file hdhr_vcr_config_file
	try
		set hdhr_vcr_config_data to read ref_num
		--on error
		--display dialog "Error"  
		--	return 
		set temp_show_info to {}
		set hdhr_vcr_config_data_parsed to my stringtolist("read_data", hdhr_vcr_config_data, return)
		log "read_data"
		--set temp_show_info_template to {show_title:missing value, show_time:missing value, show_length:missing value, show_air_date:missing value, show_transcode:missing value, show_temp_dir:missing value, show_dir:missing value, show_channel:missing value, show_active:true, show_id:(do shell script "date | md5") as text, show_recording:false, show_last:(current date), show_next:missing value, show_end:missing value, notify_upnext_time:missing value, notify_recording_time:missing value}
		repeat with i from 1 to length of hdhr_vcr_config_data_parsed
			if item i of hdhr_vcr_config_data_parsed is "--NEXT SHOW--" then
				log "read_data_start"
				log i
				set end of temp_show_info to {show_title:(item (i + 1) of hdhr_vcr_config_data_parsed), show_time:(item (i + 2) of hdhr_vcr_config_data_parsed), show_length:(item (i + 3) of hdhr_vcr_config_data_parsed), show_air_date:my stringtolist("read_data_showairdate", (item (i + 4) of hdhr_vcr_config_data_parsed), ", "), show_transcode:(item (i + 5) of hdhr_vcr_config_data_parsed), show_temp_dir:(item (i + 6) of hdhr_vcr_config_data_parsed) as alias, show_dir:(item (i + 7) of hdhr_vcr_config_data_parsed) as alias, show_channel:(item (i + 8) of hdhr_vcr_config_data_parsed), show_active:((item (i + 9) of hdhr_vcr_config_data_parsed as boolean)), show_id:(item (i + 10) of hdhr_vcr_config_data_parsed), show_recording:((item (i + 11) of hdhr_vcr_config_data_parsed as boolean)), show_last:date (item (i + 12) of hdhr_vcr_config_data_parsed), show_next:date (item (i + 13) of hdhr_vcr_config_data_parsed), show_end:date (item (i + 14) of hdhr_vcr_config_data_parsed), notify_upnext_time:missing value, notify_recording_time:missing value, show_is_series:((item (i + 15) of hdhr_vcr_config_data_parsed as boolean)), hdhr_record:(item (i + 16) of hdhr_vcr_config_data_parsed)}
				--Fix We might be losing shows here
				
				set show_info to temp_show_info
				log show_info
				if show_is_series of last item of temp_show_info = true then
					set show_next of last item of temp_show_info to my nextday(show_id of last item of temp_show_info)
				end if
				my logger(true, "read_data()", "INFO", "Class of transcode: " & class of show_transcode of last item of show_info & " / " & show_transcode of last item of show_info)
			end if
		end repeat
		my logger(true, "read_data()", "INFO", "Config loaded")
		try
			log "temp_show_info: " & temp_show_info
		end try
		(*
		log "show_title of item 1 of show_info"
		log class of show_title of item 1 of show_info 
		log "show_time of item 1 of show_info"
		log class of show_time of item 1 of show_info
		log "show_length of item 1 of show_info"
		log class of show_length of item 1 of show_info
		log my listtostring(show_air_date of item 1 of show_info, ", ")
		log class of my listtostring(show_air_date of item 1 of show_info, ", ")
		log "show_transcode of item 1 of show_info"
		log class of show_transcode of item 1 of show_info
		log "show_temp_dir of item 1 of show_info"
		log class of show_temp_dir of item 1 of show_info
		log "show_temp_dir of item 1 of show_info"
		log class of show_temp_dir of item 1 of show_info
		log "show_dir of item 1 of show_info "
		log class of show_dir of item 1 of show_info
		log "show_channel of item 1 of show_info"
		log class of show_channel of item 1 of show_info
		log "show_active of item 1 of show_info"
		log class of show_active of item 1 of show_info
		log " show_id of item 1 of show_info"
		log class of show_id of item 1 of show_info
		log "show_recording of item 1 of show_info "
		log class of show_recording of item 1 of show_info
		log "show_last of item 1 of show_info"
		log class of show_last of item 1 of show_info
		log "show_next of item 1 of show_info"
		log class of show_next of item 1 of show_info
		log "show_end of item 1 of show_info"
		log class of show_end of item 1 of show_info
		log "show_is_series of item 1 of show_info"
		log class of show_is_series of item 1 of show_info
		log "hdhr_record of item 1 of show_info"
		log class of hdhr_record of item 1 of show_info
	*)
	end try
	close access ref_num
	my validate_show_info("read_data", "", false)
end read_data

##########    These are custom handlers.  They are more like libraries    ##########

on datetime2epoch(caller, the_date_object)
	log "datetime2epoch: " & caller & " " & the_date_object
	return my getTfromN(the_date_object - (my epoch()))
end datetime2epoch

on getTfromN(this_number)
	set this_number to this_number as string
	if this_number contains "E+" then
		set x to the offset of "." in this_number
		set y to the offset of "+" in this_number
		set z to the offset of "E" in this_number
		set the decimal_adjust to characters (y - (length of this_number)) thru Â
			-1 of this_number as string as number
		if x is not 0 then
			set the first_part to characters 1 thru (x - 1) of this_number as string
		else
			set the first_part to ""
		end if
		set the second_part to characters (x + 1) thru (z - 1) of this_number as string
		set the converted_number to the first_part
		repeat with i from 1 to the decimal_adjust
			try
				set the converted_number to Â
					the converted_number & character i of the second_part
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
	if locale = "en_US" then
		return date "Thursday, January 1, 1970 at 12:00:00 AM"
	else
		set epoch_time to current date
		
		set day of epoch_time to 1 --added to work around month rolling issue (31/30)
		
		set hours of epoch_time to 0
		set minutes of epoch_time to 0
		set seconds of epoch_time to 0
		
		set year of epoch_time to "1970"
		set month of epoch_time to "1"
		set day of epoch_time to "1"
		return epoch_time
	end if
end epoch

on epoch2datetime(epochseconds)
	try
		set unix_time to (characters 1 through 10 of epochseconds) as text
	on error
		set unix_time to epochseconds
	end try
	set epoch_time to my epoch()
	
	log "epoch_time: " & epoch_time
	
	--epoch_time is now current unix epoch time as a date object
	set epochOFFSET to (epoch_time + (unix_time as number) + (time to GMT))
	log "epochOFFSET: " & epochOFFSET & " " & epochseconds
	return epochOFFSET
end epoch2datetime

on epoch2show_time(epoch)
	set show_time_temp to my epoch2datetime(epoch)
	log "--"
	log show_time_temp
	log "--"
	set show_time_temp_hours to hours of show_time_temp
	log show_time_temp_hours
	set show_time_temp_minutes to minutes of show_time_temp
	if show_time_temp_minutes ­ 0 then
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

on isModifierKeyPressed(source_reason, checkKey)
	try
		log "isModifierKeyPressed: " & checkKey & " for " & source_reason
	end try
	set modiferKeysDOWN to {command_down:false, option_down:false, control_down:false, shift_down:false, caps_down:false, numlock_down:false, function_down:false}
	
	if checkKey is in {"", "option", "alt"} then
		--if checkKey = "" or checkKey = "option" or checkKey = "alt" then
		if (do shell script "/usr/bin/python -c 'import Cocoa; print Cocoa.NSEvent.modifierFlags() & Cocoa.NSAlternateKeyMask '") > 1 then
			set option_down of modiferKeysDOWN to true
		end if
	end if
	
	if checkKey is in {"", "command"} then
		if (do shell script "/usr/bin/python -c 'import Cocoa; print Cocoa.NSEvent.modifierFlags() & Cocoa.NSCommandKeyMask '") > 1 then
			set command_down of modiferKeysDOWN to true
		end if
	end if
	
	if checkKey is in {"", "shift"} then
		if (do shell script "/usr/bin/python -c 'import Cocoa; print Cocoa.NSEvent.modifierFlags() & Cocoa.NSShiftKeyMask '") > 1 then
			set shift_down of modiferKeysDOWN to true
		end if
	end if
	
	if checkKey is in {"", "control", "ctrl"} then
		if (do shell script "/usr/bin/python -c 'import Cocoa; print Cocoa.NSEvent.modifierFlags() & Cocoa.NSControlKeyMask '") > 1 then
			set control_down of modiferKeysDOWN to true
		end if
	end if
	
	if checkKey is in {"", "caps", "capslock"} then
		if (do shell script "/usr/bin/python -c 'import Cocoa; print Cocoa.NSEvent.modifierFlags() & Cocoa.NSAlphaShiftKeyMask '") > 1 then
			set caps_down of modiferKeysDOWN to true
		end if
	end if
	
	if checkKey is in {"", "numlock"} then
		if (do shell script "/usr/bin/python -c 'import Cocoa; print Cocoa.NSEvent.modifierFlags() & Cocoa.NSNumericPadKeyMask'") > 1 then
			set numlock_down of modiferKeysDOWN to true
		end if
	end if
	--Set if any key in the numeric keypad is pressed. The numeric keypad is generally on the right side of the keyboard. This is also set if any of the arrow keys are pressed
	
	if checkKey is in {"", "function", "func", "fn"} then
		if (do shell script "/usr/bin/python -c 'import Cocoa; print Cocoa.NSEvent.modifierFlags() & Cocoa.NSFunctionKeyMask'") > 1 then
			set function_down of modiferKeysDOWN to true
		end if
	end if
	--Set if any function key is pressed. The function keys include the F keys at the top of most keyboards (F1, F2, and so on) and the navigation keys in the center of most keyboards (Help, Forward Delete, Home, End, Page Up, Page Down, and the arrow keys)
	
	return modiferKeysDOWN
end isModifierKeyPressed

on time_set(adate_object, time_shift)
	log adate_object
	log time_shift
	set dateobject to adate_object
	--set to midnight
	set hours of dateobject to 0
	set minutes of dateobject to 0
	set seconds of dateobject to 0
	set dateobject to dateobject + (time_shift * hours)
	return dateobject
end time_set

on sec_to_time(secs)
	set the_minutes to my padnum((secs div minutes) as text)
	set the_seconds to my padnum(secs - (the_minutes * minutes) as text)
	--	set the_hours to my padnum(secs - (the_minutes * minutes) - ("test") as text)
	return (the_minutes & ":" & the_seconds as text)
end sec_to_time

on padnum(thenum)
	log (length of thenum as text)
	if (length of thenum) = 1 then
		set thenum to "0" & thenum
	else
		return thenum
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

on stringtolist(the_caller, theString, delim)
	log "stringtolist: " & the_caller & ":" & theString
	set oldelim to AppleScript's text item delimiters
	set AppleScript's text item delimiters to delim
	set dlist to (every text item of theString)
	set AppleScript's text item delimiters to oldelim
	return dlist
end stringtolist

on listtostring(caller, theList, delim)
	set oldelim to AppleScript's text item delimiters
	set AppleScript's text item delimiters to delim
	set alist to theList as string
	set AppleScript's text item delimiters to oldelim
	return alist
end listtostring

on short_date(the_caller, the_date_object, twentyfourtime, show_seconds)
	--	set twentyfourtime to true
	set timeAMPM to ""
	--takes date object, and coverts to a shorter time string
	if the_date_object ­ "?" then
		if the_date_object ­ "" then
			set year_string to (items -2 thru end of (year of the_date_object as string) as string)
			
			if ((month of the_date_object) * 1) < 10 then
				set month_string to ("0" & ((month of the_date_object) * 1)) as text
			else
				set month_string to ((month of the_date_object) * 1) as text
			end if
			
			if day of the_date_object < 10 then
				set day_string to ("0" & day of the_date_object) as text
			else
				set day_string to (day of the_date_object) as text
			end if
			
			if minutes of the_date_object < 10 then
				set minutes_string to "0" & minutes of the_date_object
			else
				set minutes_string to (minutes of the_date_object) as text
			end if
			
			
			if hours of the_date_object < 10 then
				set hours_string to "0" & hours of the_date_object
			else
				set hours_string to (hours of the_date_object) as text
			end if
			if twentyfourtime = false then
				if hours_string ³ 12 then
					set timeAMPM to " PM"
					if hours_string > 12 then
						set hours_string to (hours_string - 12)
						if hours_string = 0 then
							set hours_string to "12"
						end if
					end if
				else
					set hours_string to (hours_string)
					set timeAMPM to " AM"
				end if
			end if
			if seconds of the_date_object < 10 then
				set seconds_string to "0" & seconds of the_date_object
			else
				set seconds_string to (seconds of the_date_object) as text
			end if
			if locale = "en_US" then
				if show_seconds = true then
					return month_string & "." & day_string & "." & year_string & " " & hours_string & "." & minutes_string & "." & seconds_string & timeAMPM
				else
					return month_string & "." & day_string & "." & year_string & " " & hours_string & "." & minutes_string & timeAMPM
				end if
			else
				if show_seconds = true then
					return year_string & "/" & month_string & "/" & day_string & " " & hours_string & "." & minutes_string & "." & seconds_string & timeAMPM
				else
					return year_string & "/" & month_string & "/" & day_string & " " & hours_string & "." & minutes_string & timeAMPM
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
	my logger(true, "list_position()", "INFO", this_item & ", " & this_list & " from " & caller)
	log "list_position: " & caller
	log "list_position: " & this_item
	log "list_position: " & this_list
	log "list_position: " & is_strict
	--	display dialog "!list_post: " & this_item 
	--	display dialog "!list_post2: " & this_list
	--	display dialog "!list_post3: " & is_strict
	if this_item ­ false then
		repeat with i from 1 to length of this_list
			if is_strict = false then
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
	log "list_post3: 0"
	return 0
end list_position

on update_folder(update_path)
	set posix_update_path to POSIX path of update_path
	try
		do shell script "touch \"" & posix_update_path & "hdhr_test_write\""
		delay 0.1
		do shell script "rm \"" & posix_update_path & "hdhr_test_write\""
	on error err_string
		my logger(true, "update_folder()", "ERROR", "Unable to write to " & posix_update_path & ", " & err_string)
	end try
end update_folder

on logger(logtofile, caller, loglevel, message)
	## logtofile is a boolean that tell us if we want to write this to a file, in addition to logging it out in Script Editor Console.
	## caller is a string that tells us where this handler was called from
	## loglevel is a string that tell us how severe the log line is 
	## message is the actual message we want to log.
	--log caller
	--log loglevel & " " & caller & " " & message
	--caller can be "init" or "flush"
	--We dont want to write out everything we write, so lets maintain a buffer.  We can add a hook into the idle() handler to flush the queue.
	set logger_max_queued to 1
	--if caller = "init" then
	set queued_log_lines to {}
	--end if 
	set end of queued_log_lines to my short_date("logger", current date, true, true) & " " & loglevel & " " & caller & " " & message
	if length of queued_log_lines ³ logger_max_queued or caller = "flush" then
	end if
	if loglevel is in logger_levels then
		try
			
			set logfile to open for access file ((log_dir) & (logfilename) as text) with write permission
			set ref_num to get eof of logfile
			--set eof of ref_num to 0
			repeat with i from 1 to length of queued_log_lines
				write (item i of queued_log_lines & LF) to logfile starting at ref_num
			end repeat
		on error
			--my logger(true, "logger()", "ERROR", "Unable to write to log file. " & caller & ", " & message) 
			display notification "Unable to write to log file. " & caller & ", " & message
		end try
		close access logfile
	else
		--my logger(true, "logger()", "ERROR", "Unable to display " & loglevel)
	end if
end logger

on ms2time(caller, totalMS, time_duration, level_precision)
	my logger(true, "ms2time()", "DEBUG", caller & ", " & totalMS & ", " & time_duration & ", " & level_precision)
	log "totalMS: " & totalMS & " " & time_duration
	set totalMS to totalMS as number
	set temp_time_string to {}
	set numseconds to 0
	set numinutes to 0
	set numhours to 0
	set numdays to 0
	set numyears to 0
	if time_duration is "ms" then
		if totalMS > 0 and totalMS < 1000 then
			return ("<1s")
		else
			set numseconds to totalMS div 1000
		end if
	else
		set numseconds to totalMS
	end if
	if numseconds > 3153599 then
		set numyears to numseconds div (365 * days)
		set numseconds to numseconds - (numyears * (365 * days))
	end if
	if numseconds > 86400 then
		set numdays to numseconds div days
		set numseconds to numseconds - (numdays * days)
	end if
	if numseconds > 3600 then
		set numhours to numseconds div hours
		set numseconds to numseconds - (numhours * hours)
	end if
	if numseconds ³ 60 then
		set numinutes to (numseconds div minutes)
		set numseconds to numseconds - (numinutes * minutes)
	end if
	set temp_time to (numyears & numdays & numhours & numinutes & numseconds)
	--choose from list temp_time
	repeat with i from 1 to length of temp_time
		if item i of temp_time is not in {0, "0", ""} then
			try
				if i = 1 then
					set end of temp_time_string to (item i of temp_time & "Y") as text
				end if
				if i = 2 then
					set end of temp_time_string to (item i of temp_time & "D") as text
				end if
				if i = 3 then
					set end of temp_time_string to (item i of temp_time & "H") as text
				end if
				if i = 4 then
					set end of temp_time_string to (item i of temp_time & "M") as text
				end if
				if i = 5 then
					set end of temp_time_string to (item i of temp_time & "S") as text
				end if
			end try
		end if
	end repeat
	--choose from list temp_time_string
	if level_precision > length of temp_time_string then
		set level_precision to length of temp_time_string
	end if
	if level_precision ­ 0 then
		set temp_time_string to items 1 thru (item level_precision) of temp_time_string
	end if
	if length of temp_time_string ­ 0 then
		my logger(true, "ms2time()", "DEBUG1", "Result: " & temp_time_string)
		return my listtostring("ms2time", temp_time_string, " ")
	else
		my logger(true, "ms2time()", "DEBUG2", "Result: 0ms")
		return my listtostring("ms2time", "0ms", " ")
	end if
end ms2time
