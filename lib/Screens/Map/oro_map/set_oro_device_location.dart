import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../StateManagement/mqtt_payload_provider.dart';
import '../../../modules/config_maker/view/device_list.dart' hide DeviceList;
import '../MapAreaModel.dart' hide Area;
import '../googlemap_model.dart';
import 'getlatlong.dart';



class SetSelectOroDeviceLocation extends StatefulWidget {
  const SetSelectOroDeviceLocation({Key? key}) : super(key: key);

  @override
  _SetSelectOroDeviceLocationState createState() => _SetSelectOroDeviceLocationState();
}


class _SetSelectOroDeviceLocationState extends State<SetSelectOroDeviceLocation> {

  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  Set<Marker> _markers = {};
  LatLng? _selectedPosition;
  DeviceList? _selectedDevice;
  int _selectedDeviceIndex = 0;
  double _currentZoom = 15;


  late MqttPayloadProvider mqttPayloadProvider;

  bool _searching = false;

  @override
  void initState() {
    super.initState();
    mqttPayloadProvider = Provider.of<MqttPayloadProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initializeSelectedDevice();
      _addAllDeviceMarkers();
    });
  }

  void _initializeSelectedDevice() {
    final devices = mqttPayloadProvider.mapModelInstance.data?.deviceList ?? [];
    if (devices.isNotEmpty) {
      _selectedDevice = devices.first;
      // Select first device with valid lat/long
      for (int i = 0; i < devices.length; i++) {
        final dev = devices[i];
        if (dev.geography?.lat != null && dev.geography?.long != null) {
          _selectedDevice = dev;
          _selectedDeviceIndex = i;
          _selectedPosition = LatLng(dev.geography!.lat!, dev.geography!.long!);
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(_selectedPosition!, 12),
          );
          break;
        }
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_selectedPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedPosition!, 12),
      );
    }
  }

  void _addAllDeviceMarkers() {
    final devices = mqttPayloadProvider.mapModelInstance.data?.deviceList ?? [];
    Set<Marker> markers = {};

    for (var device in devices) {
      if (device.geography?.lat != null && device.geography?.long != null) {
        final position = LatLng(device.geography!.lat!, device.geography!.long!);
        final isSelected = device.deviceId == _selectedDevice?.deviceId;

        markers.add(
          Marker(
            markerId: MarkerId(device.deviceId ?? device.controllerId.toString()),
            position: position,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              isSelected
                  ? BitmapDescriptor.hueAzure
                  : device.geography!.status == 1
                  ? BitmapDescriptor.hueGreen
                  : BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: device.deviceName ?? 'Device',
              snippet: 'Lat: ${device.geography!.lat}, Long: ${device.geography!.long}',
              onTap: () {
                setState(() {
                  _selectedDevice = device;
                  _selectedPosition = position;
                  _selectedDeviceIndex = devices.indexOf(device);
                });
                _addAllDeviceMarkers();
                _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, _currentZoom));
              },
            ),
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  void _updateMarker(double lat, double long) {
    final deviceList = mqttPayloadProvider.mapModelInstance.data?.deviceList;
    if (deviceList == null || _selectedDeviceIndex < 0 || _selectedDeviceIndex >= deviceList.length) return;

    final position = LatLng(lat, long);

    setState(() {
      deviceList[_selectedDeviceIndex].geography ??= Geography();
      deviceList[_selectedDeviceIndex].geography!.lat = lat;
      deviceList[_selectedDeviceIndex].geography!.long = long;

      _selectedDevice = deviceList[_selectedDeviceIndex];
      _selectedPosition = position;
    });

    mqttPayloadProvider.notifyListeners();
    _addAllDeviceMarkers();
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, _currentZoom));
  }

  Future<void> _searchLocation() async {
    if (_searching || _selectedDevice == null) return;
    final input = _searchController.text.trim();
    if (input.isEmpty) return;
    final index = _selectedDeviceIndex;
    setState(() => _searching = true);
    try {
      final result = await getLatLngFromInput(input);
      if (!mounted || index != _selectedDeviceIndex) return;
      if (result != null) {
        _updateMarker(result.latitude, result.longitude);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enter valid area name, map link or lat,long'),
        ));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to find location')));
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  LatLng _getInitialCameraPosition() {
    if (_selectedDevice?.geography?.lat != null && _selectedDevice?.geography?.long != null) {
      return LatLng(_selectedDevice!.geography!.lat!, _selectedDevice!.geography!.long!);
    }

    final devices = mqttPayloadProvider.mapModelInstance.data?.deviceList ?? [];
    for (var dev in devices) {
      if (dev.geography?.lat != null && dev.geography?.long != null) {
        return LatLng(dev.geography!.lat!, dev.geography!.long!);
      }
    }

    // fallback
    return const LatLng(11.5937, 78.9629);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _selectDevice(int index) {
    final devices = mqttPayloadProvider.mapModelInstance.data?.deviceList ?? [];
    if (index < 0 || index >= devices.length) return;
    final device = devices[index];
    final geo = device.geography;
    final position = geo?.lat != null && geo?.long != null
        ? LatLng(geo!.lat!, geo.long!) : null;
    setState(() {
      _selectedDevice = device;
      _selectedDeviceIndex = index;
      _selectedPosition = position;
    });
    _addAllDeviceMarkers();
    if (position != null) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, _currentZoom));
    }
  }

  Widget _devicePanel(List<DeviceList> devices) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Select device', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Choose a device to locate', style: theme.textTheme.bodySmall),
      ],
      )),
      Expanded(child: devices.isEmpty ? const Center(child: Text('No devices')) : ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: devices.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final d = devices[index];
          final selected = _selectedDevice != null && index == _selectedDeviceIndex;
          final mapped = d.geography?.lat != null && d.geography?.long != null;
          return Material(
            color: selected ? cs.primaryContainer : cs.surfaceContainerLow,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: selected ? cs.primary : cs.outlineVariant)),
            child: ListTile(
              leading: Icon(Icons.location_on_outlined, color: selected ? cs.onPrimaryContainer : cs.primary),
              title: Text(d.deviceName ?? 'Device', maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${mapped ? 'Location configured' : 'Not mapped'}\nStatus: ${d.geography?.status ?? 'Unknown'}'),
              trailing: selected ? Icon(Icons.check_circle, color: cs.primary) : null,
              onTap: () => _selectDevice(index),
            ),
          );
        },
      )),
      Padding(padding: const EdgeInsets.all(16), child: Text('1. Select a device\n2. Search or tap on the map\n3. Review the coordinates', style: theme.textTheme.bodySmall)),
    ]);
  }

  Widget _searchBar() => Padding(
    padding: const EdgeInsets.all(12),
    child: Row(children: [
      Expanded(child: TextField(
        controller: _searchController,
        enabled: _selectedDevice != null && !_searching,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _searchLocation(),
        decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'Place, map link or lat,long', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), isDense: true),
      )),
      const SizedBox(width: 8),
      FilledButton(onPressed: _searching || _selectedDevice == null ? null : _searchLocation,
          child: _searching ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Search')),
    ]),
  );

  Widget _coordinates() {
    final theme = Theme.of(context);
    final pos = _selectedPosition;
    return Padding(padding: const EdgeInsets.all(12), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text('Selected device', style: theme.textTheme.labelMedium),
      Text(_selectedDevice?.deviceName ?? 'No device selected', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: Text('Latitude\n${pos?.latitude.toStringAsFixed(6) ?? "—"}')),
        Expanded(child: Text('Longitude\n${pos?.longitude.toStringAsFixed(6) ?? "—"}')),
        IconButton(tooltip: 'Locate device', onPressed: pos == null ? null : () => _mapController?.animateCamera(CameraUpdate.newLatLngZoom(pos, _currentZoom)), icon: const Icon(Icons.my_location)),
      ]),
    ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final devices = mqttPayloadProvider.mapModelInstance.data?.deviceList ?? [];
    final mapped = devices.where((d) => d.geography?.lat != null && d.geography?.long != null).length;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Device Locations'), actions: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Center(child: Text('$mapped / ${devices.length} mapped'))),
      ]),
      body: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        return Row(children: [
          if (wide) SizedBox(width: 280, child: _devicePanel(devices)),
          if (wide) const VerticalDivider(width: 1),
          Expanded(child: Column(children: [
            if (!wide) Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 0), child: DropdownButtonFormField<int>(
              value: _selectedDevice != null && _selectedDeviceIndex < devices.length ? _selectedDeviceIndex : null,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Select device', border: OutlineInputBorder()),
              items: List.generate(devices.length, (i) => DropdownMenuItem(value: i, child: Text(devices[i].deviceName ?? 'Device', overflow: TextOverflow.ellipsis))),
              onChanged: (i) { if (i != null) _selectDevice(i); },
            )),
            _searchBar(),
            Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: GoogleMap(
              mapType: MapType.hybrid,
              onMapCreated: _onMapCreated,
              onCameraMove: (position) => _currentZoom = position.zoom,
              initialCameraPosition: CameraPosition(target: _getInitialCameraPosition(), zoom: _currentZoom),
              markers: _markers,
              onTap: (position) { if (_selectedDevice != null) _updateMarker(position.latitude, position.longitude); },
            )))),
            Container(color: cs.surface, child: _coordinates()),
          ])),
        ]);
      })),
    );
  }
}
