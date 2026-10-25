extends Node2D

@onready var player = $Player
@onready var portal = $Portal

func _ready() -> void:
	print("=== MASUK WARUNG MANG CECEP ===")

	if not player:
		return

	var pos_awal = Vector2(384, 310)
	var pos_tujuan = Vector2(384, 280)

	if portal and portal.has_node("TitikBerhenti"):
		pos_awal = portal.get_node("TitikBerhenti").global_position
		pos_tujuan = pos_awal + Vector2(0, -25)

	player.global_position = pos_awal
	if player.has_method("atur_arah_menghadap"):
		player.atur_arah_menghadap("atas")
	if player.has_method("jalan_ke_titik"):
		player.jalan_ke_titik(pos_tujuan)
		if player.has_signal("sampai_tujuan"):
			await player.sampai_tujuan

	if player.has_method("aktifkan_kontrol"):
		player.aktifkan_kontrol()
	elif player.has_method("set_bisa_gerak"):
		player.set_bisa_gerak(true)
	elif "bisa_gerak" in player:
		player.bisa_gerak = true
