import 'package:calculator_core/calculator_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fx991_calculator/application/calculator_controller.dart';
import 'package:fx991_calculator/application/key_layout.dart';
import 'package:fx991_calculator/main.dart';
import 'package:fx991_calculator/presentation/editor/fraction_expression_view.dart';

const ids = <String, String>{
  '+': 'KEY_ADD',
  '-': 'KEY_SUBTRACT',
  '*': 'KEY_MULTIPLY',
  '/': 'KEY_DIVIDE',
  '(': 'KEY_LPAREN',
  ')': 'KEY_RPAREN',
};
List<String> entry(String value) => [
  for (final character in value.split('')) ids[character] ?? 'KEY_$character',
];
void press(CalculatorController c, Iterable<String> keys) {
  for (final key in keys) {
    c.pressId(key);
  }
}

CalculatorController controller(bool math) => CalculatorController()
  ..selectInputOutput(
    math ? CalculatorInputOutput.mathMath : CalculatorInputOutput.linearLinear,
  );
Object snapshot(CalculatorController c) =>
    c.fractions ? c.structured.snapshot : c.session.snapshot;
CalculatorException? error(CalculatorController c) =>
    c.fractions ? c.structured.snapshot.error : c.session.snapshot.error;
bool hasIndicator(CalculatorController c) =>
    c.displayStatus.split(RegExp(r'\s+')).contains('M');

