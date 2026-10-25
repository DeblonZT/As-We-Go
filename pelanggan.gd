extends Node2D

signal pelanggan_pergi(node)

@onready var label_pesanan = $LabelPesanan
@onready var tombol_layani = $TombolLayani
@onready var timer_kesabaran = $TimerKesabaran
@onready var animasi = $AnimasiKarakter 

var target_posisi = Vector2.ZERO
var kecepatan = 100
var status = "JALAN"
var apakah_di_depan = false
var tipe_pelanggan = "arka"

# --- VARIABEL UNTUK RANDOM KARAKTER & PESANAN ---
var akhiran_npc: String = ""
var pesanan_item = "Cilok" # Default pesanan: "Cilok", "Es Teh", "Piscok"

var waypoint_antara: Vector2 = Vector2.ZERO
var sudah_lewat_waypoint: bool = false
var _target_antrean_akhir: Vector2 = Vector2.ZERO

func _ready():
	label_pesanan.hide()
	tombol_layani.hide()
	
	# Acak variasi karakter dari SpriteFrames pelanggan.tscn ("", "_2", "_3", "_4", "_5")
	var daftar_akhiran = ["", "_2", "_3", "_4", "_5"]
	akhiran_npc = daftar_akhiran[randi() % daftar_akhiran.size()]
	
	_mainkan_animasi("diam")
	
	# Acak menu pesanan berdasarkan hari dan resep yang terbuka
	var menu_tersedia = ["Cilok"]
	
	if Global.hari > 1:
		# Tambahkan Es Teh dan Piscok untuk hari ke-2 dan seterusnya
		# Idealnya dicek dari flag Cerita agar lebih aman
		if Cerita.has_method("punya_flag"):
			if Cerita.punya_flag("resep_es_teh_terbuka"):
				menu_tersedia.append("Es Teh")
			if Cerita.punya_flag("resep_piscok_terbuka"):
				menu_tersedia.append("Piscok")
		else:
			# Fallback jika Cerita tidak memiliki pengecekan flag yang sesuai
			menu_tersedia.append("Es Teh")
			menu_tersedia.append("Piscok")
			
	# Pastikan di hari ke-1 benar-benar hanya Cilok
	if Global.hari == 1:
		menu_tersedia = ["Cilok"]
		
	pesanan_item = menu_tersedia[randi() % menu_tersedia.size()]
	
	# Timer kesabaran 20 detik langsung berjalan sejak mulai ngantre
	if timer_kesabaran:
		timer_kesabaran.wait_time = 20.0
		timer_kesabaran.start()

func set_waypoint(pos_waypoint: Vector2):
	waypoint_antara = pos_waypoint
	sudah_lewat_waypoint = false

func _process(delta):
	if status == "JALAN":
		# 1. Jalan Horizontal (Sumbu X)
		if abs(position.x - target_posisi.x) > 1.0:
			position.x = move_toward(position.x, target_posisi.x, kecepatan * delta)
			
			if target_posisi.x > position.x:
				_mainkan_animasi("jalan_kanan")
			else:
				_mainkan_animasi("jalan_kiri")
				
		# 2. Jalan Vertikal (Sumbu Y)
		elif abs(position.y - target_posisi.y) > 1.0:
			position.y = move_toward(position.y, target_posisi.y, kecepatan * delta)
			
			if target_posisi.y > position.y:
				_mainkan_animasi("jalan_bawah")
			else:
				_mainkan_animasi("jalan_atas")
				
		# 3. Sampai di titik target
		else:
			position = target_posisi
			if waypoint_antara != Vector2.ZERO and not sudah_lewat_waypoint:
				sudah_lewat_waypoint = true
				target_posisi = _target_antrean_akhir
				status = "JALAN"
				return

			status = "NUNGGU"
			if tipe_pelanggan == "rani" and not apakah_di_depan:
				_mainkan_animasi("diam_kanan")
			else:
				_mainkan_animasi("diam")

			if apakah_di_depan:
				label_pesanan.text = "Pesan: 1 " + pesanan_item + "!"
				label_pesanan.show()
				if tipe_pelanggan != "rani":
					tombol_layani.show()
				else:
					tombol_layani.hide()
			else:
				label_pesanan.hide()
				tombol_layani.hide()

func _mainkan_animasi(nama_anim: String):
	if not (animasi and animasi.sprite_frames):
		return
	var nama_penuh = nama_anim + akhiran_npc
	if animasi.sprite_frames.has_animation(nama_penuh):
		animasi.play(nama_penuh)
	elif animasi.sprite_frames.has_animation(nama_anim):
		animasi.play(nama_anim)

func perbarui_target(koordinat_baru, urutan):
	apakah_di_depan = (urutan == 0)
	_target_antrean_akhir = koordinat_baru

	if waypoint_antara != Vector2.ZERO and not sudah_lewat_waypoint:
		target_posisi = waypoint_antara
	else:
		target_posisi = koordinat_baru

	if position != target_posisi:
		status = "JALAN"
		label_pesanan.hide()
		tombol_layani.hide()

func pergi():
	pelanggan_pergi.emit(self) 
	queue_free()

func _on_tombol_layani_pressed():
	if status != "NUNGGU": 
		return
		
	var sukses_layani: bool = false
	var harga_jual: int = 10000
	
	match pesanan_item:
		"Cilok":
			if Global.cilok_matang > 0:
				Global.cilok_matang -= 1
				harga_jual = 10000
				sukses_layani = true
		"Es Teh":
			if Global.es_teh_siap > 0:
				Global.es_teh_siap -= 1
				harga_jual = 8000
				sukses_layani = true
		"Piscok":
			if Global.piscok_matang > 0:
				Global.piscok_matang -= 1
				harga_jual = 12000
				sukses_layani = true
				
	if sukses_layani:
		Global.uang += harga_jual
		if Global.has_method("ubah_reputasi"):
			Global.ubah_reputasi(2)
		else:
			Global.reputasi_pelanggan += 2
		TeksMelayang.munculkan_di_sekitar(self, "+" + TeksMelayang.format_rupiah(harga_jual), Color(0.2, 1.0, 0.2))
		pergi()
	else:
		label_pesanan.text = pesanan_item + " belum ada!"
		if Global.has_method("ubah_reputasi"):
			Global.ubah_reputasi(-3)
		else:
			Global.reputasi_pelanggan -= 3

func _on_timer_kesabaran_timeout():
	if Global.has_method("ubah_reputasi"):
		Global.ubah_reputasi(-5)
	else:
		Global.reputasi_pelanggan -= 5
	pergi()
