# SIPANDAI — Fondasi Aplikasi

**Sistem Perencanaan dan Administrasi Pembelajaran Digital** untuk MI/SD.

Paket ini adalah fondasi teknis awal, bukan aplikasi produksi yang sudah terhubung ke akun Supabase atau layanan AI.

## Isi paket
- `supabase/migrations/001_initial_schema.sql` — skema PostgreSQL multi-sekolah, role, tabel inti kurikulum, dan Row Level Security (RLS).
- `web/` — starter frontend React + Vite + TypeScript, halaman login, dashboard, navigasi responsif.
- `.env.example` — konfigurasi frontend.
- `docs/ARSITEKTUR.md` — keputusan arsitektur dan tahapan pengembangan.

## Prinsip keamanan
1. Setiap data milik sekolah membawa `school_id`.
2. Akses data sekolah dibatasi oleh PostgreSQL RLS, bukan sekadar menyembunyikan menu.
3. Peran sekolah: `school_admin`, `principal`, `teacher`.
4. Super Admin platform dikelola terpisah melalui tabel `platform_admins`.
5. Jangan pernah menaruh `service_role` key atau kunci API AI di frontend.
6. Gunakan HTTPS, backup database, dan MFA untuk akun pengelola saat deploy produksi.

## Menjalankan frontend
Persyaratan: Node.js 20+ dan npm.

```bash
cd web
cp .env.example .env
npm install
npm run dev
```

Isi `.env` dengan Project URL dan anon/publishable key dari Supabase.

## Menyiapkan Supabase
1. Buat proyek Supabase.
2. Buka SQL Editor.
3. Jalankan isi `supabase/migrations/001_initial_schema.sql`.
4. Di Authentication, aktifkan metode Email sesuai kebijakan sekolah.
5. Buat pengguna pertama melalui Supabase Auth.
6. Jadikan akun tersebut Super Admin dengan SQL berikut (ganti UUID):
   ```sql
   insert into public.platform_admins (user_id)
   values ('00000000-0000-0000-0000-000000000000');
   ```
7. Super Admin berikutnya dapat membuat sekolah dan menambahkan keanggotaan melalui dashboard admin yang akan dibangun pada tahap berikutnya.

**Catatan:** Pendaftaran mandiri sekolah belum dibuka pada starter ini. Untuk menjaga keamanan multi-tenant, sekolah dan keanggotaan awal sebaiknya dibuat melalui alur undangan/admin.

## Status
Fondasi awal: skema database dan kerangka UI. Belum termasuk:
- alur undangan dan manajemen sekolah lengkap,
- generator AI dan backend server-side,
- unggah/ekspor DOCX/PDF,
- audit log lengkap,
- pengujian penetrasi dan hardening produksi.

Lakukan review keamanan dan uji RLS sebelum menyimpan data siswa sungguhan.
