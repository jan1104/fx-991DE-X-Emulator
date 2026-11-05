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

// Independent expectations for the secondary percent action. The three
// handbook vectors are H, physical PDF page 13; mixed postfixes use our contract.
const _ids = <String, String>{
  '+': 'KEY_ADD',
  '-': 'KEY_SUBTRACT',
  '*': 'KEY_MULTIPLY',
  '/': 'KEY_DIVIDE',
  '(': 'KEY_LPAREN',
  ')': 'KEY_RPAREN',
  '²': 'KEY_SQUARE',
};

List<String> entryIds(String expression) => [
  for (final token in expression.split(''))
    if (token == '%') ...[
      'KEY_SHIFT',
      'KEY_ANS',
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

Future<void> percent(WidgetTester tester) =>
    taps(tester, ['KEY_SHIFT', 'KEY_ANS']);

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
      '$mode percent adds a semantic action without another physical key',
      () {
        final c = controller(fractions);
        final physical = calculatorRows.expand((row) => row).toList();
        expect(physical, hasLength(50));
        expect(physical.map((key) => key.id).toSet(), hasLength(50));
        expect(
          physical.where((key) => c.isKeyEnabled(key.id)),
          hasLength(fractions ? 35 : 32),
        );
        expect(physical.where((key) => key.id == 'ACTION_PERCENT'), isEmpty);
        expect(CalculatorKey.values, hasLength(33));
        expect(CalculatorKey.fromId('ACTION_PERCENT')!.text, '%');
        expect(CalculatorKey.fromId('KEY_PERCENT'), isNull);
      },
    );

    test('$mode computes all three handbook percent examples exactly', () {
      final c = controller(fractions);
      for (final (input, expected) in [
        ('150*20%', '30'),
        ('660/880%', '75'),
        ('3500-3500*25%', '2625'),
      ]) {
        c.pressId('KEY_AC');
        pressAll(c, [...entryIds(input), 'KEY_EQUALS']);
        expect(c.resultText, expected, reason: input);
        expect(controllerAnswer(c).toString(), expected, reason: input);
        expect(c.shift, isFalse);
      }
    });

    test('$mode scales only its base and composes exact postfixes', () {
      final c = controller(fractions);
      for (final (input, expected) in [
        ('50%', '1/2'),
        ('50%%', '1/200'),
        ('-25%', '-1/4'),
        ('(1/3)%', '1/300'),
        ('200+10%', '2001/10'),
        ('2²%', '1/25'),
        ('2%²', '1/2500'),
        ('0%', '0'),
      ]) {
        c.pressId('KEY_AC');
        pressAll(c, [...entryIds(input), 'KEY_EQUALS']);
        expect(c.resultText, expected, reason: input);
      }
    });

    test(
      '$mode percent continues exact negative fractional Ans and primary Ans',
      () {
        final c = controller(fractions);
        pressAll(c, [...entryIds('-2/3'), 'KEY_EQUALS']);
        pressAll(c, ['KEY_SHIFT', 'KEY_ANS']);
        expect(controllerSource(c), 'Ans%');
        expect(controllerAnswer(c).toString(), '-2/3');
        expect(c.phase, CalculatorPhase.editing);
        c.pressId('KEY_EQUALS');
        expect(c.resultText, '-1/150');
        pressAll(c, ['KEY_AC', 'KEY_ANS']);
        expect(controllerSource(c), 'Ans');
        c.pressId('KEY_EQUALS');
        expect(c.resultText, '-1/150');
      },
    );

    test('$mode percent syntax freezes until explicit cursor recovery', () {
      final c = controller(fractions);
      pressAll(c, ['KEY_SHIFT', 'KEY_ANS', 'KEY_EQUALS']);
      expect(c.phase, CalculatorPhase.error);
      final failed = controllerSnapshot(c);
      pressAll(c, ['KEY_SHIFT', 'KEY_ANS']);
      expect(controllerSnapshot(c), same(failed));
      expect(controllerAnswer(c), Rational.fromInt(0));
      expect(c.shift, isFalse);
      pressAll(c, ['KEY_LEFT', 'KEY_5', 'KEY_0', 'KEY_EQUALS']);
      expect(c.resultText, '1/2');
    });

    test('$mode SHIFT cancellation, menus and OFF preserve percent state', () {
      final c = controller(fractions);
      pressAll(c, ['KEY_8', 'KEY_EQUALS']);
      pressAll(c, ['KEY_SHIFT', 'KEY_SHIFT', 'KEY_ANS']);
      expect(controllerSource(c), 'Ans');
      c.pressId('KEY_EQUALS');
      expect(c.resultText, '8');
      final completed = controllerSnapshot(c);
      pressAll(c, ['KEY_SHIFT', 'KEY_POWER']);
      expect(c.notice, contains('in Vorbereitung'));
      expect(controllerSnapshot(c), same(completed));
      c.openSetup();
      pressAll(c, ['KEY_SHIFT', 'KEY_ANS']);
      expect(controllerSnapshot(c), same(completed));
      expect(c.menuOpen, isTrue);
      expect(c.shift, isFalse);
      pressAll(c, ['KEY_AC', 'KEY_SHIFT', 'KEY_AC']);
      expect(c.poweredOn, isFalse);
      pressAll(c, ['KEY_SHIFT', 'KEY_ANS']);
      expect(controllerSnapshot(c), same(completed));
      expect(c.poweredOn, isFalse);
    });

    test('$mode percent uses exact Ans after a periodic display choice', () {
      final c = controller(fractions);
      pressAll(c, [...entryIds('1/3'), 'KEY_EQUALS', 'KEY_SD']);
      expect(c.resultPresentation.expansion!.repeatingDigits, '3');
      pressAll(c, ['KEY_SHIFT', 'KEY_ANS']);
      expect(controllerSource(c), 'Ans%');
      expect(c.resultPresentation.text, '');
      expect(c.resultPresentation.expansion, isNull);
      c.pressId('KEY_EQUALS');
      expect(c.resultText, '1/300');
      expect(controllerAnswer(c).toString(), '1/300');
    });

    testWidgets('$mode physical SHIFT Ans inserts percent and consumes SHIFT', (
      tester,
    ) async {
      await boot(tester, fractions: fractions);
      await taps(tester, [...entryIds('660/880'), 'KEY_SHIFT']);
      expect(
        tester.widget<Text>(keyed('display-status')).data,
        contains('SHIFT'),
      );
      await tap(tester, 'KEY_ANS');
      expect(source(tester, fractions), '660/880%');
      expect(
        tester.widget<Text>(keyed('display-status')).data,
        isNot(contains('SHIFT')),
      );
      await tap(tester, 'KEY_EQUALS');
      expect(result(tester), '75');
      expect(
        tester.widgetList<FilledButton>(find.byType(FilledButton)),
        hasLength(50),
      );
      expect(keyed('ACTION_PERCENT'), findsNothing);
    });

    testWidgets('$mode repeat percent, DEL and syntax recovery use one token', (
      tester,
    ) async {
      await boot(tester, fractions: fractions);
      await taps(tester, entryIds('50%%'));
      expect(source(tester, fractions), '50%%');
      await tap(tester, 'KEY_DEL');
      expect(source(tester, fractions), '50%');
      await percent(tester);
      await tap(tester, 'KEY_EQUALS');
      expect(result(tester), '1/200');
      await tap(tester, 'KEY_AC');
      await percent(tester);
      await tap(tester, 'KEY_EQUALS');
      expect(result(tester), 'Syntaxfehler');
      await percent(tester);
      expect(source(tester, fractions), '%');
      await taps(tester, ['KEY_LEFT', 'KEY_2', 'KEY_5', 'KEY_EQUALS']);
      expect(result(tester), '1/4');
    });

    testWidgets('$mode displayed period yields exact Ans percent on touch', (
      tester,
    ) async {
      await boot(tester, fractions: fractions);
      await taps(tester, [...entryIds('1/3'), 'KEY_EQUALS', 'KEY_SD']);
      expect(find.byType(RecurringResultView), findsOneWidget);
      await percent(tester);
      expect(find.byType(RecurringResultView), findsNothing);
      expect(source(tester, fractions), 'Ans%');
      expect(answer(tester), 'Ans: 1/3');
      await tap(tester, 'KEY_EQUALS');
      expect(result(tester), '1/300');
      expect(answer(tester), 'Ans: 1/300');
      await tap(tester, 'KEY_SD');
      expect(
        tester
            .widget<RecurringResultView>(find.byType(RecurringResultView))
            .repeatingDigits,
        '3',
      );
    });
  }

  testWidgets(
    'percent affects only its selected fraction field or whole group',
    (tester) async {
      await boot(tester, fractions: true);
      await taps(tester, ['KEY_FRACTION', 'KEY_2']);
      await percent(tester);
      final snapshot = formula(tester).snapshot;
      final numerator =
          (snapshot.root.nodes.single as EditorFraction).numerator;
      expect(numerator.nodes.cast<EditorText>().map((node) => node.text), [
        '2',
        '%',
      ]);
      expect(snapshot.cursor.path.single.field, FractionField.numerator);
      await taps(tester, ['KEY_DOWN', 'KEY_3', 'KEY_EQUALS']);
      expect(result(tester), '1/150');
      await tap(tester, 'KEY_AC');
      await taps(tester, [
        'KEY_FRACTION',
        'KEY_1',
        'KEY_DOWN',
        'KEY_2',
        'KEY_RIGHT',
      ]);
      await percent(tester);
      expect(formula(tester).snapshot.cursor.path, isEmpty);
      expect(
        (formula(tester).snapshot.root.nodes.last as EditorText).text,
        '%',
      );
      await tap(tester, 'KEY_EQUALS');
      expect(result(tester), '1/200');
    },
  );

  testWidgets('natural formula announces Prozent once', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await boot(tester, fractions: true);
      await taps(tester, entryIds('25%'));
      expect(find.bySemanticsLabel(RegExp('Prozent')), findsOneWidget);
      expect(source(tester, true), '25%');
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('percent fits 320px and repeated Enter cannot scale twice', (
    tester,
  ) async {
    await boot(tester, fractions: true, size: const Size(320, 568));
    await taps(tester, entryIds('150*20%'));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(source(tester, true), '150*20%');
    expect(result(tester), '30');
    expect(tester.takeException(), isNull);
    expect(tester.getSize(keyed('KEY_ANS')).width, greaterThanOrEqualTo(44));
  });

  test('literal percent has no assigned hardware shortcut', () {
    expect(
      mapKeyboardEvent(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.digit5,
          logicalKey: LogicalKeyboardKey.digit5,
          character: '%',
          timeStamp: Duration.zero,
        ),
        modified: false,
      ),
      isNull,
    );
  });
}
