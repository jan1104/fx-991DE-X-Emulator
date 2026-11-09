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
  for (var index = 0; index < text.length;) {
    // The superscript sign and digit are two characters but one key/token.
    if (text.startsWith('⁻¹', index)) {
      await tap(tester, 'KEY_RECIPROCAL');
      index += 2;
    } else {
      await tap(tester, ids[text[index]]!);
      index++;
    }
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

    testWidgets('$mode enables reciprocal without adding a physical key', (
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
        hasLength(structured ? 37 : 34),
      );
      expect(
        tester.widget<FilledButton>(keyed('KEY_RECIPROCAL')).onPressed,
        isNotNull,
      );
      expect(
        find.descendant(
          of: keyed('KEY_RECIPROCAL'),
          matching: find.text('x⁻¹'),
        ),
        findsOneWidget,
      );
    });

    for (final entry in {
      '4⁻¹': '1/4',
      '4⁻¹⁻¹': '4',
      '4⁻¹²': '1/16',
      '4²⁻¹': '1/16',
      '-2⁻¹': '-1/2',
      '2⁻¹^3': '1/8',
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

    testWidgets('$mode reciprocal binds inside the power exponent', (
      tester,
    ) async {
      await pumpCalculator(tester, structured: structured);
      await enter(tester, '2^2⁻¹');
      await tap(tester, 'KEY_EQUALS');
      // This means 2^(1/2), not (2^2)^-1. Irrational powers remain outside
      // the exact-rational prototype, so the explicit unsupported state is key.
      expect(result(tester), 'Noch nicht verfügbar');
      expect(source(tester, structured), '2^2⁻¹');
    });

    testWidgets(
      '$mode reciprocal after result uses exact negative fractional Ans',
      (tester) async {
        await pumpCalculator(tester, structured: structured);
        await enter(tester, '-2/3');
        await taps(tester, ['KEY_EQUALS', 'KEY_RECIPROCAL']);
        expect(source(tester, structured), 'Ans⁻¹');
        expect(result(tester), '');
        expect(tester.widget<Text>(keyed('display-answer')).data, 'Ans: -2/3');
        await tap(tester, 'KEY_EQUALS');
        expect(result(tester), '-3/2');
        await taps(tester, ['KEY_RECIPROCAL', 'KEY_EQUALS']);
        expect(result(tester), '-2/3');
        await tap(tester, 'KEY_AC');
        expect(source(tester, structured), '');
        expect(result(tester), '');
        expect(tester.widget<Text>(keyed('display-answer')).data, 'Ans: -2/3');
        await taps(tester, ['KEY_ANS', 'KEY_EQUALS']);
        expect(result(tester), '-2/3');
      },
    );

    testWidgets('$mode zero reciprocal preserves Ans and allows correction', (
      tester,
    ) async {
      await pumpCalculator(tester, structured: structured);
      await taps(tester, [
        'KEY_5',
        'KEY_EQUALS',
        'KEY_0',
        'KEY_RECIPROCAL',
        'KEY_EQUALS',
      ]);
      expect(result(tester), 'Mathem. Fehler');
      expect(source(tester, structured), '0⁻¹');
      expect(tester.widget<Text>(keyed('display-answer')).data, 'Ans: 5');
      await tap(tester, 'KEY_RECIPROCAL');
      expect(source(tester, structured), '0⁻¹');
      await tap(tester, 'KEY_LEFT');
      if (structured) {
        expect(formula(tester).snapshot.cursor.path, isEmpty);
        expect(formula(tester).snapshot.cursor.offset, 1);
      } else {
        expect(
          tester
              .widget<Text>(keyed('display-expression'))
              .textSpan!
              .toPlainText(),
          '0│⁻¹',
        );
      }
      await tap(tester, 'KEY_DEL');
      expect(source(tester, structured), '⁻¹');
      await taps(tester, ['KEY_4', 'KEY_EQUALS']);
      expect(result(tester), '1/4');
    });

    testWidgets(
      '$mode reciprocal without a base is syntax and has no auto Ans',
      (tester) async {
        await pumpCalculator(tester, structured: structured);
        await taps(tester, ['KEY_RECIPROCAL', 'KEY_EQUALS']);
        expect(source(tester, structured), '⁻¹');
        expect(result(tester), 'Syntaxfehler');
        await tap(tester, 'KEY_RIGHT');
        if (structured) {
          expect(formula(tester).snapshot.cursor.offset, 0);
        } else {
          expect(
            tester
                .widget<Text>(keyed('display-expression'))
                .textSpan!
                .toPlainText(),
            '│⁻¹',
          );
        }
        await taps(tester, ['KEY_4', 'KEY_EQUALS']);
        expect(result(tester), '1/4');
      },
    );

    testWidgets(
      '$mode deletes both reciprocal characters in one logical operation',
      (tester) async {
        await pumpCalculator(tester, structured: structured);
        await taps(tester, ['KEY_2', 'KEY_3', 'KEY_LEFT', 'KEY_RECIPROCAL']);
        expect(source(tester, structured), '2⁻¹3');
        if (structured) {
          final snapshot = formula(tester).snapshot;
          expect(snapshot.root.nodes, hasLength(3));
          expect((snapshot.root.nodes[1] as EditorText).text, '⁻¹');
          expect(snapshot.cursor.offset, 2);
        } else {
          expect(
            tester
                .widget<Text>(keyed('display-expression'))
                .textSpan!
                .toPlainText(),
            '2⁻¹│3',
          );
        }
        await tap(tester, 'KEY_DEL');
        expect(source(tester, structured), '23');
        await taps(tester, ['KEY_RECIPROCAL', 'KEY_ADD', 'KEY_EQUALS']);
        expect(source(tester, structured), '2⁻¹+3');
        expect(result(tester), '7/2');
      },
    );

    testWidgets('$mode reciprocal fits a 320x568 screen without overflow', (
      tester,
    ) async {
      await pumpCalculator(
        tester,
        structured: structured,
        size: const Size(320, 568),
      );
      await taps(tester, ['KEY_4', 'KEY_RECIPROCAL', 'KEY_EQUALS']);
      expect(result(tester), '1/4');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('reciprocal in a fraction numerator stays in that field', (
    tester,
  ) async {
    await pumpCalculator(tester, structured: true);
    await taps(tester, ['KEY_FRACTION', 'KEY_4', 'KEY_RECIPROCAL']);
    final snapshot = formula(tester).snapshot;
    final fraction = snapshot.root.nodes.single as EditorFraction;
    expect(
      fraction.numerator.nodes.cast<EditorText>().map((node) => node.text),
      ['4', '⁻¹'],
    );
    expect(snapshot.cursor.path.single.field, FractionField.numerator);
    expect(snapshot.cursor.offset, 2);
    await taps(tester, ['KEY_DOWN', 'KEY_2', 'KEY_EQUALS']);
    expect(result(tester), '1/8');
  });

  testWidgets('reciprocal can apply to a whole structural fraction', (
    tester,
  ) async {
    await pumpCalculator(tester, structured: true);
    await taps(tester, [
      'KEY_FRACTION',
      'KEY_1',
      'KEY_DOWN',
      'KEY_2',
      'KEY_RIGHT',
      'KEY_RECIPROCAL',
    ]);
    final snapshot = formula(tester).snapshot;
    expect(snapshot.root.nodes, hasLength(2));
    expect(snapshot.root.nodes.first, isA<EditorFraction>());
    expect((snapshot.root.nodes.last as EditorText).text, '⁻¹');
    expect(snapshot.cursor.path, isEmpty);
    expect(snapshot.cursor.offset, 2);
    await tap(tester, 'KEY_EQUALS');
    expect(result(tester), '2');
  });

  testWidgets(
    'reciprocal in a denominator deletes and reinserts as one token',
    (tester) async {
      await pumpCalculator(tester, structured: true);
      await taps(tester, [
        'KEY_FRACTION',
        'KEY_1',
        'KEY_DOWN',
        'KEY_4',
        'KEY_RECIPROCAL',
      ]);
      var snapshot = formula(tester).snapshot;
      var fraction = snapshot.root.nodes.single as EditorFraction;
      expect(snapshot.cursor.path.single.field, FractionField.denominator);
      expect(snapshot.cursor.offset, 2);
      expect(
        fraction.denominator.nodes.cast<EditorText>().map((node) => node.text),
        ['4', '⁻¹'],
      );
      await tap(tester, 'KEY_DEL');
      snapshot = formula(tester).snapshot;
      fraction = snapshot.root.nodes.single as EditorFraction;
      expect(fraction.denominator.nodes, hasLength(1));
      expect((fraction.denominator.nodes.single as EditorText).text, '4');
      expect(snapshot.cursor.offset, 1);
      await taps(tester, ['KEY_RECIPROCAL', 'KEY_EQUALS']);
      expect(result(tester), '4');
    },
  );

  testWidgets('structural reciprocal description announces Kehrwert', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpCalculator(tester, structured: true);
      await taps(tester, ['KEY_4', 'KEY_RECIPROCAL']);
      final label = tester
          .getSemantics(find.byType(FractionExpressionView))
          .getSemanticsData()
          .label;
      expect(label, contains('Kehrwert'));
      expect(label, contains('4'));
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('Enter repeat cannot reactivate a focused reciprocal button', (
    tester,
  ) async {
    await pumpCalculator(tester, structured: true);
    await taps(tester, ['KEY_4', 'KEY_EQUALS', 'KEY_RECIPROCAL']);
    final label = tester.element(
      find.descendant(of: keyed('KEY_RECIPROCAL'), matching: find.text('x⁻¹')),
    );
    final focus = Focus.of(label);
    focus.requestFocus();
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, same(focus));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(result(tester), '1/4');
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(result(tester), '1/4');
    expect(formula(tester).showCursor, isFalse);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(result(tester), '1/4');
  });

  testWidgets(
    'hardware reciprocal characters have no newly assigned shortcut',
    (tester) async {
      await pumpCalculator(tester, structured: false);
      await tap(tester, 'KEY_4');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.digit1, character: '⁻¹');
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.digit1);
      await tester.pump();
      expect(source(tester, false), '4');
      expect(result(tester), '');
    },
  );
}
