extends Node2D

@onready var player = $Player
@onready var portal = $Portal
@onready var titik_tangga = $Portal/TitikBerhenti

func _ready() -> void:
	if not player:
		return
	
	spawn_normal()

func spawn_normal() -> void:
	# Default posisi dekat tangga lantai 2
	var pos_awal = Vector2(273, 59)
	var pos_tujuan = Vector2(273, 95)
	
	if titik_tangga:
		pos_awal = titik_tangga.global_position
		pos_tujuan = pos_awal + Vector2(0, 36)
	elif portal:
		pos_awal = portal.global_position
		pos_tujuan = pos_awal + Vector2(0, 30)
		
	player.global_position = pos_awal
	if player.has_method("atur_arah_menghadap"):
		player.atur_arah_menghadap("bawah")
		
	if player.has_method("jalan_ke_titik"):
		player.jalan_ke_titik(pos_tujuan)
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
