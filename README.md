# Glorious Lefty -- A ZMK Keymap for Left-Handed Mousers on Glove80

A customized [MoErgo Glove80](https://www.moergo.com/collections/glove80-702702) ZMK keymap based on [Sunaku's Glorious Engrammer v42-rc9](https://github.com/sunaku/glove80-keymaps), systematically mirrored for people who **mouse with their left hand**.

## Why "Lefty"?

Sunaku's Glorious Engrammer is a brilliantly designed keymap, but it assumes you mouse with your **right** hand. Its layer activations and content placement are optimized for a right-handed mousing workflow: when your right hand leaves the keyboard for the mouse, your left hand can still activate layers and access their content.

If you're a **left-handed mouser**, this breaks down. For example:

- In the original, the **Mouse layer** is activated by a right thumb key. But if your left hand is already on a physical mouse, you don't need the ZMK mouse layer -- and that right thumb key is wasted on a layer you'll never use while mousing.
- In the original, **Cursor** and **Number** layers are activated by the left thumb. But when your left hand is on the mouse, you can't reach those left thumb keys at all.

This keymap **mirrors the entire layout** -- both layer activations and layer content -- so that a left-handed mouser gets the same hybrid keyboard+mouse efficiency that right-handed mousers enjoy with the original.

### The Hybrid Workflow

The goal is maximum efficiency in **both** modes:

- **Both hands on keyboard**: All layers work with two-handed ergonomics, just mirrored from the original. Left hand has content, right hand has modifiers/editing (or vice versa depending on the layer). Same feel as Sunaku's, but flipped.
- **Left hand on mouse**: Your right hand stays on the keyboard with full access to the most useful layers (Cursor, Number) via right thumb keys. The layer content for these is now under the right hand's fingers, so you can navigate, type numbers, and edit one-handed.

## What Changed from Sunaku's v42-rc9

### 1. Full Left-Right Mirror of All Non-Alpha Layers

Every functional layer has its content mirrored across the split. What was under the left hand is now under the right, and vice versa:

| Layer | Original (Sunaku) | Lefty |
|-------|-------------------|-------|
| **Cursor** | Arrows/Home/End on right, editing on left | Arrows/Home/End on left, editing on right |
| **Number** | Numpad on right, editing on left | Numpad on left, editing on right |
| **Symbol** | Symbols on left, editing on right | Symbols on right, editing on left |
| **Function** | F-keys/media on right, editing on left | F-keys/media on left, editing on right |
| **System** | System controls mirrored | System controls mirrored |
| **Mouse** | Movement on right, clicks on left | Movement on left, clicks on right |
| **Mouse speed layers** | Same pattern | Same pattern mirrored |

The editing keys (Esc, Del, Ins, Tab, Space, Enter, Backspace) and home row mods always go on the **opposite** hand from the active content, preserving the same two-handed ergonomic balance -- just flipped.

### 2. Thumb Cluster Layer Reassignment

Thumb key layer activations are swapped between hands so the right hand can access the most useful layers when the left hand is on the mouse:

| Thumb Key | Original | Lefty |
|-----------|----------|-------|
| LH T1 (inner top) | Esc / Function | Delete / System |
| RH T1 (inner top) | Enter / System | Esc / Function |
| LH T4 (main) | Space / Cursor | Space / Symbol |
| RH T4 (main) | R / Symbol | Space / Cursor |
| LH T5 (lower) | Delete / Number | Tab / Mouse |
| RH T5 (lower) | Tab / Mouse | Enter / Number |

Key insight: **Cursor** and **Number** (the most useful one-handed layers) are now on the **right** thumb, accessible when the left hand is on the mouse. **Mouse** and **Symbol** move to the **left** thumb for when both hands are on the keyboard.

### 3. Combo Key Mirroring

All thumb key combos have been correspondingly swapped (left-hand combos become right-hand and vice versa) to stay consistent with the thumb reassignments.

### 4. Dvorak as Default Layer

The default base layer is **Dvorak** (layer 0) instead of Enthium. The full set of base layers is preserved: Dvorak, Enthium, Colemak, and QWERTY.

### 5. macOS as Target OS

`OPERATING_SYSTEM` is set to `'M'` (macOS). All OS-dependent shortcuts (cut/copy/paste, undo/redo, etc.) use Cmd-based bindings.

### 6. Cursor Layer: macOS Shortcuts

The cursor layer adds common macOS application shortcuts on the right edge column:

- `Cmd+A` (Select All), `Cmd+N` (New), `Cmd+S` (Save), `Cmd+W` (Close), `Cmd+Q` (Quit)
- F16-F19 keys for application-specific bindings (e.g. window management, IDE shortcuts)

### 7. Custom KVM Switch Behavior

A custom ZMK behavior (`behavior_kvm.c`) adds hardware KVM switching:

- **`&kvm_switch`**: Sends alternating `Ctrl Ctrl 1` / `Ctrl Ctrl 2` sequences to toggle between KVM targets
- **`&kvm_state_color`**: RGB LED indicator -- default color for target 1, red for target 2
- The KVM indicator key is placed in the top-left corner of every layer's LED color map
- The KVM switch action is available on the Number layer

### 8. LED Color Maps Mirrored

All per-layer RGB color maps are mirrored to match the layer content, so visual feedback correctly highlights the active hand.

## What Stayed the Same

All of Sunaku's core mechanics are preserved:

- **Home row mods** with bilateral enforcement
- **Sticky shift** modtaps
- **Typing layer** for gaming/rapid input without home row mods
- **World/Emoji layers** for Unicode and emoji input
- **Magic layer** for Bluetooth/RGB controls
- **Parentheses combo** on thumb keys
- All custom behaviors (thumb hold-tap, space bar, sticky keys, etc.)

## Layers Overview

| # | Layer | Purpose |
|---|-------|---------|
| 0 | Dvorak | Default base layer |
| 1 | Enthium | Alternative base (Sunaku's default) |
| 2 | Colemak | Alternative base |
| 3 | QWERTY | Alternative base |
| 4 | macOS | OS-specific overlay |
| 5 | Typing | No home row mods |
| 6-13 | Finger layers | Home row mod activations |
| 14 | Cursor | Navigation (arrows, home/end, pg up/dn) |
| 15 | Number | Numpad + hex digits |
| 16 | Function | F-keys + media controls |
| 17 | Emoji | Emoji input via Unicode |
| 18 | World | International characters |
| 19 | Symbol | Programming symbols |
| 20 | System | RGB, Bluetooth, system keys |
| 21-24 | Mouse | Mouse movement + speed layers |
| 25 | Gaming | Gaming overlay |
| 26 | Factory | Factory test layer |
| 27 | Lower | Shared modifier layer |
| 28-30 | macOS layers | macOS-specific overlays |
| 31 | Magic | Bluetooth profiles, RGB, layer toggles |

## Layer Diagrams

See [`kle_layouts/`](kle_layouts/) for KLE (Keyboard Layout Editor) JSON files and rendered JPG diagrams of every layer.

## Building

The firmware builds automatically via GitHub Actions on push. The workflow uses the standard ZMK build system:

```
board: [ "glove80_lh", "glove80_rh" ]
```

Built `.uf2` firmware files are stored in [`artifacts/`](artifacts/).

To build locally, follow the [ZMK development setup](https://zmk.dev/docs/development/setup).

## Project Structure

```
config/
  glove80.keymap          # The main keymap file (ZMK devicetree)
  west.yml                # ZMK west manifest
sunaku/
  *.keymap                # Unmodified Sunaku v42-rc9 reference
  kle-layouts-.../        # Original Sunaku KLE diagrams
kle_layouts/
  *.json                  # Modified KLE layout files
  *.jpg                   # Rendered layer diagrams
src/
  behavior_kvm.c          # Custom KVM switch behavior
dts/bindings/behaviors/
  zmk,behavior-kvm-switch.yaml
  zmk,behavior-kvm-state-color.yaml
artifacts/
  *.uf2                   # Pre-built firmware files
.github/workflows/
  build.yml               # GitHub Actions CI
```

## Credits

- [Sunaku's Glorious Engrammer](https://github.com/sunaku/glove80-keymaps) -- the foundation this keymap builds upon
- [MoErgo Glove80](https://www.moergo.com/) -- the keyboard hardware
- [ZMK Firmware](https://zmk.dev/) -- the firmware framework
