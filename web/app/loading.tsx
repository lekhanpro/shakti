import './landing.css';

export default function Loading() {
  return <main id="main" className="shakti-site s-loading" aria-busy="true"><div role="status"><span className="s-loading-mark" aria-hidden="true"><i /><i /><i /></span><strong>shakti</strong><p>Opening your safety network.</p><span className="sr-only">Loading page</span></div></main>;
}
