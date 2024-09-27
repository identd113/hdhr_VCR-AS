global Local_env
global Show_info
global Locale
global Hostname
global Channel_list
global HDHR_DEVICE_LIST
global Idle_timer
global Idle_timer_default
global Idle_count_delay
global Idle_count
global Idle_timer_dateobj
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
global Configfilename_json
global Logfilename
global Time_slide
global Dialog_timeout
global Temp_dir
global Config_dir
global Log_dir
global Back_channel
global Config_version
global Debugger_apps
global Local_ip
global Fail_count
global Icon_record
global Shutdown_reason
global Lf
global Logger_levels
global Logger_levels_all
global Loglines_written
global Loglines_max
global Missing_tuner_retry_count
global Check_after_midnight_time
global First_open
global Show_status_list
global LibScript
global LibScript_version
global Log_errors

## Since we use JSON helper to do some of the work, we should declare it, so we dont end up having to use tell blocks everywhere.  If we declare 1 thing, we have to declare everything we are using.
use AppleScript version "2.4"
use scripting additions
use application "JSON Helper"

##########    This sets up the script.  If we fail here, the script will cease loading    ##########
on loadIcons(caller)
	try
		set Icon_record to {Warning_icon:character id {9888, 65039}, Play_icon:character id 9654, Record_icon:character id 128308, Recordsoon_icon:character id 11093, Tv_icon:character id 128250, Plus_icon:character id 10133, Single_icon:character id {49, 65039, 8419}, Series_icon:character id 128257, Series1_icon:character id 128258, Inactive_icon:character id 9940, Edit_icon:character id {9999, 65039}, Soon_icon:character id 128284, Disk_icon:character id 128190, Update_icon:character id 8682, Stop_icon:character id 9726, Up_icon:character id 128316, Up1_icon:character id 128314, Up2_icon:character id 9195, Check_icon:character id 9989, Uncheck_icon:character id 10060, Futureshow_icon:character id {9197, 65039}, Calendar_icon:character id 128197, Calendar2_icon:character id 128198, Hourglass_icon:character id 8987, Film_icon:character id 127910, Back_icon:character id 8592, Done_icon:character id 9989, Running_icon:character id {127939, 8205, 9794, 65039}, Add_icon:character id 127381}
	on error errmsg
		return false
	end try
	return true
end loadIcons

on setup_script(caller)
	set handlername to "setup_script"
	try
		set Local_env to (name of current application)
		set Lf to "
"
		set Version_local to "20240921"
		set Config_version to 1
		set temp_info to (system info)
		set Local_ip to IPv4 address of temp_info
		set Locale to user locale of temp_info
		set Hostname to host name of temp_info
		set Hdhr_setup_folder to "Volumes:"
		set Configfilename_json to ((name of me) & "-" & Hostname & ".json") as text
		set Logfilename to (name of me) & ".log" as text
		set Version_url to "https://raw.githubusercontent.com/identd113/hdhr_VCR-AS/master/version.json"
		set Version_remote to "0"
		set Idle_count_delay to 0
		set Config_dir to path to documents folder
		do shell script "mkdir -p ~/Library/Caches/" & (name of me) & "/"
		copy (current date) to Idle_timer_dateobj
		set Debugger_apps to {"Script Editor", "Script Debugger", "Smile"}
	on error errmsg
		return false
	end try
	return true
end setup_script

on setup_globals(caller)
	set handlername to "setup_globals"
	try
		set Fail_count to 5
		set HDHR_DEVICE_LIST to {}
		set Show_info to {}
		set Hdhr_config to {}
		set Notify_upnext to 35
		set Notify_recording to 15.5
		set Time_slide to 0
		set Dialog_timeout to 60
		set Idle_timer to 6
		set Idle_timer_default to 10
		set Idle_count to 0
		set Temp_dir to alias "Volumes:"
		set Online_detected to false
		set Hdhr_detected to false
		set Back_channel to missing value
		set Missing_tuner_retry_count to 0
		set Shutdown_reason to "No shutdown attempted"
		set Show_status_list to {}
	on error errmsg
		return false
	end try
	return true
end setup_globals

on setup_logging(caller)
	set handlername to "setup_logging"
	try
		set Log_dir to alias ((path to library folder from user domain) & "Logs" as text)
		set Logger_levels_all to {"INFO", "WARN", "ERROR", "NEAT", "FATAL", "DEBUG", "TRACE", "JSON"}
		if Local_env is in Debugger_apps then
			set Logger_levels to Logger_levels_all
		else
			set Logger_levels to {"INFO", "WARN", "ERROR", "NEAT", "FATAL"}
		end if
		set Log_errors to 0
		set Loglines_written to 0
		set Loglines_max to 2000 + ((length of Show_info) * 100)
	on error errmsg
		return false
	end try
	return true
end setup_logging

##########    These are reserved handlers, we do specific things in them    ##########

on run {}
	copy (round (random number from 1000 to 9999)) to caller
	set handlername to "run"
	try
		my loadlib(my cm(handlername, caller))
	end try
	-- This is the handler that loads first after the app is launched.
	set errloc to ""
	set startup_success to false
	set progress description to "Setting up script..."
	if my setup_script(my cm(handlername, caller)) is true then
		set progress description to "Setting up globals..."
		if my setup_globals(my cm(handlername, caller)) is true then
			set progress description to "Setting up logging..."
			if my setup_logging(my cm(handlername, caller)) is true then
				set progress description to "Setting up icons..."
				if my loadIcons(my cm(handlername, caller)) is true then
					set startup_success to true
					set progress description to "Loading " & name of me & " " & Version_local
				else
					set errloc to "LoadIcons"
				end if
			else
				set errloc to "Logging"
			end if
		else
			set errloc to "Globals"
		end if
	else
		set errloc to "Setup"
	end if
	if errloc is not "" then
		--log "THE_ERROR: " & errloc
	end if
	
	if Locale is not "en_US" then
		display dialog "Due to poor planning on my part, only en_US regions can use this script, sorry!"
		quit {}
		return
	end if
	if startup_success is true then
		my logger(true, handlername, caller, "INFO", "***** Starting " & name of me & " " & Version_local & " *****")
		## Lets check for a new version! This will trigger OSX to prompt for confirmation to talk to JSONHelper, the library we use for JSON related matters.
		my check_version(handlername & caller)
		if Online_detected is true then
			my HDHRDeviceDiscovery(my cm(handlername, caller), "")
		else
			my logger(true, handlername, caller, "ERROR", "online_detected is " & Online_detected)
		end if
		my logger(true, handlername, caller, "INFO", "AreWeOnline: " & my AreWeOnline(my cm(handlername, caller)))
		--Prompts for permission for removable media
		my showPathVerify(my cm(handlername, caller), "")
		my show_info_dump(my cm(handlername, caller), "", false)
		my existing_shows(my cm(handlername, caller))
		set First_open to true
		my logger(true, handlername, caller, "INFO", "Initial main() skipped, will run at the end of idle")
		if First_open is false then
			my main((handlername & caller), "run")
		end if
		if Local_env is in Debugger_apps then
			my main(my cm(handlername, caller), "run")
		end if
		my build_channel_list(my cm(handlername, caller), "")
		if Local_env is not in Debugger_apps then
			my rotate_logs(my cm(handlername, caller), (Log_dir & Logfilename as text))
		end if
	end if
	my logger(true, handlername, caller, "INFO", "End of run() handler")
end run

## This script will loop through this every 12 seconds, or whatever the return value is (Idle_timer), in second is at the bottom of this handler.
on idle
	set handlername to "idle"
	copy (round (random number from 1000 to 9999)) to caller
	copy (current date) to cd
	copy cd + (Idle_timer) to cd_object
	if Idle_timer is not Idle_timer_default then
		my logger(true, handlername, caller, "INFO", "START Idle_timer: " & Idle_timer)
	end if
	if "TRACE" is in Logger_levels then
		set progress description to "Start Idle Loop"
		set progress total steps to 2
		set progress completed steps to 1
		delay 0.1
	end if
	if cd is greater than Idle_timer_dateobj and Idle_timer is not Idle_timer_default then
		set Idle_timer to Idle_timer_default
		my logger(true, handlername, caller, "TRACE", "idle_timer set to " & Idle_timer_default)
		set Idle_timer_dateobj to cd
	end if
	try
		set Idle_count to Idle_count + Idle_timer
		try
			if length of HDHR_DEVICE_LIST is greater than 0 then
				repeat with i2 from 1 to length of HDHR_DEVICE_LIST
					if hdhr_guide_update of item i2 of HDHR_DEVICE_LIST is not missing value then
						if minutes of (cd) is in {2, 32} then
							if ((cd) - (hdhr_guide_update of item i2 of HDHR_DEVICE_LIST)) div 60 is greater than or equal to 5 then
								my logger(true, handlername, caller, "INFO", "Periodic update of tuner " & device_id of item i2 of HDHR_DEVICE_LIST & ", last update: " & hdhr_guide_update of item i2 of HDHR_DEVICE_LIST)
								try
									with timeout of 15 seconds
										my HDHRDeviceDiscovery("idle5(" & caller & ")", device_id of item i2 of HDHR_DEVICE_LIST)
									end timeout
									my save_data("idle5.1(" & caller & ")")
								on error errmsg
									my logger(true, handlername, caller, "ERROR", "Unable to update HDHRDeviceDiscovery, errmsg " & errmsg)
								end try
								my logger(true, handlername, caller, "INFO", "Tuners refresh complete")
							end if
						end if
					end if
				end repeat
			else
				try
					my logger(true, handlername, caller, "WARN", "No HDHR Device Detected")
					my HDHRDeviceDiscovery("idle51(" & caller & ")", "")
				end try
			end if
		on error errmsg
			my logger(true, handlername, caller, "ERROR", "An error occured: " & errmsg as text)
		end try
		try
			if length of Show_info is greater than 0 and length of HDHR_DEVICE_LIST is greater than 0 then
				repeat with i from 1 to length of Show_info
					repeat 1 times
						if show_active of item i of Show_info is true then
							if show_next of item i of Show_info is less than or equal to cd_object then
								if show_recording of item i of Show_info is false then
									
									if my HDHRDeviceSearch("idle71(" & caller & ")", hdhr_record of item i of Show_info) is 0 then
										--We could walk the user through reassigning a tuner.
										if Missing_tuner_retry_count is less than or equal to 3 then
											my logger(true, handlername, caller, "WARN", "The tuner, " & hdhr_record of item i of Show_info & ", does not exist, refreshing tuners")
											my HDHRDeviceDiscovery("idle82(" & caller & ")", hdhr_record of item i of Show_info)
											set Missing_tuner_retry_count to Missing_tuner_retry_count + 1
										else if Missing_tuner_retry_count is greater than 3 then
											my logger(true, handlername, caller, "WARN", "Missing tuner, errmsg: " & hdhr_record of item i of Show_info)
										end if
										exit repeat
									end if
									
									if show_end of item i of Show_info is less than or equal to (cd) then
										my logger(true, handlername, caller, "INFO", show_title of item i of Show_info & " ends at " & show_end of item i of Show_info)
										if show_is_series of item i of Show_info is true then
											set show_next of item i of Show_info to my nextday("idle10(" & caller & ")", show_id of item i of Show_info)
											my logger(true, handlername, caller, "WARN", show_title of item i of Show_info & " is a series, but passed")
											exit repeat
										else if show_is_sport of item i of Show_info is false then
											set show_active of item i of Show_info to false
											my logger(true, handlername, caller, "WARN", show_title of item i of Show_info & " is a single, and passed, so it was deactivated")
											exit repeat
										end if
									end if
									
									set show_runtime to (show_end of item i of Show_info) - (cd)
									set tuner_status_result to my tuner_status("idle15(" & caller & ")", hdhr_record of item i of Show_info)
									if tunermax of tuner_status_result is greater than tuneractive of tuner_status_result then
										my logger(true, handlername, caller, "DEBUG", show_title of item i of Show_info)
										my logger(true, handlername, caller, "DEBUG", show_next of item i of Show_info)
										my logger(true, handlername, caller, "DEBUG", show_time of item i of Show_info)
										my logger(true, handlername, caller, "DEBUG", show_end of item i of Show_info)
										if item 2 of my showid2PID("idle155(" & caller & ")", show_id of item i of Show_info, false, true) is {} then
											my record_now("idle32(" & caller & ")", (show_id of item i of Show_info), show_runtime, true)
											if (show_fail_count of item i of Show_info) is less than Fail_count then
												display notification "Ends " & my short_date("rec started", show_end of item i of Show_info, false, false) with title Recordsoon_icon of Icon_record & " Started Recording on (" & hdhr_record of item i of Show_info & ")" subtitle quote & show_title of item i of Show_info & quote & " on " & show_channel of item i of Show_info & " (" & my channel2name("idle16(" & caller & ")", show_channel of item i of Show_info as text, hdhr_record of item i of Show_info) & ")"
												set notify_recording_time of item i of Show_info to (cd) + (2 * minutes)
											end if
										else
											my logger(true, handlername, caller, "WARN", "Recording already in progeress, marking " & show_id of item i of Show_info & " as recording")
											set show_recording of item i of Show_info to true
										end if
									else
										display notification Hourglass_icon of Icon_record & " Delaying for " & Idle_timer & " seconds" with title "Tuner unavailable (" & hdhr_record of item i of Show_info & ")" subtitle show_title of item i of Show_info
									end if
								else --show_recording true 
									if (show_end of item i of Show_info) - (cd) is less than or equal to Idle_timer then
										my delay_idle_loop("idle(" & caller & ")", 1)
									end if
									if notify_recording_time of item i of Show_info is less than (cd) or notify_recording_time of item i of Show_info is missing value then
										display notification "Ends " & my short_date("rec progress", show_end of item i of Show_info, false, false) & " (" & (my ms2time("idle(19)", (show_end of item i of Show_info) - (cd), "s", 3)) & ") " with title Record_icon of Icon_record & " Recording in progress (" & hdhr_record of item i of Show_info & ")" subtitle quote & show_title of item i of Show_info & quote & " on " & show_channel of item i of Show_info & " (" & my channel2name("idle20(" & caller & ")", show_channel of item i of Show_info as text, hdhr_record of item i of Show_info) & ")"
										set notify_recording_time of item i of Show_info to (cd) + (Notify_recording * minutes)
										my logger(true, handlername, caller, "INFO", "Recording in progress for " & quote & (show_title of item i of Show_info & quote & " on " & show_channel of item i of Show_info & ", ends in " & my ms2time("idle_rip(19.1)", (show_end of item i of Show_info) - (cd), "s", 3)) & ", Next Update: " & my fixDate("idle21,8(" & caller & ")", time string of (notify_recording_time of item i of Show_info)))
										
										my tuner_inuse("idle22(" & caller & ")", hdhr_record of item i of Show_info)
										my update_folder("idle(22.2)", show_dir of item i of Show_info)
										--set notify_recording_time of item i of Show_info to (cd) + (Notify_recording * minutes)
									end if
									set check_showid_recording to item 2 of my showid2PID("idle(" & caller & ")", show_id of item i of Show_info, false, false)
									--fix might need to check to make sure there is a value here. 
									
									my logger(true, handlername, caller, "TRACE", "check_showid_recording: " & check_showid_recording)
									if length of check_showid_recording is 0 then
										my delay_idle_loop("idle(" & caller & ")", 1)
										my logger(true, handlername, caller, "WARN", show_title of item i of Show_info & " (" & show_id of item i of Show_info & ") is marked as recording, but we do not have a valid PID, setting show_recording to false")
										set show_recording of item i of Show_info to false
									end if
								end if
							else --show time has not passed.
								if (notify_upnext_time of item i of Show_info is less than (cd) or notify_upnext_time of item i of Show_info is missing value) and (show_next of item i of Show_info) - (cd) is less than or equal to 1 * hours and show_recording of item i of Show_info is false then
									display notification "Starts: " & my short_date("idle11(" & caller & ")", show_next of item i of Show_info, false, false) & " (" & my ms2time("idle12(" & caller & ")", ((show_next of item i of Show_info) - (cd)), "s", 3) & ")" with title Film_icon of Icon_record & " Next Up on (" & hdhr_record of item i of Show_info & ")" subtitle quote & show_title of item i of Show_info & quote & " on " & show_channel of item i of Show_info & " (" & my channel2name("idle13(" & caller & ")", show_channel of item i of Show_info, hdhr_record of item i of Show_info) & ")"
									my logger(true, handlername, caller, "INFO", "Next Up: " & quote & show_title of item i of Show_info & quote & " on " & hdhr_record of item i of Show_info)
									set notify_upnext_time of item i of Show_info to (cd) + (Notify_upnext * minutes)
								end if
							end if
						end if
						
						if show_recording of item i of Show_info is true then
							my logger(true, handlername, caller, "TRACE", "Show end for " & show_title of item i of Show_info & " is " & show_end of item i of Show_info)
							my logger(true, handlername, caller, "TRACE", cd)
							if (show_end of item i of Show_info) is less than or equal to cd then
								set show_recording of item i of Show_info to false
								set show_last of item i of Show_info to show_end of item i of Show_info
								set temp_guide_data to my channel_guide("idle(23 recording_ended)", hdhr_record of item i of Show_info, show_channel of item i of Show_info, show_time of item i of Show_info)
								-- FIX The show may not be done recording, so this may not be sticky.  If we could verify that the PID is gone, then we can attempt to update the file.
								set temp_OriginalAirdate to {}
								try
									set temp_OriginalAirdate to my getTfromN(OriginalAirdate of temp_guide_data)
								on error errmsg
									my logger(true, handlername, caller, "WARN", "OriginalAirdate does not exist for " & quote & show_title of item i of Show_info & quote)
								end try
								try
									if (temp_OriginalAirdate) is not {} then
										--if (OriginalAirdate of temp_guide_data) is not {} then
										set temp_dateobject to my epoch2datetime("idle(epoch)", temp_OriginalAirdate)
										my logger(true, handlername, caller, "INFO", "Epoch time converted to dateobject")
										try
											if show_recording_path of item i of Show_info is not in {missing value, {}, ""} then
												my date2touch("idle(set_date_modified)", temp_dateobject, show_recording_path of item i of Show_info)
												my logger(true, handlername, caller, "INFO", "Successfully modified the date of " & quote & show_title of item i of Show_info & quote)
											end if
										on error errmsg
											my logger(true, handlername, caller, "WARN", "Unable to modify date of " & quote & show_title of item i of Show_info & quote & ", errmsg: " & errmsg)
										end try
										my logger(true, handlername, caller, "INFO", "OriginalAirdate of " & quote & show_title of item i of Show_info & quote & " " & temp_OriginalAirdate)
									end if
								on error errmsg
									my logger(true, handlername, caller, "WARN", "Epoch time NOT converted, errmsg: " & errmsg)
									set temp_OriginalAirdate to "Failed"
								end try
								if show_is_series of item i of Show_info is true then
									set show_next of item i of Show_info to my nextday("idle24(" & caller & ")", show_id of item i of Show_info)
									set show_recorded_today of item i of Show_info to true
									set show_fail_count of item i of Show_info to 0
									my logger(true, handlername, caller, "INFO", "Recording Complete for " & quote & (show_title of item i of Show_info & quote & " on " & show_channel of item i of Show_info))
									my logger(true, handlername, caller, "INFO", "Recording Complete for " & quote & (show_title of item i of Show_info & quote & " on " & show_channel of item i of Show_info))
									display notification "Next Showing: " & my short_date("idle26(" & caller & ")", show_next of item i of Show_info, false, false) with title Stop_icon of Icon_record & " Recording Complete" subtitle (quote & show_title of item i of Show_info & quote & " on " & show_channel of item i of Show_info & " (" & my channel2name("idle(27)", show_channel of item i of Show_info as text, hdhr_record of item i of Show_info) & ")")
								else
									if show_is_sport of item i of Show_info is false then
										set show_active of item i of Show_info to false
										set show_fail_count of item i of Show_info to 0
										my logger(true, handlername, caller, "INFO", "Recording Complete for " & quote & (show_title of item i of Show_info & quote & " on " & show_channel of item i of Show_info & " and marked inactive"))
										display notification "Show marked inactive" with title Stop_icon of Icon_record & " Recording Complete" subtitle (quote & show_title of item i of Show_info & quote & " on " & show_channel of item i of Show_info & " (" & my channel2name("idle27(" & caller & ")", show_channel of item i of Show_info as text, hdhr_record of item i of Show_info) & ")")
									else
										my logger(true, handlername, caller, "INFO", show_title of item i of Show_info & " is a sport, and we are in bonus time")
										-- FIX We do not want to automatically mark sport shows as inactive, brecause we might be in the bonus 30 minutes.
									end if
								end if
								try
									if show_time_orig of item i of Show_info is not in {missing value, "missing value"} and (show_time of item i of Show_info as number) is not (show_time_orig of item i of Show_info as number) and show_active of item i of Show_info is true then
										my logger(true, handlername, caller, "INFO", "Show: " & show_title of item i of Show_info & " reverted to " & show_time_orig of item i of Show_info & ", was " & show_time of item i of Show_info)
										set show_time of item i of Show_info to show_time_orig of item i of Show_info
									end if
								on error errmsg
									my logger(true, handlername, caller, "WARN", "Show " & show_title of item i of Show_info & " unable to revert to show_time_orig, err: " & errmsg)
								end try
							end if
						else if show_is_series of item i of Show_info is false and show_end of item i of Show_info is less than or equal to (cd) and show_active of item i of Show_info is true then
							set show_active of item i of Show_info to false
							my logger(true, handlername, caller, "INFO", "Show: " & show_title of item i of Show_info & " was deactivated, as it is a single, and recording time has passed")
							display notification "Show: " & show_title of item i of Show_info & " removed" with title Stop_icon of Icon_record
						end if
					end repeat
				end repeat
			else
				my logger(true, handlername, caller, "WARN", "There are no shows setup for recording.  If you are seeing this message, and wondering if the script is actually working, it is")
				set Idle_timer to 30
			end if
		on error errmsg
			my logger(true, handlername, caller, "ERROR", errmsg)
		end try
	on error errmsg
		my logger(true, handlername, caller, "ERROR", errmsg)
	end try
	--FIX added check for is recording.
	if my check_after_midnight("idle(" & caller & ")") is true then
		--if my check_after_midnight("idle(" & caller & ")") is true then
		repeat with i from 1 to length of Show_info
			set show_recorded_today of item i of Show_info to false
		end repeat
	end if
	if First_open is true and Idle_count_delay = 0 then
		my logger(true, handlername, caller, "INFO", "Now running intial main() at end of idle loop")
		my main("idle(" & caller & ")", "run")
	end if
	if "TRACE" is in Logger_levels then
		set progress description to "END Idle Loop"
		set progress completed steps to 2
		delay 0.5
	end if
	my delay_idle_loop("idle(" & caller & ")", -1)
	if Idle_timer is not Idle_timer_default then
		my logger(true, handlername, caller, "INFO", "END Idle_timer: " & Idle_timer)
	end if
	return Idle_timer
