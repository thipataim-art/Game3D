extends CanvasLayer

@onready var score_label: Label = $"TopBar/HBoxContainer/ScoreLabel"
@onready var timer_label: Label = $"TopBar/HBoxContainer/TimerLabel"
@onready var big_msg: Label = $"CenterMessage/BigMessage"
@onready var toast_label: Label = $"Toast/ToastLabel"
@onready var dim: ColorRect = $"Dim"
@onready var retry_box: VBoxContainer = $"Retry"

var _tween: Tween

func _ready() -> void:
	# เริ่มต้นซ่อนทุกอย่างที่ไม่จำเป็น
	dim.visible = false
	retry_box.visible = false
	if timer_label:
		timer_label.text = ""
	# โชว์ “เริ่ม!” สั้น ๆ
	show_big_message("เริ่ม!", 0.8)

func reset_ui() -> void:
	dim.visible = false
	retry_box.visible = false
	if score_label and score_label.has_method("reset"):
		score_label.reset()
	if timer_label:
		timer_label.text = ""

func set_score(value: int) -> void:
	if score_label:
		score_label.text = "คะแนน: %d" % value

func show_big_message(msg: String, time_sec: float = 1.2) -> void:
	if not big_msg: return
	big_msg.text = msg
	big_msg.modulate.a = 1.0
	big_msg.visible = true
	if _tween: _tween.kill()
	_tween = create_tween()
	_tween.tween_property(big_msg, "modulate:a", 0.0, time_sec).set_delay(0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).finished.connect(func():
		big_msg.visible = false
	)

func show_toast(msg: String, time_sec: float = 1.2) -> void:
	if not toast_label: return
	toast_label.text = msg
	toast_label.modulate.a = 1.0
	toast_label.visible = true
	var t = create_tween()
	t.tween_property(toast_label, "modulate:a", 0.0, time_sec).set_delay(0.2).finished.connect(func():
		toast_label.visible = false
	)

func show_retry() -> void:
	dim.visible = true
	retry_box.visible = true

func hide_retry() -> void:
	dim.visible = false
	retry_box.visible = false
