import 'package:calculator_core/calculator_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fx991_calculator/application/calculator_controller.dart';

void press(CalculatorController c, List<String> ids) {
  for (final id in ids) {
    c.pressId(id);
  }
}

Rational currentAnswer(CalculatorController c) =>
    c.fractions ? c.structured.snapshot.answer : c.session.snapshot.answer;

void main() {
  for (final start in CalculatorInputOutput.values) {
    final math =
        start == CalculatorInputOutput.mathMath ||
        start == CalculatorInputOutput.mathDecimal;
    test('$start shares exact Ans across the input mode switch', () {
      final c = CalculatorController()..selectInputOutput(start);
      press(c, ['KEY_1', 'KEY_DIVIDE', 'KEY_3', 'KEY_EQUALS']);
      c.selectInputOutput(
        math
            ? CalculatorInputOutput.linearLinear
            : CalculatorInputOutput.mathMath,
      );
      expect(currentAnswer(c).toString(), '1/3');
      press(c, ['KEY_ANS', 'KEY_MULTIPLY', 'KEY_3', 'KEY_EQUALS']);
      expect(c.resultText, '1');
      c.selectInputOutput(start);
      expect(currentAnswer(c), Rational.fromInt(1));
      expect(
        c.fractions
            ? c.structured.snapshot.result.toString()
            : c.session.snapshot.result.toString(),
        '1/3',
      );
    });
  }

  test('controllers remain independent while each owns both sessions', () {
    final first = CalculatorController();
    final second = CalculatorController();
    press(first, ['KEY_8', 'KEY_EQUALS']);
    expect(first.session.snapshot.answer, Rational.fromInt(8));
    expect(second.memory.snapshot.answer, Rational.fromInt(0));
    expect(second.structured.snapshot.answer, Rational.fromInt(0));
    expect(second.session.snapshot.answer, Rational.fromInt(0));
  });

  test('AC clears only the active draft and preserves both registers', () {
    final c = CalculatorController();
    press(c, ['KEY_7']);
    c.structured.applyMemory(MemoryOperation.add);
    c.selectInputOutput(CalculatorInputOutput.linearLinear);
    press(c, ['KEY_9']);
    final structured = c.structured.snapshot;
    final registers = c.memory.snapshot;
    c.pressId('KEY_AC');
    expect(c.session.snapshot.expression, '');
    expect(c.structured.snapshot, same(structured));
    expect(c.memory.snapshot, same(registers));
  });

  test('handbook memory sequence spans Math and Linear without showing M', () {
    final c = CalculatorController();
    press(c, ['KEY_1', 'KEY_0', 'KEY_MULTIPLY', 'KEY_5']);
    c.structured.applyMemory(MemoryOperation.add);
    c.selectInputOutput(CalculatorInputOutput.linearLinear);
    press(c, ['KEY_1', 'KEY_0', 'KEY_ADD', 'KEY_5']);
    c.session.applyMemory(MemoryOperation.subtract);
    expect(c.resultText, '15');
    expect(c.memory.snapshot.memory, Rational.fromInt(35));
    expect(c.structured.snapshot.answer, Rational.fromInt(15));
    expect(c.structured.snapshot.result, Rational.fromInt(50));
  });

  test('setup entry and input setting preserve the shared registers', () {
    final c = CalculatorController();
    c.memory.calculate('2/3', operation: MemoryOperation.store);
    final before = c.memory.snapshot;
    c.openSetup();
    c.pressId('KEY_1'); // Input/output submenu.
    c.pressId('KEY_3'); // Linear/Linear.
    c.pressId('KEY_AC');
    expect(c.settings.inputOutput, CalculatorInputOutput.linearLinear);
    expect(c.memory.snapshot, same(before));
    expect(currentAnswer(c).toString(), '2/3');
  });

  test('OFF and ON keep shared exact values within the same controller', () {
    final c = CalculatorController();
    c.memory.calculate('1/3', operation: MemoryOperation.store);
    final before = c.memory.snapshot;
    press(c, ['KEY_SHIFT', 'KEY_AC']);
    expect(c.poweredOn, isFalse);
    c.pressId('KEY_ON');
    expect(c.memory.snapshot, same(before));
    expect(c.session.snapshot.answer.toString(), '1/3');
    expect(c.structured.snapshot.answer.toString(), '1/3');
    expect(c.memory.snapshot.memory.toString(), '1/3');
  });

  test(
    'explicit memory initialization leaves settings and saved result intact',
    () {
      final c = CalculatorController();
      press(c, ['KEY_6', 'KEY_EQUALS']);
      c.structured.applyMemory(MemoryOperation.store);
      final settings = c.settings;
      c.memory.clearMemory();
      expect(c.settings, same(settings));
      expect(c.resultText, '6');
      expect(c.memory.snapshot.hasMemory, isFalse);
      expect(c.structured.snapshot.answer, Rational.fromInt(0));
      expect(c.session.snapshot.answer, Rational.fromInt(0));
      press(c, ['KEY_AC', 'KEY_ANS', 'KEY_ADD', 'KEY_1', 'KEY_EQUALS']);
      expect(c.resultText, '1');
    },
  );

  test('an inactive syntax error keeps its draft while seeing newer Ans', () {
    final c = CalculatorController();
    press(c, ['KEY_1', 'KEY_ADD', 'KEY_EQUALS']);
    final old = c.structured.snapshot;
    c.selectInputOutput(CalculatorInputOutput.linearLinear);
    press(c, ['KEY_4', 'KEY_EQUALS']);
    c.selectInputOutput(CalculatorInputOutput.mathMath);
    final refreshed = c.structured.snapshot;
    expect(refreshed.phase, CalculatorPhase.error);
    expect(refreshed.editor, same(old.editor));
    expect(refreshed.errorCursor, same(old.errorCursor));
    expect(refreshed.error, same(old.error));
    expect(refreshed.answer, Rational.fromInt(4));
    expect(old.answer, Rational.fromInt(0));
  });
}
