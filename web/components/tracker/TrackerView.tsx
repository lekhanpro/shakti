'use client';

import dynamic from 'next/dynamic';
import Link from 'next/link';
import {
  Battery,
  BatteryLow,
  Check,
  Clock,
  Copy,
  ExternalLink,
  LoaderCircle,
  MapPin,
  Phone,
  RefreshCw,
  Route,
  Settings,
  WifiOff,
} from 'lucide-react';
import { useEffect, useState } from 'react';
import { formatDistance, formatRelative, isStale } from '@/lib/format';
import { googleMapsUrl, totalDistance } from '@/lib/geo';
import { lastUpdateIso, latestBattery, type TrackData } from '@/lib/track';
import { StatusBanner } from './StatusBanner';
import { useTrack } from './useTrack';

const TrackerMap = dynamic(() => import('./TrackerMap'), {
  ssr: false,
  loading: () => <MapPlaceholder text="Loading map" />,
});

function MapPlaceholder({ text }: { text: string }) {
  return (
    <div className="grid size-full place-items-center bg-deep text-ink-2">
      <p className="flex items-center gap-2">
        <LoaderCircle className="size-5 motion-safe:animate-spin" aria-hidden="true" />
        {text}
      </p>
    </div>
  );
}

/** Re-renders every second so relative times stay honest. */
function useNow(intervalMs = 1000) {
  const [now, setNow] = useState(() => Date.now());
  useEffect(() => {
    const id = setInterval(() => setNow(Date.now()), intervalMs);
    return () => clearInterval(id);
  }, [intervalMs]);
  return now;
}

function Call112({ className = '' }: { className?: string }) {
  return (
    <a
      href="tel:112"
      className={`inline-flex min-h-14 items-center justify-center gap-2.5 rounded-2xl bg-sos px-6 text-lg font-bold text-white hover:bg-[#be123c] ${className}`}
    >
      <Phone className="size-5" aria-hidden="true" />
      Call 112
    </a>
  );
}

function Shell({ children, demo }: { children: React.ReactNode; demo?: boolean }) {
  return (
    <div className="flex min-h-dvh flex-col">
      <header className="flex items-center justify-between gap-3 border-b border-line/70 px-4 py-3 sm:px-6">
        <Link href="/" className="flex min-h-11 items-center gap-2 font-display font-semibold text-ink">
          <span className="grid size-7 place-items-center rounded-full bg-sos" aria-hidden="true">
            <span className="size-2 rounded-full bg-white" />
          </span>
          Shakti guardian view
        </Link>
        {demo ? (
          <span className="rounded-full border border-warn/60 px-3 py-1 text-sm font-bold text-warn-soft">
            Demo, simulated data
          </span>
        ) : null}
      </header>
      <main id="main" tabIndex={-1} className="flex flex-1 flex-col outline-none">
        {children}
      </main>
    </div>
  );
}

function Message({
  icon: Icon,
  title,
  children,
  action,
}: {
  icon: typeof WifiOff;
  title: string;
  children: React.ReactNode;
  action?: React.ReactNode;
}) {
  return (
    <div className="mx-auto flex w-full max-w-xl flex-1 flex-col justify-center px-5 py-16">
      <Icon className="size-10 text-ink-3" aria-hidden="true" />
      <h1 className="mt-5 font-display text-3xl font-bold text-ink">{title}</h1>
      <div className="mt-3 space-y-3 text-lg text-ink-2">{children}</div>
      <div className="mt-8 flex flex-col gap-3 sm:flex-row">
        {action}
        <Call112 />
      </div>
    </div>
  );
}

function CopyLinkButton() {
  const [copied, setCopied] = useState<'idle' | 'done' | 'failed'>('idle');
  useEffect(() => {
    if (copied === 'idle') return;
    const id = setTimeout(() => setCopied('idle'), 2500);
    return () => clearTimeout(id);
  }, [copied]);
  const onCopy = async () => {
    try {
      await navigator.clipboard.writeText(window.location.href);
      setCopied('done');
    } catch {
      setCopied('failed');
    }
  };
  return (
    <button
      type="button"
      onClick={onCopy}
      className="inline-flex min-h-12 items-center justify-center gap-2 rounded-2xl border border-line bg-deep px-4 font-semibold text-ink hover:bg-panel"
    >
      {copied === 'done' ? (
        <Check className="size-5 text-safe-soft" aria-hidden="true" />
      ) : (
        <Copy className="size-5" aria-hidden="true" />
      )}
      <span aria-live="polite">{copied === 'done' ? 'Link copied' : copied === 'failed' ? 'Copy failed' : 'Copy link'}</span>
    </button>
  );
}

