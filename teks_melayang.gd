class_name TeksMelayang
extends Label
# Teks yang muncul, melayang naik, lalu memudar (dipakai untuk "+Rp20.000" dst).
# Dipanggil lewat static func, tidak perlu scene:
#   TeksMelayang.munculkan_di_sekitar(player, "+Rp20.000")

const WARNA_UANG: Color = Color.WHITE
const UKURAN_FONT: int = 6
const UKURAN_OUTLINE: int = 2
const LEBAR: float = 120.0
const JARAK_ACAK_X: float = 24.0   # geser acak kiri-kanan dari target
const OFFSET_ATAS: float = -40.0   # tinggi kemunculan di atas target
const JARAK_MELAYANG: float = 28.0
const DURASI_MELAYANG: float = 1.1


# Muncul di sekitar target (posisi acak di atas kepala)
static func munculkan_di_sekitar(target: Node2D, teks: String, warna: Color = WARNA_UANG) -> void:
	var adegan: Node = target.get_tree().current_scene
	if adegan == null:
		return
	var geser := Vector2(randf_range(-JARAK_ACAK_X, JARAK_ACAK_X), OFFSET_ATAS + randf_range(-8.0, 8.0))
	munculkan(adegan, target.global_position + geser, teks, warna)


static func munculkan(induk: Node, posisi_dunia: Vector2, teks: String, warna: Color = WARNA_UANG) -> void:
	var label := TeksMelayang.new()
	label.text = teks
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(LEBAR, 0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # jangan sampai menyerap klik
	label.z_index = 100
	label.add_theme_font_size_override("font_size", UKURAN_FONT)
	label.add_theme_color_override("font_color", warna)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_constant_override("outline_size", UKURAN_OUTLINE)

	induk.add_child(label)
	label.global_position = posisi_dunia - Vector2(LEBAR / 2.0, 0.0)

	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - JARAK_MELAYANG, DURASI_MELAYANG) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.4).set_delay(DURASI_MELAYANG - 0.4)
	tween.chain().tween_callback(label.queue_free)


# 20000 -> "Rp20.000"
static func format_rupiah(jumlah: int) -> String:
	var angka: String = str(absi(jumlah))
	var hasil: String = ""
	var hitung: int = 0
	for i in range(angka.length() - 1, -1, -1):
		hasil = angka[i] + hasil
		hitung += 1
		if hitung % 3 == 0 and i != 0:
			hasil = "." + hasil
	return "Rp" + hasil
