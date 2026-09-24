# Paperdoll 2.5D

Godot 4 prototype: a **3D environment** with **modular 2D paperdoll** characters drawn in a `SubViewport` and shown on Y-billboard `Sprite3D`s.

## Requirements

- [Godot 4.3+](https://godotengine.org/download) (Forward Plus)

## Run

1. Clone this repo.
2. In Godot: **Import** → select this folder (`project.godot`).
3. Press F5. Main scene is `scenes/main.tscn`.

## Controls

| Key | Action |
|---|---|
| Mouse | Look (POV) |
| WASD / arrows | Walk relative to look |
| Esc | Release cursor; click to capture again |
| 1 | Cycle hair |
| 2 | Cycle shirt |
| 3 | Cycle pants / skirt |

## Layout

```
CharacterBody3D          3D move / collide
  CollisionShape3D
  SubViewport            2D paperdoll composite
    Paperdoll
      Body, Pants, Shirt, Shoes, Eyes, Hair
  Sprite3D               Y-billboard (hidden from the local POV camera only)
  Head
    Camera3D             first person; enabled when is_player
```

Swap layer files under `assets/paperdoll/` or edit the path lists in `scripts/paperdoll.gd`.
