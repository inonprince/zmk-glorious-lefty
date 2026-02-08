# KLE Update Script Documentation

This document explains how the KLE update scripts work:
- `/Users/inon/Downloads/glove80layout-try2/update_kle_layouts.py` (diffs JSON exports)
- `/Users/inon/Downloads/glove80layout-try2/update_kle_from_keymap.py` (diffs ZMK `.keymap` files)

It is intended to be a living reference for future updates.

**Overview**
- Both scripts compare an old (reference) keymap to a new (working copy).
- They update KLE layout files in `/Users/inon/Downloads/glove80layout-try2/kle_layout-unmodified-reference`.
- They write updated KLE files to `/Users/inon/Downloads/glove80layout-try2/kle_layouts`.
- They preserve physical geometry and move full key content (label + style) when a key moves.

**Inputs**
- JSON mode (`update_kle_layouts.py`):
  - `/Users/inon/Downloads/glove80layout-try2/Glorious Engrammer v42-rc9 (unmodified-reference).json`
  - `/Users/inon/Downloads/glove80layout-try2/Glorious Engrammer v42-rc9 (working-copy).json`
- Keymap mode (`update_kle_from_keymap.py`):
  - `/Users/inon/Downloads/glove80layout-try2/Glorious Engrammer v42-rc9 (unmodified-reference).keymap`
  - `/Users/inon/Downloads/glove80layout-try2/Glorious Engrammer v42-rc9 (working-copy).keymap`
- KLE files:
  - `/Users/inon/Downloads/glove80layout-try2/kle_layout-unmodified-reference/*.json`

**Outputs**
- `/Users/inon/Downloads/glove80layout-try2/kle_layouts/*.json`

**How KLE JSON Is Parsed**
- Each KLE file is a JSON array.
- Non-list elements are treated as metadata and preserved as-is.
- Each list element represents a row and includes:
  - dictionaries that update state (position, rotation, style)
  - string items that represent key legends
- Parsing keeps a cursor state with:
  - geometry: `x`, `y`, `w`, `h`, `x2`, `y2`, `w2`, `h2`, `r`, `rx`, `ry`
  - style: persistent style and one-shot style
- Style handling:
  - `NON_STICKY_STYLE_KEYS = {"d", "n", "l", "i"}` are one-shot per key and reset after each legend.
  - Other style keys persist until changed, per the KLE format.

**How KLE JSON Is Serialized**
- Geometry is preserved exactly by reconstructing per-key deltas (`x`, `y`, `w`, `h`, `x2`, `y2`, `w2`, `h2`) and rotation blocks.
- Style for each key is emitted as explicit properties on that key (no reliance on prior persistent style during serialization).
- This ensures moved key content (label + style) is applied to the correct physical location.

**Keymap Structure Assumptions (JSON mode)**
- The keymap JSON has:
  - `layer_names`: list of layer names
  - `layers`: list of layer arrays (each with 80 key slots)
- Each slot is an object like:
  - `{"value":"&trans"}` or `{"value":"&none"}`
  - `{"value":"&kp","params":[{"value":"A"}]}`
  - `{"value":"Custom","params":[{"value":"&thumb LAYER_Function ESC"}]}`

**Layer Name Mapping From Filenames**
- Base layers:
  - `base-layer-diagram.json` maps to `Dvorak` if present, else the first layer name.
  - `base-layer-diagram-<Name>.json` maps to `<Name>` (case-insensitive).
- Other layers:
  - `<name>-layer-diagram.json` maps to `<name>` by normalized comparison (lowercase, `_` -> `-`).
- If a layer cannot be mapped, the file is skipped.

**Physical Index Mapping**
- The script maps KLE keys to keymap indices (0–79) using geometry.
- Main matrix (non-rotated keys):
  - Rows are determined by `floor(y)`.
  - Columns are determined by fixed X anchors:
    - Left: `x = 1,2,3,4,5,6`
    - Right: `x = 14.25,15.25,16.25,17.25,18.25,19.25`
  - Indices are taken from `ROW_MAP` in the script.
- Thumbs (rotated keys):
  - Keys are grouped by side and rotation:
    - Side is `L` for positive rotation, `R` for negative rotation.
    - Rotation buckets: `25`, `35`, `45` (rounded).
  - The script expects **two non-label keys** per group and assigns them as top/bottom by `y`.
  - Index mapping is defined in `THUMB_INDICES`.
  - Labels `T1`..`T6` are ignored for mapping and are treated as placeholders.
  - Empty legends are **not** ignored; they are treated as real keys.

**Keymap Structure Assumptions (ZMK .keymap mode)**
- The script finds `keymap { ... }` and then each `layer_<Name> { ... }`.
- It extracts `bindings = < ... >;` and tokenizes by whitespace.
- Each binding is stored as a list of tokens (e.g., `["&kp", "A"]`).
- Binding signatures are the exact token sequence joined by spaces.

**Move Detection And Content Reuse**
- Each key slot is reduced to a stable signature via JSON stringification.
- The script pairs old and new positions by matching signatures in order.
- If a new position is paired with a different old position, the key is treated as moved.
- For moves, the full key content is copied:
  - legend text
  - style dictionary

For `.keymap` mode, the signature is the exact token list (whitespace normalized).

**Global Content Fallback**
- The script builds a global map from signature -> content across all reference KLE files.
- If a key has no move source in the current layout, but exists elsewhere with the same signature, that content is reused.

**Label Generation For New Keys**
- `&kp` labels:
  - Uses a map from keycodes to labels derived from existing KLE content.
  - Falls back to a small built-in map (`ESC`, `RET`, `BSPC`, `DEL`, `SPACE`, `TAB`, etc.).
- `Custom` expressions:
  - Supports `&thumb` and `&space` by producing `Key\n\n\n\nLayer`.
  - Includes cursor-layer shortcut text for `&kp _C(X)` patterns (`Select all`, `Save`, etc.).
- `&none` => empty label.

**Summary Output**
- The script prints a summary per file:
  - `updated`: number of key positions updated
  - `moved`: how many positions received moved content
  - `reused`: how many positions reused content (including moves)
  - `from_global`: how many positions reused global content
  - `generated`: how many positions required new labels
  - `missing_in_kle`: 80 minus the number of mapped keys
  - `warnings`: thumb-group anomalies (expected 2 keys but found different count)

**Known Limitations**
- Duplicate signatures are paired in list order, which may not always match the intended move in rare cases.
- Any layer with a filename that cannot be mapped to `layer_names` is skipped.
- KLE style semantics are complex; some KLE properties not seen in these layouts may not be handled.

**Flags**
Both scripts accept the same normalized flags:
- `--old-keymap`
- `--new-keymap`
- `--kle-in`
- `--kle-out`

Deprecated aliases (still supported):
- `--old` (same as `--old-keymap`)
- `--new` (same as `--new-keymap`)

**Usage**
```bash
python3 /Users/inon/Downloads/glove80layout-try2/update_kle_layouts.py
```

```bash
python3 /Users/inon/Downloads/glove80layout-try2/update_kle_from_keymap.py
```
