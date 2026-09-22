extends Area2D
# Kasur: tekan E untuk tidur -> layar hitam + judul "Hari X" -> pindah hari.
# Struktur node: Area2D (script ini) -> CollisionShape2D + Sprite2D (ikon E, seperti di portal)

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

@onready var icon_e: Sprite2D = $Sprite2D

var sedang_tidur = false
var player_di_area = false
var player_ref = null

var start_y: float
var timer: float = 0.0


func _ready() -> void:
	if icon_e:
		icon_e.visible = false
		start_y = icon_e.position.y

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	if icon_e and icon_e.visible:
		timer += delta * speed
		icon_e.position.y = start_y + sin(timer) * amplitude

	if sedang_tidur:
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
	return butuh_flag != "" and not Cerita.punya_flag(butuh_flag)


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
	atur_gerak_player(player, false)

	var hari_baru: int = Global.hari + 1

	# Layar hitam + judul hari, dibuat lewat kode (tanpa scene tambahan)
	var lapisan := CanvasLayer.new()
	lapisan.layer = 128
	get_tree().root.add_child(lapisan)

	var hitam := ColorRect.new()
	hitam.color = Color.BLACK
	hitam.mouse_filter = Control.MOUSE_FILTER_IGNORE  # jangan sampai menyerap klik
	hitam.modulate.a = 0.0
	lapisan.add_child(hitam)
	hitam.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var judul := Label.new()
	judul.text = "Hari %d" % hari_baru
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	judul.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	judul.mouse_filter = Control.MOUSE_FILTER_IGNORE
	judul.add_theme_font_size_override("font_size", 24)
	hitam.add_child(judul)
	judul.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Gelap
	var tween_gelap := create_tween()
	tween_gelap.tween_property(hitam, "modulate:a", 1.0, durasi_fade)
	await tween_gelap.finished

	# Layar sudah hitam: ganti hari, reset jam, atur objektif
	Global.hari = hari_baru
	atur_hud_pagi()
	Cerita.saat_hari_baru(hari_baru)

	await get_tree().create_timer(durasi_tahan).timeout

	# Terang lagi
	var tween_terang := create_tween()
	tween_terang.tween_property(hitam, "modulate:a", 0.0, durasi_fade)
	await tween_terang.finished

	lapisan.queue_free()
	atur_gerak_player(player, true)
	sedang_tidur = false
	if player_di_area and icon_e:
		icon_e.visible = true


func atur_hud_pagi() -> void:
	var hud = Cerita.cari_hud()
	if hud == null:
		return
	hud.jam = jam_bangun
	hud.menit = menit_bangun
	if hud.has_method("cek_sesi"):
		hud.cek_sesi()
	if hud.has_method("update_ui"):
		hud.update_ui()
	hud.show()
