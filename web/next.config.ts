import type { NextConfig } from 'next';

const isDev = process.env.NODE_ENV !== 'production';

/** Origin of the configured Supabase project, if any (for connect-src). */
function supabaseOrigins(): string[] {
  const raw = process.env.NEXT_PUBLIC_SUPABASE_URL;
  if (!raw) return [];
  try {
    const u = new URL(raw);
    const wss = `${u.protocol === 'http:' ? 'ws' : 'wss'}://${u.host}`;
    return [u.origin, wss];
  } catch {
    return [];
  }
}

const csp = [
  "default-src 'self'",
  // Next.js injects inline bootstrap scripts; nonces would force every page to render dynamically.
  `script-src 'self' 'unsafe-inline'${isDev ? " 'unsafe-eval'" : ''}`,
  // Leaflet positions tiles and markers with inline styles.
  "style-src 'self' 'unsafe-inline'",
  "img-src 'self' data: blob: https://tile.openstreetmap.org https://*.tile.openstreetmap.org https://threejs.org",
  "font-src 'self'",
  `connect-src 'self' ${supabaseOrigins().join(' ')}${isDev ? ' ws:' : ''}`.trim(),
  "frame-ancestors 'none'",
  "base-uri 'self'",
  "form-action 'self'",
  "object-src 'none'",
  ...(isDev ? [] : ['upgrade-insecure-requests']),
].join('; ');

const nextConfig: NextConfig = {
  reactStrictMode: true,
  poweredByHeader: false,
  // Keep prerendering within the memory available on development laptops.
  experimental: { cpus: 2 },
  // `next build`'s embedded TypeScript worker exhausts virtual memory in this
  // environment (VirtualAlloc abort, exit 134). Types are verified separately
  // with `npm run typecheck`, which passes.
  typescript: { ignoreBuildErrors: true },
  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          { key: 'Content-Security-Policy', value: csp },
          { key: 'X-Content-Type-Options', value: 'nosniff' },
          { key: 'X-Frame-Options', value: 'DENY' },
          { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
          { key: 'Permissions-Policy', value: 'camera=(), microphone=(), geolocation=(), interest-cohort=()' },
        ],
      },
      {
        // Tracker URLs carry a secret share token: never leak it via Referer, never index it.
        source: '/track/:path*',
        headers: [
          { key: 'Referrer-Policy', value: 'no-referrer' },
          { key: 'X-Robots-Tag', value: 'noindex, nofollow' },
          { key: 'Cache-Control', value: 'no-store' },
        ],
      },
    ];
  },
};

export default nextConfig;
