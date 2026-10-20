'use client';

import { useEffect, useRef, useState } from 'react';
import { ArrowUpRight, Menu, X } from 'lucide-react';

const NAV_LINKS = [
  { href: '#story', label: 'How it works' },
  { href: '#network', label: 'For guardians' },
  { href: '#features', label: 'Features' },
  { href: '#faq', label: 'Questions' },
] as const;

export function LogoMark({ className = '' }: { className?: string }) {
  return <svg className={`s-logo ${className}`} width="32" height="32" viewBox="0 0 32 32" fill="none" aria-hidden="true"><path d="M16 3 27 9v9c0 6-11 11-11 11S5 24 5 18V9L16 3Z" stroke="currentColor" strokeWidth="1.5" /><path d="m18 9-6 8h5l-3 7 8-11h-6l2-4Z" fill="currentColor" /></svg>;
}

export function Header({ downloadHref, hasDownload = false }: { downloadHref: string; hasDownload?: boolean }) {
  const [open, setOpen] = useState(false);
  const toggleRef = useRef<HTMLButtonElement>(null);
  const navRef = useRef<HTMLElement>(null);

  useEffect(() => {
    if (!open) return;
    function close(event: KeyboardEvent) {
      if (event.key === 'Escape') { setOpen(false); toggleRef.current?.focus(); }
    }
    function outside(event: PointerEvent) {
      if (!navRef.current?.contains(event.target as Node)) setOpen(false);
    }
    const media = window.matchMedia('(min-width: 900px)');
    function onDesktop() { if (media.matches) setOpen(false); }
    document.addEventListener('keydown', close);
    document.addEventListener('pointerdown', outside);
    media.addEventListener('change', onDesktop);
    return () => {
      document.removeEventListener('keydown', close);
      document.removeEventListener('pointerdown', outside);
      media.removeEventListener('change', onDesktop);
    };
  }, [open]);

  return (
    <header className="s-header">
      <nav ref={navRef} className="s-wrap s-nav" aria-label="Primary">
        <a href="#main" className="s-brand"><LogoMark /><span>shakti</span><small>personal safety network</small></a>
        <div className="s-nav-links">{NAV_LINKS.map((link) => <a key={link.href} href={link.href}>{link.label}</a>)}</div>
        <div className="s-nav-actions"><a href={downloadHref} className="s-nav-cta">{hasDownload ? 'Get the app' : 'Explore alpha'}<ArrowUpRight size={15} aria-hidden="true" /></a><button ref={toggleRef} type="button" className="s-menu-toggle" aria-expanded={open} aria-controls="s-mobile-nav" aria-label={open ? 'Close navigation' : 'Open navigation'} onClick={() => setOpen((value) => !value)}>{open ? <X size={20} /> : <Menu size={20} />}</button></div>
        <div id="s-mobile-nav" className="s-mobile-nav" hidden={!open}>{NAV_LINKS.map((link) => <a key={link.href} href={link.href} onClick={() => setOpen(false)}>{link.label}<ArrowUpRight size={16} aria-hidden="true" /></a>)}</div>
      </nav>
    </header>
  );
}
