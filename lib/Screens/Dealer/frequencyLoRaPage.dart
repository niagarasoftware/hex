import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../StateManagement/mqtt_payload_provider.dart';
import '../../repository/repository.dart';
import '../../services/communication_service.dart';
import '../../services/http_service.dart';
import 'package:hex/utils/helpers/log_print.dart';

class FrequencyPage extends StatefulWidget {
  final int userId;
  final int controllerId;
  final String deviceId;
  final bool plusTrue;
  final String loraValue;
  final String loara1Version;
  final String loara2Version;

  const FrequencyPage({
    super.key,
    required this.userId,
    required this.controllerId,
    required this.deviceId,
    required this.plusTrue,
    required this.loraValue,
    required this.loara1Version,
    required this.loara2Version,
  });

  @override
  State<FrequencyPage> createState() => _FrequencyPageState();
}

class _FrequencyPageState extends State<FrequencyPage> {
  final frequency1Controller = TextEditingController();
  final frequency2Controller = TextEditingController();
  final sf1Controller = TextEditingController();
  final sf2Controller = TextEditingController();

  late final MqttPayloadProvider mqttPayloadProvider;

  String loRa1VersionState = '';
  String loRa2VersionState = '';

  bool _isLoading = false;
  bool _isSending = false;

  // A View request is waiting for a fresh MQTT response.
  final Set<int> _pendingViews = {};

  // Track the provider values present when View was requested.
  final Map<int, String> _viewBaselines = {};

  // Prevent unsolicited MQTT data from overwriting edited fields.
  bool _hasLocalEdits = false;
  bool _updatingControllers = false;

  Timer? _viewTimeout;

  @override
  void initState() {
    super.initState();

    mqttPayloadProvider = context.read<MqttPayloadProvider>();

    loRa1VersionState = widget.loara1Version;
    loRa2VersionState = widget.loara2Version;

    _setInitialValues(widget.loraValue);

    frequency1Controller.addListener(_onFieldEdited);
    frequency2Controller.addListener(_onFieldEdited);
    sf1Controller.addListener(_onFieldEdited);
    sf2Controller.addListener(_onFieldEdited);

    mqttPayloadProvider.addListener(_onMqttUpdated);
  }

  void _onFieldEdited() {
    if (!_updatingControllers) {
      _hasLocalEdits = true;
    }
  }

  void _setInitialValues(String value) {
    final parts = value.split(',');

    if (parts.length < 4) return;

    _setFrequencyFields(
      parts[0].trim(),
      parts[1].trim(),
      parts[2].trim(),
      parts[3].trim(),
    );
  }

  void _setFrequencyFields(
      String frequency1,
      String sf1,
      String frequency2,
      String sf2,
      ) {
    _updatingControllers = true;

    try {
      frequency1Controller.text = frequency1;
      sf1Controller.text = sf1;
      frequency2Controller.text = frequency2;
      sf2Controller.text = sf2;
    } finally {
      _updatingControllers = false;
    }
  }

  String _providerValue(int index) {
    return index == 1
        ? mqttPayloadProvider.Loara1verssion
        : mqttPayloadProvider.Loara2verssion;
  }

  void _onMqttUpdated() {
    if (!mounted || _pendingViews.isEmpty) return;

    for (final index in List<int>.from(_pendingViews)) {
      final value = _providerValue(index);

      if (value.isEmpty) continue;

      // Do not treat the previous provider value as a new response.
      if (value == _viewBaselines[index]) continue;

      final parts = value.split(',');

      if (parts.length < 3) continue;

      final version = parts[0].trim();
      final frequency = parts[1].trim();
      final sf = parts[2].trim();

      if (double.tryParse(frequency) == null ||
          int.tryParse(sf) == null) {
        continue;
      }

      _updatingControllers = true;

      try {
        setState(() {
          if (index == 1) {
            loRa1VersionState = version;
            frequency1Controller.text = frequency;
            sf1Controller.text = sf;
          } else {
            loRa2VersionState = version;
            frequency2Controller.text = frequency;
            sf2Controller.text = sf;
          }

          _pendingViews.remove(index);
          _viewBaselines.remove(index);
          _isLoading = _pendingViews.isNotEmpty;
          _hasLocalEdits = false;
        });
      } finally {
        _updatingControllers = false;
      }
    }

    if (_pendingViews.isEmpty) {
      _viewTimeout?.cancel();
    }
  }

  String formatNumber(String input) {
    final number = double.tryParse(input.trim());

    if (number == null) {
      throw const FormatException('Invalid frequency');
    }

    final result = (number * 10).round().toString().padLeft(4, '0');

    if (result.length != 4) {
      throw const FormatException('Frequency out of range');
    }

    return '${result.substring(0, 2)},${result.substring(2, 4)}';
  }

  bool _isValidFrequency(String value) {
    final frequency = double.tryParse(value.trim());

    return frequency != null &&
        frequency >= 0 &&
        frequency <= 999.9 &&
        RegExp(r'^\d{1,3}(\.\d)?$').hasMatch(value.trim());
  }

