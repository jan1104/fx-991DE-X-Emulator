import 'package:calculator_core/calculator_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fx991_calculator/application/key_layout.dart';
import 'package:fx991_calculator/main.dart';
import 'package:fx991_calculator/presentation/editor/fraction_expression_view.dart';

// "Als Zähler" is a separate application action. These tests do not assign
// capture behaviour to Casio's physical fraction key or to a keyboard shortcut.
Finder keyed(String id) => find.byKey(ValueKey(id));

FractionExpressionView formula(WidgetTester tester) =>
    tester.widget<FractionExpressionView>(find.byType(FractionExpressionView));

String result(WidgetTester tester) =>
    tester.widget<Text>(keyed('display-result')).data!;

List<Object> tree(EditorSequence sequence) => [
  for (final node in sequence.nodes)
    switch (node) {
      EditorText(:final text) => text,
      EditorAbsolute(:final argument) => {'argument': tree(argument)},
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

Future<void> pumpCalculator(
  WidgetTester tester, {
  bool structured = true,
  Size size = const Size(800, 1000),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const CalculatorApp());
  await tester.pumpAndSettle();
  await tap(tester, structured ? 'input-fractions' : 'input-linear');
}

int physicalEnabledCount(WidgetTester tester) => calculatorRows
    .expand((row) => row)
    .where(
      (definition) =>
          tester.widget<FilledButton>(keyed(definition.id)).onPressed != null,
    )
    .length;

void main() {
  testWidgets(
    'capture is a separate explained action and preserves keyboard counts',
    (tester) async {
      await pumpCalculator(tester, structured: false);
      expect(keyed('action-wrap-fraction'), findsNothing);
      expect(calculatorRows.expand((row) => row), hasLength(50));
      expect(physicalEnabledCount(tester), 34);
      await tap(tester, 'input-fractions');
      expect(physicalEnabledCount(tester), 37);
      expect(keyed('action-wrap-fraction'), findsOneWidget);
      expect(
        find.descendant(
          of: keyed('action-wrap-fraction'),
          matching: find.text('Als Zähler'),
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<TextButton>(keyed('action-wrap-fraction')).onPressed,
        isNull,
      );
      const explanation =
          'Zahl, Ans, Bruch, Betrag oder Klammergruppe links vom Cursor übernehmen';
      final tooltipExplains = tester
          .widgetList<Tooltip>(find.byType(Tooltip))
          .any((tooltip) => tooltip.message == explanation);
      expect(
        tooltipExplains || find.text(explanation).evaluate().isNotEmpty,
        isTrue,
      );
      await tap(tester, 'KEY_1');
      expect(
        tester.widget<TextButton>(keyed('action-wrap-fraction')).onPressed,
        isNotNull,
      );
      expect(physicalEnabledCount(tester), 37);
    },
  );

  testWidgets('captures all digits of twelve and enters an empty denominator', (
    tester,
  ) async {
    await pumpCalculator(tester);
    await taps(tester, ['KEY_1', 'KEY_2']);
    final before = formula(tester).snapshot;
    await tap(tester, 'action-wrap-fraction');
    expect(tree(formula(tester).snapshot.root), [
      {
        'numerator': ['1', '2'],
        'denominator': <Object>[],
      },
    ]);
    expectCursor(tester, 0, [(0, FractionField.denominator)]);
    expect(keyed('placeholder-root/f0d'), findsOneWidget);
    expect(tree(before.root), ['1', '2']);
    expect(before.cursor.offset, 2);
    await taps(tester, ['KEY_3', 'KEY_EQUALS']);
    expect(result(tester), '4');
  });

  testWidgets('decimal capture retains exact decimal value', (tester) async {
    await pumpCalculator(tester);
    await taps(tester, [
      'KEY_0',
      'KEY_DECIMAL',
      'KEY_5',
      'action-wrap-fraction',
    ]);
    expect(tree(formula(tester).snapshot.root), [
      {
        'numerator': ['0', ',', '5'],
        'denominator': <Object>[],
      },
    ]);
    await taps(tester, ['KEY_2', 'KEY_EQUALS']);
    expect(result(tester), '1/4');
  });

  testWidgets(
    'capture leaves the preceding addition outside the new fraction',
    (tester) async {
      await pumpCalculator(tester);
      await taps(tester, ['KEY_2', 'KEY_ADD', 'KEY_3', 'action-wrap-fraction']);
      expect(tree(formula(tester).snapshot.root), [
        '2',
        '+',
        {
          'numerator': ['3'],
          'denominator': <Object>[],
        },
      ]);
      expectCursor(tester, 0, [(2, FractionField.denominator)]);
      await taps(tester, ['KEY_2', 'KEY_EQUALS']);
      expect(result(tester), '7/2');
    },
  );

  testWidgets('a leading minus remains outside the captured number', (
    tester,
  ) async {
    await pumpCalculator(tester);
    await taps(tester, ['KEY_NEGATE', 'KEY_3', 'action-wrap-fraction']);
    expect(tree(formula(tester).snapshot.root), [
      '-',
      {
        'numerator': ['3'],
        'denominator': <Object>[],
      },
    ]);
    expectCursor(tester, 0, [(1, FractionField.denominator)]);
    await taps(tester, ['KEY_2', 'KEY_EQUALS']);
    expect(result(tester), '-3/2');
  });

  testWidgets('captures a whole previous fraction as a nested numerator', (
    tester,
  ) async {
    await pumpCalculator(tester);
    await taps(tester, [
      'KEY_FRACTION',
      'KEY_1',
      'KEY_DOWN',
      'KEY_2',
      'KEY_RIGHT',
      'action-wrap-fraction',
    ]);
    expect(tree(formula(tester).snapshot.root), [
      {
        'numerator': [
          {
            'numerator': ['1'],
            'denominator': ['2'],
          },
        ],
        'denominator': <Object>[],
      },
    ]);
    expect(keyed('fraction-root/f0n/0'), findsOneWidget);
    expectCursor(tester, 0, [(0, FractionField.denominator)]);
    await taps(tester, ['KEY_3', 'KEY_EQUALS']);
    expect(result(tester), '1/6');
  });

  testWidgets('Ans stays one atomic numerator with its prior exact value', (
    tester,
  ) async {
    await pumpCalculator(tester);
    await taps(tester, [
      'KEY_FRACTION',
      'KEY_1',
      'KEY_DOWN',
      'KEY_3',
      'KEY_EQUALS',
      'KEY_AC',
      'KEY_ANS',
      'action-wrap-fraction',
    ]);
    expect(tree(formula(tester).snapshot.root), [
      {
        'numerator': ['Ans'],
        'denominator': <Object>[],
      },
    ]);
    expect(tester.widget<Text>(keyed('display-answer')).data, 'Ans: 1/3');
    expectCursor(tester, 0, [(0, FractionField.denominator)]);
    await taps(tester, ['KEY_2', 'KEY_EQUALS']);
    expect(result(tester), '1/6');
  });

  testWidgets('capture at a middle cursor preserves the untouched suffix', (
    tester,
  ) async {
    await pumpCalculator(tester);
    await taps(tester, [
      'KEY_1',
      'KEY_2',
      'KEY_ADD',
      'KEY_3',
      'KEY_LEFT',
      'KEY_LEFT',
      'action-wrap-fraction',
    ]);
    expect(tree(formula(tester).snapshot.root), [
      {
        'numerator': ['1', '2'],
        'denominator': <Object>[],
      },
      '+',
      '3',
    ]);
    expectCursor(tester, 0, [(0, FractionField.denominator)]);
    await taps(tester, ['KEY_3', 'KEY_EQUALS']);
    expect(result(tester), '7');
  });

  testWidgets(
    'capture inside an outer numerator preserves its containing field',
    (tester) async {
      await pumpCalculator(tester);
      await taps(tester, [
        'KEY_FRACTION',
        'KEY_1',
        'KEY_2',
        'action-wrap-fraction',
      ]);
      expectCursor(tester, 0, [
        (0, FractionField.numerator),
        (0, FractionField.denominator),
      ]);
      expect(tree(formula(tester).snapshot.root), [
        {
          'numerator': [
            {
              'numerator': ['1', '2'],
              'denominator': <Object>[],
            },
          ],
          'denominator': <Object>[],
        },
      ]);
      await taps(tester, [
        'KEY_3',
        'KEY_RIGHT',
        'KEY_DOWN',
        'KEY_2',
        'KEY_EQUALS',
      ]);
      expect(result(tester), '2');
    },
  );

  for (final sequence in [
    ['KEY_2', 'KEY_ADD'],
    ['KEY_1', 'KEY_2', 'KEY_3', 'KEY_4', 'KEY_LEFT', 'KEY_LEFT'],
  ]) {
    testWidgets(
      'rejects unsupported capture atomically after ${sequence.join(' ')}',
      (tester) async {
        await pumpCalculator(tester);
        await taps(tester, sequence);
        final before = formula(tester).snapshot;
        final beforeTree = tree(before.root);
        final beforePath = pathOf(before.cursor);
        await tap(tester, 'action-wrap-fraction');
        expect(result(tester), 'Noch nicht verfügbar');
        expect(tree(formula(tester).snapshot.root), beforeTree);
        expectCursor(tester, before.cursor.offset, beforePath);
        expect(
          tester.widget<TextButton>(keyed('action-wrap-fraction')).onPressed,
          isNull,
        );
        expect(tree(before.root), beforeTree);
      },
    );
  }

  testWidgets(
    'a balanced group formerly rejected is now a captured numerator',
    (tester) async {
      await pumpCalculator(tester);
      await taps(tester, [
        'KEY_LPAREN',
        'KEY_1',
        'KEY_ADD',
        'KEY_2',
        'KEY_RPAREN',
        'action-wrap-fraction',
      ]);
      expect(tree(formula(tester).snapshot.root), [
        {
          'numerator': ['(', '1', '+', '2', ')'],
          'denominator': <Object>[],
        },
      ]);
      expectCursor(tester, 0, [(0, FractionField.denominator)]);
      expect(result(tester), '');
    },
  );

  testWidgets(
    'invalid decimal capture is a syntax failure with its tree preserved',
    (tester) async {
      await pumpCalculator(tester);
      await taps(tester, [
        'KEY_1',
        'KEY_DECIMAL',
        'KEY_2',
        'KEY_DECIMAL',
        'KEY_3',
      ]);
      final before = formula(tester).snapshot;
      await tap(tester, 'action-wrap-fraction');
      expect(result(tester), 'Syntaxfehler');
      expect(tree(formula(tester).snapshot.root), tree(before.root));
      expectCursor(tester, before.cursor.offset, pathOf(before.cursor));
      expect(
        tester.widget<TextButton>(keyed('action-wrap-fraction')).onPressed,
        isNull,
      );
    },
  );

  testWidgets(
    'result and field-start states disable capture without changing the draft',
    (tester) async {
      await pumpCalculator(tester);
      await taps(tester, ['KEY_1', 'KEY_ADD', 'KEY_1', 'KEY_EQUALS']);
      expect(result(tester), '2');
      expect(
        tester.widget<TextButton>(keyed('action-wrap-fraction')).onPressed,
        isNull,
      );
      await tap(tester, 'action-wrap-fraction');
      expect(result(tester), '2');
      await taps(tester, ['KEY_AC', 'KEY_FRACTION']);
      expectCursor(tester, 0, [(0, FractionField.numerator)]);
      expect(
        tester.widget<TextButton>(keyed('action-wrap-fraction')).onPressed,
        isNull,
      );
    },
  );

  testWidgets(
    'physical fraction key still inserts an empty template after a number',
    (tester) async {
      await pumpCalculator(tester);
      await taps(tester, ['KEY_1', 'KEY_2', 'KEY_FRACTION']);
      expect(tree(formula(tester).snapshot.root), [
        '1',
        '2',
        {'numerator': <Object>[], 'denominator': <Object>[]},
      ]);
      expectCursor(tester, 0, [(2, FractionField.numerator)]);
    },
  );

  testWidgets(
    'ordinary hardware division remains a text operator, not capture',
    (tester) async {
      await pumpCalculator(tester);
      await taps(tester, ['KEY_1', 'KEY_2']);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.slash, character: '/');
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.slash);
      await tester.pump();
      expect(tree(formula(tester).snapshot.root), ['1', '2', '/']);
      expectCursor(tester, 3, []);
    },
  );

  testWidgets(
    '320-pixel layout supports the explicit action and keeps linear input unchanged',
    (tester) async {
      await pumpCalculator(
        tester,
        size: const Size(320, 568),
        structured: false,
      );
      await taps(tester, ['KEY_8', 'KEY_ADD', 'KEY_1']);
      await tap(tester, 'input-fractions');
      await taps(tester, [
        'KEY_1',
        'KEY_2',
        'action-wrap-fraction',
        'KEY_3',
        'KEY_EQUALS',
      ]);
      expect(result(tester), '4');
      expect(physicalEnabledCount(tester), 37);
      expect(tester.takeException(), isNull);
      await tap(tester, 'input-linear');
      expect(keyed('action-wrap-fraction'), findsNothing);
      expect(
        tester
            .widget<Text>(keyed('display-expression'))
            .textSpan!
            .toPlainText(),
        '8+1│',
      );
      expect(physicalEnabledCount(tester), 34);
      await tap(tester, 'KEY_EQUALS');
      expect(result(tester), '9');
      expect(tester.takeException(), isNull);
    },
  );
}
