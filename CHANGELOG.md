# Changelog

## 250919

### Added
- Introduced a changelog to track user-facing and behind-the-scenes updates for hdhr_VCR.

### Removed
- No user-visible features or workflows were removed in this merge.

### Updated
- Documented the structure to follow for future entries so upcoming merges stay consistent.

## 2025-06-17

### Added
- Background queueing for SeriesID refreshes so that every completed or newly added series automatically schedules its next airing without locking up the UI.【F:hdhr_VCR.applescript†L221-L236】【F:hdhr_VCR_lib.applescript†L865-L925】
- Existing SeriesID shows are queued for refresh at launch so their next airings are recalculated as soon as the idle loop runs.【F:hdhr_VCR.applescript†L221-L236】【F:hdhr_VCR_lib.applescript†L865-L925】

### Updated
- Idle processing now drains the SeriesID refresh queue at the end of every loop, ensuring multi-show additions get their next airings without manual intervention.【F:hdhr_VCR.applescript†L440-L482】【F:hdhr_VCR_lib.applescript†L899-L925】
- Firmware update notifications now include the firmware version string so users know which build is waiting to install.【F:hdhr_VCR.applescript†L2229-L2231】
- The setup workflow always prompts to save configuration changes after maintenance tasks, reducing the chance of accidentally discarding new schedules.【F:hdhr_VCR.applescript†L1325-L1370】

### Changed
- When a recording fails repeatedly, the script now records a human-readable failure reason alongside the counter to make troubleshooting easier.【F:hdhr_VCR.applescript†L2065-L2073】

### Removed
- No user-facing functionality was removed in this merge.

## 2025-05-16

### Added
- Guided startup flow that reports progress (loading the external library, configuring globals, setting up icons) so users know why the UI is still launching.【F:hdhr_VCR.applescript†L48-L131】
- Automatic detection of Script Editor/Debugger launches enables verbose logging levels while keeping production builds quieter for end users.【F:hdhr_VCR.applescript†L113-L139】
- Expanded icon set (recording states, running indicator, eject, etc.) that is reused throughout dialogs and notifications for clearer status cues.【F:hdhr_VCR.applescript†L60-L96】

### Updated
- Logging now writes to the user’s `~/Library/Logs` folder, enforces dynamic log caps, and exposes additional log levels, improving supportability while keeping log sizes under control.【F:hdhr_VCR.applescript†L97-L139】
- The script automatically creates its cache directory during setup, preventing the missing-cache failures seen in earlier builds.【F:hdhr_VCR.applescript†L78-L92】
- Idle timers and global defaults were retuned (longer notification lead time, higher disk usage guard) to better match modern recording workloads.【F:hdhr_VCR.applescript†L113-L139】

### Changed
- Core setup responsibilities were split into focused handlers (`setup_lib`, `setup_script`, `setup_globals`, `setup_logging`, `setup_icons`), making reloads and future maintenance less error-prone for end users who reinstall the script.【F:hdhr_VCR.applescript†L48-L131】

### Removed
- No user-facing functionality was removed in this merge.

## 2025-04-07

### Added
- Multi-select show additions now respect existing schedules by skipping duplicates and immediately editing any conflicting entries, reducing accidental overwrites when bulk-adding shows.【F:hdhr_VCR.applescript†L1668-L1735】

### Updated
- Config saves are protected against writing empty files, avoiding data loss when a save happens before any shows are defined.【F:hdhr_VCR.applescript†L2034-L2071】
- Channel editing prompts only appear when they can apply, minimizing unnecessary dialogs while configuring multiple recordings.【F:hdhr_VCR.applescript†L1706-L1771】

### Changed
- Sports-specific logic (which never behaved correctly) was removed so single-event recordings fall back to the standard workflow and can no longer get stuck marked as “bonus time.”【F:hdhr_VCR.applescript†L420-L474】

### Removed
- Legacy sports-handling branches that conflicted with the new series workflow.【F:hdhr_VCR.applescript†L420-L474】

## 2024-09-27

### Added
- Standalone `hdhr_VCR_lib.applescript` that lives in the user’s Documents folder, housing shared helpers so the main app stays under AppleScript’s size ceiling while continuing to grow.【F:hdhr_VCR_lib.applescript†L1-L80】
- Runtime loading of the external library during setup, enabling the app to call into the shared handlers without additional user scripting steps.【F:hdhr_VCR.applescript†L57-L75】

### Updated
- Core utilities (disk checks, string helpers, SeriesID tooling) now execute from the shared library, reducing duplicate code inside the primary script and making maintenance simpler for end users who drop in updated library builds.【F:hdhr_VCR_lib.applescript†L22-L925】

