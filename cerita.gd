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
	"antar_rani_pulang": "Antar Rani pulang ke rumahnya (Jalan 4)",
	"bayar_pak_iwan": "Bayar booth festival ke Pak Iwan (Jalan 3) sebelum sore",
	"ke_festival": "Pergi ke festival di Jalan 4 (booth Rani tersedia)",
	"tanya_mama_mpok_wati": "Bertemu dengan Mama dan Mpok Wati",
	"temui_mama": "Bertemu dengan Mama di lantai 1",
	"temui_mpok_wati": "Bertemu dengan Mpok Wati di Jalan 2",
	"temui_pandu_hari_2": "Temui Bang Pandu di lantai 2",
	"upgrade_meja_cecep": "Temui Mang Cecep di Jalan 5 untuk upgrade meja booth",
}

const HARGA_SEWA_BOOTH: int = 10000
const HARGA_BOOTH_FESTIVAL: int = 200000
const PATH_GAMBAR_HP: String = "res://Assets/bg_Character/hape.png"  # GANTI ke gambar HP-mu
const SCENE_LUAR: Array = ["res://node_2d.tscn", "res://map_2.tscn", "res://map_3.tscn", "res://map_4.tscn", "res://map_4_festival.tscn", "res://map_5.tscn"]
const FESTIVAL_PENGGANDA_SPAWN: float = 2.0
const FESTIVAL_BATAS_ANTREAN_TAMBAHAN: int = 2
const FESTIVAL_INTERVAL_PEJALAN: float = 1.0
const FESTIVAL_MAKS_PEJALAN: int = 14
const UPAH_RANI: int = 20000
const PATH_PORTRAIT_ARKA: String = "res://Assets/bg_Character/ChatGPT Image Sep 20, 2026, 11_10_49 AM.png"  # GANTI ke portrait Arka-mu
const PATH_PORTRAIT_RANI: String = "res://Assets/bg_Character/Rani 2D.png"
const NAMA_PENELEPON: Dictionary = {"telepon_rani": "Rani"}  # selain ini, penelepon = Bang Pandu
# Suara saat uang bertambah
const PATH_SFX_UANG_MASUK: String = "res://Assets/SFX/GettingMoney.wav"
const PATH_SFX_UANG_KELUAR: String = "res://Assets/SFX/ChaChing.mp3"
const PATH_SFX_ITEM: String = "res://Assets/SFX/pickupItem.wav"  # ganti kalau pakai file lain
const PATH_SFX_BAHAN_HABIS: String = "res://Assets/SFX/bahan_habis.mp3"
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
const TAHAP_UJI: String = "hari5_festival_bad"

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
var _pak_iwan_dipantau: bool = false
var _pak_iwan_sedang_cutscene: bool = false
var _sesi_terakhir_dipantau: String = ""
var _dialog_rani_sedang_diantri: bool = false
var _lapisan_ending: CanvasLayer
var _lapisan_ganti_hari: CanvasLayer
var _lapisan_cutscene: CanvasLayer
var _scene_festival_disiapkan: bool = false
var _panel_objektif_menu_disembunyikan: bool = false

var _item_tertunda: Array = []  # isi: {"nama": String, "sfx": String}
var _timer_jualan_bg_rani: float = 0.0
var _timer_peringatan_bahan_bg: float = 0.0


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
	_sesi_terakhir_dipantau = str(cari_hud().sesi) if cari_hud() and "sesi" in cari_hud() else "Pagi"


func _process(delta: float) -> void:
	if _di_menu_utama():
		_uang_terakhir = Global.uang
		_uang_tertunda = 0
		if not _panel_objektif_menu_disembunyikan:
			_atur_visibilitas_panel_objektif(false)
			_panel_objektif_menu_disembunyikan = true
		return
	if _panel_objektif_menu_disembunyikan:
		_atur_visibilitas_panel_objektif(true)
		_panel_objektif_menu_disembunyikan = false
	_pantau_uang()
	_hitung_waktu_objektif(delta)
	_pantau_batas_tidur()
	_pantau_belanja()
	_pantau_telepon_otomatis()
	_pantau_item()
	_pantau_pak_iwan()
	_pantau_rani_sesi()
	_pantau_jualan_background_rani(delta)
	_pantau_ending_hari5()
	_pantau_masuk_festival()


func _di_menu_utama() -> bool:
	var scene = get_tree().current_scene
	return scene != null and scene.scene_file_path == "res://main_menu.tscn"


func _atur_visibilitas_panel_objektif(terlihat: bool) -> void:
	var root = get_tree().root
	for node in root.find_children("*", "Control", true, false):
		if "objektif" in node.name.to_lower():
			node.visible = terlihat and objektif_aktif != ""



# ---------------- MODE UJI ----------------
func _dijalankan_langsung() -> bool:
	# F6 mengirim path scene sebagai argumen; F5 tidak
	for arg in OS.get_cmdline_args():
		if arg.ends_with(".tscn") and not arg.ends_with("main_menu.tscn"):
			return true
	return false


