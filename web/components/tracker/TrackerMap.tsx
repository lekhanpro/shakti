'use client';

import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { useEffect, useMemo, useRef } from 'react';
import { Circle, MapContainer, Marker, Polyline, TileLayer, useMap } from 'react-leaflet';
import type { Breadcrumb } from '@/lib/track';

interface TrackerMapProps {
  points: Breadcrumb[];
  live: boolean;
  name: string;
}

const SOS = '#E11D48';
const SAFE = '#10B981';

/** Follows the latest point unless the guardian has panned the map themselves. */
function FollowLatest({ latest, all }: { latest: [number, number]; all: [number, number][] }) {
  const map = useMap();
  const userMoved = useRef(false);
  const fitted = useRef(false);

  useEffect(() => {
    const onDrag = () => {
      userMoved.current = true;
    };
    map.on('dragstart', onDrag);
    return () => {
      map.off('dragstart', onDrag);
    };
  }, [map]);

  useEffect(() => {
    if (!fitted.current) {
      fitted.current = true;
      if (all.length > 1) map.fitBounds(L.latLngBounds(all), { padding: [48, 48], maxZoom: 17 });
      else map.setView(latest, 16);
      return;
    }
    if (!userMoved.current) map.panTo(latest, { animate: !window.matchMedia('(prefers-reduced-motion: reduce)').matches });
  }, [map, latest, all]);

  return null;
}

export default function TrackerMap({ points, live, name }: TrackerMapProps) {
  const path = useMemo(() => points.map((p) => [p.latitude, p.longitude] as [number, number]), [points]);
  const last = points[points.length - 1];
  const latest = path[path.length - 1];
  const color = live ? SOS : SAFE;

  const icon = useMemo(
    () =>
      L.divIcon({
        className: '',
        html: `<div class="pulse-marker" style="--marker:${color}"></div>`,
        iconSize: [22, 22],
        iconAnchor: [11, 11],
      }),
    [color],
  );

  if (!last || !latest) return null;

  return (
    <MapContainer
      center={latest}
      zoom={16}
      className="size-full"
      scrollWheelZoom
      attributionControl
      aria-label={`Map showing ${name}'s location and route`}
    >
      <TileLayer
        className="tiles-night"
        url="https://tile.openstreetmap.org/{z}/{x}/{y}.png"
        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        maxZoom={19}
      />
      {path.length > 1 ? (
        <>
          <Polyline positions={path} pathOptions={{ color: '#070B14', weight: 8, opacity: 0.6 }} />
          <Polyline positions={path} pathOptions={{ color: '#A5B4FC', weight: 4, opacity: 0.95 }} />
        </>
      ) : null}
      {last.accuracy_meters ? (
        <Circle
          center={latest}
          radius={last.accuracy_meters}
          pathOptions={{ color, weight: 1.5, fillColor: color, fillOpacity: 0.12 }}
        />
      ) : null}
      <Marker position={latest} icon={icon} title={`${name}'s latest location`} keyboard={false} />
      <FollowLatest latest={latest} all={path} />
    </MapContainer>
  );
}
