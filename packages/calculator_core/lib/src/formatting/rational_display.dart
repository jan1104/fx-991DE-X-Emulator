import '../errors.dart';
import '../numbers/rational.dart';

enum RationalDisplayFormat { fraction, exactDecimal }

enum RationalDisplayFallbackReason { periodic, decimalPlacesLimit }

/// An immutable rendering result. [format] describes the actual output, not
/// the requested format. Exact-decimal fallbacks therefore report
/// [RationalDisplayFormat.fraction].
final class RationalDisplay {
  final String text;
  final RationalDisplayFormat format;
  final RationalDisplayFallbackReason? fallbackReason;

  const RationalDisplay(this.text, this.format, {this.fallbackReason});
}

/// Formats a mathematical value without changing it, rounding it or using a
/// floating-point conversion. This is not a complete Casio S/D implementation.
/// Factor checks stop at the first decimal-place budget overrun, so that
/// `decimalPlacesLimit` precedes any unexamined periodic remainder: for example,
/// 1/6 with a zero-place budget reports that limit rather than `periodic`.
RationalDisplay formatRational(
  Rational value, {
  RationalDisplayFormat format = RationalDisplayFormat.fraction,
  int maxDecimalPlaces = 100,
  int maxOutputCharacters = 2048,
}) {
  if (maxDecimalPlaces < 0 || maxDecimalPlaces > 1000) {
    throw ArgumentError.value(
      maxDecimalPlaces,
      'maxDecimalPlaces',
      'Must be between 0 and 1000',
    );
  }
  if (maxOutputCharacters < 1 || maxOutputCharacters > 10000) {
    throw ArgumentError.value(
      maxOutputCharacters,
      'maxOutputCharacters',
      'Must be between 1 and 10000',
    );
  }

  RationalDisplay fraction([RationalDisplayFallbackReason? reason]) =>
      RationalDisplay(
        _fractionText(value, maxOutputCharacters),
        RationalDisplayFormat.fraction,
        fallbackReason: reason,
      );

  if (format == RationalDisplayFormat.fraction) return fraction();
  if (value.isInteger) {
    return RationalDisplay(_fractionText(value, maxOutputCharacters), format);
  }

  var remaining = value.denominator;
  var twos = 0;
  var fives = 0;
  final two = BigInt.from(2);
  final five = BigInt.from(5);
  while (remaining % two == BigInt.zero) {
    if (++twos > maxDecimalPlaces) {
      return fraction(RationalDisplayFallbackReason.decimalPlacesLimit);
    }
    remaining ~/= two;
  }
  while (remaining % five == BigInt.zero) {
    if (++fives > maxDecimalPlaces) {
      return fraction(RationalDisplayFallbackReason.decimalPlacesLimit);
    }
    remaining ~/= five;
  }
  if (remaining != BigInt.one) {
    return fraction(RationalDisplayFallbackReason.periodic);
  }

  final scale = twos > fives ? twos : fives;
  final sign = value.numerator.isNegative ? '-' : '';
  // At least "0," plus scale digits are necessary. Reject before producing
  // any padding or scaled numerator when even this shortest form cannot fit.
  if (scale + 2 + sign.length > maxOutputCharacters) _outputLimit();

  final multiplier = two.pow(scale - twos) * five.pow(scale - fives);
  final upperBound = BigInt.from(10).pow(maxOutputCharacters);
  final magnitude = value.numerator.abs();
  // Public Rational values have no evaluator bit budget. Bound the integer
  // before multiplication/string conversion, rather than allocating huge text.
  if (magnitude > (upperBound - BigInt.one) ~/ multiplier) _outputLimit();
  final digits = (magnitude * multiplier).toString();
  final paddedLength = digits.length > scale ? digits.length : scale + 1;
  if (paddedLength + 1 + sign.length > maxOutputCharacters) _outputLimit();
  final padded = digits.padLeft(paddedLength, '0');
  final separator = padded.length - scale;
  final text =
      '$sign${padded.substring(0, separator)},'
      '${padded.substring(separator)}';
  // Canonical reduction guarantees that this noninteger's final decimal digit
  // is nonzero, so no rounding or trailing-zero cleanup is needed.
  _checkLength(text, maxOutputCharacters);
  return RationalDisplay(text, RationalDisplayFormat.exactDecimal);
}

String _fractionText(Rational value, int budget) {
  final sign = value.numerator.isNegative ? '-' : '';
  if (value.isInteger) {
    final digits = _boundedDigits(value.numerator.abs(), budget - sign.length);
    final text = '$sign$digits';
    _checkLength(text, budget);
    return text;
  }
  // Reserve at least a slash and one denominator digit before converting the
  // numerator; then give the denominator only the remaining character budget.
  final numerator = _boundedDigits(
    value.numerator.abs(),
    budget - sign.length - 2,
  );
  final denominator = _boundedDigits(
    value.denominator,
    budget - sign.length - numerator.length - 1,
  );
  final text = '$sign$numerator/$denominator';
  _checkLength(text, budget);
  return text;
}

String _boundedDigits(BigInt magnitude, int maxDigits) {
  if (maxDigits < 1 || magnitude >= BigInt.from(10).pow(maxDigits)) {
    _outputLimit();
  }
  return magnitude.toString();
}

void _checkLength(String text, int budget) {
  if (text.length > budget) _outputLimit();
}

Never _outputLimit() => throw const CalculatorException(
  CalculatorErrorCode.limit,
  'Formatted output exceeds character budget',
);
