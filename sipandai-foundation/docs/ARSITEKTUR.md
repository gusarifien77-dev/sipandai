# Arsitektur SIPANDAI

## Nama dan model layanan
- Nama: SIPANDAI
- Kepanjangan: Sistem Perencanaan dan Administrasi Pembelajaran Digital
- Model: gratis, multi-sekolah, multi-pengguna.
- Platform: web responsif, disiapkan untuk PWA.

## Peran
- `platform_admin`: mengelola platform dan semua tenant; disimpan di `platform_admins`.
- `school_admin`: mengelola profil, tahun ajaran, guru, kelas, dan data sekolah.
- `principal`: melihat/memantau administrasi sekolah.
- `teacher`: mengelola perencanaan, pelaksanaan, dan penilaian sesuai penugasan.

## Alur data inti
CP -> Analisis CP -> TP -> ATP -> Prota/Promes -> Modul Ajar/RPP/LKPD/KKTP -> Asesmen -> Analisis hasil -> Remedial/Pengayaan.

Setiap dokumen turunan menyimpan referensi ke sumbernya. Generator tidak boleh mengarang CP resmi. Guru memilih atau memasukkan CP, memeriksa hasil analisis, lalu menyetujui TP/ATP sebelum dokumen berikutnya dibuat.

## Batas layanan gratis
Gratis adalah keputusan produk, bukan berarti biaya infrastruktur nol. Hosting, database, penyimpanan, dan pemakaian model AI dapat memiliki kuota/biaya. Tahap awal dapat memakai kuota gratis provider dan membatasi penggunaan AI secara wajar. Jangan menjanjikan layanan tanpa batas sebelum ada perhitungan biaya.

## Keputusan teknis
- Frontend: React + Vite + TypeScript.
- Backend/database/auth: Supabase (PostgreSQL + Auth + Storage).
- Keamanan tenant: PostgreSQL Row Level Security.
- AI: panggilan melalui backend/Edge Function, bukan browser.
- Dokumen: generator DOCX/PDF di backend.
- Hosting frontend: provider static hosting yang mendukung HTTPS.

## Peta menu
1. Beranda/Dashboard
2. Data Sekolah: profil, guru, siswa, rombel/kelas
3. Pengaturan Akademik: tahun ajaran, semester, kalender pendidikan
4. Kurikulum: kurikulum, mata pelajaran, fase, CP, elemen
5. Analisis CP: analisis, TP, ATP
6. Perencanaan: Prota, Promes, hari efektif, jadwal
7. Pelaksanaan: modul ajar/RPP, bahan ajar, LKPD, KKTP
8. Jurnal Guru: jurnal harian, refleksi
9. Asesmen: diagnostik, formatif, sumatif
10. Bank Soal: kisi-kisi, kartu soal, kunci, rubrik
11. Penilaian: input nilai, analisis hasil
12. Tindak Lanjut: remedial, pengayaan, asesmen ulang
13. Laporan dan Dokumen
14. Pengaturan Akun dan Hak Akses

## Tahapan setelah fondasi
A. Uji skema dan RLS dengan dua sekolah dan beberapa role.
B. Bangun manajemen tenant, undangan, profil, kelas, dan siswa.
C. Bangun CP -> Analisis -> TP -> ATP.
D. Bangun kalender, hari efektif, Prota, Promes, jadwal.
E. Bangun modul ajar, LKPD, KKTP, jurnal.
F. Bangun asesmen, analisis, remedial, pengayaan.
G. Bangun ekspor dokumen, audit log, backup, PWA, dan hardening.
