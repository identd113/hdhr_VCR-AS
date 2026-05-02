# hdhr_vcr library.  This needs to be located in the users Documents Folder, and not renamed.

global hdhrVCR_loaded
property ParentScript : missing value

on run {}
	open ParentScript
end run

on cm(handlername, caller)
	return {handlername & "(" & caller & ")"} as text
end cm

on load_hdhrVCR_vars()
	set handlername to "load_hdhrVCR_vars_lib"
	-- We need to receive states from the hdhr_vcr here
	set vers_lib to "20260426"
	return vers_lib
end load_hdhrVCR_vars

on checkDiskSpace(caller, the_path)
	set handlername to "checkDiskSpace_lib"
	try
		set checkDiskSpace_return to do shell script "df -k '" & the_path & "'"
		set checkDiskSpace_temp1 to item 2 of my stringlistflip(my cm(handlername, caller), checkDiskSpace_return, return, "list")
		set checkDiskSpace_temp2 to my emptylist(my cm(handlername, caller), my stringlistflip(my cm(handlername, caller), checkDiskSpace_temp1, space, "list"))
		return {the_path, first word of item 5 of checkDiskSpace_temp2 as number, first word of item 4 of checkDiskSpace_temp2 as number}
	on error errmsg
		return {the_path, 0, errmsg}
	end try
end checkDiskSpace

on checkfileexists(caller, filepath)
	set handlername to "checkfileexists_lib"
	try
		if filepath is missing value then
			logger(true, handlername, caller, "WARN", "filepath is missing value") of ParentScript
			return false
		end if

		set filepath_text to filepath as text
		if filepath_text is "" then
			logger(true, handlername, caller, "WARN", "filepath is empty") of ParentScript
			return false
		end if

		logger(true, handlername, caller, "INFO", filepath_text) of ParentScript
		logger(true, handlername, caller, "DEBUG", "filepath class is " & (class of filepath as text)) of ParentScript

		set filepath_posix to ""

		-- Try to convert alias path format (e.g. "Raid6:DVR Tests:") to POSIX path
		if filepath_text contains ":" and (character 1 of filepath_text) is not "/" then
			try
				-- Convert Mac alias path to POSIX: "Raid6:DVR Tests:" -> "/Volumes/Raid6/DVR Tests"
				set posix_attempt to filepath_text
				set posix_attempt to text 1 through -2 of posix_attempt -- Remove trailing colon: "Raid6:DVR Tests"
				set old_delim to AppleScript's text item delimiters
				set AppleScript's text item delimiters to ":"
				set path_parts to every text item of posix_attempt
				set AppleScript's text item delimiters to "/"
				set posix_attempt to path_parts as text
				set AppleScript's text item delimiters to old_delim
				set posix_attempt to "/Volumes/" & posix_attempt
				do shell script "test -e " & quoted form of posix_attempt
				set filepath_posix to posix_attempt
				logger(true, handlername, caller, "DEBUG", "Converted alias path to POSIX: " & filepath_posix) of ParentScript
			on error
				-- If that fails, try standard POSIX conversion
				try
					set filepath_posix to POSIX path of filepath_text
				on error
					set filepath_posix to filepath_text
				end try
			end try
		else
			-- Already a POSIX path or file reference
			try
				set filepath_posix to POSIX path of filepath_text
			on error
				set filepath_posix to filepath_text
			end try
		end if

		logger(true, handlername, caller, "TRACE", "filepath normalized to: " & filepath_posix) of ParentScript

		try
			do shell script "test -e " & quoted form of filepath_posix
			return true
		on error errmsg number errnum
			if errnum is 1 then return false
			logger(true, handlername, caller, "ERROR", "test -e failed (" & errnum & "): " & errmsg) of ParentScript
			return false
		end try
	on error errmsg number errnum
		logger(true, handlername, caller, "ERROR", "Unable to validate filepath (" & errnum & "): " & errmsg) of ParentScript
		return false
	end try
end checkfileexists


on emptylist(caller, klist)
	set handlername to "emptylist_lib"
	try
		set nlist to {}
		set dataLength to length of klist
		repeat with i from 1 to dataLength
			if item i of klist is not in {"", {}} then
				set end of nlist to (item i of klist)
			end if
		end repeat
		return nlist
	on error errmsg
		return {handlername, errmsg}
	end try
end emptylist

on stringlistflip(caller, thearg, delim, returned)
	set handlername to "stringlistflip_lib"
	try
		set oldelim to AppleScript's text item delimiters
		set AppleScript's text item delimiters to delim
		try
			if returned is "list" then
				set dlist to (every text item of thearg)
			else if returned is "string" then
				set dlist to thearg as text
			end if
			set AppleScript's text item delimiters to oldelim
		on error errmsg
			set AppleScript's text item delimiters to oldelim
		end try
		return dlist
	on error errmsg
		return {handlername, errmsg}
	end try
end stringlistflip

on epoch(cd)
	set handlername to "epoch_lib"
	try
		if cd is in {"", {}} then
			set epoch_time to current date
		else
			set epoch_time to cd
		end if
		set day of epoch_time to 1
		set hours of epoch_time to 0
		set minutes of epoch_time to 0
		set seconds of epoch_time to 0
		set year of epoch_time to "1970"
		set month of epoch_time to "1"
		set day of epoch_time to "1"
		return epoch_time
	on error errmsg
		return {handlername, errmsg}
	end try
end epoch

on replace_chars(thestring, target, replacement)
	set handlername to "replace_chars_lib"
	try
		set oldelim to AppleScript's text item delimiters
		try
			set AppleScript's text item delimiters to target
			set theItems to every text item of thestring
			set AppleScript's text item delimiters to replacement
			set thestring to theItems as text
			set AppleScript's text item delimiters to oldelim
		on error errmsg
			set AppleScript's text item delimiters to oldelim
		end try
		return thestring
	on error errmsg
		return {handlername, errmsg}
	end try
end replace_chars

on fixDate(caller, theDate) --We may be able to remove this, since updating stringToUtf8
	set handlername to "fixDate_lib"
	try
		set thedate_text to (theDate as string)
		set thedate_list to my stringlistflip(handlername, thedate_text, {character id 8239, " "}, "list")
		set finalDate to my stringlistflip(handlername, thedate_list, " ", "string")
		return finalDate
	on error errmsg
		return {handlername, errmsg}
	end try
end fixDate

on stringToUtf8(caller, thestring)
	set handlername to "stringToUtf8_lib"
	set non_utf8 to {"�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", character id 8239, ":"}
	set fixed_utf8 to {"a", "e", "i", "o", "u", "A", "E", "I", "O", "U", "a", "e", "i", "o", "u", "A", "E", "I", "O", "U", "a", "e", "i", "o", "u", "A", "E", "I", "O", "U", "a", "e", "i", "o", "u", "A", "E", "I", "O", "U", "a", "n", "o", "A", "N", "O", "a", "A", "c", "C", "o", "O", " ", ""}
	set fixed_string to thestring
	try
		if my itemsInString(caller, non_utf8, thestring) is true then
			repeat with i from 1 to length of non_utf8
				set fixed_string to my replace_chars(fixed_string, item i of non_utf8, item i of fixed_utf8)
			end repeat
		end if
		if thestring is not fixed_string then
			logger(true, handlername, caller, "INFO", quote & thestring & quote & " stripped characters") of ParentScript
		end if
		return fixed_string
	on error errmsg
		return {handlername, errmsg}
	end try
end stringToUtf8

on isSystemShutdown(caller)
	set handlername to "isSystemShutdown_lib"
	try
		set Shutdown_reason to "No shutdown attempted"
		set temp to do shell script "log show --last 1m --predicate 'eventMessage contains \"com.apple.system.loginwindow.shutdownInitiated\" or eventMessage contains \"com.apple.system.loginwindow.restartinitiated\" or eventMessage contains \"logoutcancelled\"'"
		set xtemp to my stringlistflip("isSystemShutdown", temp, return, "list")
		repeat with i from length of xtemp to 1 by -1
			if item i of xtemp contains "sendSystemBSDNotification" then
				if item i of xtemp does not contain "noninteractively" then
					
					if item i of xtemp contains "logoutcancelled" then
						set Shutdown_reason to "Shutdown Cancelled"
						return false
					end if
					
					if item i of xtemp contains "restartinitiated" then
						set Shutdown_reason to "Restart"
						return true
					end if
					
					if item i of xtemp contains "shutdownInitiated" then
						set Shutdown_reason to "Shutdown"
						return true
					end if
				end if
			end if
			--set Shutdown_reason to "No shutdown attempted"
		end repeat
		return false
	on error errmsg
		return {handlername, errmsg}
	end try
end isSystemShutdown

on repeatProgress(caller, loop_delay, loop_total)
	set handlername to "repeatProgress_lib"
	try
		set progress total steps to loop_total
		set progress completed steps to 0
		delay loop_delay
		repeat with i from 1 to loop_total
			delay loop_delay
			set progress completed steps to i
		end repeat
	on error errmsg
		return {handlername, errmsg}
	end try
end repeatProgress

