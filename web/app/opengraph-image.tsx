import { ImageResponse } from 'next/og';

export const alt = 'Shakti: Your people. One signal away. Personal Safety Network.';
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
          // --color-deep to --color-night, the page's own ground.
          background: 'linear-gradient(160deg, #0F172A 0%, #070B14 62%)',
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
            <svg width="52" height="52" viewBox="0 0 256 256" fill="none">
              <path d="M128 30 L204 59 L204 120 C204 169 169 205 128 226 C87 205 52 169 52 120 L52 59 Z" stroke="#F8FAFC" strokeWidth="12" />
              <path d="M136 75 C143 96 165 117 159 139 C156 157 141 171 124 170 C102 169 89 153 93 134 C95 122 103 113 111 104 C108 121 115 131 124 134 C117 116 124 91 136 75 Z" fill="#F8FAFC" />
            </svg>
          </div>
          <div style={{ fontSize: '40px', fontWeight: 700, letterSpacing: '-0.02em' }}>Shakti</div>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column' }}>
          <div style={{ fontSize: '76px', fontWeight: 700, lineHeight: 1.08, letterSpacing: '-0.03em' }}>
            Your people.
          </div>
          {/* Second line in --ink-3, mirroring the page's own heading emphasis. */}
          <div style={{ fontSize: '76px', fontWeight: 700, lineHeight: 1.08, letterSpacing: '-0.03em', color: '#94A3B8' }}>
            One signal away.
          </div>
          <div style={{ marginTop: '28px', fontSize: '30px', color: '#CBD5E1' }}>
            Personal Safety Network
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
