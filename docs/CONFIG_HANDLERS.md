# Show Serialization Helpers

## Overview

Two new simplified handlers reduce repetitive serialization code:
- `serializeShows()` - Convert list of shows for JSON export
- `deserializeShows()` - Convert list of shows from JSON import

These eliminate the need for scattered `serialize_show`/`deserialize_show` repeat loops throughout `read_data` and `save_data`.

## Usage

### Loading Shows (after reading JSON)

**Old way (scattered loop):**
```applescript
set json_data to (read JSON from config_path)
set Show_info to "the_shows" of json_data
repeat with i from 1 to length of Show_info
  set item i of Show_info to deserialize_show(caller, item i of Show_info)
end repeat
```

**New way (single call):**
```applescript
set json_data to (read JSON from config_path)
set Show_info to my deserializeShows(cm, "the_shows" of json_data) of LibScript
-- Show_info now has proper date objects, no conversion needed
```

### Saving Shows (before writing JSON)

**Old way (scattered loop):**
```applescript
repeat with i from 1 to length of temp_show_info
  set item i of temp_show_info to serialize_show(caller, item i of temp_show_info)
end repeat
set json_temp to {the_shows:temp_show_info, config:Hdhr_config}
set temp_show_info_json to (make JSON from json_temp)
```

**New way (single call):**
```applescript
set shows_serialized to my serializeShows(cm, temp_show_info) of LibScript
set json_temp to {the_shows:shows_serialized, config:Hdhr_config}
set temp_show_info_json to (make JSON from json_temp)
```

## Handler Signatures

### deserializeShows

```applescript
on deserializeShows(caller, shows_list)
  -- Input: list of show records from JSON (with epoch integers/text)
  -- Output: list of show records with date objects
  -- Returns missing value on error
```

**What it does:**
- Calls `deserialize_show()` on each show record
- Converts epoch integers/text to date objects
- Logs progress and errors

### serializeShows

```applescript
on serializeShows(caller, shows_list)
  -- Input: list of show records with date objects
  -- Output: list of show records with epochs (ready for JSON)
  -- Returns missing value on error
```

**What it does:**
- Calls `serialize_show()` on each show record
- Converts date objects to epoch integers/text
- Logs progress and errors

## Field Conversions

These handlers manage conversion of:

| Field | From JSON | To Memory | To JSON |
|-------|-----------|-----------|---------|
| `show_next` | text "1777730400" | date object | text "1777730400" |
| `show_end` | text "1777732200" | date object | text "1777732200" |
| `show_last` | 0 or text | date object or 0 | 0 or text |
| `notify_recording_time` | "missing value" or text | "missing value" or date | "missing value" or text |
| `notify_upnext_time` | "missing value" or text | "missing value" or date | "missing value" or text |

All other fields pass through unchanged.

## Error Handling

**On error:**
- Logs ERROR with details
- Returns missing value
- Calling code must check return value before proceeding

Example:
```applescript
set shows to my deserializeShows(cm, show_list) of LibScript
if shows is missing value then
  my logger(true, handlername, caller, "ERROR", "Deserialization failed")
  return false
end if
```

## Fallback Strategy

If issues arise:

1. **Old handlers remain intact** - `serialize_show` and `deserialize_show` available
2. **Remove helper calls** - Revert to explicit repeat loops in `read_data`/`save_data`
3. **No code deletion** - Both approaches coexist during transition

Example fallback:
```applescript
set shows to my deserializeShows(cm, show_list) of LibScript
if shows is missing value then
  -- Fall back to old approach
  repeat with i from 1 to length of show_list
    set item i of show_list to deserialize_show(caller, item i of show_list)
  end repeat
  set shows to show_list
end if
```
