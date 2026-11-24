import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_date_range_picker/flutter_date_range_picker.dart';
import 'package:flutter_svg/svg.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:hex/Constants/properties.dart';
import 'package:hex/Widgets/custom_buttons.dart';
import 'package:hex/modules/irrigation_report/view/reason_lookup.dart';
import 'package:hex/modules/irrigation_report/view/scrollingTable.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
// import 'dart:html' as html;
// import 'package:excel/excel.dart';
// import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
// import 'dart:html' as html;
import 'dart:async';
import '../model/data_parsing_and_sorting_model.dart';
import 'excel_download_stub.dart' if (dart.library.html) 'excel_download_web.dart';
import '../model/data_parsing_and_sorting_model.dart';
import '../model/general_parameter_model.dart';
import '../repository/irrigation_repository.dart';
import 'package:hex/Screens/Logs/sensor_graph_log.dart';
import '../../../models/customer/site_model.dart';
import '../../../services/mqtt_service.dart';
import '../../../utils/environment.dart';
import '../../../utils/constants.dart';
import 'package:provider/provider.dart';
import '../../../StateManagement/customer_provider.dart';

class LogHome extends StatefulWidget {
  final dynamic serverData;
  final List<dynamic> nameData;
  final Map<String, dynamic> userData;
  final MasterControllerModel? masterData;
  const LogHome({
    super.key,
    required this.serverData,
    required this.userData,
    required this.nameData,
    this.masterData,
  });
  @override
  State<LogHome> createState() => _LogHomeState();
}

class _LogHomeState extends State<LogHome> {
  int noOfRowsPerPage = 20;
  int totalPages = 0;
  int selectedPages = 1;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Set<String> _hiddenPrograms = {};
  dynamic dataSource = [];
  List<dynamic> _localNameData = [];
  List<dynamic> _filterSiteData = [];
  int _selectedIndex = 0;
  List<List<dynamic>> _irrigationOptionWise = [['Date',true],['Program',false],['Line',false],['Valve',false],['Status',false]];
  bool graphMode = false;
  DateRange? selectedDateRange;
  DateRange? lastSelectedDateRange;
  ScrollController _graphController = ScrollController();
  StreamSubscription? _rawScheduleSubscription;
  bool isLiveSyncing = false;
  bool isLiveLoaded = false;
  late LinkedScrollControllerGroup _scrollable1;
  late ScrollController _verticalScroll1;
  late ScrollController _verticalScroll2;
  late LinkedScrollControllerGroup _scrollable2;
  late ScrollController _horizontalScroll1;
  late ScrollController _horizontalScroll2;
  Icon selectedIcon = const Icon(Icons.bar_chart,color: Colors.white,);
  String selectedChart = 'Bar';
  // late final Widget Function({DateRange? selectedDateRange})? dialogFooterBuilder;
  List<dynamic> program = [];
  List<dynamic> programDuplicate = [];
  List<dynamic> valve = [];
  List<dynamic> valveDuplicate = [];
  List<dynamic> line = [];
  List<dynamic> lineDuplicate = [];
  List<dynamic> date = [];
  List<dynamic> dateDuplicate = [];
  List<dynamic> status = [];
  List<dynamic> statusDuplicate = [];
  List<dynamic> parameters = [
    'Date','Status','ProgramS_No','ProgramCategory','ZoneS_No','ZoneName','ScheduledStartTime',
    'ActualStartTime','ActualEndTime','ActualStartReason','ActualStopReason',
    'SequenceData','ValveFlowrate','IrrigationDurationCompleted','ProgramName',
    'IrrigationMethod','IrrigationDuration_Quantity','IrrigationQuantityCompleted','ProgramCategoryName','Pretime','PostTime',
    'CentralFilterSite','LocalFilterSite','CentralFilterOnDuration','LocalFilterOnDuration', 'CentralFertOnOff', 'LocalFertOnOff'
  ];

  int httpError = 0;

  Map<String,dynamic> dataToShow = {};
  dynamic IrrigationLogParameterFromServer = {};
  IrrigationLogModel irrigationParameterArray = IrrigationLogModel();
  IrrigationLogModel irrigationParameterArrayDuplicate = IrrigationLogModel();
  String _selectedDate = '';
  String _dateCount = '';
  String _range = '';
  String _rangeCount = '';

