extends Node

const SAVE_PATH = "user://save_game.cfg"

signal reputasi_berubah(nilai_baru: int)

var uang: int = 0
var hari: int = 0
var bahan_cilok: int = 0
var cilok_matang: int = 0
var es_teh_siap: int = 0
var piscok_matang: int = 0
var reputasi_pelanggan: int = 50
var rani_sedang_jualan: bool = false

func _ready() -> void:
	print("TES OUTPUT: Global siap")

func _process(_delta):
	var scene_saat_ini = get_tree().current_scene
	if is_instance_valid(scene_saat_ini) and scene_saat_ini is Node2D:
		if not scene_saat_ini.has_meta("_spawner_terpasang"):
			scene_saat_ini.set_meta("_spawner_terpasang", true)
			call_deferred("_pasang_fitur_map", scene_saat_ini)

func _pasang_fitur_map(scene_node: Node):
	if not is_instance_valid(scene_node):
		return
	var nama_file_scene = scene_node.scene_file_path.get_file() if scene_node.scene_file_path else scene_node.name
	if nama_file_scene == "map_4_festival.tscn" and Global.hari != 5:
		return
	if nama_file_scene == "map_4_festival.tscn" and Global.hari == 5:
		_siapkan_marker_festival(scene_node)
	
	var daftar_map = ["node_2d.tscn", "map_2.tscn", "map_3.tscn", "map_4.tscn", "map_4_festival.tscn", "map_5.tscn"]
	if nama_file_scene in daftar_map or "map" in nama_file_scene.to_lower() or nama_file_scene == "Node2D":
		if not scene_node.has_node("SpawnerNpc"):
			if ResourceLoader.exists("res://spawner_npc.tscn"):
				var spawner_res = load("res://spawner_npc.tscn")
				if spawner_res:
					var spawner_inst = spawner_res.instantiate()
					if nama_file_scene == "map_3.tscn":
						spawner_inst.jumlah_npc_maks = 6
					elif nama_file_scene == "map_4_festival.tscn" and Global.hari == 5:
						spawner_inst.jumlah_npc_maks = Cerita.FESTIVAL_MAKS_PEJALAN
						spawner_inst.interval_spawn_detik = Cerita.FESTIVAL_INTERVAL_PEJALAN
					else:
						spawner_inst.jumlah_npc_maks = 3
					scene_node.add_child(spawner_inst)
		
		if nama_file_scene in ["map_3.tscn", "map_4_festival.tscn"] and (nama_file_scene != "map_4_festival.tscn" or Global.hari == 5):
			if not scene_node.has_node("Booth"):
				if ResourceLoader.exists("res://booth.tscn"):
					var booth_res = load("res://booth.tscn")
					if booth_res:
						var booth_inst = booth_res.instantiate()
						booth_inst.global_position = Vector2(420, 130) # fallback bila marker belum tersedia
						scene_node.add_child(booth_inst)
		
		# --- SPAWNER / KONTROL RANI (HARI >= 3) ---
		if Global.hari >= 3 and Cerita.punya_flag("rani_bergabung") and not Cerita.punya_flag("rani_dilarang_hari_ini") and not Cerita.punya_flag("rani_sudah_pulang"):
			if Cerita.punya_flag("rani_di_spot"):
				# Jika sudah di spot, hanya muncul di map_3.tscn pada marker Spot Rani
				if nama_file_scene in ["map_3.tscn", "map_4_festival.tscn"]:
					if not scene_node.has_node("rani") and not scene_node.has_node("Rani"):
						if ResourceLoader.exists("res://rani.tscn"):
							var rani_res = load("res://rani.tscn")
							if rani_res:
								var rani_inst = rani_res.instantiate()
								var spot = scene_node.get_node_or_null("Spot Rani")
								rani_inst.global_position = spot.global_position if spot else Vector2(520, 167)
								scene_node.add_child(rani_inst)
			elif Cerita.punya_flag("rani_ikut_arka"):
				# Jika masih mengikuti player, spawn di scene map jika belum ada
				if not scene_node.has_node("rani") and not scene_node.has_node("Rani"):
					if ResourceLoader.exists("res://rani.tscn"):
						var rani_res = load("res://rani.tscn")
						if rani_res:
							var rani_inst = rani_res.instantiate()
							var p = scene_node.get_node_or_null("Player")
							if not p:
								p = get_tree().get_first_node_in_group("Player")
							if p:
								var arah_p = p.arah if "arah" in p else "bawah"
								var offset = Vector2.ZERO
								match arah_p:
									"kanan": offset = Vector2(-32, 0)
									"kiri": offset = Vector2(32, 0)
									"atas": offset = Vector2(0, 32)
									"bawah", _: offset = Vector2(0, -32)
								rani_inst.global_position = p.global_position + offset
							scene_node.add_child(rani_inst)
		if nama_file_scene == "map_4_festival.tscn" and Global.hari == 5 and Cerita.punya_flag("rani_bergabung"):
			var rani_festival = scene_node.get_node_or_null("rani")
			if not rani_festival:
				rani_festival = scene_node.get_node_or_null("Rani")
			var marker_spot_festival = scene_node.get_node_or_null("Spot Rani")
			if rani_festival and marker_spot_festival:
				rani_festival.global_position = marker_spot_festival.global_position
				if "state" in rani_festival:
					rani_festival.state = 3
				if rani_festival.has_method("_nonaktifkan_interaksi"):
					rani_festival._nonaktifkan_interaksi()

