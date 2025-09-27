Handler Reference
=================

Overview
--------
The hdhr_VCR project packages two collaborating AppleScript files that turn an HDHomeRun tuner into a lightweight DVR. The
`hdhr_VCR.applescript` file hosts the main application logic and user interface flow, while `hdhr_VCR_lib.applescript`
provides reusable helpers for date math, logging, SeriesID handling, and other utilities that keep the core script tidy. This
reference reflects the handlers that exist in the current sources and the values they exchange.

> **Missing value semantics** – AppleScript commonly uses `missing value` to indicate "no response." Whenever a handler returns
> it, the notes column below explains how the run loop reacts.

---

## `hdhr_VCR.applescript`

### Setup and app lifecycle

| Handler | Inputs | Returns | Notes |
| --- | --- | --- | --- |
| `setup_lib` | `caller` | `boolean` | Loads the compiled library script, binds globals, and reports whether the load succeeded. |
| `setup_icons` | `caller` | `boolean` | Populates emoji icons for UI prompts; later setup steps only run when this succeeds. |
| `setup_script` | `caller` | `boolean` | Initializes environment data (paths, locale, caches); startup halts if `false`. |
| `setup_globals` | `caller` | `boolean` | Resets global state for a fresh run; failures stop progression to runtime. |
| `setup_logging` | `caller` | `boolean` | Establishes logging defaults and opens the log folder. |
| `idle_change` | `caller`, `loop_delay`, `loop_delay_sec` | `missing value` | Overrides the idle delay and schedules when the override expires. |

### Native AppleScript event handlers

AppleScript invokes these handlers automatically in response to system events. The script performs setup work inside the
event entry points before returning control to the scheduler.

| Handler | Inputs | Returns | Notes |
| --- | --- | --- | --- |
| `run` | none | `missing value` | Entry point that chains the setup sequence and then defers to `idle`. |
| `idle` | none | `integer` | Core loop that manages recordings and returns the delay before the next idle call. |
| `reopen` | none | `missing value` | Handles Dock icon reopen events by invoking `main`. |
| `quit` | none | `missing value` | Handles shutdown, optionally kills active recordings, saves state, then continues quit. |

### Channel navigation and scheduling

| Handler | Inputs | Returns | Notes |
| --- | --- | --- | --- |
| `hdhrGRID` | `caller`, `hdhr_device`, `hdhr_channel` | list of guide records, `true`, `false`, or `{""}` | Builds a channel guide list UI. Returns guide records for scheduling, `true` to jump back, `false` on cancel, or `{""}` for manual add. |
| `main` | `caller`, `emulated_button_press` | `boolean` or `missing value` | Primary UI loop; returns `false` to exit or hands control back to `idle`. |
| `add_show_info` | `caller`, `hdhr_device`, `hdhr_channel` | `boolean` or `missing value` | Scheduler workflow for adding shows; returns `false` on cancel. |
| `setup` | `caller` | `missing value` | Guides the user through first-run configuration until complete. |
| `validate_show_info` | `caller`, `show_to_check`, `should_edit` | `missing value` | Normalises existing show entries; interactive loops continue until validation passes. |
| `record_start` | `caller`, `the_show_id`, `opt_show_length`, `force_update` | `missing value` | Validates prerequisites and launches recordings; callers loop through pending shows. |
| `show_info_dump` | `caller`, `show_id_lookup`, `userdisplay` | `missing value` | Logging helper that dumps show metadata for debugging. |
| `recordingnow_main` | `caller` | `text` | Summarises recordings in progress for UI display. |
| `next_shows` | `caller` | record `{date, list, list}` | Returns the next show start plus summary lists for the main menu. |
| `seriesScan` | `caller`, `seriesID`, `hdhr_device`, `thechan`, `show_id` | `missing value` | Seeds the SeriesID processing queue housed in the library. |
| `seriesScanNext` | `caller`, `seriesID`, `hdhr_device`, `thechan`, `show_id`, `theoffset` | `record` or `{}` | Requests the next airing for a series; `{}` signals no match so callers can stop looping. |
| `seriesScanUpdate` | `caller`, `show_id` | `missing value` | Refreshes SeriesID-managed shows after recordings complete. |
| `existing_shows` | `caller` | `missing value` | Audits running helper processes tied to recordings and logs the findings. |
| `check_after_midnight2` | `caller` | `boolean` | Legacy midnight-reset guard with no active callers in the script. |

