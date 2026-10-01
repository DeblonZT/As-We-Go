class_name DataDialog
extends RefCounted

# Struktur: id_npc -> hari -> dialog_tree
# Hari 0 = malam prolog sebelum hari pertama.
# "default" dipakai kalau hari itu tidak ada dialog khusus,
# atau dialog khusus hari itu sudah pernah dibicarakan.
# Key opsional per baris: "nama" (override nama), "choices", dan "aksi"
# ("aksi" dijalankan lewat Cerita.jalankan_aksi saat baris itu tampil).

const DIALOG_NPC = {
	"mama": {
		0: {
			"start": [
				{"speaker": "player", "text": "Mah... Mama hari ini cantik banget deh."},
				{"speaker": "npc", "text": "Hehe, tumben muji Mama. Ada maunya ya?"},
				{"speaker": "player", "text": "Ih Mama tau aja. Padahal Mama tuh Mama terbaik sedunia!"},
				{"speaker": "npc", "text": "Sudah, langsung bilang aja. Kamu mau apa, Arka?"},
				{"speaker": "player", "text": "Aku pengin beli mainan GUNDAM, Mah. Harganya Rp800.000..."},
				{"speaker": "npc", "text": "Waduh, mahal banget, Ka. Mama cuma bisa bantu sedikit ya."},
				{"speaker": "npc", "text": "Ini Rp50.000. Disimpan baik-baik, jangan dihambur-hamburkan.", "aksi": "beri_uang_50000"},
				{"speaker": "player", "text": "Makasih, Mah! Aku coba tanya Bang Pandu dulu deh."}
			]
		},
		"default": {
			"start": [
				{"speaker": "npc", "text": "Ada apa Arka? Kamu sepertinya terlihat murung."},
				{"speaker": "player", "text": "Gak papa kok Mah, cuma capek aja."},
				{"speaker": "npc", "text": "Mau Mama buatkan teh hangat?", "choices": [
					{"text": "Boleh banget Mah, makasih!", "next": "terima_teh"},
					{"text": "Nggak usah deh Mah, aku mau istirahat aja", "next": "tolak_teh"}
				]}
			],
			"terima_teh": [
				{"speaker": "npc", "text": "Oke, tunggu sebentar ya!"},
				{"speaker": "player", "text": "Makasih Mah!"}
			],
			"tolak_teh": [
				{"speaker": "npc", "text": "Oke, istirahat yang cukup ya sayang."}
			]
		}
	},

	"pandu": {
		0: {
			"start": [
				{"speaker": "player", "text": "Bang Pandu, aku boleh minta tolong ngga?"},
				{"speaker": "npc", "text": "Minta tolong apa, Arka?"},
				{"speaker": "player", "text": "Aku butuh uang buat beli GUNDAM yang baru keluar, harganya Rp800.000 dan 5 hari lagi sudah tidak dijual."},
				{"speaker": "player", "text": "Mama cuma bisa kasih Rp50.000. Abang bisa kasih aku uang ngga?"},
				{"speaker": "npc", "text": "Waduhh, Abang aja belum gajian dek bulan ini hehe."},
				{"speaker": "npc", "text": "Tapi Abang tau cara buat gandain uang 50 ribu kamu itu, lho."},
				{"speaker": "player", "text": "Hah? Digandain? Gimana caranya, Bang?"},
				{"speaker": "npc", "text": "Ada syaratnya: kamu harus mau ngelakuin apa yang Abang bilang. Caranya rahasia dulu.", "choices": [
					{"text": "Oke Bang, aku mau!", "next": "terima"},
					{"text": "Gandain uang? Konyol banget, Bang.", "next": "tolak"}
				]}
			],
			"terima": [
				{"speaker": "player", "text": "Oke Bang, aku mau! Ayo kasih tau caranya!"},
				{"speaker": "npc", "text": "Hahaha, oke oke. Caranya adalah... BERJUALAN!", "aksi": "terima_tawaran_pandu"},
				{"speaker": "player", "text": "Jualan? Jualan apa, Bang?"},
				{"speaker": "npc", "text": "Makanan! Abang kenal Pak Iwan, dia nyewain booth. Sewanya Rp10.000 per hari."},
				{"speaker": "npc", "text": "Bahannya kamu beli di warung Mpok Wati, terus kamu masak, terus kamu jual ke pelanggan."},
				{"speaker": "player", "text": "Modalku cuma Rp50.000 nih, Bang..."},
				{"speaker": "npc", "text": "Makanya harus pinter ngatur. Untungnya kamu puterin lagi buat jadi modal."},
				{"speaker": "npc", "text": "Waktumu 5 hari ya, Ka. Targetmu Rp800.000. Bisa?"},
				{"speaker": "player", "text": "Sepuluh hari... oke Bang, aku coba!"},
				{"speaker": "npc", "text": "Mantap. Udah malam nih, tidur dulu. Besok pagi kita mulai."}
			],
			"tolak": [
				{"speaker": "player", "text": "Gandain uang? Konyol banget, Bang. Mana ada yang begitu."},
				{"speaker": "npc", "text": "Yaudah kalo gak percaya. Berarti Abang gak jadi kasih tau ya."},
				{"speaker": "player", "text": "Iya deh, Bang...", "aksi": "ending_gagal"}
			]
		},
		1: {
			"start": [
				{"speaker": "npc", "text": "Pagi, Ka! Semangat banget mukamu Hahaha."},
				{"speaker": "player", "text": "Siap, Bang! Aku mau mulai jualan hari ini!"},
				{"speaker": "npc", "text": "Bagus! Langkah pertama: sewa booth dulu ke Pak Iwan. Sewanya Rp10.000 per hari."},
				{"speaker": "player", "text": "Berarti modalku sisa Rp40.000 dong, Bang."},
				{"speaker": "npc", "text": "Betul. Makanya hitung baik-baik, jangan asal keluar uang.", "aksi": "mulai_tutorial_booth"},
				{"speaker": "npc", "text": "Pak Iwan ada di sekitar desa. Cari dia ya, Rumahnya berwarna coklat di jalan 3!"},
				{"speaker": "npc", "text": " Abang tunggu kabar baiknya!"}
			]
		},
		2: {
			"start": [
				{"speaker": "npc", "text": "Gimana jualan kemarin? Sekarang coba beli bahan ke Mpok Wati."}
			]
		},
		"default": {
			"start": [
				{"speaker": "npc", "text": "Semangat jualannya, Ka!"}
			]
		}
	},
	
	"pak_iwan": {
		"default": {"start": [
			{"speaker": "npc", "text": "Booth-nya jaga baik-baik ya, Nak."}
		]}
	},
	"mpok_wati": {
		"default": {"start": [
			{"speaker": "npc", "text": "Belanja lagi, Ka? Silakan dipilih bahannya."}
		]}
	},
	"mang_cecep": {
		"default": {"start": [
			{"speaker": "npc", "text": "Kalau ada yang rusak, bilang aja ke Mamang."}
		]}
	},
	"rani": {
		"default": {"start": [
			{"speaker": "npc", "text": "Aku tunggu di sini ya, Ka."}
		]}
	},

	# Cutscene: id bebas, tidak harus nama NPC
	"cutscene_hari_0": {
		0: {
			"start": [
				{"speaker": "npc", "text": "Dan sekarang, GUNDAM edisi terbaru yang paling ditunggu-tunggu tahun ini!"},
				{"speaker": "npc", "text": "Hanya Rp800.000! Stok terbatas, hanya sampai tanggal xx, jangan sampai kehabisan!"},
				{"speaker": "player", "text": "Woah... keren banget! Aku harus punya itu!"},
				{"speaker": "player", "text": "Tapi tunggu dulu, HAH 5 hari lagi!?, uangku aja gak ada sepeser pun."},
				{"speaker": "player", "text": "Hmm, coba minta Mama aja deh."}
			]
		}
	}
}

