extends Panel

@onready var label_uang = $LabelUang

var popup: Control = null

func _ready():
	hide()
	_pastikan_popup()
	update_ui_uang()

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

# Fungsi ini akan otomatis dipanggil Godot setiap kali panel_toko di-show() atau di-hide()
func _on_visibility_changed():
	if visible:
		update_ui_uang()

func update_ui_uang():
	if label_uang:
		label_uang.text = Global.format_rupiah(Global.uang)
		
	# Refresh tampilan UI utama jika tersedia
	var main_ui = get_tree().get_first_node_in_group("MainUI")
	if main_ui and main_ui.has_method("update_ui_uang"):
		main_ui.update_ui_uang()

# --- FUNGSI TRANSAKSI DENGAN VALIDASI & POP UP ---
func _beli_item(id_bahan: String, nama_tampilan: String, harga: int):
	if Global.uang < harga:
		var kurang = harga - Global.uang
		var pesan = "Uang kamu tidak cukup untuk membeli %s!\nHarga: %s\nUang kamu: %s\n(Kurang %s)" % [
			nama_tampilan,
			Global.format_rupiah(harga),
			Global.format_rupiah(Global.uang),
			Global.format_rupiah(kurang)
		]
		_tampilkan_notifikasi("UANG TIDAK CUKUP!", pesan, false)
	else:
		if Global.beli_barang(id_bahan, harga):
			update_ui_uang()
			var pesan = "Kamu berhasil membeli %s seharga %s!\nSisa uang: %s" % [
				nama_tampilan,
				Global.format_rupiah(harga),
				Global.format_rupiah(Global.uang)
			]
			_tampilkan_notifikasi("BERHASIL DIBELI!", pesan, true)

func _tampilkan_notifikasi(judul: String, pesan: String, is_sukses: bool):
	_pastikan_popup()
	if popup and popup.has_method("tampilkan"):
		popup.tampilkan(judul, pesan, is_sukses)

# --- FUNGSI TOMBOL BELI BAHAN ---
func _on_btn_beli_terigu_pressed():
	_beli_item("terigu", "Tepung Terigu", 5000)

func _on_btn_beli_pisang_pressed():
	_beli_item("pisang", "Pisang", 8000)

func _on_btn_beli_teh_pressed():
	_beli_item("teh", "Teh Bubuk", 3000)

func _on_btn_beli_coklat_pressed():
	_beli_item("coklat", "Selai Coklat", 10000)

func _on_btn_beli_kulit_pressed():
	_beli_item("kulit", "Kulit Lumpia", 4000)

func _on_btn_beli_es_pressed():
	_beli_item("es", "Es Batu", 2000)

func _on_btn_close_pressed():
	if popup and popup.visible and popup.has_method("tutup"):
		popup.tutup()
	hide()
