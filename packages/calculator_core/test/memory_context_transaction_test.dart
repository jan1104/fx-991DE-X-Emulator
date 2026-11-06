import 'package:calculator_core/calculator_core.dart';
import 'package:test/test.dart';

void main() {
  test('M binds zero in a new memory without changing the memory register', () {
    final memory = CalculatorMemory();
    expect(memory.calculate('M+1'), Rational.fromInt(1));
    expect(memory.snapshot.memory, Rational.fromInt(0));
    expect(memory.snapshot.answer, Rational.fromInt(1));
  });

  test('M and Ans bind separate exact registers in one calculation', () {
    final memory = CalculatorMemory()
      ..calculate('1/3', operation: MemoryOperation.store)
      ..calculate('1/6');
    expect(memory.calculate('M+Ans').toString(), '1/2');
    expect(memory.snapshot.memory.toString(), '1/3');
    expect(memory.calculate('M-Ans').toString(), '-1/6');
  });

  test(
    'M+ evaluation uses the old M once and publishes the operand as Ans',
    () {
      final memory = CalculatorMemory()
        ..calculate('2', operation: MemoryOperation.store);
      expect(
        memory.calculate('M+1', operation: MemoryOperation.add),
        Rational.fromInt(3),
      );
      expect(memory.snapshot.memory, Rational.fromInt(5));
      expect(memory.snapshot.answer, Rational.fromInt(3));
    },
  );

  test('subtracting the old M cancels exactly without substituting Ans', () {
    final memory = CalculatorMemory()
      ..calculate('1/3', operation: MemoryOperation.store)
      ..calculate('7');
    expect(
      memory.calculate('M', operation: MemoryOperation.subtract).toString(),
      '1/3',
    );
    expect(memory.snapshot.memory, Rational.fromInt(0));
    expect(memory.snapshot.hasMemory, isFalse);
    expect(memory.snapshot.answer.toString(), '1/3');
  });

  test('store evaluates old M/Ans before replacing either register', () {
    final memory = CalculatorMemory()
      ..calculate('3/4', operation: MemoryOperation.store)
      ..calculate('1/4');
    final old = memory.snapshot;
    memory.calculate('M-Ans', operation: MemoryOperation.store);
    expect(memory.snapshot.memory.toString(), '1/2');
    expect(memory.snapshot.answer.toString(), '1/2');
    expect(old.memory.toString(), '3/4');
    expect(old.answer.toString(), '1/4');
  });

  for (final operation in MemoryOperation.values) {
    test('${operation.name}: failure with M retains both registers', () {
      final memory = CalculatorMemory()
        ..calculate('2', operation: MemoryOperation.store)
        ..calculate('7');
      final old = memory.snapshot;
      expect(
        () => memory.calculate('M/(M-2)', operation: operation),
        throwsA(
          isA<CalculatorException>().having(
            (error) => error.code,
            'code',
            CalculatorErrorCode.math,
          ),
        ),
      );
      expect(memory.snapshot, same(old));
    });
  }

  test('separate contexts do not leak M to another memory instance', () {
    final first = CalculatorMemory()
      ..calculate('9', operation: MemoryOperation.store);
    final second = CalculatorMemory();
    expect(first.calculate('M'), Rational.fromInt(9));
    expect(second.calculate('M'), Rational.fromInt(0));
  });

  test('accumulation limit after evaluating M cannot partially write Ans', () {
    final memory = CalculatorMemory()
      ..acceptResult(
        Rational((BigInt.one << 99999) - BigInt.one),
        operation: MemoryOperation.store,
      )
      ..calculate('7');
    final old = memory.snapshot;
    expect(
      () => memory.calculate('M/M', operation: MemoryOperation.add),
      throwsA(
        isA<CalculatorException>().having(
          (error) => error.code,
          'code',
          CalculatorErrorCode.limit,
        ),
      ),
    );
    expect(memory.snapshot, same(old));
  });
}
