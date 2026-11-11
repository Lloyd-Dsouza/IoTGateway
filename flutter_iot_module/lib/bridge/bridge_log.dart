import 'package:flutter/foundation.dart';

class LogEntry {
  const LogEntry({
    required this.time,
    required this.method,
    required this.ok,
    required this.latencyMs,
    this.deviceId,
    this.errorCode,
  });

  final DateTime time;
  final String method;
  final bool ok;
  final int latencyMs;
  final String? deviceId;
  final String? errorCode;
}

class BridgeLog extends ChangeNotifier {
  static const int maxEntries = 20;

  final List<LogEntry> _entries = [];
  int _messageCount = 0;

  List<LogEntry> get entries => List.unmodifiable(_entries);
  int get messageCount => _messageCount;

  void add({
    required String method,
    required bool ok,
    required int latencyMs,
    String? deviceId,
    String? errorCode,
  }) {
    _messageCount++;
    _entries.insert(
      0,
      LogEntry(
        time: DateTime.now(),
        method: method,
        ok: ok,
        latencyMs: latencyMs,
        deviceId: deviceId,

        errorCode: errorCode,
      ),
    );
    if (_entries.length > maxEntries) _entries.removeLast();
    notifyListeners();
  }
}
