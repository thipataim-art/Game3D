extends Node

@export var mob_scene: PackedScene

@onready var player: Node3D = $"Ground/Player"
@onready var spawn_location: PathFollow3D = $"SpawnPath/SpawnLocation"
@onready var mob_timer: Timer = $MobTimer

# === เปลี่ยน path ให้ตรงกับภาพ ===
@onready var score_label: Label = $"UserInterface/TopBar/HBoxContainer/ScoreLabel"
@onready var timer_label: Label = $"UserInterface/TopBar/HBoxContainer/TimerLabel"
@onready var retry_ui: Control = $"UserInterface/Retry"

var elapsed_time: float = 0.0
var game_over: bool = false

func _ready() -> void:
	randomize()

	# UI เริ่มต้น
	if is_instance_valid(retry_ui):
		retry_ui.hide()
	if is_instance_valid(score_label) and score_label.has_method("reset"):
		score_label.reset()

	elapsed_time = 0.0
	_update_timer_label()

	# ต่อสัญญาณ player.hit → _on_player_hit (กันต่อซ้ำ)
	if is_instance_valid(player) and player.has_signal("hit"):
		if not player.hit.is_connected(_on_player_hit):
			player.hit.connect(_on_player_hit)

func _process(delta: float) -> void:
	if game_over:
		return
	elapsed_time += delta
	_update_timer_label()

func _update_timer_label() -> void:
	if not is_instance_valid(timer_label):
		return
	var total: int = int(elapsed_time)            # วินาทีสะสมทั้งหมด
	var mm:   int = int(floor(elapsed_time / 60.0))# นาที = ปัดลงจากทศนิยม
	var ss:   int = total % 60                     # วินาทีที่เหลือ 0..59
	timer_label.text = "%02d:%02d" % [mm, ss]

func _on_mob_timer_timeout() -> void:
	if mob_scene == null:
		push_error("mob_scene ยังไม่ได้ตั้งค่าใน Inspector")
		return
	if player == null:
		push_error('หาโหนด Player ไม่เจอ (คาดว่า path ควรเป็น "Ground/Player")')
		return
	if spawn_location == null:
		push_error('หาโหนด SpawnPath/SpawnLocation ไม่เจอ')
		return

	var mob := mob_scene.instantiate()

	# สุ่มตำแหน่งเกิด
	spawn_location.progress_ratio = randf()
	var spawn_pos: Vector3 = spawn_location.global_position
	var player_pos: Vector3 = player.global_position

	if mob.has_method("initialize"):
		mob.initialize(spawn_pos, player_pos)
	else:
		mob.global_position = spawn_pos

	# เชื่อมสัญญาณนับคะแนน (กันต่อซ้ำ)
	if mob.has_signal("squashed") and is_instance_valid(score_label) and score_label.has_method("_on_mob_squashed"):
		if not mob.squashed.is_connected(score_label._on_mob_squashed):
			mob.squashed.connect(score_label._on_mob_squashed)
	else:
		push_warning("หา UserInterface/.../ScoreLabel หรือเมธอด _on_mob_squashed ไม่พบ จึงไม่ได้เชื่อมสัญญาณ")

	add_child(mob)

func _on_player_hit() -> void:
	game_over = true
	if is_instance_valid(mob_timer):
		mob_timer.stop()
	if is_instance_valid(retry_ui):
		retry_ui.show()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and is_instance_valid(retry_ui) and retry_ui.visible:
		get_tree().reload_current_scene()
