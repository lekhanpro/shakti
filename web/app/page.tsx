import Link from 'next/link';
import { ArrowDownRight, ArrowRight, ArrowUpRight, Bot, Download, EyeOff, FileLock2, MessageCircleMore, Phone, Plus, Timer, Volume2 } from 'lucide-react';
import { AiDemo } from '@/components/landing/AiDemo';
import { GuardianMesh } from '@/components/landing/GuardianMesh';
import { Header, LogoMark } from '@/components/landing/Header';
import { EarthField } from '@/components/landing/EarthField';
import { SafetyRadar } from '@/components/landing/SafetyRadar';
import { StatusTag } from '@/components/landing/StatusTag';
import { StoryChoreography } from '@/components/landing/StoryChoreography';
import { TriggerDemoStage } from '@/components/landing/TriggerDemoStage';
import { Magnet } from '@/components/motion/Magnet';
import { Reveal } from '@/components/motion/Reveal';
import { ScrollProgress } from '@/components/motion/ScrollProgress';
import { SmoothScroll } from '@/components/motion/SmoothScroll';
import { HELPLINES } from '@/lib/helplines';
import { FAQS, FEATURE_GROUPS, PRIVACY } from '@/components/landing/content';

const DOWNLOAD_URL = process.env.NEXT_PUBLIC_DOWNLOAD_URL || '#download';

