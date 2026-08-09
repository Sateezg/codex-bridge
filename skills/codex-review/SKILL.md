---
description: Get an independent code review from OpenAI Codex (GPT-5) on uncommitted changes, a branch diff, a PR, or a specific module — returns findings grouped by severity with file:line references. Use when the user says "review this", "review my changes", "check this PR", "what did I miss", or before they commit or merge something substantial.
---

# Code review by Codex

An independent reviewer that hasn't seen this conversation is genuinely useful:
it won't inherit your assumptions about the change. Use it as a *second* pass, not
a replacement for your own read.

## Pick the scope

```bash
git -C <repo> diff                      # uncommitted, unstaged
git -C <repo> diff --staged             # staged
git -C <repo> diff main...HEAD          # whole branch vs main
git -C <repo> diff --stat main...HEAD   # size check first
```

Check the size before sending. Under ~1500 changed lines, pipe the diff in
directly. Larger than that, point Codex at the files instead and let it read
selectively — a giant pasted diff degrades the review.

## Run it

Small or medium change — pipe the diff as the prompt body:

```bash
{ echo "Review this diff as a senior engineer on this codebase. Report findings grouped by severity (Critical / Major / Minor / Nit). For each: file:line, what's wrong, and the concrete fix. Focus on correctness, security, error handling, race conditions, and missed edge cases. Skip style unless it hides a bug. If you find nothing at a severity level, say so rather than inventing findings."; echo; git -C <repo> diff main...HEAD; } | codex-run -C <repo> --timeout 1200 -
```

Large change or a whole module — let Codex read the tree itself:

```bash
codex-run -C <repo> --timeout 1800 \
  "Review the changes on this branch versus main (run git diff main...HEAD yourself, and read the surrounding files for context). Report findings grouped by severity (Critical/Major/Minor/Nit) with file:line and a concrete fix for each. Prioritise correctness, security, error handling, and missed edge cases."
```

Both run read-only — Codex cannot modify the working tree.

## Handling the results

1. **Verify each finding before repeating it.** Open the cited file:line. Codex
   reviews without conversation context and will sometimes flag intentional
   behaviour, or cite a line that doesn't say what it claims. A review that
   forwards false positives is worse than no review.
2. **Present it as three groups**: confirmed findings (with your verification),
   findings you checked and disagree with (say why), and anything you couldn't
   verify.
3. **Don't auto-fix.** Show the user the findings and let them choose. If they ask
   for fixes, apply them yourself — you have the conversation context.
4. Attribute clearly: these are Codex's findings, and your assessment of them.

## Rules

- Bash timeout ≥ 1200000 ms (20 min) for anything branch-sized.
- Never pass `-s workspace-write` for a review.
- Ask the user to commit or stash unrelated work first, so the diff is clean.
- One review call per scope; spends the user's ChatGPT plan quota.

For a review that also needs follow-up investigation across the repo, use the
`codex-reviewer` subagent instead so the exploration stays out of this context.
