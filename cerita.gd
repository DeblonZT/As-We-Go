extends Node
# Autoload "Cerita": flag progres cerita, objektif aktif, aksi dari dialog,
# pemantau uang (teks melayang + suara), mode uji F6, dan batas jam tidur.
# Path Autoload = res://cerita.gd (script, bukan .tscn).

signal objektif_berubah(id_objektif: String)
signal flag_berubah(nama: String)

# id_objektif -> teks yang ditampilkan di panel objektif
const DATA_OBJEKTIF = {
	"minta_uang_mama": "Minta uang ke Mama",
	"temui_pandu": "Temui Bang Pandu di lantai 2",
	"tidur": "Tidur di kasur",
	"sewa_booth": "Sewa booth ke Pak Iwan (Jalan 3)",
	"beli_bahan": "Beli bahan di Warung Mpok Wati (Jalan 2)",
	"ke_booth": "Periksa booth-mu di Jalan 3",
	"temui_mang_cecep": "Temui Mang Cecep di Jalan 5",
	"perbaiki_booth": "Perbaiki booth (tahan E selama 5 detik)",
	"berjualan": "Mulai berjualan di booth",
	"curhat_pandu": "Ceritakan keluh kesahmu ke Bang Pandu (lantai 2)",
	"keluar_rumah": "Keluar rumah",
	"jemput_rani": "Jemput Rani di Jalan 4",
	"tanya_mama_mpok_wati": "Bertemu dengan Mama dan Mpok Wati",
	"temui_mama": "Bertemu dengan Mama (Resep Es Teh)",
	"temui_mpok_wati": "Bertemu dengan Mpok Wati (Resep Piscok)",
}

const HARGA_SEWA_BOOTH: int = 10000
const PATH_GAMBAR_HP: String = "res://Assets/bg_Character/hape.png"  # GANTI ke gambar HP-mu
const SCENE_LUAR: Array = ["res://node_2d.tscn", "res://map_2.tscn", "res://map_3.tscn", "res://map_4.tscn", "res://map_5.tscn"]
const UPAH_RANI: int = 20000
const PATH_PORTRAIT_ARKA: String = "res://Assets/bg_Character/ChatGPT Image Sep 20, 2026, 11_10_49 AM.png"  # GANTI ke portrait Arka-mu
const NAMA_PENELEPON: Dictionary = {"telepon_rani": "Rani"}  # selain ini, penelepon = Bang Pandu
# Suara saat uang bertambah
const PATH_SFX_UANG: String = "res://Assets/SFX/GettingMoney.wav"
const PATH_SFX_ITEM: String = "res://Assets/SFX/pickupItem.wav"  # ganti kalau pakai file lain
const VOLUME_SFX_DB: float = 0.0
const BUS_SFX: String = "SFX"  # kalau bus ini tidak ada, otomatis pakai Master

# ---------------- MODE UJI (F6) ----------------
# Kalau game dijalankan langsung dari sebuah scene (F6), main menu dilewati sehingga
# semua flag kosong dan pintu/tangga terkunci. Mode uji mengisi flag otomatis.
# Saat lewat main menu (F5 -> New Game), mode ini tidak aktif sama sekali.
# Pilihan TAHAP_UJI:
#   "mulai"         = tanpa flag (untuk menguji cutscene TV dari awal)
#   "setelah_mama"  = Mama selesai, uang 20k, tangga terbuka, objektif temui Pandu
#   "setelah_pandu" = Pandu setuju, kasur terbuka, objektif tidur
#   "hari_1"        = sudah hari 1, tutorial Pandu selesai
const MODE_UJI: bool = true
const TAHAP_UJI: String = ""

# ---------------- BATAS JAM TIDUR ----------------
const JAM_BATAS_TIDUR: int = 21           # HARUS lebih besar dari JAM_BANGUN
const BATAS_TIDUR_MULAI_HARI: int = 1     # hari 0 (prolog) tidak dipaksa tidur
const DENDA_TIDAK_TIDUR: int = 5000       # uang yang dipotong (ganti sesukamu)
const SCENE_BANGUN_PAKSA: String = "res://rumah_2.tscn"
const SPAWN_ID_BANGUN_PAKSA: String = "lantai_2"
const JAM_BANGUN: int = 6

# Berapa detik player bebas bergerak tanpa mengerjakan objektif sebelum panah muncul.
var jeda_panah: float = 60.0