### Device discovery and tuner control

| Handler | Inputs | Returns | Notes |
| --- | --- | --- | --- |
| `tuner_overview` | `caller` | `list` | Produces human-readable tuner usage summaries. |
| `tuner_ready_time` | `caller`, `hdhr_model` | `number` | Returns seconds until the specified tuner becomes free. |
| `tuner_inuse` | `caller`, `device_id` | `list` or `text` | Lists remote client IPs for an in-use tuner or returns `""` when the status query times out. |
| `tuner_status` | `caller`, `device_id` | `record` or `false` | Retrieves `{tunermax, tuneractive}`; callers retry on `false`. |
| `tuner_mismatch` | `caller`, `device_id` | `missing value` | Audits tuner usage and corrects stale state. |
| `AreWeOnline` | `caller` | `boolean` | Checks reachability of the configured tuner fleet. |
| `HDHRDeviceDiscovery` | `caller`, `hdhr_device` | `missing value` | Scans for tuners, updates caches, and triggers refresh workflows. |
| `HDHRDeviceSearch` | `caller`, `hdhr_device` | `integer` | Returns the index of a tuner or 0 if the device is unknown. |
| `hdhr_api` | `caller`, `hdhr_ready` | `record` or `{}` | Wraps JSON Helper calls; returns `{}` when the helper cannot provide data. |
| `getHDHR_Guide` | `caller`, `hdhr_device` | `missing value` | Downloads guide data for the specified tuner. |
| `getHDHR_Lineup` | `caller`, `hdhr_device` | `missing value` | Refreshes the channel lineup from the HDHomeRun device. |
| `channel_guide` | `caller`, `hdhr_device`, `hdhr_channel`, `hdhr_time` | `record`, `{}` or `false` | Looks up guide entries; `{}` represents lookup failures, `false` indicates missing channels. |
| `tuner_dump` | `caller` | `list` | Delegates to the library to render a tuner diagnostics list. |

### Data persistence and metadata helpers

| Handler | Inputs | Returns | Notes |
| --- | --- | --- | --- |
| `build_channel_list` | `caller`, `hdhr_device`, `cd` | `missing value` | Rebuilds the cached channel list for the active device. |
| `channel2name` | `caller`, `the_channel`, `hdhr_device` | `text` or `false` | Resolves channel names; `false` signals the need for manual entry. |
| `nextday` | `caller`, `the_show_id` | `date` | Computes the next airing for the provided show ID. |
| `update_show` | `caller`, `the_show_id`, `force_update` | `missing value` | Syncs show metadata using guide data. |
| `save_data` | `caller` | `boolean` or `missing value` | Persists configuration JSON; user cancellations return `false`. |
| `showPathVerify` | `caller`, `show_id` | `boolean` | Ensures the recording folder exists for a given show. |
| `checkfileexists` | `caller`, `filepath` | `boolean` | Path existence check with logging. |
| `checkfileexists2` | `caller`, `filepath` | `boolean` | Currently unused; retained as a silent existence check for legacy integrations. |
| `read_data` | `caller` | `boolean` or `missing value` | Loads saved configuration and triggers guided setup when missing. |
| `add_record_url` | `caller`, `the_channel`, `the_device` | `text` | Retrieves the streaming URL for a channel/device pair. |
| `showid2PID` | `caller`, `show_id`, `kill_pid`, `logging` | `{text, list}` | Finds associated curl processes and optionally terminates them. |
| `curl2icon` | `caller`, `thelink` | `alias` | Downloads and returns a Finder alias for channel icons. |
| `curl2icon2` | `caller`, `thelink` | `alias` | Currently unused fallback icon fetcher kept for manual testing compatibility. |

### Status and formatting helpers

