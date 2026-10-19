import "./fonts";
import { TransitionSeries, linearTiming } from "@remotion/transitions";
import { fade } from "@remotion/transitions/fade";
import { flip } from "@remotion/transitions/flip";
import { slide } from "@remotion/transitions/slide";
import { wipe } from "@remotion/transitions/wipe";
import { useVideoConfig } from "remotion";
import { AlertScene } from "./scenes/AlertScene";
import { CountdownScene } from "./scenes/CountdownScene";
import { HookScene } from "./scenes/HookScene";
import { OutroScene } from "./scenes/OutroScene";
import { PressesScene } from "./scenes/PressesScene";
import { SafeScene } from "./scenes/SafeScene";
import { TrackerScene } from "./scenes/TrackerScene";
import { SCENE_FRAMES, TRANSITION_FRAMES } from "./timeline";

const timing = linearTiming({ durationInFrames: TRANSITION_FRAMES });

export const ShaktiPromo = () => {
  const { fps } = useVideoConfig();
  return (
    <TransitionSeries>
      <TransitionSeries.Sequence name="Hook" durationInFrames={SCENE_FRAMES.hook} premountFor={fps}>
        <HookScene />
      </TransitionSeries.Sequence>
      <TransitionSeries.Transition presentation={slide({ direction: "from-right" })} timing={timing} />
      <TransitionSeries.Sequence name="Presses" durationInFrames={SCENE_FRAMES.presses} premountFor={fps}>
        <PressesScene />
      </TransitionSeries.Sequence>
      <TransitionSeries.Transition presentation={wipe({ direction: "from-left" })} timing={timing} />
      <TransitionSeries.Sequence name="Countdown" durationInFrames={SCENE_FRAMES.countdown} premountFor={fps}>
        <CountdownScene />
      </TransitionSeries.Sequence>
      <TransitionSeries.Transition presentation={flip()} timing={timing} />
      <TransitionSeries.Sequence name="Alert" durationInFrames={SCENE_FRAMES.alert} premountFor={fps}>
        <AlertScene />
      </TransitionSeries.Sequence>
      <TransitionSeries.Transition presentation={slide({ direction: "from-bottom" })} timing={timing} />
      <TransitionSeries.Sequence name="Tracker" durationInFrames={SCENE_FRAMES.tracker} premountFor={fps}>
        <TrackerScene />
      </TransitionSeries.Sequence>
      <TransitionSeries.Transition presentation={wipe({ direction: "from-right" })} timing={timing} />
      <TransitionSeries.Sequence name="Safe" durationInFrames={SCENE_FRAMES.safe} premountFor={fps}>
        <SafeScene />
      </TransitionSeries.Sequence>
      <TransitionSeries.Transition presentation={fade()} timing={timing} />
      <TransitionSeries.Sequence name="Outro" durationInFrames={SCENE_FRAMES.outro} premountFor={fps}>
        <OutroScene />
      </TransitionSeries.Sequence>
    </TransitionSeries>
  );
};
