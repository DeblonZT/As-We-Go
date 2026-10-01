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

const JARAK_IKUT: float = 32.0       # 2 tile (16px * 2)
const JARAK_TELEPORT: float = 96.0   # 6 tile (16px * 6)

func _ready() -> void:
	add_to_group("Rani")
	add_to_group("NPC")
	
	if hanya_hari >= 0 and Global.hari != hanya_hari:
		queue_free()
		return
	
	if icon_e:
		icon_e.visible = false
	
	if area_bicara:
		area_bicara.body_entered.connect(_on_body_entered)
		area_bicara.body_exited.connect(_on_body_exited)
	
	_cek_status_awal()


func _cek_status_awal() -> void:
	if Global.hari == 3:
		if Cerita.punya_flag("rani_di_spot"):
			var scene = get_tree().current_scene
			var nama_scene = scene.scene_file_path.get_file() if scene and scene.scene_file_path else (scene.name if scene else "")
			if "map_3" in nama_scene.to_lower():
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
		elif Cerita.punya_flag("rani_bergabung"):
			state = State.IKUT_PLAYER
			_nonaktifkan_interaksi()
			collision_layer = 0
			collision_mask = 1
			call_deferred("_posisikan_di_belakang_player")
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
		var bisa_bicara = player_di_area and not sedang_dialog and player_sedang_bebas()
		if icon_e:
			icon_e.visible = bisa_bicara
		if bisa_bicara:
			if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_E):
				mulai_bicara()


func _physics_process(_delta: float) -> void:
	if state == State.IKUT_PLAYER:
		_proses_mengikuti()


func _proses_mengikuti() -> void:
	var p = player_ref if (player_ref and is_instance_valid(player_ref)) else get_tree().get_first_node_in_group("Player")
	if not is_instance_valid(p):
		velocity = Vector2.ZERO
		return
	
	var arah_p: String = p.arah if "arah" in p else "bawah"
	var offset_belakang = _get_offset_belakang(arah_p)
	var target_pos = p.global_position + offset_belakang
	
	var jarak_ke_player = global_position.distance_to(p.global_position)
	
	# Jika terhalang collision atau tertinggal sejauh 6 kotak (96px), teleport ke 2 kotak di belakang player
	if jarak_ke_player > JARAK_TELEPORT:
		global_position = target_pos
		velocity = Vector2.ZERO
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


func jalan_ke_spot(posisi_tujuan: Vector2) -> void:
	state = State.JALAN_KE_SPOT
	_nonaktifkan_interaksi()
	
	while is_instance_valid(self) and global_position.distance_to(posisi_tujuan) > 4.0:
		var arah_gerak = (posisi_tujuan - global_position).normalized()
		velocity = arah_gerak * kecepatan_jalan
		var arah_visual = _tentukan_arah_vektor(arah_gerak)
		_atur_animasi(arah_visual, true)
		move_and_slide()
		await get_tree().physics_frame
	
	if is_instance_valid(self):
		global_position = posisi_tujuan
		velocity = Vector2.ZERO
		state = State.DI_SPOT
		_atur_animasi("bawah", false)


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

	DialogBox.mulai_dialog(tree, gambar_portrait_npc, gambar_portrait_player, nama_npc, nama_player)
	await DialogBox.dialog_selesai

	Cerita.set_flag(kunci)

	if Cerita.punya_flag("ending_gagal"):
		Cerita.mulai_ending_gagal()

	atur_gerak_player(player, true)
	sedang_dialog = false
	
	if Cerita.punya_flag("rani_bergabung"):
		state = State.IKUT_PLAYER
		_nonaktifkan_interaksi()
		collision_layer = 0
		collision_mask = 1
		kembalikan_idle()
	else:
		kembalikan_idle()
