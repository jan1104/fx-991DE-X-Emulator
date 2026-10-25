/// An immutable exact fraction with a positive, reduced denominator.
///
/// Zero is always represented as 0/1. This mathematical value type does not
/// impose calculator-specific magnitude or display limits.
final class Rational implements Comparable<Rational> {
  factory Rational(BigInt numerator, [BigInt? denominator]) {
    var divisor = denominator ?? BigInt.one;
    if (divisor == BigInt.zero) {
      throw ArgumentError.value(divisor, 'denominator', 'Must not be zero.');
    }
    if (numerator == BigInt.zero) {
      return Rational._(BigInt.zero, BigInt.one);
    }
    if (divisor.isNegative) {
      numerator = -numerator;
      divisor = -divisor;
    }
    final commonFactor = numerator.abs().gcd(divisor);
    return Rational._(numerator ~/ commonFactor, divisor ~/ commonFactor);
  }

  factory Rational.fromInt(int value) => Rational(BigInt.from(value));

  /// Parses one decimal number exactly, without passing through a double.
  ///
  /// A point or comma may be used as the decimal separator, including `.5`
  /// and `1.`. A signed decimal exponent is optional. Whitespace, thousands
  /// separators and mixed decimal separators are not accepted.
  ///
  /// Input length and the absolute decimal exponent are limited to 1000.
  factory Rational.parseDecimal(String source) {
    if (source.length > 1000) {
      throw RangeError.range(source.length, 0, 1000, 'source.length');
    }
    final match = _decimalPattern.firstMatch(source);
    if (match == null || match.end != source.length) {
      throw FormatException('Expected one decimal number.', source);
    }

    final exponentIndex = source.indexOf(RegExp('[eE]'));
    var mantissa = source;
    var exponent = 0;
    if (exponentIndex >= 0) {
      mantissa = source.substring(0, exponentIndex);
      final exponentText = source.substring(exponentIndex + 1);
      // BigInt avoids overflow even for a syntactically valid long exponent.
      final parsedExponent = BigInt.parse(exponentText);
      if (parsedExponent < BigInt.from(-1000) ||
          parsedExponent > BigInt.from(1000)) {
        throw RangeError(
          'The decimal exponent must be between -1000 and 1000.',
        );
      }
      exponent = parsedExponent.toInt();
    }

    final separatorIndex = mantissa.indexOf(RegExp('[.,]'));
    final fractionalDigits = separatorIndex < 0
        ? 0
        : mantissa.length - separatorIndex - 1;
    final digits = mantissa.replaceAll(RegExp('[.,]'), '');
    final numerator = BigInt.parse(digits);
    final scale = fractionalDigits - exponent;
    if (scale <= 0) {
      return Rational(numerator * _ten.pow(-scale));
    }
    return Rational(numerator, _ten.pow(scale));
  }

  const Rational._(this.numerator, this.denominator);

  static final _decimalPattern = RegExp(
    r'^[+-]?(?:[0-9]+(?:[.,][0-9]*)?|[.,][0-9]+)(?:[eE][+-]?[0-9]+)?$',
  );
  static final _ten = BigInt.from(10);

  final BigInt numerator;
  final BigInt denominator;

  bool get isInteger => denominator == BigInt.one;

  Rational operator +(Rational other) => Rational(
    numerator * other.denominator + other.numerator * denominator,
    denominator * other.denominator,
  );

  Rational operator -(Rational other) => Rational(
    numerator * other.denominator - other.numerator * denominator,
    denominator * other.denominator,
  );

  Rational operator *(Rational other) =>
      Rational(numerator * other.numerator, denominator * other.denominator);

  Rational operator /(Rational other) =>
      Rational(numerator * other.denominator, denominator * other.numerator);

  Rational operator -() => Rational(-numerator, denominator);

  /// Raises this value to an integer power in the range -1000 through 1000.
  ///
  /// The algebraic zeroth power is one, including for zero. Calculator-specific
  /// syntax and domain decisions belong to the expression evaluator.
  Rational pow(int exponent) {
    if (exponent < -1000 || exponent > 1000) {
      throw RangeError.range(exponent, -1000, 1000, 'exponent');
    }
    if (exponent < 0) {
      if (numerator == BigInt.zero) {
        throw ArgumentError('Zero cannot be raised to a negative power.');
      }
      return Rational(denominator.pow(-exponent), numerator.pow(-exponent));
    }
    return Rational(numerator.pow(exponent), denominator.pow(exponent));
  }

  @override
  int compareTo(Rational other) =>
      (numerator * other.denominator).compareTo(other.numerator * denominator);

  @override
  bool operator ==(Object other) =>
      other is Rational &&
      numerator == other.numerator &&
      denominator == other.denominator;

  @override
  int get hashCode => Object.hash(numerator, denominator);

  @override
  String toString() => isInteger ? '$numerator' : '$numerator/$denominator';
}
