---
name: changelog-social
description: Generate social media announcements for Discord, Twitter, and LinkedIn from the latest changelog entry. Use when user asks to create release announcements, social posts, or share changelog updates.
disable-model-invocation: true
---

# Changelog Social

Generate engaging social media announcements from changelog entries.

## Workflow

### Step 1: Extract Changelog Entry

Read `./CHANGELOG.md` and extract the latest version entry. Parse:
- Version number
- Features, Bug Fixes, Documentation, Maintenance sections

### Step 2: Get Git Contributors

```bash
git tag --sort=-version:refname | head -5
git log <previous-tag>..<current-tag> --pretty=format:"%h|%s|%an" --grep="#"
```

### Step 3: Generate Discord Announcement

**Limit: 2,000 characters.** Use template:

```
🚀 **Project vVERSION RELEASED!**

🎯 **KEY FEATURES**
• Feature one - brief description
• Feature two - brief description

🔧 **FIXES**
• Fix description

📊 **STATS**
X commits | Y PRs merged

🙏 **CONTRIBUTORS**
@user1, @user2
```

**Content Strategy:**
- Focus on user impact
- Highlight annoying bugs fixed
- Show new capabilities
- Keep it punchy with emojis and short bullets

### Step 4: Generate Twitter Post

Use a single comprehensive post (Premium limit: 25,000 chars). Aim for 1,500-3,000 characters.

### Step 5: Generate LinkedIn Post (major releases only)

Professional tone, focus on business impact.

## Content Selection

**Include:** New features, annoying bug fixes, performance improvements, breaking changes
**Skip:** Internal refactoring, dependency updates, test improvements

## Output

Write files to `_bmad-output/social/`:
1. `{repo}-discord-{version}.md`
2. `{repo}-twitter-{version}.md`
3. `{repo}-linkedin-{version}.md` (if applicable)