### Changed
- The launcher now requires the companion library to be present; missing files trigger a guided notification so users can place the script correctly.【F:hdhr_VCR.applescript†L57-L75】

### Removed
- None.

## 2023-09-07

### Added
- Each scheduled show now stores the authoritative recording URL provided by the HDHomeRun device, improving compatibility with tuners that serve content on non-default ports.【F:hdhr_VCR.applescript†L1672-L1790】【F:hdhr_VCR.applescript†L2051-L2061】
- A “skip idle delay” pathway accelerates returning to the main UI after adding or editing shows, shortening the wait before new schedules become visible.【F:hdhr_VCR.applescript†L1706-L1742】

### Updated
- Recording launch commands now reuse the stored device URL and enrich the logger output so users can trace in-progress recordings without spelunking the filesystem.【F:hdhr_VCR.applescript†L2051-L2061】【F:hdhr_VCR.applescript†L2056-L2063】
- Channel list and show-add workflows were refreshed to better surface logos and metadata from the guide feed.【F:hdhr_VCR.applescript†L1672-L1790】【F:hdhr_VCR.applescript†L2417-L2433】

### Changed
- Legacy URL-construction logic (which assumed a fixed port) was replaced with the tuner-provided endpoint, avoiding failures on devices with custom stream ports.【F:hdhr_VCR.applescript†L2051-L2061】【F:hdhr_VCR.applescript†L2424-L2433】

### Removed
- Stale helper code that previously rebuilt stream URLs by hand, reducing script size so new functionality could fit within AppleScript limits.【F:hdhr_VCR.applescript†L2051-L2061】【F:hdhr_VCR.applescript†L2424-L2433】

## 2023-03-18

### Added
- Refined recording icons and notifications that distinguish between pending, running, and completed recordings, giving clearer visual feedback while browsing the UI.【F:hdhr_VCR.applescript†L60-L96】【F:hdhr_VCR.applescript†L2000-L2070】

### Updated
- Automatic cache-directory creation so poster art downloads work on first launch without manual folder setup.【F:hdhr_VCR.applescript†L100-L105】
- Recording downloads now rely on the native `curl`/`caffeinate` pipeline, removing the Python 2 helper that blocked recordings on newer macOS installs.【F:hdhr_VCR.applescript†L2051-L2058】
- Startup setup validates log and cache paths before continuing, surfacing permission problems earlier in the launch sequence.【F:hdhr_VCR.applescript†L100-L139】

### Changed
- Startup validation now warns about missing cache or log folders up front, so users can fix permissions before attempting to add shows.【F:hdhr_VCR.applescript†L100-L139】

### Removed
- Reliance on the deprecated Python 2 runtime for recording management, aligning the script with default macOS 12+ environments.【F:hdhr_VCR.applescript†L2051-L2058】

## 2021-12-22

### Added
- Automatic detection of stalled recordings: if a curl session drops mid-recording, the script now restarts it and flags the issue in the UI, improving reliability for long events.【F:hdhr_VCR.applescript†L2071-L2127】

### Updated
- Recording health checks run more often during active recordings, reducing the window where a stalled download could go unnoticed.【F:hdhr_VCR.applescript†L2049-L2127】

### Changed
- None.

### Removed
- None.

## 2021-09-05

### Added
- JSON-backed configuration with automatic migration from the legacy plist format, enabling multi-show setups without manual file edits.【F:hdhr_VCR.applescript†L2034-L2108】
- Ability to edit and add multiple shows at once from the main UI, including thumbnail previews during selection.【F:hdhr_VCR.applescript†L1668-L1828】
- Rolling log support so long-running installs keep a bounded history instead of growing log files indefinitely.【F:hdhr_VCR.applescript†L143-L150】

### Updated
- The home screen now highlights the next upcoming recordings and shows currently in progress, reducing the clicks needed to check status.【F:hdhr_VCR.applescript†L1393-L1420】【F:hdhr_VCR.applescript†L1866-L1945】
- Show-add workflow now fetches and displays poster art from the guide feed for easier identification.【F:hdhr_VCR.applescript†L1768-L1783】

### Changed
- Scheduler now aligns guide data to JSON-driven structures, paving the way for future automation like SeriesID tracking.【F:hdhr_VCR.applescript†L2034-L2108】

### Removed
- Legacy text-based config handling that could corrupt schedules when multiple shows were added back-to-back.【F:hdhr_VCR.applescript†L2034-L2108】

## 2021-08-05

### Added
- Multi-show selection for the same channel with an option to apply one set of recording settings to every show, drastically speeding up bulk subscriptions.【F:hdhr_VCR.applescript†L1668-L1762】
- Notifications for shows currently recording, providing real-time confirmation when a capture begins.【F:hdhr_VCR.applescript†L2049-L2070】
- Show artwork preview when picking new recordings, so users can confirm they selected the correct series/movie.【F:hdhr_VCR.applescript†L1672-L1790】

