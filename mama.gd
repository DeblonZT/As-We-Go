extends CharacterBody2D

@export var gambar_portrait_npc: Texture2D
@export var gambar_portrait_player: Texture2D
@export var nama_npc: String = "Mama Arka"
@export var nama_player: String = "Arka"

@onready var icon_e = $AreaBicara/IconE
@onready var area_bicara = $AreaBicara
@onready var animasi = $AnimatedSprite2D

var player_di_area = false
var sedang_dialog = false
var player_ref = null

var dialog_tree = {
	"start": [
		{"speaker": "player", "text": "Gak papa kok, cuma capek aja"},
		{"speaker": "npc", "text": "Ada apa arka?, kamu sepertinya terlihat murung"},
		{"speaker": "player", "text": "Gak papa kok, cuma capek aja"},
		{"speaker": "npc", "text": "Mau Mama buatkan teh hangat?", "choices": [
			{"text": "Boleh banget mah, makasih!", "next": "terima_teh"},
			{"text": "Nggak usah deh mah, aku mau istirahat aja", "next": "tolak_teh"}
		]}
	],
	"terima_teh": [
		{"speaker": "npc", "text": "Oke, tunggu sebentar ya!"},
		{"speaker": "player", "text": "Makasih mah!"}
	],
	"tolak_teh": [
		{"speaker": "npc", "text": "Oke, istirahat yang cukup ya sayangq"}
	]
}

func _ready():
	if icon_e: icon_e.visible = false
	area_bicara.body_entered.connect(_on_body_entered)
	area_bicara.body_exited.connect(_on_body_exited)

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

func _process(_delta):
	if player_di_area and not sedang_dialog:
		if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_E):
			mulai_bicara()

func hadap_ke_player():
	if player_ref == null or animasi == null:
		return
	var selisih_x = player_ref.global_position.x - global_position.x
	if selisih_x > 0:
		animasi.flip_h = false
		animasi.play("diam_kanan")
	else:
		animasi.flip_h = true
		animasi.play("diam_kanan")

func mulai_bicara():
	sedang_dialog = true
	if icon_e: icon_e.visible = false

	hadap_ke_player()

	if player_ref:
		if player_ref.has_method("set_bisa_gerak"):
			player_ref.set_bisa_gerak(false)
		elif "bisa_gerak" in player_ref:
			player_ref.bisa_gerak = false

	DialogBox.mulai_dialog(dialog_tree, gambar_portrait_npc, gambar_portrait_player, nama_npc, nama_player)
	await DialogBox.dialog_selesai

	if player_ref:
		if player_ref.has_method("set_bisa_gerak"):
			player_ref.set_bisa_gerak(true)
		elif "bisa_gerak" in player_ref:
			player_ref.bisa_gerak = true

	kembalikan_idle()

	sedang_dialog = false
	if player_di_area and icon_e: icon_e.visible = true

func kembalikan_idle():
	if animasi == null:
		return
	animasi.flip_h = false
	animasi.play("idle")
