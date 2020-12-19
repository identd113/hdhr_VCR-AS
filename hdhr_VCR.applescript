--Need a way to validate data if wrong in repeat loop, but be able to edit files on demand.
--Need to setup a helper for notifcations.
--We need to write a flat file to save the TV shows, as properties will lose their persistence in big sur
--We should not ask about the tuner until after we click "add"
property show_info : {}
property hdhr_IP : "10.0.1.12"
property hdhr_PORT : ":5004"
property hdhr_TUNER_ct : 0

global temp_show_info
global locale
global channel_list
global HDHR_DEVICE_LIST


global hdhr_setup_folder
global hdhr_setup_transcode
global hdhr_setup_name_bool
global hdhr_setup_length_bool
global notify_upnext
global notify_recording
global hdhr_setup_ran

--{hdhr_lineup_update:missing value, hdhr_guide_update:missing value, discover_url:"http://10.0.1.101/discover.json", lineup_url:"http://10.0.1.101/lineup.json", device_id:"XX105404BE", does_transcode:0, hdhr_lineup:missing value, hdhr_guide:missing value, hdhr_model:missing value}
-- nextup is currently a property, so this value persists through application restarts.  Big Sir will disallow this ability.  I need to be make this a global.  Does one really need to write 

use AppleScript version "2.4"
use scripting additions
use application "JSON Helper"

