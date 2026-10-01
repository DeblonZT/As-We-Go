@tool
extends CanvasLayer
# Autoload "PanelObjektif" (didaftarkan dari panel_objektif.tscn).
# Posisi, ukuran, dan margin diatur di scene. Gaya teks (ukuran, warna, jarak)
# diatur di Inspector node root ini, grup "Gaya Teks", dan langsung tampil di editor.

@export_group("Gaya Teks")
@export_range(6, 80) var ukuran_font_judul: int = 10:
	set(nilai):
		ukuran_font_judul = nilai
		_terapkan_gaya()
@export_range(6, 80) var ukuran_font_teks: int = 14:
	set(nilai):
		ukuran_font_teks = nilai
		_terapkan_gaya()
@export var warna_judul: Color = Color(0, 0, 0, 0.6):
	set(nilai):
		warna_judul = nilai
		_terapkan_gaya()
@export var warna_teks: Color = Color(0, 0, 0, 1):
	set(nilai):
		warna_teks = nilai
		_terapkan_gaya()
@export_range(0, 20) var jarak_antar_baris: int = 2:
	set(nilai):
		jarak_antar_baris = nilai
		_terapkan_gaya()

@export_group("Perilaku")
@export var pinjam_gaya_dari_dialog_box: bool = true  # hanya mengisi tekstur & font yang masih kosong
@export var tinggi_otomatis: bool = true              # tinggi panel menyesuaikan panjang teks
@export var durasi_masuk: float = 0.35
@export var durasi_keluar: float = 0.25

@onready var panel: NinePatchRect = $Panel
@onready var margin: MarginContainer = $Panel/Margin
@onready var isi_box: VBoxContainer = $Panel/Margin/Isi
@onready var judul: Label = $Panel/Margin/Isi/Judul
@onready var teks: Label = $Panel/Margin/Isi/Teks

var posisi_akhir: Vector2
var posisi_awal: Vector2
var sedang_tampil: bool = false
var tween_panel: Tween


func _ready() -> void:
	_terapkan_gaya()
	if Engine.is_editor_hint():
		return  # di editor cukup tampilkan gaya, jangan jalankan logika game
		
		process_mode = Node.PROCESS_MODE_ALWAYS

	teks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Posisi yang kamu atur di editor = posisi akhir (seperti KotakDialog)
	posisi_akhir = panel.position
	posisi_awal = Vector2(-panel.size.x - 20.0, posisi_akhir.y)
	panel.position = posisi_awal
	panel.modulate.a = 0.0
	panel.visible = false
	# Ditunda satu frame supaya DialogBox & Cerita pasti sudah siap
	call_deferred("_siapkan")


func _terapkan_gaya() -> void:
	if not is_node_ready():
		return
	judul.add_theme_font_size_override("font_size", ukuran_font_judul)
	teks.add_theme_font_size_override("font_size", ukuran_font_teks)
	judul.add_theme_color_override("font_color", warna_judul)
	teks.add_theme_color_override("font_color", warna_teks)
	isi_box.add_theme_constant_override("separation", jarak_antar_baris)


func _siapkan() -> void:
	if pinjam_gaya_dari_dialog_box:
		_pinjam_gaya()
	Cerita.objektif_berubah.connect(_pada_objektif_berubah)
	teks.text = Cerita.teks_objektif()
	await _ukur_ulang()


# Hanya mengisi yang masih kosong, jadi yang sudah kamu atur sendiri tidak ditimpa
func _pinjam_gaya() -> void:
	if panel.texture == null and DialogBox.kotak is TextureRect and DialogBox.kotak.texture:
		panel.texture = DialogBox.kotak.texture

	if not teks.has_theme_font_override("font"):
		var font: Font = null
		var sumber = DialogBox.label
		if sumber is RichTextLabel:
			font = sumber.get_theme_font("normal_font")
		elif sumber is Label:
			font = sumber.get_theme_font("font")
		if font:
			teks.add_theme_font_override("font", font)
			judul.add_theme_font_override("font", font)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var harus_tampil: bool = Cerita.objektif_aktif != "" \
		and not DialogBox.sedang_dialog \
		and not get_tree().paused \
		and not Cerita.sedang_ganti_hari
	_atur_tampil(harus_tampil)


func _pada_objektif_berubah(_id: String) -> void:
	var teks_baru: String = Cerita.teks_objektif()
	if teks_baru == "":
		return  # _process yang akan menyembunyikan panel
	teks.text = teks_baru
	await _ukur_ulang()
	if sedang_tampil:
		_kedip()


# Tunggu satu frame supaya autowrap selesai dihitung, baru ukur tinggi panel
func _ukur_ulang() -> void:
	await get_tree().process_frame
	if tinggi_otomatis:
		panel.size.y = margin.get_combined_minimum_size().y


func _atur_tampil(nilai: bool) -> void:
	if nilai == sedang_tampil:
		return
	sedang_tampil = nilai
	if tween_panel:
		tween_panel.kill()
	tween_panel = create_tween()
	tween_panel.set_parallel(true)

	if nilai:
		panel.visible = true
		tween_panel.tween_property(panel, "position", posisi_akhir, durasi_masuk) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween_panel.tween_property(panel, "modulate:a", 1.0, durasi_masuk)
	else:
		tween_panel.tween_property(panel, "position", posisi_awal, durasi_keluar) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween_panel.tween_property(panel, "modulate:a", 0.0, durasi_keluar)
		tween_panel.chain().tween_callback(func():
			if not sedang_tampil:
				panel.visible = false
		)


# Kedip terang singkat saat objektif berganti
func _kedip() -> void:
	panel.modulate = Color(1.6, 1.6, 1.3, 1.0)
	create_tween().tween_property(panel, "modulate", Color.WHITE, 0.6)
