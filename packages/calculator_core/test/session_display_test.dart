import 'package:calculator_core/calculator_core.dart';
import 'package:test/test.dart';

const fractionFormat = RationalDisplayFormat.fraction;
const decimalFormat = RationalDisplayFormat.exactDecimal;

CalculatorKey keyFor(String token) => switch (token) {
  '+' => CalculatorKey.add,
  '-' => CalculatorKey.subtract,
  '*' => CalculatorKey.multiply,
  '/' => CalculatorKey.divide,
  '^' => CalculatorKey.power,
  '(' => CalculatorKey.leftParenthesis,
  ')' => CalculatorKey.rightParenthesis,
  _ => CalculatorKey.fromId('KEY_$token')!,
};

void enterLinear(CalculatorSession session, String expression) {
  for (final token in expression.split('')) {
    session.press(keyFor(token));
  }
}

void enterStructured(StructuredCalculatorSession session, String expression) {
  for (final token in expression.split('')) {
    session.press(keyFor(token));
  }
}

CalculatorSession linearResult(String expression) {
  final session = CalculatorSession();
  enterLinear(session, expression);
  expect(session.press(CalculatorKey.equals).phase, CalculatorPhase.result);
  return session;
}

StructuredCalculatorSession structuredResult(String top, String bottom) {
  final session = StructuredCalculatorSession();
  session.pressId('KEY_FRACTION');
  enterStructured(session, top);
  session.pressId('KEY_DOWN');
  enterStructured(session, bottom);
  expect(session.press(CalculatorKey.equals).phase, CalculatorPhase.result);
  return session;
}

void sameLinearValues(CalculatorSnapshot before, CalculatorSnapshot after) {
  expect(after.phase, before.phase);
  expect(identical(after.tokens, before.tokens), isTrue);
  expect(after.expression, before.expression);
  expect(after.cursor, before.cursor);
  expect(after.cursorOffset, before.cursorOffset);
  expect(identical(after.answer, before.answer), isTrue);
  expect(identical(after.result, before.result), isTrue);
  expect(identical(after.error, before.error), isTrue);
}

void sameStructuredValues(
  StructuredCalculatorSnapshot before,
  StructuredCalculatorSnapshot after,
) {
  expect(identical(after.editor, before.editor), isTrue);
  expect(after.phase, before.phase);
  expect(identical(after.answer, before.answer), isTrue);
  expect(identical(after.result, before.result), isTrue);
  expect(identical(after.error, before.error), isTrue);
  expect(identical(after.errorCursor, before.errorCursor), isTrue);
}

Matcher outputLimit() => throwsA(
  isA<CalculatorException>().having(
    (error) => error.code,
    'code',
    CalculatorErrorCode.limit,
  ),
);

