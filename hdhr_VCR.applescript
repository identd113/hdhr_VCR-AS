-- Not needed Need to convert all times to date objects.  Currently we use 3 idfferent date formats, and this is a mess
--Need a way to validate data if wrong in repeat loop, but be able to edit files on demand.
--Need to setup a helper for notifcations.
-- Done We need to write a flat file to save the TV shows, as properties will lose their persistence in big sur
-- Done We should not ask about the tuner until after we click "add"
--property show_info : {}
--property hdhr_IP : "10.0.1.12"
--property hdhr_PORT : ":5004"
--property hdhr_TUNER_ct : 0
-- caffeinate -i curl 'http://10.0.1.101:5004/auto/v2.4?duration=1768' -o '/Volumes/Backups/DVR Tests/Dinosaur Train S02E09 The Lost Bird; The Forest Fire_01.05.21 09.55.mkv'> /dev/null 2>&1 &
--We need to know how many avilable tuners there are, and perhaps when they expire. I was trying to avoid this, but I have missed recordings because of this.

global show_info
global temp_show_info
global locale
global channel_list
global HDHR_DEVICE_LIST

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
global savefilename
global time_slide
global dialog_timeout

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


use AppleScript version "2.4"
use scripting additions
use application "JSON Helper"

--{hdhr_lineup_update:missing value, hdhr_guide_update:missing value, discover_url:"http://10.0.1.101/discover.json", lineup_url:"http://10.0.1.101/lineup.json", device_id:"XX105404BE", does_transcode:0, hdhr_lineup:missing value, hdhr_guide:missing value, hdhr_model:missing value}
-- nextup is currently a property, so this value persists through application restarts.  Big Sir will disallow this ability.  I need to be make this a global.  Does one really need to write 



