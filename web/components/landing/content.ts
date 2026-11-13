import {
  BadgeCheck,
  Bot,
  DatabaseZap,
  EyeOff,
  FileLock2,
  HardDrive,
  MapPinned,
  Mic,
  PhoneIncoming,
  Power,
  Radio,
  Send,
  ShieldCheck,
  Siren,
  Timer,
  Vibrate,
  type LucideIcon,
} from 'lucide-react';

/**
 * Every sentence here is checked against the code (documentation review of 2026-10-22).
 * "built" refers to implementation in source, not independent device validation.
 * Physical-device results belong in the QA checklist.
 */
export type Status = 'built' | 'dev';

export interface Item {
  icon: LucideIcon;
  title: string;
  body: string;
  status?: Status;
}

export const TRIGGERS: readonly Item[] = [
  {
    icon: Power,
    title: 'Hardware Power Pulse',
    body: 'Three rapid presses inside 1.2 seconds initiate an instant haptic countdown. Operates natively even with the phone locked and screen off.',
    status: 'built',
  },
  {
    icon: Timer,
    title: 'Walk with Me (Safe Timer)',
    body: 'Set a trip destination countdown with mandatory periodic PIN check-ins. If unacknowledged, SOS triggers automatically.',
    status: 'built',
  },
  {
    icon: EyeOff,
    title: 'Decoy Duress PIN',
    body: 'Enter a secondary disguise PIN under coercion. Seamlessly unlocks an innocent notes interface while silently broadcasting covert distress telemetry.',
    status: 'built',
  },
  {
    icon: Vibrate,
    title: 'Kinetic Shake Trigger',
    body: 'Calibrated tri-axis accelerometer threshold (2.8g) identifies violent physical struggle or forceful pocket shakes.',
    status: 'built',
  },
  {
    icon: Mic,
    title: 'Acoustic Distress Trigger',
    body: 'On-device acoustic pattern matching continuously monitors for user-configured distress safe-words with zero audio egress.',
    status: 'built',
  },
];

export interface FeatureGroup {
  title: string;
  intro: string;
  items: readonly Item[];
}

export const FEATURE_GROUPS: readonly FeatureGroup[] = [
  {
    title: 'Immediate Triage & Dispatch',
    intro: 'Autonomous escalation within the critical first 60 seconds.',
    items: [
      {
        icon: Radio,
        title: 'Dual-Path Cellular SMS',
        body: 'Dispatches multi-part carrier SMS with GPS coordinates, battery level, and 1-click live tracking token directly to emergency contacts without requiring mobile data.',
        status: 'built',
      },
      {
        icon: Send,
        title: 'Encrypted Telegram Bridge',
        body: 'Dispatches instant rich notifications and tracking payloads to designated guardian channels via secure edge worker.',
        status: 'built',
      },
      {
        icon: Siren,
        title: 'Tactical Siren & Strobe',
        body: 'High-decibel pulsing alarm and high-frequency camera strobe to disorient attackers and alert surrounding bystanders.',
        status: 'built',
      },
      {
        icon: PhoneIncoming,
        title: 'Decoy Incoming Call',
        body: 'Authentic incoming call simulation with configurable delay (0s to 60s) providing an immediate, socially friction-free exit route.',
        status: 'built',
      },
      {
        icon: FileLock2,
        title: 'Encrypted Evidence Vault',
        body: 'Automated 60-second high-fidelity ambient audio capture, secured on-device with AES-256 GCM encryption.',
        status: 'built',
      },
    ],
  },
  {
    title: 'Perimeter Intelligence & Post-Incident',
    intro: 'Continuous safety mapping and legal reporting after incident trigger.',
    items: [
      {
        icon: MapPinned,
        title: 'Zero-Install Guardian Tracker',
        body: 'Web-based real-time telemetry console accessible on any device via cryptographic share token without guardian registration.',
        status: 'built',
      },
      {
        icon: ShieldCheck,
        title: 'Safe Havens Spatial Radar',
        body: 'Autonomous spatial indexing identifying police stations, hospitals, 24/7 pharmacies, and verified shelters within a 5 km perimeter.',
        status: 'built',
      },
      {
        icon: Bot,
        title: 'AI Incident Triage & FIR Drafter',
        body: 'Guided incident debriefing that structures witness statements and legal details into formal FIR drafts aligned with BNS provisions, with offline fallback.',
        status: 'built',
      },
    ],
  },
];

