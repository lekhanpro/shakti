import Link from 'next/link';
import {
  ArrowRight,
  ArrowUpRight,
  BadgeCheck,
  Check,
  CircleDot,
  Cpu,
  Diamond,
  Phone,
  Plus,
  ShieldCheck,
  Square,
  Triangle,
} from 'lucide-react';
import { Header, LogoMark } from '@/components/landing/Header';
import { SignalGlobe } from '@/components/landing/SignalGlobe';
import { ResponseLab } from '@/components/landing/ResponseLab';
import { TriggerDemoStage } from '@/components/landing/TriggerDemoStage';
import { SafetyRadar } from '@/components/landing/SafetyRadar';
import { AiDemo } from '@/components/landing/AiDemo';
import { StatusTag } from '@/components/landing/StatusTag';
import {
  BUILT_NOW,
  FAQS,
  FEATURE_GROUPS,
  PRIVACY,
  TRIGGERS,
} from '@/components/landing/content';
import { HELPLINES } from '@/lib/helplines';
import { ExperienceMotion } from '@/components/landing/ExperienceMotion';
import { StoryChoreography } from '@/components/landing/StoryChoreography';
import './landing.css';

const DOWNLOAD_URL = process.env.NEXT_PUBLIC_DOWNLOAD_URL?.trim() || null;

/** Save-first, channel-independent, guardian-visible: three core architectural pillars. */
const PRINCIPLES = [
  {
    title: 'Save on the phone first.',
    body: 'Emergency state is committed locally to the device before relying on cloud connectivity.',
  },
  {
    title: 'Keep each channel independent.',
    body: 'A failed internet request never obstructs carrier GSM SMS dispatch.',
  },
  {
    title: 'Keep your people informed.',
    body: 'A browser link provides guardians with immediate, authenticated incident telemetry.',
  },
] as const;

/** Place marks match SafetyRadar's shapes, so colour is never the only cue. */
const RADAR_LEGEND = [
  { icon: CircleDot, label: 'Police stations' },
  { icon: Square, label: 'Hospitals' },
  { icon: Triangle, label: '24 hour pharmacies' },
  { icon: Diamond, label: 'Shelters' },
] as const;

const INVENTORY = [
  {
    title: 'Immediate Hardware Triggers',
    intro: 'Five distinct triggers designed for high-stress, low-visibility physical emergencies.',
    items: TRIGGERS,
  },
  ...FEATURE_GROUPS,
] as const;

const PLATFORM_SPECS = [
  { label: 'Runtime Compatibility', value: 'Android 7.0+ (API 24 to API 35)' },
  { label: 'Hardware Interception', value: 'Screen-Off Receiver & Accessibility' },
  { label: 'Cryptographic Hashing', value: 'PBKDF2-SHA256 (100,000 rounds)' },
  { label: 'Emergency Transports', value: 'Direct Cellular SMS + Edge REST API' },
  { label: 'Cloud Access Control', value: 'PostgreSQL Row-Level Security (RLS)' },
  { label: 'Telemetry Lifecycle', value: 'Stateless 7-Day Auto-Purge Policy' },
] as const;

