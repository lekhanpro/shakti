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
  Volume2,
  type LucideIcon,
} from 'lucide-react';

/**
 * Every sentence here is checked against the code (documentation review of 2026-10-21).
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
    title: 'Power button, three times',
    body: 'Three presses inside 1.2 seconds start the countdown. On by default.',
    status: 'built',
  },
  {
    icon: Volume2,
    title: 'Volume down, three times',
    body: 'Optional. Same rule, through an accessibility service. Off until you switch it on.',
    status: 'built',
  },
  {
    icon: Timer,
    title: 'Walk with me',
    body: 'Set a timer for your journey and check in with your PIN. If it runs out, the SOS goes out.',
    status: 'built',
  },
  {
    icon: EyeOff,
    title: 'Duress PIN',
    body: 'Enter the second PIN at the lock screen. A decoy notes screen opens and a silent SOS is sent.',
    status: 'built',
  },
  {
    icon: Vibrate,
    title: 'Shake',
    body: 'Three hard shakes of 2.8 g or more. Detection and sensor integration are implemented; false-trigger behavior needs real-device validation.',
    status: 'built',
  },
  {
    icon: Mic,
    title: 'Voice phrase',
    body: 'A phrase you choose, matched approximately. Off by default. Matching and speech-service integration are implemented; test permissions and listening behavior on your device.',
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
    title: 'In the moment',
    intro: 'What the phone does in the first minute.',
    items: [
      {
        icon: Radio,
        title: 'SMS first, no data needed',
        body: 'The message uses available incident information and a tracker link. Carrier SMS needs cellular service and permission; Android handoff does not confirm delivery.',
        status: 'built',
      },
      {
        icon: Send,
        title: 'Telegram alert',
        body: 'When you are online and have set a Telegram chat, an edge function posts the alert with the tracker link.',
        status: 'built',
      },
      {
        icon: Siren,
        title: 'Siren and strobe',
        body: 'Siren and strobe controls use device audio and torch capabilities. Validate hardware and permission behavior on the target phone.',
        status: 'built',
      },
      {
        icon: PhoneIncoming,
        title: 'Fake call',
        body: 'A realistic incoming call you can start after 0, 10, 30 or 60 seconds, to leave an uncomfortable situation.',
        status: 'built',
      },
      {
        icon: FileLock2,
        title: 'Audio evidence',
        body: 'A 60 second recording during an incident, encrypted on the phone.',
        status: 'built',
      },
    ],
  },
  {
    title: 'Around you and afterwards',
    intro: 'What helps before you leave and after it is over.',
    items: [
      {
        icon: MapPinned,
        title: 'Live tracker link',
        body: 'Guardians open a token-based link without installing the app. It polls uploaded incident and trail data every ten seconds while visible.',
        status: 'built',
      },
      {
        icon: ShieldCheck,
        title: 'Safety map',
        body: 'Police stations, hospitals, 24 hour pharmacies and shelters within 5 km, from OpenStreetMap.',
        status: 'built',
      },
      {
        icon: Bot,
        title: 'AI guardian and FIR draft',
        body: 'Talk through what happened and get a first information report draft to take to the police. A plain template works offline.',
        status: 'built',
      },
    ],
  },
];

export const PRIVACY: readonly Item[] = [
  {
    icon: HardDrive,
    title: 'Your PIN stays on the phone',
    body: 'It is hashed on the device with PBKDF2-SHA256, 100,000 rounds, and never sent anywhere.',
  },
  {
    icon: BadgeCheck,
    title: 'No ads, no analytics',
    body: 'The app includes no advertising or analytics libraries.',
  },
  {
    icon: DatabaseZap,
    title: 'Android backup is off',
    body: 'App data is not copied to cloud backups.',
  },
  {
    icon: ShieldCheck,
    title: 'A locked-down server',
    body: 'Every table has row-level security. The public tracker reads through one function and a random share token. Anonymous visitors can read no table.',
  },
];

export interface Faq {
  question: string;
  answer: string;
}

export const FAQS: readonly Faq[] = [
  {
    question: 'Does Shakti need the internet?',
    answer:
      'Local SOS state, contacts, evidence, and supported device functions do not require mobile data. Carrier SMS still needs a working SIM, cellular service, SMS permission, and plan/balance. Cloud alerts, fresh maps/routes, AI, and uploaded guardian tracking require internet and configuration.',
  },
  {
    question: 'Who are my guardians, and what do they need to install?',
    answer:
      'Nothing at all. The alert carries a link, and the link opens the live tracker in any browser. You can also invite a guardian to the app with an 8 character code that stays valid for 7 days.',
  },
  {
    question: 'What happens if I trigger it by accident?',
    answer:
      'A countdown starts at once, 5 seconds by default and 3 to 15 if you change it, with a vibration tick each second. Swipe to cancel. If someone forces you to unlock the phone, the duress PIN opens a decoy notes screen while a silent SOS goes out.',
  },
  {
    question: 'Will it drain my battery?',
    answer:
      'The power-button detector is a small native service, and GPS breadcrumbs go out every 10 seconds only while an incident is live. Battery impact has not been measured on real phones yet. That test is still on the checklist.',
  },
  {
    question: 'Is my location stored on your servers?',
    answer:
      'During an incident your position and trail are stored so guardians can follow them. Tracking links have expiry rules in the backend. Share a link only with trusted people. Your PIN remains local; review the deployment's data behavior before use.',
  },
  {
    question: 'Is there an iPhone version?',
    answer:
      'No. Shakti is Android only, Android 7.0 and up, because Android allows the background triggers an SOS depends on.',
  },
];

export const BUILT_NOW: readonly string[] = [
  'Power, volume, walk-with-me and duress triggers',
  'Five second cancel window with swipe to cancel',
  'Message composer: maps link, address, battery, tracking link',
  'Telegram alerts through a rate-limited edge function',
  'Guardian invites and the live tracker, with a demo mode',
  'Safety map data from OpenStreetMap (Overpass), 5 km',
  'AI guardian and FIR draft, with an offline template',
  'PIN hashing and row-level security on every table',
];

export const IN_DEVELOPMENT: readonly string[] = [
  'Recorded real-phone SMS, audio, sensor, and battery validation',
  'Deployed backend and guardian tracking integration evidence',
  'Closed-alpha release approval and tester feedback',
];