export const PRIVACY: readonly Item[] = [
  {
    icon: HardDrive,
    title: 'Zero-Knowledge On-Device Cryptography',
    body: 'All security PINs are salted and hashed on-device using PBKDF2-SHA256 (100,000 iterations). Plaintext secrets never leave local hardware.',
  },
  {
    icon: BadgeCheck,
    title: 'Zero Advertising & Zero Third-Party Trackers',
    body: 'The codebase contains zero advertising SDKs, zero telemetry brokers, and zero behavioral analytics libraries.',
  },
  {
    icon: DatabaseZap,
    title: 'Isolated Local Storage',
    body: 'App data is sandboxed on the native Android secure filesystem with cloud backup explicitly disabled to prevent unencrypted device leaks.',
  },
  {
    icon: ShieldCheck,
    title: 'Stateless Token-Based Guardian Telemetry',
    body: 'PostgreSQL database enforced by strict Row-Level Security (RLS). Public telemetry is accessible solely via ephemeral cryptographic share tokens with 7-day auto-expiry.',
  },
];

export interface Faq {
  question: string;
  answer: string;
}

export const FAQS: readonly Faq[] = [
  {
    question: 'Does Shakti operate without internet connectivity?',
    answer:
      'Yes. Core emergency triggers, local incident persistence, encrypted evidence capture, and carrier SMS dispatch operate entirely offline. Cellular SMS broadcasts live GPS coordinates and tokenized web links directly through the carrier network. Online cloud sync, Telegram dispatch, and dynamic map routing activate whenever an internet connection is present.',
  },
  {
    question: 'Do emergency guardians need to download or install an app?',
    answer:
      'No. When an alert triggers, guardians receive a secure, tokenized web link via SMS. Clicking the link opens a responsive, zero-install web telemetry dashboard in any browser with real-time GPS breadcrumbs, battery telemetry, and safe navigation routes.',
  },
  {
    question: 'What prevents accidental false triggers?',
    answer:
      'Every trigger initiates an immediate 5-second cancellation buffer (configurable from 3 to 15 seconds) accompanied by distinctive haptic pulses. A quick swipe aborts the alert before any messages or network dispatches occur.',
  },
  {
    question: 'How is battery efficiency maintained?',
    answer:
      'Zero background drain during normal standby. Shakti leverages native Android hardware broadcast receivers and AccessibilityService listeners without keeping the CPU awake. High-frequency GPS tracking and radio transmissions activate exclusively during an active emergency lifecycle.',
  },
  {
    question: 'How is user location and personal data protected?',
    answer:
      'Incident location trails are encrypted and governed by strict PostgreSQL Row-Level Security (RLS) policies. Access is strictly scoped to the incident share token with an automatic 7-day expiration window. User PINs and evidence vaults remain encrypted on the physical device.',
  },
  {
    question: 'Which mobile operating systems are supported?',
    answer:
      'Shakti is built natively for Android (Android 7.0 Nougat / API 24 and above) to take full advantage of native background hardware event interception, broadcast receivers, and direct SMS dispatch capabilities.',
  },
];

export const BUILT_NOW: readonly string[] = [
  'Triple-click hardware power button trigger with screen-off broadcast listener',
  'Dynamic 5-second haptic cancel window with swipe-to-abort safety buffer',
  'Multi-part SMS broadcast with offline GPS coordinates & battery telemetry',
  'Telegram incident alerts via edge functions with tokenized guardian URLs',
  'Zero-install live guardian tracker with 10-second real-time telemetry streaming',
  'Spatial safety radar indexing police, hospitals, and shelters within 5 km (OSM)',
  'AI-guided FIR incident drafter under Bharatiya Nyaya Sanhita (BNS) guidelines',
  'Zero-knowledge on-device PBKDF2-SHA256 hashing and Postgres Row-Level Security',
];

export const IN_DEVELOPMENT: readonly string[] = [];
