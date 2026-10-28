# ADR 0001 — Kontrak bridge M0 (plugin ↔ SeqAnalyzer_Remote)

- Status: **Diusulkan** (menunggu review Live Integration Engineer + QA; keputusan G0 ada pada owner)
- Issue: BSKR-26
- Cakupan: transport, envelope, handshake, 4 perintah M0, preconditions BUILD, alternatif bila G0 gagal.
- Di luar cakupan M0: multi-song, Section/Cue Builder, tempo pre-roll 8 bar (ADR berikutnya, M1).

## 1. Konteks

Plugin VST tidak punya akses Live Object Model (LOM). Kontrol Ableton dipegang Remote Script `SeqAnalyzer_Remote` (Python, TCP `127.0.0.1:9128`). Kode saat ini (`remote/SeqAnalyzer_Remote/__init__.py`) hanya mengenal `ping` dan `build_one`, membalas `{"ok":bool,"result"|"error":str}` tanpa id, tanpa versi protokol, dan error berupa string bebas. Kontrak ini mengunci bentuk yang stabil agar plugin, Remote Script, dan mock test bisa dikerjakan paralel.

## 2. Keputusan

### 2.1 Transport
- TCP `127.0.0.1:9128`, **JSON satu objek per baris** (UTF-8, diakhiri `\n`). Satu request → satu response. Satu koneksi boleh mengirim banyak request berurutan (M0: klien boleh tetap membuka satu koneksi per request seperti sekarang; server wajib menerima keduanya).
- Batas ukuran baris: 16 KiB request (M0). Lebih dari itu → `REQUEST_TOO_LARGE`.
- Hanya bind `127.0.0.1` (jangan `0.0.0.0`/`localhost` ambigu IPv6). Request tanpa `\n` dalam 20 dtk → koneksi ditutup.
- Server memproses **satu request pada satu waktu** pada main thread Live (lihat architecture.md). Antrean penuh → `BUSY`.

### 2.2 Envelope

Request:
```json
{"v": 1, "id": "c3f1-0007", "action": "ping", "params": {}}
```
- `v` (int, wajib): versi protokol yang diminta klien.
- `id` (string, wajib, ≤64 char): dibuat klien, di-echo apa adanya.
- `action` (string, wajib): salah satu dari `ping`, `list_clips`, `build_one`, `read_clip_state`.
- `params` (objek, default `{}`).

Response sukses:
```json
{"v": 1, "id": "c3f1-0007", "ok": true, "result": { ... }}
```
Response gagal:
```json
{"v": 1, "id": "c3f1-0007", "ok": false,
 "error": {"code": "CLIP_MOVED", "message": "clip moved since Analyze; analyze again",
           "retryable": false, "details": {"expected_start": 64.0, "actual_start": 68.0}}}
```
- `error.code`: string enum **stabil** (bagian 4). `message` hanya untuk manusia, tidak boleh di-parse. `retryable` true hanya untuk `BUSY`, `TIMEOUT_MAIN_THREAD`, `LIVE_NOT_READY`.
- Jika baris tidak bisa di-parse sehingga `id` tidak diketahui: `id` = `null`, code `BAD_REQUEST`.
- Kompatibilitas mundur dari beta.1: request tanpa `v`/`id` dan `action` `ping`/`build_one` diperlakukan sebagai protokol 0 (response format lama) **hanya** sampai M0 lulus; setelah itu dihapus. (Opsi, bukan kewajiban — lihat pertanyaan terbuka T3.)

### 2.3 Handshake: `ping`
Klien wajib `ping` sebelum perintah lain pada tiap koneksi plugin baru dan setiap reconnect.

