// Prepared widget regressions. Execution remains blocked by Windows policy;
// these cases are not an original-device comparison.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fx991_calculator/application/key_layout.dart';
import 'package:fx991_calculator/main.dart';
import 'package:fx991_calculator/presentation/editor/fraction_expression_view.dart';

Finder keyed(String id) => find.byKey(ValueKey(id));

Future<void> boot(
  WidgetTester tester, {
  Size size = const Size(800, 1000),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(const CalculatorApp());
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, String id) async {
  await tester.ensureVisible(keyed(id));
  await tester.pumpAndSettle();
  await tester.tap(keyed(id));
  await tester.pumpAndSettle();
}

Future<void> sequence(WidgetTester tester, List<String> ids) async {
  for (final id in ids) {
    await tap(tester, id);
  }
}

String text(WidgetTester tester, String id) =>
    tester.widget<Text>(keyed(id)).data!;

List<String> visibleMenuLabels(WidgetTester tester) => tester
    .widgetList<TextButton>(
      find.descendant(
        of: keyed('calculator-menu'),
        matching: find.byType(TextButton),
      ),
    )
    .map((button) => (button.key! as ValueKey<String>).value)
    .toList();

void main() {
  testWidgets('contrast changes the natural formula ink without changing Ans', (
    tester,
  ) async {
    await boot(tester);
    await sequence(tester, ['KEY_1', 'KEY_EQUALS']);
    Color formulaInk() =>
        Theme.of(tester.element(find.byType(FractionExpressionView)))
            .colorScheme
            .onSurface;
    final before = formulaInk();
    await tap(tester, 'toolbar-settings');
    for (var step = 0; step < 16; step++) {
      await tap(tester, 'menu-page-down');
    }
    await tap(tester, 'setup-item-contrast');
    await tap(tester, 'KEY_RIGHT');
    await tap(tester, 'menu-close');
    expect(formulaInk(), isNot(before));
    expect(text(tester, 'display-answer'), 'Ans: 1');
    expect(text(tester, 'display-result'), '1');
  });

  testWidgets('toolbar reveals settings after scrolling to the bottom keys', (
    tester,
  ) async {
    await boot(tester, size: const Size(320, 568));
    await tester.ensureVisible(keyed('KEY_EQUALS'));
    await tester.pumpAndSettle();
    await tap(tester, 'toolbar-settings');
    expect(keyed('menu-title').hitTestable(), findsOneWidget);
    expect(keyed('setup-item-io').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'drawn front retains all fifty physical keys and grouped directions',
    (tester) async {
      await boot(tester);
      expect(keyed('calculator-shell'), findsOneWidget);
      expect(keyed('solar-panel'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      final definitions = calculatorRows.expand((row) => row).toList();
      expect(definitions.length, 50);
      for (final definition in definitions) {
        expect(keyed(definition.id), findsOneWidget);
      }
      for (final id in ['KEY_UP', 'KEY_DOWN', 'KEY_LEFT', 'KEY_RIGHT']) {
        expect(
          find.descendant(of: keyed('direction-pad'), matching: keyed(id)),
          findsOneWidget,
        );
      }
      final buttons = tester.widgetList<FilledButton>(
        find.byType(FilledButton),
      );
      expect(buttons.length, 50);
      expect(buttons.where((button) => button.onPressed != null).length, 35);
      expect(tester.widget<FilledButton>(keyed('KEY_ALPHA')).onPressed, isNull);
    },
  );

  testWidgets('toolbar and SHIFT MENU open exactly the same LCD menu', (
    tester,
  ) async {
    await boot(tester);
    await tap(tester, 'toolbar-settings');
    final toolbarItems = visibleMenuLabels(tester);
    expect(text(tester, 'menu-title'), 'Einstellungen');
    expect(toolbarItems.length, 4);
    await tap(tester, 'menu-close');
    await sequence(tester, ['KEY_SHIFT', 'KEY_MENU']);
    expect(text(tester, 'menu-title'), 'Einstellungen');
    expect(visibleMenuLabels(tester), toolbarItems);
    expect(text(tester, 'display-status'), isNot(contains('SHIFT')));
  });

  testWidgets(
    'touch setup input choice updates the same state as the input segments',
    (tester) async {
      await boot(tester);
      await tap(tester, 'toolbar-settings');
      await tap(tester, 'setup-item-io');
      await tap(tester, 'setup-item-linearLinear');
      await tap(tester, 'menu-close');
      expect(keyed('display-expression'), findsOneWidget);
      expect(keyed('display-structured'), findsNothing);
      expect(
        tester
            .widgetList<FilledButton>(find.byType(FilledButton))
            .where((button) => button.onPressed != null)
            .length,
        32,
      );
      await tap(tester, 'input-fractions');
      await tap(tester, 'toolbar-settings');
      await tap(tester, 'setup-item-io');
      expect(
        find.descendant(
          of: keyed('setup-item-mathMath'),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'all setup pages are reachable without presenting pending modes as implemented',
    (tester) async {
      await boot(tester);
      await tap(tester, 'toolbar-settings');
      final visited = <String>{};
      for (var step = 0; step < 17; step++) {
        visited.addAll(visibleMenuLabels(tester));
        await tap(tester, 'menu-page-down');
      }
      expect(visited.length, 17);
      expect(
        visited,
        containsAll([
          'setup-item-io',
          'setup-item-contrast',
          'setup-item-qr',
          'setup-item-off',
          'setup-item-period',
        ]),
      );
      await tap(tester, 'menu-close');
      await tap(tester, 'KEY_MENU');
      expect(find.text('Für diesen Modus noch in Vorbereitung'), findsWidgets);
      await tap(tester, 'setup-item-Komplexe Zahlen');
      expect(keyed('calculator-menu'), findsNothing);
      expect(
        text(tester, 'display-notice'),
        'Für diesen Modus noch in Vorbereitung',
      );
      expect(find.text('Berechnungen · Brüche'), findsOneWidget);
    },
  );

  testWidgets('draft and Ans survive opening and closing settings', (
    tester,
  ) async {
    await boot(tester);
    await sequence(tester, ['KEY_1', 'KEY_ADD', 'KEY_2', 'KEY_EQUALS']);
    expect(text(tester, 'display-result'), '3');
    await tap(tester, 'toolbar-settings');
    await tap(tester, 'setup-item-angle');
    await tap(tester, 'menu-back');
    await tap(tester, 'menu-close');
    expect(text(tester, 'display-result'), '3');
    expect(text(tester, 'display-answer'), 'Ans: 3');
    await sequence(tester, ['KEY_ADD', 'KEY_4', 'KEY_EQUALS']);
    expect(text(tester, 'display-result'), '7');
  });

  testWidgets(
    'hardware navigation and Enter operate the same menu and consume repeats',
    (tester) async {
      await boot(tester);
      await tap(tester, 'toolbar-settings');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(text(tester, 'menu-title'), 'Winkeleinheit');
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(text(tester, 'menu-title'), 'Winkeleinheit');
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
    },
  );

  testWidgets('OFF blanks only LCD and ON remains available', (tester) async {
    await boot(tester);
    await sequence(tester, ['KEY_SHIFT', 'KEY_AC']);
    expect(keyed('calculator-display'), findsOneWidget);
    expect(keyed('display-status'), findsNothing);
    expect(
      tester
          .widgetList<FilledButton>(find.byType(FilledButton))
          .where((button) => button.onPressed != null)
          .length,
      1,
    );
    await tap(tester, 'KEY_ON');
    expect(keyed('display-status'), findsOneWidget);
    await sequence(tester, ['KEY_4', 'KEY_DIVIDE', 'KEY_2', 'KEY_EQUALS']);
    expect(text(tester, 'display-result'), '2');
  });

  for (final size in [const Size(320, 568), const Size(800, 600)]) {
    testWidgets('all physical targets stay at least 44 pixels at $size', (
      tester,
    ) async {
      await boot(tester, size: size);
      for (final definition in calculatorRows.expand((row) => row)) {
        final bounds = tester.getSize(keyed(definition.id));
        expect(bounds.width, greaterThanOrEqualTo(44), reason: definition.id);
        expect(bounds.height, greaterThanOrEqualTo(44), reason: definition.id);
      }
      await sequence(tester, ['KEY_1', 'KEY_ADD', 'KEY_2', 'KEY_EQUALS']);
      expect(text(tester, 'display-result'), '3');
      await tap(tester, 'toolbar-settings');
      await tap(tester, 'setup-item-io');
      expect(tester.takeException(), isNull);
    });
  }
}
