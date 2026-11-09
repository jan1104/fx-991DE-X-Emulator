import 'package:calculator_core/calculator_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fx991_calculator/application/calculator_controller.dart';

import 'calculator_controller_test.dart' show calculate, chooseVisible, setting;

void press(CalculatorController c, List<String> keys) {
  for (final key in keys) {
    c.pressId('KEY_$key');
  }
}

void main() {
  test(
    'setup reset restores the documented defaults and preserves contrast',
    () {
      final c = CalculatorController();
      for (final path in const [
        ['angle', 'radians'],
        ['number', 'fix', '2'],
        ['number', 'sci', '4'],
        ['number', 'norm', '2'],
        ['prefix', 'on'],
        ['fraction', 'mixed'],
        ['complex', 'polar'],
        ['frequency', 'on'],
        ['sheetAuto', 'off'],
        ['sheetCell', 'value'],
        ['solutions', 'off'],
        ['table', 'f'],
        ['period', 'off'],
        ['separator', 'on'],
        ['text', 'small'],
        ['qr', '3'],
        ['off', '60'],
      ]) {
        setting(c, path);
      }
      c.selectInputOutput(CalculatorInputOutput.linearDecimal);
      c.openSetup();
      chooseVisible(c, 'contrast');
      press(c, ['RIGHT', 'RIGHT', 'AC']);
      expect(c.settings.contrast, 7);
      expect(c.settings.inputOutput, CalculatorInputOutput.linearDecimal);

      press(c, ['SHIFT', '9', '1', 'EQUALS']);

      final s = c.settings;
      expect(c.menuOpen, isFalse);
      expect(c.notice, 'Setupdaten zurückgesetzt');
      expect(s.inputOutput, CalculatorInputOutput.mathMath);
      expect(s.angleUnit, CalculatorAngleUnit.degrees);
      expect(s.numberFormat, CalculatorNumberFormat.norm);
      expect(s.norm, 1);
      expect(s.fixDigits, 3);
      expect(s.sciDigits, 3);
      expect(s.engineeringPrefixes, isFalse);
      expect(s.fractionForm, CalculatorFractionForm.improper);
      expect(s.complexForm, CalculatorComplexForm.rectangular);
      expect(s.frequency, isFalse);
      expect(s.spreadsheetAutoCalculate, isTrue);
      expect(s.spreadsheetShowFormula, isTrue);
      expect(s.complexSolutions, isTrue);
      expect(s.tableBothFunctions, isTrue);
      expect(s.recurringDisplay, isTrue);
      expect(s.thousandsSeparator, isFalse);
      expect(s.smallText, isFalse);
      expect(s.qrVersion, 11);
      expect(s.autoOffMinutes, 10);
      expect(s.contrast, 7);
    },
  );

  test(
    'setup reset keeps registers and exact results with default formatting',
    () {
      final c = CalculatorController()
        ..selectInputOutput(CalculatorInputOutput.mathDecimal);
      c.memory.calculate('5/7', operation: MemoryOperation.store);
      calculate(c, '1/3');
      expect(c.resultText, '0,3333333333');
      final math = c.structured.snapshot;
      c.selectInputOutput(CalculatorInputOutput.linearDecimal);
      calculate(c, '2/3');
      final linear = c.session.snapshot;
      final registers = c.memory.snapshot;

      press(c, ['SHIFT', '9', '1', 'EQUALS']);

      expect(c.resultText, '1/3');
      expect(c.structured.snapshot.editor, same(math.editor));
      expect(c.structured.snapshot.result, math.result);
      expect(c.session.snapshot.expression, linear.expression);
      expect(c.session.snapshot.result, linear.result);
      expect(
        c.session.snapshot.resultDisplayFormat,
        RationalDisplayFormat.fraction,
      );
      expect(c.memory.snapshot, same(registers));
    },
  );

  test('setup reset waits for unshifted equals and allows cancellation', () {
    final c = CalculatorController()
      ..selectInputOutput(CalculatorInputOutput.linearLinear);
    c.memory.calculate('3', operation: MemoryOperation.store);
    press(c, ['4', 'ADD', 'ANS']);
    final setup = c.settings;
    final draft = c.session.snapshot;
    final registers = c.memory.snapshot;
    press(c, ['SHIFT', '9', '1']);
    expect(c.setupResetPending, isTrue);
    expect(c.isKeyEnabled('KEY_1'), isFalse);
    press(c, ['1', 'SHIFT', 'EQUALS', 'LEFT']);
    expect(c.menuTitle, 'RESET');
    expect(c.setupResetPending, isFalse);
    press(c, ['1', 'AC']);
    expect(c.menuOpen, isFalse);
    expect(c.settings, same(setup));
    expect(c.session.snapshot, same(draft));
    expect(c.memory.snapshot, same(registers));
  });
}
