'use client';

import { useEffect } from 'react';
import Lenis from 'lenis';
import 'lenis/dist/lenis.css';

/** Inertial scrolling for the landing page only. Off for reduced motion. */
export function SmoothScroll() {
  useEffect(() => {
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
    const lenis = new Lenis({ autoRaf: true, anchors: { offset: -72 }, respectReducedMotion: true });
    return () => lenis.destroy();
  }, []);
  return null;
}
