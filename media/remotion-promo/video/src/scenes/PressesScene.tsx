import { AbsoluteFill, useCurrentFrame } from "remotion";
import { Block, Burst, Note, Phone, Stage, Tag, useSpring } from "../ui";
import { BODY, CYAN, DISPLAY, INK, LILAC, MINT, ORANGE, PAPER, ROSE, YELLOW } from "../theme";

const PRESSES = [20, 38, 56] as const;

export const PressesScene = () => {
  const frame = useCurrentFrame();
  const burst = useSpring(62, 8);
  const dip = Math.max(
    0,
    ...PRESSES.map((p) => {
      const d = frame - p;
      return d >= 0 && d < 6 ? Math.sin((Math.PI * d) / 6) : 0;
    }),
  );
  const phone = useSpring(0, 14);

  return (
    <Stage from="#d9ccff" to="#b6f3ff" blobs={[YELLOW, MINT, CYAN]}>
      <AbsoluteFill style={{ justifyContent: "center", paddingLeft: 120, gap: 24 }}>
        <Block delay={2} size={190} color={YELLOW} rot={-2}>
          3 presses
        </Block>
        <Block delay={9} size={78} rot={1}>
          of the power key
        </Block>
        <div style={{ marginTop: 10, display: "flex", gap: 22, alignItems: "center" }}>
          <Note delay={18} size={38}>
            Inside 1.2 seconds.
          </Note>
          <Tag delay={24} rot={-3} color={MINT} size={28}>
            On by default
          </Tag>
        </div>
      </AbsoluteFill>

      <div style={{ position: "absolute", left: 1210, top: 90, rotate: "4deg", translate: `${(1 - phone) * 300}px 0px` }}>
        <Phone keyPress={dip} width={470} height={900}>
          <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", gap: 10 }}>
            <div style={{ fontFamily: DISPLAY, fontWeight: 700, fontSize: 64, color: PAPER }}>Locked</div>
            <div style={{ fontFamily: BODY, fontWeight: 500, fontSize: 30, color: "#94a3b8" }}>
              Press the side key 3 times
            </div>
            <div style={{ display: "flex", gap: 26, marginTop: 36 }}>
              {PRESSES.map((p) => {
                const on = frame > p + 2;
                return (
                  <div
                    key={p}
                    style={{
                      width: 46,
                      height: 46,
                      borderRadius: "50%",
                      border: `5px solid ${on ? ORANGE : "#334155"}`,
                      background: on ? ORANGE : "transparent",
                      scale: on ? 1 + Math.max(0, 0.35 - (frame - p) * 0.04) : 1,
                    }}
                  />
                );
              })}
            </div>
          </AbsoluteFill>
        </Phone>
      </div>

      <div style={{ position: "absolute", left: 1000, top: 130, scale: burst }}>
        <Burst size={310} fill={ROSE} rotate={frame * 1.2}>
          <span style={{ color: PAPER, fontSize: 62 }}>SOS</span>
        </Burst>
      </div>
      <div style={{ position: "absolute", left: 1000, top: 760 }}>
        <Tag delay={50} rot={5} color={LILAC} size={26} style={{ color: INK }}>
          Same rule as the app
        </Tag>
      </div>
    </Stage>
  );
};
