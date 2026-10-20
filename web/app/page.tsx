import Link from 'next/link';
import { ArrowDown, ArrowRight, ArrowUpRight, AudioLines, Check, Fingerprint, LockKeyhole, MapPin, MessageCircle, Phone, Plus, Radio, ShieldCheck, Timer, WifiOff } from 'lucide-react';
import { Header, LogoMark } from '@/components/landing/Header';
import { EarthField } from '@/components/landing/EarthField';
import { StoryChoreography } from '@/components/landing/StoryChoreography';
import { GuardianMesh } from '@/components/landing/GuardianMesh';
import { SafetyRadar } from '@/components/landing/SafetyRadar';
import { StatusTag } from '@/components/landing/StatusTag';
import { GuardianSculpture } from '@/components/landing/GuardianSculpture';
import { ResponseLab } from '@/components/landing/ResponseLab';
import { AiDemo } from '@/components/landing/AiDemo';
import { TriggerDemoStage } from '@/components/landing/TriggerDemoStage';
import { FAQS, FEATURE_GROUPS, PRIVACY, TRIGGERS } from '@/components/landing/content';
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

const PRIVACY_POINTS = PRIVACY;

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
          <div className="s-hero-art"><EarthField /><div className="s-floating-note"><span className="s-note-symbol"><ShieldCheck size={19} aria-hidden="true" /></span><span><strong>Built around your circle.</strong><small>Contacts. Context. A way to check in.</small></span></div></div>
          <div className="s-hero-foot"><span>DBIT COMMUNITY PROJECT / SHAKTI</span><a href="#story">A closer look <ArrowDown size={14} aria-hidden="true" /></a></div>
        </section>

        <section className="s-principles" aria-label="Shakti principles"><div className="s-wrap s-principles-grid"><div><span>01</span><strong>Save on the phone first.</strong><p>Emergency state belongs on the device before it depends on the cloud.</p></div><div><span>02</span><strong>Keep each channel independent.</strong><p>A failed internet request should not hold up carrier SMS.</p></div><div><span>03</span><strong>Keep your people informed.</strong><p>A browser link gives guardians the incident context available to share.</p></div></div></section>

        <section className="s-section s-wrap" id="story" aria-labelledby="story-title">
          <div className="s-section-heading"><div><p className="s-eyebrow">01 / UNDERSTAND THE RESPONSE</p><h2 id="story-title">Less uncertainty.<br /><em>A visible next step.</em></h2></div><p>Follow an ordinary SOS from setup to resolution. Switch off the simulated internet connection and see which channels keep their independence.</p></div>
          <ResponseLab />
        </section>

        <StoryChoreography />

        <section className="s-trigger-section" id="trigger" aria-labelledby="trigger-title"><div className="s-wrap s-trigger-layout"><div className="s-trigger-copy"><p className="s-eyebrow">02 / MAKE THE FIRST MOVE</p><h2 id="trigger-title">A pattern you<br /><em>can remember.</em></h2><p>Three quick power-button presses can start the ordinary SOS countdown. Try the phone's side key in this browser demonstration.</p><ol className="s-step-list"><li><span>01</span><div><h3>Trigger an alert.</h3><p>Use the SOS button or a configured alternative trigger.</p></div></li><li><span>02</span><div><h3>Keep a cancellation window.</h3><p>Five seconds by default. Cancel before the alert channels begin.</p></div></li><li><span>03</span><div><h3>See what each channel did.</h3><p>Local save, SMS, evidence, and cloud status remain distinct.</p></div></li></ol><p className="s-small-note">Hardware power/volume behavior varies by Android device. This demonstration does not test your phone's physical buttons.</p></div><div className="s-trigger-demo"><span className="s-micro">BROWSER DEMO / NO ALERTS SENT</span><TriggerDemoStage /></div></div></section>

        <section className="s-section s-wrap" id="network" aria-labelledby="network-title"><div className="s-section-heading"><div><p className="s-eyebrow">03 / YOUR TRUSTED CIRCLE</p><h2 id="network-title">They don't need<br /><em>another app.</em></h2></div><p>Guardians can open the shared tracker in a browser. When the app has synced, it shows the incident, location trail, battery, and latest update.</p></div><div className="s-guardian-panel"><div className="s-mesh-illustration"><span className="s-micro">GUARDIAN MESH / ORIGINAL DEMO</span><GuardianMesh /><p>One illustrated alert. Your trusted circle.</p></div><div className="s-guardian-copy"><span className="s-pill">GUARDIAN VIEW</span><h3>Enough context.<br />Less guesswork.</h3><p>The tracker checks for updates every ten seconds while visible. Location freshness depends on the phone, connectivity, and uploaded data.</p><ul className="s-check-list"><li><Check size={15} />Incident status and last update</li><li><Check size={15} />Available trail and battery information</li><li><Check size={15} />Token-based link, no guardian installation</li></ul><Link className="s-button s-button-light" href="/track/demo">Explore a simulated walk <ArrowUpRight size={16} /></Link><small>The demo uses synthetic data.</small></div></div></section>

        <section className="s-section s-feature-section" id="features" aria-labelledby="features-title"><div className="s-wrap"><div className="s-section-heading"><div><p className="s-eyebrow">04 / BEFORE, DURING, AFTER</p><h2 id="features-title">One thoughtful system.<br /><em>More ways to help.</em></h2></div><p>From the first alert to a record of what happened, each feature has a role—and clear requirements.</p></div><div className="s-feature-grid">{FEATURES.map((feature, index) => { const Icon = feature.icon; return <article key={feature.title} className="s-feature"><div className="s-feature-top"><span className="s-feature-icon"><Icon size={22} aria-hidden="true" /></span><span className="s-micro">0{index + 1}</span></div><span className="s-feature-tag">{feature.tag}</span><h3>{feature.title}</h3><p>{feature.body}</p></article>; })}</div></div></section>

        <section className="s-section s-wrap s-retained-map" id="map" aria-labelledby="map-title"><div><p className="s-eyebrow">THE ORIGINAL SAFETY RADAR</p><h2 id="map-title">Look around.<br /><em>Move toward help.</em></h2><p>Explore nearby police stations, hospitals, pharmacies, and shelters from OpenStreetMap. Place availability and opening hours need verification. A suggested route is not a guarantee of safety.</p><ul className="s-radar-legend"><li>● Police</li><li>■ Hospital</li><li>▲ Pharmacy</li><li>◆ Shelter</li></ul><small>Illustration only. Fresh map, place, and route requests need internet.</small></div><div><SafetyRadar /></div></section>

        <section className="s-section s-wrap s-toolkit" aria-labelledby="toolkit-title"><div className="s-section-heading"><div><p className="s-eyebrow">THE COMPLETE TOOLKIT</p><h2 id="toolkit-title">Every original feature.<br /><em>A clearer place in the story.</em></h2></div><p>Explore the existing triggers and supporting tools. The implementation is available; hardware reliability and delivery still need real-device checks.</p></div><details className="s-toolkit-details"><summary>Explore all triggers and features <Plus size={19} aria-hidden="true" /></summary><div className="s-toolkit-grid">{[{ title: 'Ways to trigger', items: TRIGGERS }, ...FEATURE_GROUPS].map((group) => <div key={group.title}><h3>{group.title}</h3>{group.items.map((item) => { const Icon = item.icon; return <article key={item.title}><Icon size={19} aria-hidden="true" /><div><h4>{item.title}</h4><p>{item.body}</p>{item.status ? <StatusTag status={item.status} /> : null}</div></article>; })}</div>)}</div></details></section>

        <section className="s-section s-wrap s-product-object" aria-labelledby="object-title"><div><p className="s-eyebrow">FROM YOUR PHONE TO YOUR CIRCLE</p><h2 id="object-title">The signal has<br /><em>a starting point.</em></h2><p>The globe tells the wider story. This new 3D product study puts your phone at the center, with independently controllable motion and guardian paths.</p></div><GuardianSculpture /></section>

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
