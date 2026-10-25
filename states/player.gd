extends CharacterBody2D
const kecepatan = 100
@export var kecepatan_cutscene = 50
var arah = "diam"
var bisa_gerak = true
var mode_cutscene = false
var titik_tujuan = Vector2.ZERO
var _perjalanan_id: int = 0
var _jalan_aktif: bool = false
var _collision_layer_asli: int = 1
var _collision_mask_asli: int = 1
var _posisi_cek_jalan: Vector2 = Vector2.ZERO

signal sampai_tujuan


func _exit_tree() -> void:
	if _jalan_aktif:
		collision_layer = _collision_layer_asli
		collision_mask = _collision_mask_asli
		_jalan_aktif = false
		mode_cutscene = false
		set_bisa_gerak(true)
		sampai_tujuan.emit()

func set_bisa_gerak(value: bool):
	bisa_gerak = value

func aktifkan_kontrol() -> void:
	bisa_gerak = true
	mode_cutscene = false

func atur_arah_menghadap(arah_baru: String) -> void:
	arah = arah_baru
	if has_node("AnimatedSprite2D"):
		arah_player(false)

func mainkan_animasi(nama_anim: String) -> void:
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play(nama_anim)

func jalan_ke_titik(titik: Vector2):
	_perjalanan_id += 1
	_jalan_aktif = true
	_collision_layer_asli = collision_layer
	_collision_mask_asli = collision_mask
	collision_layer = 0
	collision_mask = 0
	_posisi_cek_jalan = global_position
	titik_tujuan = titik
	mode_cutscene = true
	bisa_gerak = false
	call_deferred("_pantau_jalan", _perjalanan_id)

func _pantau_jalan(id_perjalanan: int) -> void:
	var waktu_berjalan: float = 0.0
	while is_inside_tree() and id_perjalanan == _perjalanan_id and mode_cutscene:
		await get_tree().create_timer(0.5).timeout
		if not is_inside_tree() or id_perjalanan != _perjalanan_id or not mode_cutscene:
			return
		waktu_berjalan += 0.5
		var jarak_bergerak := global_position.distance_to(_posisi_cek_jalan)
		_posisi_cek_jalan = global_position
		if global_position.distance_to(titik_tujuan) <= 4.0:
			return
		if jarak_bergerak < 2.0 or waktu_berjalan >= 6.0:
			push_warning("Player tersangkut/timeout saat auto-walk; dipindahkan ke marker tujuan.")
			_selesaikan_jalan_otomatis(true)
			return


func _selesaikan_jalan_otomatis(teleport: bool) -> void:
	if not _jalan_aktif:
		return
	_jalan_aktif = false
	mode_cutscene = false
	velocity = Vector2.ZERO
	if teleport:
		global_position = titik_tujuan
	collision_layer = _collision_layer_asli
	collision_mask = _collision_mask_asli
	atur_arah_menghadap(arah)
	set_bisa_gerak(true)
	sampai_tujuan.emit()

func _physics_process(delta):
	if mode_cutscene:
		gerak_cutscene(delta)
	elif bisa_gerak:
		gerak_player(delta)
	else:
		velocity = Vector2.ZERO
		move_and_slide()

func gerak_cutscene(delta):
	var jarak = global_position.distance_to(titik_tujuan)
	
	if jarak < 4.0:
		_selesaikan_jalan_otomatis(false)
		return
	
	var arah_vector = (titik_tujuan - global_position).normalized()
	
	if abs(arah_vector.x) > abs(arah_vector.y):
		arah = "kanan" if arah_vector.x > 0 else "kiri"
	else:
		arah = "bawah" if arah_vector.y > 0 else "atas"
	
	arah_player(true)
	
	# === PASTIKAN MENGGUNAKAN "kecepatan_cutscene" DI SINI ===
	velocity = arah_vector * kecepatan_cutscene 
	
	move_and_slide()

func gerak_player(delta):
	if Input.is_action_pressed("ui_right"):
		arah = "kanan"
		arah_player(true)
		velocity.x = kecepatan
		velocity.y = 0
	elif Input.is_action_pressed("ui_left"):
		arah = "kiri"
		arah_player(true)
		velocity.x = -kecepatan
		velocity.y = 0
	elif Input.is_action_pressed("ui_up"):
		arah = "atas"
		arah_player(true)
		velocity.x = 0
		velocity.y = -kecepatan
	elif Input.is_action_pressed("ui_down"):
		arah = "bawah"
		arah_player(true)
		velocity.x = 0
		velocity.y = kecepatan
	else:
		arah_player(false)
		velocity.x = 0
		velocity.y = 0
	move_and_slide()

func arah_player(gerak):
	var arah_sekarang = arah
	var animasi = $AnimatedSprite2D
	
	if arah_sekarang == "kanan":
		animasi.flip_h = false
		if gerak:
			animasi.play("jalan_kanan")
		else:
			animasi.play("diam_kanan")
	elif arah_sekarang == "kiri":
		animasi.flip_h = true
		if gerak:
			animasi.play("jalan_kanan")
		else:
			animasi.play("diam_kanan")
	elif arah_sekarang == "atas":
		animasi.flip_h = true
		if gerak:
			animasi.play("jalan_atas")
		else:
			animasi.play("diam_atas")
	elif arah_sekarang == "bawah":
		animasi.flip_h = true
		if gerak:
			animasi.play("jalan_bawah")
		else:
			animasi.play("diam")
