class_name Server
extends Node3D


enum TaskType {
	TAKE_ORDER,
	DELIVER_FOOD,
}


class Task:
	var type: TaskType
	var table: Table
	var food: Node3D

	func _init(task_type: TaskType, target_table: Table, target_food: Node3D = null) -> void:
		type = task_type
		table = target_table
		food = target_food


const CAPSULE_HEIGHT: float = 1.1
const CAPSULE_RADIUS: float = 0.28

## Uniform color for the server's capsule body.
@export var body_color: Color = Color(0.70, 0.12, 0.12)

## Offset from a table's position where the server stands to serve it.
const TABLE_APPROACH_OFFSET := Vector3(0.0, 0.0, 1.05)

## Set by DinerRoom before add_child.
## World position (dining-room side of counter) where server picks up food.
var pickup_station_position: Vector3 = Vector3.ZERO

var _task_queue: Array[Task] = []
var _current_task: Task = null
var _is_busy: bool = false
var _home_position: Vector3
var _status_label: Label3D


func _ready() -> void:
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

	var role_label := Label3D.new()
	role_label.text = "SERVER"
	role_label.pixel_size = 0.008
	role_label.font_size = 52
	role_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	role_label.no_depth_test = true
	role_label.modulate = Color(0.95, 0.55, 0.55)
	role_label.position = Vector3(0.0, CAPSULE_RADIUS * 2.0 + CAPSULE_HEIGHT + 0.15, 0.0)
	add_child(role_label)

	_status_label = Label3D.new()
	_status_label.text = "Idle"
	_status_label.pixel_size = 0.008
	_status_label.font_size = 38
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.no_depth_test = true
	_status_label.modulate = Color(0.80, 0.80, 0.60)
	_status_label.position = Vector3(0.0, CAPSULE_RADIUS * 2.0 + CAPSULE_HEIGHT + 0.45, 0.0)
	add_child(_status_label)


func add_task(task_type: TaskType, table: Table, food: Node3D = null) -> void:
	_task_queue.append(Task.new(task_type, table, food))
	_try_process_next()


func _try_process_next() -> void:
	if _is_busy or _task_queue.is_empty():
		if not _is_busy:
			_status_label.text = "Idle"
		return
	_is_busy = true
	_current_task = _task_queue.pop_front()
	_start_task()


func _start_task() -> void:
	match _current_task.type:
		TaskType.TAKE_ORDER:
			_status_label.text = "→ T%d order" % _current_task.table.table_id
			EventLog.log_event("Server heading to Table %d to take order" % _current_task.table.table_id)
			_walk_to(_current_task.table.position + TABLE_APPROACH_OFFSET, _on_arrived_for_order)
		TaskType.DELIVER_FOOD:
			_status_label.text = "→ Pickup station"
			EventLog.log_event("Server heading to pickup station for Table %d" % _current_task.table.table_id)
			_walk_to(pickup_station_position, _on_arrived_at_station)


## Tweens to target at staff_walk_speed, then fires callback.
func _walk_to(target: Vector3, callback: Callable) -> void:
	var dist := position.distance_to(target)
	var duration := maxf(dist / GameData.staff_walk_speed, 0.05)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(self, "position", target, duration)
	tween.tween_callback(callback)


func _on_arrived_for_order() -> void:
	_current_task.table.take_order()
	EventLog.log_event("Server took order from Table %d" % _current_task.table.table_id)
	_status_label.text = "Returning"
	_walk_to(_home_position, _on_arrived_home)


func _on_arrived_at_station() -> void:
	# Pick up the food and reparent it to self so it follows during delivery.
	var food := _current_task.food
	if food != null and is_instance_valid(food):
		food.reparent(self, false)
		food.position = Vector3(0.0, CAPSULE_RADIUS * 2.0 + CAPSULE_HEIGHT + 0.6, 0.0)
	_status_label.text = "→ T%d food" % _current_task.table.table_id
	EventLog.log_event("Server picked up food, heading to Table %d" % _current_task.table.table_id)
	_walk_to(_current_task.table.position + TABLE_APPROACH_OFFSET, _on_arrived_at_table)


func _on_arrived_at_table() -> void:
	var food := _current_task.food
	if food != null and is_instance_valid(food):
		_current_task.table.receive_food(food)
	else:
		_current_task.table.deliver_food()
	EventLog.log_event("Food delivered to Table %d. Bon appétit!" % _current_task.table.table_id)
	_status_label.text = "Returning"
	_walk_to(_home_position, _on_arrived_home)


func _on_arrived_home() -> void:
	_is_busy = false
	_try_process_next()
