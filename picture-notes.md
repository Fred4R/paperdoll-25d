# Art planning notes

Planning only. No new layers until Fred says to build.

## What the simulation can actually use

The billboard does not rotate a 3D body. It always faces the camera. A clip reads only if the layer set matches that view.

- First person and the embrace need a front set. The lens is on her face and chest.
- Walk needs a side set when the camera is beside her. GitHub has side SVGs. This folder does not.
- flip_h mirrors a set. It is not a back view and not a front view.
- Each limb is its own file, pivoted in paperdoll.tscn. A pretty full-body plate cannot be sampled by the JSON clock.

Current local layers are flat shapes. Body is 128×192. Arm is 14×56, skin #e8be96. The sampler rotates those pivots. New art has to keep that registration or the embrace keys are meaningless.

## Fields the next questions belong to

- Art direction: silhouette at billboard size, clothed vs bare, one woman or a cast.
- Technical art: canvas, pivot, front and side pairs, what the editor is allowed to swap.
- Animation: what the 4 second hold must read as from the chest-up camera.
- Character: which axes vary (hair, cloth, skin) and which stay fixed so clips are shared.
- Tools: generated layers vs traced plates, and who approves before wiring.

## Rig, not Blender (2026-10-07)

Modular body stays in Godot cut-out animation. Each part is a Sprite2D on a pivot or Bone2D. Front, side, and back are texture sets on the same pivots. Cloth hides with visible, not a new mesh. JSON sets rotation. No Blender metarig. Billboard stays the SubViewport on the Sprite3D.

- Reads about 30. Natural adult, 7 to 7.5 heads. Curvy. Not a child, not a doll: no oversized head, no baby features, no plastic shine.
- Long dark hair. Medium skin fill.
- Shirt and skirt stay on for the first embrace.
- Hold: arms around the viewer's back, hands mostly out of frame. Soft smile. Eyes on the lens.
- Sheet framing: chest-up hero. Full body still exists for registration.
- One revision, then accept or reject. Not wired until accepted.

- Reference comes from Fred's description. Do not invent her.
- Proportion: natural adult, about 7 to 7.5 heads.
- First embrace does not hide cloth. Shirt, skirt, and shoes stay on. Layers are still separate.
- First deliverable to approve: front set posed on the 4 second embrace clock. Not wired as final. Side and back after he accepts it.

Fred wants the mix sheet: flat-color cut-out vector. Local color, even contour, rounded limbs, drawn face as shapes, no gradients, no cast shadows. Not cel shading, not paint.

Production order before any wired layer:

1. Character brief for the first woman, from his reference.
2. Registration chart: head count, canvas, pivot map. Approved before drawing.
3. Front set only. Approved.
4. Side and back matched to that front.
5. Embrace clock tested on that set.
6. A second body only after the first clip reads.

- Views: front, side, and back. flip_h mirrors left and right. Back is its own set.
- Embrace may hide or swap cloth layers during the hold. Still an embrace.
- Women do not share one body. Each has her own torso and arm shapes. Clips may need per-body keys.
- New layers wait for a reference Fred describes or sends. Nothing is wired until he accepts the set.
- Style is not decided. Flat vector, illustrated vector, or painted layers.

Planning only. No new layers until Fred says to build.

Front body, front arms that can overlap the torso, face that reads at 0.25 m, side set wired from GitHub, clothing layers that survive a wrap. Editor UI stays later.
