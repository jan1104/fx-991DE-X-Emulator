import 'package:test/test.dart';

import 'package:calculator_core/src/numbers/rational.dart';

Rational fraction(int numerator, int denominator) =>
    Rational(BigInt.from(numerator), BigInt.from(denominator));

void main() {
  group('canonical fractions', () {
    test('reduces common factors and makes the denominator positive', () {
      final value = fraction(42, -56);
      expect(value.numerator, BigInt.from(-3));
      expect(value.denominator, BigInt.from(4));
      expect(fraction(-42, -56), fraction(3, 4));
      expect(fraction(-42, 56), fraction(-3, 4));
    });

    test('zero has the single representation 0/1', () {
      final value = Rational(BigInt.zero, -BigInt.from(987));
      expect(value.numerator, BigInt.zero);
      expect(value.denominator, BigInt.one);
      expect(value.isInteger, isTrue);
      expect(value.toString(), '0');
    });

    test('supports arbitrary-size integer factors exactly', () {
      final scale = BigInt.parse('1234567890123456789012345678901234567890');
      expect(
        Rational(scale * BigInt.from(5), scale * BigInt.from(7)),
        fraction(5, 7),
      );
      expect(Rational(scale).numerator, scale);
    });

    test('rejects every zero denominator, including 0/0', () {
      expect(() => Rational(BigInt.one, BigInt.zero), throwsArgumentError);
      expect(() => Rational(BigInt.zero, BigInt.zero), throwsArgumentError);
    });

    test('constructs integers and prints ASCII fractions', () {
      expect(Rational.fromInt(-17).toString(), '-17');
      expect(fraction(6, 3).isInteger, isTrue);
      expect(fraction(6, 3).toString(), '2');
      expect(fraction(-5, 7).isInteger, isFalse);
      expect(fraction(-5, 7).toString(), '-5/7');
    });

    test('equal reduced values have equal hashes and behave as map keys', () {
      final values = <Rational, String>{fraction(2, 6): 'third'};
      expect(fraction(1, 3), fraction(-2, -6));
      expect(fraction(1, 3).hashCode, fraction(-2, -6).hashCode);
      expect(values[fraction(5, 15)], 'third');
      expect(fraction(1, 3) == fraction(1, 2), isFalse);
      expect(fraction(1, 3) == 1, isFalse);
    });
  });

  group('exact decimal parsing', () {
    final cases = <String, Rational>{
      '0': Rational.fromInt(0),
      '-0': Rational.fromInt(0),
      '+0012': Rational.fromInt(12),
      '0.1': fraction(1, 10),
      '-12,3400': fraction(-617, 50),
      '.125': fraction(1, 8),
      '-,5': fraction(-1, 2),
      '1.': Rational.fromInt(1),
      '+1,': Rational.fromInt(1),
      '1e3': Rational.fromInt(1000),
      '1E+003': Rational.fromInt(1000),
      '-1.25e-2': fraction(-1, 80),
      '2,5E1': Rational.fromInt(25),
      '.5e+2': Rational.fromInt(50),
      '9007199254740993': Rational(BigInt.parse('9007199254740993')),
      '0.100000000000000001': Rational(
        BigInt.parse('100000000000000001'),
        BigInt.parse('1000000000000000000'),
      ),
    };
    for (final entry in cases.entries) {
      test('parses ${entry.key} without floating-point rounding', () {
        expect(Rational.parseDecimal(entry.key), entry.value);
      });
    }

    for (final source in <String>[
      '',
      ' ',
      ' 1',
      '1 ',
      '1\n',
      '\n1',
      '1\t',
      '.',
      ',',
      '+',
      '-',
      '1.2,3',
      '1,2.3',
      '1,000,000',
      '1.000.000',
      '1 000',
      '1_000',
      '++1',
      '--1',
      '+-1',
      '1e',
      'e1',
      '1e+',
      '1e-',
      '1e1.5',
      '1e1,5',
      '1e2e3',
      '1e 2',
      'NaN',
      'Infinity',
      '0x10',
      '1/2',
      '١٢',
    ]) {
      test('rejects malformed or ambiguous input ${source.codeUnits}', () {
        expect(() => Rational.parseDecimal(source), throwsFormatException);
      });
    }

    test('accepts exactly 1000 characters and rejects 1001', () {
      final maximum = List.filled(1000, '9').join();
      expect(Rational.parseDecimal(maximum).numerator, BigInt.parse(maximum));
      expect(() => Rational.parseDecimal('${maximum}9'), throwsRangeError);
    });

    test('checks exponent bounds before converting to a native integer', () {
      final ten = BigInt.from(10);
      expect(Rational.parseDecimal('1e1000'), Rational(ten.pow(1000)));
      expect(
        Rational.parseDecimal('1e-1000'),
        Rational(BigInt.one, ten.pow(1000)),
      );
      expect(Rational.parseDecimal('1e+0001000'), Rational(ten.pow(1000)));
      for (final source in [
        '1e1001',
        '1e-1001',
        '0e1001',
        '1e999999999999999999999999999',
      ]) {
        expect(() => Rational.parseDecimal(source), throwsRangeError);
      }
    });

    test('combines fractional digits and a negative exponent exactly', () {
      final value = Rational.parseDecimal('0.001e-1000');
      expect(value.numerator, BigInt.one);
      expect(value.denominator, BigInt.from(10).pow(1003));
    });
  });

  group('arithmetic', () {
    test('addition, subtraction, multiplication and division are exact', () {
      final left = fraction(-7, 12);
      final right = fraction(5, 18);
      expect(left + right, fraction(-11, 36));
      expect(left - right, fraction(-31, 36));
      expect(left * right, fraction(-35, 216));
      expect(left / right, fraction(-21, 10));
      expect(-left, fraction(7, 12));
      expect(left, fraction(-7, 12));
    });

    test('has fixed algebraic results with large cancellation', () {
      final large = BigInt.parse('999999999999999999999999999999999999');
      final value = Rational(large, BigInt.from(7));
      expect(value - value, Rational.fromInt(0));
      expect(value * Rational(BigInt.from(7), large), Rational.fromInt(1));
      expect(fraction(2, 3) + fraction(3, 2), fraction(13, 6));
      expect(fraction(1, 10) + fraction(2, 10), fraction(3, 10));
    });

    test('rejects division by zero and handles zero dividend', () {
      expect(fraction(0, 5) / fraction(-3, 2), Rational.fromInt(0));
      expect(() => fraction(1, 2) / Rational.fromInt(0), throwsArgumentError);
      expect(
        () => Rational.fromInt(0) / Rational.fromInt(0),
        throwsArgumentError,
      );
    });

    test('compares exact signs and arbitrary-size close values', () {
      expect(fraction(-2, 3).compareTo(fraction(-1, 2)), lessThan(0));
      expect(fraction(2, 3).compareTo(fraction(1, 2)), greaterThan(0));
      expect(fraction(2, 6).compareTo(fraction(1, 3)), 0);
      expect(Rational.fromInt(0).compareTo(fraction(-1, 100)), greaterThan(0));
      final denominator = BigInt.from(10).pow(100);
      expect(
        Rational(
          denominator + BigInt.one,
          denominator,
        ).compareTo(Rational.fromInt(1)),
        greaterThan(0),
      );
    });
  });

  group('integer powers', () {
    test('supports positive, negative, odd, even and zeroth powers', () {
      final value = fraction(-2, 3);
      expect(value.pow(3), fraction(-8, 27));
      expect(value.pow(2), fraction(4, 9));
      expect(value.pow(-3), fraction(-27, 8));
      expect(value.pow(-2), fraction(9, 4));
      expect(value.pow(0), Rational.fromInt(1));
      expect(Rational.fromInt(0).pow(0), Rational.fromInt(1));
      expect(Rational.fromInt(0).pow(3), Rational.fromInt(0));
    });

    test('allows both exponent limits and rejects larger magnitudes', () {
      final twoTo1000 = BigInt.two.pow(1000);
      expect(Rational.fromInt(2).pow(1000), Rational(twoTo1000));
      expect(Rational.fromInt(2).pow(-1000), Rational(BigInt.one, twoTo1000));
      expect(() => Rational.fromInt(1).pow(1001), throwsRangeError);
      expect(() => Rational.fromInt(1).pow(-1001), throwsRangeError);
    });

    test('zero has no negative integer power', () {
      expect(() => Rational.fromInt(0).pow(-1), throwsArgumentError);
      expect(() => Rational.fromInt(0).pow(-1000), throwsArgumentError);
    });
  });
}
