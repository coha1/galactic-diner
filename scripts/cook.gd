class_name Cook
extends Node3D


## Emitted after the cook drops food at the pickup station.
## DinerRoom listens to this to dispatch the server.
signal food_at_station(food: Node3D, table: Table)


const CAPSULE_HEIGHT: float = 1.1
const CAPSULE_RADIUS: float = 0.28

## Uniform color for the cook's capsule body.
@export var body_color: Color = Color(0.90, 0.90, 0.86)

## Set by DinerRoom before add_child.
## World position where the cook stands while using the cooktop.
var cooktop_position: Vector3 = Vector3.ZERO

## Set by DinerRoom before add_child.
## World position (kitchen side) where the cook stands to drop food.
var station_approach_position: Vector3 = Vector3.ZERO

## Set by DinerRoom before add_child.
## Exact world position on the counter surface where the food plate is placed.
var station_food_pos: Vector3 = Vector3.ZERO

var _order_queue: Array[Table] = []
var _current_table: Table = null
var _is_busy: bool = false
var _home_position: Vector3
var _current_food: Food3D = null
var _status_label: Label3D


func _ready() -> void:
	# Capture home position before DinerRoom moves us anywhere else.
	_home_position = position
	_build_visuals()


func _build_visuals() -> void:
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = CAPSULE_RADIUS
	capsule.height = CAPSULE_HEIGHT
	body.mesh = capsule
	body.position = Vector3(0.0, CAPSULE_RADIUS + CAPSULE_HEIGHT / 2.0, 0.0)
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = body_color
	body.material_override = body_mat
	add_child(body)

	# Tall chef hat sitting on top of the capsule.
	var hat := MeshInstance3D.new()
	var hat_mesh := BoxMesh.new()
	hat_mesh.size = Vector3(0.38, 0.44, 0.38)
	hat.mesh = hat_mesh
	hat.position = Vector3(0.0, CAPSULE_RADIUS * 2.0 + CAPSULE_HEIGHT + 0.22, 0.0)
	var hat_mat := StandardMaterial3D.new()
	hat_mat.albedo_color = Color.WHITE
	hat.material_override = hat_mat
	add_child(hat)

	var role_label := Label3D.new()
	role_label.text = "COOK"
	role_label.pixel_size = 0.008
	role_label.font_size = 52
	role_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	role_label.no_depth_test = true
	role_label.modulate = Color(0.95, 0.95, 0.55)
	role_label.position = Vector3(0.0, CAPSULE_RADIUS * 2.0 + CAPSULE_HEIGHT + 0.85, 0.0)
	add_child(role_label)

	_status_label = Label3D.new()
	_status_label.text = "Idle"
	_status_label.pixel_size = 0.008
	_status_label.font_size = 38
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.no_depth_test = true
	_status_label.modulate = Color(0.80, 0.80, 0.60)
	_status_label.position = Vector3(0.0, CAPSULE_RADIUS * 2.0 + CAPSULE_HEIGHT + 1.15, 0.0)
	add_child(_status_label)


func add_order(table: Table) -> void:
	_order_queue.append(table)
	_try_cook_next()


func _try_cook_next() -> void:
	if _is_busy or _order_queue.is_empty():
		if not _is_busy:
			_status_label.text = "Idle"
		return
	_is_busy = true
	_current_table = _order_queue.pop_front()
	_status_label.text = "→ Cooktop"
	EventLog.log_event("Chef heading to cooktop for Table %d" % _current_table.table_id)
	_walk_to(cooktop_position, _on_arrived_at_cooktop)


## Tweens to target at staff_walk_speed, then fires callback.
func _walk_to(target: Vector3, callback: Callable) -> void:
	var dist := position.distance_to(target)
	var duration := maxf(dist / GameData.staff_walk_speed, 0.05)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(self, "position", target, duration)
	tween.tween_callback(callback)


func _on_arrived_at_cooktop() -> void:
	_status_label.text = "Cooking T%d" % _current_table.table_id
	EventLog.log_event("Chef started cooking for Table %d" % _current_table.table_id)
	_current_table.start_cooking()
	get_tree().create_timer(GameData.cook_time).timeout.connect(_on_cook_timer_timeout)


func _on_cook_timer_timeout() -> void:
	EventLog.log_event("Food is ready for Table %d" % _current_table.table_id)
	_current_table.mark_food_ready()

	# Spawn the food and attach it to the cook so it travels with them.
	_current_food = Food3D.new()
	add_child(_current_food)
	# Float food above the chef's hat so it's clearly visible.
	_current_food.position = Vector3(0.0, CAPSULE_RADIUS * 2.0 + CAPSULE_HEIGHT + 0.6, 0.0)

	_status_label.text = "→ Pickup station"
	EventLog.log_event("Chef carrying food to pickup station for Table %d" % _current_table.table_id)
	_walk_to(station_approach_position, _on_arrived_at_station)


func _on_arrived_at_station() -> void:
	# Detach food from the cook and place it at the precise counter position.
	var food := _current_food
	_current_food = null
	food.reparent(get_parent(), false)
	food.position = station_food_pos

	var table := _current_table
	_current_table = null

	EventLog.log_event("Chef placed food at pickup station for Table %d" % table.table_id)
	food_at_station.emit(food, table)

	_status_label.text = "Returning"
	_walk_to(_home_position, _on_arrived_home)


func _on_arrived_home() -> void:
	_is_busy = false
	_try_cook_next()
