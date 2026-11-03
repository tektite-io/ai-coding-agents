# Active Context: Repository Workflow

## Durable Workflow Decision
- **Primary active workspace is always the `opencode-tektite` branch.** All development, edits, commits, and pushes happen there, in the primary repository root at `/Users/alex/dev/ai-coding-agents`.
- **`main` is used exclusively to bring in upstream changes.** Do not develop on `main`; it is a staging/upstream-sync branch only.
- This overrides the generic `git-worktree.md` policy for this repository: do not create `.worktree/<branch>` instances or switch branches in-place for day-to-day work. The active branch stays checked out on `opencode-tektite`.
- Exception: a genuinely separate concurrent task may still use a worktree, but the default session workspace remains `opencode-tektite`.

## Current Work Focus
- Humanizer skill (`shared/.ai-agents/skills/humanizer/SKILL.md`) restructured to v3.1.0 and pushed to `origin/opencode-tektite` (commit `e45f8f2`).

## Recent Changes
- Rewrote `shared/.ai-agents/skills/humanizer/SKILL.md` to v3.1.0: restructured AI-tell taxonomy (§1–§19), added voice/return-mode guidance, and trimmed redundant examples.
- Committed as `e45f8f2` and pushed to `origin/opencode-tektite`.

## Next Steps
- Continue work on `opencode-tektite`; keep `main` untouched except for upstream pulls.
- Track repo-wide changes (memory bank files are currently stale relative to actual repository contents).

## Open Gaps
- Cognee memory backend returned `401 Unauthorized` on `remember` in this session; the workflow decision was recorded in this Memory Bank instead. Re-sync to Cognee once auth is restored.