func _siapkan_marker_festival(scene_node: Node) -> void:
	var antre_arka = scene_node.get_node_or_null("Pelanggan Antre")
	var antre_rani = scene_node.get_node_or_null("Pelanggan Antre Rani 1")
	var tengah := Vector2.ZERO
	if antre_arka and antre_rani:
		tengah = (antre_arka.global_position + antre_rani.global_position) * 0.5
	elif antre_arka:
		tengah = antre_arka.global_position
	elif antre_rani:
		tengah = antre_rani.global_position
	else:
		push_warning("Marker antre festival tidak ada; posisi marker Booth memakai fallback")
		tengah = Vector2(366, 230)
	var posisi_marker := {
		"Tombol Memasak": tengah + Vector2(0, -36),
		"Arka Pindah": tengah + Vector2(0, 60),
		"Arka Pindah 2": tengah + Vector2(0, 28),
		"Spot Rani": (antre_rani.global_position + Vector2(22, -24)) if antre_rani else tengah + Vector2(36, -24),
	}
	for nama_marker in posisi_marker:
		if scene_node.get_node_or_null(nama_marker):
			continue
		push_warning("Marker %s tidak ada di map_4_festival; dibuat fallback runtime" % nama_marker)
		var marker := Marker2D.new()
		marker.name = nama_marker
		marker.position = posisi_marker[nama_marker]
		scene_node.add_child(marker)

func ubah_reputasi(jumlah: int) -> void:
	reputasi_pelanggan = clampi(reputasi_pelanggan + jumlah, 0, 100)
	reputasi_berubah.emit(reputasi_pelanggan)
	print("Reputasi berubah: ", jumlah, " | Total reputasi: ", reputasi_pelanggan)

# --- INVENTORY BAHAN ECERAN ---
var terigu: int = 0
var pisang: int = 0
var teh_bubuk: int = 0
var coklat: int = 0
var kulit_lumpia: int = 0
var es_batu: int = 0

# --- SISTEM UPGRADE BOOTH MANG CECEP ---
var level_kompor: int = 0
var waktu_masak: float = 5.0 # Kecepatan awal 5 detik

var level_meja: int = 0
var waktu_adon: float = 5.0  # Kecepatan awal 5 detik

# --- LOKASI SCENE TERAKHIR ---
var scene_aktif: String = "res://rumah.tscn"
var spawn_id_aktif: String = ""
var scene_sebelumnya: String = ""      # dipakai portal warung untuk kembali otomatis ke map asal
var spawn_id_sebelumnya: String = ""

