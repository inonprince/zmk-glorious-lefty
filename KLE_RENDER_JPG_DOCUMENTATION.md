# KLE JPG Renderer

This repo includes `kle_render_jpg.js`, a Node-based renderer that converts
Keyboard Layout Editor (KLE) JSON exports into `.jpg` files using the upstream
KLE rendering code.

## Installation

1. Clone KLE into `vendor/`:

```bash
git clone https://github.com/ijprest/keyboard-layout-editor.git vendor/keyboard-layout-editor
```

2. Install Node dependencies:

```bash
npm install
```

## Usage

Render one file:

```bash
node kle_render_jpg.js kle_layouts/function-layer-diagram.json
```

Render all JSON files in a directory:

```bash
node kle_render_jpg.js kle_layouts --out-dir out
```

Use KLE-style JPG export flow (html2canvas) instead of direct screenshot:

```bash
node kle_render_jpg.js kle_layouts --out-dir out --render-mode kle-jpg
```

If your KLE clone is not in `vendor/keyboard-layout-editor`, set it explicitly:

```bash
node kle_render_jpg.js kle_layouts --out-dir out --kle-root /path/to/keyboard-layout-editor
```

## Useful options

- `--quality <1-95>`: JPEG quality (default `92`)
- `--viewport <WIDTHxHEIGHT>`: browser viewport used for render
- `--wait <domcontentloaded|load|networkidle0|networkidle2>`: wait mode
- `--timeout <ms>`: page timeout (`0` disables)
- `--font-wait <ms>`: max time to wait for fonts
- `--render-mode <screenshot|kle-jpg>`: default clip-screenshot mode, or
  KLE-style html2canvas JPG export
