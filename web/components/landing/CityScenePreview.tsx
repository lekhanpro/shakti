'use client';

import { useEffect, useRef } from 'react';

/** A compact, self-contained version of the existing city story scene. */
export function CityScenePreview() {
  const holderRef = useRef<HTMLDivElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const holder = holderRef.current;
    const canvas = canvasRef.current;
    if (!holder || !canvas) return;

    const reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    const progress = { current: reduced ? 0.78 : 0 };
    let stopScene: (() => void) | undefined;
    let disposed = false;
    let raf = 0;
    let visible = !document.hidden;
    let inView = true;
    let pagePaused = document.querySelector<HTMLElement>('.shakti-site')?.dataset.motion === 'paused';

    import('../story/cityScene')
      .then(({ startCityScene }) => startCityScene({ canvas, holder, progress, staticAt: reduced ? 0.78 : undefined }))
      .then((stop) => {
        if (disposed) stop();
        else stopScene = stop;
      })
      .catch(() => {});

    if (!reduced) {
      const started = performance.now();
      const intersection = new IntersectionObserver(([entry]) => {
        inView = entry?.isIntersecting ?? true;
      });
      intersection.observe(holder);
      const onVisibility = () => { visible = !document.hidden; };
      document.addEventListener('visibilitychange', onVisibility);
      const onPageMotion = (event: Event) => { pagePaused = Boolean((event as CustomEvent<{ paused: boolean }>).detail.paused); };
      document.addEventListener('shakti:motion', onPageMotion);
      const tick = (now: number) => {
        raf = requestAnimationFrame(tick);
        if (!visible || !inView || pagePaused) return;
        progress.current = ((now - started) / 16000) % 1;
      };
      raf = requestAnimationFrame(tick);
      return () => {
        disposed = true;
        cancelAnimationFrame(raf);
        intersection.disconnect();
        document.removeEventListener('visibilitychange', onVisibility);
        document.removeEventListener('shakti:motion', onPageMotion);
        stopScene?.();
      };
    }

    return () => {
      disposed = true;
      stopScene?.();
    };
  }, []);

  return (
    <div ref={holderRef} className="city-scene-preview" role="img" aria-label="Three dimensional night street illustration showing a safety response moving from a phone to guardians.">
      <canvas ref={canvasRef} className="size-full" />
      <div className="city-scene-preview-label" aria-hidden="true"><span>3D RESPONSE MODEL</span><span>LIVE STORY LOOP</span></div>
      <div className="city-scene-preview-caption" aria-hidden="true"><span className="city-scene-pulse" /> the city answers in sequence</div>
    </div>
  );
}
