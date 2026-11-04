import 'package:calculator_core/calculator_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fx991_calculator/main.dart';
import 'package:fx991_calculator/presentation/editor/fraction_expression_view.dart';

// H physical PDF p.21: |2-7|*2=10. Field-navigation and DEL expectations are
// independently specified in BETRAG_EDITOR.md, not observed original behavior.
Finder keyed(String id) => find.byKey(ValueKey(id));
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

Future<void> absolute(WidgetTester tester) =>
    taps(tester, ['KEY_SHIFT', 'KEY_LPAREN']);
Future<void> close(WidgetTester tester, bool math) =>
    tap(tester, math ? 'KEY_RIGHT' : 'KEY_RPAREN');
Future<void> boot(
  WidgetTester tester, {
  required bool math,
  Size size = const Size(800, 1000),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const CalculatorApp());
  await tester.pumpAndSettle();
  await tap(tester, math ? 'input-fractions' : 'input-linear');
}

FractionExpressionView formula(WidgetTester tester) =>
    tester.widget<FractionExpressionView>(find.byType(FractionExpressionView));
String result(WidgetTester tester) =>
    tester.widget<Text>(keyed('display-result')).data!;
String answer(WidgetTester tester) =>
    tester.widget<Text>(keyed('display-answer')).data!;
String source(WidgetTester tester, bool math) => math
    ? FractionEditor.fromSnapshot(formula(tester).snapshot).toExpression()
    : tester
          .widget<Text>(keyed('display-expression'))
          .textSpan!
          .toPlainText()
          .replaceAll('│', '');
