# Handler Reference

## Overview
The hdhr_VCR project packages two collaborating AppleScript files that turn an HDHomeRun tuner into a lightweight DVR. The `hdhr_VCR.applescript` file hosts the main application logic and user interface flow, while `hdhr_VCR_lib.applescript` provides reusable helpers for date math, logging, SeriesID handling, and other utilities that keep the core script tidy.

## Purpose
This guide gives a formatted inventory of every handler in both scripts, the inputs they expect, the values they return, and how the surrounding run loop treats `missing value` results. AppleScript commonly uses `missing value` to indicate "no response"; wherever a handler returns it, the table explains whether the application's main loop, idle loop, or other retry logic will revisit the handler.

---

## `hdhr_VCR.applescript`

| Handler | Inputs | Outputs | Notes & Missing Value Handling |
| --- | --- | --- | --- |
| `setup_lib` | `caller` | `boolean` | Loads the compiled library script, binds globals, and returns success; no loop retry beyond logging failures. |
| `setup_icons` | `caller` | `boolean` | Populates emoji icons for UI; setup sequence retries by calling next setup steps only on success. |
| `setup_script` | `caller` | `boolean` | Initializes environment data (paths, locale, caches); startup chain halts if false. |
| `setup_globals` | `caller` | `boolean` | Resets global state for a fresh run; failures prevent progressing to runtime loop. |
| `setup_logging` | `caller` | `boolean` | Creates log directories and counters; startup stops on failure. |
| `run` | none | `missing value` | Entry point for the application; hands control to startup logic and then defers to the idle loop, which continually re-enters. |
| `idle` | none | `integer` | Returns seconds until the next idle invocation; the Script Editor idle loop handles repeated calls. |
| `reopen` | none | `missing value` | Handles Dock icon reopen events; UI flow resumes via `main`, triggered by the idle loop. |
| `quit` | none | `missing value` | Manages shutdown, warns about active recordings, and then allows the system quit process to continue. |
| `hdhrGRID` | `caller`, `hdhr_device`, `hdhr_channel` | `record list` or `boolean` or `list({""})` | Returns guide selections, navigation flags, or a manual entry signal; calling code loops for user interaction until ready. |
| `tuner_overview` | `caller` | `list` | Summarizes tuner status strings for UI display. |
| `tuner_ready_time` | `caller`, `hdhr_model` | `number` | Computes seconds until a tuner is available. |
| `tuner_inuse` | `caller`, `device_id` | `list` or `text` | Lists active client IPs or `""` on timeout; caller may poll again. |
| `tuner_status` | `caller`, `device_id` | `record` or `false` | Returns `{tunermax, tuneractive}` or false when unreachable; caller retries as needed. |
| `tuner_mismatch` | `caller`, `device_id` | `missing value` | Audits tuner usage; recursively loops through tuners until reconciled. |
| `is_channel_record` | `caller`, `hdhr_tuner`, `channelcheck`, `cd` | `text` | Builds recording state glyphs for a channel row. |
| `get_show_state` | `caller`, `hdhr_tuner`, `channelcheck`, `start_time`, `end_time` | `record` | Returns `{show_stat, the_show_id, status_icon}` describing schedule status. |
| `show_info_dump` | `caller`, `show_id_lookup`, `userdisplay` | `missing value` | Logs show info for debugging; manual trigger, no loop. |
| `check_version` | `caller` | `missing value` | Contacts remote version metadata, with internal retry loop on failure before giving up. |
| `kill_jsonhelper` | `caller` | `missing value` | Quits the helper process and lets idle loop restart if needed. |
| `check_version_dialog` | `caller` | `text` | Formats version information for display. |
| `build_channel_list` | `caller`, `hdhr_device`, `cd` | `missing value` | Refreshes cached lineups; invoked repeatedly during discovery loops. |
| `channel2name` | `caller`, `the_channel`, `hdhr_device` | `text` or `false` | Resolves channel names; caller may loop on false to request manual entry. |
| `nextday` | `caller`, `the_show_id` | `date` | Calculates the next airing and updates metadata. |
| `validate_show_info` | `caller`, `show_to_check`, `should_edit` | `missing value` | Normalizes Show_info entries; interactive flows keep prompting until validation passes. |
| `setup` | `caller` | `missing value` | Drives the guided setup wizard; loops through prompts until completion. |
| `AreWeOnline` | `caller` | `boolean` | Confirms device availability; caller may retry when false. |
| `main` | `caller`, `emulated_button_press` | `boolean` or `missing value` | Runs the primary UI. Returns `false` to exit or `missing value` when control passes back to idle loop. |
| `add_show_info` | `caller`, `hdhr_device`, `hdhr_channel` | `boolean` or `missing value` | Returns `false` on cancel, otherwise continues scheduling workflow; UI loops until selection complete. |
| `record_start` | `caller`, `the_show_id`, `opt_show_length`, `force_update` | `missing value` | Validates and launches recordings; main scheduler loops through pending shows. |
| `HDHRDeviceDiscovery` | `caller`, `hdhr_device` | `missing value` | Discovers tuners and updates caches, iterating over device list as needed. |
| `HDHRDeviceSearch` | `caller`, `hdhr_device` | `integer` | Returns 1-based index of a tuner or 0 when not found. |
| `hdhr_api` | `caller`, `hdhr_ready` | `record` or `{}` | Wraps JSON Helper calls, retrying internally on timeouts before returning `{}`. |
| `getHDHR_Guide` | `caller`, `hdhr_device` | `missing value` | Downloads guide data; discovery loop re-runs as scheduled. |
| `getHDHR_Lineup` | `caller`, `hdhr_device` | `missing value` | Fetches channel lineup; invoked periodically for freshness. |
| `channel_guide` | `caller`, `hdhr_device`, `hdhr_channel`, `hdhr_time` | `record` or `{}` or `false` | Returns guide entries, `{}` on lookup failure, or `false` for missing channels; caller loops to resolve. |
| `update_show` | `caller`, `the_show_id`, `force_update` | `missing value` | Syncs metadata from guide data; scheduler iterates over shows as needed. |
| `save_data` | `caller` | `boolean` or `missing value` | Persists JSON data, returning `false` when the user cancels retries; autosave logic can re-invoke later. |
| `showPathVerify` | `caller`, `show_id` | `boolean` | Ensures show folders exist and returns success. |
| `checkfileexists2` | `caller`, `filepath` | `boolean` | Bare alias existence check. |
| `checkfileexists` | `caller`, `filepath` | `boolean` | Existence check with logging. |
| `read_data` | `caller` | `boolean` or `missing value` | Loads saved configuration; startup loop may re-run setup when false. |
| `recordingnow_main` | `caller` | `text` | Builds string summary of recordings in progress. |
| `next_shows` | `caller` | `{date, list, list}` | Returns next show time and summary lists. |
| `curl2icon` | `caller`, `thelink` | `alias` | Downloads icon files and returns Finder alias. |
| `curl2icon2` | `caller`, `thelink` | `alias` | Alternate icon download path. |
| `showid2PID` | `caller`, `show_id`, `kill_pid`, `logging` | `{text, list}` | Identifies curl processes and optionally terminates them. |
| `add_record_url` | `caller`, `the_channel`, `the_device` | `text` | Provides streaming URL for a channel/device. |
| `tuner_dump` | `caller` | `list` | Delegates to library diagnostic listing. |
| `epoch2show_time` | `caller`, `epoch` | `text` | Formats epoch seconds as readable time. |
| `datetime2epoch` | `caller`, `the_date_object` | `number` | Converts date to Unix epoch seconds. |
| `epoch2datetime` | `caller`, `epochseconds` | `date` | Delegates to library conversion. |
| `emptylist` | `caller`, `klist` | `list` | Proxies to library helper. |
| `stringlistflip` | `caller`, `thearg`, `delim`, `returned` | `list` or `text` | Proxies to library helper for string/list conversion. |
| `epoch` | `cd` | `date` | Returns Unix epoch reference via library helper. |
| `replace_chars` | `thestring`, `target`, `replacement` | `text` or `{…}` | Delegates to library text replace utility. |
| `fixdate` | `caller`, `theDate` | `text` or `{…}` | Normalizes date strings using library logic. |
| `stringToUtf8` | `caller`, `thestring` | `text` or `{…}` | Cleans strings via library routine. |
| `isSystemShutdown` | `caller` | `boolean` or `{…}` | Queries OS shutdown status through library helper. |
| `repeatProgress` | `caller`, `loop_delay`, `loop_total` | `missing value` or `{…}` | Manages progress UI; loops are controlled by caller. |
| `ms2time` | `caller`, `totalMS`, `time_duration`, `level_precision` | `text` or `{…}` | Formats durations via library helper. |
| `list_position` | `caller`, `this_item`, `this_list`, `is_strict` | `integer` or `{…}` | Finds item position in a list. |
| `short_date` | `caller`, `the_date_object`, `twentyfourtime`, `show_seconds` | `text` or `{…}` | Formats date strings. |
| `padnum` | `caller`, `thenum`, `splitdot` | `text` or `{…}` | Zero-pads numbers. |
| `is_number` | `caller`, `number_string` | `boolean` or `{…}` | Tests numeric coercion. |
| `getTfromN` | `caller`, `this_number` | `number` or `{…}` | Converts between AppleScript date/seconds. |
| `HDHRShowSearch` | `caller`, `the_show_id` | `integer` | Finds show index by ID. |
| `isModifierKeyPressed` | `caller`, `checkKey`, `desc` | `record` or `{…}` | Reports modifier key state. |
| `date2touch` | `caller`, `datetime`, `filepath` | `missing value` or `{…}` | Touches files; used in loops updating metadata. |
| `time_set` | `caller`, `adate_object`, `time_shift` | `date` or `{…}` | Adjusts date/time values. |
| `update_folder` | `caller`, `update_path` | `boolean` or `{…}` | Ensures directories exist. |
| `show_name_fix` | `caller`, `show_id`, `show_object` | `record` or `{…}` | Normalizes show titles. |
| `logger` | `logtofile`, `the_handler`, `caller`, `loglevel`, `message` | `missing value` | Writes log entries; used everywhere without loop because logging is fire-and-forget. |
| `existing_shows` | `caller` | `missing value` | Audits running curl processes; scheduler loop calls this repeatedly. |
| `check_after_midnight2` | `caller` | `boolean` | Enforces once-per-day logic. |
| `cm` | `handlername`, `caller` | `text` | Formats handler/caller strings for logging. |
| `seriesScan` | `caller`, `seriesID`, `hdhr_device`, `thechan`, `show_id` | `missing value` | Seeds SeriesID processing queue; background loops pick up queued items. |
| `seriesScanNext` | `caller`, `seriesID`, `hdhr_device`, `thechan`, `show_id`, `theoffset` | `record` or `{}` | Finds next airing; returns `{}` when nothing found so callers can break loops. |
| `seriesScanUpdate` | `caller`, `show_id` | `missing value` | Refreshes SeriesID shows; invoked by periodic scans. |
| `idle_change` | `caller`, `loop_delay`, `loop_delay_sec` | `missing value` | Adjusts idle timer; idle loop immediately adopts new schedule. |

