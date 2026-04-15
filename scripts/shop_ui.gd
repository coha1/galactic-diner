class_name ShopUI
extends CanvasLayer


signal day_started


const MAX_TABLES := 8

@onready var _day_label: Label        = $Panel/Margin/VBox/DayLabel
@onready var _cash_label: Label       = $Panel/Margin/VBox/CashLabel
@onready var _tables_label: Label     = $Panel/Margin/VBox/TablesLabel
@onready var _cook_label: Label       = $Panel/Margin/VBox/CookLabel
@onready var _server_label: Label     = $Panel/Margin/VBox/ServerLabel
@onready var _buy_table_button: Button  = $Panel/Margin/VBox/BuyTableButton
@onready var _buy_cook_button: Button   = $Panel/Margin/VBox/BuyCookButton
@onready var _buy_server_button: Button = $Panel/Margin/VBox/BuyServerButton
@onready var _start_day_button: Button  = $Panel/Margin/VBox/StartDayButton
@onready var _warning_label: Label    = $Panel/Margin/VBox/WarningLabel


func _ready() -> void:
	# Stamp the actual costs from GameData onto the button labels.
	_buy_table_button.text  = "Buy Table  ($%d)"  % int(GameData.table_cost)
	_buy_cook_button.text   = "Hire Cook  ($%d)"  % int(GameData.cook_cost)
	_buy_server_button.text = "Hire Server  ($%d)" % int(GameData.server_cost)

	_buy_table_button.pressed.connect(_on_buy_table_pressed)
	_buy_cook_button.pressed.connect(_on_buy_cook_pressed)
	_buy_server_button.pressed.connect(_on_buy_server_pressed)
	_start_day_button.pressed.connect(_on_start_day_pressed)

	refresh()


func refresh() -> void:
	_day_label.text  = "Day %d — Shop Phase" % (GameData.day_number + 1)
	_cash_label.text = "Cash: $%d" % int(GameData.cash)

	_tables_label.text = "Tables owned: %d / %d" % [GameData.table_count, MAX_TABLES]
	_buy_table_button.disabled = (
		not GameData.can_afford(GameData.table_cost)
		or GameData.table_count >= MAX_TABLES
	)

	_cook_label.text = "Cook: Hired" if GameData.has_cook else "Cook: Not hired"
	_cook_label.add_theme_color_override(
		"font_color",
		Color(0.4, 0.9, 0.5) if GameData.has_cook else Color(0.7, 0.4, 0.4)
	)
	_buy_cook_button.disabled = GameData.has_cook or not GameData.can_afford(GameData.cook_cost)

	_server_label.text = "Server: Hired" if GameData.has_server else "Server: Not hired"
	_server_label.add_theme_color_override(
		"font_color",
		Color(0.4, 0.9, 0.5) if GameData.has_server else Color(0.7, 0.4, 0.4)
	)
	_buy_server_button.disabled = GameData.has_server or not GameData.can_afford(GameData.server_cost)

	_update_start_button()


func _update_start_button() -> void:
	var warnings: Array[String] = []

	if GameData.table_count == 0:
		warnings.append("Buy at least one table.")
	if not GameData.has_cook:
		warnings.append("Hire a cook.")
	if not GameData.has_server:
		warnings.append("Hire a server.")

	if warnings.is_empty():
		_warning_label.text = ""
		_start_day_button.disabled = false
	else:
		_warning_label.text = "Need: " + ", ".join(warnings)
		_start_day_button.disabled = true


func _on_buy_table_pressed() -> void:
	if not GameData.can_afford(GameData.table_cost):
		return
	GameData.spend(GameData.table_cost)
	GameData.table_count += 1
	refresh()


func _on_buy_cook_pressed() -> void:
	if GameData.has_cook or not GameData.can_afford(GameData.cook_cost):
		return
	GameData.spend(GameData.cook_cost)
	GameData.has_cook = true
	refresh()


func _on_buy_server_pressed() -> void:
	if GameData.has_server or not GameData.can_afford(GameData.server_cost):
		return
	GameData.spend(GameData.server_cost)
	GameData.has_server = true
	refresh()


func _on_start_day_pressed() -> void:
	day_started.emit()
