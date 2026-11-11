import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fx991_calculator/application/calculator_controller.dart';

import 'calculator_controller_test.dart' show setting;
import 'calculator_skin_test.dart' show boot, keyed, sequence, tap, text;

Future<void> choose(
  WidgetTester tester,
  String page,
  String current,
  String label,
) async {
  await tap(tester, 'setting-$page-$current');
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  test('GUI choices and calculator menu share every setup option', () {
    final c = CalculatorController();
    expect(c.setupSections.length, 17);
    for (final section in c.setupSections) {
      if (section.id == 'contrast' || section.id == 'number') continue;
      for (final option in c.setupOptions(section.id)) {
        c.selectSetupOption(section.id, option.id);
        expect(
          c.setupOptions(section.id).singleWhere((item) => item.selected).id,
          option.id,
        );
        setting(c, [section.id, option.id]);
        expect(
          c.setupOptions(section.id).singleWhere((item) => item.selected).id,
          option.id,
        );
      }
    }
    c.selectSetupOption('number', 'fix');
    c.selectSetupOption('fix', '7');
    expect(c.settings.fixDigits, 7);
    c.selectSetupOption('number', 'norm');
    c.selectSetupOption('number', 'fix');
    expect(c.settings.fixDigits, 7);
    c.setContrast(8);
    expect(c.settings.contrast, 8);
    expect(() => c.setContrast(11), throwsRangeError);
    expect(
      () => c.selectSetupOption('reset', 'reset-all'),
      throwsArgumentError,
    );
  });

  testWidgets('GUI and physical setup synchronize and preserve results', (
    tester,
  ) async {
    await boot(tester);
    await sequence(tester, [
      'KEY_1',
      'KEY_DIVIDE',
      'KEY_3',
      'KEY_SHIFT',
      'KEY_EQUALS',
    ]);
    await tap(tester, 'toolbar-settings');
    await choose(tester, 'number', 'norm', 'FIX');
    await choose(tester, 'fix', '3', '2');
    await tap(tester, 'settings-close');
    expect(text(tester, 'display-result'), '0,33');
    await sequence(tester, ['KEY_SHIFT', 'KEY_MENU']);
    await tap(tester, 'setup-item-number');
    await tap(tester, 'setup-item-fix');
    expect(
      find.descendant(
        of: keyed('setup-item-2'),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
    for (var i = 0; i < 4; i++) {
      await tap(tester, 'menu-page-down');
    }
    await tap(tester, 'setup-item-4');
    await tap(tester, 'menu-close');
    await tap(tester, 'toolbar-settings');
    expect(keyed('setting-fix-4'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(keyed('settings-dialog'), findsNothing);
    expect(text(tester, 'display-result'), '0,3333');
    await sequence(tester, ['KEY_AC', 'KEY_2', 'KEY_SHIFT', 'KEY_EQUALS']);
    expect(text(tester, 'display-result'), '2,0000');
  });

  for (final size in [const Size(320, 568), const Size(1000, 700)]) {
    testWidgets('settings explain options and scroll at $size', (tester) async {
      await boot(tester, size: size);
      await tap(tester, 'toolbar-settings');
      await choose(tester, 'io', 'mathMath', 'Lin. → Linear');
      await tap(tester, 'settings-pending');
      await choose(tester, 'angle', 'degrees', 'Bogenmaß R');
      expect(
        find.text('Vorgabe gespeichert · Funktion noch in Vorbereitung'),
        findsWidgets,
      );
      await tester.ensureVisible(keyed('settings-contrast'));
      await tester.pumpAndSettle();
      final slider = tester.getRect(keyed('settings-contrast'));
      await tester.tapAt(Offset(slider.right - 24, slider.center.dy));
      await tester.pumpAndSettle();
      expect(tester.widget<Slider>(keyed('settings-contrast')).value, isNot(5));
      await tap(tester, 'settings-close');
      expect(keyed('display-expression'), findsOneWidget);
      await tap(tester, 'toolbar-settings');
      expect(keyed('setting-io-linearLinear'), findsOneWidget);
      await tap(tester, 'settings-close');
      expect(tester.takeException(), isNull);
    });
  }
}