-- Done Use jsonhelper and json querys to get data.
--show_info model: (*show_title:Happy_Holidays_America, show_time:16, show_length:60, show_air_date:Sunday, show_transcode:missing value, show_temp_dir:alias Backups:, show_dir:alias Backups:, show_channel:5.1, show_active:true, show_id:221fbe1126389e6af35f405aa681cf19, show_recording:false, show_last:date Sunday, December 13, 2020 at 4:04:54 PM, show_next:date Sunday, December 13, 2020 at 4:00:00 PM, show_end:date Sunday, December 13, 2020 at 5:00:00 PM, notify_upnext_time:missing value, notify_recording_time:missing value, hdhr_record:XX105404BE*
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

on hdhr_prepare_record(hdhr_device)
	set tuner_offset to my HDHRDeviceSearch("hdhr_prepare_record0", hdhr_device)
	set temp to my stringtolist("hdhr_prepare_record", discover_url of item tuner_offset of HDHR_DEVICE_LIST, "/")
	return my listtostring(items 1 thru -2 of temp, "/")
end hdhr_prepare_record

on notify_user(the_showid)
end notify_user

on run {}
	set progress description to "Loading " & name of me
	--set global vars
	set notify_upnext to 15
	set notify_recording to 5
	set locale to user locale of (system info)
	set hdhr_setup_folder to "Volumes:"
	set hdhr_setup_transcode to "No"
	set hdhr_setup_name_bool to "No"
	set hdhr_setup_length_bool to "No"
	--We will try to autodiscover the HDHR device on the network, and throw it into a record.
	log "run()"
	
	(*
	This really kicks us off.  The will query to see if there are any HDHomeRun devices on the local network.  This script support multiple devices.
	Once we find some devices, we will query them and pull there lineup data.  This tells us what channels belong to what tags, like "2,4 TPTN"
	We will then pull guide data.  It should be said here that this data is only given for 4 hours ahead of current time, some stations maybe 6.  Special considerations have been made in this script to make this work.  We call this handler and specify "run0".  This is just a made up string that we pass to the next handler, so we can see the request came in that broke the sceript.  This is commonly repeated in my scripts.
	*)
	my HDHRDeviceDiscovery("run0", "")
	
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
	log "check_offset: " & the_show_id
	
	if length of show_info > 0 then
		repeat with i from 1 to length of show_info
			if show_id of item i of show_info = the_show_id then
				log "check_offset2: " & show_id of item i of show_info
				return i
			end if
		end repeat
	end if
	
end check_offset

on build_channel_list(hdhr_device) -- We need to have the two values in a list, so we can reference one, and pull the other, replacing channel2name
	set tuner_offset to my HDHRDeviceSearch("build_channel_list0", hdhr_device)
	set temp to hdhr_lineup of item tuner_offset of HDHR_DEVICE_LIST
	log "length of temp: " & length of temp
	set channel_list to {}
	repeat with i from 1 to length of temp
		try
			if HD of item i of temp = 1 then
				set end of channel_list to GuideNumber of item i of temp & " " & GuideName of item i of temp & " [HD]"
			end if
		on error
			set end of channel_list to GuideNumber of item i of temp & " " & GuideName of item i of temp
		end try
		--set end of channel_list to (item 2 of my stringtolist("channel2name", item i of lineup_temp_list, {"<GuideNumber>", "</GuideNumber>"}) & " (" & channel2name(item 2 of my stringtolist("channel2name", item i of lineup_temp_list, {"<GuideNumber>", "</GuideNumber>"})) & ")")
	end repeat
end build_channel_list
--fix 

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
			log "Shows match"
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
	--(*show_title:news, show_time:12, show_length:30, show_air_date:Monday, Tuesday, Wednesday, Thursday, show_transcode:false, show_temp_dir:alias Macintosh HD:Users:mike.woodfill:Dropbox:, show_dir:alias Macintosh HD:Users:mike.woodfill:Dropbox:, show_channel:11.1, show_active:true, show_id:bf4fcd8b7ac428594a386b373ef55874, show_recording:false, show_last:date Tuesday, August 30, 2016 at 11:35:04 AM, show_next:date Tuesday, August 30, 2016 at 12:00:00 PM, show_end:date Tuesday, August 30, 2016 at 12:30:00 PM*)
	
	if show_to_check = "" then
		repeat with i from 1 to length of show_info
			my validate_show_info(show_id of item i of show_info, should_edit)
		end repeat
	else
		set i to my check_offset(show_to_check)
		log check_offset
		log i
		
		log "Show_air_date: " & show_title of item i of show_info
		if show_title of item i of show_info = missing value or show_title of item i of show_info = "" or should_edit = true then
			set show_title of item i of show_info to text returned of (display dialog "What is the title of this show?" default answer show_title of item i of show_info)
		end if
		
		--repeat until my is_number(show_channel of item i of show_info) or should_edit = true
		if show_channel of item i of show_info = missing value or my is_number(show_channel of item i of show_info) = false or should_edit = true then
			--fix
			--We need to match the recored channel "5.1" with the full list "5.1 WTFC" (channel list) and then have the choose list box jump to that selection.
			
			set temp_channel_offset to my list_position(show_channel of item i of show_info, channel_list, false)
			set channel_temp to word 1 of item 1 of (choose from list channel_list with prompt "What channel does this show air on?" default items item temp_channel_offset of channel_list without empty selection allowed)
			set show_channel of item i of show_info to channel_temp --set show_channel of item i of show_info to word 1 of item 1 of (choose from list channel_list with prompt "What channel does this show air on?" default items show_channel of item i of show_info without empty selection allowed)
		end if
		--end repeat 
		
		if show_time of item i of show_info = missing value or my is_number(show_time of item i of show_info) = false or show_time of item i of show_info ³ 24 or should_edit = true then
			set show_time of item i of show_info to text returned of (display dialog "When does this show air? (use 1-24)" default answer show_time of item i of show_info)
		end if
		
		
		if show_length of item i of show_info = missing value or my is_number(show_length of item i of show_info) = false or show_length of item i of show_info ² 0 or should_edit = true then
			set show_length of item i of show_info to text returned of (display dialog "What is the length of this show?" default answer show_length of item i of show_info)
		end if
		
		if show_air_date of item i of show_info = missing value or length of show_air_date of item i of show_info = 0 or should_edit = true then
			set show_air_date of item i of show_info to (choose from list {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"} default items show_air_date of item i of show_info with multiple selections allowed without empty selection allowed)
		end if
		
		if show_dir of item i of show_info = missing value or (class of (show_temp_dir of item i of show_info) as text) ­ "alias" or should_edit = true then
			set show_dir of item i of show_info to choose folder with prompt "Select Shows Directory" default location show_dir of item i of show_info
			set show_temp_dir of item i of show_info to show_dir of item i of show_info
			--Do a test write to get OSx to prompt for security warning
		end if
		
		if show_next of item i of show_info = missing value or (class of (show_next of item i of show_info) as text) ­ "date" or should_edit = true then
			set show_next of item i of show_info to my nextday(show_id of item i of show_info)
		end if
	end if
end validate_show_info

on setup()
	set hdhr_setup_response to (display dialog "hdhr_VCR Setup." buttons {"Defaults", "Delete", "Run"} default button 1)
	if button returned of hdhr_setup_response = "Defaults" then
		set hdhr_setup_folder to choose folder with prompt "Select default Shows Directory" default location hdhr_setup_folder
		--write data here
		display dialog "We need to allow notifications." & return & "Click \"Next\" to continue." buttons {"Next"} default button 1
		display notification "Yay!" with title name of me subtitle "Notifications Enabled!"
		set hdhr_setup_transcode to button returned of (display dialog "Use transcoding with \"Extend\" devices?" buttons {"Yes", "No"} default button 2)
		set hdhr_setup_name_bool to button returned of (display dialog "Use custom naming?" buttons {"Yes", "No"} default button 2)
		set hdhr_setup_length_bool to button returned of (display dialog "Use custom show length? (minutes)" buttons {"Yes", "No"} default button 2) --default answer "30"
		set notify_upnext to text returned of (display dialog "How often to show \"Up Next\" update notifications?" default answer notify_upnext)
		set notify_recording to text returned of (display dialog "How often to show \"Up Next\" update notifications?" default answer notify_recording)
		set hdhr_setup_ran to true
	end if
	if button returned of hdhr_setup_response = "Delete" then
	end if
	
end setup

on main()
	if length of HDHR_DEVICE_LIST > 0 then
		--gather tuner names
		set temp_tuners_list to {}
		--set end of temp_tuners_list to "Auto"
		repeat with i from 1 to length of HDHR_DEVICE_LIST
			
			log "main()"
			log item i of HDHR_DEVICE_LIST
			set end of temp_tuners_list to hdhr_model of item i of HDHR_DEVICE_LIST & " " & (device_id of item i of HDHR_DEVICE_LIST)
		end repeat
		if length of HDHR_DEVICE_LIST = 1 then
			set preferred_tuner_offset to device_id of item 1 of HDHR_DEVICE_LIST
		else
			set preferred_tuner to choose from list temp_tuners_list with prompt "Multiple Devices found, please choose one.  Select \"Auto\" to use first available device." cancel button name "Quit"
			if preferred_tuner ­ false then
				set preferred_tuner_offset to last word of item 1 of preferred_tuner
			else
				set preferred_tuner_offset to missing value
			end if
		end if
	end if
	
	if preferred_tuner_offset = missing value then
		quit {}
	end if
	
	-- This gets out list of channel and channel names.  There is a better way to do this (from guide data maybe? bit this is a hold over from v1, and it works.
	my build_channel_list(preferred_tuner_offset)
	--This will make sure that data we have stored is valid
	my validate_show_info("", false)
	--Collect the temporary name.  This will likely be over written once we can pull guide data
	set title_response to (display dialog "Would you like to add a show?" buttons {"Shows..", "Add..", "Run.."} default button 2)
	
	if button returned of title_response = "Add.." then
		my add_show_info(preferred_tuner_offset)
	end if
	
	if button returned of title_response = "Shows.." then
		--display dialog button returned of title_response
		set show_list to {}
		--display dialog length of show_info
		repeat with i from 1 to length of show_info
			--set end of show_list to (show_title of item i of show_info & "\" on " & show_channel of item i of show_info & " at " & show_time of item i of show_info & " for " & show_length of item i of show_info & " minutes on " & show_air_date)
			set end of show_list to (show_title of item i of show_info & " on " & show_channel of item i of show_info & " at " & show_time of item i of show_info & " for " & show_length of item i of show_info & " minutes on " & my listtostring(show_air_date of item i of show_info, ", "))
		end repeat
		--display dialog length of show_list
		if length of show_list ³ 1 then
			--			set YY to (choose from list show_list)
			-- Fix We cant always match this. 
			my validate_show_info(show_id of item (my list_position(((choose from list show_list) as text), show_list, true)) of show_info, true)
			--			set XX to my list_position((YY as text), show_list)
			--			display dialog "XX: " & XX
			--			my validate_show_info(show_id of item XX of show_info, true)
			
		else if length of show_list = 0 then
			--	display dialog "2"
			try
				set hdhr_no_shows to button returned of (display dialog "There are no shows, why don't you add one?" buttons {"Quit", "Add Show"} default button 2)
				if hdhr_no_shows = "Add Show" then
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
		end if
	end if
	
end main

on add_show_info(hdhr_device)
	set tuner_offset to my HDHRDeviceSearch("add_show_info0", hdhr_device)
	set show_channel to missing value
	set temp_show_info to {show_title:missing value, show_time:missing value, show_length:missing value, show_air_date:missing value, show_transcode:missing value, show_temp_dir:missing value, show_dir:missing value, show_channel:missing value, show_active:true, show_id:(do shell script "date | md5") as text, show_recording:false, show_last:(current date), show_next:missing value, show_end:missing value, notify_upnext_time:missing value, notify_recording_time:missing value, hdhr_record:hdhr_device}
	
	
	repeat until my is_number(show_channel of temp_show_info)
		try
			--	
			set show_channel of temp_show_info to word 1 of item 1 of (choose from list channel_list with prompt "What channel does this show air on?" without empty selection allowed)
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
		set show_time of temp_show_info to text returned of (display dialog "When does this show air? " & return & "(0-24, use decimals, ie 9.5 for 9:30)" default answer "") as number
		--if my is_number(show_time of temp_show_info) = false then 
		
		--set show_time of temp_show_info to missing value
		--else
		--set show_time of temp_show_info to my time_shift((show_time of temp_show_info as number) * hours)
		--set show_time of temp_show_info to show_time of temp_show_info as number
		--end if
	end repeat
	
	-- We know the channel and time, we can refer to our guid data to pull the name of the show.  If we dont know of it yet, we can ask the user.
	log "Add_show"
	--log title of my channel_guide(hdhr_device, show_channel of temp_show_info, show_time of temp_show_info)
	--fix we error here if we cannot pull guidedata
	set hdhr_response_channel to my channel_guide(hdhr_device, show_channel of temp_show_info, show_time of temp_show_info)
	log hdhr_response_channel
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
	
	set show_title of temp_show_info to text returned of (display dialog "What is the title of this show?" default answer hdhr_response_channel_title)
	
	if show_title of temp_show_info contains " " then
		set show_title of temp_show_info to my listtostring(my stringtolist("show title", show_title of temp_show_info, " "), "_")
	end if
	
	--display notification "OK6: " & show_title of temp_show_info 
	log "@!@"
	--	log hdhr_response_channel
	set hdhr_response_length to 30
	try
		set hdhr_response_length to ((EndTime of hdhr_response_channel) - (StartTime of hdhr_response_channel)) div 60
		log hdhr_response_length
	on error
		--	display notification "OK4: " & hdhr_response_channel
	end try
	repeat until my is_number(show_length of temp_show_info) and show_length of temp_show_info ³ 1
		--display notification "OK7: TEST"
		set show_length of temp_show_info to text returned of (display dialog "How long is this show? (in minutes)" default answer hdhr_response_length)
		--if my is_number(show_length of temp_show_info) = false then
		--	set show_length of temp_show_info to missing value
		--else
		--set show_length of temp_show_info to show_length of temp_show_info as number
		--show_length needs to support decimels
		--end if
	end repeat
	
	
	--fix We need to ensure we are able to pull guide data, if not, we set to ""
	if hdhr_response_channel_title ­ "" then
		set default_record_day to (weekday of (current date)) as text
	else
		set default_record_day to ""
	end if
	
	set show_air_date of temp_show_info to (choose from list {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"} with prompt "Please choose the days this show airs." default items default_record_day with multiple selections allowed without empty selection allowed)
	
	set temp_dir to alias "Volumes:"
	repeat until temp_dir ­ alias "Volumes:"
		set show_dir of temp_show_info to choose folder with prompt "Select Shows Directory" default location temp_dir
		if show_dir of temp_show_info ­ temp_dir then
			set temp_dir to show_dir of temp_show_info
		end if
	end repeat
	--We attempt to write a small file to shows folder.  This will prompt the user in the OS to allow this app to write data there. 
	do shell script "touch " & POSIX path of (show_dir of temp_show_info) & "hdhr_test_write"
	delay 0.1
	do shell script "rm " & POSIX path of (show_dir of temp_show_info) & "hdhr_test_write"
	set model_response to ""
	
	--try
	--log "does_transcode: " & does_transcode of item tuner_offset of HDHR_DEVICE_LIST
	--set model_response to (do shell script "curl http://" & hdhr_IP & "/ | grep 'HDHomeRun' | grep 'div class'")
	--log "model_response: " & model_response
	--http://10.0.1.101/discover.json
	--end try
	
	if does_transcode of item tuner_offset of HDHR_DEVICE_LIST = 1 then
		set show_transcode of temp_show_info to word 1 of item 1 of (choose from list {"None: Does not transcode, will save as MPEG2 stream.", "heavy: Transcode with same settings", "mobile: Transcode not exceeding 1280x720 30fps", "intenet720: Low bit rate, not exceeding 1280x720 30fps", "internet480: Low bit rate not exceeding 848x480/640x480 for 16:9/4:3 30fps", "internet360: Low bit rate not exceeding 640x360/480x360 for 16:9/4:3 30fps", "internet240: Low bit rate not exceeding 432x240/320x240 for 16:9/4:3 30fps"} with prompt "Please choose the transcode level on the file" default items {"None: Does not transcode, will save as MPEG2 stream."})
	else
		set show_transcode of temp_show_info to missing value
	end if
	
	set show_temp_dir of temp_show_info to show_dir of temp_show_info
	--	end if
	set end of show_info to temp_show_info
	set show_next of last item of show_info to my nextday(show_id of temp_show_info)
	my validate_show_info(show_id of last item of show_info, false)
	log show_info
end add_show_info

on idle
	set cd_object to (current date) + 15
	--Re run auto discover every 2 hours. 
	if length of HDHR_DEVICE_LIST > 0 then
		repeat with i2 from 1 to length of HDHR_DEVICE_LIST
			if ((cd_object) - (hdhr_guide_update of item i2 of HDHR_DEVICE_LIST)) div 60 ³ 120 then
				my HDHRDeviceDiscovery("idle0", "")
			end if
		end repeat
	end if
	if length of show_info > 0 then
		--	display notification "1.5"
		repeat with i from 1 to length of show_info
			
			if show_recording of item i of show_info = true then
				if show_end of item i of show_info < (current date) then
					set show_last of item i of show_info to show_end of item i of show_info
					set show_next of item i of show_info to my nextday(show_id of item i of show_info)
					set show_recording of item i of show_info to false
					--display notification show_title of item i of show_info & " has ended."
					
					--Fix channel2name is not used any longer
					display notification "Next Showing: " & my short_date("rec_end", show_next of item i of show_info, false) with title "Recording Complete." subtitle (show_title of item i of show_info & " on " & show_channel of item i of show_info & " (" & my channel2name(show_channel of item i of show_info as text, hdhr_record of item i of show_info) & ")")
				end if
			end if
			
			if show_active of item i of show_info = true then
				if show_next of item i of show_info < cd_object then
					if show_recording of item i of show_info = false then
						set show_runtime to (show_end of item i of show_info) - (current date)
						my record_now((show_id of item i of show_info), show_runtime)
						display notification "Ends " & my short_date("rec started", show_end of item i of show_info, false) with title "Started Recording... (" & hdhr_record of item i of show_info & ")" subtitle show_title of item i of show_info & " on " & show_channel of item i of show_info & " (" & my channel2name(show_channel of item i of show_info as text, hdhr_record of item i of show_info) & ")"
						set notify_recording_time of item i of show_info to (current date) + (2 * minutes)
						--display notification show_title of item i of show_info & " on channel " & show_channel of item i of show_info & " started for " & show_runtime of item i of show_info & " minutes."
					else
						--display notification show_title of item i of show_info & " is recording until " & my short_date("recording", show_end of item i of show_info)
						if notify_recording_time of item i of show_info < (current date) or notify_recording_time of item i of show_info = missing value then
							display notification "Ends " & my short_date("rec started", show_end of item i of show_info, false) & " (" & (my sec_to_time((show_end of item i of show_info) - (current date))) & ") " with title "Recording in progress... (" & hdhr_record of item i of show_info & ")" subtitle show_title of item i of show_info & " on " & show_channel of item i of show_info & " (" & my channel2name(show_channel of item i of show_info as text, hdhr_record of item i of show_info) & ")"
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
				if notify_upnext_time of item i of show_info < (current date) or notify_upnext_time of item i of show_info = missing value then
					--This line is a hot mess, as it reports too often.  Lets try some progress bar hacks.
					
					--	set progress description to "Loading ..."
					--  set progress additional description to
					--	set progress completed steps to 0
					--	set progress total steps to 1
					
					--set progress description to "Next up... (" & hdhr_record of item i of show_info & ")"
					--set progress additional description to "Starts: " & my short_date("is_next", show_next of item i of show_info, false)
					display notification "Starts: " & my short_date("is_next", show_next of item i of show_info, false) with title "Next up... (" & hdhr_record of item i of show_info & ")" subtitle show_title of item i of show_info & " on " & show_channel of item i of show_info & " (" & my channel2name(show_channel of item i of show_info, hdhr_record of item i of show_info) & ")"
					set notify_upnext_time of item i of show_info to (current date) + (notify_upnext * minutes)
				end if
				--	set delay_count to 0 
				--end if
				
			end if
			
		end repeat
	end if
	return 16
end idle

on record_now(the_show_id, opt_show_length)
	set i to my check_offset(the_show_id)
	my update_show(the_show_id)
	
	(*
	set hdhr_response_channel to my channel_guide(hdhr_record of item i of show_info, show_channel of item i of show_info, show_time of item i of show_info)
	
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
	--fix endtime of 0 is not allowed
	set show_length of item i of show_info to ((EndTime of hdhr_response_channel) - (StartTime of hdhr_response_channel)) div 60
	--display dialog (show_next of item i of show_info) as text
	--display dialog (show_length of item i of show_info) as text
	set show_end of item i of show_info to (show_next of item i of show_info) + ((show_length of item i of show_info) * minutes)
		*)
	set hdhr_device to hdhr_record of item i of show_info
	if opt_show_length ­ missing value then
		set temp_show_length to opt_show_length as number
	else
		set temp_show_length to show_length of item i of show_info as number
	end if
	--do shell script "curl --max-time " & (temp_show_length) & " http://" & hdhr_IP & "/auto/v" & show_channel of item i of show_info & " -o " & quoted form of (POSIX path of (show_temp_dir of item i of show_info) & show_title of item i of show_info & "_" & my short_date("record_now", current date) & ".m2ts") & "> /dev/null 2>&1 &"
	if show_transcode of item i of show_info = missing value or show_transcode of item i of show_info = "None" then
		--We need to fix this as well, we do not refer to hdhr_ip and port any longer
		do shell script "caffeinate -i curl '" & my hdhr_prepare_record(hdhr_device) & ":5004" & "/auto/v" & show_channel of item i of show_info & "?duration=" & (temp_show_length) & "' -o " & quoted form of (POSIX path of (show_temp_dir of item i of show_info) & show_title of item i of show_info & "_" & my short_date("record_now", current date, true) & ".m2ts") & "> /dev/null 2>&1 &"
	else
		do shell script "caffeinate -i curl '" & my hdhr_prepare_record(hdhr_device) & ":5004" & "/auto/v" & show_channel of item i of show_info & "?duration=" & (temp_show_length) & "&transcode=" & show_transcode of item i of show_info & "' -o " & quoted form of (POSIX path of (show_temp_dir of item i of show_info) & show_title of item i of show_info & "_" & my short_date("record_now", current date, true) & ".mkv") & "> /dev/null 2>&1 &"
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
	--Fix add option to allow for AM/PM times
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
					if hours_string > 13 then
						set hours_string to (hours_string - 12)
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

on list_position(this_item, this_list, is_strict)
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
		set quit_response to button returned of (display dialog "Do you want to cancel the ongoing jobs?" buttons {"Go Back", "No", "Yes"} default button 3)
		if quit_response = "Yes" then
			try
				do shell script "pkill curl"
				repeat with i from 1 to length of show_info
					set show_recording of item i of show_info to false
				end repeat
			end try
		end if
	end if
	continue quit
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
			set end of HDHR_DEVICE_LIST to {hdhr_lineup_update:missing value, hdhr_guide_update:missing value, discover_url:DiscoverURL of item i of hdhr_device_discovery, lineup_url:LineupURL of item i of hdhr_device_discovery, device_id:deviceid of item i of hdhr_device_discovery, does_transcode:Transcode of item i of hdhr_device_discovery, hdhr_lineup:missing value, hdhr_guide:missing value, hdhr_model:missing value}
			log last item of HDHR_DEVICE_LIST
		end repeat
		--Add a fake device entry to make sure we dont break this for multiple devices.
		--FIX set end of HDHR_DEVICE_LIST to {hdhr_lineup_update:missing value, hdhr_guide_update:missing value, discover_url:"http://10.0.1.101/discover.json", lineup_url:"http://10.0.1.101/lineup.json", device_id:"XX105404BE", does_transcode:0, hdhr_lineup:missing value, hdhr_guide:missing value, hdhr_model:missing value}
		log "Length of HDHR_DEVICE_LIST: " & length of HDHR_DEVICE_LIST
		
		--We now have a list of tuners, via a list of records in HDHR_TUNERS, now we want to pull a lineup, and a guide.
		
		
		if length of hdhr_device_discovery > 0 then
			repeat with i2 from 1 to length of HDHR_DEVICE_LIST
				my HDHRDeviceDiscovery("HDHRDeviceDiscovery0", device_id of item i2 of HDHR_DEVICE_LIST)
			end repeat
		else
			display dialog "No HDHR devices can be found."
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

on channel_guide(hdhr_device, hdhr_channel, hdhr_time)
	set hdhr_proposed_time to my datetime2epoch((date (date string of (current date))) + hdhr_time * hours - (time to GMT)) as number
	log "hdhr_proposed_time"
	log hdhr_proposed_time
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
		log length of Guide of temp_guide_data
		set hdhr_proposed_time to my getTfromN(hdhr_proposed_time)
		repeat with i2 from 1 to length of Guide of temp_guide_data
			log "$1: " & my getTfromN(StartTime of item i2 of Guide of temp_guide_data)
			log "$2: " & hdhr_proposed_time
			try
				log "$3 : " & my getTfromN(EndTime of item i2 of Guide of temp_guide_data)
			on error
				display notification "NOTOK 1: " & EndTime of item i2 of Guide of temp_guide_data as text
			end try
			--log StartTime of item i2 of Guide of temp_guide_data
			--log EndTime of item i2 of Guide of temp_guide_data
			--fix We need to also consider if we try to record a show already in progress current date to epoch, and compare.
			if (hdhr_proposed_time) ³ my getTfromN(StartTime of item i2 of Guide of temp_guide_data) then
				log "11: " & (hdhr_proposed_time) & "=" & my getTfromN(StartTime of item i2 of Guide of temp_guide_data)
				try
					if (hdhr_proposed_time) ² my getTfromN(EndTime of item i2 of Guide of temp_guide_data) then
						log "2: " & (hdhr_proposed_time) & "²" & my getTfromN(EndTime of item i2 of Guide of temp_guide_data)
						--try
						log "$Match"
						--end try
						
						return item i2 of Guide of temp_guide_data
					end if
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
		set hdhr_response_channel to my channel_guide(hdhr_record of item i of show_info, show_channel of item i of show_info, show_time of item i of show_info)
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
				--fix endtime of 0 is not allowed -- this happends if we have a show in the early AM
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

on datetime2epoch(the_date_object)
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

on save_data()
	set ref_num to open for access file ((path to documents folder) & savefilename as string) with write permission
	set eof of ref_num to 0
	repeat with i from 1 to length of show_info
		write ("--NEXT SHOW--" & return & show_title of item i of show_info & return & show_time of item i of show_info & return & show_length of item i of show_info & return & my listtostring(show_air_date of item i of show_info, ", ") & return & show_transcode of item i of show_info & return & show_temp_dir of item i of show_info & return & show_dir of item i of show_info & return & show_channel of item i of show_info & return & show_active of item i of show_info & return & show_id of item i of show_info & return & show_recording of item i of show_info & return & show_last of item i of show_info & return & show_next of item i of show_info & return & show_end of item i of show_info & return) & (show_is_series of item i of show_info & return) to ref_num
		--write calendar_name & return & the_location & return & Event_name & return & shift_length to ref_num
	end repeat
	
	close access ref_num
end save_data
--takes the the data in the filesystem, and writes to to a variable
on read_data()
	set hdhr_vcr_config_file to ((path to documents folder) & savefilename as string)
	
	set ref_num to open for access file hdhr_vcr_config_file --with write permission
	log ref_num
	try
		set hdhr_vcr_config_data to read ref_num
	on error
		display dialog "Error"
		close access ref_num
		return
	end try
	set temp_show_info to {}
	set hdhr_vcr_config_data_parsed to my stringtolist("read__data", hdhr_vcr_config_data, return)
	--set temp_show_info_template to {show_title:missing value, show_time:missing value, show_length:missing value, show_air_date:missing value, show_transcode:missing value, show_temp_dir:missing value, show_dir:missing value, show_channel:missing value, show_active:true, show_id:(do shell script "date | md5") as text, show_recording:false, show_last:(current date), show_next:missing value, show_end:missing value, notify_upnext_time:missing value, notify_recording_time:missing value}
	repeat with i from 1 to length of hdhr_vcr_config_data_parsed
		if item i of hdhr_vcr_config_data_parsed is "--NEXT SHOW--" then
			set end of temp_show_info to {show_title:(item (i + 1) of hdhr_vcr_config_data_parsed), show_time:(item (i + 2) of hdhr_vcr_config_data_parsed), show_length:(item (i + 3) of hdhr_vcr_config_data_parsed), show_air_date:my stringtolist("read_data_showairdate", (item (i + 4) of hdhr_vcr_config_data_parsed), ", "), show_transcode:(item (i + 5) of hdhr_vcr_config_data_parsed), show_temp_dir:(item (i + 6) of hdhr_vcr_config_data_parsed) as alias, show_dir:(item (i + 7) of hdhr_vcr_config_data_parsed) as alias, show_channel:(item (i + 8) of hdhr_vcr_config_data_parsed), show_active:(item (i + 9) of hdhr_vcr_config_data_parsed), show_id:(item (i + 10) of hdhr_vcr_config_data_parsed), show_recording:(item (i + 11) of hdhr_vcr_config_data_parsed), show_last:date (item (i + 12) of hdhr_vcr_config_data_parsed), show_next:date (item (i + 13) of hdhr_vcr_config_data_parsed), show_end:date (item (i + 14) of hdhr_vcr_config_data_parsed), notify_upnext_time:missing value, notify_recording_time:missing value, show_is_series:(item (i + 15) of hdhr_vcr_config_data_parsed)}
			set show_info to temp_show_info
			set show_next of last item of temp_show_info to my nextday(show_id of last item of temp_show_info)
		end if
	end repeat
	log temp_show_info
	close access ref_num
	--set {calendar_name, the_location, Event_name, shift_length} to stringtolist(ienterdata, return)
end read_data