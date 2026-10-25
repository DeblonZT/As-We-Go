extends CharacterBody2D

enum State { NPC_DIAM, IKUT_PLAYER, JALAN_KE_SPOT, DI_SPOT }

@export var id_npc: String = "rani"
@export var gambar_portrait_npc: Texture2D
@export var gambar_portrait_player: Texture2D
@export var nama_npc: String = "Rani"
@export var nama_player: String = "Arka"
@export var hanya_hari: int = 3
@export var kecepatan_ikut: float = 105.0
@export var kecepatan_jalan: float = 60.0

@onready var icon_e = $AreaBicara/IconE if has_node("AreaBicara/IconE") else null
@onready var area_bicara = $AreaBicara if has_node("AreaBicara") else null
@onready var animasi = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null

var state: State = State.NPC_DIAM
var player_di_area: bool = false
var sedang_dialog: bool = false
var player_ref: Node2D = null
var _arah_terakhir: String = "bawah"
var _posisi_cek_ikut: Vector2 = Vector2.ZERO
var _waktu_cek_ikut: float = 0.0
var _auto_walk_layer: int = 1
var _auto_walk_mask: int = 1
var _auto_walk_aktif: bool = false

signal sampai_tujuan

const JARAK_IKUT: float = 24.0
const JARAK_TELEPORT: float = 160.0

func _ready() -> void:
	add_to_group("Rani")
	add_to_group("NPC")
	
	var scene_awal = get_tree().current_scene
	if hanya_hari >= 0:
		var festival_hari5: bool = Global.hari == 5 and scene_awal != null and scene_awal.scene_file_path == "res://map_4_festival.tscn" and Cerita.punya_flag("rani_bergabung")
		if (Global.hari < 3 or Global.hari > 4) and not festival_hari5:
			queue_free()
			return
	if Global.hari == 5 and scene_awal != null and scene_awal.scene_file_path == "res://map_4_festival.tscn" and not Cerita.punya_flag("rani_bergabung"):
		queue_free()
		return
	
	if icon_e:
		icon_e.visible = false
	
	if area_bicara:
		area_bicara.body_entered.connect(_on_body_entered)
		area_bicara.body_exited.connect(_on_body_exited)
	
	_cek_status_awal()
	_posisi_cek_ikut = global_position


func _exit_tree() -> void:
	if _auto_walk_aktif:
		collision_layer = _auto_walk_layer
		collision_mask = _auto_walk_mask
		_auto_walk_aktif = false
		sampai_tujuan.emit()


func _cek_status_awal() -> void:
	if Global.hari >= 3:
		# Rani sudah diantarkan pulang hari ini — tidak boleh muncul lagi
		if Cerita.punya_flag("rani_sudah_pulang"):
			queue_free()
			return

		if Cerita.punya_flag("rani_di_spot"):
			var scene = get_tree().current_scene
			var nama_scene = scene.scene_file_path.get_file() if scene and scene.scene_file_path else (scene.name if scene else "")
			if "map_3" in nama_scene.to_lower() or "map_4_festival" in nama_scene.to_lower():
				state = State.DI_SPOT
				var marker_spot = scene.get_node_or_null("Spot Rani") if scene else null
				if marker_spot:
					global_position = marker_spot.global_position
				else:
					global_position = Vector2(520, 167)
				_nonaktifkan_interaksi()
				_atur_animasi("bawah", false)
			else:
				queue_free()
				return
		elif Cerita.punya_flag("rani_ikut_arka"):
			state = State.IKUT_PLAYER
			_nonaktifkan_interaksi()
			collision_layer = 0
			collision_mask = 1
			call_deferred("_posisikan_di_belakang_player")
		elif Cerita.punya_flag("rani_dilarang_hari_ini"):
			# Rani dilarang — hanya muncul di map_4 sebagai NPC diam untuk dialog
			var scene = get_tree().current_scene
			var nama_scene = scene.scene_file_path.get_file() if scene and scene.scene_file_path else (scene.name if scene else "")
			if "map_4" not in nama_scene.to_lower():
				queue_free()
				return
			state = State.NPC_DIAM
		else:
			state = State.NPC_DIAM


func _nonaktifkan_interaksi() -> void:
	if icon_e:
		icon_e.visible = false
	if area_bicara:
		area_bicara.monitoring = false
		area_bicara.monitorable = false


func _posisikan_di_belakang_player() -> void:
	var p = get_tree().get_first_node_in_group("Player")
	if is_instance_valid(p):
		var arah_p = p.arah if "arah" in p else "bawah"
		var offset = _get_offset_belakang(arah_p)
		global_position = p.global_position + offset
		_atur_animasi(arah_p, false)


func _get_offset_belakang(arah_p: String) -> Vector2:
	match arah_p:
		"kanan":
			return Vector2(-JARAK_IKUT, 0.0)
		"kiri":
			return Vector2(JARAK_IKUT, 0.0)
		"atas":
			return Vector2(0.0, JARAK_IKUT)
		"bawah", _:
			return Vector2(0.0, -JARAK_IKUT)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		player_di_area = true
		player_ref = body as Node2D


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("Player"):
		player_di_area = false
		player_ref = null


