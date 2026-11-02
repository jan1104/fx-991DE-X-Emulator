import 'package:calculator_core/calculator_core.dart';
import 'package:test/test.dart';

RationalDisplay recurring(
  Rational value, {
  int digits = 100,
  int chars = 2048,
  int places = 100,
}) => formatRational(
  value,
  format: RationalDisplayFormat.exactRecurringDecimal,
  maxGeneratedDigits: digits,
  maxOutputCharacters: chars,
  maxDecimalPlaces: places,
);

Matcher limit([String? message]) => isA<CalculatorException>()
    .having((e) => e.code, 'code', CalculatorErrorCode.limit)
    .having(
      (e) => message == null || e.message == message,
      'expected message',
      isTrue,
    );

Rational reconstruct(RationalDecimalExpansion expansion) {
  final ten = BigInt.from(10);
  final prefix = expansion.nonRepeatingDigits;
  final period = expansion.repeatingDigits;
  final prefixScale = ten.pow(prefix.length);
  var value =
      Rational(BigInt.parse(expansion.integerDigits)) +
      Rational(
        prefix.isEmpty ? BigInt.zero : BigInt.parse(prefix),
        prefixScale,
      );
  if (period.isNotEmpty) {
    value += Rational(
      BigInt.parse(period),
      prefixScale * (ten.pow(period.length) - BigInt.one),
    );
  }
  return expansion.negative ? -value : value;
}

