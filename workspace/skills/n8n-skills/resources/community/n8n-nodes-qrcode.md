# n8n-nodes-qrcode

## Basic Information

- Package: `n8n-nodes-qrcode`
- Category: 🔧 Utilities & Tools
- Version: 0.1.0
- Maintainer: 0xtlt
- npm: [View Package](https://www.npmjs.com/package/n8n-nodes-qrcode)
- Repository: [View Source](https://github.com/0xtlt/n8n-nodes-qrcode)

## Description

n8n nodes to generate QRCode

## Installation

```
n8n-nodes-qrcode
```

## Nodes (1)

### QrCode

- Node Type: `n8n-nodes-qrcode.qrCode`
- Version: 1

Create a QR Code image

#### Core Properties

| Property | Type | Required | Default |
|----------|------|----------|---------|
| `value` | string | No | `""` |
| `qrCodeOptions` | fixedCollection | No | `[]` |
| `width` | number | No | `256` |

#### Connection

- Input Types: `main`
- Output Types: `main`

#### Example Configuration

```json
{
  "name": "QrCode",
  "type": "n8n-nodes-qrcode.qrCode",
  "typeVersion": 1,
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
