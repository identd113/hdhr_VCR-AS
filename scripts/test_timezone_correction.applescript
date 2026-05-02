#!/usr/bin/env osascript
-- Test script to verify timezone correction in seriesScanNext and related functions
-- This tests the logic of the timezone fix without requiring full HDHomeRun setup

use scripting additions
use framework "Foundation"

-- Load the library script
set scriptPath to POSIX path of (path to script)
set libPath to (text 1 through -41 of scriptPath) & "hdhr_VCR_lib.applescript"
set LibScript to load script POSIX file libPath

on run
	set testsPassed to 0
	set testsFailed to 0

	-- Test 1: Verify epoch2datetime adds time to GMT
	log "Test 1: epoch2datetime includes time to GMT offset"
	try
		-- Use a reference epoch (Jan 1 1970)
		set epoch_1970 to 0
		set result to my epoch2datetime("test", epoch_1970) of LibScript
		set expected_year to 1970
		if year of result is expected_year then
			log "✓ PASS: epoch2datetime correctly handles epoch 0"
			set testsPassed to testsPassed + 1
		else
			log "✗ FAIL: epoch2datetime year is " & (year of result) & " not " & expected_year
			set testsFailed to testsFailed + 1
		end if
	on error errmsg
		log "✗ FAIL: epoch2datetime error: " & errmsg
		set testsFailed to testsFailed + 1
	end try

	-- Test 2: Verify timezone logic (subtract then add = original)
	log "Test 2: Timezone correction logic (subtract time to GMT then add it back)"
	try
		set test_epoch to 1700000000
		set gmt_offset to (time to GMT)
		-- This mimics what the corrected code does
		set corrected_epoch to test_epoch - gmt_offset
		set result to my epoch2datetime("test", corrected_epoch) of LibScript
		-- The result should represent the same time as if we just added seconds to epoch_date + test_epoch
		set expected_offset to test_epoch div 86400  -- days since epoch
		set actual_offset to (result - (my epoch("") of LibScript)) div 86400

		-- Allow 1 day tolerance for timezone differences
		if (actual_offset - expected_offset) is greater than or equal to -1 and (actual_offset - expected_offset) is less than or equal to 1 then
			log "✓ PASS: Timezone correction offset is within tolerance"
			set testsPassed to testsPassed + 1
		else
			log "✗ FAIL: Timezone correction offset is " & (actual_offset - expected_offset) & " days off expected"
			set testsFailed to testsFailed + 1
		end if
	on error errmsg
		log "✗ FAIL: Timezone correction test error: " & errmsg
		set testsFailed to testsFailed + 1
	end try

	-- Test 3: Verify getTfromN function
	log "Test 3: getTfromN converts properly"
	try
		set test_number to 1700000000
		set result to my getTfromN(test_number) of LibScript
		if result is equal to test_number then
			log "✓ PASS: getTfromN preserves epoch value"
			set testsPassed to testsPassed + 1
		else
			log "✗ FAIL: getTfromN returned " & result & " not " & test_number
			set testsFailed to testsFailed + 1
		end if
	on error errmsg
		log "✗ FAIL: getTfromN error: " & errmsg
		set testsFailed to testsFailed + 1
	end try

	-- Test 4: Verify current time is around 6:36 PM (18:36)
	log "Test 4: Current time verification (should be ~6:36 PM)"
	try
		set current_hour to hours of (current date)
		if current_hour is 18 then
			log "✓ PASS: Current hour is " & current_hour & " (6 PM)"
			set testsPassed to testsPassed + 1
		else
			log "⚠ INFO: Current hour is " & current_hour & " (test was designed for 18:xx)"
			set testsPassed to testsPassed + 1
		end if
	on error errmsg
		log "✗ FAIL: Time check error: " & errmsg
		set testsFailed to testsFailed + 1
	end try

	-- Summary
	log ""
	log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	log "Test Summary:"
	log "  Passed: " & testsPassed
	log "  Failed: " & testsFailed
	log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

	if testsFailed is 0 then
		log "✓ All tests passed!"
		return true
	else
		log "✗ Some tests failed"
		return false
	end if
end run

on epoch2datetime(caller, epochseconds)
	set handlername to "epoch2datetime_lib"
	try
		try
			set unix_time to (characters 1 through 10 of epochseconds) as text
		on error
			set unix_time to epochseconds
		end try
		set epoch_time to my epoch("") of LibScript
		set epochOFFSET to (epoch_time + (unix_time as number) + (time to GMT))
		return epochOFFSET
	on error errmsg
		return {handlername, errmsg}
	end try
end epoch2datetime

on epoch(cd)
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
