extends Node2D

# Isi di Inspector (node root rumah.tscn)
@export var gambar_portrait_tv: Texture2D
@export var gambar_portrait_arka: Texture2D
@export var nama_tv: String = "Pembawa Acara"
@export var arah_menghadap_tv: String = "atas"  # arah Arka menghadap TV: atas/bawah/kanan/kiri

@onready var player = $Player

@onready var titik_berhenti_a = $TitikBerhenti_A   # dekat tangga (lantai 1 <-> lantai 2)
@onready var titik_berhenti_b = $TitikBerhenti_B   # dekat pintu keluar

@onready var titik_tujuan_a = $TitikTujuan_A       # tujuan gerak menuju titik A
@onready var titik_tujuan_b = $TitikTujuan_B       # tujuan gerak menuju titik B

# Marker2D untuk cutscene hari 0: posisi Arka duduk/berdiri dekat TV
@onready var titik_cutscene_mulai = $TitikCutsceneMulai


func _ready() -> void:
	if not player:
		return

	if Global.hari == 0 and not Cerita.punya_flag("cutscene_hari_0"):
		await cutscene_hari_0()
	else:
		await spawn_normal()


func spawn_normal() -> void:
	# default aman kalau target_spawn_id gak dikenali / belum di-set
	var aktif_titik_berhenti = titik_berhenti_b
	var aktif_titik_tujuan = titik_tujuan_b

	if TransitionScreen:
		match TransitionScreen.target_spawn_id:
			"keluar":
				# player masuk dari luar rumah -> spawn dekat pintu depan
				aktif_titik_berhenti = titik_berhenti_b
				aktif_titik_tujuan = titik_tujuan_b
			"lantai_2":
				# player turun dari lantai 2 -> spawn dekat tangga
				aktif_titik_berhenti = titik_berhenti_a
				aktif_titik_tujuan = titik_tujuan_a
			_:
				push_warning("target_spawn_id gak dikenali di rumah.gd: '%s'" % TransitionScreen.target_spawn_id)

	if aktif_titik_berhenti and aktif_titik_tujuan:
		player.global_position = aktif_titik_berhenti.global_position
		if player.has_method("atur_arah_menghadap"):
			player.atur_arah_menghadap("bawah")
		if player.has_method("jalan_ke_titik"):
			player.jalan_ke_titik(aktif_titik_tujuan.global_position)
			if player.has_signal("sampai_tujuan"):
				await player.sampai_tujuan
			aktifkan_kontrol_player()


func aktifkan_kontrol_player() -> void:
	if player.has_method("aktifkan_kontrol"):
		player.aktifkan_kontrol()
	elif player.has_method("set_bisa_gerak"):
		player.set_bisa_gerak(true)
	elif "bisa_gerak" in player:
		player.bisa_gerak = true


# ---------------------------------------------------------------
# CUTSCENE HARI 0: Arka nonton TV, lalu objektif pertama muncul
# ---------------------------------------------------------------
func cutscene_hari_0() -> void:
	# Set flag di awal supaya tidak terulang kalau player keluar-masuk scene
	Cerita.set_flag("cutscene_hari_0")

	player.global_position = titik_cutscene_mulai.global_position
	player.set_bisa_gerak(false)
	if player.has_method("atur_arah_menghadap"):
		player.atur_arah_menghadap(arah_menghadap_tv)

	# Tunggu fade-in dari TransitionScreen selesai
	await get_tree().create_timer(1.0).timeout

	# speaker "npc" = acara TV, speaker "player" = Arka
	var tree = DataDialog.ambil_dialog("cutscene_hari_0", 0)
	DialogBox.mulai_dialog(tree, gambar_portrait_tv, gambar_portrait_arka, nama_tv, "Arka")
	await DialogBox.dialog_selesai

	# Objektif pertama
	Cerita.set_objektif("minta_uang_mama")
	aktifkan_kontrol_player()
