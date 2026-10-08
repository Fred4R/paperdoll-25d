# Paperdoll 2.5D — slice spec

Living spec for the Godot 4 prototype in this folder. Code follows this file.

## Pillars (locked 2026-10-07)

1. Core loop is the interaction: approach, choose, play one synchronized animation.
2. First milestone is one room, male player, one female NPC, one paired interaction.
3. Every character is the same 2.5D paperdoll on a Y-billboard. No 3D character meshes.
4. A synchronized animation is one shared sequence. Both roles lock to it.
5. The NPC keeps a living schedule. The player interrupts it. Multiplayer is out.

## Locked slice

- Clip: **Embrace** and **Greeting**. Greeting is a 2 second wave. Embrace is the 4 second hold.
- Camera: **first person stays**. Player billboard stays culled. You see her.
- Start: in range, **E** opens a list. Room **freezes** (look still works) until you pick or Esc.
- List contents: built-in Embrace and Greeting, plus any `user://clips` JSON. Saved greeting plays in place. Other saved clips walk her in.
- Greeting is a small both-arm reach, not a wave, and plays where she stands.
- Two women. The nearer one answers E. The second walks the gate and the bench. A yard room is north of the path.
- Embrace plays a short reach sound at 0.7 s. Clothes stay on.
- Prompt radius: **1.2 m**.
- Esc **cancels only before contact** (list open, or she is still walking in). Once the clock starts, the clip plays out.
- After: **3 second cooldown**. Prompt hidden until it ends. No other state.
- Authoring: C opens a timeline. You stay visible while it is open. Up and Down nudge the selected arm. S writes `user://clips`. The list does not load those files yet.
- Schedule: **window, then chair**, loop. Idle, walk, interruptible. On end she resumes the spot she left.

## Rig

Every character, including the player, uses `data/palettes.json`. A palette names the front, side, and back layer for each part. Missing views fall back to front. `player`, `woman_dark`, and `woman_rose` are the current palettes.

Arms are out of frame by 0.7 s, held to 3.2 s, and back at 4.0 s. Her face track swaps calm and smile. Player keys share the clock.

## Clip schema

`res://data/clips/embrace.json` now. Later player files: `user://clips/*.json`.

Keys are `[time_seconds, rotation_radians]` on `leg_l`, `leg_r`, `knee_l`, `knee_r`, `arm_l`, `arm_r`, `elbow_l`, `elbow_r`. Her role also has `face`: 0 calm, 1 smile.

## Code

- `scripts/clip_library.gd` loads and samples.
- `scripts/interaction.gd` is the director on Main.
- `scripts/paperdoll.gd` applies a pose and skips `drive()` while locked.
- `scripts/character_3d.gd` schedule, approach, freeze, clip lock.
- NPC2 is not in the slice scene.
