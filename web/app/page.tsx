import Link from 'next/link';
import { ArrowDown, ArrowRight, ArrowUpRight, AudioLines, Check, Fingerprint, LockKeyhole, MapPin, MessageCircle, Phone, Plus, Radio, ShieldCheck, Timer, WifiOff } from 'lucide-react';
import { Header, LogoMark } from '@/components/landing/Header';
import { GuardianSculpture } from '@/components/landing/GuardianSculpture';
import { ResponseLab } from '@/components/landing/ResponseLab';
import { AiDemo } from '@/components/landing/AiDemo';
import { TriggerDemoStage } from '@/components/landing/TriggerDemoStage';
import { FAQS } from '@/components/landing/content';
import { HELPLINES } from '@/lib/helplines';
import { ExperienceMotion } from '@/components/landing/ExperienceMotion';
import { ArrivalIntro } from '@/components/landing/ArrivalIntro';
import './landing.css';

const DOWNLOAD_URL = process.env.NEXT_PUBLIC_DOWNLOAD_URL?.trim() || null;
const FEATURES = [
  { icon: Radio, title: 'A message without mobile data.', body: 'Carrier SMS runs independently of internet requests. A SIM, cellular service, and SMS permission are still needed.', tag: 'LOCAL CHANNEL' },
  { icon: Timer, title: 'Walk with someone in mind.', body: 'Set an escort timer, check in with your PIN, and let expiry raise an SOS. Test background behavior on your phone.', tag: 'WALK WITH ME' },
  { icon: Fingerprint, title: 'A quieter way to ask for help.', body: 'The duress PIN opens a decoy notes screen and starts a silent alert, bypassing the ordinary countdown.', tag: 'DISCREET TRIGGER' },
  { icon: AudioLines, title: 'Keep a record on your terms.', body: 'Optional audio evidence is encrypted on the device. Microphone permission and available storage are required.', tag: 'EVIDENCE VAULT' },
  { icon: MapPin, title: 'Find useful places around you.', body: 'Explore nearby police stations, hospitals, and pharmacies. Fresh map data and routes need internet.', tag: 'SAFETY MAP' },
  { icon: MessageCircle, title: 'Find the words afterwards.', body: 'AI assistance and an FIR draft help organize details. An offline template is available; you review the final text.', tag: 'AFTER THE MOMENT' },
] as const;

const PRIVACY_POINTS = [
  { icon: LockKeyhole, title: 'Your PIN stays on the phone.', body: 'Salted PIN hashing and secure-storage integration protect access to the app.' },
  { icon: ShieldCheck, title: 'Only a limited view is shared.', body: 'Guardians use a random token to read a restricted incident view. Treat that link as private.' },
  { icon: WifiOff, title: 'Local first. Connected when available.', body: 'Incidents and location points can wait in a local queue until the backend is reachable.' },
] as const;

