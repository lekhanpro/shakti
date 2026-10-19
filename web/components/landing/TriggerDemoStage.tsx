'use client';

import { PressDemo } from './PressDemo';
import { Tilt } from '@/components/motion/Tilt';

export function TriggerDemoStage() {
  return (
    <div className="v2-phone-stage-inner">
      <div className="v2-phone-stage-grid" aria-hidden="true" />
      <Tilt max={8}>
        <PressDemo />
      </Tilt>
      <div className="v2-phone-caption"><span>01</span> press the side key three times, fast</div>
    </div>
  );
}
