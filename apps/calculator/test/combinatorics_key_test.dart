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

// H physical PDF p.21 supplies 10 nPr 4=5040 and 10 nCr 4=210.
// H p.51 also limits factorial quotients, even when a binomial result fits.
const ids = <String, String>{
  '+': 'KEY_ADD',
  '-': 'KEY_SUBTRACT',
  '*': 'KEY_MULTIPLY',
  '/': 'KEY_DIVIDE',
  '^': 'KEY_POWER',
  '(': 'KEY_LPAREN',
  ')': 'KEY_RPAREN',
  ',': 'KEY_DECIMAL',
};

List<String> entry(String expression) => [
  for (final match in RegExp(r'nPr|nCr|.').allMatches(expression))
    if (match[0] == 'nPr') ...[
      'KEY_SHIFT',
      'KEY_MULTIPLY',
    ] else if (match[0] == 'nCr') ...[
      'KEY_SHIFT',
      'KEY_DIVIDE',
    ] else
      ids[match[0]] ?? 'KEY_${match[0]}',
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
  fail('Missing option $id in ${c.menuTitle}');
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
    test('$mode combinatorics are secondary without extra physical keys', () {
      final c = controller(fractions);
      final physical = calculatorRows.expand((row) => row).toList();
      expect(physical, hasLength(50));
      expect(physical.map((key) => key.id).toSet(), hasLength(50));
      expect(
        physical.where((key) => c.isKeyEnabled(key.id)),
        hasLength(fractions ? 35 : 32),
      );
      expect(CalculatorKey.values, hasLength(33));
      for (final (id, text) in [
        ('ACTION_PERMUTATION', 'nPr'),
        ('ACTION_COMBINATION', 'nCr'),
      ]) {
        expect(physical.where((key) => key.id == id), isEmpty);
        expect(CalculatorKey.fromId(id)!.text, text);
        expect(CalculatorKey.fromId(id)!.isBinaryOperator, isTrue);
      }
    });

    test(
      '$mode handbook values zero cases and binomial symmetry are exact',
      () {
        final c = controller(fractions);
        for (final (input, expected) in [
          ('10nPr4', '5040'),
          ('10nCr4', '210'),
          ('10nCr6', '210'),
          ('0nPr0', '1'),
          ('0nCr0', '1'),
          ('5nPr0', '1'),
          ('5nCr5', '1'),
          ('5nPr2', '20'),
          ('5nCr2', '10'),
        ]) {
          calculate(c, input);
          expect(c.resultText, expected, reason: input);
          expect(answer(c).toString(), expected, reason: input);
          expect(c.shift, isFalse);
        }
      },
    );

    test('$mode combinatorics bind between implicit and explicit products', () {
      final c = controller(fractions);
      for (final (input, expected) in [
        ('2*5nCr2', '20'),
        ('2(3)nPr2', '30'),
        ('10nPr2*3', '270'),
        ('5nCr2nPr2', '90'),
        ('2^3nPr2', '56'),
        ('10nPr2^2', '5040'),
      ]) {
        calculate(c, input);
        expect(answer(c).toString(), expected, reason: input);
      }
    });

    test(
      '$mode result continuation uses exact Ans and primary products remain',
      () {
        final c = controller(fractions);
        calculate(c, '10');
        pressAll(c, [...entry('nPr4'), 'KEY_EQUALS']);
        expect(controllerSource(c), 'AnsnPr4');
        expect(c.resultText, '5040');
        calculate(c, '10');
        pressAll(c, [...entry('nCr4'), 'KEY_EQUALS']);
        expect(controllerSource(c), 'AnsnCr4');
        expect(c.resultText, '210');
        calculate(c, '10*4');
        expect(c.resultText, '40');
        calculate(c, '10/4');
        expect(c.resultText, '5/2');
      },
    );

    test(
      '$mode invalid arguments keep Ans and freeze at the binary operator',
      () {
        final c = controller(fractions);
        calculate(c, '7');
        for (final input in [
          '3nPr4',
          '3nCr4',
          '-3nPr2',
          '3nCr-1',
          '(1/2)nPr0',
          '5nCr(1/2)',
          '10000000000nCr0',
        ]) {
          calculate(c, input);
          expect(c.phase, CalculatorPhase.error, reason: input);
          expect(controllerError(c)!.code, CalculatorErrorCode.math);
          expect(
            controllerError(c)!.position,
            input.indexOf('n'),
            reason: input,
          );
          expect(answer(c).toString(), '7');
          final failed = snapshot(c);
          pressAll(c, ['KEY_SHIFT', 'KEY_MULTIPLY', 'KEY_2', 'KEY_DEL']);
          expect(snapshot(c), same(failed));
          expect(c.shift, isFalse);
        }
        pressAll(c, ['KEY_AC', 'KEY_ANS', 'KEY_EQUALS']);
        expect(c.resultText, '7');
      },
    );

    test('$mode reduced integers and source intermediate limits are respected', () {
      final c = controller(fractions);
      calculate(c, '(20/2)nCr(8/2)');
      expect(answer(c).toString(), '210');
      calculate(c, '100nCr50');
      expect(answer(c).toString(), '100891344545564193334812497256');
      calculate(c, '200nCr100');
      expect(c.phase, CalculatorPhase.error);
      expect(controllerError(c)!.code, CalculatorErrorCode.math);
      expect(controllerError(c)!.position, 3);
      // C(200,100) itself is below 10^100, but both source quotients exceed it.
      calculate(c, '9999999999nPr1');
      expect(answer(c).toString(), '9999999999');
      calculate(c, '9999999999nCr9999999998');
      expect(answer(c).toString(), '9999999999');
    });

    test('$mode rounded noninteger Ans is not used as an integer argument', () {
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
      pressAll(c, [...entry('nCr0'), 'KEY_EQUALS']);
      expect(controllerSource(c), 'AnsnCr0');
      expect(c.phase, CalculatorPhase.error);
      expect(controllerError(c)!.code, CalculatorErrorCode.math);
      expect(controllerError(c)!.position, 3);
      expect(answer(c).toString(), '1/2');
    });

    test(
      '$mode middle-cursor DEL removes one complete three-letter operator',
      () {
        final c = controller(fractions);
        pressAll(c, entry('10nPr4'));
        pressAll(c, ['KEY_LEFT', 'KEY_DEL']);
        expect(controllerSource(c), '104');
        pressAll(c, [...entry('nCr'), 'KEY_EQUALS']);
        expect(controllerSource(c), '10nCr4');
        expect(c.resultText, '210');
      },
    );

    test(
      '$mode missing right operand resumes at the complete operator boundary',
      () {
        final c = controller(fractions);
        pressAll(c, [...entry('10nPr'), 'KEY_EQUALS']);
        expect(c.phase, CalculatorPhase.error);
        expect(controllerError(c)!.code, CalculatorErrorCode.syntax);
        expect(controllerError(c)!.position, 5);
        final failed = snapshot(c);
        pressAll(c, entry('nCr'));
        expect(snapshot(c), same(failed));
        pressAll(c, ['KEY_LEFT', 'KEY_2', 'KEY_EQUALS']);
        expect(controllerSource(c), '10nPr2');
        expect(c.resultText, '90');
      },
    );

    test(
      '$mode SHIFT cancellation menu and OFF preserve their previous rules',
      () {
        final c = controller(fractions);
        pressAll(c, [
          'KEY_5',
          'KEY_SHIFT',
          'KEY_SHIFT',
          'KEY_MULTIPLY',
          'KEY_2',
          'KEY_EQUALS',
        ]);
        expect(c.resultText, '10');
        final completed = snapshot(c);
        c.openSetup();
        pressAll(c, entry('nCr'));
        expect(c.menuOpen, isTrue);
        expect(snapshot(c), same(completed));
        expect(c.shift, isFalse);
        pressAll(c, ['KEY_AC', 'KEY_SHIFT', 'KEY_AC']);
        pressAll(c, entry('nPr'));
        expect(c.poweredOn, isFalse);
        expect(snapshot(c), same(completed));
      },
    );

    testWidgets('$mode visible SHIFT products execute both handbook examples', (
      tester,
    ) async {
      await boot(tester, fractions: fractions);
      await taps(tester, [...entry('10nPr4'), 'KEY_EQUALS']);
      expect(source(tester, fractions), '10nPr4');
      expect(result(tester), '5040');
      await taps(tester, ['KEY_AC', ...entry('10nCr4'), 'KEY_EQUALS']);
      expect(result(tester), '210');
      expect(
        tester.widgetList<FilledButton>(find.byType(FilledButton)),
        hasLength(50),
      );
      expect(keyed('ACTION_PERMUTATION'), findsNothing);
      expect(keyed('ACTION_COMBINATION'), findsNothing);
      await taps(tester, ['KEY_AC', ...entry('3nCr4'), 'KEY_EQUALS']);
      expect(result(tester), 'Mathem. Fehler');
      expect(tester.widget<Text>(keyed('display-answer')).data, 'Ans: 210');
      await taps(tester, ['KEY_AC', 'KEY_ANS', 'KEY_EQUALS']);
      expect(result(tester), '210');
    });

    testWidgets(
      '$mode touch DEL and missing operand recovery keep operators atomic',
      (tester) async {
        await boot(tester, fractions: fractions);
        await taps(tester, entry('10nPr'));
        await tap(tester, 'KEY_DEL');
        expect(source(tester, fractions), '10');
        await taps(tester, [...entry('nCr'), 'KEY_EQUALS']);
        expect(result(tester), 'Syntaxfehler');
        await taps(tester, entry('nPr'));
        expect(source(tester, fractions), '10nCr');
        await taps(tester, ['KEY_LEFT', 'KEY_4', 'KEY_EQUALS']);
        expect(result(tester), '210');
      },
    );

    testWidgets(
      '$mode displayed period remains exact when used as a combinatorial base',
      (tester) async {
        await boot(tester, fractions: fractions);
        await taps(tester, [...entry('1/3'), 'KEY_EQUALS', 'KEY_SD']);
        expect(find.byType(RecurringResultView), findsOneWidget);
        await taps(tester, entry('nCr0'));
        expect(find.byType(RecurringResultView), findsNothing);
        expect(source(tester, fractions), 'AnsnCr0');
        await tap(tester, 'KEY_EQUALS');
        expect(result(tester), 'Mathem. Fehler');
        expect(tester.widget<Text>(keyed('display-answer')).data, 'Ans: 1/3');
      },
    );
  }

  testWidgets(
    'combinatorics stay in selected fraction fields and can use a whole fraction',
    (tester) async {
      await boot(tester, fractions: true);
      await taps(tester, ['KEY_FRACTION', ...entry('5nCr2')]);
      final root = formula(tester).snapshot.root.nodes.single as EditorFraction;
      expect(root.numerator.nodes.cast<EditorText>().map((node) => node.text), [
        '5',
        'nCr',
        '2',
      ]);
      expect(
        formula(tester).snapshot.cursor.path.single.field,
        FractionField.numerator,
      );
      await taps(tester, ['KEY_DOWN', 'KEY_2', 'KEY_EQUALS']);
      expect(result(tester), '5');
      await taps(tester, [
        'KEY_AC',
        'KEY_FRACTION',
        'KEY_1',
        'KEY_0',
        'KEY_DOWN',
        'KEY_2',
        'KEY_RIGHT',
        ...entry('nPr2'),
        'KEY_EQUALS',
      ]);
      expect(result(tester), '20');
      expect(formula(tester).snapshot.cursor.path, isEmpty);
    },
  );

  testWidgets('natural formula announces both operator names', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await boot(tester, fractions: true);
      await taps(tester, entry('5nCr2nPr2'));
      expect(
        find.bySemanticsLabel(RegExp('Kombination.*Permutation')),
        findsOneWidget,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'combinatorics fit 320px and Enter repeat does not execute another action',
    (tester) async {
      await boot(tester, fractions: true, size: const Size(320, 568));
      await taps(tester, entry('10nPr4'));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(source(tester, true), '10nPr4');
      expect(result(tester), '5040');
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(keyed('KEY_MULTIPLY')).width,
        greaterThanOrEqualTo(44),
      );
    },
  );

  test('literal P and C do not introduce unassigned hardware shortcuts', () {
    for (final (physical, logical, character) in [
      (PhysicalKeyboardKey.keyP, LogicalKeyboardKey.keyP, 'P'),
      (PhysicalKeyboardKey.keyC, LogicalKeyboardKey.keyC, 'C'),
    ]) {
      expect(
        mapKeyboardEvent(
          KeyDownEvent(
            physicalKey: physical,
            logicalKey: logical,
            character: character,
            timeStamp: Duration.zero,
          ),
          modified: false,
        ),
        isNull,
      );
    }
  });
}
