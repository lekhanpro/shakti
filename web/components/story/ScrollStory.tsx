'use client';

import Link from 'next/link';
import { useEffect, useRef, useState } from 'react';
import { Download } from 'lucide-react';
import {
  beatAt,
  channelStatesAt,
  clockAt,
  formatClock,
  phaseAt,
  scrollProgress,
  type ChannelState,
  type Phase,
} from '@/lib/story';

/**
 * The page opens as one continuous shot: a woman walks a night street, raises
 * an SOS, and the city answers. The section is tall, its pane is sticky, and
 * scroll position is the only input. One progress number drives the 3D scene,
 * the active text beat and the HUD, so they can never disagree.
 *
 * With reduced motion the pane stops being sticky, every beat is shown in
 * order as ordinary content, and the scene renders one still frame. If WebGL
 * is missing, the CSS poster behind the canvas stands in; the copy does not
 * depend on the scene.
 */

const PHASE_LABEL: Record<Phase, string> = {
  idle: 'Walking home',
  countdown: 'Cancel window',
  sos: 'SOS sent',
  live: 'Guardians watching',
  safe: 'Marked safe',
};

const CHANNELS = ['Saved on the phone', 'SMS to guardians', 'Telegram alert', 'Live tracking link'] as const;

interface View {
  beat: number;
  phase: Phase;
  channels: ChannelState[];
}

export function ScrollStory({ downloadHref }: { downloadHref: string }) {
  const sectionRef = useRef<HTMLElement>(null);
  const holderRef = useRef<HTMLDivElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const clockRef = useRef<HTMLSpanElement>(null);
  const progress = useRef({ current: 0 });

  const [animated, setAnimated] = useState(true);
  const [view, setView] = useState<View>({ beat: 0, phase: 'idle', channels: ['idle', 'idle', 'idle', 'idle'] });

  useEffect(() => {
    const section = sectionRef.current;
    const canvas = canvasRef.current;
    const holder = holderRef.current;
    if (!section || !canvas || !holder) return;

    const reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    setAnimated(!reduced);

    let disposed = false;
    let stopScene: (() => void) | undefined;
    import('./cityScene')
      .then(({ startCityScene }) =>
        startCityScene({ canvas, holder, progress: progress.current, staticAt: reduced ? 0.8 : undefined }),
      )
      .then((stop) => {
        if (disposed) stop();
        else stopScene = stop;
      })
      .catch(() => {});

    let raf = 0;
    let stopLoop = () => {};
    if (!reduced) {
      let key = '';
      let inView = true;
      let visible = !document.hidden;
      const io = new IntersectionObserver((es) => (inView = es.some((e) => e.isIntersecting)), {
        rootMargin: '200px',
      });
      io.observe(section);
      const onVisibility = () => (visible = !document.hidden);
      document.addEventListener('visibilitychange', onVisibility);

      const tick = () => {
        raf = requestAnimationFrame(tick);
        if (!inView || !visible) return;
        const rect = section.getBoundingClientRect();
        const p = scrollProgress(-rect.top, rect.height, window.innerHeight);
        progress.current.current = p;
        if (clockRef.current) clockRef.current.textContent = formatClock(clockAt(p));
        const beat = beatAt(p);
        const channels = channelStatesAt(p);
        const k = `${beat}|${channels.join()}`;
        if (k !== key) {
          key = k;
          setView({ beat, phase: phaseAt(p), channels });
        }
      };
      raf = requestAnimationFrame(tick);
      stopLoop = () => {
        cancelAnimationFrame(raf);
        io.disconnect();
        document.removeEventListener('visibilitychange', onVisibility);
      };
    }

    return () => {
      disposed = true;
      stopLoop();
      stopScene?.();
    };
  }, []);

  const beatProps = (i: number) => ({
    'data-active': view.beat === i,
    inert: animated && view.beat !== i,
  });

  return (
    <section ref={sectionRef} id="story" aria-label="How an SOS unfolds" className="story-track relative">
      <div className="story-pane story-poster">
        <div ref={holderRef} aria-hidden="true" className="absolute inset-0">
          <canvas ref={canvasRef} className="size-full" />
        </div>
        <div aria-hidden="true" className="story-scrim pointer-events-none absolute inset-0" />

        <div className="relative z-10 mx-auto flex h-full min-h-dvh max-w-6xl items-end px-5 pb-14 pt-24 sm:px-8 lg:items-center lg:pb-0">
          <div className="story-beats w-full max-w-xl">
            <div className="beat" {...beatProps(0)}>
              <h1>
                One press.
                <br />
                Your people know where you are.
              </h1>
              <p className="mt-5 max-w-md text-lg text-ink-2 sm:text-xl">
                Press the power button three times. Shakti is built to text your guardians your location, even with no
                data.
              </p>
              <div className="mt-8 flex flex-col gap-3 sm:flex-row">
                <a href={downloadHref} className="btn btn-primary">
                  <Download className="size-5" aria-hidden="true" />
                  Get the app
                </a>
                <a href="#try" className="btn btn-ghost">
                  Try the trigger
                </a>
              </div>
            </div>

            <div className="beat" {...beatProps(1)}>
              <h2>Five seconds to change your mind</h2>
              <p className="mt-4 max-w-md text-lg text-ink-2">
                A pocket press should never become a false alarm. The phone vibrates every second as it counts down,
                and a swipe cancels it.
              </p>
            </div>

            <div className="beat" {...beatProps(2)}>
              <h2>Built so the text goes first</h2>
              <p className="mt-4 max-w-md text-lg text-ink-2">
                The incident is saved on the phone, then the SMS is handed to the SIM. Telegram and the live map follow
                when data is available.
              </p>
            </div>

            <div className="beat" {...beatProps(3)}>
              <h2>They watch you get home</h2>
              <p className="mt-4 max-w-md text-lg text-ink-2">
                Guardians open a link in any browser. Your route and battery refresh every 10 seconds.
              </p>
              <Link href="/track/demo" className="btn btn-ghost mt-7">
                Open the demo tracker
              </Link>
            </div>

            <div className="beat" {...beatProps(4)}>
              <h2>Then you tell them you are safe</h2>
              <p className="mt-4 max-w-md text-lg text-ink-2">
                Confirm with your PIN. The tracking link stops working 24 hours later.
              </p>
            </div>
          </div>
        </div>

        <div
          aria-hidden="true"
          data-phase={view.phase}
          className="story-hud motion-only pointer-events-none absolute right-5 top-20 z-10 rounded-[var(--radius-card)] border border-line/70 bg-night/70 px-4 py-3 backdrop-blur-md sm:right-8 lg:bottom-10 lg:top-auto"
        >
          <p className="mb-2 text-xs font-semibold uppercase tracking-wider text-ink-3">Demo timeline</p>
          <div className="flex items-center gap-2.5 text-sm">
            <span className="phase-dot size-2 rounded-full" />
            <span className="phase-label font-semibold">{PHASE_LABEL[view.phase]}</span>
            <span ref={clockRef} className="clock ml-2 font-mono tabular-nums">
              0:00
            </span>
          </div>
          <ul className="mt-3 hidden space-y-2 text-sm sm:block">
            {CHANNELS.map((label, i) => (
              <li key={label} className="channel" data-state={view.channels[i]}>
                <span className="tick" />
                {label}
              </li>
            ))}
          </ul>
        </div>
      </div>
    </section>
  );
}
