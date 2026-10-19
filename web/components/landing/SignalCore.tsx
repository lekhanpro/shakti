'use client';

import { motion, useMotionValue, useReducedMotion, useSpring, useTransform } from 'motion/react';
import { Radio, ShieldCheck, Smartphone } from 'lucide-react';

const NODES = [
  { label: 'guardian 01', kind: 'home', x: '8%', y: '24%', delay: '0s' },
  { label: 'guardian 02', kind: 'work', x: '78%', y: '13%', delay: '1.1s' },
  { label: 'tracker link', kind: 'link', x: '86%', y: '73%', delay: '2.2s' },
  { label: 'you', kind: 'you', x: '17%', y: '78%', delay: '0.45s' },
] as const;

export function SignalCore() {
  const reduced = useReducedMotion();
  const pointerX = useMotionValue(0);
  const pointerY = useMotionValue(0);
  const rotateY = useSpring(useTransform(pointerX, [-0.5, 0.5], [7, -7]), {
    stiffness: 180,
    damping: 22,
  });
  const rotateX = useSpring(useTransform(pointerY, [-0.5, 0.5], [-5, 5]), {
    stiffness: 180,
    damping: 22,
  });

  const handlePointerMove = (event: React.PointerEvent<HTMLDivElement>) => {
    if (reduced || event.pointerType !== 'mouse') return;
    const rect = event.currentTarget.getBoundingClientRect();
    pointerX.set((event.clientX - rect.left) / rect.width - 0.5);
    pointerY.set((event.clientY - rect.top) / rect.height - 0.5);
  };

  const resetPointer = () => {
    pointerX.set(0);
    pointerY.set(0);
  };

  return (
    <div
      className="signal-core-stage"
      onPointerMove={handlePointerMove}
      onPointerLeave={resetPointer}
      role="img"
      aria-label="Illustration of Shakti sending a signal from a phone to guardians and a live tracker link."
    >
      <div className="signal-core-noise" aria-hidden="true" />
      <div className="signal-core-coordinate" aria-hidden="true">
        <span>SHK / RESPONSE MAP</span>
        <span>LOCAL SIGNAL / 01</span>
      </div>

      <motion.div
        className="signal-core-scene"
        style={{ rotateX, rotateY }}
        transition={{ type: 'spring', stiffness: 180, damping: 24 }}
      >
        <div className="signal-core-orbit signal-core-orbit-one" aria-hidden="true" />
        <div className="signal-core-orbit signal-core-orbit-two" aria-hidden="true" />
        <div className="signal-core-beacon" aria-hidden="true">
          <span className="signal-core-beacon-ring" />
          <span className="signal-core-beacon-dot" />
        </div>

        <div className="signal-core-lines" aria-hidden="true">
          <span className="signal-line signal-line-one" />
          <span className="signal-line signal-line-two" />
          <span className="signal-line signal-line-three" />
          <span className="signal-line signal-line-four" />
        </div>

        {NODES.map((node) => (
          <div
            key={node.label}
            className={`signal-node signal-node-${node.kind}`}
            style={{ left: node.x, top: node.y, '--node-delay': node.delay } as React.CSSProperties}
          >
            <span className="signal-node-icon" aria-hidden="true">
              {node.kind === 'you' ? <Smartphone size={14} /> : node.kind === 'link' ? <Radio size={14} /> : <ShieldCheck size={14} />}
            </span>
            <span className="signal-node-label">{node.label}</span>
          </div>
        ))}

        <div className="signal-core-phone" aria-hidden="true">
          <div className="signal-core-phone-speaker" />
          <div className="signal-core-phone-screen">
            <div className="signal-core-phone-status">
              <span className="signal-live-dot" />
              <span>ready</span>
            </div>
            <div className="signal-core-phone-mark">S</div>
            <strong>3 presses</strong>
            <span>starts the response</span>
            <div className="signal-core-phone-meter">
              <span />
              <span />
              <span />
            </div>
          </div>
          <div className="signal-core-phone-button" />
        </div>

        <div className="signal-core-packet signal-core-packet-one">SMS / queued</div>
        <div className="signal-core-packet signal-core-packet-two">TRACK / 10s</div>
      </motion.div>

      <div className="signal-core-footer" aria-hidden="true">
        <span>Signal ready</span>
        <span className="signal-core-footer-line" />
        <span>press → response → people</span>
      </div>
    </div>
  );
}
