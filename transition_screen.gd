extends CanvasLayer

@onready var anim = $AnimationPlayer
@onready var color_rect = $ColorRect

# Variabel penyimpan info pintu asal
var target_spawn_id: String = ""

func _ready():
	# Pastikan saat game mulai, layar transparan (tidak hitam)
	color_rect.color.a = 0.0

# Menggunakan variadic/array (...) agar fungsi ini fleksibel 
# menerima 1 atau 2 argumen tanpa error 'Too many arguments'
func transition_to(scene_path: String, spawn_id: String = "") -> void:
	target_spawn_id = spawn_id
	print("Pindah ke scene: ", scene_path, " | Spawn ID: ", target_spawn_id)
	
	if anim.has_animation("fade_to_black"):
		anim.play("fade_to_black")
		await anim.animation_finished
	
	# Pindah Scene
	get_tree().change_scene_to_file(scene_path)
	
	# Fade In (Layar kembali terang/normal)
	if anim.has_animation("fade_to_black"):
		anim.play_backwards("fade_to_black")
		await anim.animation_finished
