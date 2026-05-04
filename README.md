# hdhr_VCR

Smart VCR for HDHomeRun devices. Guide-based, zero-setup TV recording on macOS.  
**No cloud. No subscriptions. No accounts.** Just local, AppleScript-powered automation.

---

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/m-woodfill/hdhr_VCR/main/install.sh | bash
```

This script will:
- Download the latest app and library scripts
- Offer to install [JSONHelper](https://apps.apple.com/us/app/json-helper-for-applescript/id453114608) (required, free)
- Compile everything and place it in the right locations
- Main app → `/Applications/hdhr_VCR.app`
- Library → `~/Documents/hdhr_VCR_lib.scpt`

---

## What It Does

- **Automatic discovery** – Finds all HDHomeRun tuners on your network
- **Guide-based series recording** – SeriesID tracking finds episodes on any channel, any day
- **4 flexible modes:**
  - Single episode on a specific day/time/channel
  - Multiple days/times on one channel
  - All episodes on one channel (guide-driven)
  - All episodes on any channel (fully automatic)
- **Smart queuing** – Episodes are queued at the end of each cycle; on completion, the show immediately rescans for the next episode
- **Self-healing** – When a show has no upcoming guide data, it retries every 4 hours. It picks up automatically when the show returns
- **Locale-safe** – Dates stored as Unix epoch; works on both `en_US` and `en_GB` systems
- **Resilient** – Detects and cleans up stale recordings, monitors disk space (blocks at 93% or <10GB), auto-pauses after 3 failures
- **Transparent** – Full structured logging with handler context; every decision is traceable
- **Modular** – Core logic in a separate library; library updates don't require recompiling the app


---

## Requirements

- macOS 10.13+
- [JSONHelper](https://apps.apple.com/us/app/json-helper-for-applescript/id453114608) (free, installed by the installer)
- A configured HDHomeRun device with static IP
- Read/write access to `~/Documents/` and `~/Library/Logs/`

---

## Usage

Launch `/Applications/hdhr_VCR.app`. On first run, grant the necessary macOS permissions.

**Add a show:**  
Click "Add" → Pick tuner → Enter title → Choose mode (Single, DateTime, SeriesID(Channel), or SeriesID(All)) → Answer the prompts

**Edit a show:**  
Click "Edit" → Select show → Modify and save

**Modes explained:**
- **Single**: One episode, specific day/time/channel
- **DateTime**: Multiple days/times on one channel (you specify all details)
- **SeriesID(Channel)**: All episodes on one channel; guide supplies time/date/length
- **SeriesID(All)**: All episodes on any channel; fully automatic

---

## Documentation

- **[WORKFLOWS.md](docs/WORKFLOWS.md)** — Step-by-step add/edit guides for each mode
- **[SHOW_STATUS.md](docs/SHOW_STATUS.md)** — 4-state model and validation rules
- **[ADVANCED_PROCESSES.md](docs/ADVANCED_PROCESSES.md)** — SeriesID matching, recording lifecycle, error handling
- **[CLAUDE.md](CLAUDE.md)** — Architecture, key handlers, design decisions (for developers)
- **[TESTING.md](docs/TESTING.md)** — Test procedures and validation checklist
- **[CHANGELOG.md](docs/CHANGELOG.md)** — Release history

---

## How It Works

- Discovers tuners via local HDHomeRun API, fetches lineup and guide data on startup
- Stores all show config in `~/Documents/hdhr_VCR-{hostname}.json`
- Uses `curl` for all network transfers and recording
- Wraps recordings in `caffeinate -i` to prevent sleep during capture
- Main idle loop every ~10 seconds (accelerates to 1 second when recording is imminent)

---

## Troubleshooting

**Show not recording?**  
Check `~/Library/Logs/hdhr_VCR.log` — every decision is logged with full context.

**Config corruption?**  
The app backs up the config before every write. Check `~/Documents/hdhr_VCR-*.json.bak`.

**Need to rebuild?**  
Run the install script again or manually: `osacompile -o /Applications/hdhr_VCR.app /path/to/hdhr_VCR.applescript`

---

## License

See LICENSE file in the repository.
