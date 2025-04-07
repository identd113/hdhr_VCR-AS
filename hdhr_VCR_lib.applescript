# hdhr_vcr library.  This needs to be located in the users Documents Folder, and not renamed.

global HdhrVCR_loaded
property ParentScript : missing value

on cm(handlername, caller)
	return {handlername, "(" & caller & ")"} as text
end cm

on load_hdhrVCR_vars()
	set handlername to "load_hdhrVCR_vars_lib"
	-- We need to receive states from the hdhr_vcr here
	set vers_lib to "20250407"
	return vers_lib
end load_hdhrVCR_vars

on checkDiskSpace(caller, the_path)
	set handlername to "checkDiskSpace_lib"
	try
		set checkDiskSpace_return to do shell script "df -k '" & the_path & "'"
		set checkDiskSpace_temp1 to item 2 of my stringlistflip(my cm(handlername, caller), checkDiskSpace_return, return, "list")
		set checkDiskSpace_temp2 to my emptylist(stringlistflip(my cm(handlername, caller), checkDiskSpace_temp1, space, "list"))
		return {the_path, first word of item 5 of checkDiskSpace_temp2 as number, first word of item 4 of checkDiskSpace_temp2 as number}
	on error errmsg
		return {the_path, 0, errmsg}
	end try
end checkDiskSpace

on emptylist(klist)
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

on repeatProgress(loop_delay, loop_total)
	set handlername to "repeatProgress_lib"
	try
		set progress total steps to loop_total
		repeat with i from 1 to loop_total
			set progress completed steps to i
			delay loop_delay
			if i is loop_total then
				delay loop_delay
			end if
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

on end_jsonhelper()
	try
		set handlername to "end_jsonhelper_lib"
		tell application "JSON Helper" to quit
	on error errmsg
		return {handlername, errmsg}
	end try
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

on HDHRShowSearch(the_show_id)
	set handlername to "HDHRShowSearch_lib"
	try
		set show_info to show_info of ParentScript
		if length of show_info is greater than 0 then
			repeat with i from 1 to length of show_info
				if show_id of item i of show_info is the_show_id then
					return i
				end if
			end repeat
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
		logger(true, handlername, caller, "INFO", "isModifierKeyPressed: " & checkKey & ", reason: " & desc) of ParentScript
	on error errmsg
		logger(true, handlername, caller, "WARN", "isModifierKeyPressed check failed: " & errmsg) of ParentScript
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
		logger(true, handlername, caller, "DEBUG", item 2 of my stringlistflip("isModifierKeyPressed(" & caller & ")", errmsg, {"{", "}"}, "list")) of ParentScript
	end try
	return modiferKeysDOWN
end isModifierKeyPressed

on quoteme(thestring)
	set handlername to "quoteme_lib"
	set temp to (quote & thestring & quote) as text
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