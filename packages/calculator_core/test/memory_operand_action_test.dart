import 'package:calculator_core/calculator_core.dart';
import 'package:test/test.dart';

void main() {
  test('Linear inserts M at the cursor and DEL removes just that operand', () {
    final session = CalculatorSession()
      ..press(CalculatorKey.digit2)
      ..press(CalculatorKey.add)
      ..press(CalculatorKey.left);
    final original = session.snapshot;
    final inserted = session.pressId('ACTION_MEMORY');
    expect(inserted.tokens, ['2', 'M', '+']);
    expect(inserted.cursor, 2);
    expect(inserted.cursorOffset, 2);
    final removed = session.press(CalculatorKey.delete);
    expect(removed.tokens, original.tokens);
    expect(removed.cursor, original.cursor);
    expect(inserted.tokens, ['2', 'M', '+']);
  });

  test('Linear binds a drafted M to the current exact value at execution', () {
    final memory = CalculatorMemory()
      ..calculate('1/3', operation: MemoryOperation.store);
    final session = CalculatorSession(memory: memory)
      ..press(CalculatorKey.digit2)
      ..press(CalculatorKey.multiply)
      ..press(CalculatorKey.memory);
    memory.calculate('2/7', operation: MemoryOperation.store);
    memory.calculate('9');
    final evaluated = session.press(CalculatorKey.equals);
    expect(evaluated.tokens, ['2', '*', 'M']);
    expect(evaluated.result.toString(), '4/7');
    expect(memory.snapshot.memory.toString(), '2/7');
  });

  test('Math inserts and deletes a single M inside a fraction denominator', () {
    final session = StructuredCalculatorSession()
      ..pressId('KEY_FRACTION')
      ..press(CalculatorKey.digit2)
      ..pressId('KEY_DOWN');
    final inserted = session.pressId('ACTION_MEMORY');
    final fraction = inserted.editor.root.nodes.single as EditorFraction;
    expect((fraction.denominator.nodes.single as EditorText).text, 'M');
    expect(inserted.editor.cursor.path.single.field, FractionField.denominator);
    expect(inserted.editor.cursor.offset, 1);
    final removed = session.press(CalculatorKey.delete);
    final changed = removed.editor.root.nodes.single as EditorFraction;
    expect(changed.denominator.nodes, isEmpty);
    expect((changed.numerator.nodes.single as EditorText).text, '2');
    expect(removed.editor.cursor.path.single.field, FractionField.denominator);
    expect(removed.editor.cursor.offset, 0);
  });

  test(
    'Math captures M as a numerator and evaluates its current exact value',
    () {
      final memory = CalculatorMemory()
        ..calculate('1/3', operation: MemoryOperation.store);
      final session = StructuredCalculatorSession(memory: memory)
        ..press(CalculatorKey.digit2)
        ..press(CalculatorKey.add)
        ..press(CalculatorKey.memory)
        ..pressId('ACTION_WRAP_FRACTION')
        ..press(CalculatorKey.digit4);
      final fraction =
          session.snapshot.editor.root.nodes.last as EditorFraction;
      expect((fraction.numerator.nodes.single as EditorText).text, 'M');
      memory.calculate('2/3', operation: MemoryOperation.store);
      memory.calculate('9');
      expect(session.press(CalculatorKey.equals).result.toString(), '13/6');
      expect(memory.snapshot.memory.toString(), '2/3');
    },
  );
}
