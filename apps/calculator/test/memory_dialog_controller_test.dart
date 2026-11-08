import 'package:calculator_core/calculator_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fx991_calculator/application/calculator_controller.dart';

import 'calculator_controller_test.dart' show setting;

void press(CalculatorController controller, List<String> keys) {
  for (final key in keys) {
    controller.pressId('KEY_$key');
  }
}

void main() {
  for (final mode in CalculatorInputOutput.values) {
    test(
      '$mode stores only after M and recalls the exact value after equals',
      () {
        final c = CalculatorController()..selectInputOutput(mode);
        press(c, ['1', 'DIVIDE', '8', 'STO']);
        expect(c.storePending, isTrue);
        expect(c.displayStatus, contains('STO'));
        expect(c.memory.snapshot.memory, Rational.fromInt(0));
        expect(c.memory.snapshot.answer, Rational.fromInt(0));
        expect(c.isKeyEnabled('KEY_2'), isFalse);
        press(c, ['STO', '2', 'EQUALS', 'SHIFT', 'M_PLUS']);
        expect(c.shift, isFalse);
        expect(c.storePending, isFalse);
        expect(c.memory.snapshot.memory.toString(), '1/8');
        expect(c.resultText, c.settings.decimalOutput ? '0,125' : '1/8');

        press(c, ['7', 'EQUALS', 'SHIFT', 'STO']);
        expect(c.recallPreviewText, '0,125');
        press(c, ['EQUALS']);
        expect(c.recallOpen, isTrue);
        expect(c.memory.snapshot.answer, Rational.fromInt(7));
        press(c, ['M_PLUS']);
        expect(c.recallSelected, isTrue);
        expect(c.memory.snapshot.answer, Rational.fromInt(7));
        press(c, ['EQUALS']);
        expect(c.recallOpen, isFalse);
        expect(c.resultText, c.settings.decimalOutput ? '0,125' : '1/8');
        expect(c.memory.snapshot.answer.toString(), '1/8');
        if (c.fractions) {
          final atom =
              c.structured.snapshot.editor.root.nodes.single as EditorText;
          expect(atom.text, 'M');
        } else {
          expect(c.session.snapshot.expression, 'M');
        }
      },
    );
  }

  test('AC dismisses both dialogs and retains an unexecuted draft', () {
    final c = CalculatorController()
      ..selectInputOutput(CalculatorInputOutput.linearLinear);
    press(c, ['3', 'ADD', '4']);
    final draft = c.session.snapshot;
    final registers = c.memory.snapshot;
    press(c, ['STO', 'AC', 'SHIFT', 'STO', 'M_PLUS', 'AC']);
    expect(c.storePending, isFalse);
    expect(c.recallPreviewText, isNull);
    expect(c.recallSelected, isFalse);
    expect(c.session.snapshot, same(draft));
    expect(c.memory.snapshot, same(registers));
    press(c, ['EQUALS']);
    expect(c.resultText, '7');
  });

  test('RECALL refreshes changed M and requires a fresh selection', () {
    final c = CalculatorController();
    c.memory.calculate('3', operation: MemoryOperation.store);
    press(c, ['SHIFT', 'STO', 'M_PLUS']);
    c.memory.calculate('9', operation: MemoryOperation.store);
    c.memory.calculate('4');
    expect(c.recallPreviewText, '3');
    final registers = c.memory.snapshot;
    press(c, ['EQUALS', 'EQUALS']);
    expect(c.recallPreviewText, '9');
    expect(c.recallSelected, isFalse);
    expect(c.memory.snapshot, same(registers));
    press(c, ['M_PLUS', 'EQUALS']);
    expect(c.resultText, '9');
  });

  test('RECALL uses Norm 1 even with Fix and grouping configured', () {
    final c = CalculatorController();
    setting(c, ['number', 'fix', '2']);
    setting(c, ['separator', 'on']);
    c.memory.calculate('1/300', operation: MemoryOperation.store);
    final settings = c.settings;
    press(c, ['SHIFT', 'STO']);
    expect(c.recallPreviewText, '3,333333333×10^-3');
    expect(c.settings, same(settings));
    press(c, ['AC']);
    expect(c.settings, same(settings));
  });

  test('a changed origin rejects STO and preserves the newer edit', () {
    final c = CalculatorController()
      ..selectInputOutput(CalculatorInputOutput.linearLinear);
    press(c, ['3', 'STO']);
    c.session.pressId('KEY_9');
    press(c, ['M_PLUS']);
    expect(c.storePending, isFalse);
    expect(c.session.snapshot.expression, '39');
    expect(c.memory.snapshot.memory, Rational.fromInt(0));
    expect(c.notice, contains('erneut'));
  });

  test('IO, menus and power close the dialog through normal entry points', () {
    final c = CalculatorController();
    press(c, ['2', 'STO', 'SHIFT']);
    c.selectInputOutput(CalculatorInputOutput.linearLinear);
    expect(c.storePending, isFalse);
    expect(c.shift, isFalse);
    press(c, ['SHIFT', 'STO', 'MENU']);
    expect(c.recallOpen, isFalse);
    expect(c.menuOpen, isTrue);
    press(c, ['AC', '3', 'STO', 'SHIFT', 'AC']);
    expect(c.poweredOn, isFalse);
    expect(c.storePending, isFalse);
    press(c, ['ON', 'SHIFT', 'STO', 'ON']);
    expect(c.recallOpen, isFalse);
    expect(c.memory.snapshot.memory, Rational.fromInt(0));
  });

  test('STO on empty input or division by zero never opens readiness', () {
    final c = CalculatorController();
    press(c, ['STO']);
    expect(c.storePending, isFalse);
    final registers = c.memory.snapshot;
    press(c, ['1', 'DIVIDE', '0', 'STO']);
    expect(c.storePending, isFalse);
    expect(c.phase, CalculatorPhase.error);
    expect(c.memory.snapshot, same(registers));
  });

  test('handbook sequence clears M, accumulates and recalls 35', () {
    final c = CalculatorController();
    c.memory.calculate('7', operation: MemoryOperation.store);
    press(c, ['0', 'STO', 'M_PLUS']);
    expect(c.resultText, '0');
    expect(c.memory.snapshot.hasMemory, isFalse);
    press(c, ['1', '0', 'MULTIPLY', '5', 'M_PLUS']);
    press(c, ['1', '0', 'ADD', '5', 'SHIFT', 'M_PLUS']);
    press(c, ['SHIFT', 'STO', 'M_PLUS', 'EQUALS']);
    expect(c.resultText, '35');
    expect(c.memory.snapshot.memory, Rational.fromInt(35));
  });
}