Request:
```json
{"v":1,"id":"1","action":"ping","params":{"client":"SeqAnalyzerVST","client_version":"0.9.0-dev","protocol_min":1,"protocol_max":1}}
```
Response:
```json
{"v":1,"id":"1","ok":true,"result":{
  "service":"SeqAnalyzer_Remote","script_version":"0.9.0-dev",
  "protocol_version":1,"live_version":"12.3.2",
  "session_id":"b1f0c0de-5a1e-4c1d-9a55-2f0d1f6e9a10",
  "song_id_hint":{"track_count":4,"is_playing":false},
  "capabilities":["list_clips","build_one","read_clip_state"]}}
```
- `protocol_version`: versi tertinggi yang server dan klien sama-sama dukung dalam rentang `[protocol_min, protocol_max]`. Tidak ada irisan → `PROTOCOL_MISMATCH` (details: `server_min`, `server_max`).
- `live_version`: dari `Live.Application.get_application().get_major_version()/get_minor_version()/get_bugfix_version()`. **Belum terbukti** tersedia dengan nama itu di 12.3.2 → Engineer harus verifikasi (T2); fallback `"unknown"`.
- `session_id`: UUID acak dibuat saat Remote Script dimuat (satu per proses Live, **bukan** per Live Set). Plugin menyimpannya; jika berubah antar request ia tahu Live di-restart dan semua `clip_ref` basi. Ini **bukan** identitas Live Set: untuk itu dipakai `song_id_hint` + validasi clip (bagian 3.3). Tidak ada API LOM yang andal untuk path/nama Set (belum terbukti) — jangan mengandalkannya.
- Setiap response `ok:true` selain `ping` membawa `session_id` di `result._session` agar klien mendeteksi perubahan tanpa ping ulang (opsional untuk M0; wajib M1).

### 2.4 Keamanan localhost (M0, minimal)
- Hanya loopback; tidak ada eksekusi kode arbitrer; `action` allow-list; `params` divalidasi tipe/rentang.
- Tidak ada autentikasi di M0 (risiko diterima: proses lokal lain bisa memanggil port). Mitigasi: BUILD butuh `clip_ref` valid dan semua precondition; tak ada aksi destruktif di luar clip target. Opsi hardening M1 (bukan M0): token acak yang ditulis Remote Script ke file di User Library berizin 0600 dan dikirim klien di `ping` (`params.token`) — trade-off: kompleksitas instalasi vs. melindungi dari proses lokal lain.
- Port bentrok (`EADDRINUSE`) harus dilaporkan lewat `log_message` dan tidak boleh membuat Live crash.

### 2.5 Retry
- Klien: timeout koneksi 2 dtk, timeout response 20 dtk (server menunggu main thread maks 15 dtk → `TIMEOUT_MAIN_THREAD`).
- `ping`, `list_clips`, `read_clip_state`: **idempoten**, boleh retry otomatis (maks 3, backoff 0,2/0,5/1 dtk) untuk `retryable:true` atau `ECONNREFUSED` (Remote Script belum aktif).
- `build_one`: **tidak boleh di-retry otomatis**. Setelah timeout/putus koneksi, klien wajib `read_clip_state` dulu dan menunjukkan hasil ke pengguna; baru pengguna memutuskan. Alasan: tanpa rollback, build ganda menambah marker.

## 3. Perintah M0

### 3.1 `list_clips`
Mengenumerasi clip audio Arrangement agar plugin memilih target dan membangun `clip_ref`. Read-only.

Params: `{"track_index": 0}` (opsional; tanpa ini semua track audio).
```json
{"v":1,"id":"2","action":"list_clips","params":{"track_index":0}}
```
```json
{"v":1,"id":"2","ok":true,"result":{"tracks":[
 {"track_index":0,"track_name":"Songs","clips":[
  {"clip_ref":{"track_index":0,"start":64.0,"name":"GJT"},
   "is_audio":true,"warping":true,"looping":false,
   "start_time":64.0,"end_time":584.0,"start_marker":0.0,"end_marker":520.0,
   "loop_start":0.0,"loop_end":520.0,
   "file_path":"/Users/x/Audio/GJT.wav","sample_rate":44100,"duration_s":208.0,
   "warp_marker_count":2}]}]}}
```
`clip_ref` = identitas yang di-echo pada `build_one`/`read_clip_state`; meniru pencocokan yang sudah ada (track_index + start_time ±0.02 + name). `file_path` boleh `null` jika LOM tak menyediakannya (belum terbukti, T2).
Error: `BAD_REQUEST`, `TRACK_NOT_FOUND`, `LIVE_NOT_READY`.