var flag: Dictionary = {}
var objektif_aktif: String = ""
var waktu_objektif: float = 0.0
var panah_aktif: bool = false
var sedang_ganti_hari: bool = false


var _uang_terakhir: int = 0
var _uang_tertunda: int = 0
var _hari_dipaksa: int = -1
var _bahan_terakhir: int = 0
var _sedang_telepon: bool = false

var _item_tertunda: Array = []  # isi: {"nama": String, "sfx": String}


# Pakai untuk semua barang: Cerita.dapat_item("Obeng")
func dapat_item(nama_item: String, path_sfx: String = PATH_SFX_ITEM) -> void:
	_item_tertunda.append({"nama": nama_item, "sfx": path_sfx})


func _pantau_item() -> void:
	if _item_tertunda.is_empty() or DialogBox.sedang_dialog:
		return
	var player = get_tree().get_first_node_in_group("Player")
	if player == null:
		return
	var item: Dictionary = _item_tertunda.pop_front()
	TeksMelayang.munculkan_di_sekitar(player, "Mendapatkan " + item["nama"], Color(0.6, 0.9, 1.0))
	_putar_sfx(item["sfx"])

func _ready() -> void:
	_terapkan_mode_uji()
	_uang_terakhir = Global.uang
	_bahan_terakhir = _total_bahan()


func _process(delta: float) -> void:
	_pantau_uang()
	_hitung_waktu_objektif(delta)
	_pantau_batas_tidur()
	_pantau_belanja()
	_pantau_telepon_otomatis()
	_pantau_item()



# ---------------- MODE UJI ----------------
func _dijalankan_langsung() -> bool:
	# F6 mengirim path scene sebagai argumen; F5 tidak
	for arg in OS.get_cmdline_args():
		if arg.ends_with(".tscn") and not arg.ends_with("main_menu.tscn"):
			return true
	return false


const URUTAN_FLAG_UJI: Array = ["cutscene_hari_0", "uang_mama_diterima", "tawaran_pandu_diterima", "tutorial_booth_dimulai", "booth_disewa", "telepon_belanja", "bahan_dibeli", "telepon_ke_booth", "booth_rusak_ditemukan", "punya_obeng", "booth_diperbaiki", "keluhan_hari_3", "saran_pandu_diterima", "telepon_rani", "rani_bergabung"]
func _uji_flag_sampai(jumlah: int, objektif: String) -> void:
	Global.hari = 1
	Global.uang = 50000
	for i in jumlah:
		set_flag(URUTAN_FLAG_UJI[i])
	set_objektif(objektif)


func _terapkan_mode_uji() -> void:
	if not MODE_UJI or not OS.is_debug_build() or not _dijalankan_langsung():
		return
	match TAHAP_UJI:
		"mulai":
			Global.hari = 0
		"setelah_mama":
			Global.hari = 0
			Global.uang = 50000
			set_flag("cutscene_hari_0")
			set_flag("uang_mama_diterima")
			set_objektif("temui_pandu")
		"setelah_pandu":
			Global.hari = 0
			Global.uang = 50000
			set_flag("cutscene_hari_0")
			set_flag("uang_mama_diterima")
			set_flag("tawaran_pandu_diterima")
			set_objektif("tidur")
		"hari_1":
			_uji_flag_sampai(3, "temui_pandu")
		"sewa_booth":
			_uji_flag_sampai(4, "sewa_booth")
		"beli_bahan":
			_uji_flag_sampai(5, "beli_bahan")      # telepon pertama akan berbunyi saat keluar warung
		"ke_booth":
			_uji_flag_sampai(8, "ke_booth")
		"perbaiki_booth":
			_uji_flag_sampai(10, "perbaiki_booth")
		"booth_siap":
			_uji_flag_sampai(11, "berjualan")
		"curhat_pandu":
			_uji_flag_sampai(12, "curhat_pandu")
			Global.hari = 3
		"keluar_rumah":
			_uji_flag_sampai(13, "keluar_rumah")   # telepon Rani berbunyi begitu bebas di map luar
			Global.hari = 3
		"jemput_rani":
			_uji_flag_sampai(14, "jemput_rani")    # F6 dari map_4.tscn
			Global.hari = 3
	_uang_terakhir = Global.uang
	print("[Cerita] MODE UJI aktif, tahap: ", TAHAP_UJI)
