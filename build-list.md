# Build checklist

Source of truth for the first version: what-the-game-does.md. Order source: fixes-to-make.md. GitHub main does not have the first version yet.

## Done

- [x] 3D room, CharacterBody3D, collision
- [x] Paperdoll in a SubViewport, shown on a Y-billboard Sprite3D
- [x] ViewportTexture bound after ready
- [x] First person; player billboard culled from his own camera
- [x] Male and female layer sets; hair, shirt, pants
- [x] Procedural walk on limb pivots
- [x] One female NPC; window and chair markers
- [x] Schedule: idle, walk, interrupt, resume
- [x] E opens Embrace list; room freezes; look still works
- [x] She paths to 0.25 m in front of the player; player root stays
- [x] Esc cancels only before contact
- [x] Shared clock samples both roles from JSON
- [x] 4 second built-in embrace; 5 second cooldown
- [x] Character collision off during approach and clip

## Must build next

- [x] Front cut-out pieces for the approved woman, worn by the female doll
- [ ] Side and back matched to that front
- [ ] Facing swap from the camera angle
- [ ] Play the first version in Godot 4.3 and fix anything that does not match what-the-game-does.md
- [ ] Tune embrace.json keys on the front set (reach, hold, release)
- [ ] Confirm 0.25 m does not clip the camera near plane; back off only if it does

## Editor milestone, after the clip reads

- [ ] In-game timeline editor, both roles, one clock
- [ ] Preview toggle that shows the player paperdoll while editing
- [ ] Save and load user://clips/*.json in the same schema as embrace.json
- [ ] Director plays a saved clip the same way it plays the built-in
- [ ] List stays built-in only until that loader exists

## Push

- [x] Commit the first version and planning notes to Fred4R/paperdoll-25d main
- [ ] Do not push leftover PNGs
- [ ] Facing swap is not in this commit

## Not in this first version

- [ ] Second choosable NPC
- [ ] Greeting or hand-hold clips
- [ ] Dialogue
- [ ] Day and night, needs, world save
- [ ] Multiplayer
- [ ] 3D character meshes
- [ ] AnimationPlayer as a second clip system
