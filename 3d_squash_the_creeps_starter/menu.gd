extends Control

@export var game_scene: PackedScene  # ลาก res://main.tscn มาใส่ใน Inspector

@onready var background: TextureRect = get_node_or_null("Background")
@onready var start_btn: Button = get_node_or_null("Center/VBox/StartButton") as Button
@onready var back_btn: Button = get_node_or_null("Center/VBox/BackButton") as Button
@onready var exit_btn: Button = get_node_or_null("Center/VBox/ExitButton") as Button  # fallback
@onready var fade: ColorRect = get_node_or_null("Fade") as ColorRect
@onready var bgm: AudioStreamPlayer = get_node_or_null("MenuBGM") as AudioStreamPlayer

func _ready() -> void:
	# พื้นหลัง (กันบังปุ่ม)
	if background:
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# เฟด
	if fade:
		fade.color.a = 0.0

	# ปุ่ม Start
	if start_btn and not start_btn.pressed.is_connected(_on_start):
		start_btn.pressed.connect(_on_start)
	if start_btn:
		start_btn.grab_focus()

	# ปุ่ม Back: ใช้ BackButton ถ้ามี ไม่งั้นใช้ ExitButton แทน
	var back: Button = back_btn if back_btn else exit_btn
	if back:
		back.text = "Back"
		if not back.pressed.is_connected(_on_back):
			back.pressed.connect(_on_back)

	# เล่นเพลงในเมนู (เว็บต้องรอ user gesture)
	if bgm and bgm.stream and not OS.has_feature("web") and not bgm.playing:
		bgm.play()

func _unhandled_input(event: InputEvent) -> void:
	# ครั้งแรกบนเว็บต้องมีการกดก่อนถึงจะเล่นเสียงได้
	if OS.has_feature("web") and bgm and bgm.stream and not bgm.playing and event.is_pressed():
		bgm.play()

	if event.is_action_pressed("ui_accept"):
		_on_start()
	elif event.is_action_pressed("ui_cancel"):
		_on_back()

func _on_start() -> void:
	# ถ้าอยากให้เพลงยังเล่นต่อไปที่ main ให้ 'ไม่' stop() ตรงนี้
	if bgm and bgm.playing:
		bgm.stop()

	if game_scene == null:
		push_error("ยังไม่ได้ตั้งค่า 'game_scene' ในเมนู")
		return

	if fade:
		var t := create_tween()
		t.tween_property(fade, "color:a", 1.0, 0.25)
		t.finished.connect(func(): get_tree().change_scene_to_packed(game_scene))
	else:
		get_tree().change_scene_to_packed(game_scene)

func _on_back() -> void:
	# บนเว็บ: ย้อนหน้าเบราว์เซอร์
	if OS.has_feature("web"):
		JavaScriptBridge.eval("if(history.length>1){history.back();}")
	else:
		get_tree().quit()
