# What the first version does

This file is the description the code is supposed to match.

## Rules

1. You walk up to her, open a list, and play one shared animation.
2. The first version is one room, you, two women, a greeting, and a hug.
3. Every character is the same paperdoll, drawn on a flat picture that turns to face the camera. No 3D body. Each woman has her own pictures.
4. A shared animation uses one clock. Both people follow it.
5. She keeps her own day. You can interrupt it. This is not a multiplayer game.

## What you can do

- The greeting is a both-arm reach. It plays where she stands. It is not a wave.
- The hug is the clothed hold. Shirt and skirt stay on. Arms are out by 0.7 seconds, held to 3.2 seconds, and back at 4.0 seconds. Her face is calm until 0.7 seconds, smiling through the hold, and calm again on the release.
- The camera stays first person. You see her. Your own picture stays hidden, except during the hold and in the mirror.
- E opens the list when you are within 1.2 m. The room pauses while the list is open. Looking still works.
- The list has the hug, the greeting, then any saved animations. The greeting stays where she is. A saved animation walks her to 0.4 m.
- The nearer woman answers E. The other woman walks the gate and the bench. The yard is north of the path.
- For the hug, she walks to 0.25 m in front of you. That distance is not the saved-animation stop.
- Esc cancels only before contact: while the list is open, or while she is still walking in. After the clock starts, the animation plays out.
- After it ends, that woman waits 3 seconds before her list can open again. The other woman is not blocked by that wait.
- Her day is window, then chair, then the north yard gate. When you interrupt her, she goes back to the spot she left.
- Eight views: front, side, back, and one diagonal are drawn. The other four are flips of those.

## Pictures and arms

Hands aim through a two-bone arm solve on the front view. Side and back use saved angles. Past sideways shows the back pictures.

## Saved animation file

The built-in hug is `res://data/animations/hug.json`. Later saved files go in `user://clips/*.json`.

Keys are time in seconds and rotation in radians on `leg_l`, `leg_r`, `knee_l`, `knee_r`, `arm_l`, `arm_r`, `elbow_l`, `elbow_r`. Her face key is 0 for calm and 1 for smile.

## Code

- `scripts/animation_list.gd` loads the animation and reads a time on it.
- `scripts/list_and_clock.gd` opens the list and runs the shared clock.
- `scripts/paperdoll.gd` applies the pose.
- `scripts/character_3d.gd` walks her day, walks her to you, and holds the animation.
