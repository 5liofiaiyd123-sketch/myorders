import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'config.dart';
import 'data/mock_repository.dart';
import 'theme.dart';

const dahabCenter = LatLng(dahabLat, dahabLng);

class MapPin {
  final LatLng point;
  final IconData icon;
  final Color color;
  const MapPin(this.point, this.icon, this.color);
}

/// OpenStreetMap view of Dahab with a few pins. Tapping the map reports the
/// tapped point, used to drop the delivery pin.
class DahabMap extends StatelessWidget {
  final List<MapPin> pins;
  final LatLng? center;
  final double zoom;
  final ValueChanged<LatLng>? onTap;

  const DahabMap({super.key, this.pins = const [], this.center, this.zoom = 14, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: center ?? (pins.isEmpty ? dahabCenter : pins.first.point),
          initialZoom: zoom,
          onTap: onTap == null ? null : (_, point) => onTap!(point),
        ),
        children: [
          TileLayer(urlTemplate: AppConfig.mapTilesUrl, userAgentPackageName: 'com.myorders.dahab'),
          MarkerLayer(
            markers: [
              for (final pin in pins)
                Marker(
                  point: pin.point,
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: pin.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                    ),
                    child: Icon(pin.icon, color: Colors.white, size: 20),
                  ),
                ),
            ],
          ),
          const SimpleAttributionWidget(source: Text('OpenStreetMap')),
        ],
      ),
    );
  }
}

const customerPinColor = AppColors.delivery;
const riderPinColor = AppColors.teal;
const storePinColor = AppColors.food;

/// The device's location, or null if permission is denied or unavailable.
Future<LatLng?> currentLocation() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return null;
    }
    final p = await Geolocator.getCurrentPosition();
    return LatLng(p.latitude, p.longitude);
  } catch (_) {
    return null;
  }
}

Future<void> callPhone(String phone) => launchUrl(Uri(scheme: 'tel', path: phone));

Future<void> openWhatsApp(String number, [String text = '']) => launchUrl(
  Uri.parse(
    'https://wa.me/${number.replaceAll(RegExp(r'[^0-9]'), '')}'
    '?text=${Uri.encodeComponent(text)}',
  ),
  mode: LaunchMode.externalApplication,
);

Future<void> openDirections(double lat, double lng) => launchUrl(
  Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'),
  mode: LaunchMode.externalApplication,
);
