# hdhr_VCR-AS Contribution Agent

This repository contains the AppleScript sources and assets for the hdhr_VCR smart DVR helper.

## General Guidance
- Keep `hdhr_VCR.applescript` and `hdhr_VCR_lib.applescript` in the project root; downstream users expect these exact filenames when exporting the app bundle.
- When you introduce a user-facing change, update `README.md` to reflect the new workflow or capability.
- If you bump the in-script `Version_local` or library version, add a matching entry to `version.json` (newest release at the top of the list).
- Screenshots in this repo document the UI flow. If the UI changes meaningfully, refresh the corresponding PNG and keep resolution/aspect consistent with the existing assets.

## Comment Handling
- Treat any text that follows a `#` character on a line in the AppleScript sources as a comment.
- Treat any code enclosed by `(*` and `*)` as a block comment.
- Ignore modifications limited to these comments when deciding whether `CHANGELOG.md` or `version.json` require updates.

## Coding Standards
- Follow the AppleScript conventions captured in `docs/APPLE_SCRIPT_STYLE.md` for any `.applescript` edits.

## Testing Expectations
- There are no automated tests. Perform the macOS smoke tests described in `docs/TESTING.md` when the behavior of recordings, notifications, or device discovery changes.
- Document the manual tests you executed in your PR description or summary message.

## Documentation Assets
- Place any additional developer documentation under `docs/` and link to it from the README when relevant.
- Keep markdown files wrapped at a readable width (~100 characters) and use GitHub-flavored Markdown features sparingly.

## PR Message
When preparing a PR summary, include:
1. A short list of the major feature or bug-fix highlights.
2. A bullet list of manual tests you performed (referencing `docs/TESTING.md` as needed).

Following these instructions keeps the project aligned with how downstream users compile and run the scripts.
