import 'package:calculator_core/calculator_core.dart';
import 'package:test/test.dart';

Matcher failure(CalculatorErrorCode code, [int? position]) =>
    isA<CalculatorException>()
        .having((error) => error.code, 'code', code)
        .having(
          (error) => position == null || error.position == position,
          'position',
          true,
        );

Expression balancedSum(int leaves) {
  if (leaves == 1) return NumberExpression(Rational.fromInt(1), 0);
  final leftLeaves = leaves ~/ 2;
  return BinaryExpression(
    BinaryOperator.add,
    balancedSum(leftLeaves),
    balancedSum(leaves - leftLeaves),
    0,
  );
}

void main() {
  // H physical PDF p.21 supplies |2-7|*2=10. Prefix syntax and mandatory
  // closing parentheses are our Core contract, not a recorded key sequence.
  for (final (input, expected) in [
    ('Abs(2-7)*2', '10'),
    ('Abs(0)', '0'),
    ('Abs(-2/3)', '2/3'),
    ('Abs(2/3)', '2/3'),
    ('Abs(-0,125)', '1/8'),
    ('Abs(Abs(-3)-5)', '2'),
    ('-Abs(-5)', '-5'),
    ('+Abs(-5)', '5'),
    ('Abs(-2)²', '4'),
    ('Abs(-3)!', '6'),
    ('2^Abs(-3)', '8'),
    ('Abs(-10)nCr4', '210'),
    ('2*Abs(-3)', '6'),
    ('Abs(-3)(2)', '6'),
  ]) {
    test('exact absolute value and prefix binding $input', () {
      expect(evaluate(input).toString(), expected);
    });
  }

  for (final (input, position) in [
    ('Abs', 3),
    ('Abs 1', 4),
    ('Abs()', 4),
    ('Abs(1', 5),
    ('Abs(1))', 6),
    ('2Abs(3)', 1),
    ('Abs(-3)4', 7),
  ]) {
    test(
      'explicit argument delimiters and multiplication required: $input',
      () {
        expect(
          () => evaluate(input),
          throwsA(failure(CalculatorErrorCode.syntax, position)),
        );
      },
    );
  }

  test('only the exact Abs identifier is supported', () {
    for (final input in ['abs(-1)', 'ABS(-1)', 'aBs(-1)', 'sin(0)']) {
      expect(
        () => evaluate(input),
        throwsA(failure(CalculatorErrorCode.unsupported, 0)),
        reason: input,
      );
    }
  });

  test(
    'absolute AST uses the function start and retains operand positions',
    () {
      final power = parseExpression('Abs(-2)²') as BinaryExpression;
      final absolute = power.left as UnaryExpression;
      final negative = absolute.operand as UnaryExpression;
      expect(power.position, 7);
      expect(absolute.operator, UnaryOperator.absolute);
      expect(absolute.position, 0);
      expect(negative.operator, UnaryOperator.negate);
      expect(negative.position, 4);
      expect(negative.operand.position, 5);
    },
  );

  test('argument failures preserve their own positions', () {
    expect(
      () => evaluate('Abs(1/0)'),
      throwsA(failure(CalculatorErrorCode.math, 5)),
    );
    expect(
      () => evaluate('Abs((-5)!)'),
      throwsA(failure(CalculatorErrorCode.math, 8)),
    );
    expect(
      () => evaluate('Abs(1+*2)'),
      throwsA(failure(CalculatorErrorCode.syntax, 6)),
    );
  });

  test('Ans is evaluated exactly without modifying its caller-owned value', () {
    final answer = Rational(BigInt.from(-2), BigInt.from(3));
    expect(evaluate('Abs(Ans)', answer: answer).toString(), '2/3');
    expect(answer.toString(), '-2/3');
    expect(
      () => evaluate('Abs(Ans)'),
      throwsA(failure(CalculatorErrorCode.unsupported, 4)),
    );
  });

  test('prefix nesting shares the existing parser depth budget', () {
    final accepted = '${'Abs(' * 63}1${')' * 63}';
    final rejected = '${'Abs(' * 64}1${')' * 64}';
    expect(evaluate(accepted), Rational.fromInt(1));
    expect(
      () => evaluate(rejected),
      throwsA(failure(CalculatorErrorCode.limit)),
    );
  });

  test('function names and delimiters retain character and token budgets', () {
    expect(evaluate('${' ' * 2042}Abs(1)'), Rational.fromInt(1));
    expect(
      () => evaluate('${' ' * 2043}Abs(1)'),
      throwsA(failure(CalculatorErrorCode.limit)),
    );
    final accepted = '${List.filled(102, 'Abs(1)').join('+')}+1';
    expect(evaluate(accepted), Rational.fromInt(103));
    expect(
      () => parseExpression('$accepted+1'),
      throwsA(failure(CalculatorErrorCode.limit)),
    );
  });

  test(
    'public absolute AST retains unary signs and evaluation depth limits',
    () {
      Expression expression = NumberExpression(Rational.fromInt(-5), 0);
      for (var i = 0; i < 256; i++) {
        expression = UnaryExpression(UnaryOperator.absolute, expression, 1);
      }
      expect(evaluateExpression(expression), Rational.fromInt(5));
      expect(
        () => evaluateExpression(
          UnaryExpression(UnaryOperator.absolute, expression, 2),
        ),
        throwsA(failure(CalculatorErrorCode.limit)),
      );
      for (final (operator, expected) in [
        (UnaryOperator.plus, -5),
        (UnaryOperator.negate, 5),
        (UnaryOperator.absolute, 5),
      ]) {
        expect(
          evaluateExpression(
            UnaryExpression(
              operator,
              NumberExpression(Rational.fromInt(-5), 0),
              1,
            ),
          ),
          Rational.fromInt(expected),
        );
      }
    },
  );

  test('absolute nodes consume the shared evaluation work budget', () {
    // A balanced sum of 1024 leaves visits 2047 nodes without deep recursion.
    final sum = balancedSum(1024);
    final atLimit = UnaryExpression(UnaryOperator.absolute, sum, 1);
    expect(evaluateExpression(atLimit), Rational.fromInt(1024));
    expect(
      () => evaluateExpression(
        UnaryExpression(UnaryOperator.absolute, atLimit, 2),
      ),
      throwsA(failure(CalculatorErrorCode.limit)),
    );
    expect(evaluate('Abs(-1)'), Rational.fromInt(1));
  });

  test('absolute value preserves the existing public value bit budget', () {
    final boundary = Rational(-(BigInt.one << 99998));
    final expression = UnaryExpression(
      UnaryOperator.absolute,
      NumberExpression(boundary, 4),
      0,
    );
    expect(evaluateExpression(expression).numerator, -boundary.numerator);
    expect(boundary.numerator.isNegative, isTrue);
    expect(
      () => evaluateExpression(
        UnaryExpression(
          UnaryOperator.absolute,
          NumberExpression(Rational(BigInt.one << 99999), 4),
          0,
        ),
      ),
      throwsA(failure(CalculatorErrorCode.limit, 4)),
    );
  });
}
