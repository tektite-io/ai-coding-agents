# Global Operating Rules

Applies to every session, every project. Optimize for correctness first, tokens second — never trade accuracy for brevity.

## Prime directives

- **Silent by default.** No chain-of-thought, plans, progress narration, or recaps unless the user asks. Final response ≤3 bullets: what changed, how it was verified, next action/blocker.
- **Smallest complete change.** Don't refactor, reformat, rename, or "improve" code outside the request's scope.
- **Replace, don't deprecate.** Delete superseded code entirely; no dead code left "just in case."
- **Bias to action.** Ask one concise question only when a decision materially blocks progress and is hard to reverse; otherwise pick the most reasonable option and proceed.
- **Verify before done.** Run the smallest relevant test/lint/build and inspect the diff. Never mark a task complete on intent alone — prove it works.
- **Design for agents too.** Systems/APIs should let an agent achieve any outcome a human user can.

### Code quality

Functions ≤100 lines, cyclomatic complexity ≤8, ≤5 positional params. Lines ≤100 chars. Absolute imports only. Zero warnings from any tool; inline lint-ignores require a one-line justification. Tests verify behavior (including edge/error paths), not implementation.

## Session bootstrap (do this before acting)

1. `git status` / diff to see current state.
2. Read `.opencode/MEMORY.md` if present (active task context). `recall`  
   this task's keywords from `project_<slug>` and `global_memory` in  
   Cognee. Reuse prior answers instead of re-deriving them — this is the  
   main token-saving lever. If Cognee is unreachable, proceed without it  
   and note the gap rather than blocking.
3. Query CodeGraph (`codegraph_*`) for the relevant symbols/entry points before grepping the repo. Fall back to targeted `rg`/reads only when CodeGraph is unavailable or incomplete.
4. Read only files/symbols directly relevant to the change. Don't re-read files already covered in `MEMORY.md` or earlier in this session.

## Memory & Wiki (Cognee, shared across sessions and machines)

Cognee (MCP tools `remember` / `recall` / `forget` / `cognify_status`) is the  
**durable, cross-machine** memory layer. `MEMORY.md` under `.opencode/`  
remains the **ephemeral, local, active-task scratchpad** — unchanged from  
before, overwritten in place, never pushed to Cognee. Everything durable now  
goes to Cognee instead of a per-repo `WIKI.md`. If a repo still has a legacy  
`.opencode/WIKI.md`, migrate its content into Cognee once (global vs project,  
per the rule below) and delete the file.  
  
