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

# --- VARIABEL BARU UNTUK RANDOM KARAKTER ---
var tipe_npc = "1_" 

func _ready():
	label_pesanan.hide()
	tombol_layani.hide()
	
	# Mengacak angka 1 atau 2 setiap kali pelanggan baru dipanggil
	var angka_acak = randi() % 3 + 1 
	tipe_npc = str(angka_acak) + "_" # Hasilnya jadi "1_" atau "2_"
	
	# Mainkan animasi diam sesuai tipe yang terpilih
	animasi.play(tipe_npc + "diam")

func _process(delta):
	if status == "JALAN":
		# 1. Jalan Horizontal (Sumbu X) mengikuti jalan tanah utama
		if abs(position.x - target_posisi.x) > 1.0:
			position.x = move_toward(position.x, target_posisi.x, kecepatan * delta)
			
			if target_posisi.x > position.x:
				animasi.play(tipe_npc + "jalan_kanan")
			else:
				animasi.play(tipe_npc + "jalan_kiri")
				
		# 2. Jika X sudah sejajar dengan antrean meja, Jalan Vertikal (Sumbu Y)
		elif abs(position.y - target_posisi.y) > 1.0:
			position.y = move_toward(position.y, target_posisi.y, kecepatan * delta)
			
			if target_posisi.y > position.y:
				animasi.play(tipe_npc + "jalan_bawah")
			else:
				animasi.play(tipe_npc + "jalan_atas")
				
		# 3. Sampai di titik target dengan presisi
		else:
			position = target_posisi
			status = "NUNGGU"
			animasi.play(tipe_npc + "diam")

			if apakah_di_depan:
				label_pesanan.text = "Pesan: 1 Cilok!"
				label_pesanan.show()
				tombol_layani.show()

				if timer_kesabaran.is_stopped():
					timer_kesabaran.start()
			else:
				label_pesanan.hide()
				tombol_layani.hide()

# Tambahkan parameter 'urutan' di dalam kurung
func perbarui_target(koordinat_baru, urutan):
	target_posisi = koordinat_baru
	apakah_di_depan = (urutan == 0) # Otomatis True jika dia urutan pertama (ke-0)

	if position != target_posisi:
		status = "JALAN"
		label_pesanan.hide()
		tombol_layani.hide()
		timer_kesabaran.stop() # Kesabaran tidak berkurang kalau masih ngantre

func pergi():
	pelanggan_pergi.emit(self) 
	queue_free()

func _on_tombol_layani_pressed():
	if status != "NUNGGU": 
		return
		
	if Global.cilok_matang > 0:
		Global.cilok_matang -= 1
		Global.uang += 10000
		pergi() 
	else:
		label_pesanan.text = "Cilok belum matang!"

func _on_timer_kesabaran_timeout():
	Global.reputasi_pelanggan -= 5
	pergi()
