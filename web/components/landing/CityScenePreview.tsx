'use client';

import { useEffect, useRef, useState } from 'react';
import type { MotionValue } from 'motion/react';
import { clockAt, formatClock, phaseAt } from '@/lib/story';

interface CityScenePreviewProps {
  scrollProgress?: MotionValue<number>;
}

const PHASE_LABELS: Record<string, string> = {
  idle: 'WALK · SYSTEM READY',
  countdown: '5s CANCEL WINDOW',
  sos: 'SOS DISPATCH · CARRIER SMS',
  live: 'LIVE TRACKER · 3 GUARDIANS',
  safe: 'MARKED SAFE · THREAT RESOLVED',
};

/** A high-fidelity, scroll-linked 3D night-street simulation showing Shakti's safety pipeline in motion. */
export function CityScenePreview({ scrollProgress }: CityScenePreviewProps) {
  const holderRef = useRef<HTMLDivElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);

  const [activePhase, setActivePhase] = useState<string>('idle');
  const [activeClock, setActiveClock] = useState<string>('0:00');
  const [isManualScrub, setIsManualScrub] = useState<boolean>(false);

  const targetProgress = useRef<number>(0);
  const currentProgress = useRef<number>(0);
  const manualTarget = useRef<number | null>(null);

  useEffect(() => {
    const holder = holderRef.current;
    const canvas = canvasRef.current;
    if (!holder || !canvas) return;

    const reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    const progressRef = { current: reduced ? 0.78 : 0 };
    let stopScene: (() => void) | undefined;
    let disposed = false;
    let raf = 0;
    let visible = !document.hidden;
    let inView = true;
    let pagePaused = document.querySelector<HTMLElement>('.shakti-site')?.dataset.motion === 'paused';

    import('../story/cityScene')
      .then(({ startCityScene }) =>
        startCityScene({
          canvas,
          holder,
          progress: progressRef,
          staticAt: reduced ? 0.78 : undefined,
        })
      )
      .then((stop) => {
        if (disposed) stop();
        else stopScene = stop;
      })
      .catch(() => {});

    // Listen to scroll progress if provided
    let unsubscribeScroll: (() => void) | undefined;
    if (scrollProgress && !reduced) {
      targetProgress.current = scrollProgress.get();
      unsubscribeScroll = scrollProgress.on('change', (latest) => {
        if (manualTarget.current === null) {
          targetProgress.current = latest;
        }
      });
    }

    if (!reduced) {
      const started = performance.now();
      let lastHudUpdate = 0;

      const intersection = new IntersectionObserver(([entry]) => {
        inView = entry?.isIntersecting ?? true;
      });
      intersection.observe(holder);

      const onVisibility = () => {
        visible = !document.hidden;
      };
      document.addEventListener('visibilitychange', onVisibility);

      const onPageMotion = (event: Event) => {
        pagePaused = Boolean((event as CustomEvent<{ paused: boolean }>).detail.paused);
      };
      document.addEventListener('shakti:motion', onPageMotion);

      const tick = (now: number) => {
        raf = requestAnimationFrame(tick);
        if (!visible || !inView || pagePaused) return;

        // If manual stage jump is active, smoothly ease toward manualTarget
        if (manualTarget.current !== null) {
          const delta = manualTarget.current - currentProgress.current;
          if (Math.abs(delta) < 0.002) {
            currentProgress.current = manualTarget.current;
            manualTarget.current = null;
            setIsManualScrub(false);
          } else {
            currentProgress.current += delta * 0.12;
          }
        } else if (scrollProgress) {
          // Scroll-linked smooth easing: Damped interpolation for buttery 60fps tracking
          const target = targetProgress.current;
          currentProgress.current += (target - currentProgress.current) * 0.14;
        } else {
          // Autonomous continuous loop when scroll is unattached
          currentProgress.current = ((now - started) / 16000) % 1;
        }

        // Clamp 0 to 1
        const clamped = Math.max(0, Math.min(1, currentProgress.current));
        progressRef.current = clamped;

        // Throttle HUD state updates to ~15fps for zero React re-render overhead
        if (now - lastHudUpdate > 66) {
          lastHudUpdate = now;
          const phase = phaseAt(clamped);
          const clock = formatClock(clockAt(clamped));
          setActivePhase(phase);
          setActiveClock(clock);
        }
      };

      raf = requestAnimationFrame(tick);

      return () => {
        disposed = true;
        cancelAnimationFrame(raf);
        intersection.disconnect();
        unsubscribeScroll?.();
        document.removeEventListener('visibilitychange', onVisibility);
        document.removeEventListener('shakti:motion', onPageMotion);
        stopScene?.();
      };
    }

    return () => {
      disposed = true;
      unsubscribeScroll?.();
      stopScene?.();
    };
  }, [scrollProgress]);

  function jumpToStage(stageProgress: number) {
    manualTarget.current = stageProgress;
    setIsManualScrub(true);
  }

  return (
    <div
      ref={holderRef}
      className="city-scene-preview"
      role="img"
      aria-label="Three dimensional night street illustration showing a safety response moving from a phone to guardians."
    >
      <canvas ref={canvasRef} className="size-full" />

      {/* Top HUD Header */}
      <div className="city-scene-preview-label" aria-hidden="true">
        <span>3D PIPELINE · {PHASE_LABELS[activePhase] || 'ACTIVE STORY'}</span>
        <span>CLOCK {activeClock}</span>
      </div>

      {/* Stage Selector Pills */}
      <div
        role="group"
        aria-label="Select story stage preview"
        style={{
          position: 'absolute',
          top: '3.4rem',
          right: '1.5rem',
          display: 'flex',
          gap: '0.4rem',
          zIndex: 5,
        }}
      >
        <button
          type="button"
          onClick={() => jumpToStage(0.12)}
          style={{
            background: activePhase === 'idle' ? 'rgba(56, 189, 248, 0.25)' : 'rgba(15, 23, 42, 0.65)',
            border: activePhase === 'idle' ? '1px solid rgba(56, 189, 248, 0.6)' : '1px solid rgba(255, 255, 255, 0.1)',
            color: activePhase === 'idle' ? '#38bdf8' : 'rgba(248, 250, 252, 0.6)',
            padding: '0.2rem 0.55rem',
            borderRadius: '9999px',
            fontSize: '0.62rem',
            fontFamily: 'var(--font-mono, monospace)',
            cursor: 'pointer',
            transition: 'all 0.15s ease',
          }}
          aria-label="Preview Walk stage"
        >
          01 WALK
        </button>
        <button
          type="button"
          onClick={() => jumpToStage(0.56)}
          style={{
            background: activePhase === 'countdown' || activePhase === 'sos' ? 'rgba(251, 113, 133, 0.25)' : 'rgba(15, 23, 42, 0.65)',
            border: activePhase === 'countdown' || activePhase === 'sos' ? '1px solid rgba(251, 113, 133, 0.6)' : '1px solid rgba(255, 255, 255, 0.1)',
            color: activePhase === 'countdown' || activePhase === 'sos' ? '#fb7185' : 'rgba(248, 250, 252, 0.6)',
            padding: '0.2rem 0.55rem',
            borderRadius: '9999px',
            fontSize: '0.62rem',
            fontFamily: 'var(--font-mono, monospace)',
            cursor: 'pointer',
            transition: 'all 0.15s ease',
          }}
          aria-label="Preview Alert stage"
        >
          02 ALERT
        </button>
        <button
          type="button"
          onClick={() => jumpToStage(0.92)}
          style={{
            background: activePhase === 'safe' || activePhase === 'live' ? 'rgba(52, 211, 153, 0.25)' : 'rgba(15, 23, 42, 0.65)',
            border: activePhase === 'safe' || activePhase === 'live' ? '1px solid rgba(52, 211, 153, 0.6)' : '1px solid rgba(255, 255, 255, 0.1)',
            color: activePhase === 'safe' || activePhase === 'live' ? '#34d399' : 'rgba(248, 250, 252, 0.6)',
            padding: '0.2rem 0.55rem',
            borderRadius: '9999px',
            fontSize: '0.62rem',
            fontFamily: 'var(--font-mono, monospace)',
            cursor: 'pointer',
            transition: 'all 0.15s ease',
          }}
          aria-label="Preview Safe stage"
        >
          03 SAFE
        </button>
      </div>

      {/* Bottom Caption */}
      <div className="city-scene-preview-caption" aria-hidden="true">
        <span
          className="city-scene-pulse"
          style={{
            backgroundColor:
              activePhase === 'safe'
                ? '#34d399'
                : activePhase === 'sos'
                  ? '#fb7185'
                  : activePhase === 'countdown'
                    ? '#f59e0b'
                    : '#38bdf8',
          }}
        />
        <span>
          {isManualScrub
            ? 'previewing selected stage'
            : scrollProgress
              ? 'scroll to advance the emergency sequence'
              : 'the city answers in sequence'}
        </span>
      </div>
    </div>
  );
}
