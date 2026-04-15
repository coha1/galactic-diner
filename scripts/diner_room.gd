class_name DinerRoom
extends Node3D


signal day_ended


## Horizontal distance from focal point to camera.
const ORBIT_RADIUS: float = 12.0

## Camera height above the world origin.
const ORBIT_HEIGHT: float = 10.0

## World-space point the camera always aims at (low-center of room).
const FOCAL_POINT := Vector3(0.0, 0.5, 0.0)

## Starting orbit angle in radians. PI * 0.25 places camera at the south-east corner.
const ORBIT_START_ANGLE: float = PI * 0.25

## Radians per second when rotating with keyboard.
const KEYBOARD_ORBIT_SPEED: float = 1.8

## Radians of orbit per pixel of right-click mouse drag.
const MOUSE_ORBIT_SENSITIVITY: float = 0.006

## Room boundary used to decide which walls to show. Match the wall positions in diner_room.tscn.
const ROOM_WALL_X: float = 8.0
const ROOM_WALL_Z: float = 6.0

## Predefined table positions on the diner floor (world-space, y = 0).
const TABLE_POSITIONS: Array[Vector3] = [
	Vector3(-5.0, 0.0, -3.5),
	Vector3(-1.7, 0.0, -3.5),
	Vector3( 1.7, 0.0, -3.5),
	Vector3( 5.0, 0.0, -3.5),
	Vector3(-5.0, 0.0, -0.5),
	Vector3(-1.7, 0.0, -0.5),
	Vector3( 1.7, 0.0, -0.5),
	Vector3( 5.0, 0.0, -0.5),
]

## Staff home positions (set before add_child so _ready captures them).
const COOK_POSITION   := Vector3(-2.5, 0.0, 3.8)
const SERVER_POSITION := Vector3(0.0,  0.0, 1.0)

## Where customers spawn / depart (entrance on the west wall).
const DOOR_POSITION := Vector3(-7.2, 0.0, 0.0)

## Where the cook stands while operating the cooktop.
const COOK_COOKTOP_POS := Vector3(-2.5, 0.0, 5.0)

## Kitchen-side position where the cook stands to drop off food.
const STATION_COOK_APPROACH := Vector3(3.0, 0.0, 2.7)

## Exact surface position on the counter where the food plate is set down.
const STATION_FOOD_POS := Vector3(3.0, 0.95, 2.0)

## Dining-room side position where the server stands to pick up food.
const STATION_SERVER_APPROACH := Vector3(3.0, 0.0, 1.2)

# ─── Scene node references (populated by @onready before _ready fires) ────────

@onready var _camera: Camera3D              = $Camera
@onready var _customers_container: Node3D   = $CustomersContainer
@onready var _wall_north: Node3D            = $Room/WallNorth
@onready var _wall_south: Node3D            = $Room/WallSouth
@onready var _wall_east: Node3D             = $Room/WallEast
@onready var _wall_west: Node3D             = $Room/WallWest

# ─── Runtime state ────────────────────────────────────────────────────────────

var _tables: Array[Table] = []
var _cook: Cook
var _server: Server
var _hud: HUD

var _orbit_angle: float = ORBIT_START_ANGLE
var _day_timer: Timer
var _spawn_timer: Timer
var _time_remaining: float = 0.0

var _table_scene: PackedScene
var _customer_scene: PackedScene


func _ready() -> void:
	_table_scene   = load("res://scenes/table.tscn")
	_customer_scene = load("res://scenes/customer.tscn")

	_build_tables()
	_build_staff()

	# Position camera at the starting orbit angle.
	_update_camera()
	_update_wall_visibility()

	_hud = load("res://scenes/hud.tscn").instantiate()
	add_child(_hud)
	EventLog.event_logged.connect(_hud.append_log)


func _process(delta: float) -> void:
	if _day_timer != null and not _day_timer.is_stopped():
		_time_remaining = _day_timer.time_left
		_hud.update_time(_time_remaining)
		_hud.update_earnings(int(GameData.day_earnings))

	var orbit_input := Input.get_axis("camera_rotate_left", "camera_rotate_right")
	if orbit_input != 0.0:
		_orbit_angle += orbit_input * KEYBOARD_ORBIT_SPEED * delta
		_update_camera()
		_update_wall_visibility()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_orbit_angle += event.relative.x * MOUSE_ORBIT_SENSITIVITY
		_update_camera()
		_update_wall_visibility()


func start_day() -> void:
	GameData.day_number += 1
	GameData.day_earnings = 0.0
	_time_remaining = GameData.day_duration
	_hud.set_day(GameData.day_number)
	_hud.update_time(GameData.day_duration)
	_hud.update_earnings(0)
	EventLog.log_event("=== Day %d begins! ===" % GameData.day_number)

	_day_timer = Timer.new()
	_day_timer.one_shot = true
	_day_timer.wait_time = GameData.day_duration
	_day_timer.timeout.connect(_on_day_timer_timeout)
	add_child(_day_timer)
	_day_timer.start()

	_spawn_timer = Timer.new()
	_spawn_timer.one_shot = false
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(_spawn_timer)
	_start_next_spawn()


# ─── Camera ───────────────────────────────────────────────────────────────────

