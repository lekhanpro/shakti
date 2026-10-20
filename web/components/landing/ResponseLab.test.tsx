import { act, cleanup, fireEvent, render, screen } from '@testing-library/react';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { ResponseLab } from './ResponseLab';

afterEach(() => { cleanup(); vi.useRealTimers(); });

describe('SOS explanation', () => {
  it('keeps the demonstrated local and SMS channels independent of internet', () => {
    render(<ResponseLab />);
    fireEvent.click(screen.getByRole('button', { name: /Alert/ }));
    fireEvent.click(screen.getByRole('button', { name: /Internet connected/ }));
    expect(screen.getByText('Local incident saved · simulated')).toBeInTheDocument();
    expect(screen.getByText('Android handoff · simulated, delivery unconfirmed')).toBeInTheDocument();
    expect(screen.getByText('Queued')).toBeInTheDocument();
    expect(screen.getByText('Uploads wait for internet; SMS stays independent')).toBeInTheDocument();
    fireEvent.click(screen.getByRole('button', { name: /Internet disconnected/ }));
    expect(screen.queryByText('Queued')).not.toBeInTheDocument();
  });

  it('can pause and reset a running walkthrough', () => {
    vi.useFakeTimers();
    render(<ResponseLab />);
    fireEvent.click(screen.getByRole('button', { name: 'Play walkthrough' }));
    act(() => { vi.advanceTimersByTime(1800); });
    expect(screen.getByText('A moment to change your mind.')).toBeInTheDocument();
    fireEvent.click(screen.getByRole('button', { name: 'Pause walkthrough' }));
    act(() => { vi.advanceTimersByTime(10000); });
    expect(screen.getByText('A moment to change your mind.')).toBeInTheDocument();
    fireEvent.click(screen.getByRole('button', { name: 'Reset walkthrough' }));
    expect(screen.getByText('Start with the people you trust.')).toBeInTheDocument();
  });

  it('stops playback when a visitor chooses a stage', () => {
    vi.useFakeTimers();
    render(<ResponseLab />);
    fireEvent.click(screen.getByRole('button', { name: 'Play walkthrough' }));
    fireEvent.click(screen.getByRole('button', { name: /Resolved/ }));
    act(() => { vi.advanceTimersByTime(10000); });
    expect(screen.getByText('Close the loop when you are safe.')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Play walkthrough' })).toBeInTheDocument();
  });
});
