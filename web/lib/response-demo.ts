export const RESPONSE_STEPS = [
  { label: 'Ready', title: 'Start with the people you trust.', body: 'Set up contacts, permissions, and your PIN before a walk. Try the next stages here without sending a real alert.' },
  { label: 'Countdown', title: 'A moment to change your mind.', body: 'An ordinary SOS opens a cancellation window, five seconds by default. The duress PIN uses a separate silent path and skips this countdown.' },
  { label: 'Alert', title: 'One channel can fail. The others continue.', body: 'The app attempts a local save and independent SMS, evidence, siren, and cloud channels. SMS handoff does not wait for GPS or an internet response.' },
  { label: 'Tracking', title: 'A link keeps your guardians in the loop.', body: 'Location points are stored on the phone and queued for upload. The guardian browser checks for updates every ten seconds while the page is visible.' },
  { label: 'Resolved', title: 'Close the loop when you are safe.', body: 'PIN-confirmed resolution updates the incident and attempts follow-up messages for ordinary incidents. Delivery and guardian receipt still need to be checked.' },
] as const;

export type ChannelState = 'waiting' | 'done' | 'queued';
export interface DemoChannel { name: string; state: ChannelState; detail: string }

export function responseChannels(step: number, online: boolean): DemoChannel[] {
  const active = step >= 2;
  const resolved = step >= 4;
  return [
    { name: 'On your phone', state: active ? 'done' : 'waiting', detail: active ? 'Local incident saved · simulated' : 'Contacts and settings stay local' },
    { name: 'Carrier SMS', state: active ? 'done' : 'waiting', detail: active ? resolved ? 'Safe-message handoff · simulated' : 'Android handoff · simulated, delivery unconfirmed' : 'Needs a SIM, cellular service, and permission' },
    { name: 'Guardian cloud', state: !active ? 'waiting' : online ? 'done' : 'queued', detail: !active ? 'Internet and a configured backend required' : online ? 'Cloud update · simulated' : 'Uploads wait for internet; SMS stays independent' },
  ];
}
