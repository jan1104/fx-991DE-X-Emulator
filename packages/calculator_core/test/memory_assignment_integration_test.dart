import 'package:calculator_core/calculator_core.dart';
import 'package:test/test.dart';

void linearKeys(CalculatorSession session, List<String> ids) {
  for (final id in ids) {
    session.pressId(id);
  }
}

void mathKeys(StructuredCalculatorSession session, List<String> ids) {
  for (final id in ids) {
    session.pressId(id);
  }
}

void main() {
  test(
    'linear candidate survives a Math calculation and stores its own value',
    () {
      final memory = CalculatorMemory();
      final linear = CalculatorSession(memory: memory);
      final math = StructuredCalculatorSession(memory: memory);
      linearKeys(linear, ['KEY_1', 'KEY_DIVIDE', 'KEY_3']);
      final before = memory.snapshot;
      final candidate = linear.prepareMemoryAssignment()!;
      expect(memory.snapshot, same(before));
      mathKeys(math, ['KEY_7', 'KEY_EQUALS']);
      math.applyMemory(MemoryOperation.add);
      expect(linear.commitMemoryAssignment(candidate), isTrue);
      expect(memory.snapshot.memory.toString(), '1/3');
      expect(math.snapshot.result, Rational.fromInt(7));
      expect(math.snapshot.answer.toString(), '1/3');
      expect(linear.snapshot.result.toString(), '1/3');
    },
  );

  test('structured fraction candidate survives a Linear result', () {
    final memory = CalculatorMemory();
    final linear = CalculatorSession(memory: memory);
    final math = StructuredCalculatorSession(memory: memory);
    mathKeys(math, ['KEY_FRACTION', 'KEY_1', 'KEY_DOWN', 'KEY_2']);
    final draft = math.snapshot.editor;
    final candidate = math.prepareMemoryAssignment()!;
    linearKeys(linear, ['KEY_9', 'KEY_EQUALS']);
    expect(math.commitMemoryAssignment(candidate), isTrue);
    expect(math.snapshot.editor, same(draft));
    expect(memory.snapshot.memory.toString(), '1/2');
    expect(linear.snapshot.result, Rational.fromInt(9));
    expect(linear.snapshot.answer.toString(), '1/2');
  });

  test(
    'recall source M and its displayed result have distinct later bindings',
    () {
      final memory = CalculatorMemory()
        ..calculate('2/3', operation: MemoryOperation.store);
      final linear = CalculatorSession(memory: memory);
      final math = StructuredCalculatorSession(memory: memory);
      final old = linear.recallMemory();
      expect(old.expression, 'M');
      math.recallMemory();
      mathKeys(math, ['KEY_ADD', 'KEY_1', 'KEY_EQUALS']);
      math.applyMemory(MemoryOperation.store);
      expect(memory.snapshot.memory.toString(), '5/3');
      expect(old.result.toString(), '2/3');
      final candidate = linear.prepareMemoryAssignment()!;
      expect(candidate.value.toString(), '2/3');
      expect(linear.commitMemoryAssignment(candidate), isTrue);
      expect(memory.snapshot.memory.toString(), '2/3');
      expect(math.snapshot.result.toString(), '5/3');
      expect(math.snapshot.answer.toString(), '2/3');
    },
  );

  test(
    'cancelling one session candidate does not cancel the other session',
    () {
      final memory = CalculatorMemory();
      final linear = CalculatorSession(memory: memory);
      final math = StructuredCalculatorSession(memory: memory);
      linear.pressId('KEY_8');
      math.pressId('KEY_9');
      final first = linear.prepareMemoryAssignment()!;
      final second = math.prepareMemoryAssignment()!;
      linear.cancelMemoryAssignment();
      expect(linear.commitMemoryAssignment(first), isFalse);
      expect(math.commitMemoryAssignment(second), isTrue);
      expect(memory.snapshot.memory, Rational.fromInt(9));
      expect(linear.snapshot.expression, '8');
      expect(linear.snapshot.phase, CalculatorPhase.editing);
    },
  );

  test(
    'memory initialization does not rewrite a frozen candidate or old result',
    () {
      final memory = CalculatorMemory()
        ..calculate('2/3', operation: MemoryOperation.store);
      final linear = CalculatorSession(memory: memory);
      final math = StructuredCalculatorSession(memory: memory);
      final recalled = math.recallMemory();
      final candidate = math.prepareMemoryAssignment()!;
      memory.clearMemory();
      expect(linear.snapshot.answer, Rational.fromInt(0));
      expect(math.commitMemoryAssignment(candidate), isTrue);
      expect(memory.snapshot.memory.toString(), '2/3');
      expect(linear.snapshot.answer.toString(), '2/3');
      expect(recalled.result.toString(), '2/3');
      expect(recalled.editor.root.nodes, hasLength(1));
      expect((recalled.editor.root.nodes.single as EditorText).text, 'M');
    },
  );
}
