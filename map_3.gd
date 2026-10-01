extends Node2D

@onready var player = $Player

# Titik Spawn & Tujuan yang ada di map_3.tscn
@onready var titik_portal_a3 = $TitikBerhenti_A3
@onready var tujuan_portal_a3 = $TitikTujuan_A3

@onready var titik_portal_b3 = $TitikBerhenti_B3
@onready var tujuan_portal_b3 = $TitikTujuan_B3

@onready var titik_portal_c3 = $TitikBerhenti_C3
@onready var tujuan_portal_c3 = $TitikTujuan_C3

@onready var warung_house = $HouseInteract2

func _ready() -> void:
	print("=== MASUK MAP_3, target_spawn_id = '", TransitionScreen.target_spawn_id, "' ===")

	if not player:
		return

	var pos_awal = Vector2(52, 121)
	var pos_tujuan = Vector2(52, 121)
	var arah_awal = "kanan"

	# Default ke Portal A3 jika spawn_id kosong
	if titik_portal_a3:
		pos_awal = titik_portal_a3.global_position
		pos_tujuan = tujuan_portal_a3.global_position if tujuan_portal_a3 else pos_awal

	if TransitionScreen:
		match TransitionScreen.target_spawn_id:
			"portal_a3", "map3", "map2_atas", "map2":
				# Datang dari Map 2 (jalur atas)
				if titik_portal_a3:
					pos_awal = titik_portal_a3.global_position
				if tujuan_portal_a3:
					pos_tujuan = tujuan_portal_a3.global_position
				arah_awal = "kanan"

			"portal_b3", "map33", "map2_bawah", "map22":
				# Datang dari Map 2 (jalur bawah)
				if titik_portal_b3:
					pos_awal = titik_portal_b3.global_position
				if tujuan_portal_b3:
					pos_tujuan = tujuan_portal_b3.global_position
				arah_awal = "kanan"

			"portal_c3", "map5", "map5_ke_map3":
				# Datang dari Map 5
				if titik_portal_c3:
					pos_awal = titik_portal_c3.global_position
				if tujuan_portal_c3:
					pos_tujuan = tujuan_portal_c3.global_position
				arah_awal = "atas"

			"warungPI", "warung_pi", "warung_pak_iwan":
				# Keluar dari Warung Pak Iwan di Map 3
				if warung_house:
					pos_awal = warung_house.global_position
					pos_tujuan = pos_awal + Vector2(0, 25)
				arah_awal = "bawah"

	player.global_position = pos_awal
	if player.has_method("atur_arah_menghadap"):
		player.atur_arah_menghadap(arah_awal)
	if player.has_method("jalan_ke_titik") and pos_tujuan != pos_awal:
		player.jalan_ke_titik(pos_tujuan)
		if player.has_signal("sampai_tujuan"):
			await player.sampai_tujuan

	if player.has_method("aktifkan_kontrol"):
		player.aktifkan_kontrol() 
	elif player.has_method("set_bisa_gerak"):
		player.set_bisa_gerak(true)
	elif "bisa_gerak" in player:
		player.bisa_gerak = true
