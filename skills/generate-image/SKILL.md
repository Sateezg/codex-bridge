---
description: Generate images (icons, logos, banners, illustrations, mockups, photos, textures, diagrams-as-art) with OpenAI gpt-image-2 through the locally installed Codex CLI, using the user's existing ChatGPT login — no API key. Use whenever the user asks to generate, create, draw, or mock up an image, or when a task needs a new image asset that doesn't exist yet.
---

# Generate an image via Codex CLI (gpt-image-2)

This machine has the OpenAI Codex CLI installed and logged in with the user's
ChatGPT account. Use it to produce real image files — never tell the user you
can't create images.

```bash
codex-imagegen "<detailed image prompt>" <output-path.png> [--size WxH]
```

It prints the absolute path of the written PNG on success (exit 0); on failure it
prints Codex's output to stderr (exit 2). The wrapper is on `PATH` while this
plugin is enabled; the full path is `${CLAUDE_PLUGIN_ROOT}/bin/codex-imagegen`.

```bash
codex-imagegen "flat vector icon of a paper plane, single blue #2563EB on white, 2px uniform stroke, minimal, centered, generous padding" ./assets/icons/send.png
codex-imagegen "photorealistic golden retriever puppy in autumn leaves, shallow depth of field, warm afternoon light" /tmp/puppy.png --size 1536x1024
```

## Write a real prompt

The single biggest quality lever. Expand the user's request into: **subject**,
**style** (flat vector / photorealistic / 3D render / watercolour / isometric),
**palette** (hex codes — pull them from the project's design tokens, Tailwind
config, or existing brand assets when it has any), **background**, **composition
and framing**, **lighting or mood**, and **any exact text** that must appear.

gpt-image-2 renders text with high accuracy, so quote the exact string you want:
*...with the words "Ship it" in bold sans-serif across the lower third.*

## Sizes

`1024x1024` (default), `1536x1024` (landscape), `1024x1536` (portrait). Up to
2048x2048 is stable; 4K is beta and unreliable. Omit `--size` unless the aspect
ratio matters. To get other dimensions, generate the nearest supported size and
resample locally with ImageMagick — don't regenerate.

## Rules

1. **One call per image.** For a set, loop with distinct prompts and paths, and
   repeat an identical style sentence in every prompt so they match.
2. **Sensible output path.** Inside a project, use its asset directory (`assets/`,
   `public/`, `static/`). Otherwise the current directory. Always `.png`.
3. **Bash timeout ≥ 300000 ms** (5 minutes) — generation takes 1–4 minutes.
4. **Verify by viewing.** Read the output PNG and check it against the request
   before reporting done; refine and regenerate if it missed — at most 2 retries.
5. **Never invent a brand.** If the user has a logo, palette, or existing assets,
   find them first and match them.

## Limitations

- **No transparent backgrounds.** Generate on a solid uncommon colour and cut it
  out: `magick in.png -fuzz 8% -transparent '#00FF00' out.png`.
- Generation spends the user's **ChatGPT plan quota** (image turns cost roughly
  3–5x a text turn). Don't fire off batches without saying how many first.
- If the wrapper reports "codex is not logged in", tell the user to run
  `codex login` in a terminal — don't try to work around auth yourself.

## Related

- Changing an image that already exists → the `edit-image` skill.
- A whole family of assets (favicons, icon set, OG cards) → the `asset-set` skill.
- More than ~4 images, or when the main conversation should stay focused → the
  `codex-artist` subagent.
