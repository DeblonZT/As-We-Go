extends Area2D

# Script ini dipasang di node RumahRani (Area2D) di map_4.tscn

@export var nama_marker_pulang: String = "Rani Pulang"

@onready var icon_e: Sprite2D = $IconE

var player_di_area: bool = false
var player_ref: Node2D = null
var sedang_proses: bool = false

var _timer_icon: float = 0.0
var _start_y_icon: float = 0.0
var _amplitude: float = 5.0
var _speed: float = 5.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if icon_e:
		_start_y_icon = icon_e.position.y
		icon_e.visible = false


func _process(delta: float) -> void:
	if icon_e and icon_e.visible:
		_timer_icon += delta * _speed
		icon_e.position.y = _start_y_icon + sin(_timer_icon) * _amplitude

	var tampilkan_icon: bool = (
		player_di_area
		and not sedang_proses
		and Cerita.punya_flag("rani_ikut_arka")
		and Cerita.objektif_aktif == "antar_rani_pulang"
		and not Cerita.punya_flag("rani_sudah_pulang")
		and not DialogBox.sedang_dialog
	)
	if icon_e:
		icon_e.visible = tampilkan_icon

	if tampilkan_icon and Input.is_action_just_pressed("interaksi"):
		_antar_rani_pulang()


func _antar_rani_pulang() -> void:
	if sedang_proses:
		return
	sedang_proses = true

	# Kunci gerak player
	var p = player_ref if (player_ref and is_instance_valid(player_ref)) else get_tree().get_first_node_in_group("Player")
	if p and p.has_method("set_bisa_gerak"):
		p.set_bisa_gerak(false)

	var rani = get_tree().get_first_node_in_group("Rani")

	# Marker posisi masuk rumah
	var map = get_tree().current_scene
	var marker = map.get_node_or_null(nama_marker_pulang) if map else null
	var pos_pulang = marker.global_position if marker else global_position

	# Rani berhenti ikut, jalan ke pintu, fade out
	if rani and is_instance_valid(rani):
		if rani.has_method("berhenti_ikut"):
			rani.berhenti_ikut()
		if rani.has_method("jalan_ke_titik"):
			await rani.jalan_ke_titik(pos_pulang)
		# Fade out Rani
		if is_instance_valid(rani):
			var tw = create_tween()
			tw.tween_property(rani, "modulate:a", 0.0, 0.6)
			await tw.finished
			rani.queue_free()

	# Set flag dan kurangi upah (pantau_uang akan munculkan teks -Rp otomatis)
	Cerita.set_flag("rani_sudah_pulang")
	Cerita.flag.erase("rani_ikut_arka")
	Cerita._kurangi_uang(Cerita.UPAH_RANI)
	Cerita.set_objektif("")

	# Teks konfirmasi
	if p and is_instance_valid(p):
		TeksMelayang.munculkan_di_sekitar(p, "Rani sudah diantar pulang", Color(0.6, 1.0, 0.6))

	# Kembalikan gerak player
	await get_tree().create_timer(0.4).timeout
	if p and is_instance_valid(p) and p.has_method("set_bisa_gerak"):
		p.set_bisa_gerak(true)

	sedang_proses = false


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_di_area = true
		player_ref = body


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_di_area = false
		player_ref = null
