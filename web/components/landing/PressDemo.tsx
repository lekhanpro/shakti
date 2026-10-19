'use client';

import { useEffect, useRef, useState } from 'react';
import { PRESS_COUNT, PRESS_WINDOW_MS, pushPress } from '@/lib/press';

type Status = 'idle' | 'countdown' | 'sent';

/**
 * A working copy of the app's trigger rule: three presses of the side key
 * inside 1.2 seconds start the 5 second cancel window. It sends nothing.
 */
export function PressDemo() {
  const [status, setStatus] = useState<Status>('idle');
  const [presses, setPresses] = useState(0);
  const [left, setLeft] = useState(5);
  const history = useRef<number[]>([]);

  const onPress = () => {
    if (status !== 'idle') return;
    const r = pushPress(history.current, performance.now());
    history.current = r.history;
    setPresses(r.history.length);
    if (r.triggered) {
      setLeft(5);
      setStatus('countdown');
    }
  };

  // A run of presses that stalls resets, the same way the app's detector does.
  useEffect(() => {
    if (presses === 0) return;
    const id = window.setTimeout(() => {
      history.current = [];
      setPresses(0);
    }, PRESS_WINDOW_MS);
    return () => window.clearTimeout(id);
  }, [presses]);

  useEffect(() => {
    if (status !== 'countdown') return;
    const id = window.setTimeout(() => {
      if (left <= 1) setStatus('sent');
      else setLeft(left - 1);
    }, 1000);
    return () => window.clearTimeout(id);
  }, [status, left]);

  const reset = () => {
    history.current = [];
    setPresses(0);
    setStatus('idle');
  };

  const announce =
    status === 'countdown'
      ? `Countdown ${left} seconds. Cancel to stop.`
      : status === 'sent'
        ? 'Demo SOS sent. No message was really sent.'
        : presses > 0
          ? `${presses} of ${PRESS_COUNT} presses`
          : '';

  return (
    <div className="relative mx-auto w-60 shrink-0">
      <div className="demo-phone relative flex aspect-[9/18] flex-col rounded-[2.4rem] p-3">
        <div className="mx-auto mt-1 h-1.5 w-14 rounded-full bg-night" aria-hidden="true" />
        <div className="mt-3 flex flex-1 flex-col items-center justify-center rounded-[1.7rem] bg-night px-5 text-center">
          {status === 'idle' ? (
            <>
              <p className="font-display text-lg font-semibold text-ink">Locked</p>
              <p className="mt-2 text-sm text-ink-3">Press the side key {PRESS_COUNT} times</p>
              <div className="mt-6 flex gap-2.5" aria-hidden="true">
                {Array.from({ length: PRESS_COUNT }, (_, i) => (
                  <span
                    key={i}
                    className={`size-3 rounded-full border transition-colors duration-150 ${
                      i < presses ? 'border-warn bg-warn' : 'border-line'
                    }`}
                  />
                ))}
              </div>
            </>
          ) : null}
          {status === 'countdown' ? (
            <>
              <p className="text-sm font-semibold text-warn-soft">Sending SOS in</p>
              <p className="my-2 font-display text-7xl font-extrabold tabular-nums text-ink">{left}</p>
              <button type="button" onClick={reset} className="btn btn-ghost !min-h-12 w-full !text-base">
                Cancel
              </button>
            </>
          ) : null}
          {status === 'sent' ? (
            <>
              <p className="font-display text-lg font-semibold text-sos-soft">SOS sent</p>
              <p className="mt-2 text-sm text-ink-3">This was a demo. Nothing was sent.</p>
              <button type="button" onClick={reset} className="btn btn-ghost mt-5 !min-h-12 !text-base">
                Try again
              </button>
            </>
          ) : null}
        </div>
      </div>

      <button
        type="button"
        onClick={onPress}
        aria-label="Power button. Press three times quickly."
        className="absolute -right-8 top-24 grid h-20 w-12 place-items-center"
      >
        <span className="power-key block h-16 w-1.5 rounded-full bg-ink-3" />
      </button>

      <p className="sr-only" role="status" aria-live="polite">
        {announce}
      </p>
    </div>
  );
}
