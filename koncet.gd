extends Node2D

@onready var player = $Player             
@onready var house_interact_a = $HouseInteract
@onready var portal_map2 = $Portal
@onready var titik_tujuan_rumah = $TitikTujuan_A     

func _ready() -> void:
	print("=== MASUK NODE_2D, target_spawn_id = '", TransitionScreen.target_spawn_id, "' ===")

	if not player:
		return

	var pos_awal = Vector2(238, 124)
	var pos_tujuan = Vector2(238, 140)
	var arah_awal = "bawah"

	if TransitionScreen:
		match TransitionScreen.target_spawn_id:
			"portal_map2", "map2", "node_2d":
				# Datang dari Map 2 (muncul di portal bawah dekat jalan)
				if portal_map2 and portal_map2.has_node("TitikBerhenti"):
					pos_awal = portal_map2.get_node("TitikBerhenti").global_position
				elif portal_map2:
					pos_awal = portal_map2.global_position + Vector2(0, -28)
				else:
					pos_awal = Vector2(505, 346)
				pos_tujuan = pos_awal + Vector2(0, -35)
				arah_awal = "atas"
			"rumah", "keluar", "RumahArka", _:
				# Datang dari dalam rumah (muncul di depan pintu rumah Arka)
				if house_interact_a:
					pos_awal = house_interact_a.global_position
				if titik_tujuan_rumah:
					pos_tujuan = titik_tujuan_rumah.global_position
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
