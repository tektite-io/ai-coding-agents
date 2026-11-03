# System Patterns: OpenRouter Credits Extension

## System Architecture

```
┌────────────────────────────────────────────────────────┐
│                   OpenCode Ecosystem                   │
│                                                        │
│  ┌─────────────────────────┐  ┌──────────────────────┐ │
│  │   TUI Plugin (tui.tsx)  │  │ Server Plugin (index)│ │
│  │  - prompt.footer badge  │  │ - openrouter_credits │ │
│  │  - /openrouter dialog   │  │   tool for agents    │ │
│  │  - Toast warnings       │  │ - /openrouter command│ │
│  └────────────┬────────────┘  └──────────┬───────────┘ │
│               │                          │             │
│               └───────────┬──────────────┘             │
│                           ▼                            │
│           ┌────────────────────────────────┐           │
│           │   OpenRouter Service Engine    │           │
│           │  - Credential Resolver         │           │
│           │  - API Client (fetch)          │           │
│           │  - Cache & State Management    │           │
│           └───────────────┬────────────────┘           │
└───────────────────────────┼────────────────────────────┘
                            ▼
        ┌───────────────────────────────────────┐
        │        OpenRouter Cloud APIs          │
        │ - GET /api/v1/key (Key limits & spend)│
        │ - GET /api/v1/credits (Total credits) │
        └───────────────────────────────────────┘
```

## Key Technical Decisions
1. **Dual Entrypoints**:
   - `index.ts`: Standard server plugin entrypoint (`.` export in `package.json`).
   - `tui.tsx`: CLI/TUI plugin entrypoint (`./tui` export in `package.json`).
2. **Key Discovery Pipeline**:
   - In-memory / plugin options -> `OPENROUTER_API_KEY` / `OPENROUTER_KEY` env vars -> OpenCode `auth.json` (`~/.local/share/opencode/auth.json` or `$XDG_DATA_HOME/opencode/auth.json`) under `openrouter.key`.
3. **Data Polling & Caching**:
   - Polling interval defaults to 60s (configurable).
   - Instant refresh on manual command (`/openrouter refresh` or action in dialog).
   - Cached responses with TTL so frequent renders or agent queries don't trigger API rate limits.
4. **State Machine for Display**:
   - `ok`: Balance normal, limit not reached (shows e.g. `🪙 $15.20` or `🪙 15.20/50.00`).
   - `warning`: Remaining balance < 10% of limit or < $2.00 (shows in warning color).
   - `limit_reached`: Limit remaining <= 0 or budget spent (shows `🚫 Limit Reached` in red).
   - `no_key`: No OpenRouter key found (clean muted state, or prompt to connect).
   - `error`: Network or auth failure (shows error indicator with retry).
5. **OpenTUI Integration**:
   - Uses Solid.js reactive primitives (`createSignal`, `createMemo`, `onCleanup`).
   - Styled with semantic OpenCode theme tokens (`context.theme.text.*`, feedback colors).
   - Interactive dialog using `context.ui.dialog.alert` / `context.ui.dialog.select`.

## Development Workflow

- **Active branch:** `opencode-tektite`. All day-to-day development happens directly on this branch in the primary repository root.
- **Upstream sync branch:** `main` is never used for feature work. It exists only to receive upstream changes; sync upstream into `main`, then merge or rebase `main` into `opencode-tektite`.
- **Worktrees:** The generic multi-session worktree policy is relaxed for this repo — no `.worktree/<branch>` instances for normal work. Use one only when a genuinely concurrent, conflicting task needs isolation.
- **Push target:** `origin/opencode-tektite`.
