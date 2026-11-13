'use client';

import { useEffect, useState } from 'react';

/** Brief font readiness transition; content never waits for WebGL or remote assets. */
export function ArrivalIntro() {
  const [phase, setPhase] = useState<'opening' | 'leaving' | 'done'>('opening');

  useEffect(() => {
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
      queueMicrotask(() => setPhase('done'));
      return;
    }
    let active = true;
    let exitTimer = 0;
    function finish() {
      if (!active) return;
      setPhase('leaving');
      window.clearTimeout(exitTimer);
      exitTimer = window.setTimeout(() => { if (active) setPhase('done'); }, 350);
    }
    // The maximum is a fallback, not a simulated percentage or mandatory delay.
    const fallback = window.setTimeout(finish, 1400);
    void document.fonts.ready.then(() => { if (active) { window.clearTimeout(fallback); finish(); } });
    return () => { active = false; window.clearTimeout(fallback); window.clearTimeout(exitTimer); };
  }, []);

  if (phase === 'done') return null;
  return <><div className="s-intro" data-phase={phase} aria-hidden="true"><span className="s-intro-orbit" /><strong>shakti<span>.</span></strong><p>YOUR CIRCLE. YOUR SIGNAL.</p></div><button className="s-intro-skip" type="button" onClick={() => setPhase('done')}>Skip intro</button><noscript><style>{'.s-intro,.s-intro-skip{display:none!important}'}</style></noscript></>;
}