# ---------------- EFEK UANG ----------------
# Memantau Global.uang dari mana pun berubahnya, jadi tidak perlu mengubah Global.gd.
# Teks + suara baru muncul setelah dialog tertutup supaya tidak ketutup kotak dialog.

# ---------------- ALUR BOOTH ----------------
func tahap_booth() -> String:
	if punya_flag("booth_diperbaiki"): return "siap"
	if not punya_flag("booth_disewa"): return "belum_sewa"
	if not punya_flag("bahan_dibeli"): return "belum_belanja"
	if not punya_flag("telepon_ke_booth"): return "belum_diarahkan"
	if not punya_flag("booth_rusak_ditemukan"): return "cek_booth"
	if not punya_flag("punya_obeng"): return "butuh_obeng"
	return "siap_diperbaiki"


func booth_boleh_dipakai() -> bool:
	return tahap_booth() == "siap"


func pesan_booth_terkunci(tahap: String) -> String:
	match tahap:
		"belum_sewa": return "Ini booth milik Pak Iwan. Aku harus menyewanya dulu."
		"belum_belanja": return "Booth sudah kusewa, tapi aku belum punya bahan. Belanja dulu ke Warung Mpok Wati."
		"belum_diarahkan": return "Sebaiknya tunggu kabar dari Bang Pandu dulu."
		"butuh_obeng": return "Kompor dan mejanya masih rusak. Kata Bang Pandu, minta bantuan Mang Cecep di Jalan 5."
	return ""


# Dialog tahap cerita untuk NPC yang TIDAK pakai DataDialog (Mpok Wati, Mang Cecep).
# sekali=true: hanya tampil sekali per objektif (supaya tidak diulang-ulang
# tiap player buka toko sebelum objektifnya berubah).
func dialog_tahap_untuk(id_npc: String, sekali: bool = true) -> Dictionary:
	var tahap: Dictionary = DataDialog.DIALOG_TAHAP.get(id_npc, {}).get(objektif_aktif, {})
	if tahap.is_empty():
		return {}
	if sekali:
		var kunci: String = "dengar_%s_%s" % [id_npc, objektif_aktif]
		if punya_flag(kunci):
			return {}
		set_flag(kunci)
	return tahap


# Dipakai NPC yang SUDAH pakai DataDialog.ambil_dialog() (Pandu, Pak Iwan):
# dialog tahap cerita didahulukan, kalau tidak ada baru dialog harian biasa.
func pilih_dialog(id_npc: String, hari: int, sudah_bicara: bool = false) -> Dictionary:
	if id_npc == "rani" and punya_flag("telepon_rani") and not punya_flag("rani_bergabung"):
		return DataDialog.DIALOG_TAHAP["rani"]["jemput_rani"]
	var tahap := dialog_tahap_untuk(id_npc)
	if not tahap.is_empty():
		return tahap
	return DataDialog.ambil_dialog(id_npc, hari, sudah_bicara)

func _total_bahan() -> int:
	return Global.terigu + Global.pisang + Global.teh_bubuk + Global.coklat + Global.kulit_lumpia + Global.es_batu


func _pantau_belanja() -> void:
	var total: int = _total_bahan()
	if objektif_aktif == "beli_bahan" and total > _bahan_terakhir and not punya_flag("bahan_dibeli"):
		set_flag("bahan_dibeli")
	_bahan_terakhir = total


func _player_bebas() -> bool:
	var p = get_tree().get_first_node_in_group("Player")
	return p != null and p.get("bisa_gerak") == true and p.get("mode_cutscene") != true \
		and not DialogBox.sedang_dialog and not get_tree().paused


# Telepon otomatis: bunyi begitu Arka berada di map luar dan bebas bergerak
func _pantau_telepon_otomatis() -> void:
	if _sedang_telepon or sedang_ganti_hari:
		return
	var adegan = get_tree().current_scene
	if adegan == null or not (adegan.scene_file_path in SCENE_LUAR):
		return
	var id_telepon: String = ""
	if punya_flag("booth_disewa") and not punya_flag("telepon_belanja"):
		id_telepon = "telepon_belanja"
	elif punya_flag("bahan_dibeli") and not punya_flag("telepon_ke_booth"):
		id_telepon = "telepon_ke_booth"
	elif punya_flag("bahan_dibeli") and not punya_flag("telepon_ke_booth"):
		id_telepon = "telepon_ke_booth"
	elif punya_flag("saran_pandu_diterima") and not punya_flag("telepon_rani"):
		id_telepon = "telepon_rani"
	if id_telepon == "" or not _player_bebas():
		return
	_sedang_telepon = true
	set_flag(id_telepon)
	await get_tree().create_timer(0.8).timeout
	while not _player_bebas():
		await get_tree().process_frame
	await mulai_telepon(id_telepon, NAMA_PENELEPON.get(id_telepon, "Bang Pandu"))
	_sedang_telepon = false

