extends Node2D

@onready var player = $Player

@onready var titik_berhenti_a = $TitikBerhenti_A   # dekat tangga (lantai 1 <-> lantai 2)
@onready var titik_berhenti_b = $TitikBerhenti_B   # dekat pintu keluar

@onready var titik_tujuan_a = $TitikTujuan_A       # tujuan gerak menuju titik A
@onready var titik_tujuan_b = $TitikTujuan_B       # tujuan gerak menuju titik B


func _ready() -> void:
	if not player:
		return

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
			if player.has_method("aktifkan_kontrol"):
				player.aktifkan_kontrol()
			elif "bisa_gerak" in player:
				player.bisa_gerak = true
