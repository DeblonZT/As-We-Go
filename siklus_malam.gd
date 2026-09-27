extends Node
# Autoload "SiklusMalam": mengatur gelap-terang (CanvasModulate) dan lampu jalan
# (PointLight2D) otomatis sesuai MainUI.sesi. Tidak mengubah MainUI/Global sama
# sekali - cuma membaca MainUI.sesi tiap frame, mirip pola pemantauan di cerita.gd.

const WARNA_SESI := {
	"Pagi":  Color(1.0, 1.0, 1.0, 1.0),
	"Siang": Color(1.0, 1.0, 1.0, 1.0),
	"Sore":  Color(1.0, 0.72, 0.55, 1.0),
	"Malam": Color(0.28, 0.30, 0.55, 1.0),
}

const ENERGI_LAMPU_MALAM := 1.2
const ENERGI_LAMPU_MATI := 0.0
const DURASI_TRANSISI := 2.5  # detik, biar pindah sesi tidak instan/kaget

var _sesi_terakhir: String = ""
var _scene_terakhir: Node = null


func _process(_delta: float) -> void:
	var scene_sekarang = get_tree().current_scene
	var scene_berganti = scene_sekarang != _scene_terakhir
	_scene_terakhir = scene_sekarang

	var sesi_sekarang: String = _ambil_sesi()

	if scene_berganti:
		# Map baru dimuat: langsung set instan (di balik layar hitam transisi),
		# tidak perlu tween supaya tidak kelihatan "ngefade" pas fade-in baru selesai.
		_sesi_terakhir = sesi_sekarang
		_terapkan_sesi(sesi_sekarang, true)
		return

	if sesi_sekarang == _sesi_terakhir:
		return
	_sesi_terakhir = sesi_sekarang
	_terapkan_sesi(sesi_sekarang, false)


func _ambil_sesi() -> String:
	var hud = _cari_hud()
	if hud and "sesi" in hud and hud.sesi != "":
		return hud.sesi
	return "Siang"


func _cari_hud():
	var hud = get_node_or_null("/root/MainUI")
	if hud == null:
		hud = get_node_or_null("/root/MainUi")
	return hud


func _terapkan_sesi(sesi: String, instan: bool) -> void:
	var warna: Color = WARNA_SESI.get(sesi, Color.WHITE)
	var malam: bool = sesi == "Malam" or sesi == "Sore"
	var target_energi: float = ENERGI_LAMPU_MALAM if malam else ENERGI_LAMPU_MATI

	var canvas := _cari_canvas_modulate()
	if canvas:
		if instan:
			canvas.color = warna
		else:
			create_tween().tween_property(canvas, "color", warna, DURASI_TRANSISI)

	for lampu in get_tree().get_nodes_in_group("LampuJalan"):
		if not is_instance_valid(lampu):
			continue
		if instan:
			lampu.energy = target_energi
		else:
			create_tween().tween_property(lampu, "energy", target_energi, DURASI_TRANSISI)


func _cari_canvas_modulate() -> CanvasModulate:
	var daftar := get_tree().get_nodes_in_group("CanvasMalam")
	if daftar.is_empty():
		return null
	return daftar[0] as CanvasModulate
