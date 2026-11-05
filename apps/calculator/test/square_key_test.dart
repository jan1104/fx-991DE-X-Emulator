import 'package:calculator_core/calculator_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fx991_calculator/application/key_layout.dart';
import 'package:fx991_calculator/main.dart';
import 'package:fx991_calculator/presentation/editor/fraction_expression_view.dart';

Finder keyed(String id) => find.byKey(ValueKey(id));

String result(WidgetTester tester) =>
    tester.widget<Text>(keyed('display-result')).data!;

FractionExpressionView formula(WidgetTester tester) =>
    tester.widget<FractionExpressionView>(find.byType(FractionExpressionView));

String source(WidgetTester tester, bool structured) => structured
    ? formula(tester).snapshot.root.nodes
          .cast<EditorText>()
          .map((node) => node.text)
          .join()
    : tester
          .widget<Text>(keyed('display-expression'))
          .textSpan!
          .toPlainText()
          .replaceAll('│', '');

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

Future<void> enter(WidgetTester tester, String text) async {
  final ids = <String, String>{
    for (var digit = 0; digit <= 9; digit++) '$digit': 'KEY_$digit',
    '+': 'KEY_ADD',
    '-': 'KEY_NEGATE',
    '/': 'KEY_DIVIDE',
    '^': 'KEY_POWER',
    '²': 'KEY_SQUARE',
    '(': 'KEY_LPAREN',
    ')': 'KEY_RPAREN',
  };
  for (final character in text.split('')) {
    await tap(tester, ids[character]!);
  }
}