void main() {
  test('enum extension and optional DTO preserve existing constructors', () {
    const old = RationalDisplay('1/3', RationalDisplayFormat.fraction);
    expect(old.expansion, isNull);
    const dto = RationalDecimalExpansion(
      negative: false,
      integerDigits: '0',
      nonRepeatingDigits: '08',
      repeatingDigits: '3',
    );
    expect(dto.nonRepeatingDigits, '08');
    expect(reconstruct(dto), Rational(BigInt.one, BigInt.from(12)));
    expect(
      RationalDisplayFormat.values.last,
      RationalDisplayFormat.exactRecurringDecimal,
    );
    expect(
      RationalDisplayFallbackReason.values.last,
      RationalDisplayFallbackReason.expansionLimit,
    );
  });

  test('cycle closes at the exact one-digit generation boundary', () {
    final display = recurring(Rational(BigInt.one, BigInt.from(3)), digits: 1);
    expect(display.text, '0,(3)');
    expect(display.format, RationalDisplayFormat.exactRecurringDecimal);
    expect(display.fallbackReason, isNull);
    expect(display.expansion!.nonRepeatingDigits, '');
    expect(display.expansion!.repeatingDigits, '3');
  });

  test('preperiod and cycle close at exactly two generated digits', () {
    final value = Rational(BigInt.one, BigInt.from(6));
    final complete = recurring(value, digits: 2);
    expect(complete.text, '0,1(6)');
    expect(complete.expansion!.nonRepeatingDigits, '1');
    expect(complete.expansion!.repeatingDigits, '6');
    final incomplete = recurring(value, digits: 1);
    expect(incomplete.text, '1/6');
    expect(
      incomplete.fallbackReason,
      RationalDisplayFallbackReason.expansionLimit,
    );
    expect(incomplete.expansion, isNull);
  });

  test('zero remainder wins over the exact finite digit boundary', () {
    final value = Rational(BigInt.one, BigInt.from(8));
    final display = recurring(value, digits: 3, places: 0);
    expect(display.text, '0,125');
    expect(display.format, RationalDisplayFormat.exactDecimal);
    expect(display.expansion!.nonRepeatingDigits, '125');
    expect(display.expansion!.repeatingDigits, '');
    expect(
      recurring(value, digits: 2).fallbackReason,
      RationalDisplayFallbackReason.expansionLimit,
    );
  });

  test('zero budget completes zero and signed integers with exact DTOs', () {
    for (final pair in const [('0', false), ('12', false), ('-12', true)]) {
      final display = recurring(Rational(BigInt.parse(pair.$1)), digits: 0);
      expect(display.text, pair.$1);
      expect(display.format, RationalDisplayFormat.exactDecimal);
      expect(display.expansion!.negative, pair.$2);
      expect(display.expansion!.integerDigits, pair.$1.replaceFirst('-', ''));
      expect(display.expansion!.nonRepeatingDigits, '');
      expect(display.expansion!.repeatingDigits, '');
    }
    expect(recurring(Rational.fromInt(0), digits: 0, chars: 1).text, '0');
  });

  test(
    'zero budget yields expansionLimit for finite and periodic nonintegers',
    () {
      for (final denominator in [2, 3, 6, 15]) {
        final display = recurring(
          Rational(BigInt.one, BigInt.from(denominator)),
          digits: 0,
        );
        expect(display.text, '1/$denominator');
        expect(display.format, RationalDisplayFormat.fraction);
        expect(
          display.fallbackReason,
          RationalDisplayFallbackReason.expansionLimit,
        );
        expect(display.expansion, isNull);
      }
    },
  );

  test('canonical reduction precedes digit accounting and preserves significant zeroes', () {
    final finite = recurring(
      Rational(BigInt.from(30), BigInt.from(240)),
      digits: 3,
    );
    expect(finite.text, '0,125');
    final period = recurring(Rational(BigInt.one, BigInt.from(11)), digits: 2);
    expect(period.text, '0,(09)');
    expect(period.expansion!.repeatingDigits, '09');
    final preperiod = recurring(
      Rational(BigInt.one, BigInt.from(12)),
      digits: 3,
    );
    expect(preperiod.text, '0,08(3)');
    expect(preperiod.expansion!.nonRepeatingDigits, '08');
  });

  test(
    'sign belongs to the value, not digit fields, with no negative zero',
    () {
      final display = recurring(
        Rational(BigInt.from(-22), BigInt.from(7)),
        digits: 6,
      );
      expect(display.text, '-3,(142857)');
      expect(display.expansion!.negative, isTrue);
      expect(display.expansion!.integerDigits, '3');
      expect(
        reconstruct(display.expansion!),
        Rational(BigInt.from(-22), BigInt.from(7)),
      );
      final zero = recurring(Rational(BigInt.zero, -BigInt.from(7)), digits: 0);
      expect(zero.text, '0');
      expect(zero.expansion!.negative, isFalse);
    },
  );

  test('closed period punctuation counts and does not silently fall back to shorter fraction', () {
    final value = Rational(BigInt.one, BigInt.from(3));
    expect(recurring(value, digits: 1, chars: 5).text, '0,(3)');
    expect(() => recurring(value, digits: 1, chars: 4), throwsA(limit()));
    expect(recurring(-value, digits: 1, chars: 6).text, '-0,(3)');
    expect(() => recurring(-value, digits: 1, chars: 5), throwsA(limit()));
  });

  test('finite comma, leading zero and sign count in the output budget', () {
    final value = Rational(BigInt.one, BigInt.from(8));
    expect(recurring(value, digits: 3, chars: 5).text, '0,125');
    expect(() => recurring(value, digits: 3, chars: 4), throwsA(limit()));
    expect(recurring(-value, digits: 3, chars: 6).text, '-0,125');
    expect(() => recurring(-value, digits: 3, chars: 5), throwsA(limit()));
    expect(
      () => recurring(Rational.fromInt(-1), digits: 0, chars: 1),
      throwsA(limit()),
    );
  });

  test(
    'unfinished longer decimal may fall back to a fitting short fraction',
    () {
      final value = Rational(BigInt.one, BigInt.from(8));
      final display = recurring(value, digits: 2, chars: 3);
      expect(display.text, '1/8');
      expect(
        display.fallbackReason,
        RationalDisplayFallbackReason.expansionLimit,
      );
      expect(() => recurring(value, digits: 2, chars: 2), throwsA(limit()));
    },
  );

  test('short digit budget never exposes partial expansion metadata', () {
    final display = recurring(Rational(BigInt.one, BigInt.from(7)), digits: 5);
    expect(display.text, '1/7');
    expect(display.expansion, isNull);
    expect(
      display.fallbackReason,
      RationalDisplayFallbackReason.expansionLimit,
    );
    expect(
      recurring(Rational(BigInt.one, BigInt.from(7)), digits: 6).text,
      '0,(142857)',
    );
  });

  test('maximum finite 1000-digit expansion completes without a closing extra step', () {
    final display = recurring(
      Rational(BigInt.one, BigInt.from(10).pow(1000)),
      digits: 1000,
      chars: 1002,
    );
    expect(display.text.length, 1002);
    expect(display.text.startsWith('0,'), isTrue);
    expect(display.text.endsWith('1'), isTrue);
    expect(display.expansion!.nonRepeatingDigits, '${'0' * 999}1');
    expect(display.expansion!.repeatingDigits, '');
    expect(
      () => recurring(
        Rational(BigInt.one, BigInt.from(10).pow(1000)),
        digits: 1000,
        chars: 1001,
      ),
      throwsA(limit()),
    );
  });

  test(
    'valid maximum generation budget stops before an unfinished 1001st digit',
    () {
      final value = Rational(BigInt.one, BigInt.from(10).pow(1001));
      final display = recurring(value, digits: 1000);
      expect(display.format, RationalDisplayFormat.fraction);
      expect(
        display.fallbackReason,
        RationalDisplayFallbackReason.expansionLimit,
      );
      expect(display.expansion, isNull);
    },
  );

  for (final mode in RationalDisplayFormat.values) {
    test('all parameters validated before value work in ${mode.name}', () {
      final enormous = Rational(BigInt.one << 100001);
      for (final invalid in [-1, 1001]) {
        expect(
          () => formatRational(
            enormous,
            format: mode,
            maxGeneratedDigits: invalid,
          ),
          throwsArgumentError,
        );
        expect(
          () =>
              formatRational(enormous, format: mode, maxDecimalPlaces: invalid),
          throwsArgumentError,
        );
      }
      for (final invalid in [0, 10001]) {
        expect(
          () => formatRational(
            enormous,
            format: mode,
            maxOutputCharacters: invalid,
          ),
          throwsArgumentError,
        );
      }
    });
  }

  test('valid digit budgets are independent across modes', () {
    final value = Rational(BigInt.one, BigInt.from(8));
    expect(recurring(value, digits: 3, places: 2).text, '0,125');
    final old = formatRational(
      value,
      format: RationalDisplayFormat.exactDecimal,
      maxDecimalPlaces: 3,
      maxGeneratedDigits: 0,
    );
    expect(old.text, '0,125');
    expect(old.expansion, isNull);
    final oldLimited = formatRational(
      value,
      format: RationalDisplayFormat.exactDecimal,
      maxDecimalPlaces: 2,
      maxGeneratedDigits: 1000,
    );
    expect(
      oldLimited.fallbackReason,
      RationalDisplayFallbackReason.decimalPlacesLimit,
    );
    expect(oldLimited.expansion, isNull);
    final fraction = formatRational(
      value,
      maxGeneratedDigits: 0,
      maxDecimalPlaces: 0,
    );
    expect(fraction.text, '1/8');
    expect(fraction.expansion, isNull);
  });

  test('bit sum accepts 100000 bits before ordinary output checks and rejects 100001', () {
    const outputMessage = 'Formatted output exceeds character budget';
    const bitMessage = 'Recurring expansion exceeds value bit budget';
    final acceptedMagnitude = BigInt.one << 99998;
    final rejectedMagnitude = BigInt.one << 99999;
    for (final sign in [BigInt.one, -BigInt.one]) {
      final atBoundary = Rational(sign, acceptedMagnitude);
      expect(
        atBoundary.numerator.abs().bitLength + atBoundary.denominator.bitLength,
        100000,
      );
      // The boundary passes the value guard, then the huge fraction fallback
      // independently exceeds its character budget. No huge text is needed.
      expect(
        () => recurring(atBoundary, digits: 0),
        throwsA(limit(outputMessage)),
      );
      final aboveBoundary = Rational(sign, rejectedMagnitude);
      expect(
        aboveBoundary.numerator.abs().bitLength +
            aboveBoundary.denominator.bitLength,
        100001,
      );
      expect(
        () => recurring(aboveBoundary, digits: 0),
        throwsA(limit(bitMessage)),
      );
    }
  });

  test(
    'new value guard covers integer numerator and precedes text generation',
    () {
      final integer = Rational(BigInt.one << 99999);
      expect(
        integer.numerator.bitLength + integer.denominator.bitLength,
        100001,
      );
      expect(
        () => recurring(integer, digits: 0, chars: 1),
        throwsA(limit('Recurring expansion exceeds value bit budget')),
      );
      for (final mode in [
        RationalDisplayFormat.fraction,
        RationalDisplayFormat.exactDecimal,
      ]) {
        expect(
          () => formatRational(integer, format: mode, maxOutputCharacters: 1),
          throwsA(limit('Formatted output exceeds character budget')),
        );
      }
    },
  );

  test('entire integer text is bounded including its sign', () {
    final value = Rational(-BigInt.from(10).pow(9999));
    expect(() => recurring(value, digits: 0, chars: 10000), throwsA(limit()));
    final fits = recurring(-value, digits: 0, chars: 10000);
    expect(fits.text.length, 10000);
    expect(fits.expansion!.integerDigits.length, 10000);
  });

  test('independent DTO reconstruction and shortest repeating block for small rationals', () {
    for (var numerator = -25; numerator <= 25; numerator++) {
      for (var denominator = 1; denominator <= 40; denominator++) {
        final value = Rational(
          BigInt.from(numerator),
          BigInt.from(denominator),
        );
        final display = recurring(value);
        final expansion = display.expansion!;
        expect(
          reconstruct(expansion),
          value,
          reason: '$numerator/$denominator',
        );
        expect(expansion.negative, numerator < 0);
        expect(
          RegExp(r'^(0|[1-9][0-9]*)$').hasMatch(expansion.integerDigits),
          isTrue,
        );
        final period = expansion.repeatingDigits;
        for (var length = 1; length < period.length; length++) {
          if (period.length % length == 0) {
            expect(
              period,
              isNot(period.substring(0, length) * (period.length ~/ length)),
              reason: 'Nonminimal period for $value',
            );
          }
        }
        expect(display.fallbackReason, isNull);
      }
    }
  });

  test(
    'later formatting does not mutate previous DTO or original rational',
    () {
      final value = Rational(BigInt.one, BigInt.from(12));
      final first = recurring(value);
      final expansion = first.expansion!;
      recurring(Rational(BigInt.from(-22), BigInt.from(7)));
      recurring(value, digits: 0);
      expect(first.text, '0,08(3)');
      expect(first.expansion, same(expansion));
      expect(expansion.nonRepeatingDigits, '08');
      expect(expansion.repeatingDigits, '3');
      expect(value.numerator, BigInt.one);
      expect(value.denominator, BigInt.from(12));
    },
  );

  test('existing snapshots can request recurring output without changing exact Ans', () {
    final linear = CalculatorSession();
    final structured = StructuredCalculatorSession();
    for (final id in ['KEY_1', 'KEY_DIVIDE', 'KEY_6', 'KEY_EQUALS']) {
      linear.pressId(id);
      structured.pressId(id);
    }
    final oldLinear = linear.snapshot;
    final oldStructured = structured.snapshot;
    linear.selectResultDisplayFormat(
      RationalDisplayFormat.exactRecurringDecimal,
    );
    structured.selectResultDisplayFormat(
      RationalDisplayFormat.exactRecurringDecimal,
    );
    expect(linear.snapshot.formatResult()!.text, '0,1(6)');
    expect(structured.snapshot.formatResult()!.text, '0,1(6)');
    expect(linear.snapshot.answer, same(oldLinear.answer));
    expect(structured.snapshot.answer, same(oldStructured.answer));
    expect(oldLinear.formatResult()!.text, '1/6');
    expect(oldStructured.formatResult()!.text, '1/6');
    final selected = structured.snapshot;
    structured.snapshot.formatResult();
    expect(structured.snapshot, same(selected));
  });
}
