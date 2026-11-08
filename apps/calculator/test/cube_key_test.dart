import 'package:calculator_core/calculator_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fx991_calculator/application/calculator_controller.dart';
import 'package:fx991_calculator/application/key_layout.dart';
import 'package:fx991_calculator/application/keyboard_mapping.dart';
import 'package:fx991_calculator/main.dart';
import 'package:fx991_calculator/presentation/editor/fraction_expression_view.dart';
import 'package:fx991_calculator/presentation/calculator/recurring_result_view.dart';

// Independent app-level expectations; prepared for the cloud test runner.
// The x³ action is a secondary legend, not a new physical keyboard position.
const _ids = <String, String>{
  '+': 'KEY_ADD',
  '-': 'KEY_NEGATE',
  '/': 'KEY_DIVIDE',
  '^': 'KEY_POWER',
  '(': 'KEY_LPAREN',
  ')': 'KEY_RPAREN',
  ',': 'KEY_DECIMAL',
  '²': 'KEY_SQUARE',
  'r': 'KEY_RECIPROCAL',
};

List<String> entryIds(String expression) => [
  for (final token in expression.replaceAll('⁻¹', 'r').split(''))
    if (token == '³') ...[
      'KEY_SHIFT',
      'KEY_SQUARE',
    ] else
      _ids[token] ?? 'KEY_$token',
];

CalculatorController controller(bool fractions) => CalculatorController()
  ..selectInputOutput(
    fractions
        ? CalculatorInputOutput.mathMath
        : CalculatorInputOutput.linearLinear,
  );

void pressAll(CalculatorController c, Iterable<String> ids) {
  for (final id in ids) {
    c.pressId(id);
  }
}

String controllerSource(CalculatorController c) => c.fractions
    ? c.structured.snapshot.editor.root.nodes
          .cast<EditorText>()
          .map((node) => node.text)
          .join()
    : c.session.snapshot.expression;

Rational controllerAnswer(CalculatorController c) =>
    c.fractions ? c.structured.snapshot.answer : c.session.snapshot.answer;

Object controllerSnapshot(CalculatorController c) =>
    c.fractions ? c.structured.snapshot : c.session.snapshot;

Finder keyed(String id) => find.byKey(ValueKey(id));

Future<void> boot(
  WidgetTester tester, {
  required bool fractions,
  Size size = const Size(800, 1000),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const CalculatorApp());
  await tester.pumpAndSettle();
  await tap(tester, fractions ? 'input-fractions' : 'input-linear');
}

Future<void> tap(WidgetTester tester, String id) async {
  await tester.ensureVisible(keyed(id));
  await tester.pumpAndSettle();
  await tester.tap(keyed(id));
  await tester.pumpAndSettle();
}

Future<void> taps(WidgetTester tester, Iterable<String> ids) async {
  for (final id in ids) {
    await tap(tester, id);
  }
}

Future<void> cube(WidgetTester tester) =>
    taps(tester, ['KEY_SHIFT', 'KEY_SQUARE']);

FractionExpressionView formula(WidgetTester tester) =>
    tester.widget<FractionExpressionView>(find.byType(FractionExpressionView));

String source(WidgetTester tester, bool fractions) => fractions
    ? formula(tester).snapshot.root.nodes
          .cast<EditorText>()
          .map((node) => node.text)
          .join()
    : tester
          .widget<Text>(keyed('display-expression'))
          .textSpan!
          .toPlainText()
          .replaceAll('│', '');

String result(WidgetTester tester) =>
    tester.widget<Text>(keyed('display-result')).data!;
String answer(WidgetTester tester) =>
    tester.widget<Text>(keyed('display-answer')).data!;

