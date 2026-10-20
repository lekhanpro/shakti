'use client';

import { useEffect, useRef, useState } from 'react';
import { Pause, Play } from 'lucide-react';

export function ExperienceMotion() {
  const progressRef = useRef<HTMLDivElement>(null);
  const [paused, setPaused] = useState(false);

  useEffect(() => {
    const root = document.querySelector<HTMLElement>('.shakti-site');
    if (!root) return;
    root.dataset.motion = paused ? 'paused' : 'running';
    document.dispatchEvent(new CustomEvent('shakti:motion', { detail: { paused } }));
    return () => { delete root.dataset.motion; };
  }, [paused]);

  useEffect(() => {
    const root = document.querySelector<HTMLElement>('.shakti-site');
    if (!root) return;
    let raf = 0;
    const media = window.matchMedia('(prefers-reduced-motion: reduce)');
    const animations = new Set<Animation>();
    function update() {
      raf = 0;
      const available = document.documentElement.scrollHeight - window.innerHeight;
      const progress = available > 0 ? Math.max(0, Math.min(1, window.scrollY / available)) : 0;
      if (progressRef.current) progressRef.current.style.transform = `scaleX(${progress})`;
    }
    function onScroll() { if (!raf) raf = requestAnimationFrame(update); }
    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        observer.unobserve(entry.target);
        if (media.matches || root!.dataset.motion === 'paused') return;
        const animation = entry.target.animate([{ opacity: 0.35, transform: 'translateY(20px)' }, { opacity: 1, transform: 'translateY(0)' }], { duration: 650, easing: 'cubic-bezier(.22,1,.36,1)' });
        animations.add(animation);
        animation.onfinish = () => animations.delete(animation);
      });
    }, { threshold: 0.08 });
    root.querySelectorAll('.s-section-heading, .s-feature, .s-privacy-list > div, .s-download > div:last-child').forEach((node) => observer.observe(node));
    function stopAnimations() { animations.forEach((animation) => animation.cancel()); animations.clear(); }
    document.addEventListener('shakti:motion', stopAnimations);
    media.addEventListener('change', stopAnimations);
    window.addEventListener('scroll', onScroll, { passive: true });
    window.addEventListener('resize', onScroll);
    update();
    return () => {
      cancelAnimationFrame(raf);
      observer.disconnect();
      stopAnimations();
      document.removeEventListener('shakti:motion', stopAnimations);
      media.removeEventListener('change', stopAnimations);
      window.removeEventListener('scroll', onScroll);
      window.removeEventListener('resize', onScroll);
    };
  }, []);

  return <><div ref={progressRef} className="s-scroll-progress" aria-hidden="true" /><button className="s-motion-toggle" type="button" aria-pressed={paused} onClick={() => setPaused((value) => !value)}>{paused ? <Play size={13} aria-hidden="true" /> : <Pause size={13} aria-hidden="true" />}{paused ? 'Resume page motion' : 'Pause page motion'}</button></>;
}
