
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/reset_AccumalationModel.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';
import '../../services/mqtt_service.dart';
import '../../utils/environment.dart';
import '../../utils/snack_bar.dart';

class ResetAccumalationScreen extends StatefulWidget {
  const ResetAccumalationScreen(
      {Key? key,
        required this.userId,
        required this.createUser,
        required this.controllerId,
        required this.deviceID});
  final userId, controllerId, deviceID,createUser;

  @override
  State<ResetAccumalationScreen> createState() => _ResetAccumalationScreenState();
}

class _ResetAccumalationScreenState extends State<ResetAccumalationScreen>
    with SingleTickerProviderStateMixin {
  // late TabController _tabController;
  ResetModel _resetModel = ResetModel();
  int tabclickindex = 0;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    fetchData();
    Request();
  }

  Future<void> fetchData() async {
    try{
      final Repository repository = Repository(HttpService());
      var getUserDetails = await repository.getresetAccumulation({
        "userId": widget.userId,
        "controllerId": widget.controllerId
      });

      if (getUserDetails.statusCode == 200) {
        print("body getUserDetails.body:${getUserDetails.body}");
        setState(() {
          var jsonData = jsonDecode(getUserDetails.body);
          _resetModel = ResetModel.fromJson(jsonData);
        });
      } else {
        //_showSnackBar(response.body);
      }
    }
    catch (e, stackTrace) {
      print(' Error overAll getData => ${e.toString()}');
      print(' trace overAll getData  => ${stackTrace}');
    }
  }
  createUserSentAndReceivedMessageManually(String hw) async {
    try{
      final Repository repository = Repository(HttpService());
      var getUserDetails = await repository.sendManualOperationToServer(
          {"userId": widget.userId, "controllerId": widget.controllerId, "messageStatus": "Factory Reset", "hardware": hw, "createUser": widget.createUser,}
      );
    }
    catch (e, stackTrace) {
      print(' Error overAll getData => ${e.toString()}');
      print(' trace overAll getData  => ${stackTrace}');
    }
  }




  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final groups = _resetModel.data?.accumulation;
    final hasData = _resetModel.code == 200 && groups != null && groups.isNotEmpty;

    return Scaffold(
       appBar: AppBar(
         title: const Text('Factory Reset'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: hasData
                  ? DefaultTabController(
                length: groups.length,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: TabBar(
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        indicatorColor: colors.primary,
                        labelColor: colors.primary,
                        unselectedLabelColor: colors.onSurfaceVariant,
                        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                        tabs: [
                          for (final group in groups)
                            Tab(text: '${group.name}'),
                        ],
                        onTap: (value) {
                          setState(() {
                            tabclickindex = value;
                            changeval(value);
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: Form(
                        key: _formKey,
                        child: TabBarView(
                          children: [
                            for (final group in groups)
                              buildTab(group.list),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  : const Center(child: Text('Currently No data Available')),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.error,
                    foregroundColor: colors.onError,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => _showMyDialog(context),
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Factory Reset'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMyDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Do you want to Reset All data?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the alert dialog
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                FResetAll();
                Navigator.of(context).pop(); // Close the alert dialog
              },
            ),
          ],
        );
      },
    );
  }
  double Changesize(int? count, int val) {
    count ??= 0;
    double size = (count * val).toDouble();
    return size;
  }
  changeval(int Selectindexrow) {}
  Widget buildTab(List<ListElement>? listOfValue) {
    final colors = Theme.of(context).colorScheme;
    final items = listOfValue ?? [];
    if (items.isEmpty) {
      return const Center(child: Text('Currently No data Available'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 14.0;
        const horizontalPadding = 16.0;
        final available = constraints.maxWidth - horizontalPadding * 2;
        final columns = available >= 1000 ? 3 : available >= 620 ? 2 : 1;
        final cardWidth = (available - gap * (columns - 1)) / columns;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final item in items)
                SizedBox(
                  width: cardWidth,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.outlineVariant),
                      boxShadow: [
                        BoxShadow(
                          color: colors.shadow.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colors.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.water_drop_outlined,
                                  color: colors.onPrimaryContainer),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${item.name}',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: colors.onSurface,
                                      )),
                                  const SizedBox(height: 3),
                                  Text('Sno: ${item.sNo}',
                                      style: TextStyle(color: colors.onSurfaceVariant,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(child: _accumulationMetric(
                              'Daily Accumalation',
                              '${item.todayCumulativeFlow}',
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _accumulationMetric(
                              'Total Accumalation',
                              '${item.totalCumulativeFlow}',
                            )),
                          ],
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => reset(item.sNo!),
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Reset'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.primary,
                              side: BorderSide(color: colors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _accumulationMetric(String label, String value) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11,
              color: colors.onSurfaceVariant)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 17,
              fontWeight: FontWeight.w700, color: colors.onSurface)),
        ],
      ),
    );
  }

  updateradiationset() async {
    try{
      final Repository repository = Repository(HttpService());
      var getUserDetails = await repository.updateresetAccumulation({
        "userId": widget.userId,
        "controllerId": widget.controllerId,
        "modifyUser": widget.userId
      });

      // String payLoadFinal = jsonEncode({
      //   "2900": [
      //     {"2901": body},
      //   ]
      // });
      // MQTTManager().publish( payLoadFinal, 'AppToFirmware/${widget.deviceID}');
    }
    catch (e, stackTrace) {
      print(' Error overAll getData => ${e.toString()}');
      print(' trace overAll getData  => ${stackTrace}');
    }
  }


  Request(){
    String payLoadFinal = jsonEncode({
      "5300":
      {"5301": "1"},
    });
    MqttService().topicToPublishAndItsMessage(payLoadFinal, "${Environment.mqttPublishTopic}/${widget.deviceID}");


  }

  void reset(double Srno) async{
    String payLoadFinal = jsonEncode({
      "5400":
      {"5401": '${Srno},1;'},
    });

    MqttService().topicToPublishAndItsMessage(payLoadFinal, "${Environment.mqttPublishTopic}/${widget.deviceID}");
    createUserSentAndReceivedMessageManually(payLoadFinal);
    GlobalSnackBar.show(context, 'Request send', 200);
    await Future.delayed(const Duration(seconds: 2));
    fetchData();
  }
  ResetAll(List<Accumulation>? data)   {
    String restsrn = '';

    for (var j = 0; j < data!.length; j++) {
      restsrn += "${data[j].list?[0].sNo},1;";
    }
    Map<String, dynamic> payLoadFinal = {
      "5400":
      {"5401": restsrn}
    };

    MqttService().topicToPublishAndItsMessage(jsonEncode(payLoadFinal), "${Environment.mqttPublishTopic}/${widget.deviceID}");
    createUserSentAndReceivedMessageManually(jsonEncode(payLoadFinal));
  }
  FResetAll()   {
    String payLoadFinal = jsonEncode({
      "5300":
      {"5301": "2"},
    });
    MqttService().topicToPublishAndItsMessage(payLoadFinal, "${Environment.mqttPublishTopic}/${widget.deviceID}");
    createUserSentAndReceivedMessageManually(payLoadFinal);
  }
}
