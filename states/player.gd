extends CharacterBody2D
const kecepatan = 100
@export var kecepatan_cutscene = 50
var arah = "diam"
var bisa_gerak = true
var mode_cutscene = false
var titik_tujuan = Vector2.ZERO

signal sampai_tujuan

func set_bisa_gerak(value: bool):
	bisa_gerak = value

func jalan_ke_titik(titik: Vector2):
	titik_tujuan = titik
	mode_cutscene = true
	bisa_gerak = false

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
		mode_cutscene = false
		velocity = Vector2.ZERO
		arah_player(false)
		move_and_slide()
		sampai_tujuan.emit()
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
