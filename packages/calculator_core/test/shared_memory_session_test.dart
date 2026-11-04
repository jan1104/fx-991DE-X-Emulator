import 'package:calculator_core/calculator_core.dart';
import 'package:test/test.dart';

final class Harness {
  Harness(bool structured, {CalculatorMemory? memory})
    : linear = structured ? null : CalculatorSession(memory: memory),
      math = structured ? StructuredCalculatorSession(memory: memory) : null;

  final CalculatorSession? linear;
  final StructuredCalculatorSession? math;

  CalculatorMemory get memory => linear?.memory ?? math!.memory;
  Object get snapshot => linear?.snapshot ?? math!.snapshot;
  Rational get answer => linear?.snapshot.answer ?? math!.snapshot.answer;
  Rational? get result =>
      linear != null ? linear!.snapshot.result : math!.snapshot.result;
  CalculatorPhase get phase => linear?.snapshot.phase ?? math!.snapshot.phase;
  CalculatorException? get error =>
      linear != null ? linear!.snapshot.error : math!.snapshot.error;
  RationalDisplayFormat get format =>
      linear?.snapshot.resultDisplayFormat ??
      math!.snapshot.resultDisplayFormat;
  Object get draft => linear?.snapshot.tokens ?? math!.snapshot.editor;

  void press(CalculatorKey key) {
    if (linear != null) {
      linear!.press(key);
    } else {
      math!.press(key);
    }
  }

  void pressId(String id) {
    if (linear != null) {
      linear!.pressId(id);
    } else {
      math!.pressId(id);
    }
  }

  void apply(MemoryOperation operation) {
    if (linear != null) {
      linear!.applyMemory(operation);
    } else {
      math!.applyMemory(operation);
    }
  }

  void select(RationalDisplayFormat format) {
    if (linear != null) {
      linear!.selectResultDisplayFormat(format);
    } else {
      math!.selectResultDisplayFormat(format);
    }
  }

