enum CalculatorErrorCode { syntax, math, unsupported, limit }

/// Structured errors, independent of the future localized Flutter display.
final class CalculatorException implements Exception {
  final CalculatorErrorCode code;
  final String message;
  final int? position;

  const CalculatorException(this.code, this.message, {this.position});

  @override
  String toString() =>
      '${code.name}: $message'
      '${position == null ? '' : ' (offset $position)'}';
}
