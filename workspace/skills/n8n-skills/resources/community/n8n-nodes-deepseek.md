# n8n-nodes-deepseek

## Basic Information

- Package: `n8n-nodes-deepseek`
- Category: 🤖 AI & Voice Tools
- Version: 1.0.6
- Maintainer: rubickecho
- npm: [View Package](https://www.npmjs.com/package/n8n-nodes-deepseek)
- Repository: [View Source](https://github.com/rubickecho/n8n-deepseek)

## Description

A user-friendly DeepSeek AI node, similar to OpenAI, designed to enhance your workflow. npm link: https://www.npmjs.com/package/n8n-nodes-deepseek

## Installation

```
n8n-nodes-deepseek
```

## Nodes (1)

### DeepSeek

- Node Type: `n8n-nodes-deepseek.deepSeek`
- Version: 1
- Requires Credentials: Yes

Consume DeepSeek AI

#### Available Operations

- **Complete** (`complete`)
  Creates a model response for the given chat conversation

#### Core Properties

| Property | Type | Required | Default |
|----------|------|----------|---------|
| `prompt` | string | Yes | `""` |
| `resource` | options | No | `"chat"` |
| `operation` | options | No | `"complete"` |
| `operation` | options | No | `"complete"` |
| `options` | collection | No | `{}` |
| `options` | collection | No | `{}` |
| `prompt` | fixedCollection | No | `{}` |
| `model` | options | No | `""` |
| `simplifyOutput` | boolean | No | `true` |
| `model` | options | No | `""` |

#### Connection

- Input Types: `main`
- Output Types: `main`

#### Example Configuration

```json
{
  "name": "DeepSeek",
  "type": "n8n-nodes-deepseek.deepSeek",
  "typeVersion": 1,
  "position": [
    250,
    300
  ],
  "parameters": {
    "prompt": "",
    "operation": "complete"
  }
}
```

---

---

[← Back to Community Nodes Index](README.md)