void main() {
  group('linear result display choice', () {
    test(
      'choice changes only format and old snapshots retain their own text',
      () {
        final session = linearResult('3/8');
        final original = session.snapshot;
        expect(original.resultDisplayFormat, fractionFormat);
        expect(original.formatResult()!.text, '3/8');
        final selected = session.selectResultDisplayFormat(decimalFormat);
        sameLinearValues(original, selected);
        expect(identical(original, selected), isFalse);
        expect(identical(session.snapshot, selected), isTrue);
        expect(selected.resultDisplayFormat, decimalFormat);
        expect(selected.formatResult()!.text, '0,375');
        expect(selected.formatResult()!.fallbackReason, isNull);
        final restored = session.selectResultDisplayFormat(fractionFormat);
        sameLinearValues(original, restored);
        expect(restored.formatResult()!.text, '3/8');
        expect(original.resultDisplayFormat, fractionFormat);
        expect(original.formatResult()!.text, '3/8');
        expect(selected.resultDisplayFormat, decimalFormat);
        expect(selected.formatResult()!.text, '0,375');
      },
    );

    test('same choice and equals after result are identical no-ops', () {
      final session = linearResult('1/8');
      final original = session.snapshot;
      expect(
        identical(session.selectResultDisplayFormat(fractionFormat), original),
        isTrue,
      );
      final selected = session.selectResultDisplayFormat(decimalFormat);
      expect(
        identical(session.selectResultDisplayFormat(decimalFormat), selected),
        isTrue,
      );
      expect(identical(session.press(CalculatorKey.equals), selected), isTrue);
      expect(session.snapshot.formatResult()!.text, '0,125');
    });

    test('periodic fallback preserves desired format and exact result/Ans', () {
      final session = linearResult('1/3');
      final selected = session.selectResultDisplayFormat(decimalFormat);
      final display = selected.formatResult()!;
      expect(display.text, '1/3');
      expect(display.format, fractionFormat);
      expect(display.fallbackReason, RationalDisplayFallbackReason.periodic);
      expect(selected.resultDisplayFormat, decimalFormat);
      expect(identical(session.snapshot, selected), isTrue);
      session.press(CalculatorKey.multiply);
      session.press(CalculatorKey.digit3);
      final next = session.press(CalculatorKey.equals);
      expect(next.result, Rational.fromInt(1));
      expect(next.resultDisplayFormat, fractionFormat);
      expect(selected.answer.toString(), '1/3');
      expect(selected.formatResult()!.text, '1/3');
    });

    test('place-limited fallback is a per-call decision rather than a choice change', () {
      final session = linearResult('1/2');
      final selected = session.selectResultDisplayFormat(decimalFormat);
      final limited = selected.formatResult(maxDecimalPlaces: 0)!;
      expect(limited.text, '1/2');
      expect(limited.format, fractionFormat);
      expect(
        limited.fallbackReason,
        RationalDisplayFallbackReason.decimalPlacesLimit,
      );
      expect(selected.formatResult(maxDecimalPlaces: 1)!.text, '0,5');
      expect(identical(session.snapshot, selected), isTrue);
      expect(selected.resultDisplayFormat, decimalFormat);
    });

    test(
      'format errors leave the result phase, exact values and choice untouched',
      () {
        final session = linearResult('-1/8');
        final selected = session.selectResultDisplayFormat(decimalFormat);
        expect(
          () => selected.formatResult(maxOutputCharacters: 5),
          outputLimit(),
        );
        expect(
          () => selected.formatResult(maxDecimalPlaces: -1),
          throwsArgumentError,
        );
        expect(
          () => selected.formatResult(maxOutputCharacters: 0),
          throwsArgumentError,
        );
        expect(identical(session.snapshot, selected), isTrue);
        expect(selected.phase, CalculatorPhase.result);
        expect(selected.error, isNull);
        expect(selected.resultDisplayFormat, decimalFormat);
        expect(selected.answer.toString(), '-1/8');
        expect(selected.formatResult(maxOutputCharacters: 6)!.text, '-0,125');
      },
    );

    test(
      'selection is lazy even when default formatting would exceed its budget',
      () {
        final session = linearResult('(10^1000)^3');
        final before = session.snapshot;
        final selected = session.selectResultDisplayFormat(decimalFormat);
        sameLinearValues(before, selected);
        expect(selected.resultDisplayFormat, decimalFormat);
        expect(() => selected.formatResult(), outputLimit());
        expect(identical(session.snapshot, selected), isTrue);
        final display = selected.formatResult(maxOutputCharacters: 3001)!;
        expect(display.text.length, 3001);
        expect(display.text[0], '1');
        expect(display.text.endsWith('0000'), isTrue);
        expect(display.format, decimalFormat);
      },
    );

    for (final id in [
      'KEY_7',
      'KEY_ADD',
      'KEY_LEFT',
      'KEY_RIGHT',
      'KEY_DEL',
      'KEY_AC',
    ]) {
      test(
        '$id starts editing with fraction choice without changing saved snapshots',
        () {
          final session = linearResult('3/8');
          final selected = session.selectResultDisplayFormat(decimalFormat);
          final edit = session.pressId(id);
          expect(edit.phase, CalculatorPhase.editing);
          expect(edit.resultDisplayFormat, fractionFormat);
          expect(edit.formatResult(), isNull);
          expect(edit.answer.toString(), '3/8');
          expect(selected.resultDisplayFormat, decimalFormat);
          expect(selected.formatResult()!.text, '0,375');
        },
      );
    }

    test('editing/error selection is an identical no-op and ignores unused budgets', () {
      final session = CalculatorSession();
      final empty = session.snapshot;
      expect(empty.resultDisplayFormat, fractionFormat);
      expect(
        empty.formatResult(maxDecimalPlaces: -1, maxOutputCharacters: 0),
        isNull,
      );
      expect(
        identical(session.selectResultDisplayFormat(decimalFormat), empty),
        isTrue,
      );
      enterLinear(session, '1/0');
      final editing = session.snapshot;
      expect(
        editing.formatResult(
          maxDecimalPlaces: 1001,
          maxOutputCharacters: 10001,
        ),
        isNull,
      );
      expect(
        identical(session.selectResultDisplayFormat(decimalFormat), editing),
        isTrue,
      );
      final failed = session.press(CalculatorKey.equals);
      expect(failed.error?.code, CalculatorErrorCode.math);
      expect(failed.resultDisplayFormat, fractionFormat);
      expect(
        failed.formatResult(maxDecimalPlaces: -1, maxOutputCharacters: 0),
        isNull,
      );
      for (final format in RationalDisplayFormat.values) {
        expect(
          identical(session.selectResultDisplayFormat(format), failed),
          isTrue,
        );
      }
      expect(identical(session.snapshot.error, failed.error), isTrue);
    });

    test('later calculation failure resets choice but cannot modify an older display', () {
      final session = linearResult('1/8');
      final selected = session.selectResultDisplayFormat(decimalFormat);
      enterLinear(session, '1/0');
      final failed = session.press(CalculatorKey.equals);
      expect(failed.resultDisplayFormat, fractionFormat);
      expect(failed.answer.toString(), '1/8');
      expect(failed.formatResult(), isNull);
      expect(selected.formatResult()!.text, '0,125');
    });

    test('new successful result defaults to fraction while old decimal text is stable', () {
      final session = linearResult('1/8');
      final selected = session.selectResultDisplayFormat(decimalFormat);
      session.press(CalculatorKey.reciprocal);
      final next = session.press(CalculatorKey.equals);
      expect(next.result, Rational.fromInt(8));
      expect(next.answer, Rational.fromInt(8));
      expect(next.resultDisplayFormat, fractionFormat);
      expect(next.formatResult()!.text, '8');
      expect(selected.formatResult()!.text, '0,125');
      expect(selected.result.toString(), '1/8');
    });

    test(
      'KEY_SD remains unsupported with result and display choice unchanged',
      () {
        final session = linearResult('1/8');
        final selected = session.selectResultDisplayFormat(decimalFormat);
        expect(CalculatorKey.fromId('KEY_SD'), isNull);
        expect(CalculatorKey.values, hasLength(30));
        expect(
          () => session.pressId('KEY_SD'),
          throwsA(isA<CalculatorException>()),
        );
        expect(identical(session.snapshot, selected), isTrue);
      },
    );
  });

  group('structured result display choice', () {
    test('choice preserves the whole editor, inner cursor and numerical references', () {
      final session = structuredResult('3', '8');
      final original = session.snapshot;
      expect(
        original.editor.cursor.path.single.field,
        FractionField.denominator,
      );
      expect(original.editor.cursor.offset, 1);
      expect(original.resultDisplayFormat, fractionFormat);
      expect(original.formatResult()!.text, '3/8');
      final selected = session.selectResultDisplayFormat(decimalFormat);
      sameStructuredValues(original, selected);
      expect(identical(original, selected), isFalse);
      expect(selected.formatResult()!.text, '0,375');
      final restored = session.selectResultDisplayFormat(fractionFormat);
      sameStructuredValues(original, restored);
      expect(restored.formatResult()!.text, '3/8');
      expect(original.formatResult()!.text, '3/8');
      expect(selected.formatResult()!.text, '0,375');
      expect(original.resultDisplayFormat, fractionFormat);
      expect(selected.resultDisplayFormat, decimalFormat);
    });

    test('same choice, equals and wrap after result are identical no-ops', () {
      final session = structuredResult('1', '8');
      final original = session.snapshot;
      expect(
        identical(session.selectResultDisplayFormat(fractionFormat), original),
        isTrue,
      );
      final selected = session.selectResultDisplayFormat(decimalFormat);
      expect(
        identical(session.selectResultDisplayFormat(decimalFormat), selected),
        isTrue,
      );
      expect(identical(session.press(CalculatorKey.equals), selected), isTrue);
      expect(
        identical(session.pressId('ACTION_WRAP_FRACTION'), selected),
        isTrue,
      );
      expect(selected.formatResult()!.text, '0,125');
    });

    test(
      'desired decimal and periodic fraction fallback are distinct states',
      () {
        final session = structuredResult('1', '3');
        final selected = session.selectResultDisplayFormat(decimalFormat);
        final display = selected.formatResult()!;
        expect(display.text, '1/3');
        expect(display.format, fractionFormat);
        expect(display.fallbackReason, RationalDisplayFallbackReason.periodic);
        expect(selected.resultDisplayFormat, decimalFormat);
        expect(identical(session.snapshot, selected), isTrue);
        session.press(CalculatorKey.multiply);
        session.press(CalculatorKey.digit3);
        final next = session.press(CalculatorKey.equals);
        expect(next.result, Rational.fromInt(1));
        expect(next.resultDisplayFormat, fractionFormat);
        expect(selected.formatResult()!.text, '1/3');
      },
    );

    test(
      'per-call place budget cannot overwrite the stored display choice',
      () {
        final session = structuredResult('1', '2');
        final selected = session.selectResultDisplayFormat(decimalFormat);
        final limited = selected.formatResult(maxDecimalPlaces: 0)!;
        expect(limited.text, '1/2');
        expect(limited.format, fractionFormat);
        expect(
          limited.fallbackReason,
          RationalDisplayFallbackReason.decimalPlacesLimit,
        );
        expect(selected.formatResult(maxDecimalPlaces: 1)!.text, '0,5');
        expect(selected.resultDisplayFormat, decimalFormat);
        expect(identical(session.snapshot, selected), isTrue);
      },
    );

    test(
      'format exceptions do not create a session error or move its cursor',
      () {
        final session = structuredResult('-1', '8');
        final selected = session.selectResultDisplayFormat(decimalFormat);
        expect(
          () => selected.formatResult(maxOutputCharacters: 5),
          outputLimit(),
        );
        expect(
          () => selected.formatResult(maxDecimalPlaces: -1),
          throwsArgumentError,
        );
        expect(
          () => selected.formatResult(maxOutputCharacters: 0),
          throwsArgumentError,
        );
        expect(identical(session.snapshot, selected), isTrue);
        expect(selected.phase, CalculatorPhase.result);
        expect(selected.error, isNull);
        expect(selected.errorCursor, isNull);
        expect(selected.answer.toString(), '-1/8');
        expect(selected.resultDisplayFormat, decimalFormat);
        expect(selected.formatResult(maxOutputCharacters: 6)!.text, '-0,125');
      },
    );

    test('large result selection does not eagerly attempt formatting', () {
      final session = StructuredCalculatorSession();
      enterStructured(session, '(10^1000)^3');
      final before = session.press(CalculatorKey.equals);
      expect(before.phase, CalculatorPhase.result);
      final selected = session.selectResultDisplayFormat(decimalFormat);
      sameStructuredValues(before, selected);
      expect(() => selected.formatResult(), outputLimit());
      expect(identical(session.snapshot, selected), isTrue);
      expect(
        selected.formatResult(maxOutputCharacters: 3001)!.text.length,
        3001,
      );
    });

    for (final id in [
      'KEY_7',
      'KEY_ADD',
      'KEY_LEFT',
      'KEY_RIGHT',
      'KEY_DEL',
      'KEY_AC',
      'KEY_FRACTION',
      'KEY_UP',
      'KEY_DOWN',
    ]) {
      test('$id resets requested format on structured editing transition', () {
        final session = structuredResult('3', '8');
        final selected = session.selectResultDisplayFormat(decimalFormat);
        final edit = session.pressId(id);
        expect(edit.phase, CalculatorPhase.editing);
        expect(edit.resultDisplayFormat, fractionFormat);
        expect(edit.formatResult(), isNull);
        expect(edit.answer.toString(), '3/8');
        expect(edit.error, isNull);
        expect(edit.errorCursor, isNull);
        expect(selected.resultDisplayFormat, decimalFormat);
        expect(selected.formatResult()!.text, '0,375');
      });
    }

    test('editing and error selection preserve identity and ignore irrelevant budgets', () {
      final session = StructuredCalculatorSession();
      final empty = session.snapshot;
      expect(empty.resultDisplayFormat, fractionFormat);
      expect(
        empty.formatResult(maxDecimalPlaces: -1, maxOutputCharacters: 0),
        isNull,
      );
      expect(
        identical(session.selectResultDisplayFormat(decimalFormat), empty),
        isTrue,
      );
      session.pressId('KEY_FRACTION');
      final incomplete = session.snapshot;
      expect(
        incomplete.formatResult(
          maxDecimalPlaces: 1001,
          maxOutputCharacters: 10001,
        ),
        isNull,
      );
      expect(
        identical(session.selectResultDisplayFormat(decimalFormat), incomplete),
        isTrue,
      );
      final failed = session.press(CalculatorKey.equals);
      expect(failed.error?.code, CalculatorErrorCode.syntax);
      expect(failed.errorCursor, isNotNull);
      expect(failed.resultDisplayFormat, fractionFormat);
      expect(
        failed.formatResult(maxDecimalPlaces: -1, maxOutputCharacters: 0),
        isNull,
      );
      for (final format in RationalDisplayFormat.values) {
        expect(
          identical(session.selectResultDisplayFormat(format), failed),
          isTrue,
        );
      }
      expect(identical(session.snapshot.editor, failed.editor), isTrue);
      expect(identical(session.snapshot.error, failed.error), isTrue);
      expect(
        identical(session.snapshot.errorCursor, failed.errorCursor),
        isTrue,
      );
      expect(
        identical(session.pressId('ACTION_WRAP_FRACTION'), failed),
        isTrue,
      );
    });

    test('later math error and recovery reset format while saved decimal remains valid', () {
      final session = structuredResult('1', '8');
      final selected = session.selectResultDisplayFormat(decimalFormat);
      enterStructured(session, '1/0');
      final failed = session.press(CalculatorKey.equals);
      expect(failed.error?.code, CalculatorErrorCode.math);
      expect(failed.resultDisplayFormat, fractionFormat);
      expect(failed.answer.toString(), '1/8');
      expect(failed.formatResult(), isNull);
      expect(selected.formatResult()!.text, '0,125');
      final edit = session.pressId('KEY_UP');
      expect(edit.phase, CalculatorPhase.editing);
      expect(edit.resultDisplayFormat, fractionFormat);
      expect(edit.errorCursor, isNull);
    });

    test('new exact result begins as fraction independently of old decimal snapshot', () {
      final session = structuredResult('1', '8');
      final selected = session.selectResultDisplayFormat(decimalFormat);
      session.press(CalculatorKey.reciprocal);
      final next = session.press(CalculatorKey.equals);
      expect(next.result, Rational.fromInt(8));
      expect(next.answer, Rational.fromInt(8));
      expect(next.resultDisplayFormat, fractionFormat);
      expect(next.formatResult()!.text, '8');
      expect(selected.result.toString(), '1/8');
      expect(selected.formatResult()!.text, '0,125');
    });

    test(
      'KEY_SD remains unsupported without losing the requested decimal mode',
      () {
        final session = structuredResult('1', '8');
        final selected = session.selectResultDisplayFormat(decimalFormat);
        expect(CalculatorKey.fromId('KEY_SD'), isNull);
        expect(
          () => session.pressId('KEY_SD'),
          throwsA(isA<CalculatorException>()),
        );
        expect(identical(session.snapshot, selected), isTrue);
      },
    );
  });

  test('two linear sessions and structured input maintain independent choices and Ans', () {
    final first = linearResult('1/8');
    final second = linearResult('2/3');
    final structured = structuredResult('3', '8');
    first.selectResultDisplayFormat(decimalFormat);
    expect(first.snapshot.formatResult()!.text, '0,125');
    expect(second.snapshot.resultDisplayFormat, fractionFormat);
    expect(structured.snapshot.resultDisplayFormat, fractionFormat);
    structured.selectResultDisplayFormat(decimalFormat);
    expect(structured.snapshot.formatResult()!.text, '0,375');
    expect(second.snapshot.formatResult()!.text, '2/3');
    first.selectResultDisplayFormat(fractionFormat);
    expect(first.snapshot.formatResult()!.text, '1/8');
    expect(structured.snapshot.resultDisplayFormat, decimalFormat);
    expect(structured.snapshot.answer.toString(), '3/8');
    expect(second.snapshot.answer.toString(), '2/3');
  });

  test('zero remains a present result rather than being mistaken for missing output', () {
    final linear = linearResult('0');
    final structured = structuredResult('0', '1');
    expect(
      linear.selectResultDisplayFormat(decimalFormat).formatResult()!.text,
      '0',
    );
    expect(
      structured.selectResultDisplayFormat(decimalFormat).formatResult()!.text,
      '0',
    );
  });
}
