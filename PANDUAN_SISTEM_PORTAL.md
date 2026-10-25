# PANDUAN LENGKAP SISTEM PORTAL & TELEPORTASI KOORDINAT (GODOT 4)
*Game: AS WE GO (Arka)*

Dokumen ini adalah panduan lengkap mengenai cara kerja sistem portal, penyebab masalah sebelumnya, serta tutorial langkah demi langkah saat kamu ingin menambahkan scene atau portal baru di masa depan agar koordinat player tidak salah lagi.

---

## 1. Konsep Utama: Bagaimana Portal Bekerja?

Teleportasi antar-scene membutuhkan **2 komponen utama**:

```
[SCENE ASAL]                                            [SCENE TUJUAN]
Portal (Area2D)                                         Script Root Scene (Node2D)
  - scene_tujuan: "res://map_3.tscn"                     - Menangkap target_spawn_id
  - id_pintu_keluar: "portal_a3"                         - Mencocokkan dengan Marker2D
		│                                                       │
		▼                                                       ▼
TransitionScreen.transition_to(scene_tujuan, spawn_id) ──► Tempatkan Player di Marker2D
```

1. **Scene Asal (Portal)**:
   - Portal mendeteksi player masuk (tekan tombol E atau otomatis).
   - Portal memanggil: `TransitionScreen.transition_to(scene_tujuan, id_pintu_keluar)`.
   - Di sini, `id_pintu_keluar` adalah **nama/ID titik kedatangan di scene tujuan**, BUKAN nama portal saat ini.

2. **Scene Tujuan (Penerima)**:
   - Saat scene baru terbuka, script root scene (misal: `map_2.gd`, `map_3.gd`, `koncet.gd`) akan membaca:
	 `TransitionScreen.target_spawn_id`.
   - Menggunakan perintah `match TransitionScreen.target_spawn_id:`, scene akan memindahkan player (`player.global_position`) ke Marker2D / titik berhenti yang sesuai.

---

## 2. Mengapa Kemarin Player Tidak Berpindah Koordinat?

Kemarin ada 3 kesalahan fatal yang menyebabkan player diam di tempat:

1. **`target_spawn_id` Terhapus di Tengah Jalan**:
   - Di `house_interact.gd`, kodenya memanggil:
	 `TransitionScreen.transition_to(scene_tujuan)` tanpa menyertakan argumen kedua.
	 Akibatnya, fungsi di `transition_screen.gd` menganggap spawn ID kosong `""`, sehingga ID pintu terhapus.
2. **Mencari Node yang Tidak Ada (Salah Alamat Map)**:
   - Di `map_2.gd`, saat menangkap ID `"map2"`, skrip malah memanggil `$Portal_A3` dan `$TitikTujuan_A3`.
   - Padahal node `$Portal_A3` **hanya ada di `map_3.tscn`**! Di `map_2.tscn` node tersebut adalah `null`.
   - Karena `aktif_house` bernilai `null`, kondisi `if aktif_house and aktif_titik:` menjadi **gagal/false**, sehingga posisi player tidak pernah dipindahkan sama sekali.
3. **Copy-Paste Script Antar Map**:
   - Skrip `map_3.gd` merupakan salinan mentah dari `map_2.gd` yang masih mencari node-node milik Map 2.
4. **Scene Tanpa Script Root**:
   - Scene `rumah_2.tscn` (lantai 2) dan `warung_mpok_wati.tscn` sebelumnya tidak memiliki script root untuk memposisikan player saat datang.

---

## 3. Tutorial: Cara Menambah Portal Baru (Anti-Salah)

Ikuti 4 langkah mudah ini setiap kali kamu ingin membuat portal baru:

### Langkah 1: Tentukan Scene & ID Spawn Tujuan
Tentukan dari mana mau ke mana. Contoh:
- Dari: `map_2.tscn`
- Mau ke: `map_4.tscn`
- Kita beri nama ID kedatangannya: `"portal_dari_map2"`

### Langkah 2: Buat Marker2D di Scene Tujuan (`map_4.tscn`)
1. Buka scene tujuan (`map_4.tscn`).
2. Buat node **Marker2D**, beri nama yang jelas, misalnya: `TitikBerhenti_DariMap2`.
3. Pindahkan Marker2D tersebut ke koordinat tempat player seharusnya muncul (misal: di pinggir jalan/pintu).
4. (Opsional) Buat satu Marker2D lagi untuk arah melangkah keluar, misal `TitikTujuan_DariMap2`.

