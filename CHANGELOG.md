# Changelog

## 1.1.1

Fixes found by running the real thing on a real machine rather than trusting the
blog posts.

- **`codex-imagegen` missed images saved to the default location.** Codex's
  built-in image tool writes to
  `$CODEX_HOME/generated_images/<session-id>/exec-<uuid>.png` — nested one level
  under a session directory. The fallback scan only looked at the top level, so it
  reported failure whenever Codex didn't honour the requested path. Now searches
  session subdirectories too.
- **Handles Codex's no-overwrite policy.** Codex's `imagegen` skill is instructed
  not to overwrite existing assets and to write a versioned sibling instead
  (`out-v2.png`). The wrapper now explicitly authorizes in-place replacement, and
  if Codex still versions the file, detects the sibling and reports its real path.
- **Validates PNG magic bytes** instead of just checking the file is non-empty, so
  a truncated or placeholder file is no longer reported as success.
- **Corrected size documentation.** Real constraints are: longest edge ≤ 3840px,
  both edges multiples of 16, ratio ≤ 3:1, total pixels 655,360–8,294,400. 4K
  (`3840x2160`) is properly supported, not "beta" as previously documented.
- **Corrected transparency guidance.** Replaces the ImageMagick advice with the
  `remove_chroma_key.py` helper Codex actually ships, and documents that true
  native transparency is available via Codex's CLI fallback with an
  `OPENAI_API_KEY` — presented as a user choice, not an automatic downgrade.
- Troubleshooting entries for the `base_instructions` models-cache warning and for
  unrelated MCP/hook noise in Codex output.

## 1.1.0

Turns the Codex side from a single "second opinion" agent into a proper delegation
layer, and adds image editing.

**New executable**

- `bin/codex-run` — shared wrapper for text tasks. Captures Codex's final message
  via `codex exec -o` instead of scraping the event log, so subagents receive a
  clean answer. Supports sandbox modes, model override, session resume (`-r`),
  JSON Schema-constrained output (`--schema`), stdin input, and timeouts.

**New subagents**

- `codex-reviewer` — reviews a diff, then verifies every finding against the real
  code and reports confirmed / rejected / unverified separately.
- `codex-debugger` — root-causes a failure and proposes a patch; verifies the causal
  chain before reporting. Read-only.
- `codex-implementer` — bulk mechanical edits in `workspace-write`. Requires user
  consent and a clean working tree; never commits; reviews its own diff and runs the
  verification command independently.

**New skills**

- `edit-image` — modify an existing image via `--ref` (change X keep Y, restyle,
  recolor, style-matched siblings). Never overwrites the source.
- `asset-set` — favicon / OG / app-icon / icon-family recipes with a shared style
  contract; derives size variants with ImageMagick instead of regenerating.
- `ask-codex` — one-off question to Codex, no subagent overhead.
- `codex-review` — send a diff or branch to Codex for review.
- `codex-delegate` — decision rubric for when delegating to Codex actually saves
  tokens, how to offer the split, and how to orchestrate and verify it.

**Changed**

- `codex-imagegen` gained `--ref` (up to 4 reference images, via `codex exec -i`),
  `--timeout`, and `--model`; exits `124` on timeout.
- `codex-artist` now derives a style contract from the project's real design tokens,
  generates an anchor asset for approval first, and resamples variants locally.
- `codex-second-opinion` uses `codex-run`, supports session resume, and reports
  Codex's answer separately from its own assessment.
- `generate-image` expanded with prompt structure, palette discovery, and size guidance.
- Both wrappers handle BSD and GNU `stat`, and missing `timeout`/`gtimeout`.
- README rewritten.

## 1.0.0

Initial release.

- `generate-image` skill and `codex-artist` subagent for gpt-image-2 generation
  through the Codex CLI's `$imagegen`.
- `codex-second-opinion` subagent for delegating coding questions to Codex.
- `bin/codex-imagegen` wrapper.
- Repo doubles as its own plugin marketplace.
