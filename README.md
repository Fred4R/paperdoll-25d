# Paperdoll 2.5D

Godot 4 prototype: a **3D environment** with **modular 2D paperdoll** characters drawn in a `SubViewport` and shown on Y-billboard `Sprite3D`s.

## Requirements

- [Godot 4.3+](https://godotengine.org/download) (Forward Plus)

## Run

1. Clone this repo.
2. In Godot: **Import** → select this folder (`project.godot`).
3. Press F5. Main scene is `scenes/main.tscn`.
4. Let Godot import the new SVGs before playing.

## Slice check

Walk within 1.2 m of her. E opens the list. 1 starts the embrace and she walks to 0.4 m. 2 starts the greeting where she stands. Esc cancels only before an embrace walk-in arrives. The clip then plays out, and the prompt stays hidden for 3 seconds.

## Controls

| Key | Action |
|---|---|
| Mouse | Look (POV) |
| WASD / arrows | Walk relative to look |
| Esc | Close the list, or cancel her walk-in. Does not skip a clip that has started. Releases the cursor only when you are free |
| E | Open the interaction list when the prompt shows |
| C | Open the clip timeline. Left and Right scrub. V shows your doll. Esc closes. Nothing is saved yet |
| 2 | Cycle shirt |
| 3 | Cycle pants / skirt |

## Layout

```
CharacterBody3D          3D move / collide
  CollisionShape3D
  SubViewport            2D paperdoll: torso, swinging arms and legs
    Paperdoll
      Body, Pants, Shirt, Shoes, Eyes, Hair
  Sprite3D               Y-billboard (hidden from the local POV camera only)
  Head
    Camera3D             first person; enabled when is_player
```

Swap layer files under `assets/paperdoll/` or edit the path lists in `scripts/paperdoll.gd`.