---

## `hdhr_VCR_lib.applescript`

| Handler | Inputs | Outputs | Notes & Missing Value Handling |
| --- | --- | --- | --- |
| `run` | none | `missing value` | Reopens parent script when library is double-clicked; control returns to parent run loop. |
| `cm` | `handlername`, `caller` | `text` | Provides consistent log tags. |
| `load_hdhrVCR_vars` | none | `text` | Reports library version string to the parent. |
| `checkDiskSpace` | `caller`, `the_path` | `{path, percent, available}` or `{path, 0, errmsg}` | Executes `df` and returns disk usage data. |
| `emptylist` | `caller`, `klist` | `list` or `{…}` | Removes blanks from lists. |
| `stringlistflip` | `caller`, `thearg`, `delim`, `returned` | `list` or `text` or `{…}` | Converts between list and string representations. |
| `epoch` | `cd` | `date` or `{…}` | Returns Unix epoch date (optionally offset). |
| `replace_chars` | `thestring`, `target`, `replacement` | `text` or `{…}` | Replaces characters via delimiter manipulation. |
| `fixDate` | `caller`, `theDate` | `text` or `{…}` | Normalizes localized dates. |
| `stringToUtf8` | `caller`, `thestring` | `text` or `{…}` | Sanitizes strings to UTF-8 equivalents. |
| `isSystemShutdown` | `caller` | `boolean` or `{…}` | Detects OS shutdown intent. |
| `repeatProgress` | `caller`, `loop_delay`, `loop_total` | `missing value` or `{…}` | Animates progress indicators; caller controls looping. |
| `ms2time` | `caller`, `totalMS`, `time_duration`, `level_precision` | `text` or `{…}` | Formats time durations. |
| `list_position` | `caller`, `this_item`, `this_list`, `is_strict` | `integer` or `{…}` | Finds items within a list. |
| `short_date` | `caller`, `the_date_object`, `twentyfourtime`, `show_seconds` | `text` or `{…}` | Formats dates for logs/UI. |
| `padnum` | `caller`, `thenum`, `splitdot` | `text` or `{…}` | Zero-pads numeric strings. |
| `is_number` | `caller`, `number_string` | `boolean` or `{…}` | Tests numeric coercion. |
| `getTfromN` | `this_number` | `number` or `{…}` | Converts between date and seconds. |
| `end_jsonhelper` | none | `missing value` | Quits the JSON Helper; parent run loop restarts helper later if needed. |
| `epoch2datetime` | `caller`, `epochseconds` | `date` or `{…}` | Converts epoch seconds to AppleScript date. |
| `epoch2show_time` | `caller`, `epoch` | `text` or `{…}` | Formats epoch seconds as display text. |
| `tuner_dump` | `caller` | `list` | Lists tuners, URLs, and refresh times. |
| `encode_strikethrough` | `caller`, `thedata`, `decimel_char` | `text` | Adds Unicode strike-through markers. |
| `HDHRShowSearch` | `caller`, `the_show_id` | `integer` or `0` | Looks up show index. |
| `itemsInString` | `caller`, `listofitems`, `thestring` | `boolean` or `{…}` | Tests if any list item appears in a string. |
| `check_after_midnight` | `caller` | `boolean` | Ensures once-per-day loops respect midnight boundaries. |
| `isModifierKeyPressed` | `caller`, `checkKey`, `desc` | `record` or `{…}` | Reports modifier key status. |
| `quoteme` | `thestring` | `text` | Wraps text in AppleScript-safe quotes. |
| `date2touch` | `caller`, `datetime`, `filepath` | `missing value` or `{…}` | Updates file modification times; invoked by parent loops. |
| `time_set` | `caller`, `adate_object`, `time_shift` | `date` or `{…}` | Adjusts date/time values. |
| `corrupt_showinfo` | `caller` | `missing value` | Logging hook for corruption detection; parent calls it when anomalies appear. |
| `iconEnumPopulate` | `caller`, `show_id` | `missing value` | Demonstrates enum-to-icon mapping; currently unused, so loops never call it. |
| `aroundDate` | `caller`, `thisdate`, `thatdate`, `secOffset` | `boolean` | Checks whether two dates are within tolerance. |
| `update_folder` | `caller`, `update_path` | `boolean` | Validates folder access. |
| `rotate_logs` | `caller`, `filepath` | `missing value` | Handles log rotation; scheduled maintenance loop triggers it. |
| `update_record_urls` | `caller`, `the_device` | `missing value` | Refreshes stream URLs across shows; invoked by periodic update loops. |
| `add_record_url` | `caller`, `the_channel`, `the_device` | `text` or `{…}` | Returns stream URL for a channel/device. |
| `seriesScanAdd` | `caller`, `show_id` | `missing value` | Queues SeriesID updates; background queue ensures repeated processing. |
| `seriesScanRun` | `caller`, `execute` | `missing value` | Processes SeriesID queue; loop runs until queue is clear. |
| `seriesStatusIcons` | `caller`, `show_id` | `record` | Returns icon enumerations describing show state. |
| `match2showid` | `caller`, `hdhr_tuner`, `channelcheck`, `start_time`, `end_time` | `integer` | Finds show index for a slot. |
| `recordSee` | `caller`, `the_record` | `text` | Coerces record to text for logging. |
| `recordSee2` | `caller`, `the_record` | `text` | Variant returning raw error text. |
| `show_name_fix` | `caller`, `show_id`, `show_object` | `record` | Normalizes show metadata. |
| `convertByteSize` | `caller`, `byteSize`, `KBSize`, `decPlaces` | `text` | Formats byte counts. |
| `showSeek` | `caller`, `start_time`, `end_time`, `chan`, `hdhr_device` | `list` or `false` | Filters Show_info for matches; returns `false` when no shows found so loops can stop. |
| `get_show_state2` | `caller`, `hdhr_tuner`, `channelcheck`, `start_time`, `end_time` | `record` | Legacy variant kept for reference. |
| `nextday2` | `caller`, `the_show_id` | `date` | Alternate next-airing calculator. |
| `enums2icons` | `caller`, `enumarray` | `list` or `{}` | Maps enumerations to icon glyphs; returns `{}` to signal invalid entries for caller loops. |
| `show_icons` | `caller`, `hdhr_device`, `thechan` | `missing value` | Unused icon loop stub. |
| `seriesScanList` | `caller`, `show_id`, `updateRecord` | `missing value` | Manages SeriesID refresh queue, ensuring duplicates are skipped via looping checks. |
| `seriesScanRefresh` | `caller`, `show_id` | `missing value` | Reuses queue logic to refresh SeriesID shows en masse. |

