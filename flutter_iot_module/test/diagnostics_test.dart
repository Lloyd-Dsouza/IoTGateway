import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_iot_module/bridge/bridge_handler.dart';
import 'package:flutter_iot_module/bridge/bridge_log.dart';
import 'package:flutter_iot_module/diagnostics/diagnostics_screen.dart';
import 'package:flutter_iot_module/simulator/device_simulator.dart';

void main() {
  testWidgets('diagnostics shows device IDs for successful and failed calls',
      (tester) async {
    final log = BridgeLog();
    final simulator = DeviceSimulator();
    final id = simulator.listDevices().first.id;
    final handler = BridgeHandler(
      simulator: simulator,
      log: log,
      latency: Duration.zero,
    );

    String request(String method, Map<String, dynamic> params) => jsonEncode({
      'requestId': 'test',
      'method': method,
      'params': params,
    });

    await tester.runAsync(() async {
      final response = jsonDecode(
        await handler.handle(request('device.get', {'deviceId': id})),
      ) as Map<String, dynamic>;
      expect(response.containsKey('v'), isFalse);
      expect(response.containsKey('ok'), isFalse);
      await expectLater(
        handler.handle(request('device.get', {'deviceId': 'missing'})),
        throwsA(isA<PlatformException>()),
      );
      await handler.handle(request('bridge.status', {}));
    });

    await tester.pumpWidget(MaterialApp(home: DiagnosticsScreen(log: log)));
    expect(find.text(id), findsOneWidget);
    expect(find.text('missing'), findsOneWidget);
    expect(find.text('No device'), findsOneWidget);
    expect(find.text('DEVICE_NOT_FOUND'), findsOneWidget);
  });
}