# Dialog NPC yang bergantung pada objektif aktif. Kunci dalam = id objektif.
# Dipilih oleh Cerita.pilih_dialog().
const DIALOG_TAHAP = {
	"pak_iwan": {
		"sewa_booth": {"start": [
			{"speaker": "player", "text": "Permisi, Pak Iwan..."},
			{"speaker": "npc", "text": "Oh, kamu Arka? Adiknya Pandu? Tadi dia sudah cerita kalau kamu mau jualan."},
			{"speaker": "npc", "text": "Booth Bapak boleh kamu sewa. Rp10.000 per hari, bayar di depan ya."},
			{"speaker": "player", "text": "Baik, Pak. Ini uangnya."},
			{"speaker": "npc", "text": "Terima kasih. Sudah lama nggak dipakai, jadi kamu cek sendiri kondisinya. Semangat, Nak!", "aksi": "sewa_booth_berhasil"},
			{"speaker": "player", "text": "Makasih, Pak!"}
		]}
	},
	"mpok_wati": {
		"beli_bahan": {"start": [
			{"speaker": "player", "text": "Permisi, Mpok. Aku mau beli bahan buat jualan."},
			{"speaker": "npc", "text": "Oh, Arka! Jadi beneran mau jualan? Hebat kamu, masih kecil sudah berani usaha."},
			{"speaker": "npc", "text": "Silakan lihat-lihat dulu. Harganya tetap, nggak Mpok mainin."}
		]}
	},
	"mang_cecep": {
		"temui_mang_cecep": {"start": [
			{"speaker": "player", "text": "Permisi, Mang Cecep. Aku Arka, adiknya Bang Pandu."},
			{"speaker": "npc", "text": "Oh iya, Mamang kenal Pandu. Ada apa, Ka?"},
			{"speaker": "player", "text": "Aku nyewa booth Pak Iwan buat jualan, tapi kompor sama mejanya rusak, Mang."},
			{"speaker": "npc", "text": "Waduh. Booth itu memang lama nggak dipakai. Ini, pakai obeng Mamang."},
			{"speaker": "npc", "text": "Kencangkan baut-bautnya, harusnya bisa dipakai lagi.", "aksi": "beri_obeng"},
			{"speaker": "player", "text": "Makasih banyak, Mang!"}
		]}
	},
	"pandu": {
		"curhat_pandu": {"start": [
			{"speaker": "player", "text": "Bang, aku mau cerita sebentar..."},
			{"speaker": "npc", "text": "Kenapa, Ka? Mukamu kusut banget."},
			{"speaker": "player", "text": "Jualan sendirian capek banget, Bang. Belanja, masak, layanin pelanggan, semuanya aku sendiri."},
			{"speaker": "npc", "text": "Hahaha, wajar. Makanya pengusaha butuh tim."},
			{"speaker": "npc", "text": "Coba ajak temanmu buat bantuin. Tapi jangan minta gratisan, kasih imbalan uang ya.", "aksi": "saran_pandu_diterima"},
			{"speaker": "player", "text": "Bener juga. Nanti aku hubungi temanku lewat HP pas keluar rumah, Bang."}
		]}
	},
	"rani": {
		"jemput_rani": {"start": [
			{"speaker": "npc", "text": "Nah, akhirnya dateng juga. Aku udah nunggu dari tadi lho."},
			{"speaker": "player", "text": "Maaf ya, Ran. Yuk kita ke booth!"},
			{"speaker": "npc", "text": "Inget ya, upahnya Rp20.000. Jangan lupa!"},
			{"speaker": "player", "text": "Tenang, pasti kubayar. Ayo berangkat!", "aksi": "rani_bergabung"}
		]}
	},
}

