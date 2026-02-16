# Testing hdhr_VCR

Use the automated on-demand tests below for date/time handlers, then run the
manual checklist to validate end-to-end behavior on macOS.

## Automated On-Demand Time Tests

These tests are handler-level checks for locale-sensitive time/date behavior.
They are deterministic and machine-readable, but they do not replace functional
smoke testing of the app UI and recording flows.

- Run all supported locales (`en_US`, `en_GB`):
  - `./scripts/run_time_tests.sh`
- Run only `en_US`:
  - `./scripts/run_time_tests.sh --locale en_US`
- Run only `en_GB`:
  - `./scripts/run_time_tests.sh --locale en_GB`
- Run with custom date fixtures (useful for checking date parsing formats):
  - `./scripts/run_time_tests.sh --fixture-date "Tuesday, January 2, 2024 at 1:05:09 PM" --fixture-date-half "Tuesday, January 2, 2024 at 1:30:09 PM"`
  - `./scripts/run_time_tests.sh --locale en_GB --fixture-date "2 January 2024 13:05:09" --fixture-date-half "2 January 2024 13:30:09"`

Output format is one line per assertion:
- `PASS|TEST_ID|details`
- `FAIL|TEST_ID|details`

## Preparing the App Bundle
1. Open `hdhr_VCR.applescript` in **Script Editor**.
2. Compile the script to confirm it builds cleanly.
3. Export it as an **Application** with **“Stay open after run handler”** enabled.
4. Place the exported app in `/Applications` (or a test folder) and launch it.

## Functional Smoke Tests
- **Device discovery**: Verify that the app lists all reachable HDHomeRun tuners and surfaces their channels.
- **Guide retrieval**: Ensure the channel guide populates with at least the next four hours of data and thumbnails where available.
- **Single recording**: Schedule a one-off recording, confirm pre-recording notifications, verify the `.ts` file is created, and inspect the log for errors.
- **Series recording**: Add a series recording across multiple days. Confirm subsequent entries appear in the “Shows” list with accurate next-run times.
- **Manual add**: Schedule a recording using decimal time. Confirm the time normalizes to the correct start boundary.
- **Disk checks**: Trigger a recording on a volume with limited space and watch for the warning/abort logic tied to `Max_disk_percentage`.
- **Quit flow**: While recording, attempt to quit the app. Validate the prompts to continue, cancel, or leave recordings running.

## Logging and Telemetry
- Review `~/Library/Logs/hdhr_VCR.log` for new warnings or errors.
- If debugging, switch the logger level to include `DEBUG`/`TRACE` and confirm that sensitive data (API keys, user paths) is not leaked.

Document the macOS version, HDHomeRun model, and steps executed when recording manual test results for a PR.
