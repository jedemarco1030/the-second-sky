# The Second Sky — Roadmap

Three playable milestones. Each one ends with a build that a new player can run
from start to end, and with headless checks added to `tools/smoke_test.gd`.

## Milestone 1 — The Harbor Walk ✅ (this build)

A 30-second exploration slice.

- [x] Godot 4 project, typed GDScript, Compatibility renderer, F5 runs the game
- [x] Harbor staircase down to the waterfront, with clear collision
- [x] Mira: 8-direction movement and a walk cycle; Pip following her
- [x] Nell at her radio, a floating talk prompt, readable dialogue that can be
      skipped and closed
- [x] Keyboard and gamepad input with prompts that follow the device
- [x] Objective HUD, title card, amber-and-teal palette, original placeholder art
- [x] Headless smoke test for movement, collision, dialogue, and gamepad input

## Milestone 2 — The Seawall Fight

Takes the player from Nell's call into the first fight.

- Walk the returned quarter out to the seawall; Pip lights tide-pool paths.
- Meet **Tovan**, guarding the seawall gate; short recruitment scene.
- **Turn-based battle system**: party of Mira, Tovan, Nell, with Pip's
  enemy-intent reveal. 2–3 enemy types (tide crabs, lantern-eaters), one
  mini-boss (the Barnacle Warden) at the seawall gate.
- HP, a small skill set per character, victory/defeat flow with an instant
  retry. No grinding needed.
- Save and load at lantern posts (one save slot plus autosave).
- First pass at audio: town theme, battle theme, ambience, UI sounds.
- Options menu: volume sliders, text speed, rebinding.
- Done when: a new player gets from the stairs to beating the Warden in
  10–15 minutes and can quit and continue from a save.

## Milestone 3 — The Harbor Decision and the Return Visit

The full arc in miniature.

- Reach Gull Point Light and find the source of the distress call.
- The **harbor decision**: three choices (restore the moon, let the tide
  rise, anchor both towns), with dialogue from each party member setting out
  their side.
- One scene per ending, then a **playable return visit**: the same harbor map
  rearranged for the chosen outcome — moved buildings, new or flooded routes,
  NPCs whose lines and deliveries reflect the choice.
- Credits, and the option to load the pre-decision save and try another
  choice.
- Accessibility pass: reduced motion, text size, colorblind check, story-mode
  combat.
- Done when: all three outcomes are reachable, each return visit is
  explorable for at least 5 minutes, and the smoke test covers every outcome.

## Later (not scheduled)

- Final art replacing the placeholders, controller rumble, localization
  (English first, strings already isolated in scripts), Steam Deck check.
