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
 * Loads token-scoped RPC data. Empty Realtime invalidations request a fresh
 * RPC read; ten-second polling remains the fallback. No database rows are
 * broadcast and anonymous clients receive no direct table grants.
 */
export function useTrack(token: string, demo: boolean) {
  const [state, setState] = useState<TrackState>({ kind: 'loading' });
  const [fetchedAt, setFetchedAt] = useState<number | null>(null);
  const inFlight = useRef(false);
  const requestVersion = useRef(0);

  useEffect(() => {
    requestVersion.current++;
    inFlight.current = false;
    lastData.current = null;
    demoOrigin.current = 0;
    setState({ kind: 'loading' });
    setFetchedAt(null);
    return () => { requestVersion.current++; };
  }, [token, demo]);
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
    const version = requestVersion.current;
    try {
      const { data, error } = await getSupabase(config).rpc('track_incident', { p_token: token });
      if (version !== requestVersion.current) return;
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
      if (version !== requestVersion.current) return;
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
      if (version === requestVersion.current) inFlight.current = false;
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

  useEffect(() => {
    const config = readSupabaseConfig();
    if (demo || !config || !/^[A-Za-z0-9_-]{22,64}$/.test(token)) return;
    const client = getSupabase(config);
    let stopped = false;
    let refresh: ReturnType<typeof setTimeout> | null = null;
    const channel = client.channel(`shakti:${token}`, { config: { private: false } })
      .on('broadcast', { event: 'changed' }, () => {
        // The payload is deliberately ignored. Only the token-scoped RPC is
        // trusted; coalesce bursts and keep hidden tabs quiet.
        if (stopped || document.hidden || refresh !== null) return;
        refresh = setTimeout(() => {
          refresh = null;
          if (!stopped && !document.hidden) void load();
        }, 300);
      })
      .subscribe();
    return () => {
      stopped = true;
      if (refresh !== null) clearTimeout(refresh);
      void client.removeChannel(channel);
    };
  }, [demo, token, load]);

  return { state, fetchedAt, retry: load };
}
