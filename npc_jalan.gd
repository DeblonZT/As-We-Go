extends CharacterBody2D

@export var kecepatan: float = 40.0
@export var daftar_titik_tujuan: Array[Vector2] = []
@export var waktu_tunggu_min: float = 1.0
@export var waktu_tunggu_maks: float = 3.0
@export var akhiran_npc: String = ""

@onready var animasi = $AnimasiKarakter
@onready var timer_tunggu = $TimerTunggu

var status: String = "JALAN"
var indeks_tujuan: int = -1
var titik_tujuan: Vector2 = Vector2.ZERO
var posisi_sebelumnya: Vector2 = Vector2.ZERO
var timer_stuck: float = 0.0

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
				if timer_stuck > 0.8:
					_hentikan_di_tempat()
			else:
				timer_stuck = 0.0
				
			posisi_sebelumnya = global_position
		else:
			_hentikan_di_tempat()

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

func _on_timer_tunggu_timeout():
	pilih_tujuan_baru()
