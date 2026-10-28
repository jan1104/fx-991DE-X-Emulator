import 'package:calculator_core/calculator_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fx991_calculator/main.dart';
import 'package:fx991_calculator/presentation/editor/fraction_expression_view.dart';

// Structural error recovery is a prototype contract, not an observation of the
// original Casio calculator. Parser text offsets must not become field offsets.
Finder keyed(String id) => find.byKey(ValueKey(id));

FractionExpressionView formula(WidgetTester tester) =>
    tester.widget<FractionExpressionView>(find.byType(FractionExpressionView));

String result(WidgetTester tester) =>
    tester.widget<Text>(keyed('display-result')).data!;

List<(int, FractionField)> pathOf(EditorCursor cursor) => [
  for (final step in cursor.path) (step.nodeIndex, step.field),
];

Future<void> pumpCalculator(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 1000);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const CalculatorApp());
  await tester.pumpAndSettle();
  await tap(tester, 'input-fractions');
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

void expectErrorMarker(
  WidgetTester tester, {
  required String field,
  required int offset,
  required List<(int, FractionField)> path,
}) {
  final view = formula(tester);
  expect(view.showCursor, isFalse);
  expect(view.errorCursor, isNotNull);
  expect(pathOf(view.errorCursor!), path);
  expect(view.errorCursor!.offset, offset);
  expect(keyed('formula-error'), findsOneWidget);
  expect(keyed('formula-error-field'), findsOneWidget);
  expect(keyed('formula-cursor'), findsNothing);
  expect(
    find.descendant(
      of: keyed('field-$field'),
      matching: keyed('formula-error'),
    ),
    findsOneWidget,
  );
  expect(
    find.ancestor(
      of: keyed('field-$field'),
      matching: keyed('formula-error-field'),
    ),
    findsOneWidget,
  );
  final color = tester
      .widget<ColoredBox>(
        find.descendant(
          of: keyed('formula-error'),
          matching: find.byType(ColoredBox),
        ),
      )
      .color;
  expect(color.r, greaterThan(color.g));
  expect(color.r, greaterThan(color.b));
  final help = tester.widget<Text>(keyed('display-error-help'));
  expect(help.data ?? help.textSpan!.toPlainText(), contains('Links/Rechts'));
}

void expectEditingCursor(
  WidgetTester tester, {
  required int offset,
  required List<(int, FractionField)> path,
}) {
  final view = formula(tester);
  expect(view.errorCursor, isNull);
  expect(view.showCursor, isTrue);
  expect(view.snapshot.cursor.offset, offset);
  expect(pathOf(view.snapshot.cursor), path);
  expect(keyed('formula-cursor'), findsOneWidget);
  expect(keyed('formula-error'), findsNothing);
  expect(keyed('formula-error-field'), findsNothing);
  expect(keyed('display-error-help'), findsNothing);
}

void expectMarkerInsideDisplay(WidgetTester tester) {
  final display = tester.getRect(keyed('display-structured'));
  final marker = tester.getRect(keyed('formula-error'));
  expect(marker.left, greaterThanOrEqualTo(display.left - 0.01));
  expect(marker.right, lessThanOrEqualTo(display.right + 0.01));
  expect(marker.top, greaterThanOrEqualTo(display.top - 0.01));
  expect(marker.bottom, lessThanOrEqualTo(display.bottom + 0.01));
}

ScrollableState displayScroll(WidgetTester tester, AxisDirection direction) =>
    tester
        .stateList<ScrollableState>(
          find.descendant(
            of: keyed('display-structured'),
            matching: find.byType(Scrollable),
          ),
        )
        .singleWhere((state) => state.position.axisDirection == direction);

