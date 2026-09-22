extends Node
# Autoload "Cerita": flag progres cerita, objektif aktif, aksi dari dialog,
# dan pemantau uang untuk efek teks melayang + suaranya.
# Path Autoload = res://cerita.gd (script, bukan .tscn).

signal objektif_berubah(id_objektif: String)
signal flag_berubah(nama: String)

# id_objektif -> teks yang nanti ditampilkan di layar (label objektif)
const DATA_OBJEKTIF = {
	"minta_uang_mama": "Minta uang ke Mama",
	"temui_pandu": "Temui Bang Pandu di lantai 2",
	"tidur": "Tidur di kasur",
	"sewa_booth": "Sewa booth ke Pak Iwan",
}

# Suara saat uang bertambah. GANTI dengan path file suaramu (klik kanan file -> Copy Path)
const PATH_SFX_UANG: String = "res://SFX/Item_collected_1.wav"
const VOLUME_SFX_DB: float = 0.0
const BUS_SFX: String = "SFX"  # kalau bus ini tidak ada, otomatis pakai Master

# Berapa detik player bebas bergerak tanpa mengerjakan objektif sebelum panah muncul.
var jeda_panah: float = 60.0

var flag: Dictionary = {}
var objektif_aktif: String = ""
var waktu_objektif: float = 0.0
var panah_aktif: bool = false

var _uang_terakhir: int = 0
var _uang_tertunda: int = 0


func _ready() -> void:
	_uang_terakhir = Global.uang  # supaya uang bawaan tidak dianggap "pemasukan"


func _process(delta: float) -> void:
	_pantau_uang()
	_hitung_waktu_objektif(delta)


# ---------------- EFEK UANG ----------------
# Memantau Global.uang dari mana pun berubahnya (Mama, pelanggan, dst),
# jadi tidak perlu mengubah Global.gd. Teks + suara baru muncul setelah dialog
# tertutup supaya tidak ketutup kotak dialog.
func _pantau_uang() -> void:
	var uang_sekarang: int = Global.uang
	var selisih: int = uang_sekarang - _uang_terakhir
	_uang_terakhir = uang_sekarang
	if selisih > 0:
		_uang_tertunda += selisih

	if _uang_tertunda <= 0 or DialogBox.sedang_dialog:
		return
	var player = get_tree().get_first_node_in_group("Player")
	if player == null:
		return
	TeksMelayang.munculkan_di_sekitar(player, "+" + TeksMelayang.format_rupiah(_uang_tertunda))
	_putar_sfx_uang()
	_uang_tertunda = 0


func _putar_sfx_uang() -> void:
	if not ResourceLoader.exists(PATH_SFX_UANG):
		push_warning("SFX uang tidak ditemukan: '%s' (cek PATH_SFX_UANG di cerita.gd)" % PATH_SFX_UANG)
		return
	var pemutar := AudioStreamPlayer.new()
	pemutar.stream = load(PATH_SFX_UANG)
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
# Dipanggil tempat_tidur.gd saat layar sudah hitam dan hari sudah diganti.
func saat_hari_baru(hari_baru: int) -> void:
	match hari_baru:
		1:
			set_objektif("temui_pandu")  # tutorial berjualan dilanjutkan Pandu
		_:
			set_objektif("")


# ---------------- AKSI DARI DIALOG ----------------
# Dipanggil dialog_box.gd saat baris dengan key "aksi" ditampilkan.
# Setiap aksi dijaga supaya tidak jalan dua kali kalau dialognya terulang.
func jalankan_aksi(nama_aksi: String) -> void:
	match nama_aksi:
		"beri_uang_20000":
			if punya_flag("uang_mama_diterima"):
				return
			_tambah_uang(20000)
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
		_:
			push_warning("Aksi dialog tidak dikenali: '%s'" % nama_aksi)


func mulai_ending_gagal() -> void:
	# TODO: layar ending gagal + kembali ke main menu
	push_warning("mulai_ending_gagal(): layar ending belum dibuat")


# Dipanggil saat New Game (dari main_menu.gd)
func reset_cerita() -> void:
	flag.clear()
	_uang_tertunda = 0
	set_objektif("")
