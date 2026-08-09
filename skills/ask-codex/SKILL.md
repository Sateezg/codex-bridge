---
description: Ask OpenAI Codex (GPT-5) a one-off question about the current repo and get its answer back, without spinning up a subagent. Use when the user says "ask codex", "what does GPT think", "get a second opinion on this", or when you want an independent read on a design call, a tricky bug, or an unfamiliar area of the codebase.
---

# Ask Codex a question

For a single question with a single answer. Anything multi-step or long-running
belongs to a subagent (`codex-second-opinion`, `codex-reviewer`, `codex-debugger`).

```bash
codex-run -C <repo-dir> "<self-contained question>"
```

`codex-run` prints **only Codex's final answer** on stdout (it captures the final
message via `codex exec -o` rather than dumping the whole event log). It defaults
to a read-only sandbox, so Codex can read the repo but cannot change anything.

## Writing the question

Codex has zero knowledge of this conversation. Every question must stand alone:

- Name the files or directories it should look at.
- State what you already know or already tried.
- Say what shape of answer you want ("name the single most likely cause and the
  line to look at", "answer yes/no then justify in three sentences").

```bash
codex-run -C /path/to/repo \
  "In src/auth/session.ts, refreshToken() occasionally returns a token that fails validation immediately. I suspect a clock-skew issue in the exp comparison. Read that file plus src/auth/jwt.ts and tell me the single most likely root cause and the exact line. Be concise."
```

## Useful options

```
-s workspace-write   let Codex modify files (only when the user asked for that)
-m gpt-5-codex       model override
-r                   continue the previous codex session (follow-up question)
--timeout 1800       raise the 900s default for a big repo sweep
--raw                also print Codex's full event log to stderr, for debugging
```

Use `-r` for a genuine follow-up — it keeps Codex's own context and avoids paying
to re-read the repo:

```bash
codex-run -C /path/to/repo -r "Now show me the minimal patch for that."
```

## Rules

1. **Bash timeout ≥ 600000 ms** (10 min) — Codex explores the repo before answering.
2. **Report its answer as Codex's**, not as your own conclusion. Quote it, then add
   your own take separately if you disagree — the value here is having two
   independent opinions, and blending them destroys that.
3. **Sanity-check it.** Codex can confidently cite files or lines that don't exist.
   Verify any specific claim against the repo before acting on it.
4. **Read-only unless told otherwise.** Don't pass `-s workspace-write` on your own
   initiative.
5. Each call spends the user's ChatGPT plan quota. One question, one call.
