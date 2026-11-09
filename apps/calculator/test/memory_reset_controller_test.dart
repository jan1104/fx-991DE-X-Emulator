import 'package:calculator_core/calculator_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fx991_calculator/application/calculator_controller.dart';

import 'calculator_controller_test.dart' show setting;

void press(CalculatorController c, List<String> keys) {
  for (final key in keys) {
    c.pressId('KEY_$key');
  }
}

void main() {
  test('RESET lists the three handbook choices and stages memory', () {
    final c = CalculatorController();
    c.memory.calculate('5', operation: MemoryOperation.store);
    final before = c.memory.snapshot;
    press(c, ['SHIFT', '9']);
    expect(c.menuTitle, 'RESET');
    expect(c.menuItems.map((item) => item.label), [
      'Setupdaten',
      'Speicher',
      'Alle initialis.',
    ]);
    press(c, ['3']);
    expect(c.menuTitle, 'RESET');
    expect(c.memory.snapshot, same(before));
    press(c, ['2']);
    expect(c.memoryResetPending, isTrue);
    expect(c.isKeyEnabled('KEY_EQUALS'), isTrue);
    expect(c.isKeyEnabled('KEY_M_PLUS'), isFalse);
    press(c, ['2', 'M_PLUS', 'SHIFT', 'EQUALS']);
    expect(c.memoryResetPending, isTrue);
    expect(c.memory.snapshot, same(before));
  });

  test('arrows and equals stage a reset, then LEFT returns to RESET', () {
    final c = CalculatorController();
    final before = c.memory.snapshot;
    press(c, ['SHIFT', '9', 'DOWN', 'EQUALS']);
    expect(c.memoryResetPending, isTrue);
    c.menuMove(1);
    press(c, ['LEFT']);
    expect(c.memoryResetPending, isFalse);
    expect(c.menuTitle, 'RESET');
    expect(c.menuSelection, 1);
    expect(c.memory.snapshot, same(before));
  });

  test(
    'confirmation resets both registers and preserves setup and editors',
    () {
      final c = CalculatorController();
      setting(c, ['number', 'fix', '2']);
      press(c, ['6', 'EQUALS']);
      final mathDraft = c.structured.snapshot.editor;
      c.selectInputOutput(CalculatorInputOutput.linearDecimal);
      press(c, ['7', 'ADD', 'ANS']);
      final candidate = c.session.prepareMemoryAssignment()!;
      final setup = c.settings;
      c.memory.calculate('1/3', operation: MemoryOperation.store);
      press(c, ['SHIFT', '9', '2', 'EQUALS']);
      expect(c.menuOpen, isFalse);
      expect(c.notice, 'Speicher gelöscht');
      expect(c.memory.snapshot.memory, Rational.fromInt(0));
      expect(c.memory.snapshot.answer, Rational.fromInt(0));
      expect(c.settings, same(setup));
      expect(c.session.snapshot.expression, '7+Ans');
      expect(c.structured.snapshot.editor, same(mathDraft));
      expect(c.structured.snapshot.result, Rational.fromInt(6));
      expect(c.session.commitMemoryAssignment(candidate), isFalse);
      press(c, ['EQUALS']);
      expect(c.resultText, '7,00');
    },
  );

  test(
    'AC cancels the reset without changing registers or the current draft',
    () {
      final c = CalculatorController()
        ..selectInputOutput(CalculatorInputOutput.linearLinear);
      c.memory.calculate('5', operation: MemoryOperation.store);
      press(c, ['4', 'ADD', 'ANS']);
      final before = c.memory.snapshot;
      final draft = c.session.snapshot;
      press(c, ['SHIFT', '9', '2', 'AC']);
      expect(c.menuOpen, isFalse);
      expect(c.memory.snapshot, same(before));
      expect(c.session.snapshot, same(draft));
      press(c, ['EQUALS']);
      expect(c.resultText, '9');
    },
  );

  test('opening setup or switching power cancels a pending reset', () {
    final c = CalculatorController();
    c.memory.calculate('8', operation: MemoryOperation.store);
    final before = c.memory.snapshot;
    press(c, ['SHIFT', '9', '2', 'SHIFT', 'MENU']);
    expect(c.menuTitle, 'Einstellungen');
    expect(c.memoryResetPending, isFalse);
    press(c, ['AC', 'SHIFT', '9', '2', 'SHIFT', 'AC']);
    expect(c.poweredOn, isFalse);
    press(c, ['ON']);
    expect(c.menuOpen, isFalse);
    expect(c.memory.snapshot, same(before));
  });
}