# Monolog Arka tanpa gambar HP: await Cerita.mulai_monolog("id_adegan")
# Monolog Arka: await Cerita.mulai_monolog("id_adegan")
# Portrait memakai gambar HP yang sama dengan mulai_telepon()
# Monolog Arka tanpa gambar HP: await Cerita.mulai_monolog("id_adegan")
func mulai_monolog(id_adegan: String) -> void:
	var tree: Dictionary = DataDialog.DIALOG_ADEGAN.get(id_adegan, {})
	if tree.is_empty():
		push_warning("Adegan monolog tidak ditemukan: '%s'" % id_adegan)
		return
	while DialogBox.sedang_dialog:
		await get_tree().process_frame
	var potret: Texture2D = null
	if ResourceLoader.exists(PATH_PORTRAIT_ARKA):
		potret = load(PATH_PORTRAIT_ARKA)
	_atur_gerak_player(false)
	DialogBox.mulai_dialog(tree, null, potret, "", "Arka")
	await DialogBox.dialog_selesai
	_atur_gerak_player(true)


# Adegan yang jalan setelah layar terang lagi di pagi hari baru
func _saat_hari_dimulai(hari_baru: int) -> void:
	match hari_baru:
		2:
			if not punya_flag("keluhan_hari_2"):
				await get_tree().create_timer(0.5).timeout
				await mulai_monolog("keluhan_hari_2")
		3:
			if not punya_flag("keluhan_hari_3"):
				await get_tree().create_timer(0.5).timeout
				await mulai_monolog("keluhan_hari_3")

# Dialog dengan gambar HP. Bisa dipanggil dari mana saja: await Cerita.mulai_telepon("id")
func mulai_telepon(id_telepon: String, nama_penelepon: String = "Bang Pandu") -> void:
	var tree: Dictionary = DataDialog.DIALOG_ADEGAN.get(id_telepon, {})
	if tree.is_empty():
		push_warning("Adegan telepon tidak ditemukan: '%s'" % id_telepon)
		return
	while DialogBox.sedang_dialog:
		await get_tree().process_frame
	var hp: Texture2D = null
	if ResourceLoader.exists(PATH_GAMBAR_HP):
		hp = load(PATH_GAMBAR_HP)
	else:
		push_warning("Gambar HP tidak ditemukan: '%s' (cek PATH_GAMBAR_HP)" % PATH_GAMBAR_HP)
	_atur_gerak_player(false)
	DialogBox.mulai_dialog(tree, hp, hp, nama_penelepon, "Arka")
	await DialogBox.dialog_selesai
	_atur_gerak_player(true)


func _atur_gerak_player(nilai: bool) -> void:
	var p = get_tree().get_first_node_in_group("Player")
	if p and p.has_method("set_bisa_gerak"):
		p.set_bisa_gerak(nilai)


func _kurangi_uang(jumlah: int) -> void:
	Global.uang -= mini(jumlah, Global.uang)
	_perbarui_hud()
	
func _pantau_uang() -> void:
	var uang_sekarang: int = Global.uang
	var selisih: int = uang_sekarang - _uang_terakhir
	_uang_terakhir = uang_sekarang
	if selisih != 0:
		_uang_tertunda += selisih

	if _uang_tertunda == 0 or DialogBox.sedang_dialog:
		return
	var player = get_tree().get_first_node_in_group("Player")
	if player == null:
		return
	if _uang_tertunda > 0:
		TeksMelayang.munculkan_di_sekitar(player, "+" + TeksMelayang.format_rupiah(_uang_tertunda))
		_putar_sfx_uang()
	else:
		TeksMelayang.munculkan_di_sekitar(player, "-" + TeksMelayang.format_rupiah(-_uang_tertunda), Color(1.0, 0.45, 0.45))
	_uang_tertunda = 0
	
