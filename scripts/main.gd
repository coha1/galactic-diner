class_name Main
extends Node


var _shop_ui: ShopUI
var _diner_room: DinerRoom

var _shop_ui_scene: PackedScene
var _diner_room_scene: PackedScene


func _ready() -> void:
	_shop_ui_scene = load("res://scenes/shop_ui.tscn")
	_diner_room_scene = load("res://scenes/diner_room.tscn")
	GameData.reset_for_new_game()
	_enter_shop_phase()


func _enter_shop_phase() -> void:
	if _diner_room != null:
		_diner_room.queue_free()
		_diner_room = null

	_shop_ui = _shop_ui_scene.instantiate()
	add_child(_shop_ui)
	_shop_ui.day_started.connect(_on_day_started)


func _on_day_started() -> void:
	_shop_ui.queue_free()
	_shop_ui = null

	_diner_room = _diner_room_scene.instantiate()
	add_child(_diner_room)
	_diner_room.day_ended.connect(_on_day_ended)
	_diner_room.start_day()


func _on_day_ended() -> void:
	_enter_shop_phase()
