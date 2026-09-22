extends CanvasLayer

# Variabel waktu mulai
var jam = 6
var menit = 0
var sesi = "Pagi"
var sesi_sebelumnya = "Pagi" # Untuk melacak kapan sesi berubah

# Menghubungkan script dengan node Label & Timer
@onready var label_uang = $LabelUang
@onready var label_waktu = $LabelWaktu
@onready var label_sesi = $LabelSesi
@onready var timer_waktu = $TimerWaktu

# --- NODE TRANSISI & AUDIO ---
@onready var layar_transisi = $LayarTransisi

var audio_sfx: AudioStreamPlayer
var audio_bgm: AudioStreamPlayer

# --- MEMUAT GAMBAR TRANSISI ---
var img_pagi = preload("res://Assets/BG/bg_pagi.png")
var img_siang = preload("res://Assets/BG/bg_siang.png")
var img_sore = preload("res://Assets/BG/bg_sore.png")
var img_malam = preload("res://Assets/BG/bg_malam.png")

# --- MEMUAT ASET AUDIO (SFX & BGM) ---
var sfx_pagi = preload("res://Assets/Musics/Sound Effect/sound effect pagi.mp3")
var sfx_siang = preload("res://Assets/Musics/Sound Effect/sound effect siang.mp3")
var sfx_sore = preload("res://Assets/Musics/Sound Effect/sound effect sore.mp3")
var sfx_malam = preload("res://Assets/Musics/Sound Effect/sound effect malem.mp3")

var bgm_pagi = preload("res://Assets/Musics/BGM/bgm pagi.mp3")
var bgm_siang = preload("res://Assets/Musics/BGM/bgm siang.mp3")
var bgm_sore = preload("res://Assets/Musics/BGM/bgm sore.mp3")
var bgm_malam = preload("res://Assets/Musics/BGM/bgm malem.mp3")

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_window().size = Vector2i(1280, 720)
	
	_siapkan_node_audio()
	
	if layar_transisi:
		layar_transisi.hide()
	
	update_ui()

func _siapkan_node_audio():
	if not has_node("AudioSFX"):
		audio_sfx = AudioStreamPlayer.new()
		audio_sfx.name = "AudioSFX"
		audio_sfx.process_mode = Node.PROCESS_MODE_ALWAYS
		audio_sfx.bus = &"Master"
		add_child(audio_sfx)
	else:
		audio_sfx = $AudioSFX

	if not has_node("AudioBGM"):
		audio_bgm = AudioStreamPlayer.new()
		audio_bgm.name = "AudioBGM"
		audio_bgm.process_mode = Node.PROCESS_MODE_ALWAYS
		audio_bgm.bus = &"Music"
		add_child(audio_bgm)
	else:
		audio_bgm = $AudioBGM

func _process(_delta):
	# Memperbarui teks uang setiap saat agar selalu sinkron dengan Global
	if label_uang:
		label_uang.text = "Uang Arka: " + Global.format_rupiah(Global.uang)

func cek_sesi():
	sesi_sebelumnya = sesi
	
	# Menentukan sesi berdasarkan jam
	if jam >= 6 and jam < 12:
		sesi = "Pagi"
	elif jam >= 12 and jam < 16:
		sesi = "Siang"
	elif jam >= 16 and jam < 18:
		sesi = "Sore"
	else:
		sesi = "Malam"
		
	# Jika sesi yang baru berbeda dengan sesi sebelumnya, panggil transisi!
	if sesi != sesi_sebelumnya:
		putar_transisi_waktu(sesi)

func update_ui():
	var teks_jam = str(jam).pad_zeros(2)
	var teks_menit = str(menit).pad_zeros(2)
	
	if label_waktu:
		label_waktu.text = teks_jam + ":" + teks_menit
	if label_sesi:
		label_sesi.text = "Sesi: " + sesi

func _on_timer_waktu_timeout():
	menit += 1
	
	if menit >= 60:
		menit = 0
		jam += 1
		cek_sesi() 
		
	update_ui()
	
	if jam >= 18:
		timer_waktu.stop()
		print("Sesi jualan selesai!")

# --- FUNGSI TRANSISI 2 DETIK DENGAN SFX & BGM ---
func putar_transisi_waktu(fase_waktu: String):
	_siapkan_node_audio()
	
	# 1. Hentikan BGM sebelumnya saat transisi dimulai
	if audio_bgm:
		audio_bgm.stop()
		
	# 2. Putar Sound Effect sesuai sesi
	var stream_sfx: AudioStream = null
	var stream_img: Texture2D = null
	
	match fase_waktu:
		"Pagi":
			stream_sfx = sfx_pagi
			stream_img = img_pagi
		"Siang":
			stream_sfx = sfx_siang
			stream_img = img_siang
		"Sore":
			stream_sfx = sfx_sore
			stream_img = img_sore
		"Malam":
			stream_sfx = sfx_malam
			stream_img = img_malam
			
	if audio_sfx and stream_sfx:
		audio_sfx.stream = stream_sfx
		audio_sfx.play()

	# 3. Tampilkan gambar transisi
	if layar_transisi:
		if stream_img:
			layar_transisi.texture = stream_img
		layar_transisi.show()
	
	# 4. PAUSE GAME saat transisi
	get_tree().paused = true
	
	# 5. Tunggu 2 detik
	await get_tree().create_timer(2.0).timeout
	
	# 6. Sembunyikan layar transisi dan unpause game
	if layar_transisi:
		layar_transisi.hide()
	get_tree().paused = false
	
	# 7. Putar BGM untuk sesi baru setelah transisi selesai
	putar_bgm_sesi(fase_waktu)

# --- FUNGSI PEMUTAR BGM SESI ---
func putar_bgm_sesi(fase_waktu: String):
	_siapkan_node_audio()
	
	var stream_bgm: AudioStream = null
	match fase_waktu:
		"Pagi": stream_bgm = bgm_pagi
		"Siang": stream_bgm = bgm_siang
		"Sore": stream_bgm = bgm_sore
		"Malam": stream_bgm = bgm_malam
		
	if audio_bgm and stream_bgm:
		if audio_bgm.stream != stream_bgm or not audio_bgm.playing:
			audio_bgm.stream = stream_bgm
			audio_bgm.play()
