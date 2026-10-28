import 'package:calculator_core/calculator_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fx991_calculator/main.dart';
import 'package:fx991_calculator/presentation/editor/fraction_expression_view.dart';

// Group capture is the explicit "Als Zähler" app action. It does not change
// the meaning of the physical fraction button or claim original-device parity.
Finder keyed(String id) => find.byKey(ValueKey(id));

FractionExpressionView formula(WidgetTester tester) =>
    tester.widget<FractionExpressionView>(find.byType(FractionExpressionView));

String result(WidgetTester tester) =>
    tester.widget<Text>(keyed('display-result')).data!;

List<Object> tree(EditorSequence sequence) => [
  for (final node in sequence.nodes)
    switch (node) {
      EditorText(:final text) => text,
      EditorFraction(:final numerator, :final denominator) => {
        'numerator': tree(numerator),
        'denominator': tree(denominator),
      },
    },
];

List<(int, FractionField)> pathOf(EditorCursor cursor) => [
  for (final step in cursor.path) (step.nodeIndex, step.field),
];

void expectCursor(
  WidgetTester tester,
  int offset,
  List<(int, FractionField)> path,
) {
  expect(formula(tester).snapshot.cursor.offset, offset);
  expect(pathOf(formula(tester).snapshot.cursor), path);
}

Future<void> tap(WidgetTester tester, String id) async {
  await tester.ensureVisible(keyed(id));
  await tester.pumpAndSettle();
  await tester.tap(keyed(id));
  await tester.pumpAndSettle();
}

Future<void> taps(WidgetTester tester, List<String> ids) async {
  for (final id in ids) {
    await tap(tester, id);
  }
}

Future<void> enter(WidgetTester tester, String expression) async {
  final keys = <String, String>{
    for (var digit = 0; digit <= 9; digit++) '$digit': 'KEY_$digit',
    '+': 'KEY_ADD',
    '-': 'KEY_SUBTRACT',
    '*': 'KEY_MULTIPLY',
    '/': 'KEY_DIVIDE',
    '^': 'KEY_POWER',
    ',': 'KEY_DECIMAL',
    '(': 'KEY_LPAREN',
    ')': 'KEY_RPAREN',
  };
  for (final character in expression.split('')) {
    await tap(tester, keys[character]!);
  }
}

Future<void> pumpCalculator(
  WidgetTester tester, {
  Size size = const Size(800, 1000),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const CalculatorApp());
  await tester.pumpAndSettle();
  await tap(tester, 'input-fractions');
}

