# Build list

Match this list to what-the-game-does.md. The play copy is `hud-nodes`. `main` does not load. Do not push `main` until Fred has played that save. He exports the phone build. This chat does not.

## Done

- [x] 3D room, body, and collision
- [x] Paperdoll drawn in a small view and shown on a picture that turns to face the camera
- [x] That picture is bound after the scene is ready
- [x] First person. Your picture is hidden from your own camera
- [x] Male and female picture sets: hair, shirt, pants
- [x] Walk on limb pivots
- [x] One woman, window, and chair
- [x] Her day: wait, walk, interrupt, resume
- [x] E opens the list. The room pauses. Looking still works
- [x] She walks to 0.25 m in front of you for the hug
- [x] Esc cancels only before contact
- [x] One clock reads both people from the animation file
- [x] Clothed hug, about 4 seconds. Wait after it is 3 seconds for that woman
- [x] Collision off while she walks in and during the hug
- [x] Eight views: four drawn, four flips
- [x] Walk to the window, chair, and gate uses the navigation agent. Save `e994256`

## Still to build

- [ ] Side, back, and diagonal pictures matched to the approved front
- [ ] The facing change uses those pictures from the camera angle
- [ ] Second woman in the room, with her own pictures and a name that stays
- [ ] Greeting as a both-arm reach where she stands
- [ ] Saved animation walks her to 0.4 m, which is not the hug stop
- [ ] Room is still there the next time the game opens

## Later, after the hug reads

- [ ] In-game editor for both people on one clock
- [ ] Show your paperdoll while editing
- [ ] Save and load `user://clips/*.json` in the same shape as the hug file
- [ ] The list plays a saved animation the same way it plays the built-in hug

## Not in this version

- [ ] Spoken lines
- [ ] Night, needs, and a full world save beyond the room still being there
- [ ] Multiplayer
- [ ] 3D character bodies
- [ ] A second animation system
- [ ] Clothes coming off. Shirt and skirt stay on for this hug
