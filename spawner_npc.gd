extends Node2D

@export var jumlah_npc_maks: int = 6
@export var interval_spawn_detik: float = 4.0
@export var scene_npc_jalan: PackedScene = preload("res://npc_jalan.tscn") if ResourceLoader.exists("res://npc_jalan.tscn") else null

# Daftar waypoint fallback (jika tidak ada Marker2D)
@export var daftar_waypoint: Array[Node2D] = []

var _sprite_frames_pelanggan: SpriteFrames = null
var koneksi_graph: Dictionary = {}
var dict_marker_node: Dictionary = {}
# node_ujung = endpoint: tempat NPC spawn & hilang
var node_ujung: Array = []
# node_persimpangan = junction: tempat NPC pilih arah
var node_persimpangan: Array = []

var _pakai_graph: bool = false
var _jumlah_npc_aktif: int = 0
var _timer_spawn: float = 0.0

func _ready():
	_muat_sprite_frames_pelanggan()
	
	var nama_scene = ""
	if get_parent() != null and get_parent().scene_file_path != "":
		nama_scene = get_parent().scene_file_path.get_file()
	elif get_parent() != null:
		nama_scene = get_parent().name
		
	_siapkan_graph_map(nama_scene)
	
	if _pakai_graph:
		# Spawn awal langsung beberapa NPC
		var jumlah_awal = min(jumlah_npc_maks, node_ujung.size() * 2)
		for i in range(jumlah_awal):
			_spawn_satu_npc_graph(i)
	else:
		# Fallback: sistem waypoint lama
		var koordinat_titik: Array[Vector2] = []
		if not daftar_waypoint.is_empty():
			for wp in daftar_waypoint:
				if is_instance_valid(wp):
					koordinat_titik.append(wp.global_position)
		else:
			koordinat_titik.append(Vector2(100, 265))
			koordinat_titik.append(Vector2(240, 265))
			koordinat_titik.append(Vector2(380, 265))
			koordinat_titik.append(Vector2(520, 265))
			koordinat_titik.append(Vector2(650, 265))
		_spawn_semua_npc_fallback(koordinat_titik)

func _process(delta: float):
	# Hitung NPC aktif yang masih valid
	_jumlah_npc_aktif = 0
	for child in get_children():
		if child is CharacterBody2D and is_instance_valid(child):
			_jumlah_npc_aktif += 1
	
	if _pakai_graph and _jumlah_npc_aktif < jumlah_npc_maks:
		_timer_spawn += delta
		if _timer_spawn >= interval_spawn_detik:
			_timer_spawn = 0.0
			_spawn_satu_npc_graph(_jumlah_npc_aktif)

func _siapkan_graph_map(nama_scene: String):
	koneksi_graph.clear()
	dict_marker_node.clear()
	node_ujung.clear()
	node_persimpangan.clear()
	
	# edges = [dari, ke] (koneksi satu arah: dari ujung ke persimpangan, atau antar persimpangan)
	# Arah sudah ditentukan: dari ujung → persimpangan → ujung lain
	var edges = []
	var ujung = []
	var persimpangan = []
	var map_lower = nama_scene.to_lower()
	
	if "node_2d" in map_lower:
		# Arah 1 → Arah 2 → Arah 3
		edges = [["Arah 1", "Arah 2"], ["Arah 2", "Arah 3"]]
		ujung = ["Arah 1", "Arah 3"]
		persimpangan = ["Arah 2"]
	elif "map_2" in map_lower:
		# Arah 1 → Arah 2 (persimpangan: bisa ke Arah 3 atau ke Arah 4)
		# Arah 4 (persimpangan: bisa ke Arah 5 atau kembali ke Arah 2)
		# Arah 3, Arah 5, Arah 1 adalah ujung
		edges = [
			["Arah 1", "Arah 2"],
			["Arah 2", "Arah 3"],
			["Arah 2", "Arah 4"],
			["Arah 4", "Arah 5"]
		]
		ujung = ["Arah 1", "Arah 3", "Arah 5"]
		persimpangan = ["Arah 2", "Arah 4"]
	elif "map_3" in map_lower:
		# Arah 1 → Arah 2 → Arah 3 (persimpangan: bisa ke Arah 4 atau ke Arah 5)
		# Arah 4, Arah 5, Arah 1 adalah ujung
		edges = [
			["Arah 1", "Arah 2"],
			["Arah 2", "Arah 3"],
			["Arah 3", "Arah 4"],
			["Arah 3", "Arah 5"]
		]
		ujung = ["Arah 1", "Arah 4", "Arah 5"]
		persimpangan = ["Arah 2", "Arah 3"]
	elif "map_4" in map_lower:
		# Jalur 1: Arah 1 → Arah 2 → Arah 3
		# Jalur 2: Arah 5 → Arah 4
		edges = [
			["Arah 1", "Arah 2"],
			["Arah 2", "Arah 3"],
			["Arah 3", "Arah 4"],
			["Arah 3", "Arah 5"],
		]
		ujung = ["Arah 1", "Arah 4", "Arah 5"]
		persimpangan = ["Arah 2", "Arah 3"]
	elif "map_5" in map_lower:
		# Arah 1 → Arah 2 → Arah 3
		edges = [
				["Arah 1", "Arah 2"], 
				["Arah 2", "Arah 5"],
				["Arah 2", "Arah 4"],
				["Arah 5", "Arah 6"],
				["Arah 6", "Arah 7"],
				["Arah 7", "Arah 8"],
				["Arah 8", "Arah 3"],
				]
		ujung = ["Arah 1", "Arah 3", "Arah 4"]
		persimpangan = ["Arah 2"]
	
	if edges.is_empty():
		_pakai_graph = false
		return
	
	node_ujung = ujung
	node_persimpangan = persimpangan
	
	var map_root = get_parent()
	if not map_root:
		_pakai_graph = false
		return
	
	# Cari semua Marker2D
	for edge in edges:
		for nama_node in edge:
			if not dict_marker_node.has(nama_node):
				var n = map_root.get_node_or_null(nama_node)
				if n and n is Marker2D:
					dict_marker_node[nama_node] = n
	
	# Bangun graph dua arah (NPC bisa jalan dari ujung manapun ke arah manapun)
	for edge in edges:
		var u = edge[0]
		var v = edge[1]
		if not dict_marker_node.has(u) or not dict_marker_node.has(v):
			continue
		if not koneksi_graph.has(u): koneksi_graph[u] = []
		if not koneksi_graph.has(v): koneksi_graph[v] = []
		koneksi_graph[u].append(v)
		koneksi_graph[v].append(u)
	
	# Cek apakah setidaknya ada 1 ujung yang ditemukan di scene
	var ujung_ditemukan = false
	for nama in node_ujung:
		if dict_marker_node.has(nama):
			ujung_ditemukan = true
			break
	
	_pakai_graph = ujung_ditemukan

