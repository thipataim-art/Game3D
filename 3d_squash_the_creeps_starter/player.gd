extends CharacterBody3D

signal hit

@export var speed: float = 14.0
@export var fall_acceleration: float = 75.0
@export var jump_impulse: float = 20.0
@export var bounce_impulse: float = 16.0
@export var invuln_time: float = 0.8   # อมตะช่วงเริ่ม (วินาที)

var target_velocity: Vector3 = Vector3.ZERO
var is_dead: bool = false
var invuln_until: float = 0.0

func _ready() -> void:
	invuln_start()

	# ถ้าใช้ MobDetector แล้วเด้งผิด ๆ อยากปิดเลย ให้ uncomment 3 บรรทัดนี้
	# if has_node("MobDetector"):
	# 	var md: Area3D = $"MobDetector"
	# 	if md.is_connected("body_entered", Callable(self, "_on_mob_detector_body_entered")): md.disconnect("body_entered", Callable(self, "_on_mob_detector_body_entered"))

func invuln_start() -> void:
	invuln_until = float(Time.get_ticks_msec()) / 1000.0 + invuln_time

func _physics_process(delta: float) -> void:
	var direction := Vector3.ZERO
	if Input.is_action_pressed("move_right"):  direction.x += 1.0
	if Input.is_action_pressed("move_left"):   direction.x -= 1.0
	if Input.is_action_pressed("move_back"):   direction.z += 1.0
	if Input.is_action_pressed("move_forward"):direction.z -= 1.0

	if direction != Vector3.ZERO:
		direction = direction.normalized()
		$Pivot.basis = Basis.looking_at(direction)
		if has_node("AnimationPlayer"): $AnimationPlayer.speed_scale = 4.0
	else:
		if has_node("AnimationPlayer"): $AnimationPlayer.speed_scale = 1.0

	# ระนาบ
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed

	# กระโดด/ตก
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		target_velocity.y = jump_impulse
	elif not is_on_floor():
		target_velocity.y -= fall_acceleration * delta

	# --- เก็บความเร็วแกน Y ก่อน move_and_slide() ---
	var pre_vy := target_velocity.y

	velocity = target_velocity
	move_and_slide()

	# ลูกเล่นเอียงหัวตามแกน Y
	$Pivot.rotation.x = PI / 6.0 * clamp(velocity.y / jump_impulse, -1.0, 1.0)

	# ตรวจชนหลังเคลื่อน
	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		var other := col.get_collider()
		if other == null: continue
		if other.is_in_group("mob"):
			var n := col.get_normal()
			# เหยียบหัว: ต้องกำลังลงมาก่อนชน และชนจากด้านบนพอสมควร
			var stomp := (pre_vy < 0.0) and (Vector3.UP.dot(n) > 0.1)
			if stomp:
				if other.has_method("squash"): other.squash()
				target_velocity.y = bounce_impulse
				velocity = target_velocity
			else:
				var now := float(Time.get_ticks_msec()) / 1000.0
				if not is_dead and now >= invuln_until:
					die()

# ถ้ายังใช้ MobDetector (Area3D) อยู่: ให้เด้งเมื่ออยู่เหนือมอนแทนที่จะตาย
func _on_mob_detector_body_entered(body: Node3D) -> void:
	if body != null and body.is_in_group("mob"):
		var now := float(Time.get_ticks_msec()) / 1000.0
		if is_dead or now < invuln_until:
			return
		# ประมาณจากตำแหน่ง: ผู้เล่นอยู่สูงกว่ามอน + กำลังลง => นับว่าเหยียบ
		var above := global_position.y > body.global_position.y + 0.3
		if above and velocity.y < 0.0:
			if body.has_method("squash"): body.squash()
			target_velocity.y = bounce_impulse
			velocity = target_velocity
		else:
			die()

func die() -> void:
	if is_dead: return
	is_dead = true
	hit.emit()
	queue_free()