func _update_camera() -> void:
	var x := cos(_orbit_angle) * ORBIT_RADIUS
	var z := sin(_orbit_angle) * ORBIT_RADIUS
	_camera.global_position = Vector3(x, ORBIT_HEIGHT, z)
	_camera.look_at(FOCAL_POINT, Vector3.UP)


func _update_wall_visibility() -> void:
	var cx := _camera.global_position.x
	var cz := _camera.global_position.z
	_wall_west.visible  = cx > -ROOM_WALL_X
	_wall_east.visible  = cx <  ROOM_WALL_X
	_wall_north.visible = cz > -ROOM_WALL_Z
	_wall_south.visible = cz <  ROOM_WALL_Z


# ─── Scene construction (staff + tables are still dynamic) ────────────────────

func _build_tables() -> void:
	var count := mini(GameData.table_count, TABLE_POSITIONS.size())
	for i in count:
		var table: Table = _table_scene.instantiate()
		table.table_id = i + 1
		table.position = TABLE_POSITIONS[i]
		add_child(table)
		_tables.append(table)
		_connect_table_signals(table)


func _connect_table_signals(table: Table) -> void:
	table.customer_seated.connect(_on_table_customer_seated)
	table.order_taken.connect(_on_table_order_taken)
	table.customer_finished_eating.connect(_on_table_customer_finished_eating)


func _build_staff() -> void:
	if GameData.has_cook:
		_cook = Cook.new()
		_cook.position = COOK_POSITION
		_cook.cooktop_position = COOK_COOKTOP_POS
		_cook.station_approach_position = STATION_COOK_APPROACH
		_cook.station_food_pos = STATION_FOOD_POS
		add_child(_cook)
		_cook.food_at_station.connect(_on_cook_food_at_station)

	if GameData.has_server:
		_server = Server.new()
		_server.position = SERVER_POSITION
		_server.pickup_station_position = STATION_SERVER_APPROACH
		add_child(_server)


# ─── Simulation helpers ───────────────────────────────────────────────────────

func get_available_table() -> Table:
	for table in _tables:
		if table.is_available():
			return table
	return null


func _start_next_spawn() -> void:
	_spawn_timer.wait_time = randf_range(GameData.spawn_interval_min, GameData.spawn_interval_max)
	_spawn_timer.start()


func _on_spawn_timer_timeout() -> void:
	if _day_timer == null or _day_timer.is_stopped():
		return
	_spawn_customer()
	_start_next_spawn()


func _spawn_customer() -> void:
	var table := get_available_table()
	if table == null:
		EventLog.log_event("No tables available — a visitor turns back at the door")
		return

	var customer: Customer = _customer_scene.instantiate()
	_customers_container.add_child(customer)
	customer.global_position = DOOR_POSITION

	table.is_reserved = true
	EventLog.log_event("A %s enters and heads to Table %d" % [customer.alien_type, table.table_id])

	var target := table.global_position + Vector3(0.0, 0.0, 0.8)
	var dist := customer.global_position.distance_to(target)
	var duration := maxf(dist / GameData.customer_walk_speed, 0.1)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(customer, "global_position", target, duration)
	tween.tween_callback(func() -> void: _on_customer_arrived_at_table(customer, table))


func _on_customer_arrived_at_table(customer: Customer, table: Table) -> void:
	table.is_reserved = false
	table.seat_customer(customer)
	EventLog.log_event("%s is seated at Table %d" % [customer.alien_type, table.table_id])


# ─── Table signal handlers ────────────────────────────────────────────────────

func _on_table_customer_seated(table: Table) -> void:
	if _server == null:
		EventLog.log_event("No server hired — Table %d will wait" % table.table_id)
		return
	_server.add_task(Server.TaskType.TAKE_ORDER, table)


func _on_table_order_taken(table: Table) -> void:
	if _cook == null:
		EventLog.log_event("No cook hired — Table %d order is stuck" % table.table_id)
		return
	_cook.add_order(table)


func _on_cook_food_at_station(food: Node3D, table: Table) -> void:
	if _server == null:
		EventLog.log_event("No server — food for Table %d waits at the station" % table.table_id)
		return
	_server.add_task(Server.TaskType.DELIVER_FOOD, table, food)


func _on_table_customer_finished_eating(table: Table) -> void:
	var customer := table.seated_customer
	if customer == null:
		return
	var tip := randf() * GameData.max_tip
	var total := GameData.meal_payment + tip
	GameData.add_earnings(total)
	EventLog.log_event(
		"Table %d paid $%.0f (+$%.0f tip). %s heads for the exit!" % [
			table.table_id, GameData.meal_payment, tip, customer.alien_type
		]
	)
	table.clear()

	var dist := customer.global_position.distance_to(DOOR_POSITION)
	var duration := maxf(dist / GameData.customer_walk_speed, 0.1)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(customer, "global_position", DOOR_POSITION, duration)
	tween.tween_callback(customer.queue_free)


func _on_day_timer_timeout() -> void:
	_spawn_timer.stop()
	EventLog.log_event(
		"=== Day %d over! Total earned: $%d ===" % [GameData.day_number, int(GameData.day_earnings)]
	)
	await get_tree().create_timer(2.0).timeout
	day_ended.emit()
