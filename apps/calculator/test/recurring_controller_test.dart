import 'package:calculator_core/calculator_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fx991_calculator/application/calculator_controller.dart';

void _choose(CalculatorController c, String id) {
  for (var i = 0; i < 80; i++) {
    final index = c.menuItems.indexWhere((item) => item.id == id);
    if (index >= 0) {
      c.selectMenuItem(index);
      return;
    }
    c.menuMove(1);
  }
  fail('No menu item $id');
}

void _setting(CalculatorController c, List<String> path) {
  c.openSetup();
  for (final id in path) {
    _choose(c, id);
  }
  c.pressId('KEY_AC');
}

void _calculate(
  CalculatorController c,
  String expression, {
  bool shiftEquals = false,
}) {
  c.pressId('KEY_AC');
  for (final ch in expression.split('')) {
    c.pressId(switch (ch) {
      '/' => 'KEY_DIVIDE',
      '-' => 'KEY_SUBTRACT',
      '+' => 'KEY_ADD',
      '^' => 'KEY_POWER',
      '(' => 'KEY_LPAREN',
      ')' => 'KEY_RPAREN',
      _ => 'KEY_$ch',
    });
  }
  if (shiftEquals) c.pressId('KEY_SHIFT');
  c.pressId('KEY_EQUALS');
}

RationalDisplayFormat _choice(CalculatorController c) => c.fractions
    ? c.structured.snapshot.resultDisplayFormat
    : c.session.snapshot.resultDisplayFormat;
Rational _answer(CalculatorController c) =>
    c.fractions ? c.structured.snapshot.answer : c.session.snapshot.answer;

