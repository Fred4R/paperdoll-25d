# Picture notes

Drawing is in progress. Do not wait for another permission to draw the missing views.

## What the game can use

The picture does not rotate a 3D body. It always faces the camera. The hug only reads if the picture set matches that view.

- First person and the hug need a front set. The camera is on her face and chest.
- Walk needs a side set when the camera is beside her.
- A horizontal flip mirrors a set. It is not a back view and not a front view.
- Each limb is its own file, pivoted in `paperdoll.tscn`. A single full-body plate cannot be driven by the hug file.

Body is 128 by 192. Arm is 14 by 56. New pictures have to keep that registration or the hug keys do not land.

## Same paperdoll, own pictures

Every character uses the same paperdoll. Each woman has her own pictures. The first hug does not hide clothes. Shirt, skirt, and shoes stay on. Layers stay separate.

## First woman

About 30. Adult. Curvy. Not a child. Long dark hair. Medium skin. Shirt and skirt stay on. Arms around the viewer, hands mostly out of frame. Soft smile. Eyes on the camera. Chest-up sheet is accepted as good enough. Full body still exists so the pivots stay put.

Views to draw: front, side, back, and one diagonal. The other four views are flips.

Style already chosen: flat-color cut-out. Local color, even contour, rounded limbs, face drawn as shapes, no gradients, no cast shadows.

## Order

1. Front set for the first woman. Accepted.
2. Side, back, and diagonal matched to that front.
3. Hug clock tested on that set.
4. Second woman only after the first hug reads, with her own pictures on the same paperdoll.