### Langkah 3: Tambahkan Logika di Script Scene Tujuan (`map_4.gd`)
Di dalam fungsi `_ready()` pada script root scene tujuan:

```gdscript
@onready var player = $Player
@onready var titik_dari_map2 = $TitikBerhenti_DariMap2
@onready var tujuan_dari_map2 = $TitikTujuan_DariMap2

func _ready() -> void:
	if not player:
		return

	var pos_awal = Vector2.ZERO
	var pos_tujuan = Vector2.ZERO

	match TransitionScreen.target_spawn_id:
		"portal_dari_map2":
			pos_awal = titik_dari_map2.global_position
			pos_tujuan = tujuan_dari_map2.global_position
		_:
			# Default kalau spawn ID tidak dikenali
			pos_awal = titik_dari_map2.global_position
			pos_tujuan = pos_awal

	player.global_position = pos_awal
	if player.has_method("atur_arah_menghadap"):
		player.atur_arah_menghadap("bawah")
	if player.has_method("jalan_ke_titik") and pos_tujuan != pos_awal:
		player.jalan_ke_titik(pos_tujuan)
		await player.sampai_tujuan

	player.aktifkan_kontrol()
```

### Langkah 4: Pasang Portal di Scene Asal (`map_2.tscn`)
1. Buka `map_2.tscn`.
2. Buat node `Area2D` (atau duplicate portal yang sudah ada).
3. Pasang script `res://portal.gd` (atau script portal turunan).
4. Di panel **Inspector** sebelah kanan, cukup isi 2 variabel:
   - **Scene Tujuan**: `res://map_4.tscn`
   - **Id Pintu Keluar**: `portal_dari_map2` *(harus sama persis dengan yang ditulis di match Scene Tujuan)*
5. Selesai! Saat dites, player akan langsung muncul tepat di `TitikBerhenti_DariMap2`.

---

## 4. Tabel Referensi Portal & Spawn ID Game Saat Ini

Gunakan tabel ini sebagai acuan saat mengedit atau mengecek game kamu:

| Scene Asal | Node Portal | Scene Tujuan | ID Pintu Keluar (Spawn ID) | Titik Muncul di Tujuan |
|---|---|---|---|---|
| **rumah.tscn** | `Portal` (pintu) | `res://node_2d.tscn` | `"rumah"` / `"keluar"` | Depan Pintu Rumah Arka |
| **rumah.tscn** | `Portal2` (tangga) | `res://rumah_2.tscn` | `"tangga"` / `"lantai_2"` | Depan Tangga Lantai 2 |
| **rumah_2.tscn** | `Portal` (tangga) | `res://rumah.tscn` | `"lantai_2"` | Depan Tangga Lantai 1 |
| **node_2d.tscn** | `HouseInteract` | `res://rumah.tscn` | `"keluar"` | Depan Pintu Dalam Rumah |
| **node_2d.tscn** | `Portal` (bawah) | `res://map_2.tscn` | `"portal_a"` | Portal A (Kiri Atas Map 2) |
| **map_2.tscn** | `Portal_A` | `res://node_2d.tscn` | `"portal_map2"` | Portal Bawah (Luar Rumah) |
| **map_2.tscn** | `Portal_B` (kanan atas) | `res://map_3.tscn` | `"portal_a3"` | Portal A3 (Kiri Atas Map 3) |
| **map_2.tscn** | `Portal_B2` (kanan bawah) | `res://map_3.tscn` | `"portal_b3"` | Portal B3 (Kiri Bawah Map 3) |
| **map_2.tscn** | `Portal_C` (kiri bawah) | `res://map_4.tscn` | `"map4"` / `"portal_c"` | Map 4 Jalur A (Kiri) |
| **map_2.tscn** | `Portal_C2` (kanan bawah) | `res://map_4.tscn` | `"map44"` / `"portal_c2"` | Map 4 Jalur B (Kanan) |
| **map_2.tscn** | `HouseInteract2` | `res://warung_mpok_wati.tscn`| `"warung_mw"` | Depan Warung Mpok Wati |
| **map_3.tscn** | `Portal_A3` (kiri atas) | `res://map_2.tscn` | `"portal_b"` | Portal B (Kanan Atas Map 2) |
| **map_3.tscn** | `Portal_B3` (kiri bawah)| `res://map_2.tscn` | `"portal_b2"` | Portal B2 (Kanan Bawah Map 2) |
| **map_3.tscn** | `Portal_C3` (kanan bawah)| `res://map_5.tscn` | `"map5"` / `"portal_c3"` | Map 5 Jalur Atas (Titik B) |
| **map_3.tscn** | `HouseInteract2` | `res://warung_pak_iwan.tscn`| `"warungPI"` | Depan Warung Pak Iwan |
| **map_4.tscn** | `Portal_A` (atas kiri) | `res://map_2.tscn` | `"map4a_ke_map2"` | Map 2 Portal C (Kiri Bawah) |
| **map_4.tscn** | `Portal_B` (atas kanan) | `res://map_2.tscn` | `"map4b_ke_map2"` | Map 2 Portal C2 (Kanan Bawah) |
| **map_4.tscn** | `Portal_C` (kanan) | `res://map_5.tscn` | `"map4c_ke_map5"` | Map 5 Jalur Kiri (Titik A) |
| **map_5.tscn** | `Portal_A` (kiri) | `res://map_4.tscn` | `"map5_ke_map4"` | Map 4 Jalur Kanan (Titik Dari Map 5) |
| **map_5.tscn** | `Portal_B` (atas) | `res://map_3.tscn` | `"map5_ke_map3"` | Map 3 Jalur Kanan Bawah (Portal C3) |
| **map_5.tscn** | `HouseInteract2` | `res://warung_mang_cecep.tscn`| `"warungMC"` | Depan Warung Mang Cecep |
| **warung_mpok_wati.tscn** | `Portal` | `res://map_2.tscn` (otomatis asal) | `"warung_mw"` | Depan Warung Mpok Wati di Map 2 |
| **warung_pak_iwan.tscn** | `Portal` | `res://map_3.tscn` (otomatis asal) | `"warungPI"` | Depan Warung Pak Iwan di Map 3 |
| **warung_mang_cecep.tscn** | `Portal` | `res://map_5.tscn` (otomatis asal) | `"warungMC"` | Depan Warung Mang Cecep di Map 5 |

