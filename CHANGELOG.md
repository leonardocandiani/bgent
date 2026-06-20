# Changelog

All notable changes to bgent are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/), and this project adheres to
[Semantic Versioning](https://semver.org/).

## [1.1.0] - 2026-06-20

Collision radar. bgent now warns a session when another live session in the same
project is touching the same file, and everything it injects is project-scoped by
construction and noise-bounded.

### Added
- Collision detection: before each prompt, bgent cross-references the files this session
  touched against the other live sessions in the same project and pushes a warning
  ("'X' is also working on app.ts, sync before editing") when they overlap.
- Rich per-session snapshots, written on `Stop` from a 2MB tail-read of the transcript
  (goal, files touched, where it stopped) instead of a flat 200-char summary. Measured
  at ~21ms on an 11MB transcript; the read path never parses a transcript.
- Project-scoped isolation: each snapshot records its project, resolved from the real
  repo root (`git rev-parse --show-toplevel`). Sessions only ever see others in the SAME
  resolved project; a session with no resolvable project (e.g. run from `$HOME`) stays a
  singleton (`None` never matches `None`).
- A single context selector with dedup and a hard char cap (`BGENT_MAX_CTX`, default
  1500) over everything bgent injects, so it never floods a session's context.

### Changed
- Awareness is now pull, not push: the general "what is everyone doing" block is no
  longer injected on every prompt (it was noise for solo sessions). Only collisions and
  direct messages are pushed automatically; rich awareness is on demand via
  `bgent_awareness` / `bgent awareness`, now reporting each peer's goal and touched files.
- `bgent_activity` updates the session's snapshot instead of appending to a global log.

### Fixed
- Awareness was previously cross-referenced across ALL sessions regardless of project, so
  sessions in different projects could see each other. It is now scoped to the resolved
  project.

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
