const String kSeedDevicesJson = '''
[
  {
    "id": "XYZ1001", "name": "Living Room HVAC", "kind": "hvac",
    "connection": "online", "batteryPercent": null, "signalDbm": -52,
    "samplingRateSeconds": 10, "isPoweredOn": true, "targetTemperature": 22.0,
    "metrics": [
      {"kind": "temperature", "value": 23.4, "unit": "°C"},
      {"kind": "powerConsumption", "value": 1.2, "unit": "kW"}
    ]
  },
  {
    "id": "XYZ1002", "name": "Bedroom Sensor", "kind": "tempHumidity",
    "connection": "online", "batteryPercent": 12, "signalDbm": -71,
    "samplingRateSeconds": 15, "isPoweredOn": true, "targetTemperature": null,
    "metrics": [
      {"kind": "temperature", "value": 21.8, "unit": "°C"},
      {"kind": "humidity", "value": 48.0, "unit": "%"}
    ]
  },
  {
    "id": "XYZ1003", "name": "Garage Sensor", "kind": "tempHumidity",
    "connection": "offline", "batteryPercent": 64, "signalDbm": -93,
    "samplingRateSeconds": 30, "isPoweredOn": true, "targetTemperature": null,
    "metrics": [
      {"kind": "temperature", "value": 16.2, "unit": "°C"},
      {"kind": "humidity", "value": 60.0, "unit": "%"}
    ]
  },
  {
    "id": "GW1000", "name": "Main Gateway", "kind": "gateway",
    "connection": "online", "batteryPercent": null, "signalDbm": -45,
    "samplingRateSeconds": 5, "isPoweredOn": true, "targetTemperature": null,
    "metrics": [
      {"kind": "powerConsumption", "value": 4.2, "unit": "W"}
    ]
  }
]
''';