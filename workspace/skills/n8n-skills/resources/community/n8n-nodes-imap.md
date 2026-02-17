# n8n-nodes-imap

## Basic Information

- Package: `n8n-nodes-imap`
- Category: 💬 Communication & Messaging
- Version: 2.15.0
- Maintainer: umanamente
- npm: [View Package](https://www.npmjs.com/package/n8n-nodes-imap)
- Repository: [View Source](https://github.com/umanamente/n8n-nodes-imap)

## Description

This node allows you to connect to an IMAP server and retrieve emails.

## Installation

```
n8n-nodes-imap
```

## Nodes (1)

### IMAP

- Node Type: `n8n-nodes-imap.imap`
- Version: 1
- Requires Credentials: Yes

Retrieve emails via IMAP

#### Available Operations

- **Get Many** (`loadMailboxList`)
  Get a list of mailboxes
- **Get Quota** (`getMailboxQuota`)
  Get quota (space usage) of an account
- **Get Status** (`getMailboxStatus`)
  Get status of a single mailbox
- **Create** (`createMailbox`)
  Create a new mailbox
- **Rename** (`renameMailbox`)
  Rename a mailbox

#### Core Properties

| Property | Type | Required | Default |
|----------|------|----------|---------|
| `flags` | collection | Yes | `[]` |
| `mailboxPath` | resourceLocator | Yes | `{"mode":"list","value":"INBOX"}` |
| `mailboxPath` | resourceLocator | Yes | `{"mode":"list","value":"INBOX"}` |
| `topLevelMailbox` | boolean | Yes | `true` |
| `mailboxName` | string | Yes | `""` |
| `mailboxPath` | resourceLocator | Yes | `{"mode":"list","value":"INBOX"}` |
| `newMailboxName` | string | Yes | `""` |
| `mailboxPath` | resourceLocator | Yes | `{"mode":"list","value":"INBOX"}` |
| `mailboxPath` | resourceLocator | Yes | `{"mode":"list","value":"INBOX"}` |
| `mailboxPath` | resourceLocator | Yes | `{"mode":"list","value":"INBOX"}` |

#### Connection

- Input Types: `main`
- Output Types: `main`

#### Example Configuration

```json
{
  "name": "IMAP",
  "type": "n8n-nodes-imap.imap",
  "typeVersion": 1,
  "position": [
    250,
    300
  ],
  "parameters": {
    "flags": [],
    "mailboxPath": {
      "mode": "list",
      "value": "INBOX"
    },
    "topLevelMailbox": true,
    "mailboxName": "",
    "operation": "loadMailboxList"
  }
}
```

---

---

[← Back to Community Nodes Index](README.md)
