# Master Version History

This document captures significant, user-visible capabilities that landed in the `master` branch of the hdhr_VCR AppleScript project. Each section summarizes the effective experience delivered by a merge (or direct release commit) and focuses on features an end user can interact with.

## 2025-06-17

### Added
- Background queueing for SeriesID refreshes so that every completed or newly added series automatically schedules its next airing without locking up the UI.
- Existing SeriesID shows are queued for refresh at launch so their next airings are recalculated as soon as the idle loop runs.

### Updated
- Idle processing now drains the SeriesID refresh queue at the end of every loop, ensuring multi-show additions get their next airings without manual intervention.
- Firmware update notifications now include the firmware version string so users know which build is waiting to install.
- The setup workflow always prompts to save configuration changes after maintenance tasks, reducing the chance of accidentally discarding new schedules.

### Changed
- When a recording fails repeatedly, the script now records a human-readable failure reason alongside the counter to make troubleshooting easier.

### Removed
- No user-facing functionality was removed in this merge.

## 2025-05-16

### Added
- Guided startup flow that reports progress (loading the external library, configuring globals, setting up icons) so users know why the UI is still launching.
- Automatic detection of Script Editor/Debugger launches enables verbose logging levels while keeping production builds quieter for end users.
- Expanded icon set (recording states, running indicator, eject, etc.) that is reused throughout dialogs and notifications for clearer status cues.

### Updated
- Logging now writes to the user’s `~/Library/Logs` folder, enforces dynamic log caps, and exposes additional log levels, improving supportability while keeping log sizes under control.
- The script automatically creates its cache directory during setup, preventing the missing-cache failures seen in earlier builds.
- Idle timers and global defaults were retuned (longer notification lead time, higher disk usage guard) to better match modern recording workloads.

### Changed
- Core setup responsibilities were split into focused handlers (`setup_lib`, `setup_script`, `setup_globals`, `setup_logging`, `setup_icons`), making reloads and future maintenance less error-prone for end users who reinstall the script.

### Removed
- No user-facing functionality was removed in this merge.

## 2025-04-07

### Added
- Multi-select show additions now respect existing schedules by skipping duplicates and immediately editing any conflicting entries, reducing accidental overwrites when bulk-adding shows.

### Updated
- Config saves are protected against writing empty files, avoiding data loss when a save happens before any shows are defined.
- Channel editing prompts only appear when they can apply, minimizing unnecessary dialogs while configuring multiple recordings.

### Changed
- Sports-specific logic (which never behaved correctly) was removed so single-event recordings fall back to the standard workflow and can no longer get stuck marked as “bonus time.”

### Removed
- Legacy sports-handling branches that conflicted with the new series workflow.

## 2024-09-27

### Added
- Standalone `hdhr_VCR_lib.applescript` that lives in the user’s Documents folder, housing shared helpers so the main app stays under AppleScript’s size ceiling while continuing to grow.
- Runtime loading of the external library during setup, enabling the app to call into the shared handlers without additional user scripting steps.

### Updated
- Core utilities (disk checks, string helpers, SeriesID tooling) now execute from the shared library, reducing duplicate code inside the primary script and making maintenance simpler for end users who drop in updated library builds.

### Changed
- The launcher now requires the companion library to be present; missing files trigger a guided notification so users can place the script correctly.

### Removed
- None.

## 2023-09-07

### Added
- Each scheduled show now stores the authoritative recording URL provided by the HDHomeRun device, improving compatibility with tuners that serve content on non-default ports.
- A “skip idle delay” pathway accelerates returning to the main UI after adding or editing shows, shortening the wait before new schedules become visible.

### Updated
- Recording launch commands now reuse the stored device URL and enrich the logger output so users can trace in-progress recordings without spelunking the filesystem.
- Channel list and show-add workflows were refreshed to better surface logos and metadata from the guide feed.

### Changed
- Legacy URL-construction logic (which assumed a fixed port) was replaced with the tuner-provided endpoint, avoiding failures on devices with custom stream ports.

### Removed
- Stale helper code that previously rebuilt stream URLs by hand, reducing script size so new functionality could fit within AppleScript limits.

## 2023-03-18

### Added
- Refined recording icons and notifications that distinguish between pending, running, and completed recordings, giving clearer visual feedback while browsing the UI.

### Updated
- Recording start/stop logs now capture more device context, making it easier to diagnose network or storage issues when a recording misbehaves.

### Changed
- Notification timing was tweaked so “recording started” alerts arrive closer to the actual start time, reflecting the refined icons and reducing duplicate pings.

### Removed
- No user-facing functionality was removed in this merge.

## 2023-02-23

### Added
- Automatic cache-directory creation so poster art downloads work on first launch without manual folder setup.

### Updated
- Recording downloads now rely on the native `curl`/`caffeinate` pipeline, removing the Python 2 helper that blocked recordings on newer macOS installs.
- Startup setup validates log and cache paths before continuing, surfacing permission problems earlier in the launch sequence.

