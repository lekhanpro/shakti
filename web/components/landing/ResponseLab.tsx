'use client';

import { useEffect, useState } from 'react';
import { ArrowRight, Check, Cloud, HardDrive, Pause, Play, Radio, RotateCcw, Wifi, WifiOff } from 'lucide-react';
import { responseChannels, RESPONSE_STEPS } from '@/lib/response-demo';

const CHANNEL_ICONS = [HardDrive, Radio, Cloud] as const;

/** An entirely local explanation. It never records audio or sends an alert. */
export function ResponseLab() {
  const [step, setStep] = useState(0);
  const [online, setOnline] = useState(true);
  const [playing, setPlaying] = useState(false);

  useEffect(() => {
    if (!playing || step >= RESPONSE_STEPS.length - 1) return;
    const timer = window.setTimeout(() => {
      const next = step + 1;
      setStep(next);
      if (next === RESPONSE_STEPS.length - 1) setPlaying(false);
    }, 1800);
    return () => window.clearTimeout(timer);
  }, [playing, step]);

  function play() {
    if (playing) {
      setPlaying(false);
      return;
    }
    if (step === RESPONSE_STEPS.length - 1) setStep(0);
    setPlaying(true);
  }

  const current = RESPONSE_STEPS[step];
  const channels = responseChannels(step, online);

  return (
    <div className="s-lab">
      <div className="s-lab-toolbar">
        <div className="s-lab-toolbar-info" aria-hidden="true">
          <span className="s-lab-toolbar-badge">
            <span className="s-lab-toolbar-dot" />
            Response Architecture
          </span>
        </div>
        <button type="button" className="s-connectivity" aria-pressed={online} onClick={() => setOnline((value) => !value)}>
          {online ? <Wifi size={15} aria-hidden="true" /> : <WifiOff size={15} aria-hidden="true" />}
          Internet {online ? 'connected' : 'disconnected'}
        </button>
      </div>
      <div className="s-lab-body">
        <div className="s-lab-phone" data-stage={step} aria-hidden="true">
          <div className="s-phone-reflection" />
          <div className="s-phone-island" />
          <span className="s-phone-name">shakti</span>
          <div className="s-phone-radar">
            <span />
            <span />
            <span />
            <strong>{step === 1 ? '05' : step === 4 ? <Check size={26} aria-hidden="true" /> : 'SOS'}</strong>
          </div>
          <b>{['Ready for your walk', 'Time to cancel', 'Reaching your people', 'Keeping them updated', 'Marked safe'][step]}</b>
          <small>{online ? 'Cloud connection available' : 'Local channels remain available'}</small>
          <div className="s-phone-trail"><i /><i /><i /><i /><i /></div>
        </div>
        <div className="s-lab-explanation">
          <div className="s-lab-step"><span>0{step + 1}</span><span>/ 05</span></div>
          <div className="s-lab-reading" aria-live="polite" aria-atomic="true">
            <h3>{current.title}</h3>
            <p>{current.body}</p>
          </div>
          <ul className="s-channel-list">
            {channels.map((channel, index) => {
              const Icon = CHANNEL_ICONS[index];
              return <li key={channel.name} data-state={channel.state}><Icon size={18} aria-hidden="true" /><span><strong>{channel.name}</strong><small>{channel.detail}</small></span><span className="s-channel-state">{channel.state === 'done' ? <Check size={15} aria-label="Demonstrated" /> : channel.state === 'queued' ? 'Queued' : 'Waiting'}</span></li>;
            })}
          </ul>
        </div>
      </div>
      <div className="s-lab-timeline" role="group" aria-label="Choose a demonstration stage">
        {RESPONSE_STEPS.map((item, index) => <button type="button" key={item.label} aria-pressed={step === index} onClick={() => { setPlaying(false); setStep(index); }}><span>0{index + 1}</span>{item.label}</button>)}
      </div>
      <div className="s-lab-bottom">
        <div className="s-lab-controls"><button className="s-button s-button-light" type="button" onClick={play}>{playing ? <Pause size={15} aria-hidden="true" /> : <Play size={15} aria-hidden="true" />}{playing ? 'Pause walkthrough' : 'Play walkthrough'}</button><button className="s-icon-button" type="button" aria-label="Reset walkthrough" onClick={() => { setStep(0); setPlaying(false); }}><RotateCcw size={17} /></button></div>
        <p>Simulation only. No SMS, audio capture, or emergency call. <ArrowRight size={14} aria-hidden="true" /></p>
      </div>
    </div>
  );
}