export default function Home() {
  return (
    <div className="shakti-site">
      <ArrivalIntro />
      <ExperienceMotion />
      <Header downloadHref={DOWNLOAD_URL || '#download'} hasDownload={Boolean(DOWNLOAD_URL)} />
      <main id="main" tabIndex={-1}>
        <section className="s-hero s-wrap" aria-labelledby="hero-title">
          <div className="s-hero-copy">
            <p className="s-eyebrow"><span className="s-dot" /> ANDROID PERSONAL SAFETY NETWORK</p>
            <h1 id="hero-title">Your people.<br /><em>One signal away.</em></h1>
            <p className="s-hero-description">A small action on your phone. A clearer way to reach the people who care. Shakti brings SOS, trusted contacts, and guardian tracking into one local-first safety app.</p>
            <div className="s-actions"><a className="s-button s-button-primary" href="#story">Explore the response <ArrowRight size={17} aria-hidden="true" /></a><Link className="s-text-link" href="/track/demo">Try the guardian demo <ArrowUpRight size={16} aria-hidden="true" /></Link></div>
            <div className="s-hero-facts"><span><Check size={15} aria-hidden="true" /> Android app</span><span><Check size={15} aria-hidden="true" /> No guardian install</span><span>Alpha preparation</span></div>
          </div>
          <div className="s-hero-art"><GuardianSculpture /><div className="s-floating-note"><span className="s-note-symbol"><ShieldCheck size={19} aria-hidden="true" /></span><span><strong>Built around your circle.</strong><small>Contacts. Context. A way to check in.</small></span></div></div>
          <div className="s-hero-foot"><span>DBIT COMMUNITY PROJECT / SHAKTI</span><a href="#story">A closer look <ArrowDown size={14} aria-hidden="true" /></a></div>
        </section>

        <section className="s-principles" aria-label="Shakti principles"><div className="s-wrap s-principles-grid"><div><span>01</span><strong>Save on the phone first.</strong><p>Emergency state belongs on the device before it depends on the cloud.</p></div><div><span>02</span><strong>Keep each channel independent.</strong><p>A failed internet request should not hold up carrier SMS.</p></div><div><span>03</span><strong>Keep your people informed.</strong><p>A browser link gives guardians the incident context available to share.</p></div></div></section>

        <section className="s-section s-wrap" id="story" aria-labelledby="story-title">
          <div className="s-section-heading"><div><p className="s-eyebrow">01 / UNDERSTAND THE RESPONSE</p><h2 id="story-title">Less uncertainty.<br /><em>A visible next step.</em></h2></div><p>Follow an ordinary SOS from setup to resolution. Switch off the simulated internet connection and see which channels keep their independence.</p></div>
          <ResponseLab />
        </section>

        <section className="s-trigger-section" id="trigger" aria-labelledby="trigger-title"><div className="s-wrap s-trigger-layout"><div className="s-trigger-copy"><p className="s-eyebrow">02 / MAKE THE FIRST MOVE</p><h2 id="trigger-title">A pattern you<br /><em>can remember.</em></h2><p>Three quick power-button presses can start the ordinary SOS countdown. Try the phone's side key in this browser demonstration.</p><ol className="s-step-list"><li><span>01</span><div><h3>Trigger an alert.</h3><p>Use the SOS button or a configured alternative trigger.</p></div></li><li><span>02</span><div><h3>Keep a cancellation window.</h3><p>Five seconds by default. Cancel before the alert channels begin.</p></div></li><li><span>03</span><div><h3>See what each channel did.</h3><p>Local save, SMS, evidence, and cloud status remain distinct.</p></div></li></ol><p className="s-small-note">Hardware power/volume behavior varies by Android device. This demonstration does not test your phone's physical buttons.</p></div><div className="s-trigger-demo"><span className="s-micro">BROWSER DEMO / NO ALERTS SENT</span><TriggerDemoStage /></div></div></section>

        <section className="s-section s-wrap" id="network" aria-labelledby="network-title"><div className="s-section-heading"><div><p className="s-eyebrow">03 / YOUR TRUSTED CIRCLE</p><h2 id="network-title">They don't need<br /><em>another app.</em></h2></div><p>Guardians can open the shared tracker in a browser. When the app has synced, it shows the incident, location trail, battery, and latest update.</p></div><div className="s-guardian-panel"><div className="s-map-illustration" aria-hidden="true"><div className="s-map-street s-map-street-one" /><div className="s-map-street s-map-street-two" /><div className="s-map-street s-map-street-three" /><svg viewBox="0 0 600 300"><path d="M85 245 L190 245 L190 170 Q190 145 215 145 L335 145 L335 70 L460 70" /><circle cx="85" cy="245" r="8" /><circle cx="460" cy="70" r="10" /></svg><div className="s-map-pin"><span /><strong>Illustrative route</strong><small>No live location is used</small></div><span className="s-map-caption">LOCATION SHARED DURING AN INCIDENT</span></div><div className="s-guardian-copy"><span className="s-pill">GUARDIAN VIEW</span><h3>Enough context.<br />Less guesswork.</h3><p>The tracker checks for updates every ten seconds while visible. Location freshness depends on the phone, connectivity, and uploaded data.</p><ul className="s-check-list"><li><Check size={15} />Incident status and last update</li><li><Check size={15} />Available trail and battery information</li><li><Check size={15} />Token-based link, no guardian installation</li></ul><Link className="s-button s-button-light" href="/track/demo">Explore a simulated walk <ArrowUpRight size={16} /></Link><small>The demo uses synthetic data.</small></div></div></section>

        <section className="s-section s-feature-section" id="map" aria-labelledby="features-title"><div className="s-wrap"><div className="s-section-heading"><div><p className="s-eyebrow">04 / BEFORE, DURING, AFTER</p><h2 id="features-title">One thoughtful system.<br /><em>More ways to help.</em></h2></div><p>From the first alert to a record of what happened, each feature has a role—and clear requirements.</p></div><div className="s-feature-grid">{FEATURES.map((feature, index) => { const Icon = feature.icon; return <article key={feature.title} className="s-feature"><div className="s-feature-top"><span className="s-feature-icon"><Icon size={22} aria-hidden="true" /></span><span className="s-micro">0{index + 1}</span></div><span className="s-feature-tag">{feature.tag}</span><h3>{feature.title}</h3><p>{feature.body}</p></article>; })}</div></div></section>

        <section className="s-section s-wrap s-ai-layout" id="ai" aria-labelledby="ai-title"><div><p className="s-eyebrow">05 / WHEN WORDS ARE HARD</p><h2 id="ai-title">Talk it through.<br /><em>Make a record.</em></h2><p className="s-lead">Organize what happened, consider practical next steps, and prepare a draft you can review. AI assistance needs internet and a configured backend; the FIR template can work offline.</p><div className="s-inline-note"><MessageCircle size={20} aria-hidden="true" /><p>This is a scripted product demonstration. An AI draft is not an official complaint submission.</p></div></div><div className="s-ai-demo"><span className="s-micro">AI GUARDIAN / SCRIPTED DEMO</span><AiDemo /></div></section>

        <section className="s-privacy-section"><div className="s-wrap s-privacy-layout"><div><p className="s-eyebrow">06 / YOUR BOUNDARIES MATTER</p><h2>Your safety data<br /><em>deserves care.</em></h2><p>Designed with local storage, controlled sharing, and server-side credentials. Physical-device and security validation still matter.</p></div><div className="s-privacy-list">{PRIVACY_POINTS.map((item) => { const Icon = item.icon; return <div key={item.title}><Icon size={21} aria-hidden="true" /><div><h3>{item.title}</h3><p>{item.body}</p></div></div>; })}</div></div></section>

        <section id="helplines" className="s-section s-wrap" aria-labelledby="helplines-title"><div className="s-section-heading"><div><p className="s-eyebrow">IF YOU NEED HELP NOW</p><h2 id="helplines-title">Call directly.</h2></div><p>Shakti helps you reach trusted people. It does not replace contacting emergency services.</p></div><ul className="s-helpline-grid">{HELPLINES.map((line) => <li key={line.number}><a href={`tel:${line.number}`} aria-label={`Call ${line.number}, ${line.name}`}><Phone size={19} aria-hidden="true" /><strong>{line.number}</strong><span>{line.name}</span><ArrowUpRight size={16} aria-hidden="true" /></a></li>)}</ul></section>

        <section id="faq" className="s-section s-wrap s-faq-layout" aria-labelledby="faq-title"><div><p className="s-eyebrow">THE DETAILS, CLEARLY</p><h2 id="faq-title">Before you<br /><em>take it with you.</em></h2></div><div className="s-faq-list">{FAQS.map((item) => <details key={item.question}><summary>{item.question}<Plus size={18} aria-hidden="true" /></summary><p>{item.answer}</p></details>)}</div></section>

        <section id="download" className="s-wrap s-download" aria-labelledby="download-title"><div className="s-download-lines" aria-hidden="true"><span /><span /><span /></div><div><p className="s-eyebrow">SET IT UP BEFORE YOU NEED IT</p><h2 id="download-title">A little preparation.<br /><em>A closer circle.</em></h2><p>Choose trusted contacts, review permissions, and run a controlled test together.</p><div className="s-actions">{DOWNLOAD_URL ? <a href={DOWNLOAD_URL} className="s-button s-button-primary">Get the Android app <ArrowUpRight size={16} /></a> : <span className="s-release-note">Alpha preparation · download link coming when available</span>}<Link href="/track/demo" className="s-button s-button-outline">Try the guardian demo <ArrowRight size={16} /></Link></div><small>Android 7.0+ · physical-device validation in progress</small></div></section>
      </main>
      <div className="s-closing-wordmark" aria-hidden="true"><span>YOUR CIRCLE. YOUR SIGNAL.</span><strong>shakti<span>.</span></strong></div>
      <footer className="s-footer s-wrap"><a href="#main" className="s-brand"><LogoMark /><span>shakti</span></a><p>Built by Lekhan, Manas, Vikat &amp; Hemanth.<br /><span>DBIT · VTU 1BCP308 Community Project</span></p><a href="#faq">Questions, answered <ArrowUpRight size={14} /></a></footer>
    </div>
  );
}
