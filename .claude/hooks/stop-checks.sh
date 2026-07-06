#!/bin/sh
# Stop hook: session-end verification.
# Warns (non-blocking) if uncommitted changes contain likely secrets
# or leftover debug statements, so they get a second look before commit.

if command -v git >/dev/null 2>&1 && git -C "$CLAUDE_PROJECT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  DIFF=$(git -C "$CLAUDE_PROJECT_DIR" diff --unified=0 -- . ':(exclude)*.lock' ':(exclude)package-lock.json' 2>/dev/null)

  SECRET_HITS=$(printf '%s\n' "$DIFF" | grep -E '^\+.*(api[_-]?key|secret|password|token)\s*[:=]\s*["'"'"'][A-Za-z0-9_\-]{8,}' -i | head -5)
  DEBUG_HITS=$(printf '%s\n' "$DIFF" | grep -E '^\+.*(console\.log|debugger;|dd\(|print\("DEBUG)' | head -5)

  if [ -n "$SECRET_HITS" ] || [ -n "$DEBUG_HITS" ]; then
    NOTE="graphify session-end check: "
    [ -n "$SECRET_HITS" ] && NOTE="${NOTE}possible secret-like values added to the diff; "
    [ -n "$DEBUG_HITS" ] && NOTE="${NOTE}debug statements (console.log/debugger) added to the diff; "
    NOTE="${NOTE}review before committing."
    printf '{"hookSpecificOutput":{"hookEventName":"Stop","additionalContext":"%s"}}\n' "$NOTE"
  fi
fi
