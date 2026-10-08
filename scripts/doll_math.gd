extends RefCounted
class_name DollMath
## Shared formulas. Angle blend is the shortest arc. View is a dot product.
## Two-bone reach is the law of cosines. Gait phase is distance over stride.

const STRIDE_M := 1.7
const SIDE_DOT := 0.5

static func shortest_delta(from_angle: float, to_angle: float) -> float:
	return wrapf(to_angle - from_angle, -PI, PI)

static func smoothstep(weight: float) -> float:
	var t := clampf(weight, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

static func blend_angle(from_angle: float, to_angle: float, weight: float) -> float:
	return from_angle + shortest_delta(from_angle, to_angle) * smoothstep(weight)

static func frame_point(viewport_size: Vector2, margin: float) -> Vector2:
	return Vector2(-margin, viewport_size.y * 0.36)

static func frame_pair(viewport_size: Vector2, margin: float) -> Array:
	var y := viewport_size.y * 0.36
	return [Vector2(-margin, y), Vector2(viewport_size.x + margin, y)]

static func arrive(offset: Vector3, slow_radius: float) -> Vector3:
	var flat := offset
	flat.y = 0.0
	var dist := flat.length()
	if dist <= 0.12:
		return Vector3.ZERO
	var speed := 1.0
	if dist < slow_radius:
		speed = dist / slow_radius
	return flat.normalized() * speed

static func view_from_dot(facing: float) -> String:
	if facing < 0.0:
		return "back"
	if facing < SIDE_DOT:
		return "side"
	return "front"

static func gait_phase(distance_m: float) -> float:
	if STRIDE_M <= 0.0:
		return 0.0
	return fposmod(distance_m / STRIDE_M, 1.0)

static func elbow_angle(len_a: float, len_b: float, reach: float) -> float:
	var span := clampf(reach, 0.001, len_a + len_b - 0.001)
	var cos_elbow := clampf((len_a * len_a + len_b * len_b - span * span) / (2.0 * len_a * len_b), -1.0, 1.0)
	return PI - acos(cos_elbow)
