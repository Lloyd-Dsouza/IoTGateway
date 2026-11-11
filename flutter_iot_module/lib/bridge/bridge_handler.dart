import 'dart:convert';

import 'package:flutter/services.dart';

import '../simulator/device_simulator.dart';
import 'bridge_dispatcher.dart';
import 'bridge_exception.dart';
import 'bridge_log.dart';

class BridgeHandler {
  BridgeHandler({
    required this.simulator,
    required this.log,
    this.latency = const Duration(milliseconds: 150),
  });

  final DeviceSimulator simulator;
  final BridgeLog log;
  final Duration latency;

  Future<String> handle(String requestJson) async {
    final stopwatch = Stopwatch()..start();
    var method = 'unknown';
    String? deviceId;

    try {
      final request = _decode(requestJson);

      final rawMethod = request['method'];
      method = rawMethod is String ? rawMethod : '';
      final rawParams = request['params'];
      final params = rawParams is Map
          ? rawParams.cast<String, dynamic>()
          : <String, dynamic>{};
      final rawDeviceId = params['deviceId'];
      if (rawDeviceId is String && rawDeviceId.isNotEmpty) {
        deviceId = rawDeviceId;
      }

      await Future<void>.delayed(latency);

      final data = BridgeDispatcher(
        simulator: simulator,
        log: log,
      ).dispatch(method, params);

      log.add(
        method: method,
        deviceId: deviceId,
        ok: true,
        latencyMs: stopwatch.elapsedMilliseconds,
      );
      return jsonEncode({'requestId': request['requestId'], 'data': data});
    } on BridgeException catch (e) {
      log.add(
        method: method,
        deviceId: deviceId,
        ok: false,
        latencyMs: stopwatch.elapsedMilliseconds,
        errorCode: e.code,
      );
      throw PlatformException(code: e.code, message: e.message);
    }
  }

  Map<String, dynamic> _decode(String json) {
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } on Object {
      throw const BridgeException(
        'MALFORMED_REQUEST',
        'Request is not a valid JSON object.',
      );
    }
  }
}
