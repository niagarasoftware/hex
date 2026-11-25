import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:hex/utils/helpers/log_print.dart';
import 'package:hex/utils/constants.dart';

import '../../../repository/repository.dart';
import '../../../services/http_service.dart';
import '../../../views/common/user_dashboard/widgets/valve_status_legend.dart';
import '../polygon_area_calculator.dart';
import 'map_conection_objects.dart';
import '../../../services/mqtt_service.dart';
import '../../../utils/environment.dart';


class MapScreenOro extends StatefulWidget {
  const MapScreenOro({
    super.key,
    required this.userId,
    required this.customerId,
    required this.controllerId,
    required this.imeiNo,
    required this.modelId,
    this.isCheckDashboard = false,
  });

  final int userId, customerId, controllerId,modelId;
  final String imeiNo;
  final bool isCheckDashboard;

  @override
  State<MapScreenOro> createState() => _MapScreenOroState();
}

class _MapScreenOroState extends State<MapScreenOro> {
  GoogleMapController? mapController;
  LatLng center = const LatLng(11.7749, 78.4194);
  double _currentZoom = 15;

  Set<Marker> markers = {};
  Map<String, BitmapDescriptor> markerIcons = {};
  Set<Polygon> polygons = {};
  Set<Polyline> irrigationRows = {};
  Set<Circle> waterDrops = {};
  Set<Circle> plantDots = {};
  final List<_WaterRow> _runningRows = [];
  Timer? _flowTimer;
  double _flowPhase = 0;
  // Visual spacing in metres. These are schematic, not surveyed pipe positions.
  static const double _rowSpacingMeters = 8;
  static const int _maxRowsPerValve = 45;

  String _sentTime = "";
  List<_ValveAreaEntry> _valveAreas = [];

  bool _isValve(dynamic obj) =>
      (obj['objectName'] ?? '').toString().toLowerCase().contains('valve');

  bool _isValveRunning(int status) => status == 1;

  void _requestLiveData() {
    final payload = jsonEncode({
      '3001': ''
    });

    MqttService().topicToPublishAndItsMessage(
      payload,
      '${Environment.mqttPublishTopic}/${widget.imeiNo}',
    );
  }

