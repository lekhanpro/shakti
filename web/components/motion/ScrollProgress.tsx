'use client';

import { useEffect, useRef } from 'react';

/** A thin indigo line along the top that fills as the page scrolls. */
export function ScrollProgress() {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const update = () => {
      const doc = document.documentElement;
      const max = doc.scrollHeight - doc.clientHeight;
      el.style.transform = `scaleX(${max > 0 ? Math.min(1, window.scrollY / max) : 0})`;
    };
    update();
    window.addEventListener('scroll', update, { passive: true });
    window.addEventListener('resize', update);
    return () => {
      window.removeEventListener('scroll', update);
      window.removeEventListener('resize', update);
    };
  }, []);

  return (
    <div
      ref={ref}
      aria-hidden="true"
      className="motion-only pointer-events-none fixed inset-x-0 top-0 z-50 h-0.5 origin-left bg-action-soft"
      style={{ transform: 'scaleX(0)' }}
    />
  );
}