end idle

on reopen {}
	set handlername to "reopen"
	my logger(true, handlername, "()", "INFO", "User clicked in Dock")
	my main(handlername, handlername)
end reopen

on quit {}
	try
		set handlername to "quit"
		set caller to "()"
		my logger(true, handlername, caller, "INFO", "quit() called.  We have written " & Loglines_written & " lines, errored on " & Log_errors)
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
			set systemShutdown to my isSystemShutdown(my cm(handlername, caller))
			my logger(true, handlername, caller, "INFO", "systemShutdown: " & systemShutdown)
			my logger(true, handlername, caller, "INFO", "The following shows are marked as currently recording: " & my stringlistflip("quit()", hdhr_quit_record_titles, ",", "string"))
			if systemShutdown is false then
				try
					activate me
				end try
				set quit_response to button returned of (display dialog "Do you want to cancel these recordings already in progress?" & return & return & my stringlistflip(my cm(handlername, caller), hdhr_quit_record_titles, return, "string") buttons {"Go Back", "Yes", "No"} default button 3 with title my check_version_dialog(my cm(handlername, caller)) giving up after Dialog_timeout with icon caution)
				my logger(true, handlername, caller, "INFO", "quit() user choice for killing shows: " & quit_response)
			else
				my logger(true, handlername, caller, "INFO", "" & Shutdown_reason & " detected, killing all recordings, and saving config file")
				set quit_response to "Yes"
			end if
		else
			my save_data("quit(noshows)")
			end_jsonhelper() of LibScript
			continue quit
		end if
		if quit_response is "Yes" then
			repeat with i2 from 1 to length of Show_info
				if show_recording of item i2 of Show_info is true then
					set show_recording of item i2 of Show_info to false
					my showid2PID(my cm(handlername, caller), show_id of item i2 of Show_info, true, true)
				end if
			end repeat
			my save_data("quit(yes)")
			end_jsonhelper() of LibScript
			continue quit
		end if
		if quit_response is "No" then
			my save_data("quit(no)")
			end_jsonhelper() of LibScript
			continue quit
		end if
		if quit_response is "Go Back" then
			my main("quit", "quit(home)")
			return
		end if
	on error errmsg
		display dialog "Error occured while saving, " & errmsg
	end try
end quit
##########    END of reserved handlers    ##########

##########    These are custom handlers.  These are the heart of the script.    ##########
on hdhrGRID(caller, hdhr_device, hdhr_channel)
	set handlername to "hdhrGRID"
	my logger(true, handlername, caller, "INFO", "Started hdhrGRID on " & hdhr_device & ", channel " & hdhr_channel)
	set hdhrGRID_sort to {Back_icon of Icon_record & " Back"}
	set Show_status_list to {Back_icon of Icon_record & " Back"}
	set hdhrGRID_temp to my channel_guide(my cm(handlername, caller), hdhr_device, hdhr_channel, "")
	my logger(true, handlername, caller, "INFO", "hdhrGRID_temp: " & class of (hdhrGRID_temp))
	if hdhrGRID_temp is false then
		display notification with title "Channel " & hdhr_channel & " has no guide data" subtitle hdhr_device
		return false
	end if
	try
		my logger(true, handlername, caller, "INFO", "Shows returned: " & length of Guide of hdhrGRID_temp & ", channel: " & hdhr_channel & ", hdhr_device: " & hdhr_device)
	on error
		my logger(true, handlername, caller, "ERROR", "Unable to get a length of hdhrGRID_temp")
	end try
	repeat with i from 1 to length of Guide of hdhrGRID_temp
		try
			set temp_title to (title of item i of Guide of hdhrGRID_temp & " " & quote & EpisodeTitle of item i of Guide of hdhrGRID_temp) & quote
		on error
			set temp_title to (title of item i of Guide of hdhrGRID_temp)
		end try
		--Grab the start and end date, so we can pass use this to determine if the show is recording.
		set temp_start to my epoch2datetime(my cm(handlername, caller), my getTfromN(StartTime of item i of Guide of hdhrGRID_temp))
		set temp_end to my epoch2datetime(my cm(handlername, caller), my getTfromN(EndTime of item i of Guide of hdhrGRID_temp))
		set show_status to my show_record(my cm(handlername, caller), hdhr_device, hdhr_channel, temp_start, temp_end)
		set end of Show_status_list to show_status
		set end of hdhrGRID_sort to (status_icon of show_status) & " " & my padnum(my cm(handlername, caller), word 2 of my short_date(my cm(handlername, caller), temp_start, false, false), true) & "-" & my padnum(my cm(handlername, caller), word 2 of my short_date(my cm(handlername, caller), temp_end, false, false), true) & " " & temp_title
	end repeat
	set hdhrGRID_selected to choose from list hdhrGRID_sort with prompt ("Channel " & hdhr_channel & " (" & GuideName of hdhrGRID_temp & ")" & return & "Current Time: " & word 2 of my short_date(my cm(handlername, caller), (current date), false, false)) cancel button name "Manual Add" OK button name "Next.." with title my check_version_dialog(caller) default items item 1 of hdhrGRID_sort with multiple selections allowed
	if hdhrGRID_selected is not {Back_icon of Icon_record & " Back"} then
		set selected_show to my list_position(my cm(handlername, caller), hdhrGRID_selected, hdhrGRID_sort, true)
	else
		set selected_show to 0
		my logger(true, handlername, caller, "INFO", "User pressed back")
	end if
	my logger(true, handlername, caller, "INFO", "selected_show: " & selected_show)
	if selected_show is greater than or equal to 1 and the_show_id of item selected_show of Show_status_list is not missing value then
		my logger(true, handlername, caller, "INFO", "Editing, instead of adding show")
		set Back_channel to hdhr_channel
		my validate_show_info(my cm(handlername, caller), (the_show_id of item selected_show of Show_status_list), true)
		return false
	end if
	try
		if Back_icon of Icon_record & " Back" is in hdhrGRID_selected then
			my logger(true, handlername, caller, "INFO", "Back to channel list " & hdhr_channel)
			set Back_channel to hdhr_channel
			return true
		end if
	on error errmsg
		my logger(true, handlername, caller, "WARN", "Back failed, errmsg: " & errmsg)
	end try
	if my epoch2datetime(my cm(handlername, caller), EndTime of item ((my list_position(my cm(handlername, caller), hdhrGRID_selected, hdhrGRID_sort, false)) - 1) of Guide of hdhrGRID_temp) is less than (current date) then
		my logger(true, handlername, caller, "WARN", "The show time has already passed, returning...")
		display notification "The show has already passed, refreshing tuner...."
		my HDHRDeviceDiscovery(my cm(handlername, caller), hdhr_device)
		set Back_channel to hdhr_channel
		return true
	end if
	if hdhrGRID_selected is not false then
		set list_position_response to {}
		my logger(true, handlername, caller, "INFO", "Returning guide data for " & hdhr_channel & " on device " & hdhr_device)
		repeat with i from 1 to length of hdhrGRID_selected
			set end of list_position_response to item ((my list_position(my cm(handlername, caller), item i of hdhrGRID_selected, hdhrGRID_sort, false)) - 1) of Guide of hdhrGRID_temp
		end repeat
		return list_position_response
	else
		my logger(true, handlername, caller, "INFO", "User exited")
		return {""}
	end if
	return false
end hdhrGRID
--return {} --means we want to manually add a show, return true means we want to go back, return false means we cancelled out, return anything else, and this is the guide data for the channel they are requesting.

on tuner_overview(caller)
	set handlername to "tuner_overview"
	my logger(true, handlername, caller, "INFO", "START Called")
	my tuner_mismatch("tuner_overview(" & caller & ")", "")
	set main_tuners_list to {}
	repeat with i from 1 to length of HDHR_DEVICE_LIST
		set tuner_status2_result to my tuner_status("tuner_overview(" & caller & ")", device_id of item i of HDHR_DEVICE_LIST)
		if hdhr_model of item i of HDHR_DEVICE_LIST is not missing value then
			set end of main_tuners_list to (hdhr_model of item i of HDHR_DEVICE_LIST & " " & (device_id of item i of HDHR_DEVICE_LIST) & " " & tuneractive of tuner_status2_result & " of " & tunermax of tuner_status2_result & " in use") as text
		else
			set end of main_tuners_list to (device_id of item i of HDHR_DEVICE_LIST & " " & tuneractive of tuner_status2_result & " of " & tunermax of tuner_status2_result & " in use") as text
		end if
	end repeat
	return main_tuners_list
end tuner_overview

on tuner_end(caller, hdhr_model)
	set handlername to "tuner_end"
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
		my logger(true, handlername, caller, "INFO", "Next Tuner Available in " & my ms2time("tuner_end(" & caller & ")", lowest_number, "s", 3))
		return lowest_number
	end if
	return 0
end tuner_end

on tuner_inuse(caller, device_id)
	set handlername to "tuner_inuse"
	set tuner_offset to my HDHRDeviceSearch("tuner_inuse(" & caller & ")", device_id)
	try
		with timeout of 8 seconds
			set hdhr_discover_temp to my hdhr_api("tuner_inuse(" & caller & ")", statusURL of item tuner_offset of HDHR_DEVICE_LIST)
		end timeout
		
		repeat with i from 1 to length of hdhr_discover_temp
			repeat 1 times
				set local_ip_list to {}
				set hdhr_discover_length to length of (item i of hdhr_discover_temp)
				if hdhr_discover_length is 1 then
					exit repeat
				end if
				try
					try
						set TargetIP_check to ""
						set TargetIP_check to TargetIP of item i of hdhr_discover_temp
					on error errmsg
						my logger(true, handlername, caller, "WARN", "TargetIP is not defined")
					end try
					if TargetIP_check is not "" then
						if TargetIP of item i of hdhr_discover_temp is not equal to {} then
							if (TargetIP_check as text) is not (Local_ip as text) then
								set end of local_ip_list to TargetIP_check
							else
								set end of local_ip_list to "Self: (" & TargetIP_check & ")"
							end if
							try
								set temp_line to "VctNumber: " & (VctNumber of item i of hdhr_discover_temp) & ", VctName: " & (VctName of item i of hdhr_discover_temp) & ", Frequency: " & (((Frequency of item i of hdhr_discover_temp as number) / 1000000) & " Mhz") & ", SignalStrengthPercent: " & SignalStrengthPercent of item i of hdhr_discover_temp & ", SignalQualityPercent: " & SignalQualityPercent of item i of hdhr_discover_temp & ", SymbolQualityPercent: " & SymbolQualityPercent of item i of hdhr_discover_temp & ", TargetIP: " & local_ip_list
								my logger(true, handlername, caller, "INFO", temp_line)
							on error errmsg
								my logger(true, handlername, caller, "WARN", errmsg)
							end try
						end if
					else
						my logger(true, handlername, caller, "WARN", "TargetIP is empty")
					end if
				on error errmsg number errnum
					my logger(true, handlername, caller, "WARN", "errmsg: " & errnum & ", " & errmsg)
				end try
			end repeat
		end repeat
	on error errmsg
		my logger(true, handlername, caller, "WARN", "Timeout, errmsg: " & errmsg)
		return ""
	end try
	return local_ip_list
end tuner_inuse

on tuner_status(caller, device_id)
	set handlername to "tuner_staus"
	set tuneractive to 0
	set tuner_offset to my HDHRDeviceSearch("tuner_status(" & caller & ")", device_id)
	if tuner_offset is 0 then
		my logger(true, handlername, caller, "ERROR", "Tuner " & device_id & " is invalid")
		return {tunermax:0, tuneractive:0}
	end if
	try
		with timeout of 8 seconds
			set hdhr_discover_temp to my hdhr_api("tuner_status(" & caller & ")", statusURL of item tuner_offset of HDHR_DEVICE_LIST)
		end timeout
	on error errmsg
		my logger(true, handlername, caller, "WARN", "Timeout, errmsg: " & errmsg)
		set hdhr_discover_temp to ""
		return false
	end try
	if hdhr_discover_temp is not "" then
		set tunermax to length of hdhr_discover_temp
		set temp to ""
		repeat with i from 1 to tunermax
			try
				set temp to SymbolQualityPercent of item i of hdhr_discover_temp
				set tuneractive to tuneractive + 1
			end try
		end repeat
		my logger(true, handlername, caller, "DEBUG", device_id & " tunermax:" & tunermax & ", tuneractive:" & tuneractive & ", SymbolQualityPercent: " & temp)
		return {tunermax:tunermax, tuneractive:tuneractive}
	else
		my logger(true, handlername, caller, "WARN", "Did not get a result from " & statusURL of item tuner_offset of HDHR_DEVICE_LIST)
		return {tunermax:0, tuneractive:0}
	end if
end tuner_status

on tuner_mismatch(caller, device_id)
	set handlername to "tuner_mismatch"
	if device_id is "" and length of HDHR_DEVICE_LIST is greater than 0 then
		repeat with i2 from 1 to length of HDHR_DEVICE_LIST
			my tuner_mismatch("tuner_mismatch(" & caller & ")", device_id of item i2 of HDHR_DEVICE_LIST)
		end repeat
		return
	else
		my logger(true, handlername, caller, "INFO", "Called: " & device_id)
		set tuner_offset to my HDHRDeviceSearch("tuner_mismatch(" & caller & ")", device_id)
		set tuner_status2_result to my tuner_status("tuner_mismatch(" & caller & ")", device_id)
		set temp_shows_recording to 0
		repeat with i from 1 to length of Show_info
			if hdhr_record of item i of Show_info is device_id and show_recording of item i of Show_info is true then
				set temp_shows_recording to temp_shows_recording + 1
			end if
		end repeat
		if temp_shows_recording is greater than tuneractive of tuner_status2_result then
			my logger(true, handlername, caller, "WARN", "We are marked as having more shows recording then tuners in use")
		else if temp_shows_recording is less than tuneractive of tuner_status2_result then
			set tuner_inuse_return to my tuner_inuse("tuner_mismatch(" & caller & ")", device_id)
			try
				my logger(true, handlername, caller, "WARN", "There are more tuners in use then we are using, list of other IPs: " & my stringlistflip("tuner_mismatch(" & caller & ")", tuner_inuse_return, ", ", "string"))
			on error errmsg
				my logger(true, handlername, caller, "ERROR", "err, " & errmsg)
			end try
			
		else if temp_shows_recording is tuneractive of tuner_status2_result then
			my logger(true, handlername, caller, "TRACE", "We match")
		else
			my logger(true, handlername, caller, "WARN", "TRACK USE CASE")
		end if
		my logger(true, handlername, caller, "INFO", "Expected: " & temp_shows_recording & ", Actual: " & tuneractive of tuner_status2_result)
	end if
end tuner_mismatch

on is_channel_record(caller, hdhr_tuner, channelcheck)
	set handlername to "channel_recored"
	repeat with i from 1 to length of Show_info
		if hdhr_tuner is hdhr_record of item i of Show_info and show_active of item i of Show_info is true then
			if channelcheck is show_channel of item i of Show_info then
				if show_recording of item i of Show_info is true then
					my logger(true, handlername, caller, "TRACE", channelcheck & " marked as recording in channel list")
					return true
				end if
			end if
		end if
	end repeat
end is_channel_record

on show_record(caller, hdhr_tuner, channelcheck, start_time, end_time)
	set handlername to "show_record"
	--We need to only return the 1 result
	my logger(true, handlername, caller, "DEBUG", (hdhr_tuner & " | " & channelcheck))
	copy (current date) to cd
	repeat with i from 1 to length of Show_info
		set show_record_id to show_id of item i of Show_info
		--		if hdhr_tuner is hdhr_record of item i of Show_info and show_active of item i of Show_info is true and channelcheck is show_channel of item i of Show_info then
		if hdhr_tuner is hdhr_record of item i of Show_info and channelcheck is show_channel of item i of Show_info then
			my logger(true, handlername, caller, "TRACE", "show_start: " & class of (show_next of item i of Show_info) & ", start_time: " & class of (start_time))
			
			if show_recording of item i of Show_info is true then
				if cd is greater than or equal to start_time and cd is less than or equal to end_time then
					my logger(true, handlername & i, caller, "INFO", "Marked as recording: " & show_title of item i of Show_info)
					my logger(true, handlername & i, caller, "DEBUG", "REC show_record_id: " & show_record_id & ", offset:" & i)
					return {show_stat:"record", the_show_id:show_record_id, status_icon:Record_icon of Icon_record}
				end if
			else
				try
					set show_next_low to ((show_next of item i of Show_info) - 2 * minutes)
					set show_next_high to ((show_next of item i of Show_info) + 2 * minutes)
					if start_time is greater than or equal to show_next_low then
						if start_time is less than or equal to show_next_high then
							my logger(true, handlername & i, caller, "INFO", "Marked as upnext:    " & show_title of item i of Show_info & ", channel " & channelcheck)
							my logger(true, handlername & i, caller, "DEBUG", "UPNEXT show_record_id: " & show_record_id & ", offset " & i)
							if show_active of item i of Show_info is true then
								return {show_stat:"upnext", the_show_id:show_record_id, status_icon:Up_icon of Icon_record}
							else
								return {show_stat:"deact", the_show_id:show_record_id, status_icon:Uncheck_icon of Icon_record}
							end if
						end if
					end if
				on error errmsg
					my logger(true, handlername, caller, "ERROR", "Oops, " & errmsg)
				end try
			end if
		end if
	end repeat
	return {show_stat:missing value, the_show_id:missing value, status_icon:"     "}
end show_record