# --- FUNGSI TRANSAKSI BELANJA ---
func beli_barang(nama_bahan: String, harga: int, jumlah: int = 1) -> bool:
	var total_harga: int = harga * jumlah
	if uang >= total_harga:
		uang -= total_harga # Potong uang Arka
		
		# Tambahkan bahan ke inventory yang sesuai
		if nama_bahan == "terigu":
			terigu += jumlah
		elif nama_bahan == "pisang":
			pisang += jumlah
		elif nama_bahan == "teh":
			teh_bubuk += jumlah
		elif nama_bahan == "coklat":
			coklat += jumlah
		elif nama_bahan == "kulit":
			kulit_lumpia += jumlah
		elif nama_bahan == "es":
			es_batu += jumlah
			
		print("Berhasil beli: ", jumlah, " ", nama_bahan, " | Sisa uang: ", uang)
		return true
	else:
		print("Uang tidak cukup untuk beli: ", nama_bahan)
		return false


# Helper untuk memformat angka menjadi format rupiah (contoh: 50000 -> "Rp50.000")
static func format_rupiah(jumlah: int) -> String:
	var angka: String = str(absi(jumlah))
	var hasil: String = ""
	var hitung: int = 0
	for i in range(angka.length() - 1, -1, -1):
		hasil = angka[i] + hasil
		hitung += 1
		if hitung % 3 == 0 and i != 0:
			hasil = "." + hasil
	return "Rp" + hasil

# Helper nama bahan yang rapi untuk ditampilkan di UI/Pop-up
static func get_nama_bahan(nama_bahan: String) -> String:
	match nama_bahan:
		"terigu": return "Tepung Terigu"
		"pisang": return "Pisang"
		"teh": return "Teh Bubuk"
		"coklat": return "Selai Coklat"
		"kulit": return "Kulit Lumpia"
		"es": return "Es Batu"
		_: return nama_bahan.capitalize()

# Fungsi transaksi upgrade kompor
func beli_upgrade_kompor(level: int, harga: int, waktu: float) -> Dictionary:
	if level_kompor >= level:
		return {"sukses": false, "pesan": "Kompor Level %d sudah kamu miliki!" % level}
	if level_kompor < level - 1:
		return {"sukses": false, "pesan": "Kamu harus membeli Kompor Level %d terlebih dahulu!" % (level - 1)}
	if uang < harga:
		var kurang = harga - uang
		return {
			"sukses": false, 
			"pesan": "Uang kamu tidak cukup untuk Upgrade Kompor Level %d!\nHarga: %s\nUang kamu: %s\n(Kurang %s)" % [level, format_rupiah(harga), format_rupiah(uang), format_rupiah(kurang)]
		}
	
	uang -= harga
	level_kompor = level
	waktu_masak = waktu
	print("Berhasil upgrade Kompor ke Level ", level, " | Sisa uang: ", uang)
	return {
		"sukses": true, 
		"pesan": "Selamat! Upgrade Kompor Level %d berhasil dibeli!\nWaktu masak kini menjadi %.1f detik." % [level, waktu]
	}

# Fungsi transaksi upgrade meja adonan
func beli_upgrade_meja(level: int, harga: int, waktu: float) -> Dictionary:
	if level_meja >= level:
		return {"sukses": false, "pesan": "Meja Level %d sudah kamu miliki!" % level}
	if level_meja < level - 1:
		return {"sukses": false, "pesan": "Kamu harus membeli Meja Level %d terlebih dahulu!" % (level - 1)}
	if uang < harga:
		var kurang = harga - uang
		return {
			"sukses": false, 
			"pesan": "Uang kamu tidak cukup untuk Upgrade Meja Level %d!\nHarga: %s\nUang kamu: %s\n(Kurang %s)" % [level, format_rupiah(harga), format_rupiah(uang), format_rupiah(kurang)]
		}
	
	uang -= harga
	level_meja = level
	waktu_adon = waktu
	print("Berhasil upgrade Meja ke Level ", level, " | Sisa uang: ", uang)
	return {
		"sukses": true, 
		"pesan": "Selamat! Upgrade Meja Level %d berhasil dibeli!\nWaktu adon kini menjadi %.1f detik." % [level, waktu]
	}