  void enter(String source) {
    for (final character in source.split('')) {
      pressId(switch (character) {
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
}

Rational answerOf(Object snapshot) => switch (snapshot) {
  CalculatorSnapshot(:final answer) => answer,
  StructuredCalculatorSnapshot(:final answer) => answer,
  _ => throw StateError('Unknown snapshot'),
};

void main() {
  for (final structured in [false, true]) {
    final mode = structured ? 'Math' : 'Linear';

    test('$mode injection starts with existing exact Ans and M', () {
      final memory = CalculatorMemory()
        ..calculate('4', operation: MemoryOperation.store)
        ..calculate('2/3');
      final session = Harness(structured, memory: memory);
      expect(session.memory, same(memory));
      expect(session.answer.toString(), '2/3');
      expect(session.memory.snapshot.memory, Rational.fromInt(4));
    });

    test('$mode ordinary equals publishes exact Ans but preserves M', () {
      final memory = CalculatorMemory()
        ..calculate('7', operation: MemoryOperation.store);
      final session = Harness(structured, memory: memory)..enter('1/3');
      session.press(CalculatorKey.equals);
      expect(session.result.toString(), '1/3');
      expect(memory.snapshot.answer.toString(), '1/3');
      expect(memory.snapshot.memory, Rational.fromInt(7));
    });

    for (final operation in MemoryOperation.values) {
      test('$mode empty ${operation.name} does not replace shared Ans', () {
        final memory = CalculatorMemory()..calculate('5');
        final session = Harness(structured, memory: memory);
        final before = memory.snapshot;
        final editor = session.snapshot;
        session.apply(operation);
        expect(memory.snapshot, same(before));
        expect(session.snapshot, same(editor));
      });
    }

    test('$mode H p18 editing M+ then M- stores 35 and displays 15', () {
      final session = Harness(structured)..enter('10*5');
      session.apply(MemoryOperation.add);
      expect(session.result, Rational.fromInt(50));
      session.press(CalculatorKey.clear);
      session.enter('10+5');
      session.apply(MemoryOperation.subtract);
      expect(session.phase, CalculatorPhase.result);
      expect(session.result, Rational.fromInt(15));
      expect(session.answer, Rational.fromInt(15));
      expect(session.memory.snapshot.memory, Rational.fromInt(35));
    });

    test('$mode result action reuses operand instead of reevaluating Ans', () {
      final memory = CalculatorMemory()..calculate('2');
      final session = Harness(structured, memory: memory);
      session.press(CalculatorKey.answer);
      session.enter('+1');
      session.press(CalculatorKey.equals);
      expect(session.result, Rational.fromInt(3));
      memory.calculate('9');
      session.apply(MemoryOperation.add);
      expect(session.result, Rational.fromInt(3));
      expect(session.answer, Rational.fromInt(3));
      expect(memory.snapshot.memory, Rational.fromInt(3));
      session.apply(MemoryOperation.add);
      expect(memory.snapshot.memory, Rational.fromInt(6));
    });

    test('$mode draft Ans binds current memory without a snapshot read', () {
      final memory = CalculatorMemory()..calculate('8');
      final session = Harness(structured, memory: memory);
      session.press(CalculatorKey.answer);
      session.enter('+1');
      memory.calculate('1/3');
      session.pressId('KEY_EQUALS');
      expect(session.result.toString(), '4/3');
      expect(memory.snapshot.answer.toString(), '4/3');
    });

    test('$mode direct public command returns synchronized Ans', () {
      final session = Harness(structured)..enter('2+');
      session.memory.calculate('1/3');
      final returned = structured
          ? session.math!.press(CalculatorKey.left)
          : session.linear!.press(CalculatorKey.left);
      expect(answerOf(returned).toString(), '1/3');
      expect(session.phase, CalculatorPhase.editing);
    });

    test(
      '$mode synchronization preserves old result, format and snapshots',
      () {
        final session = Harness(structured)..enter('2/3');
        session.press(CalculatorKey.equals);
        session.select(RationalDisplayFormat.exactDecimal);
        final old = session.snapshot;
        final draft = session.draft;
        session.memory.calculate('1/7');
        expect(session.answer.toString(), '1/7');
        expect(session.result.toString(), '2/3');
        expect(session.phase, CalculatorPhase.result);
        expect(session.format, RationalDisplayFormat.exactDecimal);
        expect(session.draft, same(draft));
        expect(answerOf(old).toString(), '2/3');
        expect(session.snapshot, isNot(same(old)));
      },
    );

    test(
      '$mode display selection synchronizes Ans without overwriting result',
      () {
        final session = Harness(structured)..enter('1/2');
        session.press(CalculatorKey.equals);
        session.memory.calculate('9');
        session.select(RationalDisplayFormat.exactDecimal);
        expect(session.answer, Rational.fromInt(9));
        expect(session.result.toString(), '1/2');
        expect(session.format, RationalDisplayFormat.exactDecimal);
      },
    );

    test(
      '$mode AC preserves both memory registers and another session draft',
      () {
        final memory = CalculatorMemory()
          ..calculate('5', operation: MemoryOperation.store)
          ..calculate('1/3');
        final session = Harness(structured, memory: memory)..enter('2+');
        final other = Harness(!structured, memory: memory)..enter('9-');
        final draft = other.draft;
        final before = memory.snapshot;
        session.press(CalculatorKey.clear);
        expect(memory.snapshot, same(before));
        expect(other.draft, same(draft));
        expect(session.phase, CalculatorPhase.editing);
        expect(session.answer.toString(), '1/3');
      },
    );

    test(
      '$mode memory reset refreshes Ans while preserving displayed result',
      () {
        final session = Harness(structured)..enter('6');
        session.apply(MemoryOperation.store);
        final old = session.snapshot;
        session.memory.clearMemory();
        expect(session.answer, Rational.fromInt(0));
        expect(session.result, Rational.fromInt(6));
        expect(answerOf(old), Rational.fromInt(6));
        session.press(CalculatorKey.clear);
        session.press(CalculatorKey.answer);
        session.enter('+1');
        session.press(CalculatorKey.equals);
        expect(session.result, Rational.fromInt(1));
      },
    );

    test(
      '$mode result memory action resets only its representation choice',
      () {
        final session = Harness(structured)..enter('1/3');
        session.press(CalculatorKey.equals);
        session.select(RationalDisplayFormat.exactDecimal);
        session.apply(MemoryOperation.store);
        expect(session.result.toString(), '1/3');
        expect(session.memory.snapshot.memory.toString(), '1/3');
        expect(session.format, RationalDisplayFormat.fraction);
        session.apply(MemoryOperation.subtract);
        expect(session.memory.snapshot.hasMemory, isFalse);
        expect(session.answer.toString(), '1/3');
      },
    );

    for (final operation in MemoryOperation.values) {
      test('$mode ${operation.name} leaves error phase frozen', () {
        final session = Harness(structured)..enter('1/0');
        session.press(CalculatorKey.equals);
        final failed = session.snapshot;
        final memory = session.memory.snapshot;
        session.apply(operation);
        expect(session.snapshot, same(failed));
        expect(session.memory.snapshot, same(memory));
        expect(session.error!.code, CalculatorErrorCode.math);
      });
    }

    for (final (source, code) in [
      ('1+', CalculatorErrorCode.syntax),
      ('1/0', CalculatorErrorCode.math),
      ('2^(1/2)', CalculatorErrorCode.unsupported),
      ('2^1001', CalculatorErrorCode.limit),
    ]) {
      test('$mode editing $code cannot partially apply M+', () {
        final memory = CalculatorMemory()
          ..calculate('7/3', operation: MemoryOperation.store)
          ..calculate('5');
        final session = Harness(structured, memory: memory)..enter(source);
        final before = memory.snapshot;
        session.apply(MemoryOperation.add);
        expect(session.phase, CalculatorPhase.error);
        expect(session.error!.code, code);
        expect(session.answer, Rational.fromInt(5));
        expect(memory.snapshot, same(before));
      });
    }

    test('$mode error survives shared Ans refresh and arrow recovery', () {
      final session = Harness(structured)..enter('1/0');
      session.press(CalculatorKey.equals);
      final error = session.error;
      final draft = session.draft;
      final old = session.snapshot;
      session.memory.calculate('7');
      session.apply(MemoryOperation.add);
      expect(session.answer, Rational.fromInt(7));
      expect(session.phase, CalculatorPhase.error);
      expect(session.error, same(error));
      expect(session.draft, same(draft));
      expect(answerOf(old), Rational.fromInt(0));
      session.press(CalculatorKey.left);
      expect(session.phase, CalculatorPhase.editing);
      expect(session.answer, Rational.fromInt(7));
      expect(session.memory.snapshot.memory, Rational.fromInt(0));
    });

    test('$mode editing memory overflow preserves shared registers', () {
      final memory = CalculatorMemory()
        ..acceptResult(
          Rational((BigInt.one << 99999) - BigInt.one),
          operation: MemoryOperation.store,
        )
        ..calculate('7');
      final session = Harness(structured, memory: memory)..enter('1');
      final before = memory.snapshot;
      final draft = session.draft;
      session.apply(MemoryOperation.add);
      expect(session.phase, CalculatorPhase.error);
      expect(session.error!.code, CalculatorErrorCode.limit);
      expect(session.error!.position, isNull);
      expect(session.answer, Rational.fromInt(7));
      expect(memory.snapshot, same(before));
      expect(session.draft, equals(draft));
    });

    test('$mode result memory overflow preserves shared registers', () {
      final memory = CalculatorMemory()
        ..acceptResult(
          Rational((BigInt.one << 99999) - BigInt.one),
          operation: MemoryOperation.store,
        );
      final session = Harness(structured, memory: memory)..enter('1');
      session.press(CalculatorKey.equals);
      memory.calculate('7');
      final before = memory.snapshot;
      session.apply(MemoryOperation.add);
      expect(session.phase, CalculatorPhase.error);
      expect(session.error!.code, CalculatorErrorCode.limit);
      expect(session.answer, Rational.fromInt(7));
      expect(memory.snapshot, same(before));
    });

    test('$mode default sessions keep independent calculators isolated', () {
      final first = Harness(structured)..enter('8');
      final second = Harness(structured);
      first.apply(MemoryOperation.store);
      expect(second.answer, Rational.fromInt(0));
      expect(second.memory.snapshot.memory, Rational.fromInt(0));
      expect(second.memory, isNot(same(first.memory)));
    });
  }

  test('both real sessions exchange exact Ans through one shared memory', () {
    final memory = CalculatorMemory();
    final linear = Harness(false, memory: memory)..enter('1/3');
    final math = Harness(true, memory: memory);
    math.press(CalculatorKey.answer);
    math.enter('+1/6');
    linear.press(CalculatorKey.equals);
    math.apply(MemoryOperation.add);
    expect(math.result.toString(), '1/2');
    expect(linear.result.toString(), '1/3');
    expect(linear.answer.toString(), '1/2');
    linear.press(CalculatorKey.add);
    linear.enter('1');
    linear.press(CalculatorKey.equals);
    expect(linear.result.toString(), '3/2');
    expect(math.answer.toString(), '3/2');
    expect(memory.snapshot.memory.toString(), '1/2');
  });

  test('structured projection errors still target the empty denominator', () {
    final memory = CalculatorMemory()..calculate('5');
    final session = StructuredCalculatorSession(memory: memory);
    session.pressId('KEY_FRACTION');
    session.pressId('KEY_1');
    session.pressId('KEY_DOWN');
    final before = memory.snapshot;
    session.applyMemory(MemoryOperation.add);
    expect(memory.snapshot, same(before));
    expect(session.snapshot.phase, CalculatorPhase.error);
    expect(session.snapshot.error!.code, CalculatorErrorCode.syntax);
    expect(
      session.snapshot.errorCursor!.path.single.field,
      FractionField.denominator,
    );
    final target = session.snapshot.errorCursor;
    memory.calculate('8');
    session.selectResultDisplayFormat(RationalDisplayFormat.exactDecimal);
    expect(session.snapshot.errorCursor, same(target));
    session.pressId('KEY_LEFT');
    session.pressId('KEY_2');
    session.applyMemory(MemoryOperation.add);
    expect(session.snapshot.result.toString(), '1/2');
    expect(memory.snapshot.memory.toString(), '1/2');
  });

  test('structured positionless memory limit targets the current field', () {
    final memory = CalculatorMemory()
      ..acceptResult(
        Rational((BigInt.one << 99999) - BigInt.one),
        operation: MemoryOperation.store,
      )
      ..calculate('7');
    final session = StructuredCalculatorSession(memory: memory);
    for (final id in ['KEY_FRACTION', 'KEY_1', 'KEY_DOWN', 'KEY_1']) {
      session.pressId(id);
    }
    final cursor = session.snapshot.editor.cursor;
    final before = memory.snapshot;
    session.applyMemory(MemoryOperation.add);
    expect(memory.snapshot, same(before));
    expect(session.snapshot.error!.code, CalculatorErrorCode.limit);
    expect(session.snapshot.errorCursor, same(cursor));
    session.pressId('KEY_LEFT');
    expect(
      session.snapshot.editor.cursor.path.single.field,
      FractionField.denominator,
    );
    expect(session.snapshot.editor.cursor.offset, 1);
  });
}
