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
	call_deferred("_sesuaikan_posisi_tombol_memasak")
	toko_buka = Cerita.tahap_booth() == "siap"  # sementara, sampai fitur buka/tutup ada

func _sesuaikan_posisi_tombol_memasak():
	var map = get_tree().current_scene
	if map:
		var marker_tombol = map.get_node_or_null("Tombol Memasak")
		if not marker_tombol:
			marker_tombol = map.get_node_or_null("TombolMemasak")
		if marker_tombol:
			global_position = marker_tombol.global_position

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
			
	if minigame_instance and minigame_instance.has_signal("panel_ditutup"):
		if not minigame_instance.panel_ditutup.is_connected(_on_minigame_panel_ditutup):
			minigame_instance.panel_ditutup.connect(_on_minigame_panel_ditutup)

func _on_minigame_panel_ditutup():
	var p = player_ref if (player_ref and is_instance_valid(player_ref)) else get_tree().get_first_node_in_group("Player")
	if is_instance_valid(p):
		if p.has_method("aktifkan_kontrol"):
			p.aktifkan_kontrol()
		elif p.has_method("set_bisa_gerak"):
			p.set_bisa_gerak(true)
		elif "bisa_gerak" in p:
			p.bisa_gerak = true
		
		var cam = p.get_node_or_null("Camera2D")
		if cam:
			var tw = create_tween()
			tw.tween_property(cam, "offset", Vector2.ZERO, 0.5)


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

	if icon_e:
		icon_e.show()

	if tahap == "siap":
		if baru_ditekan:
			if Global.hari == 3 and Cerita.punya_flag("rani_bergabung") and not Cerita.punya_flag("rani_di_spot"):
				_arahkan_rani_ke_spot()
			else:
				buka_minigame()
		return
		
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
		var p = player_ref if (player_ref and is_instance_valid(player_ref)) else get_tree().get_first_node_in_group("Player")
		if is_instance_valid(p):
			var cam = p.get_node_or_null("Camera2D")
			if cam:
				var tw = create_tween()
				tw.tween_property(cam, "offset", Vector2(150, 0), 0.8)
		minigame_instance.buka_panel()


func _arahkan_rani_ke_spot() -> void:
	sibuk = true
	var p = player_ref if (player_ref and is_instance_valid(player_ref)) else get_tree().get_first_node_in_group("Player")
	if is_instance_valid(p) and p.has_method("set_bisa_gerak"):
		p.set_bisa_gerak(false)
	
	var rani = get_tree().get_first_node_in_group("Rani")
	if not rani:
		var map = get_tree().current_scene
		if map:
			rani = map.get_node_or_null("rani")
			if not rani:
				rani = map.get_node_or_null("Rani")
	
	var map = get_tree().current_scene
	var marker_spot = map.get_node_or_null("Spot Rani") if map else null
	var pos_spot = marker_spot.global_position if marker_spot else Vector2(520, 167)
	
	if rani and is_instance_valid(rani):
		if rani.has_method("jalan_ke_spot"):
			await rani.jalan_ke_spot(pos_spot)
		else:
			rani.global_position = pos_spot
	
	Cerita.set_flag("rani_di_spot")
	
	if is_instance_valid(p):
		if p.has_method("aktifkan_kontrol"):
			p.aktifkan_kontrol()
		elif p.has_method("set_bisa_gerak"):
			p.set_bisa_gerak(true)
		TeksMelayang.munculkan_di_sekitar(p, "Rani siap membantu! Tekan E untuk mulai berjualan", Color(0.6, 1.0, 0.6))
	
	sibuk = false


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
	
	var map = get_tree().current_scene
	if map == null:
		sibuk = false
		return
	var marker_pindah_1 = map.get_node_or_null("Arka Pindah")
	var marker_pindah_2 = map.get_node_or_null("Arka Pindah 2")
	if not marker_pindah_2:
		marker_pindah_2 = map.get_node_or_null("Arka Pindah2")
		
	var p = player_ref if (player_ref and is_instance_valid(player_ref)) else get_tree().get_first_node_in_group("Player")
	
	if is_instance_valid(p) and p.has_method("jalan_ke_titik"):
		# 1. Jalan ke titik Arka Pindah (pertama)
		if marker_pindah_1:
			p.jalan_ke_titik(marker_pindah_1.global_position)
			if p.has_signal("sampai_tujuan"):
				await p.sampai_tujuan
		
		# 2. Jalan ke titik Arka Pindah 2 (kedua)
		if is_instance_valid(p) and marker_pindah_2:
			p.jalan_ke_titik(marker_pindah_2.global_position)
			if p.has_signal("sampai_tujuan"):
				await p.sampai_tujuan
		elif is_instance_valid(p) and not marker_pindah_2 and marker_pindah_1:
			# Fallback jika marker 2 belum ada: jalan ke posisi marker 1
			pass
		
		buka_minigame()
	
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
	var map = get_tree().current_scene
	var arah_5 = map.get_node_or_null("Arah 5")
	var arah_2 = map.get_node_or_null("Arah 2")
	if arah_5:
		node_pelanggan.global_position = arah_5.global_position
	else:
		node_pelanggan.global_position = global_position + titik_spawn

	if arah_2 and node_pelanggan.has_method("set_waypoint"):
		node_pelanggan.set_waypoint(arah_2.global_position)
	daftar_pelanggan.append(node_pelanggan)
	perbarui_semua_antrean()


func _on_pelanggan_pergi(node_pelanggan: Node2D):
	if node_pelanggan in daftar_pelanggan:
		daftar_pelanggan.erase(node_pelanggan)
		perbarui_semua_antrean()


func get_titik_antrean(index: int) -> Vector2:
	var map = get_tree().current_scene
	var nama_node = "Pelanggan Antre" if index == 0 else "Pelanggan Antre " + str(index + 1)
	var node_marker = map.get_node_or_null(nama_node)
	if not node_marker and index > 0:
		node_marker = map.get_node_or_null("Pelanggan Antre" + str(index + 1))
	
	if node_marker:
		return node_marker.global_position
	else:
		var node_utama = map.get_node_or_null("Pelanggan Antre")
		if node_utama:
			return node_utama.global_position + (jarak_antrean * index)
		else:
			return global_position + titik_depan_booth + (jarak_antrean * index)

func perbarui_semua_antrean():
	for i in range(daftar_pelanggan.size()):
		var p = daftar_pelanggan[i]
		if is_instance_valid(p):
			var pos_target = get_titik_antrean(i)
			if p.has_method("perbarui_target"):
				p.perbarui_target(pos_target, i)
