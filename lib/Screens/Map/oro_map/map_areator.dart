import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:hex/utils/helpers/log_print.dart';

import '../../../repository/repository.dart';
import '../../../services/http_service.dart';
import 'map_conection_objects.dart';


class MapScreenValve extends StatefulWidget {
  const MapScreenValve({
    Key? key,
    required this.userId,
    required this.customerId,
    required this.controllerId,
    required this.imeiNo,
    required this.modelId,
  }) : super(key: key);

  final int userId, customerId, controllerId,modelId;
  final String imeiNo;

  @override
  State<MapScreenValve> createState() => _MapScreenValveState();
}

class _MapScreenValveState extends State<MapScreenValve> {
  GoogleMapController? mapController;
  LatLng center = const LatLng(11.7749, 78.4194);

  Set<Marker> markers = {};
  Map<String, BitmapDescriptor> markerIcons = {};
  Set<Polygon> polygons = {};

  String _sentTime = "";
  final List<({String name, LatLng position, bool running})> _equipment = [];
  bool _loading = false;
  Map<String, LatLng> _gifObjects = {};
  Map<String, Offset> _gifOffsets = {};
  late BitmapDescriptor _redAeratorIcon;


  @override
  void initState() {
    AppLog.log("modelID == ${widget.modelId}");
    super.initState();
    _init();
  }

  @override
  void dispose() {
    mapController?.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await _loadIcons();
      await _fetchData();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------------- ICON LOAD ----------------
  Future<void> _loadIcons() async {
    Future<BitmapDescriptor> load(String path) {
      return BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(40, 40)),
        path,
      );
    }