Finder keyed(String id) => find.byKey(ValueKey(id));
Future<void> boot(
  WidgetTester tester,
  bool math, {
  Size size = const Size(800, 1000),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(const CalculatorApp());
  await tester.pumpAndSettle();
  await tap(tester, math ? 'input-fractions' : 'input-linear');
}

Future<void> tap(WidgetTester tester, String id) async {
  await tester.ensureVisible(keyed(id));
  await tester.pumpAndSettle();
  await tester.tap(keyed(id));
  await tester.pumpAndSettle();
}

Future<void> taps(WidgetTester tester, Iterable<String> keys) async {
  for (final key in keys) {
    await tap(tester, key);
  }
}

String text(WidgetTester tester, String id) =>
    tester.widget<Text>(keyed(id)).data!;
bool widgetIndicator(WidgetTester tester) =>
    text(tester, 'display-status').split(RegExp(r'\s+')).contains('M');

void main() {
  for (final math in [false, true]) {
    final mode = math ? 'Math' : 'Linear';
    test(
      '$mode enables the existing M key without expanding the core registry',
      () {
        final c = controller(math);
        final physical = calculatorRows.expand((row) => row).toList();
        expect(physical, hasLength(50));
        expect(physical.map((key) => key.id).toSet(), hasLength(50));
        expect(
          physical.where((key) => c.isKeyEnabled(key.id)),
          hasLength(math ? 35 : 32),
        );
        expect(CalculatorKey.values, hasLength(33));
        expect(c.isKeyEnabled('KEY_M_PLUS'), isTrue);
        expect(hasIndicator(c), isFalse);
      },
    );

    test('$mode H p18 M+ then SHIFT M+ displays 15 and stores 35', () {
      final c = controller(math);
      press(c, [...entry('10*5'), 'KEY_M_PLUS']);
      expect(c.resultText, '50');
      press(c, [...entry('10+5'), 'KEY_SHIFT', 'KEY_M_PLUS']);
      expect(c.resultText, '15');
      expect(c.memory.snapshot.answer, Rational.fromInt(15));
      expect(c.memory.snapshot.memory, Rational.fromInt(35));
      expect(c.shift, isFalse);
      expect(c.notice, '');
      expect(hasIndicator(c), isTrue);
    });

    test(
      '$mode thirds accumulate exactly and repeated result subtraction cancels M',
      () {
        final c = controller(math);
        press(c, [...entry('1/3'), 'KEY_M_PLUS', 'KEY_M_PLUS', 'KEY_M_PLUS']);
        expect(c.memory.snapshot.memory, Rational.fromInt(1));
        for (var count = 0; count < 3; count++) {
          press(c, ['KEY_SHIFT', 'KEY_M_PLUS']);
        }
        expect(c.memory.snapshot.memory, Rational.fromInt(0));
        expect(c.resultText, '1/3');
        expect(c.memory.snapshot.answer.toString(), '1/3');
        expect(hasIndicator(c), isFalse);
      },
    );

    test(
      '$mode negative M sets the indicator and subtraction reverses sign',
      () {
        final c = controller(math);
        press(c, [...entry('2'), 'KEY_SHIFT', 'KEY_M_PLUS']);
        expect(c.memory.snapshot.memory, Rational.fromInt(-2));
        expect(hasIndicator(c), isTrue);
        press(c, ['KEY_AC', 'KEY_NEGATE', 'KEY_2', 'KEY_SHIFT', 'KEY_M_PLUS']);
        expect(c.memory.snapshot.memory, Rational.fromInt(0));
        expect(c.resultText, '-2');
        expect(hasIndicator(c), isFalse);
      },
    );

    test(
      '$mode M+ after result uses stored operand despite newer shared Ans',
      () {
        final c = controller(math);
        press(c, [
          ...entry('2'),
          'KEY_EQUALS',
          'KEY_ADD',
          'KEY_1',
          'KEY_EQUALS',
        ]);
        final other = math
            ? CalculatorInputOutput.linearLinear
            : CalculatorInputOutput.mathMath;
        c.selectInputOutput(other);
        press(c, ['KEY_9', 'KEY_EQUALS']);
        c.selectInputOutput(
          math
              ? CalculatorInputOutput.mathMath
              : CalculatorInputOutput.linearLinear,
        );
        c.pressId('KEY_M_PLUS');
        expect(c.resultText, '3');
        expect(c.memory.snapshot.memory, Rational.fromInt(3));
        expect(c.memory.snapshot.answer, Rational.fromInt(3));
      },
    );

    for (final (source, code) in [
      ('1+', CalculatorErrorCode.syntax),
      ('1/0', CalculatorErrorCode.math),
    ]) {
      test('$mode $code preserves both registers and freezes M actions', () {
        final c = controller(math);
        press(c, ['KEY_7', 'KEY_M_PLUS', 'KEY_AC', ...entry(source)]);
        final before = c.memory.snapshot;
        c.pressId('KEY_M_PLUS');
        expect(c.phase, CalculatorPhase.error);
        expect(error(c)!.code, code);
        expect(c.memory.snapshot, same(before));
        final failed = snapshot(c);
        press(c, ['KEY_SHIFT', 'KEY_M_PLUS']);
        expect(snapshot(c), same(failed));
        expect(c.memory.snapshot, same(before));
        expect(c.shift, isFalse);
      });
    }

    test('$mode accumulated size limit cannot partially update Ans', () {
      final c = controller(math);
      c.memory.acceptResult(
        Rational((BigInt.one << 99999) - BigInt.one),
        operation: MemoryOperation.store,
      );
      c.memory.calculate('7');
      final before = c.memory.snapshot;
      press(c, ['KEY_1', 'KEY_M_PLUS']);
      expect(c.phase, CalculatorPhase.error);
      expect(error(c)!.code, CalculatorErrorCode.limit);
      expect(c.memory.snapshot, same(before));
      expect(hasIndicator(c), isTrue);
      if (math) {
        expect(
          c.structured.snapshot.errorCursor,
          same(c.structured.snapshot.editor.cursor),
        );
      }
    });

    test(
      '$mode menu and OFF gate memory actions while empty M+ is harmless',
      () {
        final c = controller(math);
        final empty = c.memory.snapshot;
        c.pressId('KEY_M_PLUS');
        expect(c.memory.snapshot, same(empty));
        c.openSetup();
        expect(c.isKeyEnabled('KEY_M_PLUS'), isFalse);
        press(c, ['KEY_SHIFT', 'KEY_M_PLUS']);
        expect(c.memory.snapshot, same(empty));
        c.pressId('KEY_AC');
        press(c, ['KEY_SHIFT', 'KEY_AC']);
        expect(c.isKeyEnabled('KEY_M_PLUS'), isFalse);
        c.pressId('KEY_M_PLUS');
        expect(c.memory.snapshot, same(empty));
      },
    );

    test(
      '$mode AC and ON preserve M until its exact operand is subtracted',
      () {
        final c = controller(math);
        press(c, ['KEY_5', 'KEY_M_PLUS', 'KEY_AC', 'KEY_ON']);
        expect(c.memory.snapshot.memory, Rational.fromInt(5));
        expect(c.memory.snapshot.answer, Rational.fromInt(5));
        expect(hasIndicator(c), isTrue);
        press(c, ['KEY_5', 'KEY_SHIFT', 'KEY_M_PLUS']);
        expect(hasIndicator(c), isFalse);
      },
    );

    test('$mode M travels across input modes but not separate controllers', () {
      final c = controller(math);
      press(c, ['KEY_2', 'KEY_M_PLUS']);
      c.selectInputOutput(
        math
            ? CalculatorInputOutput.linearLinear
            : CalculatorInputOutput.mathMath,
      );
      expect(hasIndicator(c), isTrue);
      press(c, ['KEY_1', 'KEY_M_PLUS']);
      expect(c.memory.snapshot.memory, Rational.fromInt(3));
      final independent = controller(math);
      expect(hasIndicator(independent), isFalse);
      expect(independent.memory.snapshot.answer, Rational.fromInt(0));
    });

    testWidgets(
      '$mode screen M keys run the handbook sequence and announce M',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          await boot(tester, math);
          await taps(tester, [
            ...entry('10*5'),
            'KEY_M_PLUS',
            ...entry('10+5'),
            'KEY_SHIFT',
            'KEY_M_PLUS',
          ]);
          expect(text(tester, 'display-result'), '15');
          expect(text(tester, 'display-answer'), 'Ans: 15');
          expect(widgetIndicator(tester), isTrue);
          expect(
            tester.widget<Text>(keyed('display-status')).semanticsLabel,
            contains('Unabhängiger Speicher M belegt'),
          );
          expect(
            find.bySemanticsLabel(RegExp('Unabhängiger Speicher M belegt')),
            findsOneWidget,
          );
          await taps(tester, [
            'KEY_AC',
            ...entry('35'),
            'KEY_SHIFT',
            'KEY_M_PLUS',
          ]);
          expect(widgetIndicator(tester), isFalse);
          expect(text(tester, 'display-result'), '35');
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      },
    );

    testWidgets('$mode M control and indicator fit a 320 pixel phone', (
      tester,
    ) async {
      await boot(tester, math, size: const Size(320, 568));
      await taps(tester, ['KEY_1', 'KEY_SHIFT', 'KEY_M_PLUS']);
      expect(widgetIndicator(tester), isTrue);
      expect(text(tester, 'display-result'), '1');
      await taps(tester, ['KEY_AC', 'KEY_1', 'KEY_M_PLUS']);
      expect(widgetIndicator(tester), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '$mode failed M action retains error until navigation correction',
      (tester) async {
        await boot(tester, math);
        await taps(tester, [
          'KEY_7',
          'KEY_M_PLUS',
          'KEY_AC',
          'KEY_1',
          'KEY_ADD',
          'KEY_M_PLUS',
        ]);
        expect(text(tester, 'display-result'), 'Syntaxfehler');
        expect(text(tester, 'display-answer'), 'Ans: 7');
        expect(widgetIndicator(tester), isTrue);
        if (math) {
          expect(keyed('formula-error'), findsOneWidget);
          final view = tester.widget<FractionExpressionView>(
            find.byType(FractionExpressionView),
          );
          expect(view.errorCursor, isNotNull);
        }
        await taps(tester, ['KEY_SHIFT', 'KEY_M_PLUS']);
        expect(text(tester, 'display-result'), 'Syntaxfehler');
        await taps(tester, ['KEY_LEFT', 'KEY_2', 'KEY_M_PLUS']);
        expect(text(tester, 'display-result'), '3');
        await taps(tester, [
          'KEY_AC',
          ...entry('10'),
          'KEY_SHIFT',
          'KEY_M_PLUS',
        ]);
        expect(widgetIndicator(tester), isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final io in [
    CalculatorInputOutput.mathDecimal,
    CalculatorInputOutput.linearDecimal,
  ]) {
    test(
      '$io M arithmetic follows decimal IO while preserving exact registers',
      () {
        final c = CalculatorController()..selectInputOutput(io);
        press(c, [...entry('1/8'), 'KEY_M_PLUS']);
        expect(c.resultText, '0,125');
        expect(c.memory.snapshot.answer.toString(), '1/8');
        expect(c.memory.snapshot.memory.toString(), '1/8');
        c.pressId('KEY_SD');
        expect(c.resultText, '1/8');
        expect(c.memory.snapshot.memory.toString(), '1/8');
      },
    );
  }

  testWidgets(
    'hardware digits and Enter do not double-apply a focused M button',
    (tester) async {
      await boot(tester, false);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.digit2, character: '2');
      await tester.sendKeyUpEvent(LogicalKeyboardKey.digit2);
      await tester.pumpAndSettle();
      await tap(tester, 'KEY_M_PLUS');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await taps(tester, ['KEY_SHIFT', 'KEY_M_PLUS']);
      expect(text(tester, 'display-result'), '2');
      expect(widgetIndicator(tester), isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
