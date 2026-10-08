# Fixes to make

Do these in the order the game can run. Do not retune the hug clock or redraw the nude pictures in this pass. Shirt and skirt stay on for this hug. F5 means press play. It does not read a character record.

## 1. Arm solve call

`scripts/arm_ik.gd` calls `stack.execute`. Godot runs a `Skeleton2D` stack through `execute_modifications(delta, mode)`.

The `Skeleton2D` should own that call. Keep the `Bone2D` chain.

## 2. Her saved record

`CharacterRecord` exists and the clothes ignore it. `SaveStore` should load and save her id, name, colors, and clothes overrides.

The list in `list_and_clock.gd` should cache those records, not be the source.

## 3. On-screen buttons

`scenes/on_screen_buttons.tscn` is in the scene. `on_screen_buttons.gd` has `closed`, and nothing connects it.

The list code sends the animation names, the clothes lines, or the editor text. The panel shows and hides itself. Esc emits `closed`.

## 4. Yard props

The yard split dropped the stone columns and crates. Add them back on `scenes/yard.tscn`, not on `main.tscn`. Same wood and stone materials. Positions stay the old path-side spots.

## 5. The hold shows your paperdoll

For the 4 second hold only, your picture moves to the visible layer, then returns to hidden. The mirror already shows the nearest paperdoll within 1.2 m. Leave that.

## 6. Face change

The face still cuts at 0.5 seconds. Add a second face picture and fade it over 0.5 seconds from the start of the hug. Do not replace the pictures with new art.

## Left for later

Chest and groin as separate clothes slots. A different animation player. Nude pictures. Those wait until this list has been played.
