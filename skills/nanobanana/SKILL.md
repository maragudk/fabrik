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

## Generating images

To generate a single image:

```bash
nanobanana generate output.jpg "a beautiful sunset over mountains"
```

## Output format

The output is always JPEG. The output path must end in `.jpg` or `.jpeg` (in any case). Any other extension, such as `.png`, makes the CLI exit with an error before it calls the API. If the user asks for a PNG, generate a `.jpg` and convert it afterwards (for example with `sips -s format png output.jpg --out output.png` on macOS).

## Editing existing images

To edit or modify an existing image using a text prompt:

```bash
nanobanana generate -i input.png output.jpg "make the sky purple and add stars"
```

The input image can be in any format the API accepts, but the output is still JPEG.

## Tips for effective prompts

- Be specific and descriptive about what you want in the image
- Include details about style, colors, mood, composition, and subject matter
- For edits, clearly describe what should change while the rest remains the same
- You can reference art styles, artists, or specific visual aesthetics

## Examples

Generate a logo:
```bash
nanobanana generate logo.jpg "minimalist tech company logo with geometric shapes in blue and white"
```

Create concept art:
```bash
nanobanana generate concept.jpg "futuristic city skyline at night with neon lights and flying vehicles, cyberpunk style"
```

Edit an existing photo:
```bash
nanobanana generate -i photo.png enhanced.jpg "enhance the colors and make it look like golden hour"
```
