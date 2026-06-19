# Changelog

All notable changes to bgent are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/), and this project adheres to
[Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-06-19

First stable release. bgent is now a Claude Code plugin (MCP server + hooks),
installable and updatable with `claude plugin`.

### Added
- Distributed as a Claude Code plugin: the MCP server (`bgent_ls`, `bgent_send`,
  `bgent_broadcast`, `bgent_awareness`, `bgent_inbox`, `bgent_activity`, `bgent_spawn`)
  and the hooks ship inside the plugin, so there is no manual `settings.json` editing.
- Automatic delivery at three moments, via hooks: `SessionStart` (pull accumulated
  messages on open/resume), `UserPromptSubmit` (deliver before each prompt), and `Stop`
  (deliver on turn end and continue the turn when there is an unread message, a soft wake).
- README hero GIF demoing cross-session messaging.

### Changed
- Session discovery now reads `claude agents --json` (the Claude Code daemon is the
  source of truth) instead of a hook-populated session store. No fragile registration
  step that can silently break.
- MCP session identity uses `CLAUDE_CODE_SESSION_ID` instead of the cwd basename, which
  fixes collisions when two sessions share a working directory.

### Fixed
- Read-marking now happens under a file lock and re-reads the inbox before rewriting it,
  so a message that arrives concurrently is never overwritten or lost.
- Read messages older than 7 days are pruned, so an inbox no longer grows unbounded.

### Removed
- Live push via cmux. cmux is no longer part of the environment; the durable inbox plus
  hook delivery replaces it. Delivery is a mailbox, not a phone: a message lands in the
  target's inbox and the target reads it on its next turn.
