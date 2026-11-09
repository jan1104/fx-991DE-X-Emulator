import 'package:calculator_core/calculator_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fx991_calculator/application/calculator_controller.dart';

import 'memory_dialog_widget_test.dart' show boot, displayText, tapKeys;

void press(CalculatorController c, List<String> keys) {
  for (final key in keys) {
    c.pressId('KEY_$key');
  }
}

void main() {
  for (final mode in [
    CalculatorInputOutput.mathMath,
    CalculatorInputOutput.linearLinear,
  ]) {
    test('$mode evaluates M against the current exact shared register', () {
      final c = CalculatorController()..selectInputOutput(mode);
      c.memory.calculate('1/3', operation: MemoryOperation.store);
      final before = c.memory.snapshot;
      press(c, ['ALPHA', 'M_PLUS', 'MULTIPLY', '3']);
      expect(c.alpha, isFalse);
      expect(c.memory.snapshot, same(before));
      c.memory.calculate('5/7', operation: MemoryOperation.store);
      press(c, ['EQUALS']);
      expect(c.resultText, '15/7');
      expect(c.memory.snapshot.memory.toString(), '5/7');
    });
  }

  test('modifiers replace each other and ALPHA toggles off on repeat', () {
    final c = CalculatorController();
    press(c, ['SHIFT', 'ALPHA']);
    expect(c.alpha, isTrue);
    expect(c.shift, isFalse);
    press(c, ['ALPHA']);
    expect(c.alpha, isFalse);
    press(c, ['ALPHA', 'SHIFT']);
    expect(c.alpha, isFalse);
    expect(c.shift, isTrue);
    press(c, ['2']); // Consume the unsupported SHIFT combination.
    press(c, ['2', 'ALPHA', 'SHIFT', 'M_PLUS']);
    expect(c.resultText, '2');
    expect(c.memory.snapshot.memory, Rational.fromInt(-2));
  });

  test('unsupported ALPHA consumes the latch without entering a digit', () {
    final c = CalculatorController()
      ..selectInputOutput(CalculatorInputOutput.linearLinear);
    press(c, ['4', 'ALPHA', '2']);
    expect(c.alpha, isFalse);
    expect(c.session.snapshot.expression, '4');
    expect(c.notice, contains('ALPHA'));
    press(c, ['2']);
    expect(c.session.snapshot.expression, '42');
  });

  test(
    'STO and RECALL keep their existing M selection while ALPHA is gated',
    () {
      final c = CalculatorController();
      press(c, ['4', 'STO', 'ALPHA', 'M_PLUS']);
      expect(c.memory.snapshot.memory, Rational.fromInt(4));
      press(c, ['SHIFT', 'STO', 'ALPHA', 'M_PLUS', 'EQUALS']);
      expect(c.resultText, '4');
      expect(c.alpha, isFalse);
      expect(c.memory.snapshot.memory, Rational.fromInt(4));
    },
  );

  test('global actions consume ALPHA and retain their normal behavior', () {
    final c = CalculatorController();
    press(c, ['5', 'ALPHA', 'AC']);
    expect(c.structured.snapshot.editor.root.nodes, isEmpty);
    expect(c.alpha, isFalse);
    press(c, ['ALPHA', 'MENU', 'ALPHA']);
    expect(c.menuOpen, isTrue);
    expect(c.alpha, isFalse);
    press(c, ['AC', 'ALPHA']);
    c.selectInputOutput(CalculatorInputOutput.linearLinear);
    expect(c.alpha, isFalse);
    press(c, ['ALPHA', 'SHIFT', 'AC', 'ALPHA']);
    expect(c.poweredOn, isFalse);
    expect(c.alpha, isFalse);
    press(c, ['ON', 'ALPHA', 'ON']);
    expect(c.alpha, isFalse);
  });

  testWidgets('ALPHA inserts a single deletable M on a narrow linear display', (
    tester,
  ) async {
    await boot(tester);
    await tapKeys(tester, ['KEY_2', 'KEY_ADD', 'KEY_ALPHA']);
    expect(displayText(tester, 'display-status'), contains('ALPHA'));
    await tapKeys(tester, ['KEY_M_PLUS']);
    expect(displayText(tester, 'display-status'), isNot(contains('ALPHA')));
    expect(displayText(tester, 'display-expression'), '2+M│');
    await tapKeys(tester, ['KEY_DEL']);
    expect(displayText(tester, 'display-expression'), '2+│');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Math captures M into a fraction and evaluates it exactly', (
    tester,
  ) async {
    await boot(tester, math: true);
    await tapKeys(tester, [
      'KEY_1',
      'KEY_DIVIDE',
      'KEY_3',
      'KEY_STO',
      'KEY_M_PLUS',
      'KEY_ALPHA',
      'KEY_M_PLUS',
      'action-wrap-fraction',
      'KEY_2',
      'KEY_EQUALS',
    ]);
    expect(displayText(tester, 'display-result'), '1/6');
    expect(displayText(tester, 'display-status'), isNot(contains('ALPHA')));
    expect(tester.takeException(), isNull);
  });
}