# --- SISTEM SAVE & LOAD GAME ---

func reset_data() -> void:
	uang = 0
	hari = 0
	bahan_cilok = 0
	cilok_matang = 0
	es_teh_siap = 0
	piscok_matang = 0
	reputasi_pelanggan = 50
	
	terigu = 0
	pisang = 0
	teh_bubuk = 0
	coklat = 0
	kulit_lumpia = 0
	es_batu = 0
	
	level_kompor = 0
	waktu_masak = 5.0
	level_meja = 0
	waktu_adon = 5.0
	
	scene_aktif = "res://rumah.tscn"
	spawn_id_aktif = ""
	scene_sebelumnya = ""
	spawn_id_sebelumnya = ""
	rani_sedang_jualan = false
	
	reputasi_berubah.emit(reputasi_pelanggan)
	
	var main_ui = Engine.get_main_loop().root.get_node_or_null("MainUI") if Engine.get_main_loop() else null
	if main_ui:
		main_ui.jam = 6
		main_ui.menit = 0
		main_ui.sesi = "Pagi"
		if main_ui.has_method("cek_sesi"):
			main_ui.cek_sesi()
		if main_ui.has_method("update_ui"):
			main_ui.update_ui()

func ada_save_data() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return false
	if not config.has_section_key("player", "hari") or not config.has_section_key("player", "uang") or not config.has_section_key("cerita", "flag"):
		return false
	return typeof(config.get_value("player", "hari")) == TYPE_INT \
		and typeof(config.get_value("player", "uang")) == TYPE_INT \
		and typeof(config.get_value("cerita", "flag")) == TYPE_DICTIONARY


func simpan_game(konteks: String = "") -> bool:
	if konteks == "akhir_tidur":
		if Cerita.MODE_UJI and OS.is_debug_build() and Cerita._dijalankan_langsung():
			return false
	elif konteks == "uji_hari_2":
		if not Cerita.MODE_UJI or not OS.is_debug_build() or not Cerita._dijalankan_langsung() or Cerita.TAHAP_UJI != "buat_save_hari_2":
			return false
	else:
		push_warning("Save diabaikan: penyimpanan hanya diizinkan setelah tidur atau tahap uji save.")
		return false

	var config = ConfigFile.new()
	
	# Simpan data pemain
	config.set_value("player", "uang", uang)
	config.set_value("player", "hari", hari)
	config.set_value("player", "bahan_cilok", bahan_cilok)
	config.set_value("player", "cilok_matang", cilok_matang)
	config.set_value("player", "es_teh_siap", es_teh_siap)
	config.set_value("player", "piscok_matang", piscok_matang)
	config.set_value("player", "reputasi_pelanggan", reputasi_pelanggan)
	
	# Simpan data inventori
	config.set_value("inventory", "terigu", terigu)
	config.set_value("inventory", "pisang", pisang)
	config.set_value("inventory", "teh_bubuk", teh_bubuk)
	config.set_value("inventory", "coklat", coklat)
	config.set_value("inventory", "kulit_lumpia", kulit_lumpia)
	config.set_value("inventory", "es_batu", es_batu)
	
	# Simpan data upgrade
	config.set_value("upgrade", "level_kompor", level_kompor)
	config.set_value("upgrade", "waktu_masak", waktu_masak)
	config.set_value("upgrade", "level_meja", level_meja)
	config.set_value("upgrade", "waktu_adon", waktu_adon)
	
	# Simpan waktu & sesi
	var main_ui = Engine.get_main_loop().root.get_node_or_null("MainUI") if Engine.get_main_loop() else null
	if main_ui:
		config.set_value("waktu", "jam", main_ui.jam)
		config.set_value("waktu", "menit", main_ui.menit)
		config.set_value("waktu", "sesi", main_ui.sesi)
	
	# Simpan scene & posisi
	config.set_value("lokasi", "scene_aktif", scene_aktif)
	config.set_value("lokasi", "spawn_id_aktif", spawn_id_aktif)
	config.set_value("lokasi", "scene_sebelumnya", scene_sebelumnya)
	config.set_value("lokasi", "spawn_id_sebelumnya", spawn_id_sebelumnya)
	config.set_value("cerita", "flag", Cerita.flag)
	config.set_value("cerita", "objektif", Cerita.objektif_aktif)
	
	var err = config.save(SAVE_PATH)
	if err == OK:
		print("Game berhasil disimpan ke: ", SAVE_PATH)
		return true
	else:
		print("Gagal menyimpan game! Error code: ", err)
		return false