on ms2time(caller, totalMS, time_duration, level_precision)
	set handlername to "ms2time_lib"
	try
		set totalMS to totalMS as number
		if totalMS is less than 0 then
			return "ended"
		end if
		set temp_time_string to {}
		set numseconds to 0
		set numinutes to 0
		set numhours to 0
		set numdays to 0
		set numyears to 0
		if time_duration is "ms" then
			if totalMS is greater than 0 and totalMS is less than 1000 then
				return ("<1s")
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
		if level_precision is greater than length of temp_time_string then
			set level_precision to length of temp_time_string
		end if
		if level_precision is not 0 then
			set temp_time_string to items 1 thru (item level_precision) of temp_time_string
		end if
		if length of temp_time_string is not 0 then
			logger(true, handlername, caller, "TRACE", "Result: " & temp_time_string) of ParentScript
			return my stringlistflip(my cm(handlername, caller), temp_time_string, " ", "string")
		else
			logger(true, handlername, caller, "TRACE", "Result: 0ms") of ParentScript
			return my stringlistflip(my cm(handlername, caller), "0ms", " ", "string")
		end if
	on error errmsg
		return {handlername, errmsg}
	end try
end ms2time

on list_position(caller, this_item, this_list, is_strict)
	set handlername to "list_position_lib"
	try
		logger(true, handlername, caller, "DEBUG", this_item & ", " & this_list) of ParentScript
		if this_item is not false then
			repeat with i from 1 to length of this_list
				if is_strict is false then
					if (item i of this_list as text) contains (this_item as text) then
						logger(true, handlername, caller, "DEBUG", "Offset contains: " & i) of ParentScript
						return i
					end if
				else
					if (item i of this_list as text) is (this_item as text) then
						logger(true, handlername, caller, "DEBUG", "Offset is: " & i) of ParentScript
						return i
					end if
				end if
			end repeat
		end if
		return 0
	on error errmsg
		return {handlername, errmsg}
	end try
end list_position

on short_date(caller, the_date_object, twentyfourtime, show_seconds)
	set handlername to "short_date_lib"
	try
		set locale to locale of ParentScript
		set timeAMPM to ""
		
		-- takes date object, and converts to a shorter time string
		if the_date_object is "?" then return "?"
		if the_date_object is "" then return ""
		
		-- Year last 2 digits
		set year_string to (items -2 thru end of ((year of the_date_object) as text))
		
		-- Pull numeric parts as integers first
		set theMonth to (month of the_date_object) * 1
		set theDay to day of the_date_object
		set theHour to hours of the_date_object
		set theMinute to minutes of the_date_object
		set theSecond to seconds of the_date_object
		-- Pad using padnum
		set month_string to my padnum(my cm(handlername, caller), theMonth, false)
		set day_string to my padnum(my cm(handlername, caller), theDay, false)
		set minutes_string to my padnum(my cm(handlername, caller), theMinute, false)
		set seconds_string to my padnum(my cm(handlername, caller), theSecond, false)
		
		-- Hours handling
		if twentyfourtime is false then
			if theHour >= 12 then
				set timeAMPM to " PM"
				if theHour > 12 then set theHour to theHour - 12
			else
				set timeAMPM to " AM"
			end if
			
			-- 12-hour clock midnight/noon rules
			if theHour is 0 then set theHour to 12
			
			-- In 12-hour mode you typically *don�t* want a leading zero,
			-- but if you DO want it, swap the next line for padnum(...)
			set hours_string to (theHour as text)
		else
			-- 24-hour mode: pad to 2 digits
			set hours_string to my padnum(my cm(handlername, caller), theHour, false)
		end if
		
		if locale is "en_US" then
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
		
	on error errmsg
		return {handlername, errmsg}
	end try
end short_date

on padnum(caller, thenum, splitdot)
	set handlername to "padnum_lib"
	try
		set the_result to {}
		if class of thenum is integer then set thenum to thenum as text
		if thenum contains "." and splitdot is true then
			set thenum to my stringlistflip(handlername, thenum, {".", ":"}, "list")
		end if
		if class of thenum is text then
			set thenum to {thenum}
		end if
		repeat with i from 1 to length of thenum
			if (length of item i of thenum) is 1 then
				set end of the_result to ("0" & item i of thenum) as text
			else
				set end of the_result to (item i of thenum) as text
			end if
		end repeat
		return my stringlistflip(my cm(handlername, caller), the_result, ".", "string")
	on error errmsg
		return {handlername, errmsg}
	end try
end padnum

on is_number(caller, number_string)
	set handlername to "is_number_lib"
	try
		set number_string to number_string as number
		return true
	on error
		return false
	end try
end is_number

on getTfromN(this_number)
	set handlername to "getTfromN_lib"
	try
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
	on error errmsg
		return {handlername, errmsg}
	end try
end getTfromN

on end_jsonhelper(caller, restart)
	set handlername to "end_jsonhelper"
	logger(true, handlername, caller, "ERROR", "Attempting to restart JSONHelper") of ParentScript
	tell application "JSON Helper" to quit
	logger(true, handlername, caller, "INFO", "JSONHelper was killed") of ParentScript
	delay 0.1
	if restart is true then
		tell application "JSON Helper" to open
	end if
end end_jsonhelper

on epoch2datetime(caller, epochseconds)
	set handlername to "epoch2datetime_lib"
	try
		try
			set unix_time to (characters 1 through 10 of epochseconds) as text
		on error
			set unix_time to epochseconds
		end try
		set epoch_time to my epoch("")
		--epoch_time is now current unix epoch time as a date object
		logger(true, handlername, caller, "TRACE", epochseconds) of ParentScript
		set epochOFFSET to (epoch_time + (unix_time as number) + (time to GMT))
		logger(true, handlername, caller, "TRACE", class of (epochOFFSET)) of ParentScript
		return epochOFFSET
	on error errmsg
		return {handlername, errmsg}
	end try
end epoch2datetime

on datetime2epoch(caller, the_date_object)
	set handlername to "datetime2epoch_lib"
	-- Convert local date to Unix epoch: subtract epoch base, then subtract GMT offset
	set local_seconds to the_date_object - (my epoch(""))
	set unix_epoch to local_seconds - (time to GMT)
	return getTfromN(unix_epoch) of me
end datetime2epoch

on epoch2show_time(caller, epoch)
	set handlername to "epoch2show_time_lib"
	set show_time_temp to my epoch2datetime(my cm(handlername, caller), epoch)
	set show_time_temp_hours to hours of show_time_temp
	set show_time_temp_minutes to minutes of show_time_temp
	if show_time_temp_minutes is not 0 then
		logger(true, handlername, caller, "TRACE", epoch) of ParentScript
		return (show_time_temp_hours & "." & (round (((show_time_temp_minutes / 60 * 100))) rounding up)) as text
	else
		return (show_time_temp_hours)
	end if
end epoch2show_time

on serialize_show(caller, show_rec)
	set handlername to "serialize_show"
	copy show_rec to s
	logger(true, handlername, caller, "DEBUG", "Converting show: " & show_title of s) of ParentScript

	try
		if (class of (show_last of s)) is date then
			set show_last of s to (my datetime2epoch(caller, show_last of s)) as text
		else
			set show_last of s to 0
		end if
	on error
		set show_last of s to 0
	end try
	try
		if (class of (show_next of s)) is date then
			set show_next of s to (my datetime2epoch(caller, show_next of s)) as text
		else
			set show_next of s to 0
		end if
	on error
		set show_next of s to 0
	end try
	try
		if (class of (show_end of s)) is date then
			set show_end of s to (my datetime2epoch(caller, show_end of s)) as text
		else
			set show_end of s to 0
		end if
	on error
		set show_end of s to 0
	end try
	try
		if (class of (notify_recording_time of s)) is date then
			set notify_recording_time of s to (my datetime2epoch(caller, notify_recording_time of s)) as text
		else if notify_recording_time of s is not "missing value" and notify_recording_time of s is not "" and notify_recording_time of s is not 0 then
			set notify_recording_time of s to (notify_recording_time of s) as text
		else
			set notify_recording_time of s to "missing value"
		end if
	on error
		set notify_recording_time of s to "missing value"
	end try
	try
		if (class of (notify_upnext_time of s)) is date then
			set notify_upnext_time of s to (my datetime2epoch(caller, notify_upnext_time of s)) as text
		else if notify_upnext_time of s is not "missing value" and notify_upnext_time of s is not "" and notify_upnext_time of s is not 0 then
			set notify_upnext_time of s to (notify_upnext_time of s) as text
		else
			set notify_upnext_time of s to "missing value"
		end if
	on error
		set notify_upnext_time of s to "missing value"
	end try

	try
		if (class of (show_dir of s)) is alias then
			set show_dir of s to POSIX path of (show_dir of s)
		else
			set show_dir of s to (show_dir of s) as text
		end if
	on error
	end try
	try
		if (class of (show_temp_dir of s)) is alias then
			set show_temp_dir of s to POSIX path of (show_temp_dir of s)
		else
			set show_temp_dir of s to (show_temp_dir of s) as text
		end if
	on error
	end try

	return s
end serialize_show

