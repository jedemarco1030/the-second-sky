# The Second Sky

An original single-player retro 2D JRPG, built as a native **Godot 4** project in
typed GDScript with the **Compatibility** renderer. No plugins, no downloads, no
network access — everything the game needs is in this repository.

The current build has two parts:

1. **The Harbor Walk**: Mira starts at the top of a harbor staircase, walks down
   to the waterfront, and talks to Nell, whose radio is picking up a distress
   call from Gull Point Light.
2. **The Seawall**: after Nell, Mira finds Tovan at the west seawall. Talking to
   him starts a turn-based battle in which Mira, Tovan, Nell, and Pip face the
   harbor pump. Win, and you return to the harbor beside Tovan.

### How the seawall battle works

- A **timeline** across the top shows the next 12 turns. The pump's **Surge** sits
  on it as a red slot, so you can see exactly when it lands.
- Every Pressure Jet starts charging the next Surge. A Surge hits the whole party.
- **Strategy A, Guard:** have everyone who acts before the Surge choose
  **Guard**. Guarded hits deal much less damage. Pip's **Mend** keeps the party
  topped up between Surges. It's slow but safe.
- **Strategy B, Breakwater:** Mira's **Rally** moves an ally to act right after
  her. Rally Nell so that Tovan and Nell both act before the Surge. Then Tovan
  (or Nell) chooses **Breakwater**. Before you confirm, the menu highlights the
  **two turns it spends** (the initiator's now and the partner's next) and
  **the turn it resolves on**. If it resolves before the Surge, it deals heavy
  damage, breaks the Surge, and the pump loses its next turn.
- Nothing is timed. The battle waits on every menu for as long as you like.

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

In battle:

| Action                 | Keyboard               | Gamepad                   |
| ---------------------- | ---------------------- | ------------------------- |
| Move menu cursor       | W/S or Up/Down arrows  | Left stick or D-pad       |
| Select / confirm       | E or Enter             | A (Cross on PS)           |
| Back                   | Esc or Backspace       | B (Circle on PS)          |
| Retry encounter        | R                      | Back / View / Share       |

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
      again. The objective reads "Find Tovan at the west seawall."
- [ ] Talk to Nell again — the conversation replays and can be closed the
      same way.

**Gamepad** (connect the controller over USB or in **System Settings →
Bluetooth** before launching the game)
- [ ] The left stick and D-pad move Mira; a slight stick tilt doesn't.
- [ ] The prompt above Nell changes to **(A) Talk**; the controls hint (top
      right) shows gamepad labels.
- [ ] **A** opens and advances dialogue, **B** closes it, and movement resumes.
- [ ] Pressing any key switches the prompts back to keyboard labels.

## Seawall playtest checklist

Run the game with F5 each time; the story state resets on launch.

**Entering the encounter**
- [ ] Before talking to Nell, talk to Tovan at the west seawall. He sends Mira
      to Nell and no battle starts.
- [ ] Talk to Nell, then Tovan. When his dialogue ends, the screen fades into
      the battle.
- [ ] The battle opens on Mira's command menu. The timeline across the top
      shows 12 turns, and the Surge is a clearly marked red slot.
- [ ] Every menu entry is readable at 1280 × 720, and the highlighted entry is
      obvious. The info box explains the highlighted command.
- [ ] Leave a menu open for 30 seconds. Nothing happens on its own.

**Strategy A: Guard through Surge** (play this one keyboard-only)
- [ ] When the pump uses Pressure Jet, the log says it is charging a Surge,
      and the timeline marks which turns come before it.
- [ ] Highlight **Guard**. The info box says whether that unit acts before
      the Surge.
- [ ] Have every unit that acts before the Surge choose Guard. The Surge
      deals small damage to everyone and nobody falls.
- [ ] Between Surges, attack and use Pip's **Mend** on whoever is lowest.
- [ ] Repeat until the pump falls. The victory screen appears.

**Strategy B: Rally Nell, then Breakwater** (play this one gamepad-only)
- [ ] On Mira's turn, highlight **Rally**, pick **Nell**. The info box and the
      timeline show Nell moving to right after Mira.
- [ ] On Tovan's turn, while a Surge is charging, highlight **Breakwater**.
      The preview highlights two spent turns (Tovan now, Nell next) and the
      turn it resolves on, and says whether that lands before the Surge.
- [ ] Press **B** on the preview. You return to the command menu with Tovan's
      turn unspent.
- [ ] Select Breakwater again and confirm. On the previewed turn, Breakwater
      hits hard, breaks the Surge, and the pump loses its next turn.
