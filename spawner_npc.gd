extends Node2D

@export var jumlah_npc: int = 4
@export var scene_npc_jalan: PackedScene = preload("res://npc_jalan.tscn") if ResourceLoader.exists("res://npc_jalan.tscn") else null

# Daftar waypoint & variasi sprite NPC
@export var daftar_waypoint: Array[Node2D] = []

var _sprite_frames_pelanggan: SpriteFrames = null

func _ready():
	_muat_sprite_frames_pelanggan()
	
	var koordinat_titik: Array[Vector2] = []
	
	if not daftar_waypoint.is_empty():
		for wp in daftar_waypoint:
			if is_instance_valid(wp):
				koordinat_titik.append(wp.global_position)
	else:
		# Titik waypoint di sepanjang jalan oranye utama (Y = 265)
		koordinat_titik.append(Vector2(100, 265))
		koordinat_titik.append(Vector2(240, 265))
		koordinat_titik.append(Vector2(380, 265))
		koordinat_titik.append(Vector2(520, 265))
		koordinat_titik.append(Vector2(650, 265))
		
	_spawn_semua_npc(koordinat_titik)

func _muat_sprite_frames_pelanggan():
	if ResourceLoader.exists("res://pelanggan.tscn"):
		var res_pel = load("res://pelanggan.tscn")
		if res_pel:
			var temp_inst = res_pel.instantiate()
			var anim_node = temp_inst.get_node_or_null("AnimasiKarakter")
			if anim_node and anim_node.sprite_frames:
				_sprite_frames_pelanggan = anim_node.sprite_frames
			temp_inst.queue_free()

func _spawn_semua_npc(koordinat_titik: Array[Vector2]):
	if scene_npc_jalan == null or koordinat_titik.is_empty():
		return
		
	var daftar_akhiran = ["", "_2", "_3", "_4", "_5"]
	
	for i in range(jumlah_npc):
		var instance_npc = scene_npc_jalan.instantiate()
		add_child(instance_npc)
		
		# Gunakan SpriteFrames dari pelanggan.tscn
		if _sprite_frames_pelanggan != null:
			var anim_node = instance_npc.get_node_or_null("AnimasiKarakter")
			if anim_node:
				anim_node.sprite_frames = _sprite_frames_pelanggan
				
		# Bergantian acak variasi karakter dari pelanggan.tscn ("", "_2", "_3", "_4", "_5")
		var suffix = daftar_akhiran[i % daftar_akhiran.size()]
		instance_npc.set("akhiran_npc", suffix)
		
		var idx_awal = i % koordinat_titik.size()
		instance_npc.global_position = koordinat_titik[idx_awal] + Vector2(randf_range(-15, 15), randf_range(-4, 4))
		instance_npc.daftar_titik_tujuan = koordinat_titik
				
		if instance_npc.has_method("pilih_tujuan_baru"):
			instance_npc.pilih_tujuan_baru()
