import type { Metadata, Viewport } from 'next';
import localFont from 'next/font/local';
import './globals.css';

// Bricolage Grotesque (display) and Instrument Sans (body) are vendored as
// woff2 in app/fonts (latin subset) and self-hosted by next/font/local: no
// runtime request, no build-time fetch.
const bricolage = localFont({
  src: [
    { path: './fonts/bricolage-grotesque-latin-600-normal.woff2', weight: '600', style: 'normal' },
    { path: './fonts/bricolage-grotesque-latin-700-normal.woff2', weight: '700', style: 'normal' },
    { path: './fonts/bricolage-grotesque-latin-800-normal.woff2', weight: '800', style: 'normal' },
  ],
  variable: '--font-bricolage',
  display: 'swap',
});
const instrument = localFont({
  src: [
    { path: './fonts/instrument-sans-latin-400-normal.woff2', weight: '400', style: 'normal' },
    { path: './fonts/instrument-sans-latin-500-normal.woff2', weight: '500', style: 'normal' },
    { path: './fonts/instrument-sans-latin-600-normal.woff2', weight: '600', style: 'normal' },
    { path: './fonts/instrument-sans-latin-700-normal.woff2', weight: '700', style: 'normal' },
  ],
  variable: '--font-instrument',
  display: 'swap',
});

const SITE_URL = process.env.NEXT_PUBLIC_SITE_URL || 'http://localhost:3000';

export const metadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  title: {
    default: 'Shakti: your people, one signal away',
    template: '%s | Shakti',
  },
  description:
    'Shakti is an Android personal safety network with local-first SOS, trusted-contact alerts, and a browser-based guardian tracker.',
  applicationName: 'Shakti',
  openGraph: {
    type: 'website',
    siteName: 'Shakti',
    locale: 'en_IN',
    title: 'Shakti: your people, one signal away',
    description:
      'Local-first SOS, trusted-contact alerts, and a browser-based guardian tracker.',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Shakti: your people, one signal away',
    description:
      'Local-first SOS, trusted-contact alerts, and a browser-based guardian tracker.',
  },
};

export const viewport: Viewport = {
  themeColor: '#101218',
  colorScheme: 'dark',
  width: 'device-width',
  initialScale: 1,
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${bricolage.variable} ${instrument.variable}`}>
      <body className="min-h-dvh antialiased">
        <a href="#main" className="skip-link">
          Skip to main content
        </a>
        {children}
      </body>
    </html>
  );
}