const URUTAN_FLAG_UJI: Array = ["cutscene_hari_0", "uang_mama_diterima", "tawaran_pandu_diterima", "tutorial_booth_dimulai", "booth_disewa", "telepon_belanja", "bahan_dibeli", "telepon_ke_booth", "booth_rusak_ditemukan", "punya_obeng", "booth_diperbaiki", "keluhan_hari_3", "saran_pandu_diterima", "telepon_rani", "rani_bergabung"]
func _uji_flag_sampai(jumlah: int, objektif: String, hari: int = 1) -> void:
	Global.hari = hari
	Global.uang = 800000
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
			_uji_flag_sampai(12, "curhat_pandu", 3)
		"keluar_rumah":
			_uji_flag_sampai(13, "keluar_rumah", 3)   # telepon Rani berbunyi begitu bebas di map luar
		"jemput_rani":
			_uji_flag_sampai(14, "jemput_rani", 3)    # F6 dari map_4.tscn
		"rani_di_booth":
			_uji_flag_sampai(15, "berjualan", 3)
			set_flag("rani_ikut_arka")
			set_flag("rani_di_spot")
			_atur_jam_uji(16, 0)
		"antar_rani":
			_uji_flag_sampai(16, "antar_rani_pulang", 3)
			set_flag("rani_ikut_arka")
		"telat_rani":
			_uji_flag_sampai(16, "berjualan", 3)
			set_flag("rani_ikut_arka")
			set_flag("rani_di_spot")
			_atur_jam_uji(20, 58)
		"hari_4_rani":
			_uji_flag_sampai(16, "jemput_rani", 4)
		"hari4_tamat_good":
			Global.hari = 4
			Global.uang = 850000
			set_flag("booth_diperbaiki")
			set_flag("rani_sudah_pulang")
			_atur_jam_uji(20, 58)
		"hari4_tamat_bad":
			Global.hari = 4
			Global.uang = 300000
			set_flag("booth_diperbaiki")
			set_flag("rani_sudah_pulang")
			_atur_jam_uji(20, 58)
		"hari4_cek_portrait":
			Global.hari = 4
			Global.uang = 800000
			set_flag("booth_diperbaiki")
			set_flag("rani_bergabung")
			set_flag("rani_ikut_arka")
			set_flag("rani_di_spot")
			set_objektif("berjualan")
			_atur_jam_uji(8, 59)
			call_deferred("_buka_panel_uji")
		"hari4_rani_ingatkan":
			Global.hari = 4
			Global.uang = 800000
			set_flag("booth_diperbaiki")
			set_flag("rani_bergabung")
			set_flag("rani_ikut_arka")
			set_flag("rani_di_spot")
			set_flag("pak_iwan_festival")
			set_flag("festival_bayar_nanti")
			set_objektif("bayar_pak_iwan")
			_atur_jam_uji(10, 58)
		"hari5_awal":
			_uji_hari5(6, 0, 500000, true, "ke_festival")
		"hari5_festival_good":
			_uji_hari5(11, 50, 850000, true, "berjualan")
		"hari5_festival_bad":
			_uji_hari5(11, 50, 300000, true, "berjualan")
		"hari5_tanpa_rani":
			_uji_hari5(9, 0, 400000, false, "berjualan")
		"buat_save_hari_2":
			# TAHAP_UJI ini menimpa save asli agar Continue bisa diuji tanpa bermain sampai hari 2.
			Global.hari = 2
			Global.uang = 100000
			for i in 11:
				set_flag(URUTAN_FLAG_UJI[i])
			set_flag("keluhan_hari_2")
			set_objektif("temui_pandu_hari_2")
			_atur_jam_uji(6, 0)
			Global.scene_aktif = SCENE_BANGUN_PAKSA
			Global.spawn_id_aktif = SPAWN_ID_BANGUN_PAKSA
			if Global.simpan_game("uji_hari_2"):
				print("[Uji] Save hari 2 dibuat, jalankan F5 > Continue")
	_uang_terakhir = Global.uang
	_sesi_terakhir_dipantau = str(cari_hud().sesi) if cari_hud() and "sesi" in cari_hud() else "Pagi"
	print("[Cerita] MODE UJI aktif, tahap: ", TAHAP_UJI)

func _buka_panel_uji() -> void:
	var booths = get_tree().get_nodes_in_group("Booth")
	if not booths.is_empty() and booths[0].minigame_instance:
		booths[0].minigame_instance.buka_panel()

func _uji_hari5(jam: int, menit: int, uang: int, ikut_rani: bool, objektif: String) -> void:
	Global.hari = 5
	Global.uang = uang
	set_flag("booth_diperbaiki")
	set_flag("festival_lunas")
	if ikut_rani:
		set_flag("rani_bergabung")
		set_flag("rani_di_spot")
	set_objektif(objektif)
	_atur_jam_uji(jam, menit)


func petakan_scene(path: String) -> String:
	if Global.hari >= 5 and path == "res://map_4.tscn":
		if punya_flag("rani_bergabung"):
			set_flag("rani_di_spot")
		return "res://map_4_festival.tscn"
	return path


func _pantau_masuk_festival() -> void:
	var scene = get_tree().current_scene
	if scene == null or scene.scene_file_path != "res://map_4_festival.tscn" or Global.hari < 5:
		_scene_festival_disiapkan = false
		return
	if _scene_festival_disiapkan:
		return
	_scene_festival_disiapkan = true
	set_objektif("berjualan")
	if punya_flag("rani_bergabung"):
		set_flag("rani_di_spot")


