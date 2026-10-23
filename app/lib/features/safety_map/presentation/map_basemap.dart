import 'package:flutter/material.dart';

/// CARTO now requires a public basemap key for both raster styles. Without one,
/// standard OSM tiles keep the map usable; only the tile artwork is dimmed at
/// night. Markers, labels and controls retain their theme colors.
abstract final class MapBasemap {
  static const cartoKey = String.fromEnvironment('CARTO_BASEMAP_KEY');
  static bool get usesCarto => cartoKey.trim().isNotEmpty;

  static String url({required bool dark, String key = cartoKey}) {
    if (key.trim().isEmpty) {
      return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
    final style = dark ? 'dark_all' : 'light_all';
    return 'https://{s}.basemaps.cartocdn.com/$style/{z}/{x}/{y}{r}.png?key=${Uri.encodeQueryComponent(key.trim())}';
  }

  // Invert and desaturate standard OSM artwork, preserving road detail.
  static const nightFilter = ColorFilter.matrix([
    -0.2126,
    -0.7152,
    -0.0722,
    0,
    245,
    -0.2126,
    -0.7152,
    -0.0722,
    0,
    239,
    -0.2126,
    -0.7152,
    -0.0722,
    0,
    237,
    0,
    0,
    0,
    1,
    0,
  ]);
}
