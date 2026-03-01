// lib/screens/campus_map_screen.dart
//
// Uses flutter_map + latlong2 (no API key required – OpenStreetMap tiles).
// Add to pubspec.yaml:
//   flutter_map: ^6.1.0
//   latlong2: ^0.9.0
//
// For real campus data, replace _campusLocations with actual lat/lng values
// and optionally supply a GeoJSON campus boundary overlay.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';
import '../data/campus_locations.dart';

// ─────────────────────────────────────────────────────────────────────────────

class CampusMapScreen extends StatefulWidget {
  final String collegeId;
  final String collegeName;
  final String? locationLabel;
  final String postTitle;

  const CampusMapScreen({
    super.key,
    required this.collegeId,
    required this.collegeName,
    required this.locationLabel,
    required this.postTitle,
  });

  @override
  State<CampusMapScreen> createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends State<CampusMapScreen>
    with TickerProviderStateMixin {
  late final MapController _mapCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _cardCtrl;
  late final Animation<double> _pulseAnim;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _cardFade;

  late final LatLng _pinLocation;
  bool _satelliteMode = false;
  double _currentZoom = 17.0;

  @override
  void initState() {
    super.initState();
    _mapCtrl = MapController();
    _pinLocation = resolveLocation(widget.collegeId, widget.locationLabel);

    // Pulse animation for the pin ring
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _pulseAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));

    // Bottom card slide-up
    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));
    _cardFade = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _cardCtrl.forward();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _cardCtrl.dispose();
    _mapCtrl.dispose();
    super.dispose();
  }

  void _zoomIn() {
    _currentZoom = math.min(_currentZoom + 1, 19);
    _mapCtrl.move(_mapCtrl.camera.center, _currentZoom);
  }

  void _zoomOut() {
    _currentZoom = math.max(_currentZoom - 1, 10);
    _mapCtrl.move(_mapCtrl.camera.center, _currentZoom);
  }

  void _centreOnPin() {
    _mapCtrl.move(_pinLocation, 17.0);
    _currentZoom = 17.0;
  }

  String get _tileUrl => _satelliteMode
      ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: _pinLocation,
              initialZoom: _currentZoom,
              minZoom: 10,
              maxZoom: 19,
              onMapEvent: (evt) {
                if (evt is MapEventMove) {
                  setState(() => _currentZoom = evt.camera.zoom);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: _tileUrl,
                userAgentPackageName: 'com.campusassist.app',
                tileBuilder: _satelliteMode ? null : _lightTileBuilder,
              ),
              MarkerLayer(markers: [_buildMarker()]),
            ],
          ),

          // ── Top gradient fade (for appbar readability) ───────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
              ),
            ),
          ),

          // ── Zoom & locate controls ────────────────────────────────────────
          Positioned(
            right: 16,
            bottom: 220,
            child: Column(
              children: [
                _MapButton(
                  icon: Icons.add_rounded,
                  onTap: _zoomIn,
                  tooltip: 'Zoom in',
                ),
                const SizedBox(height: 8),
                _MapButton(
                  icon: Icons.remove_rounded,
                  onTap: _zoomOut,
                  tooltip: 'Zoom out',
                ),
                const SizedBox(height: 8),
                _MapButton(
                  icon: Icons.my_location_rounded,
                  onTap: _centreOnPin,
                  tooltip: 'Centre on location',
                  highlight: true,
                ),
              ],
            ),
          ),

          // ── Layer toggle ─────────────────────────────────────────────────
          Positioned(
            right: 16,
            bottom: 390,
            child: _MapButton(
              icon: _satelliteMode
                  ? Icons.map_rounded
                  : Icons.satellite_alt_rounded,
              onTap: () => setState(() => _satelliteMode = !_satelliteMode),
              tooltip: _satelliteMode ? 'Street map' : 'Satellite',
            ),
          ),

          // ── Bottom info card ─────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SlideTransition(
              position: _cardSlide,
              child: FadeTransition(
                opacity: _cardFade,
                child: _LocationCard(
                  locationLabel: widget.locationLabel,
                  collegeName: widget.collegeName,
                  postTitle: widget.postTitle,
                  pinLocation: _pinLocation,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Campus Map',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            widget.collegeName,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Marker _buildMarker() {
    return Marker(
      point: _pinLocation,
      width: 80,
      height: 80,
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, __) {
          final scale = 1.0 + (_pulseAnim.value * 0.9);
          final opacity = (1.0 - _pulseAnim.value).clamp(0.0, 1.0);
          return Stack(
            alignment: Alignment.center,
            children: [
              // Pulse ring
              Transform.scale(
                scale: scale,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primary.withOpacity(opacity * 0.6),
                      width: 2,
                    ),
                    color: AppTheme.primary.withOpacity(opacity * 0.15),
                  ),
                ),
              ),
              // Pin dot
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _lightTileBuilder(
    BuildContext context,
    Widget tileWidget,
    TileImage tile,
  ) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        0.95,
        0,
        0,
        0,
        5,
        0,
        0.95,
        0,
        0,
        5,
        0,
        0,
        0.90,
        0,
        10,
        0,
        0,
        0,
        1,
        0,
      ]),
      child: tileWidget,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _LocationCard extends StatelessWidget {
  final String? locationLabel;
  final String collegeName;
  final String postTitle;
  final LatLng pinLocation;

  const _LocationCard({
    required this.locationLabel,
    required this.collegeName,
    required this.postTitle,
    required this.pinLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location name row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            locationLabel ?? 'Campus Location',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            collegeName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Coords badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Text(
                        '${pinLocation.latitude.toStringAsFixed(4)}, '
                        '${pinLocation.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(
                          fontSize: 9,
                          fontFamily: 'monospace',
                          color: AppTheme.textLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Post context
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          postTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Open in external maps
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: launch url_launcher with
                      // 'https://maps.google.com/?q=${pinLocation.latitude},${pinLocation.longitude}'
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 15),
                    label: const Text('Open in Google Maps'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Safe area spacer
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool highlight;

  const _MapButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: highlight ? AppTheme.primary : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 20,
            color: highlight ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