on deserialize_show(caller, show_rec)
	set handlername to "deserialize_show"
	copy show_rec to s

	try
		set ep to show_last of s
		if ep is 0 then
			-- Sentinel value: never recorded, keep as 0
			set show_last of s to 0
		else if ep is "" or ep is missing value then
			-- Empty sentinel: convert to never-recorded marker
			set show_last of s to 0
		else
			set ep_num to ep as number
			set show_last of s to my epoch2datetime(caller, ep_num)
		end if
	on error
		set show_last of s to 0
	end try
	try
		set ep to show_next of s
		if ep is 0 or ep is "" or ep is missing value then
			set show_next of s to my epoch("")
		else
			set ep_num to ep as number
			set show_next of s to my epoch2datetime(caller, ep_num)
		end if
	on error
		set show_next of s to my epoch("")
	end try
	try
		set ep to show_end of s
		if ep is 0 or ep is "" or ep is missing value then
			set show_end of s to my epoch("")
		else
			set ep_num to ep as number
			set show_end of s to my epoch2datetime(caller, ep_num)
		end if
	on error
		set show_end of s to my epoch("")
	end try

	try
		set ep to notify_recording_time of s
		if ep is 0 or ep is "" or ep is missing value or ep is "missing value" then
			set notify_recording_time of s to missing value
		else
			set ep_num to ep as number
			set notify_recording_time of s to my epoch2datetime(caller, ep_num)
		end if
	on error
		set notify_recording_time of s to missing value
	end try
	try
		set ep to notify_upnext_time of s
		if ep is 0 or ep is "" or ep is missing value or ep is "missing value" then
			set notify_upnext_time of s to missing value
		else
			set ep_num to ep as number
			set notify_upnext_time of s to my epoch2datetime(caller, ep_num)
		end if
	on error
		set notify_upnext_time of s to missing value
	end try

	try
		set dstr to show_dir of s as text
		if dstr starts with "/" then
			set show_dir of s to (dstr as alias)
		end if
	on error errmsg
		logger(true, handlername, caller, "WARN", "show_dir could not be aliased for " & show_title of s & ": " & errmsg) of ParentScript
	end try
	try
		set dstr to show_temp_dir of s as text
		if dstr starts with "/" then
			set show_temp_dir of s to (dstr as alias)
		end if
	on error errmsg
		logger(true, handlername, caller, "WARN", "show_temp_dir could not be aliased for " & show_title of s & ": " & errmsg) of ParentScript
	end try

	try
		set show_channel of s to (show_channel of s) as text
	end try

	try
		set show_fail_count of s to show_fail_count of s
	on error
		set s to s & {show_fail_count:0}
	end try
	try
		set show_fail_reason of s to show_fail_reason of s
	on error
		set s to s & {show_fail_reason:""}
	end try
	try
		set show_logo_url of s to show_logo_url of s
	on error
		set s to s & {show_logo_url:""}
	end try
	try
		set show_url of s to show_url of s
	on error
		set s to s & {show_url:""}
	end try
	try
		set show_time_OriginalAirdate of s to show_time_OriginalAirdate of s
	on error
		set s to s & {show_time_OriginalAirdate:""}
	end try
	try
		set show_use_seriesid of s to show_use_seriesid of s
	on error
		set s to s & {show_use_seriesid:false}
	end try
	try
		set show_use_seriesid_all of s to show_use_seriesid_all of s
	on error
		set s to s & {show_use_seriesid_all:false}
	end try

	return s
end deserialize_show

on deserializeShows(caller, shows_list)
	set handlername to "deserializeShows"
	try
		repeat with i from 1 to length of shows_list
			if item i of shows_list is not "" then
				set item i of shows_list to deserialize_show(caller, item i of shows_list)
			end if
		end repeat
		logger(true, handlername, caller, "DEBUG", "Deserialized " & length of shows_list & " shows") of ParentScript
		return shows_list
	on error errmsg
		logger(true, handlername, caller, "ERROR", "Failed to deserialize shows: " & errmsg) of ParentScript
		return missing value
	end try
end deserializeShows

on serializeShows(caller, shows_list)
	set handlername to "serializeShows"
	try
		repeat with i from 1 to length of shows_list
			if item i of shows_list is not "" then
				set item i of shows_list to serialize_show(caller, item i of shows_list)
			end if
		end repeat
		logger(true, handlername, caller, "DEBUG", "Serialized " & length of shows_list & " shows") of ParentScript
		return shows_list
	on error errmsg
		logger(true, handlername, caller, "ERROR", "Failed to serialize shows: " & errmsg) of ParentScript
		return missing value
	end try
end serializeShows

on tuner_dump(caller)
	set handlername to "tuner_dump_lib"
	set HDHR_DEVICE_LIST to HDHR_DEVICE_LIST of ParentScript
	try
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
					logger(true, handlername, caller, "WARN", "Unable to determine length of hdhr_lineup") of ParentScript
				end try
				set end of tuner_dump_per_item to ("is_active: " & (is_active of item i of HDHR_DEVICE_LIST))
				set end of tuner_dump_per_item to ("is_active_reason: " & (is_active_reason of item i of HDHR_DEVICE_LIST))
				set end of tuner_dump_per_item to ("statusURL: " & (statusURL of item i of HDHR_DEVICE_LIST))
				set end of tuner_dump_per_item to ("channel_mapping: " & (channel_mapping of item i of HDHR_DEVICE_LIST))
				set end of tuner_dump_per_item to ("hdhr_model: " & (hdhr_model of item i of HDHR_DEVICE_LIST))
				set temp to my stringlistflip(my cm(handlername, caller), tuner_dump_per_item, ", ", "string")
				logger(true, handlername, caller, "INFO", temp) of ParentScript
			on error errmsg
				logger(true, handlername, caller, "WARN", errmsg) of ParentScript
			end try
		end repeat
	on error errmsg
		return {handlername, errmsg}
	end try
end tuner_dump

on encode_strikethrough(caller, thedata, decimel_char)
	set handlername to "encode_strikethrough_lib"
	set combiningModifiers to {longStrokeOverlay:822, overline:773, lowLine:818, ringAbove:778, acuteAccent:769, diaeresis:776, tilde:771, xAbove:829, tildeOverlay:820, slashOverlay:824}
	set encoded_line to {}
	repeat with i from 1 to length of thedata
		set end of encoded_line to (item i of thedata & character id decimel_char)
	end repeat
	return {thedata, encoded_line as text}
end encode_strikethrough

on HDHRShowSearch(caller, the_show_id)
	set handlername to "HDHRShowSearch_lib"
	--logger(true, handlername, caller, "WARN", "show_id: " & the_show_id) of ParentScript
	try
		set Show_info to Show_info of ParentScript
		if the_show_id is not in {0, {}, "", missing value} then
			if length of Show_info is greater than 0 then
				repeat with i from 1 to length of Show_info
					if show_id of item i of Show_info is the_show_id then
						--logger(true, handlername, caller, "WARN", "offset: " & i) of ParentScript
						return i
					end if
				end repeat
			end if
		end if
		return 0
	on error errmsg
		return {handlername, errmsg}
	end try
end HDHRShowSearch

on itemsInString(caller, listofitems, thestring)
	set handlername to "itemsInString_lib"
	try
		set oldelim to AppleScript's text item delimiters
		set AppleScript's text item delimiters to listofitems
		set dlist to (every text item of thestring)
		set AppleScript's text item delimiters to oldelim
		if length of dlist is greater than 1 then
			return true
		else
			return false
		end if
	on error
		set AppleScript's text item delimiters to oldelim
	end try
end itemsInString

on check_after_midnight(caller)
	set handlername to "check_after_midnight_lib"
	set temp_time to day of (current date)
	try
		set Check_after_midnight_time to Check_after_midnight_time of ParentScript
		if Check_after_midnight_time is not temp_time then
			set Check_after_midnight_time to temp_time
			return true
		end if
	on error errmsg
		set Check_after_midnight_time to temp_time
	end try
	return false
end check_after_midnight

on isModifierKeyPressed(caller, checkKey, desc)
	set handlername to "isModifierKeyPressed_lib"
	set modiferKeysDOWN to {command_down:false, option_down:false, control_down:false, shift_down:false, caps_down:false, numlock_down:false, function_down:false, help_down:false}
	try
		logger(true, handlername, caller, "INFO", "key: " & checkKey & ", reason: " & desc) of ParentScript
	on error errmsg
		logger(true, handlername, caller, "WARN", "check failed: " & errmsg) of ParentScript
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
		logger(true, handlername, caller, "DEBUG", item 2 of my stringlistflip(my cm(handlername, caller), errmsg, {"{", "}"}, "list")) of ParentScript
	end try
	return modiferKeysDOWN
end isModifierKeyPressed

on quoteme(thestring)
	set handlername to "quoteme_lib"
	set temp to (quote & thestring & quote) as text
	return temp
end quoteme

