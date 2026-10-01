extends CharacterBody2D

# Isi id_npc di Inspector per instance ("mama", "pandu", dst).
# Harus sama persis dengan key di DataDialog.DIALOG_NPC.
@export var id_npc: String = "mama"
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


func _ready():
	if icon_e: icon_e.visible = false
	area_bicara.body_entered.connect(_on_body_entered)
	area_bicara.body_exited.connect(_on_body_exited)


func _on_body_entered(body):
	if body.is_in_group("Player"):
		player_di_area = true
		player_ref = body


func _on_body_exited(body):
	if body.is_in_group("Player"):
		player_di_area = false
		player_ref = null


func _process(_delta):
	# Icon E hanya tampil kalau player di area, tidak sedang dialog,
	# dan player sedang bebas (bukan lagi cutscene / dialog lain)
	var bisa_bicara = player_di_area and not sedang_dialog and player_sedang_bebas()
	if icon_e: icon_e.visible = bisa_bicara

	if bisa_bicara:
		if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_E):
			mulai_bicara()


func player_sedang_bebas() -> bool:
	if player_ref == null:
		return false
	if "bisa_gerak" in player_ref:
		return player_ref.bisa_gerak
	return true


func atur_gerak_player(player, nilai: bool):
	if player == null:
		return
	if player.has_method("set_bisa_gerak"):
		player.set_bisa_gerak(nilai)
	elif "bisa_gerak" in player:
		player.bisa_gerak = nilai


# Bisa dipanggil dari script lain (misal cutscene di rumah.gd)
func hadap_ke_posisi(posisi: Vector2):
	if animasi == null:
		return
	animasi.flip_h = posisi.x <= global_position.x
	animasi.play("diam_kanan")


func hadap_ke_player():
	if player_ref == null:
		return
	hadap_ke_posisi(player_ref.global_position)


func kembalikan_idle():
	if animasi == null:
		return
	animasi.flip_h = false
	animasi.play("idle")


func mulai_bicara():
	var hari = Global.hari
	var kunci = "%s_hari_%d" % [id_npc, hari]
	var tree = DataDialog.ambil_dialog(id_npc, hari, Cerita.punya_flag(kunci))

	if tree.is_empty():
		push_warning("Dialog kosong untuk NPC '%s' di hari %d, cek DataDialog" % [id_npc, hari])
		return

	sedang_dialog = true
	var player = player_ref  # simpan lokal, jaga-jaga player_ref jadi null di tengah dialog

	hadap_ke_player()
	atur_gerak_player(player, false)

	DialogBox.mulai_dialog(tree, gambar_portrait_npc, gambar_portrait_player, nama_npc, nama_player)
	await DialogBox.dialog_selesai

	Cerita.set_flag(kunci)

	# Ending gagal dipicu lewat "aksi" di dialog (misal Arka menolak tawaran Pandu)
	if Cerita.punya_flag("ending_gagal"):
		Cerita.mulai_ending_gagal()

	atur_gerak_player(player, true)
	kembalikan_idle()
	sedang_dialog = false
