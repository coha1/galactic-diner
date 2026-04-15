class_name Food3D
extends Node3D


const PLATE_RADIUS: float = 0.22
const PLATE_HEIGHT: float = 0.04
const FOOD_RADIUS: float = 0.13

const FOOD_COLORS: Array[Color] = [
	Color(0.85, 0.45, 0.15),  # roasted orange
	Color(0.20, 0.68, 0.25),  # alien green
	Color(0.90, 0.80, 0.20),  # golden yellow
	Color(0.68, 0.20, 0.20),  # deep red
	Color(0.58, 0.44, 0.30),  # tan / beige
	Color(0.35, 0.60, 0.80),  # cosmic blue
]


func _ready() -> void:
	_build_visuals()


func _build_visuals() -> void:
	# Plate — flat white cylinder sitting at local y = 0.
	var plate := MeshInstance3D.new()
	var plate_mesh := CylinderMesh.new()
	plate_mesh.top_radius = PLATE_RADIUS
	plate_mesh.bottom_radius = PLATE_RADIUS
	plate_mesh.height = PLATE_HEIGHT
	plate.mesh = plate_mesh
	plate.position = Vector3(0.0, PLATE_HEIGHT / 2.0, 0.0)
	var plate_mat := StandardMaterial3D.new()
	plate_mat.albedo_color = Color(0.95, 0.94, 0.92)
	plate.material_override = plate_mat
	add_child(plate)

	# Food — colored sphere resting on top of the plate.
	var food_mesh_inst := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = FOOD_RADIUS
	sphere.height = FOOD_RADIUS * 2.0
	food_mesh_inst.mesh = sphere
	food_mesh_inst.position = Vector3(0.0, PLATE_HEIGHT + FOOD_RADIUS, 0.0)
	var food_mat := StandardMaterial3D.new()
	food_mat.albedo_color = FOOD_COLORS[randi() % FOOD_COLORS.size()]
	food_mesh_inst.material_override = food_mat
	add_child(food_mesh_inst)
