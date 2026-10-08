# Fix plan

Order is the order Godot can run. Do not retune clocks or redraw the female nude pictures in this pass.

## 1. Skeleton call

`scripts/arm_ik.gd` calls `stack.execute`. Godot runs a `Skeleton2D` stack through `execute_modifications(delta, mode)`.

Edit the solver so the `Skeleton2D` owns that call. Keep the `Bone2D` chain. The drawn pivots may keep copying rotations until a later scene edit turns `ArmL` and `Elbow` into `Bone2D` nodes in `paperdoll.tscn`.

## 2. Record in use

`CharacterRecord` exists and the wardrobe ignores it. `SaveStore` should load and save `CharacterRecord` fields: id, name, palette, nude, and slot overrides.

Tab and F5 read that record. A mass edit still skips an overridden slot. The dictionary in `interaction.gd` becomes a cache of those resources, not the source.

## 3. On-screen button signals

`scenes/hud.tscn` is instanced. `hud.gd` already has `closed`, and nothing connects it.

The director sends the clip list, the wardrobe lines, or the timeline text. The panel shows and hides itself. Esc emits `closed`. `interaction.gd` stops writing label text except the string it hands over.

## 4. Yard props

The split dropped the pillars and crates. Add them back on `scenes/yard.tscn`, not on `main.tscn`. Same wood and stone materials. Positions stay the old path-side spots.

## 5. Hold shows the player doll

For the 4 second hold only, the player billboard moves to the visible layer, then returns to the first-person cull. Tab still cannot edit the player. The mirror already shows the nearest doll within 1.2 m. Leave that.

## 6. Face blend

The face still cuts at 0.5. Add a second face sprite and crossfade modulate over 0.5 s, starting with the clip. Do not replace the textures with new art.

## 7. Left for later

Chest and groin as separate slots. `AnimationPlayer` in place of the 0.4 s ease. Female nude art. Those wait until this plan has been played.
