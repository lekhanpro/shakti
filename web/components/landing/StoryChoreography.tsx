'use client';

import { motion, useScroll, useTransform } from 'motion/react';
import { ArrowDown, Check, Radio, ShieldCheck } from 'lucide-react';
import { useRef } from 'react';
import { CityScenePreview } from './CityScenePreview';

const SCENES = [
  { marker: '01', title: 'A quiet walk home.', body: 'The city is ordinary. The phone is ready.', tone: 'quiet' },
  { marker: '02', title: 'Three presses change the rhythm.', body: 'A five second window appears. Swipe to cancel.', tone: 'alert' },
  { marker: '03', title: 'Your people see the signal.', body: 'The tracker link keeps the route, battery, and distance in view.', tone: 'safe' },
] as const;

function SceneCopy({
  scene,
  index,
  progress,
}: {
  scene: (typeof SCENES)[number];
  index: number;
  progress: ReturnType<typeof useScroll>['scrollYProgress'];
}) {
  const start = index / SCENES.length;
  const end = (index + 1) / SCENES.length;
  const opacity = useTransform(
    progress,
    [Math.max(0, start - 0.08), start + 0.02, end - 0.08, Math.min(1, end + 0.08)],
    [0, 1, 1, 0]
  );
  const y = useTransform(progress, [Math.max(0, start - 0.08), start + 0.02, end], [28, 0, -28]);

  return (
    <motion.div className={`story-scene-copy story-scene-copy-${scene.tone}`} style={{ opacity, y }}>
      <span className="story-scene-marker">{scene.marker}</span>
      <h3>{scene.title}</h3>
      <p>{scene.body}</p>
    </motion.div>
  );
}

export function StoryChoreography() {
  const ref = useRef<HTMLElement>(null);
  const { scrollYProgress } = useScroll({ target: ref, offset: ['start start', 'end end'] });
  const progressWidth = useTransform(scrollYProgress, [0, 1], ['0%', '100%']);

  return (
    <section ref={ref} className="motion-story" id="story" aria-labelledby="story-title">
      <div className="motion-story-sticky">
        <div className="motion-story-visual">
          <CityScenePreview scrollProgress={scrollYProgress} />
        </div>
        <div className="motion-story-intro">
          <span className="motion-label">A RESPONSE IN MOTION</span>
          <h2 id="story-title">Watch the system answer.</h2>
          <p>Scroll through the sequence. Every beat maps to something Shakti is built to do.</p>
          <span className="motion-story-scroll">
            <ArrowDown size={14} aria-hidden="true" /> Scroll to move through the story
          </span>
        </div>
        <div className="motion-story-scenes">
          {SCENES.map((scene, index) => (
            <SceneCopy
              key={scene.marker}
              scene={scene}
              index={index}
              progress={scrollYProgress}
            />
          ))}
        </div>
        <div className="motion-story-progress" aria-hidden="true">
          <motion.span style={{ width: progressWidth }} />
        </div>
        <div className="motion-story-state" aria-hidden="true">
          <span>
            <Check size={12} /> Local first
          </span>
          <span>
            <Radio size={12} /> Live when online
          </span>
          <span>
            <ShieldCheck size={12} /> Marked safe
          </span>
        </div>
      </div>
    </section>
  );
}