export default function Home() {
  return (
    <>
      <SmoothScroll />
      <ScrollProgress />
      <Header downloadHref={DOWNLOAD_URL} />

      <main id="main" tabIndex={-1} className="motion-world outline-none">
        <section className="motion-hero" aria-labelledby="hero-title">
          <div className="motion-hero-giant" aria-hidden="true">SHAKTI</div>
          <div className="motion-hero-rail motion-hero-rail-left" aria-hidden="true"><span>01</span><span className="motion-hero-rail-line" /><span>06</span></div>
          <div className="motion-hero-rail motion-hero-rail-right" aria-hidden="true"><span>12.9716° N</span><span>77.5946° E</span></div>
          <div className="motion-hero-inner">
            <Reveal className="motion-hero-copy">
              <div className="motion-label motion-label-acid"><span className="motion-live-dot" /> personal safety / always on</div>
              <h1 id="hero-title">Three presses.<br /><em>A whole network.</em></h1>
              <p>Shakti turns a small physical action into a response your guardians can follow.</p>
              <div className="motion-hero-actions"><Magnet><a href="#trigger" className="motion-button motion-button-acid">Try the trigger <ArrowDownRight size={17} aria-hidden="true" /></a></Magnet><a href="#story" className="motion-inline-link">See how it moves <ArrowRight size={16} aria-hidden="true" /></a></div>
            </Reveal>
            <Reveal delay={140} className="motion-hero-object"><EarthField /><div className="motion-hero-object-caption"><span>earth / 001</span><span>ready to answer</span></div></Reveal>
          </div>
          <div className="motion-hero-bottom"><span>Scroll to enter the response</span><span className="motion-scroll-line" /><span>Android 7.0+</span></div>
        </section>

        <section className="motion-manifesto" aria-labelledby="manifesto-title">
          <div className="motion-manifesto-top"><span className="motion-label">WHY SHAKTI EXISTS</span><span>02 / 06</span></div>
          <div className="motion-manifesto-copy"><h2 id="manifesto-title">A safety app should not feel like another thing to manage.</h2><p>It should feel like a rhythm you remember when the rest of the world gets loud.</p></div>
          <div className="motion-manifesto-orbit" aria-hidden="true"><span /><span /><span /></div>
          <div className="motion-marquee" aria-hidden="true"><span>PRESS · PAUSE · RESPOND · PRESS · PAUSE · RESPOND · </span><span>PRESS · PAUSE · RESPOND · PRESS · PAUSE · RESPOND · </span></div>
        </section>

        <StoryChoreography />

        <section id="trigger" className="motion-trigger" aria-labelledby="trigger-title">
          <div className="motion-trigger-background" aria-hidden="true"><span>3</span><span>3</span></div>
          <div className="motion-section-head motion-trigger-head"><div><span className="motion-label">THE FIRST MOVE / 03</span><h2 id="trigger-title">The trigger is<br /><em>simple on purpose.</em></h2></div><p>One physical pattern. A five second pause. Enough time to change your mind.</p></div>
          <div className="motion-trigger-stage"><div className="motion-trigger-phone"><TriggerDemoStage /></div><div className="motion-trigger-info"><div className="motion-big-stat"><strong>01.2</strong><span>seconds<br />to recognize<br />the pattern</span></div><div className="motion-trigger-steps"><div><span>01</span><strong>press × 3</strong><p>Power button, fast.</p></div><div><span>02</span><strong>pause 5s</strong><p>Swipe to cancel.</p></div><div><span>03</span><strong>response</strong><p>The incident is saved locally first.</p></div></div><div className="motion-trigger-alts"><span>Other built triggers</span><div><span><Volume2 size={14} /> volume ×3 <StatusTag status="built" /></span><span><Timer size={14} /> walk with me <StatusTag status="built" /></span><span><EyeOff size={14} /> duress PIN <StatusTag status="built" /></span></div></div></div></div>
        </section>

        <section id="network" className="motion-network" aria-labelledby="network-title">
          <div className="motion-network-grid" aria-hidden="true" />
          <div className="motion-section-head"><div><span className="motion-label motion-label-dark">THE SIGNAL / 04</span><h2 id="network-title">One phone.<br /><em>Many people.</em></h2></div><p>Guardians open a link in any browser. No app. No sign-up. Just the part they need to see.</p></div>
          <div className="motion-network-stage"><div className="motion-network-stage-top"><span>GUARDIAN MESH / ILLUSTRATION</span><span><i /> CONNECTED</span></div><GuardianMesh /><div className="motion-network-stage-bottom"><span>you</span><span className="motion-network-dash" /><span>guardians</span><span className="motion-network-dash" /><span>tracker link</span></div></div>
          <div className="motion-network-notes"><div><span>01</span><strong>Saved locally</strong><p>The incident is written to the phone before the next channel follows.</p></div><div><span>02</span><strong>Sent outward</strong><p>Telegram posts the alert when a chat is set up and data is available.</p></div><div><span>03</span><strong>Watched live</strong><p>Route, battery, and distance refresh every 10 seconds.</p></div></div>
          <Link href="/track/demo" className="motion-inline-link motion-inline-link-dark">Open the demo tracker <ArrowUpRight size={16} /></Link>
        </section>

        <section id="map" className="motion-map" aria-labelledby="map-title">
          <div className="motion-map-top"><span className="motion-label">THE NEXT SAFEST STEP / 05</span><span>5 KM RADIUS</span></div>
          <div className="motion-map-layout"><div className="motion-map-copy"><h2 id="map-title">Look around.<br /><em>Move toward help.</em></h2><p>Police stations, hospitals, 24 hour pharmacies, and shelters from OpenStreetMap, around where you are.</p><div className="motion-map-legend"><span><i className="legend-circle" /> police</span><span><i className="legend-square" /> hospital</span><span><i className="legend-diamond" /> shelter</span><span><i className="legend-triangle" /> pharmacy</span></div></div><div className="motion-map-art"><div className="motion-map-art-label">LIVE AREA / ILLUSTRATIVE</div><SafetyRadar /><span className="motion-map-coordinates">12.9716° N · 77.5946° E</span></div></div>
        </section>

        <section id="ai" className="motion-ai" aria-labelledby="ai-title">
          <div className="motion-ai-top"><span className="motion-label">WORDS WHEN THEY ARE HARD / 06</span><span>AI GUARDIAN / DEMO</span></div>
          <div className="motion-ai-layout"><div className="motion-ai-copy"><h2 id="ai-title">Talk it through.<br /><em>Make a record.</em></h2><p>Short, calm next steps in English, Hindi, or Hinglish. Then a first information report draft you can take with you.</p><div className="motion-ai-points"><span><MessageCircleMore size={17} /> crisis words put helplines first</span><span><FileLock2 size={17} /> rate-limited server function</span><span><Bot size={17} /> offline template when needed</span></div></div><div className="motion-ai-card"><AiDemo /></div></div>
        </section>

        <section className="motion-system" aria-labelledby="system-title">
          <div className="motion-system-head"><span className="motion-label">THE REST OF THE SYSTEM</span><h2 id="system-title">Built for the moment.<br /><em>Kept for the day after.</em></h2><p>What is written and tested is marked. What is still being finished is marked too.</p></div>
          <div className="motion-system-list">{FEATURE_GROUPS.flatMap((group) => group.items).map((item, index) => <div className="motion-system-row" key={item.title}><span>{String(index + 1).padStart(2, '0')}</span><div><strong>{item.title}</strong><p>{item.body}</p></div>{item.status ? <StatusTag status={item.status} /> : null}</div>)}</div>
        </section>

        <section className="motion-trust" aria-labelledby="trust-title">
          <div className="motion-trust-copy"><span className="motion-label">YOUR BOUNDARY</span><h2 id="trust-title">Safety data should not become a second risk.</h2></div><div className="motion-trust-list">{PRIVACY.map((item, index) => { const Icon = item.icon; return <div key={item.title}><Icon size={19} aria-hidden="true" /><span>{String(index + 1).padStart(2, '0')}</span><div><strong>{item.title}</strong><p>{item.body}</p></div></div>; })}</div>
        </section>

        <section id="helplines" className="motion-emergency" aria-labelledby="helplines-title"><div className="motion-emergency-orbit" aria-hidden="true"><span /><span /></div><div className="motion-emergency-inner"><span className="motion-label motion-label-light">IF IT IS URGENT NOW</span><h2 id="helplines-title">Call directly.</h2><p>Shakti reaches your people. These connect you to the state.</p><ul>{HELPLINES.map((helpline) => <li key={helpline.number}><a href={`tel:${helpline.number}`} aria-label={`Call ${helpline.number}, ${helpline.name}. ${helpline.detail}`}><span className="motion-emergency-icon"><Phone size={16} /></span><span><strong>{helpline.number}</strong><small>{helpline.name}</small></span><ArrowUpRight size={17} /></a></li>)}</ul></div></section>

        <section id="faq" className="motion-faq" aria-labelledby="faq-title"><div className="motion-faq-head"><span className="motion-label">BEFORE YOU ASK</span><h2 id="faq-title">Clear answers for a complicated moment.</h2></div><div className="motion-faq-list">{FAQS.map((faq) => <details key={faq.question}><summary><span>{faq.question}</span><Plus size={18} /></summary><p>{faq.answer}</p></details>)}</div></section>

        <section id="download" className="motion-final" aria-labelledby="download-title"><div className="motion-final-mark"><LogoMark className="size-14" /></div><span className="motion-label motion-label-acid">READY WHEN YOU ARE</span><h2 id="download-title">Set it up once.<br /><em>Before you need it.</em></h2><p>Add two or three guardians, choose your triggers, and run a test.</p><div className="motion-final-actions"><Magnet><a href={DOWNLOAD_URL} className="motion-button motion-button-acid"><Download size={16} /> Get the app</a></Magnet><Magnet><Link href="/track/demo" className="motion-button motion-button-outline">Open the demo tracker <ArrowRight size={16} /></Link></Magnet></div><span className="motion-final-note">Android 7.0 and up · not on iPhone</span></section>
      </main>

      <footer className="motion-footer"><div><LogoMark className="size-8" /><span><strong>Shakti</strong><small>VTU Community Project / Topic #25</small></span></div><p>It helps you reach people. It does not replace calling <a href="tel:112">112</a>.</p></footer>
    </>
  );
}
