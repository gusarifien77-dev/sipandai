import { useEffect, useState } from 'react'
import type { FormEvent } from 'react'
import {
  BookOpen, CalendarDays, ClipboardCheck, FileText, GraduationCap,
  LayoutDashboard, LogOut, Menu, School, Settings, Sparkles, Users, X,
  ClipboardList, NotebookPen, BarChart3
} from 'lucide-react'
import type { User, Session } from '@supabase/supabase-js'
import { isSupabaseConfigured, supabase } from './lib/supabase'

type AccessState = 'loading' | 'signed_out' | 'checking' | 'admin' | 'denied' | 'error'

const menu = [
  { title: 'Dashboard', icon: LayoutDashboard, items: ['Ringkasan', 'Aktivitas Terbaru'] },
  { title: 'Data Sekolah', icon: School, items: ['Profil Sekolah', 'Guru', 'Peserta Didik', 'Kelas / Rombel'] },
  { title: 'Kurikulum', icon: BookOpen, items: ['Kurikulum', 'Mata Pelajaran', 'Capaian Pembelajaran'] },
  { title: 'Analisis CP', icon: Sparkles, items: ['Analisis CP', 'Tujuan Pembelajaran (TP)', 'Alur Tujuan Pembelajaran (ATP)'] },
  { title: 'Perencanaan', icon: CalendarDays, items: ['Kalender Pendidikan', 'Hari Efektif', 'Program Tahunan', 'Program Semester', 'Jadwal Pelajaran'] },
  { title: 'Pelaksanaan', icon: NotebookPen, items: ['Modul Ajar / RPP', 'Bahan Ajar', 'LKPD', 'KKTP', 'Jurnal Harian Guru'] },
  { title: 'Asesmen', icon: ClipboardCheck, items: ['Asesmen Diagnostik', 'Asesmen Formatif', 'Asesmen Sumatif', 'Bank Soal', 'Kisi-kisi', 'Kartu Soal'] },
  { title: 'Penilaian', icon: BarChart3, items: ['Input Nilai', 'Analisis Hasil Asesmen', 'Remedial', 'Pengayaan'] },
  { title: 'Laporan & Dokumen', icon: FileText, items: ['Dokumen Saya', 'Ekspor Word / PDF', 'Laporan Pembelajaran'] },
  { title: 'Pengaturan', icon: Settings, items: ['Akun', 'Pengguna & Hak Akses'] },
]