### 3.2 `build_one`
Membangun Warp map satu clip (perilaku = `warp_build.apply_clip` saat ini; tidak membuat sections/cues, tidak menulis tempo).

Params: `clip_ref`, `bpm` (20–999), `duration` (detik audio, ≥30, hasil Analyze), opsional `dry_run` (default false).
```json
{"v":1,"id":"3","action":"build_one","params":{
  "clip_ref":{"track_index":0,"start":64.0,"name":"GJT"},
  "bpm":150.0,"duration":208.0,"dry_run":false}}
```
```json
{"v":1,"id":"3","ok":true,"result":{
  "clip_ref":{"track_index":0,"start":64.0,"name":"GJT"},
  "bpm":150.0,"start":64.0,"end":584.0,"length_beats":520.0,
  "markers_added":3,"dry_run":false,
  "state_after":{ "...sama dengan result read_clip_state..." : null },
  "reminder":"Enable Lead manually AFTER BUILD."}}
```
- `dry_run:true` menjalankan seluruh validasi + `make_plan` dan mengembalikan `planned_markers` tanpa mengubah Live. Ini membuat kontrak bisa diuji tanpa menulis ke Set.
- Seluruh aksi dibungkus `begin_undo_step/end_undo_step`; tidak ada jaminan rollback atomik (belum diimplementasikan/diuji).
- `end` dari hasil bisa berubah satu tick Live kemudian (lihat build-beta1.md); karena itu verifikasi otoritatif adalah `read_clip_state`, bukan nilai balik.
Error: `PLAYBACK_ACTIVE`, `CLIP_NOT_FOUND`, `CLIP_AMBIGUOUS`, `CLIP_MOVED`, `AUDIO_CHANGED`, `NOT_AUDIO_CLIP`, `WARP_OFF`, `LOOP_ON`, `CLIP_TRIMMED`, `WARP_MAP_NOT_PRISTINE`, `FIRST_MARKER_NOT_ZERO`, `OVERLAPS_NEXT_CLIP`, `BAD_PARAMS`, `LIVE_API_ERROR`, `TIMEOUT_MAIN_THREAD`, `BUSY`.

### 3.3 `read_clip_state`
Membaca ulang keadaan clip; dipakai untuk verifikasi G0 setelah BUILD dan **setelah Live Set dibuka ulang**. Read-only; tidak mensyaratkan playback berhenti.

Params: `{"clip_ref": {...}}` (tanpa `bpm`/`duration`).
```json
{"v":1,"id":"4","action":"read_clip_state","params":{"clip_ref":{"track_index":0,"start":64.0,"name":"GJT"}}}
```
```json
{"v":1,"id":"4","ok":true,"result":{
  "clip_ref":{"track_index":0,"start":64.0,"name":"GJT"},
  "warping":true,"looping":false,
  "start_time":64.0,"end_time":584.0,
  "start_marker":0.0,"end_marker":520.0,"loop_start":0.0,"loop_end":520.0,
  "warp_markers":[{"sample_time":0.0,"beat_time":0.0},
                  {"sample_time":30.0,"beat_time":75.0},
                  {"sample_time":199.68,"beat_time":499.2},
                  {"sample_time":208.0,"beat_time":520.0}],
  "implied_bpm_segments":[150.0,150.0,150.0]}}
```
- `warp_markers` diurut `sample_time`; `implied_bpm_segments` = turunan antar marker (dihitung server, supaya verifikasi G0 tidak bergantung pada klien).
- Catatan: LOM menyimpan marker tersembunyi akhir (lihat live-integration.md); apakah muncul di `warp_markers` **belum terbukti**. Test G0 harus mencatat jumlah marker aktual sebelum/sesudah reopen.
Error: `CLIP_NOT_FOUND`, `CLIP_AMBIGUOUS`, `BAD_PARAMS`, `LIVE_NOT_READY`.

