extends CharacterBody2D

@export var gambar_portrait_npc: Texture2D
@export var gambar_portrait_player: Texture2D
@export var nama_npc: String = "Mang Cecep"
@export var nama_player: String = "Arka"

@onready var icon_e = $AreaBicara/IconE
@onready var area_bicara = $AreaBicara
@onready var animasi = $AnimatedSprite2D
@onready var panel_upgrade = $"../CanvasUI/LayerTokoMangCecep/PanelUpgrade"

var player_di_area = false
var sedang_dialog = false
var player_ref = null

# --- DIALOG SINGKAT SEBELUM BUKA TOKO UPGRADE ---
var dialog_singkat = {
	"start": [
		{"speaker": "npc", "text": "Halo Arka! Mau upgrade perlengkapan booth kamu?"},
		{"speaker": "player", "text": "Iya nih Mang, biar proses masak dan jualan lebih cepat."},
		{"speaker": "npc", "text": "Sip! Ini daftar upgrade yang tersedia, silakan dicek!"}
	]
}

func _ready():
	if icon_e: icon_e.visible = false
	area_bicara.body_entered.connect(_on_body_entered)
	area_bicara.body_exited.connect(_on_body_exited)
	
	if panel_upgrade:
		panel_upgrade.hidden.connect(_on_upgrade_ditutup)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		player_di_area = true
		player_ref = body
		if icon_e and not sedang_dialog: icon_e.visible = true

func _on_body_exited(body):
	if body.is_in_group("Player"):
		player_di_area = false
		player_ref = null
		if icon_e: icon_e.visible = false
		
		if panel_upgrade and panel_upgrade.visible:
			panel_upgrade.hide()

func _process(_delta):
	if player_di_area and not sedang_dialog:
		if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_E):
			buka_upgrade()

func hadap_ke_player():
	if player_ref == null or animasi == null: return
	var selisih_x = player_ref.global_position.x - global_position.x
	if selisih_x > 0:
		animasi.flip_h = false
		animasi.play("diam_kanan")
	else:
		animasi.flip_h = true
		animasi.play("diam_kanan")

func buka_upgrade():
	sedang_dialog = true
	if icon_e: icon_e.visible = false
	hadap_ke_player()

	if player_ref:
		if player_ref.has_method("set_bisa_gerak"):
			player_ref.set_bisa_gerak(false)
		elif "bisa_gerak" in player_ref:
			player_ref.bisa_gerak = false

	var tree_cerita: Dictionary = Cerita.dialog_tahap_untuk("mang_cecep")
	if not tree_cerita.is_empty():
		DialogBox.mulai_dialog(tree_cerita, gambar_portrait_npc, gambar_portrait_player, nama_npc, nama_player)
		await DialogBox.dialog_selesai
		_on_upgrade_ditutup()  # kunjungan cerita, bukan belanja upgrade — panel tidak dibuka
		return

	if DialogBox:
		DialogBox.mulai_dialog(dialog_singkat, gambar_portrait_npc, gambar_portrait_player, nama_npc, nama_player)
		await DialogBox.dialog_selesai

	if panel_upgrade:
		panel_upgrade.show()
	else:
		_on_upgrade_ditutup()

func _on_upgrade_ditutup():
	if player_ref:
		if player_ref.has_method("set_bisa_gerak"):
			player_ref.set_bisa_gerak(true)
		elif "bisa_gerak" in player_ref:
			player_ref.bisa_gerak = true

	kembalikan_idle()
	sedang_dialog = false
	if player_di_area and icon_e: icon_e.visible = true

func kembalikan_idle():
	if animasi == null: return
	animasi.flip_h = false
	animasi.play("idle")
