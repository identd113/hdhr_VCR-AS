# hdhr_vcr library.  This needs to be located in the users Documents Folder, and not renamed.
#Adding for Test

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
	set vers_lib to "20250924"
	return vers_lib
end load_hdhrVCR_vars

on checkDiskSpace(caller, the_path)
	set handlername to "checkDiskSpace_lib"
	try
		set checkDiskSpace_return to do shell script "df -k '" & the_path & "'"
		set checkDiskSpace_temp1 to item 2 of my stringlistflip(my cm(handlername, caller), checkDiskSpace_return, return, "list")
		set checkDiskSpace_temp2 to my emptylist(my cm(handlername, caller), stringlistflip(my cm(handlername, caller), checkDiskSpace_temp1, space, "list"))
		return {the_path, first word of item 5 of checkDiskSpace_temp2 as number, first word of item 4 of checkDiskSpace_temp2 as number}
	on error errmsg
		return {the_path, 0, errmsg}
	end try
end checkDiskSpace

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
	set non_utf8 to {"á", "é", "í", "ó", "ú", "Á", "É", "Í", "Ó", "Ú", "à", "è", "ì", "ò", "ù", "À", "È", "Ì", "Ò", "Ù", "â", "ê", "î", "ô", "û", "Â", "Ê", "Î", "Ô", "Û", "ä", "ë", "ï", "ö", "ü", "Ä", "Ë", "Ï", "Ö", "Ü", "ã", "ñ", "õ", "Ã", "Ñ", "Õ", "å", "Å", "ç", "Ç", "ø", "Ø", character id 8239, ":"}
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
		set temp_time_string to {}
		set numseconds to 0
		set numinutes to 0
		set numhours to 0
		set numdays to 0
		set numyears to 0
		if time_duration is "ms" then
			if totalMS is greater than 0 and totalMS is less than 1000 then
				return ("<1s")
			else if totalMS is less than 0 then
				
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
			return my stringlistflip("ms2time(" & caller & ")", temp_time_string, " ", "string")
		else
			logger(true, handlername, caller, "TRACE", "Result: 0ms") of ParentScript
			return my stringlistflip("ms2time(" & caller & ")", "0ms", " ", "string")
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
						logger(true, handlername, caller, "DEBUG", "Offset found: " & i) of ParentScript
						return i
					end if
				else
					if (item i of this_list as text) is (this_item as text) then
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
						set hours_string to my padnum("short_date(" & caller & ")", hours_string, false)
						set timeAMPM to " AM"
					end if
				end if
				if seconds of the_date_object is less than 10 then
					set seconds_string to "0" & seconds of the_date_object
				else
					set seconds_string to (seconds of the_date_object) as text
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
			else
				return ""
			end if
		else
			return "?"
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
		return stringlistflip("test", the_result, ".", "string")
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

on end_jsonhelper(caller)
	set handlername to "kill_jsonhelper"
	logger(true, handlername, caller, "ERROR", "Attempting to restart JSONHelper") of ParentScript
	tell application "JSON Helper" to quit
	logger(true, handlername, caller, "INFO", "JSONHelper was killed") of ParentScript
	delay 3
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
				set temp to my stringlistflip("tuner_dump(" & caller & ")", tuner_dump_per_item, ", ", "string")
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
	## It returns the resulting date/time object. This is a convenient way to say, “I want this date, at that time of day.”
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
	set RefreshderiesiD_list to RefreshderiesiD_list of ParentScript
	set Show_info to Show_info of ParentScript
	try
		if show_id = "" then
			logger(true, handlername, caller, "INFO", "Scanning Show List...") of ParentScript
			--We need to loop shows, and filter out shows that use seriesid
			repeat with i from 1 to length of Show_info
				if show_use_seriesid of item i of Show_info is true then
					seriesScanAdd(my cm(handlername & "int", caller), show_id of item i of Show_info)
				end if
			end repeat
		else
			set show_offset to my HDHRShowSearch(my cm(handlername, caller), show_id)
			logger(true, handlername, caller, "DEBUG", "Attempting to add show_id: " & show_id) of ParentScript
			if show_offset is not 0 then
				if show_use_seriesid of item show_offset of Show_info is true then
					if show_id is not in RefreshderiesiD_list then
						set end of RefreshderiesiD_list to show_id
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
		
		set RefreshderiesiD_list of ParentScript to RefreshderiesiD_list
		logger(true, handlername, caller, "DEBUG", "Updated RefreshderiesiD_list length: " & (length of RefreshderiesiD_list)) of ParentScript
	on error errmsg
		logger(true, handlername, caller, "ERROR", errmsg) of ParentScript
	end try
end seriesScanAdd

on seriesScanRun(caller, execute)
	set handlername to "seriesScanRun_lib"
	set RefreshderiesiD_list to RefreshderiesiD_list of ParentScript
	set Show_info to Show_info of ParentScript
	
	logger(true, handlername, caller, "DEBUG", "Execute flag is: " & execute) of ParentScript
	logger(true, handlername, caller, "DEBUG", "RefreshderiesiD_list count: " & (length of RefreshderiesiD_list)) of ParentScript
	
	if execute is true then
		repeat with i from 1 to length of RefreshderiesiD_list
			set show_id to item i of RefreshderiesiD_list
			logger(true, handlername, caller, "DEBUG", "Processing show_id[" & i & "]: " & show_id) of ParentScript
			set show_offset to my HDHRShowSearch(my cm(handlername, caller), show_id)
			if show_offset is 0 then
				logger(true, handlername, caller, "WARN", "Unable to locate show") of ParentScript
				--return false
			else
				if show_use_seriesid of item show_offset of Show_info is true then
					logger(true, handlername, caller, "TRACE", "Found series at offset " & show_offset & ", updating show_id: " & show_id) of ParentScript
					seriesScanUpdate(my cm(handlername, caller), show_id) of ParentScript
				else
					logger(true, handlername, caller, "WARN", "show_id: " & show_id & " is not a show_use_seriesid series, skipping update") of ParentScript
				end if
			end if
		end repeat
		idle_change(my cm(handlername, caller), 1, 2) of ParentScript
		set RefreshderiesiD_list of ParentScript to {}
		logger(true, handlername, caller, "DEBUG", "Cleared RefreshderiesiD_list") of ParentScript
	end if