-- Done Use jsonhelper and json querys to get data.
--show_info model: (*show_title:Happy_Holidays_America, show_time:16, show_length:60, show_air_date:Sunday, show_transcode:missing value, show_temp_dir:alias Backups:, show_dir:alias Backups:, show_channel:5.1, show_active:true, show_id:221fbe1126389e6af35f405aa681cf19, show_recording:false, show_last:date Sunday, December 13, 2020 at 4:04:54 PM, show_next:date Sunday, December 13, 2020 at 4:00:00 PM, show_end:date Sunday, December 13, 2020 at 5:00:00 PM, notify_upnext_time:missing value, notify_recording_time:missing value, hdhr_record:XX105404BE,show_is_series:false*

-- {show_title:"string", show_time:dateobject, show_length:interger(minutes),show_air_day:list (Sun, Mon, Tue, Wed, Thu, Fri, Sat), show_transcode:true/false, show_temp_dir:alias, show_dir:alias)

--note We will only save data to the temp directory first if the data needs to be transcoded. Once done trancoding, the resulting file will be saved to the show_temp directory
-- Done We should try to find the HDhomerun, and port on the network.
-- Done We do this already, but we should use discover.json and parse
-- Done We should try and pull the name of shows given the date and time.  These times are noted in epoch, so we need to change how we do dates script wide, or just convert to and from epoch as needed
-- -- http://api.hdhomerun.com/api/guide.php?DeviceAuth=IBn9SkGefWcxVTxbQpTBMsuI
--Done. Only offer trascode options on extend
-- Done Do a temp write to the destination directory when selected, so we can have the user accept OS security warning now, instead of when the show starts.
--We need a better way to show the user 
--	set progress description to "Loading ..."
--  set progress additional description to
--	set progress completed steps to 0 
--	set progress total steps to 1
--If you select a record time in the middle of the show, we will adjust the start time to match guide data.  We may also need to update record time, and end time.  

on tuner_end(hdhr_model)
	set temp to {}
	set lowest_number to 99999999
	repeat with i from 1 to length of show_info
		if show_recording of item i of show_info = true and hdhr_record of item i of show_info = hdhr_model then
			set end of temp to ((show_end of item i of show_info) - (current date))
		end if
	end repeat
	if length of temp ­ 0 then
		repeat with i2 from 1 to length of temp
			if item i2 of temp < lowest_number and item i2 of temp > 0 then
				set lowest_number to item i2 of temp
			end if
		end repeat
	end if
	return lowest_number
end tuner_end

on tuner_status(caller, device_id)
	log "tuner_status: " & caller & " of " & device_id
	set temp_list to {}
	set tuner_offset to my HDHRDeviceSearch("hdhr_prepare_record0", device_id)
	set used_tuner_get to do shell script "curl '" & BaseURL of item tuner_offset of HDHR_DEVICE_LIST & "/tuners.html'"
	--set used_tuner_get_response to my stringtolist("used_tuner0", used_tuner_get, {"<td>", "</td>", "<tr>", "</tr>"})
	set used_tuner_get_response to item 2 of my stringtolist("used_tuner0", used_tuner_get, {"<table>", "</table>"})
	set used_tuner_get_response to my stringtolist("used_tuner1", used_tuner_get_response, {"<td>", "</td>", "<tr>", "</tr>", return})
	set used_tuner_get_response to my emptylist(used_tuner_get_response)
	try
		if length of used_tuner_get_response > 2 then
			repeat with i from 1 to length of used_tuner_get_response
				if item i of used_tuner_get_response contains "Tuner" then
					set end of temp_list to item (i + 1) of used_tuner_get_response
				end if
			end repeat
		end if
	on error
		display notification "ERROR in used_tuner()"
	end try
	return temp_list
end tuner_status

on check_version()
	set version_response to (fetch JSON from version_url)
	set version_remote to hdhr_version of item 1 of versions of version_response
	log "Remote: " & version_remote
	log "Local: " & version_local
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

on hdhr_prepare_record(hdhr_device)
	set tuner_offset to my HDHRDeviceSearch("hdhr_prepare_record0", hdhr_device)
	set temp to my stringtolist("hdhr_prepare_record", discover_url of item tuner_offset of HDHR_DEVICE_LIST, "/")
	return my listtostring(items 1 thru -2 of temp, "/")
end hdhr_prepare_record

on run {}
	
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
	
	set version_local to "20210115"
	
	set progress description to "Loading " & name of me & " " & version_local
	--set globals 
	set show_info to {}
	set notify_upnext to 30
	set notify_recording to 10
	set locale to user locale of (system info)
	set hdhr_setup_folder to "Volumes:"
	set hdhr_setup_transcode to "No"
	set hdhr_setup_name_bool to "No"
	set hdhr_setup_length_bool to "No"
	set savefilename to "hdhr_VCR.config"
	set time_slide to 0
	set dialog_timeout to 60
	set version_url to "https://raw.githubusercontent.com/identd113/hdhr_VCR-AS/master/version.json"
	set version_remote to "0"
	--We will try to autodiscover the HDHR device on the network, and throw it into a record.
	--Lets check for a new version!
	my check_version()
	log "run()"
	
	(*
	This really kicks us off.  The will query to see if there are any HDHomeRun devices on the local network.  This script support multiple devices.
	Once we find some devices, we will query them and pull there lineup data.  This tells us what channels belong to what tags, like "2.4 TPTN"
	We will then pull guide data.  It should be said here that this data is only given for 4 hours ahead of current time, some stations maybe 6.  Special considerations have been made in this script to make this work.  We call this handler and specify "run0".  This is just a made up string that we pass to the next handler, so we can see the request came in that broke the script.  This is commonly repeated in my scripts.
	*)
	--Restore any previous state 
	
	
	my HDHRDeviceDiscovery("run0", "")
	--try
	my read_data()
	--on error
	--display notification "Error when loading data"
	--end try
	--Main is is the show adding mechanism
	my main()
end run

on reopen {}
	my main()
end reopen

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
		log channel_mapping of item tuner_offset of HDHR_DEVICE_LIST
	end if
end build_channel_list

on channel2name(the_channel, hdhr_device)
	set tuner_offset to my HDHRDeviceSearch("channel2name0", hdhr_device)
	set channel2name_temp to hdhr_lineup of item tuner_offset of HDHR_DEVICE_LIST
	repeat with i from 1 to length of channel2name_temp
		if GuideNumber of item i of channel2name_temp = the_channel then
			return GuideName of item i of channel2name_temp
		end if
	end repeat
end channel2name

--show_next should only return the next record time, considering recording and not a list of all record times, if a show is recording, that time should remain as returned
on nextday(the_show_id)
	set cd_object to current date
	set nextup to {}
	set show_offset to my check_offset(the_show_id)
	log "length of show info: " & length of show_info
	repeat with i from 0 to 7
		if the_show_id = show_id of item show_offset of show_info then
			--log "Shows match"
			if (weekday of (cd_object + i * days) as text) is in show_air_date of item show_offset of show_info then
				log "1: " & (weekday of (cd_object + i * days)) & " is in " & show_air_date of item show_offset of show_info as string
				log "2: " & (my time_set((cd_object + i * days), (show_time of item show_offset of show_info))) + ((show_length of item show_offset of show_info) * minutes)
				if cd_object < (my time_set((cd_object + i * days), (show_time of item show_offset of show_info))) + ((show_length of item show_offset of show_info) * minutes) then
					--end time in future
					set nextup to my time_set((cd_object + i * days), show_time of item show_offset of show_info)
					exit repeat
				end if
			end if
		end if
	end repeat
	set show_end of item show_offset of show_info to nextup + ((show_length of item show_offset of show_info) * minutes)
	log nextup
	return nextup
end nextday

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

on validate_show_info(show_to_check, should_edit)
	--display dialog show_to_check & " ! " & should_edit
	--(*show_title:news, show_time:12, show_length:30, show_air_date:Monday, Tuesday, Wednesday, Thursday, show_transcode:false, show_temp_dir:alias Macintosh HD:Users:TEST:Dropbox:, show_dir:alias Macintosh HD:Users:TESTl:Dropbox:, show_channel:11.1, show_active:true, show_id:bf4fcd8b7ac428594a386b373ef55874, show_recording:false, show_last:date Tuesday, August 30, 2016 at 11:35:04 AM, show_next:date Tuesday, August 30, 2016 at 12:00:00 PM, show_end:date Tuesday, August 30, 2016 at 12:30:00 PM*)
	
	if show_to_check = "" then
		repeat with i from 1 to length of show_info
			my validate_show_info(show_id of item i of show_info, should_edit)
		end repeat
	else
		set i to my check_offset(show_to_check)
		log "check_offset: "
		log i
		log "Show_air_date: " & show_title of item i of show_info
		
		if should_edit = true then
			--show_recording of item i of show_info = false and show_end of item i of show_info < (current date) and show_is_series of item i of show_info = false
			if show_active of item i of show_info = true then
				set show_deactivate to (display dialog "Would you like to deactivate: " & return & "\"" & show_title of item i of show_info & "\"" & return & return & "Deactivated shows will be removed on the next save/load." buttons {play_icon & " Run", "Deactivate", "Next"} cancel button 1 default button 3 with title my check_version_dialog() with icon stop)
				if button returned of show_deactivate = "Deactivate" then
					set show_active of item i of show_info to false
				end if
			else if show_active of item i of show_info = false then
				set show_deactivate to (display dialog "Would you like to activate: " & return & "\"" & show_title of item i of show_info & "\"" & return & return & "Active shows can be edited." buttons {play_icon & " Run", "Activate", "Next"} cancel button 1 default button 3 with title my check_version_dialog() with icon note)
				if button returned of show_deactivate = "Activate" then
					set show_active of item i of show_info to true
				end if
			end if
		end if
		
		if show_active of item i of show_info = true then
			--display dialog should_edit
			if show_title of item i of show_info = missing value or show_title of item i of show_info = "" or should_edit = true then
				set show_title_temp to display dialog "What is the title of this show, and is it a series?" & return & "Next Showing: " & my short_date("validate_show", show_next of item i of show_info, true) buttons {play_icon & " Run", series_icon & " Series", single_icon & " Single"} default button 3 cancel button 1 default answer show_title of item i of show_info with title my check_version_dialog() giving up after dialog_timeout
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
				--fixme Catch errors, and drop back into idle loop if canceled
				set channel_temp to word 1 of item 1 of (choose from list channel_mapping of item tuner_offset of HDHR_DEVICE_LIST with prompt "What channel does this show air on?" default items item temp_channel_offset of channel_mapping of item tuner_offset of HDHR_DEVICE_LIST with title my check_version_dialog() cancel button name play_icon & " Run" OK button name "Next.." without empty selection allowed)
				--	display dialog channel_temp
				set show_channel of item i of show_info to channel_temp --set show_channel of item i of show_info to word 1 of item 1 of (choose from list channel_list with prompt "What channel does this show air on?" default items show_channel of item i of show_info without empty selection allowed) 
			end if
			--end repeat  
			
			if show_time of item i of show_info = missing value or (show_time of item i of show_info as number) ³ 24 or my is_number(show_time of item i of show_info) = false or should_edit = true then
				--set show_time of item i of show_info to text returned of (display dialog "What time does this show air? (use 1-24)" default answer show_time of item i of show_info)
				--FIX give option to smart "adjust" the time if guide data is available 
				set show_time of item i of show_info to text returned of (display dialog "What time does this show air? " & return & "(0-24, use decimals, ie 9.5 for 9:30)" default answer hours of (current date) buttons {play_icon & " Run", "Next.."} with title my check_version_dialog() giving up after dialog_timeout default button 2 cancel button 1) as number
			end if
			if show_length of item i of show_info = missing value or my is_number(show_length of item i of show_info) = false or show_length of item i of show_info ² 0 or should_edit = true then
				set show_length of item i of show_info to text returned of (display dialog "How long is this show? (in minutes)" default answer show_length of item i of show_info with title my check_version_dialog() buttons {play_icon & " Run", "Next.."} default button 2 cancel button 1 giving up after dialog_timeout)
			end if
			
			if show_air_date of item i of show_info = missing value or length of show_air_date of item i of show_info = 0 or should_edit = true then
				set show_air_date of item i of show_info to (choose from list {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"} default items show_air_date of item i of show_info with title my check_version_dialog() OK button name "Next.." cancel button name play_icon & " Run" with prompt "Select the days you wish to record." & return & "If this is a series, you can select multiple days." with multiple selections allowed without empty selection allowed)
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
	set hdhr_setup_response to (display dialog "hdhr_VCR Setup." buttons {"Defaults", "Delete", play_icon & " Run"} default button 1 cancel button 3 with title my check_version_dialog() giving up after dialog_timeout)
	if button returned of hdhr_setup_response = "Defaults" then
		set temp_dir to alias "Volumes:"
		repeat until temp_dir ­ alias "Volumes:"
			set hdhr_setup_folder to choose folder with prompt "Select default Shows Directory" default location temp_dir
		end repeat
		--write data here
		display dialog "We need to allow notifications." & return & "Click \"Next\" to continue." buttons {"Next"} default button 1 with title my check_version_dialog() giving up after dialog_timeout
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
		--  if my remove_show("setup0", "?")
	end if
	
end setup

on main()
	--my read_data()
	(*
	if preferred_tuner_offset = missing value then
		quit {}
	end if
	*)
	-- This gets out list of channel and channel names.  There is a better way to do this (from guide data maybe? bit this is a hold over from v1, and it works.
	--This will make sure that data we have stored is valid
	my validate_show_info("", false)
	my build_channel_list("main0", "")
	
	--This will mark shows as inactive (single show recording that has already passed)
	set show_info_length to length of show_info
	if show_info_length > 0 then
		repeat with i from 1 to show_info_length
			if show_last of item i of show_info ­ my epoch() and show_is_series of item i of show_info = false then
				set show_active of item i of show_info to false
			end if
		end repeat
	end if
	
	--Collect the temporary name.  This will likely be over written once we can pull guide data
	activate me
	set title_response to (display dialog "Would you like to add a show?" buttons {tv_icon & " Shows..", plus_icon & " Add..", play_icon & " Run"} with title my check_version_dialog() giving up after (dialog_timeout - 30) with icon note default button 2)
	if button returned of title_response contains "Add.." then
		set temp_tuners_list to {}
		--set end of temp_tuners_list to "Auto"
		repeat with i from 1 to length of HDHR_DEVICE_LIST
			
			log "main()"
			log item i of HDHR_DEVICE_LIST
			set end of temp_tuners_list to hdhr_model of item i of HDHR_DEVICE_LIST & " " & (device_id of item i of HDHR_DEVICE_LIST)
		end repeat
		if length of temp_tuners_list > 1 then
			set preferred_tuner to choose from list temp_tuners_list with prompt "Multiple HDHR Devices found, please choose one." cancel button name play_icon & " Run" OK button name "Select" with title my check_version_dialog()
			if preferred_tuner ­ false then
				set hdhr_device to last word of item 1 of preferred_tuner
			else
				set hdhr_device to missing value
			end if
		else
			set hdhr_device to device_id of item i of HDHR_DEVICE_LIST
		end if
		my add_show_info(hdhr_device)
	end if
	
	if button returned of title_response contains "Shows.." then
		--display dialog button returned of title_response
		set show_list to {}
		--display dialog length of show_info
		-- FIX We need to figure out how to sort this list. ideally the list would be:
		-- recording
		-- up next
		-- up next2
		-- rest
		
		repeat with i from 1 to length of show_info
			--set end of show_list to (show_title of item i of show_info & "\" on " & show_channel of item i of show_info & " at " & show_time of item i of show_info & " for " & show_length of item i of show_info & " minutes on " & show_air_date)
			--display notification class of show_recording of item i of show_info
			set temp_show_line to " " & (show_title of item i of show_info & " on " & show_channel of item i of show_info & " at " & show_time of item i of show_info & " for " & show_length of item i of show_info & " minutes on " & my listtostring(show_air_date of item i of show_info, ", "))
			
			if show_is_series of item i of show_info = true then
				set temp_show_line to series_icon & temp_show_line
			else
				set temp_show_line to single_icon & temp_show_line
			end if
			
			if show_active of item i of show_info = true then
				set temp_show_line to check_icon & temp_show_line
			else
				set temp_show_line to uncheck_icon & temp_show_line
			end if
			
			if ((show_next of item i of show_info) - (current date)) < 4 * hours and show_active of item i of show_info = true and show_recording of item i of show_info = false then
				set temp_show_line to up_icon & temp_show_line
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
			
			
			set end of show_list to temp_show_line
		end repeat
		
		--display dialog length of show_list 
		if length of show_list = 0 then
			--	display dialog "2"
			try
				set hdhr_no_shows to button returned of (display dialog "There are no shows, why don't you add one?" buttons {"Quit", plus_icon & " Add Show"} default button 2)
				if hdhr_no_shows = "Add Show" then
					--This should kick us to the adding a show handler.
					my main()
				end if
				if hdhr_no_shows = "Quit" then
					quit {}
				end if
				--We need a to prompt user for perferred tuner here to make this work. 
			on error
				--display dialog "4"
				return
			end try
		else if length of show_list > 0 then
			set temp_show_list to (choose from list show_list with title my check_version_dialog() with prompt "Select show to edit: " & return & single_icon & " Single   " & series_icon & " Series" & "   " & record_icon & " Recording" & "   " & uncheck_icon & "/" & check_icon & " In/active" & "   " & up_icon & " Up Next" & "  " & up2_icon & " Up Next > 4h" & "  " & calendar_icon & " Future Show" OK button name edit_icon & " Edit.." cancel button name play_icon & " Run" without empty selection allowed)
			if temp_show_list ­ false then
				my validate_show_info(show_id of item (my list_position("main1", (temp_show_list as text), show_list, true)) of show_info, true)
				my save_data()
			else
				return false
			end if
			--my validate_show_info(show_id of item (my list_position("main2", ((choose from list show_list) as text), show_list, true)) of show_info, false)
			--			set XX to my list_position((YY as text), show_list)
			--			display dialog "XX: " & XX
			--			my validate_show_info(show_id of item XX of show_info, true)
		end if
	end if
	
end main

on add_show_info(hdhr_device)
	
	set tuner_offset to my HDHRDeviceSearch("add_show_info0", hdhr_device)
	set show_channel to missing value
	set temp_show_info to {show_title:missing value, show_time:missing value, show_length:missing value, show_air_date:missing value, show_transcode:missing value, show_temp_dir:missing value, show_dir:missing value, show_channel:missing value, show_active:true, show_id:(do shell script "date | md5") as text, show_recording:false, show_last:my epoch(), show_next:missing value, show_end:missing value, notify_upnext_time:missing value, notify_recording_time:missing value, hdhr_record:hdhr_device, show_is_series:false}
	
	if hdhr_device = "" then
		if length of HDHR_DEVICE_LIST = 1 then
			--fix Add multiple tuner prompt
			set hdhr_device to device_id of item 1 of HDHR_DEVICE_LIST
		end if
	end if
	
	
	repeat until my is_number(show_channel of temp_show_info)
		try
			--	
			set show_channel of temp_show_info to word 1 of item 1 of (choose from list channel_mapping of item tuner_offset of HDHR_DEVICE_LIST with prompt "What channel does this show air on?" with title my check_version_dialog() OK button name "Next.." cancel button name play_icon & " Run" without empty selection allowed)
			--set show_channel of temp_show_info to text returned of (display dialog "What channel does this show air on?" default answer "") --pull channel kineup, and parse out Channel name/channel.
			--if my is_number(show_channel of temp_show_info) = false then
			--	set show_channel of temp_show_info to missing value
			--else
			--		set show_channel of temp_show_info to show_channel of temp_show_info as number
			--end if
		on error
			error number -128
		end try
	end repeat
	
	repeat until my is_number(show_time of temp_show_info) and show_time of temp_show_info ³ 0 and show_time of temp_show_info < 24
		set show_time of temp_show_info to text returned of (display dialog "What time does this show air? " & return & "(0-24, use decimals, ie 9.5 for 9:30)" default answer hours of (current date) buttons {play_icon & " Run", "Next.."} with title my check_version_dialog() giving up after dialog_timeout default button 2 cancel button 1) as number
		
		--if my is_number(show_time of temp_show_info) = false then 
		
		--set show_time of temp_show_info to missing value
		--else
		--set show_time of temp_show_info to my time_shift((show_time of temp_show_info as number) * hours)
		--set show_time of temp_show_info to show_time of temp_show_info as number
		--end if
	end repeat
	
	-- We know the channel and time, we can refer to our guid data to pull the name of the show.  If we dont know of it yet, we can ask the user.
	log "Add_show"
	--log my channel_guide(hdhr_device, show_channel of temp_show_info, show_time of temp_show_info)
	--fix we error here if we cannot pull guidedata
	set hdhr_response_channel to my channel_guide("Add_show_info0", hdhr_device, show_channel of temp_show_info, show_time of temp_show_info)
	--log " hdhr_response_channel: " & hdhr_response_channel
	if hdhr_response_channel ­ {} then
		set show_time_adjusted to my epoch2show_time(getTfromN(StartTime of hdhr_response_channel))
		if (show_time of temp_show_info as number) ­ (show_time_adjusted as number) then
			display notification edit_icon & " Show Time changed to " & show_time_adjusted
			set show_time of temp_show_info to show_time_adjusted
		end if
	end if
	--	log "start time: " & my epoch2show_time(getTfromN(StartTime of hdhr_response_channel))
	--fixme!
	--	(*start time: 1.609974E+9*)
	-- (*proposed time: 17.5*) 
	
	--FIX
	--if show_time of temp_show_info > StartTime of  hdhr_response_channel then
	--set show_time of temp_show_info to StartTime of  hdhr_response_channel
	--end if
	--repeat this for the end time as well
	
	if hdhr_response_channel ­ {} then
		set hdhr_response_channel_title to title of hdhr_response_channel
	else
		set hdhr_response_channel_title to ""
	end if
	
	try
		set hdhr_response_channel_title to hdhr_response_channel_title & " " & EpisodeNumber of hdhr_response_channel
	end try
	
	try
		set hdhr_response_channel_title to hdhr_response_channel_title & " " & EpisodeTitle of hdhr_response_channel
	end try
	
	set show_title_temp to display dialog "What is the title of this show, and is it a series?" buttons {"Cancel", series_icon & " Series", single_icon & " Single"} default button 3 default answer hdhr_response_channel_title with title my check_version_dialog() giving up after dialog_timeout
	set show_title of temp_show_info to text returned of show_title_temp
	--if show_title of temp_show_info contains " " then
	--set show_title of temp_show_info to my listtostring(my stringtolist("show title", show_title of temp_show_info, " "), "_")
	--end if
	if button returned of show_title_temp contains "Series" then
		set show_is_series of temp_show_info to true
	else if button returned of show_title_temp contains "Single" then
		set show_is_series of temp_show_info to false
	end if
	--display notification "OK6: " & show_title of temp_show_info 
	--log "StartTime of hdhr_response_channel " & getTfromN(StartTime of hdhr_response_channel)
	log (my datetime2epoch("add_show0", current date))
	
	if hdhr_response_channel ­ {} then
		if my getTfromN(StartTime of hdhr_response_channel) < my datetime2epoch("add_show0", current date) then
			set hdhr_response_length to (my getTfromN(StartTime of hdhr_response_channel)) - (my datetime2epoch("add_show0", current date))
		else
			set hdhr_response_length to ((EndTime of hdhr_response_channel) - (StartTime of hdhr_response_channel)) div 60
			log hdhr_response_length
			
		end if
	else
		set hdhr_response_length to 30
	end if
	
	repeat until my is_number(show_length of temp_show_info) and show_length of temp_show_info ³ 1
		set show_length of temp_show_info to text returned of (display dialog "How long is this show? (in minutes)" default answer hdhr_response_length with title my check_version_dialog() buttons {play_icon & " Run", "Next.."} default button 2 cancel button 1 giving up after dialog_timeout)
	end repeat
	
	--	if hdhr_response_channel_title ­ "" then
	set default_record_day to (weekday of ((current date) + time_slide * days)) as text
	--else
	--set default_record_day to ""
	-- end if
	
	set time_slide to 0
	
	if show_is_series of temp_show_info = true then
		--set show_air_date of temp_show_info to (choose from list {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"} with prompt "Please choose the days this series airs." default items default_record_day with multiple selections allowed without empty selection allowed)
		
		set show_air_date of temp_show_info to (choose from list {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"} default items default_record_day with title my check_version_dialog() OK button name "Next.." cancel button name play_icon & " Run" with prompt "Select the days you wish to record." & return & "You can select multiple days." with multiple selections allowed without empty selection allowed)
	else
		set show_air_date of temp_show_info to (choose from list {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"} default items default_record_day with title my check_version_dialog() OK button name "Next.." cancel button name play_icon & " Run" with prompt "Select the days you wish to record." & return & "You can only select 1 day." without empty selection allowed)
	end if
	if show_air_date of temp_show_info = false then
		return
	end if
	
	set temp_dir to alias "Volumes:"
	repeat until temp_dir ­ alias "Volumes:"
		set show_dir of temp_show_info to choose folder with prompt "Select Shows Directory" default location temp_dir
		if show_dir of temp_show_info ­ temp_dir then
			set temp_dir to show_dir of temp_show_info
		end if
	end repeat
	--We attempt to write a small file to shows folder.  This will prompt the user in the OS to allow this app to write data there. 
	my update_folder(show_dir of temp_show_info)
	
	set model_response to ""
	
	--try
	--log "does_transcode: " & does_transcode of item tuner_offset of HDHR_DEVICE_LIST
	--set model_response to (do shell script "curl http://" & hdhr_IP & "/ | grep 'HDHomeRun' | grep 'div class'")
	--log "model_response: " & model_response
	--http://10.0.1.101/discover.json
	--end try
	
	if does_transcode of item tuner_offset of HDHR_DEVICE_LIST = 1 then
		set show_transcode of temp_show_info to word 1 of item 1 of (choose from list {"None: Does not transcode, will save as MPEG2 stream.", "heavy: Transcode with same settings", "mobile: Transcode not exceeding 1280x720 30fps", "intenet720: Low bit rate, not exceeding 1280x720 30fps", "internet480: Low bit rate not exceeding 848x480/640x480 for 16:9/4:3 30fps", "internet360: Low bit rate not exceeding 640x360/480x360 for 16:9/4:3 30fps", "internet240: Low bit rate not exceeding 432x240/320x240 for 16:9/4:3 30fps"} with prompt "Please choose the transcode level on the file" with title my check_version_dialog() default items {"None: Does not transcode, will save as MPEG2 stream."} OK button name disk_icon & " Save Show" cancel button name play_icon & " Run")
	else
		set show_transcode of temp_show_info to missing value
	end if
	
	set show_temp_dir of temp_show_info to show_dir of temp_show_info
	--	end if
	--commit the temp_show_info to show_info
	set end of show_info to temp_show_info
	set show_next of last item of show_info to my nextday(show_id of temp_show_info)
	my validate_show_info(show_id of last item of show_info, false)
	log show_info
	my save_data()
end add_show_info

on update_folder(update_path)
	do shell script "touch \"" & POSIX path of update_path & "hdhr_test_write\""
	delay 0.1
	do shell script "rm \"" & POSIX path of update_path & "hdhr_test_write\""
end update_folder

on idle
	--display notification time string of (current date)
	set cd_object to (current date) + 10
	--Re run auto discover every 2 hours, or once we flip past midnight
	if length of HDHR_DEVICE_LIST > 0 then
		repeat with i2 from 1 to length of HDHR_DEVICE_LIST
			if ((cd_object) - (hdhr_guide_update of item i2 of HDHR_DEVICE_LIST)) div 60 ³ 120 or date string of (hdhr_guide_update of item i2 of HDHR_DEVICE_LIST) ­ date string of (current date) then
				my HDHRDeviceDiscovery("idle0", "")
			end if
		end repeat
	end if
	if length of show_info > 0 then
		repeat with i from 1 to length of show_info
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
			if show_active of item i of show_info = true then
				if show_next of item i of show_info < cd_object then
					--if show_next of item i of show_info < cd_object then
					if show_recording of item i of show_info = false then
						if show_end of item i of show_info < (current date) then
							display notification "show_end of item i of show_info < (current date)"
						end if
						--FIX the above line would cause some issues when quitting/re opening.  We should resume more gracefully
						--try
						--on error
						--	display notification "Used Tuner Error"
						--end try 
						set show_runtime to (show_end of item i of show_info) - (current date)
						if my tuner_status("idle5", hdhr_record of item i of show_info) does not contain "not in use" then
							set tuner_end_temp to my tuner_end(hdhr_record of item i of show_info)
							if tuner_end_temp ² 15 then
								display notification "Pausing idle for " & tuner_end_temp & " seconds."
								delay (my tuner_end(hdhr_record of item i of show_info)) + 5
							else
								display notification "No Tuners: next time out in " & tuner_end_temp & "seconds"
							end if
						end if
						my record_now((show_id of item i of show_info), show_runtime)
						display notification "Ends " & my short_date("rec started", show_end of item i of show_info, false) with title record_icon & " Started Recording on (" & hdhr_record of item i of show_info & ")" subtitle show_title of item i of show_info & " on " & show_channel of item i of show_info & " (" & my channel2name(show_channel of item i of show_info as text, hdhr_record of item i of show_info) & ")"
						set notify_recording_time of item i of show_info to (current date) + (2 * minutes)
						--display notification show_title of item i of show_info & " on channel " & show_channel of item i of show_info & " started for " & show_runtime of item i of show_info & " minutes."
					else
						--display notification show_title of item i of show_info & " is recording until " & my short_date("recording", show_end of item i of show_info)
						if notify_recording_time of item i of show_info < (current date) or notify_recording_time of item i of show_info = missing value then
							display notification "Ends " & my short_date("rec progress", show_end of item i of show_info, false) & " (" & (my sec_to_time((show_end of item i of show_info) - (current date))) & ") " with title record_icon & " Recording in progress on (" & hdhr_record of item i of show_info & ")" subtitle show_title of item i of show_info & " on " & show_channel of item i of show_info & " (" & my channel2name(show_channel of item i of show_info as text, hdhr_record of item i of show_info) & ")"
							--try to refresh the file, so it shows it refreshes finder.
							try
								my update_folder(show_dir of item i of show_info)
							on error
								display notification "Touch Update failed"
							end try
							set notify_recording_time of item i of show_info to (current date) + (notify_recording * minutes)
						end if
					end if
				end if
			end if
			
			
			if show_recording of item i of show_info = false and show_active of item i of show_info = true then
				--my update_show(show_id of item i of show_info)
				--set delay_count to delay_count + 1
				--if delay_count ³ 36 then -- ~ 10 minutes 
				--display notification show_title of item i of show_info & " is next at " & my short_date("is_next", show_next of item i of show_info)
				if (notify_upnext_time of item i of show_info < (current date) or notify_upnext_time of item i of show_info = missing value) and (show_next of item i of show_info) - (current date) ² 4 * hours then
					--This line is a hot mess, as it reports too often.  Lets try some progress bar hacks.
					
					--	set progress description to "Loading ..."
					--  set progress additional description to
					--	set progress completed steps to 0 
					--	set progress total steps to 1 
					
					--set progress description to "Next up... (" & hdhr_record of item i of show_info & ")"
					--set progress additional description to "Starts: " & my short_date("is_next", show_next of item i of show_info, false)
					
					--We see this message very often, lets make sure we only display up next shows just for today. 
					display notification "Starts: " & my short_date("is_next", show_next of item i of show_info, false) & " (" & my sec_to_time(((show_next of item i of show_info) - (current date))) & ")" with title up_icon & " Next Up on (" & hdhr_record of item i of show_info & ")" subtitle show_title of item i of show_info & " on " & show_channel of item i of show_info & " (" & my channel2name(show_channel of item i of show_info, hdhr_record of item i of show_info) & ")"
					set notify_upnext_time of item i of show_info to (current date) + (notify_upnext * minutes)
				end if
				--	set delay_count to 0 
				--end if
				
			end if
			
			if show_recording of item i of show_info = true then
				if show_end of item i of show_info < (current date) then
					set show_last of item i of show_info to show_end of item i of show_info
					set show_next of item i of show_info to my nextday(show_id of item i of show_info)
					set show_recording of item i of show_info to false
					if show_is_series of item i of show_info = true then
						display notification "Next Showing: " & my short_date("rec_end", show_next of item i of show_info, false) with title stop_icon & " Recording Complete." subtitle (show_title of item i of show_info & " on " & show_channel of item i of show_info & " (" & my channel2name(show_channel of item i of show_info as text, hdhr_record of item i of show_info) & ")")
					else
						set show_active of item i of show_info to false
						display notification "Show marked for removal" with title stop_icon & " Recording Complete." subtitle (show_title of item i of show_info & " on " & show_channel of item i of show_info & " (" & my channel2name(show_channel of item i of show_info as text, hdhr_record of item i of show_info) & ")")
					end if
					
					
					--This needs to happen not in the idle loop.  Since we loop the stored tv shows (show_info), and we are still inside of the repeat loop, we end up trying to walk past the list, kind of a off by 1 error.
					--We can remove these shows on app start, before we start walking the idle loop.  If we want to remove a show, we have to make sure we are not in a loop inside of the idle handler.  We can create an idle lock bit, which can increase the call back time to a much higer number, run our code, and then "unlock" the loop.  This all sounds very sloppy, and i dont like it.  We may just need to mark the show entries as dirty, likely by making making the show_id a missing value.  We would need to clear this out before we get stuck in a repeat loop.  This sounds cleaner.  This also means we need to remove references of the remove_show_info handler,  and stick this in the idle handler, which can have its own host of issues.
				end if
				--else if show_end of item i of show_info < (current date) and show_is_series of item i of show_info = false then 
			else if show_is_series of item i of show_info = false and show_end of item i of show_info < (current date) and show_active of item i of show_info = true then
				set show_active of item i of show_info to false
				display notification show_title of item i of show_info & " removed"
			end if
		end repeat
	end if
	return 12
end idle

on record_now(the_show_id, opt_show_length)
	-- FIX We need to return a true/false if this is successful
	--display notification opt_show_length
	set i to my check_offset(the_show_id)
	my update_show(the_show_id)
	set hdhr_device to hdhr_record of item i of show_info
	if opt_show_length ­ missing value then
		set temp_show_length to opt_show_length as number
	else
		set temp_show_length to show_length of item i of show_info as number
	end if
	if temp_show_length < 0 then
		display notification "Negative duration: " & show_title of item i of show_info
	end if
	if show_transcode of item i of show_info = missing value or show_transcode of item i of show_info = "None" then
		do shell script "caffeinate -i curl '" & my hdhr_prepare_record(hdhr_device) & ":5004" & "/auto/v" & show_channel of item i of show_info & "?duration=" & (temp_show_length) & "' -o " & quoted form of (POSIX path of (show_temp_dir of item i of show_info) & show_title of item i of show_info & "_" & my short_date("record_now0", current date, true) & ".m2ts") & "> /dev/null 2>&1 &"
	else
		do shell script "caffeinate -i curl '" & my hdhr_prepare_record(hdhr_device) & ":5004" & "/auto/v" & show_channel of item i of show_info & "?duration=" & (temp_show_length) & "&transcode=" & show_transcode of item i of show_info & "' -o " & quoted form of (POSIX path of (show_temp_dir of item i of show_info) & show_title of item i of show_info & "_" & my short_date("record_now1", current date, true) & ".mkv") & "> /dev/null 2>&1 &"
		--display dialog "caffeinate -i curl '" & my hdhr_prepare_record(hdhr_device) & ":5004" & "/auto/v" & show_channel of item i of show_info & "?duration=" & (temp_show_length) & "' -o " & quoted form of (POSIX path of (show_temp_dir of item i of show_info) & show_title of item i of show_info & "_" & my short_date("record_now", current date, true) & ".mkv") & "> /dev/null 2>&1 &"
	end if
	
	set show_recording of item i of show_info to true
	--display notification "Recording " & show_title of item i of show_info & " until " & show_end of item i of show_info
	--display dialog show_end of item i of show_info as text 
	--set show_end of item of show_info to (current date) + (show_length of item i of show_info as number)
	
	--	end if 
end record_now

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

on listtostring(theList, delim)
	set oldelim to AppleScript's text item delimiters
	set AppleScript's text item delimiters to delim
	set alist to theList as string
	set AppleScript's text item delimiters to oldelim
	return alist
end listtostring

on short_date(the_caller, the_date_object, twentyfourtime)
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
				return month_string & "." & day_string & "." & year_string & " " & hours_string & "." & minutes_string & timeAMPM
			else
				return year_string & "/" & month_string & "/" & day_string & " " & hours_string & "." & minutes_string & timeAMPM
			end if
		else
			return ""
		end if
	else
		return "?"
	end if
end short_date

on list_position_old(this_item, this_list)
	--	display dialog "thisitem: " & this_item & " " & (this_list as text)
	repeat with i from 1 to length of this_list
		if this_item = item i of this_list then
			return i
		end if
	end repeat
	return 0
end list_position_old

on list_position(caller, this_item, this_list, is_strict)
	log "list_position: " & caller
	--	display dialog "!list_post: " & this_item 
	--	display dialog "!list_post2: " & this_list
	--	display dialog "!list_post3: " & is_strict
	if this_item ­ false then
		repeat with i from 1 to the length of this_list
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

on quit {}
	--add check to see if we are recording.
	set hdhr_quit_record to false
	repeat with i from 1 to length of show_info
		if show_recording of item i of show_info = true then
			set hdhr_quit_record to true
		end if
	end repeat
	if hdhr_quit_record = true then
		--Add currently recorded shows
		set quit_response to button returned of (display dialog "Do you want to cancel recordings already in progress?" buttons {"Go Back", "Yes", "No"} default button 3 with title my check_version_dialog() giving up after dialog_timeout with icon stop)
	else
		my save_data()
		continue quit
	end if
	if quit_response = "Yes" then
		try
			do shell script "pkill curl"
			repeat with i from 1 to length of show_info
				set show_recording of item i of show_info to false
			end repeat
			my save_data()
			continue quit
		end try
	end if
	if quit_response = "No" then
		my save_data()
		continue quit
	end if
	if quit_response = "Go Back" then
		my main()
	end if
	
end quit


------HDHR Disscovery------

on HDHRDeviceDiscovery(caller, hdhr_device)
	log "HDHRDeviceDiscovery: " & caller
	if hdhr_device is not "" then
		set tuner_offset to my HDHRDeviceSearch("HDHRDeviceDiscovery0", hdhr_device)
		--We need to move lineup it its own sub routine.
		--set hdhr_lineup of item tuner_offset of HDHR_TUNERS to my HDHR_api(lineup_url of item tuner_offset of HDHR_TUNERS, "", "", "")
		my getHDHR_Lineup("HDHRDeviceDiscovery0", hdhr_device)
		my getHDHR_Guide("HDHRDeviceDiscovery0", hdhr_device)
		
	else
		set HDHR_DEVICE_LIST to {}
		set progress additional description to "Discovering HDHomeRun Devices."
		set progress completed steps to 0
		set hdhr_device_discovery to my hdhr_api("", "", "", "/discover")
		set progress total steps to length of hdhr_device_discovery
		repeat with i from 1 to length of hdhr_device_discovery
			set progress completed steps to i
			set end of HDHR_DEVICE_LIST to {hdhr_lineup_update:missing value, hdhr_guide_update:missing value, discover_url:DiscoverURL of item i of hdhr_device_discovery, lineup_url:LineupURL of item i of hdhr_device_discovery, device_id:deviceid of item i of hdhr_device_discovery, does_transcode:Transcode of item i of hdhr_device_discovery, hdhr_lineup:missing value, hdhr_guide:missing value, hdhr_model:missing value, channel_mapping:missing value, BaseURL:BaseURL of item i of hdhr_device_discovery}
			log last item of HDHR_DEVICE_LIST
		end repeat
		--Add a fake device entry to make sure we dont break this for multiple devices.
		set end of HDHR_DEVICE_LIST to {hdhr_lineup_update:missing value, hdhr_guide_update:missing value, discover_url:"http://10.0.1.101/discover.json", lineup_url:"http://10.0.1.101/lineup.json", device_id:"XX105404BE", does_transcode:0, hdhr_lineup:missing value, hdhr_guide:missing value, hdhr_model:missing value, channel_mapping:missing value}
		log "Length of HDHR_DEVICE_LIST: " & length of HDHR_DEVICE_LIST
		
		--We now have a list of tuners, via a list of records in HDHR_TUNERS, now we want to pull a lineup, and a guide.
		
		
		if length of hdhr_device_discovery > 0 then
			repeat with i2 from 1 to length of HDHR_DEVICE_LIST
				my HDHRDeviceDiscovery("HDHRDeviceDiscovery0", device_id of item i2 of HDHR_DEVICE_LIST)
			end repeat
		else
			set HDHRDeviceDiscovery_none to display dialog "No HDHR devices can be found." buttons {"Quit", "Rescan"} default button 2 cancel button 1 with title my check_version_dialog() giving up after dialog_timeout
			if button returned of HDHRDeviceDiscovery_none = "Rescan" then
				my HDHRDeviceDiscovery("no_devices", "")
			end if
			
			if button returned of HDHRDeviceDiscovery_none = "Quit" then
				quit {}
			end if
		end if
		--Now that we pulled new data, we need to update the shows we have.
		my update_show("")
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
	log "HDHRDeviceSearch: " & 0
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
		--COnnection issue here hangs up jsonhelper
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
	set progress completed steps to 1
	display notification "Last Updated: " & (my short_date("getHDHR_Guide", current date, false)) with title hdhr_device subtitle "Guide and Lineup Data"
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
	set progress completed steps to 1
end getHDHR_Lineup

on channel_guide(caller, hdhr_device, hdhr_channel, hdhr_time)
	log "channel_guide: " & caller
	set time_slide to 0
	
	if (hdhr_time + 1) < hours of (current date) then
		set time_slide to 1
	end if
	
	set hdhr_proposed_time to my datetime2epoch("channel_guide", (date (date string of ((current date) + time_slide * days))) + hdhr_time * hours - (time to GMT)) as number
	set hdhr_proposed_time to my getTfromN(hdhr_proposed_time)
	log "hdhr_proposed_time"
	log hdhr_proposed_time
	log "---"
	set temp_guide_data to missing value
	set tuner_offset to my HDHRDeviceSearch("channel_guide0", hdhr_device)
	if HDHR_DEVICE_LIST ­ missing value then
		repeat with i from 1 to length of hdhr_guide of item tuner_offset of HDHR_DEVICE_LIST
			if hdhr_channel = GuideNumber of item i of hdhr_guide of item tuner_offset of HDHR_DEVICE_LIST then
				set temp_guide_data to item i of hdhr_guide of item tuner_offset of HDHR_DEVICE_LIST as record
				log "!!!!!"
				log temp_guide_data as record
			end if
		end repeat
		--We need to now parse the json object and try to get the start and end times.
		log "length"
		--FIX missing value
		log length of Guide of temp_guide_data
		repeat with i2 from 1 to length of Guide of temp_guide_data
			log "$1: " & my getTfromN(StartTime of item i2 of Guide of temp_guide_data)
			log "$2: " & hdhr_proposed_time
			try
				log "$3 : " & my getTfromN(EndTime of item i2 of Guide of temp_guide_data)
				log " "
			on error
				display notification "NOTOK 1: " & EndTime of item i2 of Guide of temp_guide_data as text
			end try
			--log StartTime of item i2 of Guide of temp_guide_data
			--log EndTime of item i2 of Guide of temp_guide_data
			--fix We need to also consider if we try to record a show already in progress current date to epoch, and compare.
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
					display notification "NOT OK 2: " & i2
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
		set hdhr_response_channel to {}
		set hdhr_response_channel to my channel_guide("update_show", hdhr_record of item i of show_info, show_channel of item i of show_info, show_time of item i of show_info)
		try
			if length of hdhr_response_channel > 0 then
				try
					set hdhr_response_channel_title to title of hdhr_response_channel
				on error
					set hdhr_response_channel_title to ""
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
					display notification "3: " & show_title of item i of show_info
				end try
				--display dialog (show_next of item i of show_info) as text
				--display dialog (show_length of item i of show_info) as text
				set show_end of item i of show_info to (show_next of item i of show_info) + ((show_length of item i of show_info) * minutes)
				--display notification "Show Updated: " & show_title of item i of show_info
			end if
		on error errmsg
			display notification "updateshow error " & errmsg
		end try
	end if
end update_show

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
		return (show_time_temp_hours & "." & ((show_time_temp_minutes / 60 * 100) as integer)) as text
	else
		return (show_time_temp_hours)
	end if
end epoch2show_time


on save_data()
	--try
	set ref_num to open for access file ((path to documents folder) & savefilename as string) with write permission
	--end try
	set eof of ref_num to 0
	if length of show_info > 0 then
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
				write ("--NEXT SHOW--" & return & show_title of item i of show_info & return & show_time of item i of show_info & return & show_length of item i of show_info & return & my listtostring(show_air_date of item i of show_info, ", ") & return & show_transcode of item i of show_info & return & show_temp_dir of item i of show_info & return & show_dir of item i of show_info & return & show_channel of item i of show_info & return & show_active of item i of show_info & return & show_id of item i of show_info & return & show_recording of item i of show_info & return & show_last of item i of show_info & return & show_next of item i of show_info & return & show_end of item i of show_info & return & show_is_series of item i of show_info & return & hdhr_record of item i of show_info & return) to ref_num
			else
				log trash_icon & " Removed " & show_title of item i of show_info
			end if
			
		end repeat
	else
		log "Save file protected from being wiped."
	end if
	
	try
		set show_info_json to (make JSON from show_info)
		log show_info_json
	on error
		log "json error"
	end try
	
	close access ref_num
	display notification disk_icon & " " & length of show_info & " shows saved"
end save_data
--takes the the data in the filesystem, and writes to to a variable
on read_data()
	--set ref_num to missing value
	set hdhr_vcr_config_file to ((path to documents folder) & savefilename as string)
	log "Config loaded from " & POSIX path of hdhr_vcr_config_file
	set ref_num to open for access file hdhr_vcr_config_file
	log ref_num
	try
		set hdhr_vcr_config_data to read ref_num
		--on error
		--display dialog "Error"  
		--	return 
		set temp_show_info to {}
		set hdhr_vcr_config_data_parsed to my stringtolist("read__data", hdhr_vcr_config_data, return)
		log "read_data"
		--set temp_show_info_template to {show_title:missing value, show_time:missing value, show_length:missing value, show_air_date:missing value, show_transcode:missing value, show_temp_dir:missing value, show_dir:missing value, show_channel:missing value, show_active:true, show_id:(do shell script "date | md5") as text, show_recording:false, show_last:(current date), show_next:missing value, show_end:missing value, notify_upnext_time:missing value, notify_recording_time:missing value}
		repeat with i from 1 to length of hdhr_vcr_config_data_parsed
			if item i of hdhr_vcr_config_data_parsed is "--NEXT SHOW--" then
				log "read_data_start"
				log i
				set end of temp_show_info to {show_title:(item (i + 1) of hdhr_vcr_config_data_parsed), show_time:(item (i + 2) of hdhr_vcr_config_data_parsed), show_length:(item (i + 3) of hdhr_vcr_config_data_parsed), show_air_date:my stringtolist("read_data_showairdate", (item (i + 4) of hdhr_vcr_config_data_parsed), ", "), show_transcode:(item (i + 5) of hdhr_vcr_config_data_parsed), show_temp_dir:(item (i + 6) of hdhr_vcr_config_data_parsed) as alias, show_dir:(item (i + 7) of hdhr_vcr_config_data_parsed) as alias, show_channel:(item (i + 8) of hdhr_vcr_config_data_parsed), show_active:((item (i + 9) of hdhr_vcr_config_data_parsed as boolean)), show_id:(item (i + 10) of hdhr_vcr_config_data_parsed), show_recording:((item (i + 11) of hdhr_vcr_config_data_parsed as boolean)), show_last:date (item (i + 12) of hdhr_vcr_config_data_parsed), show_next:date (item (i + 13) of hdhr_vcr_config_data_parsed), show_end:date (item (i + 14) of hdhr_vcr_config_data_parsed), notify_upnext_time:missing value, notify_recording_time:missing value, show_is_series:((item (i + 15) of hdhr_vcr_config_data_parsed as boolean)), hdhr_record:(item (i + 16) of hdhr_vcr_config_data_parsed)}
				set show_info to temp_show_info
				log show_info
				if show_is_series of last item of temp_show_info = true then
					set show_next of last item of temp_show_info to my nextday(show_id of last item of temp_show_info)
				end if
			end if
		end repeat
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
end read_data

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

on get_my_pid()
	--helpful for debugging, but throws an extra permission ns prompt, so not worth calling to.
	tell application "System Events"
		return get unix id of (every process whose name is (name of me))
	end tell
end get_my_pid