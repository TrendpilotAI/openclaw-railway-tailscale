---
name: himalaya
description: "CLI to manage emails via IMAP/SMTP. Use `himalaya` to list, read, write, reply, forward, search, and organize emails from the terminal."
homepage: https://github.com/pimalaya/himalaya
metadata:
  {
    "openclaw":
      {
        "emoji": "📧",
        "requires": { "bins": ["himalaya"] },
        "install":
          [
            {
              "id": "brew",
              "kind": "brew",
              "formula": "himalaya",
              "bins": ["himalaya"],
              "label": "Install Himalaya (brew)",
            },
          ],
      },
  }
---

# Himalaya Email CLI

Himalaya is a CLI email client using IMAP, SMTP, Notmuch, or Sendmail backends.

## Setup

Run `himalaya account configure` or create `~/.config/himalaya/config.toml`:

```toml
[accounts.personal]
email = "you@example.com"
display-name = "Your Name"
default = true

backend.type = "imap"
backend.host = "imap.example.com"
backend.port = 993
backend.encryption.type = "tls"
backend.login = "you@example.com"
backend.auth.type = "password"
backend.auth.cmd = "pass show email/imap"

message.send.backend.type = "smtp"
message.send.backend.host = "smtp.example.com"
message.send.backend.port = 587
message.send.backend.encryption.type = "start-tls"
message.send.backend.login = "you@example.com"
message.send.backend.auth.type = "password"
message.send.backend.auth.cmd = "pass show email/smtp"
```

## Common Operations

- List folders: `himalaya folder list`
- List emails: `himalaya envelope list`
- List in folder: `himalaya envelope list --folder "Sent"`
- Search: `himalaya envelope list from john@example.com subject meeting`
- Read email: `himalaya message read 42`
- Reply: `himalaya message reply 42`
- Reply all: `himalaya message reply 42 --all`
- Forward: `himalaya message forward 42`
- Compose: `himalaya message write`
- Move: `himalaya message move 42 "Archive"`
- Copy: `himalaya message copy 42 "Important"`
- Delete: `himalaya message delete 42`
- Add flag: `himalaya flag add 42 --flag seen`
- Remove flag: `himalaya flag remove 42 --flag seen`

## Send directly

```bash
cat << 'EOF' | himalaya template send
From: you@example.com
To: recipient@example.com
Subject: Test Message

Hello from Himalaya!
EOF
```