func _putar_sfx_uang() -> void:
	_putar_sfx(PATH_SFX_UANG)


func _putar_sfx(path: String) -> void:
	if not ResourceLoader.exists(path):
		push_warning("SFX tidak ditemukan: '%s'" % path)
		return
	var pemutar := AudioStreamPlayer.new()
	pemutar.stream = load(path)
	pemutar.volume_db = VOLUME_SFX_DB
	if AudioServer.get_bus_index(BUS_SFX) != -1:
		pemutar.bus = BUS_SFX
	add_child(pemutar)
	pemutar.finished.connect(pemutar.queue_free)
	pemutar.play()


func _hitung_waktu_objektif(delta: float) -> void:
	if objektif_aktif == "" or panah_aktif:
		return
	# Waktu hanya berjalan saat player bebas bergerak (bukan cutscene / dialog / pindah scene)
	var player = get_tree().get_first_node_in_group("Player")
	if player == null or not player.get("bisa_gerak"):
		return
	waktu_objektif += delta
	if waktu_objektif >= jeda_panah:
		panah_aktif = true


# ---------------- BATAS JAM TIDUR ----------------
# Kalau jam sudah lewat batas dan player belum tidur: paksa ganti hari + potong uang.
# Menunggu sampai player bebas (tidak sedang dialog / cutscene) supaya tidak memotong adegan.
func _pantau_batas_tidur() -> void:
	if sedang_ganti_hari or Global.hari < BATAS_TIDUR_MULAI_HARI:
		return
	if _hari_dipaksa == Global.hari:
		return  # sekali per hari, mencegah pengulangan
	var hud = cari_hud()
	if hud == null or not ("jam" in hud):
		return
	var terlalu_malam: bool = hud.jam >= JAM_BATAS_TIDUR or hud.jam < JAM_BANGUN
	if not terlalu_malam:
		return
	var player = get_tree().get_first_node_in_group("Player")
	if player == null or not player.get("bisa_gerak") or DialogBox.sedang_dialog:
		return
	_hari_dipaksa = Global.hari
	ganti_hari(true)


func boleh_tidur() -> bool:
	# Hari 0: kasur baru terbuka setelah Pandu mengajak berjualan
	if Global.hari == 0:
		return punya_flag("tawaran_pandu_diterima")
	return true

func _taruh_di_kasur() -> void:
	var kasur = get_tree().get_first_node_in_group("kasur")
	var p = get_tree().get_first_node_in_group("Player")
	if kasur == null or p == null:
		push_warning("Kasur/Player tidak ditemukan di scene bangun paksa")
		return
	# batalkan jalan otomatis dari script scene (kalau ada)
	p.set("mode_cutscene", false)
	p.velocity = Vector2.ZERO
	var geser = kasur.get("offset_bangun")
	p.global_position = kasur.global_position + (geser if geser else Vector2.ZERO)
	if p.has_method("atur_arah_menghadap"):
		p.atur_arah_menghadap("bawah")

