# hdhr_VCR Workflows

Guide to adding, editing, and managing shows with the 4-state recording system.

> **📖 Reference:** [SHOW_STATUS.md](SHOW_STATUS.md) — State reference · [UI_EXPECTATIONS.md](UI_EXPECTATIONS.md) — Dialogs, icons, user flows · [CLAUDE.md](../CLAUDE.md) — Technical implementation

**Note:** "Prompts:" sequences below describe the logical flow of decisions and inputs per show type. For the actual UI sequence when adding shows, see [CLAUDE.md - Adding a Show](../CLAUDE.md#adding-a-show), which describes the guide-first flow (Channel → Guide Grid → Series Type → Conditional Prompts).

---

## State Details

### 1. SINGLE
Record ONE specific episode.

**Prompts:** Title → Single → Day (1) → Channel → Time → Length → Folder

**Edit:** Title, Day, Channel, Time, Length

---

### 2. DATETIME SERIES
Record specific days/times on a specific channel (manual schedule).

**Example:** "Monday, Wednesday, Friday at 8pm on channel 5"

**Prompts:** Title → Series → DateTime → Days → Channel → Time → Length → Folder

**Edit:** Title, Days, Channel, Time, Length

---

### 3. SERIESID(CHANNEL)
Record all episodes on ONE channel (guide-driven, times vary).

**Example:** "Record all episodes of The Office on channel 5, whenever they air"

**Prompts:** Title → Series → SeriesID(Channel) → Channel → Folder

**Edit:** Title, Channel (only)

Note: Days/time/length auto from guide

---

### 4. SERIESID(ALL)
Record all episodes on ANY/ALL channels (guide-driven).

**Example:** "Record all episodes of Friends, on any channel, any time"

**Prompts:** Title → Series → SeriesID(All) → Folder

**Edit:** Title (only)

Note: Channel/days/time/length all auto from guide

---

## Workflow Quick Reference

| Workflow | Start | Key Choices | Result |
|----------|-------|-------------|--------|
| **Single** | Add → Single → Day → Channel → Time → Length | Specific day only | Record 1 episode |
| **DateTime** | Add → Series → DateTime → Days → Channel → Time → Length | Multiple days allowed | Recurring on schedule |
| **SeriesID(Channel)** | Add → Series → SeriesID(Channel) → Channel | Channel matters only | Record all episodes on 1 channel |
| **SeriesID(All)** | Add → Series → SeriesID(All) | No other choices | Record all episodes everywhere |

---

## Validation Rules

For details on validation and state requirements, see [SHOW_STATUS.md](SHOW_STATUS.md#invalid-combinations-should-never-occur).

---

## Common Tasks

**Want to change how a show records?**
- Edit the show (click Edit button)
- Change the title to re-prompt for Series/Single status
- Once changed, subsequent prompts reflect the new mode

**Recording stopped working?**
- Check that show_active = true in config
- Verify the tuner is still on the network
- See [ADVANCED_PROCESSES.md](ADVANCED_PROCESSES.md#error-handling--retry-logic) for error recovery

**Need to record a show on specific days but it keeps auto-updating?**
- Use DateTime Series (not SeriesID) if you want to control the exact days

**Recording on the wrong channel?**
- For SeriesID(Channel): edit show and change channel
- For DateTime: edit show and change channel
- For SeriesID(All): cannot restrict to one channel (it records on all)

---

## Prompt Reference

| Prompt | Single | DateTime | SeriesID(Ch) | SeriesID(All) |
|--------|--------|----------|--------------|---------------|
| **Title** | ✅ | ✅ | ✅ | ✅ |
| **Series/Single** | ✅ | ✅ | ✅ | ✅ |
| **Series Type** | ❌ | ✅* | ✅* | ✅* |
| **Days** | ✅ | ✅ | ❌ Auto | ❌ Auto |
| **Channel** | ✅ | ✅ | ✅ | ❌ Auto |
| **Time** | ✅ | ✅ | ❌ Guide | ❌ Guide |
| **Length** | ✅ | ✅ | ❌ Guide | ❌ Guide |
| **Folder** | ✅ | ✅ | ✅ | ✅ |

\* Only on initial creation. When editing, series type dialog only appears if you change from Single→Series.
