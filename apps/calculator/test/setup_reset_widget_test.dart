import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'memory_dialog_widget_test.dart' show boot, displayText, keyed, tapKeys;

void main() {
  testWidgets('setup reset confirms defaults and retains Ans and M at 320 px', (
    tester,
  ) async {
    await boot(tester);
    await tapKeys(tester, ['KEY_7', 'KEY_STO', 'KEY_M_PLUS']);
    expect(keyed('display-expression'), findsOneWidget);

    await tapKeys(tester, ['KEY_SHIFT', 'KEY_9', 'KEY_1']);
    expect(displayText(tester, 'menu-title'), 'Setupdaten zurücksetzen?');
    expect(
      displayText(tester, 'setup-reset-prompt'),
      contains('Standardwerte'),
    );
    expect(
      displayText(tester, 'setup-reset-prompt'),
      contains('Kontrast, Ans und M'),
    );
    expect(keyed('menu-page-down'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(keyed('calculator-menu'), findsNothing);
    expect(keyed('display-expression'), findsOneWidget);
    expect(displayText(tester, 'display-answer'), 'Ans: 7');

    await tapKeys(tester, [
      'KEY_SHIFT',
      'KEY_9',
      'KEY_1',
      'setup-reset-confirm',
    ]);
    expect(keyed('calculator-menu'), findsNothing);
    expect(keyed('display-structured'), findsOneWidget);
    expect(keyed('display-expression'), findsNothing);
    expect(displayText(tester, 'display-answer'), 'Ans: 7');
    expect(
      displayText(tester, 'display-status').split(RegExp(r'\s+')),
      contains('M'),
    );
    expect(tester.takeException(), isNull);
  });
}
