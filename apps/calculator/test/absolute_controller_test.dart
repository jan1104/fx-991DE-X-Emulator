import 'package:calculator_core/calculator_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fx991_calculator/application/calculator_controller.dart';
import 'package:fx991_calculator/application/key_layout.dart';

CalculatorController controller(bool math) => CalculatorController()
  ..selectInputOutput(
    math ? CalculatorInputOutput.mathMath : CalculatorInputOutput.linearLinear,
  );

void press(CalculatorController c, List<String> ids) {
  for (final id in ids) {
    c.pressId(id);
  }
}

void absolute(CalculatorController c) => press(c, ['KEY_SHIFT', 'KEY_LPAREN']);
void exitArgument(CalculatorController c, bool math) =>
    c.pressId(math ? 'KEY_RIGHT' : 'KEY_RPAREN');
Rational answer(CalculatorController c) =>
    c.fractions ? c.structured.snapshot.answer : c.session.snapshot.answer;
Object snapshot(CalculatorController c) =>
    c.fractions ? c.structured.snapshot : c.session.snapshot;
CalculatorException? error(CalculatorController c) =>
    c.fractions ? c.structured.snapshot.error : c.session.snapshot.error;

void main() {
  for (final math in [false, true]) {
    final mode = math ? 'Math' : 'Linear';

    test('$mode absolute remains a secondary action on the existing front', () {
      final c = controller(math);
      final keys = calculatorRows.expand((row) => row).toList();
      expect(keys, hasLength(50));
      expect(
        keys.where((key) => c.isKeyEnabled(key.id)),
        hasLength(math ? 36 : 33),
      );
      expect(keys.where((key) => key.id == 'ACTION_ABS'), isEmpty);
      expect(CalculatorKey.values, hasLength(33));
    });

    test('$mode SHIFT left parenthesis executes the handbook expression', () {
      final c = controller(math);
      absolute(c);
      expect(c.shift, isFalse);
      press(c, ['KEY_2', 'KEY_SUBTRACT', 'KEY_7']);
      exitArgument(c, math);
      press(c, ['KEY_MULTIPLY', 'KEY_2', 'KEY_EQUALS']);
      expect(c.resultText, '10');
      expect(answer(c), Rational.fromInt(10));
    });

    test('$mode absolute binds negative fractional Ans exactly', () {
      final c = controller(math);
      press(c, ['KEY_NEGATE', 'KEY_2', 'KEY_DIVIDE', 'KEY_3', 'KEY_EQUALS']);
      final oldAnswer = answer(c);
      absolute(c);
      expect(c.phase, CalculatorPhase.editing);
      expect(answer(c), same(oldAnswer));
      if (math) {
        final node =
            c.structured.snapshot.editor.root.nodes.single as EditorAbsolute;
        expect((node.argument.nodes.single as EditorText).text, 'Ans');
        expect(
          c.structured.snapshot.editor.cursor.path.single.field,
          FractionField.argument,
        );
      } else {
        expect(c.session.snapshot.tokens, ['Abs(', 'Ans']);
      }
      exitArgument(c, math);
      c.pressId('KEY_EQUALS');
      expect(c.resultText, '2/3');
    });

    test(
      '$mode DEL removes the empty new argument without touching its prefix',
      () {
        final c = controller(math);
        c.pressId('KEY_8');
        absolute(c);
        c.pressId('KEY_DEL');
        c.pressId('KEY_EQUALS');
        expect(c.resultText, '8');
        expect(answer(c), Rational.fromInt(8));
      },
    );

    test('$mode empty argument freezes and recovers at its error cursor', () {
      final c = controller(math);
      absolute(c);
      c.pressId('KEY_EQUALS');
      expect(c.phase, CalculatorPhase.error);
      expect(error(c)!.code, CalculatorErrorCode.syntax);
      final failed = snapshot(c);
      absolute(c);
      expect(snapshot(c), same(failed));
      c.pressId('KEY_LEFT');
      c.pressId('KEY_5');
      exitArgument(c, math);
      c.pressId('KEY_EQUALS');
      expect(c.resultText, '5');
    });

    test('$mode cancelling SHIFT leaves the primary parenthesis intact', () {
      final c = controller(math);
      press(c, [
        'KEY_SHIFT',
        'KEY_SHIFT',
        'KEY_LPAREN',
        'KEY_2',
        'KEY_RPAREN',
        'KEY_EQUALS',
      ]);
      expect(c.resultText, '2');
      final completed = snapshot(c);
      press(c, ['KEY_SHIFT', 'KEY_POWER']);
      expect(c.notice, contains('in Vorbereitung'));
      expect(snapshot(c), same(completed));
    });

    test('$mode setup and OFF guard the new shifted action', () {
      final c = controller(math);
      press(c, ['KEY_8', 'KEY_EQUALS']);
      final completed = snapshot(c);
      c.openSetup();
      absolute(c);
      expect(c.menuOpen, isTrue);
      expect(snapshot(c), same(completed));
      press(c, ['KEY_AC', 'KEY_SHIFT', 'KEY_AC']);
      expect(c.poweredOn, isFalse);
      absolute(c);
      expect(snapshot(c), same(completed));
    });

    test('$mode absolute drafts survive switching the input mode', () {
      final c = controller(math);
      absolute(c);
      c.pressId('KEY_2');
      exitArgument(c, math);
      c.selectInputOutput(
        math
            ? CalculatorInputOutput.linearLinear
            : CalculatorInputOutput.mathMath,
      );
      absolute(c);
      c.pressId('KEY_3');
      exitArgument(c, !math);
      c.pressId('KEY_EQUALS');
      expect(c.resultText, '3');
      c.selectInputOutput(
        math
            ? CalculatorInputOutput.mathMath
            : CalculatorInputOutput.linearLinear,
      );
      c.pressId('KEY_EQUALS');
      expect(c.resultText, '2');
    });
  }
}
