// lib/data/campus_locations.dart
//
// Shared campus location registry used by both CampusMapScreen
// and LocationPickerScreen.
//
// TODO: Replace mock coordinates with real college lat/lng values,
// or fetch dynamically from your backend:
//   GET /api/colleges/:id/locations

import 'package:latlong2/latlong.dart';

/// Known landmark positions per college.
/// Structure: { collegeId: { locationLabel: LatLng } }
const Map<String, Map<String, LatLng>> campusLocations = {
  'c1': {
    // IIT Guwahati — approximate coordinates for demo
    'Central Mess Area': LatLng(26.1905, 91.6953),
    'Barak Hostel Block B': LatLng(26.1912, 91.6971),
    'Academic Complex': LatLng(26.1887, 91.6942),
    'Sports Complex': LatLng(26.1878, 91.6965),
    'Main Gate': LatLng(26.1860, 91.6930),
    'Library': LatLng(26.1893, 91.6958),
  },
  'c2': {
    // NIT Silchar
    'Sports Complex Gate 2': LatLng(24.8278, 92.7985),
    'Central Library': LatLng(24.8265, 92.7972),
  },
  'c3': {
    // IIT Delhi
    'Sports Complex Gate 2': LatLng(28.5459, 77.1926),
  },
  'c4': {
    // IIT Bombay
    'Main Campus': LatLng(19.1334, 72.9133),
  },
};

/// Fallback centre coordinate per college (used when no specific
/// landmark is matched).
const Map<String, LatLng> collegeCentres = {
  'c1': LatLng(26.1905, 91.6953),
  'c2': LatLng(24.8278, 92.7985),
  'c3': LatLng(28.5459, 77.1926),
  'c4': LatLng(19.1334, 72.9133),
  'c5': LatLng(28.3649, 75.5885),
  'c6': LatLng(12.9694, 79.1559),
  'c7': LatLng(22.4996, 88.3673),
  'c8': LatLng(28.5445, 77.3275),
};

/// Resolves a [LatLng] from a college ID and optional location label.
/// Falls back to the college centre, then to the geographic centre of India.
LatLng resolveLocation(String collegeId, String? locationLabel) {
  if (locationLabel != null) {
    final byCollege = campusLocations[collegeId];
    if (byCollege != null) {
      final exact = byCollege[locationLabel];
      if (exact != null) return exact;
    }
  }
  return collegeCentres[collegeId] ?? const LatLng(20.5937, 78.9629);
}
