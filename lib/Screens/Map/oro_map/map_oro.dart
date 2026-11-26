import 'dart:math' as math;
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hex/utils/helpers/log_print.dart';

import '../../../repository/repository.dart';
import '../../../services/http_service.dart';
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

  final int userId, customerId, controllerId, modelId;
  final String imeiNo;
  final bool isCheckDashboard;

  @override
  State<MapScreenOro> createState() => _MapScreenOroState();
}

class _MapScreenOroState extends State<MapScreenOro> {
  GoogleMapController? mapController;
  LatLng center = const LatLng(11.7749, 78.4194);
  double _currentZoom = 16.5;
  int _lastZoomGroup = 1; // 0: <16, 1: 16-18, 2: >18

  CameraPosition? _currentCameraPosition;
  bool _hasInitialBoundsFit = false;
  int _labelGenToken = 0;

  String? _selectedPolygonId;
  String? _hoveredPolygonId;
  _SelectedValveData? _selectedValveData;

  Set<Marker> markers = {};
  Set<Marker> _baseMarkers = {};
  Map<String, BitmapDescriptor> markerIcons = {};
  Set<Polygon> polygons = {};
  Set<Polyline> statusBoundaries = {};

  final Map<String, BitmapDescriptor> _bitmapCache = {};
  final List<_RawPolygonData> _rawPolygonList = [];

  // Centralized semantic status palette
  static const Color _runningColor = Color(0xFF22C55E); // Green
  static const Color _inactiveColor = Color(0xFF64748B); // Slate Grey
  static const Color _partialColor = Color(0xFFF59E0B); // Amber
  static const Color _completedColor = Color(0xFF3B82F6); // Blue

  String _sentTime = "";
  List<_ValveAreaEntry> _valveAreas = [];
  dynamic _rawDeviceList;
  dynamic _rawLiveMessage;

  bool _isValve(dynamic obj) =>
      (obj['objectName'] ?? '').toString().toLowerCase().contains('valve');

  bool _isValveRunning(int status) => status == 1;

  int _getZoomGroup(double zoom) {
    if (zoom < 16.0) return 0;
    if (zoom <= 18.0) return 1;
    return 2;
  }

  Color _getAreaColor(int? status, int? percentage) {
    int st = status ?? 0;
    int per = (percentage ?? 0).clamp(0, 100);

    if (per >= 100) return _completedColor;
    if (st == 1) return _runningColor;
    if (per > 0) return _partialColor;
    return _inactiveColor;
  }

  void _requestLiveData() {
    final payload = jsonEncode({'3001': ''});
    MqttService().topicToPublishAndItsMessage(
      payload,
      '${Environment.mqttPublishTopic}/${widget.imeiNo}',
    );
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    mapController?.dispose();
    super.dispose();
  }

  Future<void> _init({bool resetBounds = false}) async {
    if (resetBounds) {
      _hasInitialBoundsFit = false;
    }
    await _loadIcons();
    if (!mounted) return;
    await _fetchData();
    if (mounted) _requestLiveData();
  }

