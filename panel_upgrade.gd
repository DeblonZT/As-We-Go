extends Panel

@onready var label_uang = $LabelUang
@onready var btn_kompor_1 = $ScrollContainer/VBoxContainer/HboxKompor/BtnKompor1
@onready var btn_kompor_2 = $ScrollContainer/VBoxContainer/HboxKompor/BtnKompor2
@onready var btn_kompor_3 = $ScrollContainer/VBoxContainer/HboxKompor/BtnKompor3

@onready var btn_meja_1 = $ScrollContainer/VBoxContainer/HboxMeja/BtnMeja1
@onready var btn_meja_2 = $ScrollContainer/VBoxContainer/HboxMeja/BtnMeja2
@onready var btn_meja_3 = $ScrollContainer/VBoxContainer/HboxMeja/BtnMeja3

var popup: Control = null

func _ready():
	hide() # Sembunyikan panel saat game baru mulai
	_pastikan_popup()
	update_ui()

func _pastikan_popup():
	if popup == null:
		popup = get_node_or_null("../PopupNotifikasi")
		if popup == null:
			popup = get_node_or_null("PopupNotifikasi")
		if popup == null:
			var popup_scene = load("res://popup_notifikasi.tscn")
			if popup_scene:
				popup = popup_scene.instantiate()
				if get_parent():
					get_parent().add_child(popup)
				else:
					add_child(popup)

func _on_visibility_changed():
	if visible:
		update_ui() # Refresh UI setiap kali panel muncul di layar

# Fungsi ini menyegarkan tulisan uang dan status tombol sesuai level
func update_ui():
	if label_uang: 
		label_uang.text = Global.format_rupiah(Global.uang)
	
	# Status Tombol Kompor
	if btn_kompor_1:
		if Global.level_kompor >= 1:
			btn_kompor_1.disabled = true
			btn_kompor_1.text = "lvl 1\n(Milik)"
		else:
			btn_kompor_1.disabled = false
			btn_kompor_1.text = "lvl 1\n50rb"
			
	if btn_kompor_2:
		if Global.level_kompor >= 2:
			btn_kompor_2.disabled = true
			btn_kompor_2.text = "lvl 2\n(Milik)"
		elif Global.level_kompor == 1:
			btn_kompor_2.disabled = false
			btn_kompor_2.text = "lvl 2\n100rb"
		else:
			btn_kompor_2.disabled = true
			btn_kompor_2.text = "lvl 2\n100rb"
			
	if btn_kompor_3:
		if Global.level_kompor >= 3:
			btn_kompor_3.disabled = true
			btn_kompor_3.text = "lvl 3\n(Milik)"
		elif Global.level_kompor == 2:
			btn_kompor_3.disabled = false
			btn_kompor_3.text = "lvl 3\n200rb"
		else:
			btn_kompor_3.disabled = true
			btn_kompor_3.text = "lvl 3\n200rb"
	
	# Status Tombol Meja
	if btn_meja_1:
		if Global.level_meja >= 1:
			btn_meja_1.disabled = true
			btn_meja_1.text = "lvl 1\n(Milik)"
		else:
			btn_meja_1.disabled = false
			btn_meja_1.text = "lvl 1\n40rb"
			
	if btn_meja_2:
		if Global.level_meja >= 2:
			btn_meja_2.disabled = true
			btn_meja_2.text = "lvl 2\n(Milik)"
		elif Global.level_meja == 1:
			btn_meja_2.disabled = false
			btn_meja_2.text = "lvl 2\n80rb"
		else:
			btn_meja_2.disabled = true
			btn_meja_2.text = "lvl 2\n80rb"
			
	if btn_meja_3:
		if Global.level_meja >= 3:
			btn_meja_3.disabled = true
			btn_meja_3.text = "lvl 3\n(Milik)"
		elif Global.level_meja == 2:
			btn_meja_3.disabled = false
			btn_meja_3.text = "lvl 3\n150rb"
		else:
			btn_meja_3.disabled = true
			btn_meja_3.text = "lvl 3\n150rb"
		
	# Refresh tampilan UI utama jika diperlukan
	var main_ui = get_tree().get_first_node_in_group("MainUI")
	if main_ui and main_ui.has_method("update_ui_uang"):
		main_ui.update_ui_uang()

# --- FUNGSI TOMBOL BELI KOMPOR ---
func _on_btn_kompor_1_pressed():
	_proses_upgrade_kompor(1, 50000, 4.0)

func _on_btn_kompor_2_pressed():
	_proses_upgrade_kompor(2, 100000, 3.0)

func _on_btn_kompor_3_pressed():
	_proses_upgrade_kompor(3, 200000, 1.5)

func _proses_upgrade_kompor(level: int, harga: int, waktu: float):
	var hasil = Global.beli_upgrade_kompor(level, harga, waktu)
	update_ui()
	var judul = "BERHASIL UPGRADE!" if hasil.sukses else "UANG TIDAK CUKUP!"
	_tampilkan_notifikasi(judul, hasil.pesan, hasil.sukses)

# --- FUNGSI TOMBOL BELI MEJA ADONAN ---
func _on_btn_meja_1_pressed():
	_proses_upgrade_meja(1, 40000, 4.0)

func _on_btn_meja_2_pressed():
	_proses_upgrade_meja(2, 80000, 3.0)

func _on_btn_meja_3_pressed():
	_proses_upgrade_meja(3, 150000, 1.5)

func _proses_upgrade_meja(level: int, harga: int, waktu: float):
	var hasil = Global.beli_upgrade_meja(level, harga, waktu)
	update_ui()
	var judul = "BERHASIL UPGRADE!" if hasil.sukses else "UANG TIDAK CUKUP!"
	_tampilkan_notifikasi(judul, hasil.pesan, hasil.sukses)

func _tampilkan_notifikasi(judul: String, pesan: String, is_sukses: bool):
	_pastikan_popup()
	if popup and popup.has_method("tampilkan"):
		popup.tampilkan(judul, pesan, is_sukses)

# --- FUNGSI TOMBOL CLOSE ---
func _on_btn_close_pressed():
	if popup and popup.visible and popup.has_method("tutup"):
		popup.tutup()
	hide() # Ini akan memicu sinyal `hidden` ke skrip mang_cecep.gd
