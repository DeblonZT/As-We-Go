extends Area2D

@export var scene_minigame_masak: PackedScene
@export var scene_pelanggan: PackedScene = preload("res://pelanggan.tscn") if ResourceLoader.exists("res://pelanggan.tscn") else null

@export var titik_spawn: Vector2 = Vector2(-200, 135)
@export var titik_depan_booth: Vector2 = Vector2(0, 50)
@export var jarak_antrean: Vector2 = Vector2(0, 25)
@export var interval_spawn_detik: float = 6.0
@export var maksimum_antrean: int = 4

@export_group("Perbaikan Booth")
@export var gambar_portrait_player: Texture2D
@export var nama_player: String = "Arka"
@export var durasi_perbaikan: float = 5.0
@export var amplitude_icon: float = 5.0
@export var speed_icon: float = 5.0
@export_group("Toko")
@export var toko_buka: bool = false 

@onready var icon_e = $IconE
@onready var timer_spawn = $TimerSpawn

var player_di_area: bool = false
var player_ref: Node2D = null
var minigame_instance: CanvasLayer = null
var daftar_pelanggan: Array[Node2D] = []

# --- state interaksi cerita/perbaikan ---
var sibuk: bool = false               # dialog / telepon sedang berjalan
var sedang_memperbaiki: bool = false  # E sedang ditahan buat perbaikan
var progres_perbaikan: float = 0.0
var _tahan_sebelumnya: bool = false
var _start_y_icon: float = 0.0
var _timer_icon: float = 0.0
var bar_perbaikan: ProgressBar


func _ready():
	if icon_e:
		icon_e.hide()
		_start_y_icon = icon_e.position.y

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	if timer_spawn:
		timer_spawn.wait_time = interval_spawn_detik
		timer_spawn.timeout.connect(_on_timer_spawn_timeout)
		timer_spawn.start()

	_siapkan_minigame()
	_siapkan_bar_perbaikan()
	toko_buka = Cerita.tahap_booth() == "siap"  # sementara, sampai fitur buka/tutup ada

func _siapkan_minigame():
	if scene_minigame_masak:
		minigame_instance = scene_minigame_masak.instantiate()
		add_child(minigame_instance)
	else:
		var path_masak = "res://minigame_masak.tscn"
		if ResourceLoader.exists(path_masak):
			var res_masak = load(path_masak)
			minigame_instance = res_masak.instantiate()
			add_child(minigame_instance)


func _siapkan_bar_perbaikan():
	bar_perbaikan = ProgressBar.new()
	bar_perbaikan.custom_minimum_size = Vector2(40, 6)
	bar_perbaikan.size = Vector2(40, 6)
	bar_perbaikan.position = Vector2(-20, -56)
	bar_perbaikan.show_percentage = false
	bar_perbaikan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_perbaikan.visible = false
	add_child(bar_perbaikan)


func _e_ditahan() -> bool:
	return Input.is_action_pressed("ui_accept") or Input.is_key_pressed(KEY_E)


func _e_baru_ditekan() -> bool:
	return Input.is_action_just_pressed("ui_accept") or (_e_ditahan() and not _tahan_sebelumnya)


func _process(delta: float):
	var sekarang: bool = _e_ditahan()
	var baru_ditekan: bool = _e_baru_ditekan()
	_tahan_sebelumnya = sekarang

	# Ikon E mengambang naik-turun selama terlihat
	if icon_e and icon_e.visible:
		_timer_icon += delta * speed_icon
		icon_e.position.y = _start_y_icon + sin(_timer_icon) * amplitude_icon

	if not player_di_area or sibuk or Cerita.sedang_ganti_hari:
		return

	var tahap: String = Cerita.tahap_booth()

	if tahap == "siap":
		if icon_e:
			icon_e.show()
		if baru_ditekan:
			buka_minigame()
		return

	if icon_e:
		icon_e.show()

	# Ikon E hanya tampil kalau belum siap dipakai (biar tidak dobel sama ikon minigame lain)
	if icon_e:
		icon_e.visible = tahap != "siap"

	if tahap == "siap":
		return  # booth normal, tidak ada logika perbaikan lagi

	if sedang_memperbaiki:
		if sekarang:
			progres_perbaikan += delta
			bar_perbaikan.value = progres_perbaikan
			if progres_perbaikan >= durasi_perbaikan:
				_selesai_perbaikan()
		else:
			_batalkan_perbaikan()
		return

	if baru_ditekan:
		_tangani_interaksi(tahap)


