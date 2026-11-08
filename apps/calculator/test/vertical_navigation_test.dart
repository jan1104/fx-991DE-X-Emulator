import 'package:calculator_core/calculator_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fx991_calculator/application/key_layout.dart';
import 'package:fx991_calculator/main.dart';
import 'package:fx991_calculator/presentation/editor/fraction_expression_view.dart';

// Vertical field switching is an explicit prototype rule: only the immediate
// containing fraction is involved. No original-device behaviour is asserted.
Finder keyed(String id) => find.byKey(ValueKey(id));

FractionExpressionView formula(WidgetTester tester) =>
    tester.widget<FractionExpressionView>(find.byType(FractionExpressionView));

String result(WidgetTester tester) =>
    tester.widget<Text>(keyed('display-result')).data!;

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
  expect(keyed('formula-cursor'), findsOneWidget);
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

Future<void> hardwareKey(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(key);
  await tester.pump();
  await tester.sendKeyUpEvent(key);
  await tester.pump();
}

void main() {
  testWidgets('vertical buttons are enabled only in the structured draft', (
    tester,
  ) async {
    await pumpCalculator(tester, structured: false);
    for (final id in ['KEY_UP', 'KEY_DOWN']) {
      expect(tester.widget<FilledButton>(keyed(id)).onPressed, isNull);
    }
    await tap(tester, 'input-fractions');
    for (final id in ['KEY_UP', 'KEY_DOWN']) {
      expect(tester.widget<FilledButton>(keyed(id)).onPressed, isNotNull);
    }
    var enabled = 0;
    for (final definition in calculatorRows.expand((row) => row)) {
      if (tester.widget<FilledButton>(keyed(definition.id)).onPressed != null) {
        enabled++;
      }
    }
    expect(enabled, 36);
    await tap(tester, 'input-linear');
    for (final id in ['KEY_UP', 'KEY_DOWN']) {
      expect(tester.widget<FilledButton>(keyed(id)).onPressed, isNull);
    }
  });

  testWidgets('screen buttons switch fields and clamp the logical offset', (
    tester,
  ) async {
    await pumpCalculator(tester);
    await taps(tester, [
      'KEY_FRACTION',
      'KEY_1',
      'KEY_2',
      'KEY_3',
      'KEY_4',
      'KEY_5',
    ]);
    expectCursor(tester, 5, [(0, FractionField.numerator)]);
    await tap(tester, 'KEY_DOWN');
    expectCursor(tester, 0, [(0, FractionField.denominator)]);
    await taps(tester, ['KEY_6', 'KEY_7', 'KEY_UP']);
    expectCursor(tester, 2, [(0, FractionField.numerator)]);
    await taps(tester, ['KEY_RIGHT', 'KEY_RIGHT', 'KEY_RIGHT']);
    expectCursor(tester, 5, [(0, FractionField.numerator)]);
    await tap(tester, 'KEY_DOWN');
    expectCursor(tester, 2, [(0, FractionField.denominator)]);
    final fraction =
        formula(tester).snapshot.root.nodes.single as EditorFraction;
    expect(
      fraction.numerator.nodes
          .cast<EditorText>()
          .map((node) => node.text)
          .join(),
      '12345',
    );
    expect(
      fraction.denominator.nodes
          .cast<EditorText>()
          .map((node) => node.text)
          .join(),
      '67',
    );
  });

  testWidgets(
    'root and wrong-direction moves do not enter or leave fractions',
    (tester) async {
      await pumpCalculator(tester);
      await taps(tester, ['KEY_UP', 'KEY_DOWN']);
      expectCursor(tester, 0, []);
      await taps(tester, ['KEY_FRACTION', 'KEY_1', 'KEY_UP']);
      expectCursor(tester, 1, [(0, FractionField.numerator)]);
      await taps(tester, ['KEY_DOWN', 'KEY_2', 'KEY_DOWN']);
      expectCursor(tester, 1, [(0, FractionField.denominator)]);
      await taps(tester, ['KEY_RIGHT', 'KEY_UP', 'KEY_DOWN']);
      expectCursor(tester, 1, []);
      expect(result(tester), '');
    },
  );

  testWidgets(
    'nested movement changes only the last path step, without ancestor climb',
    (tester) async {
      await pumpCalculator(tester);
      await taps(tester, [
        'KEY_FRACTION',
        'KEY_9',
        'KEY_DOWN',
        'KEY_FRACTION',
        'KEY_1',
        'KEY_2',
        'KEY_DOWN',
        'KEY_3',
      ]);
      final saved = formula(tester).snapshot;
      final denominatorPath = [
        (0, FractionField.denominator),
        (0, FractionField.denominator),
      ];
      final numeratorPath = [
        (0, FractionField.denominator),
        (0, FractionField.numerator),
      ];
      expectCursor(tester, 1, denominatorPath);
      await taps(tester, ['KEY_UP', 'KEY_UP']);
      expectCursor(tester, 1, numeratorPath);
      await taps(tester, ['KEY_DOWN', 'KEY_DOWN']);
      expectCursor(tester, 1, denominatorPath);
      expect(pathOf(saved.cursor), denominatorPath);
      expect(saved.cursor.offset, 1);
      final outer = saved.root.nodes.single as EditorFraction;
      expect((outer.numerator.nodes.single as EditorText).text, '9');
      final inner = outer.denominator.nodes.single as EditorFraction;
      expect(inner.numerator.nodes, hasLength(2));
      expect((inner.denominator.nodes.single as EditorText).text, '3');
    },
  );

  for (final navigation in ['KEY_UP', 'KEY_DOWN']) {
    testWidgets(
      'first $navigation after result restores root end and preserves Ans',
      (tester) async {
        await pumpCalculator(tester);
        await taps(tester, [
          'KEY_FRACTION',
          'KEY_1',
          'KEY_DOWN',
          'KEY_2',
          'KEY_EQUALS',
        ]);
        expect(result(tester), '1/2');
        expect(keyed('formula-cursor'), findsNothing);
        await tap(tester, navigation);
        expectCursor(tester, 1, []);
        expect(result(tester), '');
        expect(tester.widget<Text>(keyed('display-answer')).data, 'Ans: 1/2');
        await tap(tester, navigation);
        expectCursor(tester, 1, []);
      },
    );

    testWidgets(
      'first $navigation from error restores errorCursor without field switching',
      (tester) async {
        await pumpCalculator(tester);
        await taps(tester, [
          'KEY_7',
          'KEY_EQUALS',
          'KEY_FRACTION',
          'KEY_1',
          'KEY_ADD',
          'KEY_RIGHT',
          'KEY_2',
          'KEY_EQUALS',
        ]);
        expect(result(tester), 'Syntaxfehler');
        expect(pathOf(formula(tester).errorCursor!), [
          (0, FractionField.numerator),
        ]);
        expect(formula(tester).errorCursor!.offset, 2);
        await tap(tester, navigation);
        expectCursor(tester, 2, [(0, FractionField.numerator)]);
        expect(formula(tester).errorCursor, isNull);
        expect(keyed('formula-error'), findsNothing);
        expect(keyed('display-error-help'), findsNothing);
        expect(tester.widget<Text>(keyed('display-answer')).data, 'Ans: 7');
        await tap(tester, 'KEY_DOWN');
        expectCursor(tester, 1, [(0, FractionField.denominator)]);
      },
    );
  }

  testWidgets(
    'hardware arrows switch fields while repeats cannot move focused buttons',
    (tester) async {
      await pumpCalculator(tester);
      await taps(tester, ['KEY_FRACTION', 'KEY_1']);
      final buttonLabel = tester.element(
        find.descendant(of: keyed('KEY_1'), matching: find.text('1')),
      );
      final focus = Focus.of(buttonLabel);
      focus.requestFocus();
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, same(focus));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expectCursor(tester, 0, [(0, FractionField.denominator)]);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expectCursor(tester, 0, [(0, FractionField.denominator)]);
      expect(FocusManager.instance.primaryFocus, same(focus));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await hardwareKey(tester, LogicalKeyboardKey.arrowUp);
      expectCursor(tester, 0, [(0, FractionField.numerator)]);
      await hardwareKey(tester, LogicalKeyboardKey.arrowDown);
      expectCursor(tester, 0, [(0, FractionField.denominator)]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Ctrl, Meta, and Alt plus a vertical arrow do not navigate fields',
    (tester) async {
      await pumpCalculator(tester);
      await taps(tester, ['KEY_FRACTION', 'KEY_1', 'KEY_DOWN', 'KEY_2']);
      for (final modifier in [
        LogicalKeyboardKey.controlLeft,
        LogicalKeyboardKey.metaLeft,
        LogicalKeyboardKey.altLeft,
      ]) {
        await tester.sendKeyDownEvent(modifier);
        await hardwareKey(tester, LogicalKeyboardKey.arrowUp);
        expectCursor(tester, 1, [(0, FractionField.denominator)]);
        await tester.sendKeyUpEvent(modifier);
        await tester.pump();
        await hardwareKey(tester, LogicalKeyboardKey.arrowUp);
        expectCursor(tester, 1, [(0, FractionField.numerator)]);
        await hardwareKey(tester, LogicalKeyboardKey.arrowDown);
        expectCursor(tester, 1, [(0, FractionField.denominator)]);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'linear arrows remain unassigned without a core unsupported failure',
    (tester) async {
      await pumpCalculator(
        tester,
        structured: false,
        size: const Size(320, 568),
      );
      await taps(tester, ['KEY_1', 'KEY_2']);
      await hardwareKey(tester, LogicalKeyboardKey.arrowUp);
      await hardwareKey(tester, LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      final text = tester.widget<Text>(keyed('display-expression'));
      expect(text.textSpan!.toPlainText(), '12│');
      expect(result(tester), '');
      expect(find.byType(FractionExpressionView), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '320x568 screen vertical buttons allow fraction calculation without overflow',
    (tester) async {
      await pumpCalculator(tester, size: const Size(320, 568));
      await taps(tester, [
        'KEY_FRACTION',
        'KEY_1',
        'KEY_DOWN',
        'KEY_2',
        'KEY_UP',
        'KEY_EQUALS',
      ]);
      expect(result(tester), '1/2');
      await tester.ensureVisible(keyed('KEY_UP'));
      await tester.pumpAndSettle();
      expect(keyed('KEY_UP').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