---

## 5. Fitur Khusus Interior (Kembali Otomatis ke Scene Asal)

Untuk scene warung dan interior:
- **Warung Mpok Wati** terhubung dengan **Map 2** (Spawn ID: `"warung_mw"`).
- **Warung Pak Iwan** terhubung dengan **Map 3** (Spawn ID: `"warungPI"`).
- **Warung Mang Cecep** terhubung dengan **Map 5** (Spawn ID: `"warungMC"`).

Portal keluar di setiap warung memiliki opsi:
`@export var kembali_ke_scene_asal: bool = true`
- Ketika opsi ini bernilai `true`, portal keluar secara otomatis membaca `Global.scene_sebelumnya`.
- Player akan selalu kembali ke map asal dan muncul tepat di depan pintu warung yang bersangkutan.

---

## 6. Template Script Map Baru (Bisa Di-Copy)

Jika nanti kamu membuat `map_4.gd`, `map_5.gd`, atau map baru lainnya, kamu bisa langsung copy template berikut:

```gdscript
extends Node2D

@onready var player = $Player

# Daftarkan marker spawn di scene ini
@onready var titik_spawn_1 = $TitikBerhenti_1
@onready var titik_tujuan_1 = $TitikTujuan_1

func _ready() -> void:
	if not player:
		return

	var pos_awal = Vector2.ZERO
	var pos_tujuan = Vector2.ZERO
	var arah_hadap = "bawah"

	match TransitionScreen.target_spawn_id:
		"portal_1":
			if titik_spawn_1: pos_awal = titik_spawn_1.global_position
			if titik_tujuan_1: pos_tujuan = titik_tujuan_1.global_position
			arah_hadap = "bawah"
		_:
			# Default jika tidak ada ID khusus
			if titik_spawn_1:
				pos_awal = titik_spawn_1.global_position
				pos_tujuan = pos_awal

	# Tempatkan player
	if pos_awal != Vector2.ZERO:
		player.global_position = pos_awal
	if player.has_method("atur_arah_menghadap"):
		player.atur_arah_menghadap(arah_hadap)
	if player.has_method("jalan_ke_titik") and pos_tujuan != pos_awal:
		player.jalan_ke_titik(pos_tujuan)
		if player.has_signal("sampai_tujuan"):
			await player.sampai_tujuan

	# Berikan kembali kendali ke player
	if player.has_method("aktifkan_kontrol"):
		player.aktifkan_kontrol()
	elif "bisa_gerak" in player:
		player.bisa_gerak = true
```
