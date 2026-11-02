import 'dart:convert';
import 'dart:io';

import 'package:calculator_core/calculator_core.dart';
import 'package:test/test.dart';

// The unchanged fixtures supply independent, closed-form-verified expectations.
// This adapter does not derive decimal digits or reproduce long division.
File _findPlan() {
  var directory = Directory.current.absolute;
  while (true) {
    final candidate = File.fromUri(
      directory.uri.resolve(
        'tests/reference/formatting/recurring_decimal_planned.json',
      ),
    );
    if (candidate.existsSync()) return candidate;
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError('Cannot locate the recurring-decimal reference plan');
    }
    directory = parent;
  }
}

void main() {
  final plan =
      jsonDecode(_findPlan().readAsStringSync()) as Map<String, dynamic>;
  final cases = (plan['cases'] as List).cast<Map<String, dynamic>>();
  if (cases.length != 30 ||
      cases.map((fixture) => fixture['id']).toSet().length != 30) {
    throw StateError('Expected the thirty distinct unchanged reference cases');
  }

  group('independent recurring-decimal reference fixtures', () {
    for (final fixture in cases) {
      test(fixture['id'] as String, () {
        expect(plan['status'], 'planned');
        expect(plan['evidence'], 'ownMathematicalEvidence');
        expect(plan['originalDeviceVerified'], isFalse);
        expect(fixture['status'], 'planned');
        expect(fixture['evidence'], 'ownMathematicalEvidence');

        final input = fixture['input'] as Map<String, dynamic>;
        final value = Rational(
          BigInt.parse(input['numerator'] as String),
          BigInt.parse(input['denominator'] as String),
        );
        final numerator = value.numerator;
        final denominator = value.denominator;
        RationalDisplay render() => formatRational(
          value,
          format: RationalDisplayFormat.exactRecurringDecimal,
          maxGeneratedDigits: fixture['maxGeneratedDigits'] as int,
          maxOutputCharacters: fixture['maxOutputCharacters'] as int,
        );

        if (fixture['expectedError'] != null) {
          expect(fixture['expectedError'], 'limit');
          expect(fixture['expectedText'], isNull);
          expect(fixture['expectedFormat'], isNull);
          expect(
            render,
            throwsA(
              isA<CalculatorException>().having(
                (error) => error.code,
                'code',
                CalculatorErrorCode.limit,
              ),
            ),
          );
          // expectedFallback may describe a planning decision before the
          // output error. A throwing call returns no display or expansion DTO.
        } else {
          final display = render();
          expect(display.text, fixture['expectedText']);
          expect(
            display.format,
            RationalDisplayFormat.values.byName(
              fixture['expectedFormat'] as String,
            ),
          );
          final fallback = fixture['expectedFallback'] as String?;
          expect(
            display.fallbackReason,
            fallback == null
                ? isNull
                : RationalDisplayFallbackReason.values.byName(fallback),
          );
          if (fallback != null) {
            expect(display.expansion, isNull);
          } else {
            final components = fixture['components'] as Map<String, dynamic>;
            expect(display.expansion, isNotNull);
            final expansion = display.expansion!;
            expect(expansion.negative, (components['sign'] as int) < 0);
            expect(expansion.integerDigits, components['integerPart']);
            expect(expansion.nonRepeatingDigits, components['preperiod']);
            expect(expansion.repeatingDigits, components['period']);
          }
        }
        expect(value.numerator, numerator);
        expect(value.denominator, denominator);
      });
    }
  });
}