    _redAeratorIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(40, 40)),
      "assets/png/aerators_r.png",
    );

    markerIcons = {
      "gray": await load('assets/png/markergray.png'),
      "green": await load('assets/png/markergreen.png'),
      "red": await load('assets/png/markerred.png'),
      "blue": await load('assets/png/markerblue.png'),
      "yellow": await load('assets/png/markeryellow.png'),
      "pump": await load('assets/png/markerpump.png'),
      "sensor": await load('assets/png/markersensor.png'),
      "fert": await load('assets/png/markerfertilizer.png'),
      "filter": await load('assets/png/markerfilter.png'),
      "injector": await load('assets/png/markerinjector.png'),
    };
  }

  // ---------------- FETCH DATA ----------------
  Future<void> _fetchData() async {
    try {
      final repo = Repository(HttpService());
      final response = await repo.getgeography({
        "userId": widget.customerId,
        "controllerId": widget.controllerId,
      });

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);
      final deviceList = data["data"]["deviceList"] ?? [];
      _sentTime = data["data"]?["liveMessage"]?["cM"]?["SentTime"] ?? "";
      _gifObjects.clear();
      final equipment = <({String name, LatLng position, bool running})>[];
      Set<Marker> newMarkers = {};
      Set<Polygon> newPolygons = {};

      for (var device in deviceList) {
        // --- Process Device Geography ---
        final geo = device["geography"];
        if (geo != null) {
          if (geo["lat"] != null && geo["long"] != null) {

            final marker = _createMarker(
              id: "device-${device["deviceId"]}",
              lat: geo["lat"],
              lng: geo["long"],
              title: device["deviceName"],
              type: device["categoryName"],
              status: device["status"],
              percentage: 0,
            );

            if (marker != null) {
              newMarkers.add(marker);
            }
          }

          // Polygons and Labels for Device
          if (geo["area"] != null && (geo["area"] as List).isNotEmpty) {
            final polyPoints = (geo["area"] as List).map((p) =>
                LatLng((p["lat"] as num).toDouble(), (p["long"] as num).toDouble())
            ).toList();

            newPolygons.add(_createPolygon(
              id: "poly-device-${device["deviceId"]}",
              points: geo["area"],
              color: Colors.blue,
            ));

            // Permanent Label
            final labelIcon = await _getLabelIcon(device["deviceName"] ?? "");
            newMarkers.add(Marker(
              markerId: MarkerId("label-device-${device["deviceId"]}"),
              position: _calculateCentroid(polyPoints),
              icon: labelIcon,
              anchor: const Offset(0.5, 0.5),
            ));
          }
        }

        // --- Process Connected Objects ---
        for (var obj in device["connectedObject"] ?? []) {
          if (obj["lat"] != null && obj["long"] != null) {
            var resultstaus = getStatusPercentage(double.tryParse(obj["sNo"].toString()) ?? -1, data["data"]["liveMessage"]);
            equipment.add((
            name: (obj["name"] ?? obj["objectName"] ?? "Object").toString(),
            position: LatLng((obj["lat"] as num).toDouble(), (obj["long"] as num).toDouble()),
            running: resultstaus["status"] == 1,
            ));
            final marker = _createMarker(
              id: "obj-${obj["sNo"]}",
              lat: obj["lat"],
              lng: obj["long"],
              title: obj["name"] ?? obj["objectName"],
              type: obj["objectName"],
              status: resultstaus["status"],
              percentage: resultstaus["percentage"] ?? 0,
            );

            if (marker != null) {
              newMarkers.add(marker);
            }
          }


        }
      }

      final initialCenter = _getInitialCenter(deviceList);

      if (!mounted) return;
      setState(() {
        _equipment..clear()..addAll(equipment);
        markers = newMarkers;
        polygons = newPolygons;
        if (initialCenter != null) center = initialCenter;
      });
      if (initialCenter != null) {
        await mapController?.animateCamera(CameraUpdate.newLatLngZoom(center, 17));
      }
      await _updateGifPositions();
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _updateGifPositions() async {
    if (mapController == null) return;

    Map<String, Offset> temp = {};

    for (var entry in _gifObjects.entries) {
      final screen =
      await mapController!.getScreenCoordinate(entry.value);

      temp[entry.key] = Offset(
        screen.x.toDouble(),
        screen.y.toDouble(),
      );
    }

    if (!mounted) return;
    setState(() {
      _gifOffsets = temp;
    });
  }

  // ---------------- CREATE POLYGON ----------------
  Polygon _createPolygon({
    required String id,
    required List<dynamic> points,
    required Color color,
  }) {
    List<LatLng> latLngPoints = points.map((p) {
      return LatLng((p["lat"] as num).toDouble(), (p["long"] as num).toDouble());
    }).toList();

    return Polygon(
      polygonId: PolygonId(id),
      points: latLngPoints,
      strokeWidth: 2,
      strokeColor: color.withOpacity(1),
      fillColor: color.withOpacity(0.8),
      geodesic: true,
    );
  }

  Map<String, int> getStatusPercentage(
      double serialNumber, Map<String, dynamic>? liveMessage)
  {

    try {
      // 1. Safe extraction of the nested map and string
      if (liveMessage == null || liveMessage["cM"] == null) {
        return {"status": 0, "percentage": 0};
      }

      // Cast cM safely
      final dynamic cMData = liveMessage["cM"];
      if (cMData is! Map) return {"status": 0, "percentage": 0};

      final String? data = cMData["2402"]?.toString();

      if (data == null || data.isEmpty) {
        AppLog.log('data is empty or null');
        return {"status": 0, "percentage": 0};
      }

      final List<String> values = data.split(";");

      for (var value in values) {

        final List<String> parts = value.split(",");
        if (parts.length >= 3) {
          // 2. Convert string ID to double to ensure 13.010 == 13.01
          double? partId = double.tryParse(parts[0]);

          if (partId != null && partId == serialNumber) {
            return {
              "status": int.tryParse(parts[1]) ?? 0,
              "percentage": int.tryParse(parts[2]) ?? 0,
            };
          }
        }
      }

      AppLog.log('No match found for serialNumber');
      return {"status": 0, "percentage": 0};

    } catch (e, stacktrace) {
      AppLog.log("Error getting valve data: $e");
      AppLog.log("Stacktrace: $stacktrace");
      return {"status": 0, "percentage": 0};
    }
  }

  LatLng? _getInitialCenter(List deviceList) {
    AppLog.log("_getInitialCenter");
    // 1️⃣ First Valve Object
    for (var device in deviceList) {
      for (var obj in device["connectedObject"] ?? []) {
        if (obj["objectName"] != null &&
            obj["objectName"].toString().contains("Valve") &&
            obj["lat"] != null &&
            obj["long"] != null) {

          return LatLng((obj["lat"] as num).toDouble(), (obj["long"] as num).toDouble());
        }
      }
    }

    // 2️⃣ First Available Object
    for (var device in deviceList) {
      for (var obj in device["connectedObject"] ?? []) {
        if (obj["lat"] != null && obj["long"] != null) {

          // AppLog.log("object:%:${LatLng(obj["lat"], obj["long"])}");
          return LatLng((obj["lat"] as num).toDouble(), (obj["long"] as num).toDouble());
        }
      }
    }

    // 3️⃣ First Device Geography
    for (var device in deviceList) {
      final geo = device["geography"];
      if (geo != null &&
          geo["lat"] != null &&
          geo["long"] != null) {
        // AppLog.log("geography:%:${LatLng(geo["lat"], geo["long"])}");

        return LatLng((geo["lat"] as num).toDouble(), (geo["long"] as num).toDouble());
      }
    }

    return null;
  }

  // ---------------- CREATE MARKER ----------------


  Marker? _createMarker({
    required String id,
    required num lat,
    required num lng,
    required String title,
    required String type,
    int? status,
    int? percentage,
  }) {
    final position = LatLng(lat.toDouble(), lng.toDouble());

    // ✅ STATUS 1 → use GIF overlay
    if (status == 1) {
      _gifObjects[id] = position;
      return null;
    }

    // ✅ STATUS 0 → normal marker
    return Marker(
      markerId: MarkerId(id),
      position: position,
      icon: _redAeratorIcon,
      infoWindow: InfoWindow(
        title: title,
      ),
    );
  }

  Widget _buildCustomInfoWindow() {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              "assets/gif/aerators_g.gif",
              height: 50,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
  // Helper to find the center of the polygon
  LatLng _calculateCentroid(List<LatLng> points) {
    double lat = 0, lng = 0;
    for (var p in points) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / points.length, lng / points.length);
  }

// Helper to create a Text-only Marker Icon
  Future<BitmapDescriptor> _getLabelIcon(String label) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double fontSize = 12.0; // Adjust size as needed

    final TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
    painter.text = TextSpan(
      text: label,
      style: const TextStyle(
        fontSize: fontSize,
        color: Colors.white,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.black45, // Background makes text readable on map
      ),
    );

    painter.layout();
    painter.paint(canvas, const Offset(0, 0));

    final img = await pictureRecorder.endRecording().toImage(
      painter.width.toInt(),
      painter.height.toInt(),
    );
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }
  BitmapDescriptor _getIcon(String type, int? status, int? percentage) {

    int st = status ?? 0;
    int per = percentage ?? 0;

    if (type.contains("Valve")) {
      if (st == 1 && per == 100) {
        return markerIcons["blue"] ?? BitmapDescriptor.defaultMarker;
      }
      else if (st == 0 && per == 0) {
        return markerIcons["gray"] ?? BitmapDescriptor.defaultMarker;
      }
      else if (st == 0 && per > 0) {
        return markerIcons["yellow"] ?? BitmapDescriptor.defaultMarker;
      }
      else if (st == 1 && per <= 100) {
        return markerIcons["green"] ?? BitmapDescriptor.defaultMarker;
      }
      else {
        return markerIcons["gray"] ?? BitmapDescriptor.defaultMarker;
      }
    }

    if (type.contains("Pump")) {
      return markerIcons["pump"] ?? BitmapDescriptor.defaultMarker;
    }

    if (type.contains("Sensor")) {
      return markerIcons["sensor"] ?? BitmapDescriptor.defaultMarker;
    }

    if (type.contains("Filter")) {
      return markerIcons["filter"] ?? BitmapDescriptor.defaultMarker;
    }

    if (type.contains("fertilizer")) {
      return markerIcons["fert"] ?? BitmapDescriptor.defaultMarker;
    }

    if (type.contains("Injector")) {
      return markerIcons["injector"] ?? BitmapDescriptor.defaultMarker;
    }

    return markerIcons["blue"] ?? BitmapDescriptor.defaultMarker;
  }

  // ---------------- MAP CREATED ----------------

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;

    // Small delay to make sure map is fully rendered
    Future.delayed(const Duration(milliseconds: 500), () {
      mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: center,
            zoom: 17, //
          ),
        ),
      );
    });
  }


  Widget _metric(String label, int value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Expanded(child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor.withOpacity(.25))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text('$value', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color)),
        Text(label, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    ));
  }

  Widget _inventory() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Equipment status', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text('Connected objects with locations', style: theme.textTheme.bodySmall),
        const SizedBox(height: 12),
        Expanded(child: _equipment.isEmpty
            ? const Center(child: Text('No mapped objects'))
            : ListView.separated(
          itemCount: _equipment.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final item = _equipment[index];
            final color = item.running ? Colors.green : Colors.red;
            return Material(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(.45),
              borderRadius: BorderRadius.circular(10),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: color.withOpacity(.12),
                    child: Icon(Icons.waves, color: color)),
                title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(item.running ? 'Running' : 'Stopped', style: TextStyle(color: color)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => mapController?.animateCamera(CameraUpdate.newLatLngZoom(item.position, 18)),
              ),
            );
          },
        )),
      ]),
    );
  }

  Widget _mapPanel() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(children: [
        GoogleMap(
          mapType: MapType.hybrid,
          initialCameraPosition: CameraPosition(target: center, zoom: 17),
          markers: markers,
          polygons: polygons,
          onMapCreated: (controller) {
            _onMapCreated(controller);
            _updateGifPositions();
          },
          onCameraMove: (_) => _updateGifPositions(),
          onCameraIdle: _updateGifPositions,
        ),
        ..._gifOffsets.entries.map((entry) => Positioned(
          left: entry.value.dx - 25,
          top: entry.value.dy - 50,
          child: IgnorePointer(child: Image.asset('assets/gif/aerators_g.gif', height: 50, width: 50)),
        )),
        Positioned(left: 12, bottom: 12, child: IgnorePointer(child: Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          child: Padding(padding: const EdgeInsets.all(10), child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.circle, color: Colors.green, size: 10),
            const SizedBox(width: 5), const Text('Running'),
            const SizedBox(width: 14),
            const Icon(Icons.circle, color: Colors.red, size: 10),
            const SizedBox(width: 5), const Text('Stopped'),
          ])),
        ))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final running = _equipment.where((e) => e.running).length;
    return Scaffold(
      appBar: AppBar(
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Geography'),
          Text('Aerator monitoring', style: TextStyle(fontSize: 12)),
        ]),
        actions: [
          IconButton(tooltip: 'Refresh', onPressed: _loading ? null : _init, icon: const Icon(Icons.refresh)),
          IconButton(tooltip: 'Edit map', icon: const Icon(Icons.edit_location_alt_outlined),
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => MapConnectionObject(
                  userId: widget.userId, customerId: widget.customerId, controllerId: widget.controllerId,
                  imeiNo: widget.imeiNo, modelId: widget.modelId,
                )));
                if (mounted) await _init();
              }),
        ],
      ),
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Row(children: [
            _metric('Mapped objects', _equipment.length, Icons.waves, theme.colorScheme.primary),
            const SizedBox(width: 8),
            _metric('Running', running, Icons.play_circle_outline, Colors.green),
            const SizedBox(width: 8),
            _metric('Stopped', _equipment.length-running, Icons.stop_circle_outlined, Colors.red),
          ]),
          if (_loading) const LinearProgressIndicator(),
          const SizedBox(height: 10),
          Expanded(child: LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth >= 800) {
              return Row(children: [
                Expanded(child: _mapPanel()),
                const SizedBox(width: 12),
                SizedBox(width: 300, child: _inventory()),
              ]);
            }
            return Column(children: [
              Expanded(flex: 3, child: _mapPanel()),
              const SizedBox(height: 8),
              Expanded(flex: 2, child: _inventory()),
            ]);
          })),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.schedule, size: 15),
            const SizedBox(width: 6),
            Expanded(child: Text('Live sync: ${_sentTime.isEmpty ? "Not available" : _sentTime}',
                style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
            const Text('Hybrid map', style: TextStyle(fontSize: 11)),
          ]),
        ]),
      )),
    );
  }
}