  Widget _buildAreaSummary() {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final total = _valveAreas.fold<double>(0, (sum, e) => sum + e.acres);
    final irrigated = _valveAreas.fold<double>(0, (sum, e) => sum + e.irrigatedAcres);
    final running = _valveAreas.fold<double>(0, (sum, e) => sum + (e.running ? e.remainingAcres : 0.0));
    final pending = _valveAreas.fold<double>(0, (sum, e) => sum + (!e.running ? e.remainingAcres : 0.0));
    return Material(
      color: c.surface,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text('Total field area', style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),
          Text('${total.toStringAsFixed(2)} ac', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(height: 10, child: LayoutBuilder(builder: (context, constraints) {
              final width = constraints.maxWidth;
              return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                SizedBox(width: total > 0 ? width * irrigated / total : 0.0, child: const ColoredBox(color: Colors.blue)),
                SizedBox(width: total > 0 ? math.min(width * running / total, math.max(0.0, width - width * irrigated / total)) : 0.0, child: const ColoredBox(color: Colors.green)),
                Expanded(child: ColoredBox(color: c.surfaceContainerHighest)),
              ]);
            })),
          ),
          const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _areaMetric('Irrigated', irrigated, Colors.blue)),
            Expanded(child: _areaMetric('Irrigating', running, Colors.green)),
            Expanded(child: _areaMetric('Pending', pending, c.onSurfaceVariant)),
          ]),
          const SizedBox(height: 8),
          Text('Estimated area based on irrigation progress', style: theme.textTheme.bodySmall),
          const Divider(height: 24),
          Text('Valve areas', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          if (_valveAreas.isEmpty) const Center(child: Text('No valve areas')),
          ..._valveAreas.map((e) {
            final color = e.color;
            final status = e.percentage == 100 ? 'Completed' : e.running ? 'Irrigating' : e.percentage > 0 ? 'Partially irrigated' : 'Not irrigated';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: c.surfaceContainerLow, borderRadius: BorderRadius.circular(8), border: Border(left: BorderSide(color: color, width: 3))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.water_drop_outlined, color: color, size: 18),
                  const SizedBox(width: 6),
                  Expanded(child: Text(e.name, style: theme.textTheme.titleSmall)),
                  Text('${e.acres.toStringAsFixed(2)} ac', style: theme.textTheme.labelLarge),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(child: Text(status, style: theme.textTheme.bodySmall)),
                  Text('${e.percentage}%', style: theme.textTheme.labelLarge),
                ]),
                const SizedBox(height: 6),
                ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(value: e.percentage / 100.0, minHeight: 6, color: color, backgroundColor: c.surfaceContainerHighest)),
                const SizedBox(height: 6),
                Text('Irrigated: ${e.irrigatedAcres.toStringAsFixed(2)} ac', style: theme.textTheme.bodySmall),
                Text('${e.running ? 'Irrigating' : 'Pending'}: ${e.remainingAcres.toStringAsFixed(2)} ac', style: theme.textTheme.bodySmall),
              ]),
            );
          }),
        ],
      ),
    );
  }

  Widget _areaMetric(String label, double value, Color color) => Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: Theme.of(context).textTheme.labelSmall),
    const SizedBox(height: 4),
    Text('${value.toStringAsFixed(2)} ac', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
  ]);

  void _openMapEditor() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => MapConnectionObject(
        userId: widget.userId, customerId: widget.customerId, controllerId: widget.controllerId,
        imeiNo: widget.imeiNo, modelId: widget.modelId)));
  }

  Widget _mapHeader() {
    final theme = Theme.of(context);
    return Material(color: theme.colorScheme.surface, child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Geography', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          Text('Farm monitoring', style: theme.textTheme.bodySmall),
        ])),
        Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('Live Sync', style: theme.textTheme.labelMedium?.copyWith(color: Colors.green)),
          Text(_sentTime.isEmpty ? '--' : _sentTime, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
        ])),
        if (kIsWeb || widget.isCheckDashboard) ...[
          IconButton(tooltip: 'Refresh', onPressed: () async { await _init(); }, icon: const Icon(Icons.refresh)),
           IconButton(tooltip: 'Edit', onPressed: _openMapEditor, icon: const Icon(Icons.map_outlined)),
        ],
      ]),
    ));
  }

  @override
  void initState() {
    super.initState();
    _init();
    _flowTimer = Timer.periodic(const Duration(milliseconds: 160), (_) {
      if (!mounted || _runningRows.isEmpty || _currentZoom < 17) return;
      _flowPhase += 0.035;
      _updateWaterDrops();
    });
  }

  @override
  void dispose() {
    _flowTimer?.cancel();
    mapController?.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _loadIcons();
    await _fetchData();
    _requestLiveData();
  }

  // ---------------- ICON LOAD ----------------
  Future<void> _loadIcons() async {
    Future<BitmapDescriptor> load(String path) {
      return BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(40, 40)),
        path,
      );
    }

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

      print("user id :${widget.customerId},controller id:${widget.controllerId}") ;
      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);
      final deviceList = data["data"]["deviceList"] ?? [];
      String date = data["data"]?["liveMessage"]?["cD"] ?? "";
      String time = data["data"]?["liveMessage"]?["cT"] ?? "";
      _sentTime = "$date $time";

      Set<Marker> newMarkers = {};
      Set<Polygon> newPolygons = {};
      Set<Polyline> newRows = {};
      Set<Circle> newPlantDots = {};
      final List<_WaterRow> newRunningRows = [];
      final List<_ValveAreaEntry> newValveAreas = [];

      for (var device in deviceList) {
        final geo = device["geography"];

        // ---------------- DEVICE MARKER ----------------
        if (geo != null && geo["lat"] != null && geo["long"] != null) {
          newMarkers.add(_createMarker(
            id: "device-${device["deviceId"]}",
            lat: geo["lat"],
            lng: geo["long"],
            title: device["deviceName"],
            type: device["categoryName"],
            status: geo["status"],
            percentage: 0,
          ));
        }

        // ---------------- CONNECTED OBJECT ----------------
        for (var obj in device["connectedObject"] ?? []) {

          // ✅ GET LIVE STATUS
          var resultstaus = getStatusPercentage(
            obj["sNo"],
            data["data"]["liveMessage"],
          );

          int st = resultstaus["status"] ?? 0;
          int per = (resultstaus["percentage"] ?? 0).clamp(0, 100).toInt();

          // ---------------- OBJECT MARKER ----------------
          if (obj["lat"] != null && obj["long"] != null) {
            newMarkers.add(_createMarker(
              id: "obj-${obj["sNo"]}",
              lat: obj["lat"],
              lng: obj["long"],
              title: obj["name"] ?? obj["objectName"],
              type: obj["objectName"],
              status: st,
              percentage: per,
            ));
          }

          // ---------------- AREA POLYGON ----------------
          if (obj["area"] != null && obj["area"].isNotEmpty) {
            List<LatLng> points = [];

            for (var point in obj["area"]) {
              if (point["lat"] != null && point["long"] != null) {
                points.add(LatLng(point["lat"], point["long"]));
              }
            }

            if (points.isNotEmpty) {

              // ✅ GET COLOR FROM FUNCTION
              Color areaColor = _getAreaColor(st, per);
              if (_isValve(obj) && points.length >= 3) {
                newValveAreas.add(_ValveAreaEntry(
                  name: (obj['name'] ?? obj['objectName'] ?? 'Valve').toString(),
                  acres: PolygonAreaCalculator.calculateAcres(points),
                  running: _isValveRunning(st) && per < 100,
                  percentage: per.clamp(0, 100).toInt(),
                  color: areaColor,
                ));
              }

              // ✅ ADD POLYGON
              newPolygons.add(
                Polygon(
                  polygonId: PolygonId("area-${obj["sNo"]}"),
                  points: points,
                  strokeColor: areaColor.withOpacity(0.8),
                  strokeWidth: 2,
                  fillColor: areaColor.withOpacity(0.25),
                ),
              );

              // ---------------- AUTO IRRIGATION ROWS + RUNNING WATER DOTS ----------------
              // Rows, plant dots and moving water particles appear ONLY while running.
              if (points.length >= 3 && st == 1 && per < 100 &&
                  (obj["objectName"] ?? "").toString().toLowerCase().contains('valve')) {
                _generatePlantation(
                  id: '${device["deviceId"]}-${obj["sNo"]}',
                  boundary: points,
                  isRunning: st == 1 && per < 100,
                  statusColor: areaColor,
                  rows: newRows,
                  plants: newPlantDots,
                  runningRows: newRunningRows,
                );
              }

              // ---------------- AREA LABEL ----------------
              final centerPoint = _getPolygonCenter(points);

              final labelIcon = await _getLabelIcon(
                  "${obj["name"] ?? obj["objectName"]} ($per%)",areaColor
              );

              newMarkers.add(
                Marker(
                  markerId: MarkerId("label-${obj["sNo"]}"),
                  position: centerPoint,
                  icon: labelIcon,
                  anchor: const Offset(0.5, 0.5),
                  zIndex: 2,
                ),
              );

            }
          }
        }
      }

      final initialCenter = _getInitialCenter(deviceList);

      if (!mounted) return;

      setState(() {
        markers = newMarkers;
        polygons = newPolygons;
        irrigationRows = newRows;
        _valveAreas = newValveAreas;
        plantDots = newPlantDots;
        _runningRows
          ..clear()
          ..addAll(newRunningRows);
        waterDrops = {};
        if (initialCenter != null) {
          center = initialCenter;
        }
      });

      _fitMapToBounds(newMarkers, newPolygons);
    } catch (e) {
      AppLog.log("Error: $e");
    }
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
    // 1️⃣ First Valve Object
    for (var device in deviceList) {
      for (var obj in device["connectedObject"] ?? []) {
        if (obj["objectName"] != null &&
            obj["objectName"].toString().contains("Valve") &&
            obj["lat"] != null &&
            obj["long"] != null) {

          return LatLng(obj["lat"], obj["long"]);
        }
      }
    }

    // 2️⃣ First Available Object
    for (var device in deviceList) {
      for (var obj in device["connectedObject"] ?? []) {
        if (obj["lat"] != null && obj["long"] != null) {

          // AppLog.log("object:%:${LatLng(obj["lat"], obj["long"])}");
          return LatLng(obj["lat"], obj["long"]);
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

        return LatLng(geo["lat"], geo["long"]);
      }
    }

    return null;
  }

  // ---------------- CREATE MARKER ----------------
  Marker _createMarker({
    required String id,
    required double lat,
    required double lng,
    required String title,
    required String type,
    int? status,
    int? percentage,
  }) {
    return Marker(
      markerId: MarkerId(id),
      position: LatLng(lat, lng),
      icon: _getIcon(type, status, percentage),
      infoWindow: InfoWindow(
        title: title,
        snippet: "Irrigation: ${percentage ?? 0}%",
      ),
    );
  }

  Color _getAreaColor(int? status, int? percentage) {
    int st = status ?? 0;
    int per = percentage ?? 0;

    if (per >= 100) return Colors.blue;
    if (st == 1) return Colors.green;
    if (per > 0) return Colors.amber;
    return Colors.grey;
  }

  LatLng _getPolygonCenter(List<LatLng> points) {
    double lat = 0;
    double lng = 0;

    for (var p in points) {
      lat += p.latitude;
      lng += p.longitude;
    }

    return LatLng(lat / points.length, lng / points.length);
  }

  Future<BitmapDescriptor> _getLabelIcon(String text,Color labelColor) async {
    // Use device pixel ratio for high-resolution markers on mobile
    final double ratio = ui.PlatformDispatcher.instance.views.isNotEmpty
        ? ui.PlatformDispatcher.instance.views.first.devicePixelRatio
        : 1.0;

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 13 * ratio,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout();

    // Calculate dynamic width and height with padding
    final double width = textPainter.width + (16 * ratio);
    final double height = textPainter.height + (6 * ratio);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final paint = Paint()..color = labelColor;
    final border = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1 * ratio;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, height),
      Radius.circular(10 * ratio),
    );

    canvas.drawRRect(rect, paint);
    canvas.drawRRect(rect, border);

    textPainter.paint(
      canvas,
      Offset(
        (width - textPainter.width) / 2,
        (height - textPainter.height) / 2,
      ),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  BitmapDescriptor _getIcon(String type, int? status, int? percentage) {

    int st = status ?? 0;
    int per = percentage ?? 0;

    if (type.toLowerCase().contains('valve')) {
      final key = per >= 100 ? 'blue' : st == 1 ? 'green' : per > 0 ? 'yellow' : 'gray';
      return markerIcons[key] ?? BitmapDescriptor.defaultMarker;
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
    // Optional: re-fit when map is ready
    if (markers.isNotEmpty || polygons.isNotEmpty) {
      _fitMapToBounds(markers, polygons);
    }
  }



  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    // AppLog.log("build center:$center");
    final bool isAquaculture = [...AppConstants.aquacultureModelList].contains(widget.modelId);

    return Scaffold(
      appBar: (widget.isCheckDashboard || kIsWeb) ? null : AppBar(title: const Text(" Geography"),
        // automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _init();
            },
          ),
          if (!widget.isCheckDashboard)
            IconButton(
              icon: const Icon(Icons.map_outlined),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => MapConnectionObject(userId: widget.userId, customerId: widget.customerId, controllerId: widget.controllerId, imeiNo: widget.imeiNo,modelId: widget.modelId,),
                ));
              },
              tooltip: 'Edit',
            ),
        ],
      ) ,

      body: Column(children: [
        _mapHeader(),
        Expanded(child: LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 800;
          final map = ClipRRect(borderRadius: BorderRadius.circular(10), child: GoogleMap(
            mapType: MapType.hybrid,
            onCameraMove: (CameraPosition position) {
              final oldVisible = _currentZoom >= 17;
              _currentZoom = position.zoom;
              if (oldVisible != (_currentZoom >= 17)) {
                setState(() {});
              }
            },
            initialCameraPosition: CameraPosition(
              target: center,
              zoom: _currentZoom,
            ),
            markers: markers,
            polygons: polygons,
            polylines: irrigationRows,
            circles: {
              if (_currentZoom >= 17) ...plantDots,
              if (_currentZoom >= 17) ...waterDrops,
            },
            onMapCreated: _onMapCreated,
          ));
          final panel = ClipRRect(borderRadius: BorderRadius.circular(10), child: _buildAreaSummary());
          return Padding(padding: const EdgeInsets.all(8), child: wide
              ? Row(children: [Expanded(child: map), const SizedBox(width: 8), SizedBox(width: 320, child: panel)])
              : Column(children: [Expanded(flex: 3, child: map), const SizedBox(height: 8), Expanded(flex: 2, child: panel)]));
        })),
      ]),
    );
  }
  // Build horizontal irrigation rows clipped to each irregular valve area.
  // Coordinates are projected locally to metres to maintain sensible spacing.
  void _generatePlantation({
    required String id,
    required List<LatLng> boundary,
    required bool isRunning,
    required Color statusColor,
    required Set<Polyline> rows,
    required Set<Circle> plants,
    required List<_WaterRow> runningRows,
  }) {
    final lat0 = boundary.map((p) => p.latitude).reduce((a,b) => a+b) / boundary.length;
    final lng0 = boundary.map((p) => p.longitude).reduce((a,b) => a+b) / boundary.length;
    final xScale = 111320.0 * math.cos(lat0 * math.pi / 180);
    const yScale = 110540.0;
    if (xScale.abs() < 1) return;
    final xy = boundary.map((p) => _XY((p.longitude-lng0)*xScale, (p.latitude-lat0)*yScale)).toList();
    final minY = xy.map((p) => p.y).reduce(math.min);
    final maxY = xy.map((p) => p.y).reduce(math.max);
    final height = maxY-minY;
    if (height <= 0) return;
    final rowStep = math.max(_rowSpacingMeters, height / _maxRowsPerValve);
    int rowIndex = 0;
    LatLng toLatLng(double x, double y) => LatLng(lat0+y/yScale, lng0+x/xScale);

    for (double y=minY+rowStep/2; y<maxY; y+=rowStep) {
      final crossings = <double>[];
      for (int i=0; i<xy.length; i++) {
        final a=xy[i], b=xy[(i+1)%xy.length];
        if ((a.y <= y && b.y > y) || (b.y <= y && a.y > y)) {
          crossings.add(a.x+(y-a.y)*(b.x-a.x)/(b.y-a.y));
        }
      }
      crossings.sort();
      for (int j=0; j+1<crossings.length; j+=2) {
        final start=crossings[j], end=crossings[j+1];
        if (end-start < 2) continue;
        final a=toLatLng(start,y), b=toLatLng(end,y);
        final key='$id-$rowIndex-$j';
        rows.add(Polyline(
          polylineId: PolylineId('plant-row-$key'),
          points: [a,b],
          color: statusColor.withOpacity(.8),
          width: 2,
          zIndex: 2,
        ));
        if (isRunning) {
          runningRows.add(_WaterRow(key,a,b));
          // Static plant dots along the row, distinct from moving water drops.
          // Cap the count to protect Google Maps performance on large farms.
          final lengthMeters = end - start;
          final count = math.min(18, (lengthMeters / 6).floor());
          for (int k = 1; k <= count; k++) {
            final t = k / (count + 1);
            plants.add(Circle(
              circleId: CircleId('plant-$key-$k'),
              center: toLatLng(start + lengthMeters * t, y),
              radius: 1.4,
              fillColor: Colors.green,
              strokeColor: Colors.green,
              strokeWidth: 0,
              zIndex: 3,
            ));
          }
        }
      }
      rowIndex++;
    }
  }

  void _updateWaterDrops() {
    final drops = <Circle>{};
    // Keep particle count bounded on large farms.
    for (final row in _runningRows.take(180)) {
      for (int i=0; i<2; i++) {
        // Each row gets a stable, different starting point and speed.
        // This prevents all water particles from jumping together.
        final hash = row.id.codeUnits.fold<int>(17, (h, c) => (h * 31 + c) & 0x7fffffff);
        final offset = (hash % 997) / 997.0;
        final speed = 0.55 + ((hash ~/ 997) % 55) / 100.0;
        final particleGap = 0.38 + ((hash ~/ 113) % 20) / 100.0;
        final t = (_flowPhase * speed + offset + i * particleGap) % 1.0;
        drops.add(Circle(
          circleId: CircleId('water-${row.id}-$i'),
          center: LatLng(
            row.start.latitude+(row.end.latitude-row.start.latitude)*t,
            row.start.longitude+(row.end.longitude-row.start.longitude)*t,
          ),
          radius: 2.0,
          fillColor: Colors.blue,
          strokeColor: Colors.white,
          strokeWidth: 1,
          zIndex: 4,
        ));
      }
    }
    setState(() => waterDrops=drops);
  }

  void _fitMapToBounds(Set<Marker> markers, Set<Polygon> polygons) {
    if (mapController == null) return;
    if (markers.isEmpty && polygons.isEmpty) return;

    List<LatLng> allPoints = [];

    // ✅ Add marker positions
    for (var m in markers) {
      allPoints.add(m.position);
    }

    // ✅ Add polygon points
    for (var p in polygons) {
      allPoints.addAll(p.points);
    }

    if (allPoints.isEmpty) return;

    double minLat = allPoints.first.latitude;
    double maxLat = allPoints.first.latitude;
    double minLng = allPoints.first.longitude;
    double maxLng = allPoints.first.longitude;

    for (var point in allPoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    // ✅ Run AFTER UI is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || mapController == null) return;

      try {
        mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 80),
        );
      } catch (e) {
        debugPrint("Map fit error: $e");
      }
    });
  }

}
class _XY {
  const _XY(this.x,this.y);
  final double x,y;
}

class _WaterRow {
  const _WaterRow(this.id,this.start,this.end);
  final String id;
  final LatLng start,end;
}


class _ValveAreaEntry {
  const _ValveAreaEntry({
    required this.name,
    required this.acres,
    required this.running,
    required this.percentage,
    required this.color,
  });
  final String name;
  final double acres;
  final bool running;
  final int percentage;
  final Color color;
  double get irrigatedAcres => acres * percentage / 100.0;
  double get remainingAcres => math.max(0.0, acres - irrigatedAcres);
}
