# Design

## The core loop

What exists in the slice today:

- **Walk/run** across rolling plains ringed by snow-capped peaks, third-person orbit camera. Terrain mesh, collider, grass scatter and camera ground-clamp all derive from one height function, so they cannot drift apart.
- **Graze** — hold E standing still on grass. Head drops, individual tufts out of ~27,000 are chewed down and vanish. A patch exhausts in about a second, so grazing is already a rhythm of *stop, eat, walk on* rather than a hold-to-win. Tufts regrow after 35s.
- **Fullness meter** — fills while grazing, drains slowly the rest of the time. The only number in the game, and it currently feeds nothing.
- **Moo** — M. A procedurally synthesised call (the project ships zero audio assets) plus an expanding ring so it reads on video. Currently pure decoration.

Four verbs, two of which are decorative. The entire design question is what makes the meter and the moo load-bearing without adding art.

## Why a cow game could actually be fun

The honest answer: **because the thing that feels good is the same thing that ruins you.**

Cows are not agile, clever, or stealthy. Every animal game verb worth stealing (goose honk, cat meow) is about agency; a cow has almost none. What a cow has is *appetite* and *mass*, and appetite is a genuine trap — grazing is the pleasure, grazing is blind, and blindness costs you the herd.

So the tension is: **the herd leaves without you, and you're the slowest cow.** Not wolves, not cold, not a hunger clock.

- Cliffs → a fail state, not a loop.
- Cold/weather → an invisible meter, nothing to decide.
- Wolves → predator AI, chase anims, most expensive thing on the list, and the tension is borrowed from a different game.
- Hunger/thirst clock → the most shovelware-coded mechanic in existence.
- **Herd abandonment** → pleasure and danger are one action.

That last one is a design engine, not a mechanic. It also costs nearly nothing: a herd is N instances of the cow already rigged, on a spline with separation.

## Candidate directions

**HINDMOST — herd abandonment**
*You are the slowest cow. The herd does not wait.*
Adds: herd agents, `distance_to_herd` driving audio/color/FOV instead of a HUD, moo as a range-gated call that spends satisfaction to buy seconds, a choice between the grassy contour path and the fast scree shortcut.
Cost: ~2 weeks. No new mesh, no new anim set, no combat.
Risk: it's one atom from an escort mission. The gap between "poignant" and "this game won't let me enjoy the grass" is two numbers wide, and only strangers playing it find those numbers.

**A VERY LARGE COW — warmth**
*The mountain is cold; you are 700kg of warm.* Lie down, thaw the ground, small shivering things come and nestle against you.
Adds: a persistent world-space warmth mask shader, a lie-down state, three critter types with a ~40-line nestle state machine.
Cost: ~2 weeks, but front-loaded on one shader.
Risk: the feeling lives or dies on that shader, and a dev with no art budget cannot iterate out of "it isn't beautiful." Also the most passive design here — it photographs better than it plays. And "cute animal + alpine meadow + small friends" is exactly where cozy-shelf filler is converging.

**OVERGRAZED — ecological terraforming**
*The mountain is your food, and eating it makes it fall down.*
Adds: a vegetation cell grid, soil stability, runtime terrain deformation, seasons, dung nutrient flow.
Cost: two weeks that end with zero fun, then months more.
Risk: binary and engine-level. Godot has no first-party terrain; deforming a chunk means rebuilding `ConcavePolygonShape3D` on a worker thread. A landslide that hitches 200ms is a bug, not an event — and the collapsing ground *is* the product, so there's nothing to salvage.

**BELL — the sound-only variant**
*Find the herd by ear alone in fog.* Cut the visuals entirely; navigation is a mix problem.
Adds: nothing but a distance-attenuated bell and volumetric fog.
Cost: days.
Risk: it's a jam toy, not a $12.99 product. Named here to be rejected honestly — it's the fallback if Hindmost's tuning proves unsolvable.

## Recommendation

**Build HINDMOST.** It is the only direction where the design problem and the already-solved problem are the same problem. Walk, graze, moo, satisfaction — those four, unchanged, become a complete game the moment a line of cows walks away over a ridge. Walk becomes pursuit. Graze becomes the cost. The meter becomes the only currency. Moo stops being a sound effect and becomes the entire economy: spend fullness, buy seconds, range-gated so a desperate long-range bellow does nothing. Its risk profile is also the right shape — tuning, discoverable by five strangers in week three, fixable forever. And the placeholder-art alibi is real: identical untextured grey silhouettes cresting a ridge in flat light reads as *lonely*, not *unfinished*. Ship at **$12.99**, no Early Access, with "about 90 minutes" stated above the fold. Comparables: **Herdling** ($24.99, ~93% of ~800 reviews) proves the fantasy sells and is a ceiling you can't out-render; **WolfQuest: Anniversary Edition** ($29.99, ~11k reviews at 97%) is the model to actually copy — modest art, deep systems, decade-long tail; **Shelter 2** (~$14.99, 87%) is the ancestor; **A Short Hike** ($7.99, 99%) is the price anchor below you.

**Grafts.** From A VERY LARGE COW, take **lie-down as the reward beat**: rejoin the herd, bed down among them, camera lowers, bell-and-lowing mix closes in warm, nothing is asked of you. A game that only pulls nags; a game that pulls then rests has rhythm. One key, one capsule tilt, one mix change. From OVERGRAZED, take **persistent grazed ground as a trail, not terrain** — the herd strips and tramples what it walks over, and it stays. You look up, see a chewed-down line running over the ridge, and follow it. That solves "no HUD but never lost" diegetically, using the grass system that already exists. Implement as a splat mask painted by herd agents. No heightmap. No collision rebuild.

## What we are deliberately NOT doing yet

- Terrain collapse, soil stability, dung chemistry, seasons, cow-vision — every one is a second game.
- Warmth fields and nestling critters. The lie-down pose, yes; the shader and the AI, no.
- Wolves, cold, hunger/thirst meters. They return later only as *modifiers on herd speed*, never as their own systems.
- Milk economy, barns, NPCs, inventory, crafting, dialogue. The cow never goes indoors.
- Any HUD. No distance bar, no compass, no objective marker. If the world can't say it, it isn't said.
- **A store title containing "Simulator".** The working project name *is* Cow Simulator and that is a deliberate call by the owner — but it should be revisited before the store page goes live, because it reads as "asset flip" to the exact buyer we want. Steam shipped 19,000+ games in 2025 and nearly half have under 10 reviews; that sludge is content-shaped (a truck, a shop, a room of bought assets) and it clusters under that one word. Tag *Atmospheric, Exploration, Singleplayer, 3D* — never *Casual*, never *Simulation*. No purchased realistic assets: one hand, one palette, one shading model. Mismatched fidelity is the #1 shovelware tell.

## Open questions

1. **What are the two numbers?** Herd speed and moo-purchased slowdown. Does a rubber band (herd imperceptibly slows when you graze well, speeds up when you dawdle full) keep the wire taut, or does it read as cheating when noticed?
2. **What happens when you lose them?** Current answer: the leg ends, night falls, restart the leg. Is that a punishment or a mercy? Untested.
3. **How much mountain can one person author?** 90 minutes needs ~8 legs. If legs 4–8 are re-dressed leg 1, players will see it.
4. **Does the trampled trail actually read** at a distance, in flat light, with no texture budget?
5. **Is the 15-second GIF the deliverable at D10 — cow eating, camera lifts, herd is dots on a ridge, one moo, nothing answers?** If it doesn't move a stranger, repitch or kill it in week 2, not month 8. And the Steam page should go live that same day; wishlists compound from the day it exists.