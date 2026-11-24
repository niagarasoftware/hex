import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:hex/utils/helpers/log_print.dart';

import '../../../StateManagement/mqtt_payload_provider.dart';
import '../googlemap_model.dart';
import 'getlatlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key, required this.index}) : super(key: key);
  final int index;

  @override
  _MapScreenState createState() => _MapScreenState();
}


class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  Set<Marker> _markers = {};
  double _currentZoom = 15;
  bool _isAreaMode = false;
  late MqttPayloadProvider mqttPayloadProvider;
  ConnectedObject? _selectedObject;
  bool _isDrawerOpen = false;
  double _drawerWidth = 280;

  List<LatLng> _points = [];
  bool _isClosed = false;
  Set<Marker> _vertices = {};
  Set<Polyline> _lines = {};
  Set<Polygon> _fill = {};
  BitmapDescriptor? _dotIcon;

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    mqttPayloadProvider = Provider.of<MqttPayloadProvider>(context, listen: false);
    _createMarkerImage();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllMarkers();
    });
  }

  Future<void> _createMarkerImage() async {
    const double size = 10;

    final pictureRecorder = PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(Icons.circle.codePoint),
      style: TextStyle(
        fontSize: size,
        fontFamily: Icons.circle.fontFamily,
        color: Colors.white, // dot color
      ),
    );

    textPainter.layout();
    textPainter.paint(canvas, const Offset(0, 0));

    final image = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );

    final byteData = await image.toByteData(format: ImageByteFormat.png);

    _dotIcon = BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  /// Load all markers from device's connected objects
  void _loadAllMarkers() {
    final device =
    mqttPayloadProvider.mapModelInstance.data?.deviceList?[widget.index];

    final objects = device?.connectedObject;

    AppLog.log('Device index: ${widget.index}');
    AppLog.log('Device geography: ${device?.geography}');
    AppLog.log('Device geography lat: ${device?.geography?.lat}');
    AppLog.log('Device geography long: ${device?.geography?.long}');
    AppLog.log('Connected objects: ${objects?.length ?? 0}');

    if (!mounted || objects == null || objects.isEmpty) return;

    Set<Marker> newMarkers = {};

    for (var obj in objects) {
      if (obj.lat != null && obj.long != null) {
        newMarkers.add(
          Marker(
            markerId: MarkerId(obj.name ?? obj.objectName ?? 'object_${objects.indexOf(obj)}'),
            position: LatLng(obj.lat!, obj.long!),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              obj == _selectedObject
                  ? BitmapDescriptor.hueAzure
                  : obj.status == 1
                  ? BitmapDescriptor.hueGreen
                  : BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: obj.name ?? 'Connected Object',
              snippet:
              'Lat: ${obj.lat}, Long: ${obj.long}, Status: ${obj.status ?? "Unknown"}',
            ),
          ),
        );
      }
    }

    setState(() {
      _markers = newMarkers;
    });
  }

  /// Update only the selected marker's position
  void _updateMarker(double lat, double long) {
    if (_selectedObject == null) return;

    final position = LatLng(lat, long);

    setState(() {
      // Remove old marker of selected object
      _markers.removeWhere((marker) =>
      marker.markerId.value ==
          (_selectedObject!.name ?? _selectedObject!.objectName));

      // Add updated marker with info always visible
      _markers.add(
        Marker(
          markerId: MarkerId(
              _selectedObject!.name ?? _selectedObject!.objectName ?? 'selected'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: _selectedObject?.name ?? 'Connected Object',
            snippet:
            'Lat: ${_selectedObject?.lat}, Long: ${_selectedObject?.long}, Status: ON',
          ),
        ),
      );
    });

    AppLog.log('Lat: ${_selectedObject?.lat}, Long: ${_selectedObject?.long}');
    AppLog.log('Lat: ${lat}, Long: ${long}');
    AppLog.log('_selectedObject:${_selectedObject?.name} ${_selectedObject?.objectId}');
    _selectedObject!.lat = lat;
    _selectedObject!.long = long;
    _selectedObject!.status = 1;

    mqttPayloadProvider.notifyListeners();

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(position, _currentZoom),
    );
  }

  /// Search location and update marker
  void _searchLocation() async {
    final input = _searchController.text;
    final LatLng? result = await getLatLngFromInput(input);

    if (!mounted) return;
    if (result != null) {
      _updateMarker(result.latitude, result.longitude);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter valid area name, map link or lat,long"),
        ),
      );
    }
  }

  String extractCoordinates(String input) {
    final regExp = RegExp(r"@(-?\d+\.\d+),(-?\d+\.\d+)");
    final match = regExp.firstMatch(input);

    if (match != null) {
      return '${match.group(1)},${match.group(2)}';
    }

    var coords = input.split(",");
    if (coords.length == 2) {
      return '${coords[0].trim()},${coords[1].trim()}';
    }

    return "Invalid coordinates format.";
  }


  LatLng _getInitialCameraPosition() {
    // 1️⃣ If selected object has valid lat/long → use it
    if (_selectedObject != null &&
        _selectedObject!.lat != null &&
        _selectedObject!.long != null &&
        _selectedObject!.lat != 0 &&
        _selectedObject!.long != 0) {
      return LatLng(_selectedObject!.lat!, _selectedObject!.long!);
    }

    // 2️⃣ Otherwise use first valid object
    final device =
    mqttPayloadProvider.mapModelInstance.data?.deviceList?[widget.index];

    final objects = device?.connectedObject;

    if (objects != null && objects.isNotEmpty) {
      for (var obj in objects) {
        if (obj.lat != null &&
            obj.long != null &&
            obj.lat != 0 &&
            obj.long != 0) {
          return LatLng(obj.lat!, obj.long!);
        }
      }
    }

    // 3️⃣ Final fallback (safe location)
    return const LatLng(11.1271, 78.6569);
  }


  Future<void> _checkLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    if (status == PermissionStatus.granted) {
      setState(() {});
    }
  }

  void _refreshLayers() {
    setState(() {
      _vertices.clear();
      _lines.clear();
      _fill.clear();

      // Step A: Create interactive, DRAGGABLE dots (Vertices)
      for (int i = 0; i < _points.length; i++) {
        bool isStartPoint = (i == 0);

        _vertices.add(
          Marker(
            markerId: MarkerId("vertex_$i"),
            position: _points[i],
            draggable: true, // 🚀 THE KEY OPTION
            anchor: const Offset(0.5, 0.5), // Center the dot on the point
            // Visual style: Start point is Yellow (if open), others are Azure/Asset
            icon: (isStartPoint && !_isClosed)
                ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow)
                : (_dotIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)),

            // Interaction: Closing the Loop
            onTap: () {
              // If tapping the start point, have 3+ points, and it's not closed, fill it!
              if (isStartPoint && _points.length >= 3 && !_isClosed) {
                setState(() => _isClosed = true);
                _refreshLayers();
              }
            },

            // Interaction: DRAGGING
            onDragEnd: (newPos) {
              // 🚀 Update the master point list with the new position
              setState(() {
                _points[i] = newPos;
                _syncArea();
                _refreshLayers();
              });
            },
          ),
        );
      }

      // Step B: Create the Lines (The Path)
      List<LatLng> linePath = List.from(_points);
      // Visually close the loop if the state is closed
      if (_isClosed && _points.isNotEmpty) {
        linePath.add(_points.first); // Join last point back to first
      }
      _lines.add(Polyline(
        polylineId: const PolylineId("path"),
        points: linePath,
        color: Colors.yellow,
        width: 3,
        jointType: JointType.round,
      ));

      if (_isClosed && _points.length >= 3) {
        _fill.add(Polygon(
          polygonId: const PolygonId("area_fill"),
          points: _points,
          strokeWidth: 0, // Border is handled by Polyline
          fillColor: Colors.blue.withOpacity(0.3),
        ));
      }
    });
  }

  void _handleMapTap(LatLng pos) {
    if (_isClosed || _selectedObject == null) return;
    _points.add(pos);
    _syncArea();
    _refreshLayers();


  }


  void _selectObject(ConnectedObject obj) {
    setState(() {
      _selectedObject = obj;
      _points = (obj.area ?? [])
          .where((p) => p.latitude != null && p.longitude != null)
          .map((p) => LatLng(p.latitude!, p.longitude!)).toList();
      _isClosed = _points.length >= 3;
    });
    _refreshLayers();
    _loadAllMarkers();
    if (obj.lat != null && obj.long != null) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(
          LatLng(obj.lat!, obj.long!), _currentZoom));
    } else if (_points.isNotEmpty) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(
          _points.first, _currentZoom));
    }
  }

  void _syncArea() {
    if (_selectedObject == null) return;
    _selectedObject!.area = _points.map((p) =>
        Area(latitude: p.latitude, longitude: p.longitude)).toList();
    mqttPayloadProvider.notifyListeners();
  }

  bool _mapped(ConnectedObject obj) =>
      obj.lat != null && obj.long != null &&
          (obj.lat != 0 || obj.long != 0);

  Widget _panel({required Widget child}) {
    final c = Theme.of(context).colorScheme;
    return Container(
        decoration: BoxDecoration(color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.outlineVariant)),
        clipBehavior: Clip.antiAlias, child: child);
  }

  Widget _modeSwitch() {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(value: false, icon: Icon(Icons.location_on_outlined),
            label: Text('Marker')),
        ButtonSegment(value: true, icon: Icon(Icons.polyline),
            label: Text('Area')),
      ],
      selected: {_isAreaMode},
      onSelectionChanged: (v) => setState(() => _isAreaMode = v.first),
    );
  }

  Widget _objectList(List<ConnectedObject> objects) {
    final c = Theme.of(context).colorScheme;
    final count = objects.where(_mapped).length;
    return _panel(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.all(16), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Connected objects', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('$count of ${objects.length} locations configured'),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: objects.isEmpty ? 0.0 : count / objects.length),
          ])),
          const Divider(height: 1),
          Expanded(child: objects.isEmpty ? const Center(child: Text('No connected objects'))
              : ListView.builder(padding: const EdgeInsets.all(10),
              itemCount: objects.length, itemBuilder: (context, i) {
                final obj = objects[i];
                final selected = obj == _selectedObject;
                return Padding(padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: selected ? c.primaryContainer : c.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      child: ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        leading: Icon(_mapped(obj) ? Icons.location_on : Icons.location_off_outlined),
                        title: Text(obj.name ?? obj.objectName ?? 'Object'),
                        subtitle: Text(_mapped(obj) ? 'Location configured' : 'Not mapped'),
                        trailing: selected ? Icon(Icons.check_circle, color: c.primary) : null,
                        onTap: () => _selectObject(obj),
                      ),
                    ));
              })),
        ]));
  }

  Widget _selectedDetails() {
    final obj = _selectedObject;
    return _panel(child: Padding(padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, children: [
              Text(obj?.name ?? obj?.objectName ?? 'Select an object',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              if (obj != null) Wrap(spacing: 20, runSpacing: 6, children: [
                Text('Lat: ${obj.lat?.toStringAsFixed(6) ?? "-"}'),
                Text('Long: ${obj.long?.toStringAsFixed(6) ?? "-"}'),
                Text('Status: ${obj.status == 1 ? "ON" : "OFF"}'),
                if (_isAreaMode) Text('${_points.length} points · ${_isClosed ? "Closed" : "Open"}'),
              ]),
              const SizedBox(height: 4),
              Text(obj == null ? 'Choose equipment before editing.'
                  : _isAreaMode ? 'Tap map to add points. Drag points to adjust.'
                  : 'Tap map to relocate the selected object.'),
            ])));
  }

  Widget _mapWorkspace() {
    return Column(children: [
      Row(children: [
        Expanded(child: TextField(controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _searchLocation(),
            decoration: InputDecoration(
                hintText: 'Place, map link or coordinates',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true))),
        const SizedBox(width: 8),
        IconButton.filledTonal(onPressed: _selectedObject == null ? null : _searchLocation,
            tooltip: 'Search', icon: const Icon(Icons.search)),
        IconButton.filledTonal(onPressed: _selectedObject == null ? null : _getCurrentLocation,
            tooltip: 'Current location', icon: const Icon(Icons.my_location)),
      ]),
      const SizedBox(height: 8),
      if (_isAreaMode) Wrap(spacing: 8, children: [
        TextButton.icon(onPressed: _selectedObject == null || _points.isEmpty ? null : () {
          _points.removeLast();
          if (_points.length < 3) _isClosed = false;
          _syncArea(); _refreshLayers();
        }, icon: const Icon(Icons.undo), label: const Text('Undo point')),
        TextButton.icon(onPressed: _points.length < 3 || _isClosed ? null : () {
          _isClosed = true; _syncArea(); _refreshLayers();
        }, icon: const Icon(Icons.check), label: const Text('Close')),
        TextButton.icon(onPressed: !_isClosed ? null : () {
          _isClosed = false; _refreshLayers();
        }, icon: const Icon(Icons.edit), label: const Text('Reopen')),
      ]),
      Expanded(child: _panel(child: GoogleMap(
        mapType: MapType.hybrid,
        onMapCreated: _onMapCreated,
        onCameraMove: (p) => _currentZoom = p.zoom,
        initialCameraPosition: CameraPosition(target: _getInitialCameraPosition(), zoom: _currentZoom),
        markers: {..._markers, ..._vertices},
        polylines: _lines, polygons: _fill,
        onTap: (p) {
          if (_selectedObject == null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select an object first')));
            return;
          }
          if (_isAreaMode) { _handleMapTap(p); } else { _updateMarker(p.latitude, p.longitude); }
        },
        myLocationButtonEnabled: false, compassEnabled: true,
      ))),
      const SizedBox(height: 8),
      _selectedDetails(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final devices = mqttPayloadProvider.mapModelInstance.data?.deviceList;
    final List<ConnectedObject> objects = devices != null &&
        widget.index >= 0 && widget.index < devices.length
        ? (devices[widget.index].connectedObject ?? []) : [];
    return Scaffold(
      appBar: AppBar(title: const Text('Object Mapping')),
      body: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 850;
        return Padding(padding: const EdgeInsets.all(12), child: Column(children: [
          Align(alignment: Alignment.centerRight, child: _modeSwitch()),
          const SizedBox(height: 12),
          if (!wide) ...[
            DropdownButtonFormField<ConnectedObject>(
              isExpanded: true,
              value: objects.contains(_selectedObject) ? _selectedObject : null,
              decoration: const InputDecoration(labelText: 'Connected object', border: OutlineInputBorder()),
              items: objects.map((o) => DropdownMenuItem(value: o,
                  child: Text(o.name ?? o.objectName ?? 'Object', overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (o) { if (o != null) _selectObject(o); },
            ),
            const SizedBox(height: 10),
          ],
          Expanded(child: wide ? Row(children: [
            SizedBox(width: 280, child: _objectList(objects)),
            const SizedBox(width: 12),
            Expanded(child: _mapWorkspace()),
          ]) : _mapWorkspace()),
        ]));
      })),
    );
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check GPS
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enable Location Services')),
      );
      return;
    }

    // Check Permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (!mounted) return;
    if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
      return;
    }

    // Get Position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // ✅ Add marker
    if (!mounted) return;
    if (_isAreaMode) {
      _handleMapTap(LatLng(position.latitude, position.longitude));
    } else {
      _updateMarker(position.latitude, position.longitude);
    }
  }

}