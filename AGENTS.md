
# Proyek: Arka - WE AS GO (Godot 4.7.2, GDScript)
- Nama variabel/fungsi Bahasa Indonesia, snake_case. Gerak pakai velocity + move_and_slide(), bukan Tween.
- Area2D pakai body_entered/body_exited. Config per-instance lewat @export. Interaksi: Input.is_action_just_pressed("interaksi").
- Autoload: Global, Musik, TransitionScreen, TeksMelayang, DialogBox, Cerita (cerita.gd), MainUI.
- Data dialog: data_dialog.gd (DIALOG_NPC, DIALOG_TAHAP, DIALOG_ADEGAN). DIALOG_TAHAP didahulukan dari DIALOG_NPC, dan hanya tampil sekali per objektif lewat dialog_tahap_untuk().
- Uji tanpa F5: MODE_UJI / TAHAP_UJI di cerita.gd (F6 dari scene).

## Aturan kerja
- Baca hanya file yang relevan dengan tugas (gunakan grep), jangan scan seluruh project.
- Jangan refactor kode lain, jangan tulis ulang file utuh, jangan edit .tscn kecuali tugas memintanya.
- Kamu tidak bisa menjalankan Godot, jadi jangan coba run/test. Cukup pastikan sintaks dan nama node/fungsi konsisten dengan kode yang ada.
- Kalau ambigu, pilih opsi paling sederhana dan tulis asumsinya di ringkasan akhir.
- Ringkasan akhir: daftar file yang diubah + cara tes per TAHAP_UJI, maksimal 15 baris.