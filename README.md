<div align="center">

# codex-bridge

**Give Claude Code image generation and a team of GPT-5 subagents — using the Codex CLI login you already have.**

[![Claude Code plugin](https://img.shields.io/badge/Claude%20Code-plugin-D97757)](https://code.claude.com/docs/en/plugins)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![No API key required](https://img.shields.io/badge/OpenAI%20API%20key-not%20required-brightgreen)](#why-no-api-key)

</div>

Claude Code can't generate images, and everything it does runs on your Claude quota. The Codex CLI can generate images with **gpt-image-2**, and runs on your **ChatGPT plan** — a completely separate budget. This plugin bridges the two.

Two things you get:

**1. Claude can produce images.** Ask for an icon, a mockup, a hero image, a full favicon set — Claude writes the prompt, drives gpt-image-2 through Codex, then *looks at the result* and regenerates if it missed.

**2. Claude can delegate to GPT-5.** Four Codex-powered subagents handle review, debugging, bulk implementation, and image work. Claude stays the orchestrator: it scopes the task, Codex does the volume, Claude verifies the result. Heavy work runs on your ChatGPT quota and its intermediate output never enters your Claude context.

<a id="why-no-api-key"></a>
> **No OpenAI API key.** Everything routes through `codex login`, so it bills against your ChatGPT plan rather than API credits.

## Contents

- [Install](#install) · [Quickstart](#quickstart) · [What's inside](#whats-inside)
- [Feature 1 — images](#feature-1--images) · [Feature 2 — GPT-5 subagents](#feature-2--gpt-5-subagents)
- [How it works](#how-it-works) · [Limitations](#limitations) · [Troubleshooting](#troubleshooting)

## Install

**Prerequisites**

| | |
| :-- | :-- |
| Codex CLI | `npm i -g @openai/codex` or `brew install codex` |
| Logged in | `codex login` → verify with `codex login status` (should say *Logged in using ChatGPT*) |
| ChatGPT plan | Plus, Pro, or Team |
| Claude Code | any current version |

**Then:**

```
/plugin marketplace add Sateezg/codex-bridge
/plugin install codex-bridge@codex-bridge
```

Run `/reload-plugins` if Claude Code asks you to.

<details>
<summary>Other install methods</summary>

Try it for one session, no install:

```bash
git clone https://github.com/Sateezg/codex-bridge.git
claude --plugin-dir ./codex-bridge
```

Auto-load from your skills directory:

```bash
git clone https://github.com/Sateezg/codex-bridge.git ~/.claude/skills/codex-bridge
chmod +x ~/.claude/skills/codex-bridge/bin/*
```

Loads as `codex-bridge@skills-dir` on your next session.

</details>

## Quickstart

Nothing to configure. Just ask in plain language:

```
generate a hero image for the landing page, save it in assets/
make the sky in assets/hero.png sunset orange, keep everything else
set up favicons and an OG card for this project
review my changes before I commit
ask codex why this test only fails under --parallel
rename useSession to useAuthSession across the whole repo
```

The last one is the interesting case. Claude notices it's mechanical work across many files and offers the split before starting:

> This touches 34 files with the same change. I can hand the edits to Codex — runs on your ChatGPT quota and keeps 34 file dumps out of this context — then review its diff here. Want me to?

## What's inside

**Skills** — Claude picks these up automatically; you can also call them as `/codex-bridge:<name>`.

| Skill | Fires when |
| :-- | :-- |
| `generate-image` | a task needs a new image that doesn't exist yet |
| `edit-image` | you point at an image file and ask to change or restyle it |
| `asset-set` | favicons, app icons, OG cards, or a matching icon family |
| `ask-codex` | you want GPT-5's take on one question about this repo |
| `codex-review` | "review my changes" — diff, branch, or module |
| `codex-delegate` | a task is big or repetitive enough that delegating saves you tokens |

**Subagents** — Claude launches these itself, or you can name them.

| Subagent | Does | Can write files? |
| :-- | :-- | :-- |
| `codex-artist` | images, icon sets, style-matched asset families | images only |
| `codex-reviewer` | review a diff, then verifies every finding against the code | no |
| `codex-debugger` | root-cause a failure, proposes a patch | no |
| `codex-implementer` | bulk mechanical edits and scaffolding | **yes** — after you agree |
| `codex-second-opinion` | general independent opinion on an approach | no |

**Executables** — on your `PATH` while the plugin is enabled, and usable straight from a shell.

| | |
| :-- | :-- |
| `codex-imagegen` | generate or edit an image; prints the output path |
| `codex-run` | run any task on Codex; prints only its final answer |

## Feature 1 — images

```bash
codex-imagegen "flat vector rocket icon, #2563EB on white, 2px stroke, minimal" ./rocket.png
codex-imagegen "change the sky to sunset orange, keep everything else identical" ./out.png --ref ./hero.png
codex-imagegen "settings gear, same style as the reference" ./settings.png --ref ./home.png
```

| Option | |
| :-- | :-- |
| `--size WxH` | `1024x1024`, `1536x1024`, `1024x1536`, `2048x2048`, `3840x2160`, … — see note below |
| `--ref <file>` | source or style reference, repeatable up to 4 — turns the call into an edit |
| `--model <name>` | model override |
| `--timeout <sec>` | default 600 |

A custom size is only accepted if all of these hold: longest edge ≤ 3840px, both edges multiples of 16, long-to-short ratio ≤ 3:1, total pixels between 655,360 and 8,294,400. Square is fastest. For anything outside that — favicons, a 1200×630 OG card — generate a large master and resample locally.

The wrapper prints the path it actually wrote. Codex is instructed not to overwrite existing assets, so it occasionally saves `out-v2.png`; the wrapper detects that (and the `~/.codex/generated_images/<session>/` default location) and reports the real path.

What makes this better than pasting prompts into a chat window: the skills teach Claude to pull your **actual palette** out of `tailwind.config.*` or your design tokens, to reuse one style contract across a whole set so the assets match, to derive size variants with ImageMagick instead of regenerating, and to **open the PNG and check it** before telling you it's done.

## Feature 2 — GPT-5 subagents

The point isn't "Claude can also call GPT-5". It's the division of labour: **Claude scopes and verifies, Codex does the volume.**

```
you ──▶ Claude          scopes the work, writes the brief, reviews the result
             │
             ▼
        codex-run ──▶ Codex CLI ──▶ GPT-5 / gpt-image-2
                                     (your ChatGPT quota)
```

Because Codex runs as a separate process, its intermediate output — the 40 files it read, the search results, the generated boilerplate — never enters your Claude context. You pay Claude tokens only for the brief and the review.

**What gets delegated**, per the `codex-delegate` rubric: mechanical edits across many files, bulk generation, exhaustive repo sweeps, all image work, and self-contained subtasks. **What doesn't:** architecture calls, ambiguous requirements, anything needing the conversation history, and small edits — round-tripping a two-line fix costs *more*, not less.

Every subagent follows the same contract: read-only by default, verify before reporting, and never claim success on unverified work. Only `codex-implementer` writes to your files, only after you've agreed, and only with a clean working tree so its changes land as a reviewable diff.

Straight from a shell:

```bash
codex-run -C . "which module owns rate limiting? name the file"
codex-run -C . -r "now show me the minimal patch"          # -r continues the session
git diff main...HEAD | codex-run -C . --timeout 1200 -      # pipe a diff in
```

| Option | |
| :-- | :-- |
| `-C, --cd <dir>` | working directory (default: cwd) |
| `-s, --sandbox <mode>` | `read-only` (default), `workspace-write`, `danger-full-access` |
| `-m, --model <name>` | e.g. `gpt-5-codex` |
| `-r, --resume` | continue the previous session instead of starting fresh |
| `--schema <file>` | constrain the answer to a JSON Schema |
| `--raw` | also dump Codex's event log to stderr |
| `--timeout <sec>` | default 900 |

## How it works

Both wrappers shell out to `codex exec`, Codex's non-interactive mode.

**Images** run in a `workspace-write` sandbox scoped to the output directory:

```bash
codex exec -C <outdir> -s workspace-write --skip-git-repo-check [-i <ref>...] \
  "Use the \$imagegen image generation tool to ... save to ./<file>.png ..."
```

`$imagegen` is Codex's built-in image skill; it calls gpt-image-2 with your ChatGPT credentials and writes the PNG into the working directory. The wrapper verifies the file landed — falling back to `$CODEX_HOME/generated_images/` if Codex saved it there instead — and prints the absolute path so Claude can read the image back.

**Text tasks** capture the final message with `-o` instead of scraping the event log, so subagents get a clean answer rather than a transcript:

```bash
codex exec -C <dir> -s read-only --skip-git-repo-check -o <tmpfile> "<task>"
```

Both fail fast and loudly: a missing `codex` binary or a logged-out session exits `1` with an actionable message rather than hanging. Timeouts exit `124`. Both handle BSD and GNU `stat`, and degrade gracefully when `timeout`/`gtimeout` isn't installed.

## Limitations

- **Quota, not free.** Image turns burn ChatGPT plan quota roughly 3–5× faster than text turns. Set `OPENAI_API_KEY` and Codex switches to API billing instead.
- **Transparency takes two steps.** The default path can't emit alpha, so the skills generate on a flat `#00FF00` key and strip it with the `remove_chroma_key.py` helper Codex already ships. True native transparency needs Codex's CLI fallback plus an `OPENAI_API_KEY`; the skills surface that as a choice rather than switching silently.
- **Slow.** 1–4 minutes per image; a repo-wide Codex task can take 10+ minutes. Skills set long Bash timeouts accordingly.
- **Codex is blind to your conversation.** Every brief has to stand alone. This is exactly why the subagents verify before reporting.
- **macOS and Linux.** Not tested on Windows.

## Troubleshooting

| Symptom | Fix |
| :-- | :-- |
| `codex CLI not found on PATH` | install Codex CLI, then reopen your shell |
| `codex is not logged in` | run `codex login`; confirm with `codex login status` |
| `Operation not permitted` from codex | ownership on `~/.codex` — `sudo chown -R $(whoami) ~/.codex` |
| Got `out-v2.png` instead of `out.png` | expected — Codex won't overwrite; use the path the wrapper printed |
| Image lands somewhere unexpected | the wrapper also checks `$CODEX_HOME/generated_images/<session>/`; pass an absolute output path |
| `failed to load models cache: missing field base_instructions` | harmless Codex cache warning; clear it with `rm -rf ~/.codex/cache` if it persists |
| Codex output full of MCP/hook errors | your Codex config, not this plugin — the wrapper ignores them. Prune unused MCP servers in `~/.codex/config.toml` to speed runs up |
| Skills don't show up | `/reload-plugins`, then `/help` → Custom commands |
| Wrapper "permission denied" | `chmod +x ~/.claude/skills/codex-bridge/bin/*` |
| Everything times out | raise `--timeout`; check `codex exec -C . -s read-only "say hi"` works standalone |

## Contributing

Issues and PRs welcome.

```bash
claude plugin validate .
bash -n bin/codex-imagegen && bash -n bin/codex-run
```

## Credits

- [openai/codex](https://github.com/openai/codex) — the Codex CLI and its `$imagegen` skill
- [oakplank/gpt-image-bridge](https://github.com/oakplank/gpt-image-bridge) — the original codex-CLI image bridge idea
- [Codex CLI image generation write-up](https://codex.danielvaughan.com/2026/04/27/codex-cli-image-generation-gpt-image-2-visual-development-workflows/)

## License

MIT — see [LICENSE](LICENSE).