Future<void> view(
  WidgetTester tester,
  FractionEditorSnapshot snapshot, {
  double fontSize = 24,
  Color color = Colors.black,
  EditorCursor? errorCursor,
  bool showCursor = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)
            .copyWith(onSurface: color),
      ),
      home: Scaffold(
        body: SizedBox(
          width: 320,
          height: 300,
          child: FractionExpressionView(
            snapshot: snapshot,
            fontSize: fontSize,
            errorCursor: errorCursor,
            showCursor: showCursor,
            followCursor: true,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final math in [false, true]) {
    final mode = math ? 'Math' : 'Linear';
    testWidgets(
      '$mode visible SHIFT parenthesis computes the handbook amount',
      (tester) async {
        await boot(tester, math: math);
        await absolute(tester);
        await taps(tester, ['KEY_2', 'KEY_SUBTRACT', 'KEY_7']);
        await close(tester, math);
        await taps(tester, ['KEY_MULTIPLY', 'KEY_2', 'KEY_EQUALS']);
        expect(result(tester), '10');
        expect(answer(tester), 'Ans: 10');
        expect(source(tester, math), math ? '(Abs(2-7))*2' : 'Abs(2-7)*2');
        expect(
          tester.widgetList<FilledButton>(find.byType(FilledButton)),
          hasLength(50),
        );
        expect(keyed('ACTION_ABS'), findsNothing);
      },
    );

    testWidgets(
      '$mode negative fractional Ans becomes an exact positive amount',
      (tester) async {
        await boot(tester, math: math);
        await taps(tester, [
          'KEY_SUBTRACT',
          'KEY_1',
          'KEY_DIVIDE',
          'KEY_2',
          'KEY_EQUALS',
        ]);
        expect(answer(tester), 'Ans: -1/2');
        await absolute(tester);
        expect(answer(tester), 'Ans: -1/2');
        await close(tester, math);
        await tap(tester, 'KEY_EQUALS');
        expect(result(tester), '1/2');
        expect(answer(tester), 'Ans: 1/2');
      },
    );

    testWidgets('$mode empty argument error recovers inside the argument', (
      tester,
    ) async {
      await boot(tester, math: math);
      await absolute(tester);
      await tap(tester, 'KEY_EQUALS');
      expect(result(tester), 'Syntaxfehler');
      await absolute(tester);
      expect(result(tester), 'Syntaxfehler');
      await taps(tester, ['KEY_LEFT', 'KEY_5']);
      await close(tester, math);
      await tap(tester, 'KEY_EQUALS');
      expect(result(tester), '5');
    });

    testWidgets('$mode DEL treats the prefix or template atomically', (
      tester,
    ) async {
      await boot(tester, math: math);
      await absolute(tester);
      await tap(tester, 'KEY_DEL');
      if (math) {
        expect(formula(tester).snapshot.root.nodes, isEmpty);
      } else {
        expect(source(tester, false), isEmpty);
      }
      await absolute(tester);
      await tap(tester, 'KEY_5');
      await close(tester, math);
      await tap(tester, 'KEY_DEL');
      if (math) {
        expect(formula(tester).snapshot.root.nodes, isEmpty);
      } else {
        expect(source(tester, false), 'Abs(5');
        await tap(tester, 'KEY_DEL');
        expect(source(tester, false), 'Abs(');
        await tap(tester, 'KEY_DEL');
        expect(source(tester, false), isEmpty);
      }
    });

    testWidgets('$mode SHIFT cancellation preserves ordinary parentheses', (
      tester,
    ) async {
      await boot(tester, math: math);
      await taps(tester, [
        'KEY_SHIFT',
        'KEY_SHIFT',
        'KEY_LPAREN',
        'KEY_2',
        'KEY_ADD',
        'KEY_3',
        'KEY_RPAREN',
        'KEY_EQUALS',
      ]);
      expect(result(tester), '5');
      expect(source(tester, math), '(2+3)');
      expect(find.byKey(const ValueKey('absolute-root/0')), findsNothing);
    });

    testWidgets('$mode Enter repeat executes an amount once at 320px', (
      tester,
    ) async {
      await boot(tester, math: math, size: const Size(320, 568));
      await absolute(tester);
      await taps(tester, ['KEY_2', 'KEY_SUBTRACT', 'KEY_7']);
      await close(tester, math);
      await taps(tester, ['KEY_MULTIPLY', 'KEY_2']);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(result(tester), '10');
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(keyed('KEY_LPAREN')).width,
        greaterThanOrEqualTo(44),
      );
    });
  }

  testWidgets(
    'fraction in an argument retains natural height and exact value',
    (tester) async {
      await boot(tester, math: true);
      await absolute(tester);
      await taps(tester, [
        'KEY_FRACTION',
        'KEY_1',
        'KEY_DOWN',
        'KEY_2',
        'KEY_RIGHT',
        'KEY_RIGHT',
        'KEY_EQUALS',
      ]);
      expect(result(tester), '1/2');
      final fraction = tester.getSize(keyed('fraction-root/a0/0'));
      final amount = tester.getSize(keyed('absolute-root/0'));
      expect(amount.height, greaterThan(fraction.height));
      expect(amount.width, greaterThan(fraction.width));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('argument Up Down does not jump across an outer fraction', (
    tester,
  ) async {
    await boot(tester, math: true);
    await tap(tester, 'KEY_FRACTION');
    await absolute(tester);
    await taps(tester, ['KEY_2', 'KEY_SUBTRACT', 'KEY_7', 'KEY_DOWN']);
    expect(formula(tester).snapshot.cursor.path.map((step) => step.field), [
      FractionField.numerator,
      FractionField.argument,
    ]);
    await taps(tester, ['KEY_RIGHT', 'KEY_DOWN', 'KEY_2', 'KEY_EQUALS']);
    expect(result(tester), '5/2');
  });

  testWidgets('nested amounts exit only their current argument', (
    tester,
  ) async {
    await boot(tester, math: true);
    await absolute(tester);
    await absolute(tester);
    await taps(tester, ['KEY_SUBTRACT', 'KEY_3', 'KEY_RIGHT']);
    expect(formula(tester).snapshot.cursor.path, hasLength(1));
    await taps(tester, ['KEY_SUBTRACT', 'KEY_5', 'KEY_RIGHT', 'KEY_EQUALS']);
    expect(result(tester), '2');
    expect(source(tester, true), '(Abs((Abs(-3))-5))');
  });

  testWidgets('Left reenters an argument and DEL removes its empty template', (
    tester,
  ) async {
    await boot(tester, math: true);
    await absolute(tester);
    await taps(tester, ['KEY_5', 'KEY_RIGHT', 'KEY_LEFT']);
    expect(
      formula(tester).snapshot.cursor.path.single.field,
      FractionField.argument,
    );
    expect(formula(tester).snapshot.cursor.offset, 1);
    await taps(tester, ['KEY_DEL', 'KEY_DEL']);
    expect(formula(tester).snapshot.root.nodes, isEmpty);
    expect(formula(tester).snapshot.cursor.path, isEmpty);
  });

  testWidgets('whole amount is captured as one numerator subtree', (
    tester,
  ) async {
    await boot(tester, math: true);
    await absolute(tester);
    await taps(tester, [
      'KEY_2',
      'KEY_SUBTRACT',
      'KEY_7',
      'KEY_RIGHT',
      'action-wrap-fraction',
      'KEY_2',
      'KEY_EQUALS',
    ]);
    expect(result(tester), '5/2');
    final fraction =
        formula(tester).snapshot.root.nodes.single as EditorFraction;
    expect(fraction.numerator.nodes.single, isA<EditorAbsolute>());
  });

  testWidgets(
    'inner denominator failure highlights and restores its exact field',
    (tester) async {
      await boot(tester, math: true);
      await absolute(tester);
      await taps(tester, [
        'KEY_FRACTION',
        'KEY_1',
        'KEY_DOWN',
        'KEY_0',
        'KEY_EQUALS',
      ]);
      expect(result(tester), 'Mathem. Fehler');
      expect(formula(tester).errorCursor!.path.map((step) => step.field), [
        FractionField.argument,
        FractionField.denominator,
      ]);
      expect(keyed('formula-error'), findsOneWidget);
      expect(keyed('formula-error-field'), findsOneWidget);
      await taps(tester, [
        'KEY_LEFT',
        'KEY_RIGHT',
        'KEY_DEL',
        'KEY_2',
        'KEY_EQUALS',
      ]);
      expect(result(tester), '1/2');
    },
  );

  testWidgets(
    'Math user closing parenthesis does not silently close an argument',
    (tester) async {
      await boot(tester, math: true);
      await absolute(tester);
      await taps(tester, ['KEY_2', 'KEY_RPAREN', 'KEY_EQUALS']);
      expect(result(tester), 'Syntaxfehler');
      expect(
        formula(tester).errorCursor!.path.single.field,
        FractionField.argument,
      );
      await taps(tester, ['KEY_LEFT', 'KEY_RIGHT', 'KEY_DEL', 'KEY_EQUALS']);
      expect(result(tester), '2');
    },
  );

  testWidgets(
    'one semantics label describes the argument and its error location',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await boot(tester, math: true);
        await absolute(tester);
        await tap(tester, 'KEY_EQUALS');
        expect(
          find.bySemanticsLabel(
            RegExp('Betrag leeres Feld, Ende Betrag.*Argument des 1. Betrags'),
          ),
          findsOneWidget,
        );
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'empty argument keeps the placeholder and error caret inside bars',
    (tester) async {
      final session = StructuredCalculatorSession()
        ..pressId('ACTION_ABS')
        ..pressId('KEY_EQUALS');
      await view(
        tester,
        session.snapshot.editor,
        errorCursor: session.snapshot.errorCursor,
      );
      expect(keyed('placeholder-root/a0'), findsOneWidget);
      final amount = tester.getRect(keyed('absolute-root/0'));
      final field = tester.getRect(keyed('formula-error-field'));
      final caret = tester.getRect(keyed('formula-error'));
      expect(amount.contains(field.topLeft), isTrue);
      expect(amount.contains(field.bottomRight), isTrue);
      expect(field.contains(caret.topLeft), isTrue);
      expect(field.contains(caret.bottomRight), isTrue);
    },
  );

  testWidgets('amount baseline aligns with an ordinary neighboring number', (
    tester,
  ) async {
    final editor = FractionEditor()
      ..insertAbsolute()
      ..insertText('5')
      ..moveRight()
      ..insertText('+')
      ..insertText('2');
    await view(tester, editor.snapshot, showCursor: false);
    final left = tester.renderObject<RenderBox>(find.text('5'));
    final right = tester.renderObject<RenderBox>(find.text('2'));
    final leftBaseline =
        left.localToGlobal(Offset.zero).dy +
        left.getDistanceToBaseline(TextBaseline.alphabetic)!;
    final rightBaseline =
        right.localToGlobal(Offset.zero).dy +
        right.getDistanceToBaseline(TextBaseline.alphabetic)!;
    expect(leftBaseline, closeTo(rightBaseline, .1));
    expect(keyed('formula-cursor'), findsNothing);
  });

  testWidgets('font size and contrast propagate into a growing argument', (
    tester,
  ) async {
    final editor = FractionEditor()
      ..insertAbsolute()
      ..insertText('5');
    await view(tester, editor.snapshot, fontSize: 16, color: Colors.black);
    final small = tester.getSize(keyed('absolute-root/0'));
    await view(tester, editor.snapshot, fontSize: 32, color: Colors.grey);
    final large = tester.getSize(keyed('absolute-root/0'));
    expect(large.height, greaterThan(small.height));
    expect(large.width, greaterThan(small.width));
    expect(
      DefaultTextStyle.of(tester.element(find.text('5'))).style.color,
      Colors.grey,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('sixteen mixed templates render and reveal their deepest caret', (
    tester,
  ) async {
    final editor = FractionEditor();
    for (var i = 0; i < 16; i++) {
      if (i.isEven) {
        editor.insertAbsolute();
      } else {
        editor.insertFraction();
      }
    }
    await view(tester, editor.snapshot);
    expect(editor.snapshot.cursor.path, hasLength(16));
    expect(keyed('formula-cursor'), findsOneWidget);
    expect(tester.takeException(), isNull);
    final caret = tester.getRect(keyed('formula-cursor'));
    expect(caret.top, greaterThanOrEqualTo(0));
    expect(caret.bottom, lessThanOrEqualTo(300));
  });
}
