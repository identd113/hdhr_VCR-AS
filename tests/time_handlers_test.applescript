property passedCount : 0
property failedCount : 0
property activeLocale : ""
property fixtureDateText : "Tuesday, January 2, 2024 at 1:05:09 PM"
property fixtureDateHalfText : "Tuesday, January 2, 2024 at 1:30:09 PM"

on run argv
	set libPath to ""
	set localeArg to "all"
	
	set i to 1
	repeat while i is less than or equal to (count of argv)
		set argi to item i of argv
		if argi is "--lib-path" then
			set i to i + 1
			if i is less than or equal to (count of argv) then set libPath to item i of argv
		else if argi is "--locale" then
			set i to i + 1
			if i is less than or equal to (count of argv) then set localeArg to item i of argv
		else if argi is "--fixture-date" then
			set i to i + 1
			if i is less than or equal to (count of argv) then set fixtureDateText to item i of argv
		else if argi is "--fixture-date-half" then
			set i to i + 1
			if i is less than or equal to (count of argv) then set fixtureDateHalfText to item i of argv
		end if
		set i to i + 1
	end repeat
	
	set localeList to my resolveLocales(localeArg)
	repeat with loc in localeList
		my runLocaleSuite((loc as text), libPath)
	end repeat
	
	my emit("SUMMARY|passed=" & passedCount & "|failed=" & failedCount)
	if failedCount is greater than 0 then error "Time handler tests failed" number 1
	return "OK"
end run

on resolveLocales(localeArg)
	if localeArg is "all" then return {"en_US", "en_GB"}
	if localeArg is "en_US" then return {"en_US"}
	if localeArg is "en_GB" then return {"en_GB"}
	error "Unsupported locale: " & localeArg number 2
end resolveLocales

on runLocaleSuite(localeName, libPath)
	set activeLocale to localeName
	my emit("SUITE|" & localeName)
	
	script ParentStub
		property locale : "en_US"
		property Check_after_midnight_time : missing value
		property log_lines : {}
		
		on logger(logtofile, the_handler, caller, loglevel, message)
			set end of log_lines to (loglevel & "|" & the_handler & "|" & caller & "|" & message)
			return true
		end logger
	end script
	set locale of ParentStub to localeName
	
	if libPath is "" then
		set LibScript to me
		set ParentScript to ParentStub
	else
		set libAlias to POSIX file libPath as alias
		set LibScript to run script libAlias
		set ParentScript of LibScript to ParentStub
	end if
	
	set fixedDate to my parseDateOrFail(fixtureDateText, "fixture-date")
	set fixedDateHalf to my parseDateOrFail(fixtureDateHalfText, "fixture-date-half")
	
	my testEpochHandlers(LibScript, fixedDate)
	my testRoundTripHandlers(LibScript, fixedDate)
	my testEpoch2ShowTime(LibScript, fixedDate, fixedDateHalf)
	my testTimeSet(LibScript, fixedDate)
	my testMs2Time(LibScript)
	my testShortDate(LibScript, fixedDate, localeName)
	my testFixDate(LibScript)
	my testCheckAfterMidnight(LibScript, ParentStub)
end runLocaleSuite

on testEpochHandlers(LibScript, fixedDate)
	set testEpochNow to epoch("") of LibScript
	my assertEpochBase(activeLocale & ":epoch:blank", testEpochNow)
	
	-- epoch() mutates the date object it receives, so pass a copy.
	set fixedDateCopy to my cloneDate(fixedDate)
	set testEpochFromDate to epoch(fixedDateCopy) of LibScript
	my assertEpochBase(activeLocale & ":epoch:explicit", testEpochFromDate)
end testEpochHandlers

on testRoundTripHandlers(LibScript, fixedDate)
	set epochSecs to my datetime2epochViaLib(LibScript, fixedDate)
	set roundTripDate to epoch2datetime("test", epochSecs) of LibScript
	my assertNearSeconds(activeLocale & ":roundtrip:datetime2epoch+epoch2datetime", roundTripDate, fixedDate, 1)
end testRoundTripHandlers

