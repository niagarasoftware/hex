import 'dart:async';
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

class MapTestPage extends StatefulWidget {
  const MapTestPage({super.key});

  @override
  State<MapTestPage> createState() => _MapTestPageState();
}

class _MapTestPageState extends State<MapTestPage> {
  bool _isReady = false;
  Timer? _pollingTimer;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _isReady = isGoogleMapsReady();
    if (!_isReady && kIsWeb) {
      _startPolling();
    }
  }

  void _checkStatus() {
    final ready = isGoogleMapsReady();
    if (ready != _isReady) {
      setState(() {
        _isReady = ready;
      });
      if (ready) {
        _pollingTimer?.cancel();
      }
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _retryCount = 0;
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _retryCount++;
      if (isGoogleMapsReady()) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _isReady = true;
          });
        }
      } else if (_retryCount >= 20) {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recheck Maps SDK',
            onPressed: () {
              _checkStatus();
              if (!_isReady) {
                _startPolling();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: _isReady ? Colors.green : Colors.red,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _isReady
                        ? 'Maps SDK loaded'
                        : 'Maps SDK NOT loaded (window.google missing)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!_isReady)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      _checkStatus();
                      if (!_isReady) _startPolling();
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _isReady
                ? const GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(11.0168, 76.9558), // Coimbatore
                      zoom: 12,
                    ),
                  )
                : const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'Map not built.\n\nEnsure web/index.html includes the Google Maps script and restart your Flutter dev server.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
