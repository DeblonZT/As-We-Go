extends Node
# Autoload "Musik": memutar BGM per scene bangunan, dengan fade masuk/keluar.
# Scene yang tidak terdaftar di DAFTAR_BGM = musik berhenti (fade out).
# Kalau pindah antar scene yang memakai lagu SAMA (misal rumah -> rumah_2),
# lagu lanjut tanpa mengulang dari awal.
# Mengikuti bus "Music" (toggle ON/OFF musik di menu setting ikut berlaku).

const BUS_MUSIK: String = "Music"  # kalau bus ini tidak ada, otomatis pakai Master
const DURASI_FADE: float = 0.8
const VOLUME_HENING_DB: float = -60.0

# ISI PATH-nya sendiri: klik kanan file di panel FileSystem -> Copy Path.
# Kunci kiri = path SCENE bangunan, "bgm" = path file lagu.
# volume_db: 0.0 = normal, negatif = lebih pelan (misal -6.0).
const DAFTAR_BGM: Dictionary = {
	"res://rumah.tscn": {"bgm": "res://Assets//Musics/BGM/bgm rumah.mp3", "volume_db": 0.0},
	"res://rumah_2.tscn": {"bgm": "res://Assets//Musics/BGM/bgm rumah.mp3", "volume_db": 0.0},
	"res://warung_mpok_wati.tscn": {"bgm": "res://Assets//Musics/BGM/bgm warung mpok wati.mp3", "volume_db": 0.0},
	"res://warung_mang_cecep.tscn": {"bgm": "res://Assets//Musics/BGM/bgm warung mang cecep.mp3", "volume_db": 0.0},
	"res://warung_pak_iwan.tscn": {"bgm": "res://Assets//Musics/BGM/bgm warung pak iwan.mp3", "volume_db": 0.0},
}

var _pemutar: AudioStreamPlayer
var _tween: Tween
var _bgm_aktif: String = ""
var _scene_terakhir: Node = null
var sedang_di_bangunan: bool = false


func _ready() -> void:
	_pemutar = AudioStreamPlayer.new()
	if AudioServer.get_bus_index(BUS_MUSIK) != -1:
		_pemutar.bus = BUS_MUSIK
	add_child(_pemutar)


func _process(_delta: float) -> void:
	var scene_sekarang = get_tree().current_scene
	if scene_sekarang == _scene_terakhir:
		return
	_scene_terakhir = scene_sekarang
	if scene_sekarang == null:
		return
	_pada_scene_berganti(scene_sekarang.scene_file_path)


func _pada_scene_berganti(path_scene: String) -> void:
	sedang_di_bangunan = DAFTAR_BGM.has(path_scene)
	if not DAFTAR_BGM.has(path_scene):
		_hentikan()
		return

	var data: Dictionary = DAFTAR_BGM[path_scene]
	var file: String = data.get("bgm", "")
	var volume: float = data.get("volume_db", 0.0)

	if file == _bgm_aktif and _pemutar.playing:
		_ubah_volume(volume)  # lagu sama: lanjut, tidak diulang
		return

	if not ResourceLoader.exists(file):
		push_warning("BGM tidak ditemukan: '%s' (cek DAFTAR_BGM di musik.gd)" % file)
		_hentikan()
		return

	_putar(file, volume)


func _putar(file: String, volume: float) -> void:
	_bgm_aktif = file
	if _tween:
		_tween.kill()
	_tween = create_tween()
	if _pemutar.playing:
		_tween.tween_property(_pemutar, "volume_db", VOLUME_HENING_DB, DURASI_FADE * 0.5)
	_tween.tween_callback(_mulai_lagu.bind(file, volume))


func _mulai_lagu(file: String, volume: float) -> void:
	var stream: AudioStream = load(file)
	if "loop" in stream:
		stream.loop = true  # OGG / MP3. Untuk WAV, atur loop di dock Import.
	_pemutar.stream = stream
	_pemutar.volume_db = VOLUME_HENING_DB
	_pemutar.play()
	_tween = create_tween()
	_tween.tween_property(_pemutar, "volume_db", volume, DURASI_FADE)


func _ubah_volume(volume: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_pemutar, "volume_db", volume, DURASI_FADE)


func _hentikan() -> void:
	_bgm_aktif = ""
	if not _pemutar.playing:
		return
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_pemutar, "volume_db", VOLUME_HENING_DB, DURASI_FADE)
	_tween.tween_callback(_pemutar.stop)