# Transisi tidur: layar hitam + judul hari, ganti hari, reset jam.
# paksa = true -> dipanggil karena lewat jam batas: uang dipotong dan player bangun di rumah.
func ganti_hari(paksa: bool = false, durasi_fade: float = 0.8, durasi_tahan: float = 1.0, jam_bangun: int = JAM_BANGUN, menit_bangun: int = 0) -> void:
	if sedang_ganti_hari:
		return
	sedang_ganti_hari = true

	var hari_baru: int = Global.hari + 1
	var denda: int = mini(DENDA_TIDAK_TIDUR, Global.uang) if paksa else 0

	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_method("set_bisa_gerak"):
		player.set_bisa_gerak(false)

	# Layar hitam + teks, dibuat lewat kode (tanpa scene tambahan)
	var lapisan := CanvasLayer.new()
	lapisan.layer = 128
	get_tree().root.add_child(lapisan)

	var hitam := ColorRect.new()
	hitam.color = Color.BLACK
	hitam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hitam.modulate.a = 0.0
	lapisan.add_child(hitam)
	hitam.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var kotak := VBoxContainer.new()
	kotak.alignment = BoxContainer.ALIGNMENT_CENTER
	kotak.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hitam.add_child(kotak)
	kotak.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var judul := Label.new()
	judul.text = "Hari %d" % hari_baru
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	judul.add_theme_font_size_override("font_size", 24)
	kotak.add_child(judul)

	if paksa:
		var sub := Label.new()
		sub.text = "Kamu ketiduran di luar karena terlalu larut."
		if denda > 0:
			sub.text += "\nUang terpotong %s." % TeksMelayang.format_rupiah(denda)
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub.add_theme_font_size_override("font_size", 12)
		kotak.add_child(sub)

	# Gelap
	var tween_gelap := create_tween()
	tween_gelap.tween_property(hitam, "modulate:a", 1.0, durasi_fade)
	await tween_gelap.finished

	# Layar sudah hitam: ganti hari, potong uang, reset jam, atur objektif
	Global.hari = hari_baru
	if denda > 0:
		Global.uang -= denda
		_uang_terakhir = Global.uang
	_atur_hud_pagi(jam_bangun, menit_bangun)
	saat_hari_baru(hari_baru)

	if paksa:
		TransitionScreen.target_spawn_id = SPAWN_ID_BANGUN_PAKSA
		get_tree().change_scene_to_file(SCENE_BANGUN_PAKSA)
		for i in 3:
			await get_tree().process_frame
		_taruh_di_kasur()



	await get_tree().create_timer(durasi_tahan).timeout

	# Terang lagi
	var tween_terang := create_tween()
	tween_terang.tween_property(hitam, "modulate:a", 0.0, durasi_fade)
	await tween_terang.finished

	lapisan.queue_free()
	sedang_ganti_hari = false

	if paksa:
		_pulihkan_setelah_paksa(denda)

	_saat_hari_dimulai(hari_baru)
	
func _pulihkan_setelah_paksa(denda: int) -> void:
	var p = get_tree().get_first_node_in_group("Player")
	if p == null:
		return
	# Jaga-jaga kalau scene baru belum mengaktifkan kontrol player
	if p.get("bisa_gerak") == false and p.get("mode_cutscene") != true and p.has_method("set_bisa_gerak"):
		p.set_bisa_gerak(true)
	if denda > 0:
		TeksMelayang.munculkan_di_sekitar(p, "-" + TeksMelayang.format_rupiah(denda), Color(1.0, 0.45, 0.45))


func _atur_hud_pagi(jam_bangun: int, menit_bangun: int) -> void:
	var hud = cari_hud()
	if hud == null:
		return
	hud.jam = jam_bangun
	hud.menit = menit_bangun
	if hud.has_method("cek_sesi"):
		hud.cek_sesi()
	if hud.has_method("update_ui"):
		hud.update_ui()
	hud.show()


# ---------------- HUD ----------------
# Ejaan autoload HUD bisa "MainUI" atau "MainUi", jadi dicari dua-duanya
func cari_hud():
	var hud = get_node_or_null("/root/MainUI")
	if hud == null:
		hud = get_node_or_null("/root/MainUi")
	return hud


func _perbarui_hud() -> void:
	var hud = cari_hud()
	if hud and hud.has_method("update_ui"):
		hud.update_ui()


func _tambah_uang(jumlah: int) -> void:
	if Global.has_method("tambah_uang"):
		Global.call("tambah_uang", jumlah)
	else:
		Global.uang += jumlah
	_perbarui_hud()


# ---------------- FLAG ----------------
func set_flag(nama: String) -> void:
	flag[nama] = true
	flag_berubah.emit(nama)


func punya_flag(nama: String) -> bool:
	return flag.get(nama, false)


# ---------------- OBJEKTIF ----------------
func set_objektif(id_objektif: String) -> void:
	objektif_aktif = id_objektif
	waktu_objektif = 0.0
	panah_aktif = false
	objektif_berubah.emit(id_objektif)


func teks_objektif() -> String:
	return DATA_OBJEKTIF.get(objektif_aktif, "")


# ---------------- HARI BARU ----------------
func saat_hari_baru(hari_baru: int) -> void:
	match hari_baru:
		1:
			set_objektif("temui_pandu")  # tutorial berjualan dilanjutkan Pandu
		2:
			set_objektif("temui_pandu")  # Di hari 2, Arka temui Bang Pandu
		_:
			set_objektif("")