function Stat({ icon: Icon, label, value, tone }: { icon: typeof Clock; label: string; value: string; tone?: 'warn' | 'bad' }) {
  const valueTone = tone === 'warn' ? 'text-warn-soft' : tone === 'bad' ? 'text-sos-soft' : 'text-ink';
  return (
    <div className="flex items-center gap-3 rounded-2xl bg-deep px-4 py-3">
      <Icon className={`size-5 shrink-0 ${tone ? valueTone : 'text-ink-3'}`} aria-hidden="true" />
      <div className="min-w-0">
        <dt className="text-sm text-ink-3">{label}</dt>
        <dd className={`truncate text-lg font-bold ${valueTone}`}>{value}</dd>
      </div>
    </div>
  );
}

function Dashboard({
  data,
  now,
  fetchedAt,
  error,
  onRetry,
}: {
  data: TrackData;
  now: number;
  fetchedAt: number | null;
  error: string | null;
  onRetry: () => void;
}) {
  const { incident, breadcrumbs } = data;
  const live = incident.status === 'ACTIVE' || incident.status === 'COUNTDOWN';
  const updated = lastUpdateIso(data);
  const stale = live && isStale(updated, now);
  const battery = latestBattery(data);
  const latest = breadcrumbs.at(-1);
  const distance = totalDistance(breadcrumbs);

  return (
    <div className="flex flex-1 flex-col gap-4 p-4 sm:p-6 lg:grid lg:grid-cols-[minmax(0,1fr)_400px] lg:grid-rows-[auto_1fr] lg:gap-5">
      <div className="lg:col-span-2">
        <StatusBanner
          status={incident.status}
          name={incident.first_name}
          createdAt={incident.created_at}
          updatedAt={incident.updated_at}
          now={now}
          triggerLabel={incident.trigger_label}
        />
      </div>

      {/* Map */}
      <section
        aria-label="Live map"
        className="relative h-[52vh] min-h-72 overflow-hidden rounded-[var(--radius-card)] border border-line lg:h-auto"
      >
        {latest ? (
          <TrackerMap points={breadcrumbs} live={live} name={incident.first_name} />
        ) : (
          <div className="grid size-full place-items-center bg-deep p-6 text-center text-ink-2">
            <p>
              <MapPin className="mx-auto mb-3 size-8 text-ink-3" aria-hidden="true" />
              No location yet. {incident.first_name}&rsquo;s phone may still be getting a GPS fix. The SMS they sent
              includes their last known location.
            </p>
          </div>
        )}
      </section>

      {/* Details and actions */}
      <section aria-labelledby="details-title" className="flex flex-col gap-4">
        <h2 id="details-title" className="sr-only">
          Details and actions
        </h2>

        <div
          className={`flex items-center gap-3 rounded-2xl border px-4 py-3 ${
            stale ? 'border-warn bg-warn/10' : 'border-line bg-deep'
          }`}
          role="status"
          aria-live="off"
        >
          {stale ? (
            <WifiOff className="size-6 shrink-0 text-warn-soft" aria-hidden="true" />
          ) : (
            <span className="relative flex size-3 shrink-0" aria-hidden="true">
              <span className={`live-dot size-3 rounded-full ${live ? 'bg-safe' : 'bg-ink-3'}`} />
            </span>
          )}
          <div className="min-w-0">
            <p className={`text-lg font-bold ${stale ? 'text-warn-soft' : 'text-ink'}`}>
              Last update {formatRelative(updated, now)}
            </p>
            <p className="text-sm text-ink-2">
              {stale
                ? 'No new location for over a minute. The phone may have lost signal or battery. Keep this page open.'
                : live
                  ? 'Updates every 10 seconds while the alert is active.'
                  : 'Tracking has stopped.'}
            </p>
          </div>
        </div>

        {error ? (
          <div role="alert" className="flex items-center justify-between gap-3 rounded-2xl border border-sos/60 bg-sos/10 px-4 py-3">
            <p className="text-ink">
              <span className="font-bold">Could not refresh.</span> {error}
              {fetchedAt ? ` Showing data from ${formatRelative(fetchedAt, now)}.` : ''}
            </p>
            <button
              type="button"
              onClick={onRetry}
              className="inline-flex min-h-11 shrink-0 items-center gap-2 rounded-xl bg-panel px-3 font-semibold text-ink hover:bg-line"
            >
              <RefreshCw className="size-4" aria-hidden="true" />
              Retry
            </button>
          </div>
        ) : null}

        {incident.address ? (
          <div className="rounded-2xl bg-deep px-4 py-3">
            <p className="text-sm text-ink-3">Nearest address</p>
            <p className="mt-0.5 text-lg font-semibold text-ink">{incident.address}</p>
          </div>
        ) : null}

        <dl className="grid grid-cols-2 gap-3">
          <Stat
            icon={battery !== null && battery <= 20 ? BatteryLow : Battery}
            label="Phone battery"
            value={battery === null ? 'Unknown' : `${battery}%`}
            tone={battery !== null && battery <= 10 ? 'bad' : battery !== null && battery <= 20 ? 'warn' : undefined}
          />
          <Stat icon={Route} label="Distance moved" value={formatDistance(distance)} />
          {latest?.accuracy_meters ? (
            <Stat icon={MapPin} label="GPS accuracy" value={`±${Math.round(latest.accuracy_meters)} m`} />
          ) : null}
          {latest?.speed_kmh !== null && latest?.speed_kmh !== undefined ? (
            <Stat icon={Clock} label="Speed" value={`${latest.speed_kmh.toFixed(1)} km/h`} />
          ) : null}
        </dl>

        <div className="mt-auto flex flex-col gap-3">
          {live ? <Call112 className="w-full" /> : null}
          <div className="grid grid-cols-2 gap-3">
            {latest ? (
              <a
                href={googleMapsUrl(latest)}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex min-h-12 items-center justify-center gap-2 rounded-2xl bg-action-strong px-4 font-semibold text-white hover:bg-action"
              >
                <ExternalLink className="size-5" aria-hidden="true" />
                <span>
                  Open in Google Maps<span className="sr-only"> (opens in a new tab)</span>
                </span>
              </a>
            ) : null}
            <CopyLinkButton />
          </div>
          {!live ? <Call112 className="w-full" /> : null}
          <p className="text-sm text-ink-3">
            If you think {incident.first_name} is in danger, call 112 and share the address above. Do not go alone.
          </p>
        </div>
      </section>
    </div>
  );
}