on date2touch(caller, datetime, filepath)
	set handlername to "date2touch_lib"
	set temp_year to year of datetime
	set temp_month to my padnum(my cm(handlername, caller), ((month of datetime) * 1) as text, false)
	set temp_day to my padnum(my cm(handlername, caller), (day of datetime as text), false)
	set temp_hour to my padnum(my cm(handlername, caller), (hours of datetime as text), false)
	set temp_minute to my padnum(my cm(handlername, caller), (minutes of datetime as text), false)
	try
		set temp_message to "touch -t " & temp_year & temp_month & temp_day & temp_hour & temp_minute & " " & quote & filepath & quote
		logger(true, handlername, caller, "INFO", temp_message) of ParentScript
	on error errmsg
		logger(true, handlername, caller, "WARN", filepath & ", unable to touch") of ParentScript
		set temp_message to missing value
	end try
	if temp_message is not missing value then
		try
			do shell script temp_message
		on error errmsg
			logger(true, handlername, caller, "WARN", errmsg) of ParentScript
		end try
	end if
end date2touch

on time_set(caller, adate_object, time_shift)
	## It returns the resulting date/time object. This is a convenient way to say, �I want this date, at that time of day.�
	set handlername to "time_set"
	if class of adate_object is not date then
		logger(true, handlername, caller, "ERROR", (adate_object as text) & " is not a date object!") of ParentScript
	end if
	set dateobject to adate_object
	--set to midnight
	set hours of dateobject to 0
	set minutes of dateobject to 0
	set seconds of dateobject to 0
	set dateobject to dateobject + (time_shift * hours)
	return dateobject
end time_set

on midnight_of(caller, d)
	set handlername to "midnight_of"
	copy d to d2
	set hours of d2 to 0
	set minutes of d2 to 0
	set seconds of d2 to 0
	return d2
end midnight_of

on corrupt_showinfo(caller)
	set handlername to "corrupt_showinfo"
	try
		set Show_info of ParentScript to {}
		return true
	on error
		return false
	end try
end corrupt_showinfo

on iconEnumPopulate(caller, show_id) --NOT USED
	--Takes a show_id and adds enums to show_status_icons
	set handlername to "iconEnumPopulate"
	set status_enums to {} --includes upnext, upnext2, film, recording, inactive, warning
	set series_enums to {}
	logger(true, handlername, caller, "INFO", "show_id1: " & show_id) of ParentScript
	copy (current date) to cd
	repeat with i from 1 to length of Show_info
		--Series status
		logger(true, handlername, caller, "INFO", "show_id2: " & show_id) of ParentScript
		if show_is_series of item i of Show_info is true then
			if length of show_air_date of item i of Show_info is greater than 1 then
				set series_enums to 8
			else
				set series_enums to 9
			end if
		else
			set series_enums to 7
		end if
		--status
		if show_id is show_id of item i of Show_info then
			set channelcheck to show_channel of item i of Show_info
			set sec_to_show to ((show_next of item i of Show_info) - (cd))
			if show_recorded_today of item i of Show_info is true then
				set status_enums to 18
				--fixmeme
			else
				if sec_to_show is less than 4 * hours then -- and show_recording of item i of Show_info is false then
					if sec_to_show is less than 0 then
						if show_record of item i of Show_info is true then
							set status_enums to 3
							logger(true, handlername, caller, "TRACE", channelcheck & " marked as Record_icon in channel list") of ParentScript
						else
							--fixme
							set status_enums to 1
							logger(true, handlername, caller, "TRACE", channelcheck & " marked as Warning_icon in channel list") of ParentScript
						end if
					end if
					if sec_to_show is less than 1 * hours and sec_to_show is greater than 0 then
						set status_enums to 24
						logger(true, handlername, caller, "TRACE", channelcheck & " marked as Film_icon in channel list") of ParentScript
					end if
					
					if sec_to_show is greater than 1 * hours and sec_to_show is less than 4 * hours then
						set status_enums to 15
						logger(true, handlername, caller, "TRACE", channelcheck & " marked as Up_icon in channel list") of ParentScript
					end if
				else
					if (date (date string of (cd))) is (date (date string of (show_next of item i of Show_info))) then
						set status_enums to 17
						logger(true, handlername, caller, "TRACE", channelcheck & " marked as upnext3 in channel list") of ParentScript
					end if
					if (date (date string of (cd))) is less than (date (date string of (show_next of item i of Show_info))) and (show_recorded_today of item i of Show_info) is false then
						set status_enums to 20
						--set temp_show_line to Futureshow_icon of Icon_record & temp_show_line
					end if
				end if
			end if
			if show_active of item i of Show_info is false then
				set status_enums to 19
				--19: Uncheck_icon  
			end if
			
		end if
	end repeat
	logger(true, handlername, caller, "INFO", "End of handler") of ParentScript
	return {series_enums, status_enums}
end iconEnumPopulate

on aroundDate(caller, thisdate, thatdate, secOffset)
	set handlername to "aroundDate_lib"
	set secOffset to secOffset as number
	set basetime to thatdate
	set lowtime to basetime - secOffset
	set hightime to basetime + secOffset
	if thisdate is greater than or equal to lowtime and thisdate is less than or equal to hightime then
		return true
	end if
	return false
end aroundDate

on update_folder(caller, update_path)
	set handlername to "update_folder_lib"
	logger(true, handlername, caller, "INFO", "\"" & update_path & "\"") of ParentScript
	if update_path is not missing value then
		try
			set posix_update_path to POSIX path of update_path
		on error errmsg
			logger(true, handlername, caller, "WARN", "\"" & update_path & "\" not converted to POSIXs.") of ParentScript
		end try
		try
			do shell script "touch \"" & posix_update_path & "hdhrVCR_test_write\""
			delay 0.1
			do shell script "rm \"" & posix_update_path & "hdhrVCR_test_write\""
			return true
		on error errmsg
			logger(true, handlername, caller, "ERROR", "Unable to write to " & posix_update_path & ", " & errmsg) of ParentScript
			return false
		end try
	else
		logger(true, handlername, caller, "WARN", "update_path has missing value") of ParentScript
	end if
end update_folder

on rotate_logs(caller, filepath)
	set handlername to "rotate_logs_lib"
	set Loglines_max to Loglines_max of ParentScript
	set Show_info to Show_info of ParentScript
	set filepath to POSIX path of filepath
	set progress description to "Rotated log to " & Loglines_max & " lines"
	set progress additional description to filepath
	set progress total steps to 0
	set progress completed steps to -1
	delay 0.1
	try
		if length of Show_info is not 0 then
			do shell script "tail -n " & Loglines_max & " '" & filepath & "'>" & filepath & ".temp;mv '" & filepath & ".temp' '" & filepath & "'"
			set progress completed steps to 1
			logger(true, handlername, caller, "INFO", "Log file " & filepath & " rotated to " & Loglines_max & " lines") of ParentScript
		else
			logger(true, handlername, caller, "WARN", "Show List is empty, so logs not rotated") of ParentScript
		end if
	end try
end rotate_logs

on update_record_urls(caller, the_device)
	set handlername to "update_record_urls"
	set Show_info to Show_info of ParentScript
	set HDHR_DEVICE_LIST to HDHR_DEVICE_LIST of ParentScript
	set HDHR_DEVICE_LIST_length to length of HDHR_DEVICE_LIST
	if HDHR_DEVICE_LIST_length is greater than 0 then
		if the_device is "" then
			repeat with i from 1 to HDHR_DEVICE_LIST_length
				my update_record_urls(handlername, device_id of item i of HDHR_DEVICE_LIST)
			end repeat
		else
			try
				set tuner_offset to HDHRDeviceSearch(my cm(handlername, caller), the_device) of ParentScript
				repeat with i from 1 to length of Show_info
					if hdhr_record of item i of Show_info is the_device then
						set temp_url to my add_record_url(my cm(handlername, caller), show_channel of item i of Show_info, the_device)
						if temp_url is not show_url of item i of Show_info then
							logger(true, handlername, caller, "WARN", "Updated show URL from " & show_url of item i of Show_info & " to " & temp_url) of ParentScript
							## set show_url of item i of Show_info to temp_url
							set show_url of item i of (Show_info of ParentScript) to temp_url
						end if
					end if
				end repeat
			on error errmsg
				logger(true, handlername, caller, "WARN", "Unable to update URLs on " & the_device & ", " & errmsg) of ParentScript
			end try
		end if
	else
		logger(true, handlername, caller, "ERROR", "HDHR_DEVICE_LIST is empty") of ParentScript
	end if
end update_record_urls

on add_record_url(caller, the_channel, the_device)
	set handlername to "add_record_url_lib"
	set HDHR_DEVICE_LIST to HDHR_DEVICE_LIST of ParentScript
	try
		set tuner_offset to HDHRDeviceSearch(my cm(handlername, caller), the_device) of ParentScript
		set hdhr_lineup_temp to hdhr_lineup of item tuner_offset of HDHR_DEVICE_LIST
		repeat with i from 1 to length of hdhr_lineup_temp
			if GuideNumber of item i of hdhr_lineup_temp is the_channel then
				set temp_url to |url| of item i of hdhr_lineup_temp
				return temp_url
			end if
		end repeat
	on error errmsg
		logger(true, handlername, caller, "WARN", "err, " & errmsg) of ParentScript
	end try
	--return false
