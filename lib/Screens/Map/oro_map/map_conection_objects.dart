import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hex/Screens/Map/oro_map/set_oro_device_location.dart';
import 'package:provider/provider.dart';
import '../../../StateManagement/mqtt_payload_provider.dart';
import '../../../repository/repository.dart';
import '../../../services/http_service.dart';
import '../../../utils/snack_bar.dart';
import '../set_device_areator_location.dart';
import 'SetSelectAreatorLocation.dart';
import 'SetSelectValveOroLocation.dart';
import 'package:hex/utils/helpers/log_print.dart';
import 'map_oro.dart';

class MapConnectionObject extends StatefulWidget {
  const MapConnectionObject({super.key, required this.userId,
    required this.customerId, required this.controllerId,
    required this.imeiNo, required this.modelId});
  final int userId, customerId, controllerId, modelId;
  final String imeiNo;
  @override
  State<MapConnectionObject> createState() => _MapConnectionObjectState();
}

class _MapConnectionObjectState extends State<MapConnectionObject> {
  bool _isSaving = false;
  bool _isLoading = true;
  bool _loadFailed = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) fetchData();
    });
  }

  Future<void> fetchData() async {
    if (!mounted) return;
    final provider = context.read<MqttPayloadProvider>();
    setState(() { _isLoading = true; _loadFailed = false; });
    try {
      final response = await Repository(HttpService()).getgeography({
        'userId': widget.customerId, 'controllerId': widget.controllerId,
      });
      if (!mounted) return;
      if (response.statusCode == 200) {
        AppLog.log(response.body);
        provider.updateMapData(jsonDecode(response.body));
      } else {
        setState(() => _loadFailed = true);
      }
    } catch (e) {
      if (!mounted) return;
      provider.httpError = true;
      setState(() => _loadFailed = true);
      debugPrint('Error Fetching Data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> updateMapLocation() async {
    if (_isSaving || _isLoading || _loadFailed) return;
    final provider = context.read<MqttPayloadProvider>();
    final data = provider.mapModelInstance.data?.toJson();
    if (data == null) return;
    setState(() => _isSaving = true);
    try {
      final response = await Repository(HttpService()).creategeography({
        'userId': widget.customerId,
        'controllerId': widget.controllerId,
        'userGeography': data['deviceList'],
        'createUser': widget.userId,
      });
      final jsonRes = jsonDecode(response.body);
      final ok = response.statusCode >= 200 && response.statusCode < 300;
      if (mounted) GlobalSnackBar.show(context,
          jsonRes['message']?.toString() ?? (ok ? 'Success' : 'Update failed'),
          ok ? 200 : 400);
    } catch (e) {
      if (mounted) GlobalSnackBar.show(context, 'Update failed', 400);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool _mapped(dynamic lat, dynamic lng) {
    final a = double.tryParse('$lat');
    final b = double.tryParse('$lng');
    return a != null && b != null && a.isFinite && b.isFinite &&
        a.abs() <= 90 && b.abs() <= 180 && (a != 0 || b != 0);
  }

  Future<void> _openEditor([int? index]) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) {
      if (index == null) {
        return widget.modelId == 72 ? MapScreendevice() : SetSelectOroDeviceLocation();
      }
      return widget.modelId == 72 ? MapScreen(index: index) : SetSelectOroLocation(index: index);
    }));
    // Keep local provider edits until Save changes is pressed.
    if (mounted) setState(() {});
  }

  Widget _metric(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: c.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14), border: Border.all(color: c.outlineVariant)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: c.primary, size: 21), const SizedBox(height: 10),
        Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4), Text(label, style: theme.textTheme.bodySmall),
      ]),
    );
  }

  Widget _deviceTile({required String name, required String id,
    required String category, required int count, required dynamic lat,
    required dynamic lng, required int index}) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final mapped = _mapped(lat, lng);
    final statusColor = mapped ? c.primary : c.tertiary;
    return Material(
      color: c.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: c.outlineVariant)), clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: _isSaving || _isLoading ? null : () => _openEditor(index),
        child: Padding(padding: const EdgeInsets.all(16), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 46, height: 46, decoration: BoxDecoration(
                color: c.primaryContainer, borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.memory_outlined, color: c.onPrimaryContainer)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              Text('ID: $id • $category', style: theme.textTheme.bodySmall),
            ])),
            const SizedBox(width: 8),
            Tooltip(message: mapped ? 'Mapped' : 'Not mapped', child: Icon(
                mapped ? Icons.check_circle_outline : Icons.location_off_outlined, color: statusColor)),
          ]),
          const SizedBox(height: 12), const Divider(),
          Row(children: [Icon(Icons.location_on_outlined, size: 19, color: c.onSurfaceVariant),
            const SizedBox(width: 8), Expanded(child: Text(mapped ? '$lat, $lng' : 'Location not configured',
                style: theme.textTheme.bodyMedium)),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text(mapped ? 'Mapped' : 'Not mapped', style: TextStyle(color: statusColor, fontWeight: FontWeight.w600)),
            Text('$count connected objects', style: theme.textTheme.bodySmall),
          ]),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerRight, child: TextButton.icon(
              onPressed: _isSaving || _isLoading ? null : () => _openEditor(index),
              icon: const Icon(Icons.arrow_forward, size: 17), label: const Text('Configure'))),
        ],
        )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    return Consumer<MqttPayloadProvider>(builder: (context, provider, _) {
      final devices = provider.mapModelInstance.data?.deviceList ?? [];
      final objects = devices.fold<int>(0, (sum, d) => sum + (d.connectedObject?.length ?? 0));
      final mapped = devices.where((d) => _mapped(d.geography?.lat, d.geography?.long)).length;
      final disabled = _isSaving || _isLoading || _loadFailed;
      return Scaffold(
        appBar: AppBar(title: const Text('Device Mapping'), actions: [
          IconButton(tooltip: 'Refresh', onPressed: disabled && !_loadFailed ? null : (_isSaving || _isLoading ? null : fetchData), icon: const Icon(Icons.refresh)),
          IconButton(tooltip: 'Edit locations', onPressed: disabled ? null : () => _openEditor(), icon: const Icon(Icons.edit_location_alt_outlined)),
        ]),
        body: SafeArea(bottom: false, child: RefreshIndicator(
          onRefresh: () async { if (!_isSaving && !_isLoading) await fetchData(); },
          child: LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1050 ? 3 : constraints.maxWidth >= 700 ? 2 : 1;
            final width = (constraints.maxWidth - 32 - (columns - 1) * 12) / columns;
            return ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(16), children: [
              Text('Configure device locations', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6), Text('Manage devices and their connected objects.', style: theme.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
              const SizedBox(height: 20),
              if (_isLoading) const LinearProgressIndicator(),
              LayoutBuilder(builder: (context, box) {
                final n = box.maxWidth >= 360 ? 3 : 1;
                final w = (box.maxWidth - (n - 1) * 10) / n;
                return Wrap(spacing: 10, runSpacing: 10, children: [
                  SizedBox(width: w, child: _metric('Devices', '${devices.length}', Icons.memory)),
                  SizedBox(width: w, child: _metric('Connected objects', '$objects', Icons.hub_outlined)),
                  SizedBox(width: w, child: _metric('Mapped devices', '$mapped/${devices.length}', Icons.map_outlined)),
                ]);
              }),
              const SizedBox(height: 24),
              Row(children: [Expanded(child: Text('Device inventory', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700))),
                TextButton.icon(onPressed: disabled ? null : () => _openEditor(), icon: const Icon(Icons.edit_location_alt_outlined), label: const Text('Edit locations'))]),
              const SizedBox(height: 12),
              if (_loadFailed) Center(child: Column(children: [const Text('Unable to load devices.'), TextButton(onPressed: fetchData, child: const Text('Retry'))]))
              else if (devices.isEmpty && !_isLoading) const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No devices found.')))
              else Wrap(spacing: 12, runSpacing: 12, children: [
                  for (int i = 0; i < devices.length; i++) SizedBox(width: width, child: _deviceTile(
                      name: '${devices[i].deviceName}', id: '${devices[i].deviceId}', category: '${devices[i].categoryName}',
                      count: devices[i].connectedObject?.length ?? 0, lat: devices[i].geography?.lat,
                      lng: devices[i].geography?.long, index: i)),
                ]),
            ]);
          }),
        )),
        bottomNavigationBar: Material(color: c.surface, elevation: 3, child: SafeArea(top: false,
          child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            Expanded(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Geography configuration', style: theme.textTheme.titleSmall),
              Text('Save your device locations', style: theme.textTheme.bodySmall),
            ])), const SizedBox(width: 8),
            FilledButton.icon(onPressed: disabled || devices.isEmpty ? null : updateMapLocation,
                icon: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Saving...' : 'Save changes')),
          ])),
        )),
      );
    });
  }
}
