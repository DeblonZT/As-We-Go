extends CharacterBody2D

@export var gambar_portrait_npc: Texture2D
@export var gambar_portrait_player: Texture2D
@export var nama_npc: String = "Mpok Wati"
@export var nama_player: String = "Arka"

@onready var icon_e = $AreaBicara/IconE
@onready var area_bicara = $AreaBicara
@onready var animasi = $AnimatedSprite2D
@onready var panel_toko = $"../LayerToko/PanelToko" 

var player_di_area = false
var sedang_dialog = false
var player_ref = null

# --- DIALOG SINGKAT SEBELUM BUKA TOKO ---
var dialog_singkat = {
	"start": [
		{"speaker": "npc", "text": "Eh Arka! Nyari bahan eceran buat jualan ya?"},
		{"speaker": "player", "text": "Iya nih Mpok, stok ada yang mau habis."},
		{"speaker": "npc", "text": "Ini daftar barang di warung Mpok, silakan pilih!"}
	]
}

func _ready():
	if icon_e: icon_e.visible = false
	area_bicara.body_entered.connect(_on_body_entered)
	area_bicara.body_exited.connect(_on_body_exited)
	
	if panel_toko:
		panel_toko.hidden.connect(_on_toko_ditutup)

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
		
		if panel_toko and panel_toko.visible:
			panel_toko.hide()

func _process(_delta):
	if player_di_area and not sedang_dialog:
		if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_E):
			buka_toko()

func hadap_ke_player():
	if player_ref == null or animasi == null: return
	var selisih_x = player_ref.global_position.x - global_position.x
	if selisih_x > 0:
		animasi.flip_h = false
		animasi.play("diam_kanan")
	else:
		animasi.flip_h = true
		animasi.play("diam_kanan")

func buka_toko():
	sedang_dialog = true
	if icon_e: icon_e.visible = false
	hadap_ke_player()

	if player_ref:
		if player_ref.has_method("set_bisa_gerak"):
			player_ref.set_bisa_gerak(false)
		elif "bisa_gerak" in player_ref:
			player_ref.bisa_gerak = false

	print("1. Dialog Mpok Wati dimulai...")
	DialogBox.mulai_dialog(dialog_singkat, gambar_portrait_npc, gambar_portrait_player, nama_npc, nama_player)
	
	# Menunggu sinyal dialog_selesai dari DialogBox
	await DialogBox.dialog_selesai
	print("2. Dialog sudah selesai ditekan!")

	# Mengecek apakah panel toko berhasil ditemukan
	if panel_toko:
		print("3. Panel toko ditemukan, memunculkan UI...")
		panel_toko.show()
	else:
		print("ERROR: Panel Toko tidak ditemukan (NULL)! Cek jalur node-nya.")
		_on_toko_ditutup()

func _on_toko_ditutup():
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