void main() {
  for (final io in [
    CalculatorInputOutput.mathMath,
    CalculatorInputOutput.linearLinear,
  ]) {
    test(
      '${io.name}: exact period, rounded, fraction cycle preserves result and Ans',
      () {
        final c = CalculatorController()..selectInputOutput(io);
        _calculate(c, '1/6');
        final result = c.result, answer = _answer(c);
        final oldLinear = c.session.snapshot,
            oldStructured = c.structured.snapshot;
        expect(c.resultPresentation.text, '1/6');
        c.pressId('KEY_SD');
        expect(_choice(c), RationalDisplayFormat.exactRecurringDecimal);
        final period = c.resultPresentation;
        expect(period.text, '0,1(6)');
        expect(period.periodPrefix, '0,1');
        expect(period.expansion!.repeatingDigits, '6');
        expect(period.fallbackReason, isNull);
        expect(c.result, same(result));
        expect(_answer(c), same(answer));
        c.pressId('KEY_EQUALS');
        expect(_choice(c), RationalDisplayFormat.exactRecurringDecimal);
        c.pressId('KEY_SD');
        expect(c.resultText, '0,1666666667');
        expect(_choice(c), RationalDisplayFormat.exactDecimal);
        expect(c.resultPresentation.expansion, isNull);
        c.pressId('KEY_SD');
        expect(c.resultText, '1/6');
        expect(c.result, same(result));
        expect(_answer(c), same(answer));
        expect(period.text, '0,1(6)');
        expect(period.expansion!.repeatingDigits, '6');
        expect(oldLinear.resultDisplayFormat, RationalDisplayFormat.fraction);
        expect(
          oldStructured.resultDisplayFormat,
          RationalDisplayFormat.fraction,
        );
      },
    );

    test(
      '${io.name}: finite values and integers skip exact-recurring state',
      () {
        final c = CalculatorController()..selectInputOutput(io);
        for (final pair in const [
          ('1/8', '1/8', '0,125'),
          ('12', '12', '12'),
          ('0', '0', '0'),
        ]) {
          _calculate(c, pair.$1);
          c.pressId('KEY_SD');
          expect(_choice(c), RationalDisplayFormat.exactDecimal);
          expect(c.resultText, pair.$3);
          expect(c.resultPresentation.periodPrefix, isNull);
          expect(c.resultPresentation.expansion, isNull);
          c.pressId('KEY_SD');
          expect(_choice(c), RationalDisplayFormat.fraction);
          expect(c.resultText, pair.$2);
        }
      },
    );

    test(
      '${io.name}: bounded unfinished cycle gives a nonmutating fallback presentation',
      () {
        final c = CalculatorController()..selectInputOutput(io);
        _calculate(c, '1/109');
        final answer = _answer(c), result = c.result;
        c.pressId('KEY_SD');
        final before = c.fractions ? c.structured.snapshot : c.session.snapshot;
        final notice = c.notice;
        final display = c.resultPresentation;
        expect(_choice(c), RationalDisplayFormat.exactRecurringDecimal);
        expect(display.text, '1/109');
        expect(
          display.fallbackReason,
          RationalDisplayFallbackReason.expansionLimit,
        );
        expect(display.expansion, isNull);
        expect(display.periodPrefix, isNull);
        expect(c.notice, notice);
        expect(
          c.fractions ? c.structured.snapshot : c.session.snapshot,
          same(before),
        );
        c.pressId('KEY_SD');
        expect(c.resultText, '9,174311927×10^-3');
        expect(c.resultPresentation.fallbackReason, isNull);
        expect(_answer(c), same(answer));
        expect(c.result, same(result));
        c.pressId('KEY_SD');
        expect(c.resultText, '1/109');
      },
    );

    test(
      '${io.name}: long finite development also enters bounded fallback then rounded',
      () {
        final c = CalculatorController()..selectInputOutput(io);
        _calculate(c, '1/(10^101)');
        c.pressId('KEY_SD');
        expect(
          c.resultPresentation.fallbackReason,
          RationalDisplayFallbackReason.expansionLimit,
        );
        expect(c.resultPresentation.expansion, isNull);
        c.pressId('KEY_SD');
        expect(c.resultText, '1×10^-101');
      },
    );

    test(
      '${io.name}: separate output limit does not escape S/D key event or mutate arithmetic',
      () {
        final c = CalculatorController()..selectInputOutput(io);
        _calculate(c, '(10^1000)^3/3');
        final result = c.result, answer = _answer(c);
        expect(() => c.pressId('KEY_SD'), returnsNormally);
        expect(_choice(c), RationalDisplayFormat.exactRecurringDecimal);
        expect(
          () => c.resultPresentation,
          throwsA(
            isA<CalculatorException>().having(
              (e) => e.code,
              'code',
              CalculatorErrorCode.limit,
            ),
          ),
        );
        expect(c.phase, CalculatorPhase.result);
        expect(c.result, same(result));
        expect(_answer(c), same(answer));
        c.pressId('KEY_SD');
        expect(c.resultText, '3,333333333×10^2999');
        expect(_answer(c), same(answer));
      },
    );

    test(
      '${io.name}: huge integer skips period classification and goes straight to Sci',
      () {
        final c = CalculatorController()..selectInputOutput(io);
        _calculate(c, '1000^1000');
        final answer = _answer(c), result = c.result;
        expect(() => c.pressId('KEY_SD'), returnsNormally);
        expect(_choice(c), RationalDisplayFormat.exactDecimal);
        expect(c.resultText, '1×10^3000');
        expect(c.resultPresentation.expansion, isNull);
        expect(c.result, same(result));
        expect(_answer(c), same(answer));
        c.pressId('KEY_SD');
        expect(_choice(c), RationalDisplayFormat.fraction);
      },
    );

    test('${io.name}: period disabled and Fix/Sci keep a two-state cycle', () {
      final c = CalculatorController()..selectInputOutput(io);
      for (final path in const [
        ['period', 'off'],
        ['number', 'fix', '2'],
        ['number', 'sci', '3'],
      ]) {
        _setting(c, path);
        _calculate(c, '1/6');
        c.pressId('KEY_SD');
        expect(_choice(c), RationalDisplayFormat.exactDecimal);
        expect(c.resultPresentation.expansion, isNull);
        c.pressId('KEY_SD');
        expect(_choice(c), RationalDisplayFormat.fraction);
      }
    });

    test(
      '${io.name}: editing/error S/D is noop and new arithmetic resets display choice',
      () {
        final c = CalculatorController()..selectInputOutput(io);
        final editing = c.fractions
            ? c.structured.snapshot
            : c.session.snapshot;
        c.pressId('KEY_SD');
        expect(
          c.fractions ? c.structured.snapshot : c.session.snapshot,
          same(editing),
        );
        expect(c.resultPresentation.text, '');
        _calculate(c, '1/6');
        c.pressId('KEY_SD');
        c.pressId('KEY_ADD');
        c.pressId('KEY_1');
        c.pressId('KEY_EQUALS');
        expect(_choice(c), RationalDisplayFormat.fraction);
        expect(c.resultText, '7/6');
        _calculate(c, '1/0');
        final error = c.fractions ? c.structured.snapshot : c.session.snapshot;
        c.pressId('KEY_SD');
        expect(
          c.fractions ? c.structured.snapshot : c.session.snapshot,
          same(error),
        );
        expect(c.resultPresentation.text, '');
      },
    );
  }

  test(
    'negative grouped period prefix is ready for overline without parsing',
    () {
      final c = CalculatorController();
      _setting(c, ['separator', 'on']);
      _calculate(c, '-1234567/6');
      c.pressId('KEY_SD');
      final presentation = c.resultPresentation;
      expect(presentation.text, '-205.761,1(6)');
      expect(presentation.periodPrefix, '-205.761,1');
      expect(presentation.expansion!.negative, isTrue);
      expect(presentation.expansion!.integerDigits, '205761');
      expect(presentation.expansion!.nonRepeatingDigits, '1');
      expect(presentation.expansion!.repeatingDigits, '6');
      expect(c.resultText, presentation.text);
    },
  );

  test(
    'zeroes in a pure cycle and preperiod are retained in prefix and DTO',
    () {
      final c = CalculatorController();
      _calculate(c, '1/11');
      c.pressId('KEY_SD');
      expect(c.resultPresentation.periodPrefix, '0,');
      expect(c.resultPresentation.expansion!.repeatingDigits, '09');
      _calculate(c, '1/12');
      c.pressId('KEY_SD');
      expect(c.resultPresentation.periodPrefix, '0,08');
      expect(c.resultPresentation.text, '0,08(3)');
    },
  );

  test('global period switch normalizes both snapshots but keeps all numeric/editor references', () {
    final c = CalculatorController();
    _calculate(c, '1/6');
    c.pressId('KEY_SD');
    final math = c.structured.snapshot;
    c.selectInputOutput(CalculatorInputOutput.linearLinear);
    _calculate(c, '1/3');
    c.pressId('KEY_SD');
    final linear = c.session.snapshot;
    expect(
      math.resultDisplayFormat,
      RationalDisplayFormat.exactRecurringDecimal,
    );
    expect(
      linear.resultDisplayFormat,
      RationalDisplayFormat.exactRecurringDecimal,
    );
    _setting(c, ['period', 'off']);
    expect(
      c.session.snapshot.resultDisplayFormat,
      RationalDisplayFormat.exactDecimal,
    );
    expect(
      c.structured.snapshot.resultDisplayFormat,
      RationalDisplayFormat.exactDecimal,
    );
    expect(c.session.snapshot.tokens, same(linear.tokens));
    expect(c.session.snapshot.answer, same(linear.answer));
    expect(c.session.snapshot.result, same(linear.result));
    expect(c.structured.snapshot.editor, same(math.editor));
    expect(c.structured.snapshot.answer, same(linear.answer));
    expect(math.answer, Rational(BigInt.one, BigInt.from(6)));
    expect(c.structured.snapshot.result, same(math.result));
    expect(c.resultText, '0,3333333333');
    _setting(c, ['period', 'on']);
    expect(_choice(c), RationalDisplayFormat.exactDecimal);
    expect(c.resultPresentation.expansion, isNull);
  });

  for (final path in const [
    ['number', 'fix', '2'],
    ['number', 'sci', '3'],
  ]) {
    test(
      '${path[1]} normalizes both prior period choices; Norm never auto-enters period',
      () {
        final c = CalculatorController();
        _calculate(c, '1/6');
        c.pressId('KEY_SD');
        c.selectInputOutput(CalculatorInputOutput.linearLinear);
        _calculate(c, '1/3');
        c.pressId('KEY_SD');
        final answer = c.session.snapshot.answer;
        _setting(c, path);
        expect(_choice(c), RationalDisplayFormat.exactDecimal);
        expect(
          c.structured.snapshot.resultDisplayFormat,
          RationalDisplayFormat.exactDecimal,
        );
        expect(c.resultText, path[1] == 'fix' ? '0,33' : '3,33×10^-1');
        expect(c.session.snapshot.answer, same(answer));
        _setting(c, ['number', 'norm', '2']);
        expect(_choice(c), RationalDisplayFormat.exactDecimal);
        expect(c.resultPresentation.expansion, isNull);
        c.pressId('KEY_SD');
        expect(_choice(c), RationalDisplayFormat.fraction);
        c.pressId('KEY_SD');
        expect(_choice(c), RationalDisplayFormat.exactRecurringDecimal);
      },
    );
  }

  for (final io in [
    CalculatorInputOutput.mathDecimal,
    CalculatorInputOutput.linearDecimal,
  ]) {
    test('${io.name}: decimal IO and SHIFT equals go straight to rounded', () {
      final c = CalculatorController()..selectInputOutput(io);
      _calculate(c, '1/6');
      expect(_choice(c), RationalDisplayFormat.exactDecimal);
      expect(c.resultText, '0,1666666667');
      expect(c.resultPresentation.expansion, isNull);
      c.pressId('KEY_SD');
      expect(_choice(c), RationalDisplayFormat.fraction);
      c.pressId('KEY_SD');
      expect(_choice(c), RationalDisplayFormat.exactRecurringDecimal);
      c.pressId('KEY_SHIFT');
      c.pressId('KEY_EQUALS');
      expect(_choice(c), RationalDisplayFormat.exactDecimal);
      expect(c.resultText, '0,1666666667');
    });
  }

  test(
    'SHIFT equals on Math IO is rounded, while SHIFT SD selects fraction form',
    () {
      final c = CalculatorController();
      _calculate(c, '7/3', shiftEquals: true);
      expect(c.resultText, '2,333333333');
      c.pressId('KEY_SD');
      c.pressId('KEY_SD');
      expect(c.resultText, '2,(3)');
      c.pressId('KEY_SHIFT');
      c.pressId('KEY_SD');
      expect(c.resultText, '2 1/3');
      expect(_choice(c), RationalDisplayFormat.fraction);
      expect(c.resultPresentation.expansion, isNull);
    },
  );

  test('period setup exposes real capability without enabling unrelated missing modes', () {
    final c = CalculatorController()..openSetup();
    for (var i = 0; i < 20; i++) {
      final items = c.menuItems.where((e) => e.id == 'period');
      if (items.isNotEmpty) {
        expect(items.single.capabilityStatus, 'Verfügbar');
        break;
      }
      c.menuMove(1);
    }
    _choose(c, 'period');
    expect(c.menuItems.every((i) => i.capabilityStatus == 'Verfügbar'), isTrue);
    expect(c.menuItems.first.selected, isTrue);
    c.pressId('KEY_AC');
    expect(c.isKeyEnabled('KEY_SIN'), isFalse);
  });

  test(
    'S/D leaves the synchronized other snapshot and old presentation untouched',
    () {
      final c = CalculatorController();
      _calculate(c, '1/6');
      c.pressId('KEY_SD');
      final math = c.structured.snapshot, presentation = c.resultPresentation;
      c.selectInputOutput(CalculatorInputOutput.linearLinear);
      _calculate(c, '1/7');
      final synchronized = c.structured.snapshot;
      expect(synchronized.answer, Rational(BigInt.one, BigInt.from(7)));
      expect(synchronized.editor, same(math.editor));
      expect(synchronized.result, same(math.result));
      expect(synchronized.resultDisplayFormat, math.resultDisplayFormat);
      c.pressId('KEY_SD');
      c.pressId('KEY_SD');
      expect(c.structured.snapshot, same(synchronized));
      expect(presentation.text, '0,1(6)');
      expect(presentation.expansion!.repeatingDigits, '6');
      c.selectInputOutput(CalculatorInputOutput.mathMath);
      expect(c.resultPresentation.text, '0,1(6)');
      c.pressId('KEY_MULTIPLY');
      c.pressId('KEY_6');
      c.pressId('KEY_EQUALS');
      expect(c.result, Rational(BigInt.from(6), BigInt.from(7)));
      expect(c.resultText, '6/7');
      expect(math.answer, Rational(BigInt.one, BigInt.from(6)));
    },
  );
}
