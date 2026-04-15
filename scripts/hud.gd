class_name HUD
extends CanvasLayer


@onready var _day_label: Label          = $HUDRoot/TopBar/TopHBox/DayMargin/DayLabel
@onready var _timer_label: Label        = $HUDRoot/TopBar/TopHBox/TimerLabel
@onready var _earnings_label: Label     = $HUDRoot/TopBar/TopHBox/EarnMargin/EarningsLabel
@onready var _log_scroll: ScrollContainer = $HUDRoot/LogPanel/LogInner/LogVBox/LogScroll
@onready var _log_label: RichTextLabel  = $HUDRoot/LogPanel/LogInner/LogVBox/LogScroll/LogLabel


func set_day(day_num: int) -> void:
	_day_label.text = "Day %d" % day_num


func update_timer(seconds: int) -> void:
	_timer_label.text = "Time: %ds" % seconds


func update_earnings(amount: int) -> void:
	_earnings_label.text = "Earned: $%d" % amount


func append_log(message: String) -> void:
	_log_label.append_text(message + "\n")
	_scroll_to_bottom()


func _scroll_to_bottom() -> void:
	await get_tree().process_frame
	if is_instance_valid(_log_scroll):
		_log_scroll.scroll_vertical = int(_log_scroll.get_v_scroll_bar().max_value)