### Changed
- Startup validation now warns about missing cache or log folders up front, so users can fix permissions before attempting to add shows.

### Removed
- Reliance on the deprecated Python 2 runtime for recording management, aligning the script with default macOS 12+ environments.

## 2021-12-22

### Added
- Automatic detection of stalled recordings: if a curl session drops mid-recording, the script now restarts it and flags the issue in the UI, improving reliability for long events.

### Updated
- Recording health checks run more often during active recordings, reducing the window where a stalled download could go unnoticed.

### Changed
- None.

### Removed
- None.

## 2021-09-05

### Added
- JSON-backed configuration with automatic migration from the legacy plist format, enabling multi-show setups without manual file edits.
- Ability to edit and add multiple shows at once from the main UI, including thumbnail previews during selection.
- Rolling log support so long-running installs keep a bounded history instead of growing log files indefinitely.

### Updated
- The home screen now highlights the next upcoming recordings and shows currently in progress, reducing the clicks needed to check status.
- Show-add workflow now fetches and displays poster art from the guide feed for easier identification.

### Changed
- Scheduler now aligns guide data to JSON-driven structures, paving the way for future automation like SeriesID tracking.

### Removed
- Legacy text-based config handling that could corrupt schedules when multiple shows were added back-to-back.

## 2021-08-05

### Added
- Multi-show selection for the same channel with an option to apply one set of recording settings to every show, drastically speeding up bulk subscriptions.
- Notifications for shows currently recording, providing real-time confirmation when a capture begins.
- Show artwork preview when picking new recordings, so users can confirm they selected the correct series/movie.

### Updated
- Main screen now includes the upcoming queue directly beneath live status, surfacing schedule context without drilling into submenus.

### Changed
- Bulk-add workflow now pre-validates duplicates and quietly skips ones already scheduled instead of erroring out.

### Removed
- None.

## 2021-07-21

### Added
- The dashboard now displays the next scheduled recordings inline, saving a trip into the Shows view for status checks.

### Updated
- None.

### Changed
- None.

### Removed
- None.

## 2021-07-16

### Added
- Refreshed UI copy and iconography throughout the script for clearer prompts and actions, aligning with the expanded icon set introduced earlier.
- Stability improvements around tuner discovery and recording retries, reducing the number of modal errors users encounter when devices temporarily vanish.

### Updated
- Dialog wording around adding shows and managing tuners now matches the new iconography, making workflows easier to follow.

### Changed
- None.

### Removed
- None.

## 2021-03-01

### Added
- Persistent logging infrastructure that writes structured entries to disk, giving users an audit trail for each recording attempt.
- Automated log trimming so the script self-manages log growth based on the number of configured shows.

### Updated
- Numerous stability fixes across show validation and schedule updates, preventing off-day recordings from firing when a show isn’t supposed to run.

### Changed
- None.

### Removed
- None.

## 2021-02-09

### Added
- Log entries now include the running version number, simplifying support requests by tying reports to a concrete build.

### Updated
- Handler cleanup reduced redundant device discovery calls, making idle refreshes faster for end users with multiple tuners.

### Changed
- None.

### Removed
- None.

## 2021-02-08

### Added
- Dedicated log file (`hdhr_VCR.log`) stored alongside user documents so day-to-day recording activity is captured for later review.
- Automatic version-check notifications that alert users from the UI when a newer release is available.

### Updated
- Startup routine now immediately discovers HDHomeRun tuners and restores prior show schedules before opening the main UI, making restarts seamless.

### Changed
- None.

### Removed
- None.

## 2021-02-01

### Added
- Integrated “Facelift” UI with refreshed imagery and channel tiles, modernizing the experience compared to the 2021-01 builds.
- Automatic tuner discovery runs on a timer to keep device lists current even when the app stays open for days.

### Updated
- Notifications and dialogs include richer context (channel names, durations) so users can quickly confirm the right show is being configured.

### Changed
- None.

### Removed
- None.

## 2021-01-24

### Added
- Bulk of the DVR workflow: show discovery, scheduling UI, and background idle loop that keeps recordings on track without manual intervention.
- Initial support for per-show notification lead times so users can receive “up next” alerts before a recording starts.

### Updated
- None.

### Changed
- None.

### Removed
- None.

## 2021-01-19

### Added
- Ability to recover from tuner conflicts by retrying shows that were previously blocked, reducing manual babysitting of the queue.

### Updated
- None.

### Changed
- None.

### Removed
- None.

## 2021-01-11

### Added
- Initial public release of hdhr_VCR with a clickable UI for browsing HDHomeRun guide data and scheduling recordings from macOS.

### Updated
- Version metadata surfaced in the UI to match the downloadable package name.

### Changed
- None.

### Removed
- None.

