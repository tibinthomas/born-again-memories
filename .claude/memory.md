# Project Memory — Born Again Memories (BAM)

Durable project notes for agents working in this repo. Update when architecture, stack, or conventions change — this file is not a changelog (see `git log` for that).

## What this is

Flutter app for capturing and cherishing a child's milestones (photos, videos, audio, links) across multiple profiles. Backed by Firebase (Auth via Google Sign-In, Firestore, Storage). Cross-platform: iOS, Android, macOS, web, Linux, Windows.

## Stack

- Flutter/Dart, provider-based state management (`lib/providers/`)
- Firebase: Auth, Firestore (`firestore.rules`, `firestore.indexes.json`), Storage (`storage.rules`), Realtime Database (`database.rules.json`), Cloud Functions (`functions/`)
- `graphify-out/` holds a generated knowledge graph of this codebase — check `graphify-out/GRAPH_REPORT.md` before architecture questions (see project `CLAUDE.md`)

## Structure

- `lib/screens/` — UI screens (home, account recovery, etc.)
- `lib/providers/` — app state (auth, profiles, etc.)
- `lib/services/`, `lib/models/`, `lib/data/`, `lib/utils/`, `lib/widgets/`

## Conventions / decisions worth remembering

- MediaQuery usage standardized on the new static methods (`MediaQuery.sizeOf`, etc.) rather than `MediaQuery.of(context)` — see commit `125bee3`.
- `.claude/hooks/` runs pre-tool-use and session-end verification hooks; `graphify-context.sh` and `stop-checks.sh` are part of this harness, not app code.
- Google Photos integration was tried and removed (commit `45bb36c`) — don't reintroduce without checking why it was pulled.
