---
name: scientific-slides
description: "Build slide decks and presentations for research talks. Use for PowerPoint slides, conference presentations, seminar talks, thesis defense slides, or any scientific talk."
allowed-tools: [Read, Write, Edit, Bash]
---

# Scientific Slides

Build effective scientific presentations for conferences, seminars, defenses, and professional talks.

## Design Philosophy

- **Compelling visuals**: High-quality figures, diagrams (not just bullet points)
- **Minimal text**: Bullet points as prompts, speaker provides explanation
- **Professional design**: Modern color schemes, strong visual hierarchy
- **Story-driven**: Clear narrative arc, not just data dumps

## When to Use

- Conference presentations (5-20 minutes)
- Academic seminars (45-60 minutes)
- Thesis/dissertation defense presentations
- Grant pitch presentations
- Journal club presentations

## Presentation Structure

### Conference Talk (15 min)

| Section | Slides | Time |
|---------|--------|------|
| Title + Motivation | 1-2 | 1-2 min |
| Background | 2-3 | 2-3 min |
| Methods | 2-3 | 2-3 min |
| Results | 3-5 | 5-6 min |
| Discussion | 1-2 | 1-2 min |
| Conclusion | 1 | 1 min |

### Seminar (45 min)

| Section | Slides | Time |
|---------|--------|------|
| Title + Overview | 2-3 | 3-5 min |
| Background/Literature | 5-8 | 8-10 min |
| Methods | 4-6 | 5-8 min |
| Results | 8-12 | 15-18 min |
| Discussion | 3-5 | 5-8 min |
| Conclusion + Future | 2-3 | 3-5 min |

## Slide Design Rules

1. **One idea per slide** - If you need "and", split the slide
2. **6x6 rule maximum** - 6 bullets, 6 words each (prefer fewer)
3. **Visual hierarchy** - Title > Key point > Supporting detail
4. **Consistent formatting** - Same fonts, colors, spacing throughout
5. **High-contrast text** - Dark on light or light on dark
6. **Professional figures** - Publication-quality, properly labeled

## Output Formats

- **PowerPoint** (python-pptx): Full programmatic control
- **LaTeX Beamer**: Academic standard, beautiful math
- **HTML/Reveal.js**: Web-based, interactive

## Figure Guidelines

- Export at 300 DPI minimum
- Use vector formats (SVG/PDF) when possible
- Include proper axis labels, legends, units
- Use colorblind-friendly palettes
