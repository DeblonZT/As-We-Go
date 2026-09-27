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

# --- VARIABEL UNTUK RANDOM KARAKTER & PESANAN ---
var akhiran_npc: String = ""
var pesanan_item = "Cilok" # Default pesanan: "Cilok", "Es Teh", "Piscok"

func _ready():
	label_pesanan.hide()
	tombol_layani.hide()
	
	# Acak variasi karakter dari SpriteFrames pelanggan.tscn ("", "_2", "_3", "_4", "_5")
	var daftar_akhiran = ["", "_2", "_3", "_4", "_5"]
	akhiran_npc = daftar_akhiran[randi() % daftar_akhiran.size()]
	
	_mainkan_animasi("diam")
	
	# Acak menu pesanan (0: Cilok, 1: Es Teh, 2: Piscok)
	var acak_menu = randi() % 3
	match acak_menu:
		0: pesanan_item = "Cilok"
		1: pesanan_item = "Es Teh"
		2: pesanan_item = "Piscok"
	
	# Timer kesabaran 20 detik langsung berjalan sejak mulai ngantre
	if timer_kesabaran:
		timer_kesabaran.wait_time = 20.0
		timer_kesabaran.start()

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
			status = "NUNGGU"
			_mainkan_animasi("diam")

			if apakah_di_depan:
				label_pesanan.text = "Pesan: 1 " + pesanan_item + "!"
				label_pesanan.show()
				tombol_layani.show()
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
	target_posisi = koordinat_baru
	apakah_di_depan = (urutan == 0)

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
				harga_jual = 5000
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
