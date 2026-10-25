extends CharacterBody2D

@export var id_npc: String = "pak_iwan"
@export var gambar_portrait_npc: Texture2D
@export var gambar_portrait_player: Texture2D
@export var nama_npc: String = "Pak Iwan"
@export var nama_player: String = "Arka"

@onready var icon_e = $AreaBicara/IconE
@onready var area_bicara = $AreaBicara
@onready var animasi = $AnimatedSprite2D

var player_di_area = false
var sedang_dialog = false
var player_ref = null
var _jalan_aktif: bool = false
var _auto_walk_layer: int = 1
var _auto_walk_mask: int = 1

signal sampai_tujuan


func _exit_tree() -> void:
	if _jalan_aktif:
		collision_layer = _auto_walk_layer
		collision_mask = _auto_walk_mask
		_jalan_aktif = false
		sampai_tujuan.emit()


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
	var bisa_bicara = player_di_area and not sedang_dialog and not DialogBox.sedang_dialog and player_sedang_bebas()
	if icon_e: icon_e.visible = bisa_bicara
	if bisa_bicara:
			if Input.is_action_just_pressed("interaksi"):
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


func hadap_ke_posisi(posisi: Vector2):
	if animasi == null: return
	animasi.flip_h = posisi.x <= global_position.x
	animasi.play("diam_kanan")


func hadap_ke_player():
	if player_ref == null: return
	hadap_ke_posisi(player_ref.global_position)


func kembalikan_idle():
	if animasi == null: return
	animasi.flip_h = false
	animasi.play("idle")

func jalan_ke_titik(pos: Vector2) -> void:
	_jalan_aktif = true
	_auto_walk_layer = collision_layer
	_auto_walk_mask = collision_mask
	collision_layer = 0
	collision_mask = 0
	var waktu_mulai := Time.get_ticks_msec()
	var waktu_cek := waktu_mulai
	var posisi_cek := global_position
	var waktu_tersangkut: float = 0.0
	while is_inside_tree() and global_position.distance_to(pos) > 4.0:
		var arah := (pos - global_position).normalized()
		velocity = arah * 70.0
		move_and_slide()
		if animasi:
			animasi.flip_h = arah.x < 0
			animasi.play("jalan_kanan" if abs(arah.x) >= abs(arah.y) else ("jalan_bawah" if arah.y > 0 else "jalan_atas"))
		await get_tree().physics_frame
		if not is_inside_tree():
			return
		var sekarang := Time.get_ticks_msec()
		var durasi_cek := float(sekarang - waktu_cek) / 1000.0
		if durasi_cek >= 0.5:
			if global_position.distance_to(posisi_cek) < 2.0:
				waktu_tersangkut += durasi_cek
			else:
				waktu_tersangkut = 0.0
			posisi_cek = global_position
			waktu_cek = sekarang
		if waktu_tersangkut >= 0.5 or sekarang - waktu_mulai >= 6000:
			push_warning("Pak Iwan tersangkut/timeout saat auto-walk; dipindahkan ke marker tujuan.")
			global_position = pos
			break
	_jalan_aktif = false
	velocity = Vector2.ZERO
	collision_layer = _auto_walk_layer
	collision_mask = _auto_walk_mask
	kembalikan_idle()
	sampai_tujuan.emit()


func mulai_bicara():
	var hari = Global.hari
	var kunci = "%s_hari_%d" % [id_npc, hari]
	var tree = Cerita.pilih_dialog(id_npc, hari, Cerita.punya_flag(kunci))

	if tree.is_empty():
		push_warning("Dialog kosong untuk NPC '%s' di hari %d" % [id_npc, hari])
		return

	sedang_dialog = true
	var player = player_ref
	hadap_ke_player()
	atur_gerak_player(player, false)

	DialogBox.mulai_dialog(tree, gambar_portrait_npc, gambar_portrait_player, nama_npc, nama_player)
	await DialogBox.dialog_selesai

	Cerita.set_flag(kunci)
	atur_gerak_player(player, true)
	kembalikan_idle()
	sedang_dialog = false
