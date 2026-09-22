extends Node

const SAVE_PATH = "user://save_game.cfg"

var uang: int = 0
var hari: int = 0
var bahan_cilok: int = 0
var cilok_matang: int = 0
var reputasi_pelanggan: int = 50

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

# --- FUNGSI TRANSAKSI BELANJA ---
func beli_barang(nama_bahan: String, harga: int) -> bool:
	if uang >= harga:
		uang -= harga # Potong uang Arka
		
		# Tambahkan bahan ke inventory yang sesuai
		if nama_bahan == "terigu":
			terigu += 1
		elif nama_bahan == "pisang":
			pisang += 1
		elif nama_bahan == "teh":
			teh_bubuk += 1
		elif nama_bahan == "coklat":
			coklat += 1
		elif nama_bahan == "kulit":
			kulit_lumpia += 1
		elif nama_bahan == "es":
			es_batu += 1
			
		print("Berhasil beli: ", nama_bahan, " | Sisa uang: ", uang)
		simpan_game() # Auto-save setelah transaksi
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
	simpan_game() # Auto-save setelah upgrade
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
	simpan_game() # Auto-save setelah upgrade
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
	return FileAccess.file_exists(SAVE_PATH)

func simpan_game() -> bool:
	var config = ConfigFile.new()
	
	# Simpan data pemain
	config.set_value("player", "uang", uang)
	config.set_value("player", "hari", hari)
	config.set_value("player", "bahan_cilok", bahan_cilok)
	config.set_value("player", "cilok_matang", cilok_matang)
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
	
	var trans = Engine.get_main_loop().root.get_node_or_null("TransitionScreen") if Engine.get_main_loop() else null
	if trans and spawn_id_aktif != "":
		trans.target_spawn_id = spawn_id_aktif
		
	print("Game berhasil dimuat! Sisa uang: ", uang, " | Hari: ", hari, " | Scene: ", scene_aktif)
	return true