void main() {
  for (final fractions in [false, true]) {
    final mode = fractions ? 'Math' : 'Linear';

    test(
      '$mode controller keeps 50 physical positions and 33/36 active primary keys',
      () {
        final c = controller(fractions);
        final physical = calculatorRows.expand((row) => row).toList();
        expect(physical, hasLength(50));
        expect(physical.map((key) => key.id).toSet(), hasLength(50));
        expect(
          physical.where((key) => c.isKeyEnabled(key.id)),
          hasLength(fractions ? 36 : 33),
        );
        expect(physical.where((key) => key.id == 'ACTION_CUBE'), isEmpty);
        expect(CalculatorKey.values, hasLength(33));
        expect(CalculatorKey.fromId('ACTION_CUBE')!.text, '³');
      },
    );

    test(
      '$mode controller independently checks cube and postfix precedence',
      () {
        final c = controller(fractions);
        for (final (input, expected) in [
          ('-2³', '-8'),
          ('(-2)³', '-8'),
          ('3³³', '19683'),
          ('2³²', '64'),
          ('2²³', '64'),
          ('3³⁻¹', '1/27'),
          ('2^3³', '134217728'),
          ('2³^2', '64'),
        ]) {
          c.pressId('KEY_AC');
          pressAll(c, entryIds(input));
          expect(controllerSource(c), input, reason: input);
          expect(c.shift, isFalse);
          c.pressId('KEY_EQUALS');
          expect(c.resultText, expected, reason: input);
        }
      },
    );

    test(
      '$mode controller cubes exact negative fractional Ans after a result',
      () {
        final c = controller(fractions);
        pressAll(c, [...entryIds('-2/3'), 'KEY_EQUALS']);
        expect(c.resultText, '-2/3');
        pressAll(c, ['KEY_SHIFT', 'KEY_SQUARE']);
        expect(controllerSource(c), 'Ans³');
        expect(controllerAnswer(c).toString(), '-2/3');
        expect(c.phase, CalculatorPhase.editing);
        c.pressId('KEY_EQUALS');
        expect(c.resultText, '-8/27');
        c.pressId('KEY_AC');
        expect(controllerSource(c), '');
        expect(controllerAnswer(c).toString(), '-8/27');
      },
    );

    test(
      '$mode controller freezes cube syntax errors and recovers at the error cursor',
      () {
        final c = controller(fractions);
        pressAll(c, ['KEY_SHIFT', 'KEY_SQUARE', 'KEY_EQUALS']);
        expect(c.phase, CalculatorPhase.error);
        final failed = controllerSnapshot(c);
        pressAll(c, ['KEY_SHIFT', 'KEY_SQUARE']);
        expect(controllerSnapshot(c), same(failed));
        expect(c.shift, isFalse);
        expect(controllerAnswer(c), Rational.fromInt(0));
        pressAll(c, ['KEY_LEFT', 'KEY_2', 'KEY_EQUALS']);
        expect(c.resultText, '8');
      },
    );

    test(
      '$mode controller consumes SHIFT once and leaves other SHIFT/Basis-N pending',
      () {
        final c = controller(fractions);
        pressAll(c, [
          'KEY_2',
          'KEY_SHIFT',
          'KEY_SQUARE',
          'KEY_SQUARE',
          'KEY_EQUALS',
        ]);
        expect(controllerSource(c), '2³²');
        expect(c.resultText, '64');
        final completed = controllerSnapshot(c);
        pressAll(c, ['KEY_SHIFT', 'KEY_POWER']);
        expect(c.notice, contains('in Vorbereitung'));
        expect(c.shift, isFalse);
        expect(controllerSnapshot(c), same(completed));
        c.openModeMenu();
        c.selectMenuItem(
          c.menuItems.indexWhere((item) => item.id == 'Basis-N'),
        );
        expect(c.notice, contains('in Vorbereitung'));
        expect(controllerSnapshot(c), same(completed));
        expect(c.menuOpen, isFalse);
      },
    );

    test('$mode controller replaces a period view with exact Ans cubed', () {
      final c = controller(fractions);
      pressAll(c, [...entryIds('1/3'), 'KEY_EQUALS', 'KEY_SD']);
      expect(c.resultPresentation.expansion!.repeatingDigits, '3');
      pressAll(c, ['KEY_SHIFT', 'KEY_SQUARE']);
      expect(controllerSource(c), 'Ans³');
      expect(c.resultPresentation.text, '');
      expect(c.resultPresentation.expansion, isNull);
      c.pressId('KEY_EQUALS');
      expect(c.resultText, '1/27');
      expect(controllerAnswer(c).toString(), '1/27');
    });

    test('$mode controller cancels SHIFT and blocks cube in menus or OFF', () {
      final c = controller(fractions);
      pressAll(c, [
        'KEY_2',
        'KEY_SHIFT',
        'KEY_SHIFT',
        'KEY_SQUARE',
        'KEY_EQUALS',
      ]);
      expect(c.resultText, '4');
      final completed = controllerSnapshot(c);
      c.openSetup();
      pressAll(c, ['KEY_SHIFT', 'KEY_SQUARE']);
      expect(controllerSnapshot(c), same(completed));
      expect(c.menuOpen, isTrue);
      expect(c.shift, isFalse);
      pressAll(c, ['KEY_AC', 'KEY_SHIFT', 'KEY_AC']);
      expect(c.poweredOn, isFalse);
      pressAll(c, ['KEY_SHIFT', 'KEY_SQUARE']);
      expect(c.poweredOn, isFalse);
      expect(controllerSnapshot(c), same(completed));
      expect(c.shift, isFalse);
    });

    testWidgets('$mode physical SHIFT x² inserts cube and clears the latch', (
      tester,
    ) async {
      await boot(tester, fractions: fractions);
      await taps(tester, ['KEY_2', 'KEY_SHIFT']);
      expect(
        tester.widget<Text>(keyed('display-status')).data,
        contains('SHIFT'),
      );
      await tap(tester, 'KEY_SQUARE');
      expect(source(tester, fractions), '2³');
      expect(
        tester.widget<Text>(keyed('display-status')).data,
        isNot(contains('SHIFT')),
      );
      await taps(tester, ['KEY_SQUARE', 'KEY_EQUALS']);
      expect(result(tester), '64');
      expect(
        tester.widgetList<FilledButton>(find.byType(FilledButton)),
        hasLength(50),
      );
      expect(find.byKey(const ValueKey('ACTION_CUBE')), findsNothing);
    });

    testWidgets('$mode touch cube repeats and mixes with reciprocal in order', (
      tester,
    ) async {
      await boot(tester, fractions: fractions);
      await taps(tester, entryIds('3³³'));
      await tap(tester, 'KEY_EQUALS');
      expect(result(tester), '19683');
      await tap(tester, 'KEY_AC');
      await taps(tester, entryIds('3³⁻¹'));
      await tap(tester, 'KEY_EQUALS');
      expect(result(tester), '1/27');
    });

    testWidgets(
      '$mode result cube uses negative fractional Ans and AC retains it',
      (tester) async {
        await boot(tester, fractions: fractions);
        await taps(tester, [...entryIds('-2/3'), 'KEY_EQUALS']);
        await cube(tester);
        expect(source(tester, fractions), 'Ans³');
        expect(answer(tester), 'Ans: -2/3');
        await tap(tester, 'KEY_EQUALS');
        expect(result(tester), '-8/27');
        await tap(tester, 'KEY_AC');
        expect(source(tester, fractions), '');
        expect(answer(tester), 'Ans: -8/27');
      },
    );

    testWidgets(
      '$mode cube is one editable token in the middle and syntax recovers',
      (tester) async {
        await boot(tester, fractions: fractions);
        await taps(tester, ['KEY_2', 'KEY_3', 'KEY_LEFT']);
        await cube(tester);
        expect(source(tester, fractions), '2³3');
        await tap(tester, 'KEY_DEL');
        expect(source(tester, fractions), '23');
        await cube(tester);
        await taps(tester, ['KEY_ADD', 'KEY_EQUALS']);
        expect(result(tester), '11');
        await tap(tester, 'KEY_AC');
        await cube(tester);
        await tap(tester, 'KEY_EQUALS');
        expect(result(tester), 'Syntaxfehler');
        await cube(tester);
        expect(source(tester, fractions), '³');
        expect(result(tester), 'Syntaxfehler');
        await taps(tester, ['KEY_LEFT', 'KEY_2', 'KEY_EQUALS']);
        expect(result(tester), '8');
      },
    );

    testWidgets('$mode period selection remains exact when followed by cube', (
      tester,
    ) async {
      await boot(tester, fractions: fractions);
      await taps(tester, [...entryIds('1/3'), 'KEY_EQUALS', 'KEY_SD']);
      expect(find.byType(RecurringResultView), findsOneWidget);
      await cube(tester);
      expect(find.byType(RecurringResultView), findsNothing);
      expect(source(tester, fractions), 'Ans³');
      await tap(tester, 'KEY_EQUALS');
      expect(result(tester), '1/27');
      expect(answer(tester), 'Ans: 1/27');
      await tap(tester, 'KEY_SD');
      expect(
        tester
            .widget<RecurringResultView>(find.byType(RecurringResultView))
            .repeatingDigits,
        '037',
      );
    });
  }

  test('superscript cube has no hardware shortcut', () {
    expect(
      mapKeyboardEvent(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.digit3,
          logicalKey: LogicalKeyboardKey.digit3,
          character: '³',
          timeStamp: Duration.zero,
        ),
        modified: false,
      ),
      isNull,
    );
  });

  testWidgets(
    'cube remains inside its fraction field and applies to a whole fraction',
    (tester) async {
      await boot(tester, fractions: true);
      await taps(tester, ['KEY_FRACTION', 'KEY_2']);
      await cube(tester);
      final numerator =
          (formula(tester).snapshot.root.nodes.single as EditorFraction)
              .numerator;
      expect(numerator.nodes.cast<EditorText>().map((node) => node.text), [
        '2',
        '³',
      ]);
      expect(
        formula(tester).snapshot.cursor.path.single.field,
        FractionField.numerator,
      );
      await taps(tester, ['KEY_DOWN', 'KEY_3', 'KEY_EQUALS']);
      expect(result(tester), '8/3');
      await tap(tester, 'KEY_AC');
      await taps(tester, [
        'KEY_FRACTION',
        'KEY_1',
        'KEY_DOWN',
        'KEY_2',
        'KEY_RIGHT',
      ]);
      await cube(tester);
      expect(formula(tester).snapshot.cursor.path, isEmpty);
      expect(formula(tester).snapshot.root.nodes.last, isA<EditorText>());
      await tap(tester, 'KEY_EQUALS');
      expect(result(tester), '1/8');
    },
  );

  testWidgets('natural formula announces cube as hoch drei once', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await boot(tester, fractions: true);
      await taps(tester, entryIds('2³'));
      expect(find.bySemanticsLabel(RegExp('hoch drei')), findsOneWidget);
      expect(source(tester, true), '2³');
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'SHIFT cube fits 320px and Enter repeat cannot insert another cube',
    (tester) async {
      await boot(tester, fractions: true, size: const Size(320, 568));
      await taps(tester, ['KEY_2']);
      await cube(tester);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(source(tester, true), '2³');
      expect(result(tester), '8');
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(keyed('KEY_SQUARE')).width,
        greaterThanOrEqualTo(44),
      );
    },
  );
}
