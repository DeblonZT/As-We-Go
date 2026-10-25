extends Area2D

@export var arah_masuk: String = "" # Kosongkan untuk otomatis (posisi titik_berhenti rel terhadap player)
@export var scene_tujuan: String = "res://rumah_2.tscn"
@export var id_pintu_keluar: String = "lantai_2" # <-- Isi nama unik di Inspector (misal: "rumah_a", "rumah_b", dll)

# Kunci portal: kalau butuh_flag diisi dan flag itu belum ada di Cerita,
# player tidak bisa lewat dan hanya muncul pesan singkat.
@export var butuh_flag: String = ""
@export_multiline var pesan_terkunci: String = "Sepertinya aku belum boleh ke sana."
@export var gambar_portrait_player: Texture2D  # opsional, untuk pesan terkunci
@export var nama_player: String = "Arka"

@onready var icon_e: Sprite2D = $Sprite2D
@onready var titik_berhenti: Marker2D = $TitikBerhenti

var sedang_transisi = false
var player_di_area = false
var player_ref = null

var start_y: float
var timer: float = 0.0
@export var amplitude: float = 5.0
@export var speed: float = 5.0

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

	if sedang_transisi or DialogBox.sedang_dialog:
		return

	if player_di_area:
		if Input.is_action_just_pressed("interaksi"):
			if portal_terkunci():
				tampilkan_pesan_terkunci()
			else:
				mulai_transisi_masuk()

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
		if icon_e and not sedang_transisi:
			icon_e.visible = false

func portal_terkunci() -> bool:
	if butuh_flag == "":
		return false
	if Cerita.punya_flag(butuh_flag):
		return false
	# Izinkan lewat di mode uji agar tidak menghalangi pengujian
	if Cerita.get("MODE_UJI") == true and OS.is_debug_build():
		return false
	return true

func tampilkan_pesan_terkunci() -> void:
	sedang_transisi = true  # pakai flag yang sama supaya E tidak terpicu berulang
	if icon_e:
		icon_e.visible = false

	var player = player_ref if (player_ref and is_instance_valid(player_ref)) else get_tree().get_first_node_in_group("Player")
	var player_pos_awal = player.global_position if (player and is_instance_valid(player)) else global_position
	if player and is_instance_valid(player) and player.has_method("set_bisa_gerak"):
		player.set_bisa_gerak(false)

	var tree = {"start": [{"speaker": "player", "text": pesan_terkunci}]}
	DialogBox.mulai_dialog(tree, null, gambar_portrait_player, "", nama_player)
	await DialogBox.dialog_selesai

	if player and is_instance_valid(player) and player.has_method("set_bisa_gerak"):
		player.set_bisa_gerak(true)
	sedang_transisi = false
	if player_di_area and icon_e:
		icon_e.visible = true

func mulai_transisi_masuk() -> void:
	sedang_transisi = true
	if icon_e:
		icon_e.visible = false

	var player = player_ref if (player_ref and is_instance_valid(player_ref)) else get_tree().get_first_node_in_group("Player")
	var player_pos_awal = player.global_position if (player and is_instance_valid(player)) else global_position
	if player == null or not is_instance_valid(player):
		sedang_transisi = false
		return

	if titik_berhenti and player.has_method("jalan_ke_titik"):
		player.jalan_ke_titik(titik_berhenti.global_position)
		if player.has_signal("sampai_tujuan"):
			await player.sampai_tujuan

	if is_instance_valid(player) and player.has_method("atur_arah_menghadap"):
		var target_arah = arah_masuk
		if target_arah == "":
			if titik_berhenti:
				var diff = titik_berhenti.global_position - player_pos_awal
				if abs(diff.y) >= abs(diff.x):
					target_arah = "bawah" if diff.y > 0 else "atas"
				else:
					target_arah = "kanan" if diff.x > 0 else "kiri"
			else:
				target_arah = "atas"
		player.atur_arah_menghadap(target_arah)

	if is_instance_valid(player) and player.has_method("mainkan_animasi"):
		player.mainkan_animasi("diam")

	await get_tree().create_timer(0.2).timeout

	# KIRIM ID PINTU SAAT MELAKUKAN TRANSISI
	if TransitionScreen:
		TransitionScreen.transition_to(scene_tujuan, id_pintu_keluar)
	else:
		get_tree().change_scene_to_file(scene_tujuan)
