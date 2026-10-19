export interface Helpline {
  number: string;
  name: string;
  detail: string;
}

/** National helplines in India. Keep in sync with the app (CLAUDE.md). */
export const HELPLINES: readonly Helpline[] = [
  { number: '112', name: 'Emergency', detail: 'Police, fire and ambulance, anywhere in India' },
  { number: '181', name: 'Women helpline', detail: 'Counselling, shelter and legal support' },
  { number: '1091', name: 'Women police', detail: 'Direct line to the women police cell' },
  { number: '1098', name: 'Childline', detail: 'For any child in distress' },
];
