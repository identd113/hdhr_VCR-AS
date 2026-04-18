-- JSONHelper Type Round-Trip Test — individual type tests
-- Each type is saved and loaded in isolation so a bad type doesn't wipe other results.
-- Uses the same open-for-access / make JSON from / read JSON from pattern as hdhr_VCR.
--
-- Run: osascript scripts/jsonhelper_type_test.applescript
-- Results: logged to stdout and ~/Desktop/jsonhelper_type_test_results.txt

use AppleScript version "2.4"
use scripting additions
use application "JSON Helper"

-- ── File helpers ──────────────────────────────────────────────────────────────

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

-- ── Single-type round-trip test ───────────────────────────────────────────────
-- Saves {key: value}, loads it back, compares class and text representation.

on test_type(testpath, label, value)
	set orig_class to (class of value) as text
	set orig_val to ""
	try
		set orig_val to value as text
	on error
		set orig_val to "«uncoerceable»"
	end try

	-- Save
	set json_written to my write_json(testpath, {testval:value})
	if json_written starts with "MAKE_JSON_ERROR" or json_written starts with "READ_ERROR" then
		return "[" & label & "] SAVE FAILED — " & json_written & "  (orig class=" & orig_class & " val=" & orig_val & ")"
	end if

	-- Load
	set loaded_rec to my read_json(testpath)
	if class of loaded_rec is text then
		return "[" & label & "] LOAD FAILED — " & loaded_rec & "  (json=" & json_written & ")"
	end if

	-- Inspect loaded value
	set loaded_val_raw to testval of loaded_rec
	set loaded_class to (class of loaded_val_raw) as text
	set loaded_val to ""
	try
		set loaded_val to loaded_val_raw as text
	on error
		set loaded_val to "«uncoerceable»"
	end try

	-- Determine status
	set status to "OK"
	if orig_class is not loaded_class then set status to "CLASS CHANGED (" & orig_class & " → " & loaded_class & ")"
	if orig_val is not loaded_val and status is "OK" then set status to "VALUE CHANGED"

	-- Extra: for date, try re-parsing the loaded string back as a date (the locale-risk op)
	set date_note to ""
	if orig_class is "date" then
		try
			set reparsed to date (loaded_val)
			set date_note to "  [date reparse: OK → " & reparsed & "]"
		on error errmsg
			set date_note to "  [date reparse: FAILED — " & errmsg & "]"
		end try
	end if

	return "[" & label & "] " & status & return ¬
		& "  orig:   class=" & orig_class & "  val=" & orig_val & return ¬
		& "  loaded: class=" & loaded_class & "  val=" & loaded_val & return ¬
		& "  json:   " & json_written & date_note
end test_type

-- ── Missing value needs special handling — test_type can't hold it ─────────────

on test_missing_value(testpath)
	set label to "missing value (raw)"
	try
		set json_written to my write_json(testpath, {testval:missing value})
		if json_written starts with "MAKE_JSON_ERROR" then
			return "[" & label & "] SAVE FAILED — " & json_written
		end if
		set loaded_rec to my read_json(testpath)
		if class of loaded_rec is text then
			return "[" & label & "] LOAD FAILED — " & loaded_rec
		end if
		set loaded_val_raw to testval of loaded_rec
		return "[" & label & "] OK" & return ¬
			& "  loaded class=" & (class of loaded_val_raw as text) & "  json=" & json_written
	on error errmsg
		return "[" & label & "] ERROR — " & errmsg
	end try
end test_missing_value

-- ── List round-trip (can't pass list through test_type's record) ───────────────

on test_list(testpath, label, listval)
	set orig_class to (class of listval) as text
	set orig_len to length of listval
	set json_written to my write_json(testpath, {testval:listval})
	if json_written starts with "MAKE_JSON_ERROR" then
		return "[" & label & "] SAVE FAILED — " & json_written
	end if
	set loaded_rec to my read_json(testpath)
	if class of loaded_rec is text then
		return "[" & label & "] LOAD FAILED — " & loaded_rec
	end if
	set loaded_val_raw to testval of loaded_rec
	set loaded_class to (class of loaded_val_raw) as text
	set loaded_len to 0
	try
		set loaded_len to length of loaded_val_raw
	end try
	set status to "OK"
	if orig_class is not loaded_class then set status to "CLASS CHANGED (" & orig_class & " → " & loaded_class & ")"
	if orig_len is not loaded_len and status is "OK" then set status to "LENGTH CHANGED (" & orig_len & " → " & loaded_len & ")"
	return "[" & label & "] " & status & return ¬
		& "  orig:   class=" & orig_class & "  len=" & orig_len & return ¬
		& "  loaded: class=" & loaded_class & "  len=" & loaded_len & return ¬
		& "  json:   " & json_written
end test_list

-- ── Main ──────────────────────────────────────────────────────────────────────

on run
	set testpath to POSIX path of (path to desktop) & "jsonhelper_type_test.json"
	set resultpath to POSIX path of (path to desktop) & "jsonhelper_type_test_results.txt"

	set divider to "─────────────────────────────────────────────────"
	set report to "JSONHelper Type Round-Trip Test" & return
	set report to report & "Locale: " & (user locale of (system info)) & return
	set report to report & "OS: " & (system version of (system info)) & return
	set report to report & "Date: " & (current date) as text & return
	set report to report & divider & return

	-- Run individual tests
	set test_results to {}
	set end of test_results to my test_type(testpath, "string", "Hello from hdhr_VCR")
	set end of test_results to my test_type(testpath, "empty string", "")
	set end of test_results to my test_type(testpath, "integer (small)", 42)
	set end of test_results to my test_type(testpath, "integer (negative)", -7)
	set end of test_results to my test_type(testpath, "integer (epoch-scale 1745006400)", 1745006400)
	set end of test_results to my test_type(testpath, "real (3.14159)", 3.14159)
	set end of test_results to my test_type(testpath, "real (show_time 20.5)", 20.5)
	set end of test_results to my test_type(testpath, "boolean true", true)
	set end of test_results to my test_type(testpath, "boolean false", false)
	set end of test_results to my test_type(testpath, "date (current date)", current date)
	set end of test_results to my test_type(testpath, "string 'missing value'", "missing value")
	set end of test_results to my test_missing_value(testpath)
	set end of test_results to my test_list(testpath, "list of strings", {"Monday", "Wednesday", "Friday"})
	set end of test_results to my test_list(testpath, "empty list", {})
	set end of test_results to my test_list(testpath, "list with integer", {1, 2, 3})

	-- Assemble report
	repeat with ln in test_results
		set report to report & (ln as text) & return & return
	end repeat

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

	-- Log to stdout (visible when run via osascript)
	log report
end run
