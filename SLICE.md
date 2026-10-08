# Paperdoll 2.5D — slice spec

Living spec for the Godot 4 prototype in this folder. Code follows this file.

## Pillars (locked 2026-10-07)

1. Core loop is the interaction: approach, choose, play one synchronized animation.
2. First milestone is one room, male player, one female NPC, one paired interaction.
3. Every character is the same 2.5D paperdoll on a Y-billboard. No 3D character meshes.
4. A synchronized animation is one shared sequence. Both roles lock to it.
5. The NPC keeps a living schedule. The player interrupts it. Multiplayer is out.

## Locked slice

- Clip: **Embrace**. Arms wrap, hold, release.
- Camera: **first person stays**. Player billboard stays culled. You see her.
- Start: in range, **E** opens a list. Room **freezes** (look still works) until you pick or Esc.
- List contents now: **built-in Embrace only**. `user://clips` loads when the editor exists.
- Who moves: **she comes to you**. Your root does not lerp. Slot is **0.25 m** in front of you (chest-up, high overlap).
- Esc **cancels only before contact** (list open, or she is still walking in). Once the clock starts, the clip plays out.
- After: **5 second cooldown**. Prompt hidden until it ends. No other state.
- Authoring: **pivot-curve JSON**, both roles, one clock. Editor UI is the next milestone. Format must already match what that editor will write.
- Schedule: **window, then chair**, loop. Idle, walk, interruptible. On end she resumes the spot she left.
- Prompt radius: **1.6 m**.

## Rig limit

Current paperdoll art is a profile rig. The embrace poses in the sprite plane. A true front-facing wrap needs front-view layers later. The sampler does not care which art is on the pivots.

## Clip schema

`res://data/clips/embrace.json` now. Later player files: `user://clips/*.json`.

Keys are `[time_seconds, rotation_radians]` on `leg_l`, `leg_r`, `knee_l`, `knee_r`, `arm_l`, `arm_r`, `elbow_l`, `elbow_r`.

## Code

- `scripts/clip_library.gd` loads and samples.
- `scripts/interaction.gd` is the director on Main.
- `scripts/paperdoll.gd` applies a pose and skips `drive()` while locked.
- `scripts/character_3d.gd` schedule, approach, freeze, clip lock.
- NPC2 is not in the slice scene.