func _pantau_ending_hari5() -> void:
	if Global.hari != 5 or punya_flag("ending_tampil") or sedang_ganti_hari or _jam_sekarang() < 12:
		return
	var booth = get_tree().get_first_node_in_group("Booth")
	if booth:
		if booth.minigame_instance and booth.minigame_instance.get("panel_terbuka"):
			booth.minigame_instance.tutup_panel()
		booth.tutup_toko_arka()
		booth.tutup_toko_rani()
		if booth.timer_spawn:
			booth.timer_spawn.stop()
	var spawner = get_tree().current_scene.get_node_or_null("SpawnerNpc") if get_tree().current_scene else null
	if spawner:
		spawner.set_process(false)
		for npc_jalan in spawner.get_children():
			if npc_jalan is CharacterBody2D:
				npc_jalan.set_physics_process(false)
				npc_jalan.queue_free()
	if not _player_bebas():
		return
	_atur_gerak_player(false)
	mulai_ending_festival("good" if Global.uang >= 800000 else "bad")

func _atur_jam_uji(jam: int, menit: int) -> void:
	var hud = cari_hud()
	if hud:
		if "jam" in hud: hud.jam = jam
		if "menit" in hud: hud.menit = menit
		if hud.has_method("cek_sesi"): hud.cek_sesi()
		if hud.has_method("update_ui"): hud.update_ui()
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
	if id_npc == "pak_iwan" and objektif_aktif == "bayar_pak_iwan" and punya_flag("pak_iwan_festival") and not punya_flag("festival_lunas"):
		var tahap_pak: Dictionary = DataDialog.DIALOG_TAHAP.get("pak_iwan", {})
		var bayar: Dictionary = tahap_pak.get("bayar_pak_iwan", {}).duplicate(true)
		if bayar.is_empty():
			push_warning("Dialog bayar_pak_iwan belum termuat; gunakan fallback")
			bayar = {"start": [{"speaker": "npc", "text": "Arka, booth festivalnya Rp200.000. Bayar sekarang atau nanti?", "choices": [{"text": "Bayar sekarang", "next": "bayar"}, {"text": "Bayar nanti", "next": "nanti"}]}], "bayar": [{"speaker": "npc", "text": "Sip, booth festivalnya sudah lunas!", "aksi": "festival_bayar_sekarang"}], "nanti": [{"speaker": "npc", "text": "Baik, tunggu di toko sampai sore ya.", "aksi": "festival_bayar_nanti"}]}
		if Global.uang < HARGA_BOOTH_FESTIVAL:
			bayar["start"][-1]["choices"][0]["nonaktif"] = true
			set_flag("festival_uang_kurang")
			_alert_uang_kurang()
		return bayar
	if id_npc == "rani":
		if punya_flag("telepon_rani") and not punya_flag("rani_bergabung"):
			return DataDialog.DIALOG_TAHAP["rani"]["jemput_rani"]
		elif punya_flag("rani_bergabung") and hari >= 4 and objektif_aktif == "jemput_rani":
			if punya_flag("rani_dilarang_hari_ini"):
				return DataDialog.DIALOG_TAHAP["rani"]["rani_dilarang"]
			else:
				return DataDialog.DIALOG_TAHAP["rani"]["jemput_rani_harian"]
				
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

func _jam_sekarang() -> int:
	var hud = cari_hud()
	return int(hud.jam) if hud and "jam" in hud else -1

func _di_map_3() -> bool:
	return get_tree().current_scene != null and get_tree().current_scene.scene_file_path == "res://map_3.tscn"

func _pantau_pak_iwan() -> void:
	if Global.hari != 4 or punya_flag("pak_iwan_festival") or _pak_iwan_sedang_cutscene or sedang_ganti_hari:
		return
	var jam := _jam_sekarang()
	if jam < 9:
		return
	if jam >= 16 and punya_flag("festival_bayar_nanti") and not punya_flag("festival_lunas"):
		set_flag("festival_lewat_tenggat")
	if jam < 11 and not _di_map_3():
		return
	if _di_map_3():
		var daftar_booth = get_tree().get_nodes_in_group("Booth")
		var booth = daftar_booth[0] if not daftar_booth.is_empty() else null
		if booth and booth.minigame_instance and booth.minigame_instance.get("panel_terbuka"):
			booth.minigame_instance.tutup_panel()
	if not _player_bebas():
		return
	_pak_iwan_sedang_cutscene = true
	if not _di_map_3():
		await TransitionScreen.transition_to("res://map_3.tscn", "Arka Pindah 2")
		for i in 120:
			if _di_map_3():
				break
			await get_tree().process_frame
		if not _di_map_3():
			push_warning("Gagal menunggu map_3 saat cutscene Pak Iwan")
			_pak_iwan_sedang_cutscene = false
			return
	await mulai_cutscene_pak_iwan()
	_pak_iwan_sedang_cutscene = false