func _on_body_entered(body: Node2D):
	if body.is_in_group("Player"):
		player_di_area = true
		player_ref = body
		if icon_e and Cerita.tahap_booth() == "siap":
			icon_e.show()


func _on_body_exited(body: Node2D):
	if body.is_in_group("Player"):
		if sedang_memperbaiki:
			_batalkan_perbaikan()
		player_di_area = false
		player_ref = null
		if icon_e:
			icon_e.hide()


# ---------------- INTERAKSI NORMAL (booth sudah siap) ----------------
func buka_minigame():
	if minigame_instance and minigame_instance.has_method("buka_panel"):
		minigame_instance.buka_panel()


# ---------------- ALUR CERITA / PERBAIKAN ----------------
func _tangani_interaksi(tahap: String) -> void:
	match tahap:
		"cek_booth":
			_adegan_booth_rusak()
		"siap_diperbaiki":
			_mulai_perbaikan()
		_:
			_bicara({"start": [{"speaker": "player", "text": Cerita.pesan_booth_terkunci(tahap)}]})


func _atur_gerak(nilai: bool) -> void:
	if player_ref and player_ref.has_method("set_bisa_gerak"):
		player_ref.set_bisa_gerak(nilai)


func _bicara(tree: Dictionary) -> void:
	sibuk = true
	_atur_gerak(false)
	DialogBox.mulai_dialog(tree, null, gambar_portrait_player, "", nama_player)
	await DialogBox.dialog_selesai
	_atur_gerak(true)
	sibuk = false


func _adegan_booth_rusak() -> void:
	sibuk = true
	_atur_gerak(false)
	DialogBox.mulai_dialog(DataDialog.DIALOG_ADEGAN["booth_rusak"], null, gambar_portrait_player, "", nama_player)
	await DialogBox.dialog_selesai
	Cerita.set_flag("booth_rusak_ditemukan")
	await Cerita.mulai_telepon("telepon_booth_rusak")
	sibuk = false


func _mulai_perbaikan() -> void:
	sedang_memperbaiki = true
	progres_perbaikan = 0.0
	bar_perbaikan.max_value = durasi_perbaikan
	bar_perbaikan.value = 0.0
	bar_perbaikan.visible = true
	_atur_gerak(false)


func _batalkan_perbaikan() -> void:
	sedang_memperbaiki = false
	bar_perbaikan.visible = false
	_atur_gerak(true)
	if player_ref:
		TeksMelayang.munculkan_di_sekitar(player_ref, "Tahan E sampai selesai!", Color(1.0, 0.9, 0.4))


func _selesai_perbaikan() -> void:
	sedang_memperbaiki = false
	bar_perbaikan.visible = false
	sibuk = true
	Cerita.jalankan_aksi("booth_diperbaiki")
	if player_ref:
		TeksMelayang.munculkan_di_sekitar(player_ref, "Booth diperbaiki!", Color(0.6, 1.0, 0.6))
	await get_tree().create_timer(0.6).timeout
	await Cerita.mulai_telepon("telepon_booth_selesai")
	toko_buka = true
	sibuk = false



# ---------------- SPAWNER PELANGGAN (tidak diubah) ----------------
func _on_timer_spawn_timeout():
	# Booth belum diperbaiki atau toko belum dibuka: tidak ada pelanggan
	if Cerita.tahap_booth() != "siap" or not toko_buka:
		return
	var batas_maks = clampi(int(Global.reputasi_pelanggan / 20) + 1, 1, maksimum_antrean)
	if daftar_pelanggan.size() < batas_maks:
		tambah_pelanggan_baru()
		
func buka_toko() -> void:
	toko_buka = true


func tutup_toko() -> void:
	toko_buka = false
	for p in daftar_pelanggan:
		if is_instance_valid(p):
			p.queue_free()
	daftar_pelanggan.clear()


func tambah_pelanggan_baru():
	var res_pelanggan = scene_pelanggan
	if res_pelanggan == null and ResourceLoader.exists("res://pelanggan.tscn"):
		res_pelanggan = load("res://pelanggan.tscn")
	if res_pelanggan == null:
		return

	var node_pelanggan = res_pelanggan.instantiate()
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
