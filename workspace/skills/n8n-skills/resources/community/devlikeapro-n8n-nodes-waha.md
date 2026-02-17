# @devlikeapro/n8n-nodes-waha

## Basic Information

- Package: `@devlikeapro/n8n-nodes-waha`
- Category: 💬 Communication & Messaging
- Version: 2025.2.9
- Maintainer: devlikeapro
- npm: [View Package](https://www.npmjs.com/package/@devlikeapro/n8n-nodes-waha)
- Repository: [View Source](https://github.com/devlikeapro/n8n-nodes-waha)

## Description

n8n to connect with WAHA (Whatsapp HTTP API)

## Installation

```
@devlikeapro/n8n-nodes-waha
```

## Nodes (2)

### WAHA

- Node Type: `@devlikeapro/n8n-nodes-waha.WAHA`
- Version: 202502
- Requires Credentials: Yes

Connect with Whatsapp HTTP API

#### Available Operations

- **Get QR** (`Get QR`)
  Get QR code for pairing WhatsApp API.
- **Request Code** (`Request Code`)
  Request authentication code.

#### Core Properties

| Property | Type | Required | Default |
|----------|------|----------|---------|
| `url` | string | Yes | `""` |
| `format` | options | Yes | `"image"` |
| `presence` | options | Yes | `"offline"` |
| `session` | string | Yes | `"={{ $json.session }}"` |
| `session` | string | Yes | `"={{ $json.session }}"` |
| `phoneNumber` | string | Yes | `"12132132130"` |
| `session` | string | Yes | `"={{ $json.session }}"` |
| `session` | string | Yes | `"={{ $json.session }}"` |
| `session` | string | Yes | `"={{ $json.session }}"` |
| `session` | string | Yes | `"={{ $json.session }}"` |

#### Connection

- Input Types: `main`
- Output Types: `main`

#### Example Configuration

```json
{
  "name": "WAHA",
  "type": "@devlikeapro/n8n-nodes-waha.WAHA",
  "typeVersion": 202502,
  "position": [
    250,
    300
  ],
  "parameters": {
    "url": "",
    "format": "image",
    "presence": "offline",
    "session": "={{ $json.session }}",
    "operation": "Get QR"
  }
}
```

---

### WAHA Trigger

- Node Type: `@devlikeapro/n8n-nodes-waha.wahaTrigger`
- Version: 202502

Handle WAHA events via webhooks

#### Core Properties

| Property | Type | Required | Default |
|----------|------|----------|---------|
| `operation` | notice | No | `""` |
| `operation` | notice | No | `""` |

#### Connection

- Input Types: 
- Output Types: `main`
- Output Count: 26

#### Example Configuration

```json
{
  "name": "WAHA Trigger",
  "type": "@devlikeapro/n8n-nodes-waha.wahaTrigger",
  "typeVersion": 202502,
  "position": [
    250,
    300
  ],
  "parameters": {}
}
```

---

---

[← Back to Community Nodes Index](README.md)
