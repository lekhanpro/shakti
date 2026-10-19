'use client';

import { useEffect, useState } from 'react';
import { AnimatePresence, motion, useReducedMotion } from 'motion/react';
import { FileText, RotateCcw, Send } from 'lucide-react';

const USER_MESSAGE = 'A man has been following me since the bus stop. I am scared.';

// Written to follow the rules in supabase/functions/ai-guard/prompts.ts:
// danger first, the three helplines, short steps, under 150 words.
const REPLY =
  'If you are in danger now, press SOS in the app or call 112.\n' +
  'Move toward light and people: a shop, a petrol pump or a police station.\n' +
  'Share your live location with someone you trust and stay on the phone with them.\n' +
  'Helplines: 112 (all emergencies), 181 (Women Helpline), 1091 (Women Police).';

// The section headings of the app's offline FIR template, with blanks left blank.
const FIR_SAMPLE = `FIRST INFORMATION REPORT (DRAFT)
(Under Section 173, Bharatiya Nagarik Suraksha Sanhita, 2023)

To,
The Station House Officer (SHO),
[Police station name]

Subject: Complaint regarding an incident on [date] at [time]

1. Complainant
Name: [Complainant name]

2. Place of occurrence
Place: [address from your SOS]
Map: [link from your SOS]

3. Facts of the incident
[Describe what happened, in your own words,
in the order it happened]

4. Evidence
- GPS trail: [n] GPS points recorded between [time] and [time]`;

type Step = 'idle' | 'typing' | 'done';

/** A scripted walk-through. It calls no model and says so on screen. */
export function AiDemo() {
  const reduce = useReducedMotion();
  const [step, setStep] = useState<Step>('idle');
  const [shown, setShown] = useState(0);
  const [fir, setFir] = useState(false);
  const words = REPLY.split(/(\s+)/);

  useEffect(() => {
    if (step !== 'typing') return;
    const id = window.setInterval(() => {
      setShown((n) => {
        if (n + 2 >= words.length) {
          window.clearInterval(id);
          setStep('done');
          return words.length;
        }
        return n + 2;
      });
    }, 55);
    return () => window.clearInterval(id);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [step]);

  // Reduced motion shows the whole reply at once instead of typing it out.
  const send = () => {
    if (reduce) {
      setShown(words.length);
      setStep('done');
    } else {
      setStep('typing');
    }
  };

  const reset = () => {
    setStep('idle');
    setShown(0);
    setFir(false);
  };

  return (
    <div className="rounded-[var(--radius-xl)] border border-line/70 bg-night p-5 sm:p-6">
      <p className="text-sm font-semibold text-warn-soft">Demo. A scripted exchange, not a live model.</p>

      <div className="mt-5 space-y-3" aria-live="off">
        <p className="ml-auto max-w-[85%] rounded-2xl rounded-br-md bg-action-strong px-4 py-3 text-white">
          {USER_MESSAGE}
        </p>
        {step !== 'idle' ? (
          <div className="max-w-[92%] rounded-2xl rounded-bl-md border border-line bg-deep px-4 py-3">
            <p className="mb-2 inline-block rounded-full bg-sos/15 px-2.5 py-0.5 text-xs font-semibold text-sos-soft">
              Crisis words noticed, helplines first
            </p>
            <p className="whitespace-pre-line text-ink">{words.slice(0, shown).join('')}</p>
          </div>
        ) : null}
      </div>
      <p className="sr-only" role="status">
        {step === 'done' ? 'Reply ready.' : ''}
      </p>

      <div className="mt-5 flex flex-wrap gap-3">
        {step === 'idle' ? (
          <button type="button" className="btn btn-primary !min-h-12 !text-base" onClick={send}>
            <Send className="size-4" aria-hidden="true" />
            Send this message
          </button>
        ) : null}
        {step === 'done' && !fir ? (
          <button type="button" className="btn btn-primary !min-h-12 !text-base" onClick={() => setFir(true)}>
            <FileText className="size-4" aria-hidden="true" />
            Draft an FIR
          </button>
        ) : null}
        {step !== 'idle' ? (
          <button type="button" className="btn btn-ghost !min-h-12 !text-base" onClick={reset}>
            <RotateCcw className="size-4" aria-hidden="true" />
            Start over
          </button>
        ) : null}
      </div>

      <AnimatePresence>
        {fir ? (
          <motion.div
            key="fir"
            initial={reduce ? false : { opacity: 0, y: 24, height: 0 }}
            animate={{ opacity: 1, y: 0, height: 'auto' }}
            exit={{ opacity: 0 }}
            transition={{ duration: reduce ? 0 : 0.5, ease: [0.22, 1, 0.36, 1] }}
            className="overflow-hidden"
          >
            <p className="mt-6 text-sm font-semibold text-ink-2">
              Sample layout. The app fills the blanks from your SOS and what you tell it.
            </p>
            <pre className="mt-2 overflow-x-auto rounded-[var(--radius-card)] border border-line bg-deep p-4 font-mono text-sm leading-relaxed text-ink-2">
              {FIR_SAMPLE}
            </pre>
          </motion.div>
        ) : null}
      </AnimatePresence>
    </div>
  );
}