export default function App() {
  const [access, setAccess] = useState<AccessState>('loading')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)
  const [mobileOpen, setMobileOpen] = useState(false)
  const [active, setActive] = useState('Dashboard')

  async function verifyPlatformAdmin(user: User | null) {
    if (!user) {
      setEmail('')
      setAccess('signed_out')
      return
    }

    setEmail(user.email ?? '')
    setAccess('checking')

    if (!supabase) {
      setAccess('error')
      setError('Konfigurasi Supabase belum tersedia.')
      return
    }

    const { data, error: queryError } = await supabase
      .from('platform_admins')
      .select('user_id')
      .eq('user_id', user.id)
      .maybeSingle()

    if (queryError) {
      console.error('Pemeriksaan akses Super Admin gagal:', queryError)
      setAccess('error')
      setError('Hak akses belum dapat diverifikasi. Periksa koneksi dan kebijakan RLS Supabase.')
      return
    }

    if (!data) {
      setAccess('denied')
      return
    }

    setAccess('admin')
  }

  useEffect(() => {
    if (!supabase) {
      setAccess('signed_out')
      return
    }

    let activeEffect = true

    supabase.auth.getSession().then(({ data, error: sessionError }) => {
      if (!activeEffect) return
      if (sessionError) {
        setAccess('error')
        setError('Sesi login tidak dapat diperiksa. Silakan muat ulang halaman.')
        return
      }
      void verifyPlatformAdmin(data.session?.user ?? null)
    })

    const { data: listener } = supabase.auth.onAuthStateChange((_event, session: Session | null) => {
      // Jalankan pemeriksaan setelah callback auth selesai agar tidak menahan lock internal Auth.
      Promise.resolve().then(() => {
        if (activeEffect) void verifyPlatformAdmin(session?.user ?? null)
      })
    })

    return () => {
      activeEffect = false
      listener.subscription.unsubscribe()
    }
  }, [])

  async function signIn(e: FormEvent) {
    e.preventDefault()
    setError('')
    if (!supabase) {
      setError('Supabase belum dikonfigurasi. Isi file .env terlebih dahulu.')
      return
    }
    setBusy(true)
    const { error: signInError } = await supabase.auth.signInWithPassword({ email, password })
    if (signInError) setError(signInError.message)
    setBusy(false)
  }

  async function signOut() {
    await supabase?.auth.signOut()
    setPassword('')
    setError('')
    setAccess('signed_out')
  }

  if (access === 'loading' || access === 'checking') {
    return <main className="login-shell">
      <section className="login-card">
        <div className="brand-mark"><GraduationCap size={30} /></div>
        <div className="eyebrow">PLATFORM ADMINISTRASI PEMBELAJARAN</div>
        <h1>SIPANDAI</h1>
        <p className="muted">{access === 'loading' ? 'Memeriksa sesi...' : 'Memverifikasi hak akses Super Admin...'}</p>
      </section>
    </main>
  }

  if (access === 'signed_out' || access === 'denied' || access === 'error') {
    return <main className="login-shell">
      <section className="login-card">
        <div className="brand-mark"><GraduationCap size={30} /></div>
        <div className="eyebrow">PLATFORM ADMINISTRASI PEMBELAJARAN</div>
        <h1>SIPANDAI</h1>
        <p className="muted">Sistem Perencanaan dan Administrasi Pembelajaran Digital</p>
        {!isSupabaseConfigured && <div className="notice">Hubungkan proyek Supabase dengan mengisi file <code>.env</code> berdasarkan <code>.env.example</code>.</div>}
        {access === 'denied' && <div className="error">Akun berhasil login, tetapi belum memiliki hak akses Super Admin SIPANDAI. Silakan hubungi administrator platform.</div>}
        {access === 'error' && <div className="error">{error || 'Terjadi kesalahan saat memeriksa hak akses.'}</div>}
        {access === 'signed_out' && <form onSubmit={signIn}>
          <label>Email</label>
          <input type="email" value={email} onChange={e => setEmail(e.target.value)} placeholder="nama@email.com" required />
          <label>Kata sandi</label>
          <input type="password" value={password} onChange={e => setPassword(e.target.value)} placeholder="Masukkan kata sandi" required />
          {error && <div className="error">{error}</div>}
          <button className="primary full" disabled={!isSupabaseConfigured || busy}>{busy ? 'Memproses...' : 'Masuk ke SIPANDAI'}</button>
        </form>}
        {(access === 'denied' || access === 'error') && <button className="secondary full" onClick={signOut}>Keluar / Ganti Akun</button>}
        <p className="small muted">Akses dashboard Super Admin hanya diberikan kepada akun yang terdaftar di tabel platform_admins.</p>
      </section>
    </main>
  }

  return <div className="app-shell">
    {mobileOpen && <button className="scrim" aria-label="Tutup menu" onClick={() => setMobileOpen(false)} />}
    <aside className={`sidebar ${mobileOpen ? 'open' : ''}`}>
      <div className="sidebar-brand">
        <div className="brand-mark small-mark"><GraduationCap size={23}/></div>
        <div><strong>SIPANDAI</strong><span>Administrasi Pembelajaran</span></div>
        <button className="icon-btn mobile-close" onClick={() => setMobileOpen(false)}><X size={19}/></button>
      </div>
      <div className="workspace"><School size={17}/><span>Ruang Platform</span><b>▾</b></div>
      <nav>
        {menu.map(group => <div className="nav-group" key={group.title}>
          <button className={`nav-item ${active === group.title ? 'selected' : ''}`} onClick={() => { setActive(group.title); setMobileOpen(false) }}>
            <group.icon size={18}/><span>{group.title}</span>
          </button>
          {active === group.title && group.items.length > 0 && <div className="subnav">
            {group.items.map(item => <button key={item} onClick={() => { setActive(item); setMobileOpen(false) }}>{item}</button>)}
          </div>}
        </div>)}
      </nav>
      <div className="sidebar-foot"><span className="online-dot"/> Super Admin • SIPANDAI</div>
    </aside>

    <main className="main-area">
      <header className="topbar">
        <button className="icon-btn menu-toggle" onClick={() => setMobileOpen(true)}><Menu/></button>
        <div><span className="crumb">Ruang Platform /</span> <strong>{active}</strong></div>
        <div className="user-chip"><span className="avatar">{(email || 'G').slice(0,1).toUpperCase()}</span><span>{email}</span><button className="icon-btn" onClick={signOut} title="Keluar"><LogOut size={17}/></button></div>
      </header>

      <div className="content">
        <div className="welcome">
          <div><div className="eyebrow">SELAMAT DATANG, SUPER ADMIN</div><h2>Administrasi pembelajaran, lebih terarah.</h2><p className="muted">Kelola platform SIPANDAI dan siapkan layanan administrasi pembelajaran untuk banyak sekolah.</p></div>
          <div className="welcome-icon"><GraduationCap size={42}/></div>
        </div>

        <section className="stats">
          <article className="stat-card"><span className="stat-icon blue"><School/></span><div><small>Platform</small><strong>Multi-sekolah</strong><p>Pengelolaan terpusat</p></div></article>
          <article className="stat-card"><span className="stat-icon purple"><BookOpen/></span><div><small>Kurikulum</small><strong>CP → TP → ATP</strong><p>Alur sumber data utama</p></div></article>
          <article className="stat-card"><span className="stat-icon green"><ClipboardList/></span><div><small>Administrasi</small><strong>Terintegrasi</strong><p>Perencanaan sampai penilaian</p></div></article>
        </section>

        <section className="section-head"><div><h3>Mulai dari pengelolaan platform</h3><p className="muted">Tahap awal: siapkan data sekolah dan pengelola sekolah.</p></div></section>
        <section className="feature-grid">
          <article className="feature-card feature-primary"><div className="feature-icon"><School/></div><h3>Data Sekolah</h3><p>Menyiapkan identitas sekolah sebagai ruang data terpisah (tenant).</p><button className="primary" onClick={() => setActive('Data Sekolah')}>Buka Data Sekolah</button></article>
          <article className="feature-card"><div className="feature-icon pale"><Users/></div><h3>Pengelola Sekolah</h3><p>Menyiapkan akun dan peran school_admin, kepala sekolah, serta guru.</p><button className="secondary" onClick={() => setActive('Pengaturan')}>Lihat pengaturan</button></article>
          <article className="feature-card"><div className="feature-icon pale"><Sparkles/></div><h3>Fondasi Kurikulum</h3><p>Data CP menjadi sumber untuk analisis, TP, dan ATP.</p><button className="secondary" onClick={() => setActive('Analisis CP')}>Lihat modul</button></article>
          <article className="feature-card"><div className="feature-icon pale"><FileText/></div><h3>Dokumen Pembelajaran</h3><p>Persiapan dokumen pembelajaran yang terhubung dengan data sumber.</p><button className="secondary" onClick={() => setActive('Laporan & Dokumen')}>Lihat dokumen</button></article>
        </section>
        <div className="footer-note">SIPANDAI • Fondasi versi 0.2 • Akses dashboard dibatasi untuk Super Admin</div>
      </div>
    </main>
  </div>
}
