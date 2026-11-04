import 'package:calculator_core/calculator_core.dart';
import 'package:test/test.dart';

Matcher failure(CalculatorErrorCode code, {int? position}) =>
    isA<CalculatorException>()
        .having((error) => error.code, 'code', code)
        .having((error) => error.position, 'position', position);

void main() {
  test('new calculator has zero Ans and no independent memory indicator', () {
    final memory = CalculatorMemory();
    expect(memory.snapshot.answer, Rational.fromInt(0));
    expect(memory.snapshot.memory, Rational.fromInt(0));
    expect(memory.snapshot.hasMemory, isFalse);
    expect(memory.calculate('Ans+2'), Rational.fromInt(2));
  });

  test('H p18: add 50 then subtract 15 displays operand and stores 35', () {
    final memory = CalculatorMemory();
    memory.calculate('0', operation: MemoryOperation.store);
    expect(
      memory.calculate('10*5', operation: MemoryOperation.add),
      Rational.fromInt(50),
    );
    expect(
      memory.calculate('10+5', operation: MemoryOperation.subtract),
      Rational.fromInt(15),
    );
    expect(memory.snapshot.answer, Rational.fromInt(15));
    expect(memory.snapshot.memory, Rational.fromInt(35));
    expect(memory.snapshot.hasMemory, isTrue);
  });

  test('repeated thirds accumulate exactly and cancel to zero', () {
    final memory = CalculatorMemory();
    for (var count = 0; count < 3; count++) {
      memory.calculate('1/3', operation: MemoryOperation.add);
    }
    expect(memory.snapshot.memory, Rational.fromInt(1));
    memory.calculate('1', operation: MemoryOperation.subtract);
    expect(memory.snapshot.memory, Rational.fromInt(0));
    expect(memory.snapshot.hasMemory, isFalse);
    expect(memory.snapshot.answer, Rational.fromInt(1));
  });

  test('subtraction and negative operands retain their algebraic signs', () {
    final memory = CalculatorMemory();
    memory.calculate('2/3', operation: MemoryOperation.subtract);
    expect(memory.snapshot.memory.toString(), '-2/3');
    expect(memory.snapshot.hasMemory, isTrue);
    memory.calculate('-1/6', operation: MemoryOperation.subtract);
    expect(memory.snapshot.memory.toString(), '-1/2');
    memory.calculate('-1/2', operation: MemoryOperation.add);
    expect(memory.snapshot.memory, Rational.fromInt(-1));
  });

  test('Ans in a transaction is the previous result, not the M total', () {
    final memory = CalculatorMemory();
    memory.calculate('20', operation: MemoryOperation.store);
    memory.calculate('1/3');
    expect(
      memory.calculate('Ans+1/6', operation: MemoryOperation.add).toString(),
      '1/2',
    );
    expect(memory.snapshot.answer.toString(), '1/2');
    expect(memory.snapshot.memory.toString(), '41/2');
    expect(memory.calculate('Ans*6'), Rational.fromInt(3));
    expect(memory.snapshot.memory.toString(), '41/2');
  });

  test('ordinary results replace Ans while preserving M', () {
    final memory = CalculatorMemory();
    memory.calculate('8', operation: MemoryOperation.store);
    expect(memory.calculate('2+3'), Rational.fromInt(5));
    expect(memory.snapshot.answer, Rational.fromInt(5));
    expect(memory.snapshot.memory, Rational.fromInt(8));
  });

  test('store replaces rather than adds, zero removes the M indicator', () {
    final memory = CalculatorMemory();
    memory.calculate('100', operation: MemoryOperation.add);
    memory.calculate('-1/8', operation: MemoryOperation.store);
    expect(memory.snapshot.memory.toString(), '-1/8');
    expect(memory.snapshot.hasMemory, isTrue);
    memory.calculate('0', operation: MemoryOperation.store);
    expect(memory.snapshot.memory, Rational.fromInt(0));
    expect(memory.snapshot.answer, Rational.fromInt(0));
    expect(memory.snapshot.hasMemory, isFalse);
  });

  test('snapshots remain unchanged after later result, store and reset', () {
    final memory = CalculatorMemory();
    memory.calculate('7', operation: MemoryOperation.store);
    final old = memory.snapshot;
    memory.calculate('1/2');
    memory.calculate('3', operation: MemoryOperation.store);
    memory.clearMemory();
    expect(old.answer, Rational.fromInt(7));
    expect(old.memory, Rational.fromInt(7));
    expect(old.hasMemory, isTrue);
    expect(memory.snapshot, isNot(same(old)));
  });

  test('separate calculator instances never share memory or Ans', () {
    final first = CalculatorMemory();
    final second = CalculatorMemory();
    first.calculate('9', operation: MemoryOperation.store);
    second.calculate('Ans+1', operation: MemoryOperation.add);
    first.clearMemory();
    expect(first.snapshot.answer, Rational.fromInt(0));
    expect(first.snapshot.memory, Rational.fromInt(0));
    expect(second.snapshot.answer, Rational.fromInt(1));
    expect(second.snapshot.memory, Rational.fromInt(1));
  });

  test('memory initialization clears both registers and allows fresh use', () {
    final memory = CalculatorMemory();
    memory.calculate('8', operation: MemoryOperation.store);
    memory.calculate('3');
    memory.clearMemory();
    expect(memory.snapshot.answer, Rational.fromInt(0));
    expect(memory.snapshot.memory, Rational.fromInt(0));
    expect(memory.snapshot.hasMemory, isFalse);
    expect(memory.calculate('Ans+2'), Rational.fromInt(2));
    memory.calculate('Ans', operation: MemoryOperation.add);
    expect(memory.snapshot.memory, Rational.fromInt(2));
  });

  for (final operation in MemoryOperation.values) {
    for (final (source, code, position) in [
      ('1+', CalculatorErrorCode.syntax, 2),
      ('1/0', CalculatorErrorCode.math, 1),
      ('2^(1/2)', CalculatorErrorCode.unsupported, 1),
      ('2^1001', CalculatorErrorCode.limit, 1),
    ]) {
      test(
        '${operation.name}: $code preserves both registers and snapshot',
        () {
          final memory = CalculatorMemory();
          memory.calculate('7/3', operation: MemoryOperation.store);
          memory.calculate('5/2');
          final before = memory.snapshot;
          expect(
            () => memory.calculate(source, operation: operation),
            throwsA(failure(code, position: position)),
          );
          expect(memory.snapshot, same(before));
          expect(memory.calculate('Ans'), Rational(BigInt.from(5), BigInt.two));
          expect(memory.snapshot.memory.toString(), '7/3');
        },
      );
    }
  }

  test(
    'already evaluated structured results commit without decimal rounding',
    () {
      final memory = CalculatorMemory();
      final third = Rational(BigInt.one, BigInt.from(3));
      expect(memory.acceptResult(third, operation: MemoryOperation.add), third);
      memory.acceptResult(third, operation: MemoryOperation.add);
      expect(memory.snapshot.answer, third);
      expect(memory.snapshot.memory.toString(), '2/3');
    },
  );

  test('integer at the evaluator size boundary is accepted', () {
    final memory = CalculatorMemory();
    final edge = Rational(BigInt.one << 99998);
    expect(memory.acceptResult(edge, operation: MemoryOperation.store), edge);
    expect(memory.snapshot.answer, edge);
    expect(memory.snapshot.memory, edge);
    expect(memory.snapshot.hasMemory, isTrue);
  });

  test('fraction denominator at size boundary remains exact', () {
    final memory = CalculatorMemory();
    final edge = Rational(BigInt.one, BigInt.one << 99998);
    memory.acceptResult(edge, operation: MemoryOperation.store);
    expect(memory.snapshot.memory, edge);
    expect(memory.calculate('Ans'), edge);
  });

  for (final operation in MemoryOperation.values) {
    test('${operation.name}: oversized direct operand fails atomically', () {
      final memory = CalculatorMemory();
      memory.calculate('7', operation: MemoryOperation.store);
      memory.calculate('3');
      final before = memory.snapshot;
      final over = Rational(BigInt.one << 99999);
      expect(
        () => memory.acceptResult(over, operation: operation),
        throwsA(failure(CalculatorErrorCode.limit)),
      );
      expect(memory.snapshot, same(before));
    });
  }

  test(
    'oversized denominator is rejected before publishing either register',
    () {
      final memory = CalculatorMemory();
      memory.calculate('7', operation: MemoryOperation.store);
      final before = memory.snapshot;
      expect(
        () => memory.acceptResult(
          Rational(BigInt.one, BigInt.one << 99999),
          operation: MemoryOperation.store,
        ),
        throwsA(failure(CalculatorErrorCode.limit)),
      );
      expect(memory.snapshot, same(before));
    },
  );

  test(
    'valid operand cannot overflow accumulated M or update Ans on failure',
    () {
      final memory = CalculatorMemory();
      final largest = Rational((BigInt.one << 99999) - BigInt.one);
      memory.acceptResult(largest, operation: MemoryOperation.store);
      memory.calculate('7');
      final before = memory.snapshot;
      expect(
        () => memory.calculate('1', operation: MemoryOperation.add),
        throwsA(failure(CalculatorErrorCode.limit)),
      );
      expect(memory.snapshot, same(before));
      expect(memory.snapshot.answer, Rational.fromInt(7));
      expect(memory.snapshot.memory, largest);
    },
  );

  test('subtraction overflow is atomic even when operand fits', () {
    final memory = CalculatorMemory();
    final largest = Rational((BigInt.one << 99999) - BigInt.one);
    memory.acceptResult(largest, operation: MemoryOperation.store);
    final before = memory.snapshot;
    expect(
      () => memory.calculate('-1', operation: MemoryOperation.subtract),
      throwsA(failure(CalculatorErrorCode.limit)),
    );
    expect(memory.snapshot, same(before));
  });

  test('two individually valid boundary integers cannot overflow M', () {
    final memory = CalculatorMemory();
    final edge = Rational(BigInt.one << 99998);
    memory.acceptResult(edge, operation: MemoryOperation.store);
    final before = memory.snapshot;
    expect(
      () => memory.acceptResult(edge, operation: MemoryOperation.add),
      throwsA(failure(CalculatorErrorCode.limit)),
    );
    expect(memory.snapshot, same(before));
  });

  test('oversized operand is rejected even when cancellation would fit M', () {
    final memory = CalculatorMemory();
    final largest = Rational((BigInt.one << 99999) - BigInt.one);
    memory.acceptResult(largest, operation: MemoryOperation.store);
    final before = memory.snapshot;
    expect(
      () => memory.acceptResult(
        Rational(BigInt.one << 99999),
        operation: MemoryOperation.subtract,
      ),
      throwsA(failure(CalculatorErrorCode.limit)),
    );
    expect(memory.snapshot, same(before));
  });

  test('fraction addition uses the reduced result for the memory budget', () {
    final memory = CalculatorMemory();
    final denominator = BigInt.one << 99998;
    memory.acceptResult(
      Rational(BigInt.one, denominator),
      operation: MemoryOperation.store,
    );
    memory.acceptResult(
      Rational(BigInt.one, denominator),
      operation: MemoryOperation.add,
    );
    expect(memory.snapshot.memory, Rational(BigInt.one, denominator >> 1));
  });
}
