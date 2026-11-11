class BridgeException implements Exception {
  final String code;
  final String message;

  const BridgeException(this.code, this.message);

  @override
  String toString() => '$code: $message';
}
