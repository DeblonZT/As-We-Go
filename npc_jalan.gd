extends CharacterBody2D

@export var kecepatan: float = 40.0
@export var daftar_titik_tujuan: Array[Vector2] = []
@export var waktu_tunggu_min: float = 0.3
@export var waktu_tunggu_maks: float = 1.0
@export var akhiran_npc: String = ""

@onready var animasi = $AnimasiKarakter
@onready var timer_tunggu = $TimerTunggu

var status: String = "JALAN"
var indeks_tujuan: int = -1
var titik_tujuan: Vector2 = Vector2.ZERO
var posisi_sebelumnya: Vector2 = Vector2.ZERO
var timer_stuck: float = 0.0

# Variabel untuk sistem graph Marker2D
var pakai_sistem_graph: bool = false
var koneksi_graph: Dictionary = {}
var dict_marker_node: Dictionary = {}
var node_ujung: Array = []
var nama_node_sekarang: String = ""
var nama_node_sebelumnya: String = ""

func _ready():
	collision_layer = 0
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	
	if timer_tunggu:
		timer_tunggu.timeout.connect(_on_timer_tunggu_timeout)
		
	if akhiran_npc == "":
		var daftar_akhiran = ["", "_2", "_3", "_4", "_5"]
		akhiran_npc = daftar_akhiran[randi() % daftar_akhiran.size()]
		
	_mainkan_animasi("diam")
	
	# Jika tidak dipanggil via graph, gunakan list biasa
	if not pakai_sistem_graph:
		if not daftar_titik_tujuan.is_empty():
			pilih_tujuan_baru()
		else:
			status = "DIAM"

func _physics_process(delta: float):
	if status == "JALAN":
		var jarak_ke_tujuan = global_position.distance_to(titik_tujuan)
		
		if jarak_ke_tujuan > 4.0:
			var arah = (titik_tujuan - global_position).normalized()
			velocity = arah * kecepatan
			
			move_and_slide()
			
			if abs(arah.x) > abs(arah.y):
				if arah.x < 0:
					_mainkan_animasi("jalan_kiri")
				elif arah.x > 0:
					_mainkan_animasi("jalan_kanan")
			else:
				if arah.y > 0:
					_mainkan_animasi("jalan_bawah")
				elif arah.y < 0:
					_mainkan_animasi("jalan_atas")
			
			if global_position.distance_to(posisi_sebelumnya) < 0.2:
				timer_stuck += delta
				if timer_stuck > 1.5:
					if pakai_sistem_graph:
						queue_free()
					else:
						_hentikan_di_tempat()
			else:
				timer_stuck = 0.0
				
			posisi_sebelumnya = global_position
		else:
			# Sampai di titik tujuan
			if pakai_sistem_graph:
				_tiba_di_node_graph()
			else:
				_hentikan_di_tempat()

func _tiba_di_node_graph():
	velocity = Vector2.ZERO
	# Cek apakah node ini adalah ujung (endpoint) → hilang
	if nama_node_sekarang in node_ujung:
		queue_free()
		return
	
	# Persimpangan → langsung pilih arah berikutnya tanpa jeda
	pilih_tujuan_baru_graph()

func _mainkan_animasi(nama_anim: String):
	if not (animasi and animasi.sprite_frames):
		return
	var nama_penuh = nama_anim + akhiran_npc
	if animasi.sprite_frames.has_animation(nama_penuh):
		animasi.play(nama_penuh)
	elif animasi.sprite_frames.has_animation(nama_anim):
		animasi.play(nama_anim)

func _hentikan_di_tempat():
	velocity = Vector2.ZERO
	status = "DIAM"
	_mainkan_animasi("diam")
		
	var jeda_tunggu = randf_range(waktu_tunggu_min, waktu_tunggu_maks)
	if timer_tunggu and timer_tunggu.is_stopped():
		timer_tunggu.start(jeda_tunggu)

func pilih_tujuan_baru():
	if daftar_titik_tujuan.is_empty():
		return
		
	var idx_baru = randi() % daftar_titik_tujuan.size()
	if daftar_titik_tujuan.size() > 1 and idx_baru == indeks_tujuan:
		idx_baru = (idx_baru + 1) % daftar_titik_tujuan.size()
		
	indeks_tujuan = idx_baru
	titik_tujuan = daftar_titik_tujuan[indeks_tujuan]
	timer_stuck = 0.0
	status = "JALAN"

func pilih_tujuan_baru_graph():
	if koneksi_graph.is_empty() or not koneksi_graph.has(nama_node_sekarang):
		queue_free()
		return
		
	var tetangga = koneksi_graph[nama_node_sekarang].duplicate()
	
	# Jangan balik ke node sebelumnya (kecuali hanya ada satu pilihan)
	if tetangga.size() > 1 and nama_node_sebelumnya in tetangga:
		tetangga.erase(nama_node_sebelumnya)
		
	if tetangga.is_empty():
		queue_free()
		return
		
	var nama_tujuan = tetangga[randi() % tetangga.size()]
	
	nama_node_sebelumnya = nama_node_sekarang
	nama_node_sekarang = nama_tujuan
	
	var marker_tujuan = dict_marker_node.get(nama_tujuan)
	if marker_tujuan:
		titik_tujuan = marker_tujuan.global_position
		timer_stuck = 0.0
		status = "JALAN"
	else:
		queue_free()

func _on_timer_tunggu_timeout():
	if pakai_sistem_graph:
		pilih_tujuan_baru_graph()
	else:
		pilih_tujuan_baru()
