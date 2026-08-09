---
description: Generate a complete, style-consistent set of image assets for a web or app project in one pass — favicons, app icons, OG/social cards, hero images, empty-state illustrations, or a matching icon family. Use when the user asks for "icons for", "assets for", "favicon", "og image", "app icon", "a set of illustrations", or is setting up branding for a new project.
---

# Generate a consistent asset set

Individual images are the `generate-image` skill. This is for **families of assets
that must look like they came from the same designer** — which requires a shared
style contract, correct sizes, and correct filenames.

## Step 1 — lock the style contract

Before generating anything, write one style sentence you will paste verbatim into
every prompt in the set. It must pin down: art style, palette (hex codes), stroke
weight, corner treatment, background, and perspective. For example:

> Flat vector, 2px uniform stroke, palette #2563EB on #FFFFFF with #94A3B8
> accents, 4px rounded corners, centered, generous padding, no gradients, no
> shadows, front-on view.

Pull the palette from the project when one exists — check `tailwind.config.*`,
CSS custom properties, a design tokens file, or an existing logo. Ask the user only
if nothing is discoverable.

## Step 2 — generate

One call per asset, style sentence repeated in each:

```bash
codex-imagegen "<subject>. <style contract>" <path>.png --size <WxH>
```

Generate the **most important asset first** (the logo mark or the hero), show it to
the user, and only continue once they're happy. Regenerating a whole set after the
fact wastes their quota.

For assets that must match one already generated, pass it as a reference so the
model has the style in front of it, not just described:

```bash
codex-imagegen "a settings gear icon, same style as the reference" ./icons/settings.png --ref ./icons/home.png
```

## Step 3 — derive the size variants locally

**Do not regenerate for each size.** Generate one large master and resample it with
ImageMagick (or `sips` on macOS) — it's instant, free, and pixel-consistent:

```bash
magick master.png -resize 512x512 icon-512.png
magick master.png -define icon:auto-resize=16,32,48,64 favicon.ico
```

## Standard recipes

**Web favicon set** — master at 1024x1024, then derive `favicon.ico` (16/32/48),
`favicon-32x32.png`, `apple-touch-icon.png` (180x180), `icon-192.png`, `icon-512.png`.

**Social / OG card** — generate at 1536x1024, resample to 1200x630 (1200x630 isn't
directly generatable: 630 is not a multiple of 16). Leave the centre clear if a
title will be overlaid; ask whether text should be baked in — text renders
reliably, but baked text can't be localised later.

**iOS / Android app icon** — master at 1024x1024, no transparency, no rounded
corners (the OS masks them), subject centred with ~10% safe margin.

**Icon family** — all at 1024x1024 with the identical style sentence, downscaled to
the size the UI actually uses.

**Empty states / illustrations** — 1536x1024, same palette as the product, generous
whitespace so copy can sit alongside.

## Rules

1. **Verify visually.** Read every generated PNG and check the set actually looks
   coherent side by side — not just each image on its own.
2. **Name and place files conventionally**: `public/` or `assets/` for web,
   kebab-case, size in the filename where a variant exists.
3. **Budget honestly.** A full favicon + OG + icon-family run is 8–12 generations
   and spends real ChatGPT quota. Say the expected count before you start and let
   the user trim the list.
4. Use a Bash timeout of at least 300000 ms per generation.
5. **Only certain sizes are generatable**: longest edge ≤ 3840, both edges
   multiples of 16, ratio ≤ 3:1, total pixels 655,360–8,294,400. Every standard
   icon size (16, 32, 180, 192, 512) is below that floor — which is exactly why
   you generate one large master and resample.
6. **Use the path the wrapper prints.** Codex avoids overwriting existing files and
   may write a versioned sibling (`icon-v2.png`); the wrapper detects that and
   reports the real path.

For sets larger than about four images, hand the whole brief to the `codex-artist`
subagent so the generation loop stays out of the main conversation.
