import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hex/Widgets/sized_image.dart';
import 'package:hex/modules/calibration/repository/calibration_repository.dart';
import 'package:hex/services/mqtt_service.dart';
import '../../../Constants/properties.dart';
import '../../../Widgets/custom_buttons.dart';
import '../../../Widgets/status_box.dart';
import '../../../repository/repository.dart';
import '../../../services/http_service.dart';
import '../../config_maker/view/config_web_view.dart';
import '../../../utils/constants.dart';
import '../../../utils/environment.dart';
import 'package:hex/views/customer/controller_settings/widgets/mobile_settings_app_bar.dart';
import '../model/calibration_object_model.dart';
import '../model/sensor_category_model.dart';

class CalibrationScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const CalibrationScreen({
    super.key,
    required this.userData,
  });

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  late Future<List<SensorCategoryModel>> listOfSensorCategoryModel;
  late Map<String, dynamic> defaultData;
  Set<int> selectedTab = {0};
  HardwareAcknowledgementState payloadState =
      HardwareAcknowledgementState.notSent;
  MqttService mqttService = MqttService();
  final Repository repository = Repository(HttpService());

  @override
  void initState() {
    super.initState();
    listOfSensorCategoryModel = getCalibration(widget.userData);
  }

  Future<List<SensorCategoryModel>> getCalibration(userData) async {
    List<SensorCategoryModel> calibrationData = [];
    try {
      var body = {
        "userId": userData['customerId'],
        "controllerId": userData['controllerId'],
      };
      var response = await CalibrationRepository().getUserCalibration(body);
      Map<String, dynamic> jsonData = jsonDecode(response.body);
      calibrationData =
          (jsonData['data']['calibration'] as List<dynamic>).map((element) {
        return SensorCategoryModel.fromJson(element);
      }).toList();
      setState(() {
        defaultData = jsonData['data']['default'];
      });
    } catch (e, stackTrace) {
      debugPrint('error :: $e');
      debugPrint('stackTrace :: $stackTrace');
      rethrow;
    }
    return calibrationData;
  }

  void _updateValue(CalibrationObjectModel object, double delta) {
    final currentStr = selectedTab.first == 0
        ? object.maximumValue
        : object.calibrationFactor;
    double val = double.tryParse(currentStr) ?? 0.0;
    val = (val + delta).clamp(0.0, 9999.0);
    final newStr = val.toStringAsFixed(1);
    setState(() {
      if (selectedTab.first == 0) {
        object.maximumValue = newStr;
      } else {
        object.calibrationFactor = newStr;
      }
    });
  }

  void _showManualEditDialog(CalibrationObjectModel object) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentVal = selectedTab.first == 0
        ? object.maximumValue
        : object.calibrationFactor;
    final textController = TextEditingController(text: currentVal);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            object.name,
            style: TextStyle(
                color: colorScheme.onSurface, fontWeight: FontWeight.bold),
          ),
          content: TextFormField(
            controller: textController,
            autofocus: true,
            keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: AppProperties.regexForDecimal,
            decoration: const InputDecoration(
              labelText: "Enter value",
              isDense: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  if (selectedTab.first == 0) {
                    object.maximumValue = textController.text;
                  } else {
                    object.calibrationFactor = textController.text;
                  }
                });
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<List<SensorCategoryModel>>(
        future: listOfSensorCategoryModel,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              backgroundColor: colorScheme.surfaceContainerLowest,
              body: const Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            return Scaffold(
              backgroundColor: colorScheme.surfaceContainerLowest,
              body: Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            );
          } else if (snapshot.hasData) {
            final data = snapshot.data!;
            return Scaffold(
              backgroundColor: colorScheme.surfaceContainerLowest,
              floatingActionButton: getFloatingActionButton(data),
              appBar: MediaQuery.of(context).size.width < 500
                  ? buildMobileSettingsAppBar(
                      context,
                      title: 'Calibration',
                    )
                  : null,
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _buildCenteredSegmentedControl(),
                        const SizedBox(height: 24),
                        ..._buildFilteredSensorCategories(data),
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ),
            );
          } else {
            return Scaffold(
              backgroundColor: colorScheme.surfaceContainerLowest,
              body: const Center(child: Text('No data')),
            );
          }
        });
  }

  Widget _buildCenteredSegmentedControl() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSegmentTab(0, "Calibration"),
            _buildSegmentTab(1, "Factor"),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentTab(int tabIndex, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = selectedTab.contains(tabIndex);

    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() {
            selectedTab = {tabIndex};
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(Icons.check_rounded, size: 16, color: colorScheme.onPrimary),
              const SizedBox(width: 6),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFilteredSensorCategories(List<SensorCategoryModel> data) {
    final keyType = selectedTab.first == 0 ? 'maximum' : 'factor';
    return [
      for (var sensorCategory in data)
        if (defaultData[keyType] != null &&
            defaultData[keyType]
                .contains(sensorCategory.objectTypeId.toString()))
          _buildResponsiveSensorGrid(sensorCategory),
    ];
  }

  Widget _buildResponsiveSensorGrid(SensorCategoryModel sensorCategory) {
    final objects = sensorCategory.calibrationObject;
    if (objects.isEmpty) return const SizedBox();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const spacing = 16.0;
        int columns = 1;
        if (width >= 1000) {
          columns = 3;
        } else if (width >= 600) {
          columns = 2;
        }

        final itemWidth = (width - (spacing * (columns - 1))) / columns;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoryHeader(sensorCategory),
            const SizedBox(height: 14),
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: List.generate(objects.length, (index) {
                final object = objects[index];
                return SizedBox(
                  width: itemWidth,
                  child: _buildSensorCard(object, index, sensorCategory),
                );
              }),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildCategoryHeader(SensorCategoryModel sensorCategory) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SizedImage(
                imagePath:
                '${AppConstants.svgObjectPath}objectId_${sensorCategory.objectTypeId}.svg',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            sensorCategory.object,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorCard(CalibrationObjectModel object, int index,
      SensorCategoryModel sensorCategory) {
    final colorScheme = Theme.of(context).colorScheme;
    final sensorNumber = (index + 1).toString().padLeft(2, '0');
    final currentValue = selectedTab.first == 0
        ? object.maximumValue
        : object.calibrationFactor;
    final displayVal = currentValue.isEmpty ? "0.0" : currentValue;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Sensor Name (left) & Number 01, 02 (right)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  object.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                sensorNumber,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Controls Row: [ - ]  Value  [ + ]
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Minus Button
              InkWell(
                onTap: () => _updateValue(object, -0.1),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withOpacity(0.6),
                    ),
                  ),
                  child: Icon(
                    Icons.remove_rounded,
                    size: 18,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),

              // Value Display (Tap to type manually if desired)
              GestureDetector(
                onTap: () => _showManualEditDialog(object),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Text(
                    displayVal,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),

              // Plus Button
              InkWell(
                onTap: () => _updateValue(object, 0.1),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withOpacity(0.6),
                    ),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),

          // Calibration count action for Factor mode
          if ((AppConstants.levelObjectId == object.objectId ||
                  AppConstants.pressureSensorObjectId == object.objectId) &&
              selectedTab.first == 1) ...[
            const SizedBox(height: 12),
            Divider(
              height: 1,
              thickness: 0.5,
              color: colorScheme.outlineVariant.withOpacity(0.3),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Calibration Count",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                IconButton(
                  tooltip: "Send Calibration Count",
                  icon: const Icon(
                    Icons.send_time_extension_rounded,
                    color: Colors.green,
                    size: 20,
                  ),
                  onPressed: () =>
                      _sendCalibrationCountDialog(object, sensorCategory),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _sendCalibrationCountDialog(
      CalibrationObjectModel object, SensorCategoryModel sensorCategory) {
    var payload = {
      "7600": {
        "7601": "${object.sNo},${sensorCategory.calibrationCount},0"
      }
    };
    setState(() {
      payloadState = HardwareAcknowledgementState.notSent;
      mqttService.acknowledgementPayload = null;
    });

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, stateSetter) {
            return AlertDialog(
              title: Text(
                'Send Payload',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              content: getHardwareAcknowledgementWidget(payloadState),
              actions: [
                if (payloadState != HardwareAcknowledgementState.sending &&
                    payloadState != HardwareAcknowledgementState.notSent)
                  CustomMaterialButton(),
                if (payloadState == HardwareAcknowledgementState.notSent)
                  CustomMaterialButton(
                    title: 'Cancel',
                    outlined: true,
                  ),
                if (payloadState == HardwareAcknowledgementState.notSent)
                  CustomMaterialButton(
                    onPressed: () async {
                      int delayDuration = 20;
                      for (var delay = 0; delay < delayDuration; delay++) {
                        if (delay == 0) {
                          stateSetter(() {
                            setState(() {
                              mqttService.topicToPublishAndItsMessage(
                                  jsonEncode(payload),
                                  '${Environment.mqttPublishTopic}/${widget.userData['deviceId']}');
                              payloadState =
                                  HardwareAcknowledgementState.sending;
                            });
                          });
                        }
                        stateSetter(() {
                          setState(() {
                            if (mqttService.acknowledgementPayload != null) {
                              if (validatePayloadFromHardware(
                                      mqttService.acknowledgementPayload!,
                                      ['cC'],
                                      widget.userData['deviceId']) &&
                                  validatePayloadFromHardware(
                                      mqttService.acknowledgementPayload!,
                                      ['cM', '4201', 'PayloadCode'],
                                      '7600')) {
                                if (mqttService.acknowledgementPayload!['cM']
                                        ['4201']['Code'] ==
                                    '200') {
                                  payloadState =
                                      HardwareAcknowledgementState.success;
                                } else if (mqttService
                                            .acknowledgementPayload!['cM']
                                        ['4201']['Code'] ==
                                    '90') {
                                  payloadState = HardwareAcknowledgementState
                                      .programRunning;
                                } else if (mqttService
                                            .acknowledgementPayload!['cM']
                                        ['4201']['Code'] ==
                                    '1') {
                                  payloadState = HardwareAcknowledgementState
                                      .hardwareUnknownError;
                                } else {
                                  payloadState = HardwareAcknowledgementState
                                      .errorOnPayload;
                                }
                                mqttService.acknowledgementPayload == null;
                              }
                            }
                          });
                        });
                        await Future.delayed(const Duration(seconds: 1));
                        if (delay == delayDuration - 1) {
                          stateSetter(() {
                            setState(() {
                              payloadState = HardwareAcknowledgementState.failed;
                            });
                          });
                        }
                        if (payloadState !=
                            HardwareAcknowledgementState.sending) {
                          break;
                        }
                      }
                      var data = {
                        "userId": widget.userData["customerId"],
                        "controllerId": widget.userData["controllerId"],
                        "data": payload,
                        "messageStatus": "${object.name} - calibration",
                        "createUser": widget.userData["customerId"],
                        "hardware": payload,
                      };
                      await repository.sendManualOperationToServer(data);
                    },
                    title: 'Send',
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget getFloatingActionButton(
      List<SensorCategoryModel> sensorCategoryModel) {
    return FloatingActionButton(
      onPressed: () {
        setState(() {
          payloadState = HardwareAcknowledgementState.notSent;
          mqttService.acknowledgementPayload = null;
        });
        showDialog(
            barrierDismissible: false,
            context: context,
            builder: (context) {
              return StatefulBuilder(builder: (context, stateSetter) {
                return AlertDialog(
                  title: Text(
                    'Send Payload',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  content: getHardwareAcknowledgementWidget(payloadState),
                  actions: [
                    if (payloadState != HardwareAcknowledgementState.sending &&
                        payloadState != HardwareAcknowledgementState.notSent)
                      CustomMaterialButton(),
                    if (payloadState == HardwareAcknowledgementState.notSent)
                      CustomMaterialButton(
                        title: 'Cancel',
                        outlined: true,
                      ),
                    if (payloadState == HardwareAcknowledgementState.notSent)
                      CustomMaterialButton(
                        onPressed: () async {
                          sendToHttp(sensorCategoryModel);
                          var payload = jsonEncode(
                              getCalibrationPayload(sensorCategoryModel));
                          int delayDuration = 20;
                          for (var delay = 0; delay < delayDuration; delay++) {
                            if (delay == 0) {
                              stateSetter(() {
                                setState(() {
                                  mqttService.topicToPublishAndItsMessage(
                                      payload,
                                      '${Environment.mqttPublishTopic}/${widget.userData['deviceId']}');
                                  payloadState =
                                      HardwareAcknowledgementState.sending;
                                });
                              });
                            }
                            stateSetter(() {
                              setState(() {
                                if (mqttService.acknowledgementPayload !=
                                    null) {
                                  if (validatePayloadFromHardware(
                                          mqttService.acknowledgementPayload!,
                                          ['cC'],
                                          widget.userData['deviceId']) &&
                                      validatePayloadFromHardware(
                                          mqttService.acknowledgementPayload!,
                                          ['cM', '4201', 'PayloadCode'],
                                          '4600')) {
                                    if (mqttService.acknowledgementPayload![
                                                'cM']['4201']['Code'] ==
                                            '200') {
                                      payloadState =
                                          HardwareAcknowledgementState.success;
                                    } else if (mqttService
                                                .acknowledgementPayload!['cM']
                                            ['4201']['Code'] ==
                                        '90') {
                                      payloadState =
                                          HardwareAcknowledgementState
                                              .programRunning;
                                    } else if (mqttService
                                                .acknowledgementPayload!['cM']
                                            ['4201']['Code'] ==
                                        '1') {
                                      payloadState =
                                          HardwareAcknowledgementState
                                              .hardwareUnknownError;
                                    } else {
                                      payloadState =
                                          HardwareAcknowledgementState
                                              .errorOnPayload;
                                    }
                                    mqttService.acknowledgementPayload == null;
                                  }
                                }
                              });
                            });
                            await Future.delayed(const Duration(seconds: 1));
                            if (delay == delayDuration - 1) {
                              stateSetter(() {
                                setState(() {
                                  payloadState =
                                      HardwareAcknowledgementState.failed;
                                });
                              });
                            }
                            if (payloadState !=
                                HardwareAcknowledgementState.sending) {
                              break;
                            }
                          }
                        },
                        title: 'Send',
                      ),
                  ],
                );
              });
            });
      },
      child: const Icon(Icons.send),
    );
  }

  void sendToHttp(List<SensorCategoryModel> sensorCategoryModel) async {
    var body = {
      "userId": widget.userData['customerId'],
      "controllerId": widget.userData['controllerId'],
      'calibration': sensorCategoryModel
          .map((sensorCategory) => sensorCategory.toJson())
          .toList(),
      "createUser": widget.userData['userId']
    };
    var response = await CalibrationRepository().createUserCalibration(body);
    debugPrint('response calibration : ${response.body}');
  }

  Map<String, dynamic> getCalibrationPayload(
      List<SensorCategoryModel> sensorCategory) {
    var payloadWithOutWeather = sensorCategory
        .map((category) {
          return category.calibrationObject.map((object) {
            return {
              'S_No': object.sNo,
              'CalibrationValue': object.calibrationFactor.isEmpty
                  ? 1.0
                  : object.calibrationFactor,
              'MaximumValue':
                  object.maximumValue.isEmpty ? 1.0 : object.maximumValue,
            }.entries.map((obj) => obj.value).join(',');
          }).toList();
        })
        .expand((list) => list)
        .toList()
        .join(';');
    var calibrationPayload = {
      "4600": {"4601": payloadWithOutWeather}
    };
    return calibrationPayload;
  }

  Widget getHardwareAcknowledgementWidget(HardwareAcknowledgementState state) {
    debugPrint('state : $state');
    if (state == HardwareAcknowledgementState.notSent) {
      return const StatusBox(
        color: Colors.black87,
        child: Text('Do you want to send payload..'),
      );
    } else if (state == HardwareAcknowledgementState.success) {
      return const StatusBox(
        color: Colors.green,
        child: Text('Success..'),
      );
    } else if (state == HardwareAcknowledgementState.failed) {
      return const StatusBox(
        color: Colors.red,
        child: Text('Failed..'),
      );
    } else if (state == HardwareAcknowledgementState.errorOnPayload) {
      return const StatusBox(
        color: Colors.red,
        child: Text('Payload error..'),
      );
    } else {
      return const SizedBox(
          width: double.infinity,
          height: 5,
          child: LinearProgressIndicator());
    }
  }
}
