import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fx991_calculator/main.dart';

Finder keyed(String id) => find.byKey(ValueKey(id));

Future<void> tapKeys(WidgetTester tester, List<String> ids) async {
  for (final id in ids) {
    final key = keyed(id);
    await tester.ensureVisible(key);
    await tester.pumpAndSettle();
    await tester.tap(key);
    await tester.pumpAndSettle();
  }
}

Future<void> boot(WidgetTester tester, {bool math = false}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(320, 568);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(const CalculatorApp());
  await tester.pumpAndSettle();
  await tapKeys(tester, [math ? 'input-fractions' : 'input-linear']);
}

String displayText(WidgetTester tester, String id) {
  final text = tester.widget<Text>(keyed(id));
  return text.data ?? text.textSpan!.toPlainText();
}

void main() {
  testWidgets('STO preserves the draft on AC and stores it on M+', (
    tester,
  ) async {
    await boot(tester);
    await tapKeys(tester, ['KEY_3', 'KEY_ADD', 'KEY_5', 'KEY_LEFT', 'KEY_STO']);
    expect(keyed('display-store-prompt'), findsOneWidget);
    expect(displayText(tester, 'display-status'), contains('STO'));
    expect(displayText(tester, 'display-expression'), '3+5');
    expect(displayText(tester, 'display-answer'), 'Ans: 0');
    await tapKeys(tester, ['KEY_AC']);
    expect(keyed('display-store-prompt'), findsNothing);
    expect(displayText(tester, 'display-expression'), '3+│5');
    await tapKeys(tester, ['KEY_STO', 'KEY_M_PLUS']);
    expect(keyed('display-store-prompt'), findsNothing);
    expect(displayText(tester, 'display-result'), '8');
    expect(displayText(tester, 'display-answer'), 'Ans: 8');
    expect(
      displayText(tester, 'display-status').split(RegExp(r'\s+')),
      contains('M'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Math STO blocks fraction capture while an assignment is ready', (
    tester,
  ) async {
    await boot(tester, math: true);
    await tapKeys(tester, ['KEY_3']);
    final capture = keyed('action-wrap-fraction');
    expect(tester.widget<TextButton>(capture).onPressed, isNotNull);
    await tapKeys(tester, ['KEY_STO']);
    expect(tester.widget<TextButton>(capture).onPressed, isNull);
    await tapKeys(tester, ['KEY_AC']);
    expect(tester.widget<TextButton>(capture).onPressed, isNotNull);
    await tapKeys(tester, ['KEY_STO', 'KEY_M_PLUS']);
    expect(displayText(tester, 'display-result'), '3');
    expect(tester.takeException(), isNull);
  });

  testWidgets('RECALL requires a selection and Escape restores the draft', (
    tester,
  ) async {
    await boot(tester);
    await tapKeys(tester, [
      'KEY_1',
      'KEY_DIVIDE',
      'KEY_3',
      'KEY_STO',
      'KEY_M_PLUS',
      'KEY_4',
      'KEY_ADD',
      'KEY_5',
      'KEY_SHIFT',
      'KEY_STO',
    ]);
    expect(keyed('display-recall'), findsOneWidget);
    expect(displayText(tester, 'display-recall-value'), '0,3333333333');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(keyed('display-recall'), findsOneWidget);
    await tapKeys(tester, ['display-recall-select']);
    expect(
      displayText(tester, 'display-recall-prompt'),
      startsWith('= ruft ab'),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(keyed('display-recall'), findsNothing);
    expect(displayText(tester, 'display-expression'), '4+5│');
    expect(tester.takeException(), isNull);
  });

  testWidgets('RECALL on a narrow display loads exact M after Enter', (
    tester,
  ) async {
    await boot(tester);
    await tapKeys(tester, [
      'KEY_1',
      'KEY_DIVIDE',
      'KEY_3',
      'KEY_STO',
      'KEY_M_PLUS',
      'KEY_9',
      'KEY_EQUALS',
      'KEY_SHIFT',
      'KEY_STO',
      'KEY_M_PLUS',
    ]);
    expect(keyed('display-recall'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(keyed('display-recall'), findsNothing);
    expect(displayText(tester, 'display-expression'), 'M');
    expect(displayText(tester, 'display-result'), '1/3');
    expect(displayText(tester, 'display-answer'), 'Ans: 1/3');
    expect(tester.takeException(), isNull);
  });
}