  @override
  void initState() {
    // TODO: implement initState
    _localNameData = List.from(widget.nameData);
    _fetchConfigObjects();
    if (kDebugMode) {
      print('parameters => $parameters');
    }
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (mounted) {
        dataSource = [];
        dataToShow = {};
        program = [];
        programDuplicate = [];
        valve = [];
        valveDuplicate = [];
        line = [];
        lineDuplicate = [];
        date = [];
        dateDuplicate = [];
        status = [];
        statusDuplicate = [];
        IrrigationLogParameterFromServer = mergeDefaultLogParameters(
            widget.serverData['irrigationLog'] ?? widget.serverData['default'] ?? widget.serverData,
            widget.serverData['default']);
        for(var globalParameter in IrrigationLogParameterFromServer.keys){
          for(var localParameter in IrrigationLogParameterFromServer[globalParameter].keys){
            var data = IrrigationLogParameterFromServer[globalParameter][localParameter];
            var split = localParameter.split('/');
            if(data[1] == true){
              for(var key in split){
                if(key != 'overAll'){
                  if(!parameters.contains(key)){
                    parameters.add(key);
                  }
                }
              }
            }
          }
        }
        getData();
      }
    });

    _rawScheduleSubscription = MqttService().rawSchedulePayloadStream.listen((rawPayload) {
      if (rawPayload != null && mounted && isLiveSyncing) {
        _mergeLivePayload(rawPayload);
      }
    });

    _scrollable1 = LinkedScrollControllerGroup();
    _verticalScroll1 = _scrollable1.addAndGet();
    _verticalScroll2 = _scrollable1.addAndGet();
    _scrollable2 = LinkedScrollControllerGroup();
    _horizontalScroll1 = _scrollable2.addAndGet();
    _horizontalScroll2 = _scrollable2.addAndGet();
    super.initState();
  }

  @override
  void dispose() {
    _rawScheduleSubscription?.cancel();
    _scrollController.dispose();
    _graphController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchConfigObjects() async {
    try {
      var body = {
        'userId': widget.userData['customerId'],
        'controllerId': widget.userData['controllerId'],
      };
      var configResponse = await IrrigationRepository().getUserNames(body);
      Map<String, dynamic> configJsonData = jsonDecode(configResponse.body);
      if (configJsonData['code'] == 200 && configJsonData['data'] != null) {
        if (mounted) {
          setState(() {
            if (configJsonData['data']['configObject'] != null) {
              _localNameData = configJsonData['data']['configObject'];
              irrigationParameterArray.editName(_localNameData);
              irrigationParameterArrayDuplicate.editName(_localNameData);
            }
            if (configJsonData['data']['filterSite'] != null) {
              _filterSiteData = configJsonData['data']['filterSite'];
              irrigationParameterArray.editFilterSite(_filterSiteData);
              irrigationParameterArrayDuplicate.editFilterSite(_filterSiteData);
            }
          });
          if (dataSource != null && dataSource.isNotEmpty) {
            _reprocessAndFilterData();
          }
        }
      }
    } catch (e) {
      // ignore
    }
  }

  bool get hasConfiguredSensors {
    final sensorObjectIds = <int>{
      AppConstants.moistureObjectId,          // 25
      AppConstants.pressureSensorObjectId,    // 24
      AppConstants.levelObjectId,             // 26
      AppConstants.ecObjectId,                // 27
      AppConstants.phObjectId,                // 28
      AppConstants.temperatureObjectId,       // 29
      AppConstants.soilTemperatureObjectId,   // 30
      AppConstants.waterMeterObjectId,        // 22
      AppConstants.analogWaterMeterObjectId,  // 46
      AppConstants.humidityObjectId,          // 36
      AppConstants.co2ObjectId,               // 33
      AppConstants.windDirectionObjectId,     // 31
      AppConstants.windSpeedObjectId,         // 32
      AppConstants.luxObjectId,               // 34
      AppConstants.ldrObjectId,               // 35
      AppConstants.leafWetnessObjectId,       // 37
      AppConstants.rainFallObjectId,          // 38
      AppConstants.atmosphericPressureObjectId, // 39
      AppConstants.pressureSwitchObjectId,    // 23
    };

    final namesToCheck = _localNameData.isNotEmpty ? _localNameData : widget.nameData;
    if (namesToCheck.isNotEmpty) {
      for (var item in namesToCheck) {
        if (item is Map) {
          final rawId = item['objectId'];
          final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
          if (id != null && sensorObjectIds.contains(id)) {
            return true;
          }
          final objectName = (item['objectName'] ?? '').toString().toLowerCase();
          final name = (item['name'] ?? '').toString().toLowerCase();
          if (objectName.contains('sensor') ||
              objectName.contains('moisture') ||
              objectName.contains('pressure') ||
              objectName.contains('level') ||
              objectName.contains('ec') ||
              objectName.contains('ph') ||
              objectName.contains('temp') ||
              objectName.contains('humidity') ||
              objectName.contains('water meter') ||
              name.contains('sensor') ||
              name.contains('moisture') ||
              name.contains('pressure')) {
            return true;
          }
        }
      }
    }

    if (widget.masterData?.configObjects != null &&
        widget.masterData!.configObjects.isNotEmpty) {
      for (var obj in widget.masterData!.configObjects) {
        if (sensorObjectIds.contains(obj.objectId)) {
          return true;
        }
        final objectName = obj.objectName.toLowerCase();
        final name = obj.name.toLowerCase();
        if (objectName.contains('sensor') ||
            objectName.contains('moisture') ||
            objectName.contains('pressure') ||
            objectName.contains('level') ||
            objectName.contains('ec') ||
            objectName.contains('ph') ||
            objectName.contains('temp') ||
            objectName.contains('humidity') ||
            objectName.contains('water meter') ||
            name.contains('sensor') ||
            name.contains('moisture') ||
            name.contains('pressure')) {
          return true;
        }
      }
    }

    if (widget.masterData?.ecSensors != null && widget.masterData!.ecSensors.isNotEmpty) {
      return true;
    }
    if (widget.masterData?.phSensors != null && widget.masterData!.phSensors.isNotEmpty) {
      return true;
    }

    return false;
  }

  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   if (mounted) {
  //     Navigator.maybePop(context);
  //   }
  // }

  String _formatNumber(int number) {
    // Add leading zero if the number is less than 10
    return number.toString().padLeft(2, '0');
  }

  void loadingDialog()async{
    showDialog(
        barrierDismissible: false,
        context: context, builder: (context){
      return const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            spacing: 20,
            children: [
              CircularProgressIndicator(),
              Text('Please wait...')
            ],
          ),
        ),
      );
    }
    );
  }

  Future<void> getData() async {
    loadingDialog();
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('dd/MM/yyyy').format(now);
    _selectedDate = _selectedDate == '' ? '$formattedDate - $formattedDate' : _selectedDate;
    String dateString1;
    String dateString2;
    if (_selectedDate.contains(' - ')) {
      final parts = _selectedDate.split(' - ');
      dateString1 = parts[0].trim();
      dateString2 = parts[1].trim();
    } else {
      dateString1 = _selectedDate.trim();
      dateString2 = _selectedDate.trim();
    }

    DateTime date1;
    DateTime date2;

    if (dateString1.contains('/')) {
      List<String> parts1 = dateString1.split('/');
      date1 = DateTime(int.parse(parts1[2]), int.parse(parts1[1]), int.parse(parts1[0]));
    } else {
      date1 = DateTime.tryParse(dateString1) ?? now;
    }

    if (dateString2.contains('/')) {
      List<String> parts2 = dateString2.split('/');
      date2 = DateTime(int.parse(parts2[2]), int.parse(parts2[1]), int.parse(parts2[0]));
    } else {
      date2 = DateTime.tryParse(dateString2) ?? now;
    }

    // Format DateTime objects into desired format
    String formattedDate1 = "${date1.year}-${_formatNumber(date1.month)}-${_formatNumber(date1.day)}";
    String formattedDate2 = "${date2.year}-${_formatNumber(date2.month)}-${_formatNumber(date2.day)}";

    irrigationParameterArray.editParameter(IrrigationLogParameterFromServer);
    irrigationParameterArray.editName(_localNameData.isNotEmpty ? _localNameData : widget.nameData);
    irrigationParameterArray.editFilterSite(_filterSiteData);

    irrigationParameterArrayDuplicate.editParameter(IrrigationLogParameterFromServer);
    irrigationParameterArrayDuplicate.editName(_localNameData.isNotEmpty ? _localNameData : widget.nameData);
    irrigationParameterArrayDuplicate.editFilterSite(_filterSiteData);
    try{
      String? startMonth = selectedDateRange?.start.month.toString();

      String? startday = selectedDateRange?.start.day.toString();
      String? endMonth = selectedDateRange?.end.month.toString();
      String? endday = selectedDateRange?.end.day.toString();
      var body = {
        "userId": widget.userData['customerId'],
        "controllerId": widget.userData['controllerId'],
        "logType" : "Irrigation",
        "fromDate" : formattedDate1,
        "toDate" : formattedDate2,
        "parameters" : parameters,
      };
      var response = await IrrigationRepository().getLogDateWise(body);
      Map<String, dynamic> jsonData = jsonDecode(response.body);
      if(jsonData['code'] == 200){
        setState(() {
          dataSource = jsonData['data'];
          httpError = 0;
          isLiveLoaded = false;
        });
        _reprocessAndFilterData();
      }
      Navigator.pop(context);
    }catch(e,stackTrace){
      Navigator.pop(context);
      setState(() {
        httpError = 1;
      });
      if (kDebugMode){
        print('error in log = > ${e.toString()}');
        print('error in log stackTrace= > $stackTrace');
      }
    }
  }

  bool _isValidIndex(dynamic listObj, int index) {
    if (listObj == null) return true;
    if (listObj is List) {
      if (listObj.isEmpty) return true;
      return index < listObj.length;
    }
    return true;
  }

  void _reprocessAndFilterData() {
    if (!mounted) return;
    if (dataSource == null || dataSource is! Map || dataSource['log'] == null) return;
    setState(() {
      dataToShow = {};
      program = [];
      programDuplicate = [];
      valve = [];
      valveDuplicate = [];
      line = [];
      lineDuplicate = [];
      date = [];
      dateDuplicate = [];
      status = [];
      statusDuplicate = [];
    });

    for (var data in dataSource['log']) {
      if (data != null && data['irrigation'] != null && data['irrigation'].isNotEmpty) {
        if (data['irrigation']['Date'] != null) {
          //Todo date
          try {
            for (var howManyDate = 0; howManyDate < data['irrigation']['Date'].length; howManyDate++) {
              if (_isValidIndex(data['irrigation']['HeadUnit'], howManyDate)) {
                setState(() {
                  if (!date.any((element) => element['name'] == data['irrigation']['Date'][howManyDate])) {
                    date.add({
                      'name': data['irrigation']['Date'][howManyDate],
                      'show': true,
                    });
                    dateDuplicate.add({
                      'name': data['irrigation']['Date'][howManyDate],
                      'show': true,
                    });
                  }
                });
              }
            }
          } catch (e, stackTrace) {
            log('Error on Date : ${e.toString()}');
            print('Stack Trace: $stackTrace');
          }

          //Todo Status
          try {
            if (data['irrigation']['Status'] != null) {
              for (var howManyStatus = 0; howManyStatus < data['irrigation']['Status'].length; howManyStatus++) {
                if (_isValidIndex(data['irrigation']['HeadUnit'], howManyStatus)) {
                  setState(() {
                    if (!status.any((element) => element['name'] == data['irrigation']['Status'][howManyStatus])) {
                      status.add({
                        'name': data['irrigation']['Status'][howManyStatus],
                        'show': true,
                      });
                      statusDuplicate.add({
                        'name': data['irrigation']['Status'][howManyStatus],
                        'show': true,
                      });
                    }
                  });
                }
              }
            }
          } catch (e, stackTrace) {
            log('Error on Status : ${e.toString()}');
            print('Stack Trace: $stackTrace');
          }

          //Todo ProgramS_No
          try {
            if (data['irrigation']['ProgramS_No'] != null) {
              for (var howManyProgram = 0; howManyProgram < data['irrigation']['ProgramS_No'].length; howManyProgram++) {
                if (_isValidIndex(data['irrigation']['HeadUnit'], howManyProgram)) {
                  setState(() {
                    if (!program.any((element) => element['name'] == data['irrigation']['ProgramS_No'][howManyProgram])) {
                      program.add({
                        'name': data['irrigation']['ProgramS_No'][howManyProgram],
                        'show': true,
                        'programName': irrigationParameterArray.getProgramName(
                            dataSource['default']?['program'] ?? [],
                            data['irrigation']['ProgramS_No'][howManyProgram])
                      });

                      programDuplicate.add({
                        'name': data['irrigation']['ProgramS_No'][howManyProgram],
                        'show': true,
                        'programName': irrigationParameterArray.getProgramName(
                            dataSource['default']?['program'] ?? [],
                            data['irrigation']['ProgramS_No'][howManyProgram])
                      });
                    }
                  });
                }
              }
            }
          } catch (e, stackTrace) {
            log('Error on ProgramS_No : ${e.toString()}');
            print('Stack Trace: $stackTrace');
          }

          //Todo ProgramCategory && ProgramCategoryName
          try {
            if (data['irrigation']['ProgramCategory'] != null) {
              for (var howManyLine = 0; howManyLine < data['irrigation']['ProgramCategory'].length; howManyLine++) {
                if (_isValidIndex(data['irrigation']['HeadUnit'], howManyLine)) {
                  for (var splitLine in data['irrigation']['ProgramCategory'][howManyLine].toString().split('_')) {
                    var lineName = (data['irrigation']['HeadUnit'] != null &&
                        data['irrigation']['HeadUnit'] is List &&
                        howManyLine < data['irrigation']['HeadUnit'].length)
                        ? data['irrigation']['HeadUnit'][howManyLine].toString().split('_')
                        : [splitLine];
                    setState(() {
                      if (!line.any((element) => element['name'] == splitLine)) {
                        line.add({
                          'name': splitLine,
                          'show': true,
                          'lineName': lineName
                        });
                        lineDuplicate.add({
                          'name': splitLine,
                          'show': true,
                          'lineName': lineName
                        });
                      }
                    });
                  }
                }
              }
            }
          } catch (e, stackTrace) {
            log('Error on HeadUnit : ${e.toString()}');
            print('Stack Trace: $stackTrace');
          }

          //Todo SequenceData
          try {
            if (data['irrigation']['SequenceData'] != null) {
              for (var howManyValve = 0; howManyValve < data['irrigation']['SequenceData'].length; howManyValve++) {
                if (_isValidIndex(data['irrigation']['HeadUnit'], howManyValve)) {
                  for (var splitValve in data['irrigation']['SequenceData'][howManyValve].toString().split('_')) {
                    setState(() {
                      if (splitValve.contains('13')) {
                        if (!valve.any((element) => element['name'] == splitValve)) {
                          valve.add({
                            'name': splitValve,
                            'show': true,
                          });
                          valveDuplicate.add({
                            'name': splitValve,
                            'show': true,
                          });
                        }
                      }
                    });
                  }
                }
              }
            }
          } catch (e, stackTrace) {
            log('Error on SequenceData : ${e.toString()}');
            print('Stack Trace: $stackTrace');
          }
        }
      }
    }

    setState(() {
      if (valve.isNotEmpty) {
        valve.sort((a, b) {
          var aParts = a['name'].split('VL.');
          var bParts = b['name'].split('VL.');
          if (aParts.length > 1 && bParts.length > 1) {
            return double.parse(aParts[1]).compareTo(double.parse(bParts[1]));
          }
          return 0;
        });

        valveDuplicate.sort((a, b) {
          var aParts = a['name'].split('VL.');
          var bParts = b['name'].split('VL.');
          if (aParts.length > 1 && bParts.length > 1) {
            return double.parse(aParts[1]).compareTo(double.parse(bParts[1]));
          }
          return 0;
        });
      }

      if (line.isNotEmpty) {
        line.sort((a, b) {
          var aParts = a['name'].split('.');
          var bParts = b['name'].split('.');
          if (aParts.length > 1 && bParts.length > 1) {
            return int.parse(aParts[1]).compareTo(int.parse(bParts[1]));
          }
          return 0;
        });

        lineDuplicate.sort((a, b) {
          var aParts = a['name'].split('.');
          var bParts = b['name'].split('.');
          if (aParts.length > 1 && bParts.length > 1) {
            return int.parse(aParts[1]).compareTo(int.parse(bParts[1]));
          }
          return 0;
        });
      }

      if (program.isNotEmpty) {
        program.sort((a, b) => a['name'].compareTo(b['name']));
        programDuplicate.sort((a, b) => a['name'].compareTo(b['name']));
      }
    });

    setState(() {
      if (_irrigationOptionWise[0][1] == true) {
        dataToShow = irrigationParameterArray.editDateWise(dataSource, date);
      } else if (_irrigationOptionWise[1][1] == true) {
        dataToShow = irrigationParameterArray.editProgramWise(dataSource, program);
      } else if (_irrigationOptionWise[2][1] == true) {
        dataToShow = irrigationParameterArray.editLineWise(dataSource, line);
      } else if (_irrigationOptionWise[3][1] == true) {
        dataToShow = irrigationParameterArray.editValveWise(dataSource, valve);
      } else if (_irrigationOptionWise[4][1] == true) {
        dataToShow = irrigationParameterArray.editStatusWise(dataSource, status);
      }
    });

    setState(() {
      if (dataToShow.containsKey('fixedColumnData') && dataToShow['fixedColumnData'] is List) {
        totalPages = (dataToShow['fixedColumnData'].length ~/ noOfRowsPerPage);
        if ((totalPages * noOfRowsPerPage) < dataToShow['fixedColumnData'].length) {
          totalPages += 1;
        }
      } else {
        totalPages = 0;
      }
      selectedPages = 1;
    });
  }

  Map<String, dynamic>? _prepareLiveIrrigationData(Map<String, dynamic> raw, String todayStr) {
    if (raw.isEmpty) return null;
    final Map<String, dynamic> prepared = Map<String, dynamic>.from(raw);
    int count = 0;
    for (var v in prepared.values) {
      if (v is List && v.isNotEmpty) {
        count = v.length;
        break;
      }
    }
    if (count == 0) return null;

    if (!prepared.containsKey('Date') || prepared['Date'] == null || (prepared['Date'] as List).isEmpty) {
      prepared['Date'] = List.filled(count, todayStr);
    } else {
      prepared['Date'] = (prepared['Date'] as List).map((d) => (d == null || d.toString().isEmpty) ? todayStr : d.toString()).toList();
    }

    if (prepared.containsKey('HeadUnit') && prepared['HeadUnit'] is List) {
      prepared['HeadUnit'] = (prepared['HeadUnit'] as List).map((h) {
        final s = h.toString();
        if (!s.contains('.')) {
          return '2.$s';
        }
        return s;
      }).toList();
    } else {
      prepared['HeadUnit'] = List.filled(count, '2.1');
    }

    if (!prepared.containsKey('ProgramCategory') || prepared['ProgramCategory'] == null) {
      prepared['ProgramCategory'] = List.from(prepared['HeadUnit']);
    }

    final keysToEnsure = [
      'Status',
      'ProgramS_No',
      'SequenceData',
      'ActualStartTime',
      'ActualEndTime',
      'ActualStartReason',
      'ActualStopReason',
      'ValveFlowrate',
      'Pretime',
      'PostTime',
      'CentralFilterName',
      'LocalFilterName',
      'CentralFilterOnDuration',
      'LocalFilterOnDuration',
      'CentralFertOnOff',
      'LocalFertOnOff',
      'PumpCtAverage',
      'PumpCtMaximum',
      'PumpCtMinimum',
      'PressureAverage',
      'PressureMaximum',
      'PressureMinimum',
    ];

    for (final key in keysToEnsure) {
      if (!prepared.containsKey(key) || prepared[key] == null || (prepared[key] is List && (prepared[key] as List).length < count)) {
        prepared[key] = List.filled(count, '-');
      }
    }

    return prepared;
  }

  void _mergeLivePayload(Map<String, dynamic> rawLive) {
    if (!mounted) return;
    if (dataSource == null || dataSource is! Map) {
      dataSource = {'log': []};
    }
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final preparedLive = _prepareLiveIrrigationData(rawLive, todayStr);
    if (preparedLive == null) return;

    setState(() {
      dataSource['log'] ??= [];
      List logs = dataSource['log'];

      logs.removeWhere((item) {
        if (item is Map && item['irrigation'] != null) {
          final dates = item['irrigation']['Date'];
          if (dates is List && dates.isNotEmpty && dates.any((d) => d.toString().contains(todayStr))) {
            return true;
          }
        }
        return false;
      });

      logs.add({'irrigation': preparedLive});
      isLiveLoaded = true;
      isLiveSyncing = false;
    });

    _reprocessAndFilterData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Live data updated from controller'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _requestLiveSync({bool silent = false}) async {
    String? deviceId = widget.masterData?.deviceId ?? widget.userData['deviceId']?.toString();
    if (deviceId == null || deviceId.isEmpty) {
      try {
        final custPvd = Provider.of<CustomerProvider>(context, listen: false);
        if (custPvd.deviceId != null && custPvd.deviceId!.isNotEmpty) {
          deviceId = custPvd.deviceId;
        }
      } catch (_) {}
    }

    if (deviceId == null || deviceId.isEmpty) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device ID not found. Unable to request live data.')),
        );
      }
      return;
    }

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    DateTime date1 = today;
    DateTime date2 = today;
    if (_selectedDate.contains(' - ')) {
      final parts = _selectedDate.split(' - ');
      final p1 = parts[0].trim().split('/');
      final p2 = parts[1].trim().split('/');
      if (p1.length == 3 && p2.length == 3) {
        date1 = DateTime(int.parse(p1[2]), int.parse(p1[1]), int.parse(p1[0]));
        date2 = DateTime(int.parse(p2[2]), int.parse(p2[1]), int.parse(p2[0]));
      }
    }

    bool includesToday = (today.isAfter(date1) || today.isAtSameMomentAs(date1)) &&
        (today.isBefore(date2) || today.isAtSameMomentAs(date2));

    if (!includesToday) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Live sync is only available for today. Please select today to view live data.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    if (!silent) {
      setState(() {
        isLiveSyncing = true;
      });
    }

    final String todayFormatted = DateFormat('yyyy-MM-dd').format(now);
    final Map<String, dynamic> data = {
      "2600": {
        "2601": "$todayFormatted,$todayFormatted"
      }
    };

    try {
      final topic = '${Environment.mqttPublishTopic}/$deviceId';
      await MqttService().topicToPublishAndItsMessage(jsonEncode(data), topic);

      Timer(const Duration(seconds: 6), () {
        if (mounted && isLiveSyncing) {
          setState(() {
            isLiveSyncing = false;
          });
          if (!silent) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No response from controller. Showing cloud log.'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      });
    } catch (e) {
      if (mounted && !silent) {
        setState(() {
          isLiveSyncing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish live request: $e')),
        );
      }
    }
  }

  // Widget navigationItem(String name,int index,icon){
  //   return InkWell(
  //     onTap: (){
  //       setState(() {
  //         _selectedIndex = index;
  //       });
  //     },
  //     child: Container(
  //         width: 230,
  //         height: 50,
  //         decoration: BoxDecoration(
  //           borderRadius: BorderRadius.circular(8),
  //           color: _selectedIndex == index ? Theme.of(context).primaryColorDark : null,
  //         ),
  //         child: ListTile(
  //           leading: icon,
  //           title: Text(name,style: TextStyle(color: _selectedIndex == index ? Colors.white : Colors.white,fontSize: 14,fontWeight: FontWeight.bold),),
  //         )
  //     ),
  //   );
  // }

  // Widget getIcon(icon,index){
  //   return Icon(icon,color: _selectedIndex == index ? Colors.white : Colors.white,);
  // }

  // String getLineName(list){
  //   var name = '';
  //   for(var i in list){
  //     name += '${name.length == 0 ? '' : ','}$i';
  //   }
  //   return name;
  // }

  void _onSelectionChanged(DateRangePickerSelectionChangedArgs args) {
    setState(() {
      if (args.value is PickerDateRange) {
        _selectedDate  = '${DateFormat('dd/MM/yyyy').format(args.value.startDate)} -'
            ' ${DateFormat('dd/MM/yyyy').format(args.value.endDate ?? args.value.startDate)}';

      } else if (args.value is DateTime) {
        _selectedDate = args.value.toString();
      } else if (args.value is List<DateTime>) {
        _dateCount = args.value.length.toString();
      } else {
        _rangeCount = args.value.length.toString();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context,constraint) {
      final Map<String, dynamic> view = _applySearch(dataToShow);
      final int viewRows = (view['fixedColumnData'] is List)
          ? (view['fixedColumnData'] as List).length
          : 0;
      final int viewTotalPages = (viewRows / noOfRowsPerPage).ceil();
      return Scaffold(
          backgroundColor: const Color(0xffF8FAFB),
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            toolbarHeight: 64,
            shape: const Border(bottom: BorderSide(color: Color(0xffE6ECEE))),
            title: Row(
              children: [
                _buildTitleBlock(constraint.maxWidth >= 900),
                if (constraint.maxWidth >= 900)
                  Expanded(child: Center(child: _buildTabPill())),
              ],
            ),
            bottom: constraint.maxWidth >= 900
                ? null
                : PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 12, right: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _buildTabPill(),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12, left: 4),
                child: ElevatedButton.icon(
                  onPressed: _showDownloadDialog,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: constraint.maxWidth >= 600
                      ? const Text('Export')
                      : const SizedBox.shrink(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.symmetric(
                        horizontal: constraint.maxWidth >= 600 ? 16 : 10, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: httpError == 0
                ? Padding(
              padding: EdgeInsets.all(constraint.maxWidth < 600 ? 8 : 16),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xffE3E9EC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildToolbar(constraint, viewRows),
                    if((dataSource == null || view.isEmpty))
                      Expanded(child: Center(child: Text('There is no data in ${_selectedDate}'))),
                    if((dataSource != null || view.isNotEmpty))
                      if(graphMode == false)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if(view.isNotEmpty)
                                ScrollingTable(
                                  fixedColumn: view['fixedColumn'],
                                  fixedColumnData: filterDataByPages(data: view['fixedColumnData']),
                                  generalColumn: view['generalColumn'],
                                  generalColumnData: filterDataByPages(data: view['generalColumnData']),
                                  waterColumn: view['waterColumn'],
                                  waterColumnData: filterDataByPages(data: view['waterColumnData']),
                                  centralFilterColumn: view['centralFilterColumn'] ?? [],
                                  centralFilterColumnData: filterDataByPages(data: view['centralFilterColumnData'] ?? []),
                                  localFilterColumn: view['localFilterColumn'] ?? [],
                                  localFilterColumnData: filterDataByPages(data: view['localFilterColumnData'] ?? []),
                                  filterColumn: view['filterColumn'],
                                  filterColumnData: filterDataByPages(data: view['filterColumnData']),
                                  prePostColumn: view['prePostColumn'],
                                  prePostColumnData: filterDataByPages(data: view['prePostColumnData']),
                                  centralEcPhColumn: view['centralEcPhColumn'],
                                  centralEcPhColumnData: filterDataByPages(data: view['centralEcPhColumnData']),
                                  centralChannel1Column: view['centralChannel1Column'],
                                  centralChannel1ColumnData: filterDataByPages(data: view['centralChannel1ColumnData']),
                                  centralChannel2Column: view['centralChannel2Column'],
                                  centralChannel2ColumnData: filterDataByPages(data: view['centralChannel2ColumnData']),
                                  centralChannel3Column: view['centralChannel3Column'],
                                  centralChannel3ColumnData: filterDataByPages(data: view['centralChannel3ColumnData']),
                                  centralChannel4Column: view['centralChannel4Column'],
                                  centralChannel4ColumnData: filterDataByPages(data: view['centralChannel4ColumnData']),
                                  centralChannel5Column: view['centralChannel5Column'],
                                  centralChannel5ColumnData: filterDataByPages(data: view['centralChannel5ColumnData']),
                                  centralChannel6Column: view['centralChannel6Column'],
                                  centralChannel6ColumnData: filterDataByPages(data: view['centralChannel6ColumnData']),
                                  centralChannel7Column: view['centralChannel7Column'],
                                  centralChannel7ColumnData: filterDataByPages(data: view['centralChannel7ColumnData']),
                                  centralChannel8Column: view['centralChannel8Column'],
                                  centralChannel8ColumnData: filterDataByPages(data: view['centralChannel8ColumnData']),
                                  localEcPhColumn: view['localEcPhColumn'],
                                  localEcPhColumnData: filterDataByPages(data: view['localEcPhColumnData']),
                                  localChannel1Column: view['localChannel1Column'],
                                  localChannel1ColumnData: filterDataByPages(data: view['localChannel1ColumnData']),
                                  localChannel2Column: view['localChannel2Column'],
                                  localChannel2ColumnData: filterDataByPages(data: view['localChannel2ColumnData']),
                                  localChannel3Column: view['localChannel3Column'],
                                  localChannel3ColumnData: filterDataByPages(data: view['localChannel3ColumnData']),
                                  localChannel4Column: view['localChannel4Column'],
                                  localChannel4ColumnData: filterDataByPages(data: view['localChannel4ColumnData']),
                                  localChannel5Column: view['localChannel5Column'],
                                  localChannel5ColumnData: filterDataByPages(data: view['localChannel5ColumnData']),
                                  localChannel6Column: view['localChannel6Column'],
                                  localChannel6ColumnData: filterDataByPages(data: view['localChannel6ColumnData']),
                                  localChannel7Column: view['localChannel7Column'],
                                  localChannel7ColumnData: filterDataByPages(data: view['localChannel7ColumnData']),
                                  localChannel8Column: view['localChannel8Column'],
                                  localChannel8ColumnData: filterDataByPages(data: view['localChannel8ColumnData']),
                                  graphData: view['graphData'],
                                  showSensorReport: hasConfiguredSensors,
                                  onSequenceClicked: hasConfiguredSensors
                                      ? (sequenceName) {
                                    DateTime date1 = DateTime.now();
                                    DateTime date2 = DateTime.now();
                                    try {
                                      String dateString1 = _selectedDate.split(' - ')[0];
                                      String dateString2 = _selectedDate.split(' - ')[1];
                                      List<String> parts1 = dateString1.split('/');
                                      List<String> parts2 = dateString2.split('/');
                                      date1 = DateTime(int.parse(parts1[2]), int.parse(parts1[1]), int.parse(parts1[0]));
                                      date2 = DateTime(int.parse(parts2[2]), int.parse(parts2[1]), int.parse(parts2[0]));
                                    } catch (e) {
                                      // Fallback to now if parse fails
                                    }

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SensorGraphLog(
                                          userId: widget.userData['customerId'],
                                          controllerId: widget.userData['controllerId'],
                                          fromDate: date1,
                                          toDate: date2,
                                        ),
                                      ),
                                    );
                                  }
                                      : null,
                                ),
                            ],
                          ),
                        )
                      else
                        Expanded(
                          child: Scrollbar(
                            controller: _graphController,
                            thickness: 20,
                            interactive: true,
                            radius: const Radius.circular(50),
                            child: SingleChildScrollView(
                              controller: _graphController,
                              child: Column(
                                children: [
                                  Wrap(
                                    runSpacing: 10,
                                    children: [
                                      if(graphMode == true)
                                        if(view.isNotEmpty)
                                          for(var i in view['graphData'])
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              margin: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                  boxShadow: AppProperties.customBoxShadowLiteTheme,
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(20)
                                              ),
                                              width: MediaQuery.of(context).size.width > 500 ? 500 : MediaQuery.of(context).size.width,
                                              height: 250,
                                              child: Column(
                                                children: [
                                                  Text('${i['name']}'),
                                                  Expanded(
                                                      child: SfCartesianChart(
                                                        enableAxisAnimation: false,
                                                        plotAreaBackgroundColor: Colors.transparent,
                                                        borderColor: Colors.transparent,
                                                        borderWidth: 0,
                                                        plotAreaBorderWidth: 0,
                                                        enableSideBySideSeriesPlacement: false,
                                                        tooltipBehavior: TooltipBehavior(
                                                          enable: true,
                                                          animationDuration: 0,
                                                          canShowMarker: true,
                                                          // format: 'point.x',
                                                          textStyle: const TextStyle(color: Colors.white),
                                                          tooltipPosition: TooltipPosition.pointer,
                                                          // borderColor: Colors.red,
                                                          borderWidth: 2,
                                                          color: Colors.black,
                                                          // You can customize more tooltip settings here
                                                        ),
                                                        primaryXAxis: CategoryAxis(
                                                          isVisible: true,
                                                          rangePadding: ChartRangePadding.round,
                                                          labelPlacement: LabelPlacement.onTicks,
                                                          maximumLabels: i['data'].length,
                                                          minimum: -0.5,
                                                          maximum: (i['data']).length.toDouble(),
                                                          initialVisibleMinimum: -0.5,
                                                          initialVisibleMaximum: (i['data'])!.length <= 3 ? (i['data'])!.length.toDouble() - 0.5 : 3,
                                                        ),
                                                        primaryYAxis: const NumericAxis(
                                                          isVisible: true,
                                                          // title: AxisTitle(text: "Dur/Qty"),
                                                          minimum: 0,
                                                        ),
                                                        legend: Legend(
                                                          isVisible: true,
                                                          position: LegendPosition.bottom,
                                                          overflowMode: LegendItemOverflowMode.wrap,
                                                        ),
                                                        zoomPanBehavior: ZoomPanBehavior(
                                                          enablePanning: true,
                                                        ),
                                                        series: <CartesianSeries>[
                                                          RangeColumnSeries<dynamic, String>(
                                                              name: 'Pre',
                                                              borderRadius: BorderRadius.zero,
                                                              dataSource: (i['data']) ?? [],
                                                              width: 0.4,
                                                              color: Colors.blue.shade200,
                                                              xValueMapper: (dynamic data, _) => "${data.seqName}",
                                                              lowValueMapper: (dynamic data, _) => data.preFrom,
                                                              highValueMapper: (dynamic data, _) => data.preTo
                                                          ),
                                                          RangeColumnSeries<dynamic, String>(
                                                              name: 'Actual',
                                                              borderRadius: BorderRadius.circular(0),
                                                              dataSource: (i['data']) ?? [],
                                                              width: 0.4,
                                                              color: Colors.green,
                                                              xValueMapper: (dynamic data, _) => "${data.seqName}",
                                                              lowValueMapper: (dynamic data, _) => data.actualFrom,
                                                              highValueMapper: (dynamic data, _) => data.actualTo
                                                          ),
                                                          RangeColumnSeries<dynamic, String>(
                                                              name: 'Post',
                                                              borderRadius: BorderRadius.circular(0),
                                                              dataSource: (i['data']) ?? [],
                                                              width: 0.4,
                                                              color: Colors.blue.shade400,
                                                              xValueMapper: (dynamic data, _) => "${data.seqName}",
                                                              lowValueMapper: (dynamic data, _) => data.postFrom,
                                                              highValueMapper: (dynamic data, _) => data.postTo
                                                          ),
                                                          RangeColumnSeries<dynamic, String>(
                                                              name: 'Planned',
                                                              borderRadius: BorderRadius.circular(0),
                                                              dataSource: (i['data']) ?? [],
                                                              width: 0.4,
                                                              color: Colors.amber.shade700,
                                                              xValueMapper: (dynamic data, _) => "${data.seqName}",
                                                              lowValueMapper: (dynamic data, _) => data.plannedFrom,
                                                              highValueMapper: (dynamic data, _) => data.plannedTo
                                                          ),
                                                        ],
                                                      )
                                                  )
                                                ],
                                              ),
                                            )
                                    ],
                                  )

                                ],
                              ),
                            ),
                          ),
                        ),
                    _buildFooter(viewRows, viewTotalPages),
                  ],
                ),
              ),
            )
                : SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Network is unreachable!!'),
                  MaterialButton(
                    onPressed: ()async{
                      if(httpError != 2){
                        setState(() {
                          httpError = 2;
                        });
                        await Future.delayed(const Duration(seconds: 2));
                        getData();
                      }
                    },
                    child: httpError != 2 ? const Text('RETRY',style: TextStyle(color: Colors.white),) : loadingButtuon(),
                    color: Colors.blueGrey,
                  ),
                ],
              ),
            ),
          )
      );
    }
    );
  }

  // ───────────────────────── toolbar (search / date / filter / refresh) ─────────────────────────

  Map<String, dynamic> _applySearch(Map<String, dynamic> source) {
    if ((_searchQuery.isEmpty && _hiddenPrograms.isEmpty) || source.isEmpty) return source;
    final fixed = source['fixedColumnData'];
    if (fixed is! List) return source;
    final generalCols = source['generalColumn'];

    final knownLower = _programNames().map((e) => e.toLowerCase()).toSet();
    final hiddenLower = _hiddenPrograms.map((e) => e.toLowerCase()).toSet();

    final keep = <int>[];
    for (var i = 0; i < fixed.length; i++) {
      // program filter: hide the row only when it clearly belongs to an unchecked program
      if (hiddenLower.isNotEmpty) {
        final cells = <String>{};
        void addCell(dynamic c) {
          for (final part in '$c'.split('\n')) {
            cells.add(part.trim().toLowerCase());
          }
        }
        addCell(fixed[i]);
        final g = source['generalColumnData'];
        if (g is List && i < g.length && g[i] is List) {
          for (final c in g[i] as List) {
            addCell(c);
          }
        }
        final matched = knownLower.where(cells.contains).toList();
        if (matched.isNotEmpty && matched.every(hiddenLower.contains)) continue;
      }
      final buf = StringBuffer();
      for (final entry in source.entries) {
        final v = entry.value;
        if (entry.key.endsWith('ColumnData') && v is List && i < v.length) {
          final row = v[i];
          if (entry.key == 'generalColumnData' && row is List && generalCols is List) {
            for (var j = 0; j < row.length; j++) {
              if (j < generalCols.length && generalCols[j] == 'Status') {
                buf.write('${getStatus(row[j])['status']} ');
              } else {
                buf.write('${row[j]} ');
              }
            }
          } else {
            buf.write('$row ');
          }
        }
      }
      if (_searchQuery.isEmpty || buf.toString().toLowerCase().contains(_searchQuery)) keep.add(i);
    }

    final result = Map<String, dynamic>.from(source);
    for (final entry in source.entries) {
      if (entry.key.endsWith('ColumnData') && entry.value is List) {
        final list = entry.value as List;
        result[entry.key] = [
          for (final i in keep)
            if (i < list.length) list[i]
        ];
      }
    }
    return result;
  }

  List<String> _programNames() {
    final seen = <String>{};
    final out = <String>[];
    for (final p in program) {
      final n = '${p['programName'] ?? ''}'.trim();
      if (n.isNotEmpty && n != 'null' && seen.add(n)) out.add(n);
    }
    return out;
  }

  String _filterLabel() {
    final names = _programNames();
    final hidden = names.where(_hiddenPrograms.contains).length;
    if (names.isEmpty || hidden == 0) return 'All status';
    return '${names.length - hidden} of ${names.length} selected';
  }

  void _showProgramFilterDialog() {
    final names = _programNames();
    final temp = Set<String>.from(_hiddenPrograms);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setD) {
            final allSelected = names.every((n) => !temp.contains(n));
            return AlertDialog(
              title: const Text('Filter'),
              content: SizedBox(
                width: 320,
                child: names.isEmpty
                    ? const Text('No options available for this date range')
                    : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CheckboxListTile(
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: allSelected,
                      title: const Text('Select all',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      onChanged: (v) => setD(() {
                        if (v == true) {
                          temp.clear();
                        } else {
                          temp.addAll(names);
                        }
                      }),
                    ),
                    const Divider(height: 1),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final n in names)
                            CheckboxListTile(
                              dense: true,
                              controlAffinity: ListTileControlAffinity.leading,
                              value: !temp.contains(n),
                              title: Text(n),
                              onChanged: (v) => setD(() {
                                if (v == true) {
                                  temp.remove(n);
                                } else {
                                  temp.add(n);
                                }
                              }),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hiddenPrograms = temp;
                      selectedPages = 1;
                    });
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _toolbarChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xffDCE5E7)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.black54),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(fontSize: 13, color: Colors.black87)),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.black45),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(BoxConstraints constraint, int recordCount) {
    final bool wide = constraint.maxWidth >= 1100;
    final primary = Theme.of(context).primaryColor;
    const borderColor = Color(0xffDCE5E7);

    OutlineInputBorder inputBorder(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: c),
    );

    final searchField = SizedBox(
      height: 40,
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() {
          _searchQuery = v.trim().toLowerCase();
          selectedPages = 1;
        }),
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search program, sequence, valve, reason…',
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xff9AA8AE)),
          prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xff9AA8AE)),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                selectedPages = 1;
              });
            },
          ),
          filled: true,
          fillColor: const Color(0xffF6F9FA),
          contentPadding: EdgeInsets.zero,
          border: inputBorder(borderColor),
          enabledBorder: inputBorder(borderColor),
          focusedBorder: inputBorder(primary),
        ),
      ),
    );

    final dateChip = _toolbarChip(
      icon: Icons.calendar_today_outlined,
      label: _selectedDate.isEmpty
          ? 'Select date'
          : _selectedDate.replaceAll(' - ', '  –  '),
      onTap: _showDatePickerDialog,
    );

    final filterChip = _toolbarChip(
      icon: Icons.tune,
      label: _filterLabel(),
      onTap: _showProgramFilterDialog,
    );

    final refreshButton = InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: isLiveSyncing
          ? null
          : () async {
        await getData();
        _requestLiveSync(silent: false);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            isLiveSyncing
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : Icon(Icons.refresh_outlined,
                size: 18, color: isLiveLoaded ? Colors.green : Colors.black87),
            const SizedBox(width: 6),
            Text('Refresh',
                style: TextStyle(
                    fontSize: 13,
                    color: isLiveLoaded ? Colors.green : Colors.black87)),
          ],
        ),
      ),
    );

    Widget content;
    if (wide) {
      content = Row(
        children: [
          SizedBox(width: 380, child: searchField),
          const SizedBox(width: 10),
          dateChip,
          const SizedBox(width: 8),
          filterChip,
          const Spacer(),
          refreshButton,
        ],
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchField,
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              dateChip,
              filterChip,
              refreshButton,
            ],
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xffE3E9EC))),
      ),
      child: content,
    );
  }

  // ───────────────────────── footer (Showing x–y of z  |  Prev 1 / n Next) ─────────────────────────

  Widget _buildFooter(int total, int totalPages) {
    final int pages = totalPages < 1 ? 1 : totalPages;
    final int page = selectedPages > pages ? pages : (selectedPages < 1 ? 1 : selectedPages);
    final int from = total == 0 ? 0 : (page - 1) * noOfRowsPerPage + 1;
    final int to = (page * noOfRowsPerPage) < total ? page * noOfRowsPerPage : total;
    const mono = TextStyle(
      fontFamily: 'monospace',
      fontFamilyFallback: ['Courier New', 'Courier'],
      fontSize: 12.5,
      color: Color(0xff5F6F76),
    );

    Widget navButton(String label, IconData icon, bool leading, bool enabled, VoidCallback onTap) {
      final Color c = enabled ? const Color(0xff1F2D33) : const Color(0xffB5C0C5);
      final children = <Widget>[
        if (leading) Icon(icon, size: 16, color: c),
        Text(label, style: TextStyle(fontSize: 13, color: c)),
        if (!leading) Icon(icon, size: 16, color: c),
      ];
      return InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: enabled ? onTap : null,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xffE3E9EC)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: children),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xffE3E9EC))),
      ),
      child: Row(
        children: [
          Text('Showing $from–$to of $total', style: mono),
          const Spacer(),
          navButton('Prev', Icons.chevron_left, true, page > 1, () {
            setState(() => selectedPages = page - 1);
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text('$page / $pages',
                style: mono.copyWith(color: const Color(0xff1F2D33))),
          ),
          navButton('Next', Icons.chevron_right, false, page < pages, () {
            setState(() => selectedPages = page + 1);
          }),
        ],
      ),
    );
  }

  void _showDatePickerDialog() {
    showDialog(context: context, builder: (context){
      return AlertDialog(
        title: const Text('Date Picker'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter stateSetter) {
            return SizedBox(
              width: 200,
              height: 250,
              child: SfDateRangePicker(
                onSelectionChanged: _onSelectionChanged,
                selectionMode: DateRangePickerSelectionMode.range,
                initialSelectedRange: PickerDateRange(
                    DateTime.now(),
                    DateTime.now()
                ),
              ),
            );
          },
        ),
        actions: [
          CustomMaterialButton(
            title: 'Cancel',
            outlined: true,
          ),
          CustomMaterialButton(
            onPressed: ()async{
              Navigator.pop(context);
              getDialog(context);
              getData();
              setState(() {
                for(var sortItem = 0;sortItem < _irrigationOptionWise.length;sortItem++){
                  if(_selectedIndex == sortItem){
                    _irrigationOptionWise[sortItem][1] = true;
                  }else{
                    _irrigationOptionWise[sortItem][1] = false;
                  }
                }
              });
              if(mounted){
                Navigator.pop(context);
              }
            },
          ),
        ],
      );
    });
  }

  Widget _buildTitleBlock(bool wide) {
    final primary = Theme.of(context).primaryColor;
    final iconBox = Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.water_drop_outlined, color: Colors.white, size: 20),
    );
    final liveBadge = isLiveLoaded
        ? Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green, width: 0.8),
      ),
      child: const Text('LIVE',
          style: TextStyle(
              color: Colors.green,
              fontSize: 10,
              fontWeight: FontWeight.bold)),
    )
        : const SizedBox.shrink();

    final dateText = Text(
      _selectedDate.replaceAll(' - ', '  –  '),
      style: const TextStyle(fontSize: 12, color: Colors.black45),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconBox,
        const SizedBox(width: 10),
        wide
            ? Row(
          children: [
            const Text('Irrigation Log',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87)),
            const SizedBox(width: 10),
            dateText,
            liveBadge,
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('Irrigation Log',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87)),
              liveBadge,
            ]),
            dateText,
          ],
        ),
      ],
    );
  }

  Widget _buildTabPill() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xffF1F4F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xffE3E9EC)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < _irrigationOptionWise.length; i++)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _onTabSelected(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: _irrigationOptionWise[i][1] == true
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _irrigationOptionWise[i][1] == true
                      ? const [
                    BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 4,
                        offset: Offset(0, 1))
                  ]
                      : null,
                ),
                child: Text(
                  '${_irrigationOptionWise[i][0]}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: _irrigationOptionWise[i][1] == true
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: _irrigationOptionWise[i][1] == true
                        ? Colors.black87
                        : Colors.black54,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onTabSelected(int i) {
    getDialog(context);
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _selectedIndex = i;
        for (var j = 0; j < _irrigationOptionWise.length; j++) {
          _irrigationOptionWise[j][1] = (j == i);
        }
        if (_irrigationOptionWise[0][1] == true) {
          dataToShow = irrigationParameterArray.editDateWise(dataSource, date);
        } else if (_irrigationOptionWise[1][1] == true) {
          dataToShow = irrigationParameterArray.editProgramWise(dataSource, program);
        } else if (_irrigationOptionWise[2][1] == true) {
          dataToShow = irrigationParameterArray.editLineWise(dataSource, line);
        } else if (_irrigationOptionWise[3][1] == true) {
          dataToShow = irrigationParameterArray.editValveWise(dataSource, valve);
        } else if (_irrigationOptionWise[4][1] == true) {
          dataToShow = irrigationParameterArray.editStatusWise(dataSource, status);
        }
      });
      Navigator.pop(context);
    });
  }

  void _showDownloadDialog() {
    var fileName = 'file';
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Give Name For Your File'),
          content: TextFormField(
            initialValue: fileName,
            onChanged: (value) => fileName = value,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const AlertDialog(
                    title: Text('Saving Excel...'),
                    content: SizedBox(
                        height: 50,
                        child: Center(child: CircularProgressIndicator())),
                  ),
                );
                bool result = await generateExcel(_applySearch(dataToShow), fileName);
                if (mounted) Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(result
                          ? '$fileName.xlsx downloaded successfully'
                          : 'Failed to save $fileName.xlsx')));
                }
              },
              child: const Text('Download Excel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006573),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const AlertDialog(
                    title: Text('Generating PDF...'),
                    content: SizedBox(
                        height: 50,
                        child: Center(child: CircularProgressIndicator())),
                  ),
                );
                bool result = await generatePdf(_applySearch(dataToShow), fileName);
                if (mounted) Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(result
                          ? '$fileName.pdf downloaded successfully'
                          : 'Failed to generate PDF')));
                }
              },
              child: const Text('Download PDF'),
            ),
          ],
        );
      },
    );
  }

  Widget myButtons({required String name,required void Function() onTap,double? radius,double? verticalPadding,int? index}){
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: verticalPadding ?? 10,horizontal: 10),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius ?? 5),
            color: index != null ? (index == _irrigationOptionWise.indexWhere((element) => element[1] == true) ? Theme.of(context).primaryColor : null) : Theme.of(context).primaryColor
        ),
        child: Text(name,style: TextStyle(color: index != null ? (index == _irrigationOptionWise.indexWhere((element) => element[1] == true) ? Colors.white : Colors.black87) : Colors.white,fontSize: 13,fontWeight: FontWeight.w200),),
      ),
    );
  }

  Widget getTableOptionSelector(List data){
    if(data[1] == true){
      return SizedBox(
        width: 100,
        height: 40,
        child: Stack(
          children: [
            SvgPicture.asset(
              'assets/images/tableOptionSelected.svg',
              color: Theme.of(context).primaryColor,
            ),
            Positioned(
              top: 15,
              left: 20,
              child: Text('${data[0]}',style: const TextStyle(color: Colors.white),),
            )
          ],
        ),
      );
    }else{
      return SizedBox(
        width: 150,
        height: 50,
        child: Center(
          child: Text('${data[0]}',style: const TextStyle(color: Colors.black)),
        ),
      );
    }
  }

  void setOriginalToDuplicateParameter({required List<GeneralParameterModel> originalParameterList,required List<GeneralParameterModel> duplicateParameterList}){
    setState(() {
      for(var i = 0;i < originalParameterList.length;i++){
        duplicateParameterList[i].show = originalParameterList[i].show;
      }
    });
  }

  void sideSheet(constraints) {

    for(var i = 0;i < date.length;i++){
      dateDuplicate[i]['show'] = date[i]['show'];
    }
    for(var i = 0;i < line.length;i++){
      lineDuplicate[i]['show'] = line[i]['show'];
    }
    for(var i = 0;i < valve.length;i++){
      valveDuplicate[i]['show'] = valve[i]['show'];
    }
    for(var i = 0;i < program.length;i++){
      programDuplicate[i]['show'] = program[i]['show'];
    }
    for(var i = 0;i < status.length;i++){
      statusDuplicate[i]['show'] = status[i]['show'];
    }
    showGeneralDialog(
      barrierLabel: "Side sheet",
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 300),
      context: context,
      pageBuilder: (context, animation1, animation2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            elevation: 15,
            color: Colors.transparent,
            borderRadius: BorderRadius.zero,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter stateSetter) {
                return SizedBox(
                  width: constraints.maxWidth < 600 ? constraints.maxWidth * 0.7 : constraints.maxWidth * 0.2,
                  child: Scaffold(
                    floatingActionButton: Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: AppProperties.customBoxShadowLiteTheme
                      ),
                      height: 60,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          MaterialButton(
                            onPressed: (){
                              Navigator.pop(context);
                            },
                            child: const Text("Cancel",style: TextStyle(color: Colors.white),),
                            color: Colors.red,
                          ),
                          MaterialButton(
                            onPressed: (){
                              stateSetter(() {
                                // irrigationParameterArray.editParameterList(
                                //     generalParameterListDuplicate: irrigationParameterArrayDuplicate.generalParameterList,
                                //     waterParameterListDuplicate: irrigationParameterArrayDuplicate.waterParameterList,
                                //     centralEcPhParameterListDuplicate: irrigationParameterArrayDuplicate.centralEcPhParameterList,
                                //     centralChannel1ParameterListDuplicate: irrigationParameterArrayDuplicate.centralChannel1ParameterList,
                                //     centralChannel2ParameterListDuplicate: irrigationParameterArrayDuplicate.centralChannel2ParameterList,
                                //     centralChannel3ParameterListDuplicate: irrigationParameterArrayDuplicate.centralChannel3ParameterList,
                                //     centralChannel4ParameterListDuplicate: irrigationParameterArrayDuplicate.centralChannel4ParameterList,
                                //     centralChannel5ParameterListDuplicate: irrigationParameterArrayDuplicate.centralChannel5ParameterList,
                                //     centralChannel6ParameterListDuplicate: irrigationParameterArrayDuplicate.centralChannel6ParameterList,
                                //     centralChannel7ParameterListDuplicate: irrigationParameterArrayDuplicate.centralChannel7ParameterList,
                                //     centralChannel8ParameterListDuplicate: irrigationParameterArrayDuplicate.centralChannel8ParameterList
                                // );
                                if(_irrigationOptionWise[0][1] == true){
                                  setState(() {
                                    for(var i = 0;i < dateDuplicate.length;i++){
                                      date[i]['show'] = dateDuplicate[i]['show'];
                                    }
                                    dataToShow = irrigationParameterArray.editDateWise(dataSource, date);
                                  });
                                }else if(_irrigationOptionWise[1][1] == true){
                                  setState(() {
                                    for(var i = 0;i < programDuplicate.length;i++){
                                      program[i]['show'] = programDuplicate[i]['show'];
                                    }
                                    dataToShow = irrigationParameterArray.editProgramWise(dataSource, program);
                                  });
                                }else if(_irrigationOptionWise[2][1] == true){
                                  setState(() {
                                    for(var i = 0;i < lineDuplicate.length;i++){
                                      line[i]['show'] = lineDuplicate[i]['show'];
                                    }
                                    dataToShow = irrigationParameterArray.editLineWise(dataSource, line);
                                  });
                                }else if(_irrigationOptionWise[3][1] == true){
                                  setState(() {
                                    for(var i = 0;i < valveDuplicate.length;i++){
                                      valve[i]['show'] = valveDuplicate[i]['show'];
                                    }
                                    dataToShow = irrigationParameterArray.editValveWise(dataSource, valve);
                                  });
                                }
                                else if(_irrigationOptionWise[4][1] == true){
                                  setState(() {
                                    for(var i = 0;i < statusDuplicate.length;i++){
                                      status[i]['show'] = statusDuplicate[i]['show'];
                                    }
                                    dataToShow = irrigationParameterArray.editStatusWise(dataSource, status);
                                  });
                                }
                              });
                              Navigator.pop(context);
                            },
                            child: const Text("OK",style: TextStyle(color: Colors.white)),
                            color: Theme.of(context).primaryColor,
                          )
                        ],
                      ),
                    ),
                    floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
                    body: Container(
                      padding: const EdgeInsets.all(15),
                      // margin: EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.zero,
                      ),
                      height: double.infinity,
                      width: constraints.maxWidth < 600 ? constraints.maxWidth * 0.7 : constraints.maxWidth * 0.2,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if(_irrigationOptionWise[0][1] == true)
                              Column(
                                children: [
                                  const SizedBox(height: 40,),
                                  Text('Filter Date',style: headingStyleInSheet,),
                                  for(var i in dateDuplicate)
                                    Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 5),
                                      width: 250,
                                      child: ListTile(
                                        leading: const Icon(Icons.commit,color: Colors.blueGrey,),
                                        title: Text('${i['name']}',style: const TextStyle(fontSize: 12),),
                                        trailing: Checkbox(
                                          value: i['show'],
                                          onChanged: (value) {
                                            stateSetter(() {
                                              i['show'] = value!;
                                            });
                                          },

                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 10,)
                                ],
                              ),
                            if(_irrigationOptionWise[1][1] == true)
                              Column(
                                children: [
                                  Text('Filter Program',style: headingStyleInSheet),
                                  for(var i in programDuplicate)
                                    Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 5),
                                      width: 250,
                                      child: ListTile(
                                        leading: const Icon(Icons.commit,color: Colors.blueGrey,),
                                        title: Text('${i['programName']}',style: const TextStyle(fontSize: 12),),
                                        trailing: Checkbox(
                                          value: i['show'],
                                          onChanged: (value) {
                                            stateSetter(() {
                                              i['show'] = value!;
                                            });
                                          },

                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 10,)
                                ],
                              ),
                            if(_irrigationOptionWise[2][1] == true)
                              Column(
                                children: [
                                  Text('Filter Line',style: headingStyleInSheet),
                                  for(var i in lineDuplicate)
                                    Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 5),
                                      width: 250,
                                      child: ListTile(
                                        leading: const Icon(Icons.commit,color: Colors.blueGrey,),
                                        title: Text('${i['lineName']}',style: const TextStyle(fontSize: 12),),
                                        trailing: Checkbox(
                                          value: i['show'],
                                          onChanged: (value) {
                                            stateSetter(() {
                                              i['show'] = value!;
                                            });
                                          },

                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 10,)
                                ],
                              ),
                            if(_irrigationOptionWise[3][1] == true)
                              Column(
                                children: [
                                  Text('Filter Valve',style: headingStyleInSheet),
                                  for(var i in valveDuplicate)
                                    Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 5),
                                      width: 250,
                                      child: ListTile(
                                        leading: const Icon(Icons.commit,color: Colors.blueGrey,),
                                        title: Text('${i['name']}',style: const TextStyle(fontSize: 12),),
                                        trailing: Checkbox(
                                          value: i['show'],
                                          onChanged: (value) {
                                            stateSetter(() {
                                              i['show'] = value!;
                                            });
                                          },

                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 10,)
                                ],
                              ),
                            if(_irrigationOptionWise[4][1] == true)
                              Column(
                                children: [
                                  Text('Filter Status',style: headingStyleInSheet),
                                  for(var i in statusDuplicate)
                                    Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 5),
                                      width: 250,
                                      child: ListTile(
                                        leading: const Icon(Icons.commit,color: Colors.blueGrey,),
                                        title: Text('${getStatus(i['name'])['status']}',style: const TextStyle(fontSize: 12),),
                                        trailing: Checkbox(
                                          value: i['show'],
                                          onChanged: (value) {
                                            stateSetter(() {
                                              i['show'] = value!;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 10,)
                                ],
                              ),
                            const SizedBox(
                              height: 50,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
      transitionBuilder: (context, animation1, animation2, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: const Offset(0, 0)).animate(animation1),
          child: child,
        );
      },
    );
  }

  Widget getChannelFilter({required List<GeneralParameterModel> parameterList,required int channelNo}){
    return StatefulBuilder(
        builder: (BuildContext context, StateSetter stateSetter){
          return Column(
            children: [
              SizedBox(
                width: 250,
                height: 60,
                child: ListTile(
                  title: Text('<C - CH$channelNo> Parameter',style: const TextStyle(fontWeight: FontWeight.bold),),
                  leading: Checkbox(
                    value: parameterList[parameterList.length - 1].show,
                    onChanged: (bool? value) {
                      stateSetter(() {
                        parameterList[parameterList.length - 1].show = value!;
                        for(var p in parameterList){
                          p.show = value;
                        }
                      });

                    },
                  ),
                ),
              ),
              for(var i in parameterList)
                if(i.payloadKey != 'overAll')
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: 250,
                    child: ListTile(
                      leading: const Icon(Icons.adb_outlined,color: Colors.blueGrey,),
                      title: Text('${i.uiKey}',style: const TextStyle(fontSize: 12),),
                      trailing: Checkbox(
                        value: i.show,
                        onChanged: (value) {
                          stateSetter(() {
                            i.show = value!;
                          });
                        },

                      ),
                    ),
                  ),
              const SizedBox(
                height: 10,
              ),
            ],
          );
        }
    );

  }

  List<dynamic> filterDataByPages({required data}){
    List<dynamic> slicingList = [];
    int from = (selectedPages * noOfRowsPerPage) - 20;
    int to = (selectedPages * noOfRowsPerPage);
    if(data.length < to){
      to = data.length;
    }
    for(var i = from;i < to;i++){
      slicingList.add(data[i]);
    }
    return slicingList;
  }

  Widget datePickerBuilder(
      BuildContext context, dynamic Function(DateRange?) onDateRangeChanged,
      [bool doubleMonth = true]) =>
      DateRangePickerWidget(
        maxDate: DateTime.now(),
        theme: kTheme1,
        height: 400,
        doubleMonth: false,
        maximumDateRangeLength: 100,
        quickDateRanges: [
          // QuickDateRange(dateRange: null, label: "Remove date range"),
          // QuickDateRange(
          //   label: 'Last 3 days',
          //   dateRange: DateRange(
          //     DateTime.now().subtract(const Duration(days: 3)),
          //     DateTime.now(),
          //   ),
          // ),
          // QuickDateRange(
          //   label: 'Last 7 days',
          //   dateRange: DateRange(
          //     DateTime.now().subtract(const Duration(days: 7)),
          //     DateTime.now(),
          //   ),
          // ),
          // QuickDateRange(
          //   label: 'Last 30 days',
          //   dateRange: DateRange(
          //     DateTime.now().subtract(const Duration(days: 30)),
          //     DateTime.now(),
          //   ),
          // ),
          // QuickDateRange(
          //   label: 'Last 90 days',
          //   dateRange: DateRange(
          //     DateTime.now().subtract(const Duration(days: 90)),
          //     DateTime.now(),
          //   ),
          // ),
          // QuickDateRange(
          //   label: 'Last 180 days',
          //   dateRange: DateRange(
          //     DateTime.now().subtract(const Duration(days: 180)),
          //     DateTime.now(),
          //   ),
          // ),
        ],
        minimumDateRangeLength: 3,
        initialDateRange: selectedDateRange,
        initialDisplayedDate: selectedDateRange?.start ?? DateTime(2023, 11, 20),
        onDateRangeChanged: onDateRangeChanged,
      );
}