## 4. Preconditions penolakan BUILD dan kode error

Urutan evaluasi (cek murah/global dulu, semua sebelum mengubah apa pun):

| # | Precondition | Kode | Sumber saat ini |
|---|---|---|---|
| 1 | Params valid (tipe, bpm 20–999, duration ≥30) | `BAD_PARAMS` | `make_plan/_number` |
| 2 | Playback & record mati | `PLAYBACK_ACTIVE` | `song.is_playing/record_mode` |
| 3 | Track ada | `TRACK_NOT_FOUND` | cek `track_index` |
| 4 | Tepat 1 clip cocok (start ±0.02 + nama) | `CLIP_NOT_FOUND` (0) / `CLIP_AMBIGUOUS` (>1) | `_execute` |
| 5 | Clip audio | `NOT_AUDIO_CLIP` | `validate_clip` |
| 6 | Warp ON | `WARP_OFF` | `validate_clip` |
| 7 | Loop OFF | `LOOP_ON` | `validate_clip` |
| 8 | `start_time` tidak bergeser | `CLIP_MOVED` | `validate_clip` |
| 9 | Durasi audio = hasil Analyze (±0.06 s) | `AUDIO_CHANGED` | `validate_clip` |
| 10 | `start_marker`=0 dan `loop_start`=0 (tidak di-trim) | `CLIP_TRIMMED` | `validate_clip` |
| 11 | Warp marker **tepat 2** | `WARP_MAP_NOT_PRISTINE` | `validate_clip` |
| 12 | Marker pertama di 0 s / 0 beat | `FIRST_MARKER_NOT_ZERO` | `validate_clip` |
| 13 | Ujung hasil ≤ awal clip berikutnya (+0.02) | `OVERLAPS_NEXT_CLIP` | `make_plan` |

Catatan: "clip berubah" (butir 4/8/9) memakai identitas yang sama dengan Analyze; nama sama + start sama tapi isi diganti hanya tertangkap lewat durasi (butir 9). Ini kelemahan yang diketahui; hash isi tidak tersedia dari LOM (T4).

Kode lain: `BAD_REQUEST` (JSON rusak/`action` kosong), `UNKNOWN_ACTION`, `REQUEST_TOO_LARGE`, `PROTOCOL_MISMATCH`, `BUSY`, `LIVE_NOT_READY`, `TIMEOUT_MAIN_THREAD`, `LIVE_API_ERROR` (exception LOM tak terduga; `details.exception` berisi tipe, bukan traceback penuh), `INTERNAL`.

## 5. Bisa diuji tanpa Live
- Semua precondition di tabel adalah fungsi murni atas objek clip palsu (pola `test/test_warp_build.py`, `test/mock_live_test.js`). Engineer menyediakan `FakeSong/FakeClip` + dispatcher `handle(request_dict) -> response_dict` yang bebas socket; test kontrak memanggil dispatcher itu untuk tiap contoh JSON di atas.
- Test kontrak minimum: satu kasus sukses + satu kasus per kode error per perintah; `id` selalu di-echo; `ping` dengan rentang protokol tak beririsan → `PROTOCOL_MISMATCH`.
- Yang **tidak** bisa dibuktikan mock: perilaku `add_warp_marker`, `loop_end`, `end_marker`, penyimpanan setelah reopen — hanya G0 di Live nyata.

## 6. Terbukti vs belum (rujukan bukti)