void main() {
  testWidgets(
    'captures the closed group including parentheses and evaluates over three',
    (tester) async {
      await pumpCalculator(tester);
      await enter(tester, '(1+2)');
      final old = formula(tester).snapshot;
      await tap(tester, 'action-wrap-fraction');
      expect(tree(formula(tester).snapshot.root), [
        {
          'numerator': ['(', '1', '+', '2', ')'],
          'denominator': <Object>[],
        },
      ]);
      expectCursor(tester, 0, [(0, FractionField.denominator)]);
      expect(keyed('placeholder-root/f0d'), findsOneWidget);
      expect(tree(old.root), ['(', '1', '+', '2', ')']);
      await taps(tester, ['KEY_3', 'KEY_EQUALS']);
      expect(result(tester), '1');
    },
  );

  testWidgets('preceding addition remains outside the captured group', (
    tester,
  ) async {
    await pumpCalculator(tester);
    await enter(tester, '2+(3+5)');
    await tap(tester, 'action-wrap-fraction');
    expect(tree(formula(tester).snapshot.root), [
      '2',
      '+',
      {
        'numerator': ['(', '3', '+', '5', ')'],
        'denominator': <Object>[],
      },
    ]);
    expectCursor(tester, 0, [(2, FractionField.denominator)]);
    await taps(tester, ['KEY_4', 'KEY_EQUALS']);
    expect(result(tester), '4');
  });

  testWidgets('nested balanced groups are captured as one complete atom', (
    tester,
  ) async {
    await pumpCalculator(tester);
    const group = '((1+2)*2)';
    await enter(tester, group);
    await tap(tester, 'action-wrap-fraction');
    final fraction =
        formula(tester).snapshot.root.nodes.single as EditorFraction;
    expect(tree(fraction.numerator), group.split(''));
    expect(fraction.denominator.nodes, isEmpty);
    await taps(tester, ['KEY_3', 'KEY_EQUALS']);
    expect(result(tester), '2');
  });

  testWidgets('a fraction inside a group stays an intact nested atom', (
    tester,
  ) async {
    await pumpCalculator(tester);
    await taps(tester, [
      'KEY_LPAREN',
      'KEY_FRACTION',
      'KEY_1',
      'KEY_DOWN',
      'KEY_2',
      'KEY_RIGHT',
      'KEY_ADD',
      'KEY_1',
      'KEY_RPAREN',
      'action-wrap-fraction',
    ]);
    expect(tree(formula(tester).snapshot.root), [
      {
        'numerator': [
          '(',
          {
            'numerator': ['1'],
            'denominator': ['2'],
          },
          '+',
          '1',
          ')',
        ],
        'denominator': <Object>[],
      },
    ]);
    expect(keyed('fraction-root/f0n/1'), findsOneWidget);
    expectCursor(tester, 0, [(0, FractionField.denominator)]);
    await taps(tester, ['KEY_3', 'KEY_EQUALS']);
    expect(result(tester), '1/2');
  });

  testWidgets(
    'the minus before a closed group is not included in its numerator',
    (tester) async {
      await pumpCalculator(tester);
      await tap(tester, 'KEY_NEGATE');
      await enter(tester, '(1+2)');
      await tap(tester, 'action-wrap-fraction');
      expect(tree(formula(tester).snapshot.root), [
        '-',
        {
          'numerator': ['(', '1', '+', '2', ')'],
          'denominator': <Object>[],
        },
      ]);
      expectCursor(tester, 0, [(1, FractionField.denominator)]);
      await taps(tester, ['KEY_2', 'KEY_EQUALS']);
      expect(result(tester), '-3/2');
    },
  );

  testWidgets('capture before a middle suffix preserves the suffix nodes', (
    tester,
  ) async {
    await pumpCalculator(tester);
    await enter(tester, '(1+2)+4');
    await taps(tester, ['KEY_LEFT', 'KEY_LEFT', 'action-wrap-fraction']);
    expect(tree(formula(tester).snapshot.root), [
      {
        'numerator': ['(', '1', '+', '2', ')'],
        'denominator': <Object>[],
      },
      '+',
      '4',
    ]);
    await taps(tester, ['KEY_3', 'KEY_EQUALS']);
    expect(result(tester), '5');
  });

  testWidgets(
    'group capture in a numerator does not capture its ancestor fraction',
    (tester) async {
      await pumpCalculator(tester);
      await tap(tester, 'KEY_FRACTION');
      await enter(tester, '(1+2)');
      await tap(tester, 'action-wrap-fraction');
      expectCursor(tester, 0, [
        (0, FractionField.numerator),
        (0, FractionField.denominator),
      ]);
      final outer =
          formula(tester).snapshot.root.nodes.single as EditorFraction;
      final captured = outer.numerator.nodes.single as EditorFraction;
      expect(tree(captured.numerator), ['(', '1', '+', '2', ')']);
      expect(outer.denominator.nodes, isEmpty);
      await taps(tester, [
        'KEY_3',
        'KEY_RIGHT',
        'KEY_DOWN',
        'KEY_2',
        'KEY_EQUALS',
      ]);
      expect(result(tester), '1/2');
    },
  );

  for (final invalid in [')', '1)', '(1+2))', '()', '(())']) {
    testWidgets('invalid group $invalid fails atomically as syntax', (
      tester,
    ) async {
      await pumpCalculator(tester);
      await enter(tester, invalid);
      final before = formula(tester).snapshot;
      final beforeTree = tree(before.root);
      await tap(tester, 'action-wrap-fraction');
      expect(result(tester), 'Syntaxfehler');
      expect(tree(formula(tester).snapshot.root), beforeTree);
      expectCursor(tester, before.cursor.offset, pathOf(before.cursor));
      expect(tree(before.root), beforeTree);
      expect(
        tester.widget<TextButton>(keyed('action-wrap-fraction')).onPressed,
        isNull,
      );
    });
  }

  testWidgets(
    'unfinished arithmetic may be captured but its syntax error stays mapped',
    (tester) async {
      await pumpCalculator(tester);
      await enter(tester, '(1+)');
      await tap(tester, 'action-wrap-fraction');
      expect(result(tester), '');
      expectCursor(tester, 0, [(0, FractionField.denominator)]);
      expect(tree(formula(tester).snapshot.root), [
        {
          'numerator': ['(', '1', '+', ')'],
          'denominator': <Object>[],
        },
      ]);
      await taps(tester, ['KEY_2', 'KEY_EQUALS']);
      expect(result(tester), 'Syntaxfehler');
      expect(formula(tester).errorCursor!.offset, 3);
      expect(pathOf(formula(tester).errorCursor!), [
        (0, FractionField.numerator),
      ]);
      expect(
        find.descendant(
          of: keyed('field-root/f0n'),
          matching: keyed('formula-error'),
        ),
        findsOneWidget,
      );
      await tap(tester, 'KEY_LEFT');
      expectCursor(tester, 3, [(0, FractionField.numerator)]);
      await taps(tester, ['KEY_DEL', 'KEY_EQUALS']);
      expect(result(tester), '1/2');
      expect(keyed('formula-error'), findsNothing);
      expect(keyed('display-error-help'), findsNothing);
    },
  );

  testWidgets(
    'division-by-zero after group capture points to the new denominator',
    (tester) async {
      await pumpCalculator(tester);
      await enter(tester, '(1+2)');
      await taps(tester, ['action-wrap-fraction', 'KEY_0', 'KEY_EQUALS']);
      expect(result(tester), 'Mathem. Fehler');
      expect(formula(tester).errorCursor!.offset, 1);
      expect(pathOf(formula(tester).errorCursor!), [
        (0, FractionField.denominator),
      ]);
      await tap(tester, 'KEY_DOWN');
      expectCursor(tester, 1, [(0, FractionField.denominator)]);
      await taps(tester, ['KEY_DEL', 'KEY_3', 'KEY_EQUALS']);
      expect(result(tester), '1');
    },
  );

  testWidgets('320-pixel layout supports group capture and explanatory text', (
    tester,
  ) async {
    await pumpCalculator(tester, size: const Size(320, 568));
    await enter(tester, '(1+2)');
    await tap(tester, 'action-wrap-fraction');
    expectCursor(tester, 0, [(0, FractionField.denominator)]);
    expect(tester.takeException(), isNull);
    await taps(tester, ['KEY_3', 'KEY_EQUALS']);
    expect(result(tester), '1');
    expect(tester.takeException(), isNull);
  });
}
