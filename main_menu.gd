extends Control

const GAME_SCENE_PATH = "res://rumah.tscn"

@onready var new_game_button: Button = $TextureRect/NewGameButton
@onready var continue_button: Button = $TextureRect/ContinueButton
@onready var setting_button: Button = $TextureRect/SettingButton 
@onready var quit_button: Button = $TextureRect/QuitButton

@onready var panel_setting: Panel = $PanelSetting
@onready var slider_volume: HSlider = $PanelSetting/SliderVolume
@onready var tombol_tutup: Button = $PanelSetting/TombolTutup
@onready var toggle_musik: CheckButton = $PanelSetting/ToggleMusik 

var master_bus_index: int
var music_bus_index: int
var popup: Control = null

func _ready() -> void:
	if MainUI:
		MainUI.hide()
	if panel_setting:
		panel_setting.hide()
	
	_pastikan_popup()
	
	master_bus_index = AudioServer.get_bus_index("Master")
	music_bus_index = AudioServer.get_bus_index("Music")
	
	if slider_volume:
		slider_volume.value = db_to_linear(AudioServer.get_bus_volume_db(master_bus_index))
		if not slider_volume.value_changed.is_connected(_on_slider_volume_value_changed):
			slider_volume.value_changed.connect(_on_slider_volume_value_changed)
	
	if toggle_musik:
		toggle_musik.button_pressed = not AudioServer.is_bus_mute(music_bus_index)
		if not toggle_musik.toggled.is_connected(_on_toggle_musik_toggled):
			toggle_musik.toggled.connect(_on_toggle_musik_toggled)
	
	if tombol_tutup:
		if not tombol_tutup.pressed.is_connected(_on_tombol_tutup_pressed):
			tombol_tutup.pressed.connect(_on_tombol_tutup_pressed)
		
	# Hubungkan sinyal tombol secara aman jika belum terhubung
	if new_game_button and not new_game_button.pressed.is_connected(_on_new_game_button_pressed):
		new_game_button.pressed.connect(_on_new_game_button_pressed)
	if continue_button and not continue_button.pressed.is_connected(_on_continue_button_pressed):
		continue_button.pressed.connect(_on_continue_button_pressed)
	if setting_button and not setting_button.pressed.is_connected(_on_setting_button_pressed):
		setting_button.pressed.connect(_on_setting_button_pressed)
	if quit_button and not quit_button.pressed.is_connected(_on_quit_button_pressed):
		quit_button.pressed.connect(_on_quit_button_pressed)
		
	# Visual cue untuk tombol continue jika belum ada save data
	if continue_button:
		if Global.ada_save_data():
			continue_button.modulate = Color(1, 1, 1, 1.0)
		else:
			continue_button.modulate = Color(1, 1, 1, 0.6)

func _pastikan_popup():
	if popup == null:
		popup = get_node_or_null("PopupNotifikasi")
		if popup == null:
			var popup_scene = load("res://popup_notifikasi.tscn")
			if popup_scene:
				popup = popup_scene.instantiate()
				add_child(popup)

func _tampilkan_notifikasi(judul: String, pesan: String, is_sukses: bool = false):
	_pastikan_popup()
	if popup and popup.has_method("tampilkan"):
		popup.tampilkan(judul, pesan, is_sukses)

# --- MEKANIK NEW GAME DENGAN KONFIRMASI ---
func _on_new_game_button_pressed() -> void:
	if Global.ada_save_data():
		_pastikan_popup()
		if popup and popup.has_method("tampilkan_konfirmasi"):
			popup.tampilkan_konfirmasi(
				"ULANG PERMAINAN?", 
				"Apakah kamu yakin ingin memulai game baru?\nProgres game sebelumnya yang tersimpan akan dihapus!", 
				_mulai_game_baru_langsung
			)
		else:
			_mulai_game_baru_langsung()
	else:
		_mulai_game_baru_langsung()

func _mulai_game_baru_langsung() -> void:
	print("Memulai Game Baru...")
	Global.reset_data()
	Global.scene_aktif = GAME_SCENE_PATH
	Global.simpan_game()
	
	if continue_button:
		continue_button.modulate = Color(1, 1, 1, 1.0)
	
	if MainUI:
		MainUI.jam = 6
		MainUI.menit = 0
		MainUI.sesi = "Pagi"
		MainUI.update_ui()
		MainUI.putar_bgm_sesi("Pagi")
		MainUI.show()
	
	if TransitionScreen:
		TransitionScreen.transition_to(GAME_SCENE_PATH)
	else:
		get_tree().change_scene_to_file(GAME_SCENE_PATH)

# Alias untuk kompatibilitas nama fungsi
func _on_new_game_pressed() -> void:
	_on_new_game_button_pressed()

# --- MEKANIK CONTINUE GAME ---
func _on_continue_button_pressed() -> void:
	if Global.ada_save_data():
		print("Melanjutkan game dari file simpanan...")
		if Global.muat_game():
			var target_scene = Global.scene_aktif
			if not ResourceLoader.exists(target_scene):
				target_scene = GAME_SCENE_PATH
				
			if MainUI:
				MainUI.show()
				MainUI.putar_bgm_sesi(MainUI.sesi)
				
			if TransitionScreen:
				TransitionScreen.transition_to(target_scene, Global.spawn_id_aktif)
			else:
				get_tree().change_scene_to_file(target_scene)
		else:
			_tampilkan_notifikasi("GAGAL MEMUAT", "Gagal membaca data simpanan permainan.", false)
	else:
		print("Belum ada data save!")
		_tampilkan_notifikasi("DATA KOSONG", "Belum ada data permainan yang tersimpan.\nSilakan klik 'New Game' untuk memulai petualangan baru!", false)

# --- MEKANIK QUIT & SETTING ---
func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_quit_pressed() -> void:
	_on_quit_button_pressed()

func _on_setting_button_pressed() -> void:
	if panel_setting:
		panel_setting.show()

func _on_tombol_tutup_pressed() -> void:
	if panel_setting:
		panel_setting.hide()

func _on_slider_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(value))
	AudioServer.set_bus_mute(master_bus_index, value == 0.0)

func _on_toggle_musik_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(music_bus_index, not toggled_on)
