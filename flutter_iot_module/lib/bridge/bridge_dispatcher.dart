import '../simulator/device_simulator.dart';
import 'bridge_exception.dart';
import 'bridge_log.dart';

class BridgeDispatcher {
  BridgeDispatcher({required this.simulator, required this.log});

  final DeviceSimulator simulator;
  final BridgeLog log;

  Map<String, dynamic> dispatch(String method, Map<String, dynamic> params) {
    switch (method) {
      case 'bridge.status':
        return {'status': 'ready', 'messageCount': log.messageCount};

      case 'devices.list':
        return {
          'devices': simulator.listDevices().map((d) => d.toJson()).toList(),
        };

      case 'device.get':
        return {
          'device': simulator.getDevice(_string(params, 'deviceId')).toJson(),
        };

      case 'device.sendCommand':
        return _sendCommand(params);

      case 'device.setSamplingRate':
        final device = simulator.setSamplingRate(
          _string(params, 'deviceId'),
          _int(params, 'rateSeconds'),
        );
        return {
          'deviceId': device.id,
          'appliedRateSeconds': device.samplingRateSeconds,
        };

      default:
        throw BridgeException('UNKNOWN_METHOD', 'Unknown method "$method".');
    }
  }

  Map<String, dynamic> _sendCommand(Map<String, dynamic> params) {
    final id = _string(params, 'deviceId');
    final command = _string(params, 'command');
    final value = params['value'];

    switch (command) {
      case 'setPower':
        if (value is! bool) {
          throw const BridgeException(
            'INVALID_VALUE',
            'setPower needs a true/false value.',
          );
        }
        return {'device': simulator.setPower(id, value).toJson()};

      case 'setTargetTemperature':
        if (value is! num) {
          throw const BridgeException(
            'INVALID_VALUE',
            'setTargetTemperature needs a number.',
          );
        }
        return {
          'device': simulator
              .setTargetTemperature(id, value.toDouble())
              .toJson(),
        };

      default:
        throw BridgeException('INVALID_VALUE', 'Unknown command "$command".');
    }
  }

  String _string(Map<String, dynamic> params, String key) {
    final value = params[key];
    if (value is String && value.isNotEmpty) return value;
    throw BridgeException('INVALID_VALUE', 'Missing or invalid "$key".');
  }

  int _int(Map<String, dynamic> params, String key) {
    final value = params[key];
    if (value is int) return value;
    throw BridgeException('INVALID_VALUE', 'Missing or invalid "$key".');
  }
}