  bool _isValidSf(String value) {
    final sf = int.tryParse(value.trim());
    return sf != null && sf >= 7 && sf <= 12;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Invalid Input'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshFrequencyFromApi() async {
    try {
      final repository = Repository(HttpService());

      final response =
      await repository.getUserDeviceFirmwareDetails({
        'userId': widget.userId,
        'controllerId': widget.controllerId,
      });

      if (!mounted || response.statusCode != 200) return;

      final jsonData = jsonDecode(response.body);

      if (jsonData['code'] != 200 ||
          jsonData['data'] is! List) {
        return;
      }

      final devices = jsonData['data'] as List;

      for (final device in devices) {
        if (device['deviceId'].toString() != widget.deviceId) {
          continue;
        }

        final value = device['loraFrequency']?.toString() ?? '';
        final parts = value.split(',');

        if (parts.length >= 4 && mounted) {
          setState(() {
            _setFrequencyFields(
              parts[0].trim(),
              parts[1].trim(),
              parts[2].trim(),
              parts[3].trim(),
            );
            _hasLocalEdits = false;
          });
        }

        break;
      }
    } catch (e) {
      AppLog.log('Frequency API refresh error: $e');
    }
  }

  Future<void> _handleSend() async {
    if (_isSending) return;

    final freq1 = frequency1Controller.text.trim();
    final freq2 = frequency2Controller.text.trim();
    final sf1 = sf1Controller.text.trim();
    final sf2 = sf2Controller.text.trim();

    if (!_isValidFrequency(freq1) || !_isValidSf(sf1)) {
      _showErrorDialog(
        'Enter valid LoRa Frequency 1 and SF value (7-12).',
      );
      return;
    }

    if (widget.plusTrue &&
        (!_isValidFrequency(freq2) || !_isValidSf(sf2))) {
      _showErrorDialog(
        'Enter valid LoRa Frequency 2 and SF value (7-12).',
      );
      return;
    }

    final effectiveFreq2 = widget.plusTrue ? freq2 : '0.0';
    final effectiveSf2 = widget.plusTrue ? sf2 : '0';

    setState(() => _isSending = true);

    try {
      final payload = jsonEncode({
        '6500': {
          '6501':
          '${formatNumber(freq1)},$sf1,'
              '${formatNumber(effectiveFreq2)},$effectiveSf2',
        },
      });

      final communicationService =
      context.read<CommunicationService>();

      final result = await communicationService.sendCommand(
        payload: payload,
        serverMsg: 'LORA KEY UPDATE',
      );

      if (!mounted) return;

      final commandSent = result['http'] == true ||
          result['mqtt'] == true ||
          result['bluetooth'] == true;

      if (!commandSent) {
        _showSnackBar('Unable to send LoRa settings command');
        return;
      }

      final repository = Repository(HttpService());

      final body = {
        'userId': widget.userId,
        'controllerId': widget.controllerId,
        'loraFrequency':
        '$freq1,$sf1,$effectiveFreq2,$effectiveSf2',
        'modifyUser': widget.userId,
      };

      final response =
      await repository.updateUserDeviceFirmwareDetails(body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['code'] == 200) {
          await _refreshFrequencyFromApi();

          if (!mounted) return;

          _showSnackBar(
            data['message']?.toString() ??
                'LoRa settings updated successfully',
          );
        } else {
          _showSnackBar(
            data['message']?.toString() ??
                'Failed to save LoRa settings',
          );
        }
      } else {
        _showSnackBar('Failed to save LoRa settings');
      }
    } catch (e) {
      AppLog.log('LoRa send error: $e');
      _showSnackBar('Error sending LoRa settings');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _handleView(int loraIndex) async {
    if (_isLoading || _isSending) return;

    final command = loraIndex == 1 ? '29' : '30';

    // Capture the old value before requesting new device data.
    _viewBaselines[loraIndex] = _providerValue(loraIndex);

    setState(() {
      _pendingViews.add(loraIndex);
      _isLoading = true;
    });

    try {
      final payload = jsonEncode({
        '5700': {'5701': command},
      });

      final communicationService =
      context.read<CommunicationService>();

      final result = await communicationService.sendCommand(
        payload: payload,
        serverMsg: 'LORA KEY View',
      );

      print("result:$result");

      if (!mounted) return;

      print("result:$result");


      final commandSent = result['http'] == true ||
          result['mqtt'] == true ||
          result['bluetooth'] == true;

      if (!commandSent) {
        setState(() {
          _pendingViews.remove(loraIndex);
          _viewBaselines.remove(loraIndex);
          _isLoading = _pendingViews.isNotEmpty;
        });

        _showSnackBar('Unable to request LoRa settings');
        return;
      }

      // The provider listener updates the UI when data changes.
      // Timeout only stops the loading indicator.
      _viewTimeout?.cancel();

      _viewTimeout = Timer(const Duration(seconds: 12), () {
        if (!mounted || !_pendingViews.contains(loraIndex)) {
          return;
        }

        setState(() {
          _pendingViews.remove(loraIndex);
          _viewBaselines.remove(loraIndex);
          _isLoading = _pendingViews.isNotEmpty;
        });

        _showSnackBar('LoRa response timeout. Please try View again.');
      });
    } catch (e) {
      AppLog.log('LoRa View error: $e');

      if (mounted) {
        setState(() {
          _pendingViews.remove(loraIndex);
          _viewBaselines.remove(loraIndex);
          _isLoading = _pendingViews.isNotEmpty;
        });

        _showSnackBar('Unable to read LoRa settings');
      }
    }
  }

  // UI-only helpers: all controllers, validation, and communication logic remain unchanged.
  Widget _settingTile({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final primaryColor = Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.09),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: primaryColor, size: 20),
            ),
            const SizedBox(width: 11),
            Expanded(child: Text(title, style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ))),
          ]),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _frequencyInput(TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d?)?$')),
      ],
      decoration: _inputDecoration('LoRa Frequency (000.0)'),
    );
  }

  Widget _sfInput(TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(2),
      ],
      decoration: _inputDecoration('SF Value (7-12)'),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    final primaryColor = Theme.of(context).primaryColor;
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(11)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
    );
  }

  Widget _frequencySection({
    required int index,
    required TextEditingController frequencyController,
    required TextEditingController sfController,
    required double tileWidth,
  }) {
    final version = index == 1 ? loRa1VersionState : loRa2VersionState;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text('FREQUENCY $index SETTINGS', style: const TextStyle(
            fontSize: 12, letterSpacing: 1.2,
            fontWeight: FontWeight.w800, color: Color(0xFF64748B),
          )),
        ),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            SizedBox(
              width: tileWidth,
              child: _settingTile(
                title: 'LoRa Frequency $index',
                icon: Icons.wifi_tethering_rounded,
                child: _frequencyInput(frequencyController),
              ),
            ),
            SizedBox(
              width: tileWidth,
              child: _settingTile(
                title: 'Spreading Factor $index',
                icon: Icons.settings_input_antenna_rounded,
                child: _sfInput(sfController),
              ),
            ),
            SizedBox(
              width: tileWidth,
              child: _settingTile(
                title: 'Device $index Version',
                icon: Icons.memory_rounded,
                child: Row(children: [
                  Expanded(child: Text(
                    version.isEmpty ? '--' : version,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    overflow: TextOverflow.ellipsis,
                  )),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: (_isLoading || _isSending)
                        ? null : () => _handleView(index),
                    icon: const Icon(Icons.refresh, size: 17),
                    label: const Text('View'),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: primaryColor.withOpacity(0.01),
      appBar: AppBar(
        title: const Text('LoRa Frequency Settings'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh saved frequency',
            onPressed: (_isLoading || _isSending)
                ? null : _refreshFrequencyFromApi,
            icon: const Icon(Icons.sync),
          ),
        ],
      ),
      body: Stack(children: [
        LayoutBuilder(builder: (context, constraints) {
          const horizontalPadding = 18.0;
          const spacing = 14.0;
          final availableWidth = constraints.maxWidth - horizontalPadding * 2;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: horizontalPadding, vertical: 22,
            ),
            child: Center(child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Builder(builder: (context) {
                final contentWidth = availableWidth > 1200 ? 1200.0 : availableWidth;
                final count = contentWidth >= 900 ? 3 : contentWidth >= 560 ? 2 : 1;
                final cardWidth = (contentWidth - spacing * (count - 1)) / count;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Configure LoRa', style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    )),
                    const SizedBox(height: 5),
                    const Text('Manage device frequency and spreading factor settings',
                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    const SizedBox(height: 24),
                    _frequencySection(
                      index: 1,
                      frequencyController: frequency1Controller,
                      sfController: sf1Controller,
                      tileWidth: cardWidth,
                    ),
                    if (widget.plusTrue) ...[
                      const SizedBox(height: 28),
                      _frequencySection(
                        index: 2,
                        frequencyController: frequency2Controller,
                        sfController: sf2Controller,
                        tileWidth: cardWidth,
                      ),
                    ],
                    const SizedBox(height: 26),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _isSending ? null : () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('Cancel'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: (_isSending || _isLoading) ? null : _handleSend,
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: Text(_isSending ? 'Sending...' : 'Send'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }),
            )),
          );
        }),
        if (_isLoading || _isSending)
          Positioned.fill(child: ColoredBox(
            color: Colors.black38,
            child: const Center(child: CircularProgressIndicator()),
          )),
      ]),
    );
  }

  @override
  void dispose() {
    _viewTimeout?.cancel();

    mqttPayloadProvider.removeListener(_onMqttUpdated);

    frequency1Controller.removeListener(_onFieldEdited);
    frequency2Controller.removeListener(_onFieldEdited);
    sf1Controller.removeListener(_onFieldEdited);
    sf2Controller.removeListener(_onFieldEdited);

    frequency1Controller.dispose();
    frequency2Controller.dispose();
    sf1Controller.dispose();
    sf2Controller.dispose();

    super.dispose();
  }
}