on testEpoch2ShowTime(LibScript, fixedDate, fixedDateHalf)
	set epochHour to my datetime2epochViaLib(LibScript, fixedDate)
	set showTimeHour to epoch2show_time("test", epochHour) of LibScript
	set expectedHourText to my expectedEpoch2ShowTime(fixedDate)
	my assertPattern(activeLocale & ":epoch2show_time:whole_hour_pattern", showTimeHour, {item 1 of my stringlistflip("t", expectedHourText, ".", "list"), "."})
	
	set epochHalf to my datetime2epochViaLib(LibScript, fixedDateHalf)
	set showTimeHalf to epoch2show_time("test", epochHalf) of LibScript
	set expectedHalfText to my expectedEpoch2ShowTime(fixedDateHalf)
	my assertEqual(activeLocale & ":epoch2show_time:half_hour", showTimeHalf, expectedHalfText)
	my assertPattern(activeLocale & ":epoch2show_time:half_hour_pattern", showTimeHalf, {item 1 of my stringlistflip("t", expectedHalfText, ".", "list"), "."})
end testEpoch2ShowTime

on testTimeSet(LibScript, fixedDate)
	set shifted to time_set("test", my cloneDate(fixedDate), 16.75) of LibScript
	my assertEqual(activeLocale & ":time_set:year", year of shifted, year of fixedDate)
	my assertEqual(activeLocale & ":time_set:month", (month of shifted) * 1, (month of fixedDate) * 1)
	my assertEqual(activeLocale & ":time_set:day", day of shifted, day of fixedDate)
	my assertEqual(activeLocale & ":time_set:hour", hours of shifted, 16)
	my assertEqual(activeLocale & ":time_set:minute", minutes of shifted, 45)
	my assertEqual(activeLocale & ":time_set:second", seconds of shifted, 0)
end testTimeSet

on testMs2Time(LibScript)
	my assertEqual(activeLocale & ":ms2time:lt1s", ms2time("test", 500, "ms", 3) of LibScript, "<1s")
	my assertEqual(activeLocale & ":ms2time:zero", ms2time("test", 0, "s", 3) of LibScript, "0ms")
	my assertEqual(activeLocale & ":ms2time:hms", ms2time("test", 3661, "s", 3) of LibScript, "1H 1M 1S")
	my assertEqual(activeLocale & ":ms2time:day_rollup", ms2time("test", 90061, "s", 4) of LibScript, "1D 1H 1M 1S")
	my assertEqual(activeLocale & ":ms2time:precision", ms2time("test", 3661, "s", 2) of LibScript, "1H 1M")
end testMs2Time

on testShortDate(LibScript, fixedDate, localeName)
	if localeName is "en_US" then
		my assertEqual(activeLocale & ":short_date:us_12h_seconds", short_date("test", fixedDate, false, true) of LibScript, my expectedShortDate(fixedDate, "en_US", false, true))
		my assertEqual(activeLocale & ":short_date:us_24h_no_seconds", short_date("test", fixedDate, true, false) of LibScript, my expectedShortDate(fixedDate, "en_US", true, false))
	else if localeName is "en_GB" then
		my assertEqual(activeLocale & ":short_date:gb_12h_seconds", short_date("test", fixedDate, false, true) of LibScript, my expectedShortDate(fixedDate, "en_GB", false, true))
		my assertEqual(activeLocale & ":short_date:gb_24h_no_seconds", short_date("test", fixedDate, true, false) of LibScript, my expectedShortDate(fixedDate, "en_GB", true, false))
	end if
end testShortDate

on testFixDate(LibScript)
	set thinSpace to character id 8239
	set rawDateText to "A" & thinSpace & "B C"
	set fixedText to fixDate("test", rawDateText) of LibScript
	my assertEqual(activeLocale & ":fixDate:normalized_spaces", fixedText, "A B C")
	my assertEqual(activeLocale & ":fixDate:no_thin_space", (fixedText contains thinSpace), false)
end testFixDate

on testCheckAfterMidnight(LibScript, ParentStub)
	set todayDay to day of my nowDate()
	set Check_after_midnight_time of ParentStub to todayDay
	set noChangeResult to check_after_midnight("test") of LibScript
	my assertBoolean(activeLocale & ":check_after_midnight:no_change_boolean", noChangeResult)
	
	if todayDay is greater than 1 then
		set Check_after_midnight_time of ParentStub to todayDay - 1
	else
		set Check_after_midnight_time of ParentStub to todayDay + 1
	end if
	set priorState to Check_after_midnight_time of ParentStub
	
	my assertEqual(activeLocale & ":check_after_midnight:day_change", check_after_midnight("test") of LibScript, true)
	-- Current handler updates only local state, not ParentScript state.
	my assertEqual(activeLocale & ":check_after_midnight:state_passthrough", Check_after_midnight_time of ParentStub, priorState)
