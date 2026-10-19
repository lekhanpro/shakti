'use client';

import { useEffect, useRef, type ReactNode } from 'react';

/** Pulls a button a few pixels toward the pointer when it is close. Fine pointers only. */
export function Magnet({ children, className = '' }: { children: ReactNode; className?: string }) {
  const ref = useRef<HTMLSpanElement>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    if (!window.matchMedia('(pointer: fine) and (prefers-reduced-motion: no-preference)').matches) return;
    let raf = 0;
    const move = (e: PointerEvent) => {
      cancelAnimationFrame(raf);
      raf = requestAnimationFrame(() => {
        const r = el.getBoundingClientRect();
        const dx = e.clientX - (r.left + r.width / 2);
        const dy = e.clientY - (r.top + r.height / 2);
        const near = Math.hypot(dx, dy) < Math.max(r.width, r.height) * 0.9;
        el.style.transform = near ? `translate(${(dx * 0.18).toFixed(1)}px, ${(dy * 0.28).toFixed(1)}px)` : '';
      });
    };
    window.addEventListener('pointermove', move, { passive: true });
    return () => {
      cancelAnimationFrame(raf);
      window.removeEventListener('pointermove', move);
    };
  }, []);

  return (
    <span ref={ref} className={`magnet ${className}`}>
      {children}
    </span>
  );
}
