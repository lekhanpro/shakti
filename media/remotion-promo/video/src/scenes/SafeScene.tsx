import { AbsoluteFill, interpolate, useCurrentFrame } from "remotion";
import { Block, Burst, CLAMP, Note, Stage, useSpring } from "../ui";
import { CYAN, INK, LILAC, MINT, PAPER, YELLOW, hardShadow } from "../theme";

export const SafeScene = () => {
  const frame = useCurrentFrame();
  const s = useSpring(0, 10);
  const draw = interpolate(frame, [8, 26], [0, 1], CLAMP);

  return (
    <Stage from="#b9f6dc" to="#e8ffd0" blobs={[MINT, CYAN, YELLOW]}>
      <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", gap: 18 }}>
        <div
          style={{
            width: 250,
            height: 250,
            borderRadius: "50%",
            background: MINT,
            border: `8px solid ${INK}`,
            boxShadow: hardShadow(14),
            display: "grid",
            placeItems: "center",
            scale: s,
            marginBottom: 6,
          }}
        >
          <svg width={150} height={150} viewBox="0 0 170 170">
            <path
              d="M24 90 L70 136 L148 38"
              fill="none"
              stroke={INK}
              strokeWidth={24}
              strokeLinecap="round"
              strokeLinejoin="round"
              pathLength={1}
              strokeDasharray={1}
              strokeDashoffset={1 - draw}
            />
          </svg>
        </div>
        <Block delay={6} size={84} color={PAPER} rot={-1} style={{ alignSelf: "center" }}>
          Then you tell them
        </Block>
        <Block delay={11} size={130} color={YELLOW} rot={1} style={{ alignSelf: "center" }}>
          you are safe.
        </Block>
        <div style={{ marginTop: 14 }}>
          <Note delay={18} size={32}>
            Confirm with your PIN. The tracking link stops working 24 hours later.
          </Note>
        </div>
      </AbsoluteFill>
      <div style={{ position: "absolute", left: 1380, top: 140 }}>
        <Burst size={230} fill={LILAC} points={12} rotate={-12 + frame}>
          PIN
        </Burst>
      </div>
    </Stage>
  );
};