void getDialog(context){
  showDialog(
      context: context,
      builder: (BuildContext context){
        return const AlertDialog(
          content: Row(
            spacing: 20,
            children: [
              CircularProgressIndicator(),
              Text('Please wait...')
            ],
          ),
        );
      }
  );
}

const CalendarTheme kTheme1 = CalendarTheme(
  selectedColor: Color(0xff10E196),
  dayNameTextStyle: TextStyle(color: Colors.black45, fontSize: 10),
  inRangeColor: Color(0xFFDFFEF3),
  inRangeTextStyle: TextStyle(color: Color(0xff006943)),
  selectedTextStyle: TextStyle(color: Colors.white),
  todayTextStyle: TextStyle(fontWeight: FontWeight.bold),
  defaultTextStyle: TextStyle(color: Colors.black, fontSize: 12),
  radius: 10,
  tileSize: 40,
  disabledTextStyle: TextStyle(color: Colors.grey),
);
class _ChartData {
  _ChartData(this.x, this.y,this.z);

  final String x;
  final double y;
  final String z;
}

Widget getTableHeader(name,flex){
  return Expanded(
      flex: flex,
      child: Container(
        // color: Colors.green.shade50,
        height: 40,
        child: Center(
          child: Text('$name',style: const TextStyle(fontSize: 14,fontWeight: FontWeight.w900),),
        ),
      )
  );
}

