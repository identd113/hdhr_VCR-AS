# hdhr_VCR

> **A Smart VCR script for all HDHomeRun devices.  
No cloud. No subscriptions. No drama.  
Just simple, AppleScript-powered TV recording for macOS.**

![Show List](show_list.png)

---

## Why?

I wanted to record TV shows quickly on my HDHomeRun, without a massive install or a paid DVR system. This project gives you guide-based, one-click recording—no accounts or setup fees.

---

## Features

- **Automatic HDHomeRun discovery** – Finds all compatible tuners on your network.
- **Guide-based recording** – Automatically pulls show, season, episode, and timing info.
- **Icon-rich selection views** – Show list, channel list, and grid now surface
  lineup badges (`[HD]`, favorites). In the show edit list, the left icon now
  represents next-airing status while the right icon represents show type
  (single/series variants), with inactive shows using the cancel icon.
- **Deterministic multi-select mapping** – Duplicate-looking rows are resolved by
  selection order so edits/adds do not collapse into a single matched item.
- **Flexible Series Recording:**  
  • Record by channel or *across all channels* for syndicated shows **(NEW)**  
  • Supports SeriesID tracking for smarter scheduling **(NEW)**
- **Dynamic Task Queueing:**  
  • Show IDs for series recordings are now queued and processed efficiently at the end of the idle loop **(NEW)**
- **Modular Script Design:**  
  • Core logic split into a library file for easier updates and better stability **(NEW)**
- **Powerful Logging and Debugging:**  
  • Robust, handler-specific logs  
  • Optional JSON log mode: open API calls in your browser for troubleshooting **(NEW)**
- **Smart Error Handling:**  
  • Automatic pause on repeated recording failures **(NEW)**  
  • Protects against accidental config wipeouts **(NEW)**
- **Disk space management:**  
  • Configurable disk space checks before/during recording **(NEW)**
- **Easy “Add,” “Edit,” and “Manual Add” workflows**
- **macOS notifications:** See every step from “about to record” to “recording complete”
- **Runs quietly in the background—no complex setup needed**

---

## Requirements

1. macOS
2. [JSONHelper](https://apps.apple.com/us/app/json-helper-for-applescript/id453114608) is required (free)
3. A configured HDHomeRun device from [SiliconDust](https://www.silicondust.com)
4. The HDHomeRun device should have a static IP on the network, as we record the IP address of the tuner when we add a show.
5. hdhr_VCR needs access to the following paths:

   - ~/Documents/hdhr_VCR.json
   - ~/Library/Caches/hdhr_VCR/
   - ~/Library/Logs/hdhr_VCR.log

---

## Quick Start

1. Download `hdhr_VCR.applescript` ([latest release](https://raw.githubusercontent.com/identd113/hdhr_VCR-AS/20230907_Release/hdhr_VCR.applescript)).
2. Open in **Script Editor**.
3. Go to **File → Export...**  
   - Save as **Application**
   - Check **“Stay open after run handler”**
4. Move the app to your **Applications** folder and launch.
5. On first run, grant the necessary permissions (macOS will prompt).

---

## How to Use

- **Add**: Pick a tuner, pick a channel, pick a show—done.
- **Series Recording**: Record on specific days, repeats every week.
- **Manual Add**: Need something outside the guide? Use decimal time (e.g., 18.75 for 6:45pm).
- **Run**: Resets UI or goes idle.
- **Edit/Remove**: Click the app in the dock for options.

### Screenshots

_See below for a visual walkthrough of the process:_

![Title Screen](title.png)

- **Channel List Selection**

![Channel List](channel_list.png)

- **Show Grid / Guide View**

![HDHR Guide](hdhrGRID.png)

- **Show Info**

![Show Info](show_info2.png)

---

## How It Works

- Scans for tuners, fetches lineup and guide.
- Stores settings/data in JSON and AppleScript records.
- Uses `curl` for all network/file transfers.
- Prevents sleep with `caffeinate` during recordings.
- Shows and device records look like this:

```applescript
{show_title:"Example", show_time:16, ...}
```

---

## Developer Testing

Run the on-demand locale/time handler tests before larger date or locale
changes:

- `./scripts/run_time_tests.sh`
- `./scripts/run_time_tests.sh --locale en_US`
- `./scripts/run_time_tests.sh --locale en_GB`
- `./scripts/run_time_tests.sh --fixture-date "Tuesday, January 2, 2024 at 1:05:09 PM" --fixture-date-half "Tuesday, January 2, 2024 at 1:30:09 PM"`

See [docs/TESTING.md](docs/TESTING.md) for full testing guidance.

---

## Maintainer Automation

See [docs/CODEX_REQUESTS.md](docs/CODEX_REQUESTS.md) for details on the workflow
that archives Codex requests automatically after a pull request merges.