- [ ] Breakwater is greyed out, with the reason, when the partner is down or
      a Breakwater is already set.
- [ ] Without Rally, preview Breakwater while Nell acts after the Surge. The
      preview says it resolves "AFTER the Surge" and suggests Rally.
- [ ] The fight ends noticeably faster than the Guard run.

**Losing and retry**
- [ ] Choose only attacks and ignore the Surges. The party falls and the
      defeat screen appears with **Retry** highlighted.
- [ ] Press **Enter / A** once. The encounter resets: full HP, turn 1, Mira's
      menu, the original timeline.
- [ ] Mid-fight, press **R** (keyboard) or **Back/View** (gamepad) once. The
      encounter resets the same way, with no confirmation dialog.
- [ ] On the victory screen, choose **Fight Again**. The encounter resets.

**Return to town**
- [ ] On the victory screen, **Return to Harbor** is highlighted. Select it.
- [ ] Mira reappears beside Tovan at the west seawall and can walk at once.
      The objective reads "The seawall pump is quiet."
- [ ] Talk to Tovan again. He has a new line and the battle does not restart.
- [ ] Walk back to Nell and up the stairs. The harbor walk still works.

## Automated checks (headless)

`tools/smoke_test.tscn` loads the real scenes and drives them with simulated
keyboard and gamepad events. Harbor: layout integrity, a walkable route from the
stairs to Nell, railing and NPC collision, the prompt, dialogue open, advance, and
dismiss, input lock, objective progress, and gamepad prompt switching. Seawall:
entering from Tovan after Nell, timeline length and Surge placement, menu
navigation by key, D-pad, and stick, no timed input, a full Guard win
(keyboard), a full Rally + Breakwater win (gamepad), Breakwater's preview and
Back, every Breakwater resolving on its previewed turn, a defeat, Retry from
defeat, victory, and mid-fight (R and gamepad Back), and Return to Harbor
putting Mira beside Tovan with the battle not restarting.

`tools/battle_sim.gd` plays the battle rules (no UI) with three policies (attack
only, Guard, and Rally + Breakwater) and prints each fight. Use it after
changing numbers in `scripts/battle/battle_model.gd`:

```bash
"$GODOT" --headless --path . --script res://tools/battle_sim.gd
```

```bash
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
"$GODOT" --headless --path . --import                  # first run only
"$GODOT" --headless --path . res://tools/smoke_test.tscn
echo $?                                                # 0 = all checks passed
```

It prints one `ok` / `FAIL` line per check and ends with `SMOKE TEST PASSED`.

## Placeholder art

All graphics are original placeholder pixel art in `art/` (tile atlas, Mira, Nell,
Pip, Tovan, the harbor pump, and the window icon). They are committed, so the game runs without extra
steps. They were drawn by a script, which you can rerun after changing the
palette:

```bash
"$GODOT" --headless --path . --script res://tools/generate_art.gd
```

## Project layout

```
project.godot            entry point: main scene, input autoload, renderer, window
scenes/harbor.tscn       main scene (map, y-sorted world, HUD, dialogue)
scenes/seawall_battle.tscn  the seawall encounter (timeline, field, menus, results)
scenes/*.tscn            player, Nell, Tovan, Pip, interactable prompt, HUD, dialogue box
scripts/harbor.gd        scene flow: intro fade, objectives, Nell and Tovan, battle entry/return
scripts/game_state.gd    autoload: story flags and scene changes between harbor and battle
scripts/battle/battle_model.gd   battle rules, turn order, Surge, Rally, Breakwater (no UI)
scripts/battle/battle_unit.gd    one combatant's stats and timeline position
scripts/battle/seawall_battle.gd battle UI: timeline, menus, previews, retry, results
scripts/harbor_map.gd    tile layout as text, draws tiles and builds collision
scripts/player.gd        movement, animation, interaction focus, input lock
scripts/interactable.gd  reusable "press E to …" area with a floating prompt
scripts/dialogue_box.gd  typewriter dialogue with advance and dismiss
scripts/input_hints.gd   autoload: input bindings and keyboard/gamepad labels
art/                     placeholder sprites and tiles
tools/                   art generator, headless smoke test, battle balance sim
GAME_DESIGN.md           story, world, characters, systems, art, audio, accessibility
ROADMAP.md               the first three playable milestones
```

To change the harbor layout, edit the `LAYOUT` text grid in
`scripts/harbor_map.gd`; the legend is at the top of that file.