# ---------------- AKSI DARI DIALOG ----------------
# Dipanggil dialog_box.gd saat baris dengan key "aksi" ditampilkan.
# Setiap aksi dijaga supaya tidak jalan dua kali kalau dialognya terulang.
func jalankan_aksi(nama_aksi: String) -> void:
	match nama_aksi:
		"beri_uang_50000":
			if punya_flag("uang_mama_diterima"):
				return
			_tambah_uang(50000)
			set_flag("uang_mama_diterima")
			set_objektif("temui_pandu")
		"terima_tawaran_pandu":
			if punya_flag("tawaran_pandu_diterima"):
				return
			set_flag("tawaran_pandu_diterima")
			set_objektif("tidur")
		"mulai_tutorial_booth":
			if punya_flag("tutorial_booth_dimulai"):
				return
			set_flag("tutorial_booth_dimulai")
			set_objektif("sewa_booth")
		"ending_gagal":
			set_flag("ending_gagal")
			set_objektif("")
				
		"sewa_booth_berhasil":
			if punya_flag("booth_disewa"):
				return
			_kurangi_uang(HARGA_SEWA_BOOTH)
			set_flag("booth_disewa")
			set_objektif("")   # tunggu telepon dulu
			
		"buka_objektif_belanja":
			set_objektif("beli_bahan")
			if punya_flag("booth_disewa"):
				return
			_kurangi_uang(HARGA_SEWA_BOOTH)
			set_flag("booth_disewa")
			set_objektif("beli_bahan")
		"ke_booth":
			set_objektif("ke_booth")
		"booth_rusak_ditemukan":
			set_flag("booth_rusak_ditemukan")
		"cari_mang_cecep":
			if punya_flag("punya_obeng"):
				return  # jangan mundurkan objektif kalau obeng sudah didapat
			set_objektif("temui_mang_cecep")
		"beri_obeng":
			if punya_flag("punya_obeng"):
				return
			set_flag("punya_obeng")
			set_objektif("perbaiki_booth")
			dapat_item("Obeng")
		"booth_diperbaiki":
			set_flag("booth_diperbaiki")
		"mulai_berjualan":
			set_objektif("berjualan")
		"keluhan_hari_2_selesai":
			if punya_flag("keluhan_hari_2"):
				return
			set_flag("keluhan_hari_2")
			set_objektif("temui_pandu")
		"saran_pandu_hari2":
			if punya_flag("saran_pandu_hari2"):
				return
			set_flag("saran_pandu_hari2")
			set_objektif("tanya_mama_mpok_wati")
		"buka_resep_es_teh":
			if not punya_flag("resep_es_teh_terbuka"):
				set_flag("resep_es_teh_terbuka")
				dapat_item("Resep Es Teh")
			if punya_flag("resep_piscok_terbuka"):
				set_objektif("beli_bahan")
			else:
				set_objektif("temui_mpok_wati")
		"buka_resep_piscok":
			if not punya_flag("resep_piscok_terbuka"):
				set_flag("resep_piscok_terbuka")
				dapat_item("Resep Piscok")
			if punya_flag("resep_es_teh_terbuka"):
				set_objektif("beli_bahan")
			else:
				set_objektif("temui_mama")
		"keluhan_hari_3_selesai":
			if punya_flag("keluhan_hari_3"):
				return
			set_flag("keluhan_hari_3")
			set_objektif("curhat_pandu")
		"saran_pandu_diterima":
			if punya_flag("saran_pandu_diterima"):
				return
			set_flag("saran_pandu_diterima")
			set_objektif("keluar_rumah")
		"rani_setuju":
			if punya_flag("rani_setuju"):
				return
			set_flag("rani_setuju")   # upah UPAH_RANI dibayar nanti, bukan sekarang
			set_objektif("jemput_rani")
		"rani_bergabung":
			if punya_flag("rani_bergabung"):
				return
			set_flag("rani_bergabung")
			set_objektif("berjualan")
		_:
			push_warning("Aksi dialog tidak dikenali: '%s'" % nama_aksi)


func mulai_ending_gagal() -> void:
	# TODO: layar ending gagal + kembali ke main menu
	push_warning("mulai_ending_gagal(): layar ending belum dibuat")


# Dipanggil saat New Game (dari main_menu.gd)
func reset_cerita() -> void:
	flag.clear()
	_uang_tertunda = 0
	_hari_dipaksa = -1
	sedang_ganti_hari = false
	set_objektif("")
	_sedang_telepon = false
	_bahan_terakhir = _total_bahan()
