import { act, renderHook, waitFor } from '@testing-library/react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { useTrack } from './useTrack';

const mocks = vi.hoisted(() => ({
  rpc: vi.fn(), channel: vi.fn(), on: vi.fn(), subscribe: vi.fn(),
  removeChannel: vi.fn(), config: vi.fn(),
  changed: undefined as undefined | (() => void),
}));
vi.mock('@/lib/supabase', () => ({
  readSupabaseConfig: mocks.config,
  getSupabase: () => ({
    rpc: mocks.rpc, channel: mocks.channel, removeChannel: mocks.removeChannel,
  }),
}));
const token = 'abcdefghijklmnopqrstuvwx';
const payload = {
  status: 'ACTIVE', created_at: '2026-10-21T00:00:00Z',
  updated_at: '2026-10-21T00:00:00Z', first_name: 'Test', breadcrumbs: [],
};

beforeEach(() => {
  vi.clearAllMocks();
  mocks.config.mockReturnValue({ url: 'https://example.supabase.co', anonKey: 'public' });
  mocks.rpc.mockResolvedValue({ data: payload, error: null });
  mocks.on.mockImplementation((_kind, _filter, callback) => {
    mocks.changed = callback;
    return { subscribe: mocks.subscribe };
  });
  mocks.subscribe.mockReturnValue({});
  mocks.channel.mockReturnValue({ on: mocks.on });
  mocks.removeChannel.mockResolvedValue('ok');
});

describe('guardian refresh lifecycle', () => {
  it('uses only the token RPC for incident data and removes its channel on unmount', async () => {
    const { result, unmount } = renderHook(() => useTrack(token, false));
    await waitFor(() => expect(result.current.state.kind).toBe('ready'));
    expect(mocks.rpc).toHaveBeenCalledWith('track_incident', { p_token: token });
    expect(mocks.channel).toHaveBeenCalledWith(`shakti:${token}`, { config: { private: false } });
    unmount();
    expect(mocks.removeChannel).toHaveBeenCalledOnce();
  });

  it('coalesces broadcast bursts into a fresh token-scoped read', async () => {
    const { result } = renderHook(() => useTrack(token, false));
    await waitFor(() => expect(result.current.state.kind).toBe('ready'));
    act(() => { mocks.changed?.(); mocks.changed?.(); mocks.changed?.(); });
    await waitFor(() => expect(mocks.rpc).toHaveBeenCalledTimes(2));
  });

  it('does not connect a channel when configuration is missing', async () => {
    mocks.config.mockReturnValue(null);
    const { result } = renderHook(() => useTrack(token, false));
    await waitFor(() => expect(result.current.state.kind).toBe('config'));
    expect(mocks.channel).not.toHaveBeenCalled();
  });

  it('does not let an old token response overwrite the current token', async () => {
    let resolveOld!: (value: { data: typeof payload; error: null }) => void;
    mocks.rpc.mockImplementationOnce(() => new Promise((resolve) => { resolveOld = resolve; }));
    const { result, rerender } = renderHook(({ value }) => useTrack(value, false), {
      initialProps: { value: token },
    });
    const nextToken = 'zyxwvutsrqponmlkjihgfedcb';
    rerender({ value: nextToken });
    await waitFor(() => expect(result.current.state.kind).toBe('ready'));
    await act(async () => {
      resolveOld({ data: { ...payload, first_name: 'Old token' }, error: null });
    });
    expect(result.current.state.kind).toBe('ready');
    if (result.current.state.kind === 'ready') {
      expect(result.current.state.data.incident.first_name).toBe('Test');
    }
  });
});
