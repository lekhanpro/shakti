import { render, screen } from '@testing-library/react';
import { describe, expect, it } from 'vitest';
import { StatusBanner } from './StatusBanner';

const createdAt = '2026-09-29T10:00:00Z';
const base = {
  name: 'Priya',
  createdAt,
  updatedAt: '2026-09-29T10:12:00Z',
  now: Date.parse(createdAt) + 4 * 60_000 + 12_000,
};

describe('StatusBanner', () => {
  it('shows an alert with elapsed time for ACTIVE', () => {
    render(<StatusBanner {...base} status="ACTIVE" triggerLabel="Shake detected" />);
    const banner = screen.getByRole('alert');
    expect(banner).toHaveAttribute('data-status', 'ACTIVE');
    expect(screen.getByRole('heading', { level: 1 })).toHaveTextContent('Priya needs help');
    expect(banner).toHaveTextContent('SOS raised 4 min 12 s ago. Shake detected');
  });

  it('shows a calm status for RESOLVED with the incident duration', () => {
    render(<StatusBanner {...base} status="RESOLVED" />);
    expect(screen.queryByRole('alert')).toBeNull();
    const banner = screen.getByRole('status');
    expect(screen.getByRole('heading', { level: 1 })).toHaveTextContent('Priya is safe');
    expect(banner).toHaveTextContent('The alert lasted 12 min');
  });

  it('explains a FALSE_ALARM', () => {
    render(<StatusBanner {...base} status="FALSE_ALARM" />);
    expect(screen.getByRole('heading', { level: 1 })).toHaveTextContent('This alert was cancelled');
    expect(screen.getByRole('status')).toHaveTextContent('Priya marked it as a false alarm');
  });

  it('shows the cancel window for COUNTDOWN', () => {
    render(<StatusBanner {...base} status="COUNTDOWN" />);
    expect(screen.getByRole('heading', { level: 1 })).toHaveTextContent('Priya started an SOS');
    expect(screen.getByRole('status')).toHaveTextContent('5 second cancel window');
  });
});
