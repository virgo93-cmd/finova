import type { Metadata } from 'next';
import { Geist, Geist_Mono } from 'next/font/google';
import './globals.css';

const geistSans = Geist({ variable: '--font-geist-sans', subsets: ['latin'] });
const geistMono = Geist_Mono({ variable: '--font-geist-mono', subsets: ['latin'] });

export const metadata: Metadata = {
  metadataBase: new URL('https://finova.ailooma.biz.id'),
  title: 'Finova — Keuangan Lebih Jelas. Hidup Lebih Terarah.',
  description: 'Catat keuangan, anggaran, tugas, dan kebiasaan dalam satu aplikasi Android yang tenang, privat, dan mendukung pilihan multi-mata uang.',
  icons: {
    icon: [{ url: '/brand/finova-icon.png', type: 'image/png' }],
    shortcut: '/brand/finova-icon.png',
    apple: '/brand/finova-icon.png',
  },
  openGraph: { title: 'Finova — Keuangan Lebih Jelas. Hidup Lebih Terarah.', description: 'Keuangan pribadi dan produktivitas harian untuk Android dengan pilihan multi-mata uang.', url: 'https://finova.ailooma.biz.id', siteName: 'Finova', images: [{ url: '/og.png', width: 1200, height: 768 }], locale: 'id_ID', type: 'website' },
  twitter: { card: 'summary_large_image', title: 'Finova — Keuangan Lebih Jelas. Hidup Lebih Terarah.', description: 'Keuangan pribadi dan produktivitas harian untuk Android dengan pilihan multi-mata uang.', images: ['/og.png'] },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="id"><body className={`${geistSans.variable} ${geistMono.variable}`}>{children}</body></html>;
}
