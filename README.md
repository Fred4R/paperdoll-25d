# Paperdoll 2.5D

A playable simulation: a 3D room, first person, a woman on a 2D paperdoll billboard, and clips that stay.

Play `hud-nodes`. `main` does not load. Success is `what-playing-it-means.md`.

## Requirements

- [Godot 4.3+](https://godotengine.org/download) (Forward Plus)

## Run

```
git fetch origin
git checkout hud-nodes
git pull
```

1. In Godot: **Import** → select this folder (`project.godot`).
2. Press F5. Main scene is `scenes/main.tscn`.
3. Let Godot import the SVGs before playing.

## First version check

Walk within 1.2 m of her. E opens the list. 1 is embrace. 2 is greeting. Saved clips in user://clips appear after those. Greeting plays where she stands. Embrace walks her to 0.4 m. Esc cancels only before an embrace walk-in arrives. The prompt stays hidden for 3 seconds.

## Controls

| Key | Action |
|---|---|
| Mouse | Look (POV) |
| WASD / arrows | Walk relative to look |
| Esc | Close the list, or cancel her walk-in. Does not skip a clip that has started. Releases the cursor only when you are free |
| E | Open the interaction list when the prompt shows |
| C | Open the clip timeline. You stay visible. Left and Right scrub. Up and Down nudge the selected arm. A switches arm. R switches role. S saves to user://clips. Esc closes. The list does not load saves yet |
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
