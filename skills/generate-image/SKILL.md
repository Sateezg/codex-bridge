---
description: Generate images (icons, logos, banners, illustrations, mockup assets, photos, textures) with OpenAI gpt-image-2 through the locally installed Codex CLI, using the user's existing ChatGPT login — no API key. Use whenever the user asks to generate, create, or draw an image, or when a task needs a new image asset.
---

# Generate an image via Codex CLI (gpt-image-2)

This machine has the OpenAI Codex CLI installed and logged in with the user's ChatGPT
account. Use it to generate images instead of saying you cannot create images.

## How to generate

Run the bundled wrapper (it is on PATH while this plugin is enabled; the full path is
`${CLAUDE_PLUGIN_ROOT}/bin/codex-imagegen`):

```bash
codex-imagegen "<detailed image prompt>" <output-path.png> [--size WxH]
```

Examples:

```bash
codex-imagegen "flat vector icon of a paper plane, single blue #2563EB on white, minimal, centered" ./assets/icons/send.png
codex-imagegen "photorealistic golden retriever puppy in autumn leaves, shallow depth of field" /tmp/puppy.png --size 1536x1024
```

The script prints the absolute path of the written image on success (exit 0). On
failure it prints Codex's output to stderr (exit 2).

## Rules

1. **Write a rich prompt.** Expand the user's request into a detailed description:
   subject, style (flat/vector/photo/3D), colors (hex codes when the project has a
   palette), background, composition, and any text that must appear in the image.
2. **One call per image.** For multiple images, loop with distinct prompts and paths.
3. **Pick a sensible output path.** Inside a project, save under the project's asset
   directory (e.g. `./assets/` or `./public/`). Otherwise use the current directory.
   Always use a `.png` extension.
4. **Use a generous Bash timeout** (at least 300000 ms / 5 minutes) — image generation
   through Codex regularly takes 1–4 minutes.
5. **Verify by viewing.** After generation, use the Read tool on the output PNG to
   confirm it matches the request; regenerate with a refined prompt if it doesn't.
6. **Sizes:** 1024x1024 (default), 1536x1024 (landscape), 1024x1536 (portrait). Up to
   2048x2048 is stable; 4K is beta. Omit `--size` unless the user needs a specific one.

## Limitations to keep in mind

- Transparent backgrounds are not supported by gpt-image-2. If a transparent asset is
  needed, generate on a solid uncommon color (e.g. `#00FF00`) and remove it with
  ImageMagick: `magick in.png -fuzz 8% -transparent '#00FF00' out.png`.
- Generation consumes the user's ChatGPT plan quota (image turns cost ~3–5x a text
  turn). Don't fire off large batches without asking.
- If the script reports "codex is not logged in", tell the user to run `codex login`
  in a terminal and retry — don't try to work around auth yourself.

## Delegation

For multi-image jobs (e.g. a full icon set) or when the main conversation should stay
focused, delegate to the `codex-artist` subagent, which knows this workflow.
