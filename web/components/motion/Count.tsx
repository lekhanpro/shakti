'use client';

import { useEffect, useRef } from 'react';

const fmt = (n: number, decimals: number) =>
  n.toLocaleString('en-IN', { minimumFractionDigits: decimals, maximumFractionDigits: decimals });

/**
 * Counts up to `to` once it scrolls into view. The server renders the final
 * number, so it is correct with no script and for reduced motion; the count-up
 * writes straight to the DOM node instead of going through React state.
 */
export function Count({ to, decimals = 0 }: { to: number; decimals?: number }) {
  const ref = useRef<HTMLSpanElement>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
    let raf = 0;
    el.textContent = fmt(0, decimals);
    const io = new IntersectionObserver(([entry]) => {
      if (!entry.isIntersecting) return;
      io.disconnect();
      const start = performance.now();
      const run = (now: number) => {
        const t = Math.min(1, (now - start) / 1100);
        el.textContent = fmt(to * (1 - Math.pow(1 - t, 3)), decimals);
        if (t < 1) raf = requestAnimationFrame(run);
      };
      raf = requestAnimationFrame(run);
    });
    io.observe(el);
    return () => {
      io.disconnect();
      cancelAnimationFrame(raf);
      el.textContent = fmt(to, decimals);
    };
  }, [to, decimals]);

  return (
    <span ref={ref} className="tabular-nums">
      {fmt(to, decimals)}
    </span>
  );
}
