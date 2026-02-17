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
- Right click: configurable action
- Middle click: configurable action

### Combined Mode (`combineButtons = true`)

- Left click: focus left column
- Right click: focus right column
- Middle click: configurable action

## Installation

1. Install or load this repository as a custom Noctalia plugin source.
2. Enable `Niri Focus Arrows`.
3. Add the bar widget to your desired bar section.

## Requirements

- Noctalia Shell `>= 4.1.2`
- Niri installed and reachable from shell (`niri` in `PATH`)
