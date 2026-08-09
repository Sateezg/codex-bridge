---
description: Offer to hand heavy work to Codex (GPT-5) as a subagent so it runs on the ChatGPT plan quota instead of burning Claude context and tokens. Use at the START of any task that is large, repetitive, or asset-producing — bulk refactors across many files, generating boilerplate or fixtures, exhaustive repo-wide audits, writing many similar tests, and anything needing mockups or images. Also use whenever the user says "save tokens", "use codex", "delegate this", or "who should do this".
---

# Delegate to Codex when it saves the user tokens

The Codex CLI on this machine runs on the user's **ChatGPT plan quota** — a
separate budget from this Claude session. Work pushed to Codex costs no Claude
output tokens and, more importantly, keeps large intermediate output (file dumps,
generated boilerplate, long search results) out of this context window.

Your job is to notice when that trade is worth making, **offer it**, and then
orchestrate.

## The decision rubric

Delegate to Codex when the task is **high-volume and low-judgment**:

| Signal | Example |
| :-- | :-- |
| Mechanical edits across many files | rename a symbol in 40 files, migrate an import style, add a header to every module |
| Bulk generation | scaffold 20 CRUD endpoints, write fixtures, generate a large seed dataset |
| Exhaustive sweeps | "find every place we call the old API", audit all routes for auth |
| Assets | any image, icon set, mockup, or diagram — always Codex, it has gpt-image-2 |
| Long, self-contained subtasks | port a module to TypeScript, write the test suite for one file |
| A genuinely independent opinion | you already have an answer and want it challenged |

Keep it yourself when the task is **low-volume and high-judgment**: architecture
calls, ambiguous requirements, anything needing the conversation history, small
edits (under ~3 files), or anything the user is iterating on interactively.
Round-tripping a two-line fix through Codex is slower and costs *more* overall.

## How to offer it

When the rubric says delegate, say so in one or two sentences **before** starting,
and be concrete about the split. Don't ask a vague "should I use Codex?" — the user
can't judge that. Tell them what each side does and what it saves:

> This touches ~35 files with the same mechanical change. I can hand the edits to
> Codex — it runs on your ChatGPT quota and keeps 35 file dumps out of this
> context — then review its diff here. Want me to?

If the user has already said "use Codex" or "save tokens", skip the question and
just do it. If the task is small, don't offer at all — the offer itself is noise.

## How to orchestrate

You stay the orchestrator. The pattern is always: **you scope, Codex executes, you
verify.**

1. **Scope it yourself.** Work out exactly what needs doing — the file list, the
   rule, the acceptance criteria. This is the judgment part and it's cheap.
2. **Write a self-contained brief.** Codex has none of this conversation. Include
   the goal, the exact files or glob, the rule to apply, what must not change, and
   the output you expect back.
3. **Pick the right delegate:**
   - `codex-implementer` subagent — for edits to files (runs `workspace-write`)
   - `codex-reviewer` subagent — for review of a diff or module
   - `codex-debugger` subagent — for root-causing a failure
   - `codex-artist` subagent — for images, icons, mockups
   - `codex-run "<task>"` in Bash — for a single quick question, no subagent needed
4. **Verify what comes back.** Read the diff, run the tests, spot-check the images.
   Never forward Codex's claim of success without checking. This is the part that
   makes delegation safe, and it's why you don't delegate judgment.
5. **Report the split.** Tell the user what Codex did and what you checked.

## Guardrails

- **Never delegate a task you can't verify.** If you couldn't tell a good result
  from a bad one, do it yourself.
- **`workspace-write` only when file changes are the point**, and tell the user
  before Codex writes to their repo. Default everything else to read-only.
- **Uncommitted work:** ask the user to commit or stash first when Codex will write
  to files, so its changes are reviewable as a clean diff.
- **Don't fan out.** One Codex task at a time unless the user asked for parallel
  work; each one spends their quota.
- **Codex is not always right.** It has no conversation context and can
  misunderstand a brief. Treat its output as a draft from a capable stranger.
