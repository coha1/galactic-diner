class_name Table
extends Node3D


signal customer_seated(table: Table)
signal order_taken(table: Table)
signal food_marked_ready(table: Table)
signal customer_finished_eating(table: Table)


enum TableState {
	EMPTY,
	CUSTOMER_SEATED,
	ORDER_PLACED,
	COOKING,
	FOOD_READY,
	EATING,
}

## Width of the table surface mesh in world units.
@export var table_width: float = 1.4

## Depth of the table surface mesh in world units.
@export var table_depth: float = 1.0

var table_id: int = 0
var state: TableState = TableState.EMPTY
var seated_customer: Customer = null
## True while a customer is walking toward this table, preventing double-booking.
var is_reserved: bool = false
## Food node resting on this table; freed when the table is cleared.
var current_food: Node3D = null

var _top_material: StandardMaterial3D
var _state_label: Label3D
var _customer_label: Label3D
var _eat_timer: Timer

const STATE_COLORS: Dictionary = {
	TableState.EMPTY:           Color(0.35, 0.25, 0.15),
	TableState.CUSTOMER_SEATED: Color(0.55, 0.48, 0.08),
	TableState.ORDER_PLACED:    Color(0.18, 0.28, 0.65),
	TableState.COOKING:         Color(0.58, 0.32, 0.04),
	TableState.FOOD_READY:      Color(0.12, 0.55, 0.14),
	TableState.EATING:          Color(0.08, 0.42, 0.48),
}

const STATE_NAMES: Dictionary = {
	TableState.EMPTY:           "Empty",
	TableState.CUSTOMER_SEATED: "Seated",
	TableState.ORDER_PLACED:    "Ordering",
	TableState.COOKING:         "Cooking...",
	TableState.FOOD_READY:      "Food Ready!",
	TableState.EATING:          "Eating",
}

const LEG_COLOR := Color(0.28, 0.18, 0.10)
const LEG_HEIGHT: float = 0.78
const TOP_Y: float = 0.83


func _ready() -> void:
	_build_visuals()

	_eat_timer = Timer.new()
	_eat_timer.one_shot = true
	_eat_timer.timeout.connect(_on_eat_timer_timeout)
	add_child(_eat_timer)

	_refresh_visuals()


func _build_visuals() -> void:
	_add_leg(Vector3(-0.55, 0.0, -0.38))
	_add_leg(Vector3( 0.55, 0.0, -0.38))
	_add_leg(Vector3(-0.55, 0.0,  0.38))
	_add_leg(Vector3( 0.55, 0.0,  0.38))

	var top := MeshInstance3D.new()
	var top_mesh := BoxMesh.new()
	top_mesh.size = Vector3(table_width, 0.1, table_depth)
	top.mesh = top_mesh
	top.position = Vector3(0.0, TOP_Y, 0.0)
	_top_material = StandardMaterial3D.new()
	_top_material.albedo_color = STATE_COLORS[TableState.EMPTY]
	top.material_override = _top_material
	add_child(top)

	var id_label := Label3D.new()
	id_label.text = "Table %d" % table_id
	id_label.pixel_size = 0.008
	id_label.font_size = 52
	id_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	id_label.no_depth_test = true
	id_label.modulate = Color.WHITE
	id_label.position = Vector3(0.0, 1.25, 0.0)
	add_child(id_label)

	_state_label = Label3D.new()
	_state_label.pixel_size = 0.008
	_state_label.font_size = 42
	_state_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_state_label.no_depth_test = true
	_state_label.modulate = Color(0.95, 0.95, 0.7)
	_state_label.position = Vector3(0.0, 1.55, 0.0)
	add_child(_state_label)

	_customer_label = Label3D.new()
	_customer_label.pixel_size = 0.008
	_customer_label.font_size = 36
	_customer_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_customer_label.no_depth_test = true
	_customer_label.modulate = Color(0.65, 0.9, 0.65)
	_customer_label.position = Vector3(0.0, 1.82, 0.0)
	add_child(_customer_label)


func _add_leg(offset: Vector3) -> void:
	var leg := MeshInstance3D.new()
	var leg_mesh := BoxMesh.new()
	leg_mesh.size = Vector3(0.08, LEG_HEIGHT, 0.08)
	leg.mesh = leg_mesh
	leg.position = offset + Vector3(0.0, LEG_HEIGHT / 2.0, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = LEG_COLOR
	leg.material_override = mat
	add_child(leg)


func _refresh_visuals() -> void:
	if _top_material != null:
		_top_material.albedo_color = STATE_COLORS[state]
	if _state_label != null:
		_state_label.text = STATE_NAMES[state]
	if _customer_label != null:
		_customer_label.text = seated_customer.alien_type if seated_customer != null else ""


func is_empty() -> bool:
	return state == TableState.EMPTY


## Returns true only when this table can accept a new customer right now.
func is_available() -> bool:
	return state == TableState.EMPTY and not is_reserved


func seat_customer(customer: Customer) -> void:
	seated_customer = customer
	_set_state(TableState.CUSTOMER_SEATED)
	customer_seated.emit(self)


func take_order() -> void:
	if state != TableState.CUSTOMER_SEATED:
		printerr(get_path(), ": take_order called in wrong state: ", state)
		return
	_set_state(TableState.ORDER_PLACED)
	order_taken.emit(self)


func start_cooking() -> void:
	if state != TableState.ORDER_PLACED:
		printerr(get_path(), ": start_cooking called in wrong state: ", state)
		return
	_set_state(TableState.COOKING)


func mark_food_ready() -> void:
	if state != TableState.COOKING:
		printerr(get_path(), ": mark_food_ready called in wrong state: ", state)
		return
	_set_state(TableState.FOOD_READY)
	food_marked_ready.emit(self)


func deliver_food() -> void:
	if state != TableState.FOOD_READY:
		printerr(get_path(), ": deliver_food called in wrong state: ", state)
		return
	_set_state(TableState.EATING)
	_eat_timer.wait_time = GameData.eat_time
	_eat_timer.start()


## Called by the server when it physically carries food to the table.
## Reparents the food node onto the table surface and begins the eat timer.
func receive_food(food: Node3D) -> void:
	if state != TableState.FOOD_READY:
		printerr(get_path(), ": receive_food called in wrong state: ", state)
		return
	current_food = food
	food.reparent(self, false)
	# Table top face is at TOP_Y + half the top-mesh height (0.05).
	food.position = Vector3(0.0, TOP_Y + 0.05, 0.0)
	_set_state(TableState.EATING)
	_eat_timer.wait_time = GameData.eat_time
	_eat_timer.start()


func clear() -> void:
	if current_food != null:
		current_food.queue_free()
		current_food = null
	seated_customer = null
	is_reserved = false
	_set_state(TableState.EMPTY)


func _set_state(new_state: TableState) -> void:
	state = new_state
	_refresh_visuals()


func _on_eat_timer_timeout() -> void:
	customer_finished_eating.emit(self)