end add_record_url

on seriesScanAdd(caller, show_id)
	set handlername to "seriesScanAdd_lib"
	set RefreshSeriesID_list to RefreshSeriesID_list of ParentScript
	set Show_info to Show_info of ParentScript
	try
		if show_id = "" then
			logger(true, handlername, caller, "INFO", "Scanning Show List...") of ParentScript
			--We need to loop shows, and filter out shows that use seriesid
			repeat with i from 1 to length of Show_info
				if show_use_seriesid of item i of Show_info is true and show_active of item i of Show_info is true then
					my seriesScanAdd(my cm(handlername & "int", caller), show_id of item i of Show_info)
				end if
			end repeat
		else
			set show_offset to my HDHRShowSearch(my cm(handlername, caller), show_id)
			if show_offset is not 0 then
				if show_use_seriesid of item show_offset of Show_info is true then
					if show_id is not in RefreshSeriesID_list then
						set end of RefreshSeriesID_list to show_id
						logger(true, handlername, caller, "INFO", "Added " & show_id & " to seriesScan list") of ParentScript
					else
						logger(true, handlername, caller, "WARN", show_id & " already on refresh list") of ParentScript
					end if
				else
					logger(true, handlername, caller, "WARN", show_id & " does not use SeriesID for tracking") of ParentScript
				end if
			else
				logger(true, handlername, caller, "WARN", show_id & " is no longer a valid show id") of ParentScript
			end if
		end if

		set RefreshSeriesID_list of ParentScript to RefreshSeriesID_list
	on error errmsg
		logger(true, handlername, caller, "ERROR", errmsg) of ParentScript
	end try
end seriesScanAdd

on seriesScanRun(caller, execute)
	set handlername to "seriesScanRun_lib"
	set RefreshSeriesID_list to RefreshSeriesID_list of ParentScript
	set Show_info to Show_info of ParentScript

	if execute is true then
		repeat with i from 1 to length of RefreshSeriesID_list
			set show_id to item i of RefreshSeriesID_list
			set show_offset to my HDHRShowSearch(my cm(handlername, caller), show_id)
			if show_offset is 0 then
				logger(true, handlername, caller, "WARN", "Unable to locate show") of ParentScript
				--return false
			else
				if show_use_seriesid of item show_offset of Show_info is true then
					my seriesScanUpdate(my cm(handlername, caller), show_id)
				else
					logger(true, handlername, caller, "WARN", "show_id: " & show_id & " is not a show_use_seriesid series, skipping update") of ParentScript
				end if
			end if
		end repeat
		idle_change(my cm(handlername, caller), 1, 2) of ParentScript
		set RefreshSeriesID_list of ParentScript to {}
	end if
end seriesScanRun

on seriesScan(caller, seriesID, hdhr_device, thechan, show_id)
	set handlername to "seriesScan_lib"
	set HDHR_DEVICE_LIST to HDHR_DEVICE_LIST of ParentScript
	set show_match_list to {}
	set show_channel_list to {}
	set tuner_offset to HDHRDeviceSearch(my cm(handlername, caller), hdhr_device) of ParentScript
	set hdhr_guide to hdhr_guide of item tuner_offset of HDHR_DEVICE_LIST
	try
		repeat with i from 1 to length of hdhr_guide
			set temp_channel to (GuideNumber of item i of hdhr_guide) as text
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
	on error errmsg
		logger(true, handlername, caller, "ERROR", "hdhr_guide likely empty, " & errmsg) of ParentScript
		return {}
	end try
	set show_match_list_length to length of show_match_list
	if show_match_list_length is greater than 0 then
		if thechan is "" then
			--	logger(true, handlername, caller, "INFO", "Total of " & show_match_list_length & " shows found, on all channels") of ParentScript
		else
			--	logger(true, handlername, caller, "INFO", "Total of " & show_match_list_length & " shows found, on channel " & thechan) of ParentScript
		end if
		set temp to {show_match_list:show_match_list, show_channel_list:show_channel_list, hdhr_device:hdhr_device, show_id:show_id}
		return temp
	else
		return {}
	end if
end seriesScan

on seriesScanNext(caller, seriesID, hdhr_device, thechan, show_id, theoffset)
	set handlername to "seriesScanNext_lib"
	set Show_info to Show_info of ParentScript
	--	logger(true, handlername, caller, "DEBUG", "real_chan: " & thechan) of ParentScript
	--	logger(true, handlername, caller, "DEBUG", "seriesID: " & seriesID) of ParentScript
	--	logger(true, handlername, caller, "DEBUG", "hdhr_device: " & hdhr_device) of ParentScript
	set show_offset to my HDHRShowSearch(my cm(handlername, caller), show_id)
	set newest_show_epoch to {"9999999999"}
	set newest_show_epoch_offset to {0}
	set seriesScanTemp to my seriesScan(my cm(handlername, caller), seriesID, hdhr_device, thechan, show_id)
	
	if seriesScanTemp is not {} then
		if length of show_match_list of seriesScanTemp is greater than 0 then
			logger(true, handlername, caller, "INFO", "Showname: " & show_title of item show_offset of Show_info) of ParentScript
			copy (current date) to cd
			try
				repeat with i from 1 to length of show_match_list of seriesScanTemp
					set StartTime_epoch to my getTfromN(StartTime of item i of show_match_list of seriesScanTemp)
					set EndTime_epoch to my getTfromN(EndTime of item i of show_match_list of seriesScanTemp)
					my show_name_fix(my cm(handlername, caller), show_id, item i of show_match_list of seriesScanTemp) --correct, returns the whole channel object, build_channel might do this.
					if StartTime_epoch is less than item 1 of newest_show_epoch then
						if cd is less than my epoch2datetime(my cm(handlername, caller), EndTime_epoch) then
							set beginning of newest_show_epoch to StartTime_epoch
							set beginning of newest_show_epoch_offset to i
							logger(true, handlername, caller, "INFO", "Offset: " & theoffset & " New Start Time: " & my short_date(my cm(handlername, caller), my epoch2datetime(my cm(handlername, caller), StartTime_epoch), false, false)) of ParentScript
						end if
					else
						set end of newest_show_epoch to StartTime_epoch
						set end of newest_show_epoch_offset to i
					end if
				end repeat
			on error errmsg
				logger(true, handlername, caller, "WARN", "Error processing episodes for " & show_title of item show_offset of Show_info & ": " & errmsg) of ParentScript
				return {}
			end try
			--	choose from list newest_show_epoch_offset
			if item theoffset of newest_show_epoch_offset is not 0 then
				--	set show_offset to my HDHRShowSearch(my cm(handlername, caller), show_id of seriesScanTemp)
				set temp to {item (item theoffset of newest_show_epoch_offset) of show_match_list of seriesScanTemp, item (item theoffset of newest_show_epoch_offset) of show_channel_list of seriesScanTemp, show_id of seriesScanTemp}
				return temp
			else
				if length of newest_show_epoch_offset is greater than 1 then
					logger(true, handlername, caller, "WARN", "No future episodes found, returning most recent: " & show_title of item show_offset of Show_info) of ParentScript
					set temp to {item (item 2 of newest_show_epoch_offset) of show_match_list of seriesScanTemp, item (item 2 of newest_show_epoch_offset) of show_channel_list of seriesScanTemp, show_id of seriesScanTemp}
					return temp
				else
					logger(true, handlername, caller, "WARN", "No episodes found for " & show_title of item show_offset of Show_info) of ParentScript
					return {}
				end if
			end if
		end if
	else
		return {}
	end if
end seriesScanNext

