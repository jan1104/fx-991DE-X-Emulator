import 'package:calculator_core/calculator_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fx991_calculator/application/calculator_controller.dart';

import 'calculator_controller_test.dart' show chooseVisible, setting;

void press(CalculatorController c, List<String> keys) {
  for (final key in keys) {
    c.pressId('KEY_$key');
  }
}

void main() {
  test('full reset restores setup and clears registers and both sessions', () {
    final c = CalculatorController();
    setting(c, ['number', 'fix', '2']);
    c.openSetup();
    chooseVisible(c, 'contrast');
    press(c, ['RIGHT', 'RIGHT', 'AC']);
    press(c, ['7', 'M_PLUS']);
    final mathAssignment = c.structured.prepareMemoryAssignment()!;
    c.selectInputOutput(CalculatorInputOutput.linearDecimal);
    press(c, ['9', 'ADD', 'ANS']);
    final linearAssignment = c.session.prepareMemoryAssignment()!;

    press(c, ['SHIFT', '9', '3']);
    expect(c.fullResetPending, isTrue);
    expect(c.menuTitle, 'Alles initialisieren?');
    expect(c.memory.snapshot.memory, Rational.fromInt(7));
    expect(c.settings.inputOutput, CalculatorInputOutput.linearDecimal);
    press(c, ['EQUALS']);

    expect(c.menuOpen, isFalse);
    expect(c.notice, 'Initialisierung abgeschlossen');
    expect(c.settings.inputOutput, CalculatorInputOutput.mathMath);
    expect(c.settings.numberFormat, CalculatorNumberFormat.norm);
    expect(c.settings.norm, 1);
    expect(c.settings.fixDigits, 3);
    expect(c.settings.contrast, 7);
    expect(c.memory.snapshot.answer, Rational.fromInt(0));
    expect(c.memory.snapshot.memory, Rational.fromInt(0));
    expect(c.structured.snapshot.editor.root.nodes, isEmpty);
    expect(c.structured.snapshot.result, isNull);
    expect(c.session.snapshot.expression, isEmpty);
    expect(c.session.snapshot.result, isNull);
    expect(c.session.commitMemoryAssignment(linearAssignment), isFalse);
    expect(c.structured.commitMemoryAssignment(mathAssignment), isFalse);
  });

  test(
    'full reset requires confirmation and preserves data on cancellation',
    () {
      final c = CalculatorController()
        ..selectInputOutput(CalculatorInputOutput.linearLinear);
      c.memory.calculate('5', operation: MemoryOperation.store);
      press(c, ['4', 'ADD', 'ANS']);
      final setup = c.settings;
      final draft = c.session.snapshot;
      final registers = c.memory.snapshot;
      press(c, ['SHIFT', '9', '3', '3', 'SHIFT', 'EQUALS']);
      expect(c.fullResetPending, isTrue);
      press(c, ['LEFT']);
      expect(c.menuTitle, 'RESET');
      press(c, ['3', 'AC']);
      expect(c.menuOpen, isFalse);
      expect(c.settings, same(setup));
      expect(c.session.snapshot, same(draft));
      expect(c.memory.snapshot, same(registers));
    },
  );

  test('full reset clears an error and permits a new calculation', () {
    final c = CalculatorController();
    press(c, ['1', 'DIVIDE', '0', 'EQUALS']);
    expect(c.phase, CalculatorPhase.error);
    press(c, ['SHIFT', '9', '3', 'EQUALS']);
    expect(c.phase, CalculatorPhase.editing);
    expect(c.structured.snapshot.error, isNull);
    press(c, ['2', 'EQUALS']);
    expect(c.resultText, '2');
  });
}
