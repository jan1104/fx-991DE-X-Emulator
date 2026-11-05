import 'package:calculator_core/calculator_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fx991_calculator/application/calculator_controller.dart';
import 'package:fx991_calculator/application/key_layout.dart';
import 'package:fx991_calculator/application/keyboard_mapping.dart';
import 'package:fx991_calculator/main.dart';
import 'package:fx991_calculator/presentation/calculator/recurring_result_view.dart';
import 'package:fx991_calculator/presentation/editor/fraction_expression_view.dart';

// H physical PDF p.21 supplies (5+3)! = 40320; p.51 limits inputs to integers
// from 0 through 69. Mixed postfix examples describe our own parser contract.
// The 69! oracle below was independently checked with Python math.factorial.
const factorial69 =
    '171122452428141311372468338881272839092270544893520369393648040923257279754140647424000000000000000';
const ids = <String, String>{
  '+': 'KEY_ADD',
  '-': 'KEY_SUBTRACT',
  '/': 'KEY_DIVIDE',
  '(': 'KEY_LPAREN',
  ')': 'KEY_RPAREN',
  '²': 'KEY_SQUARE',
};

List<String> entry(String expression) => [
  for (final character in expression.split(''))
    if (character == '!') ...[
      'KEY_SHIFT',
      'KEY_RECIPROCAL',
    ] else
      ids[character] ?? 'KEY_$character',
];

CalculatorController controller(bool fractions) => CalculatorController()
  ..selectInputOutput(
    fractions
        ? CalculatorInputOutput.mathMath
        : CalculatorInputOutput.linearLinear,
  );

void pressAll(CalculatorController c, Iterable<String> keys) {
  for (final key in keys) {
    c.pressId(key);
  }
}

void calculate(CalculatorController c, String expression) =>
    pressAll(c, ['KEY_AC', ...entry(expression), 'KEY_EQUALS']);

String controllerSource(CalculatorController c) => c.fractions
    ? FractionEditor.fromSnapshot(c.structured.snapshot.editor).toExpression()
    : c.session.snapshot.expression;
Rational answer(CalculatorController c) =>
    c.fractions ? c.structured.snapshot.answer : c.session.snapshot.answer;
Object snapshot(CalculatorController c) =>
    c.fractions ? c.structured.snapshot : c.session.snapshot;
CalculatorException? controllerError(CalculatorController c) =>
    c.fractions ? c.structured.snapshot.error : c.session.snapshot.error;

void choose(CalculatorController c, String id) {
  for (var guard = 0; guard < 80; guard++) {
    final index = c.menuItems.indexWhere((item) => item.id == id);
    if (index >= 0) {
      c.selectMenuItem(index);
      return;
    }
    c.menuMove(1);
  }
  fail('Missing menu option $id in ${c.menuTitle}');
}

Finder keyed(String id) => find.byKey(ValueKey(id));

