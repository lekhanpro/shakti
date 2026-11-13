import type { Status } from './content';

/** Marks a feature as written and tested ("Built") or still being finished ("In development"). */
export function StatusTag({ status }: { status?: Status }) {
  if (!status) return null;
  return status === 'built' ? (
    <span className="status-tag status-tag-built" data-status="built">
      <span className="status-tag-dot" aria-hidden="true" />
      Built
    </span>
  ) : (
    <span className="status-tag status-tag-dev" data-status="dev">
      <span className="status-tag-dot" aria-hidden="true" />
      In development
    </span>
  );
}