| Handler | Inputs | Returns | Notes |
| --- | --- | --- | --- |
| `is_channel_record` | `caller`, `hdhr_tuner`, `channelcheck`, `cd` | `text` | Builds recording-state glyphs for a channel row. |
| `get_show_state` | `caller`, `hdhr_tuner`, `channelcheck`, `start_time`, `end_time` | `record` | Returns `{show_stat, the_show_id, status_icon}` describing schedule state. |
| `check_version` | `caller` | `missing value` | Contacts remote version metadata and retries locally on failure. |
| `check_version_dialog` | `caller` | `text` | Formats version information for UI presentation. |
| `recordingnow_main` | `caller` | `text` | See table above; kept here for quick reference when formatting menus. |

### Library passthroughs
These handlers exist for compatibility with older scripts. Each simply calls the identically named library handler (passing the
same arguments) and returns whatever the library returns:

`epoch2show_time`, `datetime2epoch`, `epoch2datetime`, `emptylist`, `stringlistflip`, `epoch`, `replace_chars`, `fixdate`,
`stringToUtf8`, `isSystemShutdown`, `repeatProgress`, `ms2time`, `list_position`, `short_date`, `padnum`, `is_number`,
`getTfromN`, `HDHRShowSearch`, `isModifierKeyPressed`, `date2touch`, `time_set`, `update_folder`, `show_name_fix`.

The `logger` handler is implemented locally to keep log writes within the application bundle.

---

## `hdhr_VCR_lib.applescript`

### Script metadata and lifecycle

| Handler | Inputs | Returns | Notes |
| --- | --- | --- | --- |
| `cm` | `handlername`, `caller` | `text` | Produces a `handler(caller)` tag for logging. |
| `load_hdhrVCR_vars` | none | `text` | Reports the library version string back to the parent script. |

### Native AppleScript event handlers

| Handler | Inputs | Returns | Notes |
| --- | --- | --- | --- |
| `run` | none | `missing value` | Reopens the parent script if the library is launched standalone. |

### Disk, filesystem, and environment helpers

| Handler | Inputs | Returns | Notes |
| --- | --- | --- | --- |
| `checkDiskSpace` | `caller`, `the_path` | `{path, percent, available}` or `{path, 0, errmsg}` | Wraps the `df` command to report free space. |
| `update_folder` | `caller`, `update_path` | `boolean` | Ensures directories exist before writing recordings. |
| `rotate_logs` | `caller`, `filepath` | `missing value` | Renames oversized logs and starts a new file. |
| `update_record_urls` | `caller`, `the_device` | `missing value` | Refreshes saved stream URLs for all shows on a device. |
| `add_record_url` | `caller`, `the_channel`, `the_device` | `text` or `{…}` | Returns the streaming URL and error info on failure. |
| `date2touch` | `caller`, `datetime`, `filepath` | `missing value` or `{…}` | Updates file modification times. |
| `end_jsonhelper` | `caller` | `missing value` | Quits the JSON Helper app and allows the parent to restart it later. |

### Text, list, and conversion utilities

| Handler | Inputs | Returns | Notes |
| --- | --- | --- | --- |
| `emptylist` | `caller`, `klist` | `list` or `{…}` | Removes blanks from list values. |
| `stringlistflip` | `caller`, `thearg`, `delim`, `returned` | `list`, `text`, or `{…}` | Converts between delimited strings and lists. |
| `replace_chars` | `thestring`, `target`, `replacement` | `text` or `{…}` | Performs character substitution without regex. |
| `stringToUtf8` | `caller`, `thestring` | `text` or `{…}` | Normalises strings to UTF-8 safe values. |
| `list_position` | `caller`, `this_item`, `this_list`, `is_strict` | `integer` or `{…}` | Returns the position of an item in a list. |
| `padnum` | `caller`, `thenum`, `splitdot` | `text` or `{…}` | Zero pads numeric strings. |
| `is_number` | `caller`, `number_string` | `boolean` or `{…}` | Tests numeric coercion. |
| `itemsInString` | `caller`, `listofitems`, `thestring` | `boolean` or `{…}` | Checks if any list entry appears in a string. |
| `quoteme` | `thestring` | `text` | Wraps text in AppleScript-safe quotes. |
| `encode_strikethrough` | `caller`, `thedata`, `decimel_char` | `text` | Adds Unicode strikethrough markers to text. |
| `convertByteSize` | `caller`, `byteSize`, `KBSize`, `decPlaces` | `text` | Formats byte counts with human-readable suffixes. |
| `recordSee` | `caller`, `the_record` | `text` | Produces a text representation of a record for logs. |
| `recordSee2` | `caller`, `the_record` | `text` | Variant that preserves raw error strings. |
| `show_name_fix` | `caller`, `show_id`, `show_object` | `record` | Normalises show metadata imported from the guide. |
| `enums2icons` | `caller`, `enumarray` | `list` or `{}` | Maps status enumeration values to emoji glyphs. |