  // ---------------- ICON LOAD ----------------
  Future<void> _loadIcons() async {
    Future<BitmapDescriptor> load(String path) {
      return BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(36, 36)),
        path,
      );
    }

    try {
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
    } catch (e) {
      debugPrint("Icon load warning: $e");
    }
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
      _rawDeviceList = data["data"]["deviceList"] ?? [];
      _rawLiveMessage = data["data"]?["liveMessage"];

      String date = _rawLiveMessage?["cD"] ?? "";
      String time = _rawLiveMessage?["cT"] ?? "";
      _sentTime = "$date $time";

      await _buildMapElements();
    } catch (e) {
      AppLog.log("Geography fetch error: $e");
    }
  }

  // ---------------- BUILD MAP ELEMENTS ----------------
  Future<void> _buildMapElements() async {
    if (_rawDeviceList == null) return;

    final currentToken = ++_labelGenToken;

    Set<Marker> newMarkers = {};
    Set<Polyline> newBoundaries = {};
    final List<_ValveAreaEntry> newValveAreas = [];
    _rawPolygonList.clear();

    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final zoomGroup = _getZoomGroup(_currentZoom);

    for (var device in _rawDeviceList) {
      final geo = device["geography"];

      // ---------------- DEVICE MARKER ----------------
      if (geo != null && geo["lat"] != null && geo["long"] != null) {
        newMarkers.add(await _createMarker(
          id: "device-${device["deviceId"]}",
          lat: geo["lat"],
          lng: geo["long"],
          title: device["deviceName"],
          type: device["categoryName"],
          status: geo["status"],
          percentage: 0,
        ));
      }

      // ---------------- CONNECTED OBJECTS ----------------
      for (var obj in device["connectedObject"] ?? []) {
        var resultStatus = getStatusPercentage(
          obj["sNo"],
          _rawLiveMessage,
        );

        int st = resultStatus["status"] ?? 0;
        int per = (resultStatus["percentage"] ?? 0).clamp(0, 100).toInt();
        bool hasPolygon = obj["area"] != null &&
            (obj["area"] as List).isNotEmpty &&
            (obj["area"] as List).length >= 3;

        // ---------------- OBJECT MARKER (if no polygon) ----------------
        if (!hasPolygon && obj["lat"] != null && obj["long"] != null) {
          newMarkers.add(await _createMarker(
            id: "obj-${obj["sNo"]}",
            lat: obj["lat"],
            lng: obj["long"],
            title: (obj["name"] ?? obj["objectName"]).toString(),
            type: obj["objectName"],
            status: st,
            percentage: per,
          ));
        }

        // ---------------- AREA POLYGON & COMPACT LABEL ----------------
        if (hasPolygon) {
          List<LatLng> points = [];

          for (var point in obj["area"]) {
            if (point["lat"] != null && point["long"] != null) {
              points.add(LatLng(point["lat"], point["long"]));
            }
          }

          if (points.length >= 3) {
            Color areaColor = _getAreaColor(st, per);
            final areaAcres = PolygonAreaCalculator.calculateAcres(points);
            final valveName =
                (obj['name'] ?? obj['objectName'] ?? 'Valve').toString();
            final polyId = "area-${obj["sNo"]}";

            if (_isValve(obj)) {
              newValveAreas.add(_ValveAreaEntry(
                name: valveName,
                acres: areaAcres,
                running: _isValveRunning(st) && per < 100,
                percentage: per,
                color: areaColor,
              ));
            }

            _rawPolygonList.add(_RawPolygonData(
              sNo: (obj["sNo"] as num).toDouble(),
              valveName: valveName,
              status: st,
              percentage: per,
              acres: areaAcres,
              deviceId: device["deviceId"] ?? "",
              points: points,
              color: areaColor,
            ));

            // Centroid Label Marker
            final centerPoint = _getPolygonCenter(points);
            final labelIcon = await _generateBitmapLabel(
              valveName,
              st,
              per,
              zoomGroup,
              pixelRatio,
            );

            newMarkers.add(
              Marker(
                markerId: MarkerId("label-${obj["sNo"]}"),
                position: centerPoint,
                icon: labelIcon,
                anchor: const Offset(0.5, 0.5),
                zIndexInt: st == 1 ? 5 : 2,
                onTap: () => _handlePolygonTap(
                  polygonId: polyId,
                  valveName: valveName,
                  status: st,
                  percentage: per,
                  acres: areaAcres,
                  deviceId: device["deviceId"] ?? "",
                ),
              ),
            );
          }
        }
      }
    }

    if (!mounted || currentToken != _labelGenToken) return;

    final initialCenter = _getInitialCenter(_rawDeviceList);

    setState(() {
      _baseMarkers = newMarkers;
      statusBoundaries = newBoundaries;
      _valveAreas = newValveAreas;
      _lastZoomGroup = zoomGroup;
      _updatePolygonStyles();
      _updateMarkerStyles();
      if (initialCenter != null && center.latitude == 11.7749) {
        center = initialCenter;
      }
    });

    if (!_hasInitialBoundsFit) {
      _fitMapToBounds(newMarkers, polygons);
    }
  }

  // ---------------- UPDATE POLYGON HOVER & SELECTION STYLES ----------------
  void _updatePolygonStyles() {
    final colorScheme = Theme.of(context).colorScheme;
    final themeAccent = colorScheme.secondary;

    polygons = _rawPolygonList.map((data) {
      final polyId = "area-${data.sNo}";
      final isSelected = polyId == _selectedPolygonId;
      final isHovered = polyId == _hoveredPolygonId;
      final isHighlighted = isSelected || isHovered;
      final areaColor = data.color;

      return Polygon(
        polygonId: PolygonId(polyId),
        points: data.points,
        strokeColor: isHighlighted ? themeAccent : areaColor,
        strokeWidth: isSelected ? 4 : (isHovered ? 3 : 2),
        fillColor: areaColor.withOpacity(
          isSelected ? 0.32 : (data.status == 1 ? 0.18 : 0.12),
        ),
        consumeTapEvents: true,
        onTap: () => _handlePolygonTap(
          polygonId: polyId,
          valveName: data.valveName,
          status: data.status,
          percentage: data.percentage,
          acres: data.acres,
          deviceId: data.deviceId,
        ),
      );
    }).toSet();
  }

  // ---------------- UPDATE MARKER HOVER & SELECTION STYLES ----------------
  Future<void> _updateMarkerStyles() async {
    final colorScheme = Theme.of(context).colorScheme;
    final themeAccent = colorScheme.secondary;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final zoomGroup = _getZoomGroup(_currentZoom);

    Set<Marker> updatedMarkers = {};

    for (var m in _baseMarkers) {
      final markerIdStr = m.markerId.value;
      if (markerIdStr.startsWith("label-")) {
        final sNoStr = markerIdStr.replaceFirst("label-", "");
        final polyId = "area-$sNoStr";
        final isHighlighted =
            polyId == _selectedPolygonId || polyId == _hoveredPolygonId;

        _RawPolygonData? rawData;
        try {
          rawData = _rawPolygonList.firstWhere(
            (p) => "area-${p.sNo}" == polyId,
          );
        } catch (_) {
          rawData = null;
        }

        if (rawData != null) {
          final labelIcon = await _generateBitmapLabel(
            rawData.valveName,
            rawData.status,
            rawData.percentage,
            zoomGroup,
            pixelRatio,
            overrideBorderColor: isHighlighted ? themeAccent : null,
          );

          updatedMarkers.add(m.copyWith(
            iconParam: labelIcon,
            zIndexIntParam: isHighlighted ? 10 : (rawData.status == 1 ? 5 : 2),
          ));
          continue;
        }
      }
      updatedMarkers.add(m);
    }

    if (mounted) {
      setState(() {
        markers = updatedMarkers;
      });
    }
  }

  // ---------------- HANDLE POLYGON & LABEL TAP ----------------
  void _handlePolygonTap({
    required String polygonId,
    required String valveName,
    required int status,
    required int percentage,
    required double acres,
    required String deviceId,
  }) {
    setState(() {
      _selectedPolygonId = polygonId;
      _selectedValveData = _SelectedValveData(
        polygonId: polygonId,
        valveName: valveName,
        status: status,
        percentage: percentage,
        acres: acres,
        deviceId: deviceId,
      );
      _updatePolygonStyles();
    });
    _updateMarkerStyles();
  }

  void _clearSelection() {
    setState(() {
      _selectedPolygonId = null;
      _selectedValveData = null;
      _hoveredPolygonId = null;
      _updatePolygonStyles();
    });
    _updateMarkerStyles();
  }

  // ---------------- GENERATE COMPACT BITMAP LABEL ----------------
  Future<BitmapDescriptor> _generateBitmapLabel(
    String name,
    int st,
    int per,
    int zoomGroup,
    double pixelRatio, {
    Color? overrideBorderColor,
  }) async {
    per = per.clamp(0, 100);
    final borderHex = overrideBorderColor?.toARGB32() ?? 0;
    final cacheKey =
        'lbl_${name}_${st}_${per}_${zoomGroup}_${pixelRatio.toStringAsFixed(1)}_$borderHex';

    if (_bitmapCache.containsKey(cacheKey)) {
      return _bitmapCache[cacheKey]!;
    }

    final accent = _getAreaColor(st, per);
    final borderColor = overrideBorderColor ?? accent;
    const bg = Color(0xF00F172A); // Dark Slate Navy background for high contrast

    // Compact Dimensions
    double w = 92.0;
    double h = zoomGroup == 0 ? 24.0 : (zoomGroup == 1 ? 34.0 : 46.0);

    final scale = pixelRatio.clamp(1.0, 3.0);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(scale);

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.5, 0.5, w - 1.0, h - 1.0),
      const Radius.circular(6),
    );

    canvas.drawRRect(rect, Paint()..color = bg);
    canvas.drawRRect(
      rect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = overrideBorderColor != null ? 1.8 : 1.0,
    );

    void drawText(
      String text,
      double x,
      double y,
      double size,
      Color color, {
      double maxWidth = 76,
      bool bold = false,
    }) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: color,
            fontSize: size,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            fontFamily: 'sans-serif',
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      );
      painter.layout(maxWidth: maxWidth);
      painter.paint(canvas, Offset(x, y));
    }

    if (zoomGroup == 0) {
      // Zoom < 16: Small status dot + Valve Name
      canvas.drawCircle(const Offset(10, 12), 3.5, Paint()..color = accent);
      drawText(name, 18, 5, 10, Colors.white, maxWidth: w - 24, bold: true);
    } else if (zoomGroup == 1) {
      // Zoom 16-18: Valve Name + Status / %
      canvas.drawCircle(const Offset(10, 10), 3.5, Paint()..color = accent);
      drawText(name, 18, 3, 10, Colors.white, maxWidth: w - 24, bold: true);
      drawText(
        '${st == 1 ? "ON" : "OFF"} • $per%',
        18,
        18,
        9.5,
        accent,
        maxWidth: w - 24,
      );
    } else {
      // Zoom > 18: Valve Name + ON/OFF status + percentage + thin progress bar
      drawText(name, 8, 4, 10.5, Colors.white, maxWidth: w - 16, bold: true);
      canvas.drawCircle(const Offset(12, 23), 3.5, Paint()..color = accent);
      drawText(
        '${st == 1 ? "ON" : "OFF"} • $per%',
        20,
        17,
        9.5,
        accent,
        maxWidth: w - 26,
      );

      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(8, 35, w - 16, 4),
        const Radius.circular(2),
      );
      canvas.drawRRect(barRect, Paint()..color = Colors.white24);

      if (per > 0) {
        final fillWidth = ((w - 16) * per / 100.0).clamp(2.0, w - 16);
        final fillRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(8, 35, fillWidth, 4),
          const Radius.circular(2),
        );
        canvas.drawRRect(fillRect, Paint()..color = accent);
      }
    }

    final picture = recorder.endRecording();
    final image =
        await picture.toImage((w * scale).ceil(), (h * scale).ceil());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();

    final bitmap = BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: w,
      height: h,
    );

    if (_bitmapCache.length >= 200) _bitmapCache.clear();
    _bitmapCache[cacheKey] = bitmap;
    return bitmap;
  }

  // ---------------- CREATE CUSTOM CANVAS MARKER ICON ----------------
  Future<BitmapDescriptor> _createSymbolMarker({
    required Color color,
    required String symbol, // 'play', 'stop', 'pause', 'check'
    double size = 30.0,
    double pixelRatio = 2.0,
  }) async {
    final cacheKey =
        'sym_${symbol}_${color.toARGB32()}_${pixelRatio.toStringAsFixed(1)}';
    if (_bitmapCache.containsKey(cacheKey)) {
      return _bitmapCache[cacheKey]!;
    }

    final scale = pixelRatio.clamp(1.0, 3.0);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(scale);

    const bg = Color(0xF00F172A);
    final radius = size / 2;

    canvas.drawCircle(Offset(radius, radius), radius - 1, Paint()..color = bg);
    canvas.drawCircle(
      Offset(radius, radius),
      radius - 1,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    final iconPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    if (symbol == 'play') {
      final path = Path()
        ..moveTo(radius - 3, radius - 5)
        ..lineTo(radius + 5, radius)
        ..lineTo(radius - 3, radius + 5)
        ..close();
      canvas.drawPath(path, iconPaint);
    } else if (symbol == 'pause') {
      canvas.drawRect(
        Rect.fromLTWH(radius - 4, radius - 4, 3, 8),
        iconPaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(radius + 1, radius - 4, 3, 8),
        iconPaint,
      );
    } else if (symbol == 'check') {
      final path = Path()
        ..moveTo(radius - 5, radius)
        ..lineTo(radius - 1, radius + 4)
        ..lineTo(radius + 5, radius - 4);
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
    } else {
      canvas.drawRect(
        Rect.fromLTWH(radius - 4, radius - 4, 8, 8),
        iconPaint,
      );
    }

    final picture = recorder.endRecording();
    final image =
        await picture.toImage((size * scale).ceil(), (size * scale).ceil());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();

    final bitmap = BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: size,
      height: size,
    );

    _bitmapCache[cacheKey] = bitmap;
    return bitmap;
  }

  // ---------------- CREATE MARKER ----------------
  Future<Marker> _createMarker({
    required String id,
    required double lat,
    required double lng,
    required String title,
    required String type,
    int? status,
    int? percentage,
  }) async {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    int st = status ?? 0;
    int per = (percentage ?? 0).clamp(0, 100);
    final accent = _getAreaColor(st, per);

    BitmapDescriptor icon;
    if (type.toLowerCase().contains("valve")) {
      String symbol = per >= 100
          ? 'check'
          : st == 1
              ? 'play'
              : per > 0
                  ? 'pause'
                  : 'stop';
      icon = await _createSymbolMarker(
        color: accent,
        symbol: symbol,
        pixelRatio: pixelRatio,
      );
    } else {
      icon = _getIcon(type, status, percentage);
    }

    return Marker(
      markerId: MarkerId(id),
      position: LatLng(lat, lng),
      icon: icon,
      infoWindow: InfoWindow(
        title: title,
        snippet: "${st == 1 ? 'ON' : 'OFF'} • Irrigation: $per%",
      ),
    );
  }

  Map<String, int> getStatusPercentage(
      double serialNumber, Map<String, dynamic>? liveMessage) {
    try {
      if (liveMessage == null || liveMessage["cM"] == null) {
        return {"status": 0, "percentage": 0};
      }

      final dynamic cMData = liveMessage["cM"];
      if (cMData is! Map) return {"status": 0, "percentage": 0};

      final String? data = cMData["2402"]?.toString();
      if (data == null || data.isEmpty) {
        return {"status": 0, "percentage": 0};
      }

      final List<String> values = data.split(";");

      for (var value in values) {
        final List<String> parts = value.split(",");
        if (parts.length >= 3) {
          double? partId = double.tryParse(parts[0]);
          if (partId != null && partId == serialNumber) {
            return {
              "status": int.tryParse(parts[1]) ?? 0,
              "percentage": int.tryParse(parts[2]) ?? 0,
            };
          }
        }
      }

      return {"status": 0, "percentage": 0};
    } catch (e) {
      return {"status": 0, "percentage": 0};
    }
  }

  LatLng? _getInitialCenter(List deviceList) {
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

    for (var device in deviceList) {
      for (var obj in device["connectedObject"] ?? []) {
        if (obj["lat"] != null && obj["long"] != null) {
          return LatLng(obj["lat"], obj["long"]);
        }
      }
    }

    for (var device in deviceList) {
      final geo = device["geography"];
      if (geo != null && geo["lat"] != null && geo["long"] != null) {
        return LatLng(geo["lat"], geo["long"]);
      }
    }

    return null;
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

  BitmapDescriptor _getIcon(String type, int? status, int? percentage) {
    int st = status ?? 0;
    int per = percentage ?? 0;

    if (type.toLowerCase().contains('valve')) {
      final key = per >= 100
          ? 'blue'
          : st == 1
              ? 'green'
              : per > 0
                  ? 'yellow'
                  : 'gray';
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

  // ---------------- DYNAMIC VALVE DETAILS INSPECTOR PANEL ----------------
  Widget _buildValveDetailsPanel(_SelectedValveData data) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = _getAreaColor(data.status, data.percentage);
    final isRunning = data.status == 1;
    final irrigatedAcres = data.acres * data.percentage / 100.0;
    final remainingAcres = math.max(0.0, data.acres - irrigatedAcres);

    String statusTitle = data.percentage >= 100
        ? 'Irrigation Completed'
        : isRunning
            ? 'Irrigating Now'
            : data.percentage > 0
                ? 'Partially Irrigated'
                : 'Inactive / Pending';

    return Material(
      color: colorScheme.surface,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Top Navigation & Close Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: _clearSelection,
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text(
                  'Field Overview',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              IconButton(
                onPressed: _clearSelection,
                icon: Icon(Icons.close_rounded,
                    color: colorScheme.onSurfaceVariant),
                tooltip: 'Close Details',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Valve Title Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        data.valveName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (data.deviceId.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Device ID: ${data.deviceId}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Status & Progress Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      statusTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isRunning ? 'ON' : 'OFF',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.surface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'Irrigation Progress',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${data.percentage}%',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: data.percentage / 100.0,
                    minHeight: 8,
                    color: accent,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Field Area Metrics Section
          Text(
            'Field Metrics',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                _panelDetailRow('Total Field Area',
                    '${data.acres.toStringAsFixed(2)} ac', colorScheme),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),
                _panelDetailRow('Irrigated Area',
                    '${irrigatedAcres.toStringAsFixed(2)} ac', colorScheme),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),
                _panelDetailRow('Remaining Area',
                    '${remainingAcres.toStringAsFixed(2)} ac', colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _panelDetailRow(
      String label, String value, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  // ---------------- CAMERA IDLE & ZOOM HANDLER ----------------
  void _onCameraIdle() async {
    if (mapController == null) return;
    try {
      final newZoomGroup = _getZoomGroup(_currentZoom);

      if (newZoomGroup != _lastZoomGroup) {
        _lastZoomGroup = newZoomGroup;
        await _buildMapElements();
      }
    } catch (e) {
      debugPrint("Camera idle zoom check error: $e");
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (!_hasInitialBoundsFit && (markers.isNotEmpty || polygons.isNotEmpty)) {
      _fitMapToBounds(markers, polygons);
    }
  }

  // ---------------- AREA SUMMARY & MAP HEADER ----------------
  Widget _buildAreaSummary() {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final total = _valveAreas.fold<double>(0, (sum, e) => sum + e.acres);
    final irrigated =
        _valveAreas.fold<double>(0, (sum, e) => sum + e.irrigatedAcres);
    final running = _valveAreas.fold<double>(
        0, (sum, e) => sum + (e.running ? e.remainingAcres : 0.0));
    final pending = _valveAreas.fold<double>(
        0, (sum, e) => sum + (!e.running ? e.remainingAcres : 0.0));

    return Material(
      color: c.surface,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text('Total field area', style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),
          Text(
            '${total.toStringAsFixed(2)} ac',
            style: theme.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 10,
              child: LayoutBuilder(builder: (context, constraints) {
                final width = constraints.maxWidth;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: total > 0 ? width * irrigated / total : 0.0,
                      child: const ColoredBox(color: _completedColor),
                    ),
                    SizedBox(
                      width: total > 0
                          ? math.min(
                              width * running / total,
                              math.max(0.0, width - width * irrigated / total),
                            )
                          : 0.0,
                      child: const ColoredBox(color: _runningColor),
                    ),
                    Expanded(
                      child: ColoredBox(color: c.surfaceContainerHighest),
                    ),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _areaMetric('Irrigated', irrigated, _completedColor),
              ),
              Expanded(
                child: _areaMetric('Irrigating', running, _runningColor),
              ),
              Expanded(
                child: _areaMetric('Pending', pending, c.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Estimated area based on irrigation progress',
            style: theme.textTheme.bodySmall,
          ),
          const Divider(height: 24),
          Text('Valve areas', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          if (_valveAreas.isEmpty)
            const Center(child: Text('No valve areas')),
          ..._valveAreas.map((e) {
            final color = e.color;
            final status = e.percentage == 100
                ? 'Completed'
                : e.running
                    ? 'Irrigating'
                    : e.percentage > 0
                        ? 'Partially irrigated'
                        : 'Not irrigated';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: c.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border(left: BorderSide(color: color, width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.water_drop_outlined, color: color, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(e.name, style: theme.textTheme.titleSmall),
                      ),
                      Text(
                        '${e.acres.toStringAsFixed(2)} ac',
                        style: theme.textTheme.labelLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(status, style: theme.textTheme.bodySmall),
                      ),
                      Text(
                        '${e.percentage}%',
                        style: theme.textTheme.labelLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: e.percentage / 100.0,
                      minHeight: 6,
                      color: color,
                      backgroundColor: c.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Irrigated: ${e.irrigatedAcres.toStringAsFixed(2)} ac',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    '${e.running ? 'Irrigating' : 'Pending'}: ${e.remainingAcres.toStringAsFixed(2)} ac',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _areaMetric(String label, double value, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(
            '${value.toStringAsFixed(2)} ac',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      );

  void _openMapEditor() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => MapConnectionObject(
        userId: widget.userId,
        customerId: widget.customerId,
        controllerId: widget.controllerId,
        imeiNo: widget.imeiNo,
        modelId: widget.modelId,
      ),
    ));
  }

  Widget _mapHeader() {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Geography',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text('Farm monitoring', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Live Sync',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: _runningColor),
                  ),
                  Text(
                    _sentTime.isEmpty ? '--' : _sentTime,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (kIsWeb || widget.isCheckDashboard) ...[
              IconButton(
                tooltip: 'Refresh',
                onPressed: () async {
                  await _init(resetBounds: true);
                },
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: 'Edit',
                onPressed: _openMapEditor,
                icon: const Icon(Icons.map_outlined),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final panelContent = _selectedValveData != null
        ? _buildValveDetailsPanel(_selectedValveData!)
        : _buildAreaSummary();

    return Scaffold(
      appBar: (widget.isCheckDashboard || kIsWeb)
          ? null
          : AppBar(
              title: const Text("Geography"),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () async {
                    await _init(resetBounds: true);
                  },
                ),
                if (!widget.isCheckDashboard)
                  IconButton(
                    icon: const Icon(Icons.map_outlined),
                    onPressed: _openMapEditor,
                    tooltip: 'Edit',
                  ),
              ],
            ),
      body: Column(
        children: [
          _mapHeader(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 800;
                final map = ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: GoogleMap(
                    key: ValueKey("google_map_${widget.controllerId}"),
                    mapType: MapType.hybrid,
                    initialCameraPosition: _currentCameraPosition ??
                        CameraPosition(
                          target: center,
                          zoom: _currentZoom,
                        ),
                    markers: markers,
                    polygons: polygons,
                    polylines: statusBoundaries,
                    onMapCreated: _onMapCreated,
                    onCameraMove: (position) {
                      _currentCameraPosition = position;
                      _currentZoom = position.zoom;
                    },
                    onCameraIdle: _onCameraIdle,
                  ),
                );
                final panel = ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: panelContent,
                );
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: wide
                      ? Row(
                          children: [
                            Expanded(child: map),
                            const SizedBox(width: 8),
                            SizedBox(width: 320, child: panel),
                          ],
                        )
                      : Column(
                          children: [
                            Expanded(flex: 3, child: map),
                            const SizedBox(height: 8),
                            Expanded(flex: 2, child: panel),
                          ],
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _fitMapToBounds(Set<Marker> markers, Set<Polygon> polygons) {
    if (_hasInitialBoundsFit) return;
    if (mapController == null) return;
    if (markers.isEmpty && polygons.isEmpty) return;

    List<LatLng> allPoints = [];

    for (var m in markers) {
      allPoints.add(m.position);
    }

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

    final boundsCenter = LatLng(
      (minLat + maxLat) / 2,
      (minLng + maxLng) / 2,
    );

    _hasInitialBoundsFit = true;
    center = boundsCenter;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || mapController == null) return;

      try {
        await mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 80),
        );
        if (!mounted || mapController == null) return;
        final currentZoomLevel = await mapController!.getZoomLevel();
        _currentZoom = currentZoomLevel;
        _currentCameraPosition = CameraPosition(
          target: boundsCenter,
          zoom: currentZoomLevel,
        );
      } catch (e) {
        debugPrint("Map fit error: $e");
      }
    });
  }
}

class _SelectedValveData {
  final String polygonId;
  final String valveName;
  final int status;
  final int percentage;
  final double acres;
  final String deviceId;

  _SelectedValveData({
    required this.polygonId,
    required this.valveName,
    required this.status,
    required this.percentage,
    required this.acres,
    required this.deviceId,
  });
}

class _RawPolygonData {
  final double sNo;
  final String valveName;
  final int status;
  final int percentage;
  final double acres;
  final String deviceId;
  final List<LatLng> points;
  final Color color;

  _RawPolygonData({
    required this.sNo,
    required this.valveName,
    required this.status,
    required this.percentage,
    required this.acres,
    required this.deviceId,
    required this.points,
    required this.color,
  });
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
