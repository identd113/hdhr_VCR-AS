# AppleScript Style Guide

These conventions capture how the existing scripts are structured. Follow them for any changes to `hdhr_VCR.applescript` or `hdhr_VCR_lib.applescript`.

## Indentation and Formatting
- Use **hard tabs** for indentation inside handlers. The top-level scope stays unindented.
- Keep handler declarations flush left: `on handlerName(...)` on one line followed by the body on the next line.
- Leave a blank line between handlers and between logical sections inside a long handler.

## Handler Structure
- Define `handlername` at the beginning of every handler. The literal string should match the handler’s purpose (e.g., `set handlername to "setup_logging"`).
- When a handler accepts a `caller`, compute a context string with `my cm(handlername, caller)` and reuse it for nested calls.
- Wrap risky logic in `try/on error` blocks. On failure, return either `false` or a `{handlername, errmsg}` tuple, matching the surrounding pattern.
- When returning lists or records, stick to the existing AppleScript record syntax (`{key:value, ...}`) and maintain consistent key names.

## Logging and Diagnostics
- Use the logger in the parent script (`logger(...) of ParentScript`) instead of ad-hoc `display dialog` calls for background operations.
- Populate the logger with the `handlername` and `caller` context so log lines stay searchable.
- Prefer returning explicit error details and let the caller decide how to handle UI notifications.

## Error Handling Patterns
- Normalize strings through helpers like `stringToUtf8` before logging them.
- Use helper utilities in `hdhr_VCR_lib.applescript` (e.g., `stringlistflip`, `emptylist`) rather than duplicating parsing logic.
- When touching file paths or shell commands, sanitize inputs with the existing helper routines (e.g., `replace_chars`).

## Versioning and Globals
- Keep global declarations grouped at the top of `hdhr_VCR.applescript`. Add new globals near related entries to preserve readability.
- If you introduce new configuration constants, ensure they are initialized both in `setup_globals` and persisted through the JSON config.

## User Interaction
- Maintain the non-blocking pattern: dialogs should have timeouts and avoid leaving the app idle loop paused indefinitely.
- Leverage the existing emoji icon map (`Icon_record`) for any new UI icons instead of embedding raw characters throughout the code.

Following these conventions keeps the app consistent and makes it easier to diff updates across releases.
