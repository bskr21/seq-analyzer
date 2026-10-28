# Checklist manual G0 — satu lagu, Ableton Live 12.3.2

Gunakan **salinan** Live Set, bukan Set pertunjukan. Catat versi macOS, Live, paket BUILD, Remote Script, nama lagu, durasi audio, BPM hasil Analyze, `clip_ref`, dan waktu uji. G0 dinilai owner setelah bukti Live nyata terkumpul; test offline hanya memeriksa logika.

`docs/adr/0001-bridge-protocol-m0.md` adalah kontrak G0. Pada revisi awal, `remote/SeqAnalyzer_Remote/__init__.py` baru mengimplementasikan `ping` dan `build_one` format beta tanpa `v`/`id`; `list_clips` dan `read_clip_state` belum tersedia. Jalankan langkah kontrak di bawah setelah implementasinya masuk. Jangan menganggap pesan sukses beta sebagai bukti persistensi.

| Langkah owner | Hasil yang diharapkan | Bukti yang disimpan |
|---|---|---|
| 1. Duplikasi Live Set; buka **salinannya**. Catat lokasi clip sumber dan clip berikutnya. | Set asli tidak disentuh; ruang cukup hingga akhir hasil BUILD. | Nama Set salinan, screenshot Arrangement sebelum BUILD. |
| 2. Pasang Remote Script dengan `bash /path/to/extracted/install-build-bridge.command`; pastikan `SeqAnalyzer_Remote` tersalin ke folder Remote Scripts User Library. Tutup Live sepenuhnya lalu buka lagi. | Instalasi selesai tanpa error; Live memuat script saat start. | Output installer dan bagian relevan `Log.txt` Live. |
| 3. Live Settings → Link, Tempo & MIDI → Control Surface: `SeqAnalyzer_Remote`; Input/Output: None. | Control Surface terpilih dan log menyatakan bridge mendengar pada `127.0.0.1:9128`. | Screenshot Settings dan log start bridge. |
| 4. Kirim `ping` lewat klien BUILD/bridge; pada kontrak v1, periksa `ok:true`, `id` sama, `service:SeqAnalyzer_Remote`, `protocol_version:1`, dan kemampuan `build_one`/`read_clip_state`. | Respons diterima dari Remote Script yang berjalan pada sesi Live saat ini. | Request dan response JSON lengkap, tanpa data pribadi atau secret. |
| 5. Pilih **satu** clip audio Arrangement yang baru diimpor, BPM stabil, tanpa trim, downbeat pada detik 0, Warp ON, Loop OFF, Lead OFF, tepat dua Warp Marker awal. Berhentikan playback dan recording. ANALYZE, lalu catat BPM dan durasi. | BPM masuk akal; clip cocok dengan hasil Analyze; belum ada penulisan oleh BUILD. | Screenshot Clip View sebelum BUILD: semua marker, Warp/Loop/Lead, `start_marker`, `loop_start`, panjang clip (`start_time`/`end_time`). |
| 6. Jalankan `build_one`/BUILD **sekali** pada clip tersebut. Jangan retry otomatis saat timeout; baca keadaan clip lebih dahulu. | `ok:true`; respons menunjukkan BPM, `markers_added`, rencana akhir dan pengingat mengaktifkan Lead manual. Tidak ada clip lain yang berubah. | Request/response, status UI, log Live/Max yang relevan, screenshot Arrangement dan Clip View sesudah BUILD. |
| 7. Setelah Live selesai memperbarui clip, jalankan `read_clip_state` dengan `clip_ref` yang sama. Hitung BPM tiap segmen dari selisih beat marker / selisih detik × 60. | Warp ON, Loop OFF; marker tambahan sesuai plan; tiap segmen sesuai BPM Analyze; `end_time` dan `end_marker` menutup seluruh audio dan tidak menabrak clip berikutnya. Nilai `end` pada respons BUILD sendiri bukan verifikasi akhir karena tepi clip dapat berubah satu tick kemudian. | Response JSON, daftar marker sebelum/sesudah, BPM tiap segmen, panjang clip sebelum/sesudah, screenshot Clip View. Catat marker akhir tersembunyi bila terlihat di API. |
| 8. Simpan **salinan** Set. Tutup Set/Live, buka lagi salinan yang disimpan, pilih lagi Control Surface jika perlu, lakukan `ping` dan `read_clip_state` dengan `clip_ref` yang sama. | Clip tetap ada dan Warp map, BPM segmen, tepi clip, serta panjangnya sama dengan hasil sesudah BUILD. `session_id` boleh berubah setelah restart Live. | Log restart, request/response `ping` dan `read_clip_state` setelah reopen, screenshot Clip View dan Arrangement setelah reopen; perbandingan nilai sebelum/sesudah reopen. |
| 9. Sesudah verifikasi Warp, aktifkan Lead **manual** bila ingin memeriksa tempo automation. | Lead ditandai aktif di UI; hasilnya diperiksa visual. Status Lead tidak tersedia lewat API dan tidak menjadi klaim otomatis. | Screenshot UI Lead dan tempo envelope bila diuji. |

Contoh request kontrak v1 (satu objek JSON per baris ke TCP `127.0.0.1:9128`):

```json
{"v":1,"id":"g0-ping","action":"ping","params":{"client":"G0 manual QA","client_version":"1","protocol_min":1,"protocol_max":1}}
{"v":1,"id":"g0-state","action":"read_clip_state","params":{"clip_ref":{"track_index":0,"start":64.0,"name":"GJT"}}}
```

Ganti `track_index`, `start`, dan `name` dengan identitas dari `list_clips`/hasil Analyze. Gunakan koneksi terpisah atau kirim baris dan tunggu respons satu per satu sesuai implementasi bridge. Jangan menjalankan contoh identitas clip apa adanya pada Set lain.

## Diagnosis `ECONNREFUSED 127.0.0.1:9128`

| Temuan | Pemeriksaan | Tindakan dan bukti |
|---|---|---|
| Script belum terpasang atau jalur User Library salah | Periksa hasil installer dan keberadaan folder `SeqAnalyzer_Remote` di Remote Scripts User Library. | Pasang ulang dari paket build yang sama; simpan output installer dan path instalasi tanpa informasi sensitif. |
| Live belum di-restart setelah instalasi | Cek waktu proses Live dan instalasi. | Tutup Live sepenuhnya, buka lagi; simpan log start. |
| Control Surface belum dipilih | Periksa Settings → Link, Tempo & MIDI. | Pilih `SeqAnalyzer_Remote`, Input/Output None; screenshot Settings. |
| Script gagal dimuat atau port sudah dipakai | Cari `SeqAnalyzer`, traceback, atau `EADDRINUSE` di `Log.txt`; periksa proses yang mendengar pada port 9128. | Simpan potongan log dan identitas proses; laporkan ke Live Integration, jangan memaksa BUILD. |
| Klien mengarah ke host/port yang salah | Cocokkan konfigurasi klien dengan `127.0.0.1:9128` (IPv4). | Perbaiki alamat; simpan request `ping` dan hasilnya. |

`ECONNREFUSED` berarti sambungan TCP belum terbentuk, sehingga belum membuktikan apa pun tentang Warp API atau persistensi. Bila BUILD gagal setelah koneksi berhasil, simpan respons error, log, dan keadaan clip; jangan menekan BUILD berulang. Jika clip berubah sebagian, gunakan Undo atau tutup salinan Set tanpa menyimpan.
