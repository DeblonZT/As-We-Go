extends Area2D
# Kasur: tekan E untuk tidur. Transisi hari ditangani Cerita.ganti_hari().
# Struktur node: Area2D (script ini) -> CollisionShape2D + Sprite2D (ikon E)

@export var butuh_flag: String = ""
@export_multiline var pesan_terkunci: String = "Belum ngantuk, masih ada yang harus kulakukan."
@export var gambar_portrait_player: Texture2D  # opsional, untuk pesan terkunci
@export var nama_player: String = "Arka"
@export var jam_bangun: int = 6
@export var menit_bangun: int = 0
@export var durasi_fade: float = 0.8
@export var durasi_tahan: float = 1.0  # lama layar hitam ditahan (judul hari terbaca)
@export var amplitude: float = 5.0
@export var speed: float = 5.0
@export var offset_bangun: Vector2 = Vector2(0, 20)  # geser dari titik Area2D kasur, atur di Inspector




@onready var icon_e: Sprite2D = $Sprite2D

var sedang_tidur = false
var player_di_area = false
var player_ref = null

var start_y: float
var timer: float = 0.0


func _ready() -> void:
	add_to_group("kasur")
	if icon_e:
		icon_e.visible = false
		start_y = icon_e.position.y

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	if icon_e and icon_e.visible:
		timer += delta * speed
		icon_e.position.y = start_y + sin(timer) * amplitude

	if sedang_tidur or Cerita.sedang_ganti_hari:
		return

	if player_di_area:
		if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_E):
			if kasur_terkunci():
				tampilkan_pesan_terkunci()
			else:
				tidur()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_di_area = true
		player_ref = body
		if icon_e:
			icon_e.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_di_area = false
		player_ref = null
		if icon_e and not sedang_tidur:
			icon_e.visible = false


func kasur_terkunci() -> bool:
	if butuh_flag != "" and not Cerita.punya_flag(butuh_flag):
		return true
	# Aturan bawaan: hari 0 tidak bisa tidur sebelum Pandu setuju (tidak tergantung isi Inspector)
	return not Cerita.boleh_tidur()


func atur_gerak_player(player, nilai: bool) -> void:
	if player and player.has_method("set_bisa_gerak"):
		player.set_bisa_gerak(nilai)


func tampilkan_pesan_terkunci() -> void:
	sedang_tidur = true  # pakai flag yang sama supaya E tidak terpicu berulang
	if icon_e:
		icon_e.visible = false

	var player = player_ref
	atur_gerak_player(player, false)

	var tree = {"start": [{"speaker": "player", "text": pesan_terkunci}]}
	DialogBox.mulai_dialog(tree, null, gambar_portrait_player, "", nama_player)
	await DialogBox.dialog_selesai

	atur_gerak_player(player, true)
	sedang_tidur = false
	if player_di_area and icon_e:
		icon_e.visible = true


func tidur() -> void:
	sedang_tidur = true
	if icon_e:
		icon_e.visible = false

	var player = player_ref
	await Cerita.ganti_hari(false, durasi_fade, durasi_tahan, jam_bangun, menit_bangun)

	atur_gerak_player(player, true)
	sedang_tidur = false
	if player_di_area and icon_e:
		icon_e.visible = true
