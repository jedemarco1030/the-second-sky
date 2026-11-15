# The Second Sky

An original single-player retro 2D JRPG, built as a native **Godot 4** project in
typed GDScript with the **Compatibility** renderer. No plugins, no downloads, no
network access — everything the game needs is in this repository.

This first pass is a ~30-second exploration scene, **The Harbor Walk**: Mira starts
at the top of a harbor staircase, walks down to the waterfront, and talks to Nell,
whose radio is picking up a distress call from Gull Point Light.

## Requirements

- macOS 11 (Big Sur) or later, Apple Silicon or Intel
- **Godot 4.7.2-stable**, standard build (not the .NET / C# build)
- Git
- Optional: a gamepad (Xbox, PlayStation, or Switch Pro controller)

The project was created and validated with Godot 4.7.2-stable. Any later 4.x
release should open it; older 4.x versions are not supported.

## Setup on macOS

### 1. Install Godot 4.7.2

Option A, direct download:

1. Go to <https://godotengine.org/download/archive/4.7.2-stable/>.
2. Download **Godot Engine – macOS** (the standard build, a `.zip` with `Godot.app`).
3. Unzip it and drag `Godot.app` into `/Applications`.
4. The first time, right-click `Godot.app`, choose **Open**, then **Open** again to
   get past Gatekeeper.

Option B, Homebrew:

```bash
brew install --cask godot
```

Check the version by opening Godot: the version string appears in the
Project Manager title bar. From Terminal:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --version
# 4.7.2.stable.official.ed1daf0bf
```

### 2. Clone the repository

```bash
cd ~/Projects            # or wherever you keep code
git clone <your-repo-url> the-second-sky
cd the-second-sky
```

### 3. Import `project.godot`

1. Open **Godot.app**. The Project Manager appears.
2. Click **Import** (top left).
3. Browse to the cloned folder and select **`project.godot`** at its root.
4. Click **Open**, then **Import & Edit**.

On the first import Godot creates a `.godot/` cache folder and imports the PNGs in
`art/`. That folder is ignored by Git.

### 4. Run it

Press **F5** (or **fn + F5** on a MacBook keyboard, or click the ▶ **Run Project**
button in the top right). The main scene is already set to
`res://scenes/harbor.tscn`, so the game starts right away in a 1280 × 720 window
(a 640 × 360 pixel-art view scaled 2×).

## Controls

| Action           | Keyboard             | Gamepad              |
| ---------------- | -------------------- | -------------------- |
| Move             | WASD or arrow keys   | Left stick or D-pad  |
| Talk / next line | E or Enter           | A (Cross on PS)      |
| Close dialogue   | Esc or Backspace     | B (Circle on PS)     |

On-screen prompts switch between keyboard and gamepad labels automatically,
depending on what you used last.

## Manual test checklist

Run the game with F5 and check each item.

**Movement**
- [ ] Mira starts at the top of the staircase, under the title card.
- [ ] WASD and the arrow keys each move her in all four directions, including
      diagonally; her walk animation faces the direction she moves.
- [ ] Walk down both flights of stairs to the waterfront. The objective
      (top left) changes to "Find Nell by the pier."

**Collision**
- [ ] Walk into building walls, crates, lamp posts, and the railings beside
      the stairs — Mira stops and never overlaps them.
- [ ] Walk south along the waterfront — the pier railing stops her before
      the water.
- [ ] Walk straight into Nell — Mira stops beside her instead of walking
      through.

**Dialogue**
- [ ] Get close to Nell — a small **E Talk** prompt appears above her.
- [ ] Press **E** — the dialogue box opens at the bottom and Mira can't move.
- [ ] Press **Enter** while a line is typing — the line finishes at once. Press
      it again — the next line starts.
- [ ] Press **Esc** at any point — the dialogue closes and Mira can walk
      again. The objective reads "Gull Point Light is calling."
- [ ] Talk to Nell again — the conversation replays and can be closed the
      same way.

**Gamepad** (connect the controller over USB or in **System Settings →
Bluetooth** before launching the game)
- [ ] The left stick and D-pad move Mira; a slight stick tilt doesn't.
- [ ] The prompt above Nell changes to **(A) Talk**; the controls hint (top
      right) shows gamepad labels.
- [ ] **A** opens and advances dialogue, **B** closes it, and movement resumes.
- [ ] Pressing any key switches the prompts back to keyboard labels.

## Automated check (headless)

`tools/smoke_test.tscn` loads the real main scene and drives it with simulated
keyboard and gamepad events: layout integrity, a walkable route from the stairs
to Nell, railing and NPC collision, the prompt, dialogue open, advance, and
dismiss, input lock, objective progress, and gamepad prompt switching.

```bash
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
"$GODOT" --headless --path . --import                  # first run only
"$GODOT" --headless --path . res://tools/smoke_test.tscn
echo $?                                                # 0 = all checks passed
```

It prints one `ok` / `FAIL` line per check and ends with `SMOKE TEST PASSED`.

## Placeholder art

All graphics are original placeholder pixel art in `art/` (tile atlas, Mira, Nell,
Pip, and the window icon). They are committed, so the game runs without extra
steps. They were drawn by a script, which you can rerun after changing the
palette:

```bash
"$GODOT" --headless --path . --script res://tools/generate_art.gd
```

## Project layout

```
project.godot            entry point: main scene, input autoload, renderer, window
scenes/harbor.tscn       main scene (map, y-sorted world, HUD, dialogue)
scenes/*.tscn            player, Nell, Pip, interactable prompt, HUD, dialogue box
scripts/harbor.gd        scene flow: intro fade, objectives, Nell's dialogue
scripts/harbor_map.gd    tile layout as text, draws tiles and builds collision
scripts/player.gd        movement, animation, interaction focus, input lock
scripts/interactable.gd  reusable "press E to …" area with a floating prompt
scripts/dialogue_box.gd  typewriter dialogue with advance and dismiss
scripts/input_hints.gd   autoload: input bindings and keyboard/gamepad labels
art/                     placeholder sprites and tiles
tools/                   art generator and headless smoke test
GAME_DESIGN.md           story, world, characters, systems, art, audio, accessibility
ROADMAP.md               the first three playable milestones
```

To change the harbor layout, edit the `LAYOUT` text grid in
`scripts/harbor_map.gd`; the legend is at the top of that file.