func mulai_cutscene_pak_iwan() -> void:
	if punya_flag("pak_iwan_festival"):
		return
	_atur_gerak_player(false)
	var map = get_tree().current_scene
	var p = get_tree().get_first_node_in_group("Player")
	var booth = get_tree().get_first_node_in_group("Booth")
	if booth and booth.has_method("mulai_cutscene_pak_iwan"):
		booth.mulai_cutscene_pak_iwan()
	_buat_layar_cutscene()
	await fade_hitam(true)
	map = get_tree().current_scene
	p = get_tree().get_first_node_in_group("Player")
	if map == null or map.scene_file_path != "res://map_3.tscn":
		push_warning("Cutscene Pak Iwan hanya boleh berjalan di map_3")
		await fade_hitam(false)
		_bebaskan_lapisan_cutscene()
		if booth and booth.has_method("akhiri_cutscene_pak_iwan"):
			booth.akhiri_cutscene_pak_iwan()
		_atur_gerak_player(true)
		return
	var marker_player = map.get_node_or_null("Arka Pindah 2")
	if marker_player and p:
		p.global_position = marker_player.global_position
		if p.has_method("atur_arah_menghadap"):
			p.atur_arah_menghadap("atas")
	var marker_a = map.get_node_or_null("Pak Iwan A")
	var pak = map.get_node_or_null("pak_iwan")
	var sementara := false
	var resource_holder: Node = null
	if pak == null and ResourceLoader.exists("res://warung_pak_iwan.tscn"):
		var scene: PackedScene = load("res://warung_pak_iwan.tscn")
		resource_holder = scene.instantiate()
		pak = resource_holder.get_node_or_null("pak_iwan")
		if pak:
			resource_holder.remove_child(pak)
			map.add_child(pak)
			sementara = true
		else:
			resource_holder.free()
			resource_holder = null
	if marker_a == null:
		push_warning("Marker Pak Iwan A tidak ditemukan; dialog tetap dijalankan")
	if pak and marker_a:
		pak.global_position = marker_a.global_position
	# Scene dan posisi telah disiapkan; fade keluar sebelum cutscene terlihat.
	await fade_hitam(false)
	if pak and marker_a:
		for nama_marker in ["Pak Iwan B", "Pak Iwan C", "Pak Iwan D"]:
			var m = map.get_node_or_null(nama_marker)
			if m and pak.has_method("jalan_ke_titik"):
				await pak.jalan_ke_titik(m.global_position)
			elif not m:
				push_warning("Marker %s tidak ditemukan; dilewati" % nama_marker)
	var tree_key := "pak_iwan_festival_rani" if (punya_flag("rani_ikut_arka") or punya_flag("rani_di_spot")) else "pak_iwan_festival_sendiri"
	var tree: Dictionary = DataDialog.DIALOG_ADEGAN[tree_key].duplicate(true)
	if Global.uang < HARGA_BOOTH_FESTIVAL:
		tree["start"][-1]["choices"][0]["nonaktif"] = true
		set_flag("festival_uang_kurang")
		_alert_uang_kurang()
	var portrait_pak: Texture2D = pak.get("gambar_portrait_npc") if pak and pak.get("gambar_portrait_npc") is Texture2D else null
	if portrait_pak == null and ResourceLoader.exists("res://Assets/bg_Character/Pak Iwan.png"):
		portrait_pak = load("res://Assets/bg_Character/Pak Iwan.png")
	var portrait_arka: Texture2D = load(PATH_PORTRAIT_ARKA) if ResourceLoader.exists(PATH_PORTRAIT_ARKA) else null
	var portrait_rani := muat_portrait_rani()
	if portrait_rani == null and tree_key == "pak_iwan_festival_rani":
		portrait_rani = portrait_pak
	DialogBox.portrait_by_id = {"rani": portrait_rani if portrait_rani else portrait_pak}
	if tree.is_empty():
		push_warning("Dialog cutscene Pak Iwan tidak ditemukan: %s" % tree_key)
	else:
		while DialogBox.sedang_dialog:
			await get_tree().process_frame
		DialogBox.mulai_dialog(tree, portrait_pak, portrait_arka, "Pak Iwan", "Arka")
		await DialogBox.dialog_selesai
	DialogBox.portrait_by_id.clear()
	if pak and marker_a and pak.has_method("jalan_ke_titik"):
		await pak.jalan_ke_titik(marker_a.global_position)
	await fade_hitam(true)
	if sementara and is_instance_valid(pak):
		pak.queue_free()
		await get_tree().process_frame
	if is_instance_valid(resource_holder):
		resource_holder.queue_free()
	set_flag("pak_iwan_festival")
	if booth and booth.has_method("akhiri_cutscene_pak_iwan"):
		booth.akhiri_cutscene_pak_iwan()
	await fade_hitam(false)
	_bebaskan_lapisan_cutscene()
	_atur_gerak_player(true)

func _buat_layar_cutscene() -> ColorRect:
	var layer := CanvasLayer.new()
	layer.layer = 127
	get_tree().root.add_child(layer)
	_lapisan_cutscene = layer
	var rect := ColorRect.new()
	rect.color = Color.BLACK
	rect.modulate.a = 0.0
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return rect

func fade_hitam(masuk: bool) -> void:
	if not is_instance_valid(_lapisan_cutscene):
		return
	var rect := _lapisan_cutscene.get_child(0) as ColorRect
	if rect == null:
		return
	var alpha := 1.0 if masuk else 0.0
	var tween := create_tween()
	tween.tween_property(rect, "modulate:a", alpha, 0.35)
	await tween.finished

func _bebaskan_lapisan_cutscene() -> void:
	_bebaskan_lapisan(_lapisan_cutscene)
	_lapisan_cutscene = null