| Klaim | Status | Bukti |
|---|---|---|
| Warp marker bisa dibuat dari Python (`Live.Clip.WarpMarker`), loop_end/end_marker diatur, playback OK, reopen dicek | **Teramati di eksperimen**, bukan integrasi produk | `docs/vst3-controller-architecture.md` § "Existing vs not yet proven" (Eksperimen 10B–14, Live 12.3.2 macOS); test CI `445eeb9` hanya fake clip |
| Logika plan/validasi benar terhadap fake clip | Terbukti (unit) | `test/test_warp_build.py` |
| Bridge TCP dari plugin/klien ke Remote Script berfungsi | **Belum** | uji beta.1: `ECONNREFUSED 127.0.0.1:9128` (script belum terpasang); tidak ada bukti sukses |
| Map warp bertahan setelah Set dibuka ulang | **Belum** (inti G0) | — |
| `read_clip_state` dapat membaca `warp_markers`, `file_path`, versi Live | **Belum diverifikasi** | LOM docs; harus dicek di Live 12.3.2 (T2) |
| Marker akhir tersembunyi muncul/tidak di `warp_markers` | **Belum** | live-integration.md hanya menyebut perilaku Max |
| Status Lead dapat dibaca/di-set via API | **Tidak** (diingatkan manual) | docs/vst3-controller-architecture.md |
| Handshake, id, error code stabil, `dry_run`, `list_clips`, `read_clip_state` | **Belum ada di kode** (kontrak ini) | `__init__.py` hanya `ping`/`build_one` |

## 7. Alternatif bila G0 gagal (opsi, TIDAK diputuskan — keputusan owner)

"G0 gagal" = BUILD tidak bisa dijalankan dari Remote Script (bridge/Live API), atau hasil tidak benar/tidak bertahan setelah reopen.

**Opsi A — Ekspor MIDI.** Plugin/engine menulis file MIDI standar: track tempo map (tempo event tiap lagu) + marker/teks section dan cue. Pengguna drag-drop ke Arrangement.
- (+) Tidak butuh LOM; format standar; mudah diuji otomatis; tempo map Live dibaca saat import MIDI.
- (−) Live memperlakukan tempo dari MIDI hanya lewat dialog import (perilaku perlu diverifikasi, belum terbukti); lagu audio tetap di-warp manual; langkah manual lebih banyak; kehilangan verifikasi otomatis.

**Opsi B — Ekspor WAV/stem + file rencana.** Engine merender WAV guide cue (suara nama section + hitungan) dengan jeda sesuai plan, plus JSON/CSV posisi dan BPM; pengguna menaruh dan men-warp sendiri.
- (+) Bekerja di DAW mana pun; tak bergantung API Live.
- (−) Paling manual; rawan salah posisi; tidak ada verifikasi; cue harus dirender ulang tiap perubahan plan.

**Opsi C — Hibrida/ditunda.** Tetap Remote Script, tetapi turunkan cakupan: hanya `read_clip_state` + `list_clips` (read-only) + panduan manual untuk menulis, sambil menyelidiki penyebab kegagalan (mis. fallback ke Max for Live hanya sebagai jembatan).
- (+) Menjaga investasi bridge; memberi data diagnosis.
- (−) Tidak memenuhi G0 secara langsung; Max for Live bertentangan dengan tujuan produk tanpa Max (docs/vst3-controller-architecture.md).

Rekomendasi arsitek bila G0 gagal karena **bridge** (bukan karena Warp API): perbaiki instalasi/port dulu — bukan alternatif ekspor. Alternatif A/B relevan bila **penulisan Warp/persistensi** terbukti tidak mungkin di Python.

## 8. Pertanyaan terbuka (untuk Live Integration Engineer)
- T1: apakah antrean `update_display` cukup cepat/dipanggil selama Live idle? (frekuensi ~tiap 100 ms diasumsikan, belum diukur)
- T2: ketersediaan `live_version`, `clip.file_path`, `clip.warp_markers` di 12.3.2.
- T3: pertahankan kompatibilitas protokol 0 atau langsung 1?
- T4: adakah cara mendeteksi isi audio berubah selain durasi (mis. `file_path` + mtime)?

## 9. Konsekuensi
Engineer `remote/` mengimplementasikan dispatcher + kode error ini; QA menulis test kontrak dari contoh JSON; plugin boleh dikembangkan terhadap mock setelah G0, bukan sebelum. Perubahan kontrak → ADR baru atau revisi ADR ini dengan menaikkan `protocol_version`.
