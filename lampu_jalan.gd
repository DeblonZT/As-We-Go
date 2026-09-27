extends PointLight2D
# Pasang script ini di tiap node PointLight2D lampu jalan.
# Bentuk kipas (celah di atas, melebar & melengkung di bawah) di-generate
# lewat kode saat game jalan. Titik runcing kipas SENGAJA ditaruh di tengah
# vertikal tekstur, karena Godot selalu menaruh titik tengah tekstur PointLight2D
# tepat di posisi node ini -> jadi titik runcingnya otomatis pas di bohlam lampu,
# dan seluruh kipas menjulur ke bawah saja (tidak nyasar ke atas tiang).

@export_range(32, 256, 8) var ukuran_tekstur: int = 160
@export_range(0.0, 0.5) var lebar_celah_atas: float = 0.10   # jarak dua "tanduk" di atas
@export_range(0.0, 0.9) var lebar_atas: float = 0.22          # lebar sisi atas kipas
@export_range(0.0, 1.0) var lebar_bawah: float = 0.80         # lebar sisi bawah kipas
@export_range(0.0, 0.45) var jarak_atas_dari_tengah: float = 0.04   # jarak titik atas dari TENGAH tekstur
@export_range(0.05, 0.5) var jarak_bawah_dari_tengah: float = 0.42  # jarak titik bawah dari TENGAH tekstur
@export_range(-0.2, 0.2) var lengkung_bawah: float = 0.06     # + = tengah-bawah nungging turun
@export var terangkan_ulang_saat_ready: bool = true

const SUPER_SAMPLE: int = 3  # 3x3 = 9 sub-titik per piksel, buat menghaluskan tepi


func _ready() -> void:
	if terangkan_ulang_saat_ready:
		texture = buat_tekstur()
	# Override filter tekstur jadi Linear khusus untuk node ini saja,
	# supaya cahaya halus walau project pakai Nearest filter (pixel art).
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func buat_tekstur() -> ImageTexture:
	var n := ukuran_tekstur
	var gambar := Image.create(n, n, false, Image.FORMAT_RGBA8)

	# Semua posisi Y dihitung relatif ke TENGAH tekstur (0.5), karena
	# node PointLight2D selalu berada tepat di tengah tekstur ini.
	var y_atas := 0.5 + jarak_atas_dari_tengah
	var y_bawah := 0.5 + jarak_bawah_dari_tengah

	var atas_kiri := Vector2(0.5 - lebar_celah_atas - lebar_atas, y_atas)
	var atas_kanan := Vector2(0.5 + lebar_celah_atas + lebar_atas, y_atas)
	var celah_kiri := Vector2(0.5 - lebar_celah_atas, y_atas - 0.03)
	var celah_kanan := Vector2(0.5 + lebar_celah_atas, y_atas - 0.03)
	var bawah_kiri := Vector2(0.5 - lebar_bawah, y_bawah)
	var bawah_kanan := Vector2(0.5 + lebar_bawah, y_bawah)
	var bawah_tengah := Vector2(0.5, y_bawah + lengkung_bawah)

	var titik_lengkung := _sampel_kurva(bawah_kiri, bawah_tengah, bawah_kanan, 12)

	var poligon: PackedVector2Array = []
	poligon.append(celah_kiri)
	poligon.append(atas_kiri)
	poligon.append_array(titik_lengkung)
	poligon.append(atas_kanan)
	poligon.append(celah_kanan)

	var poligon_piksel: PackedVector2Array = []
	for p in poligon:
		poligon_piksel.append(p * n)

	# Titik paling terang: sedikit di bawah ujung runcing (dekat sumber cahaya)
	var pusat_terang := Vector2(0.5, y_atas + 0.10) * n
	var jarak_maks := n * 0.75

	for y in range(n):
		for x in range(n):
			var total_alpha := 0.0
			for sy in range(SUPER_SAMPLE):
				for sx in range(SUPER_SAMPLE):
					var offset := Vector2(
						(float(sx) + 0.5) / SUPER_SAMPLE,
						(float(sy) + 0.5) / SUPER_SAMPLE
					)
					var titik := Vector2(x, y) + offset
					if Geometry2D.is_point_in_polygon(titik, poligon_piksel):
						var jarak := titik.distance_to(pusat_terang)
						var t := clampf(1.0 - (jarak / jarak_maks), 0.0, 1.0)
						total_alpha += ease(t, 1.8)
			var alpha_final := total_alpha / float(SUPER_SAMPLE * SUPER_SAMPLE)
			gambar.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha_final))

	return ImageTexture.create_from_image(gambar)


func _sampel_kurva(a: Vector2, kontrol: Vector2, b: Vector2, langkah: int) -> PackedVector2Array:
	var hasil: PackedVector2Array = []
	for i in range(langkah + 1):
		var t := float(i) / float(langkah)
		var titik := a.lerp(kontrol, t).lerp(kontrol.lerp(b, t), t)
		hasil.append(titik)
	return hasil
