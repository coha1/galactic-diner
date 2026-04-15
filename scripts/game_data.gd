extends Node


## Starting cash given to the player at the beginning of each run.
@export var starting_cash: float = 300.0

## Cost to place one table in the diner.
@export var table_cost: float = 50.0

## Cost to hire the cook.
@export var cook_cost: float = 100.0

## Cost to hire the server.
@export var server_cost: float = 75.0

## Fixed payment received when a customer completes a meal.
@export var meal_payment: float = 25.0

## Maximum random tip added on top of the meal payment.
@export var max_tip: float = 10.0

## Total length of one day in seconds.
@export var day_duration: float = 90.0

## Minimum seconds between customer spawn attempts.
@export var spawn_interval_min: float = 4.0

## Maximum seconds between customer spawn attempts.
@export var spawn_interval_max: float = 12.0

## Seconds the cook spends preparing a single meal.
@export var cook_time: float = 8.0

## Seconds a customer spends eating after food is delivered.
@export var eat_time: float = 6.0

## Walk speed for staff (cook and server) in world units per second.
@export var staff_walk_speed: float = 3.5

## Walk speed for customers in world units per second.
@export var customer_walk_speed: float = 2.5

var cash: float = 300.0
var day_number: int = 0
var table_count: int = 0
var has_cook: bool = false
var has_server: bool = false
var day_earnings: float = 0.0


func reset_for_new_game() -> void:
	cash = starting_cash
	day_number = 0
	table_count = 0
	has_cook = false
	has_server = false
	day_earnings = 0.0


func can_afford(cost: float) -> bool:
	return cash >= cost


func spend(amount: float) -> void:
	cash -= amount


func add_earnings(amount: float) -> void:
	day_earnings += amount
	cash += amount