void main() {
  testWidgets('spoken error identifies the second neighboring fraction', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpCalculator(tester);
      await taps(tester, [
        'KEY_FRACTION',
        'KEY_1',
        'KEY_RIGHT',
        'KEY_2',
        'KEY_RIGHT',
        'KEY_ADD',
        'KEY_FRACTION',
        'KEY_1',
        'KEY_RIGHT',
        'KEY_0',
        'KEY_EQUALS',
      ]);
      final label = tester
          .getSemantics(find.byType(FractionExpressionView))
          .getSemanticsData()
          .label;
      expect(label, contains('Fehlerstelle im Nenner des 2. Bruchs'));
      expectErrorMarker(
        tester,
        field: 'root/f2d',
        offset: 1,
        path: [(2, FractionField.denominator)],
      );
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });
  testWidgets(
    'empty nested denominator is marked while saved cursor stays at root',
    (tester) async {
      await pumpCalculator(tester);
      await taps(tester, [
        'KEY_FRACTION',
        'KEY_1',
        'KEY_RIGHT',
        'KEY_FRACTION',
        'KEY_2',
        'KEY_RIGHT',
        'KEY_RIGHT',
        'KEY_RIGHT',
      ]);
      expectEditingCursor(tester, offset: 1, path: []);
      await tap(tester, 'KEY_EQUALS');
      expect(result(tester), 'Syntaxfehler');
      expect(pathOf(formula(tester).snapshot.cursor), isEmpty);
      expect(formula(tester).snapshot.cursor.offset, 1);
      expectErrorMarker(
        tester,
        field: 'root/f0d/f0d',
        offset: 0,
        path: [(0, FractionField.denominator), (0, FractionField.denominator)],
      );
      await tap(tester, 'KEY_LEFT');
      expectEditingCursor(
        tester,
        offset: 0,
        path: [(0, FractionField.denominator), (0, FractionField.denominator)],
      );
      await taps(tester, ['KEY_3', 'KEY_EQUALS']);
      expect(result(tester), '3/2');
      expect(keyed('formula-error'), findsNothing);
      expect(keyed('formula-error-field'), findsNothing);
      expect(keyed('display-error-help'), findsNothing);
      expect(keyed('formula-cursor'), findsNothing);
    },
  );

  for (final navigation in ['KEY_LEFT', 'KEY_RIGHT']) {
    testWidgets('trailing numerator plus focuses its end with $navigation', (
      tester,
    ) async {
      await pumpCalculator(tester);
      await taps(tester, [
        'KEY_FRACTION',
        'KEY_1',
        'KEY_ADD',
        'KEY_RIGHT',
        'KEY_2',
        'KEY_EQUALS',
      ]);
      expect(result(tester), 'Syntaxfehler');
      expect(pathOf(formula(tester).snapshot.cursor), [
        (0, FractionField.denominator),
      ]);
      expect(formula(tester).snapshot.cursor.offset, 1);
      expectErrorMarker(
        tester,
        field: 'root/f0n',
        offset: 2,
        path: [(0, FractionField.numerator)],
      );
      await tap(tester, navigation);
      // Neither navigation direction adds another move on first recovery.
      expectEditingCursor(
        tester,
        offset: 2,
        path: [(0, FractionField.numerator)],
      );
      await taps(tester, ['KEY_DEL', 'KEY_EQUALS']);
      expect(result(tester), '1/2');
      expect(keyed('formula-error'), findsNothing);
      expect(keyed('display-error-help'), findsNothing);
    });
  }

  testWidgets('unmatched closing parenthesis targets its token start', (
    tester,
  ) async {
    await pumpCalculator(tester);
    await taps(tester, [
      'KEY_FRACTION',
      'KEY_1',
      'KEY_RPAREN',
      'KEY_RIGHT',
      'KEY_2',
      'KEY_EQUALS',
    ]);
    expectErrorMarker(
      tester,
      field: 'root/f0n',
      offset: 1,
      path: [(0, FractionField.numerator)],
    );
    await tap(tester, 'KEY_RIGHT');
    expectEditingCursor(
      tester,
      offset: 1,
      path: [(0, FractionField.numerator)],
    );
    await taps(tester, ['KEY_RIGHT', 'KEY_DEL', 'KEY_EQUALS']);
    expect(result(tester), '1/2');
    expect(keyed('formula-error'), findsNothing);
    expect(keyed('display-error-help'), findsNothing);
  });

  testWidgets(
    'synthetic division points to denominator end even from root cursor',
    (tester) async {
      await pumpCalculator(tester);
      await taps(tester, [
        'KEY_FRACTION',
        'KEY_1',
        'KEY_RIGHT',
        'KEY_0',
        'KEY_RIGHT',
        'KEY_EQUALS',
      ]);
      expect(result(tester), 'Mathem. Fehler');
      expect(pathOf(formula(tester).snapshot.cursor), isEmpty);
      expectErrorMarker(
        tester,
        field: 'root/f0d',
        offset: 1,
        path: [(0, FractionField.denominator)],
      );
      await tap(tester, 'KEY_LEFT');
      expectEditingCursor(
        tester,
        offset: 1,
        path: [(0, FractionField.denominator)],
      );
      await taps(tester, ['KEY_DEL', 'KEY_2', 'KEY_EQUALS']);
      expect(result(tester), '1/2');
    },
  );

  testWidgets(
    'error marker and help follow the active draft across mode switches',
    (tester) async {
      await pumpCalculator(tester);
      await taps(tester, [
        'KEY_7',
        'KEY_EQUALS',
        'KEY_FRACTION',
        'KEY_1',
        'KEY_EQUALS',
      ]);
      expectErrorMarker(
        tester,
        field: 'root/f0d',
        offset: 0,
        path: [(0, FractionField.denominator)],
      );
      await tap(tester, 'input-linear');
      expect(keyed('formula-error'), findsNothing);
      expect(keyed('formula-error-field'), findsNothing);
      expect(keyed('display-error-help'), findsNothing);
      await taps(tester, ['KEY_4', 'KEY_EQUALS']);
      expect(result(tester), '4');
      await tap(tester, 'input-fractions');
      expect(result(tester), 'Syntaxfehler');
      expectErrorMarker(
        tester,
        field: 'root/f0d',
        offset: 0,
        path: [(0, FractionField.denominator)],
      );
      await tap(tester, 'KEY_AC');
      expectEditingCursor(tester, offset: 0, path: []);
      expect(result(tester), '');
      expect(tester.widget<Text>(keyed('display-answer')).data, 'Ans: 7');
      expect(keyed('placeholder-root'), findsOneWidget);
    },
  );

  testWidgets(
    'accessible description announces the structural error location',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await pumpCalculator(tester);
        await taps(tester, [
          'KEY_FRACTION',
          'KEY_1',
          'KEY_RIGHT',
          'KEY_0',
          'KEY_EQUALS',
        ]);
        var label = tester
            .getSemantics(find.byType(FractionExpressionView))
            .getSemanticsData()
            .label;
        expect(label, contains('Fehlerstelle'));
        expect(label, contains('Nenner'));
        await tap(tester, 'KEY_LEFT');
        label = tester
            .getSemantics(find.byType(FractionExpressionView))
            .getSemanticsData()
            .label;
        expect(label, isNot(contains('Fehlerstelle')));
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'offscreen root error scrolls back horizontally without page movement',
    (tester) async {
      await pumpCalculator(tester);
      await tap(tester, 'KEY_RPAREN');
      final page = tester.state<ScrollableState>(
        find.ancestor(
          of: keyed('calculator-display'),
          matching: find.byType(Scrollable),
        ),
      );
      final pageOffset = page.position.pixels;
      for (var index = 0; index < 80; index++) {
        await hardwareKey(tester, LogicalKeyboardKey.digit1, character: '1');
      }
      await tester.pumpAndSettle();
      final horizontal = displayScroll(tester, AxisDirection.right);
      final beforeError = horizontal.position.pixels;
      expect(beforeError, greaterThan(0));
      await hardwareKey(tester, LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(result(tester), 'Syntaxfehler');
      expectErrorMarker(tester, field: 'root', offset: 0, path: []);
      expectMarkerInsideDisplay(tester);
      // The error-field border adds horizontal padding. Visibility and a move
      // back toward the start matter, not an arbitrary exact scroll offset.
      expect(horizontal.position.pixels, lessThan(beforeError));
      expect(page.position.pixels, pageOffset);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'deep empty field error follows vertically and navigation opens it',
    (tester) async {
      await pumpCalculator(tester);
      for (var depth = 0; depth < 8; depth++) {
        await taps(tester, ['KEY_FRACTION', 'KEY_1', 'KEY_RIGHT']);
      }
      for (var depth = 0; depth < 8; depth++) {
        await hardwareKey(tester, LogicalKeyboardKey.arrowRight);
      }
      await tester.pumpAndSettle();
      expectEditingCursor(tester, offset: 1, path: []);
      final vertical = displayScroll(tester, AxisDirection.down);
      final beforeError = vertical.position.pixels;
      final page = tester.state<ScrollableState>(
        find.ancestor(
          of: keyed('calculator-display'),
          matching: find.byType(Scrollable),
        ),
      );
      final pageOffset = page.position.pixels;
      await hardwareKey(tester, LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      final errorPath = List.generate(8, (_) => (0, FractionField.denominator));
      final field = 'root${'/f0d' * 8}';
      expectErrorMarker(tester, field: field, offset: 0, path: errorPath);
      expectMarkerInsideDisplay(tester);
      expect(vertical.position.pixels, greaterThan(beforeError));
      expect(page.position.pixels, pageOffset);
      await hardwareKey(tester, LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expectEditingCursor(tester, offset: 0, path: errorPath);
      expect(tester.takeException(), isNull);
    },
  );
}
