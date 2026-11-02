import 'package:calculator_core/calculator_core.dart';
import 'package:test/test.dart';

Rational fraction(int n, int d) => Rational(BigInt.from(n), BigInt.from(d));

RationalDisplay decimal(
  Rational value, {
  int places = 100,
  int characters = 2048,
}) => formatRational(
  value,
  format: RationalDisplayFormat.exactDecimal,
  maxDecimalPlaces: places,
  maxOutputCharacters: characters,
);

Matcher outputLimit() => throwsA(
  isA<CalculatorException>().having(
    (error) => error.code,
    'code',
    CalculatorErrorCode.limit,
  ),
);

void main() {
  group('fraction output and actual-format metadata', () {
    for (final (n, d, expected) in [
      (0, 7, '0'),
      (6, 15, '2/5'),
      (-6, 4, '-3/2'),
      (6, -4, '-3/2'),
      (-6, -4, '3/2'),
      (9, 3, '3'),
      (1000, 1, '1000'),
      (1, 3, '1/3'),
    ]) {
      test('$n/$d defaults to reduced $expected without fallback', () {
        final display = formatRational(fraction(n, d));
        expect(display.text, expected);
        expect(display.format, RationalDisplayFormat.fraction);
        expect(display.fallbackReason, isNull);
      });
    }

    test('integer decimal requests retain the exactDecimal format', () {
      for (final value in [0, 123, -123, 1000]) {
        final display = decimal(Rational.fromInt(value), places: 0);
        expect(display.text, '$value');
        expect(display.format, RationalDisplayFormat.exactDecimal);
        expect(display.fallbackReason, isNull);
      }
    });

    test('canonical zero never gains a negative sign or decimal tail', () {
      final zero = Rational(BigInt.zero, BigInt.from(-10));
      expect(decimal(zero).text, '0');
      expect(formatRational(zero).text, '0');
    });
  });

  group('exact finite German decimals', () {
    for (final (n, d, expected) in [
      (1, 2, '0,5'),
      (-3, 2, '-1,5'),
      (1, 8, '0,125'),
      (-1, 8, '-0,125'),
      (1, 40, '0,025'),
      (3, 40, '0,075'),
      (7, 250, '0,028'),
      (3, 24, '0,125'),
      (1200, 1000, '1,2'),
      (6, 15, '0,4'),
      (25, 4, '6,25'),
      (1, 1024, '0,0009765625'),
      (1, 125, '0,008'),
      (12300, 10, '1230'),
    ]) {
      test(
        '$n/$d renders as $expected with no rounding or unnecessary zeros',
        () {
          final display = decimal(fraction(n, d));
          expect(display.text, expected);
          expect(display.format, RationalDisplayFormat.exactDecimal);
          expect(display.fallbackReason, isNull);
          expect(display.text.contains('.'), isFalse);
        },
      );
    }

    test('numerators above double integer precision are not rounded', () {
      final value = Rational(BigInt.parse('9007199254740993'), BigInt.two);
      expect(decimal(value).text, '4503599627370496,5');
      expect(value.numerator, BigInt.parse('9007199254740993'));
      expect(value.denominator, BigInt.two);
    });

    test('long exact decimal digits remain intact', () {
      final value = Rational(
        BigInt.parse('100000000000000001'),
        BigInt.parse('1000000000000000000'),
      );
      expect(decimal(value).text, '0,100000000000000001');
      expect(decimal(-value).text, '-0,100000000000000001');
    });

    test('decimal length uses max(v2,v5), not the sum of exponents', () {
      final denominator = BigInt.two.pow(60) * BigInt.from(5).pow(60);
      final value = Rational(BigInt.one, denominator);
      final display = decimal(value, places: 60, characters: 62);
      expect(display.text, '0,${List.filled(59, '0').join()}1');
      expect(display.fallbackReason, isNull);
      expect(
        decimal(value, places: 59).fallbackReason,
        RationalDisplayFallbackReason.decimalPlacesLimit,
      );
    });

    test('the maximum 1000 decimal places is supported without long-division loops', () {
      final value = Rational(BigInt.one, BigInt.from(10).pow(1000));
      final display = decimal(value, places: 1000, characters: 1002);
      expect(display.text, '0,${List.filled(999, '0').join()}1');
      expect(display.text.length, 1002);
      expect(display.fallbackReason, isNull);
      expect(
        () => decimal(value, places: 1000, characters: 1001),
        outputLimit(),
      );
    });

    test(
      'finite decimal text roundtrips exactly over a grid of signs and factors',
      () {
        for (final twos in [0, 1, 2, 3, 8, 20, 60]) {
          for (final fives in [0, 1, 2, 3, 8, 20, 60]) {
            final denominator =
                BigInt.two.pow(twos) * BigInt.from(5).pow(fives);
            for (final numerator in [0, 1, -1, 3, -7, 10, 125]) {
              final value = Rational(BigInt.from(numerator), denominator);
              final display = decimal(value);
              expect(display.format, RationalDisplayFormat.exactDecimal);
              expect(display.fallbackReason, isNull);
              expect(
                Rational.parseDecimal(display.text),
                value,
                reason: '$numerator / (2^$twos * 5^$fives)',
              );
            }
          }
        }
      },
    );
  });

  group('explicit fraction fallback', () {
    for (final (n, d, expected) in [
      (1, 3, '1/3'),
      (-2, 7, '-2/7'),
      (2, 6, '1/3'),
      (1, 6, '1/6'),
      (1, 15, '1/15'),
    ]) {
      test('$n/$d is periodic after budgeted factor checks', () {
        final display = decimal(fraction(n, d));
        expect(display.text, expected);
        expect(display.format, RationalDisplayFormat.fraction);
        expect(display.fallbackReason, RationalDisplayFallbackReason.periodic);
      });
    }

    test('max places zero distinguishes pure periodic from an earlier factor limit', () {
      expect(
        decimal(fraction(1, 3), places: 0).fallbackReason,
        RationalDisplayFallbackReason.periodic,
      );
      for (final denominator in [2, 6, 15]) {
        final display = decimal(fraction(1, denominator), places: 0);
        expect(display.text, '1/$denominator');
        expect(
          display.fallbackReason,
          RationalDisplayFallbackReason.decimalPlacesLimit,
        );
      }
    });

    test('end of decimal-place budget is inclusive', () {
      expect(decimal(fraction(1, 8), places: 3).text, '0,125');
      final fallback = decimal(fraction(1, 8), places: 2);
      expect(fallback.text, '1/8');
      expect(fallback.format, RationalDisplayFormat.fraction);
      expect(
        fallback.fallbackReason,
        RationalDisplayFallbackReason.decimalPlacesLimit,
      );
      expect(decimal(fraction(1, 40), places: 2).text, '1/40');
      expect(decimal(fraction(1, 40), places: 3).text, '0,025');
    });

    test(
      'factor-2 limit takes precedence over later periodic rest factors',
      () {
        final denominator = BigInt.two.pow(101) * BigInt.from(3);
        final display = decimal(Rational(BigInt.one, denominator));
        expect(display.text, '1/$denominator');
        expect(
          display.fallbackReason,
          RationalDisplayFallbackReason.decimalPlacesLimit,
        );
        expect(
          decimal(Rational(BigInt.one, BigInt.two.pow(100) * BigInt.from(3)))
              .fallbackReason,
          RationalDisplayFallbackReason.periodic,
        );
      },
    );

    test('factor-5 limit also precedes a remaining periodic factor', () {
      final denominator = BigInt.from(5).pow(101) * BigInt.from(7);
      final display = decimal(Rational(BigInt.one, denominator));
      expect(display.text, '1/$denominator');
      expect(
        display.fallbackReason,
        RationalDisplayFallbackReason.decimalPlacesLimit,
      );
    });

    test(
      'factor limit at 1001 does not continue searching the full denominator',
      () {
        final denominator = BigInt.two.pow(1001);
        final display = decimal(
          Rational(BigInt.one, denominator),
          places: 1000,
        );
        expect(display.text, '1/$denominator');
        expect(
          display.fallbackReason,
          RationalDisplayFallbackReason.decimalPlacesLimit,
        );
      },
    );
  });

  group('parameter validation and output character limits', () {
    for (final format in RationalDisplayFormat.values) {
      for (final places in [-1, 1001]) {
        test(
          '$format rejects decimal-place parameter $places even if unused',
          () {
            expect(
              () => formatRational(
                Rational.fromInt(1),
                format: format,
                maxDecimalPlaces: places,
              ),
              throwsArgumentError,
            );
          },
        );
      }
      for (final characters in [-1, 0, 10001]) {
        test('$format rejects character parameter $characters', () {
          expect(
            () => formatRational(
              Rational.fromInt(1),
              format: format,
              maxOutputCharacters: characters,
            ),
            throwsArgumentError,
          );
        });
      }
    }

    test(
      'budget includes sign, leading zero and comma for exact decimal output',
      () {
        expect(decimal(fraction(1, 8), places: 3, characters: 5).text, '0,125');
        expect(
          () => decimal(fraction(1, 8), places: 3, characters: 4),
          outputLimit(),
        );
        expect(decimal(fraction(-1, 8), characters: 6).text, '-0,125');
        expect(() => decimal(fraction(-1, 8), characters: 5), outputLimit());
        expect(decimal(Rational.fromInt(0), characters: 1).text, '0');
        expect(decimal(Rational.fromInt(-1), characters: 2).text, '-1');
        expect(
          () => decimal(Rational.fromInt(-1), characters: 1),
          outputLimit(),
        );
      },
    );

    test(
      'valid exact decimal cannot evade output limit by silently falling back',
      () {
        expect(
          formatRational(fraction(1, 8), maxOutputCharacters: 3).text,
          '1/8',
        );
        expect(
          () => decimal(fraction(1, 8), places: 3, characters: 3),
          outputLimit(),
        );
      },
    );

    test('fraction budget includes numerator, slash, denominator and sign', () {
      expect(
        formatRational(fraction(-1, 3), maxOutputCharacters: 4).text,
        '-1/3',
      );
      expect(
        () => formatRational(fraction(-1, 3), maxOutputCharacters: 3),
        outputLimit(),
      );
      expect(
        formatRational(fraction(123, 7), maxOutputCharacters: 5).text,
        '123/7',
      );
      expect(
        () => formatRational(fraction(123, 7), maxOutputCharacters: 4),
        outputLimit(),
      );
      expect(
        formatRational(fraction(1, 123), maxOutputCharacters: 5).text,
        '1/123',
      );
      expect(
        () => formatRational(fraction(1, 123), maxOutputCharacters: 4),
        outputLimit(),
      );
    });

    test('periodic and decimal-limit fallbacks still respect the full output budget', () {
      expect(decimal(fraction(1, 3), characters: 3).text, '1/3');
      expect(() => decimal(fraction(1, 3), characters: 2), outputLimit());
      expect(decimal(fraction(1, 8), places: 2, characters: 3).text, '1/8');
      expect(
        () => decimal(fraction(1, 8), places: 2, characters: 2),
        outputLimit(),
      );
    });

    test('fraction length is not used to prematurely reject a shorter exact decimal', () {
      final value = fraction(999, 1000);
      expect(
        () => formatRational(value, maxOutputCharacters: 5),
        outputLimit(),
      );
      expect(decimal(value, places: 3, characters: 5).text, '0,999');
      expect(
        decimal(fraction(1, 1024), places: 10, characters: 12).text,
        '0,0009765625',
      );
    });

    test('maximum allowed character budget supports a 10000-digit integer', () {
      final value = Rational(BigInt.from(10).pow(9999));
      for (final format in RationalDisplayFormat.values) {
        final display = formatRational(
          value,
          format: format,
          maxOutputCharacters: 10000,
        );
        expect(display.text.length, 10000);
        expect(display.text[0], '1');
        expect(display.text.endsWith('0000'), isTrue);
        expect(
          display.format,
          format == RationalDisplayFormat.exactRecurringDecimal
              ? RationalDisplayFormat.exactDecimal
              : format,
        );
      }
      expect(
        () => formatRational(value, maxOutputCharacters: 9999),
        outputLimit(),
      );
    });

    test('oversized public BigInts are rejected before unrestricted output strings', () {
      final enormous = BigInt.from(10).pow(100000);
      final integer = Rational(enormous);
      final finite = Rational(enormous + BigInt.one, BigInt.two);
      final periodic = Rational(BigInt.one, enormous + BigInt.from(3));
      for (final format in RationalDisplayFormat.values) {
        expect(
          () => formatRational(integer, format: format, maxOutputCharacters: 8),
          outputLimit(),
        );
        expect(
          () => formatRational(finite, format: format, maxOutputCharacters: 8),
          outputLimit(),
        );
        expect(
          () =>
              formatRational(periodic, format: format, maxOutputCharacters: 8),
          outputLimit(),
        );
      }
    });

    test('large power-of-two denominator respects bounded factor work and fallback size', () {
      final value = Rational(BigInt.one, BigInt.two.pow(100000));
      expect(() => decimal(value, places: 1000, characters: 8), outputLimit());
    });
  });

  group('formatting never writes a session or mathematical value', () {
    test(
      'linear result and Ans survive alternating exact formats and errors',
      () {
        final session = CalculatorSession();
        session.press(CalculatorKey.digit3);
        session.press(CalculatorKey.divide);
        session.press(CalculatorKey.digit8);
        final old = session.press(CalculatorKey.equals);
        expect(formatRational(old.answer).text, '3/8');
        expect(decimal(old.answer).text, '0,375');
        expect(
          decimal(old.answer, places: 0).fallbackReason,
          RationalDisplayFallbackReason.decimalPlacesLimit,
        );
        expect(() => decimal(old.answer, characters: 1), outputLimit());
        expect(identical(session.snapshot, old), isTrue);
        expect(old.answer.toString(), '3/8');
        expect(old.result.toString(), '3/8');
        session.press(CalculatorKey.multiply);
        session.press(CalculatorKey.digit8);
        expect(session.press(CalculatorKey.equals).result, Rational.fromInt(3));
        expect(old.answer.toString(), '3/8');
      },
    );

    test('structured result, editor cursor and exact Ans remain independent of text', () {
      final session = StructuredCalculatorSession();
      session.pressId('KEY_FRACTION');
      session.press(CalculatorKey.digit7);
      session.pressId('KEY_DOWN');
      session.press(CalculatorKey.digit4);
      session.press(CalculatorKey.digit0);
      final old = session.press(CalculatorKey.equals);
      expect(decimal(old.answer).text, '0,175');
      expect(formatRational(old.answer).text, '7/40');
      expect(identical(session.snapshot, old), isTrue);
      expect(old.editor.cursor.path.single.field, FractionField.denominator);
      expect(old.editor.cursor.offset, 2);
      expect(old.answer.toString(), '7/40');
      session.press(CalculatorKey.add);
      session.press(CalculatorKey.digit2);
      expect(session.press(CalculatorKey.equals).result.toString(), '87/40');
      expect(old.answer.toString(), '7/40');
    });
  });
}
