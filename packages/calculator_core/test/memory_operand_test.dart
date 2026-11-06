import 'package:calculator_core/calculator_core.dart';
import 'package:test/test.dart';

Matcher failure(CalculatorErrorCode code, int position) =>
    isA<CalculatorException>()
        .having((error) => error.code, 'code', code)
        .having((error) => error.position, 'position', position);

void main() {
  for (final (source, memory, expected) in [
    ('M', '1/3', '1/3'),
    ('M+1/6', '1/3', '1/2'),
    ('M-M', '1/3', '0'),
    ('M*M', '1/3', '1/9'),
    ('1/M', '2/3', '3/2'),
    ('-M²', '3', '-9'),
    ('(-M)²', '3', '9'),
    ('M⁻¹', '2/3', '3/2'),
    ('M³', '-2', '-8'),
    ('M%', '3', '3/100'),
    ('M!', '5', '120'),
    ('Abs(M)', '-2/3', '2/3'),
    ('M^2^3', '2', '256'),
    ('2*M', '1/3', '2/3'),
    ('2(M)', '1/3', '2/3'),
    ('M(2+1)', '1/3', '1'),
    ('M nCr 2', '5', '10'),
    ('M', '0', '0'),
  ]) {
    test('exact M binding and existing precedence: $source with $memory', () {
      final value = evaluate(memory);
      expect(evaluate(source, memoryValue: value).toString(), expected);
    });
  }

  test('Ans and M have independent explicit contexts', () {
    final answer = Rational(BigInt.one, BigInt.from(6));
    final memory = Rational(BigInt.one, BigInt.from(3));
    expect(
      evaluate('M+Ans', answer: answer, memoryValue: memory).toString(),
      '1/2',
    );
    expect(
      evaluate('M-Ans', answer: memory, memoryValue: answer).toString(),
      '-1/6',
    );
    expect(answer.toString(), '1/6');
    expect(memory.toString(), '1/3');
  });

  for (final (source, position) in [('M', 0), ('1+M', 2), ('Abs(M)', 4)]) {
    test('missing M context fails at its own position in $source', () {
      expect(
        () => evaluate(source, answer: Rational.fromInt(9)),
        throwsA(failure(CalculatorErrorCode.unsupported, position)),
      );
    });
  }

  test('M context never substitutes for missing Ans', () {
    expect(
      () => evaluate('Ans+M', memoryValue: Rational.fromInt(4)),
      throwsA(failure(CalculatorErrorCode.unsupported, 0)),
    );
  });

  for (final (source, position) in [
    ('2M', 1),
    ('M2', 1),
    ('M M', 2),
    ('M+', 2),
    ('(M', 2),
  ]) {
    test(
      'M does not extend implicit multiplication or malformed grammar: $source',
      () {
        expect(
          () => evaluate(source, memoryValue: Rational.fromInt(3)),
          throwsA(failure(CalculatorErrorCode.syntax, position)),
        );
      },
    );
  }

  for (final source in ['m', 'A', 'x', 'sin(M)', 'Memory']) {
    test('other identifiers remain unsupported: $source', () {
      expect(
        () => evaluate(source, memoryValue: Rational.fromInt(3)),
        throwsA(
          isA<CalculatorException>().having(
            (error) => error.code,
            'code',
            CalculatorErrorCode.unsupported,
          ),
        ),
      );
    });
  }

  test('the parsed tree freezes the memory binding without global state', () {
    var memory = Rational(BigInt.one, BigInt.from(3));
    final expression = parseExpression('M+1/6', memoryValue: memory);
    memory = Rational.fromInt(9);
    expect(evaluateExpression(expression).toString(), '1/2');
    expect(evaluate('M', memoryValue: memory), Rational.fromInt(9));
  });

  test('M is a bound number with its original source position', () {
    final value = Rational(BigInt.one, BigInt.from(3));
    final expression = parseExpression('  M', memoryValue: value);
    expect(expression, isA<NumberExpression>());
    final number = expression as NumberExpression;
    expect(number.position, 2);
    expect(number.value, same(value));
  });

  test('zero M division retains the existing mathematical error location', () {
    expect(
      () => evaluate('1/M', memoryValue: Rational.fromInt(0)),
      throwsA(failure(CalculatorErrorCode.math, 1)),
    );
  });

  test('a memory operand exactly at the size boundary is accepted', () {
    final value = Rational(BigInt.one << 99998);
    expect(evaluate('M', memoryValue: value), same(value));
  });

  test('an oversized bound memory value cannot bypass evaluator limits', () {
    expect(
      () => evaluate('M', memoryValue: Rational(BigInt.one << 99999)),
      throwsA(failure(CalculatorErrorCode.limit, 0)),
    );
  });

  test(
    'a large denominator is kept exact and checked at the same boundary',
    () {
      final value = Rational(BigInt.one, BigInt.one << 99998);
      expect(evaluate('M', memoryValue: value), same(value));
      expect(
        () => evaluate(
          'M',
          memoryValue: Rational(BigInt.one, BigInt.one << 99999),
        ),
        throwsA(failure(CalculatorErrorCode.limit, 0)),
      );
    },
  );
}
