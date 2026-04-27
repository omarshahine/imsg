---
name: imsg
description: Use for local iMessage/SMS archive reads, chat history, watch, and explicitly requested sends.
---

# imsg

Use this for Messages.app history, chat lookup, streaming, and sends. Reading is local DB access; sending uses Messages automation and must be explicitly requested.

## Sources

- DB: `~/Library/Messages/chat.db`
- Repo: `~/Projects/imsg`
- CLI: `imsg`
- JSON output is NDJSON; pipe to `jq -s` for arrays.

## Read Workflow

Check DB access:

```bash
sqlite3 ~/Library/Messages/chat.db 'pragma quick_check;'
```

List chats:

```bash
imsg chats --json | jq -s
```

Read a chat:

```bash
imsg history --chat-id ID --json | jq -s
```

Use `--attachments` when attachment metadata matters. Use `--start`/`--end` with absolute timestamps for date-scoped questions.

## Sends

Only send, react, mark read, or show typing when the user explicitly asks. Prefer dry wording in the final confirmation: recipient, service, and what was sent.

Common send command:

```bash
imsg send --to "+15551234567" --text "message" --service auto
```

## Verification

For repo edits:

```bash
make test
make build
```

For live read proof:

```bash
imsg chats --limit 3 --json | jq -s
```
