import { Composition } from "remotion";
import { ShaktiPromo } from "./ShaktiPromo";

export const RemotionRoot: React.FC = () => {
  return (
    <Composition
      id="ShaktiPromo"
      component={ShaktiPromo}
      durationInFrames={600}
      fps={30}
      width={1920}
      height={1080}
    />
  );
};
