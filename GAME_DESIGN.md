# The Second Sky — Game Design

## Pitch

A short, warm, retro JRPG about a harbor town that gets back something it lost,
and has to decide what to do with it. Four characters, one town, one big choice,
and a return visit where you see what that choice did.

## Story

Port Calloway has lived for decades under an **artificial moon**, a lantern
engine hung over the bay to light the night-fishing fleet and hold back the
tides. One night it cracks. The tide recedes and an **old waterfront**, drowned
when the moon was first lit, rises out of the water: streets, a chapel, a
market, and people's houses, still wet.

**Mira**, a courier who knows every staircase in town, is first on the scene.
**Nell** picks up a distress call from Gull Point Light, which has been dark
for thirty years. Over the next three acts Mira's group works out why the moon
was built, who the drowned waterfront belonged to, and what keeps calling from
the lighthouse.

The story ends with a **harbor decision**: repair the moon and send the old
waterfront back under the tide, let the tide take the new town, or anchor both
halves halfway, with a cost to each. The player then makes a **return visit**
to the settled harbor and sees the consequences in places and people they know.

Tone: small-scale and kind. Nobody is evil. Everyone wants to protect a home.

## World

- **Upper Calloway** — the current town: brick terraces, steep stairs, lantern
  posts, and laundry lines. Warm amber light. Where the game opens.
- **The Waterfront** — the boardwalk and pier where the two towns meet. Nell's
  radio stand.
- **The Returned Quarter** — the drowned district, teal and barnacled, lit by
  glowing tide pools. Its seawall still holds back the sea.
- **Gull Point Light** — the lighthouse at the end of the seawall.
- **The Cracked Moon** — visible from everywhere; it changes as the story
  progresses and works as an at-a-glance progress marker.

## Characters

| Character | Role | Want | In play |
| --- | --- | --- | --- |
| **Mira** | Courier, playable lead | To keep the town connected, house to house | Fast mover; can carry and deliver items between NPCs |
| **Tovan** | Retired knight, joins in the seawall fight | To finish a duty he walked away from | Defender; shields allies, holds chokepoints |
| **Nell** | Radio mechanic | To find who is broadcasting from the light | Support; scans enemies, tunes radio "frequencies" that act as buffs |
| **Pip** | Lantern moth, Mira's companion | To stay near light | Follows Mira; lights dark areas, points out things to interact with |

## Gameplay

- **Exploration**: top-down, free 8-direction movement on a 16 px tile grid
  with clear collision. Interactables show a floating button prompt.
  Objectives are always visible in the top-left corner.
- **Dialogue**: typewriter text that the player can skip line by line or close
  completely at any moment. No timed text.
- **Combat** (from milestone 2): turn-based, small parties (up to 3 plus Pip),
  short fights. Each character has one signature mechanic instead of a long
  spell list. Pip's light reveals enemy intent for the next turn.
- **Deliveries**: Mira's courier work is the side-quest structure: carry
  letters, parts, and messages between NPCs in both towns.
- **The decision**: one choice, foreshadowed by every delivery and
  conversation, with three outcomes and a playable return visit.

## Art direction

- 640 × 360 internal resolution, scaled with nearest-neighbor filtering. 16 px
  tiles, characters 16 × 24.
- **Amber and teal**: amber for lantern light, warmth, and the player's UI
  focus; teal for the sea, the returned quarter, and night. A deep teal-black
  as the base and a cream for text.
- Readable silhouettes before detail. Collision is always visible in the art:
  if it looks solid, it is solid.
- The current art is original placeholder art made by `tools/generate_art.gd`;
  it sets the palette and proportions for the final art.

## Audio direction (not yet in the build)

- Music: small ensemble, with accordion, upright bass, glockenspiel, and
  soft synth pads for the moon. One theme for the town, reharmonized for the
  returned quarter and the return visit.
- Ambience is the main storytelling layer: gulls, rope creak, distant bells,
  radio static that gets clearer as Nell tunes in.
- UI sounds: one soft tick per typewriter word (not per letter), a lantern
  "chime" when a prompt appears.
- Separate volume sliders for music, ambience, effects, and voice blips.

## Accessibility

Already in the harbor walk:
- Full keyboard and gamepad support with no mouse required; the two can be
  swapped at any time, and prompts follow the last device used.
- Dialogue can always be finished instantly or closed; no timed text.
- High-contrast cream-on-teal text with an amber border; the objective is
  always on screen.
- Stick deadzone so a drifting controller doesn't move Mira.

Planned:
- Rebindable controls and an option to toggle instead of hold.
- Text size and text speed settings, plus a dyslexia-friendly font option.
- Reduced motion (no camera smoothing, no screen shake, no moon flicker).
- Colorblind-safe check: amber vs. teal never carries meaning alone; every
  state also has a shape or icon.
- Combat: adjustable difficulty, "story mode" auto-win, no time pressure.
- Subtitles and visual cues for every important sound.