Production instance: `cognee-docker-compose.yml` in  
`~/.config/opencode/scripts/`, API on `:8000`, MCP on  
`:8001/mcp` (wired into `opencode.jsonc`'s `mcp.cognee` entry). Runs with  
`ENABLE_BACKEND_ACCESS_CONTROL=true` for real per-dataset isolation .

### Two datasets

- `global_memory` — reusable across any repo: tool/workflow lessons,  
  environment conventions (asdf, rtk, codegraph usage), generic debugging  
  techniques, prompt/agent-config decisions, cross-project architecture  
  patterns.
- `project_<slug>` — tied to one codebase: its architecture decisions,  
  its bugs and root causes, its subsystem wiki, its conventions.

Compute `<slug>` once per session, deterministically, from repo identity —  
**never from the local absolute path** (it differs per machine):

```bash
remote=$(git remote get-url origin 2>/dev/null)
base=${remote:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}
slug=$(basename "$base" .git | tr '[:upper:]' '[:lower:]' \
       | sed -E 's/[^a-z0-9_-]+/-/g; s/-+/-/g; s/^-|-$//g')
# project_dataset = "project_${slug}"
```

For a security engagement (not an ordinary git repo), the canonical  
`project_<slug>` is instead the `name` field in  
`~/.config/opencode/security/authorized_targets.yaml` — read identically by  
any security-focused subagent and by a standalone harness, if one exists.  
Never derive a second, independent slug for the same engagement.  
  
Decision rule — **"would this help in a different repo?"**  
Yes → `global_memory`. No, only makes sense in this codebase → `project_<slug>`.  
When unsure, default to project-scoped; it's cheaper to promote something to  
global later than to pollute global with repo-specific facts.  
  
Always pass the dataset explicitly on every `remember`/`recall`/`forget` call  
(check the live tool schema for the exact field — `dataset_name` on  
`remember`/`forget` as of the current MCP server). Do not rely on  
per-client auto-scoped default datasets; that would silently fragment memory  
by client instead of by global/project. `COGNEE_MCP_AGENT_SCOPED=false` on  
the server side is what makes this hold across clients, not just a prompt  
convention.

### What to persist

Treat Cognee as a curated knowledge base, not a transcript. Persist only  
information with durable value for future work, using three categories:  
  
**DECISION** — architectural/technical choices that must stay consistent.

```text
TYPE: DECISION
DATASET: global_memory | project_<slug>

Decision: <what was decided>
Reason: <why>
Implication: <what future agents must do differently as a result>
```

**LESSON** — verified knowledge from solving a problem.

```text
TYPE: LESSON
DATASET: global_memory | project_<slug>

Problem: <what went wrong>
Root cause: <verified cause>
Solution: <fix>
Verification: <how it was confirmed>
```

Prefer `"OpenCode rejected X because the provider expects Y"` over  
`"We tried X, then Y, then eventually it worked."` Only store a failed  
attempt if the failure itself is a reusable fact.  
  
**WIKI** — stable technical knowledge useful independent of any one task:  
architecture, config, subsystem behavior, important commands/procedures,  
tool capabilities, repo conventions.

```text
TYPE: WIKI
DATASET: global_memory | project_<slug>

Topic: <topic>
Knowledge: <concise, self-contained explanation>
Relevant configuration: <only if useful>
```

Do **not** persist: ordinary conversation, intermediate reasoning, raw  
command output, unverified assumptions, transient task state, source code  
that already lives in the repo, or anything interesting-but-not-reusable.

### Never store secrets

Never send passwords, API keys, tokens, SSH keys, certs, cookies, auth  
headers, or `.env` values to Cognee. If a config depends on a secret, record  
only the variable name:

```text
The service requires OPENROUTER_API_KEY. The value must not be stored.
```

### Never commit credentials

Never commit credential files or secret values to git — `.env`, `.env.*`,  
`*.pem`, `*.key`, `credentials.json`, `secrets.*`, service-account JSON, and  
similar. Keep them in `.gitignore`; commit only variable names or example  
files. Before every commit, check `git status` and `git diff --cached` for  
these paths. If a credential file was committed, treat the secret as  
compromised: rotate it, purge it from history (for example  
`git filter-repo --path <file> --invert-paths`), force-push the rewritten  
branch, and delete local backups. Never rely on deleting it in a later commit.

### Before writing: dedupe and decide

1. `recall` the target dataset for the topic first.
2. If an equivalent memory exists and the new info only extends it: add a  
   short follow-up entry referencing the earlier one.
3. If it contradicts/supersedes an existing entry: there is no "update" —  
   `forget` the stale item (by `data_id` if `recall` returned one; otherwise  
   leave it and let the new entry supersede it in retrieval) then `remember`  
   the corrected version. Never let two contradictory active memories stand  
   in the same dataset.
4. Ask: *"Would this still help another agent on this working weeks or  
   months from now?"* No → keep it in `MEMORY.md` only, don't write to  
   Cognee.

### Before acting: recall

Before a significant change in an area that may have prior decisions or  
lessons (architecture, infra, model/provider config, security tooling, dev  
environment, or a recurring failure), `recall` from both `project_<slug>` and  
`global_memory` first. For anything security-related, also `recall` from  
`security_corpus`. Current repository state and explicit user instructions  
always outrank recalled memory. If memory conflicts with verified current  
state, trust current state, don't silently follow stale memory, and  
update/forget the stale entry if the discrepancy matters.

### Explicit triggers

If the user says "remember this", "save this", "add this to the project  
knowledge", or similar — persist it after classifying DECISION/LESSON/WIKI  
and global/project, following the dedupe step above.

### Automatic promotion at task end

Do not auto-promote ordinary conversation. At the end of a substantial task,  
check:

1. Did we make a decision future agents need to know?
2. Did we discover a reusable, verified lesson?
3. Did we learn stable technical info belonging in the wiki?
4. Did an existing Cognee memory become obsolete?

Only write/update Cognee when the answer to one of these is yes and the  
information is sufficiently verified. If nothing durable came out of the  
task, write nothing.

### Quick reference

| Tool | Use for |
| --- | --- |
| `recall` | Query before researching (session bootstrap) and before big changes. |
| `remember` | Persist a DECISION/LESSON/WIKI entry; always pass the target dataset. |
| `forget` | Remove a stale item (`data_id`) or an entire dataset. |
| `cognify_status` | Check progress of a background `remember(background=True)` write. |


## Delegation (Task tool / subagents)

Spawn a subagent for: reading 3+ files to answer one question, research (web/docs lookups), code review or analysis producing verbose output, or any investigation where only the summary matters.  
  
Stay in the main thread for: direct edits the user requested, 1–2 targeted reads, back-and-forth conversation, or steps the user needs to see live.  
  
**Rule of thumb:** if a step would read more than ~3 files or produce output the user doesn't need verbatim, delegate it and return only the summary.

## Workflow

- **Plan** — for any 3+ step or architectural task, use the `todowrite` tool to track steps in-session; use plan mode when the user needs to sign off before execution. Re-plan immediately if something goes sideways.
- **Execute** — surgical edits only; reuse existing patterns/deps/tests; one coherent change at a time. Trace only `caller → changed code → callee/config/schema/test` as needed. Re-scan broadly only for public-API, shared-config, build-tooling, security-boundary, or architectural changes, or when targeted evidence fails.
- **Verify** — run the smallest relevant check; diff behavior against main when relevant. Bar: "would a staff engineer approve this?"
- **Re-index** — after completing any code change (before verify/handoff), run `codegraph index` (or the project's equivalent reindex command) so the graph reflects the new state; don't rely solely on the file-watcher's debounce for changes you're about to query or hand off.
- **Handoff** — run the "Automatic promotion at task end" check; `remember`  
  any durable DECISION/LESSON/WIKI into the right Cognee dataset, then  
  overwrite `MEMORY.md` with the final active-context state (or clear it if  
  the task is fully done). Confirm only intended changes remain, then stop  
  or hand off.

---

## CodeGraph

This project has a CodeGraph MCP server (`codegraph_*` tools) configured. CodeGraph is a tree-sitter-parsed knowledge graph of every symbol, edge, and file. Reads are sub-millisecond and return structural information grep cannot.

### When to prefer codegraph over native search

Use codegraph for **structural** questions — what calls what, what would break, where is X defined, what is X's signature. Use native grep/read only for **literal text** queries (string contents, comments, log messages) or after you already have a specific file open.

| Question | Tool |
| --- | --- |
| "Where is X defined?" / "Find symbol named X" | `codegraph_search` |
| "What calls function Y?" | `codegraph_callers` |
| "What does Y call?" | `codegraph_callees` |
| "What would break if I changed Z?" | `codegraph_impact` |
| "Show me Y's signature / source / docstring" | `codegraph_node` |
| "Give me focused context for a task/area" | `codegraph_context` |
| "See several related symbols' source at once" | `codegraph_explore` |
| "What files exist under path/" | `codegraph_files` |
| "Is the index healthy?" | `codegraph_status` |


### Rules of thumb

- **Answer directly — don't delegate exploration.** For "how does X work" / architecture / trace questions, answer with 2-3 codegraph calls: `codegraph_context` first, then ONE `codegraph_explore` for the source of the symbols it surfaces. Codegraph IS the pre-built index, so spawning a separate file-reading sub-task/agent — or running a grep + read loop — repeats work codegraph already did and costs more for the same answer.
- **Trust codegraph results.** They come from a full AST parse. Do NOT re-verify them with grep — that's slower, less accurate, and wastes context.
- **Don't grep first** when looking up a symbol by name. `codegraph_search` is faster and returns kind + location + signature in one call.
- **Don't chain** `codegraph_search` **+** `codegraph_node` when you just want context — `codegraph_context` is one call.
- **Don't loop** `codegraph_node` **over many symbols** — one `codegraph_explore` call returns several symbols' source grouped in a single capped call, while each separate node/Read call re-reads the whole context and costs far more.
- **Index lag**: the file watcher debounces ~500ms behind writes; don't re-query immediately after editing a file in the same turn.

### If `.codegraph/` doesn't exist

The MCP server returns "not initialized." Ask the user: *"I notice this project doesn't have CodeGraph initialized. Want me to run* `codegraph init -i` *to build the index?"*  

# RTK (Rust Token Killer) - Token-Optimized Commands

When running shell commands, **always prefix with** `rtk`. This reduces context  
usage by 60-90% with zero behavior change. If rtk has no filter for a command,  
it passes through unchanged — so it is always safe to use.

## Key Commands

```bash
# Git (59-80% savings)
rtk git status          rtk git diff            rtk git log

# Files & Search (60-75% savings)
rtk ls <path>           rtk read <file>         rtk grep <pattern>
rtk find <pattern>      rtk diff <file>

# Test (90-99% savings) — shows failures only
rtk pytest tests/       rtk cargo test          rtk test <cmd>

# Build & Lint (80-90% savings) — shows errors only
rtk tsc                 rtk lint                rtk cargo build
rtk prettier --check    rtk mypy                rtk ruff check

# Analysis (70-90% savings)
rtk err <cmd>           rtk log <file>          rtk json <file>
rtk summary <cmd>       rtk deps                rtk env

# GitHub (26-87% savings)
rtk gh pr view <n>      rtk gh run list         rtk gh issue list

# Infrastructure (85% savings)
rtk docker ps           rtk kubectl get         rtk docker logs <c>

# Package managers (70-90% savings)
rtk pip list            rtk pnpm install        rtk npm run <script>
```

## Rules

- In command chains, prefix each segment: `rtk git add . && rtk git commit -m "msg"`
- For debugging, use raw command without rtk prefix
- `rtk proxy <cmd>` runs command without filtering but tracks usage