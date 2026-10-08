# Next build plan

Compared 2026-10-07. GitHub `Fred4R/paperdoll-25d` main (`aaa78cc`) versus this folder, against Godot 4.3 docs.

## What GitHub actually is

A Godot 4.3 Forward Plus prototype. No interaction director, no clip JSON, no schedule markers.

- `CharacterBody3D` + capsule
- `SubViewport` (2D only, transparent) draws `paperdoll.tscn`
- `Sprite3D` with `billboard = 2` (Y-billboard) shows `ViewportTexture`
- Player head `Camera3D`; own sprite on layer 2, culled from that camera
- Walk is procedural in `paperdoll.gd`
- SVG layers under `assets/paperdoll/`, including side files: `body_side_*`, `eyes_side`, `hair_side_*`, `shirt_side`, `skirt_side`

Local folder has the slice those commits do not: `scripts/interaction.gd`, `scripts/clip_library.gd`, `data/clips/embrace.json`, `SLICE.md`. Local also still has leftover PNGs. Do not treat GitHub as the interaction source of truth until we push.

## What the docs say to keep

- SubViewport does not draw by itself. Display it with `Viewport.get_texture()` on the Sprite3D. ViewportTexture is local to the scene and wrong if read before the root is ready. `call_deferred` bind is the documented fix. https://docs.godotengine.org/en/4.3/classes/class_viewporttexture.html
- `disable_3d` and `transparent_bg` are correct for a 2D paperdoll. Update mode must stay Always while limbs move. Once/When Visible is only for static targets. https://docs.godotengine.org/en/4.3/tutorials/rendering/viewports.html
- Y-billboard (`billboard = 2`) is the right character mode. Full billboard tilts with pitch. The sprite still always faces the camera, so facing is an art swap plus `flip_h`, not a 3D look-at.
- One SubViewport per character. That is the cost of live paperdolls. Do not share one viewport across NPCs.

## What not to switch to

Godot AnimationPlayer is the official node animator. It is the wrong store for this game. Clips must be pivot-curve JSON so a later in-game editor can write `user://clips` without the Godot editor. The sampler already plays both roles from one clock. Do not add a second animation system.

CharacterBody3D and `move_and_slide` stay. The 0.25 m slot is inside both capsules (radius 0.28), so character-character collision has to be off during approach and contact. That is a body constraint, not a billboard one.

## Order

1. Facing sets. Wire the side SVGs already on GitHub. First person and the embrace use the front set, because the billboard faces the lens. Walk uses the side set when the camera is beside her. `flip_h` only mirrors. This is the gap that makes the embrace read wrong.
2. Keep the director as specified: E list, freeze, she walks to 0.25 m, Esc only before contact, 4 s embrace, 5 s cooldown, window then chair.
3. Playtest the built-in JSON on the front set. Tune keys. No editor UI yet.
4. Editor milestone: same schema, both roles, preview toggle for the hidden player doll, save `user://clips/*.json`.
5. Push to `main` only after the facing swap and the slice play in Godot.

## Out until those land

More NPCs, dialogue, day/night, multiplayer, 3D meshes, AnimationPlayer clips.
