# Niri Focus Arrows

A Noctalia Bar Widget plugin for navigating Niri columns using mouse input.

## What It Does

This widget sends Niri IPC actions:

- Left: `niri msg action focus-column-left`
- Right: `niri msg action focus-column-right`

When wrap mode is enabled, it uses:

- Left wrap: `focus-column-left-or-last`
- Right wrap: `focus-column-right-or-first`

## Controls

### Split Mode (`combineButtons = false`)

- Left arrow click: focus left column
- Right arrow click: focus right column
- Mouse wheel on widget: focus left/right
- Right click on widget: open context menu (Widget settings)

### Combined Mode (`combineButtons = true`)

- Left click: focus left column
- Right click: focus right column
- Middle click: open context menu (Widget settings)
- Mouse wheel on widget: focus left/right

## Settings

Available in plugin settings UI:

1. `Reverse scroll direction`
2. `Wrap around columns`
3. `Icon color` (Noctalia theme color keys)
4. `Combine buttons`
5. `Compact mode` (make gaps smaller in not combined mode)
6. `Hide tooltip`

Defaults are defined in `manifest.json` under `metadata.defaultSettings`.

## Installation

1. Install or load this repository as a custom Noctalia plugin source.
2. Enable `Niri Focus Arrows`.
3. Add the bar widget to your desired bar section.

## Requirements

- Noctalia Shell `>= 4.1.2`
- Niri installed and reachable from shell (`niri` in `PATH`)
