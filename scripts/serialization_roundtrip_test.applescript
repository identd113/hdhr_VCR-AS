-- Serialization/Deserialization Round-Trip Test
-- Tests serialize_show and deserialize_show handlers with a complete show record.

use AppleScript version "2.4"
use scripting additions
use application "JSON Helper"

global ParentScript

on logger(verbose, handlername, caller, level, msg)
	if verbose then
		log level & " [" & handlername & "] " & msg
	end if
end logger

on write_json(testpath, rec)
	try
		set json_out to (make JSON from rec)
		set ref_num to open for access POSIX file testpath with write permission
		set eof of ref_num to 0
		write json_out to ref_num
		close access ref_num
		return json_out
	on error errmsg
		try
			close access ref_num
		end try
		return "MAKE_JSON_ERROR: " & errmsg
	end try
end write_json

on read_json(testpath)
	try
		set ref_num to open for access POSIX file testpath
		set raw to read ref_num
		close access ref_num
		if raw is "" then return "READ_ERROR: file is empty"
		return (read JSON from raw)
	on error errmsg
		try
			close access ref_num
		end try
		return "READ_JSON_ERROR: " & errmsg
	end try
end read_json

on dates_nearly_equal(d1, d2, gmt_offset)
	try
		-- Handle missing value comparisons
		if (d1 is missing value) and (d2 is missing value) then
			return true
		end if
		set diff to d1 - d2
		if diff < 0 then set diff to -diff
		-- Allow GMT offset difference plus 5 seconds for precision loss
		-- GMT offset is in seconds (negative for west of GMT, positive for east)
		set tolerance to (gmt_offset / 1) + 5
		if tolerance < 0 then set tolerance to -tolerance
		return diff < (tolerance + 5)
	on error
		-- If subtraction fails, compare as text
		return (d1 as text) is (d2 as text)
	end try
end dates_nearly_equal

on run
	set LibScript to load script POSIX file "/Users/plexserver/Documents/hdhr_VCR_lib.scpt"
	set ParentScript of LibScript to me

	set testpath to POSIX path of (path to desktop) & "serialization_roundtrip_test.json"
	set resultpath to POSIX path of (path to desktop) & "serialization_roundtrip_test_results.txt"

	-- Calculate GMT offset for timezone-aware comparisons
	set gmt_offset to (time to GMT)
	if gmt_offset < 0 then set gmt_offset to -gmt_offset

	set divider to "-----------------------------------"
	set report to "Serialization/Deserialization Round-Trip Test" & return
	set report to report & "GMT Offset: " & (gmt_offset / 3600) & " hours" & return
	set report to report & divider & return & return

	-- Create test show record with date objects
	set test_date_next to (current date) + 3600
	set test_date_end to test_date_next + 1800
	set test_date_last to (current date) - 86400
	set test_date_notify_rec to test_date_next - 930
	set test_date_notify_upnext to test_date_next - 2100

	set test_show to {show_id:"TEST-001", show_title:"Test Show", show_is_series:true, show_use_seriesid:false, show_use_seriesid_all:false, show_active:true, show_recording:false, show_channel:"5.4", show_time:14.5, show_length:30, show_dir:"/Volumes/test", show_temp_dir:"/Volumes/test", show_url:"http://test", show_air_date:{"Monday", "Wednesday"}, show_next:test_date_next, show_end:test_date_end, show_last:test_date_last, notify_recording_time:test_date_notify_rec, notify_upnext_time:test_date_notify_upnext, hdhr_record:"12345ABC", show_fail_count:0, show_fail_reason:""}

	-- Step 1: Serialize
	set report to report & "Step 1: Serialize" & return
	set report to report & "  Input: show record with date objects" & return

	set serialized to ""
	try
		set serialized to serialize_show("test_handler", test_show) of LibScript
	on error errmsg
		set report to report & "  ERROR during serialization: " & errmsg & return & return
		log report
		return
	end try
	set report to report & "  Output: serialized record" & return
	set report to report & "    show_next class: " & (class of show_next of serialized as text) & return
	set report to report & "    show_end class: " & (class of show_end of serialized as text) & return
	set report to report & "    show_last class: " & (class of show_last of serialized as text) & return & return

	-- Step 2: JSON Round-Trip
	set report to report & "Step 2: JSON Round-Trip" & return
	set json_written to my write_json(testpath, {the_shows:{serialized}})
	if json_written starts with "MAKE_JSON_ERROR" then
		set report to report & "  SAVE FAILED: " & json_written & return & return
		log report
		return
	end if

	set json_loaded_rec to my read_json(testpath)
	if class of json_loaded_rec is text then
		set report to report & "  LOAD FAILED: " & json_loaded_rec & return & return
		log report
		return
	end if

	set json_shows_list to the_shows of json_loaded_rec
	set loaded_from_json to item 1 of json_shows_list
	set report to report & "  JSON loaded successfully" & return & return

	-- Step 3: Deserialize
	set report to report & "Step 3: Deserialize" & return
	set deserialized to deserialize_show("test_handler", loaded_from_json) of LibScript
	set report to report & "  Output: deserialized record" & return
	set report to report & "    show_next class: " & (class of show_next of deserialized as text) & return
	set report to report & "    show_end class: " & (class of show_end of deserialized as text) & return
	set report to report & "    show_last class: " & (class of show_last of deserialized as text) & return & return

	-- Step 4: Verify Dates Match
	set report to report & "Step 4: Verify Dates Match" & return

	set show_next_match to my dates_nearly_equal(show_next of test_show, show_next of deserialized, gmt_offset)
	set show_end_match to my dates_nearly_equal(show_end of test_show, show_end of deserialized, gmt_offset)
	set show_last_match to my dates_nearly_equal(show_last of test_show, show_last of deserialized, gmt_offset)
	set notify_rec_match to my dates_nearly_equal(notify_recording_time of test_show, notify_recording_time of deserialized, gmt_offset)
	set notify_upnext_match to my dates_nearly_equal(notify_upnext_time of test_show, notify_upnext_time of deserialized, gmt_offset)

	set all_match to show_next_match and show_end_match and show_last_match and notify_rec_match and notify_upnext_match

	set show_next_status to "MISMATCH"
	if show_next_match then set show_next_status to "MATCH"
	set report to report & "  show_next: " & show_next_status & return
	set report to report & "    orig:  " & (show_next of test_show as text) & return
	set report to report & "    deser: " & (show_next of deserialized as text) & return

	set show_end_status to "MISMATCH"
	if show_end_match then set show_end_status to "MATCH"
	set report to report & "  show_end: " & show_end_status & return

	set show_last_status to "MISMATCH"
	if show_last_match then set show_last_status to "MATCH"
	set report to report & "  show_last: " & show_last_status & return

	set notify_rec_status to "MISMATCH"
	if notify_rec_match then set notify_rec_status to "MATCH"
	set report to report & "  notify_recording_time: " & notify_rec_status & return

	set notify_upnext_status to "MISMATCH"
	if notify_upnext_match then set notify_upnext_status to "MATCH"
	set report to report & "  notify_upnext_time: " & notify_upnext_status & return & return

	-- Summary
	set report to report & divider & return
	set summary_status to "SOME TESTS FAILED"
	if all_match then set summary_status to "ALL TESTS PASSED"
	set report to report & summary_status & return

	-- Write results file
	try
		set result_ref to open for access POSIX file resultpath with write permission
		set eof of result_ref to 0
		write report to result_ref
		close access result_ref
	on error errmsg
		try
			close access result_ref
		end try
	end try

	log report
end run
