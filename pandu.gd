extends CharacterBody2D

@export var gambar_portrait_npc: Texture2D
@export var gambar_portrait_player: Texture2D
@export var nama_npc: String = "Bang Pandu"
@export var nama_player: String = "Arka"

@onready var icon_e = $AreaBicara/IconE
@onready var area_bicara = $AreaBicara
@onready var animasi = $AnimatedSprite2D

var player_di_area = false
var sedang_dialog = false
var player_ref = null

var dialog_tree = {
"start": [
		{"speaker": "player", "text": "Bang Pandu, aku boleh minta tolong ngga?"},
		{"speaker": "npc", "text": "Kamu minta Tolong apa Arka?"},
		{"speaker": "player", "text": "Aku butuh uang untuk membeli barang yang kuinginkan"},
		{"speaker": "player", "text": "Tapi uang ku tidak cukup untuk membelinya"},
		{"speaker": "player", "text": "Abang bisa kasih aku uang ngga?"},
		{"speaker": "npc", "text": "Waduhh, Abang aja belum gajian dek bulan ini hehe"},
		{"speaker": "npc", "text": "Tapi kalo kamu mau uang Abang tau cara lain selain meminta"},
		{"speaker": "player", "text": "Apa tuh bang caranya?"},
		{"speaker": "npc", "text": "Beneran Kamu mau tau caranya?", "choices": [
			{"text": "Mau lah bang", "next": "terima"},
			{"text": "Nggak usah deh bang keburu males", "next": "tolak"}
		]}
	],
	"terima": [
		{"speaker": "npc", "text": "Mau tau banget nihh?"},
		{"speaker": "player", "text": "Mau lah bang ishh ayolah bang kasih tau dong!"},
		{"speaker": "npc", "text": "Hahahaha, oke oke, caranya adalah BERJUALAN"},
	],
	"tolak": [
		{"speaker": "player", "text": "Ngga usah deh bang udah keburu males ini pasti mau ngejoks garing"},
		{"speaker": "npc", "text": "Yaudah kalo ngga mau"},
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
