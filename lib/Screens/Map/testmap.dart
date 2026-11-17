import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:web/web.dart' as web;

bool isGoogleMapsReady() {
  if (!kIsWeb) return true;
  final g = web.window.getProperty('google'.toJS);
  if (g.isUndefinedOrNull) return false;
  return !(g as JSObject).getProperty('maps'.toJS).isUndefinedOrNull;
}

class MapTestPage extends StatelessWidget {
  const MapTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ready = isGoogleMapsReady();
    return Scaffold(
      appBar: AppBar(title: const Text('Map Test')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: ready ? Colors.green : Colors.red,
            padding: const EdgeInsets.all(12),
            child: Text(
              ready ? 'Maps SDK loaded' : 'Maps SDK NOT loaded (window.google missing)',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Expanded(
            child: ready
                ? const GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(11.0168, 76.9558), // Coimbatore
                zoom: 12,
              ),
            )
                : const Center(child: Text('Map not built')),
          ),
        ],
      ),
    );
  }
}