end testCheckAfterMidnight

on datetime2epochViaLib(LibScript, theDateObject)
	return (theDateObject - (epoch("") of LibScript)) as integer
end datetime2epochViaLib

on assertEpochBase(testId, dateValue)
	my assertEqual(testId & ":year", year of dateValue, 1970)
	my assertEqual(testId & ":month", (month of dateValue) * 1, 1)
	my assertEqual(testId & ":day", day of dateValue, 1)
	my assertEqual(testId & ":hour", hours of dateValue, 0)
	my assertEqual(testId & ":minute", minutes of dateValue, 0)
	my assertEqual(testId & ":second", seconds of dateValue, 0)
end assertEpochBase

on assertEqual(testId, gotValue, expectedValue)
	set gotText to my asTextSafe(gotValue)
	set expectedText to my asTextSafe(expectedValue)
	if gotText is expectedText then
		set passedCount to passedCount + 1
		my emit("PASS|" & testId & "|" & gotText)
	else
		set failedCount to failedCount + 1
		my emit("FAIL|" & testId & "|expected=" & expectedText & "|got=" & gotText)
	end if
end assertEqual

on assertNearSeconds(testId, gotDate, expectedDate, toleranceSec)
	try
		set deltaSec to gotDate - expectedDate
		if deltaSec is less than 0 then set deltaSec to deltaSec * -1
		if deltaSec is less than or equal to toleranceSec then
			set passedCount to passedCount + 1
			my emit("PASS|" & testId & "|delta=" & deltaSec)
		else
			set failedCount to failedCount + 1
			my emit("FAIL|" & testId & "|expected_delta<=" & toleranceSec & "|got_delta=" & deltaSec)
		end if
	on error errmsg
		set failedCount to failedCount + 1
		my emit("FAIL|" & testId & "|error=" & errmsg)
	end try
end assertNearSeconds

on assertPattern(testId, gotValue, patternParts)
	set gotText to my asTextSafe(gotValue)
	repeat with p in patternParts
		if gotText does not contain (p as text) then
			set failedCount to failedCount + 1
			my emit("FAIL|" & testId & "|missing=" & (p as text) & "|got=" & gotText)
			return
		end if
	end repeat
	set passedCount to passedCount + 1
	my emit("PASS|" & testId & "|" & gotText)
end assertPattern

on assertBoolean(testId, gotValue)
	if gotValue is in {true, false} then
		set passedCount to passedCount + 1
		my emit("PASS|" & testId & "|" & (gotValue as text))
	else
		set failedCount to failedCount + 1
		my emit("FAIL|" & testId & "|expected=true_or_false|got=" & my asTextSafe(gotValue))
	end if
end assertBoolean

on asTextSafe(v)
	try
		return v as text
	on error
		return "<non-text>"
	end try
end asTextSafe

on emit(lineText)
	log lineText
end emit

on nowDate()
	return my parseDateOrFail(fixtureDateText, "fixture-date")
end nowDate

on cloneDate(sourceDate)
	return date (sourceDate as text)
end cloneDate

on parseDateOrFail(dateText, argName)
	if (dateText contains "-") or (dateText contains "/") then
		set numericFirst to my parseNumericDate(dateText)
		if numericFirst is not missing value then return numericFirst
	end if
	try
		set nativeDate to date dateText
		set nativeYear to year of nativeDate as integer
		if nativeYear is greater than or equal to 1900 and nativeYear is less than or equal to 2100 then
			return nativeDate
		end if
	on error
	end try
	set parsed to my parseNumericDate(dateText)
	if parsed is not missing value then return parsed
	error "Unable to parse --" & argName & ": " & quote & dateText & quote & ". Supported examples: \"Tuesday, January 2, 2024 at 1:05:09 PM\", \"2024-01-02 13:05:09\", \"02/01/2024 13:05:09\", \"01/02/2024 13:05:09\"" number 2
end parseDateOrFail

