<div align="center">
  <h1>ai-coding-agents</h1>
  <img src="illustration.png" alt="ai-coding-agents illustration" width="800" />
  <p><strong>Personal AI agent configuration managed with GNU Stow — shared across opencode and pi-mono.</strong></p>
</div>

<p align="center">
  <a href="https://awesome.re"><img src="https://awesome.re/badge.svg" alt="Awesome" /></a>
  <a href="https://github.com/jjmartres/ai-coding-agents"><img src="https://img.shields.io/github/last-commit/jjmartres/ai-coding-agents?label=Last%20update&style=flat-square" alt="Last Update" /></a>
  <a href="https://github.com/jjmartres/ai-coding-agents/issues"><img src="https://img.shields.io/github/issues/jjmartres/ai-coding-agents" alt="GitHub Issues" /></a>
  <a href="https://github.com/jjmartres/ai-coding-agents/pulls"><img src="https://img.shields.io/github/issues-pr/jjmartres/ai-coding-agents" alt="GitHub Pull Requests" /></a>
</p>

---

## Table of Contents

- [What this repo is](#what-this-repo-is)
- [Prerequisites](#prerequisites)
- [Repository structure](#repository-structure)
- [Stow packages](#stow-packages)
- [Installation](#installation)
- [Secrets configuration](#secrets-configuration)
- [Make targets](#make-targets)
- [Pre-commit hooks](#pre-commit-hooks)
- [Development](#development)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [Architecture](docs/ARCHITECTURE.md)

## What this repo is

Three [GNU Stow](https://www.gnu.org/software/stow/) packages, all targeting
`$HOME`, that deploy:

- **103 agent persona files** shared between opencode and pi-mono
- **22 reusable skill packs** covering diagrams, code docs, Jira, Datadog, robotics, web security, and more
- **15 slash commands** for common workflows (worktree isolation, commit, review, test, speckit, …)
- **opencode-specific** configuration (migrated natively to OpenCode V2): `opencode.jsonc`, `cli.json`, MCP servers, plugins
- **pi-mono-specific** configuration: settings, models, TypeScript extensions

## Prerequisites

| Tool | Purpose | Required |
|------|---------|----------|
| [GNU Stow](https://www.gnu.org/software/stow/) | Symlink farm manager | Yes |
| [opencode](https://opencode.ai) | AI coding agent (V2 native) | If using the `opencode` package |
| [Node.js](https://nodejs.org/) v18+ | JSONC validation script | Yes |
| [TypeScript](https://www.typescriptlang.org/) | pi-mono extension typechecking | Yes (`npm install -g typescript`) |
| [pre-commit](https://pre-commit.com/) | Git hook framework | Optional |
| [jq](https://jqlang.github.io/jq/) | JSON query engine | Yes |

**macOS:**

```bash
brew install stow node pre-commit jq
npm install -g typescript
```

## Repository structure

```
ai-coding-agents/
├── shared/                          # Stow package 1 — shared across both agents
│   └── .ai-agents/
│       ├── agents/                  # 103 agent persona .md files across 11 categories
│       │   ├── 00-general/
│       │   ├── 01-core/
│       │   ├── 02-languages/
│       │   ├── 03-infrastructure/
│       │   ├── 04-quality-and-security/
│       │   ├── 05-data-ai/
│       │   ├── 06-developer-experience/
│       │   ├── 07-specialized-domains/
│       │   ├── 08-business-product/
│       │   ├── 09-meta-orchestration/
│       │   └── 10-curiosity/
│       ├── commands/                # Shared slash commands (18 workflows)
│       │   ├── astro-dso-doc.md
│       │   ├── call-agent.md        # Dynamic agent caller with fuzzy matching & aliases
│       │   ├── commit.md
│       │   ├── commit-and-create-mr.md
│       │   ├── compose-email.md
│       │   ├── datadog.md
│       │   ├── documentation.md
│       │   ├── fix-renovate-mr.md
│       │   ├── memory-bank.md
│       │   ├── next-sprint-design.md
│       │   ├── prepare-dataset.md
│       │   ├── review.md
│       │   ├── speckit.polish.md
│       │   ├── test.md
│       │   ├── worktree.create.md   # Isolated worktree creation & session move
│       │   ├── worktree.delete.md   # Worktree & branch cleanup / prune
│       │   ├── worktree.list.md     # Active worktree & PR/MR status monitor
│       │   └── worktree.md          # Unified worktree command router
│       ├── rules/
│       │   ├── git-worktree.md      # Worktree isolation & session relocation
│       │   └── memory-bank.md
│       ├── scripts/                 # Shared helper utilities
│       │   └── match-agent.js       # Dynamic fuzzy agent matching with alias & typo tolerance
│       └── skills/                  # Reusable skill packs (22)
│           ├── asdf/
│           ├── content-research-writer/
│           ├── datadog/
│           ├── document-code/
│           ├── document-project/
│           ├── file-organizer/
│           ├── graphify/
│           ├── httpie/
│           ├── humanizer/
│           ├── jira/
│           ├── karpathy-guidelines/
│           ├── llm-council/
│           ├── logo-design/
│           ├── marp-slide/
│           ├── mcp-builder/
│           ├── meeting-insights-analyzer/
│           ├── mermaid-diagrams/
│           ├── reachy-mini-sdk/     # git submodule
│           ├── security-audit/      # Source-first security review, attack classes & ledger validators
│           ├── vibesec/             # Secure coding guidance for web applications
│           ├── work-on-ticket/
│           └── writing-clearly-and-concisely/
│
├── opencode/                        # Stow package 2 — opencode-specific (OpenCode V2 native)
│   └── .config/opencode/
│       ├── opencode.jsonc           # Server & agent config (providers, compaction, default_agent)
│       ├── cli.json                 # Terminal & TUI config (replaces legacy V1 tui.jsonc)
│       ├── plugins/                 # OpenCode TUI plugins
│       │   ├── workspace-manager/   # Recency-based workspace switcher & sidebar session monitor
│       │   ├── openrouter-credits/
│       │   └── session-namer/
│       └── themes/                  # Theme documentation (Catppuccin bundled natively in V2)
│
│
├── scripts/
│   └── validate-jsonc.js
├── .stowrc
└── Makefile
```

## Stow packages

### `shared/` → `~/.ai-agents/`

Contains everything that both opencode and pi-mono consume: agent personas,
skill packs, slash commands, and rules. Stow maps the contents of
`shared/` directly into `$HOME`, so `shared/.ai-agents/` lands at
`~/.ai-agents/`.

### `opencode/` → `~/.config/opencode/`

OpenCode V2 native application configuration: main `opencode.jsonc` (migrated to V2 declarative schema with
`experimental.policies` and native autocompaction), cost-guard settings, terminal & TUI preferences
(`cli.json`, which replaces legacy V1 `tui.jsonc`), plugins,
and bundled Catppuccin theme integration.

**Shared symlinks (not managed by Stow)**

OpenCode expects agents, skills, commands, rules, and helper scripts under
`~/.config/opencode/`. Stow cannot map the same source directory to two
different destinations, so `make install` (or `make link-shared`) creates these symlinks
separately:

```
~/.config/opencode/agents/   →  flattened symlinks to all 103 ~/.ai-agents/agents/*/*.md
~/.config/opencode/skills    →  ~/.ai-agents/skills
~/.config/opencode/commands  →  ~/.ai-agents/commands
~/.config/opencode/rules     →  ~/.ai-agents/rules
~/.config/opencode/scripts   →  ~/.ai-agents/scripts
```

Run `make link-shared` to create them independently, or `make link-agents` to re-flatten agent symlinks. See `make status` to verify.

### `pi-mono/` → `~/.pi/`

pi-mono application config: settings, model definitions, auth, themes, and a
set of TypeScript extensions that add custom behaviour (agent loading, skill
search, session management, git checkpoints, usage tracking, and more).

## Installation

```bash
# Clone the tektite-io repository on the opencode-tektite branch (include submodules)
git clone --recurse-submodules --branch opencode-tektite https://github.com/tektite-io/ai-coding-agents.git
cd ai-coding-agents

# Stow all packages, init submodules, and create shared symlinks
make install

# (Optional) Install pre-commit hooks
make install-hooks
```

After install, symlinks under `$HOME` point back into this repo. Edit files
here; changes take effect immediately.

## Secrets configuration

This repo is public. **Never commit credentials** to `opencode.jsonc`, `cli.json`,
or any other tracked file. OpenCode resolves secrets when it loads its config,
using variable substitution:

| Syntax | Source |
|--------|--------|
| `{env:VAR_NAME}` | An environment variable |
| `{file:path/to/file}` | The contents of a file (relative to the config file, or an absolute/`~` path) |


```jsonc
"cognee": {
  "headers": { "Authorization": "Bearer {file:~/.secrets/opencode/cognee-token}" }
},
"github": {
  "headers": { "Authorization": "Bearer {file:~/.secrets/opencode/github-token}" }
}
```

### Set up the secret files

Store tokens outside the repo, under `~/.secrets/opencode/`, with `600`
permissions. These files are not managed by Stow and are never tracked by Git:

```bash
mkdir -p ~/.secrets/opencode
chmod 700 ~/.secrets/opencode

# Write each token without a trailing newline
printf '%s' "$COGNEE_TOKEN" > ~/.secrets/opencode/cognee-token
printf '%s' "$GITHUB_TOKEN" > ~/.secrets/opencode/github-token
chmod 600 ~/.secrets/opencode/*

# Verify permissions and that each file is non-empty
stat -f '%Sp %N' ~/.secrets/opencode/*
```

Supply the token values however you prefer (1Password CLI, `pass`, a password
manager export, or an exported shell variable). Avoid pasting tokens into the
files with an editor when a command can write them instead.

### Or use environment variables

`{env:VAR_NAME}` works anywhere `{file:path}` does. If the variable is unset,
OpenCode substitutes an **empty string**, so a missing token can silently become
`Authorization: Bearer ` and fail only when the server is called. Prefer file
substitution when the server needs the secret to work, and check the file exists
before starting OpenCode:

```bash
test -s ~/.secrets/opencode/cognee-token && echo "cognee token present"
test -s ~/.secrets/opencode/github-token && echo "github token present"
```

### Apply changes

Secret file contents are read when OpenCode loads its config. Restart OpenCode
after creating or rotating a token. `make restow` only re-links the tracked
config files; it does not create or update anything under `~/.secrets/`.

## Make targets

```
Installation
  install              Stow all packages + init submodules + gen local index + create shared symlinks
  submodules           Initialize and update git submodules
  stow-install         Stow all packages only
  link-shared          Create ~/.config/opencode/{skills,commands,rules,scripts} and flat agents symlinks
  link-agents          Create flat symlinks in ~/.config/opencode/agents/ for all 103 agents
  unlink-agents        Remove flat agent symlinks in ~/.config/opencode/agents/
  unlink-shared        Remove ~/.config/opencode/{agents,skills,commands,rules,scripts} symlinks
  uninstall            Remove shared symlinks + unstow all packages
  restow               Re-run stow (use after adding/removing files)

Utilities
  check                Verify setup (directories, stow binary, .stowrc)
  status               Show linked packages and shared symlinks state
  clean                Remove broken symlinks under ~/.ai-agents and ~/.config/opencode

Pre-commit hooks
  install-hooks        Install pre-commit hooks
  uninstall-hooks      Remove pre-commit hooks
  run-hooks            Run all hooks against all files
  update-hooks         Update hooks to latest versions
```

## Pre-commit hooks

| Hook | What it checks |
|------|---------------|
| `check-stowrc-exists` | `.stowrc` is present |
| `validate-makefile` | Makefile parses without syntax errors |
| `typecheck-extensions` | pi-mono TypeScript extensions pass `tsc --noEmit` |
| `validate-jsonc` | All `.jsonc` files are valid JSON-with-comments |
| `trailing-whitespace` | No trailing whitespace |
| `end-of-file-fixer` | Files end with a newline |
| `check-yaml` | YAML files are valid |
| `check-json` | JSON files (non-JSONC) are valid |
| `check-added-large-files` | No files larger than 1 MB |
| `check-merge-conflict` | No leftover conflict markers |
| `detect-private-key` | No accidental private key commits |
| `mixed-line-ending` | Enforces LF line endings |
| `markdownlint` | Markdown in `shared/` passes `.markdownlint.yaml` |
| `shellcheck` | Shell scripts pass `shellcheck --severity=warning` |

## Development

### Adding an agent

Create a `.md` file in the appropriate category under
`shared/.ai-agents/agents/`. No re-stowing needed — the directory is already
symlinked.

### Adding a skill

Create a subdirectory under `shared/.ai-agents/skills/` with a `SKILL.md`
entry point. Same as agents: no re-stowing needed.

### Adding or removing files in a stow package

After adding or deleting files in `opencode/`:

```bash
make restow
```

### Running hooks manually

```bash
make run-hooks

# Or target a single hook
pre-commit run typecheck-extensions --all-files
pre-commit run markdownlint --all-files
```

### Updating configuration

```bash
git pull origin opencode-tektite
make restow
```

## Troubleshooting

**Symlinks not created / stow conflicts**

```bash
make status          # check what's linked
make clean           # remove broken symlinks
make uninstall
make install
```

**Agents not loading in opencode**

```bash
# Verify the shared symlinks exist
ls -la ~/.config/opencode/agents ~/.config/opencode/skills

# Recreate them if missing
make link-shared
```

**TypeScript typecheck fails**

```bash
# Ensure tsc is available
npm install -g typescript

# Run the check manually
pre-commit run typecheck-extensions --all-files
```

**JSONC validation fails**

```bash
# Ensure Node.js >= 18 is installed
node --version

# Run the check manually
pre-commit run validate-jsonc --all-files
```

**Submodule missing or empty**

```bash
# If you cloned without --recurse-submodules
make submodules

# Or manually
git submodule update --init --recursive
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to add agents, skills, commands, and rules, coding standards, and how the pre-commit hooks work.

---

MIT License — see [LICENSE](LICENSE).