Future<void> pumpCalculator(
  WidgetTester tester, {
  required bool structured,
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

void main() {
  for (final structured in [false, true]) {
    final mode = structured ? 'structured' : 'linear';
    testWidgets('$mode exposes square in the existing 50-key inventory', (
      tester,
    ) async {
      await pumpCalculator(tester, structured: structured);
      final definitions = calculatorRows.expand((row) => row).toList();
      expect(definitions, hasLength(50));
      expect(
        definitions.map((definition) => definition.id).toSet(),
        hasLength(50),
      );
      expect(
        definitions.where(
          (definition) =>
              tester.widget<FilledButton>(keyed(definition.id)).onPressed !=
              null,
        ),
        hasLength(structured ? 35 : 32),
      );
      expect(
        tester.widget<FilledButton>(keyed('KEY_SQUARE')).onPressed,
        isNotNull,
      );
      expect(
        find.descendant(of: keyed('KEY_SQUARE'), matching: find.text('x²')),
        findsOneWidget,
      );
    });

    for (final entry in {
      '3²²': '81',
      '-2²': '-4',
      '(-2)²': '4',
      '2^3²': '512',
      '2²^3': '64',
    }.entries) {
      testWidgets('$mode screen ${entry.key} gives ${entry.value}', (
        tester,
      ) async {
        await pumpCalculator(tester, structured: structured);
        await enter(tester, entry.key);
        expect(source(tester, structured), entry.key);
        await tap(tester, 'KEY_EQUALS');
        expect(result(tester), entry.value);
      });
    }

    testWidgets('$mode square after result starts exact Ans squared', (
      tester,
    ) async {
      await pumpCalculator(tester, structured: structured);
      await enter(tester, '1/3');
      await taps(tester, ['KEY_EQUALS', 'KEY_SQUARE']);
      expect(source(tester, structured), 'Ans²');
      expect(result(tester), '');
      expect(tester.widget<Text>(keyed('display-answer')).data, 'Ans: 1/3');
      await tap(tester, 'KEY_EQUALS');
      expect(result(tester), '1/9');
      await taps(tester, ['KEY_SQUARE', 'KEY_EQUALS']);
      expect(result(tester), '1/81');
      await tap(tester, 'KEY_AC');
      expect(source(tester, structured), '');
      expect(result(tester), '');
      expect(tester.widget<Text>(keyed('display-answer')).data, 'Ans: 1/81');
      await taps(tester, ['KEY_ANS', 'KEY_EQUALS']);
      expect(result(tester), '1/81');
    });

    testWidgets(
      '$mode empty square is syntax, freezes on error, and accepts repair',
      (tester) async {
        await pumpCalculator(tester, structured: structured);
        await taps(tester, ['KEY_SQUARE', 'KEY_EQUALS']);
        expect(source(tester, structured), '²');
        expect(result(tester), 'Syntaxfehler');
        expect(tester.widget<Text>(keyed('display-answer')).data, 'Ans: 0');
        await tap(tester, 'KEY_SQUARE');
        expect(source(tester, structured), '²');
        expect(result(tester), 'Syntaxfehler');
        await tap(tester, 'KEY_LEFT');
        if (structured) {
          expect(formula(tester).snapshot.cursor.path, isEmpty);
          expect(formula(tester).snapshot.cursor.offset, 0);
        } else {
          expect(
            tester
                .widget<Text>(keyed('display-expression'))
                .textSpan!
                .toPlainText(),
            '│²',
          );
        }
        await taps(tester, ['KEY_2', 'KEY_EQUALS']);
        expect(result(tester), '4');
      },
    );

    testWidgets(
      '$mode inserts and deletes a single square token in the middle',
      (tester) async {
        await pumpCalculator(tester, structured: structured);
        await taps(tester, ['KEY_2', 'KEY_3', 'KEY_LEFT', 'KEY_SQUARE']);
        expect(source(tester, structured), '2²3');
        await tap(tester, 'KEY_DEL');
        expect(source(tester, structured), '23');
        await taps(tester, ['KEY_SQUARE', 'KEY_ADD', 'KEY_EQUALS']);
        expect(source(tester, structured), '2²+3');
        expect(result(tester), '7');
        await tap(tester, 'KEY_AC');
        expect(source(tester, structured), '');
        expect(tester.widget<Text>(keyed('display-answer')).data, 'Ans: 7');
      },
    );

    testWidgets('$mode square works in a 320x568 layout without overflow', (
      tester,
    ) async {
      await pumpCalculator(
        tester,
        structured: structured,
        size: const Size(320, 568),
      );
      await taps(tester, ['KEY_2', 'KEY_SQUARE', 'KEY_EQUALS']);
      expect(result(tester), '4');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'squares an entire structural fraction after leaving its denominator',
    (tester) async {
      await pumpCalculator(tester, structured: true);
      await taps(tester, [
        'KEY_FRACTION',
        'KEY_1',
        'KEY_DOWN',
        'KEY_2',
        'KEY_RIGHT',
        'KEY_SQUARE',
      ]);
      final nodes = formula(tester).snapshot.root.nodes;
      expect(nodes, hasLength(2));
      expect(nodes.first, isA<EditorFraction>());
      expect((nodes.last as EditorText).text, '²');
      expect(formula(tester).snapshot.cursor.path, isEmpty);
      expect(formula(tester).snapshot.cursor.offset, 2);
      await tap(tester, 'KEY_EQUALS');
      expect(result(tester), '1/4');
    },
  );

  testWidgets(
    'invalid postfix maps to its own structural token for correction',
    (tester) async {
      await pumpCalculator(tester, structured: true);
      await enter(tester, '1+²');
      await tap(tester, 'KEY_EQUALS');
      expect(result(tester), 'Syntaxfehler');
      expect(formula(tester).errorCursor!.path, isEmpty);
      expect(formula(tester).errorCursor!.offset, 2);
      expect(formula(tester).snapshot.cursor.offset, 3);
      expect(keyed('formula-error'), findsOneWidget);
      expect(keyed('formula-cursor'), findsNothing);
      await tap(tester, 'KEY_RIGHT');
      expect(formula(tester).snapshot.cursor.offset, 2);
      await taps(tester, ['KEY_2', 'KEY_EQUALS']);
      expect(result(tester), '5');
      expect(keyed('formula-error'), findsNothing);
    },
  );

  testWidgets('structural square is announced as zum Quadrat', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpCalculator(tester, structured: true);
      await enter(tester, '3²');
      final label = tester
          .getSemantics(find.byType(FractionExpressionView))
          .getSemanticsData()
          .label;
      expect(label, contains('zum Quadrat'));
      expect(label, contains('3'));
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('Enter repeat cannot reactivate the focused square button', (
    tester,
  ) async {
    await pumpCalculator(tester, structured: true);
    await taps(tester, ['KEY_2', 'KEY_EQUALS', 'KEY_SQUARE']);
    final label = tester.element(
      find.descendant(of: keyed('KEY_SQUARE'), matching: find.text('x²')),
    );
    final focus = Focus.of(label);
    focus.requestFocus();
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, same(focus));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(result(tester), '4');
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(result(tester), '4');
    expect(formula(tester).showCursor, isFalse);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(result(tester), '4');
  });

  testWidgets(
    'a hardware superscript character has no newly assigned shortcut',
    (tester) async {
      await pumpCalculator(tester, structured: false);
      await tap(tester, 'KEY_2');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.digit2, character: '²');
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.digit2);
      await tester.pump();
      expect(source(tester, false), '2');
      expect(result(tester), '');
    },
  );
}
