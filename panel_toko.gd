extends Panel

@onready var label_uang = $LabelUang

var popup: Control = null

var jumlah_item = {
	"terigu": 1,
	"pisang": 1,
	"teh": 1,
	"coklat": 1,
	"kulit": 1,
	"es": 1
}

const DATA_BARANG = {
	"terigu": {"nama": "Tepung Terigu", "harga": 5000, "resep": ""},
	"teh": {"nama": "Teh Bubuk", "harga": 3000, "resep": "resep_es_teh_terbuka"},
	"es": {"nama": "Es Batu", "harga": 2000, "resep": "resep_es_teh_terbuka"},
	"pisang": {"nama": "Pisang", "harga": 8000, "resep": "resep_piscok_terbuka"},
	"coklat": {"nama": "Selai Coklat", "harga": 10000, "resep": "resep_piscok_terbuka"},
	"kulit": {"nama": "Kulit Lumpia", "harga": 4000, "resep": "resep_piscok_terbuka"},
}

func _ready():
	hide()
	visibility_changed.connect(_on_visibility_changed)
	_pastikan_popup()
	_hubungkan_tombol_jumlah()
	update_ui_uang()
	update_tampilan_toko()

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
		update_ui_uang()
		update_tampilan_toko()

func update_ui_uang():
	if label_uang:
		label_uang.text = Global.format_rupiah(Global.uang)
		
	var main_ui = get_tree().get_first_node_in_group("MainUI")
	if main_ui and main_ui.has_method("update_ui_uang"):
		main_ui.update_ui_uang()

func _hubungkan_tombol_jumlah():
	for key in DATA_BARANG.keys():
		var node_name = _get_node_name_by_key(key)
		var item_container = get_node_or_null("ScrollContainer/VBoxContainer/" + node_name)
		if item_container:
			var btn_min = item_container.get_node_or_null("BtnMin")
			var btn_plus = item_container.get_node_or_null("BtnPlus")
			
			if btn_min and not btn_min.pressed.is_connected(_on_btn_min_pressed.bind(key)):
				btn_min.pressed.connect(_on_btn_min_pressed.bind(key))
			if btn_plus and not btn_plus.pressed.is_connected(_on_btn_plus_pressed.bind(key)):
				btn_plus.pressed.connect(_on_btn_plus_pressed.bind(key))

func _get_node_name_by_key(key: String) -> String:
	match key:
		"terigu": return "ItemTerigu"
		"pisang": return "ItemPisang"
		"teh": return "ItemTeh"
		"coklat": return "ItemCoklat"
		"kulit": return "ItemLumpia"
		"es": return "ItemEs"
		_: return ""

func _on_btn_min_pressed(key: String):
	if jumlah_item[key] > 1:
		jumlah_item[key] -= 1
		update_tampilan_toko()

func _on_btn_plus_pressed(key: String):
	if jumlah_item[key] < 99:
		jumlah_item[key] += 1
		update_tampilan_toko()

func is_bahan_unlocked(key: String) -> bool:
	var req_resep = DATA_BARANG[key]["resep"]
	if req_resep == "":
		return true # Terigu selalu bisa dibeli
	return Cerita.punya_flag(req_resep)

func update_tampilan_toko():
	for key in DATA_BARANG.keys():
		var node_name = _get_node_name_by_key(key)
		var item_container = get_node_or_null("ScrollContainer/VBoxContainer/" + node_name)
		if not item_container:
			continue
			
		var label_item = item_container.get_node_or_null("Label")
		var label_jumlah = item_container.get_node_or_null("LabelJumlah")
		var btn_beli = item_container.get_node_or_null("btn_beli_" + key)
		if not btn_beli:
			btn_beli = item_container.get_node_or_null("btn_beli_kulit") if key == "kulit" else null
		var btn_min = item_container.get_node_or_null("BtnMin")
		var btn_plus = item_container.get_node_or_null("BtnPlus")
		
		var unlocked = is_bahan_unlocked(key)
		var info = DATA_BARANG[key]
		var qty = jumlah_item[key]
		var total_harga = info["harga"] * qty
		
		if label_jumlah:
			label_jumlah.text = str(qty)
			
		if unlocked:
			if label_item:
				label_item.text = "%s - Rp%s" % [info["nama"], Global.format_rupiah(info["harga"]).replace("Rp", "")]
			if btn_beli:
				btn_beli.disabled = false
				btn_beli.text = "Beli (%s)" % Global.format_rupiah(total_harga)
			if btn_min: btn_min.disabled = (qty <= 1)
			if btn_plus: btn_plus.disabled = false
		else:
			if label_item:
				label_item.text = "??? (Terkunci)"
			if btn_beli:
				btn_beli.disabled = true
				btn_beli.text = "Terkunci"
			if btn_min: btn_min.disabled = true
			if btn_plus: btn_plus.disabled = true

func _beli_item_by_key(key: String):
	if not is_bahan_unlocked(key):
		_tampilkan_notifikasi("TERKUNCI!", "Kamu belum membuka resep untuk bahan ini!", false)
		return
		
	var info = DATA_BARANG[key]
	var qty = jumlah_item[key]
	var total_harga = info["harga"] * qty
	
	if Global.uang < total_harga:
		var kurang = total_harga - Global.uang
		var pesan = "Uang kamu tidak cukup untuk membeli %d %s!\nTotal: %s\nUang kamu: %s\n(Kurang %s)" % [
			qty,
			info["nama"],
			Global.format_rupiah(total_harga),
			Global.format_rupiah(Global.uang),
			Global.format_rupiah(kurang)
		]
		_tampilkan_notifikasi("UANG TIDAK CUKUP!", pesan, false)
	else:
		if Global.beli_barang(key, info["harga"], qty):
			update_ui_uang()
			update_tampilan_toko()
			var pesan = "Kamu berhasil membeli %d %s seharga %s!\nSisa uang: %s" % [
				qty,
				info["nama"],
				Global.format_rupiah(total_harga),
				Global.format_rupiah(Global.uang)
			]
			_tampilkan_notifikasi("BERHASIL DIBELI!", pesan, true)

func _tampilkan_notifikasi(judul: String, pesan: String, is_sukses: bool):
	_pastikan_popup()
	if popup and popup.has_method("tampilkan"):
		popup.tampilkan(judul, pesan, is_sukses)

func _on_btn_beli_terigu_pressed(): _beli_item_by_key("terigu")
func _on_btn_beli_pisang_pressed(): _beli_item_by_key("pisang")
func _on_btn_beli_teh_pressed(): _beli_item_by_key("teh")
func _on_btn_beli_coklat_pressed(): _beli_item_by_key("coklat")
func _on_btn_beli_kulit_pressed(): _beli_item_by_key("kulit")
func _on_btn_beli_es_pressed(): _beli_item_by_key("es")

func _on_btn_close_pressed():
	if popup and popup.visible and popup.has_method("tutup"):
		popup.tutup()
	hide()