on seriesScanUpdate(caller, show_id)
	set handlername to "seriesScanUpdate_lib"
	set Show_info to Show_info of ParentScript
	set show_offset to my HDHRShowSearch(my cm(handlername, caller), show_id)
	if show_offset is not 0 then
		if show_use_seriesid of item show_offset of Show_info is true then
			if show_use_seriesid_all of item show_offset of Show_info is true then
				set temp_chan to ""
			else
				set temp_chan to show_channel of item show_offset of Show_info
			end if
			
			set show_temp to my seriesScanNext(my cm(handlername, caller), show_seriesid of item show_offset of Show_info, hdhr_record of item show_offset of Show_info, temp_chan, show_id, 1)
			--		my show_name_fix(my cm(handlername, caller), "", my seriesScanNext(my cm(handlername, caller & "+1"), show_seriesid of item show_offset of Show_info, hdhr_record of item show_offset of Show_info, temp_chan, show_id, 2))
			if show_temp is not {} then
				set channel_record to item 1 of show_temp
				set channel_number to item 2 of show_temp
				set channel_showid to item 3 of show_temp
				if show_offset is not 0 then
					if show_recording of item show_offset of Show_info is false then
						set isdupe to {false, false, false}
						-- Guide returns times as "local time encoded as UTC epoch", so subtract GMT offset to get true UTC epoch
						set StartTime_guide_epoch to my getTfromN(StartTime of channel_record)
						set StartTime_utc_epoch to StartTime_guide_epoch - (time to GMT)

						if show_next of item show_offset of Show_info is my epoch2datetime(my cm(handlername, caller), StartTime_utc_epoch) then
							set item 1 of isdupe to true
						else
							set show_next of item show_offset of Show_info to my epoch2datetime(my cm(handlername, caller), StartTime_utc_epoch)
						end if
						-- Always update show_end based on show_next + show_length
						set show_end of item show_offset of Show_info to (show_next of item show_offset of Show_info) + (show_length of item show_offset of Show_info * minutes)

						if show_time of item show_offset of Show_info is my epoch2show_time(my cm(handlername, caller), StartTime_utc_epoch) then
							set item 2 of isdupe to true
						else
							set show_time of item show_offset of Show_info to my epoch2show_time(my cm(handlername, caller), my getTfromN(StartTime of channel_record))
						end if
						if (show_channel of item show_offset of Show_info) is not channel_number then
							logger(true, handlername, caller, "INFO", "Channel updated: " & (show_channel of item show_offset of Show_info) & " → " & channel_number) of ParentScript
						end if
						set show_channel of item show_offset of Show_info to channel_number

						set guide_title to fixall of my show_name_fix(my cm(handlername, caller), "", channel_record)
						if show_title of item show_offset of Show_info is guide_title then
							set item 3 of isdupe to true
						end if

						if item 1 of isdupe is false and item 3 of isdupe is false then
							set new_showid to do shell script ("uuidgen | tr -d '-'")
							logger(true, handlername, caller, "WARN", "The show, " & show_title of item show_offset of Show_info & " showid changed from " & show_id of item show_offset of Show_info & " to " & new_showid) of ParentScript
							set show_id of item show_offset of Show_info to new_showid
							set Show_info of ParentScript to Show_info
							set show_offset to my HDHRShowSearch(my cm(handlername, caller), new_showid)
							logger(true, handlername, caller, "INFO", "show channel: " & show_channel of item show_offset of Show_info) of ParentScript
							
							set show_title of item show_offset of Show_info to fixall of my show_name_fix(my cm(handlername, caller), new_showid, channel_record)
							set show_next of item show_offset of Show_info to my epoch2datetime(my cm(handlername, caller), (my getTfromN(StartTime of channel_record)) - (time to GMT))
							set show_end of item show_offset of Show_info to my epoch2datetime(my cm(handlername, caller), (my getTfromN(EndTime of channel_record)) - (time to GMT))
							set show_fail_count of item show_offset of Show_info to 0
							set show_fail_reason of item show_offset of Show_info to ""
							try
								set show_time_OriginalAirdate of item show_offset of Show_info to my getTfromN(OriginalAirdate of channel_record)
							end try
							set show_length of item show_offset of Show_info to ((EndTime of channel_record) - (StartTime of channel_record)) div 60
							set show_url of item show_offset of Show_info to my add_record_url(my cm(handlername, caller), show_channel of item show_offset of Show_info, hdhr_record of item show_offset of Show_info)
							--my update_show(my cm(handlername, caller), new_showid, false)
							logger(true, handlername, caller, "INFO", "The show, " & show_title of item show_offset of Show_info & ", was updated") of ParentScript
							--	my idle_change(my cm(handlername, caller), 1, 2)
						else
							if item 1 of isdupe is true and item 3 of isdupe is false then
								logger(true, handlername, caller, "INFO", "Title changed but StartTime unchanged; keeping existing show_id. Old: " & show_title of item show_offset of Show_info) of ParentScript
							end if
						end if
					else
						logger(true, handlername, caller, "WARN", "The show, " & show_title of item show_offset of Show_info & " was not updated, as it was recording") of ParentScript
					end if
				end if
			else
				logger(true, handlername, caller, "WARN", "No upcoming episodes found in guide for " & quote & show_title of item show_offset of Show_info & quote & " (seriesID: " & show_seriesid of item show_offset of Show_info & "); advancing show_next by 4 hours to retry later") of ParentScript
				set show_next of item show_offset of Show_info to (current date) + 4 * hours
			end if
		else
		end if
	end if
	set Show_info of ParentScript to Show_info
end seriesScanUpdate

on updateSeriesID(caller, show_id, new_seriesid)
	set handlername to "updateSeriesID_lib"
	if show_id is "" or new_seriesid is "" then
		logger(true, handlername, caller, "WARN", "Cannot update SeriesID: show_id=" & quote & show_id & quote & ", new_seriesid=" & quote & new_seriesid & quote) of ParentScript
		return false
	end if
	set Show_info to Show_info of ParentScript
	set show_offset to my HDHRShowSearch(my cm(handlername, caller), show_id)
	if show_offset is not 0 then
		set old_seriesid to show_seriesid of item show_offset of Show_info
		set show_title to show_title of item show_offset of Show_info
		set show_seriesid of item show_offset of Show_info to new_seriesid
		logger(true, handlername, caller, "INFO", "SeriesID updated for " & quote & show_title & quote & ": " & quote & old_seriesid & quote & " → " & quote & new_seriesid & quote) of ParentScript
		set Show_info of ParentScript to Show_info
		return true
	else
		logger(true, handlername, caller, "WARN", "Show not found: " & show_id) of ParentScript
		return false
	end if
end updateSeriesID

on seriesStatusIcons(caller, show_id)
	set handlername to "seriesStatus_Lib"
	set temp_series_status to {}
	set Show_info to Show_info of ParentScript
	set Icon_record to Icon_record of ParentScript
	set show_offset to my HDHRShowSearch(my cm(handlername, caller), show_id)
	set show_kind to ""
	if show_offset is not 0 then
		if show_recording of item show_offset of Show_info is true then
			set temp_series_status to Record_icon of Icon_record
			set show_kind to "Recording"
		else
			if show_is_series of item show_offset of Show_info is true then
				if length of show_air_date of item show_offset of Show_info is 1 then
					set temp_series_status to Series1_icon of Icon_record
					set show_kind to "One Day Series"
				else
					if show_use_seriesid of item show_offset of Show_info = true then
						set temp_series_status to Series3_icon of Icon_record
						set show_kind to "SeriesID Series"
					else
						set temp_series_status to Series_icon of Icon_record
						set show_kind to "Multiday Series"
					end if
				end if
			else
				set temp_series_status to Single_icon of Icon_record
				set show_kind to "Single"
			end if
		end if
		return {show_stat:show_kind, the_show_id:show_id, status_icon:temp_series_status}
	else
		return {show_stat:missing value, the_show_id:missing value, status_icon:"     "}
	end if
	--return temp_series_status
end seriesStatusIcons

on match2showid(caller, hdhr_tuner, channelcheck, start_time, end_time)
	set handlername to "match2showid_lib"
	logger(true, handlername, caller, "INFO", "Called") of ParentScript
	set Show_info to Show_info of ParentScript
	copy (current date) to cd
	repeat with i from 1 to length of Show_info
		if hdhr_tuner is hdhr_record of item i of Show_info and channelcheck is show_channel of item i of Show_info then
			if my aroundDate(my cm(handlername, caller), start_time, show_next of item i of Show_info, 120) is true then
				logger(true, handlername, caller, "WARN", "Returned " & show_id of item i of Show_info) of ParentScript
				return show_id of item i of Show_info
			end if
		end if
	end repeat
	return 0
end match2showid

on recordSee(caller, the_record)
	set handlername to "recordSee_lib"
	try
		set the_record to the_record as text
	on error errmsg
		set parsed_errmsg to item 2 of my stringlistflip(handlername, errmsg, {"Can�t make ", " into"}, "list")
		return parsed_errmsg
	end try
end recordSee


on show_name_fix(caller, show_id, show_object)
	set handlername to "show_name_fix_lib"
	set temp_name to {}
	set show_offset to my HDHRShowSearch(my cm(handlername, caller), show_id)
	set channel_record to show_object
	if show_object is not {} then
		set hdhr_response_channel_title to ""
		set hdhr_response_channel_episodeNum to ""
		set hdhr_response_channel_episodeTitle to ""
		try
			set hdhr_response_channel_title to title of channel_record
		end try
		try
			set hdhr_response_channel_episodeNum to EpisodeNumber of channel_record
		end try
		try
			set hdhr_response_channel_episodeTitle to EpisodeTitle of channel_record
		end try
		
		set temp_name to {hdhr_response_channel_title, hdhr_response_channel_episodeNum, hdhr_response_channel_episodeTitle}
		set temp_name to my emptylist(my cm(handlername, caller), temp_name)
		set temp_name to my stringToUtf8(my cm(handlername, caller), my stringlistflip(my cm(handlername, caller), temp_name, " ", "string"))
		logger(true, handlername, caller, "DEBUG", "hdhr_response_channel_title: " & hdhr_response_channel_title & ":" & hdhr_response_channel_episodeNum & ":" & hdhr_response_channel_episodeTitle) of ParentScript
		return {fixTitle:hdhr_response_channel_title, fixEpisodeNum:hdhr_response_channel_episodeNum, fixEpisodeTitle:hdhr_response_channel_episodeTitle, fixall:temp_name}
		
	end if
end show_name_fix

