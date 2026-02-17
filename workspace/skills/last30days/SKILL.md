---
name: last30days
description: Research any topic across Reddit, X, YouTube, and the web from the last 30 days.
metadata:
  {
    "openclaw":
      {
        "emoji": "📰",
        "requires": { "bins": ["python3"] },
      },
  }
---

# /last30days - Research Any Topic from the Last 30 Days

Research ANY topic across Reddit, X, YouTube, and the web. Surface what people are actually discussing, recommending, and debating right now.

## Quick Start

```bash
python3 /root/.claude/skills/last30days/scripts/last30days.py "your topic" --emit=compact
```

## Parse User Intent

Before doing anything, parse the user's input for:

1. **TOPIC**: What they want to learn about
2. **TARGET_TOOL** (if specified): Where they'll use the prompts (e.g., "ChatGPT", "Midjourney")
3. **QUERY TYPE**:
   - **PROMPTING** - "X prompts", "prompting for X" -> techniques and copy-paste prompts
   - **RECOMMENDATIONS** - "best X", "top X" -> a LIST of specific things
   - **NEWS** - "what's happening with X" -> current events/updates
   - **GENERAL** - anything else -> broad understanding

## Research Execution

**Step 1: Run the research script (FOREGROUND with 5-minute timeout)**

```bash
python3 /root/.claude/skills/last30days/scripts/last30days.py "$TOPIC" --emit=compact
```

The script automatically detects available API keys and runs Reddit/X/YouTube searches.

**Read the ENTIRE output.** It contains Reddit items, X items, and YouTube items.

**Options:**
- `--days=N` - Look back N days instead of 30
- `--quick` - Faster, fewer sources (8-12 each)
- `--deep` - Comprehensive (50-70 Reddit, 40-60 X)

**Step 2: WebSearch to supplement**

After the script, do WebSearch to find blogs, tutorials, and news.
EXCLUDE reddit.com, x.com, twitter.com (covered by script).

## Synthesize Results

Weight sources by engagement: Reddit/X (highest) > YouTube (high) > Web (supplementary).

## Output Format

Show "What I learned" section with citations, then stats block:

```
---
✅ All agents reported back!
├─ 🟠 Reddit: {N} threads │ {N} upvotes │ {N} comments
├─ 🔵 X: {N} posts │ {N} likes │ {N} reposts
├─ 🔴 YouTube: {N} videos │ {N} views │ {N} with transcripts
├─ 🌐 Web: {N} pages (supplementary)
└─ 🗣️ Top voices: @{handle1}, @{handle2} │ r/{sub1}, r/{sub2}
---
```

Then invite follow-up based on query type.

## API Keys

The skill uses keys from environment or `~/.config/last30days/.env`:
- `OPENAI_API_KEY` - Reddit search via OpenAI responses API
- `XAI_API_KEY` - X search via xAI Grok (fallback; Bird CLI preferred)
- `BRAVE_API_KEY` / `OPENROUTER_API_KEY` - Optional web search

Bird CLI provides free X search if installed. YouTube uses yt-dlp (free).

Run `python3 /root/.claude/skills/last30days/scripts/last30days.py --diagnose` to check availability.
