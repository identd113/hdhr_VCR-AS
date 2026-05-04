# hdhr_VCR

**Smart TV recording for HDHomeRun devices on macOS.** One app. One-click recording. No subscriptions, no cloud, no drama.

We built hdhr_VCR because traditional DVRs are overpriced, clunky, and bound to your hardware. This is different: it's local-first, fully automatic, and works with any HDHomeRun tuner on your network.

---

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/m-woodfill/hdhr_VCR/main/install.sh | bash
```

---

## The 4 Recording Modes

**Pick the one that fits your show:**

### 1. **Single** — One episode, one time
Record a specific episode on a specific day/time/channel. Set it and forget it.

### 2. **DateTime Series** — Same time, multiple days
Record "Monday and Wednesday at 8 PM on Channel 5." Perfect for weekly shows with predictable schedules.

### 3. **SeriesID(Channel)** — All episodes on one channel
Tell it your show and which channel. The app watches the guide and records *every new episode* on that channel—automatically. No setup needed; it finds the air time, duration, and episode info from the guide.

### 4. **SeriesID(All)** — All episodes, any channel
The ultimate set-it-and-forget-it mode. Record a show title, and hdhr_VCR finds it *everywhere* it airs. When a syndicated show moves channels or preempts for a special, the app rolls with it. When it goes on hiatus with no upcoming guide data, it quietly waits and picks up the moment it returns.

---

## Why SeriesID is Different

Traditional DVRs tie you to a timeslot. If your show moves nights or preempts, you miss episodes. 

**hdhr_VCR uses SeriesID**—the same system cable providers use to identify shows. Instead of recording "Monday 8 PM," it records "this specific series." The guide tells us where and when the next episode airs, and we record it. If a show moves to a new channel, preempts for a special, or goes on hiatus, hdhr_VCR adapts automatically.

No manual intervention. No missed episodes. Just the show you asked for, whenever it airs.


---

## Key Features

- **Automatic HDHomeRun discovery** – Finds all tuners on your network instantly
- **Guide-powered scheduling** – Pulls air times, durations, and episode titles from the live guide
- **Self-healing** – When a show has no upcoming episodes, it retries every 4 hours. Picks up automatically when the show returns
- **Resilient** – Detects stale recordings, monitors disk space, auto-pauses after 3 consecutive failures
- **Locale-safe** – Works correctly on both US and UK systems; no locale-specific date bugs
- **Transparent** – Full structured logging; every decision is traceable and debuggable
- **Modular design** – Library updates don't require recompiling the app

---

## What You Need

- macOS 10.13 or later
- [JSONHelper](https://apps.apple.com/us/app/json-helper-for-applescript/id453114608) (free app, installed automatically)
- A configured HDHomeRun tuner with a static IP
- About 30 seconds to install

---

## How to Use It

1. **Install:** Run the curl command above (or clone and run `./install.sh`)
2. **Launch:** Open `/Applications/hdhr_VCR.app`
3. **Add a show:** Click "Add" → Pick your tuner → Enter the show title → Choose a mode → Done

That's it. The app runs in the background and handles the rest.

---

## Documentation

- **[WORKFLOWS.md](docs/WORKFLOWS.md)** — Step-by-step guides for adding and editing shows
- **[SHOW_STATUS.md](docs/SHOW_STATUS.md)** — Details on the 4-state model
- **[ADVANCED_PROCESSES.md](docs/ADVANCED_PROCESSES.md)** — SeriesID matching and episode detection
- **[CHANGELOG.md](docs/CHANGELOG.md)** — Release history and what's new

For developers: See [CLAUDE.md](CLAUDE.md) for architecture and design decisions.

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
