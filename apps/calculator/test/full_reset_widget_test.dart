import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'memory_dialog_widget_test.dart' show boot, displayText, keyed, tapKeys;

void main() {
  testWidgets('full reset cancels and confirms at 320 px', (tester) async {
    await boot(tester, math: true);
    await tapKeys(tester, ['KEY_8', 'KEY_EQUALS', 'input-linear']);
    await tapKeys(tester, ['KEY_7', 'KEY_STO', 'KEY_M_PLUS', 'KEY_4']);

    await tapKeys(tester, ['KEY_SHIFT', 'KEY_9', 'KEY_3']);
    expect(displayText(tester, 'menu-title'), 'Alles initialisieren?');
    final prompt = displayText(tester, 'full-reset-prompt');
    expect(prompt, contains('Standardwerte'));
    expect(prompt, contains('Ans, M und beide Eingaben'));
    expect(prompt, contains('Der Kontrast bleibt erhalten.'));
    expect(keyed('menu-page-down'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(keyed('calculator-menu'), findsNothing);
    expect(displayText(tester, 'display-expression'), '4│');
    expect(displayText(tester, 'display-answer'), 'Ans: 7');

    await tapKeys(tester, [
      'KEY_SHIFT',
      'KEY_9',
      'KEY_3',
      'full-reset-confirm',
    ]);
    expect(keyed('calculator-menu'), findsNothing);
    expect(keyed('display-structured'), findsOneWidget);
    expect(keyed('placeholder-root'), findsOneWidget);
    expect(displayText(tester, 'display-result'), isEmpty);
    expect(displayText(tester, 'display-answer'), 'Ans: 0');
    expect(
      displayText(tester, 'display-status').split(RegExp(r'\s+')),
      isNot(contains('M')),
    );

    await tapKeys(tester, ['input-linear']);
    expect(displayText(tester, 'display-expression'), '│');
    expect(displayText(tester, 'display-result'), isEmpty);
    expect(tester.takeException(), isNull);
  });
}
