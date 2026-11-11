import 'package:calculator_core/calculator_core.dart';
import 'package:test/test.dart';

Matcher failure(CalculatorErrorCode code, {int? position}) =>
    isA<CalculatorException>()
        .having((error) => error.code, 'code', code)
        .having((error) => error.position, 'position', position);

void main() {
  for (final (source, value, expected) in [
    ('A', '0', '0'),
    ('A+1/6', '1/3', '1/2'),
    ('A*A', '2/3', '4/9'),
    ('-A²', '3', '-9'),
    ('(-A)²', '3', '9'),
    ('A⁻¹', '2/3', '3/2'),
    ('Abs(A)', '-2/3', '2/3'),
    ('A%', '3', '3/100'),
    ('A!', '5', '120'),
    ('A nCr 2', '5', '10'),
  ]) {
    test('exact A binding: $source with $value', () {
      expect(evaluate(source, variableA: evaluate(value)).toString(), expected);
    });
  }

  for (final (source, position) in [('A', 0), ('1+A', 2), ('Abs(A)', 4)]) {
    test('missing A context fails at its own source position in $source', () {
      expect(
        () => evaluate(
          source,
          answer: Rational.fromInt(9),
          memoryValue: Rational.fromInt(8),
        ),
        throwsA(failure(CalculatorErrorCode.unsupported, position: position)),
      );
    });
  }

  test('Ans, M and A bind independently in one expression', () {
    expect(
      evaluate(
        'A+M+Ans',
        answer: evaluate('1/2'),
        memoryValue: evaluate('1/6'),
        variableA: evaluate('1/3'),
      ),
      Rational.fromInt(1),
    );
    expect(
      () => evaluate('Ans+A', variableA: Rational.fromInt(4)),
      throwsA(failure(CalculatorErrorCode.unsupported, position: 0)),
    );
    expect(
      () => evaluate('M+A', variableA: Rational.fromInt(4)),
      throwsA(failure(CalculatorErrorCode.unsupported, position: 0)),
    );
  });

  for (final (source, position) in [('2A', 1), ('A2', 1), ('A A', 2)]) {
    test('A preserves existing implicit multiplication policy in $source', () {
      expect(
        () => evaluate(source, variableA: Rational.fromInt(3)),
        throwsA(failure(CalculatorErrorCode.syntax, position: position)),
      );
    });
  }

  test('parsed expression keeps the exact A value after reassignment', () {
    final memory = CalculatorMemory();
    memory.storeVariableA(evaluate('1/3'));
    final expression = parseExpression(
      'A+1/6',
      variableA: memory.snapshot.variableA,
    );
    memory.storeVariableA(Rational.fromInt(9));
    expect(evaluateExpression(expression), evaluate('1/2'));
    expect(memory.calculate('A'), Rational.fromInt(9));
    final positioned = parseExpression(
      '  A',
      variableA: memory.snapshot.variableA,
    ) as NumberExpression;
    expect(positioned.position, 2);
    expect(positioned.value, same(memory.snapshot.variableA));
  });

  test(
    'A starts at zero and assignment preserves Ans, M and old snapshots',
    () {
      final memory = CalculatorMemory();
      expect(memory.snapshot.variableA, Rational.fromInt(0));
      expect(memory.calculate('A'), Rational.fromInt(0));
      memory.calculate('7', operation: MemoryOperation.store);
      memory.calculate('1/2');
      final before = memory.snapshot;
      memory.storeVariableA(evaluate('-2/3'));
      expect(memory.snapshot.variableA, evaluate('-2/3'));
      expect(memory.snapshot.answer, before.answer);
      expect(memory.snapshot.memory, before.memory);
      expect(before.variableA, Rational.fromInt(0));
      expect(memory.snapshot, isNot(same(before)));
    },
  );

  for (final operation in MemoryOperation.values) {
    test('${operation.name} binds A and preserves it when committing', () {
      final memory = CalculatorMemory();
      memory.calculate('2', operation: MemoryOperation.store);
      memory.storeVariableA(evaluate('1/3'));
      expect(memory.calculate('A+1/6', operation: operation), evaluate('1/2'));
      expect(memory.snapshot.variableA, evaluate('1/3'));
      expect(memory.snapshot.answer, evaluate('1/2'));
      expect(memory.snapshot.memory, switch (operation) {
        MemoryOperation.result => evaluate('2'),
        MemoryOperation.add => evaluate('5/2'),
        MemoryOperation.subtract => evaluate('3/2'),
        MemoryOperation.store => evaluate('1/2'),
      });
    });

    test(
      '${operation.name} failed A expression preserves the entire snapshot',
      () {
        final memory = CalculatorMemory();
        memory.calculate('7', operation: MemoryOperation.store);
        memory.calculate('1/2');
        memory.storeVariableA(evaluate('2/3'));
        final before = memory.snapshot;
        expect(
          () => memory.calculate('A/0', operation: operation),
          throwsA(failure(CalculatorErrorCode.math, position: 1)),
        );
        expect(memory.snapshot, same(before));
      },
    );
  }

  test('A keeps its own register and does not activate the M indicator', () {
    final first = CalculatorMemory();
    final second = CalculatorMemory();
    first.storeVariableA(evaluate('2/3'));
    expect(first.snapshot.hasMemory, isFalse);
    expect(second.snapshot.variableA, Rational.fromInt(0));
    first.clearMemory();
    expect(first.snapshot.answer, Rational.fromInt(0));
    expect(first.snapshot.memory, Rational.fromInt(0));
    expect(first.snapshot.variableA, Rational.fromInt(0));
    expect(first.calculate('A+Ans+M'), Rational.fromInt(0));
  });

  test('memory reset clears A together with nonzero Ans and M', () {
    final memory = CalculatorMemory();
    memory.calculate('8', operation: MemoryOperation.store);
    memory.calculate('3');
    memory.storeVariableA(evaluate('-1/3'));
    final before = memory.snapshot;
    memory.clearMemory();
    expect(memory.snapshot.answer, Rational.fromInt(0));
    expect(memory.snapshot.memory, Rational.fromInt(0));
    expect(memory.snapshot.variableA, Rational.fromInt(0));
    expect(before.variableA, evaluate('-1/3'));
    expect(memory.calculate('A+1'), Rational.fromInt(1));
  });

  for (final denominator in [false, true]) {
    test(
      'A assignment and evaluation enforce the size boundary ($denominator)',
      () {
        final memory = CalculatorMemory();
        memory.calculate('7', operation: MemoryOperation.store);
        final edge = denominator
            ? Rational(BigInt.one, BigInt.one << 99998)
            : Rational(BigInt.one << 99998);
        memory.storeVariableA(edge);
        expect(memory.calculate('A'), edge);
        final before = memory.snapshot;
        final oversized = denominator
            ? Rational(BigInt.one, BigInt.one << 99999)
            : Rational(BigInt.one << 99999);
        expect(
          () => memory.storeVariableA(oversized),
          throwsA(failure(CalculatorErrorCode.limit)),
        );
        expect(memory.snapshot, same(before));
        expect(
          () => evaluate('A', variableA: oversized),
          throwsA(failure(CalculatorErrorCode.limit, position: 0)),
        );
      },
    );
  }
}
