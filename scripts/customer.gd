class_name Customer
extends Node3D


const ALIEN_TYPES: Array[String] = [
	"Glorpian", "Zorbite", "Fluxoid", "Narvax",
	"Quiblon", "Crystalid", "Vexling", "Molthor",
	"Blorbax", "Splurgin",
]

const ALIEN_COLORS: Array[Color] = [
	Color(0.30, 0.78, 0.36),
	Color(0.72, 0.32, 0.80),
	Color(0.28, 0.62, 0.90),
	Color(0.90, 0.60, 0.15),
	Color(0.72, 0.22, 0.22),
	Color(0.22, 0.78, 0.68),
	Color(0.88, 0.88, 0.20),
	Color(0.52, 0.30, 0.90),
]

## Capsule cylinder height (total height = height + 2 * radius).
const CAPSULE_HEIGHT: float = 1.1

## Capsule end-cap radius.
const CAPSULE_RADIUS: float = 0.28

var alien_type: String = ""


func _ready() -> void:
	alien_type = ALIEN_TYPES[randi() % ALIEN_TYPES.size()]
	var body_color := ALIEN_COLORS[randi() % ALIEN_COLORS.size()]
	_build_visuals(body_color)


func _build_visuals(body_color: Color) -> void:
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = CAPSULE_RADIUS
	capsule.height = CAPSULE_HEIGHT
	body.mesh = capsule
	# Center the capsule so its base sits at y = 0.
	body.position = Vector3(0.0, CAPSULE_RADIUS + CAPSULE_HEIGHT / 2.0, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	body.material_override = mat
	add_child(body)

	var name_label := Label3D.new()
	name_label.text = alien_type
	name_label.pixel_size = 0.008
	name_label.font_size = 42
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.no_depth_test = true
	name_label.modulate = Color.WHITE
	name_label.position = Vector3(0.0, CAPSULE_RADIUS * 2.0 + CAPSULE_HEIGHT + 0.15, 0.0)
	add_child(name_label)
