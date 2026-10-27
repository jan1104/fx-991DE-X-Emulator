import 'package:calculator_core/calculator_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/presentation/editor/fraction_expression_view.dart';

Finder keyed(String value) => find.byKey(ValueKey(value));

void appendFraction(
  FractionEditor editor,
  String numerator,
  String denominator,
) {
  editor.insertFraction();
  for (final digit in numerator.split('')) {
    editor.insertText(digit);
  }
  editor.moveRight();
  for (final digit in denominator.split('')) {
    editor.insertText(digit);
  }
  editor.moveRight();
}

Future<void> pumpFormula(
  WidgetTester tester,
  FractionEditorSnapshot snapshot, {
  bool showCursor = true,
  double width = 600,
  double height = 400,
  double scale = 1,
  double fontSize = 24,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              height: height,
              child: FractionExpressionView(
                snapshot: snapshot,
                showCursor: showCursor,
                fontSize: fontSize,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void expectCursorIn(String path) {
  expect(keyed('formula-cursor'), findsOneWidget);
  expect(
    find.descendant(
      of: keyed('field-$path'),
      matching: keyed('formula-cursor'),
    ),
    findsOneWidget,
  );
}

void expectFractionGeometry(
  WidgetTester tester, {
  required String numerator,
  required String denominator,
}) {
  final top = tester.getRect(keyed('field-$numerator'));
  final bottom = tester.getRect(keyed('field-$denominator'));
  expect(top.bottom, lessThan(bottom.top));
  expect(top.center.dx, closeTo(bottom.center.dx, 0.01));
}

void main() {
  testWidgets('empty root has a placeholder and exactly one cursor', (
    tester,
  ) async {
    await pumpFormula(tester, FractionEditor().snapshot);
    expect(keyed('field-root'), findsOneWidget);
    expect(keyed('placeholder-root'), findsOneWidget);
    expectCursorIn('root');
    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty fraction renders separate numerator and denominator', (
    tester,
  ) async {
    final editor = FractionEditor()..insertFraction();
    await pumpFormula(tester, editor.snapshot);
    expect(keyed('fraction-root/0'), findsOneWidget);
    expect(keyed('placeholder-root'), findsNothing);
    expect(keyed('placeholder-root/f0n'), findsOneWidget);
    expect(keyed('placeholder-root/f0d'), findsOneWidget);
    expectCursorIn('root/f0n');
    expectFractionGeometry(
      tester,
      numerator: 'root/f0n',
      denominator: 'root/f0d',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'one third plus one sixth is displayed as two natural fractions',
    (tester) async {
      final editor = FractionEditor();
      appendFraction(editor, '1', '3');
      editor.insertText('+');
      appendFraction(editor, '1', '6');
      await pumpFormula(tester, editor.snapshot);
      for (final key in [
        'fraction-root/0',
        'fraction-root/2',
        'field-root/f0n',
        'field-root/f0d',
        'field-root/f2n',
        'field-root/f2d',
      ]) {
        expect(keyed(key), findsOneWidget);
      }
      expect(find.text('1'), findsNWidgets(2));
      expect(find.text('3'), findsOneWidget);
      expect(find.text('+'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expectCursorIn('root');
      expectFractionGeometry(
        tester,
        numerator: 'root/f0n',
        denominator: 'root/f0d',
      );
      expectFractionGeometry(
        tester,
        numerator: 'root/f2n',
        denominator: 'root/f2d',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('draws a horizontal fraction bar between unequal-width fields', (
    tester,
  ) async {
    final editor = FractionEditor();
    appendFraction(editor, '12', '3');
    await pumpFormula(tester, editor.snapshot, showCursor: false);
    final fractionRect = tester.getRect(keyed('fraction-root/0'));
    final numeratorRect = tester.getRect(keyed('field-root/f0n'));
    final denominatorRect = tester.getRect(keyed('field-root/f0d'));
    expect(numeratorRect.width, greaterThan(denominatorRect.width));
    expectFractionGeometry(
      tester,
      numerator: 'root/f0n',
      denominator: 'root/f0d',
    );
    final barY =
        (numeratorRect.bottom + denominatorRect.top) / 2 - fractionRect.top;
    final renderObject = tester.renderObject(keyed('fraction-root/0'));
    expect(
      renderObject,
      paints..line(p1: Offset(0, barY), p2: Offset(fractionRect.width, barY)),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('nested one over two thirds has correctly nested field keys', (
    tester,
  ) async {
    final editor = FractionEditor()..insertFraction();
    editor.insertText('1');
    editor.moveRight();
    appendFraction(editor, '2', '3');
    await pumpFormula(tester, editor.snapshot);
    expect(keyed('fraction-root/0'), findsOneWidget);
    expect(keyed('fraction-root/f0d/0'), findsOneWidget);
    expect(keyed('field-root/f0d/f0n'), findsOneWidget);
    expect(keyed('field-root/f0d/f0d'), findsOneWidget);
    expectCursorIn('root/f0d');
    expect(
      find.descendant(
        of: keyed('field-root/f0d'),
        matching: keyed('fraction-root/f0d/0'),
      ),
      findsOneWidget,
    );
    expectFractionGeometry(
      tester,
      numerator: 'root/f0d/f0n',
      denominator: 'root/f0d/f0d',
    );
    expectFractionGeometry(
      tester,
      numerator: 'root/f0n',
      denominator: 'root/f0d',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('adjacent unequal-height fractions share their main bar axis', (
    tester,
  ) async {
    final editor = FractionEditor()..insertFraction();
    editor.insertText('1');
    editor.moveRight();
    appendFraction(editor, '2', '3');
    editor.moveRight();
    editor.insertText('+');
    appendFraction(editor, '1', '2');
    await pumpFormula(tester, editor.snapshot, showCursor: false);
    final tallNumerator = tester.getRect(keyed('field-root/f0n'));
    final tallDenominator = tester.getRect(keyed('field-root/f0d'));
    final shortNumerator = tester.getRect(keyed('field-root/f2n'));
    final shortDenominator = tester.getRect(keyed('field-root/f2d'));
    final tallBar = (tallNumerator.bottom + tallDenominator.top) / 2;
    final shortBar = (shortNumerator.bottom + shortDenominator.top) / 2;
    expect(tallBar, closeTo(shortBar, 0.01));
    expect(
      tester.getSize(keyed('fraction-root/0')).height,
      greaterThan(tester.getSize(keyed('fraction-root/2')).height),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('new snapshots move the unique cursor through field paths', (
    tester,
  ) async {
    final editor = FractionEditor()..insertFraction();
    await pumpFormula(tester, editor.snapshot);
    expectCursorIn('root/f0n');
    editor.moveRight();
    await pumpFormula(tester, editor.snapshot);
    expectCursorIn('root/f0d');
    editor.insertFraction();
    await pumpFormula(tester, editor.snapshot);
    expectCursorIn('root/f0d/f0n');
    editor.moveRight();
    await pumpFormula(tester, editor.snapshot);
    expectCursorIn('root/f0d/f0d');
    editor.moveRight();
    editor.moveRight();
    await pumpFormula(tester, editor.snapshot);
    expectCursorIn('root');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'showCursor false hides only the cursor, not empty field markers',
    (tester) async {
      final editor = FractionEditor()..insertFraction();
      await pumpFormula(tester, editor.snapshot, showCursor: false);
      expect(keyed('formula-cursor'), findsNothing);
      expect(keyed('placeholder-root/f0n'), findsOneWidget);
      expect(keyed('placeholder-root/f0d'), findsOneWidget);
      await pumpFormula(tester, editor.snapshot);
      expectCursorIn('root/f0n');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'view renders the supplied old snapshot rather than later edits',
    (tester) async {
      final editor = FractionEditor();
      appendFraction(editor, '1', '3');
      final oldSnapshot = editor.snapshot;
      editor.clear();
      appendFraction(editor, '4', '5');
      await pumpFormula(tester, oldSnapshot);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsNothing);
      expect(find.text('5'), findsNothing);
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);
      expectCursorIn('root');
      await pumpFormula(tester, editor.snapshot);
      expect(find.text('1'), findsNothing);
      expect(find.text('3'), findsNothing);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('provides one coherent German formula semantics description', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      final editor = FractionEditor();
      appendFraction(editor, '1', '3');
      editor.insertText('+');
      appendFraction(editor, '1', '6');
      await pumpFormula(tester, editor.snapshot);
      final node = tester.getSemantics(find.byType(FractionExpressionView));
      final label = node.getSemanticsData().label;
      expect(label, contains('Eingabe'));
      expect(label, contains('Bruch'));
      expect(label, contains('Zähler'));
      expect(label, contains('Nenner'));
      expect(label, contains('3'));
      expect(label, contains('6'));
      // Scroll containers may expose their own semantics/actions. Individual
      // digits and fraction fields must not add competing spoken descriptions.
      final spokenDescendants = <String>[];
      void inspectChildren(SemanticsNode parent) {
        parent.visitChildren((child) {
          final data = child.getSemanticsData();
          if (data.label.isNotEmpty) spokenDescendants.add(data.label);
          if (data.value.isNotEmpty) spokenDescendants.add(data.value);
          inspectChildren(child);
          return true;
        });
      }

      inspectChildren(node);
      expect(spokenDescendants, isEmpty);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('long formula scrolls horizontally inside a 320-pixel viewport', (
    tester,
  ) async {
    final editor = FractionEditor();
    for (var index = 0; index < 20; index++) {
      if (index > 0) editor.insertText('+');
      appendFraction(editor, '12', '345');
    }
    await pumpFormula(tester, editor.snapshot, width: 320, height: 180);
    final scroll = tester.widget<SingleChildScrollView>(
      keyed('formula-scroll'),
    );
    expect(scroll.scrollDirection, Axis.horizontal);
    expect(
      tester.getSize(keyed('formula-scroll')).width,
      lessThanOrEqualTo(320),
    );
    final state = tester.state<ScrollableState>(
      find.descendant(
        of: keyed('formula-scroll'),
        matching: find.byType(Scrollable),
      ),
    );
    expect(state.position.maxScrollExtent, greaterThan(0));
    final before = state.position.pixels;
    final firstBefore = tester.getTopLeft(keyed('fraction-root/0'));
    await tester.drag(keyed('formula-scroll'), const Offset(-240, 0));
    await tester.pumpAndSettle();
    expect(state.position.pixels, greaterThan(before));
    expect(
      tester.getTopLeft(keyed('fraction-root/0')).dx,
      lessThan(firstBefore.dx),
    );
    expect(keyed('formula-cursor'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TextScaler two enlarges fields and the caret without overflow', (
    tester,
  ) async {
    final editor = FractionEditor()..insertFraction();
    editor.insertText('1');
    editor.moveRight();
    editor.insertText('3');
    await pumpFormula(tester, editor.snapshot, width: 320, height: 300);
    final normalFraction = tester.getSize(keyed('fraction-root/0'));
    final normalCaret = tester.getSize(keyed('formula-cursor'));
    await pumpFormula(
      tester,
      editor.snapshot,
      width: 320,
      height: 300,
      scale: 2,
    );
    final enlargedFraction = tester.getSize(keyed('fraction-root/0'));
    final enlargedCaret = tester.getSize(keyed('formula-cursor'));
    expect(enlargedFraction.height, greaterThan(normalFraction.height));
    expect(enlargedFraction.width, greaterThan(normalFraction.width));
    expect(enlargedCaret.height, greaterThan(normalCaret.height));
    expectCursorIn('root/f0d');
    expectFractionGeometry(
      tester,
      numerator: 'root/f0n',
      denominator: 'root/f0d',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('sixteen nested fractions lay out in a bounded narrow viewport', (
    tester,
  ) async {
    final editor = FractionEditor();
    for (var depth = 0; depth < 16; depth++) {
      editor.insertFraction();
    }
    editor.insertText('1');
    await pumpFormula(
      tester,
      editor.snapshot,
      width: 320,
      height: 240,
      scale: 2,
    );
    var path = 'root';
    for (var depth = 0; depth < 16; depth++) {
      expect(keyed('fraction-$path/0'), findsOneWidget);
      expect(keyed('field-$path/f0n'), findsOneWidget);
      expect(keyed('placeholder-$path/f0d'), findsOneWidget);
      path += '/f0n';
    }
    expectCursorIn(path);
    final contentSize = tester.getSize(keyed('field-root'));
    expect(contentSize.width.isFinite, isTrue);
    expect(contentSize.height.isFinite, isTrue);
    expect(tester.takeException(), isNull);
  });
}
