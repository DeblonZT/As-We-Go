extends Area2D

@export var scene_tujuan: String = "res://node_2d.tscn"
@export var id_pintu_keluar: String = "warungMW" # <-- Isi nama unik di Inspector (misal: "rumah_a", "rumah_b", dll)
@onready var icon_e: Sprite2D = $Sprite2D
@onready var titik_berhenti: Marker2D = $TitikBerhenti  

var sedang_transisi = false
var player_di_area = false
var player_ref = null

var start_y: float
var timer: float = 0.0
@export var amplitude: float = 5.0  
@export var speed: float = 5.0       

func _ready() -> void:
	if icon_e:
		icon_e.visible = false
		start_y = icon_e.position.y
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if icon_e and icon_e.visible:
		timer += delta * speed
		icon_e.position.y = start_y + sin(timer) * amplitude

	if sedang_transisi:
		return
		
	if player_di_area:
		if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_E):
			mulai_transisi_masuk()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_di_area = true
		player_ref = body
		if icon_e:
			icon_e.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_di_area = false
		player_ref = null
		if icon_e and not sedang_transisi:
			icon_e.visible = false

func mulai_transisi_masuk() -> void:
	sedang_transisi = true
	if icon_e:
		icon_e.visible = false

	if player_ref == null:
		return

	if player_ref.has_method("jalan_ke_titik") and titik_berhenti:
		player_ref.jalan_ke_titik(titik_berhenti.global_position)
		if player_ref.has_signal("sampai_tujuan"):
			await player_ref.sampai_tujuan

	if player_ref.has_method("atur_arah_menghadap"):
		player_ref.atur_arah_menghadap("atas")
	
	if player_ref.has_method("mainkan_animasi"):
		player_ref.mainkan_animasi("diam")

	await get_tree().create_timer(0.2).timeout

	# KIRIM ID PINTU SAAT MELAKUKAN TRANSISI
	if TransitionScreen:
		TransitionScreen.transition_to(scene_tujuan, id_pintu_keluar)
	else:
		get_tree().change_scene_to_file(scene_tujuan)
