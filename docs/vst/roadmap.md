# Roadmap Seq Analyzer VST

Alur pengguna: ANALYZE (read-only) -> REVIEW -> BUILD -> aktifkan LEAD manual -> VERIFY.
Gate diputuskan owner (Baskara) langsung di Ableton Live 12; agent tidak mengubah status gate.

| Milestone | Isi | Gate |
|---|---|---|
| M0 Bridge terbukti | Remote Script `SeqAnalyzer_Remote` (TCP 127.0.0.1:9128, JSON per baris): `ping`, `list_clips`, `build_one`, `read_clip_state`; kontrak + ADR; panduan instal; test offline | **G0**: BUILD 1 lagu sukses dari Remote Script, dan benar setelah Live Set disimpan lalu dibuka ulang |
| M1 Controller lengkap | Multi-lagu; Section Builder + Cue Builder di Python (clip SECTIONS/GUIDE CUES); tempo 8 bar sebelum lagu; pengingat Lead manual | **G1**: 3 lagu benar setelah Lead diaktifkan |
| M2 Core + VST3 JUCE | Plugin JUCE (VST3 + AU) di `plugin/`, integrasi engine, klien bridge | **G2**: plugin memicu ANALYZE/BUILD end-to-end di Live |
| M3 UX polish | Alur REVIEW, status/error yang jelas, pengaturan lead bars & count-in | **G3**: owner menilai alur layak pakai ibadah/latihan |
| M4 Release 1.0 | Packaging, dokumentasi, rilis | **G4**: owner menyetujui rilis 1.0 |

## Stage M0
1. Architect: kontrak bridge + ADR `docs/adr/0001-bridge-protocol-m0.md`.
2. Live Integration (bridge + panduan instal) dan QA (rencana uji, test offline, checklist G0).
3. Gate G0 oleh owner di Ableton.

Plugin Core/UI/Analysis tidak dikerjakan sebelum G0 lolos.

## Terbukti vs belum (Live 12.3.2, macOS)
- Terbukti (eksperimen): deteksi BPM engine; warp marker via `Live.Clip.WarpMarker`; perpanjang clip lewat `loop_end` lalu `end_marker` (loop OFF); Song Tempo automation via Lead manual.
- Belum terbukti: BUILD satu klik lewat bridge (uji beta.1 ECONNREFUSED karena Remote Script belum terpasang); pembuatan clip SECTIONS/GUIDE CUES dari Python; tempo pre-roll 8 bar; persistensi 5 warp marker setelah reopen; multi-lagu.

## Risiko terbuka
- Status Lead tidak bisa dibaca/ditulis API; hanya bisa diingatkan.
- Jeda antar lagu kembali ke 120 BPM.
- Warp builder baru menangani BPM stabil, tanpa trim, downbeat di detik 0, 2 warp marker.
- Semua uji pada copy / Live Set sekali pakai.

## Jika G0 gagal
Arah alternatif (mis. ekspor MIDI/WAV) diputuskan owner; opsi dan trade-off ditulis Architect di ADR.
