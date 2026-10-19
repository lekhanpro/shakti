'use client';

import { useEffect, useRef } from 'react';

const GUARDIANS = [
  { a: -2.5, r: 1 },
  { a: -1.75, r: 0.86 },
  { a: -0.8, r: 1 },
  { a: 0.35, r: 0.92 },
  { a: 1.3, r: 1 },
  { a: 2.2, r: 0.88 },
] as const;

/**
 * An illustration of one SOS reaching several guardians. It draws on a plain
 * 2D canvas, pauses off-screen, and renders a single still frame for reduced
 * motion. The phone is rose because an incident is live; the links are
 * indigo because guardians are watching.
 */
export function GuardianMesh() {
  const ref = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = ref.current;
    const ctx = canvas?.getContext('2d');
    if (!canvas || !ctx) return;
    const reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    let w = 0;
    let h = 0;
    let raf = 0;
    let inView = true;
    let visible = !document.hidden;

    const draw = (t: number) => {
      ctx.clearRect(0, 0, w, h);
      const cx = w / 2;
      const cy = h / 2;
      const rx = w * 0.4;
      const ry = h * 0.38;

      GUARDIANS.forEach((g, i) => {
        const gx = cx + Math.cos(g.a) * rx * g.r;
        const gy = cy + Math.sin(g.a) * ry * g.r;
        ctx.strokeStyle = 'rgba(100,116,139,0.35)';
        ctx.lineWidth = 1;
        ctx.beginPath();
        ctx.moveTo(cx, cy);
        ctx.lineTo(gx, gy);
        ctx.stroke();

        const k = (t * 0.32 + i * 0.17) % 1;
        const reach = Math.min(1, k / 0.8);
        ctx.strokeStyle = 'rgba(165,180,252,0.85)';
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.moveTo(cx, cy);
        ctx.lineTo(cx + (gx - cx) * reach, cy + (gy - cy) * reach);
        ctx.stroke();

        const arrived = k > 0.8;
        ctx.fillStyle = arrived ? '#a5b4fc' : '#1e293b';
        ctx.strokeStyle = '#a5b4fc';
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.arc(gx, gy, 9, 0, Math.PI * 2);
        ctx.fill();
        ctx.stroke();
      });

      for (let n = 0; n < 3; n++) {
        const k = (t * 0.45 + n / 3) % 1;
        ctx.strokeStyle = `rgba(251,113,133,${(1 - k) * 0.7})`;
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.arc(cx, cy, 18 + k * Math.min(rx, ry) * 0.5, 0, Math.PI * 2);
        ctx.stroke();
      }

      ctx.fillStyle = '#0f172a';
      ctx.strokeStyle = '#e2e8f0';
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.roundRect(cx - 12, cy - 20, 24, 40, 6);
      ctx.fill();
      ctx.stroke();
      ctx.fillStyle = '#fb7185';
      ctx.beginPath();
      ctx.arc(cx, cy, 5, 0, Math.PI * 2);
      ctx.fill();
    };

    const resize = () => {
      const r = canvas.getBoundingClientRect();
      const dpr = Math.min(window.devicePixelRatio || 1, 2);
      w = r.width;
      h = r.height;
      canvas.width = Math.round(w * dpr);
      canvas.height = Math.round(h * dpr);
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      if (reduced) draw(2.6);
    };
    const ro = new ResizeObserver(resize);
    ro.observe(canvas);
    resize();
    if (reduced) return () => ro.disconnect();

    const io = new IntersectionObserver(([e]) => (inView = e.isIntersecting));
    io.observe(canvas);
    const onVis = () => (visible = !document.hidden);
    document.addEventListener('visibilitychange', onVis);
    const loop = (now: number) => {
      raf = requestAnimationFrame(loop);
      if (inView && visible) draw(now / 1000);
    };
    raf = requestAnimationFrame(loop);
    return () => {
      cancelAnimationFrame(raf);
      ro.disconnect();
      io.disconnect();
      document.removeEventListener('visibilitychange', onVis);
    };
  }, []);

  return (
    <canvas
      ref={ref}
      role="img"
      aria-label="Illustration: a phone in the centre sends an alert along lines to six guardians around it."
      className="h-80 w-full"
    />
  );
}