func _process(_delta: float) -> void:
	if state == State.NPC_DIAM:
		var bisa_bicara = player_di_area and not sedang_dialog and not DialogBox.sedang_dialog and player_sedang_bebas()
		if icon_e:
			icon_e.visible = bisa_bicara
		if bisa_bicara:
			if Input.is_action_just_pressed("interaksi"):
				mulai_bicara()


func _physics_process(delta: float) -> void:
	if state == State.IKUT_PLAYER:
		_proses_mengikuti(delta)


func _proses_mengikuti(delta: float) -> void:
	var p = player_ref if (player_ref and is_instance_valid(player_ref)) else get_tree().get_first_node_in_group("Player")
	if not is_instance_valid(p):
		velocity = Vector2.ZERO
		_waktu_cek_ikut = 0.0
		return
	
	var arah_p: String = p.arah if "arah" in p else "bawah"
	var offset_belakang = _get_offset_belakang(arah_p)
	var target_pos = p.global_position + offset_belakang
	
	var jarak_ke_player = global_position.distance_to(p.global_position)
	
	# Jika tertinggal lebih dari 160 px, rapatkan langsung ke Arka.
	if jarak_ke_player > JARAK_TELEPORT:
		global_position = target_pos
		velocity = Vector2.ZERO
		_posisi_cek_ikut = global_position
		_waktu_cek_ikut = 0.0
		_atur_animasi(arah_p, false)
		return
	
	var jarak_ke_target = global_position.distance_to(target_pos)
	var player_sedang_bergerak = (p.velocity.length_squared() > 10.0) or (p.get("mode_cutscene") == true and p.velocity.length_squared() > 1.0)
	
	if player_sedang_bergerak:
		# Saat player bergerak, Rani terus bergerak mengikuti target tanpa berhenti mendadak
		var arah_gerak = (target_pos - global_position).normalized()
		var spd = kecepatan_ikut
		if jarak_ke_target > 48.0:
			spd = 125.0
		elif jarak_ke_target > 16.0:
			spd = 105.0
		else:
			spd = 95.0
		
		velocity = arah_gerak * spd
		var arah_visual = _tentukan_arah_vektor(arah_gerak)
		_atur_animasi(arah_visual, true)
		move_and_slide()
	else:
		# Saat player diam, Rani melangkah merapat ke target lalu berhenti (idle)
		if jarak_ke_target > 4.0:
			var arah_gerak = (target_pos - global_position).normalized()
			velocity = arah_gerak * 70.0
			var arah_visual = _tentukan_arah_vektor(arah_gerak)
			_atur_animasi(arah_visual, true)
			move_and_slide()
		else:
			velocity = Vector2.ZERO
			_atur_animasi(arah_p, false)
			move_and_slide()
	if player_sedang_bergerak or jarak_ke_target > 4.0:
		_waktu_cek_ikut += delta
		if _waktu_cek_ikut >= 1.0:
			if global_position.distance_to(_posisi_cek_ikut) < 2.0:
				global_position = target_pos
				velocity = Vector2.ZERO
				_atur_animasi(arah_p, false)
			else:
				_posisi_cek_ikut = global_position
			_waktu_cek_ikut = 0.0
	else:
		_posisi_cek_ikut = global_position
		_waktu_cek_ikut = 0.0

func ikut_arka() -> void:
	state = State.IKUT_PLAYER
	_nonaktifkan_interaksi()
	collision_layer = 0
	collision_mask = 1
	_posisikan_di_belakang_player()

func berhenti_ikut() -> void:
	state = State.NPC_DIAM
	velocity = Vector2.ZERO
	kembalikan_idle()

func jalan_ke_titik(posisi_tujuan: Vector2) -> void:
	await _jalan_otomatis_ke(posisi_tujuan, false)

func jalan_ke_spot(posisi_tujuan: Vector2) -> void:
	await _jalan_otomatis_ke(posisi_tujuan, true)


func _jalan_otomatis_ke(posisi_tujuan: Vector2, jadi_spot: bool) -> void:
	state = State.JALAN_KE_SPOT
	_nonaktifkan_interaksi()
	_auto_walk_layer = collision_layer
	_auto_walk_mask = collision_mask
	_auto_walk_aktif = true
	collision_layer = 0
	collision_mask = 0
	var waktu_mulai := Time.get_ticks_msec()
	var waktu_cek := waktu_mulai
	var posisi_cek := global_position
	var waktu_tersangkut: float = 0.0
	while is_instance_valid(self) and global_position.distance_to(posisi_tujuan) > 4.0:
		var arah_gerak = (posisi_tujuan - global_position).normalized()
		velocity = arah_gerak * kecepatan_jalan
		var arah_visual = _tentukan_arah_vektor(arah_gerak)
		_atur_animasi(arah_visual, true)
		move_and_slide()
		await get_tree().physics_frame
		if not is_instance_valid(self):
			return
		var sekarang := Time.get_ticks_msec()
		var durasi_cek := float(sekarang - waktu_cek) / 1000.0
		if durasi_cek >= 0.5:
			if global_position.distance_to(posisi_cek) < 2.0:
				waktu_tersangkut += durasi_cek
			else:
				waktu_tersangkut = 0.0
			posisi_cek = global_position
			waktu_cek = sekarang
		if waktu_tersangkut >= 0.5 or sekarang - waktu_mulai >= 6000:
			push_warning("Rani tersangkut/timeout saat auto-walk; dipindahkan ke marker tujuan.")
			global_position = posisi_tujuan
			break
	if is_instance_valid(self):
		velocity = Vector2.ZERO
		collision_layer = _auto_walk_layer
		collision_mask = _auto_walk_mask
		_auto_walk_aktif = false
		if jadi_spot:
			state = State.DI_SPOT
			_atur_animasi("bawah", false)
		else:
			state = State.NPC_DIAM
			kembalikan_idle()
		sampai_tujuan.emit()


