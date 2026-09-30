extends Node2D

@onready var player = $Player

# Titik Spawn & Tujuan yang ada di map_2.tscn
@onready var titik_portal_a = $TitikBerhenti_A
@onready var tujuan_portal_a = $TitikTujuan_A2

@onready var titik_portal_b = $TitikBerhenti_B
@onready var tujuan_portal_b = $TitikTujuan_B2

@onready var titik_portal_b2 = $TitikBerhenti_BB2
@onready var tujuan_portal_b2 = $TitikTujuan_BB2

@onready var titik_portal_c = $TitikBerhenti_C
@onready var tujuan_portal_c = $TitikTujuan_C2

@onready var titik_portal_c2 = $TitikBerhenti_C2
@onready var tujuan_portal_c2 = $TitikTujuan_CC2

@onready var warung_house = $HouseInteract2 if has_node("HouseInteract2") else ($warung_house if has_node("warung_house") else null)
@onready var warung_tujuan = $warung_tujuan if has_node("warung_tujuan") else ($TitikTujuan_B if has_node("TitikTujuan_B") else null)

func _ready() -> void:
	print("=== MASUK MAP_2, target_spawn_id = '", TransitionScreen.target_spawn_id, "' ===")

	if not player:
		return

	var pos_awal = Vector2(94, 20)
	var pos_tujuan = Vector2(94, 20)
	var arah_awal = "bawah"

	# Default ke Portal A jika spawn_id kosong
	if titik_portal_a:
		pos_awal = titik_portal_a.global_position
		pos_tujuan = tujuan_portal_a.global_position if tujuan_portal_a else pos_awal

	if TransitionScreen:
		match TransitionScreen.target_spawn_id:
			"portal_a", "node_2d", "map2", "dari_node_2d":
				# Datang dari node_2d (luar rumah)
				if titik_portal_a:
					pos_awal = titik_portal_a.global_position
				if tujuan_portal_a:
					pos_tujuan = tujuan_portal_a.global_position
				arah_awal = "bawah"

			"portal_b", "map3_atas", "map3":
				# Datang dari Map 3 (jalur atas)
				if titik_portal_b:
					pos_awal = titik_portal_b.global_position
				if tujuan_portal_b:
					pos_tujuan = tujuan_portal_b.global_position
				arah_awal = "kiri"

			"portal_b2", "map3_bawah", "map33", "map22":
				# Datang dari Map 3 (jalur bawah)
				if titik_portal_b2:
					pos_awal = titik_portal_b2.global_position
				if tujuan_portal_b2:
					pos_tujuan = tujuan_portal_b2.global_position
				arah_awal = "kiri"

			"portal_c", "map4_kiri", "map4", "map4a_ke_map2":
				# Datang dari Map 4 (jalur kiri)
				if titik_portal_c:
					pos_awal = titik_portal_c.global_position
				if tujuan_portal_c:
					pos_tujuan = tujuan_portal_c.global_position
				arah_awal = "atas"

			"portal_c2", "map4_kanan", "map44", "map4b_ke_map2":
				# Datang dari Map 4 (jalur kanan)
				if titik_portal_c2:
					pos_awal = titik_portal_c2.global_position
				if tujuan_portal_c2:
					pos_tujuan = tujuan_portal_c2.global_position
				arah_awal = "atas"

			"warung_mw", "warung", "warungMW", "pintu", "MW":
				# Keluar dari Warung Mpok Wati
				if warung_house:
					pos_awal = warung_house.global_position
				if warung_tujuan:
					pos_tujuan = warung_tujuan.global_position
				else:
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
