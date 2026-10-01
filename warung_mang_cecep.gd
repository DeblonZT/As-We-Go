extends CharacterBody2D

@onready var label_tombol = $LabelTombol
# Sesuaikan path panel_upgrade dengan struktur CanvasLayer milikmu
@onready var panel_upgrade = $"../CanvasUI/PanelUpgrade" 
@onready var btn_tutup = $"../CanvasUI/PanelUpgrade/BtnTutup"

# --- VARIABEL PERGERAKAN ---
var kecepatan = 40
var waktu_gerak = 0.0
var arah_gerak = Vector2.ZERO
var status_gerak = "DIAM"

# --- VARIABEL INTERAKSI ---
var bisa_interaksi = false

func _ready():
	label_tombol.hide()
	
	# Mencegah error jika panel_upgrade belum dibuat sepenuhnya
	if panel_upgrade:
		panel_upgrade.hide()
		btn_tutup.pressed.connect(_on_btn_tutup_pressed)

func _physics_process(delta):
	# 1. LOGIKA BERGERAK RANDOM (WANDERING AI)
	waktu_gerak -= delta
	if waktu_gerak <= 0:
		_acak_gerakan()
		
	if status_gerak == "JALAN":
		# Memberikan kecepatan dorongan ke arah yang terpilih
		velocity = arah_gerak * kecepatan
		# Fungsi ajaib Godot: Menggerakkan karakter dan otomatis berhenti jika menabrak tembok/objek
		move_and_slide() 
	else:
		velocity = Vector2.ZERO
		
	# 2. LOGIKA BUKA PANEL (TEKAN E)
	if bisa_interaksi and Input.is_physical_key_pressed(KEY_E):
		buka_panel()

func _acak_gerakan():
	# Reset timer untuk 2 sampai 4 detik ke depan
	waktu_gerak = randf_range(2.0, 4.0) 
	
	# Mengacak angka 0 sampai 4 untuk menentukan arah
	var angka_acak = randi() % 5 
	
	if angka_acak == 0:
		status_gerak = "JALAN"
		arah_gerak = Vector2(1, 0) # Jalan Kanan
	elif angka_acak == 1:
		status_gerak = "JALAN"
		arah_gerak = Vector2(-1, 0) # Jalan Kiri
	elif angka_acak == 2:
		status_gerak = "JALAN"
		arah_gerak = Vector2(0, 1) # Jalan Bawah
	elif angka_acak == 3:
		status_gerak = "JALAN"
		arah_gerak = Vector2(0, -1) # Jalan Atas
	else:
		status_gerak = "DIAM"

# --- FUNGSI PANEL & INTERAKSI ---
func buka_panel():
	if panel_upgrade and not panel_upgrade.visible:
		panel_upgrade.show()
		label_tombol.hide()

func _on_btn_tutup_pressed():
	if panel_upgrade:
		panel_upgrade.hide()
		label_tombol.show()

# Sinyal dari AreaInteraksi (Bukan dari MangCecep lagi)
func _on_area_interaksi_body_entered(body):
	if body.name == "Player":
		bisa_interaksi = true
		if not panel_upgrade.visible:
			label_tombol.show()

func _on_area_interaksi_body_exited(body):
	if body.name == "Player":
		bisa_interaksi = false
		label_tombol.hide()
		if panel_upgrade:
			panel_upgrade.hide() # Panel otomatis tutup jika ditinggal pergi
