extends Node2D

@onready var player = $Player             

@onready var house_interact_a = $HouseInteract
@onready var house_interact_b = $HouseInteract2
# <-- tambahan untuk warung

@onready var titik_tujuan_a = $TitikTujuan_A     
@onready var titik_tujuan_b = $TitikTujuan_B    
   # <-- tambahan untuk warung

func _ready() -> void:
	print("=== MASUK RUMAH, target_spawn_id = '", TransitionScreen.target_spawn_id, "' ===")

	if player:
		var aktif_house = house_interact_a 
		var aktif_titik = titik_tujuan_a
		
		if TransitionScreen:
			match TransitionScreen.target_spawn_id:
				"RumahArka":
					aktif_house = house_interact_a
					aktif_titik = titik_tujuan_a
				"warungMW":
					aktif_house = house_interact_b
					aktif_titik = titik_tujuan_b


		if aktif_house and aktif_titik:
			player.global_position = aktif_house.global_position
			if player.has_method("atur_arah_menghadap"):
				player.atur_arah_menghadap("bawah")
			if player.has_method("jalan_ke_titik"):
				player.jalan_ke_titik(aktif_titik.global_position)
				if player.has_signal("sampai_tujuan"):
					await player.sampai_tujuan
				if player.has_method("aktifkan_kontrol"):
					player.aktifkan_kontrol() 
				elif "bisa_gerak" in player:
					player.bisa_gerak = true
