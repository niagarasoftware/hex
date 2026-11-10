import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:hex/utils/constants.dart';

MqttClient createMqttClient(String server, String clientId) {
  final client = MqttBrowserClient(server, clientId);
  client.websocketProtocols = ['mqtt'];
  client.port = AppConstants.mqttWebPort;
  return client;
}