func muat_portrait_rani() -> Texture2D:
	if not ResourceLoader.exists(PATH_PORTRAIT_RANI):
		push_warning("Portrait Rani tidak ditemukan: %s" % PATH_PORTRAIT_RANI)
		return null
	return load(PATH_PORTRAIT_RANI)

func _pantau_rani_sesi() -> void:
	var hud = cari_hud()
	if hud == null or not ("sesi" in hud):
		return
	var sesi_baru := str(hud.sesi)
	var sesi_lama := _sesi_terakhir_dipantau
	if sesi_baru == sesi_lama:
		return
	_sesi_terakhir_dipantau = sesi_baru
	if Global.hari != 4 or punya_flag("festival_lunas") or not punya_flag("pak_iwan_festival"):
		return
	if not (punya_flag("rani_ikut_arka") or punya_flag("rani_di_spot")):
		return
	var id_dialog := ""
	if sesi_lama == "Pagi" and sesi_baru == "Siang":
		id_dialog = "rani_ingatkan_siang"
	elif sesi_lama == "Siang" and sesi_baru == "Sore":
		id_dialog = "rani_ingatkan_sore"
	if id_dialog == "" or punya_flag(id_dialog) or _dialog_rani_sedang_diantri:
		return
	_dialog_rani_sedang_diantri = true
	call_deferred("_jalankan_dialog_rani_sesi", id_dialog)

func _jalankan_dialog_rani_sesi(id_dialog: String) -> void:
	while not _player_bebas():
		if punya_flag("ending_tampil") or Global.hari != 4 or punya_flag("festival_lunas"):
			_dialog_rani_sedang_diantri = false
			return
		await get_tree().process_frame
	if not punya_flag("pak_iwan_festival") or not (punya_flag("rani_ikut_arka") or punya_flag("rani_di_spot")):
		_dialog_rani_sedang_diantri = false
		return
	var rani = get_tree().get_first_node_in_group("Rani")
	if rani == null:
		push_warning("Rani tidak ada di scene saat pengingat sesi")
		_dialog_rani_sedang_diantri = false
		return
	set_flag(id_dialog)
	var tree: Dictionary = DataDialog.DIALOG_ADEGAN.get(id_dialog, {})
	var tex_rani := muat_portrait_rani()
	var tex_arka: Texture2D = load(PATH_PORTRAIT_ARKA) if ResourceLoader.exists(PATH_PORTRAIT_ARKA) else null
	DialogBox.portrait_by_id = {"rani": tex_rani}
	DialogBox.mulai_dialog(tree, tex_rani, tex_arka, "Rani", "Arka")
	await DialogBox.dialog_selesai
	DialogBox.portrait_by_id.clear()
	_dialog_rani_sedang_diantri = false

func _alert_uang_kurang() -> void:
	var p = get_tree().get_first_node_in_group("Player")
	if p:
		TeksMelayang.munculkan_di_sekitar(p, "Uang belum cukup!", Color(1.0, 0.15, 0.15))

