extends StaticBody2D

@export var scene_tujuan: String = "res://warung_mpok_wati.tscn"
@onready var icon_e = $AreaPintu/IconE
@onready var sprite = $SpriteRumah
@onready var area_pintu = $AreaPintu
@onready var titik_jalan = $TitikJalanMasuk

var sedang_transisi = false
var player_di_area = false
var player_ref = null

var start_y: float
var timer: float = 0.0
@export var amplitude: float = 5.0
@export var speed: float = 5.0

func _ready():
	if icon_e:
		icon_e.visible = false
		start_y = icon_e.position.y
	area_pintu.body_entered.connect(_on_body_entered)
	area_pintu.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		player_di_area = true
		player_ref = body
		if icon_e:
			icon_e.visible = true

func _on_body_exited(body):
	if body.is_in_group("Player"):
		player_di_area = false
		player_ref = null
		if icon_e and not sedang_transisi:
			icon_e.visible = false

func _process(delta):
	if icon_e and icon_e.visible:
		timer += delta * speed
		icon_e.position.y = start_y + sin(timer) * amplitude

	if sedang_transisi:
		return
	if player_di_area:
		if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_E):
			masuk_rumah()

func masuk_rumah():
	sedang_transisi = true
	if icon_e:
		icon_e.visible = false

	if player_ref == null:
		return

	player_ref.jalan_ke_titik(titik_jalan.global_position)
	await player_ref.sampai_tujuan

	if sprite and sprite.sprite_frames.has_animation("buka_pintu"):
		sprite.play("buka_pintu")
		await sprite.animation_finished

	TransitionScreen.transition_to(scene_tujuan)
