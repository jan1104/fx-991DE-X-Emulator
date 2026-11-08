import 'package:calculator_core/calculator_core.dart';
import 'package:test/test.dart';

void enter(CalculatorSession session, String source) {
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

void main() {
  test('preparing editing 3+5 is pure until the candidate is confirmed', () {
    final memory = CalculatorMemory()
      ..calculate('2', operation: MemoryOperation.store)
      ..calculate('7');
    final session = CalculatorSession(memory: memory);
    enter(session, '3+5');
    final before = session.snapshot;
    final registers = memory.snapshot;
    final candidate = session.prepareMemoryAssignment()!;
    expect(candidate.value, Rational.fromInt(8));
    expect(session.snapshot, same(before));
    expect(memory.snapshot, same(registers));
    expect(session.commitMemoryAssignment(candidate), isTrue);
    expect(session.snapshot.expression, '3+5');
    expect(session.snapshot.result, Rational.fromInt(8));
    expect(memory.snapshot.memory, Rational.fromInt(8));
    expect(memory.snapshot.answer, Rational.fromInt(8));
    expect(before.phase, CalculatorPhase.editing);
    expect(before.answer, Rational.fromInt(7));
  });

  test('zero assignment clears an occupied M only on confirmation', () {
    final memory = CalculatorMemory()
      ..calculate('5', operation: MemoryOperation.store);
    final session = CalculatorSession(memory: memory);
    enter(session, '0');
    final candidate = session.prepareMemoryAssignment()!;
    expect(memory.snapshot.hasMemory, isTrue);
    expect(session.commitMemoryAssignment(candidate), isTrue);
    expect(memory.snapshot.hasMemory, isFalse);
    expect(session.snapshot.result, Rational.fromInt(0));
  });

  test('repeated preparation returns the same exact frozen candidate', () {
    final session = CalculatorSession();
    enter(session, '1/3');
    final candidate = session.prepareMemoryAssignment()!;
    expect(session.prepareMemoryAssignment(), same(candidate));
    expect(candidate.value.toString(), '1/3');
    session.commitMemoryAssignment(candidate);
    expect(session.memory.snapshot.memory.toString(), '1/3');
  });

  test(
    'shared Ans changes do not rebind or invalidate an editing candidate',
    () {
      final memory = CalculatorMemory()..calculate('2');
      final session = CalculatorSession(memory: memory);
      session.press(CalculatorKey.answer);
      enter(session, '+1');
      final candidate = session.prepareMemoryAssignment()!;
      final old = session.snapshot;
      memory.calculate('99', operation: MemoryOperation.store);
      expect(session.prepareMemoryAssignment(), same(candidate));
      expect(session.snapshot.answer, Rational.fromInt(99));
      expect(old.answer, Rational.fromInt(2));
      expect(session.commitMemoryAssignment(candidate), isTrue);
      expect(session.snapshot.result, Rational.fromInt(3));
      expect(memory.snapshot.memory, Rational.fromInt(3));
    },
  );

  test(
    'a prepared M value remains frozen after the shared register changes',
    () {
      final memory = CalculatorMemory()
        ..calculate('1/3', operation: MemoryOperation.store);
      final session = CalculatorSession(memory: memory)..recallMemory();
      session.press(CalculatorKey.left);
      enter(session, '+1');
      final candidate = session.prepareMemoryAssignment()!;
      memory.calculate('9', operation: MemoryOperation.store);
      expect(session.commitMemoryAssignment(candidate), isTrue);
      expect(session.snapshot.result.toString(), '4/3');
      expect(memory.snapshot.memory.toString(), '4/3');
    },
  );

  test(
    'result preparation reuses the displayed value rather than current Ans',
    () {
      final memory = CalculatorMemory()..calculate('2');
      final session = CalculatorSession(memory: memory);
      session.press(CalculatorKey.answer);
      enter(session, '+1');
      session.press(CalculatorKey.equals);
      memory.calculate('9');
      final candidate = session.prepareMemoryAssignment()!;
      expect(candidate.value, Rational.fromInt(3));
      expect(session.commitMemoryAssignment(candidate), isTrue);
      expect(session.snapshot.result, Rational.fromInt(3));
      expect(memory.snapshot.memory, Rational.fromInt(3));
    },
  );

  test(
    'display choice alone preserves origin but confirmation resets choice',
    () {
      final session = CalculatorSession();
      enter(session, '1/3');
      session.press(CalculatorKey.equals);
      final candidate = session.prepareMemoryAssignment()!;
      session.selectResultDisplayFormat(RationalDisplayFormat.exactDecimal);
      expect(session.prepareMemoryAssignment(), same(candidate));
      expect(session.commitMemoryAssignment(candidate), isTrue);
      expect(
        session.snapshot.resultDisplayFormat,
        RationalDisplayFormat.fraction,
      );
    },
  );

  test('cancel preserves editing cursor, snapshots and register identity', () {
    final session = CalculatorSession();
    enter(session, '1+2');
    session.press(CalculatorKey.left);
    final before = session.snapshot;
    final registers = session.memory.snapshot;
    final candidate = session.prepareMemoryAssignment()!;
    session.cancelMemoryAssignment();
    expect(session.snapshot, same(before));
    expect(session.memory.snapshot, same(registers));
    expect(session.commitMemoryAssignment(candidate), isFalse);
  });

  test('cancel never rolls back later direct register or editor changes', () {
    final session = CalculatorSession();
    enter(session, '3');
    session.prepareMemoryAssignment();
    session.memory.calculate('9', operation: MemoryOperation.store);
    session.press(CalculatorKey.clear);
    enter(session, '4');
    final current = session.snapshot;
    final registers = session.memory.snapshot;
    session.cancelMemoryAssignment();
    expect(session.snapshot, same(current));
    expect(session.memory.snapshot, same(registers));
    expect(session.snapshot.expression, '4');
  });

  test('editing the source rejects a stale candidate without restoring it', () {
    final session = CalculatorSession();
    enter(session, '3');
    final candidate = session.prepareMemoryAssignment()!;
    enter(session, '9');
    final current = session.snapshot;
    final registers = session.memory.snapshot;
    expect(session.commitMemoryAssignment(candidate), isFalse);
    expect(session.snapshot, same(current));
    expect(session.snapshot.expression, '39');
    expect(session.memory.snapshot, same(registers));
  });

  test('navigation invalidates the prepared source cursor', () {
    final session = CalculatorSession();
    enter(session, '12');
    final candidate = session.prepareMemoryAssignment()!;
    session.press(CalculatorKey.left);
    final current = session.snapshot;
    expect(session.commitMemoryAssignment(candidate), isFalse);
    expect(session.snapshot, same(current));
    expect(session.snapshot.cursor, 1);
  });

  test('an old candidate cannot cancel a newly prepared candidate', () {
    final session = CalculatorSession();
    enter(session, '3');
    final old = session.prepareMemoryAssignment()!;
    enter(session, '9');
    final current = session.prepareMemoryAssignment()!;
    expect(session.commitMemoryAssignment(old), isFalse);
    expect(session.commitMemoryAssignment(current), isTrue);
    expect(session.memory.snapshot.memory, Rational.fromInt(39));
  });

  test(
    'foreign candidates cannot affect either owner or local pending action',
    () {
      final first = CalculatorSession();
      final second = CalculatorSession();
      enter(first, '3');
      enter(second, '7');
      final foreign = first.prepareMemoryAssignment()!;
      final local = second.prepareMemoryAssignment()!;
      expect(second.commitMemoryAssignment(foreign), isFalse);
      expect(first.memory.snapshot.memory, Rational.fromInt(0));
      expect(second.commitMemoryAssignment(local), isTrue);
      expect(second.memory.snapshot.memory, Rational.fromInt(7));
      expect(first.commitMemoryAssignment(foreign), isTrue);
    },
  );

  test('a confirmed candidate cannot be committed twice', () {
    final session = CalculatorSession();
    enter(session, '3');
    final candidate = session.prepareMemoryAssignment()!;
    expect(session.commitMemoryAssignment(candidate), isTrue);
    session.memory.calculate('9', operation: MemoryOperation.store);
    final registers = session.memory.snapshot;
    expect(session.commitMemoryAssignment(candidate), isFalse);
    expect(session.memory.snapshot, same(registers));
  });

  test('ordinary execution consumes the old preparation', () {
    final session = CalculatorSession();
    enter(session, '3');
    final candidate = session.prepareMemoryAssignment()!;
    session.press(CalculatorKey.equals);
    expect(session.commitMemoryAssignment(candidate), isFalse);
    expect(session.memory.snapshot.memory, Rational.fromInt(0));
  });

  test(
    'result M+ consumes preparation even when source and result stay equal',
    () {
      final session = CalculatorSession();
      enter(session, '3');
      session.press(CalculatorKey.equals);
      final candidate = session.prepareMemoryAssignment()!;
      session.applyMemory(MemoryOperation.add);
      final registers = session.memory.snapshot;
      final current = session.snapshot;
      expect(current.expression, '3');
      expect(current.result, Rational.fromInt(3));
      expect(registers.memory, Rational.fromInt(3));
      expect(registers.answer, Rational.fromInt(3));
      expect(session.commitMemoryAssignment(candidate), isFalse);
      expect(session.memory.snapshot, same(registers));
      expect(session.snapshot, same(current));
    },
  );

  test('empty and existing error states prepare no candidate', () {
    final session = CalculatorSession();
    final empty = session.snapshot;
    expect(session.prepareMemoryAssignment(), isNull);
    expect(session.snapshot, same(empty));
    enter(session, '1/0');
    session.press(CalculatorKey.equals);
    final failed = session.snapshot;
    expect(session.prepareMemoryAssignment(), isNull);
    expect(session.snapshot, same(failed));
  });

  for (final (source, code) in [
    ('1+', CalculatorErrorCode.syntax),
    ('1/0', CalculatorErrorCode.math),
    ('2^(1/2)', CalculatorErrorCode.unsupported),
    ('2^1001', CalculatorErrorCode.limit),
  ]) {
    test(
      '$code during preparation preserves both registers and permits recovery',
      () {
        final memory = CalculatorMemory()
          ..calculate('7', operation: MemoryOperation.store)
          ..calculate('5');
        final session = CalculatorSession(memory: memory);
        enter(session, source);
        final registers = memory.snapshot;
        expect(session.prepareMemoryAssignment(), isNull);
        expect(memory.snapshot, same(registers));
        expect(session.snapshot.phase, CalculatorPhase.error);
        expect(session.snapshot.error!.code, code);
        session.press(CalculatorKey.left);
        expect(session.snapshot.phase, CalculatorPhase.editing);
        expect(memory.snapshot, same(registers));
      },
    );
  }

  for (final phase in CalculatorPhase.values) {
    test(
      'recall replaces a $phase origin with coherent M and its exact result',
      () {
        final memory = CalculatorMemory()
          ..calculate('-1/3', operation: MemoryOperation.store)
          ..calculate('5');
        final session = CalculatorSession(memory: memory);
        enter(session, phase == CalculatorPhase.error ? '1/0' : '2');
        if (phase != CalculatorPhase.editing)
          session.press(CalculatorKey.equals);
        final old = session.snapshot;
        final recalled = session.recallMemory();
        expect(recalled.expression, 'M');
        expect(recalled.tokens, ['M']);
        expect(recalled.cursor, 1);
        expect(recalled.phase, CalculatorPhase.result);
        expect(recalled.result.toString(), '-1/3');
        expect(recalled.answer.toString(), '-1/3');
        expect(recalled.error, isNull);
        expect(memory.snapshot.memory.toString(), '-1/3');
        expect(old.expression, phase == CalculatorPhase.error ? '1/0' : '2');
        expect(
          old.answer,
          phase == CalculatorPhase.result
              ? Rational.fromInt(2)
              : Rational.fromInt(5),
        );
      },
    );
  }

  test(
    'recall zero updates Ans without inventing an occupied memory indicator',
    () {
      final memory = CalculatorMemory()..calculate('7');
      final session = CalculatorSession(memory: memory)..recallMemory();
      expect(session.snapshot.result, Rational.fromInt(0));
      expect(memory.snapshot.answer, Rational.fromInt(0));
      expect(memory.snapshot.hasMemory, isFalse);
    },
  );

  test(
    'left opens M and DEL removes the recalled atom rather than old input',
    () {
      final session = CalculatorSession();
      enter(session, '123');
      session.recallMemory();
      session.press(CalculatorKey.left);
      expect(session.snapshot.phase, CalculatorPhase.editing);
      expect(session.snapshot.tokens, ['M']);
      expect(session.snapshot.cursor, 1);
      session.press(CalculatorKey.delete);
      expect(session.snapshot.tokens, isEmpty);
    },
  );

  test('editing recalled M rebinds the then-current M exactly', () {
    final memory = CalculatorMemory()
      ..calculate('1/3', operation: MemoryOperation.store);
    final session = CalculatorSession(memory: memory)..recallMemory();
    final old = session.snapshot;
    memory.calculate('2/3', operation: MemoryOperation.store);
    session.press(CalculatorKey.left);
    session.press(CalculatorKey.equals);
    expect(session.snapshot.result.toString(), '2/3');
    expect(old.result.toString(), '1/3');
  });

  test('operator after recall continues with the confirmed exact Ans', () {
    final memory = CalculatorMemory()
      ..calculate('1/3', operation: MemoryOperation.store);
    final session = CalculatorSession(memory: memory)..recallMemory();
    enter(session, '*3');
    session.press(CalculatorKey.equals);
    expect(session.snapshot.result, Rational.fromInt(1));
    expect(memory.snapshot.memory.toString(), '1/3');
  });

  test('recall consumes pending assignment and resets only display choice', () {
    final session = CalculatorSession();
    enter(session, '3');
    session.press(CalculatorKey.equals);
    session.selectResultDisplayFormat(RationalDisplayFormat.exactDecimal);
    final candidate = session.prepareMemoryAssignment()!;
    session.memory.calculate('1/3', operation: MemoryOperation.store);
    session.recallMemory();
    expect(
      session.snapshot.resultDisplayFormat,
      RationalDisplayFormat.fraction,
    );
    expect(session.commitMemoryAssignment(candidate), isFalse);
    expect(session.snapshot.expression, 'M');
  });

  test(
    'large admissible rational recall uses one token without literal expansion',
    () {
      final value = Rational(BigInt.one, BigInt.one << 99998);
      final memory = CalculatorMemory()
        ..acceptResult(value, operation: MemoryOperation.store);
      final session = CalculatorSession(memory: memory)..recallMemory();
      expect(session.snapshot.tokens, ['M']);
      expect(session.snapshot.result, value);
      expect(memory.snapshot.answer, value);
      expect(memory.snapshot.memory, value);
    },
  );
}