on parseNumericDate(dateText)
	try
		set normalized to my replace_chars(my replace_chars(dateText, "T", " "), "  ", " ")
		set parts to my stringlistflip("parseNumericDate", normalized, " ", "list")
		if (length of parts) is less than 2 then return missing value
		
		if (length of parts) is greater than or equal to 4 and (item 2 of parts as text) is not in {"AM", "PM", "am", "pm"} then
			set dayText to item 1 of parts as text
			set monthText to item 2 of parts as text
			set yearText to item 3 of parts as text
			set timePart to item 4 of parts as text
			set dd to dayText as integer
			set mm to my monthNameToNumber(monthText)
			set yy to yearText as integer
			if mm is missing value then return missing value
		else
			set datePart to item 1 of parts
			set timePart to item 2 of parts

			if datePart contains "-" then
				set dParts to my stringlistflip("parseNumericDate", datePart, "-", "list")
			else if datePart contains "/" then
				set dParts to my stringlistflip("parseNumericDate", datePart, "/", "list")
			else
				return missing value
			end if
			if (length of dParts) is not 3 then return missing value

			set d1 to (item 1 of dParts) as integer
			set d2 to (item 2 of dParts) as integer
			set d3 to (item 3 of dParts) as integer

			if (length of (item 1 of dParts as text)) is 4 then
				set yy to d1
				set mm to d2
				set dd to d3
			else
				set yy to d3
				if d1 is greater than 12 then
					set dd to d1
					set mm to d2
				else if d2 is greater than 12 then
					set mm to d1
					set dd to d2
				else
					if activeLocale is "en_US" then
						set mm to d1
						set dd to d2
					else
						set dd to d1
						set mm to d2
					end if
				end if
			end if
		end if
		
		set tParts to my stringlistflip("parseNumericDate", timePart, ":", "list")
		if (length of tParts) is less than 2 then return missing value
		set hh to (item 1 of tParts) as integer
		set mi to (item 2 of tParts) as integer
		if (length of tParts) is greater than or equal to 3 then
			set ss to (item 3 of tParts) as integer
		else
			set ss to 0
		end if
		
		set d to date "Tuesday, January 2, 2024 at 1:05:09 PM"
		set year of d to yy
		set month of d to mm
		set day of d to dd
		set hours of d to hh
		set minutes of d to mi
		set seconds of d to ss
		return d
	on error
		return missing value
	end try
end parseNumericDate

on monthNameToNumber(monthText)
	set m to my replace_chars(monthText as text, ".", "")
	if m is in {"January", "Jan", "january", "jan"} then return 1
	if m is in {"February", "Feb", "february", "feb"} then return 2
	if m is in {"March", "Mar", "march", "mar"} then return 3
	if m is in {"April", "Apr", "april", "apr"} then return 4
	if m is in {"May", "may"} then return 5
	if m is in {"June", "Jun", "june", "jun"} then return 6
	if m is in {"July", "Jul", "july", "jul"} then return 7
	if m is in {"August", "Aug", "august", "aug"} then return 8
	if m is in {"September", "Sep", "sept", "september", "sep"} then return 9
	if m is in {"October", "Oct", "october", "oct"} then return 10
	if m is in {"November", "Nov", "november", "nov"} then return 11
	if m is in {"December", "Dec", "december", "dec"} then return 12
	return missing value
end monthNameToNumber

on expectedEpoch2ShowTime(theDate)
	set h to hours of theDate
	set m to minutes of theDate
	if m is not 0 then
		set mPart to ((m * 100 + 59) div 60) as integer
		return (h as text) & "." & my pad2(mPart)
	else
		return h as text
	end if
end expectedEpoch2ShowTime

on expectedShortDate(theDate, localeName, twentyFour, showSeconds)
	set y to year of theDate as text
	set yy to text -2 thru -1 of y
	set mm to my pad2((month of theDate) * 1)
	set dd to my pad2(day of theDate)
	set hh to hours of theDate
	set mi to my pad2(minutes of theDate)
	set ss to my pad2(seconds of theDate)
	set ampm to ""
	
	if twentyFour is false then
		if hh is greater than or equal to 12 then
			set ampm to " PM"
			if hh is greater than 12 then set hh to hh - 12
		else
			set ampm to " AM"
		end if
		if hh is 0 then set hh to 12
		set hhText to hh as text
	else
		set hhText to my pad2(hh)
	end if
	
	if localeName is "en_US" then
		if showSeconds is true then
			return mm & "." & dd & "." & yy & " " & hhText & "." & mi & "." & ss & ampm
		else
			return mm & "." & dd & "." & yy & " " & hhText & "." & mi & ampm
		end if
	else
		if showSeconds is true then
			return yy & "/" & mm & "/" & dd & " " & hhText & "." & mi & "." & ss & ampm
		else
			return yy & "/" & mm & "/" & dd & " " & hhText & "." & mi & ampm
		end if
	end if
end expectedShortDate

on pad2(n)
	set t to n as text
	if (length of t) is 1 then return "0" & t
	return t
end pad2