Future<void> boot(
  WidgetTester tester, {
  required bool fractions,
  Size size = const Size(800, 1000),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
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

Future<void> taps(WidgetTester tester, Iterable<String> keys) async {
  for (final key in keys) {
    await tap(tester, key);
  }
}

Future<void> factorial(WidgetTester tester) =>
    taps(tester, ['KEY_SHIFT', 'KEY_RECIPROCAL']);
FractionExpressionView formula(WidgetTester tester) =>
    tester.widget<FractionExpressionView>(find.byType(FractionExpressionView));
String source(WidgetTester tester, bool fractions) => fractions
    ? FractionEditor.fromSnapshot(formula(tester).snapshot).toExpression()
    : tester
          .widget<Text>(keyed('display-expression'))
          .textSpan!
          .toPlainText()
          .replaceAll('│', '');
String result(WidgetTester tester) =>
    tester.widget<Text>(keyed('display-result')).data!;

void main() {
  for (final fractions in [false, true]) {
    final mode = fractions ? 'Math' : 'Linear';

    test('$mode factorial is secondary and keeps physical primary counts', () {
      final c = controller(fractions);
      final physical = calculatorRows.expand((row) => row).toList();
      expect(physical, hasLength(50));
      expect(physical.map((key) => key.id).toSet(), hasLength(50));
      expect(
        physical.where((key) => c.isKeyEnabled(key.id)),
        hasLength(fractions ? 35 : 32),
      );
      expect(physical.where((key) => key.id == 'ACTION_FACTORIAL'), isEmpty);
      expect(CalculatorKey.values, hasLength(33));
      expect(CalculatorKey.fromId('ACTION_FACTORIAL')!.text, '!');
      expect(CalculatorKey.fromId('KEY_FACTORIAL'), isNull);
    });

    test('$mode handbook value, zero and own postfix binding are exact', () {
      final c = controller(fractions);
      for (final (input, expected) in [
        ('(5+3)!', '40320'),
        ('0!', '1'),
        ('1!', '1'),
        ('3!!', '720'),
        ('-5!', '-120'),
        ('2²!', '24'),
        ('3!²', '36'),
        ('(10/2)!', '120'),
      ]) {
        calculate(c, input);
        expect(c.resultText, expected, reason: input);
        expect(answer(c).toString(), expected, reason: input);
        expect(c.shift, isFalse);
      }
    });

    test('$mode 69 factorial retains its full exact answer', () {
      final c = controller(fractions);
      calculate(c, '69!');
      expect(c.phase, CalculatorPhase.result);
      expect(answer(c).toString(), factorial69);
      expect(c.resultText, isNotEmpty);
      // Display rounding may use scientific notation; it must not replace Ans.
      c.pressId('KEY_SD');
      expect(answer(c).toString(), factorial69);
    });

    test('$mode out of domain reports math and preserves the previous Ans', () {
      final c = controller(fractions);
      calculate(c, '5');
      for (final input in ['70!', '(-5)!', '(1/2)!']) {
        calculate(c, input);
        expect(c.phase, CalculatorPhase.error, reason: input);
        expect(
          controllerError(c)!.code,
          CalculatorErrorCode.math,
          reason: input,
        );
        expect(controllerError(c)!.position, input.length - 1, reason: input);
        expect(answer(c).toString(), '5');
        final failed = snapshot(c);
        pressAll(c, ['KEY_SHIFT', 'KEY_RECIPROCAL', 'KEY_2', 'KEY_DEL']);
        expect(snapshot(c), same(failed));
        expect(c.shift, isFalse);
      }
      pressAll(c, ['KEY_AC', 'KEY_ANS', 'KEY_EQUALS']);
      expect(c.resultText, '5');
    });

    test('$mode factorial uses exact Ans before any display rounding', () {
      final c = controller(fractions);
      c.openSetup();
      for (final id in ['number', 'fix', '0']) {
        choose(c, id);
      }
      c.pressId('KEY_AC');
      c.selectInputOutput(
        fractions
            ? CalculatorInputOutput.mathDecimal
            : CalculatorInputOutput.linearDecimal,
      );
      calculate(c, '1/2');
      expect(c.resultText, '1');
      expect(answer(c).toString(), '1/2');
      pressAll(c, ['KEY_SHIFT', 'KEY_RECIPROCAL']);
      expect(controllerSource(c), 'Ans!');
      c.pressId('KEY_EQUALS');
      expect(c.phase, CalculatorPhase.error);
      expect(controllerError(c)!.code, CalculatorErrorCode.math);
      expect(controllerError(c)!.position, 3);
      expect(answer(c).toString(), '1/2');
    });

    test(
      '$mode negative Ans remains bound and does not become minus factorial',
      () {
        final c = controller(fractions);
        calculate(c, '-5');
        pressAll(c, ['KEY_SHIFT', 'KEY_RECIPROCAL']);
        expect(controllerSource(c), 'Ans!');
        c.pressId('KEY_EQUALS');
        expect(c.phase, CalculatorPhase.error);
        expect(answer(c).toString(), '-5');
        calculate(c, '10/2');
        pressAll(c, ['KEY_SHIFT', 'KEY_RECIPROCAL', 'KEY_EQUALS']);
        expect(answer(c).toString(), '120');
      },
    );

    test('$mode SHIFT cancellation keeps the primary reciprocal', () {
      final c = controller(fractions);
      pressAll(c, ['KEY_5', 'KEY_SHIFT', 'KEY_SHIFT', 'KEY_RECIPROCAL']);
      expect(controllerSource(c), '5⁻¹');
      c.pressId('KEY_EQUALS');
      expect(c.resultText, '1/5');
      final completed = snapshot(c);
      pressAll(c, ['KEY_SHIFT', 'KEY_POWER']);
      expect(c.notice, contains('in Vorbereitung'));
      expect(snapshot(c), same(completed));
      expect(c.shift, isFalse);
    });

    test('$mode menu and OFF do not evaluate a shifted factorial', () {
      final c = controller(fractions);
      calculate(c, '5');
      final completed = snapshot(c);
      c.openSetup();
      pressAll(c, ['KEY_SHIFT', 'KEY_RECIPROCAL']);
      expect(c.menuOpen, isTrue);
      expect(c.shift, isFalse);
      expect(snapshot(c), same(completed));
      pressAll(c, ['KEY_AC', 'KEY_SHIFT', 'KEY_AC']);
      expect(c.poweredOn, isFalse);
      pressAll(c, ['KEY_SHIFT', 'KEY_RECIPROCAL']);
      expect(snapshot(c), same(completed));
      expect(c.poweredOn, isFalse);
    });

    testWidgets('$mode visible SHIFT reciprocal runs the handbook example', (
      tester,
    ) async {
      await boot(tester, fractions: fractions);
      await taps(tester, [...entry('(5+3)'), 'KEY_SHIFT']);
      expect(
        tester.widget<Text>(keyed('display-status')).data,
        contains('SHIFT'),
      );
      await tap(tester, 'KEY_RECIPROCAL');
      expect(source(tester, fractions), '(5+3)!');
      expect(
        tester.widget<Text>(keyed('display-status')).data,
        isNot(contains('SHIFT')),
      );
      await tap(tester, 'KEY_EQUALS');
      expect(result(tester), '40320');
      expect(
        tester.widgetList<FilledButton>(find.byType(FilledButton)),
        hasLength(50),
      );
      expect(keyed('ACTION_FACTORIAL'), findsNothing);
      await taps(tester, ['KEY_AC', ...entry('70!'), 'KEY_EQUALS']);
      expect(result(tester), 'Mathem. Fehler');
      expect(tester.widget<Text>(keyed('display-answer')).data, 'Ans: 40320');
      await factorial(tester);
      expect(source(tester, fractions), '70!');
      expect(result(tester), 'Mathem. Fehler');
      await taps(tester, ['KEY_AC', 'KEY_ANS', 'KEY_EQUALS']);
      expect(result(tester), '40320');
    });

    testWidgets('$mode repeated factorial and DEL remove exactly one token', (
      tester,
    ) async {
      await boot(tester, fractions: fractions);
      await taps(tester, entry('3!!'));
      expect(source(tester, fractions), '3!!');
      await tap(tester, 'KEY_DEL');
      expect(source(tester, fractions), '3!');
      await tap(tester, 'KEY_EQUALS');
      expect(result(tester), '6');
      await tap(tester, 'KEY_AC');
      await factorial(tester);
      await tap(tester, 'KEY_EQUALS');
      expect(result(tester), 'Syntaxfehler');
      await factorial(tester);
      expect(source(tester, fractions), '!');
      await taps(tester, ['KEY_LEFT', 'KEY_5', 'KEY_EQUALS']);
      expect(result(tester), '120');
    });

    testWidgets('$mode factorial preserves exact integer and periodic Ans', (
      tester,
    ) async {
      await boot(tester, fractions: fractions);
      await taps(tester, [...entry('10/2'), 'KEY_EQUALS']);
      await factorial(tester);
      expect(source(tester, fractions), 'Ans!');
      await tap(tester, 'KEY_EQUALS');
      expect(result(tester), '120');
      await taps(tester, ['KEY_AC', ...entry('1/3'), 'KEY_EQUALS', 'KEY_SD']);
      expect(find.byType(RecurringResultView), findsOneWidget);
      await factorial(tester);
      expect(find.byType(RecurringResultView), findsNothing);
      await tap(tester, 'KEY_EQUALS');
      expect(result(tester), 'Mathem. Fehler');
      expect(tester.widget<Text>(keyed('display-answer')).data, 'Ans: 1/3');
    });
  }

  testWidgets(
    'factorial applies to its fraction field or a whole exact group',
    (tester) async {
      await boot(tester, fractions: true);
      await taps(tester, ['KEY_FRACTION', 'KEY_5']);
      await factorial(tester);
      final snapshot = formula(tester).snapshot;
      final numerator =
          (snapshot.root.nodes.single as EditorFraction).numerator;
      expect(numerator.nodes.cast<EditorText>().map((node) => node.text), [
        '5',
        '!',
      ]);
      expect(snapshot.cursor.path.single.field, FractionField.numerator);
      await taps(tester, ['KEY_DOWN', 'KEY_2', 'KEY_EQUALS']);
      expect(result(tester), '60');
      await taps(tester, [
        'KEY_AC',
        'KEY_FRACTION',
        'KEY_1',
        'KEY_0',
        'KEY_DOWN',
        'KEY_2',
        'KEY_RIGHT',
      ]);
      await factorial(tester);
      expect(formula(tester).snapshot.cursor.path, isEmpty);
      expect(
        (formula(tester).snapshot.root.nodes.last as EditorText).text,
        '!',
      );
      await tap(tester, 'KEY_EQUALS');
      expect(result(tester), '120');
    },
  );

  testWidgets('natural formula announces Fakultät once', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await boot(tester, fractions: true);
      await taps(tester, entry('5!'));
      expect(find.bySemanticsLabel(RegExp('Fakultät')), findsOneWidget);
      expect(source(tester, true), '5!');
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('factorial fits 320px and Enter repeat cannot apply it twice', (
    tester,
  ) async {
    await boot(tester, fractions: true, size: const Size(320, 568));
    await taps(tester, entry('(5+3)!'));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(source(tester, true), '(5+3)!');
    expect(result(tester), '40320');
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(keyed('KEY_RECIPROCAL')).width,
      greaterThanOrEqualTo(44),
    );
  });

  test('literal factorial has no assigned hardware shortcut', () {
    expect(
      mapKeyboardEvent(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.digit1,
          logicalKey: LogicalKeyboardKey.digit1,
          character: '!',
          timeStamp: Duration.zero,
        ),
        modified: false,
      ),
      isNull,
    );
  });
}
