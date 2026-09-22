extends CanvasLayer

@onready var kotak = $KotakDialog
@onready var label = $KotakDialog/LabelDialog
@onready var nama_label = $KotakDialog/NamaSpeaker
@onready var portrait = $Portrait
@onready var click_area = $ClickArea
@onready var choices_box = $ChoicesBox

var posisi_kotak_akhir: Vector2
var posisi_kotak_awal: Vector2
var posisi_portrait_akhir: Vector2
var posisi_portrait_awal: Vector2

var dialog_tree: Dictionary = {}
var branch_sekarang: String = "start"
var index_dialog: int = 0
var sedang_dialog: bool = false
var sedang_animasi: bool = false
var bisa_lanjut: bool = false
var menampilkan_pilihan: bool = false
var hud_terlihat_sebelumnya: bool = false
var gambar_npc: Texture2D
var gambar_player: Texture2D
var nama_npc: String = "NPC"
var nama_player: String = "Kamu"


signal dialog_selesai

func _ready():
	visible = false
	
	label.add_theme_color_override("default_color", Color.BLACK)
	posisi_kotak_akhir = kotak.position
	posisi_portrait_akhir = portrait.position
	posisi_kotak_awal = posisi_kotak_akhir + Vector2(600, 0)
	posisi_portrait_awal = posisi_portrait_akhir + Vector2(0, 400)
	kotak.position = posisi_kotak_awal
	portrait.position = posisi_portrait_awal
	click_area.pressed.connect(_on_click_next)
	choices_box.visible = false

func mulai_dialog(tree: Dictionary, npc_texture: Texture2D = null, player_texture: Texture2D = null, nama_npc_baru: String = "NPC", nama_player_baru: String = "Kamu", branch_awal: String = "start"):
	if sedang_dialog: return
	dialog_tree = tree
	branch_sekarang = branch_awal
	index_dialog = 0
	gambar_npc = npc_texture
	gambar_player = player_texture
	nama_npc = nama_npc_baru
	nama_player = nama_player_baru
	sedang_dialog = true
	visible = true
	sembunyikan_hud()

	siapkan_portrait_awal()   # <- BARU: set texture yang benar SEBELUM slide jalan
	await animasi_masuk()
	tampilkan_baris()

func siapkan_portrait_awal():
	var baris_list: Array = dialog_tree.get(branch_sekarang, [])
	if baris_list.is_empty():
		portrait.visible = false
		return

	var baris_pertama = baris_list[0]
	var speaker = baris_pertama.get("speaker", "npc")

	if speaker == "npc":
		if gambar_npc:
			portrait.texture = gambar_npc
			portrait.visible = true
		else:
			portrait.visible = false
	else:
		if gambar_player:
			portrait.texture = gambar_player
			portrait.visible = true
		else:
			portrait.visible = false
			
func animasi_masuk():
	sedang_animasi = true
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(kotak, "position", posisi_kotak_akhir, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(portrait, "position", posisi_portrait_akhir, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween.finished
	sedang_animasi = false

func tampilkan_baris():
	choices_box.visible = false
	menampilkan_pilihan = false
	var baris_list: Array = dialog_tree.get(branch_sekarang, [])
	if index_dialog >= baris_list.size():
		tutup_dialog()
		return

	var baris = baris_list[index_dialog]
	var speaker = baris.get("speaker", "npc")
	label.text = baris.get("text", "")

	if baris.has("aksi"):
		Cerita.jalankan_aksi(baris["aksi"])
		
	if speaker == "npc":
		nama_label.text = baris.get("nama", nama_npc)
		if gambar_npc:
			portrait.texture = gambar_npc
			portrait.visible = true
		else:
			portrait.visible = false
	else:
		nama_label.text = baris.get("nama", nama_player)
		if gambar_player:
			portrait.texture = gambar_player
			portrait.visible = true
		else:
			portrait.visible = false

	if baris.has("choices"):
		bisa_lanjut = false
		tampilkan_pilihan(baris["choices"])
	else:
		bisa_lanjut = false
		await get_tree().create_timer(2.0).timeout
		bisa_lanjut = true

func tampilkan_pilihan(daftar_pilihan: Array):
	menampilkan_pilihan = true
	for child in choices_box.get_children():
		child.queue_free()
	for pilihan in daftar_pilihan:
		var tombol = Button.new()
		tombol.text = pilihan.get("text", "...")
		tombol.pressed.connect(_on_pilihan_dipilih.bind(pilihan.get("next", "")))
		choices_box.add_child(tombol)
	choices_box.visible = true

func _on_pilihan_dipilih(branch_tujuan: String):
	choices_box.visible = false
	menampilkan_pilihan = false
	branch_sekarang = branch_tujuan
	index_dialog = 0
	tampilkan_baris()

func _on_click_next():
	if not sedang_dialog or sedang_animasi or menampilkan_pilihan or not bisa_lanjut:
		return
	index_dialog += 1
	tampilkan_baris()

func tutup_dialog():
	sedang_animasi = true
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(kotak, "position", posisi_kotak_awal, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(portrait, "position", posisi_portrait_awal, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.finished
	visible = false
	tampilkan_hud()
	sedang_dialog = false
	sedang_animasi = false
	dialog_selesai.emit()
	
	
func _cari_hud():
	var hud = get_node_or_null("/root/MainUI")
	if hud == null:
		hud = get_node_or_null("/root/MainUi")
	return hud

func sembunyikan_hud():
	var hud = _cari_hud()
	if hud == null:
		return
	hud_terlihat_sebelumnya = hud.visible
	hud.visible = false

func tampilkan_hud():
	var hud = _cari_hud()
	if hud == null:
		return
	hud.visible = hud_terlihat_sebelumnya
