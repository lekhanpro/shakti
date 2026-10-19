import type { Metadata } from 'next';
import { TrackerView } from '@/components/tracker/TrackerView';

export const metadata: Metadata = {
  title: 'Guardian tracker',
  robots: { index: false, follow: false, nocache: true, googleBot: { index: false, follow: false } },
  referrer: 'no-referrer',
};

// The token is a secret; never pre-render or cache per-token pages.
export const dynamic = 'force-dynamic';

const TOKEN_RE = /^[A-Za-z0-9_-]{1,128}$/;

export default async function TrackPage({
  params,
  searchParams,
}: {
  params: Promise<{ token: string }>;
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}) {
  const [{ token }, query] = await Promise.all([params, searchParams]);
  const demo = token === 'demo' || query.demo === '1';
  // Anything outside the share-token alphabet cannot match; the RPC will return null for it.
  const safeToken = TOKEN_RE.test(token) ? token : 'invalid';
  return <TrackerView token={safeToken} demo={demo} />;
}
