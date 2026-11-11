class SimulatedMetric {
  final String kind;
  double value;
  final String unit;

  SimulatedMetric({
    required this.kind,
    required this.value,
    required this.unit,
  });

  Map<String, dynamic> toJson() => {
    'kind': kind,
    'value': double.parse(value.toStringAsFixed(1)),
    'unit': unit,
  };
}

class SimulatedDevice {
  final String id;
  final String name;
  final String kind;
  String connection;
  int? batteryPercent;
  int signalDbm;
  int samplingRateSeconds;
  bool isPoweredOn;
  double? targetTemperature;
  final List<SimulatedMetric> metrics;

  bool get isOnline => connection == 'online';

  SimulatedDevice({
    required this.id,
    required this.name,
    required this.kind,
    required this.connection,
    required this.batteryPercent,
    required this.signalDbm,
    required this.samplingRateSeconds,
    required this.isPoweredOn,
    required this.targetTemperature,
    required this.metrics,
  });

  factory SimulatedDevice.fromJson(Map<String, dynamic> json) {
    return SimulatedDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      kind: json['kind'] as String,
      connection: json['connection'] as String,
      batteryPercent: json['batteryPercent'] as int?,
      signalDbm: json['signalDbm'] as int,
      samplingRateSeconds: json['samplingRateSeconds'] as int,
      isPoweredOn: json['isPoweredOn'] as bool,
      targetTemperature: (json['targetTemperature'] as num?)?.toDouble(),
      metrics: (json['metrics'] as List<dynamic>).map((item) {
        final m = item as Map<String, dynamic>;
        return SimulatedMetric(
          kind: m['kind'] as String,
          value: (m['value'] as num).toDouble(),
          unit: m['unit'] as String,
        );
      }).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'kind': kind,
    'connection': connection,
    'batteryPercent': batteryPercent,
    'signalDbm': signalDbm,
    'samplingRateSeconds': samplingRateSeconds,
    'isPoweredOn': isPoweredOn,
    'targetTemperature': targetTemperature,
    'metrics': metrics.map((m) => m.toJson()).toList(),
  };
}
