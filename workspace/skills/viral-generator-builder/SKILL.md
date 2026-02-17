---
name: viral-generator-builder
description: "Expert in building shareable generator tools that go viral - name generators, quiz makers, avatar creators, personality tests, and calculator tools."
source: vibeship-spawner-skills (Apache 2.0)
---

# Viral Generator Builder

Build tools that create "identity moments" - results people want to show off. Optimize for the screenshot, the share, the "OMG you have to try this" moment.

## Capabilities

- Generator tool architecture
- Shareable result design
- Quiz and personality test builders
- Name and text generators
- Avatar and image generators
- Social sharing optimization

## Generator Architecture

```
Input (minimal) --> Magic (your algorithm) --> Result (shareable)
```

### Input Design

| Type | Example | Virality |
|------|---------|----------|
| Name only | "Enter your name" | High (low friction) |
| Birthday | "Enter your birth date" | High (personal) |
| Quiz answers | "Answer 5 questions" | Medium |
| Photo upload | "Upload a selfie" | High (personalized) |

### Result Types That Get Shared

1. **Identity results** - "You are a..."
2. **Comparison results** - "You're 87% like..."
3. **Prediction results** - "In 2025 you will..."
4. **Score results** - "Your score: 847/1000"
5. **Visual results** - Avatar, badge, certificate

### The Screenshot Test

- Result must look good as a screenshot
- Include branding subtly
- Make text readable on mobile

## Quiz Builder Pattern

```
5-10 questions --> Weighted scoring --> One of N results
```

- 4-8 possible results (sweet spot)
- Each result should feel desirable
- Include "rare" results for sharing

## Name Generator Pattern

| Type | Algorithm |
|------|-----------|
| Deterministic | Hash of input (same input = same output = shareable) |
| Random + seed | Seeded random |
| AI-powered | LLM generation |
| Combinatorial | Word parts |

## Anti-Patterns

- **Forgettable Results**: "You are creative" -- too generic, no identity moment
- **Too Much Input**: Every field is a dropout point, minimize friction
- **Boring Share Cards**: Design for the social feed, bold colors, clear text
