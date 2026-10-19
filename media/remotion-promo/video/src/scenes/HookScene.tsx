import { AbsoluteFill, interpolate, useCurrentFrame } from "remotion";
import { Block, CLAMP, Glass, Note, Stage, Tag, useSpring } from "../ui";
import { CYAN, DISPLAY, INK, LILAC, ORANGE, PAPER, ROSE, YELLOW, hardShadow } from "../theme";

export const HookScene = () => {
  const frame = useCurrentFrame();
  const pop = useSpring(16, 9);
  const press = interpolate(frame, [44, 48, 54], [1, 0.9, 1], CLAMP);

  return (
    <Stage from="#fff3b0" to="#e9defd" blobs={[CYAN, LILAC, ORANGE]}>
      <AbsoluteFill style={{ justifyContent: "center", paddingLeft: 120, gap: 22 }}>
        <Block delay={2} size={150} color={YELLOW} rot={-2}>
          One press.
        </Block>
        <Block delay={9} size={96} rot={1.5}>
          Your people know
        </Block>
        <Block delay={15} size={96} color={LILAC} rot={-1}>
          where you are.
        </Block>
        <div style={{ marginTop: 14 }}>
          <Note delay={26} size={36}>
            Shakti is built to text your guardians
            <br />
            your location, even with no data.
          </Note>
        </div>
      </AbsoluteFill>

      <div style={{ position: "absolute", left: 1235, top: 250, width: 520, height: 520 }}>
        {[0, 1, 2].map((i) => {
          const k = ((frame + i * 12) % 36) / 36;
          return (
            <div
              key={i}
              style={{
                position: "absolute",
                inset: 40,
                borderRadius: "50%",
                border: `8px solid ${ROSE}`,
                opacity: (1 - k) * 0.85,
                scale: 1 + k * 0.75,
              }}
            />
          );
        })}
        <Glass
          radius={999}
          shadow={14}
          tint={0.55}
          style={{
            position: "absolute",
            inset: 40,
            display: "grid",
            placeItems: "center",
            scale: pop * press,
          }}
        >
          <div
            style={{
              width: 330,
              height: 330,
              borderRadius: "50%",
              background: ROSE,
              border: `8px solid ${INK}`,
              boxShadow: hardShadow(12),
              display: "grid",
              placeItems: "center",
              fontFamily: DISPLAY,
              fontWeight: 800,
              fontSize: 130,
              color: PAPER,
              letterSpacing: -4,
            }}
          >
            SOS
          </div>
        </Glass>
        <div style={{ position: "absolute", left: -30, top: 20 }}>
          <Tag delay={32} rot={-8} color={YELLOW}>
            Android
          </Tag>
        </div>
        <div style={{ position: "absolute", right: -40, bottom: 30 }}>
          <Tag delay={38} rot={6} color={CYAN}>
            Power key x3
          </Tag>
        </div>
      </div>
    </Stage>
  );
};
