extends CanvasLayer

@onready var panel_utama = $PanelUtama
@onready var label_stok = $PanelUtama/VBoxContainer/LabelStok
@onready var label_hasil = $PanelUtama/VBoxContainer/LabelHasil
@onready var label_status = $PanelUtama/VBoxContainer/LabelStatus
@onready var bar_proses = $PanelUtama/VBoxContainer/BarProses

@onready var tombol_masak_cilok = $PanelUtama/VBoxContainer/HBoxTombol/TombolCilok
@onready var tombol_buat_es_teh = $PanelUtama/VBoxContainer/HBoxTombol/TombolEsTeh
@onready var tombol_masak_piscok = $PanelUtama/VBoxContainer/HBoxTombol/TombolPiscok
@onready var tombol_tutup = $PanelUtama/TombolTutup

var sedang_masak: bool = false
var menu_sedang_dimasak: String = ""
var waktu_berjalan: float = 0.0
var durasi_masak: float = 5.0

func _ready():
	hide()
	if tombol_masak_cilok:
		tombol_masak_cilok.pressed.connect(_on_tombol_masak_cilok_pressed)
	if tombol_buat_es_teh:
		tombol_buat_es_teh.pressed.connect(_on_tombol_buat_es_teh_pressed)
	if tombol_masak_piscok:
		tombol_masak_piscok.pressed.connect(_on_tombol_masak_piscok_pressed)
	if tombol_tutup:
		tombol_tutup.pressed.connect(_on_tombol_tutup_pressed)
	
	if bar_proses:
		bar_proses.value = 0
	if label_status:
		label_status.text = "Pilih menu untuk dimasak/dibuat"
	perbarui_tampilan()

func _process(delta: float):
	if visible:
		perbarui_tampilan()
		
		if sedang_masak:
			waktu_berjalan += delta
			var persentase = (waktu_berjalan / durasi_masak) * 100.0
			if bar_proses:
				bar_proses.value = clampf(persentase, 0.0, 100.0)
			
			if waktu_berjalan >= durasi_masak:
				_selesai_masak()

func buka_panel():
	show()
	perbarui_tampilan()

func tutup_panel():
	hide()

func perbarui_tampilan():
	if label_stok:
		label_stok.text = "BAHAN: Terigu:%d | Teh:%d | Es:%d | Pisang:%d | Coklat:%d | Kulit:%d" % [
			Global.terigu + Global.bahan_cilok,
			Global.teh_bubuk,
			Global.es_batu,
			Global.pisang,
			Global.coklat,
			Global.kulit_lumpia
		]
	if label_hasil:
		label_hasil.text = "SIAP JUAL: Cilok:%d porsi | Es Teh:%d gelas | Piscok:%d porsi" % [
			Global.cilok_matang,
			Global.es_teh_siap,
			Global.piscok_matang
		]
		
	durasi_masak = Global.waktu_masak
	
	var ada_bahan_cilok = (Global.terigu > 0 or Global.bahan_cilok > 0)
	var ada_bahan_esteh = (Global.teh_bubuk > 0 and Global.es_batu > 0)
	var ada_bahan_piscok = (Global.pisang > 0 and Global.coklat > 0 and Global.kulit_lumpia > 0)
	
	if tombol_masak_cilok:
		tombol_masak_cilok.disabled = sedang_masak or not ada_bahan_cilok
	if tombol_buat_es_teh:
		tombol_buat_es_teh.disabled = sedang_masak or not ada_bahan_esteh
	if tombol_masak_piscok:
		tombol_masak_piscok.disabled = sedang_masak or not ada_bahan_piscok

func _on_tombol_masak_cilok_pressed():
	if sedang_masak: return
	if Global.terigu > 0:
		Global.terigu -= 1
	elif Global.bahan_cilok > 0:
		Global.bahan_cilok -= 1
	else:
		label_status.text = "Bahan Terigu Habis!"
		return
		
	menu_sedang_dimasak = "Cilok"
	_mulai_proses("Sedang memasak Cilok...")

func _on_tombol_buat_es_teh_pressed():
	if sedang_masak: return
	if Global.teh_bubuk > 0 and Global.es_batu > 0:
		Global.teh_bubuk -= 1
		Global.es_batu -= 1
	else:
		label_status.text = "Bahan Teh Bubuk / Es Batu kurang!"
		return
		
	menu_sedang_dimasak = "Es Teh"
	_mulai_proses("Sedang membuat Es Teh Segar...")

func _on_tombol_masak_piscok_pressed():
	if sedang_masak: return
	if Global.pisang > 0 and Global.coklat > 0 and Global.kulit_lumpia > 0:
		Global.pisang -= 1
		Global.coklat -= 1
		Global.kulit_lumpia -= 1
	else:
		label_status.text = "Bahan Pisang / Coklat / Kulit kurang!"
		return
		
	menu_sedang_dimasak = "Piscok"
	_mulai_proses("Sedang menggoreng Piscok...")

func _mulai_proses(pesan_status: String):
	sedang_masak = true
	waktu_berjalan = 0.0
	if bar_proses: bar_proses.value = 0
	if label_status: label_status.text = pesan_status
	perbarui_tampilan()

func _selesai_masak():
	sedang_masak = false
	waktu_berjalan = 0.0
	if bar_proses: bar_proses.value = 100
	
	match menu_sedang_dimasak:
		"Cilok":
			Global.cilok_matang += 1
			label_status.text = "Cilok Matang Selesai!"
		"Es Teh":
			Global.es_teh_siap += 1
			label_status.text = "Es Teh Segar Selesai!"
		"Piscok":
			Global.piscok_matang += 1
			label_status.text = "Piscok Renyah Selesai!"
			
	menu_sedang_dimasak = ""
	perbarui_tampilan()

func _on_tombol_tutup_pressed():
	tutup_panel()
