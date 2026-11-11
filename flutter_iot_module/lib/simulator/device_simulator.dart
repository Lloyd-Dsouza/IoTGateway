import 'dart:convert';
import 'dart:math';

import 'package:flutter_iot_module/simulator/simulated_device.dart';

import '../bridge/bridge_exception.dart';
import 'seed_devices.dart';

class DeviceSimulator {
  DeviceSimulator({String seedJson = kSeedDevicesJson, Random? random})
    : _random = random ?? Random() {
    final items = jsonDecode(seedJson) as List<dynamic>;
    for (final item in items) {
      final device = SimulatedDevice.fromJson(item as Map<String, dynamic>);
      _devices[device.id] = device;
    }
  }

  final Random _random;
  final Map<String, SimulatedDevice> _devices = {};

  List<SimulatedDevice> listDevices() {
    for (final device in _devices.values) {
      _tick(device);
    }
    return _devices.values.toList();
  }

  SimulatedDevice getDevice(String id) {
    final device = _find(id);
    _tick(device);
    return device;
  }

  SimulatedDevice setPower(String id, bool on) {
    final device = _requireOnlineHvac(id);
    device.isPoweredOn = on;
    return device;
  }

  SimulatedDevice setTargetTemperature(String id, double value) {
    final device = _requireOnlineHvac(id);
    if (value < 16 || value > 30) {
      throw const BridgeException(
        'INVALID_VALUE',
        'Target temperature must be 16 to 30 °C.',
      );
    }
    device.targetTemperature = value;
    return device;
  }

  SimulatedDevice setSamplingRate(String id, int seconds) {
    final device = _requireOnline(id);
    if (seconds < 1 || seconds > 60) {
      throw const BridgeException(
        'INVALID_VALUE',
        'Sampling rate must be 1 to 60 seconds.',
      );
    }
    device.samplingRateSeconds = seconds;
    return device;
  }

  SimulatedDevice _find(String id) {
    final device = _devices[id];
    if (device == null) {
      throw BridgeException('DEVICE_NOT_FOUND', 'No device with id $id.');
    }
    return device;
  }

  SimulatedDevice _requireOnline(String id) {
    final device = _find(id);
    if (!device.isOnline) {
      throw BridgeException('DEVICE_OFFLINE', 'Device $id is offline.');
    }
    return device;
  }

  SimulatedDevice _requireOnlineHvac(String id) {
    final device = _requireOnline(id);
    if (device.kind != 'hvac') {
      throw BridgeException('INVALID_VALUE', 'Device $id is not an HVAC unit.');
    }
    return device;
  }

  double _jitter(double amount) => (_random.nextDouble() - 0.5) * 2 * amount;

  void _tick(SimulatedDevice device) {
    if (!device.isOnline) return;

    for (final metric in device.metrics) {
      switch (metric.kind) {
        case 'temperature':
          final target = device.targetTemperature;
          if (device.kind == 'hvac' && device.isPoweredOn && target != null) {
            metric.value += (target - metric.value) * 0.1 + _jitter(0.1);
          } else {
            metric.value += _jitter(0.2);
          }
        case 'humidity':
          metric.value = (metric.value + _jitter(1.0))
              .clamp(20.0, 90.0)
              .toDouble();
        case 'powerConsumption':
          if (device.kind == 'hvac') {
            metric.value = device.isPoweredOn
                ? 1.0 + _random.nextDouble() * 0.8
                : 0.05;
          }
      }
    }
  }
}
