# Panduan Login Super Admin SIPANDAI (Fondasi v0.2)

## Yang berubah
- Login tetap menggunakan Supabase Auth `signInWithPassword`.
- Setelah login, aplikasi membaca `public.platform_admins` untuk memverifikasi UID.
- Dashboard hanya ditampilkan jika baris UID pengguna ditemukan.
- Pengguna yang berhasil login tetapi tidak terdaftar sebagai Super Admin tidak dapat melihat dashboard.

## Konfigurasi lokal
1. Masuk ke folder `sipandai-foundation/web`.
2. Salin `.env.example` menjadi `.env`.
3. Isi `VITE_SUPABASE_URL` dengan Project URL Supabase.
4. Isi `VITE_SUPABASE_ANON_KEY` dengan publishable/anon key dari proyek Supabase.
5. Jalankan `npm install`, lalu `npm run dev`.

Jangan pernah memasukkan `service_role` key ke file `.env` frontend atau ke kode browser.

## Batasan tahap ini
Ini adalah gerbang akses dashboard Super Admin pada sisi aplikasi. RLS database tetap menjadi pengaman utama. Belum ada modul CRUD sekolah, pengelolaan undangan, atau pengujian dua tenant. Sebelum produksi, uji login dengan akun Super Admin dan akun biasa yang tidak terdaftar sebagai Super Admin.