func muat_game() -> bool:
	if not ada_save_data():
		print("Data save tidak ditemukan!")
		return false
		
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	if err != OK:
		print("Gagal memuat save data! Error code: ", err)
		return false
		
	# Muat data pemain
	uang = config.get_value("player", "uang", 20000)
	hari = config.get_value("player", "hari", 1)
	bahan_cilok = config.get_value("player", "bahan_cilok", 10)
	cilok_matang = config.get_value("player", "cilok_matang", 0)
	es_teh_siap = config.get_value("player", "es_teh_siap", 0)
	piscok_matang = config.get_value("player", "piscok_matang", 0)
	reputasi_pelanggan = config.get_value("player", "reputasi_pelanggan", 50)
	
	# Muat data inventori
	terigu = config.get_value("inventory", "terigu", 0)
	pisang = config.get_value("inventory", "pisang", 0)
	teh_bubuk = config.get_value("inventory", "teh_bubuk", 0)
	coklat = config.get_value("inventory", "coklat", 0)
	kulit_lumpia = config.get_value("inventory", "kulit_lumpia", 0)
	es_batu = config.get_value("inventory", "es_batu", 0)
	
	# Muat data upgrade
	level_kompor = config.get_value("upgrade", "level_kompor", 0)
	waktu_masak = config.get_value("upgrade", "waktu_masak", 5.0)
	level_meja = config.get_value("upgrade", "level_meja", 0)
	waktu_adon = config.get_value("upgrade", "waktu_adon", 5.0)
	
	# Muat waktu & sesi
	var main_ui = Engine.get_main_loop().root.get_node_or_null("MainUI") if Engine.get_main_loop() else null
	if main_ui:
		main_ui.jam = config.get_value("waktu", "jam", 6)
		main_ui.menit = config.get_value("waktu", "menit", 0)
		main_ui.sesi = config.get_value("waktu", "sesi", "Pagi")
		if main_ui.has_method("cek_sesi"):
			main_ui.cek_sesi()
		if main_ui.has_method("update_ui"):
			main_ui.update_ui()
			
	# Muat lokasi
	scene_aktif = config.get_value("lokasi", "scene_aktif", "res://rumah.tscn")
	spawn_id_aktif = config.get_value("lokasi", "spawn_id_aktif", "")
	scene_sebelumnya = config.get_value("lokasi", "scene_sebelumnya", "")
	spawn_id_sebelumnya = config.get_value("lokasi", "spawn_id_sebelumnya", "")
	Cerita.flag = config.get_value("cerita", "flag", {})
	Cerita.set_objektif(config.get_value("cerita", "objektif", ""))
	reputasi_berubah.emit(reputasi_pelanggan)
	
	var trans = Engine.get_main_loop().root.get_node_or_null("TransitionScreen") if Engine.get_main_loop() else null
	if trans and spawn_id_aktif != "":
		trans.target_spawn_id = spawn_id_aktif
		
	print("Game berhasil dimuat! Sisa uang: ", uang, " | Hari: ", hari, " | Scene: ", scene_aktif)
	return true