end seriesScanRun

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
		set parsed_errmsg to item 2 of my stringlistflip(handlername, errmsg, {"Can’t make ", " into"}, "list")
		return parsed_errmsg
	end try
end recordSee


on show_name_fix(caller, show_id, show_object)
	set handlername to "show_name_fix_lib"
	set temp_name to {}
	logger(true, handlername, caller, "DEBUG", "showid: " & show_id & ", show_object: " & (my recordSee(my cm(handlername, caller), show_object))) of ParentScript
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


----NOT IN USE------
(*
on get_show_state2(caller, hdhr_tuner, channelcheck, start_time, end_time) --not in use
	set handlername to "get_show_state_lib"
	--my logger(true, handlername, caller, "INFO", my stringlistflip(my cm(handlername, caller), my showSeek(my cm(handlername, caller), "", "", channelcheck, hdhr_tuner), ", ", "string"))
	--We need to only return the 1 result
	my logger(true, handlername, caller, "DEBUG", (hdhr_tuner & " | " & channelcheck))
	copy (current date) to cd
	repeat with i from 1 to length of Show_info
		set show_record_id to show_id of item i of Show_info
		--  if hdhr_tuner is hdhr_record of item i of Show_info and show_active of item i of Show_info is true and channelcheck is show_channel of item i of Show_info then
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
					if my aroundDate(my cm(handlername, caller), start_time, show_next of item i of Show_info, 120) of ParentScript is true then
						my logger(true, handlername & i, caller, "INFO", "Marked as upnext:    " & show_title of item i of Show_info & ", channel " & channelcheck)
						my logger(true, handlername & i, caller, "DEBUG", "UPNEXT show_record_id: " & show_record_id & ", offset " & i)
						if show_active of item i of Show_info is true then
							if cd is greater than or equal to start_time and cd is less than or equal to end_time then
								my logger(true, handlername & i, caller, "INFO", "Marked as NOT recording: " & show_title of item i of Show_info)
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
					my logger(true, handlername, caller, "ERROR", "Oops, " & errmsg)
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
				my logger(true, handlername, caller, "DEBUG", "1nextup: " & nextup)
				my logger(true, handlername, caller, "DEBUG", "cd_object: " & cd_object)
				my logger(true, handlername, caller, "DEBUG", "i: " & i)
				set nextup to my time_set(my cm(handlername, caller), (cd_object + i * days), show_time of item show_offset of Show_info)
				exit repeat
			end if
		end if
	end repeat
	
	try
		if nextup is missing value then
			my logger(true, handlername, caller, "WARN", "nextup0 is missing value")
		end if
	on error errmsg
		my logger(true, handlername, caller, "WARN", "errmsg1: " & errmsg)
	end try
	
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
	
	--FIX we need to check for show_use_seriesid here.  If we are using series id, we might not have a good way to mark this show.  We might need to select the next showing, and when that showing is over, check to see if a next show is on the schedule.
	if show_end of item show_offset of Show_info is not nextup + ((show_length of item show_offset of Show_info) * minutes) then
		set show_end of item show_offset of Show_info to nextup + ((show_length of item show_offset of Show_info) * minutes)
		my logger(true, handlername, caller, "INFO", "Show end of \"" & show_title of item show_offset of Show_info & "\" set to: " & nextup + ((show_length of item show_offset of Show_info) * minutes))
		my logger(true, handlername, caller, "DEBUG", "WORK Show end class: " & class of (show_end of item show_offset of Show_info))
	end if
	return nextup
end nextday2

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
		my get_show_state(my cm(handlername, caller), hdhr_device, thechan, start_time, end_time)
	end repeat
end show_icons

on seriesScanList(caller, show_id, updateRecord)
	set handlername to "seriesScanList_lib"
	set RefreshderiesiD_list to RefreshderiesiD_list of ParentScript
	set Show_info to Show_info of ParentScript
	if show_id is not in RefreshderiesiD_list then
		if show_id is not missing value then
			set end of RefreshderiesiD_list to show_id
			logger(true, handlername, caller, "INFO", "Added " & show_id & " to SeriesScan list") of ParentScript
		end if
		if updateRecord is true then
			repeat with i from 1 to length of RefreshderiesiD_list
				set show_offset to my HDHRShowSearch(my cm(handlername, caller), item i of RefreshderiesiD_list)
				if show_is_series of item show_offset of Show_info is true then
					seriesScanUpdate(my cm(handlername, caller), item i of RefreshderiesiD_list) of ParentScript
				end if
			end repeat
			set RefreshderiesiD_list to {}
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
				seriesScanUpdate(my cm(handlername, caller), show_id of item i of Show_info) of ParentScript
			end if
		end repeat
		return true
	else
		seriesScanUpdate(my cm(handlername, caller), show_id) of ParentScript
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

*)
