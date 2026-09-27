extends Node2D

@onready var player = $Player

# Titik Spawn & Tujuan di map_5.tscn
@onready var titik_portal_a = $TitikBerhenti_A
@onready var tujuan_portal_a = $TitikTujuan_A

@onready var titik_portal_b = $TitikBerhenti_B
@onready var tujuan_portal_b = $TitikTujuan_B

@onready var warung_house = $HouseInteract2

func _ready() -> void:
	print("=== MASUK MAP_5, target_spawn_id = '", TransitionScreen.target_spawn_id, "' ===")

	if not player:
		return

	var pos_awal = Vector2.ZERO
	var pos_tujuan = Vector2.ZERO
	var arah_awal = "bawah"

	# Default ke jalur B (datang dari map_3) kalau spawn_id kosong/tidak dikenali
	if titik_portal_b:
		pos_awal = titik_portal_b.global_position
		pos_tujuan = tujuan_portal_b.global_position if tujuan_portal_b else pos_awal
		arah_awal = "bawah"

	if TransitionScreen:
		match TransitionScreen.target_spawn_id:
			"map4c_ke_map5", "map4_ke_map5", "portal_a5", "dari_map4":
				# Datang dari Map 4 (masuk dari sebelah kiri/barat)
				if titik_portal_a:
					pos_awal = titik_portal_a.global_position
				if tujuan_portal_a:
					pos_tujuan = tujuan_portal_a.global_position
				else:
					pos_tujuan = pos_awal + Vector2(35, 0)
				arah_awal = "kanan"

			"map5", "portal_c3", "map3_ke_map5", "dari_map3", "portal_b5":
				# Datang dari Map 3 (masuk dari atas/utara)
				if titik_portal_b:
					pos_awal = titik_portal_b.global_position
				if tujuan_portal_b:
					pos_tujuan = tujuan_portal_b.global_position
				else:
					pos_tujuan = pos_awal + Vector2(0, 35)
				arah_awal = "bawah"

			"warung_mw", "warung", "warungMW":
				# Keluar dari Warung Mpok Wati di Map 5
				if warung_house:
					pos_awal = warung_house.global_position
					pos_tujuan = pos_awal + Vector2(0, 25)
				arah_awal = "bawah"

			_:
				print("target_spawn_id '%s' memakai default di map_5" % TransitionScreen.target_spawn_id)

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