### Date, time, and scheduling helpers

| Handler | Inputs | Returns | Notes |
| --- | --- | --- | --- |
| `epoch` | `cd` | `date` or `{…}` | Returns the Unix epoch reference as an AppleScript date. |
| `epoch2datetime` | `caller`, `epochseconds` | `date` or `{…}` | Converts epoch seconds to AppleScript date objects. |
| `epoch2show_time` | `caller`, `epoch` | `text` or `{…}` | Formats epoch seconds for UI display. |
| `getTfromN` | `this_number` | `number` or `{…}` | Converts AppleScript date values to seconds and back. |
| `time_set` | `caller`, `adate_object`, `time_shift` | `date` or `{…}` | Adjusts dates by a given offset. |
| `repeatProgress` | `caller`, `loop_delay`, `loop_total` | `missing value` or `{…}` | Animates Script Editor progress bars. |
| `ms2time` | `caller`, `totalMS`, `time_duration`, `level_precision` | `text` or `{…}` | Formats durations into readable strings. |
| `short_date` | `caller`, `the_date_object`, `twentyfourtime`, `show_seconds` | `text` or `{…}` | Formats timestamps for logs and dialogs. |
| `check_after_midnight` | `caller` | `boolean` | Detects when a new day has started to reset daily counters. |
| `nextday2` | `caller`, `the_show_id` | `date` | Calculates the next airing for a show using schedule metadata. |
| `aroundDate` | `caller`, `thisdate`, `thatdate`, `secOffset` | `boolean` | Tests whether two dates are within a tolerance. |

### Device, guide, and series helpers

| Handler | Inputs | Returns | Notes |
| --- | --- | --- | --- |
| `tuner_dump` | `caller` | `list` | Enumerates tuners, streaming URLs, and refresh timing. |
| `HDHRShowSearch` | `caller`, `the_show_id` | `integer` or `0` | Finds a show index by ID. |
| `match2showid` | `caller`, `hdhr_tuner`, `channelcheck`, `start_time`, `end_time` | `integer` | Resolves guide slots to show IDs. |
| `showSeek` | `caller`, `start_time`, `end_time`, `chan`, `hdhr_device` | `list` or `false` | Filters `Show_info` for matching entries. |
| `get_show_state2` | `caller`, `hdhr_tuner`, `channelcheck`, `start_time`, `end_time` | `record` | Legacy variant retained for reference. |
| `seriesScanAdd` | `caller`, `show_id` | `missing value` | Queues show IDs for SeriesID updates. |
| `seriesScanRun` | `caller`, `execute` | `missing value` | Processes the SeriesID refresh queue. |
| `seriesScanList` | `caller`, `show_id`, `updateRecord` | `missing value` | Ensures SeriesID queue entries remain unique. |
| `seriesScanRefresh` | `caller`, `show_id` | `missing value` | Bulk refresh of SeriesID-managed shows. |
| `seriesStatusIcons` | `caller`, `show_id` | `record` | Maps show status values to icon enumerations for display. |
| `show_icons` | `caller`, `hdhr_device`, `thechan` | `missing value` | Placeholder that demonstrates icon lookups; not used. |

### System integration

| Handler | Inputs | Returns | Notes |
| --- | --- | --- | --- |
| `isSystemShutdown` | `caller` | `boolean` or `{…}` | Detects whether macOS is in the middle of shutting down. |
| `corrupt_showinfo` | `caller` | `missing value` | Logging hook that fires when saved show data looks corrupted. |
| `isModifierKeyPressed` | `caller`, `checkKey`, `desc` | `record` or `{…}` | Reports modifier key state for UI shortcuts. |

