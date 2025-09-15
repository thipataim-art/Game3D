extends Label

signal changed(value: int)

var score: int = 0

func _ready() -> void:
	reset()

func reset() -> void:
	score = 0
	text = "Score: 0"

func add(n: int = 1) -> void:
	score += n
	text = "Score: %d" % score
	changed.emit(score)

func _on_mob_squashed() -> void:
	add(1)  # <<< เพิ่มทีละ 1 ชัดเจน