Widget getTableRow(name,flex){
  return Expanded(
      flex: flex,
      child: Container(
        // color: Colors.green.shade50,
        height: 40,
        child: Center(
          child: Text('$name',style: const TextStyle(fontSize: 13,fontWeight: FontWeight.w500),),
        ),
      )
  );
}
Widget getTableRowLinearIndicater(seting,flex){
  return Expanded(
    flex: flex,
    child: ListTile(
      title: Text('${seting['output']}',style: const TextStyle(fontSize: 12,fontWeight: FontWeight.w500),),
      subtitle:  LinearProgressIndicator(
        backgroundColor: Colors.grey.shade300,
        color: const Color(0xff10E196),
        minHeight: 7,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        // value: timeToSeconds(name) as double, // Update this value to reflect loading progress
        value: timeToSeconds(seting), // Update this value to reflect loading progress
      ),
    ),
  );
}
double timeToSeconds(dynamic timeString) {
  List<String> input = timeString['input'].split(':');
  List<String> output = timeString['output'].split(':');
  int hours = int.parse(input[0]);
  int minutes = int.parse(input[1]);
  int seconds = int.parse(input[2]);
  int hours1 = int.parse(output[0]);
  int minutes1 = int.parse(output[1]);
  int seconds1 = int.parse(output[2]);
  var total = hours * 3600 + minutes * 60 + seconds;
  var total1 = hours1 * 3600 + minutes1 * 60 + seconds1;
  return total1/total;
}

Widget chartColorInformation(String title,List<Color> color,textColor){
  return Row(
    children: [
      Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
                colors: [
                  ...color
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight
            )
        ),

      ),
      const SizedBox(width: 10,),
      Text(title,style: const TextStyle(fontSize: 14,fontWeight: FontWeight.w900,color: Colors.black),),
    ],
  );
}
double convertTimeStringToHours(String timeString) {
  List<String> parts = timeString.split(':');
  int hours = int.parse(parts[0]);
  int minutes = int.parse(parts[1]);
  int seconds = int.parse(parts[2]);

  double totalHours = hours + (minutes / 60) + (seconds / 3600);
  return totalHours;
}
TextStyle headingStyleInSheet = const TextStyle(fontSize: 14,fontWeight: FontWeight.bold);

Widget loadingButtuon(){
  return const SizedBox(
    width: 20,
    height: 20,
    child: LoadingIndicator(
      colors: [
        Colors.white,
        Colors.white,
      ],
      indicatorType: Indicator.ballPulse,
    ),
  );
}