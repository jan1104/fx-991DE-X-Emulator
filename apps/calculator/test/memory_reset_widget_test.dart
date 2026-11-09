import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'memory_dialog_widget_test.dart' show boot, displayText, keyed, tapKeys;

bool hasMemoryIndicator(WidgetTester tester) =>
    displayText(tester, 'display-status').split(RegExp(r'\s+')).contains('M');

void main() {
  testWidgets('Escape cancels and Enter confirms reset of M and Ans', (
    tester,
  ) async {
    await boot(tester);
    await tapKeys(tester, ['KEY_7', 'KEY_STO', 'KEY_M_PLUS', 'KEY_4']);
    await tapKeys(tester, ['KEY_SHIFT', 'KEY_9', 'KEY_2']);
    expect(displayText(tester, 'menu-title'), 'Speicher löschen?');
    expect(displayText(tester, 'memory-reset-prompt'), contains('Ans und M'));
    expect(keyed('menu-page-down'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(keyed('calculator-menu'), findsNothing);
    expect(displayText(tester, 'display-expression'), '4│');
    expect(displayText(tester, 'display-answer'), 'Ans: 7');
    expect(hasMemoryIndicator(tester), isTrue);

    await tapKeys(tester, ['KEY_SHIFT', 'KEY_9', 'KEY_2']);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(keyed('calculator-menu'), findsNothing);
    expect(displayText(tester, 'display-expression'), '4│');
    expect(displayText(tester, 'display-answer'), 'Ans: 0');
    expect(hasMemoryIndicator(tester), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('touch confirmation resets memory and retains the Math result', (
    tester,
  ) async {
    await boot(tester, math: true);
    await tapKeys(tester, [
      'KEY_7',
      'KEY_STO',
      'KEY_M_PLUS',
      'KEY_SHIFT',
      'KEY_9',
    ]);
    expect(displayText(tester, 'menu-title'), 'RESET');
    await tapKeys(tester, ['setup-item-reset-memory', 'memory-reset-confirm']);
    expect(keyed('calculator-menu'), findsNothing);
    expect(displayText(tester, 'display-result'), '7');
    expect(displayText(tester, 'display-answer'), 'Ans: 0');
    expect(hasMemoryIndicator(tester), isFalse);
    expect(tester.takeException(), isNull);
  });
}