func _muat_sprite_frames_pelanggan():
	if ResourceLoader.exists("res://pelanggan.tscn"):
		var res_pel = load("res://pelanggan.tscn")
		if res_pel:
			var temp_inst = res_pel.instantiate()
			var anim_node = temp_inst.get_node_or_null("AnimasiKarakter")
			if anim_node and anim_node.sprite_frames:
				_sprite_frames_pelanggan = anim_node.sprite_frames
			temp_inst.queue_free()

func _spawn_satu_npc_graph(indeks: int):
	if scene_npc_jalan == null: return
	
	# Pilih ujung spawn secara bergantian / acak dari node_ujung yang ada di scene
	var ujung_tersedia: Array[String] = []
	for nama in node_ujung:
		if dict_marker_node.has(nama):
			ujung_tersedia.append(nama)
	
	if ujung_tersedia.is_empty(): return
	
	var nama_spawn = ujung_tersedia[indeks % ujung_tersedia.size()]
	var marker_spawn = dict_marker_node.get(nama_spawn)
	if not marker_spawn: return
	
	var instance_npc = scene_npc_jalan.instantiate()
	add_child(instance_npc)
	
	# Set SpriteFrames
	if _sprite_frames_pelanggan != null:
		var anim_node = instance_npc.get_node_or_null("AnimasiKarakter")
		if anim_node: anim_node.sprite_frames = _sprite_frames_pelanggan
	
	# Set variasi karakter acak
	var daftar_akhiran = ["", "_2", "_3", "_4", "_5"]
	instance_npc.set("akhiran_npc", daftar_akhiran[randi() % daftar_akhiran.size()])
	
	# Set data graph
	instance_npc.set("pakai_sistem_graph", true)
	instance_npc.set("koneksi_graph", koneksi_graph)
	instance_npc.set("dict_marker_node", dict_marker_node)
	instance_npc.set("node_ujung", node_ujung)
	instance_npc.set("nama_node_sekarang", nama_spawn)
	instance_npc.set("nama_node_sebelumnya", "")
	
	# Posisikan di marker spawn dengan sedikit offset acak
	instance_npc.global_position = marker_spawn.global_position + Vector2(randf_range(-8, 8), randf_range(-8, 8))
	
	# Mulai jalan dari ujung spawn
	if instance_npc.has_method("pilih_tujuan_baru_graph"):
		instance_npc.pilih_tujuan_baru_graph()

func _spawn_semua_npc_fallback(koordinat_titik: Array[Vector2]):
	if scene_npc_jalan == null or koordinat_titik.is_empty(): return
	var daftar_akhiran = ["", "_2", "_3", "_4", "_5"]
	for i in range(jumlah_npc_maks):
		var instance_npc = scene_npc_jalan.instantiate()
		add_child(instance_npc)
		if _sprite_frames_pelanggan != null:
			var anim_node = instance_npc.get_node_or_null("AnimasiKarakter")
			if anim_node: anim_node.sprite_frames = _sprite_frames_pelanggan
		instance_npc.set("akhiran_npc", daftar_akhiran[i % daftar_akhiran.size()])
		var idx_awal = i % koordinat_titik.size()
		instance_npc.global_position = koordinat_titik[idx_awal] + Vector2(randf_range(-15, 15), randf_range(-4, 4))
		instance_npc.daftar_titik_tujuan = koordinat_titik
		if instance_npc.has_method("pilih_tujuan_baru"):
			instance_npc.pilih_tujuan_baru()
