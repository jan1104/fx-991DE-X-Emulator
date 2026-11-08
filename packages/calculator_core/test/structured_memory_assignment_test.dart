import 'package:calculator_core/calculator_core.dart';
import 'package:test/test.dart';

void enter(StructuredCalculatorSession session, String source) {
  for (final character in source.split('')) {
    session.pressId(switch (character) {
      '+' => 'KEY_ADD',
      '-' => 'KEY_SUBTRACT',
      '*' => 'KEY_MULTIPLY',
      '/' => 'KEY_DIVIDE',
      '^' => 'KEY_POWER',
      '(' => 'KEY_LPAREN',
      ')' => 'KEY_RPAREN',
      _ => 'KEY_$character',
    });
  }
}

String expression(StructuredCalculatorSession session) =>
    FractionEditor.fromSnapshot(session.snapshot.editor).toExpression();

void main() {
  test('empty preparation preserves snapshot and both registers', () {
    final session = StructuredCalculatorSession();
    final before = session.snapshot;
    final memory = session.memory.snapshot;
    expect(session.prepareMemoryAssignment(), isNull);
    expect(session.snapshot, same(before));
    expect(session.memory.snapshot, same(memory));
  });

  test('an existing error cannot prepare a candidate or write registers', () {
    final session = StructuredCalculatorSession();
    enter(session, '1+');
    session.pressId('KEY_EQUALS');
    final before = session.snapshot;
    final memory = session.memory.snapshot;
    expect(session.prepareMemoryAssignment(), isNull);
    expect(session.snapshot, same(before));
    expect(session.memory.snapshot, same(memory));
  });

  test('editing preparation is pure and repeated preparation reuses it', () {
    final session = StructuredCalculatorSession();
    enter(session, '3+5');
    final before = session.snapshot;
    final registers = session.memory.snapshot;
    final candidate = session.prepareMemoryAssignment()!;
    expect(candidate.value, Rational.fromInt(8));
    expect(session.snapshot, same(before));
    expect(session.memory.snapshot, same(registers));
    expect(session.prepareMemoryAssignment(), same(candidate));
  });

  test('result preparation reuses shown value instead of reevaluating Ans', () {
    final memory = CalculatorMemory()..calculate('2');
    final session = StructuredCalculatorSession(memory: memory);
    session.pressId('KEY_ANS');
    enter(session, '+1');
    session.pressId('KEY_EQUALS');
    memory.calculate('9');
    final registers = memory.snapshot;
    expect(session.prepareMemoryAssignment()!.value, Rational.fromInt(3));
    expect(memory.snapshot, same(registers));
    expect(session.snapshot.result, Rational.fromInt(3));
    expect(session.snapshot.answer, Rational.fromInt(9));
  });

  test(
    'cancel preserves an unexecuted draft and invalidates its candidate',
    () {
      final session = StructuredCalculatorSession();
      enter(session, '3+5');
      final before = session.snapshot;
      final registers = session.memory.snapshot;
      final candidate = session.prepareMemoryAssignment()!;
      session.cancelMemoryAssignment();
      expect(session.snapshot, same(before));
      expect(session.memory.snapshot, same(registers));
      expect(session.commitMemoryAssignment(candidate), isFalse);
      expect(session.snapshot.phase, CalculatorPhase.editing);
    },
  );

  test('cancel retains a result and its representation request', () {
    final session = StructuredCalculatorSession();
    enter(session, '1/3');
    session.pressId('KEY_EQUALS');
    session.selectResultDisplayFormat(RationalDisplayFormat.exactDecimal);
    final before = session.snapshot;
    session.prepareMemoryAssignment();
    session.cancelMemoryAssignment();
    expect(session.snapshot, same(before));
    expect(
      session.snapshot.resultDisplayFormat,
      RationalDisplayFormat.exactDecimal,
    );
  });

  test(
    'commit stores the candidate once and publishes the matching result',
    () {
      final session = StructuredCalculatorSession();
      enter(session, '3+5');
      final editor = session.snapshot.editor;
      final candidate = session.prepareMemoryAssignment()!;
      expect(session.commitMemoryAssignment(candidate), isTrue);
      expect(session.memory.snapshot.memory, Rational.fromInt(8));
      expect(session.memory.snapshot.answer, Rational.fromInt(8));
      expect(session.snapshot.result, Rational.fromInt(8));
      expect(session.snapshot.editor, same(editor));
      final registers = session.memory.snapshot;
      expect(session.commitMemoryAssignment(candidate), isFalse);
      expect(session.memory.snapshot, same(registers));
    },
  );

  test('foreign candidate rejection preserves the legitimate current one', () {
    final first = StructuredCalculatorSession();
    final second = StructuredCalculatorSession();
    enter(first, '3');
    enter(second, '9');
    final foreign = first.prepareMemoryAssignment()!;
    final own = second.prepareMemoryAssignment()!;
    final registers = second.memory.snapshot;
    expect(second.commitMemoryAssignment(foreign), isFalse);
    expect(second.memory.snapshot, same(registers));
    expect(second.commitMemoryAssignment(own), isTrue);
    expect(second.memory.snapshot.memory, Rational.fromInt(9));
  });

  test('old candidate rejection does not cancel a later prepared value', () {
    final session = StructuredCalculatorSession();
    enter(session, '3');
    final old = session.prepareMemoryAssignment()!;
    session.pressId('KEY_4');
    final current = session.prepareMemoryAssignment()!;
    expect(session.commitMemoryAssignment(old), isFalse);
    expect(session.commitMemoryAssignment(current), isTrue);
    expect(session.snapshot.result, Rational.fromInt(34));
  });

  test('direct source editing rejects stale value without restoring draft', () {
    final session = StructuredCalculatorSession();
    enter(session, '3');
    final candidate = session.prepareMemoryAssignment()!;
    session.pressId('KEY_AC');
    enter(session, '9');
    session.memory.calculate('7', operation: MemoryOperation.store);
    final registers = session.memory.snapshot;
    final draft = session.snapshot;
    expect(session.commitMemoryAssignment(candidate), isFalse);
    expect(session.snapshot, same(draft));
    expect(expression(session), '9');
    expect(session.memory.snapshot, same(registers));
  });

  test('cursor movement changes the origin and rejects a stale candidate', () {
    final session = StructuredCalculatorSession();
    enter(session, '3+5');
    final candidate = session.prepareMemoryAssignment()!;
    session.pressId('KEY_LEFT');
    final current = session.snapshot;
    expect(session.commitMemoryAssignment(candidate), isFalse);
    expect(session.snapshot, same(current));
    expect(session.snapshot.editor.cursor.offset, 2);
  });

  test('prepared Ans is frozen despite later shared register changes', () {
    final memory = CalculatorMemory()..calculate('2');
    final session = StructuredCalculatorSession(memory: memory);
    session.pressId('KEY_ANS');
    enter(session, '+1');
    final candidate = session.prepareMemoryAssignment()!;
    memory.calculate('9', operation: MemoryOperation.store);
    expect(session.commitMemoryAssignment(candidate), isTrue);
    expect(session.snapshot.result, Rational.fromInt(3));
    expect(memory.snapshot.memory, Rational.fromInt(3));
  });

  test('prepared M is frozen and does not expand or reread its value', () {
    final memory = CalculatorMemory()
      ..calculate('2', operation: MemoryOperation.store);
    final session = StructuredCalculatorSession(memory: memory);
    session.recallMemory();
    session.pressId('KEY_LEFT');
    enter(session, '+1');
    final candidate = session.prepareMemoryAssignment()!;
    memory.calculate('9', operation: MemoryOperation.store);
    expect(session.commitMemoryAssignment(candidate), isTrue);
    expect(expression(session), 'M+1');
    expect(session.snapshot.result, Rational.fromInt(3));
    expect(memory.snapshot.memory, Rational.fromInt(3));
  });

  test('display choice alone preserves a prepared result candidate', () {
    final session = StructuredCalculatorSession();
    enter(session, '1/3');
    session.pressId('KEY_EQUALS');
    final candidate = session.prepareMemoryAssignment()!;
    session.selectResultDisplayFormat(RationalDisplayFormat.exactDecimal);
    expect(session.prepareMemoryAssignment(), same(candidate));
    expect(session.commitMemoryAssignment(candidate), isTrue);
    expect(session.snapshot.result.toString(), '1/3');
    expect(
      session.snapshot.resultDisplayFormat,
      RationalDisplayFormat.fraction,
    );
  });

  test('answer synchronization alone preserves the candidate identity', () {
    final session = StructuredCalculatorSession();
    enter(session, '3');
    final candidate = session.prepareMemoryAssignment()!;
    final before = session.snapshot;
    session.memory.calculate('9');
    expect(session.snapshot, isNot(same(before)));
    expect(session.prepareMemoryAssignment(), same(candidate));
    expect(session.commitMemoryAssignment(candidate), isTrue);
  });

  test('clearing the source prevents a pending assignment', () {
    final session = StructuredCalculatorSession();
    enter(session, '3');
    final candidate = session.prepareMemoryAssignment()!;
    session.pressId('KEY_AC');
    expect(session.commitMemoryAssignment(candidate), isFalse);
    expect(session.snapshot.editor.root.nodes, isEmpty);
    expect(session.memory.snapshot.memory, Rational.fromInt(0));
  });

  test(
    'empty fraction preparation reports its original denominator target',
    () {
      final session = StructuredCalculatorSession();
      session.pressId('KEY_FRACTION');
      session.pressId('KEY_1');
      session.pressId('KEY_DOWN');
      final registers = session.memory.snapshot;
      expect(session.prepareMemoryAssignment(), isNull);
      expect(session.memory.snapshot, same(registers));
      expect(session.snapshot.phase, CalculatorPhase.error);
      expect(session.snapshot.error!.code, CalculatorErrorCode.syntax);
      expect(
        session.snapshot.errorCursor!.path.single.field,
        FractionField.denominator,
      );
      expect(session.snapshot.errorCursor!.offset, 0);
    },
  );

  for (final (source, code) in [
    ('1/0', CalculatorErrorCode.math),
    ('2^(1/2)', CalculatorErrorCode.unsupported),
    ('2^1001', CalculatorErrorCode.limit),
  ]) {
    test(
      'preparation $code keeps both registers and existing source mapping',
      () {
        final memory = CalculatorMemory()
          ..calculate('7', operation: MemoryOperation.store);
        final session = StructuredCalculatorSession(memory: memory);
        enter(session, source);
        final registers = memory.snapshot;
        expect(session.prepareMemoryAssignment(), isNull);
        expect(session.snapshot.phase, CalculatorPhase.error);
        expect(session.snapshot.error!.code, code);
        expect(session.snapshot.errorCursor, isNotNull);
        expect(memory.snapshot, same(registers));
      },
    );
  }

  test('recall replaces an unrelated draft with one coherent M node', () {
    final memory = CalculatorMemory()
      ..calculate('8', operation: MemoryOperation.store);
    final session = StructuredCalculatorSession(memory: memory);
    enter(session, '9+');
    final old = session.snapshot;
    session.recallMemory();
    expect(expression(session), 'M');
    expect(session.snapshot.editor.root.nodes, hasLength(1));
    expect(session.snapshot.result, Rational.fromInt(8));
    expect(memory.snapshot.answer, Rational.fromInt(8));
    expect(memory.snapshot.memory, Rational.fromInt(8));
    expect(old.phase, CalculatorPhase.editing);
    expect(FractionEditor.fromSnapshot(old.editor).toExpression(), '9+');
  });

  test('negative fractional recall retains the exact value', () {
    final memory = CalculatorMemory()
      ..calculate('-1/3', operation: MemoryOperation.store);
    final session = StructuredCalculatorSession(memory: memory);
    session.recallMemory();
    expect(session.snapshot.result.toString(), '-1/3');
    expect(session.snapshot.answer.toString(), '-1/3');
    expect(expression(session), 'M');
  });

  test('zero recall clears previous error and retains a zero M register', () {
    final session = StructuredCalculatorSession();
    enter(session, '1+');
    session.pressId('KEY_EQUALS');
    session.recallMemory();
    expect(session.snapshot.phase, CalculatorPhase.result);
    expect(session.snapshot.error, isNull);
    expect(session.snapshot.errorCursor, isNull);
    expect(session.snapshot.result, Rational.fromInt(0));
    expect(session.memory.snapshot.hasMemory, isFalse);
  });

  test('large rational recall occupies one node without digit expansion', () {
    final value = Rational(BigInt.one, BigInt.one << 99998);
    final memory = CalculatorMemory()
      ..acceptResult(value, operation: MemoryOperation.store);
    final session = StructuredCalculatorSession(memory: memory);
    session.recallMemory();
    expect(session.snapshot.result, value);
    expect(session.snapshot.editor.root.nodes, hasLength(1));
    expect(expression(session), 'M');
  });

  test('recall resets the display choice and old error markers', () {
    final session = StructuredCalculatorSession();
    enter(session, '1/3');
    session.applyMemory(MemoryOperation.store);
    session.selectResultDisplayFormat(RationalDisplayFormat.exactDecimal);
    session.recallMemory();
    expect(
      session.snapshot.resultDisplayFormat,
      RationalDisplayFormat.fraction,
    );
    expect(session.snapshot.error, isNull);
    expect(session.snapshot.errorCursor, isNull);
  });

  test('recall invalidates an older prepared assignment', () {
    final session = StructuredCalculatorSession();
    enter(session, '3');
    final candidate = session.prepareMemoryAssignment()!;
    session.memory.calculate('8', operation: MemoryOperation.store);
    session.recallMemory();
    final registers = session.memory.snapshot;
    expect(session.commitMemoryAssignment(candidate), isFalse);
    expect(expression(session), 'M');
    expect(session.memory.snapshot, same(registers));
  });

  test(
    'a new result action consumes preparation even for the same operand',
    () {
      final session = StructuredCalculatorSession();
      enter(session, '3');
      session.pressId('KEY_EQUALS');
      final candidate = session.prepareMemoryAssignment()!;
      session.applyMemory(MemoryOperation.add);
      final registers = session.memory.snapshot;
      expect(session.snapshot.result, Rational.fromInt(3));
      expect(registers.memory, Rational.fromInt(3));
      expect(session.commitMemoryAssignment(candidate), isFalse);
      expect(session.memory.snapshot, same(registers));
    },
  );

  test('left and DEL after recall edit M rather than the previous draft', () {
    final session = StructuredCalculatorSession();
    enter(session, '987');
    session.recallMemory();
    session.pressId('KEY_LEFT');
    expect(expression(session), 'M');
    expect(session.snapshot.editor.cursor.offset, 1);
    session.pressId('KEY_DEL');
    expect(session.snapshot.editor.root.nodes, isEmpty);
  });

  test('recalled M is eligible for natural fraction capture', () {
    final memory = CalculatorMemory()
      ..calculate('1/3', operation: MemoryOperation.store);
    final session = StructuredCalculatorSession(memory: memory);
    session.recallMemory();
    session.pressId('KEY_LEFT');
    session.pressId('ACTION_WRAP_FRACTION');
    final fraction =
        session.snapshot.editor.root.nodes.single as EditorFraction;
    expect((fraction.numerator.nodes.single as EditorText).text, 'M');
    session.pressId('KEY_2');
    session.pressId('KEY_EQUALS');
    expect(session.snapshot.result.toString(), '1/6');
    expect(memory.snapshot.memory.toString(), '1/3');
  });

  test('operator after recall continues with exact Ans without altering M', () {
    final memory = CalculatorMemory()
      ..calculate('1/3', operation: MemoryOperation.store);
    final session = StructuredCalculatorSession(memory: memory);
    session.recallMemory();
    enter(session, '+1');
    session.pressId('KEY_EQUALS');
    expect(session.snapshot.result.toString(), '4/3');
    expect(memory.snapshot.memory.toString(), '1/3');
  });

  test('old recall result stays frozen while edited M uses current memory', () {
    final memory = CalculatorMemory()
      ..calculate('1/3', operation: MemoryOperation.store);
    final session = StructuredCalculatorSession(memory: memory);
    session.recallMemory();
    final old = session.snapshot;
    memory.calculate('2', operation: MemoryOperation.store);
    expect(session.snapshot.result.toString(), '1/3');
    session.pressId('KEY_LEFT');
    session.pressId('KEY_EQUALS');
    expect(session.snapshot.result, Rational.fromInt(2));
    expect(old.result.toString(), '1/3');
    expect(old.answer.toString(), '1/3');
  });

  test('cancel does not restore registers changed by a direct API call', () {
    final session = StructuredCalculatorSession();
    enter(session, '3');
    session.prepareMemoryAssignment();
    session.memory.calculate('9', operation: MemoryOperation.store);
    final current = session.memory.snapshot;
    session.cancelMemoryAssignment();
    expect(session.memory.snapshot, same(current));
    expect(session.snapshot.answer, Rational.fromInt(9));
    expect(expression(session), '3');
  });

  test('zero assignment clears a previously occupied M', () {
    final memory = CalculatorMemory()
      ..calculate('35', operation: MemoryOperation.store);
    final session = StructuredCalculatorSession(memory: memory);
    enter(session, '0');
    final candidate = session.prepareMemoryAssignment()!;
    expect(memory.snapshot.hasMemory, isTrue);
    expect(session.commitMemoryAssignment(candidate), isTrue);
    expect(memory.snapshot.hasMemory, isFalse);
    expect(session.snapshot.result, Rational.fromInt(0));
    expect(memory.snapshot.answer, Rational.fromInt(0));
  });
}