export function TrackerView({ token, demo }: { token: string; demo: boolean }) {
  const { state, fetchedAt, retry } = useTrack(token, demo);
  const now = useNow();

  if (state.kind === 'loading') {
    return (
      <Shell demo={demo}>
        <div className="flex flex-1 items-center justify-center" role="status">
          <p className="flex items-center gap-3 text-lg text-ink-2">
            <LoaderCircle className="size-6 motion-safe:animate-spin" aria-hidden="true" />
            Loading the latest location
          </p>
        </div>
      </Shell>
    );
  }

  if (state.kind === 'config') {
    return (
      <Shell>
        <Message icon={Settings} title="This tracker is not connected yet">
          <p>
            The site has no Supabase project configured, so it cannot look up alerts. If you run this site, set
            <code className="mx-1 rounded bg-panel px-1.5 py-0.5 text-base">NEXT_PUBLIC_SUPABASE_URL</code>
            and
            <code className="mx-1 rounded bg-panel px-1.5 py-0.5 text-base">NEXT_PUBLIC_SUPABASE_ANON_KEY</code>
            and rebuild. See <code className="rounded bg-panel px-1.5 py-0.5 text-base">.env.example</code>.
          </p>
          <p>
            To see how the page works, open the{' '}
            <Link className="font-semibold text-action-soft underline underline-offset-4" href="/track/demo">
              demo tracker
            </Link>
            .
          </p>
        </Message>
      </Shell>
    );
  }

  if (state.kind === 'not_found') {
    return (
      <Shell>
        <Message icon={MapPin} title="This tracking link has ended">
          <p>
            The link may have expired because the person marked themselves safe, or it may have been copied
            incompletely. Tracking links only work while an alert is open.
          </p>
          <p>Check the SMS or Telegram message you received for the full link, or call the person directly.</p>
        </Message>
      </Shell>
    );
  }

  if (state.kind === 'error' && !state.data) {
    return (
      <Shell>
        <Message
          icon={WifiOff}
          title="Could not load this alert"
          action={
            <button
              type="button"
              onClick={() => void retry()}
              className="inline-flex min-h-14 items-center justify-center gap-2.5 rounded-2xl bg-action-strong px-6 text-lg font-bold text-white hover:bg-action"
            >
              <RefreshCw className="size-5" aria-hidden="true" />
              Try again
            </button>
          }
        >
          <p>{state.message}</p>
          <p>The page will keep trying every 10 seconds. The SMS you received has the last known location.</p>
        </Message>
      </Shell>
    );
  }

  const data = state.kind === 'ready' ? state.data : state.data!;
  return (
    <Shell demo={demo}>
      <Dashboard
        data={data}
        now={now}
        fetchedAt={fetchedAt}
        error={state.kind === 'error' ? state.message : null}
        onRetry={() => void retry()}
      />
    </Shell>
  );
}
