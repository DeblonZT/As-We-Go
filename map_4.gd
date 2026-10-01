extends Node2D

@onready var player = $Player

# Titik Spawn & Tujuan di map_4.tscn
@onready var titik_dari_map2a = $TitikBerhenti_DariMap2A
@onready var tujuan_dari_map2a = $TitikTujuan_DariMap2A

@onready var titik_dari_map2b = $TitikBerhenti_DariMap2B
@onready var tujuan_dari_map2b = $TitikTujuan_DariMap2B

@onready var titik_dari_map5 = $TitikBerhenti_DariMap5
@onready var tujuan_dari_map5 = $TitikTujuan_DariMap5


func _ready() -> void:
	print("=== MASUK MAP_4, target_spawn_id = '", TransitionScreen.target_spawn_id, "' ===")

	if not player:
		return

	var pos_awal = Vector2.ZERO
	var pos_tujuan = Vector2.ZERO
	var arah_awal = "diam"

	# Default ke jalur A dari map_2 kalau spawn_id kosong/tidak dikenali
	if titik_dari_map2a:
		pos_awal = titik_dari_map2a.global_position
		pos_tujuan = tujuan_dari_map2a.global_position if tujuan_dari_map2a else pos_awal

	if TransitionScreen:
		match TransitionScreen.target_spawn_id:
			"map2a_ke_map4", "portal_c", "map4", "map4_kiri", "dari_map2a":
				# Datang dari Map 2, jalur A (kiri)
				if titik_dari_map2a:
					pos_awal = titik_dari_map2a.global_position
				if tujuan_dari_map2a and tujuan_dari_map2a.global_position.distance_to(pos_awal) > 5:
					pos_tujuan = tujuan_dari_map2a.global_position
				else:
					pos_tujuan = pos_awal + Vector2(0, 35)
				arah_awal = "bawah"

			"map2b_ke_map4", "portal_c2", "map44", "map4_kanan", "dari_map2b":
				# Datang dari Map 2, jalur B (kanan)
				if titik_dari_map2b:
					pos_awal = titik_dari_map2b.global_position
				if tujuan_dari_map2b and tujuan_dari_map2b.global_position.distance_to(pos_awal) > 5:
					pos_tujuan = tujuan_dari_map2b.global_position
				else:
					pos_tujuan = pos_awal + Vector2(0, 35)
				arah_awal = "bawah"

			"map5_ke_map4", "dari_map5":
				# Datang dari Map 5
				if titik_dari_map5:
					pos_awal = titik_dari_map5.global_position
				if tujuan_dari_map5 and tujuan_dari_map5.global_position.distance_to(pos_awal) > 5:
					pos_tujuan = tujuan_dari_map5.global_position
				else:
					pos_tujuan = pos_awal + Vector2(-35, 0)
				arah_awal = "kiri"

			_:
				print("target_spawn_id '%s' memakai default jalur A di map_4" % TransitionScreen.target_spawn_id)

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
