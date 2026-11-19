---
name: nanobanana
description: Guide for generating and editing images using generative AI with the nanobanana CLI
license: MIT
---

# Nanobanana

This is a guide for generating and editing images using the nanobanana CLI tool.

Nanobanana is a command-line interface for Nano Banana 2.1 (`gemini-nano-banana-2.1`), Google's Gemini image generation model. It is the only model the CLI supports, so there are no model flags.

## Installation

If the nanobanana CLI is not already installed, install it using:

```bash
go install maragu.dev/nanobanana@latest
```

## Prerequisites

The `GOOGLE_API_KEY` environment variable must be set, or a `.env` file with the key must be present in the working directory.

## Usage

```bash
nanobanana generate [flags] <output-path> <prompt>
```

Flags must come before the output path, and the prompt must be a single quoted argument. Any extra argument after the prompt (including a flag placed there) is a usage error. Run `nanobanana generate -h` for the full help text.

## Flags

- `-i <path>` -- Input image. Repeat for up to 14 images. Inputs can be PNG, JPEG, WebP, HEIC, or HEIF.
- `-aspect <ratio>` -- Aspect ratio: `1:1`, `1:4`, `1:8`, `2:3`, `3:2`, `3:4`, `4:1`, `4:3`, `4:5`, `5:4`, `8:1`, `9:16`, `16:9`, `21:9`. If not set, the model decides.
- `-size <size>` -- Image size: `1K`, `2K`, or `4K` (in any case). If not set, the model decides (currently 1K).

## Output format

The output format follows the extension of the output path: `.png` gives PNG, and `.jpg` or `.jpeg` gives JPEG. Pick the extension that matches what the user asked for.

## Generating images

```bash
nanobanana generate output.png "a beautiful sunset over mountains"
```

With a specific aspect ratio and size:

```bash
nanobanana generate -aspect 16:9 -size 4K wallpaper.jpg "a misty pine forest at dawn"
```

## Editing existing images

To edit or modify an existing image using a text prompt:

```bash
nanobanana generate -i input.png output.jpg "make the sky purple and add stars"
```

## Combining several images

Pass `-i` multiple times (up to 14). Refer to the images by their order in the prompt:

```bash
nanobanana generate -i hat.png -i banana.jpg output.png "put the hat from the first image on the banana in the second"
```

## Tips for effective prompts

- Be specific and descriptive about what you want in the image
- Include details about style, colors, mood, composition, and subject matter
- For edits, clearly describe what should change while the rest remains the same
- When combining images, say which image contributes what ("the first image", "the second image")
- You can reference art styles, artists, or specific visual aesthetics

## Examples

Generate a square logo:
```bash
nanobanana generate -aspect 1:1 -size 2K logo.png "minimalist tech company logo with geometric shapes in blue and white"
```

Create concept art:
```bash
nanobanana generate -aspect 21:9 concept.jpg "futuristic city skyline at night with neon lights and flying vehicles, cyberpunk style"
```

Edit an existing photo:
```bash
nanobanana generate -i photo.png enhanced.jpg "enhance the colors and make it look like golden hour"
```