func _pantau_jualan_background_rani(delta: float) -> void:
	# Berjalan hanya jika Rani di spot, toko Rani dibuka, tidak sedang cutscene/transisi/menu
	if not Global.rani_sedang_jualan or not punya_flag("rani_di_spot") or sedang_ganti_hari or _di_menu_utama():
		_timer_jualan_bg_rani = 0.0
		return
	
	# Jika saat ini berada di scene booth (map_3 atau festival hari 5), simulasi fisik booth.gd yang bekerja
	var scene = get_tree().current_scene
	var nama_scene = scene.scene_file_path.get_file() if scene and scene.scene_file_path else ""
	if nama_scene == "map_3.tscn" or (nama_scene == "map_4_festival.tscn" and Global.hari == 5):
		_timer_jualan_bg_rani = 0.0
		return
	
	# Timer jualan di belakang layar (setiap 6-8 detik)
	_timer_jualan_bg_rani += delta
	_timer_peringatan_bahan_bg += delta
	if _timer_jualan_bg_rani < 7.0:
		return
	_timer_jualan_bg_rani = 0.0
	
	# Pilih random dari 3 menu (Cilok, Es Teh, Piscok) yang resepnya sudah terbuka
	var menu_tersedia: Array[String] = ["Cilok"]
	if punya_flag("resep_es_teh_terbuka"):
		menu_tersedia.append("Es Teh")
	if punya_flag("resep_piscok_terbuka"):
		menu_tersedia.append("Piscok")
	menu_tersedia.shuffle()
	
	var menu_terjual := ""
	var harga_terjual := 0
	
	for m in menu_tersedia:
		match m:
			"Cilok":
				if Global.terigu > 0:
					Global.terigu -= 1
					menu_terjual = "Cilok"
					harga_terjual = 10000
					break
				elif Global.bahan_cilok > 0:
					Global.bahan_cilok -= 1
					menu_terjual = "Cilok"
					harga_terjual = 10000
					break
			"Es Teh":
				if Global.teh_bubuk > 0 and Global.es_batu > 0:
					Global.teh_bubuk -= 1
					Global.es_batu -= 1
					menu_terjual = "Es Teh"
					harga_terjual = 8000
					break
			"Piscok":
				if Global.pisang > 0 and Global.coklat > 0 and Global.kulit_lumpia > 0:
					Global.pisang -= 1
					Global.coklat -= 1
					Global.kulit_lumpia -= 1
					menu_terjual = "Piscok"
					harga_terjual = 12000
					break
	
	var hud = cari_hud()
	var pos_ui_uang = Vector2(80, 25)
	if hud and "label_uang" in hud and hud.label_uang:
		pos_ui_uang = hud.label_uang.global_position + Vector2(60, 20)
		
	if menu_terjual != "":
		Global.uang += harga_terjual
		_uang_terakhir = Global.uang # Agar tidak diduplikasi oleh _pantau_uang()
		if Global.has_method("ubah_reputasi"):
			Global.ubah_reputasi(2)
		else:
			Global.reputasi_pelanggan += 2
		_putar_sfx(PATH_SFX_UANG_MASUK)
		
		# Teks melayang muncul di sekitar UI uang di kiri atas
		if scene:
			TeksMelayang.munculkan(scene, pos_ui_uang + Vector2(randf_range(-15, 15), randf_range(-5, 5)), "Rani: +" + TeksMelayang.format_rupiah(harga_terjual) + " (" + menu_terjual + ")", Color(0.2, 1.0, 0.2))
	else:
		# Bahan baku habis untuk semua menu
		if _timer_peringatan_bahan_bg >= 5.0:
			_timer_peringatan_bahan_bg = 0.0
			_putar_sfx(PATH_SFX_BAHAN_HABIS)
			if scene:
				TeksMelayang.munculkan(scene, pos_ui_uang + Vector2(randf_range(-10, 10), randf_range(0, 8)), "Rani: Bahan mentah habis!", Color(1.0, 0.4, 0.4))

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
				await _saat_hari_dimulai(hari_baru)
		3:
			if not punya_flag("keluhan_hari_3"):
				await get_tree().create_timer(0.5).timeout
				await mulai_monolog("keluhan_hari_3")
				await _saat_hari_dimulai(hari_baru)
		5:
			if not punya_flag("pagi_hari_5"):
				await get_tree().create_timer(0.5).timeout
				await mulai_monolog("pagi_hari_5")

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
		_putar_sfx(PATH_SFX_UANG_MASUK)
	else:
		TeksMelayang.munculkan_di_sekitar(player, "-" + TeksMelayang.format_rupiah(-_uang_tertunda), Color(1.0, 0.45, 0.45))
		_putar_sfx(PATH_SFX_UANG_KELUAR)
	_uang_tertunda = 0


func putar_sfx(path: String) -> void:
	_putar_sfx(path)

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
	if sedang_ganti_hari or Global.hari < BATAS_TIDUR_MULAI_HARI or Global.hari >= 5:
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
	
	# Hari 1 ke atas: tidur hanya bisa dilakukan ketika sudah memasuki waktu sore sampai malam (jam >= 16)
	var hud = cari_hud()
	if hud and "jam" in hud:
		return hud.jam >= 16 or hud.jam < JAM_BANGUN
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
	if sedang_ganti_hari or Global.hari >= 5:
		return
	sedang_ganti_hari = true

	var hari_baru: int = Global.hari + 1
	var akan_ending_hari_4: bool = hari_baru == 5 and not punya_flag("festival_lunas")
	var denda: int = 0
	var rani_dihukum: bool = false
	
	if paksa:
		if (punya_flag("rani_ikut_arka") or punya_flag("rani_di_spot")) and not punya_flag("rani_sudah_pulang"):
			rani_dihukum = true
			denda = mini(45000, Global.uang)
		else:
			denda = mini(DENDA_TIDAK_TIDUR, Global.uang)

	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_method("set_bisa_gerak"):
		player.set_bisa_gerak(false)

	# Layar hitam + teks, dibuat lewat kode (tanpa scene tambahan)
	var lapisan := CanvasLayer.new()
	lapisan.layer = 128
	get_tree().root.add_child(lapisan)
	_lapisan_ganti_hari = lapisan

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
		if rani_dihukum:
			sub.text = "Kamu ketiduran di luar dan lupa mengantar Rani pulang!"
		else:
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
		_putar_sfx(PATH_SFX_UANG_KELUAR)
	_atur_hud_pagi(jam_bangun, menit_bangun)
	# Set flag larangan Rani SEBELUM saat_hari_baru() agar objektif pagi langsung kosong
	if rani_dihukum:
		set_flag("rani_dilarang_hari_ini")
	if not akan_ending_hari_4 or punya_flag("festival_lunas"):
		saat_hari_baru(hari_baru)
	else:
		pass

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

	_bebaskan_lapisan(lapisan)
	_lapisan_ganti_hari = null
	sedang_ganti_hari = false

	# Jeda 1 detik setelah layar terang sebelum menjalankan monolog atau cutscene baru
	await get_tree().create_timer(1.0).timeout

	if akan_ending_hari_4 and not punya_flag("festival_lunas"):
		if paksa:
			var p_end = get_tree().get_first_node_in_group("Player")
			if denda > 0 and p_end:
				TeksMelayang.munculkan_di_sekitar(p_end, "-" + TeksMelayang.format_rupiah(denda), Color(1.0, 0.45, 0.45))
		mulai_ending("good" if Global.uang >= 800000 else "bad")
		return

	if paksa:
		_pulihkan_setelah_paksa(denda)

	if rani_dihukum:
		await mulai_telepon("telepon_mama_rani", "Mama Rani")

	await _saat_hari_dimulai(hari_baru)
	Global.scene_aktif = SCENE_BANGUN_PAKSA
	Global.spawn_id_aktif = SPAWN_ID_BANGUN_PAKSA
	Global.simpan_game("akhir_tidur")
	
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
	# Simpan dulu status larangan sebelum reset, agar pengecekan objektif pagi benar
	var rani_dilarang: bool = punya_flag("rani_dilarang_hari_ini")

	# Reset flag Rani harian (kecuali rani_dilarang_hari_ini — sudah di-set di ganti_hari)
	flag.erase("rani_ikut_arka")
	flag.erase("rani_sudah_pulang")
	flag.erase("rani_di_spot")
	Global.rani_sedang_jualan = false
	for booth in get_tree().get_nodes_in_group("Booth"):
		if is_instance_valid(booth):
			booth.tutup_toko_arka()
			booth.tutup_toko_rani()
	# rani_dilarang_hari_ini sengaja TIDAK dierase di sini; sudah ditangani di ganti_hari()

	match hari_baru:
		1:
			set_objektif("temui_pandu")
		2:
			set_objektif("temui_pandu_hari_2")
		5:
			set_objektif("ke_festival")
		_:
			if hari_baru >= 4 and punya_flag("rani_bergabung") and not rani_dilarang:
				set_objektif("jemput_rani")
			else:
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
			set_objektif("temui_pandu_hari_2")
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
				set_objektif("upgrade_meja_cecep")
			else:
				set_objektif("temui_mpok_wati")
		"buka_resep_piscok":
			if not punya_flag("resep_piscok_terbuka"):
				set_flag("resep_piscok_terbuka")
				dapat_item("Resep Piscok")
			if punya_flag("resep_es_teh_terbuka"):
				set_objektif("upgrade_meja_cecep")
			else:
				set_objektif("temui_mama")
		"keluhan_hari_3_selesai":
			if punya_flag("keluhan_hari_3"):
				return
			set_flag("keluhan_hari_3")
			set_objektif("curhat_pandu")
		"pagi_hari_5_selesai":
			set_flag("pagi_hari_5")
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
			set_flag("rani_ikut_arka")
			set_objektif("berjualan")
		"rani_ikut_lagi":
			set_flag("rani_ikut_arka")
			set_objektif("berjualan")
		"festival_bayar_sekarang":
			if Global.uang < HARGA_BOOTH_FESTIVAL:
				set_flag("festival_uang_kurang")
				return
			_kurangi_uang(HARGA_BOOTH_FESTIVAL)
			set_flag("festival_lunas")
			set_objektif("berjualan")
		"festival_bayar_nanti":
			set_flag("festival_bayar_nanti")
			set_objektif("bayar_pak_iwan")
		_:
			push_warning("Aksi dialog tidak dikenali: '%s'" % nama_aksi)


