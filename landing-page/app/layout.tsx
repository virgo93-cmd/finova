import type { Metadata } from 'next';
import { Geist, Geist_Mono } from 'next/font/google';
import './globals.css';

const geistSans = Geist({ variable: '--font-geist-sans', subsets: ['latin'] });
const geistMono = Geist_Mono({ variable: '--font-geist-mono', subsets: ['latin'] });

export const metadata: Metadata = {
  metadataBase: new URL('https://finova.ailooma.biz.id'),
  title: 'Finova — Money Clarity. Everyday Momentum.',
  description: 'Track money, budgets, tasks, and habits in one calm, local-first Android app with multi-currency selection.',
  openGraph: { title: 'Finova — Money Clarity. Everyday Momentum.', description: 'Personal finance and daily productivity for Android, with multi-currency selection.', url: 'https://finova.ailooma.biz.id', siteName: 'Finova', images: [{ url: '/og.png', width: 1024, height: 500 }], locale: 'en_US', type: 'website' },
  twitter: { card: 'summary_large_image', title: 'Finova — Money Clarity. Everyday Momentum.', description: 'Personal finance and daily productivity for Android, with multi-currency selection.', images: ['/og.png'] },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body className={`${geistSans.variable} ${geistMono.variable}`}>{children}</body></html>;
}