# Adegan non-NPC: telepon (gambar HP) dan monolog di booth.
const DIALOG_ADEGAN = {
	"telepon_belanja": {"start": [
		{"speaker": "player", "text": "Halo Bang, Booth nya sudah ku sewa bang!."},
		{"speaker": "npc", "text": "Sudah beres nyewa booth-nya?"},
		{"speaker": "player", "text": "Sudah, Bang! Barusan bayar ke Pak Iwan."},
		{"speaker": "npc", "text": "Mantap. Sekarang kamu butuh bahan. Belanja ke warung Mpok Wati di Jalan 2 ya."},
		{"speaker": "player", "text": "Siap, Bang!"},
		{"speaker": "npc", "text": "Belanjanya secukupnya aja, jangan boros.", "aksi": "buka_objektif_belanja"}
	]},
	"telepon_ke_booth": {"start": [
		{"speaker": "npc", "text": "Ka, sudah selesai belanja? Bagus."},
		{"speaker": "npc", "text": "Sekarang ke booth-mu di Jalan 3, cek dulu kondisinya.", "aksi": "ke_booth"},
		{"speaker": "player", "text": "Oke, Bang. Aku ke sana sekarang."}
	]},
	"booth_rusak": {"start": [
		{"speaker": "player", "text": "Ini booth-nya... Kompornya nggak mau nyala.", "aksi": "booth_rusak_ditemukan"},
		{"speaker": "player", "text": "Mejanya juga goyang dan ada yang patah. Aku harus lapor ke Bang Pandu."}
	]},
	"telepon_booth_rusak": {"start": [
		{"speaker": "player", "text": "Halo Bang, gawat! Kompor sama meja booth-nya rusak, nggak bisa dipakai."},
		{"speaker": "npc", "text": "Waduh... Tenang dulu, Ka. Abang kenal Mang Cecep, warungnya di Jalan 5."},
		{"speaker": "npc", "text": "Temui dia dan jelaskan keadaannya. Mungkin dia bisa bantu.", "aksi": "cari_mang_cecep"},
		{"speaker": "player", "text": "Oke, Bang. Aku ke sana."}
	]},
	"telepon_booth_selesai": {"start": [
		{"speaker": "player", "text": "Bang, kompor sama mejanya sudah kuperbaiki!"},
		{"speaker": "npc", "text": "Hebat! Berarti tinggal jualan. Ingat, targetmu Rp800.000 dalam 5 hari.", "aksi": "mulai_berjualan"},
		{"speaker": "player", "text": "Siap, Bang! Aku mulai sekarang!"}
	]},
		"keluhan_hari_3": {"start": [
		{"speaker": "player", "text": "Hoaaam... badanku pegal semua."},
		{"speaker": "player", "text": "Kemarin jualan sendirian, beli bahan, masak, layanin pelanggan, semuanya sendiri."},
		{"speaker": "player", "text": "Kalau begini terus aku bisa tumbang. Aku butuh bantuan..."},
		{"speaker": "player", "text": "Coba cerita ke Bang Pandu ah.", "aksi": "keluhan_hari_3_selesai"}
	]},
	"telepon_rani": {"start": [
		{"speaker": "player", "text": "Halo, Ran? Ini Arka."},
		{"speaker": "npc", "text": "Oh, Arka. Ada apa pagi-pagi begini?"},
		{"speaker": "player", "text": "Aku lagi jualan dan kewalahan sendirian. Bantuin aku dong!"},
		{"speaker": "npc", "text": "Hah? Ogah ah, capek. Aku mau santai hari ini."},
		{"speaker": "player", "text": "Ayolah Ran, sebentar aja..."},
		{"speaker": "npc", "text": "Nggak mau, Ka."},
		{"speaker": "player", "text": "Aku kasih upah deh, Rp20.000. Gimana?"},
		{"speaker": "npc", "text": "Dua puluh ribu? ...Hmm. Oke deh, tapi beneran ya dibayar!"},
		{"speaker": "player", "text": "Beneran! Aku jemput kamu ke Jalan 4 sekarang."},
		{"speaker": "npc", "text": "Oke, aku tunggu di sana.", "aksi": "rani_setuju"}
	]},
}

static func ambil_dialog(id_npc: String, hari: int, sudah_bicara: bool = false) -> Dictionary:
	var data_npc: Dictionary = DIALOG_NPC.get(id_npc, {})
	if not sudah_bicara and data_npc.has(hari):
		return data_npc[hari]
	return data_npc.get("default", {})