func mulai_ending(jenis: String) -> void:
	_buat_tampilan_ending(jenis, false)


func mulai_ending_festival(jenis: String) -> void:
	_buat_tampilan_ending(jenis, true)


func _buat_tampilan_ending(jenis: String, festival: bool) -> void:
	if punya_flag("ending_tampil"):
		return
	set_flag("ending_tampil")
	_atur_gerak_player(false)
	var layer := CanvasLayer.new()
	layer.layer = 250
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(layer)
	_lapisan_ending = layer

	var latar := ColorRect.new()
	latar.color = Color(0.05, 0.05, 0.07, 0.92)
	latar.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(latar)
	latar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Container kartu tengah
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -240.0
	panel.offset_right = 240.0
	panel.offset_top = -140.0
	panel.offset_bottom = 140.0
	panel.custom_minimum_size = Vector2(480, 280)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.12, 0.15, 0.98)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.85, 0.65, 0.25, 0.8)
	panel_style.content_margin_left = 24.0
	panel_style.content_margin_right = 24.0
	panel_style.content_margin_top = 18.0
	panel_style.content_margin_bottom = 18.0
	panel.add_theme_stylebox_override("panel", panel_style)
	latar.add_child(panel)

	var isi := VBoxContainer.new()
	isi.alignment = BoxContainer.ALIGNMENT_CENTER
	isi.add_theme_constant_override("separation", 12)
	panel.add_child(isi)

	var judul := Label.new()
	var teks := Label.new()
	var teks_uang := "Total Uang: " + TeksMelayang.format_rupiah(Global.uang)
	var warna_judul := Color(1.0, 0.84, 0.0) # Emas

	match jenis:
		"good":
			judul.text = "★ GOOD ENDING ★"
			warna_judul = Color(0.2, 0.9, 0.4) # Hijau terang
			if festival:
				var kunci_teks := "good_rani" if punya_flag("rani_bergabung") else "good_sendiri"
				teks.text = DataDialog.TEKS_ENDING_FESTIVAL[kunci_teks]
			else:
				teks.text = "Kamu berhasil mengumpulkan cukup uang walau tidak berjualan di festival. Arka pun berhasil membeli GUNDAM yang ia impikan!"
		"gagal":
			judul.text = "GAME OVER"
			warna_judul = Color(0.9, 0.25, 0.25)
			teks.text = "Perjalanan Arka berakhir di sini.\nMungkin lain waktu ia bisa mencoba lagi."
		_:
			judul.text = "BAD ENDING"
			warna_judul = Color(0.95, 0.45, 0.2)
			if festival:
				teks.text = DataDialog.TEKS_ENDING_FESTIVAL["bad"]
				teks_uang += "  |  Kekurangan: " + TeksMelayang.format_rupiah(800000 - Global.uang)
			else:
				teks.text = "Arka belum berhasil mengumpulkan cukup uang untuk festival.\nHari yang melelahkan itu menjadi akhir dari rencananya."

	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	judul.add_theme_font_size_override("font_size", 20)
	judul.add_theme_color_override("font_color", warna_judul)
	isi.add_child(judul)

	teks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	teks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	teks.custom_minimum_size = Vector2(430, 80)
	teks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	teks.add_theme_font_size_override("font_size", 12)
	teks.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	isi.add_child(teks)

	var jumlah_uang := Label.new()
	jumlah_uang.text = teks_uang
	jumlah_uang.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	jumlah_uang.add_theme_font_size_override("font_size", 13)
	jumlah_uang.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	isi.add_child(jumlah_uang)

	# Spacer
	var pemisah := Control.new()
	pemisah.custom_minimum_size = Vector2(0, 4)
	isi.add_child(pemisah)

	var tombol := Button.new()
	tombol.text = "Kembali ke Menu Utama"
	tombol.custom_minimum_size = Vector2(180, 36)
	tombol.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tombol.mouse_filter = Control.MOUSE_FILTER_STOP
	tombol.focus_mode = Control.FOCUS_ALL

	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.2, 0.5, 0.8, 1.0)
	btn_normal.corner_radius_top_left = 6
	btn_normal.corner_radius_top_right = 6
	btn_normal.corner_radius_bottom_left = 6
	btn_normal.corner_radius_bottom_right = 6
	btn_normal.content_margin_left = 12.0
	btn_normal.content_margin_right = 12.0
	btn_normal.content_margin_top = 6.0
	btn_normal.content_margin_bottom = 6.0
	tombol.add_theme_stylebox_override("normal", btn_normal)

	var btn_hover := StyleBoxFlat.new()
	btn_hover.bg_color = Color(0.25, 0.6, 0.95, 1.0)
	btn_hover.corner_radius_top_left = 6
	btn_hover.corner_radius_top_right = 6
	btn_hover.corner_radius_bottom_left = 6
	btn_hover.corner_radius_bottom_right = 6
	btn_hover.content_margin_left = 12.0
	btn_hover.content_margin_right = 12.0
	btn_hover.content_margin_top = 6.0
	btn_hover.content_margin_bottom = 6.0
	tombol.add_theme_stylebox_override("hover", btn_hover)

	tombol.add_theme_font_size_override("font_size", 13)
	tombol.pressed.connect(_kembali_ke_menu)
	isi.add_child(tombol)

