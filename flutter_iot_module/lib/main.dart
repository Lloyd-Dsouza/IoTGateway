import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_iot_module/bridge/bridge_handler.dart';
import 'package:flutter_iot_module/bridge/bridge_log.dart';
import 'package:flutter_iot_module/diagnostics/diagnostics_screen.dart';
import 'package:flutter_iot_module/simulator/device_simulator.dart';

const _channel = MethodChannel('com.lloyd.iot/commands');

final BridgeLog _log = BridgeLog();
final BridgeHandler _handler = BridgeHandler(simulator: DeviceSimulator(), log: _log);

@pragma('vm:entry-point')
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _channel.setMethodCallHandler(_onCall);
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: DiagnosticsScreen(log: _log),
  ));
}

Future<dynamic> _onCall(MethodCall call) async {
  if (call.method != 'rpc') throw MissingPluginException();
  return _handler.handle(call.arguments as String);
}