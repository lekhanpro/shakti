import type { Status } from './content';

/** Marks a feature as written and tested ("Built") or still being finished ("In development"). */
export function StatusTag({ status }: { status?: Status }) {
  if (!status) return null;
  return status === 'built' ? (
    <span className="status-tag" data-status="built">
      Built
    </span>
  ) : (
    <span className="status-tag" data-status="dev">
      In development
    </span>
  );
}
