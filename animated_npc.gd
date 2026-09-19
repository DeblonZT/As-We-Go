extends AnimatedSprite2D

# Jalankan animasi "idle" secara otomatis begitu NPC muncul di game
func _ready() -> void:
	play("idle")
