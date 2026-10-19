'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import { demoTrack } from '@/lib/demo';
import { getSupabase, readSupabaseConfig } from '@/lib/supabase';
import { parseTrackResponse, type TrackData } from '@/lib/track';

export const POLL_MS = 10_000;

export type TrackState =
  | { kind: 'loading' }
  | { kind: 'config' }
  | { kind: 'not_found' }
  | { kind: 'error'; message: string; data: TrackData | null }
  | { kind: 'ready'; data: TrackData };

/**
 * Loads an incident by share token. Polls every 10 s, paused while the tab is
 * hidden. There is no realtime channel: anon has no table grants, so the
 * track_incident RPC is the only way in.
 */
export function useTrack(token: string, demo: boolean) {
  const [state, setState] = useState<TrackState>({ kind: 'loading' });
  const [fetchedAt, setFetchedAt] = useState<number | null>(null);
  const inFlight = useRef(false);
  const lastData = useRef<TrackData | null>(null);
  const demoOrigin = useRef<number>(0);

  const load = useCallback(async () => {
    if (demo) {
      if (!demoOrigin.current) demoOrigin.current = Date.now();
      const data = demoTrack(2509, Date.now() - demoOrigin.current, demoOrigin.current);
      lastData.current = data;
      setState({ kind: 'ready', data });
      setFetchedAt(Date.now());
      return;
    }
    const config = readSupabaseConfig();
    if (!config) {
      setState({ kind: 'config' });
      return;
    }
    if (inFlight.current) return;
    inFlight.current = true;
    try {
      const { data, error } = await getSupabase(config).rpc('track_incident', { p_token: token });
      if (error) throw new Error(error.message || 'The server rejected the request.');
      const parsed = parseTrackResponse(data);
      if (parsed.ok) {
        lastData.current = parsed.data;
        setState({ kind: 'ready', data: parsed.data });
        setFetchedAt(Date.now());
      } else if (parsed.reason === 'not_found') {
        setState({ kind: 'not_found' });
      } else {
        throw new Error('The server sent data this page could not read.');
      }
    } catch (e) {
      const offline = typeof navigator !== 'undefined' && navigator.onLine === false;
      setState({
        kind: 'error',
        message: offline
          ? 'Your device is offline.'
          : e instanceof Error && e.message
            ? e.message
            : 'Could not reach the server.',
        data: lastData.current,
      });
    } finally {
      inFlight.current = false;
    }
  }, [demo, token]);

  // Polling, paused while hidden; refetch immediately when the tab comes back.
  useEffect(() => {
    let timer: ReturnType<typeof setInterval> | null = null;
    const start = () => {
      if (timer === null) timer = setInterval(load, demo ? 2_000 : POLL_MS);
    };
    const stop = () => {
      if (timer !== null) clearInterval(timer);
      timer = null;
    };
    const onVisibility = () => {
      if (document.hidden) stop();
      else {
        void load();
        start();
      }
    };
    void load();
    if (!document.hidden) start();
    document.addEventListener('visibilitychange', onVisibility);
    window.addEventListener('online', load);
    return () => {
      stop();
      document.removeEventListener('visibilitychange', onVisibility);
      window.removeEventListener('online', load);
    };
  }, [load, demo]);

  return { state, fetchedAt, retry: load };
}
