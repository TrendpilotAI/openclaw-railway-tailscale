# n8n-nodes-aistudio

## Basic Information

- Package: `n8n-nodes-aistudio`
- Category: 🤖 AI & Voice Tools
- Version: 1.0.11
- Maintainer: ronieremarques
- npm: [View Package](https://www.npmjs.com/package/n8n-nodes-aistudio)

## Description

N8N nodes for Gemini API

## Installation

```
n8n-nodes-aistudio
```

## Nodes (1)

### Gemini IA Studio [8links]

- Node Type: `n8n-nodes-aistudio.geminiIAStudio`
- Version: 1
- Requires Credentials: Yes

Gera conteúdo usando a API do Gemini

#### Core Properties

| Property | Type | Required | Default |
|----------|------|----------|---------|
| `prompt` | string | Yes | `""` |
| `responseMimeType` | options | No | `"text/plain"` |
| `model` | options | No | `"gemini-1.5-flash"` |
| `topP` | number | No | `0.95` |
| `topK` | number | No | `40` |
| `temperature` | number | No | `1` |
| `maxOutputTokens` | number | No | `8192` |

#### Connection

- Input Types: `main`
- Output Types: `main`

#### Example Configuration

```json
{
  "name": "Gemini IA Studio [8links]",
  "type": "n8n-nodes-aistudio.geminiIAStudio",
  "typeVersion": 1,
  "position": [
    250,
    300
  ],
  "parameters": {
    "prompt": ""
  }
}
```

---

---

[← Back to Community Nodes Index](README.md)
