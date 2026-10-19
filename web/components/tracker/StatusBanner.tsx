import { CircleCheck, ShieldAlert, Timer, TriangleAlert } from 'lucide-react';
import { formatElapsed } from '@/lib/format';
import type { IncidentStatus } from '@/lib/track';

interface StatusBannerProps {
  status: IncidentStatus;
  name: string;
  createdAt: string;
  /** Resolved/closed time; used to show how long the incident lasted. */
  updatedAt: string;
  now: number;
  triggerLabel?: string | null;
}

const TONES = {
  ACTIVE: 'bg-sos text-white',
  COUNTDOWN: 'bg-warn text-night',
  RESOLVED: 'bg-safe text-night',
  FALSE_ALARM: 'bg-panel text-ink border border-line',
} as const;

/**
 * Top-of-page status. Colour is never the only signal: every state has its own icon and wording.
 */
export function StatusBanner({ status, name, createdAt, updatedAt, now, triggerLabel }: StatusBannerProps) {
  const started = Date.parse(createdAt);
  const elapsed = formatElapsed(now - started);
  const lasted = formatElapsed(Date.parse(updatedAt) - started);

  let Icon = ShieldAlert;
  let title: string;
  let detail: string;
  switch (status) {
    case 'ACTIVE':
      title = `${name} needs help`;
      detail = `SOS raised ${elapsed} ago${triggerLabel ? `. ${triggerLabel}` : ''}`;
      break;
    case 'COUNTDOWN':
      Icon = Timer;
      title = `${name} started an SOS`;
      detail = 'The alert is in its 5 second cancel window. Stay on this page.';
      break;
    case 'RESOLVED':
      Icon = CircleCheck;
      title = `${name} is safe`;
      detail = `Marked safe. The alert lasted ${lasted}.`;
      break;
    case 'FALSE_ALARM':
      Icon = TriangleAlert;
      title = 'This alert was cancelled';
      detail = `${name} marked it as a false alarm. No action is needed.`;
      break;
  }

  return (
    <div
      role={status === 'ACTIVE' ? 'alert' : 'status'}
      data-status={status}
      className={`flex items-start gap-3 rounded-[var(--radius-card)] px-5 py-4 sm:items-center ${TONES[status]}`}
    >
      <Icon className="mt-0.5 size-7 shrink-0 sm:mt-0" aria-hidden="true" strokeWidth={2.25} />
      <div className="min-w-0">
        <h1 className="font-display text-2xl font-bold leading-tight sm:text-3xl">{title}</h1>
        <p className="mt-0.5 text-base font-semibold opacity-95">{detail}</p>
      </div>
    </div>
  );
}
