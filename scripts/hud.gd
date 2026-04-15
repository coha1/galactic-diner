class_name HUD
extends CanvasLayer


## Diner opening time in 24-hour float hours (7 = 7:00 AM).
const OPEN_HOUR: float  = 7.0
## Diner closing time in 24-hour float hours (22 = 10:00 PM).
const CLOSE_HOUR: float = 22.0

@onready var _day_label: Label            = $HUDRoot/TopBar/TopHBox/DayMargin/DayLabel
@onready var _timer_label: Label          = $HUDRoot/TopBar/TopHBox/TimerLabel
@onready var _earnings_label: Label       = $HUDRoot/TopBar/TopHBox/EarnMargin/EarningsLabel
@onready var _log_scroll: ScrollContainer = $HUDRoot/LogPanel/LogInner/LogVBox/LogScroll
@onready var _log_label: RichTextLabel    = $HUDRoot/LogPanel/LogInner/LogVBox/LogScroll/LogLabel


func set_day(day_num: int) -> void:
	_day_label.text = "Day %d" % day_num


## Pass the seconds remaining in the day; the label displays a 12-hour clock
## that runs from OPEN_HOUR (opening) to CLOSE_HOUR (closing).
func update_time(time_remaining: float) -> void:
	_timer_label.text = _format_game_time(time_remaining)


func update_earnings(amount: int) -> void:
	_earnings_label.text = "Earned: $%d" % amount


func append_log(message: String) -> void:
	_log_label.append_text(message + "\n")
	_scroll_to_bottom()


# ─── Helpers ──────────────────────────────────────────────────────────────────

func _format_game_time(time_remaining: float) -> String:
	# progress 0 = opening time, progress 1 = closing time.
	var progress := 1.0 - clampf(time_remaining / GameData.day_duration, 0.0, 1.0)
	var game_hour := OPEN_HOUR + progress * (CLOSE_HOUR - OPEN_HOUR)
	var hour   := int(game_hour)
	var minute := int((game_hour - float(hour)) * 60.0)
	var is_pm  := hour >= 12
	var disp   := hour % 12
	if disp == 0:
		disp = 12
	return "%d:%02d %s" % [disp, minute, "PM" if is_pm else "AM"]


func _scroll_to_bottom() -> void:
	await get_tree().process_frame
	if is_instance_valid(_log_scroll):
		_log_scroll.scroll_vertical = int(_log_scroll.get_v_scroll_bar().max_value)
