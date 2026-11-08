import 'package:calculator_core/calculator_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fx991_calculator/application/key_layout.dart';
import 'package:fx991_calculator/main.dart';
import 'package:fx991_calculator/presentation/editor/fraction_expression_view.dart';

// The two independent input drafts are an explicit prototype rule, not an
// assertion about mode switching in the original calculator or emulator.
Finder keyed(String id) => find.byKey(ValueKey(id));

String result(WidgetTester tester) =>
    tester.widget<Text>(keyed('display-result')).data!;

String answer(WidgetTester tester) =>
    tester.widget<Text>(keyed('display-answer')).data!;

String linearExpression(WidgetTester tester) =>
    tester.widget<Text>(keyed('display-expression')).textSpan!.toPlainText();

FractionExpressionView formula(WidgetTester tester) =>
    tester.widget<FractionExpressionView>(find.byType(FractionExpressionView));

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
  // Regression cases select linear input explicitly; the device defaults to Math.
  await tester.ensureVisible(find.byKey(const ValueKey('input-linear')));
  await tester.tap(find.byKey(const ValueKey('input-linear')));
  await tester.pumpAndSettle();
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

Future<void> hardwareKey(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  String? character,
}) async {
  await tester.sendKeyDownEvent(key, character: character);
  await tester.pump();
  await tester.sendKeyUpEvent(key);
  await tester.pump();
}

void expectCursor(
  WidgetTester tester,
  int offset,
  List<(int, FractionField)> path,
) {
  final cursor = formula(tester).snapshot.cursor;
  expect(cursor.offset, offset);
  expect([for (final step in cursor.path) (step.nodeIndex, step.field)], path);
  expect(keyed('formula-cursor'), findsOneWidget);
}

Future<void> enterThird(WidgetTester tester) =>
    taps(tester, ['KEY_FRACTION', 'KEY_1', 'KEY_RIGHT', 'KEY_3']);

void expectEnabledCount(WidgetTester tester, int enabledCount) {
  final definitions = calculatorRows.expand((row) => row).toList();
  expect(definitions, hasLength(50));
  expect(definitions.map((definition) => definition.id).toSet(), hasLength(50));
  final buttons = [
    for (final definition in definitions)
      tester.widget<FilledButton>(keyed(definition.id)),
  ];
  expect(
    buttons.where((button) => button.onPressed != null),
    hasLength(enabledCount),
  );
  expect(
    buttons.where((button) => button.onPressed == null),
    hasLength(50 - enabledCount),
  );
}

void expectCursorVisibleInDisplay(WidgetTester tester) {
  final display = tester.getRect(keyed('display-structured'));
  final cursor = tester.getRect(keyed('formula-cursor'));
  expect(cursor.left, greaterThanOrEqualTo(display.left - 0.01));
  expect(cursor.right, lessThanOrEqualTo(display.right + 0.01));
  expect(cursor.top, greaterThanOrEqualTo(display.top - 0.01));
  expect(cursor.bottom, lessThanOrEqualTo(display.bottom + 0.01));
}