on convertByteSize(caller, byteSize, KBSize, decPlaces)
	--my convertByteSize(todoBytes of item i of GUID_backupUsage, 1000, 2)
	set handlername to "convertByteSize_lib"
	if (KBSize is missing value) then set KBSize to 1000 + 24 * (((system attribute "sysv") < 4192) as integer)
	
	if (byteSize is 1) then
		set conversion to "1 byte" as Unicode text
	else if (byteSize < KBSize) then
		set conversion to (byteSize as Unicode text) & " bytes"
	else
		set conversion to "Oooh lots!" -- Default in case yottabytes isn't enough!
		set suffixes to {" KB", " MB", " GB", " TB", " PB", " EB", " ZB", " YB"}
		set dpShift to ((10 ^ 0.5) ^ 2) * (10 ^ (decPlaces - 1)) -- (10 ^ decPlaces) convolutedly to try to shake out any floating-point errors.
		repeat with p from 1 to (count suffixes)
			if (byteSize < (KBSize ^ (p + 1))) then
				tell ((byteSize / (KBSize ^ p)) * dpShift) to set conversion to (((it div 0.5 - it div 1) / dpShift) as Unicode text) & item p of suffixes
				exit repeat
			end if
		end repeat
	end if
	return conversion
end convertByteSize

on cleanFolder(caller, folderLoc, time_offset, ext_remove)
	set handlername to "cleanFolder_lib"
	set cd to current date
	set oldest_date_boundry to (cd + time_offset)
	set deleted_filecount to 0
	logger(true, handlername, caller, "DEBUG", "oldest_date_boundry:" & oldest_date_boundry) of ParentScript
	if class of folderLoc is text then
		set folderLoc to (POSIX file folderLoc) as alias
	end if
	tell application "System Events"
		-- Make sure System Events treats folderLoc as a folder
		set old_files to every file of (folderLoc) whose name extension is ext_remove and modification date is less than oldest_date_boundry
		set fileCount to (length of old_files)
		logger(true, handlername, caller, "DEBUG", "Matching Files: " & fileCount) of ParentScript
		-- Reasonable defaults: start from the boundary, not from 1970 or 'now'
		set oldest_date_test to oldest_date_boundry
		set newest_date_test to oldest_date_boundry
		if fileCount is not 0 then
			repeat with i from 1 to fileCount
				set temp to (modification date of (item i of old_files)) as date
				
				if temp is less than oldest_date_test then
					logger(true, handlername, caller, "DEBUG", "oldfile_swap new: " & temp & " / old: " & oldest_date_test) of ParentScript
					set oldest_date_test to temp
				end if
				
				if temp is greater than newest_date_test then
					logger(true, handlername, caller, "DEBUG", "newfile_swap new: " & temp & " / old: " & newest_date_test) of ParentScript
					set newest_date_test to temp
				end if
				set deleted_filecount to deleted_filecount + 1
				delete item i of old_files
			end repeat
			logger(true, handlername, caller, "INFO", deleted_filecount & " " & quote & ext_remove & quote & "'s deleted from " & (folderLoc as text)) of ParentScript
		else
			logger(true, handlername, caller, "INFO", "No cache files to be removed") of ParentScript
		end if
	end tell
end cleanFolder


on curl2icon(caller, thelink)
	set handlername to "curl2icon_lib"
	logger(true, handlername, caller, "INFO", thelink) of ParentScript
	-- Return default if link is missing or empty
	if thelink is in {"", {}, missing value} then
		logger(true, handlername, caller, "WARN", "Passed link is invalid") of ParentScript
		return caution
	end if
	-- Derive filename from URL
	try
		set savename to last item of my stringlistflip(my cm(handlername, caller), thelink, "/", "list")
	on error errmsg
		logger(true, handlername, caller, "WARN", "Unable to pull image, providing default image") of ParentScript
		logger(true, handlername, caller, "WARN", "err: " & errmsg) of ParentScript
		return caution
	end try
	try
		set temp_path to (Base_icon_path of ParentScript) & savename as text
		logger(true, handlername, caller, "DEBUG", "temp_path: " & temp_path) of ParentScript
	on error errmsg
		logger(true, handlername, caller, "WARN", "Base path invalid, err " & thelink) of ParentScript
	end try
	-- If cached, update timestamp
	try
		logger(true, handlername, caller, "DEBUG", "Cache check") of ParentScript
		if my checkfileexists(my cm(handlername, caller), temp_path) is true then
			logger(true, handlername, caller, "INFO", "File exists: " & savename) of ParentScript
			try
				logger(true, handlername, caller, "DEBUG", "Quoted Form: " & quoted form of temp_path) of ParentScript
				do shell script "touch " & quoted form of temp_path
			on error errmsg
				logger(true, handlername, caller, "WARN", "Unable to update date modified of " & savename) of ParentScript
				logger(true, handlername, caller, "WARN", "err: " & errmsg) of ParentScript
			end try
		else
			-- Download with HTTP error checking
			
			set temp_curl to "curl --fail --connect-timeout 10 --silent -H 'appname:" & name of me & "' " & quoted form of thelink & " -o " & quoted form of temp_path
			try
				do shell script temp_curl
				logger(true, handlername, caller, "WARN", temp_curl) of ParentScript
			on error errmsg
				logger(true, handlername, caller, "ERROR", "curl failed for " & quoted form of thelink) of ParentScript
				logger(true, handlername, caller, "ERROR", "err: " & errmsg) of ParentScript
				return caution
			end try
			-- Verify it's an image
			set temp_path_type to do shell script "file -Ib " & quoted form of temp_path
			if temp_path_type does not contain "image" then
				logger(true, handlername, caller, "WARN", "Icon is not an image (" & temp_path_type & "), defaulting to alert icon") of ParentScript
				do shell script "rm " & quoted form of temp_path
				return caution
			else
				logger(true, handlername, caller, "WARN", "Icon is valid image") of ParentScript
			end if
			logger(true, handlername, caller, "INFO", "Created new icon: " & quoted form of temp_path & ", type: " & temp_path_type) of ParentScript
		end if
	on error errmsg
		logger(true, handlername, caller, "WARN", "General Error, " & errmsg) of ParentScript
	end try
	-- Return alias to the image file
	return POSIX file temp_path
end curl2icon

----NOT IN USE------
on showSeek(caller, start_time, end_time, chan, hdhr_device)
	set handlername to "showSeek_lib"
	set Show_info to Show_info of ParentScript
	set temp_showids to {}
	try
		repeat with i from 1 to length of Show_info
			if show_active of item i of Show_info is true then
				if hdhr_device is hdhr_record of item i of Show_info then
					if chan is show_channel of item i of Show_info or chan is "" then
						if start_time is show_next of item i of Show_info or start_time is "" then
							if end_time is show_end of item i of Show_info or end_time is "" then
								set end of temp_showids to show_id of item i of Show_info
							end if
						end if
					end if
				end if
			end if
		end repeat
		return temp_showids
	on error
		return false
	end try
end showSeek

on get_show_state2(caller, hdhr_tuner, channelcheck, start_time, end_time) --not in use
	set handlername to "get_show_state_lib"
	--logger(true, handlername, caller, "INFO", stringlistflip(cm(handlername, caller), showSeek(cm(handlername, caller), "", "", channelcheck, hdhr_tuner), ", ", "string")) of ParentScript
	--We need to only return the 1 result
	logger(true, handlername, caller, "DEBUG", (hdhr_tuner & " | " & channelcheck)) of ParentScript
	copy (current date) to cd
	repeat with i from 1 to length of Show_info
		set show_record_id to show_id of item i of Show_info
		--  if hdhr_tuner is hdhr_record of item i of Show_info and show_active of item i of Show_info is true and channelcheck is show_channel of item i of Show_info then
		if hdhr_tuner is hdhr_record of item i of Show_info and channelcheck is show_channel of item i of Show_info then
			logger(true, handlername, caller, "TRACE", "show_start: " & class of (show_next of item i of Show_info) & ", start_time: " & class of (start_time)) of ParentScript

			if show_recording of item i of Show_info is true then
				if cd is greater than or equal to start_time and cd is less than or equal to end_time then
					logger(true, handlername & i, caller, "INFO", "Marked as recording: " & show_title of item i of Show_info) of ParentScript
					logger(true, handlername & i, caller, "DEBUG", "REC show_record_id: " & show_record_id & ", offset:" & i) of ParentScript
					return {show_stat:"record", the_show_id:show_record_id, status_icon:Record_icon of Icon_record}
				end if
			else
				try
					if my aroundDate(my cm(handlername, caller), start_time, show_next of item i of Show_info, 120) of ParentScript is true then
						logger(true, handlername & i, caller, "INFO", "Marked as upnext:    " & show_title of item i of Show_info & ", channel " & channelcheck) of ParentScript
						logger(true, handlername & i, caller, "DEBUG", "UPNEXT show_record_id: " & show_record_id & ", offset " & i) of ParentScript
						if show_active of item i of Show_info is true then
							if cd is greater than or equal to start_time and cd is less than or equal to end_time then
								logger(true, handlername & i, caller, "INFO", "Marked as NOT recording: " & show_title of item i of Show_info) of ParentScript
								return {show_stat:"norecord", the_show_id:show_record_id, status_icon:Warning_icon of Icon_record}
							else if start_time - cd is less than or equal to 1 * hours then
								return {show_stat:"upnext0", the_show_id:show_record_id, status_icon:Film_icon of Icon_record}
							else
								return {show_stat:"upnext", the_show_id:show_record_id, status_icon:Up_icon of Icon_record}
							end if
						else
							return {show_stat:"deact", the_show_id:show_record_id, status_icon:Uncheck_icon of Icon_record}
						end if
						--end if
					end if
				on error errmsg
					logger(true, handlername, caller, "ERROR", "Oops, " & errmsg) of ParentScript
				end try
			end if
		end if
	end repeat
	return {show_stat:missing value, the_show_id:missing value, status_icon:"     "}
