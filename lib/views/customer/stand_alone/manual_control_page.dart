import 'package:flutter/material.dart';
import '../../../models/customer/site_model.dart';
import 'stand_alone_narrow.dart';
import 'stand_alone_wide.dart';

class ManualControlPage extends StatelessWidget {
  final int siteId;
  final int controllerId;
  final int customerId;
  final int userId;
  final String deviceId;
  final void Function(String msg) callbackFunction;
  final MasterControllerModel masterData;

  const ManualControlPage({
    super.key,
    required this.siteId,
    required this.controllerId,
    required this.customerId,
    required this.userId,
    required this.deviceId,
    required this.callbackFunction,
    required this.masterData,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          return StandAloneWide(
            siteId: siteId,
            controllerId: controllerId,
            customerId: customerId,
            userId: userId,
            deviceId: deviceId,
            callbackFunction: callbackFunction,
            masterData: masterData,
          );
        } else {
          return StandAloneNarrow(
            siteId: siteId,
            controllerId: controllerId,
            customerId: customerId,
            userId: userId,
            deviceId: deviceId,
            callbackFunction: callbackFunction,
            masterData: masterData,
          );
        }
      },
    );
  }
}