void main() {
  testWidgets(
    'starts linear and enables structural-only controls when switched',
    (tester) async {
      await pumpCalculator(tester);
      expect(find.text('Berechnungen · Linear'), findsOneWidget);
      expect(keyed('input-linear'), findsOneWidget);
      expect(keyed('input-fractions'), findsOneWidget);
      expectEnabledCount(tester, 33);
      expect(
        tester.widget<FilledButton>(keyed('KEY_FRACTION')).onPressed,
        isNull,
      );
      await tap(tester, 'input-fractions');
      expect(find.text('Berechnungen · Brüche'), findsOneWidget);
      expect(keyed('display-structured'), findsOneWidget);
      expect(find.byType(FractionExpressionView), findsOneWidget);
      expectEnabledCount(tester, 36);
      for (final definition in calculatorRows.expand((row) => row)) {
        final expected =
            CalculatorKey.fromId(definition.id) != null ||
            const {
              'KEY_SHIFT',
              'KEY_MENU',
              'KEY_ON',
              'KEY_SD',
              'KEY_M_PLUS',
              'KEY_STO',
            }.contains(definition.id) ||
            {'KEY_FRACTION', 'KEY_UP', 'KEY_DOWN'}.contains(definition.id);
        expect(
          tester.widget<FilledButton>(keyed(definition.id)).onPressed != null,
          expected,
          reason: definition.id,
        );
      }
      expect(keyed('placeholder-root'), findsOneWidget);
      expectCursor(tester, 0, []);
      await tap(tester, 'input-linear');
      expectEnabledCount(tester, 33);
      expect(
        tester.widget<FilledButton>(keyed('KEY_FRACTION')).onPressed,
        isNull,
      );
      expect(linearExpression(tester), '│');
    },
  );

  testWidgets('one fraction tap creates exactly one empty template', (
    tester,
  ) async {
    await pumpCalculator(tester);
    await tap(tester, 'input-fractions');
    await tap(tester, 'KEY_FRACTION');
    expect(formula(tester).snapshot.root.nodes, hasLength(1));
    final fraction =
        formula(tester).snapshot.root.nodes.single as EditorFraction;
    expect(fraction.numerator.nodes, isEmpty);
    expect(fraction.denominator.nodes, isEmpty);
    expect(keyed('fraction-root/0'), findsOneWidget);
    expect(keyed('placeholder-root/f0n'), findsOneWidget);
    expect(keyed('placeholder-root/f0d'), findsOneWidget);
    expectCursor(tester, 0, [(0, FractionField.numerator)]);
  });

  testWidgets('touch entry one third plus one sixth gives an exact half', (
    tester,
  ) async {
    await pumpCalculator(tester);
    await tap(tester, 'input-fractions');
    await enterThird(tester);
    await taps(tester, [
      'KEY_RIGHT',
      'KEY_ADD',
      'KEY_FRACTION',
      'KEY_1',
      'KEY_RIGHT',
      'KEY_6',
      'KEY_EQUALS',
    ]);
    expect(result(tester), '1/2');
    expect(answer(tester), 'Ans: 1/2');
    expect(formula(tester).showCursor, isFalse);
    expect(keyed('formula-cursor'), findsNothing);
    expect(keyed('fraction-root/0'), findsOneWidget);
    expect(keyed('fraction-root/2'), findsOneWidget);
    await tap(tester, 'KEY_LEFT');
    expectCursor(tester, 3, []);
    expect(result(tester), '');
    await tap(tester, 'KEY_LEFT');
    expectCursor(tester, 1, [(2, FractionField.denominator)]);
  });

  testWidgets(
    'nested fraction one over two thirds evaluates from the display',
    (tester) async {
      await pumpCalculator(tester);
      await tap(tester, 'input-fractions');
      await taps(tester, [
        'KEY_FRACTION',
        'KEY_1',
        'KEY_RIGHT',
        'KEY_FRACTION',
        'KEY_2',
        'KEY_RIGHT',
        'KEY_3',
      ]);
      expect(keyed('fraction-root/f0d/0'), findsOneWidget);
      expectCursor(tester, 1, [
        (0, FractionField.denominator),
        (0, FractionField.denominator),
      ]);
      await tap(tester, 'KEY_EQUALS');
      expect(result(tester), '3/2');
      expect(answer(tester), 'Ans: 3/2');
      expect(keyed('formula-cursor'), findsNothing);
    },
  );

  testWidgets(
    'error navigation restores the saved field cursor for correction',
    (tester) async {
      await pumpCalculator(tester);
      await tap(tester, 'input-fractions');
      await taps(tester, ['KEY_7', 'KEY_EQUALS']);
      await taps(tester, [
        'KEY_FRACTION',
        'KEY_1',
        'KEY_RIGHT',
        'KEY_0',
        'KEY_EQUALS',
      ]);
      expect(result(tester), 'Mathem. Fehler');
      expect(answer(tester), 'Ans: 7');
      expect(keyed('formula-cursor'), findsNothing);
      await tap(tester, 'KEY_9');
      expect(result(tester), 'Mathem. Fehler');
      await tap(tester, 'KEY_LEFT');
      // Restore the original denominator cursor; do not map an error offset from
      // the generated linear expression back into the structural editor.
      expectCursor(tester, 1, [(0, FractionField.denominator)]);
      expect(result(tester), '');
      await tap(tester, 'KEY_DEL');
      expectCursor(tester, 0, [(0, FractionField.denominator)]);
      expect(keyed('placeholder-root/f0d'), findsOneWidget);
      await taps(tester, ['KEY_2', 'KEY_EQUALS']);
      expect(result(tester), '1/2');
      expect(answer(tester), 'Ans: 1/2');
    },
  );

  testWidgets('empty field errors clear with AC without losing the answer', (
    tester,
  ) async {
    await pumpCalculator(tester);
    await tap(tester, 'input-fractions');
    await enterThird(tester);
    await tap(tester, 'KEY_EQUALS');
    await taps(tester, ['KEY_FRACTION', 'KEY_2', 'KEY_EQUALS']);
    expect(result(tester), 'Syntaxfehler');
    expect(answer(tester), 'Ans: 1/3');
    await tap(tester, 'KEY_AC');
    expect(keyed('fraction-root/0'), findsNothing);
    expect(keyed('placeholder-root'), findsOneWidget);
    expectCursor(tester, 0, []);
    expect(result(tester), '');
    expect(answer(tester), 'Ans: 1/3');
  });

  testWidgets(
    'exact Ans continuation and atomic deletion work in fractions mode',
    (tester) async {
      await pumpCalculator(tester);
      await tap(tester, 'input-fractions');
      await enterThird(tester);
      await tap(tester, 'KEY_EQUALS');
      await tap(tester, 'KEY_MULTIPLY');
      final nodes = formula(tester).snapshot.root.nodes;
      expect(nodes, hasLength(2));
      expect((nodes.first as EditorText).text, 'Ans');
      expect((nodes.last as EditorText).text, '*');
      expectCursor(tester, 2, []);
      await taps(tester, ['KEY_6', 'KEY_EQUALS']);
      expect(result(tester), '2');
      await taps(tester, ['KEY_AC', 'KEY_ANS']);
      expect(formula(tester).snapshot.root.nodes, hasLength(1));
      expectCursor(tester, 1, []);
      await tap(tester, 'KEY_DEL');
      expect(keyed('placeholder-root'), findsOneWidget);
      expectCursor(tester, 0, []);
      expect(answer(tester), 'Ans: 2');
      await taps(tester, ['KEY_ANS', 'KEY_EQUALS']);
      expect(result(tester), '2');
    },
  );

  testWidgets('fraction key after a result starts a fresh structural draft', (
    tester,
  ) async {
    await pumpCalculator(tester);
    await tap(tester, 'input-fractions');
    await taps(tester, ['KEY_7', 'KEY_EQUALS', 'KEY_FRACTION']);
    expect(formula(tester).snapshot.root.nodes, hasLength(1));
    expect(formula(tester).snapshot.root.nodes.single, isA<EditorFraction>());
    expectCursor(tester, 0, [(0, FractionField.numerator)]);
    expect(keyed('placeholder-root/f0n'), findsOneWidget);
    expect(keyed('placeholder-root/f0d'), findsOneWidget);
    expect(result(tester), '');
    expect(answer(tester), 'Ans: 7');
  });

  testWidgets('switching preserves drafts and cursors while sharing Ans', (
    tester,
  ) async {
    await pumpCalculator(tester);
    await taps(tester, ['KEY_7', 'KEY_EQUALS', 'KEY_1', 'KEY_2', 'KEY_LEFT']);
    expect(linearExpression(tester), '1│2');
    expect(answer(tester), 'Ans: 7');
    await tap(tester, 'input-fractions');
    // Drafts stay separate; both input modes use the current shared Ans.
    expect(keyed('placeholder-root'), findsOneWidget);
    expect(answer(tester), 'Ans: 7');
    await taps(tester, [
      'KEY_FRACTION',
      'KEY_1',
      'KEY_RIGHT',
      'KEY_2',
      'KEY_EQUALS',
      'KEY_FRACTION',
      'KEY_9',
    ]);
    expect(answer(tester), 'Ans: 1/2');
    expectCursor(tester, 1, [(0, FractionField.numerator)]);
    await tap(tester, 'input-linear');
    expect(linearExpression(tester), '1│2');
    expect(answer(tester), 'Ans: 1/2');
    expect(result(tester), '');
    await tap(tester, 'input-fractions');
    final draft = formula(tester).snapshot.root.nodes.single as EditorFraction;
    expect((draft.numerator.nodes.single as EditorText).text, '9');
    expect(draft.denominator.nodes, isEmpty);
    expectCursor(tester, 1, [(0, FractionField.numerator)]);
    expect(answer(tester), 'Ans: 1/2');
    await tap(tester, 'KEY_AC');
    await tap(tester, 'input-linear');
    expect(linearExpression(tester), '1│2');
    expect(answer(tester), 'Ans: 1/2');
  });

  testWidgets(
    'returning to a completed structural result keeps the cursor hidden',
    (tester) async {
      await pumpCalculator(tester);
      await tap(tester, 'input-fractions');
      await enterThird(tester);
      await tap(tester, 'KEY_EQUALS');
      await tap(tester, 'input-linear');
      await taps(tester, ['KEY_4', 'KEY_EQUALS']);
      expect(answer(tester), 'Ans: 4');
      await tap(tester, 'input-fractions');
      expect(result(tester), '1/3');
      expect(answer(tester), 'Ans: 4');
      expect(formula(tester).showCursor, isFalse);
      expect(keyed('formula-cursor'), findsNothing);
    },
  );

  testWidgets(
    'hardware navigation enters fields and Repeat produces no edits',
    (tester) async {
      await pumpCalculator(tester);
      await tap(tester, 'input-fractions');
      await tap(tester, 'KEY_FRACTION');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.digit1, character: '1');
      await tester.pump();
      await tester.sendKeyRepeatEvent(
        LogicalKeyboardKey.digit1,
        character: '1',
      );
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.digit1);
      await tester.pump();
      final fraction =
          formula(tester).snapshot.root.nodes.single as EditorFraction;
      expect(fraction.numerator.nodes, hasLength(1));
      expectCursor(tester, 1, [(0, FractionField.numerator)]);
      await hardwareKey(tester, LogicalKeyboardKey.arrowRight);
      expectCursor(tester, 0, [(0, FractionField.denominator)]);
      await hardwareKey(tester, LogicalKeyboardKey.digit3, character: '3');
      await hardwareKey(tester, LogicalKeyboardKey.enter);
      expect(result(tester), '1/3');
      await hardwareKey(tester, LogicalKeyboardKey.arrowLeft);
      expectCursor(tester, 1, []);
      await hardwareKey(tester, LogicalKeyboardKey.arrowLeft);
      expectCursor(tester, 1, [(0, FractionField.denominator)]);
      await hardwareKey(tester, LogicalKeyboardKey.backspace);
      expect(keyed('placeholder-root/f0d'), findsOneWidget);
      await hardwareKey(tester, LogicalKeyboardKey.digit6, character: '6');
      await hardwareKey(tester, LogicalKeyboardKey.numpadEnter);
      expect(result(tester), '1/6');
    },
  );

  testWidgets(
    '320x568 supports mode selection and fraction entry without overflow',
    (tester) async {
      await pumpCalculator(tester, size: const Size(320, 568));
      expect(tester.takeException(), isNull);
      await tap(tester, 'input-fractions');
      await enterThird(tester);
      await tap(tester, 'KEY_EQUALS');
      expect(result(tester), '1/3');
      await tester.ensureVisible(keyed('KEY_EQUALS'));
      await tester.pumpAndSettle();
      expect(keyed('KEY_EQUALS').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tap(tester, 'input-linear');
      expect(linearExpression(tester), '│');
      expectEnabledCount(tester, 33);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'long hardware entry reveals the cursor without scrolling the page',
    (tester) async {
      await pumpCalculator(tester);
      await tap(tester, 'input-fractions');
      final pageScroll = tester.state<ScrollableState>(
        find.ancestor(
          of: keyed('calculator-display'),
          matching: find.byType(Scrollable),
        ),
      );
      final pageOffset = pageScroll.position.pixels;
      for (var index = 0; index < 80; index++) {
        await hardwareKey(tester, LogicalKeyboardKey.digit1, character: '1');
      }
      await tester.pumpAndSettle();
      expectCursor(tester, 80, []);
      expectCursorVisibleInDisplay(tester);
      expect(pageScroll.position.pixels, pageOffset);
      final horizontal = tester
          .stateList<ScrollableState>(
            find.descendant(
              of: keyed('display-structured'),
              matching: find.byType(Scrollable),
            ),
          )
          .singleWhere(
            (state) => state.position.axisDirection == AxisDirection.right,
          );
      expect(horizontal.position.maxScrollExtent, greaterThan(0));
      expect(horizontal.position.pixels, greaterThan(0));
      for (var index = 0; index < 80; index++) {
        await hardwareKey(tester, LogicalKeyboardKey.arrowLeft);
      }
      await tester.pumpAndSettle();
      expectCursor(tester, 0, []);
      expectCursorVisibleInDisplay(tester);
      expect(horizontal.position.pixels, 0);
      expect(pageScroll.position.pixels, pageOffset);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'nested denominator editing follows the cursor vertically inside display',
    (tester) async {
      await pumpCalculator(tester);
      await tap(tester, 'input-fractions');
      for (var depth = 0; depth < 8; depth++) {
        await tap(tester, 'KEY_FRACTION');
        await hardwareKey(tester, LogicalKeyboardKey.digit1, character: '1');
        await hardwareKey(tester, LogicalKeyboardKey.arrowRight);
      }
      await hardwareKey(tester, LogicalKeyboardKey.digit3, character: '3');
      await tester.pumpAndSettle();
      expectCursor(
        tester,
        1,
        List.generate(8, (_) => (0, FractionField.denominator)),
      );
      expectCursorVisibleInDisplay(tester);
      final vertical = tester
          .stateList<ScrollableState>(
            find.descendant(
              of: keyed('display-structured'),
              matching: find.byType(Scrollable),
            ),
          )
          .singleWhere(
            (state) => state.position.axisDirection == AxisDirection.down,
          );
      expect(vertical.position.maxScrollExtent, greaterThan(0));
      expect(vertical.position.pixels, greaterThan(0));
      expect(tester.takeException(), isNull);
    },
  );
}