### Updated
- Main screen now includes the upcoming queue directly beneath live status, surfacing schedule context without drilling into submenus.【F:hdhr_VCR.applescript†L1393-L1420】

### Changed
- Bulk-add workflow now pre-validates duplicates and quietly skips ones already scheduled instead of erroring out.【F:hdhr_VCR.applescript†L1668-L1762】

### Removed
- None.

## 2021-07-21

### Added
- The dashboard now displays the next scheduled recordings inline, saving a trip into the Shows view for status checks.【F:hdhr_VCR.applescript†L1393-L1420】

### Updated
- None.

### Changed
- None.

### Removed
- None.

## 2021-07-16

### Added
- Refreshed UI copy and iconography throughout the script for clearer prompts and actions, aligning with the expanded icon set introduced earlier.【F:hdhr_VCR.applescript†L60-L96】
- Stability improvements around tuner discovery and recording retries, reducing the number of modal errors users encounter when devices temporarily vanish.【F:hdhr_VCR.applescript†L2049-L2127】

### Updated
- Dialog wording around adding shows and managing tuners now matches the new iconography, making workflows easier to follow.【F:hdhr_VCR.applescript†L1668-L1790】

### Changed
- None.

### Removed
- None.

## 2021-03-01

### Added
- Persistent logging infrastructure that writes structured entries to disk, giving users an audit trail for each recording attempt.【F:hdhr_VCR.applescript†L100-L139】【F:hdhr_VCR.applescript†L2008-L2070】
- Automated log trimming so the script self-manages log growth based on the number of configured shows.【F:hdhr_VCR.applescript†L126-L139】

### Updated
- Numerous stability fixes across show validation and schedule updates, preventing off-day recordings from firing when a show isn’t supposed to run.【F:hdhr_VCR.applescript†L1856-L1959】

### Changed
- None.

### Removed
- None.

## 2021-02-09

### Added
- Log entries now include the running version number, simplifying support requests by tying reports to a concrete build.【F:hdhr_VCR.applescript†L88-L108】

### Updated
- Handler cleanup reduced redundant device discovery calls, making idle refreshes faster for end users with multiple tuners.【F:hdhr_VCR.applescript†L180-L265】

### Changed
- None.

### Removed
- None.

## 2021-02-08

### Added
- Dedicated log file (`hdhr_VCR.log`) stored alongside user documents so day-to-day recording activity is captured for later review.【F:hdhr_VCR.applescript†L100-L139】
- Automatic version-check notifications that alert users from the UI when a newer release is available.【F:hdhr_VCR.applescript†L142-L194】

### Updated
- Startup routine now immediately discovers HDHomeRun tuners and restores prior show schedules before opening the main UI, making restarts seamless.【F:hdhr_VCR.applescript†L140-L206】

### Changed
- None.

### Removed
- None.

## 2021-02-01

### Added
- Integrated “Facelift” UI with refreshed imagery and channel tiles, modernizing the experience compared to the 2021-01 builds.【F:hdhr_VCR.applescript†L1668-L1828】
- Automatic tuner discovery runs on a timer to keep device lists current even when the app stays open for days.【F:hdhr_VCR.applescript†L180-L265】

### Updated
- Notifications and dialogs include richer context (channel names, durations) so users can quickly confirm the right show is being configured.【F:hdhr_VCR.applescript†L1668-L1790】

### Changed
- None.

### Removed
- None.

## 2021-01-24

### Added
- Bulk of the DVR workflow: show discovery, scheduling UI, and background idle loop that keeps recordings on track without manual intervention.【F:hdhr_VCR.applescript†L1668-L2127】
- Initial support for per-show notification lead times so users can receive “up next” alerts before a recording starts.【F:hdhr_VCR.applescript†L2008-L2070】

### Updated
- None.

### Changed
- None.

### Removed
- None.

## 2021-01-19

### Added
- Ability to recover from tuner conflicts by retrying shows that were previously blocked, reducing manual babysitting of the queue.【F:hdhr_VCR.applescript†L1970-L2045】

### Updated
- None.

### Changed
- None.

### Removed
- None.

## 2021-01-11

### Added
- Initial public release of hdhr_VCR with a clickable UI for browsing HDHomeRun guide data and scheduling recordings from macOS.【F:hdhr_VCR.applescript†L140-L206】

### Updated
- Version metadata surfaced in the UI to match the downloadable package name.【F:hdhr_VCR.applescript†L88-L108】

### Changed
- None.

### Removed
- None.
