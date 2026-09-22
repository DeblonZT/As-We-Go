extends Control

@onready var dim_layer = $DimLayer
@onready var kotak = $KotakPopup
@onready var header = $KotakPopup/Header
@onready var label_judul = $KotakPopup/Header/LabelJudul
@onready var label_pesan = $KotakPopup/LabelPesan
@onready var btn_ok = $KotakPopup/BtnOK
@onready var btn_batal = $KotakPopup/BtnBatal

var tween_anim: Tween
var mode_konfirmasi: bool = false
var callback_ya_func: Callable

# Warna tema
var warna_sukses_header = Color(0.18, 0.62, 0.32, 1.0)
var warna_gagal_header = Color(0.85, 0.22, 0.22, 1.0)
var warna_peringatan_header = Color(0.85, 0.48, 0.16, 1.0)

func _ready():
	hide()
	if btn_ok:
		btn_ok.pressed.connect(_on_btn_ok_pressed)
	if btn_batal:
		btn_batal.pressed.connect(tutup)
	if dim_layer:
		dim_layer.gui_input.connect(_on_dim_layer_gui_input)

func _unhandled_input(event: InputEvent):
	if visible and (event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode in [KEY_SPACE, KEY_ENTER, KEY_E, KEY_ESCAPE])):
		if not mode_konfirmasi:
			tutup()
			get_viewport().set_input_as_handled()

func _on_dim_layer_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not mode_konfirmasi:
			tutup()

func _on_btn_ok_pressed():
	if mode_konfirmasi:
		var cb = callback_ya_func
		tutup()
		if cb.is_valid():
			cb.call()
	else:
		tutup()

func tampilkan(judul: String, pesan: String, is_sukses: bool = true):
	mode_konfirmasi = false
	show()
	
	if label_judul:
		label_judul.text = judul
	if label_pesan:
		label_pesan.text = pesan
	
	if btn_batal:
		btn_batal.hide()
		
	if btn_ok:
		btn_ok.text = "OK"
		btn_ok.offset_left = 105.0
		btn_ok.offset_right = 175.0
		var style_btn = btn_ok.get_theme_stylebox("normal")
		if style_btn is StyleBoxFlat:
			var new_btn_style = style_btn.duplicate()
			new_btn_style.bg_color = warna_sukses_header if is_sukses else warna_gagal_header
			btn_ok.add_theme_stylebox_override("normal", new_btn_style)
			btn_ok.add_theme_stylebox_override("hover", new_btn_style)
		btn_ok.grab_focus()
	
	if header:
		var style_header = header.get_theme_stylebox("panel")
		if style_header is StyleBoxFlat:
			var new_style = style_header.duplicate()
			new_style.bg_color = warna_sukses_header if is_sukses else warna_gagal_header
			header.add_theme_stylebox_override("panel", new_style)

	_animasi_pop_in()

func tampilkan_konfirmasi(judul: String, pesan: String, callback_ya: Callable):
	mode_konfirmasi = true
	callback_ya_func = callback_ya
	show()
	
	if label_judul:
		label_judul.text = judul
	if label_pesan:
		label_pesan.text = pesan
		
	if btn_ok:
		btn_ok.text = "YA, ULANG"
		btn_ok.offset_left = 60.0
		btn_ok.offset_right = 135.0
		var style_btn = btn_ok.get_theme_stylebox("normal")
		if style_btn is StyleBoxFlat:
			var new_btn_style = style_btn.duplicate()
			new_btn_style.bg_color = warna_gagal_header
			btn_ok.add_theme_stylebox_override("normal", new_btn_style)
			btn_ok.add_theme_stylebox_override("hover", new_btn_style)
		btn_ok.grab_focus()
		
	if btn_batal:
		btn_batal.show()
		btn_batal.offset_left = 145.0
		btn_batal.offset_right = 220.0
		var style_batal = btn_batal.get_theme_stylebox("normal")
		if style_batal is StyleBoxFlat:
			var new_batal_style = style_batal.duplicate()
			new_batal_style.bg_color = warna_peringatan_header
			btn_batal.add_theme_stylebox_override("normal", new_batal_style)
			btn_batal.add_theme_stylebox_override("hover", new_batal_style)

	if header:
		var style_header = header.get_theme_stylebox("panel")
		if style_header is StyleBoxFlat:
			var new_style = style_header.duplicate()
			new_style.bg_color = warna_peringatan_header
			header.add_theme_stylebox_override("panel", new_style)

	_animasi_pop_in()

func _animasi_pop_in():
	if kotak:
		kotak.pivot_offset = kotak.size / 2.0
		kotak.scale = Vector2(0.7, 0.7)
		kotak.modulate.a = 0.0
		
		if tween_anim and tween_anim.is_running():
			tween_anim.kill()
		tween_anim = create_tween().set_parallel(true)
		tween_anim.tween_property(kotak, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween_anim.tween_property(kotak, "modulate:a", 1.0, 0.15)

func tutup():
	if not visible:
		return
		
	if tween_anim and tween_anim.is_running():
		tween_anim.kill()
		
	tween_anim = create_tween().set_parallel(true)
	tween_anim.tween_property(kotak, "scale", Vector2(0.8, 0.8), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween_anim.tween_property(kotak, "modulate:a", 0.0, 0.12)
	tween_anim.chain().tween_callback(hide)
