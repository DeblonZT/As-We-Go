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
				{"speaker": "player", "text": "Aku pengin beli mainan yang di TV tadi, Mah. Harganya Rp800.000..."},
				{"speaker": "npc", "text": "Waduh, mahal banget, Ka. Mama cuma bisa bantu sedikit ya."},
				{"speaker": "npc", "text": "Ini Rp20.000. Disimpan baik-baik, jangan dihambur-hamburkan.", "aksi": "beri_uang_20000"},
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
				{"speaker": "player", "text": "Aku butuh uang buat beli mainan yang baru keluar, harganya Rp800.000."},
				{"speaker": "player", "text": "Mama cuma bisa kasih Rp20.000. Abang bisa kasih aku uang ngga?"},
				{"speaker": "npc", "text": "Waduhh, Abang aja belum gajian dek bulan ini hehe."},
				{"speaker": "npc", "text": "Tapi Abang tau cara buat gandain uang 20 ribu kamu itu, lho."},
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
				{"speaker": "npc", "text": "Cilok! Abang kenal Pak Iwan, dia nyewain booth. Sewanya Rp10.000 per hari."},
				{"speaker": "npc", "text": "Bahannya kamu beli di warung Mpok Wati, terus kamu masak, terus kamu jual ke pelanggan."},
				{"speaker": "player", "text": "Modalku cuma Rp20.000 nih, Bang..."},
				{"speaker": "npc", "text": "Makanya harus pinter ngatur. Untungnya kamu puterin lagi buat jadi modal."},
				{"speaker": "npc", "text": "Waktumu 10 hari ya, Ka. Targetmu Rp800.000. Bisa?"},
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
				{"speaker": "player", "text": "Berarti modalku sisa Rp10.000 dong, Bang."},
				{"speaker": "npc", "text": "Betul. Makanya hitung baik-baik, jangan asal keluar uang.", "aksi": "mulai_tutorial_booth"},
				{"speaker": "npc", "text": "Pak Iwan ada di sekitar desa. Cari dia ya, Abang tunggu kabar baiknya!"}
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

	# Cutscene: id bebas, tidak harus nama NPC
	"cutscene_hari_0": {
		0: {
			"start": [
				{"speaker": "npc", "text": "Dan sekarang, mainan edisi terbaru yang paling ditunggu-tunggu tahun ini!"},
				{"speaker": "npc", "text": "Hanya Rp800.000! Stok terbatas, jangan sampai kehabisan!"},
				{"speaker": "player", "text": "Woah... keren banget! Aku harus punya itu!"},
				{"speaker": "player", "text": "Tapi... uangku aja gak ada sepeser pun."},
				{"speaker": "player", "text": "Hmm, coba minta Mama aja deh."}
			]
		}
	}
}


static func ambil_dialog(id_npc: String, hari: int, sudah_bicara: bool = false) -> Dictionary:
	var data_npc: Dictionary = DIALOG_NPC.get(id_npc, {})
	if not sudah_bicara and data_npc.has(hari):
		return data_npc[hari]
	return data_npc.get("default", {})
