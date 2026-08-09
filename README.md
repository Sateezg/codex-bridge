# codex-bridge

A [Claude Code](https://claude.com/claude-code) plugin that lets Claude use your **existing Codex CLI (ChatGPT) login** — no OpenAI API key — for two things:

1. **Image generation** — Claude produces real image files (icons, logos, banners, illustrations, photos) with OpenAI **gpt-image-2**, by driving the Codex CLI's built-in `$imagegen` skill. It triggers automatically whenever a task needs an image, and there's a `codex-artist` subagent for bigger jobs.
2. **Second opinions** — a `codex-second-opinion` subagent that hands any coding question, review, or debugging task to Codex (GPT-5 family) and reports back its answer.

Both run on your ChatGPT plan quota rather than API billing.

## Prerequisites

- **Codex CLI** installed: `npm i -g @openai/codex` (or `brew install codex`)
- **Logged in with a ChatGPT plan** (Plus / Pro / Team): run `codex login`, then verify with `codex login status` → should say `Logged in using ChatGPT`
- **Claude Code** installed

## Install

```bash
/plugin marketplace add Sateezg/codex-bridge
/plugin install codex-bridge@codex-bridge
```

Then run `/reload-plugins` if Claude Code asks you to.

<details>
<summary>Other install methods</summary>

**Try it for one session, without installing:**

```bash
git clone https://github.com/Sateezg/codex-bridge.git
claude --plugin-dir ./codex-bridge
```

**Auto-load from your skills directory:**

```bash
git clone https://github.com/Sateezg/codex-bridge.git ~/.claude/skills/codex-bridge
chmod +x ~/.claude/skills/codex-bridge/bin/codex-imagegen
```

It loads as `codex-bridge@skills-dir` on your next session.

</details>

## Usage

Ask for an image in plain language — the `generate-image` skill triggers on its own:

> generate a hero image for the landing page and save it in assets/

Invoke the skill explicitly:

```
/codex-bridge:generate-image a flat blue rocket icon → assets/rocket.png
```

Delegate a batch to the subagent:

> use codex-artist to generate the 6 sidebar icons in a consistent flat style

Get a cross-check from Codex:

> ask codex-second-opinion to review the auth changes in src/auth/

You can also run the wrapper directly from a shell:

```bash
codex-imagegen "flat vector icon of a rocket, blue #2563EB, minimal, centered" ./rocket.png --size 1024x1024
```

## What's inside

| Component | Type | What it does |
| :-- | :-- | :-- |
| `generate-image` | Skill | Auto-triggers when Claude needs an image; teaches it prompt structure, sizes, and the transparency workaround |
| `codex-artist` | Subagent | Batch image jobs — writes rich prompts, generates, visually verifies each PNG, retries misses |
| `codex-second-opinion` | Subagent | Sends a task to Codex via `codex exec` (read-only sandbox by default) and reports its answer |
| `codex-imagegen` | Executable | Bash wrapper on `PATH` while the plugin is enabled |

## How it works

The wrapper (`bin/codex-imagegen`) runs:

```bash
codex exec -C <output-dir> -s workspace-write --skip-git-repo-check \
  "Use the \$imagegen image generation tool to generate ... save to ./<file>.png ..."
```

Codex's built-in `$imagegen` skill calls gpt-image-2 with your ChatGPT credentials and writes the PNG into the working directory. The wrapper then verifies the file landed — falling back to `$CODEX_HOME/generated_images/` if Codex saved it there instead — and prints the final absolute path so Claude can read the image back.

It fails loudly and early: missing `codex` binary or a logged-out session exits `1` with a clear message rather than hanging.

## Notes & limitations

- Image turns consume your **ChatGPT plan quota** roughly 3–5× faster than text turns. For heavy batch use, set `OPENAI_API_KEY` in your environment and Codex switches to API billing instead.
- gpt-image-2 does **not** support transparent backgrounds. The skill knows the workaround: generate on solid `#00FF00`, then `magick in.png -fuzz 8% -transparent '#00FF00' out.png`.
- Sizes: `1024x1024` (default), `1536x1024` (landscape), `1024x1536` (portrait). Up to 2048×2048 is stable; 4K is beta.
- Generation typically takes 1–4 minutes per image, so the skill instructs Claude to use a ≥5 minute Bash timeout.
- macOS and Linux. The wrapper handles both BSD and GNU `stat`.

## Structure

```
codex-bridge/
├── .claude-plugin/
│   ├── plugin.json                 # plugin manifest
│   └── marketplace.json            # lets this repo serve as its own marketplace
├── bin/codex-imagegen              # bash wrapper around `codex exec` + $imagegen
├── skills/generate-image/SKILL.md  # auto-invoked image generation skill
├── agents/codex-artist.md          # image-generation subagent
├── agents/codex-second-opinion.md  # delegate coding tasks/reviews to Codex
├── LICENSE
└── README.md
```

## Contributing

Issues and PRs welcome. Before opening a PR, run:

```bash
claude plugin validate .
bash -n bin/codex-imagegen
```

## Credits / prior art

- [openai/codex](https://github.com/openai/codex) — the Codex CLI and its `$imagegen` skill
- [oakplank/gpt-image-bridge](https://github.com/oakplank/gpt-image-bridge) — the original codex-CLI image bridge idea
- [Codex CLI image generation write-up](https://codex.danielvaughan.com/2026/04/27/codex-cli-image-generation-gpt-image-2-visual-development-workflows/)

## License

MIT — see [LICENSE](LICENSE).