func _mainkan_animasi(nama_anim: String, flip: bool) -> void:
	if animasi == null or not is_instance_valid(animasi):
		return
	if animasi.flip_h != flip:
		animasi.flip_h = flip
	if animasi.animation != nama_anim or not animasi.is_playing():
		animasi.play(nama_anim)


func _atur_animasi(arah_str: String, gerak: bool) -> void:
	_arah_terakhir = arah_str
	match arah_str:
		"kanan":
			_mainkan_animasi("jalan_kanan" if gerak else "diam_kanan", false)
		"kiri":
			_mainkan_animasi("jalan_kanan" if gerak else "diam_kanan", true)
		"atas":
			_mainkan_animasi("jalan_atas" if gerak else "diam_atas", false)
		"bawah", _:
			_mainkan_animasi("jalan_bawah" if gerak else "diam", false)


func _tentukan_arah_vektor(vektor: Vector2) -> String:
	if vektor.is_zero_approx():
		return _arah_terakhir
	
	# Hysteresis ambang arah agar tidak flicker horizontal/vertikal di sudut diagonal
	var ambang: float = 1.25
	if _arah_terakhir == "kanan" or _arah_terakhir == "kiri":
		if abs(vektor.y) > abs(vektor.x) * ambang:
			return "bawah" if vektor.y > 0 else "atas"
		else:
			return "kanan" if vektor.x >= 0 else "kiri"
	else:
		if abs(vektor.x) > abs(vektor.y) * ambang:
			return "kanan" if vektor.x > 0 else "kiri"
		else:
			return "bawah" if vektor.y >= 0 else "atas"


func player_sedang_bebas() -> bool:
	if player_ref == null:
		return false
	if "bisa_gerak" in player_ref:
		return player_ref.bisa_gerak
	return true


func atur_gerak_player(player: Node, nilai: bool) -> void:
	if player == null:
		return
	if player.has_method("set_bisa_gerak"):
		player.set_bisa_gerak(nilai)
	elif "bisa_gerak" in player:
		player.bisa_gerak = nilai


func hadap_ke_posisi(posisi: Vector2) -> void:
	if posisi.x <= global_position.x:
		_atur_animasi("kiri", false)
	else:
		_atur_animasi("kanan", false)


func hadap_ke_player() -> void:
	if player_ref == null:
		return
	hadap_ke_posisi(player_ref.global_position)


func kembalikan_idle() -> void:
	_atur_animasi("bawah", false)


func mulai_bicara() -> void:
	print("[NPC] id=", id_npc, " objektif=", Cerita.objektif_aktif, " hari=", Global.hari)
	var hari = Global.hari
	var kunci = "%s_hari_%d" % [id_npc, hari]
	var tree = Cerita.pilih_dialog(id_npc, hari, Cerita.punya_flag(kunci))

	if tree.is_empty():
		push_warning("Dialog kosong untuk NPC '%s' di hari %d, cek DataDialog" % [id_npc, hari])
		return

	sedang_dialog = true
	var player = player_ref

	hadap_ke_player()
	atur_gerak_player(player, false)

	var portrait_dialog: Texture2D = gambar_portrait_npc
	if Global.hari == 4:
		portrait_dialog = Cerita.muat_portrait_rani()
	DialogBox.mulai_dialog(tree, portrait_dialog, gambar_portrait_player, nama_npc, nama_player)
	await DialogBox.dialog_selesai

	Cerita.set_flag(kunci)

	if Cerita.punya_flag("ending_gagal"):
		Cerita.mulai_ending_gagal()

	atur_gerak_player(player, true)
	sedang_dialog = false
	
	# Ikut player hanya jika flag rani_ikut_arka aktif (di-set lewat aksi dialog)
	# Jika rani_dilarang_hari_ini aktif, aksi dialog tidak akan set flag ini
	if Cerita.punya_flag("rani_ikut_arka") and not Cerita.punya_flag("rani_dilarang_hari_ini"):
		state = State.IKUT_PLAYER
		_nonaktifkan_interaksi()
		collision_layer = 0
		collision_mask = 1
		kembalikan_idle()
	else:
		kembalikan_idle()
