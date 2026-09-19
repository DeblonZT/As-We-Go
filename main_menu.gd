extends Control

const GAME_SCENE_PATH = "res://kamar.tscn"

@onready var new_game_button: Button = $TextureRect/NewGameButton
@onready var quit_button: Button = $TextureRect/QuitButton
@onready var setting_button: Button = $TextureRect/SettingButton 

@onready var panel_setting: Panel = $PanelSetting
@onready var slider_volume: HSlider = $PanelSetting/SliderVolume
@onready var tombol_tutup: Button = $PanelSetting/TombolTutup

# Node baru untuk tombol ON/OFF
@onready var toggle_musik: CheckButton = $PanelSetting/ToggleMusik 

var master_bus_index: int
var music_bus_index: int # Variabel untuk menyimpan jalur musik

func _ready() -> void:
	MainUI.hide()
	panel_setting.hide()
	
	master_bus_index = AudioServer.get_bus_index("Master")
	music_bus_index = AudioServer.get_bus_index("Music") # Mengambil ID bus Music
	
	slider_volume.value = db_to_linear(AudioServer.get_bus_volume_db(master_bus_index))
	
	# Menyesuaikan posisi tombol (ON/OFF) dengan status mute saat ini
	toggle_musik.button_pressed = not AudioServer.is_bus_mute(music_bus_index)
	
	if not new_game_button.pressed.is_connected(_on_new_game_pressed):
		new_game_button.pressed.connect(_on_new_game_pressed)
	if not quit_button.pressed.is_connected(_on_quit_pressed):
		quit_button.pressed.connect(_on_quit_pressed)
	if not setting_button.pressed.is_connected(_on_setting_button_pressed):
		setting_button.pressed.connect(_on_setting_button_pressed)
	
	tombol_tutup.pressed.connect(_on_tombol_tutup_pressed)
	slider_volume.value_changed.connect(_on_slider_volume_value_changed)
	
	# Menghubungkan sinyal klik dari CheckButton
	toggle_musik.toggled.connect(_on_toggle_musik_toggled)


func _on_new_game_pressed() -> void:
	Global.uang = 20000
	Global.hari = 1
	Global.bahan_cilok = 0
	Global.cilok_matang = 0
	Global.reputasi_pelanggan = 50
	
	MainUI.jam = 6
	MainUI.menit = 0
	MainUI.cek_sesi()
	MainUI.update_ui()
	
	MainUI.show()
	get_tree().change_scene_to_file(GAME_SCENE_PATH)


func _on_quit_pressed() -> void:
	get_tree().quit()


# --- FUNGSI UNTUK MENU SETTING ---

func _on_setting_button_pressed() -> void:
	panel_setting.show()

func _on_tombol_tutup_pressed() -> void:
	panel_setting.hide()

func _on_slider_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(value))
	AudioServer.set_bus_mute(master_bus_index, value == 0.0)

func _on_toggle_musik_toggled(toggled_on: bool) -> void:
	# Jika tombol dimatikan (false), maka fitur mute dinyalakan (true) pada bus Music
	AudioServer.set_bus_mute(music_bus_index, not toggled_on)


# Fungsi sisa
func _on_continue_button_pressed() -> void:
	print("Fitur Continue belum dibuat")