end get_show_state2

on nextday2(caller, the_show_id)
	set handlername to "nextday_lib"
	copy (current date) to cd_object
	set nextup to {}
	set show_offset to my HDHRShowSearch(my cm(handlername, caller), the_show_id)

	repeat with i from -1 to 7
		if ((weekday of (cd_object + i * days)) as text) is in (show_air_date of item show_offset of Show_info) then
			if cd_object is less than (my time_set(my cm(handlername, caller), (cd_object + i * days), (show_time of item show_offset of Show_info))) + ((show_length of item show_offset of Show_info) * minutes) then
				logger(true, handlername, caller, "DEBUG", "1nextup: " & nextup) of ParentScript
				logger(true, handlername, caller, "DEBUG", "cd_object: " & cd_object) of ParentScript
				logger(true, handlername, caller, "DEBUG", "i: " & i) of ParentScript
				set nextup to my time_set(my cm(handlername, caller), (cd_object + i * days), show_time of item show_offset of Show_info)
				exit repeat
			end if
		end if
	end repeat

	try
		if nextup is missing value then
			logger(true, handlername, caller, "WARN", "nextup0 is missing value") of ParentScript
		end if
	on error errmsg
		logger(true, handlername, caller, "WARN", "errmsg1: " & errmsg) of ParentScript
	end try

	try
		set record_check_pre to ((nextup) - 1 * weeks)
		set record_check_post to (record_check_pre) + ((show_length of item show_offset of Show_info) * minutes)
		if (cd_object) is greater than record_check_pre and (cd_object) is less than record_check_post then
			logger(true, handlername, caller, "WARN", "We are between record_check_pre and record_check_post") of ParentScript
			set show_next of item show_offset of Show_info to record_check_pre
		end if
	on error errmsg
		logger(true, handlername, caller, "WARN", "0errmsg: " & errmsg) of ParentScript
	end try

	--FIX we need to check for show_use_seriesid here.  If we are using series id, we might not have a good way to mark this show.  We might need to select the next showing, and when that showing is over, check to see if a next show is on the schedule.
	if show_end of item show_offset of Show_info is not nextup + ((show_length of item show_offset of Show_info) * minutes) then
		set show_end of item show_offset of Show_info to nextup + ((show_length of item show_offset of Show_info) * minutes)
		logger(true, handlername, caller, "INFO", "Show end of \"" & show_title of item show_offset of Show_info & "\" set to: " & nextup + ((show_length of item show_offset of Show_info) * minutes)) of ParentScript
		logger(true, handlername, caller, "DEBUG", "WORK Show end class: " & class of (show_end of item show_offset of Show_info)) of ParentScript
	end if
	return nextup
end nextday2

on enums2icons(caller, enumarray)
	set handlername to "statusEnums"
	set iconFinal to {}
	set iconLength to length of IconList
	if class of enumarray is list then
		repeat with i from 1 to length of enumarray
			set currentEnum to item i of enumarray
			if currentEnum is less than or equal to iconLength and currentEnum is greater than 0 then
				set end of iconFinal to item (item i of enumarray) of IconList
			else
				set end of iconFinal to "?"
			end if
		end repeat
	else
		return {}
	end if
	return iconFinal
end enums2icons

on show_icons(caller, hdhr_device, thechan) -- not used
	set handlername to "show_icons"
	repeat with i from 1 to length of Show_info
		get_show_state(my cm(handlername, caller), hdhr_device, thechan, start_time, end_time) of ParentScript
	end repeat
end show_icons

on seriesScanList(caller, show_id, updateRecord)
	set handlername to "seriesScanList_lib"
	set RefreshSeriesID_list to RefreshSeriesID_list of ParentScript
	set Show_info to Show_info of ParentScript
	if show_id is not in RefreshSeriesID_list then
		if show_id is not missing value then
			set end of RefreshSeriesID_list to show_id
			logger(true, handlername, caller, "INFO", "Added " & show_id & " to SeriesScan list") of ParentScript
		end if
		if updateRecord is true then
			repeat with i from 1 to length of RefreshSeriesID_list
				set show_offset to my HDHRShowSearch(my cm(handlername, caller), item i of RefreshSeriesID_list)
				if show_is_series of item show_offset of Show_info is true then
					my seriesScanUpdate(my cm(handlername, caller), item i of RefreshSeriesID_list)
				end if
			end repeat
			set RefreshSeriesID_list to {}
		end if
	else
		logger(true, handlername, caller, "WARN", show_id & " already on refresh list") of ParentScript
	end if
end seriesScanList

on seriesScanRefresh(caller, show_id)
	--This should use the add/run combo
	set handlername to "seriesScanRefresh_lib"
	set Show_info to Show_info of ParentScript
	if show_id is "" then
		repeat with i from 1 to length of Show_info
			if show_use_seriesid of item i of Show_info is true and show_recording of item i of Show_info is false and show_active of item i of Show_info is true then
				my seriesScanUpdate(my cm(handlername, caller), show_id of item i of Show_info)
			end if
		end repeat
		return true
	else
		seriesScanUpdate(my cm(handlername, caller), show_id)
	end if
end seriesScanRefresh

on recordSee2(caller, the_record)
	set handlername to "recordSee_lib"
	try
		set the_record to the_record as text
	on error errmsg
		return errmsg
	end try
end recordSee2

on choose_folder_with_fallback(caller, prompt_msg, fallback_locs)
	set handlername to "choose_folder_with_fallback_lib"
	set best_default to alias "Volumes:"

	-- Find first valid default location from fallback list
	repeat with loc_item in fallback_locs
		try
			if loc_item is not missing value and loc_item is not alias "Volumes:" then
				set best_default to loc_item as alias
				logger(true, handlername, caller, "DEBUG", "Using default location: " & (best_default as text)) of ParentScript
				exit repeat
			end if
		on error
			-- Skip invalid locations
		end try
	end repeat

	-- Show one dialog with best default found
	try
		set selected_folder to choose folder with prompt prompt_msg default location best_default
		-- Reject root folder
		if selected_folder is alias "Volumes:" then
			logger(true, handlername, caller, "WARN", "User selected root folder, not allowed") of ParentScript
			return missing value
		end if
		logger(true, handlername, caller, "DEBUG", "Folder selected: " & (selected_folder as text)) of ParentScript
		return selected_folder
	on error errmsg
		logger(true, handlername, caller, "INFO", "User cancelled folder selection: " & errmsg) of ParentScript
		return missing value
	end try
end choose_folder_with_fallback

on choose_folder_with_fallback_v2(caller, prompt_msg, fallback_locs)
	set handlername to "choose_folder_with_fallback_v2_lib"
	set total_locs to length of fallback_locs
	logger(true, handlername, caller, "DEBUG", "Trying " & total_locs & " fallback locations") of ParentScript

	set current_index to 0
	repeat with fallback_loc in fallback_locs
		set current_index to current_index + 1
		-- Validate fallback location before showing dialog
		try
			set test_alias to fallback_loc as alias
		on error errmsg number errnum
			logger(true, handlername, caller, "DEBUG", "Skipping invalid fallback location (" & errnum & "): " & errmsg) of ParentScript
			exit repeat
		end try

		-- Valid location found, show dialog with path info
		set loc_path to fallback_loc as text
		set tier_names to {"Configured Default", "Last Show", "Volume Root", "⁄Volumes Root"}
		set tier_name to item current_index of tier_names
		set enhanced_prompt to prompt_msg & return & return & "[" & current_index & "⁄" & total_locs & " - " & tier_name & "] " & loc_path

		try
			set selected_folder to choose folder with prompt enhanced_prompt default location fallback_loc
			-- Reject root folder
			if selected_folder is alias "Volumes:" then
				logger(true, handlername, caller, "WARN", "User selected root folder, not allowed") of ParentScript
				exit repeat
			else
				logger(true, handlername, caller, "DEBUG", "Folder selected: " & (selected_folder as text)) of ParentScript
				return selected_folder
			end if
		on error errmsg number errnum
			if errnum is -128 then
				logger(true, handlername, caller, "INFO", "User cancelled from tier " & current_index & " (" & tier_name & "), trying next fallback") of ParentScript
				exit repeat
			else
				logger(true, handlername, caller, "DEBUG", "Dialog error (" & errnum & "): " & errmsg) of ParentScript
				exit repeat
			end if
		end try
	end repeat

	return missing value
end choose_folder_with_fallback_v2