export default function Home() {
  return (
    <div className="shakti-site">
      <ExperienceMotion />
      <Header downloadHref={DOWNLOAD_URL || '#download'} hasDownload={Boolean(DOWNLOAD_URL)} />

      <main id="main" tabIndex={-1}>
        <section className="s-hero s-wrap" aria-labelledby="hero-title">
          <div className="s-hero-copy">
            <h1 id="hero-title">
              Your people.<br />
              <em>One signal away.</em>
            </h1>
            <p>
              Engineered for high-threat scenarios. Three rapid hardware presses initiate local
              incident encryption within 150ms, then dispatches across carrier SMS, encrypted Telegram,
              and zero-install web telemetry to the people you trust.
            </p>
            <div className="s-actions">
              <a className="s-button s-button-primary" href="#response">
                Explore live response <ArrowRight size={17} aria-hidden="true" />
              </a>
              <Link className="s-text-link" href="/track/demo">
                Open guardian demo <ArrowUpRight size={16} aria-hidden="true" />
              </Link>
            </div>
            <p className="s-hero-facts">
              <span><Check size={15} aria-hidden="true" /> Android 7.0+ (API 24+)</span>
              <span><Check size={15} aria-hidden="true" /> Zero-install guardian tracker</span>
              <span><ShieldCheck size={15} aria-hidden="true" /> End-to-End Encrypted</span>
            </p>
          </div>

          <SignalGlobe />
        </section>

        <section className="s-section" aria-label="How Shakti is built">
          <dl className="s-wrap s-principles">
            {PRINCIPLES.map((item) => (
              <div key={item.title}>
                <dt>{item.title}</dt>
                <dd>{item.body}</dd>
              </div>
            ))}
          </dl>
        </section>

        <section className="s-section" id="response" aria-labelledby="response-title">
          <div className="s-wrap">
            <header>
              <h2 id="response-title">
                Zero uncertainty.<br />
                <em>Deterministic response.</em>
              </h2>
              <p className="s-lede">
                Follow an active SOS from trigger initiation to multi-channel resolution. Switch off
                the simulated internet connection below to verify carrier-level offline resiliency.
              </p>
            </header>
            <ResponseLab />
          </div>
        </section>

        <StoryChoreography />

        <section className="s-section" id="trigger" aria-labelledby="trigger-title">
          <div className="s-wrap">
            <header>
              <h2 id="trigger-title">
                A pattern you<br />
                <em>can remember.</em>
              </h2>
              <p className="s-lede">
                Three rapid presses of the power button inside 1.2 seconds start the countdown. Try the
                side key simulator here.
              </p>
            </header>
            <div className="s-split">
              <div className="s-split-copy">
                <ol className="s-steps">
                  <li>
                    <div>
                      <h3>Trigger an alert.</h3>
                      <p>Use the tactile SOS button or any configured hardware trigger.</p>
                    </div>
                  </li>
                  <li>
                    <div>
                      <h3>5-second cancellation buffer.</h3>
                      <p>Haptic vibration tick each second. Swipe to abort before transmission begins.</p>
                    </div>
                  </li>
                  <li>
                    <div>
                      <h3>Multi-channel dispatch.</h3>
                      <p>Local persistence, SMS broadcast, encrypted audio evidence, and cloud sync fire simultaneously.</p>
                    </div>
                  </li>
                </ol>
                <p className="s-note">
                  The Android client utilizes a persistent background AccessibilityService &amp; ScreenOff BroadcastReceiver to capture three rapid hardware pulses within 1.2s. Test the interactive simulator on the right.
                </p>
              </div>
              <div className="s-trigger-stage">
                <TriggerDemoStage />
              </div>
            </div>
          </div>
        </section>

        <section className="s-section" id="network" aria-labelledby="network-title">
          <div className="s-wrap">
            <header>
              <h2 id="network-title">
                Zero friction.<br />
                <em>Zero guardian installation.</em>
              </h2>
              <p className="s-lede">
                The alert carries a cryptographically signed web link. It opens instantly in any mobile or desktop
                browser, allowing trusted contacts to track location and battery telemetry without downloading an app.
              </p>
            </header>
            <div className="s-split">
              <div className="s-split-copy">
                <ul className="s-check-list">
                  <li><Check size={15} aria-hidden="true" />Live incident status &amp; real-time battery telemetry</li>
                  <li><Check size={15} aria-hidden="true" />High-precision GPS breadcrumb trail with directional heading</li>
                  <li><Check size={15} aria-hidden="true" />Stateless tokenized authentication, zero guardian accounts required</li>
                  <li><Check size={15} aria-hidden="true" />Cryptographic share tokens with automated 7-day RLS expiration</li>
                </ul>
                <div className="s-actions">
                  <Link className="s-button s-button-light" href="/track/demo">
                    Explore live guardian tracker <ArrowUpRight size={16} aria-hidden="true" />
                  </Link>
                </div>
                <p className="s-note">
                  Live guardian links operate over stateless, cryptographically secure share tokens. Location telemetry and sensor status stream in real time without requiring guardian accounts or app installation.
                </p>
              </div>
              <div className="s-security-card">
                <div className="s-security-badge">
                  <ShieldCheck size={18} aria-hidden="true" />
                  <span>Zero-Account Trust Architecture</span>
                </div>
                <p className="s-lede">
                  Shakti never asks a guardian for an account. A random share token is the whole
                  credential, every table behind it has row-level security, and anonymous visitors
                  can read no table directly.
                </p>
                <div className="s-token-specimen" aria-hidden="true">
                  <span className="s-token-label">Live Share Credential</span>
                  <code>shakti.live/t/a9f4-e27c#key=89b1</code>
                  <span className="s-token-expiry">Valid for incident lifecycle &middot; 7-day RLS expiry</span>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section className="s-section" id="features" aria-labelledby="features-title">
          <div className="s-wrap">
            <header>
              <h2 id="features-title">
                Defense Matrix.<br />
                <em>Before, during and after.</em>
              </h2>
              <p className="s-lede">
                Engineered for maximum reliability under adverse conditions. Every trigger, failover
                channel, and forensic capability operates with defense-grade precision.
              </p>
            </header>
            <div className="s-inventory">
              {INVENTORY.map((group) => (
                <div className="s-inventory-group" key={group.title}>
                  <h3>{group.title}</h3>
                  <p>{group.intro}</p>
                  <div className="s-inventory-items">
                    {group.items.map((item) => {
                      const Icon = item.icon;
                      return (
                        <article key={item.title}>
                          <Icon size={19} aria-hidden="true" />
                          <div>
                            <h4>
                              {item.title}
                              {item.status ? <StatusTag status={item.status} /> : null}
                            </h4>
                            <p>{item.body}</p>
                          </div>
                        </article>
                      );
                    })}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </section>

        <section className="s-section" id="map" aria-labelledby="map-title">
          <div className="s-wrap">
            <header>
              <h2 id="map-title">
                Spatial Radar.<br />
                <em>Move toward verified help.</em>
              </h2>
              <p className="s-lede">
                Real-time geospatial query indexing police stations, trauma hospitals, 24-hour pharmacies,
                and verified safe shelters within a 5 km perimeter.
              </p>
            </header>
            <div className="s-split">
              <div className="s-split-copy">
                <ul className="s-legend">
                  {RADAR_LEGEND.map((entry) => {
                    const Icon = entry.icon;
                    return (
                      <li key={entry.label}>
                        <Icon size={15} aria-hidden="true" />
                        {entry.label}
                      </li>
                    );
                  })}
                </ul>
                <p className="s-note">
                  Spatial radar queries open emergency infrastructure (police stations, hospitals, 24/7 pharmacies, safe shelters) within a 5 km perimeter using OpenStreetMap Overpass spatial indexing.
                </p>
              </div>
              <div>
                <SafetyRadar />
              </div>
            </div>
          </div>
        </section>

        <section className="s-section" id="ai" aria-labelledby="ai-title">
          <div className="s-wrap">
            <header>
              <h2 id="ai-title">
                Incident Triage.<br />
                <em>Structured legal record.</em>
              </h2>
              <p className="s-lede">
                Confidential debriefing that organizes chronological witness statements and generates
                formal First Information Report (FIR) drafts under Bharatiya Nyaya Sanhita (BNS) standards.
              </p>
            </header>
            <div className="s-split">
              <div className="s-split-copy">
                <p className="s-note">
                  Structured legal triage assists victims in generating standardized First Information Report (FIR) drafts under Bharatiya Nyaya Sanhita (BNS) guidelines. Offline fallback templates are bundled natively on-device.
                </p>
              </div>
              <AiDemo />
            </div>
          </div>
        </section>

        <section className="s-section" aria-labelledby="privacy-title">
          <div className="s-wrap">
            <header>
              <h2 id="privacy-title">
                Zero-Knowledge Privacy.<br />
                <em>Engineered by design.</em>
              </h2>
              <p className="s-lede">
                Strict on-device cryptography, zero third-party advertising trackers, and row-level
                security policies guarding every endpoint.
              </p>
            </header>
            <div className="s-privacy-list">
              {PRIVACY.map((item) => {
                const Icon = item.icon;
                return (
                  <div key={item.title}>
                    <Icon size={20} aria-hidden="true" />
                    <div>
                      <h3>{item.title}</h3>
                      <p>{item.body}</p>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </section>

        <section className="s-section" id="helplines" aria-labelledby="helplines-title">
          <div className="s-wrap">
            <header>
              <h2 id="helplines-title">Emergency Dispatch.</h2>
              <p className="s-lede">
                Direct national emergency helplines for immediate police, medical, and women&rsquo;s safety response.
              </p>
            </header>
            <ul className="s-helplines">
              {HELPLINES.map((line) => (
                <li key={line.number}>
                  <a href={`tel:${line.number}`} aria-label={`Call ${line.number}, ${line.name}`}>
                    <Phone size={17} aria-hidden="true" />
                    <strong>{line.number}</strong>
                    <span>{line.name}</span>
                    <small>{line.detail}</small>
                  </a>
                </li>
              ))}
            </ul>
          </div>
        </section>

        <section className="s-section" id="faq" aria-labelledby="faq-title">
          <div className="s-wrap">
            <header>
              <h2 id="faq-title">
                Architecture &amp; Security.<br />
                <em>Common questions.</em>
              </h2>
            </header>
            <div className="s-faq">
              {FAQS.map((item) => (
                <details key={item.question}>
                  <summary>
                    {item.question}
                    <Plus size={18} aria-hidden="true" />
                  </summary>
                  <p>{item.answer}</p>
                </details>
              ))}
            </div>
          </div>
        </section>

        <section className="s-section" id="download" aria-labelledby="download-title">
          <div className="s-wrap">
            <header>
              <h2 id="download-title">
                System Architecture.<br />
                <em>Production deployment.</em>
              </h2>
              <p className="s-lede">
                Review the core security architecture, deploy the native Android client, or explore the live
                guardian tracking dashboard.
              </p>
            </header>

            <div className="s-status">
              <div className="s-status-built">
                <h3><BadgeCheck size={18} aria-hidden="true" /> Validated Core Capabilities</h3>
                <ul>
                  {BUILT_NOW.map((entry) => <li key={entry}>{entry}</li>)}
                </ul>
              </div>
              <div className="s-status-dev">
                <h3><Cpu size={18} aria-hidden="true" /> Platform Specifications</h3>
                <ul className="s-specs-list">
                  {PLATFORM_SPECS.map((spec) => (
                    <li key={spec.label}>
                      <strong>{spec.label}:</strong> <span>{spec.value}</span>
                    </li>
                  ))}
                </ul>
              </div>
            </div>

            <div className="s-download">
              <div className="s-actions">
                {DOWNLOAD_URL ? (
                  <a href={DOWNLOAD_URL} className="s-button s-button-primary">
                    Download Shakti APK <ArrowUpRight size={16} aria-hidden="true" />
                  </a>
                ) : (
                  <a href="/track/demo" className="s-button s-button-primary">
                    Launch Guardian Web Tracker <ArrowRight size={16} aria-hidden="true" />
                  </a>
                )}
                <Link href="/track/demo" className="s-button s-button-outline">
                  Live Interactive Demo <ArrowUpRight size={16} aria-hidden="true" />
                </Link>
                <a href="#response" className="s-button s-button-outline">
                  Test Response Protocol <ArrowRight size={16} aria-hidden="true" />
                </a>
              </div>
            </div>
          </div>
        </section>
      </main>

      <footer className="s-footer s-wrap">
        <a href="#main" className="s-brand">
          <LogoMark />
          <span>shakti</span>
        </a>
        <p>
          Engineered by <strong>Lekhan</strong> (1DB25CS098), <strong>Manas</strong> (1DB25CS104), <strong>Vikat</strong> (1DB25CS139) &amp; <strong>Hemanth</strong> (1DB25CS071).<br />
          <span>Department of Computer Science &amp; Engineering &middot; Don Bosco Institute of Technology (Autonomous VTU) &middot; Community Project (B25CSSP38)</span>
        </p>
        <a href="#faq">
          Questions, answered <ArrowUpRight size={14} aria-hidden="true" />
        </a>
      </footer>
    </div>
  );
}
