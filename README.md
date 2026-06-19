# bgent

**A communication bus for background Claude Code sessions.** They message each other
and stay aware of what the others are doing, delivered into their context automatically.
Zero dependencies (Python stdlib only).

![bgent demo](docs/demo.gif)

## The problem

Claude Code can run sessions in the background (`claude --bg`, the `claude agents` view).
They show up in a list, but they're islands: there's no native way for one session to
message another, and no way for a session to know what the others are doing. You end up
re-explaining context across sessions by hand.

bgent fixes that. Sessions message each other through a shared bus, and each session pulls
the others' messages and status into its own context automatically, through hooks.

## Install

bgent is a Claude Code plugin:

```
/plugin marketplace add leonardocandiani/bgent
/plugin install bgent@bgent
```

That's it. The MCP server and the delivery hooks ship with the plugin, nothing to wire
into `settings.json` by hand. Update later from `/plugin` (or `claude plugin update bgent`).

Requirements: the `claude` CLI on your `PATH`, and Python 3.8+ (stdlib only, nothing to
`pip install`).

## How it works

Three layers:

1. **Discovery, native.** bgent asks `claude agents --json` who exists. The Claude Code
   daemon is the source of truth, so there's no registration step that can drift or break.

2. **Mailbox, durable.** A file-based bus under `~/.bgent`: one inbox (`jsonl`) per session
   and a shared activity log. Writes are locked (`flock`) and read-marking re-reads the
   inbox under the lock, so a message arriving concurrently is never lost.

3. **Delivery, automatic.** Three hooks put messages and awareness into a session's context
   without you asking:
   - `SessionStart` — pulls accumulated messages when the session opens or resumes.
   - `UserPromptSubmit` — delivers unread messages plus a snapshot of what the others are
     doing, before each prompt.
   - `Stop` — on turn end, delivers any new message and lets the session keep going to act
     on it (a soft wake while it's active).

An **MCP server** exposes the bus as native tools so a session can act on it directly.

## Usage

With the plugin installed, delivery is hands-off, you rarely call anything by hand. When
you want to act explicitly, the MCP tools are:

- `bgent_ls` — list sessions and their status.
- `bgent_send` — message a session (by name or id).
- `bgent_broadcast` — message every other session.
- `bgent_awareness` — what the others are doing right now.
- `bgent_inbox` — read this session's inbox.
- `bgent_activity` — publish what this session is doing.

You ask one session "is anyone else touching the database?" and it already knows, because
the hook put the others' activity in its context.

## Delivery model: mailbox, not phone

A message lands in the target's inbox and reaches it on its **next turn**. A session that's
actively working picks it up almost immediately, the `Stop` hook continues its turn when a
message is waiting. A session that's fully idle reads it whenever it's next prompted. There
is no supported way, on Claude Code today, to inject input into a parked session from the
outside, so bgent guarantees delivery to the inbox rather than pretending to ring a phone.

## License

MIT. See [LICENSE](LICENSE).
