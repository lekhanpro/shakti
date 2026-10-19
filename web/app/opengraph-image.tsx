import { ImageResponse } from 'next/og';

export const alt = 'Shakti: a safety network that works without internet';
export const size = { width: 1200, height: 630 };
export const contentType = 'image/png';

export default function OpenGraphImage() {
  return new ImageResponse(
    (
      <div
        style={{
          width: '100%',
          height: '100%',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'space-between',
          padding: '72px 84px',
          background: 'linear-gradient(160deg, #0B1220 0%, #070B14 62%)',
          color: '#F1F5F9',
          fontFamily: 'sans-serif',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
          <div
            style={{
              width: '64px',
              height: '64px',
              borderRadius: '32px',
              background: '#4F46E5',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <div style={{ width: '18px', height: '18px', borderRadius: '9px', background: '#fff' }} />
          </div>
          <div style={{ fontSize: '40px', fontWeight: 700, letterSpacing: '-0.02em' }}>Shakti</div>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column' }}>
          <div style={{ fontSize: '76px', fontWeight: 700, lineHeight: 1.08, letterSpacing: '-0.03em' }}>
            One press. Your people
          </div>
          <div style={{ fontSize: '76px', fontWeight: 700, lineHeight: 1.08, letterSpacing: '-0.03em' }}>
            know where you are.
          </div>
          <div style={{ marginTop: '28px', fontSize: '30px', color: '#CBD5E1' }}>
            An SOS built to work without mobile data. By SMS, first.
          </div>
        </div>

        <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '24px', color: '#94A3B8' }}>
          <div style={{ display: 'flex', gap: '28px' }}>
            <span>SMS-first</span>
            <span>Live tracker</span>
            <span>AI guardian</span>
          </div>
          <span>Android</span>
        </div>
      </div>
    ),
    size,
  );
}