on show_info_dump(caller, show_id_lookup, userdisplay)
	set handlername to "show_info_dump"
	--  (*show_title:Happy_Holidays_America, show_time:16, show_length:60, show_air_date:Sunday, show_transcode:missing value, show_temp_dir:alias Backups:, show_dir:alias Backups:, show_channel:5.1, show_active:true, show_id:221fbe1126389e6af35f405aa681cf19, #show_recording:false, show_last:date Sunday, December 13, 2020 at 4:04:54 PM, show_next:date Sunday, December 13, 2020 at 4:00:00 PM, show_end:date Sunday, December 13, 2020 at 5:00:00 PM, notify_upnext_time:missing value, #notify_recording_time:missing value, hdhr_record:XX105404BE,show_is_series:false*
	if show_id_lookup is "" then
		repeat with i2 from 1 to length of Show_info
			my show_info_dump("show_info_dump(2-" & i2 & ")", show_id of item i2 of Show_info, userdisplay)
		end repeat
		return
	end if
	set i to my HDHRShowSearch(show_id_lookup)
	--if show_id_lookup
	if Local_env is not in Debugger_apps then
		my logger(true, handlername, caller, "TRACE", "show " & i & ", show_title: " & show_title of item i of Show_info & ", show_time: " & show_time of item i of Show_info & ", show_length: " & show_length of item i of Show_info & ", show_air_date: " & show_air_date of item i of Show_info & ", show_transcode: " & show_transcode of item i of Show_info & ", show_temp_dir: " & show_temp_dir of item i of Show_info & ", show_dir: " & show_dir of item i of Show_info & ", show_channel: " & show_channel of item i of Show_info & ", show_active: " & show_active of item i of Show_info & ", show_id: " & show_id of item i of Show_info & ", show_recording: " & show_recording of item i of Show_info & ", show_last: " & show_last of item i of Show_info & ", show_next: " & show_next of item i of Show_info & ", show_end: " & notify_upnext_time of item i of Show_info & ", notify_recording_time: " & notify_recording_time of item i of Show_info & ", hdhr_record: " & hdhr_record of item i of Show_info & ", show_is_series: " & show_is_series of item i of Show_info)
	end if
end show_info_dump

on check_version(caller)
	set handlername to "check_version"
	try
		with timeout of 10 seconds
			set version_response to (fetch JSON from Version_url with cleaning feed)
			set Version_remote to hdhr_version of item 1 of versions of version_response
			set Online_detected to true
			my logger(true, handlername, caller, "INFO", "Current Version: " & Version_local & ", Remote Version: " & Version_remote & ", Lib Version: " & LibScript_version)
			if Version_remote is greater than Version_local then
				my logger(true, handlername, caller, "INFO", "Changelog: " & changelog of item 1 of versions of version_response)
			end if
		end timeout
	on error errmsg
		my logger(true, handlername, caller, "ERROR", "Unable to check for new versions: " & errmsg)
		set version_response to {versions:{{changelog:"Unable to check for new versions", hdhr_version:"20210101"}}}
		set Version_remote to hdhr_version of item 1 of versions of version_response
		tell application "JSON Helper" to quit
		delay 3
		my check_version("check_version(" & caller & ")")
	end try
end check_version

on check_version_dialog(caller)
	set handlername to "check_version_display"
	--This handler compares the current version, and the current remote version, and sets a string to show the status
	if Version_remote is greater than Version_local then
		set temp to Version_local & " " & Update_icon of Icon_record & " " & Version_remote
	end if
	if Version_remote is less than Version_local then
		set temp to "Beta " & Version_local
	end if
	if Version_remote is Version_local then
		set temp to Version_local
	end if
	return temp
end check_version_dialog

on build_channel_list(caller, hdhr_device)
	set handlername to "build_channel_list"
	set channel_list_temp to {}
	try
		if hdhr_device is "" then
			repeat with i from 1 to length of HDHR_DEVICE_LIST
				my logger(true, handlername, caller, "INFO", device_id of item i of HDHR_DEVICE_LIST)
				my build_channel_list("build_channel_list-" & i & "(" & caller & ")", device_id of item i of HDHR_DEVICE_LIST)
			end repeat
		else
			set tuner_offset to my HDHRDeviceSearch("build_channel_list(" & caller & ")", hdhr_device)
			set temp to hdhr_lineup of item tuner_offset of HDHR_DEVICE_LIST
			repeat with i from 1 to length of temp
				--(*GuideNumber:49.2, URL:http://10.0.1.101:5004/auto/v49.2, GuideName:KMQV-LD, VideoCodec:MPEG2, AudioCodec:AC3*)
				
				try
					if HD of item i of temp is 1 then
						set end of channel_list_temp to GuideNumber of item i of temp & " " & GuideName of item i of temp & " [HD]"
					end if
				on error
					set end of channel_list_temp to GuideNumber of item i of temp & " " & GuideName of item i of temp
				end try
				
				try
					if my is_channel_record("build_channel_list(" & caller & ")", hdhr_device, GuideNumber of item i of temp) is true then
						my logger(true, handlername, caller, "INFO", GuideNumber of item i of temp & " marked on channel list as recording")
						set last item of channel_list_temp to last item of channel_list_temp & " " & Record_icon of Icon_record
					end if
				end try
				
				try
					if VideoCodec of item i of temp is not "MPEG2" then
						my logger(true, handlername & "_build_channel_list_VIDEO_CODEC", caller, "NEAT", (last item of channel_list_temp as text) & " is using " & VideoCodec of item i of temp)
					end if
				end try
				
				try
					if AudioCodec of item i of temp is not "AC3" then
						my logger(true, handlername & "_build_channel_list_AUDIO_CODEC", caller, "NEAT", (last item of channel_list_temp as text) & " is using " & AudioCodec of item i of temp)
					end if
				end try
				
			end repeat
			set channel_mapping of item tuner_offset of HDHR_DEVICE_LIST to channel_list_temp
			my logger(true, handlername, caller, "INFO", "Updated channel list for " & hdhr_device & ", " & length of channel_list_temp & " found")
		end if
	on error errmsg
		my logger(true, handlername, caller, "ERROR", "Unable to build channel list " & errmsg)
	end try
end build_channel_list

on channel2name(caller, the_channel, hdhr_device)
	set handlername to "channel2name"
	my logger(true, handlername, caller, "DEBUG", the_channel & " on " & hdhr_device)
	set tuner_offset to my HDHRDeviceSearch("channel2name0(" & caller & ")", hdhr_device)
	if tuner_offset is greater than 0 then
		set channel2name_temp to hdhr_lineup of item tuner_offset of HDHR_DEVICE_LIST
		repeat with i from 1 to length of channel2name_temp
			if GuideNumber of item i of channel2name_temp is the_channel then
				my logger(true, handlername, caller, "DEBUG", "returned \"" & GuideName of item i of channel2name_temp & "\" station for channel " & the_channel & " on " & hdhr_device)
				return GuideName of item i of channel2name_temp
			end if
		end repeat
		my logger(true, handlername, caller, "ERROR", "We were not able to pull lineup data for channel " & the_channel & " for device " & hdhr_device)
		--return false
	else
		my logger(true, handlername, caller, "WARN", "tuner_offset is 0")
		return false
	end if
end channel2name

on nextday(caller, the_show_id)
	set handlername to "nextday"
	copy (current date) to cd_object
	set nextup to {}
	set show_offset to my HDHRShowSearch(the_show_id)
	repeat with i from -1 to 7
		--FIX We might be able to skip this, since the show_id offset is already known
		--if the_show_id is show_id of item show_offset of Show_info then
		if ((weekday of (cd_object + i * days)) as text) is in (show_air_date of item show_offset of Show_info) then
			if cd_object is less than (my time_set("nextday(" & caller & ")", (cd_object + i * days), (show_time of item show_offset of Show_info))) + ((show_length of item show_offset of Show_info) * minutes) then
				my logger(true, handlername, caller, "DEBUG", "1nextup: " & nextup)
				my logger(true, handlername, caller, "DEBUG", "cd_object: " & cd_object)
				my logger(true, handlername, caller, "DEBUG", "i: " & i)
				set nextup to my time_set("nextday(" & caller & ")", (cd_object + i * days), show_time of item show_offset of Show_info)
				exit repeat
			end if
		end if
		--end if
	end repeat
	try
		set record_check_pre to ((nextup) - 1 * weeks)
		set record_check_post to (record_check_pre) + ((show_length of item show_offset of Show_info) * minutes)
		if (cd_object) is greater than record_check_pre and (cd_object) is less than record_check_post then
			my logger(true, handlername, caller, "WARN", "We are between record_check_pre and record_check_post")
			set show_next of item show_offset of Show_info to record_check_pre
		end if
	on error errmsg
		my logger(true, handlername, caller, "WARN", "0errmsg: " & errmsg)
	end try
	try
		if nextup is missing value then
			my logger(true, handlername, caller, "WARN", "nextup0 is missing value")
		end if
	on error errmsg
		my logger(true, handlername, caller, "WARN", "errmsg1: " & errmsg)
	end try
	if show_end of item show_offset of Show_info is not nextup + ((show_length of item show_offset of Show_info) * minutes) then
		set show_end of item show_offset of Show_info to nextup + ((show_length of item show_offset of Show_info) * minutes)
		my logger(true, handlername, caller, "INFO", "Show end of \"" & show_title of item show_offset of Show_info & "\" set to: " & nextup + ((show_length of item show_offset of Show_info) * minutes))
		my logger(true, handlername, caller, "DEBUG", "WORK Show end class: " & class of (show_end of item show_offset of Show_info))
	end if
	return nextup
end nextday

on validate_show_info(caller, show_to_check, should_edit)
	set handlername to "validate_show_info"
	my logger(true, handlername, caller, "DEBUG", "show_to_check: " & show_to_check)
	set show_active_changed to false
	if show_to_check is "" then
		repeat with i2 from 1 to length of Show_info
			my validate_show_info("validate_show_info" & i2 & "(" & caller & ")", show_id of item i2 of Show_info, should_edit)
		end repeat
	else
		set i to my HDHRShowSearch(show_to_check)
		my logger(true, handlername, caller, "TRACE", "Running validate on " & show_title of item i of Show_info & ", should_edit: " & should_edit)
		if should_edit is true then
			if show_active of item i of Show_info is true then
				
				--fix this line may be redundent
				if my HDHRDeviceSearch("validate_show_info(" & caller & ")", hdhr_record of item i of Show_info) is 0 then
					set show_deactivate to (display dialog "The tuner, " & hdhr_record of item i of Show_info & " is not currently active, the show should be deactivated" & return & return & "Deactivated shows will be removed on the next save/load" buttons {Running_icon of Icon_record & " Run", "Deactivate", "Next"} cancel button 1 default button 2 with title my check_version_dialog(caller) with icon stop)
				else
					try
						set show_deactivate to (display dialog "Would you like to deactivate: " & return & "\"" & show_title of item i of Show_info & "\"" & return & return & "Deactivated shows will be removed on the next save/load" buttons {Running_icon of Icon_record & "Run", "Deactivate", Edit_icon of Icon_record & " Edit.."} cancel button 1 default button 3 with title my check_version_dialog("validate_show_info(" & caller & ")") with icon my curl2icon("validate_show_info(" & caller & ")", show_logo_url of item i of Show_info))
					on error number -128
						my logger(true, handlername, caller, "WARN", "User clicked " & quote & "Run" & quote)
						set show_deactivate to Running_icon of Icon_record & "Run"
						return false
					end try
				end if
				
				if button returned of show_deactivate is "Deactivate" then
					set show_active of item i of Show_info to false
					set show_recording of item i of Show_info to false
					my showid2PID("main(" & caller & ")", show_id of item i of Show_info, true, true)
					my logger(true, handlername, caller, "INFO", "Deactivated: " & show_title of item i of Show_info)
					return true
				else if button returned of show_deactivate contains "Run" then
					my logger(true, handlername, caller, "INFO", "User clicked " & quote & "Run" & quote)
				end if
			else --if show_active of item i of Show_info is false then
				set show_deactivate to (display dialog "Would you like to activate: " & return & "\"" & show_title of item i of Show_info & "\"" & return & return & "Active shows can be edited" buttons {Running_icon of Icon_record & " Run", "Activate"} cancel button 1 default button 2 with title my check_version_dialog(caller) with icon caution)
				if button returned of show_deactivate is "Activate" then
					set show_active of item i of Show_info to true
					set show_active_changed to true
					my logger(true, handlername, caller, "INFO", "Reactivated: " & show_title of item i of Show_info)
				else if button returned of show_deactivate contains "Run" then
					my logger(true, handlername, caller, "INFO", "User clicked " & quote & "Run" & quote)
				end if
			end if
		end if
		my logger(true, handlername, caller, "DEBUG", show_title of item i of Show_info & " is active? " & show_active of item i of Show_info)
		if show_active of item i of Show_info is true and show_active_changed is false then
			if show_title of item i of Show_info is missing value or show_title of item i of Show_info is "" or should_edit is true then
				
				if show_is_series of item i of Show_info is false then
					set temp_default_button to 3
				else -- if show_is_series of item i of Show_info is true then 
					set temp_default_button to 2
				end if
				
				set show_title_temp to display dialog "What is the title of this show, and is it a series?" & return & "Next Showing: " & my short_date("validate_show(" & caller & ")", show_next of item i of Show_info, true, false) & return & "SeriesID: " & show_seriesid of item i of Show_info buttons {Running_icon of Icon_record & " Run", Series_icon of Icon_record & " Series", Single_icon of Icon_record & " Single"} default button temp_default_button cancel button 1 default answer show_title of item i of Show_info with title my check_version_dialog(caller) giving up after Dialog_timeout
				
				set show_title of item i of Show_info to my stringToUtf8("validate_show_info(" & caller & ")", text returned of show_title_temp)
				
				my logger(true, handlername, caller, "INFO", "Show Title prompt: " & text returned of show_title_temp & ", button_pressed: " & button returned of show_title_temp)
				
				if button returned of show_title_temp contains "Series" then
					set show_is_series of item i of Show_info to true
				else if button returned of show_title_temp contains "Single" then
					set show_is_series of item i of Show_info to false
				end if
				
			end if
			
			--repeat until my is_number(show_channel of item i of show_info) or should_edit = true
			if show_channel of item i of Show_info is missing value or my is_number("validate_show_info(" & caller & ")", show_channel of item i of Show_info) is false or should_edit is true then
				
				set temp_tuner to hdhr_record of item i of Show_info
				set tuner_offset to my HDHRDeviceSearch("channel2name0", temp_tuner)
				if tuner_offset is greater than 0 then
					
					set default_selection to item (my list_position("validate_show_info1", show_channel of item i of Show_info, channel_mapping of item tuner_offset of HDHR_DEVICE_LIST, false)) of channel_mapping of item tuner_offset of HDHR_DEVICE_LIST
					set channel_choice to (choose from list channel_mapping of item tuner_offset of HDHR_DEVICE_LIST with prompt "What channel does this show air on?" default items default_selection with title my check_version_dialog(caller) cancel button name Running_icon of Icon_record & " Run" OK button name "Next.." without empty selection allowed)
					set channel_temp to word 1 of item 1 of channel_choice
					if channel_choice is false then
						my logger(true, handlername, caller, "INFO", "User clicked " & quote & "Run" & quote)
					end if
					
				else
					set channel_temp to text returned of (display dialog "What channel does this show air on?" default answer show_channel of item i of Show_info with title my check_version_dialog(caller) giving up after Dialog_timeout)
				end if
				my logger(true, handlername, caller, "INFO", "Channel Prompt returned: " & channel_temp)
				set show_channel of item i of Show_info to channel_temp --set show_channel of item i of show_info to word 1 of item 1 of (choose from list channel_list with prompt "What channel does this show air on?" default items show_channel of item i of show_info without empty selection allowed) 
			end if
			
			if show_time of item i of Show_info is missing value or (show_time of item i of Show_info as number) is greater than or equal to 24 or my is_number("validate_show_info(" & caller & ")", show_time of item i of Show_info) is false or should_edit is true then
				set show_time of item i of Show_info to text returned of (display dialog "What time does this show air? " & return & "(0-24, use decimals, ie 9.5 for 9:30)" default answer show_time of item i of Show_info buttons {Running_icon of Icon_record & " Run", "Next.."} with title my check_version_dialog(caller) giving up after Dialog_timeout default button 2 cancel button 1) as number
				set show_time_orig of item i of Show_info to show_time of item i of Show_info
			end if
			if show_length of item i of Show_info is missing value or my is_number("validate_show_info(" & caller & ")", show_length of item i of Show_info) is false or show_length of item i of Show_info is less than or equal to 0 or should_edit is true then
				set show_length of item i of Show_info to text returned of (display dialog "How long is this show? (minutes)" default answer show_length of item i of Show_info with title my check_version_dialog(caller) buttons {Running_icon of Icon_record & " Run", "Next.."} default button 2 cancel button 1 giving up after Dialog_timeout)
			end if
			
			if show_air_date of item i of Show_info is missing value or length of (show_air_date of item i of Show_info) is 0 or should_edit is true or class of (show_air_date of item i of Show_info) is not list then
				if show_is_series of item i of Show_info is true then
					set show_air_date of item i of Show_info to (choose from list {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"} default items show_air_date of item i of Show_info with title my check_version_dialog(caller) OK button name "Next.." cancel button name Running_icon of Icon_record & " Run" with prompt "Select the days you wish to record" & return & "If this is a series, you can select multiple days" with multiple selections allowed without empty selection allowed)
				else
					set show_air_date of item i of Show_info to (choose from list {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"} default items show_air_date of item i of Show_info with title my check_version_dialog(caller) OK button name "Next.." cancel button name Running_icon of Icon_record & " Run" with prompt "Select the days you wish to record" & return & "If this is a series, you can select multiple days" without multiple selections allowed and empty selection allowed)
				end if
			end if
			if show_dir of item i of Show_info is missing value or (class of (show_temp_dir of item i of Show_info) as text) is not "alias" or should_edit is true then
				try
					set show_dir of item i of Show_info to choose folder with prompt "Select shows Directory" default location show_dir of item i of Show_info
				on error errmsg
					my logger(true, handlername, caller, "WARN", "Invalid path, errmsg: " & errmsg)
					
					try
						--new added default location
						set show_dir of item i of Show_info to choose folder with prompt "The show: " & return & show_title of item i of Show_info & return & " has an invalid directory. Please choose another" default location show_dir of item i of Show_info
					on error errmsg
						my logger(true, handlername, caller, "WARN", "Invalid path, errmsg: " & errmsg)
						my validate_show_info("main(" & caller & ")", show_id of item i of Show_info, false)
					end try
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
				display notification with title Edit_icon of Icon_record & " Show Changed! (" & hdhr_record of last item of Show_info & ")" subtitle "" & quote & show_title of last item of Show_info & quote & " at " & show_time of last item of Show_info
			end if
			if my HDHRDeviceSearch("validate_show_info(hdhr)", hdhr_record of item i of Show_info) is 0 then
				my logger(true, handlername, caller, "WARN", "The show " & quote & show_title of item i of Show_info & quote & ", will not be recorded, as the tuner " & hdhr_record of item i of Show_info & ", is no longer detected")
				display notification with title Stop_icon of Icon_record & " Recording Stopped!"
			end if
		else
			set show_active_changed to false
		end if
	end if
end validate_show_info

on setup(caller)
	set handlername to "setup"
	set hdhr_setup_response to (display dialog "hdhr_VCR Setup" buttons {"Logging", "Defaults", "Run"} default button 1 cancel button 3 with title my check_version_dialog(caller) giving up after Dialog_timeout)
	repeat 1 times
		try
			if button returned of hdhr_setup_response is "Defaults" then
				set rerun_discovery to button returned of (display dialog "Rerun HDHRDeviceDiscovery?" buttons {"Skip", "Yes"} default button 2 with title my check_version_dialog(caller) giving up after Dialog_timeout with icon note)
				try
					if rerun_discovery is "Yes" then
						my HDHRDeviceDiscovery("main_opt", "")
					end if
				end try
				
				set reload_script to button returned of (display dialog "Reload hdhr library?" buttons {"Skip", "Yes"} default button 2 with title my check_version_dialog(caller) giving up after Dialog_timeout with icon note)
				try
					if reload_script is "Yes" then
						my loadlib(handlername)
					end if
				end try
				
				
				set Temp_dir to alias "Volumes:"
				repeat until Temp_dir is not alias "Volumes:"
					set hdhr_setup_folder_temp to choose folder with prompt "Select default shows directory" default location Temp_dir
					if hdhr_setup_folder_temp is not alias "Volumes:" then
						set Hdhr_setup_folder to hdhr_setup_folder_temp as text
						exit repeat
					end if
				end repeat
				display dialog "We need to allow notifications" & return & "Click " & quote & "Next" & quote & " to continue" buttons {"Next"} default button 1 with title my check_version_dialog(caller) giving up after Dialog_timeout
				display notification "Yay!" with title name of me subtitle "Notifications Enabled!"
				set Notify_upnext to text returned of (display dialog "How often to show " & quote & "Up Next" & quote & " update notifications?" default answer Notify_upnext buttons {"Run", "Skip", "OK"} default button 3 cancel button 1 with title my check_version_dialog(caller) giving up after Dialog_timeout with icon note)
				set Notify_recording to text returned of (display dialog "How often to show " & quote & "Recording" & quote & " update notifications?" default answer Notify_recording buttons {"Run", "Skip", "OK"} default button 3 cancel button 1 with title my check_version_dialog(caller) giving up after Dialog_timeout with icon note)
				
				set Hdhr_setup_ran to true
			end if
			if button returned of hdhr_setup_response is "Logging" then
				try
					set logging_response to (choose from list Logger_levels_all with prompt "Current Logging Levels:" default items Logger_levels with multiple selections allowed without empty selection allowed)
					--set logging_response to button returned of (display dialog "Set logging levels to all?" buttons {"Run", "Default", "Yes"} default button 3)
				on error errmsg
					my logger(true, handlername, caller, "WARN", "Logging Setup error: " & errmsg)
				end try
				if length of logging_response is greater than 1 then
					set Logger_levels to logging_response
				end if
			end if
		on error errmsg
			my logger(true, handlername, caller, "WARN", "User cancelled")
		end try
	end repeat
end setup

on AreWeOnline(caller)
	set handlername to "AreWeOnline"
	if Online_detected and Hdhr_detected is true then
		my read_data(my cm(handlername, caller))
		set Hdhr_config to {Notify_upnext:Notify_upnext, Notify_recording:Notify_recording, Hdhr_setup_folder:Hdhr_setup_folder, Config_version:Config_version}
		return true
	else
		my logger(true, handlername, caller, "ERROR", "hdhr_detected is " & Hdhr_detected)
		return false
	end if
end AreWeOnline

on main(caller, emulated_button_press)
	set handlername to "main"
	if First_open is true then
		set First_open to false
	end if
	if length of HDHR_DEVICE_LIST is 0 then my HDHRDeviceDiscovery(my cm(handlername, caller), "")
	my logger(true, handlername, caller, "INFO", "Main screen called")
	--This will mark shows as inactive (single show recording that has already passed)
	set show_info_length to length of Show_info
	if show_info_length is greater than 0 then
		repeat with i from 1 to show_info_length
			if show_last of item i of Show_info is not my epoch() and show_is_series of item i of Show_info is false then
				set show_active of item i of Show_info to false
			end if
		end repeat
	end if
	set show_list_empty to false
	set next_show_main_temp to my next_shows(my cm(handlername, caller))
	my logger(true, handlername, caller, "DEBUG", "Tracking non open00")
	set next_show_main to my stringlistflip(my cm(handlername, caller), item 2 of next_show_main_temp, return, "string")
	set next_show_main_time to my short_date(my cm(handlername, caller), item 1 of next_show_main_temp, false, false)
	set next_show_main_time_real to item 1 of next_show_main_temp
	set error_shows to my stringlistflip(my cm(handlername, caller), item 3 of next_show_main_temp, return, "string")
	my logger(true, handlername, caller, "DEBUG", "Tracking non open01")
	if emulated_button_press is not in {"Add", "Shows"} then
		my logger(true, handlername, caller, "INFO", "Emulated_button_press is " & emulated_button_press)
		try
			try
				activate me
			end try
			if show_list_empty is true then
				my logger(true, handlername, caller, "TRACE", "Tracking non open2")
				set title_response to (display dialog "Would you like to add a show?" & return & return & "Tuner(s): " & return & my stringlistflip(my cm(handlername, caller), my tuner_overview(my cm(handlername, caller)), return, "string") buttons {Tv_icon of Icon_record & " Shows..", Plus_icon of Icon_record & " Add..", Running_icon of Icon_record & " Run"} with title my check_version_dialog(my cm(handlername, caller)) giving up after (Dialog_timeout * 0.5) with icon my curl2icon(my cm(handlername, caller), "https://raw.githubusercontent.com/identd113/hdhr_VCR-AS/master/app.jpg") default button 2)
				my logger(true, handlername, caller, "INFO", "EMPTY LIST")
			else
				my logger(true, handlername, caller, "TRACE", "Tracking non open3")
				set title_response to (display dialog "Would you like to add a show?" & return & return & "Tuner(s): " & return & my stringlistflip(my cm(handlername, caller), my tuner_overview(my cm(handlername, caller)), return, "string") & return & return & my recordingnow_main("main(" & caller & ")") & return & error_shows & return & return & Up_icon of Icon_record & " Next Show: " & next_show_main_time & " (in " & my ms2time(my cm(handlername, caller), (next_show_main_time_real) - (current date), "s", 2) & ")" & return & next_show_main buttons {Tv_icon of Icon_record & " Shows..", Plus_icon of Icon_record & " Add..", Running_icon of Icon_record & " Run"} with title my check_version_dialog("main(" & caller & ")") giving up after (Dialog_timeout * 0.5) with icon my curl2icon("main(" & caller & ")", "https://raw.githubusercontent.com/identd113/hdhr_VCR-AS/master/app.jpg") default button 2)
				my logger(true, handlername, caller, "INFO", "SHOW LIST")
			end if
		on error errmsg
			my logger(true, handlername, caller, "TRACE", "Tracking non open03, errmsg: " & errmsg)
		end try
		my logger(true, handlername, caller, "TRACE", "Tracking non open4")
	else
		my logger(true, handlername, caller, "DEBUG", "emulated_button_press is " & emulated_button_press)
		set title_response to {button returned:emulated_button_press, gave up:false}
	end if
	my logger(true, handlername, caller, "INFO", "Main screen called2 " & quote & emulated_button_press & quote & " " & quote & button returned of title_response & quote)
	--ADD
	my logger(true, handlername, caller, "TRACE", "Tracking non open5")
	if button returned of title_response contains "Add" then
		my logger(true, handlername, caller, "INFO", "UI:Clicked " & quote & "Add" & quote)
		my build_channel_list(my cm(handlername, caller), "")
		set temp_tuners_list to {}
		if length of HDHR_DEVICE_LIST is greater than 0 then
			repeat with i from 1 to length of HDHR_DEVICE_LIST
				if is_active of item i of HDHR_DEVICE_LIST is true then
					set end of temp_tuners_list to hdhr_model of item i of HDHR_DEVICE_LIST & " " & (device_id of item i of HDHR_DEVICE_LIST)
				else
					set is_active_reason of item i of HDHR_DEVICE_LIST to "Deactivated"
					my logger(true, handlername, caller, "INFO", "The tuner, " & device_id of item i of HDHR_DEVICE_LIST & " was not added")
				end if
			end repeat
			if length of temp_tuners_list is greater than 1 then
				set preferred_tuner to choose from list temp_tuners_list with prompt "Multiple HDHR Devices found, please choose one" cancel button name Running_icon of Icon_record & " Run" OK button name "Select" with title my check_version_dialog(my cm(handlername, caller)) default items item 1 of temp_tuners_list
				if preferred_tuner is not false then
					my logger(true, my cm(handlername, caller), "INFO", "User clicked " & quote & "Run" & quote)
					set hdhr_device to last word of item 1 of preferred_tuner
				else
					set hdhr_device to missing value
				end if
			else
				set hdhr_device to device_id of item 1 of HDHR_DEVICE_LIST
			end if
			my add_show_info(my cm(handlername, caller), hdhr_device, "")
		else
			try
				with timeout of 15 seconds
					my HDHRDeviceDiscovery(my cm(handlername, caller), "")
				end timeout
			on error errnum
				my logger(true, handlername, caller, "INFO", "UI:Clicked " & quote & "Add" & quote)
				my main(my cm(handlername, caller), "")
			end try
		end if
	end if
	--SHOWS
	if button returned of title_response contains "Shows" then
		set progress description to "Loading " & length of Show_info & " shows ..."
		set progress additional description to ""
		set progress completed steps to 0
		set progress total steps to length of Show_info
		if option_down of my isModifierKeyPressed("main(" & caller & ")", "option", "Runs Setup") is true then
			my setup("main(" & caller & ")")
			return
		end if
		my logger(true, handlername, caller, "INFO", "UI:Clicked \"Shows\"")
		set show_list to {}
		set show_list_length to length of Show_info
		copy (current date) to cd
		repeat with i from 1 to show_list_length
			set progress completed steps to i
			set progress additional description to show_title of item i of Show_info
			set temp_show_line to " " & (show_title of item i of Show_info & " on " & show_channel of item i of Show_info & " at " & show_time of item i of Show_info & " for " & show_length of item i of Show_info & " minutes on " & my stringlistflip("main", show_air_date of item i of Show_info, ", ", "string"))
			if show_is_series of item i of Show_info is true then
				if length of show_air_date of item i of Show_info is 1 then
					set temp_show_line to Series1_icon of Icon_record & temp_show_line
				else
					set temp_show_line to Series_icon of Icon_record & temp_show_line
				end if
			else
				set temp_show_line to Single_icon of Icon_record & temp_show_line
			end if
			
			if show_active of item i of Show_info is false then
				set temp_show_line to Uncheck_icon of Icon_record & temp_show_line
			end if
			
			if ((show_next of item i of Show_info) - (cd)) is less than 4 * hours and show_active of item i of Show_info is true and show_recording of item i of Show_info is false then
				if ((show_next of item i of Show_info) - (cd)) is greater than 1 * hours then
					set temp_show_line to Up_icon of Icon_record & temp_show_line
				else if ((show_next of item i of Show_info) - (cd)) is less than 0 then
					set temp_show_line to Warning_icon of Icon_record & temp_show_line
				else
					set temp_show_line to Film_icon of Icon_record & temp_show_line
				end if
			end if
			if ((show_next of item i of Show_info) - (cd)) is greater than or equal to 4 * hours and (date (date string of (cd))) is (date (date string of (show_next of item i of Show_info))) and show_active of item i of Show_info is true and show_recording of item i of Show_info is false then
				set temp_show_line to Up2_icon of Icon_record & temp_show_line
			end if
			if show_recording of item i of Show_info is true and show_active of item i of Show_info is true then
				set temp_show_line to Record_icon of Icon_record & temp_show_line
			end if
			if (date (date string of (cd))) is less than (date (date string of (show_next of item i of Show_info))) and show_active of item i of Show_info is true and (show_recorded_today of item i of Show_info) is false then
				set temp_show_line to Futureshow_icon of Icon_record & temp_show_line
			end if
			try
				if (show_recorded_today of item i of Show_info) is true then
					set temp_show_line to Done_icon of Icon_record & temp_show_line
				end if
			on error errmsg
				my logger(true, handlername, caller, "ERROR", "Error with show_recorded_today, errmsg: " & errmsg)
			end try
			set end of show_list to temp_show_line
			if show_list_length is i then
				set progress additional description to length of Show_info & " shows loaded"
			end if
		end repeat
		if length of show_list is 0 then
			set progress completed steps to -1
			set progress additional description to "No shows to load"
			try
				my logger(true, handlername, caller, "WARN", "There are no shows")
				set hdhr_no_shows to button returned of (display dialog "There are no shows, why don't you add one?" buttons {"Quit", Plus_icon of Icon_record & " Add Show"} default button 2)
				if hdhr_no_shows contains "Add Show" then
					my main("main_noshow(" & caller & ")", "Add")
				end if
				if hdhr_no_shows is "Quit" then
					quit {}
				end if
			on error
				my logger(true, handlername, caller, "INFO", "User clicked " & quote & "Run" & quote)
				return
			end try
		else if length of show_list is greater than 0 then
			set temp_show_list to (choose from list show_list with title my check_version_dialog(caller) with prompt "" & length of show_list & " shows to edit: " & return & Single_icon of Icon_record & " Single   " & Series_icon of Icon_record & " Series" & "   " & Record_icon of Icon_record & " Recording" & "   " & Uncheck_icon of Icon_record & " Inactive" & return & Film_icon of Icon_record & " Up Next < 1h" & "  " & Up_icon of Icon_record & " Up Next < 4h" & "  " & Up2_icon of Icon_record & " Up Next > 4h" & "  " & Futureshow_icon of Icon_record & " Future Show" & "   " & Done_icon of Icon_record & " Recorded today" & "   " & Warning_icon of Icon_record & " Error" OK button name Edit_icon of Icon_record & " Edit.." cancel button name Running_icon of Icon_record & " Run" default items item 1 of show_list with multiple selections allowed without empty selection allowed)
			
			if temp_show_list is not false then
				repeat with i3 from 1 to length of temp_show_list
					set temp_show_list_offset to (my list_position("main1(" & caller & ")", (item i3 of temp_show_list as text), show_list, true))
					my logger(true, handlername, caller, "DEBUG", "Pre validate for " & show_title of item temp_show_list_offset of Show_info)
					
					my validate_show_info("main(" & caller & ")", show_id of item temp_show_list_offset of Show_info, true)
					if show_active of item (temp_show_list_offset) of Show_info is true then
						my update_show("main2(" & caller & ")", show_id of item temp_show_list_offset of Show_info, true)
						set show_next of item temp_show_list_offset of Show_info to my nextday("main(" & caller & ")", show_id of item temp_show_list_offset of Show_info)
					end if
					
					if i3 is length of temp_show_list then
						my main("shows(" & caller & ")", "Shows")
						return
					end if
				end repeat
			else
				my logger(true, handlername, caller, "INFO", "1User clicked " & quote & "Run" & quote)
				return false
			end if
		end if
	end if
	
	if button returned of title_response contains "Run" or gave up of title_response is true then
		my logger(true, handlername, caller, "INFO", "2User clicked " & quote & "Run" & quote)
		if option_down of my isModifierKeyPressed("main_opt", "option", "Quit?") is true then
			quit {}
		end if
		return
	end if
end main

on add_show_info(caller, hdhr_device, hdhr_channel)
	set handlername to "add_show_info"
	copy (current date) to cd
	set hdhr_skip_multiple_bool to false
	set temp_show_air_date to missing value
	set temp_show_dir to missing value
	set temp_show_transcode to missing value
	set temp_is_series to missing value
	set progress additional description to ""
	set progress description to "Adding a show on " & hdhr_device & "..."
	set tuner_status_result to my tuner_status("add_show(" & caller & ")", hdhr_device)
	set tuner_status_icon to "Tuner: " & hdhr_device
	if tunermax of tuner_status_result is tuneractive of tuner_status_result then
		set tuner_status_icon to hdhr_device & " has no available tuners" & return & "Next timeout: " & my ms2time("add_show_info(" & caller & ")", my tuner_end("add_show_info(" & caller & ")", hdhr_device), "s", 3)
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
	set temp_show_progress to {}
	set hdhrGRID_response to true
	set progress description to "Select a channel on tuner: " & hdhr_device & "..."
	repeat until hdhrGRID_response is not true
		if Back_channel is missing value then
			set default_selection to item 1 of channel_mapping of item tuner_offset of HDHR_DEVICE_LIST
		else
			set default_selection to item (my list_position("add_show_info(" & caller & ")", Back_channel, channel_mapping of item tuner_offset of HDHR_DEVICE_LIST, false)) of channel_mapping of item tuner_offset of HDHR_DEVICE_LIST
		end if
		my logger(true, handlername, caller, "INFO", "default_selection: " & default_selection)
		set hdhrGRID_list_response to (choose from list channel_mapping of item tuner_offset of HDHR_DEVICE_LIST with prompt "What channel does this show air?" & return & return & tuner_status_icon with title my check_version_dialog(caller) OK button name "Next.." cancel button name Running_icon of Icon_record & " Run" default items default_selection without empty selection allowed)
		if hdhrGRID_list_response is not false then
			set show_channel_temp to word 1 of item 1 of hdhrGRID_list_response
			set end of temp_show_progress to "Channel: " & show_channel_temp & " (" & my channel2name("add_show_info(" & caller & ")", show_channel_temp, hdhr_device) & ")"
			set progress additional description to my stringlistflip("add_show(" & caller & ")", temp_show_progress, return, "string")
			set hdhrGRID_response to my hdhrGRID("add_show_info(" & caller & ")", hdhr_device, show_channel_temp)
		else
			my logger(true, handlername, caller, "INFO", "User clicked " & quote & "Run" & quote)
			return
		end if
	end repeat
	--return true means we want to go back 
	--return false means we cancelled out.
	--return anything else, and this is the guide data for the channel they are requesting.
	--The above line pulls guide data.  If we fail this, we will prompt the user to enter the information. 
	
	if hdhrGRID_response is not false then
		if length of hdhrGRID_response is greater than 1 then
			my logger(true, handlername, caller, "INFO", "Multiple shows selected for recording on " & hdhr_device)
			set hdhr_skip_multiple to button returned of (display dialog "You are adding multiple shows.  Do you wish to use the same settings for all shows?" buttons {"No", "Yes"} default button 2 with title my check_version_dialog(caller) giving up after Dialog_timeout * 0.5 with icon note)
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
				set temp_show_info to {show_title:missing value, show_time:missing value, show_length:missing value, show_air_date:missing value, show_transcode:missing value, show_temp_dir:missing value, show_dir:missing value, show_channel:show_channel_temp, show_active:true, show_id:(do shell script "date | md5") as text, show_recording:false, show_last:my epoch(), show_next:missing value, show_end:missing value, notify_upnext_time:missing value, notify_recording_time:missing value, hdhr_record:hdhr_device, show_is_series:false, show_seriesid:"", show_tags:{}, show_time_orig:missing value, show_is_sport:false, show_recorded_today:false, show_recording_path:"", show_logo_url:"", show_url:"", show_fail_count:0, show_use_seriesid:false, show_use_seriesid_all:false}
				if length of hdhrGRID_response is 1 and hdhrGRID_response is {""} then
					my logger(true, handlername, caller, "INFO", "(Manual) Adding show for " & hdhr_device)
					set show_title_temp to display dialog "What is the title of this show, and is it a series?" buttons {Running_icon of Icon_record & " Run", Series_icon of Icon_record & " Series", Single_icon of Icon_record & " Single"} cancel button 1 default button 3 default answer "" with title my check_version_dialog(caller) giving up after Dialog_timeout
					--set show_title of temp_show_info to my stringToUtf8("add_show(" & caller & ")", text returned of show_title_temp)
					set show_title of temp_show_info to text returned of show_title_temp
					set end of temp_show_progress to "Title: " & show_title of temp_show_info
					set progress additional description to my stringlistflip("add_show(" & caller & ")", temp_show_progress, return, "string")
					my logger(true, handlername, caller, "INFO", "(Manual) Show name: " & show_title of temp_show_info)
					set progress completed steps to 1
					--show_is_series
					if button returned of show_title_temp contains "Series" then
						set show_is_series of temp_show_info to true
					else if button returned of show_title_temp contains "Single" then
						set show_is_series of temp_show_info to false
					else
						my logger(true, handlername, caller, "INFO", "User clicked " & quote & "Run" & quote)
						return
					end if
					set end of temp_show_progress to "Series: " & show_is_series of temp_show_info
					set progress additional description to my stringlistflip("add_show(" & caller & ")", temp_show_progress, return, "string")
					set progress completed steps to 2
					my logger(true, handlername, caller, "INFO", "(Manual) show_is_series: " & show_is_series of temp_show_info)
					--time
					repeat until my is_number("add_show_info(" & caller & ")", show_time of temp_show_info) and show_time of temp_show_info is greater than or equal to 0 and show_time of temp_show_info is less than 24
						set Time_slide to 0
						set show_time_temp to (display dialog "What time does this show air? " & return & "(0-24, use decimals, ie 16.75 for 4:45 PM)" default answer hours of (cd) buttons {Running_icon of Icon_record & " Run", "Next.."} with title my check_version_dialog(caller) giving up after Dialog_timeout default button 2 cancel button 1)
						if (text returned of show_time_temp as number) is less than hours of (cd) then
							set Time_slide to Time_slide + 1
							set default_record_day to (weekday of ((cd) + Time_slide * days)) as text
							my logger(true, handlername, caller, "INFO", "default_record_day set to " & default_record_day)
						end if
						set show_time of temp_show_info to text returned of show_time_temp as number
						set show_time_orig of temp_show_info to show_time of temp_show_info
						
					end repeat
					set end of temp_show_progress to "Air time: " & show_time of temp_show_info
					set progress additional description to my stringlistflip("add_show(" & caller & ")", temp_show_progress, return, "string")
					set progress completed steps to 3
					my logger(true, handlername, caller, "INFO", "(Manual) show time: " & show_time of temp_show_info)
					repeat until my is_number("add_show_info(" & caller & ")", show_length of temp_show_info) and show_length of temp_show_info is greater than or equal to 1
						set show_length of temp_show_info to text returned of (display dialog "How long is this show? (minutes)" default answer "30" with title my check_version_dialog(caller) buttons {Running_icon of Icon_record & " Run", "Next.."} default button 2 cancel button 1 giving up after Dialog_timeout)
					end repeat
					
					set end of temp_show_progress to "Length: " & show_length of temp_show_info
					set progress additional description to my stringlistflip("add_show(" & caller & ")", temp_show_progress, return, "string")
					set progress completed steps to 4
					my logger(true, handlername, caller, "INFO", "(Manual) show length: " & show_length of temp_show_info)
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
					on error errmsg
						my logger(true, handlername, caller, "WARN", "(Auto) Unable to set full show name, " & errmsg)
					end try
					
					try
						set default_record_day to (weekday of my epoch2datetime("hdhrGRID3(" & caller & ")", (my getTfromN(StartTime of item i3 of hdhrGRID_response)))) as text
					on error errmsg
						my logger(true, handlername, caller, "WARN", "default_record_day failed, errmsg: " & errmsg)
						set default_record_day to weekday of (cd) as text
					end try
					
					--set show_title of temp_show_info to my stringToUtf8("add_show(" & caller & ")", hdhr_response_channel_title)
					set show_title of temp_show_info to hdhr_response_channel_title
					set end of temp_show_progress to "Title: " & hdhr_response_channel_title
					set progress additional description to my stringlistflip("add_show(" & caller & ")", temp_show_progress, return, "string")
					set progress completed steps to 1
					my logger(true, handlername, caller, "INFO", "(Auto) show name: " & show_title of temp_show_info)
					
					--auto length 
					try
						set show_length of temp_show_info to ((EndTime of item i3 of hdhrGRID_response) - (StartTime of item i3 of hdhrGRID_response)) div 60
						my logger(true, handlername, caller, "INFO", "(Auto) show_length of temp_show_info: " & show_length of temp_show_info)
					on error errmsg
						my logger(true, handlername, caller, "WARN", "(Auto) show length defaulted to 30 minutes, errmsg: " & errmsg)
						set show_length of temp_show_info to 30
					end try
					set end of temp_show_progress to "Length: " & show_length of temp_show_info
					set progress additional description to my stringlistflip("add_show(" & caller & ")", temp_show_progress, return, "string")
					set progress completed steps to 2
					my logger(true, handlername, caller, "INFO", "(Auto) show length: " & show_length of temp_show_info)
					
					--auto show_time 
					set show_time of temp_show_info to my epoch2show_time("hdhrGRID4(" & caller & ")", my getTfromN(StartTime of item i3 of hdhrGRID_response))
					set show_time_orig of temp_show_info to show_time of temp_show_info
					my logger(true, handlername, caller, "INFO", "(Auto) show time: " & (show_time of temp_show_info as text))
					set end of temp_show_progress to "Air time: " & show_time of temp_show_info
					set progress additional description to my stringlistflip("add_show(" & caller & ")", temp_show_progress, return, "string")
					set progress completed steps to 3
					try
						set synopsis_temp to Synopsis of item i3 of hdhrGRID_response
					on error errmsg
						my logger(true, handlername, caller, "WARN", "Unable to pull Synopsis")
						set synopsis_temp to "No Synopsis"
					end try
					
					try
						set show_logo_url of temp_show_info to (ImageURL of item i3 of hdhrGRID_response as text)
					on error errmsg
						my logger(true, handlername, caller, "WARN", "Unable to pull ImageURL")
						set show_logo_url of temp_show_info to ""
					end try
					
					try
						set show_url of temp_show_info to my add_record_url("add_show_info(" & caller & ")", show_channel_temp, hdhr_device)
						my logger(true, handlername, caller, "INFO", "Added show_url: " & show_url of temp_show_info)
					on error errmsg
						my logger(true, handlername, caller, "WARN", "Unable to pull show_url, errmsg: " & errmsg)
						set show_url of temp_show_info to ""
					end try
					
					try
						set seriesid_temp to seriesID of item i3 of hdhrGRID_response
						set show_seriesid of temp_show_info to seriesID of item i3 of hdhrGRID_response
						my logger(true, handlername, caller, "INFO", "Set Series ID: " & seriesID of item i3 of hdhrGRID_response)
					on error errmsg
						my logger(true, handlername, caller, "WARN", "Unable to pull Series ID: " & errmsg)
						set seriesid_temp to "No SeriesID provided"
					end try
					--(*
					try
						if option_down of my isModifierKeyPressed("main(" & caller & ")", "option", "SeriesID search per channel") then
							my seriesScan(caller, (seriesID of item i3 of hdhrGRID_response), hdhr_device, show_channel_temp)
						else
							my seriesScan(caller, (seriesID of item i3 of hdhrGRID_response), hdhr_device, "")
						end if
					on error errmsg
						my logger(true, handlername, caller, "WARN", "Unable to lookup Series ID: " & errmsg)
					end try
					--*)
					
					try
						set temp_icon to my curl2icon("add_show_info(" & caller & ")", ImageURL of item i3 of hdhrGRID_response)
					on error errmsg
						my logger(true, handlername, caller, "WARN", "Unable to pull ImageURL: " & errmsg)
						set temp_icon to ""
					end try
					
					try
						set show_tags of temp_show_info to Filter of item i3 of hdhrGRID_response
					on error
						set show_tags of temp_show_info to {"None"}
					end try
					
					try
						set tags_text to my stringlistflip("add_show_info(" & caller & ")", show_tags of temp_show_info, ", ", "string")
					on error errmsg
						set tags_text to "ERROR"
						my logger(true, handlername, caller, "ERROR", errmsg)
					end try
					
					set temp_default_button to 3
					if temp_is_series is true then
						set temp_default_button to 2
					end if
					
					try
						set show_originalairdate to OriginalAirdate of item i3 of hdhrGRID_response
						set show_originalairdate_real to my short_date("add_show_info(" & caller & ")", my epoch2datetime("add_show_info1(" & caller & ")", show_originalairdate), false, false)
					on error errmsg
						set show_originalairdate_real to "Unknown"
					end try
					
					try
						-- We need to note if the show start time was yesterday, and adjust as needed.
						
						set temp_show_info_series to (display dialog "Is this a single or a series recording? " & return & return & "Title: " & show_title of temp_show_info & return & "Type: " & tags_text & return & "SeriesID: " & seriesid_temp & return & return & "Synopsis: " & synopsis_temp & return & return & "Start: " & time string of my time_set("add_show_info(" & caller & ")", cd, show_time of temp_show_info) & return & "Length: " & my ms2time("add_show_info2", ((show_length of temp_show_info) * 60), "s", 2) & return & "OriginalAirdate: " & show_originalairdate_real buttons {Running_icon of Icon_record & " Run", Series_icon of Icon_record & " Series", Single_icon of Icon_record & " Single"} default button temp_default_button cancel button 1 with title my check_version_dialog(caller) giving up after Dialog_timeout with icon temp_icon)
						
						if button returned of temp_show_info_series contains "Series" then
							set show_is_series of temp_show_info to true
							set series_bySeriesID to (display dialog "Would you like to record based on Time/Channel or SeriesID?" buttons {"Time/Channel", "SeriesID", Running_icon of Icon_record & " Run"} giving up after Dialog_timeout with icon temp_icon)
							if button returned of series_bySeriesID is "SeriesID" then
								set show_use_seriesid of temp_show_info to true
							else if button returned of series_bySeriesID contains "Run" then
								return false
							end if
							set temp_channel_record to {button returned:"Run"}
							if show_use_seriesid of temp_show_info is true then
								set temp_channel_record to (display dialog "How would you like to record, based on SeriesID?" buttons {"This Channel", "All Channels", Running_icon of Icon_record & " Run"} giving up after Dialog_timeout with icon temp_icon)
								if button returned of temp_channel_record is "All Channels" then
									set show_use_seriesid_all of temp_show_info to true
								else if button returned of temp_channel_record contains "Run" then
									return false
								end if
							end if
						else if button returned of temp_show_info_series contains "Single" then
							set show_is_series of temp_show_info to false
						end if
						
						set end of temp_show_progress to "Series: " & show_is_series of temp_show_info
						set progress additional description to my stringlistflip("add_show(" & caller & ")", temp_show_progress, return, "string")
						set progress completed steps to 4
						my logger(true, handlername, caller, "INFO", "(Auto) show_is_series: " & show_is_series of temp_show_info)
					on error errmsg
						my logger(true, handlername, caller, "WARN", "(Auto) " & show_title of temp_show_info & " NOT added, errmsg: " & errmsg)
						exit repeat
					end try
				end if
				
				set Time_slide to 0
				
				if temp_show_air_date is missing value then
					try
						if (weekday of my epoch2datetime("hdhrGRID(" & caller & ")", (my getTfromN(StartTime of item i3 of hdhrGRID_response)))) as text is not (weekday of (cd) as text) then
							set Time_slide to 1
						end if
					on error errmsg
						my logger(true, handlername, caller, "WARN", "Time Slide defaulted to 0, errmsg: " & errmsg)
						set Time_slide to 0
						set default_record_day to weekday of (cd) as text
					end try
				else
					set default_record_day to temp_show_air_date
				end if
				
				--NEW
				set sports_ball_bool to "No"
				(*
				try
					if "Sports" is in show_tags of temp_show_info then
						set sports_ball_bool to button returned of (display dialog quote & show_title of temp_show_info & quote & return & return & "Is listed as a Sport" & return & "Would you like to add an additional 30 minutes past the scheduled time, to ensure the whole game is captured?" buttons {"Run", "No", "Yes"} default button 3 cancel button 1 with title my check_version_dialog(caller) giving up after Dialog_timeout with icon temp_icon)
						if sports_ball_bool is "Yes" then
							set show_is_sport of temp_show_info to true
						end if
					end if
				end try
				*)
				if show_air_date of temp_show_info is false then
					return
					--fall back into the idle() loop 
				end if
				if show_is_series of temp_show_info is true then
					set show_air_date of temp_show_info to (choose from list {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"} default items default_record_day with title my check_version_dialog(caller) OK button name "Next.." cancel button name Running_icon of Icon_record & " Run" with prompt "Select the days you wish to record." & return & "A \"Series\" can select multiple days" with multiple selections allowed without empty selection allowed)
					my logger(true, handlername, caller, "INFO", "(Manual) show_air_date: " & my stringlistflip("add_show", show_air_date of temp_show_info, ",", "string"))
				else
					if hdhrGRID_response is {""} then
						set show_air_date of temp_show_info to (choose from list {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"} default items default_record_day with title my check_version_dialog(caller) OK button name "Next.." cancel button name Running_icon of Icon_record & " Run" with prompt "Select the day you wish to record." & return & "A \"Single\" can only select 1 day." without empty selection allowed)
						if show_air_date of temp_show_info is false then
							return
						end if
						--set temp_show_air_date to show_air_date of temp_show_info
						my logger(true, handlername, caller, "INFO", "(Manual) show_air_date: " & my stringlistflip("add_show2()", show_air_date of temp_show_info, ",", "string"))
					else
						set show_air_date of temp_show_info to (weekday of (my epoch2datetime("hdhrGRID6(" & caller & ")", (my getTfromN(StartTime of item i3 of hdhrGRID_response)))) as text) as list
						my logger(true, handlername, caller, "INFO", "(Auto) show_air_date: " & show_air_date of temp_show_info)
					end if
				end if
				set end of temp_show_progress to "When: " & my stringlistflip("add_show_info(show_air_date)", show_air_date of temp_show_info, ", ", "string")
				set progress additional description to my stringlistflip("add_show_info(" & caller & ")", temp_show_progress, return, "string")
				set progress completed steps to 5
				
				if does_transcode of item tuner_offset of HDHR_DEVICE_LIST is 1 then
					--!! This may throw an error if the hdhr unit does not have transcoding 
					if temp_show_transcode is missing value then
						set show_transcode_response to (choose from list {"None: Does not transcode, will save as MPEG2 stream", "heavy: AVC with the same resolution, frame-rate, and interlacing as the original stream", "mobile: AVC progressive not exceeding 1280x720 30fps", "internet720: low bitrate AVC progressive not exceeding 1280x720 30fps", "internet480: low bitrate AVC progressive not exceeding 848x480 30fps for 16:9 content, not exceeding 640x480 30fps for 4:3 content", "internet360: low bitrate AVC progressive not exceeding 640x360 30fps for 16:9 content, not exceeding 480x360 30fps for 4:3 content", "internet240: low bitrate AVC progressive not exceeding 432x240 30fps for 16:9 content, not exceeding 320x240 30fps for 4:3 content"} with prompt "Please choose the transcode level on the file" with title my check_version_dialog(caller) default items {"None: Does not transcode, will save as MPEG2 stream"} OK button name "Next" cancel button name Running_icon of Icon_record & " Run")
						try
							set show_transcode of temp_show_info to word 1 of item 1 of show_transcode_response
						on error errmsg
							set show_transcode of temp_show_info to "None"
							my logger(true, handlername, caller, "INFO", "User clicked " & quote & "Run" & quote & ", errmsg: " & errmsg)
							return false
						end try
					else
						set show_transcode of temp_show_info to temp_show_transcode
					end if
				else
					set show_transcode of temp_show_info to "None"
				end if
				set end of temp_show_progress to "Transcode: " & show_transcode of temp_show_info
				set progress additional description to my stringlistflip("add_show_info(" & caller & ")", temp_show_progress, return, "string")
				set progress completed steps to 6
				my logger(true, handlername, caller, "INFO", "(Auto) Transcode: " & show_transcode of temp_show_info)
				set progress description to "Choose Folder..."
				set Temp_dir to alias "Volumes:"
				set update_folder_result to true
				set failed_showdir to {}
				if temp_show_dir is missing value then
					my logger(true, handlername, caller, "TRACE", "Track1")
					repeat until Temp_dir is not alias "Volumes:" and update_folder_result is true
						my logger(true, handlername, caller, "TRACE", "Track2")
						try
							set Temp_dir to show_dir of last item of Show_info
						on error errmsg
							my logger(true, handlername, caller, "TRACE", "Track3")
							set Temp_dir to alias "Volumes:"
						end try
						my logger(true, handlername, caller, "TRACE", "Track4")
						try
							my logger(true, handlername, caller, "TRACE", "Track5")
							if update_folder_result is true then
								my logger(true, handlername, caller, "TRACE", "Track6")
								set show_dir of temp_show_info to choose folder with prompt "Select Show location" default location Temp_dir
							else if update_folder_result is false then
								my logger(true, handlername, caller, "TRACE", "Track7")
								set show_dir of temp_show_info to choose folder with prompt "Unable to write to location:" & return & (failed_showdir as text) & return & "Select another location" default location Temp_dir
							end if
						on error errmsg
							my logger(true, handlername, caller, "TRACE", "Track8")
							--set show_dir of temp_show_info to choose folder with prompt "Unable to write to location:" & return & (failed_showdir as text) & return & "Select another location"
							my logger(true, handlername, caller, "ERROR", "Unable to select show location, errmsg: " & errmsg)
							-- exit repeat
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
				set end of temp_show_progress to "Where: " & POSIX path of show_dir of temp_show_info
				my logger(true, handlername, caller, "INFO", "Show Directory: " & show_dir of temp_show_info)
				set show_temp_dir of temp_show_info to show_dir of temp_show_info
				set maybe_dupe_show to false
				set show_title of temp_show_info to my stringToUtf8("add_show(" & caller & ")", show_title of temp_show_info)
				repeat with i from 1 to length of Show_info
					if show_title of temp_show_info is show_title of item i of Show_info and show_active of item i of Show_info is true then
						my logger(true, handlername, caller, "WARN", show_title of temp_show_info & " may be a dupe")
						set maybe_dupe_show to true
					end if
				end repeat
				if maybe_dupe_show is true then
					set maybe_dupe_show_response to button returned of (display dialog "The show name matches another recording, do you wish to proceed?" buttons {"Abort", "Add Anyways"} default button 1 with title my check_version_dialog(caller) giving up after Dialog_timeout with icon stop)
					if maybe_dupe_show_response is "Abort" then
						my logger(true, handlername, caller, "WARN", show_title of temp_show_info & " is a dupe, and was skipped")
						exit repeat
					end if
				end if
				--commit the temp_show_info to show_info 
				set end of Show_info to temp_show_info
				
				set progress additional description to my stringlistflip("add_show(" & caller & ")", temp_show_progress, return, "string")
				set progress completed steps to 7
				if hdhr_skip_multiple_bool is true then
					set temp_show_air_date to show_air_date of temp_show_info
					set temp_show_dir to show_dir of temp_show_info
					set temp_show_transcode to show_transcode of temp_show_info
					set temp_is_series to show_is_series of temp_show_info
				end if
				
				--end repeat 
				--end if
				my logger(true, handlername, caller, "DEBUG", "Adding temp_show_info to end of show_info, count: " & length of Show_info)
				--display dialog show_id of last item of show_info
				set show_next of last item of Show_info to my nextday("add_show_info(" & caller & ")", show_id of temp_show_info)
				my validate_show_info("add_show_info(" & caller & ")", show_id of last item of Show_info, false)
				my update_show("add_show_info(" & caller & ")", show_id of last item of Show_info, false)
				my save_data("add_show_info(" & caller & ")")
				display notification with title Add_icon of Icon_record & " Show Added! (" & hdhr_device & ")" subtitle "" & quote & show_title of last item of Show_info & quote & " at " & show_time of last item of Show_info
				set progress description to "This show has been added!"
				set end of temp_show_progress to return & "Show: " & quote & show_title of last item of Show_info & quote & " at " & show_time of last item of Show_info
				my delay_idle_loop("add_show_info(" & caller & ")", 1)
				my repeatProgress(0.2, 6)
			end repeat
		end repeat
	else
		return false
	end if
	set hdhr_skip_multiple_bool to false
end add_show_info

on record_now(caller, the_show_id, opt_show_length, force_update)
	set handlername to "record_now"
	-- We should do very little validation here, aside from what is required to start a recording.  Qualifers belong in the code block that called us.
	-- FIX We need to return a true/false if this is successful.  We may be able to do this with showid2PID
	set i to my HDHRShowSearch(the_show_id)
	set temp_show_end to my short_date("rec started", show_end of item i of Show_info, true, false)
	--my update_folder("record_now(" & caller & ")", show_dir of item i of Show_info)
	--my update_show("record_now(" & caller & ")", the_show_id, force_update)
	set hdhr_device to hdhr_record of item i of Show_info
	set tuner_offset to my HDHRDeviceSearch("record_now(" & caller & ")", hdhr_device)
	set fileext to ".mkv"
	if opt_show_length is not missing value then
		set temp_show_length to opt_show_length as number
	else
		set temp_show_length to show_length of item i of Show_info as number
	end if
	
	try
		--fix this might be able to be removed
		if show_is_sport of item i of Show_info is true and 3 is equal to 2 then
			--	if show_is_series of item i of Show_info is false and show_active of item i of Show_info is false then
			my logger(true, handlername, caller, "INFO", show_title of item i of Show_info & "is sport, show_end current: " & show_end of item i of Show_info)
			--set show_end of item i of Show_info to (show_end of item i of Show_info) + (1800)
			set temp_show_date to ((show_end of item i of Show_info) + 1800)
			set temp_show_end to my short_date("rec started", temp_show_date, true, false)
			
			set temp_show_length to ((temp_show_date) - (current date))
			--set temp_show_length to (temp_show_length + (1800)) as number
			--				set show_length of item i of Show_info to temp_show_length
			my logger(true, handlername, caller, "INFO", "Show is sport, show_end now: " & temp_show_end)
			--	end if
		end if
	on error errmsg
		my logger(true, handlername, caller, "ERROR", "is_sport: " & errmsg)
	end try
	
	if temp_show_length is less than 0 then
		my logger(true, handlername, caller, "ERROR", show_title of item i of Show_info & " has a duration of " & temp_show_length & ", deactivating show...")
		set show_active of item i of Show_info to false
	end if
	
	set checkDiskSpace_percent to 0
	set checkDiskSpace_temp to checkDiskSpace("record_now(" & caller & ")", (POSIX path of (show_temp_dir of item i of Show_info))) of LibScript
	set checkDiskSpace_leftKB to item 3 of checkDiskSpace_temp
	set checkDiskSpace_percent to item 2 of checkDiskSpace_temp
	set checkDiskSpace_path to item 1 of checkDiskSpace_temp
	
	if show_fail_count of item i of Show_info is less than Fail_count then
		my update_folder("record_now(" & caller & ")", show_dir of item i of Show_info)
		my update_show("record_now(" & caller & ")", the_show_id, force_update)
		set show_fail_count of item i of Show_info to ((show_fail_count of item i of Show_info) + 1)
		if checkDiskSpace_percent is less than or equal to 95 or checkDiskSpace_leftKB is greater than or equal to 10485760 then
			my logger(true, handlername, caller, "INFO", "Path: " & quote & checkDiskSpace_path & quote & " is " & checkDiskSpace_percent & "% full")
			if show_transcode of item i of Show_info is in {missing value, "None", "none", ""} then
				set show_transcode of item i of Show_info to "none"
				set fileext to ".m2ts"
			end if
			if Local_env is not in Debugger_apps then
				set temp_save_path to (POSIX path of (show_temp_dir of item i of Show_info) & show_title of item i of Show_info & "_" & my short_date("record_now0", current date, true, true) & fileext)
				my logger(true, handlername, caller, "INFO", "caffeinate -i curl -H 'show_id:" & show_id of item i of Show_info & "' -H 'show_end:" & temp_show_end & "' -H 'appname:" & name of me & "' '" & show_url of item i of Show_info & "?duration=" & (temp_show_length) & "&transcode=" & show_transcode of item i of Show_info & "' -o \"" & temp_save_path & "\"> /dev/null 2>&1 &")
				do shell script "caffeinate -i curl -H 'show_id:" & show_id of item i of Show_info & "' -H 'show_end:" & temp_show_end & "' -H 'appname:" & name of me & "' '" & show_url of item i of Show_info & "?duration=" & (temp_show_length) & "&transcode=" & show_transcode of item i of Show_info & "' -o \"" & temp_save_path & "\"> /dev/null 2>&1 &"
				set show_recording of item i of Show_info to true
				set show_recording_path of item i of Show_info to temp_save_path
				my logger(true, handlername, caller, "INFO", "\"" & show_title of item i of Show_info & "\" started recording for " & my ms2time("record_now(" & caller & ")", temp_show_length, "s", 3) & " with transcode profile, " & show_transcode of item i of Show_info)
			else
				my logger(true, handlername, caller, "INFO", "Record function surpressed in DEV")
			end if
		else
			my logger(true, handlername, caller, "The show " & quote & show_title of item i of Show_info & quote & " can not be recorded. " & quote & checkDiskSpace_path & quote & " is " & checkDiskSpace_percent & "& full, max is 95%")
		end if
	else
		if show_fail_count of item i of Show_info is Fail_count then
			my logger(true, handlername, caller, "ERROR", "The show " & quote & show_title of item i of Show_info & quote & " has failed to record multiple times, so we fail here")
			set show_fail_count of item i of Show_info to (show_fail_count of item i of Show_info) + 1
		end if
	end if
	if item 2 of my showid2PID("record_now(" & caller & ")", show_id of item i of Show_info, false, true) is {} and show_fail_count of item i of Show_info is less than Fail_count then
		my logger(true, handlername, caller, quote & show_id of item i of Show_info & quote & " has failed to start recording")
	end if
end record_now

on HDHRShowSearch(the_show_id)
	set handlername to "HDHRShowSearch"
	if length of Show_info is greater than 0 then
		repeat with i from 1 to length of Show_info
			if show_id of item i of Show_info is the_show_id then
				return i
			end if
		end repeat
	end if
	return 0
end HDHRShowSearch

on HDHRDeviceDiscovery(caller, hdhr_device)
	set handlername to "HDHRDeviceDiscovery"
	if hdhr_device is not "" then
		my logger(true, handlername, caller, "DEBUG", "Pre getHDHR_Lineup")
		my getHDHR_Lineup("HDHRDeviceDiscovery(" & caller & ")", hdhr_device)
		my logger(true, handlername, caller, "DEBUG", "Pre getHDHR_Guide")
		my getHDHR_Guide("HDHRDeviceDiscovery(" & caller & ")", hdhr_device)
	else
		set HDHR_DEVICE_LIST to {}
		set progress additional description to "Discovering HDHomeRun Devices"
		set progress completed steps to 0
		my logger(true, handlername, caller, "INFO", "Pre Discovery")
		set hdhr_device_discovery to my hdhr_api("HDHRDeviceDiscovery(" & caller & ")", "https://ipv4-api.hdhomerun.com/discover")
		my logger(true, handlername, caller, "INFO", "Post Discovery, Tuners found: " & length of hdhr_device_discovery)
		set progress total steps to length of hdhr_device_discovery
		repeat with i from 1 to length of hdhr_device_discovery
			repeat 1 times
				--FIX Check for legacy devices, line below mocks it
				--set item i of hdhr_device_discovery to item i of hdhr_device_discovery & {Legacy:1}
				set progress completed steps to i
				try
					set is_legacy to true
					set temp to Legacy of item i of hdhr_device_discovery
					my logger(true, handlername, caller, "WARN", "Unable to add tuner, device is legacy")
				on error errmsg
					set is_legacy to false
				end try
				
				try
					set is_valid to true
					set temp to DeviceID of item i of hdhr_device_discovery
				on error errmsg
					set is_valid to false
					my logger(true, handlername, caller, "WARN", "Unable to add tuner, device has no DeviceID, err: " & errmsg)
				end try
				
				if is_valid is false then
					exit repeat
				end if
				
				try
					set tuner_transcode_temp to Transcode of item i of hdhr_device_discovery
				on error errmsg
					my logger(true, handlername, caller, "WARN", "Unable to determine transcode settings, err: " & errmsg)
					set tuner_transcode_temp to 0
				end try
				
				set end of HDHR_DEVICE_LIST to {hdhr_lineup_update:missing value, hdhr_guide_update:missing value, discover_url:DiscoverURL of item i of hdhr_device_discovery, lineup_url:LineupURL of item i of hdhr_device_discovery, device_id:DeviceID of item i of hdhr_device_discovery, does_transcode:tuner_transcode_temp, hdhr_lineup:missing value, hdhr_guide:missing value, hdhr_model:missing value, channel_mapping:missing value, BaseURL:BaseURL of item i of hdhr_device_discovery, statusURL:(BaseURL of item i of hdhr_device_discovery & "/status.json"), is_active:true, is_active_reason:"Added Tuner on startup"}
				if is_legacy is true then
					my logger(true, handlername, caller, "WARN", hdhr_device & " is a legacy device, so it will be deactivated")
					set is_active of last item of HDHR_DEVICE_LIST to false
					set is_active_reason of last item of HDHR_DEVICE_LIST to "Legacy Device"
				else
					my logger(true, handlername, caller, "INFO", "Tuner " & device_id of last item of HDHR_DEVICE_LIST & " detected")
				end if
			end repeat
		end repeat
		if length of HDHR_DEVICE_LIST is greater than 0 then
			repeat with i2 from 1 to length of HDHR_DEVICE_LIST
				my HDHRDeviceDiscovery("HDHRDeviceDiscovery1(" & caller & ")", device_id of item i2 of HDHR_DEVICE_LIST)
				delay 0.1
			end repeat
			my logger(true, handlername, caller, "INFO", "Completed Guide and Lineup Updates")
			-- my tuner_dump("main")
		else
			try
				activate me
			end try
			set HDHRDeviceDiscovery_none to display dialog "No supported HDHR devices can be found" buttons {"Quit", "Rescan"} default button 2 cancel button 1 with title my check_version_dialog(caller) giving up after Dialog_timeout * 0.5 with icon stop
			if button returned of HDHRDeviceDiscovery_none is "Rescan" then
				my logger(true, handlername, caller, "INFO", "No Devices Added")
				my HDHRDeviceDiscovery("no_devices", "")
			end if
			
			if button returned of HDHRDeviceDiscovery_none is "Quit" then
				if Local_env is not in Debugger_apps then quit {}
			end if
		end if
	end if
	my update_show("HDHRDeviceDiscovery(" & caller & ")", "", true)
end HDHRDeviceDiscovery

on HDHRDeviceSearch(caller, hdhr_device)
	set handlername to "HDHRDeviceSearch"
	repeat with i from 1 to length of HDHR_DEVICE_LIST
		if (device_id of item i of HDHR_DEVICE_LIST as text) is (hdhr_device as text) and is_active of item i of HDHR_DEVICE_LIST is true then
			return i
		end if
	end repeat
	my logger(true, handlername, caller, "WARN ", "No match for " & hdhr_device & " out of " & length of HDHR_DEVICE_LIST & " possible items")
	return 0
end HDHRDeviceSearch

on hdhr_api(caller, hdhr_ready)
	set handlername to "hdhr_api"
	try
		with timeout of 8 seconds
			my logger(true, handlername, caller, "DEBUG", "API call: " & hdhr_ready)
			set hdhr_api_result to (fetch JSON from hdhr_ready with cleaning feed)
			if "JSON" is in Logger_levels and "status" is not in hdhr_ready then
				open location hdhr_ready
				activate me
			end if
			set Hdhr_detected to true
			return hdhr_api_result
		end timeout
	on error errmsg
		my logger(true, handlername, caller, "API timeout, errmsg: " & errmsg & " at " & hdhr_ready)
		set Hdhr_detected to false
		return {}
	end try
end hdhr_api

on getHDHR_Guide(caller, hdhr_device)
	set handlername to "getHDHR_Guide"
	set progress total steps to 1
	set progress completed steps to 0
	set progress additional description to "Guide Refresh: " & hdhr_device
	copy (current date) to cd
	try
		set tuner_offset to my HDHRDeviceSearch("getHDHR_Guide0(" & caller & ")", hdhr_device)
		try
			with timeout of 7 seconds
				set hdhr_discover_temp to my hdhr_api("getHDHR_Guide0(" & caller & ")", discover_url of item tuner_offset of HDHR_DEVICE_LIST)
			end timeout
		on error
			set hdhr_guide_update of item tuner_offset of HDHR_DEVICE_LIST to ((cd) - 45 * minutes)
			set hdhr_discover_temp to missing value
		end try
		if hdhr_discover_temp is not equal to missing value then
			set device_auth to DeviceAuth of hdhr_discover_temp
			set hdhr_model of item tuner_offset of HDHR_DEVICE_LIST to ModelNumber of hdhr_discover_temp
			set hdhr_update to ""
			try
				set hdhr_update to UpgradeAvailable of hdhr_discover_temp
			on error
				set hdhr_update to false
			end try
			
			if hdhr_update is not false then
				display notification "" with title "Firmware Update Available" subtitle hdhr_model of item tuner_offset of HDHR_DEVICE_LIST & " is ready to update"
			end if
			set hdhr_guide_data to my hdhr_api("getHDHR_Guide1(" & caller & ")", "http://api.hdhomerun.com/api/guide.php?DeviceAuth=" & device_auth)
			set hdhr_guide of item tuner_offset of HDHR_DEVICE_LIST to hdhr_guide_data
			set hdhr_guide_update of item tuner_offset of HDHR_DEVICE_LIST to cd
			my logger(true, handlername, caller, "INFO", "Updated Guide for " & hdhr_device)
			set progress completed steps to 1
		end if
	on error errmsg
		set progress completed steps to -1
		set progress additional description to "ERROR on Guide Refresh: " & hdhr_device
		my logger(true, handlername, caller, "ERROR", "ERROR on Guide Refresh: " & hdhr_device & ", will retry in 10 seconds, errmsg: " & errmsg)
	end try
end getHDHR_Guide

on add_record_url(caller, the_channel, the_device)
	set handlername to "add_record_url"
	try
		set tuner_offset to my HDHRDeviceSearch("add_record_url(" & caller & ")", the_device)
		set hdhr_lineup_temp to hdhr_lineup of item tuner_offset of HDHR_DEVICE_LIST
		repeat with i from 1 to length of hdhr_lineup_temp
			if GuideNumber of item i of hdhr_lineup_temp is the_channel then
				set temp_channel to |url| of item i of hdhr_lineup_temp
				my logger(true, handlername, caller, "INFO", temp_channel)
				return temp_channel
			end if
		end repeat
	on error errmsg
		my logger(true, handlername, caller, "WARN", "err, " & errmsg)
	end try
	--return false
end add_record_url

on getHDHR_Lineup(caller, hdhr_device)
	set handlername to "getHDHR_Lineup"
	--FIX This should grab the URL in the lineup when recording 
	set progress total steps to 1
	set progress completed steps to 0
	set progress additional description to "LineUP Refresh: " & hdhr_device
	set tuner_offset to my HDHRDeviceSearch("getHDHR_Lineup0(" & caller & ")", hdhr_device)
	try
		with timeout of 7 seconds
			set hdhr_lineup of item tuner_offset of HDHR_DEVICE_LIST to my hdhr_api("getHDHR_Lineup(" & caller & ")", lineup_url of item tuner_offset of HDHR_DEVICE_LIST)
		end timeout
	on error errmsg
		my logger(true, handlername, caller, "ERROR", errmsg)
		set hdhr_lineup of item tuner_offset of HDHR_DEVICE_LIST to missing value
	end try
	if hdhr_lineup of item tuner_offset of HDHR_DEVICE_LIST is not in {"", {}, missing value} then
		set hdhr_lineup_update of item tuner_offset of HDHR_DEVICE_LIST to current date
		my logger(true, handlername, caller, "INFO", "Updated Lineup for " & hdhr_device)
		set progress completed steps to 1
		delay 0.1
	else
		my logger(true, handlername, caller, "ERROR", "Unable to update lineup for " & hdhr_device)
	end if
end getHDHR_Lineup

on channel_guide(caller, hdhr_device, hdhr_channel, hdhr_time)
	set handlername to "channel_guide"
	my logger(true, handlername, caller, "INFO", "hdhr_device: " & hdhr_device & ", hdhr_channel: " & hdhr_channel & ", hdhr_time: " & hdhr_time)
	copy (current date) to cd
	set Time_slide to 0
	set tuner_offset to my HDHRDeviceSearch("channel_guide0(" & caller & ")", hdhr_device)
	my logger(true, handlername, caller, "DEBUG", "tuner_offset: " & tuner_offset)
	set temp_guide_data to missing value
	if hdhr_time is not "" then
		if (hdhr_time + 1) is less than hours of (cd) then
			set Time_slide to 1
		end if
		set hdhr_proposed_time to my datetime2epoch("channel_guide(" & caller & ")", (date (date string of ((cd) + Time_slide * days))) + hdhr_time * hours - (time to GMT)) as number
		set hdhr_proposed_time to my getTfromN(hdhr_proposed_time)
		my logger(true, handlername, caller, "DEBUG", "hdhr_proposed_time2: " & my epoch2show_time("channel_guide(" & caller & ")", hdhr_proposed_time))
	end if
	if HDHR_DEVICE_LIST is not in {missing value, {}, 0, ""} then
		repeat with i from 1 to length of hdhr_guide of item tuner_offset of HDHR_DEVICE_LIST
			if hdhr_channel is GuideNumber of item i of hdhr_guide of item tuner_offset of HDHR_DEVICE_LIST then
				set temp_guide_data to item i of hdhr_guide of item tuner_offset of HDHR_DEVICE_LIST --as record
			end if
		end repeat
		if temp_guide_data is missing value then
			--FIX We have no guide data, as the channel does not provide them, but we can mock the dtaa, so we can record for a period of time.
			if channel2name("channel_guide(" & caller & ")", hdhr_channel, hdhr_device) is not false then
				--We have a show on the lineup, but contains no guide data
				my logger(true, handlername, caller, "INFO", "Show is in lineup, but no guide data")
			end if
			display notification with title Stop_icon of Icon_record & "Channel unavailable ..." subtitle hdhr_channel & " no longer exists on " & hdhr_device & ", exiting..."
			set Back_channel to hdhr_channel
			my logger(true, handlername, caller, "ERROR", hdhr_channel & " no longer exists on " & hdhr_device & ", exiting...")
			my main("channel_gone(" & caller & ")", "Add")
			return false
		end if
		if hdhr_time is "" then
			return temp_guide_data as record
		end if
		repeat with i2 from 1 to length of Guide of temp_guide_data
			if (hdhr_proposed_time) is greater than or equal to my getTfromN(StartTime of item i2 of Guide of temp_guide_data) and (hdhr_proposed_time) is less than my getTfromN(EndTime of item i2 of Guide of temp_guide_data) then
				try
					return item i2 of Guide of temp_guide_data
				on error
					my logger(true, handlername, caller, "ERROR", "Unable to match a show " & i2)
				end try
			end if
		end repeat
	else
		my logger(true, handlername, caller, "ERROR", "HDHR_DEVICE_LIST has an empty value")
	end if
	return {}
end channel_guide

on update_show(caller, the_show_id, force_update)
	set handlername to "update_show"
	if the_show_id is "" then
		repeat with i2 from 1 to length of Show_info
			my update_show("update_show" & my padnum("update_show", i2, false) & "(" & caller & ")", show_id of item i2 of Show_info, false)
		end repeat
	else
		set show_offset to my HDHRShowSearch(the_show_id)
		set progress description to "Updating Show: " & show_title of item show_offset of Show_info
		set progress total steps to 7
		set time2show_next to (show_next of item show_offset of Show_info) - (current date)
		set progress additional description to "Updating Show: " & show_title of item show_offset of Show_info
		if time2show_next is less than or equal to 6 * hours and time2show_next is greater than or equal to -60 and show_active of item show_offset of Show_info is true or force_update is true then
			my logger(true, handlername, caller, "INFO", "Updating \"" & show_title of item show_offset of Show_info & "\" " & the_show_id & "...")
			set hdhr_response_channel to {}
			set hdhr_response_channel to my channel_guide("update_shows(" & caller & ")", hdhr_record of item show_offset of Show_info, show_channel of item show_offset of Show_info, show_time of item show_offset of Show_info)
			try
			on error errmsg
				my logger(true, handlername, caller, "errmsg", errmsg)
			end try
			set progress completed steps to 1
			--	try
			if length of hdhr_response_channel is greater than 0 then
				
				try
					set hdhr_response_channel_title to title of hdhr_response_channel
				on error errmsg
					my logger(true, handlername, caller, "DEBUG", "Unable to set title of show name, ")
				end try
				
				try
					set hdhr_response_channel_title to hdhr_response_channel_title & " " & EpisodeNumber of hdhr_response_channel
				on error errmsg
					my logger(true, handlername, caller, "DEBUG", "Unable to set EpisodeNumber of " & quote & hdhr_response_channel_title & quote & ", errmsg: " & errmsg)
				end try
				
				try
					set hdhr_response_channel_title to hdhr_response_channel_title & " " & EpisodeTitle of hdhr_response_channel
				on error errmsg
					my logger(true, handlername, caller, "DEBUG", "Unable to set EpisodeTitle of " & quote & hdhr_response_channel_title & quote & ", errmsg: " & errmsg)
				end try
				
				try
					set show_seriesid of item show_offset of Show_info to seriesID of hdhr_response_channel
				on error errmsg
					my logger(true, handlername, caller, "DEBUG", "Unable to set show_seriesid, errmsg: " & errmsg)
				end try
				
				try
					set show_tags of item show_offset of Show_info to Filter of hdhr_response_channel
				on error errmsg
					my logger(true, handlername, caller, "DEBUG", "Unable to set show_tags, errmsg: " & errmsg)
				end try
				
				try
					set show_logo_url of item show_offset of Show_info to (ImageURL of hdhr_response_channel as text)
				on error errmsg
					my logger(true, handlername, caller, "WARN", "Unable to set ImageURL, errmsg: " & errmsg)
				end try
				
				set progress completed steps to 2
				if show_title of item show_offset of Show_info is not equal to hdhr_response_channel_title then
					my logger(true, handlername, caller, "INFO", "Title changed from " & quote & show_title of item show_offset of Show_info & quote & " to " & quote & hdhr_response_channel_title & quote)
					set show_title of item show_offset of Show_info to my stringToUtf8("update_shows(" & caller & ")", hdhr_response_channel_title)
				end if
				set progress completed steps to 3
				try
					if show_is_sport of item show_offset of Show_info is false then
						if (show_length of item show_offset of Show_info as number) is not equal to (((EndTime of hdhr_response_channel) - (StartTime of hdhr_response_channel)) div 60 as number) then
							my logger(true, handlername, caller, "INFO", "Show length changed to " & ((EndTime of hdhr_response_channel) - (StartTime of hdhr_response_channel)) div 60 & " minutes")
						end if
						set show_length of item show_offset of Show_info to ((EndTime of hdhr_response_channel) - (StartTime of hdhr_response_channel)) div 60
					end if
				on error errmsg
					my logger(true, handlername, caller, "Unable to set length of " & show_title of item show_offset of Show_info & ", errmsg: " & errmsg)
				end try
				
				set progress completed steps to 4
				try
					set temp_show_time to my epoch2show_time("hdhrGRID(" & caller & ")", my getTfromN((StartTime of hdhr_response_channel)))
					
					if (temp_show_time as number) is not equal to (show_time of item show_offset of Show_info as number) then
						my logger(true, handlername, caller, "INFO", "Show time changed from " & show_time of item show_offset of Show_info & " to " & temp_show_time)
						set show_time of item show_offset of Show_info to my epoch2show_time("hdhrGRID(8)", my getTfromN((StartTime of hdhr_response_channel)))
						
						set show_next of item show_offset of Show_info to my nextday("update_show(" & caller & ")", show_id of item show_offset of Show_info)
						--We may be to run next_day logic  
					end if
				on error errmsg
					my logger(true, handlername, caller, "ERROR", "Unable to set show_time for this show, error: " & errmsg)
				end try
				set progress completed steps to 5
				try
					--	if show_is_sport of item show_offset of Show_info is false then
					if (show_next of item show_offset of Show_info) + ((show_length of item show_offset of Show_info) * minutes) is not equal to show_end of item show_offset of Show_info then
						set show_end of item show_offset of Show_info to (show_next of item show_offset of Show_info) + ((show_length of item show_offset of Show_info) * minutes)
						--display notification "Show Updated: " & show_title of item i of show_info
						my logger(true, handlername, caller, "INFO", "Show end changed to " & show_end of item show_offset of Show_info)
					end if
				on error errmsg
					my logger(true, handlername, caller, "ERROR", "Unable to set show_time for this show, error: " & errmsg)
				end try
				try
					if show_url of item show_offset of Show_info is in {"", "?", false, "false"} then
						my logger(true, handlername, caller, "WARN", "show_url is invalid, updating...")
						set show_url of item show_offset of Show_info to my add_record_url("record_now(" & caller & ")", show_channel of item show_offset of Show_info, hdhr_record of item show_offset of Show_info)
					end if
				on error errmsg
					my logger(true, handlername, caller, "WARN", "Unable to update show_url of " & show_title of item show_offset of Show_info & ", errmsg: " & errmsg)
				end try
			end if
			set progress completed steps to 7
		else
			my logger(true, handlername, caller, "DEBUG", "Did not update the show " & show_title of item show_offset of Show_info & ", next_show in " & my ms2time("update_show1", ((show_next of item show_offset of Show_info) - (current date)), "s", 4))
		end if
	end if
end update_show

on save_data(caller)
	set handlername to "save_data"
	my logger(true, handlername, caller, "INFO", "Called")
	copy Show_info to temp_show_info
	if Local_env is not in Debugger_apps then
		--if Local_env does not contain "Editor" or Local_env does not contain "Debugger" then
		my show_info_dump("save_data(" & caller & ")", "", false)
	else
		my logger(true, handlername, caller, "INFO", "save_data(" & caller & ") not run, we are in DEBUG mode")
		return true
	end if
	set deleted_show_count to 0
	try
		if length of Show_info is greater than 0 then
			repeat with i5 from 1 to length of temp_show_info
				if show_active of item i5 of temp_show_info is true then
					set show_dir of item i5 of temp_show_info to (show_dir of item i5 of temp_show_info as text)
					set show_temp_dir of item i5 of temp_show_info to (show_temp_dir of item i5 of temp_show_info as text)
					
					set show_length of item i5 of temp_show_info to (show_length of item i5 of temp_show_info as number)
					set show_air_date of item i5 of temp_show_info to (show_air_date of item i5 of temp_show_info)
					set show_title of item i5 of temp_show_info to (show_title of item i5 of temp_show_info as text)
					set show_time of item i5 of temp_show_info to (show_time of item i5 of temp_show_info as number)
					set show_channel of item i5 of temp_show_info to (show_channel of item i5 of temp_show_info as text)
					
					try
						set show_seriesid of item i5 of temp_show_info to (show_seriesid of item i5 of temp_show_info as text)
					on error errmsg
						set item i5 of temp_show_info to item i5 of temp_show_info & {show_seriesid:""}
						my logger(true, handlername, caller, "INFO", "Added SeriesID to " & quote & show_title of item i5 of temp_show_info & quote)
					end try
					
					try
						set show_time_orig of item i5 of temp_show_info to (show_time_orig of item i5 of temp_show_info)
					on error errmsg
						set item i5 of temp_show_info to item i5 of temp_show_info & {show_time_orig:show_time of item i5 of temp_show_info as number}
						my logger(true, handlername, caller, "INFO", "Added show_time_orig to " & quote & show_title of item i5 of temp_show_info & quote)
					end try
					
					try
						set show_recorded_today of item i5 of temp_show_info to (show_recorded_today of item i5 of temp_show_info)
					on error errmsg
						set item i5 of temp_show_info to item i5 of temp_show_info & {show_recorded_today:false}
						my logger(true, handlername, caller, "INFO", "Added show_recorded_today to " & quote & show_title of item i5 of temp_show_info & quote)
					end try
					
					
					try
						set show_tags of item i5 of temp_show_info to show_tags of item i5 of temp_show_info as text
					on error errmsg
						set item i5 of temp_show_info to item i5 of temp_show_info & {show_tags:{}}
						my logger(true, handlername, caller, "INFO", "Added show_tags to " & quote & show_title of item i5 of temp_show_info & quote)
					end try
					
					try
						set show_is_sport of item i5 of temp_show_info to show_is_sport of item i5 of temp_show_info
					on error errmsg
						set item i5 of temp_show_info to item i5 of temp_show_info & {show_is_sport:false}
						my logger(true, handlername, caller, "INFO", "Added show_is_sport to " & quote & show_title of item i5 of temp_show_info & quote)
					end try
					
					try
						set show_recording_path of item i5 of temp_show_info to (show_recording_path of item i5 of temp_show_info)
					on error errmsg
						set item i5 of temp_show_info to item i5 of temp_show_info & {show_recording_path:""}
						my logger(true, handlername, caller, "INFO", "Added show_recording_path to " & quote & show_title of item i5 of temp_show_info & quote)
					end try
					
					try
						set show_logo_url of item i5 of temp_show_info to (show_logo_url of item i5 of temp_show_info)
					on error errmsg
						my logger(true, handlername, caller, "INFO", errmsg)
						set item i5 of temp_show_info to item i5 of temp_show_info & {show_logo_url:""}
						my logger(true, handlername, caller, "INFO", "Added show_logo_url to " & quote & show_title of item i5 of temp_show_info & quote)
					end try
					
					try
						set show_url of item i5 of temp_show_info to (show_url of item i5 of temp_show_info)
					on error errmsg
						my logger(true, handlername, caller, "WARN", errmsg)
						set item i5 of temp_show_info to item i5 of temp_show_info & {show_url:""}
						my logger(true, handlername, caller, "INFO", "Added show_url to " & quote & show_title of item i5 of temp_show_info & quote)
					end try
					
					try
						set show_last of item i5 of temp_show_info to my fixDate("save_data_json(" & caller & ")", (show_last of item i5 of temp_show_info))
					on error errmsg
						my logger(true, handlername, caller, "WARN", errmsg)
						set item i5 of temp_show_info to item i5 of temp_show_info & {show_last:""}
						my logger(true, handlername, caller, "INFO", "Added show_last to " & quote & show_title of item i5 of temp_show_info & quote)
					end try
					try
						set show_next of item i5 of temp_show_info to my fixDate("save_data_json(" & caller & ")", (show_next of item i5 of temp_show_info))
					on error errmsg
						my logger(true, handlername, caller, "WARN", errmsg)
						set item i5 of temp_show_info to item i5 of temp_show_info & {show_next:""}
						my logger(true, handlername, caller, "INFO", "Added show_next to " & quote & show_title of item i5 of temp_show_info & quote)
					end try
					try
						set show_end of item i5 of temp_show_info to my fixDate("save_data_json(" & caller & ")", (show_end of item i5 of temp_show_info))
					on error errmsg
						my logger(true, handlername, caller, "WARN", errmsg)
						set item i5 of temp_show_info to item i5 of temp_show_info & {show_end:""}
						my logger(true, handlername, caller, "INFO", "Added show_end to " & quote & show_title of item i5 of temp_show_info & quote)
					end try
					
					try
						set notify_recording_time of item i5 of temp_show_info to my fixDate("save_data_json(" & caller & ")", (notify_recording_time of item i5 of temp_show_info))
					on error errmsg
						my logger(true, handlername, caller, "WARN", errmsg)
						set item i5 of temp_show_info to item i5 of temp_show_info & {notify_recording_time:""}
						my logger(true, handlername, caller, "INFO", "Added notify_recording_time to " & quote & show_title of item i5 of temp_show_info & quote)
					end try
					
					try
						set notify_upnext_time of item i5 of temp_show_info to my fixDate("save_data_json(" & caller & ")", (notify_upnext_time of item i5 of temp_show_info))
					on error errmsg
						my logger(true, handlername, caller, "WARN", errmsg)
						set item i5 of temp_show_info to item i5 of temp_show_info & {notify_upnext_time:""}
						my logger(true, handlername, caller, "INFO", "Added notify_upnext_time to " & quote & show_title of item i5 of temp_show_info & quote)
					end try
					
					try
						set show_fail_count of item i5 of temp_show_info to show_fail_count of item i5 of temp_show_info
					on error errmsg
						my logger(true, handlername, caller, "WARN", errmsg)
						set item i5 of temp_show_info to item i5 of temp_show_info & {show_fail_count:0}
						my logger(true, handlername, caller, "INFO", "Added show_fail_count to " & quote & show_title of item i5 of temp_show_info & quote)
					end try
					
					try
						set show_use_seriesid of item i5 of temp_show_info to show_use_seriesid of item i5 of temp_show_info
					on error errmsg
						my logger(true, handlername, caller, "WARN", errmsg)
						set item i5 of temp_show_info to item i5 of temp_show_info & {show_use_seriesid:false}
						my logger(true, handlername, caller, "INFO", "Added show_use_seriesid to " & quote & show_title of item i5 of temp_show_info & quote)
					end try
					
					try
						set show_use_seriesid_all of item i5 of temp_show_info to show_use_seriesid_all of item i5 of temp_show_info
					on error errmsg
						my logger(true, handlername, caller, "WARN", errmsg)
						set item i5 of temp_show_info to item i5 of temp_show_info & {show_use_seriesid_all:false}
						my logger(true, handlername, caller, "INFO", "Added show_use_seriesid_all to " & quote & show_title of item i5 of temp_show_info & quote)
					end try
					
					
					
				else
					set deleted_show_count to deleted_show_count + 1
					set temp_title to show_title of item i5 of temp_show_info
					set item i5 of temp_show_info to ""
					my logger(true, handlername, caller, "INFO", "JSON: Removed " & quote & temp_title & quote & ", as it was deactivated")
				end if
				
			end repeat
			set temp_show_info to my emptylist(temp_show_info)
			--	set temp_show_info_json to (make JSON from temp_show_info)
			try
				try
					set ref_num to open for access file ((Config_dir) & Configfilename_json as text) with write permission
				on error errmsg
					my logger(true, handlername, caller, "FATAL", "Error reading the file, errmsg: " & errmsg)
				end try
				set eof of ref_num to 0
				set json_temp to {the_shows:temp_show_info, config:Hdhr_config}
				try
					set temp_show_info_json to (make JSON from json_temp)
				on error errmsg
					my logger(true, handlername, caller, "FATAL", "Error convert the file to JSON, errmsg: " & errmsg)
				end try
				if temp_show_info_json is "" then
					my logger(true, handlername, caller, "FATAL", "Error when attempting to save show list. Trying to recover")
					set json_temp to {the_shows:temp_show_info, config:{}}
					set temp_show_info_json to (make JSON from json_temp)
				end if
				my logger(true, handlername, caller, "TRACE", temp_show_info_json)
				write temp_show_info_json to ref_num
				my logger(true, handlername, caller, "INFO", "Saved " & length of Show_info & " shows to file, removed " & deleted_show_count & " shows")
			on error errmsg
				my logger(true, handlername, caller, "FATAL", "Unable to save JSON file: " & errmsg)
			end try
		else
			my logger(true, handlername, caller, "INFO", "No shows to save")
			return false
		end if
	on error errmsg
		my logger(true, handlername, caller, "FATAL", "Unable to save JSON file: " & errmsg)
		try
			set save_data_oops to button returned of (display dialog "We ran into an error when attempting to save the config file" & return & quote & errmsg & quote & return & return & "What would you like to do?" buttons {"Save Again", "Exit without saving"} with title my check_version_dialog(caller) giving up after Dialog_timeout with icon caution)
			if save_data_oops is "Save Again" then
				my save_data("save_data_retry(" & caller & ")")
				return
			end if
			if save_data_oops is "Exit without saving" then
				return false
			end if
		on error errmsg
			my logger(true, handlername, caller, "FATAL", "Much uh oh.  We errored out of another error, errmsg: " & errmsg)
		end try
	end try
	try
		close access ref_num
	on error errmsg
		my logger(true, handlername, caller, "ERROR", "We attempted to close a handler that was not open, the save likely failed")
	end try
end save_data

on showPathVerify(caller, show_id)
	set handlername to "showPathVerify"
	if show_id is "" then
		repeat with i3 from 1 to (length of Show_info)
			my showPathVerify("showPathVerify(" & caller & ")", show_id of item i3 of Show_info)
		end repeat
	else
		set show_offset to my HDHRShowSearch(show_id)
		try
			if my checkfileexists("showPathVerify(" & caller & ")", show_dir of item show_offset of Show_info) is false then
				my logger(true, handlername, caller, "WARN", "The show, " & show_title of item show_offset of Show_info & " has a invalid save directory")
			else
				my logger(true, handlername, caller, "DEBUG", "The show, " & show_title of item show_offset of Show_info & " has a valid save directory")
			end if
		on error errmsg
			my logger(true, handlername, caller, "ERROR", "An error occured, errmsg: " & errmsg)
		end try
	end if
end showPathVerify

on checkfileexists(caller, filepath)
	set handlername to "checkfileexists"
	try
		my logger(true, handlername, caller, "DEBUG", filepath as text)
		--if class of filepath is not Çclass furlÈ then
		if class of filepath is not alias then
			my logger(true, handlername, caller, "INFO", "filepath class is " & class of filepath)
			set filepath to POSIX file filepath
			my logger(true, handlername, caller, "DEBUG", "filepath is now posix file")
		end if
		tell application "Finder" to return (exists filepath)
	on error errmsg
		my logger(true, handlername, caller, "ERROR", "Finder reported: " & errmsg)
		return false
	end try
end checkfileexists

on read_data(caller)
	set handlername to "read_data"
	set hdhr_vcr_config_file to ((Config_dir) & Configfilename_json as text)
	set ref_num to open for access hdhr_vcr_config_file
	try
		set hdhr_vcr_config_data to read ref_num
		set show_info_json to (read JSON from hdhr_vcr_config_data)
		set Show_info to the_shows of show_info_json
		set Hdhr_config to config of show_info_json
		--Try and load the config stuff, and erro gracefully if this fails.
		try
			my logger(true, handlername, caller, "INFO", "Config version: " & Config_version of Hdhr_config)
			
		on error errmsg
			
		end try
		my logger(true, handlername, caller, "INFO", "Loading config from \"" & POSIX path of hdhr_vcr_config_file & "\"...")
		repeat with i5 from 1 to length of Show_info
			try
				set show_dir of item i5 of Show_info to (show_dir of item i5 of Show_info as alias)
				set show_temp_dir of item i5 of Show_info to (show_temp_dir of item i5 of Show_info as alias)
			on error errmsg
				set show_dir of item i5 of Show_info to {}
				set show_temp_dir of item i5 of Show_info to {}
				my logger(true, handlername, caller, "ERROR", "A show has an invalid directory, " & errmsg)
				exit repeat
			end try
			try
				set show_fail_count of item i5 of Show_info to 0
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
				my logger(true, handlername, caller, "WARN", "Unable to change class of notify_recording_time, err: " & errmsg)
			end try
			
			
			try
				if notify_upnext_time of item i5 of Show_info is "missing value" then
					set notify_upnext_time of item i5 of Show_info to missing value
				end if
			on error errmsg
				my logger(true, handlername, caller, "WARN", "Unable to change class of notify_upnext_time, err: " & errmsg)
			end try
			
			try
				if show_is_sport of item i5 of Show_info is "false" then
					set show_is_sport of item i5 of Show_info to false
				end if
				if show_is_sport of item i5 of Show_info is "true" then
					set show_is_sport of item i5 of Show_info to true
				end if
			on error errmsg
				my logger(true, handlername, caller, "WARN", "Unable to change class of show_is_sport, err: " & errmsg)
			end try
			
			try
				if show_recorded_today of item i5 of Show_info is "false" then
					set show_recorded_today of item i5 of Show_info to false
				end if
				if show_recorded_today of item i5 of Show_info is "true" then
					set show_recorded_today of item i5 of Show_info to true
				end if
			on error errmsg
				my logger(true, handlername, caller, "WARN", "Unable to change class of show_recorded_today, err: " & errmsg)
			end try
			
		end repeat
	on error errmsg
		my logger(true, handlername, caller, "FATAL", "Unable to read file, err: " & errmsg)
	end try
	close access ref_num
	my validate_show_info("read_data(" & caller & ")", "", false)
end read_data

on recordingnow_main(caller)
	set handlername to "recordingnow_main"
	my logger(true, handlername, caller, "INFO", "Called")
	copy (current date) to cd
	set recording_now_final to {}
	if length of Show_info is greater than 0 then
		repeat with i from 1 to length of Show_info
			if show_recording of item i of Show_info is true then
				if show_is_sport of item i of Show_info is true then
					set recording_end to my ms2time("recording_now(" & caller & ")", ((show_end of item i of Show_info) + 1800) - (cd), "s", 3)
				else
					set recording_end to my ms2time("recording_now(" & caller & ")", (show_end of item i of Show_info) - (cd), "s", 3)
				end if
				if show_is_series of item i of Show_info is true then
					if length of show_air_date of item i of Show_info is 1 then
						set end of recording_now_final to (Series1_icon of Icon_record & " " & show_title of item i of Show_info & " on " & show_channel of item i of Show_info & " (" & recording_end & " left)")
					else
						set end of recording_now_final to (Series_icon of Icon_record & " " & show_title of item i of Show_info & " on " & show_channel of item i of Show_info & " (" & recording_end & " left)")
					end if
				else
					set end of recording_now_final to (Single_icon of Icon_record & " " & show_title of item i of Show_info & " on " & show_channel of item i of Show_info & " (" & recording_end & " left)")
				end if
			end if
		end repeat
		if recording_now_final is {} then
			return ("No Shows Recording")
		end if
		return (Record_icon of Icon_record & " Recording" & return & my stringlistflip("recording_now(" & caller & ")", recording_now_final, return, "string")) as text
	else
		my logger(true, handlername, caller, "INFO", "No Shows")
		return ("Recording: None")
	end if
	my logger(true, handlername, caller, "INFO", "No Shows Setup")
	return ("Recording: ?")
end recordingnow_main

on next_shows(caller)
	set handlername to "next_shows"
	my logger(true, handlername, caller, "INFO", "Called")
	copy (current date) to cd
	set error_show_list to {}
	set soonest_show to 9999999
	set soonest_show_time to cd
	repeat with i from 1 to length of Show_info
		if ((show_next of item i of Show_info) - (cd)) is less than soonest_show and show_next of item i of Show_info is greater than (cd) and show_active of item i of Show_info is true then
			set soonest_show_time to show_next of item i of Show_info
			set soonest_show to ((show_next of item i of Show_info) - (cd))
		end if
		--use loop to gather info about shows not recording correctly
		if ((show_next of item i of Show_info) - (cd)) is less than 0 and show_recording of item i of Show_info is false and show_active of item i of Show_info is true then
			set end of error_show_list to Warning_icon of Icon_record & " " & show_title of item i of Show_info & " on channel " & show_channel of item i of Show_info
		end if
	end repeat
	my logger(true, handlername, caller, "INFO", "Soonest: " & soonest_show & ": 9999999")
	if soonest_show is less than 9999999 then
		set next_shows_final to {}
		repeat with i2 from 1 to length of Show_info
			--build show_end time
			try
				set temp_show_end to items 2 thru end of my stringlistflip("next_shows(" & caller & ")", my short_date("next_shows(" & caller & ")", show_end of item i2 of Show_info, false, false), " ", "list")
			on error errmsg
				my logger(true, handlername, caller, "WARN", "Error when calculating show_end")
				--choose from list temp_show_end
				set temp_show_end to {"ERROR", "ERROR", "ERROR", "ERROR"}
			end try
			if show_next of item i2 of Show_info is soonest_show_time and show_active of item i2 of Show_info is true then
				
				my short_date("next_shows(" & caller & ")", show_end of item i of Show_info, false, false)
				if show_is_series of item i2 of Show_info is true then
					if length of show_air_date of item i2 of Show_info is 1 then
						set end of next_shows_final to (Series1_icon of Icon_record & " " & show_title of item i2 of Show_info & " on channel " & show_channel of item i2 of Show_info & " until " & temp_show_end)
					else
						set end of next_shows_final to (Series_icon of Icon_record & " " & show_title of item i2 of Show_info & " on channel " & show_channel of item i2 of Show_info & " until " & temp_show_end)
					end if
				else
					set end of next_shows_final to (Single_icon of Icon_record & " " & show_title of item i2 of Show_info & " on channel " & show_channel of item i2 of Show_info & " until " & temp_show_end)
				end if
			end if
		end repeat
		return {soonest_show_time, next_shows_final, error_show_list}
	else
		return {soonest_show_time, "Nope!", error_show_list}
	end if
end next_shows

##########    These are custom handlers.  They are more like libraries    ##########

on curl2icon(caller, thelink)
	set handlername to "curl2icon"
	try
		set savename to last item of my stringlistflip("curl2icon(" & caller & ")", thelink, "/", "list")
	on error errmsg
		my logger(true, handlername, caller, "WARN", "Unable to image, providing default image")
		return caution
	end try
	try
		set temp_path to POSIX path of (path to home folder) & "Library/Caches/hdhr_VCR/" & savename as text
		if my checkfileexists("curl2icon(" & caller & ")", temp_path) is true then
			my logger(true, handlername, caller, "DEBUG", "File exists")
			try
				do shell script "touch " & temp_path
			on error errmsg
				my logger(true, handlername, caller, "WARN", "Unable to update date modified of " & savename)
			end try
		else
			do shell script "curl --silent -H 'appname:" & name of me & "' '" & thelink & "' -o '" & temp_path & "'"
			set temp_path_type to (do shell script "file -Ib " & temp_path)
			if temp_path_type does not contain "image" then
				my logger(true, handlername, caller, "WARN", "Icon is not an image, defaulting to alert icon")
				do shell script "rm " & temp_path
				return caution
			end if
			my logger(true, handlername, caller, "INFO", "File does not exist: " & quote & temp_path & quote & ", creating")
			my logger(true, handlername, caller, "INFO", "New icon is " & temp_path_type)
		end if
		return POSIX file temp_path
	on error errmsg
		my logger(true, handlername, caller, "ERROR", "curl --silent -H 'appname:" & name of me & "' '" & thelink & "' -o '" & temp_path & "'")
		return caution
	end try
end curl2icon

on showid2PID(caller, show_id, kill_pid, logging)
	set handlername to "showid2PID"
	set showid2PID_result to false
	set showid2PID_perline to {}
	my logger(true, handlername, caller, "DEBUG", show_id & " " & kill_pid & " " & logging)
	--add var to capture command, so we can echo, and use it.
	if show_id is "" then
		repeat with i from 1 to length of Show_info
			my showid2PID("showid2PID_" & i & "(" & caller & ")", show_id of item i of Show_info, kill_pid, logging)
		end repeat
	else
		set show_offset to my HDHRShowSearch(show_id)
		if show_offset is greater than 0 then
			try
				my logger(true, handlername, caller, "DEBUG", "ps -Aa|grep " & show_id & "|grep -v 'grep\\|caffeinate'")
				set showid2PID_result to do shell script "ps -Aa|grep " & show_id & "|grep -v 'grep\\|caffeinate'"
			on error errmsg
				my logger(true, handlername, caller, "DEBUG", show_title of item show_offset of Show_info & ", err: " & errmsg)
				return {show_id, {}}
			end try
			set showid2PID_data_parsed to my stringlistflip("showid2PID(" & caller & ")", showid2PID_result, return, "list")
			if length of showid2PID_data_parsed is greater than 0 then
				repeat with i from 1 to length of showid2PID_data_parsed
					set end of showid2PID_perline to word 1 of item i of showid2PID_data_parsed
					if kill_pid is true then
						set show_recording of item show_offset of Show_info to false
						do shell script "kill " & word 1 of item i of showid2PID_data_parsed
						my logger(true, handlername, caller, "INFO", "The show " & show_id & " has a PID of " & word 1 of item i of showid2PID_data_parsed & ", and was killed")
						display notification with title Stop_icon of Icon_record & " Recording Stopped! (" & hdhr_record of item show_offset of Show_info & ")" subtitle "" & quote & show_title of item show_offset of Show_info & quote & " at " & show_time of item show_offset of Show_info
					else
						if logging is true then
							my logger(true, handlername, caller, "INFO", "The show " & show_id & " has a PID of " & word 1 of item i of showid2PID_data_parsed)
						end if
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
	set handlername to "rotate_logs"
	set filepath to POSIX path of filepath
	set progress description to "Rotated log to " & Loglines_max & " lines"
	set progress additional description to filepath
	set progress total steps to 0
	set progress completed steps to -1
	delay 0.1
	try
		if length of Show_info is not 0 then
			set Loglines_max to 500 + ((length of Show_info) * 100)
			do shell script "tail -n " & Loglines_max & " '" & filepath & "'>" & filepath & ".temp;mv '" & filepath & ".temp' '" & filepath & "'"
			set progress completed steps to 1
			my logger(true, handlername, caller, "INFO", "Log file " & filepath & " rotated to " & Loglines_max & " lines")
		else
			my logger(true, handlername, caller, "WARN", "Show List is empty, so logs not rotated")
		end if
	end try
end rotate_logs

##########    These are handlers loaded from the Library, we do specific things in them    ##########

on epoch2show_time(caller, epoch)
	set handlername to "epoch2datetime"
	return epoch2show_time(caller, epoch) of LibScript
end epoch2show_time

on datetime2epoch(caller, the_date_object)
	set handlername to "datetime2epoch"
	return my getTfromN(the_date_object - (my epoch()))
end datetime2epoch

on epoch2datetime(caller, epochseconds)
	set handlername to "epoch2datetime"
	return epoch2datetime(caller, epochseconds) of LibScript
end epoch2datetime

on emptylist(klist)
	set handlername to "emptylist"
	return emptylist(klist) of LibScript
end emptylist

on stringlistflip(caller, thearg, delim, returned)
	set handlername to "stringlistflip"
	return stringlistflip(caller, thearg, delim, returned) of LibScript
end stringlistflip

on epoch()
	set handlername to "epoch"
	return epoch() of LibScript
end epoch

on replace_chars(thestring, target, replacement)
	set handlername to "replace_chars"
	return replace_chars(thestring, target, replacement) of LibScript
end replace_chars

on fixDate(caller, theDate)
	set handlername to "fixDate"
	return fixDate(caller, theDate) of LibScript
end fixDate

on stringToUtf8(caller, thestring)
	set handlername to "stringToUtf8"
	return stringToUtf8(caller, thestring) of LibScript
end stringToUtf8

on isSystemShutdown(caller)
	set handlername to "isSystemShutdown"
	return isSystemShutdown(caller) of LibScript
end isSystemShutdown

on repeatProgress(loop_delay, loop_total)
	set handlername to "repeatProgress"
	return repeatProgress(loop_delay, loop_total) of LibScript
end repeatProgress

on ms2time(caller, totalMS, time_duration, level_precision)
	set handlername to "ms2time"
	return ms2time(caller, totalMS, time_duration, level_precision) of LibScript
end ms2time

on list_position(caller, this_item, this_list, is_strict)
	set handlername to "list_position"
	return list_position(caller, this_item, this_list, is_strict) of LibScript
end list_position

on short_date(caller, the_date_object, twentyfourtime, show_seconds)
	set handlername to "short_date"
	return short_date(caller, the_date_object, twentyfourtime, show_seconds) of LibScript
end short_date

on padnum(caller, thenum, splitdot)
	set handlername to "padnum"
	return padnum(caller, thenum, splitdot) of LibScript
end padnum

on is_number(caller, number_string)
	set handlername to "is_number"
	return is_number(caller, number_string) of LibScript
end is_number


on getTfromN(this_number)
	set handlername to "getTfromN"
	return getTfromN(this_number) of LibScript
end getTfromN

on isModifierKeyPressed(caller, checkKey, desc)
	set handlername to "isModifierKeyPressed"
	set modiferKeysDOWN to {command_down:false, option_down:false, control_down:false, shift_down:false, caps_down:false, numlock_down:false, function_down:false, help_down:false}
	try
		my logger(true, handlername, caller, "INFO", "isModifierKeyPressed: " & checkKey & ", reason: " & desc)
	on error errmsg
		my logger(true, handlername, caller, "WARN", "isModifierKeyPressed check failed: " & errmsg)
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
	try
		set temp to modiferKeysDOWN as text
	on error errmsg
		my logger(true, handlername, caller, "DEBUG", item 2 of my stringlistflip("isModifierKeyPressed(" & caller & ")", errmsg, {"{", "}"}, "list"))
	end try
	return modiferKeysDOWN
end isModifierKeyPressed

on time_set(caller, adate_object, time_shift)
	
	-- FIX library?
	set handlername to "time_set"
	if class of adate_object is not date then
		my logger(true, handlername, caller, "ERROR", (adate_object as text) & " is not a date object!")
	end if
	set dateobject to adate_object
	--set to midnight
	set hours of dateobject to 0
	set minutes of dateobject to 0
	set seconds of dateobject to 0
	set dateobject to dateobject + (time_shift * hours)
	return dateobject
end time_set

on date2touch(caller, datetime, filepath)
	set handlername to "date2touch"
	set temp_year to year of datetime
	set temp_month to my padnum("date2touch(" & caller & ")", ((month of datetime) * 1) as text, false)
	set temp_day to my padnum("date2touch(" & caller & ")", (day of datetime as text), false)
	set temp_hour to my padnum("date2touch(" & caller & ")", (hours of datetime as text), false)
	set temp_minute to my padnum("date2touch(" & caller & ")", (minutes of datetime as text), false)
	set temp_message to "touch -t " & temp_year & temp_month & temp_day & temp_hour & temp_minute & " \"" & filepath & "\""
	my logger(true, handlername, caller, "INFO", temp_message)
	do shell script temp_message
end date2touch

on update_folder(caller, update_path)
	set handlername to "update_folder"
	my logger(true, handlername, caller, "INFO", "\"" & update_path & "\"")
	set posix_update_path to POSIX path of update_path
	try
		do shell script "touch \"" & posix_update_path & "hdhrVCR_test_write\""
		delay 0.1
		do shell script "rm \"" & posix_update_path & "hdhrVCR_test_write\""
		return true
	on error errmsg
		my logger(true, handlername, caller, "ERROR", "Unable to write to " & posix_update_path & ", " & errmsg)
		return false
	end try
end update_folder

on logger(logtofile, the_handler, caller, loglevel, message)
	set handlername to "logger"
	# logtofile is a boolean that tell us if we want to write this to a file, in addition to logging it out in Script Editor Console.
	# caller is a string that tells us where this handler was called from
	# loglevel is a string that tell us how severe the log line is 
	# message is the actual message we want to log.
	set caller to (caller) as text
	set logger_max_queued to 1
	set queued_log_lines to {}
	set end of queued_log_lines to my short_date("logger(" & caller & ")", current date, true, true) & " " & Local_env & " " & loglevel & " " & the_handler & "(" & caller & ")" & " " & message
	if loglevel is in Logger_levels then
		try
			set logfile to open for access file ((Log_dir) & (Logfilename) as text) with write permission
		on error
			set logfile to ""
		end try
		if logfile is not "" then
			repeat with i from 1 to length of queued_log_lines
				set ref_num to get eof of logfile
				write (item i of queued_log_lines & Lf) as text to logfile starting at (ref_num + 1)
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

on existing_shows(caller)
	set handlername to "existing_shows"
	try
		set showid2PID_result to do shell script "ps -Aa|grep appname|grep -v 'grep\\|caffeinate'"
		my logger(true, handlername, caller, "TRACE", "ps -Aa|grep appname|grep -v 'grep\\|caffeinate', msg: " & showid2PID_result)
	on error errmsg
		my logger(true, handlername, caller, "DEBUG", "Exception while grepping, " & errmsg)
		set showid2PID_result to {}
		return
	end try
	set showid2PID_result_list to my stringlistflip("existing_shows(" & caller & ")", showid2PID_result, return, "list")
	if length of showid2PID_result_list is greater than 0 then
		try
			repeat with i from 1 to length of showid2PID_result_list
				set showid2PID_result_list_perline to my stringlistflip("existing_shows(" & caller & ")", item i of showid2PID_result_list, {" -H ", "show_id:"}, "list")
				set temp_show_id to item 3 of showid2PID_result_list_perline
				set show_offset to my HDHRShowSearch(temp_show_id)
				if show_offset is not 0 then
					if show_recording of item show_offset of Show_info is false then
						set show_recording of item show_offset of Show_info to true
						my logger(true, handlername, caller, "WARN", "The show " & show_title of item show_offset of Show_info & " is already recording, so show_recording set to true!")
					end if
				else
					my logger(true, handlername, caller, "WARN", "A show is recording that we do not recognize, show_id:" & temp_show_id)
				end if
			end repeat
		on error errmsg
			my logger(true, handlername, caller, "ERROR", "errmsg, " & errmsg)
		end try
	end if
end existing_shows

on check_after_midnight(caller)
	set handlername to "check_after_midnight"
	set temp_time to day of (current date)
	try
		if Check_after_midnight_time is not temp_time then
			set Check_after_midnight_time to temp_time
			return true
		end if
	on error errmsg
		set Check_after_midnight_time to temp_time
	end try
	return false
end check_after_midnight

on tuner_dump(caller)
	set handlername to "tuner_dump"
	repeat with i from 1 to length of HDHR_DEVICE_LIST
		set tuner_dump_per_item to {}
		try
			set end of tuner_dump_per_item to ("BaseURL: " & (BaseURL of item i of HDHR_DEVICE_LIST))
			set end of tuner_dump_per_item to ("hdhr_lineup_update: " & (hdhr_lineup_update of item i of HDHR_DEVICE_LIST) as text)
			set end of tuner_dump_per_item to ("hdhr_guide_update: " & (hdhr_guide_update of item i of HDHR_DEVICE_LIST) as text)
			set end of tuner_dump_per_item to ("discover_url: " & (discover_url of item i of HDHR_DEVICE_LIST))
			set end of tuner_dump_per_item to ("lineup_url: " & (lineup_url of item i of HDHR_DEVICE_LIST))
			set end of tuner_dump_per_item to ("device_id: " & (device_id of item i of HDHR_DEVICE_LIST))
			set end of tuner_dump_per_item to ("does_transcode: " & (does_transcode of item i of HDHR_DEVICE_LIST))
			try
				set end of tuner_dump_per_item to ("hdhr_lineup_length: " & (length of hdhr_lineup of item i of HDHR_DEVICE_LIST))
			on error errmsg
				my logger(true, handlername, caller, "WARN", "Unable to determine length of hdhr_lineup")
			end try
			set end of tuner_dump_per_item to ("is_active: " & (is_active of item i of HDHR_DEVICE_LIST))
			set end of tuner_dump_per_item to ("is_active_reason: " & (is_active_reason of item i of HDHR_DEVICE_LIST))
			set end of tuner_dump_per_item to ("statusURL: " & (statusURL of item i of HDHR_DEVICE_LIST))
			set end of tuner_dump_per_item to ("channel_mapping: " & (channel_mapping of item i of HDHR_DEVICE_LIST))
			set end of tuner_dump_per_item to ("hdhr_model: " & (hdhr_model of item i of HDHR_DEVICE_LIST))
			set temp to my stringlistflip("tuner_dump(" & caller & ")", tuner_dump_per_item, ", ", "string")
			my logger(true, handlername, caller, "INFO", temp)
		on error errmsg
			my logger(true, handlername, caller, "WARN", errmsg)
		end try
	end repeat
end tuner_dump

on cm(handlername, caller)
	return {handlername, "(" & caller & ")"} as text
end cm

on seriesScan(caller, seriesID, hdhr_device, thechan)
	--This will return shows that match a specific show_id.  Returned data is a list of records
	set handlername to "seriesScan"
	my logger(true, handlername, caller, "WARN", "seriesID: " & seriesID & ", hdhr_device: " & hdhr_device & ", thechan: " & thechan)
	set show_match_list to {}
	set show_channel_list to {}
	set tuner_offset to my HDHRDeviceSearch("seriesScan(" & caller & ")", hdhr_device)
	my logger(true, handlername, caller, "WARN", "tuner_offset: " & tuner_offset)
	set hdhr_guide to hdhr_guide of item tuner_offset of HDHR_DEVICE_LIST
	--set hdhr_guide to (fetch JSON from "https://api.hdhomerun.com/api/guide.php?DeviceAuth=Jznln9JXdQz83NWwNueB11f4" with cleaning feed)
	repeat with i from 1 to length of hdhr_guide
		set temp_channel to GuideNumber of item i of hdhr_guide
		set guide_temp to Guide of item i of hdhr_guide
		repeat with i2 from 1 to length of guide_temp
			if seriesID of item i2 of guide_temp is seriesID then
				if thechan is "" then
					set end of show_channel_list to temp_channel
					set end of show_match_list to item i2 of guide_temp
				else
					if thechan is temp_channel then
						set end of show_channel_list to temp_channel
						set end of show_match_list to item i2 of guide_temp
					end if
				end if
			end if
		end repeat
	end repeat
	if thechan is "" then
		my logger(true, handlername, caller, "INFO", "Total of " & length of show_match_list & " shows found, on all channels")
	else
		my logger(true, handlername, caller, "INFO", "Total of " & length of show_match_list & " shows found, on channel " & thechan)
	end if
	return {show_match_list, show_channel_list, hdhr_device}
end seriesScan

on loadlib(caller)
	set handlername to "loadlib"
	try
		tell application "Finder"
			set loaded_script_path to (path to documents folder as text) & "hdhr_VCR_lib.scpt"
			set loaded_script_alias to loaded_script_path as alias
			set loaded_script_name to (name of loaded_script_alias) as text
		end tell
	on error errmsg
		my logger(true, handlername, caller, "WARN", "errmsg, " & errmsg)
	end try
	set LibScript to load script loaded_script_alias
	set LibScript_version to load_hdhrVCR_vars() of LibScript
	set ParentScript of LibScript to me
	my logger(true, handlername, caller, "INFO", "Loaded: " & loaded_script_name & ", version: " & LibScript_version)
end loadlib

on delay_idle_loop(caller, the_delay)
	set handlername to "delay_idle_loop"
	my logger(true, handlername, caller, "TRACE", Idle_count_delay)
	if the_delay is less than or equal to 0 then
		set Idle_count_delay to 0
	else
		set Idle_count_delay to Idle_count_delay + the_delay
		my temp_auto_delay(my cm(handlername, caller), the_delay)
	end if
end delay_idle_loop

on temp_auto_delay(caller, thesec)
	set handlername to "temp_auto_delay"
	set Idle_timer to thesec
	copy ((current date) + thesec) to Idle_timer_dateobj
	my logger(true, handlername, caller, "TRACE", "idle_timer set to " & thesec)
end temp_auto_delay