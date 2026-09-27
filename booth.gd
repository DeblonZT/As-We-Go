extends Area2D

@export var scene_minigame_masak: PackedScene
@export var scene_pelanggan: PackedScene = preload("res://pelanggan.tscn") if ResourceLoader.exists("res://pelanggan.tscn") else null

# Titik awal spawn pelanggan (misal dari jalan oranye)
@export var titik_spawn: Vector2 = Vector2(-200, 135)

# Jarak antar antrean di depan booth atas Arka
@export var titik_depan_booth: Vector2 = Vector2(0, 50)
@export var jarak_antrean: Vector2 = Vector2(0, 25)

@export var interval_spawn_detik: float = 6.0
@export var maksimum_antrean: int = 4

@onready var icon_e = $IconE
@onready var timer_spawn = $TimerSpawn

var player_di_area: bool = false
var player_ref: Node2D = null
var minigame_instance: CanvasLayer = null

var daftar_pelanggan: Array[Node2D] = []

func _ready():
	if icon_e:
		icon_e.hide()
		
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if timer_spawn:
		timer_spawn.wait_time = interval_spawn_detik
		timer_spawn.timeout.connect(_on_timer_spawn_timeout)
		timer_spawn.start()
		
	_siapkan_minigame()

func _siapkan_minigame():
	if scene_minigame_masak:
		minigame_instance = scene_minigame_masak.instantiate()
		add_child(minigame_instance)
	else:
		# Fallback instantiate minigame_masak.tscn jika ada
		var path_masak = "res://minigame_masak.tscn"
		if ResourceLoader.exists(path_masak):
			var res_masak = load(path_masak)
			minigame_instance = res_masak.instantiate()
			add_child(minigame_instance)

func _process(_delta):
	if player_di_area and Input.is_action_just_pressed("ui_accept") or (player_di_area and Input.is_key_pressed(KEY_E)):
		buka_minigame()

func _on_body_entered(body: Node2D):
	if body.is_in_group("Player"):
		player_di_area = true
		player_ref = body
		if icon_e:
			icon_e.show()

func _on_body_exited(body: Node2D):
	if body.is_in_group("Player"):
		player_di_area = false
		player_ref = null
		if icon_e:
			icon_e.hide()

func buka_minigame():
	if minigame_instance and minigame_instance.has_method("buka_panel"):
		minigame_instance.buka_panel()

func _on_timer_spawn_timeout():
	# Hitung batas antrean berdasarkan reputasi pelanggan
	var batas_maks = clampi(int(Global.reputasi_pelanggan / 20) + 1, 1, maksimum_antrean)
	
	if daftar_pelanggan.size() < batas_maks:
		tambah_pelanggan_baru()

func tambah_pelanggan_baru():
	var res_pelanggan = scene_pelanggan
	if res_pelanggan == null and ResourceLoader.exists("res://pelanggan.tscn"):
		res_pelanggan = load("res://pelanggan.tscn")
		
	if res_pelanggan == null:
		return
		
	var node_pelanggan = res_pelanggan.instantiate()
	
	# Hubungkan sinyal pelanggan_pergi
	if node_pelanggan.has_signal("pelanggan_pergi"):
		node_pelanggan.pelanggan_pergi.connect(_on_pelanggan_pergi)
		
	get_parent().add_child(node_pelanggan)
	node_pelanggan.global_position = global_position + titik_spawn
	
	daftar_pelanggan.append(node_pelanggan)
	perbarui_semua_antrean()

func _on_pelanggan_pergi(node_pelanggan: Node2D):
	if node_pelanggan in daftar_pelanggan:
		daftar_pelanggan.erase(node_pelanggan)
		perbarui_semua_antrean()

func perbarui_semua_antrean():
	for i in range(daftar_pelanggan.size()):
		var p = daftar_pelanggan[i]
		if is_instance_valid(p):
			var pos_target = global_position + titik_depan_booth + (jarak_antrean * i)
			if p.has_method("perbarui_target"):
				p.perbarui_target(pos_target, i)