func _tampilkan_ending(tombol: Button) -> void:
	pass

func _kembali_ke_menu() -> void:
	var tree := get_tree()
	_bebaskan_lapisan(_lapisan_ganti_hari)
	_lapisan_ganti_hari = null
	_bebaskan_lapisan(_lapisan_cutscene)
	_lapisan_cutscene = null
	_bebaskan_lapisan(_lapisan_ending)
	_lapisan_ending = null
	tree.paused = false
	sedang_ganti_hari = false
	set_objektif("")
	_atur_visibilitas_panel_objektif(false)
	_panel_objektif_menu_disembunyikan = true

	# Reset state cerita dan global flags
	flag.erase("ending_tampil")
	flag.clear()

	var hud_ending = cari_hud()
	if hud_ending:
		hud_ending.menu_akhir_aktif = true
		if hud_ending.audio_bgm: hud_ending.audio_bgm.stop()
		if hud_ending.audio_sfx: hud_ending.audio_sfx.stop()
		if hud_ending.timer_waktu: hud_ending.timer_waktu.stop()
		hud_ending.hide()
	if Musik:
		Musik.reset_untuk_menu()
	var hud = cari_hud()
	if hud:
		var transisi_hud = hud.get("layar_transisi")
		if transisi_hud is CanvasItem:
			transisi_hud.hide()
	if TransitionScreen and is_instance_valid(TransitionScreen.color_rect):
		TransitionScreen.anim.stop()
		TransitionScreen.color_rect.color.a = 0.0

	var hasil := tree.change_scene_to_file("res://main_menu.tscn")
	if hasil != OK:
		push_warning("Gagal kembali ke menu: %s" % error_string(hasil))

func _bebaskan_lapisan(lapisan: CanvasLayer) -> void:
	if not is_instance_valid(lapisan):
		return
	if lapisan.is_inside_tree():
		lapisan.get_parent().remove_child(lapisan)
	lapisan.queue_free()

func mulai_ending_gagal() -> void:
	mulai_ending("gagal")


# Dipanggil saat New Game (dari main_menu.gd)
func reset_cerita() -> void:
	flag.clear()
	_scene_festival_disiapkan = false
	_uang_tertunda = 0
	_hari_dipaksa = -1
	sedang_ganti_hari = false
	set_objektif("")
	_sedang_telepon = false
	_pak_iwan_sedang_cutscene = false
	_dialog_rani_sedang_diantri = false
	_bahan_terakhir = _total_bahan()
