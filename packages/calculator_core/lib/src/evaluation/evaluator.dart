import '../errors.dart';
import '../expressions/expression.dart';
import '../expressions/parser.dart';
import '../numbers/rational.dart';

Rational evaluate(String source, {Rational? answer, Rational? memoryValue}) =>
    evaluateExpression(
      parseExpression(source, answer: answer, memoryValue: memoryValue),
    );

/// Application resource limits; these are not claimed as Casio hardware limits.
Rational evaluateExpression(Expression expression) =>
    _evaluate(expression, 0, _EvaluationBudget());

final class _EvaluationBudget {
  int visits = 0;

  void consume(int position) {
    if (++visits > 2048) {
      throw CalculatorException(
        CalculatorErrorCode.limit,
        'Evaluation work budget exceeded',
        position: position,
      );
    }
  }
}

Rational _evaluate(Expression expression, int depth, _EvaluationBudget budget) {
  budget.consume(expression.position);
  if (depth > 256) {
    throw CalculatorException(
      CalculatorErrorCode.limit,
      'Evaluation too deep',
      position: expression.position,
    );
  }
  final Rational result;
  switch (expression) {
    case NumberExpression(:final value):
      result = value;
    case UnaryExpression(:final operator, :final operand):
      final value = _evaluate(operand, depth + 1, budget);
      result = switch (operator) {
        UnaryOperator.plus => value,
        UnaryOperator.negate => -value,
        UnaryOperator.absolute => value.numerator.isNegative ? -value : value,
        UnaryOperator.factorial => _factorial(
          value,
          expression.position,
          budget,
        ),
      };
    case BinaryExpression(:final operator, :final left, :final right):
      final a = _evaluate(left, depth + 1, budget);
      final b = _evaluate(right, depth + 1, budget);
      if (operator == BinaryOperator.divide && b.numerator == BigInt.zero) {
        throw CalculatorException(
          CalculatorErrorCode.math,
          'Division by zero',
          position: expression.position,
        );
      }
      if (operator == BinaryOperator.permutation ||
          operator == BinaryOperator.combination) {
        result = _combinatorics(
          a,
          b,
          combination: operator == BinaryOperator.combination,
          position: expression.position,
          budget: budget,
        );
      } else if (operator == BinaryOperator.power) {
        if (!b.isInteger) {
          throw CalculatorException(
            CalculatorErrorCode.unsupported,
            'Non-integer powers are not implemented',
            position: expression.position,
          );
        }
        if (b.numerator.abs() > BigInt.from(1000)) {
          throw CalculatorException(
            CalculatorErrorCode.limit,
            'Exponent exceeds budget',
            position: expression.position,
          );
        }
        if (a.numerator == BigInt.zero && b.numerator <= BigInt.zero) {
          throw CalculatorException(
            b.numerator == BigInt.zero
                ? CalculatorErrorCode.unsupported
                : CalculatorErrorCode.math,
            b.numerator == BigInt.zero
                ? 'Zero to zero awaits domain specification'
                : 'Division by zero',
            position: expression.position,
          );
        }
        final exponent = b.numerator.toInt();
        if ((a.numerator.bitLength + a.denominator.bitLength) * exponent.abs() >
            100000) {
          throw CalculatorException(
            CalculatorErrorCode.limit,
            'Power exceeds size budget',
            position: expression.position,
          );
        }
        result = a.pow(exponent);
      } else {
        result = switch (operator) {
          BinaryOperator.add => a + b,
          BinaryOperator.subtract => a - b,
          BinaryOperator.multiply => a * b,
          BinaryOperator.divide => a / b,
          BinaryOperator.power => throw StateError('Power handled above'),
          BinaryOperator.permutation || BinaryOperator.combination =>
            throw StateError('Combinatorics handled above'),
        };
      }
  }
  if (result.numerator.bitLength + result.denominator.bitLength > 100000) {
    throw CalculatorException(
      CalculatorErrorCode.limit,
      'Result exceeds size budget',
      position: expression.position,
    );
  }
  return result;
}

Rational _factorial(Rational value, int position, _EvaluationBudget budget) {
  if (!value.isInteger ||
      value.numerator < BigInt.zero ||
      value.numerator > BigInt.from(69)) {
    throw CalculatorException(
      CalculatorErrorCode.math,
      'Factorial requires an integer between 0 and 69',
      position: position,
    );
  }
  // Convert only after domain validation. At most 68 bounded multiplications
  // are charged to the same per-evaluation work budget as expression visits.
  final argument = value.numerator.toInt();
  var product = BigInt.one;
  for (var factor = 2; factor <= argument; factor++) {
    budget.consume(position);
    product *= BigInt.from(factor);
  }
  return Rational(product, BigInt.one);
}

final _combinatoricsInputLimit = BigInt.from(10).pow(10);
final _combinatoricsProductLimit = BigInt.from(10).pow(100);

Rational _combinatorics(
  Rational nValue,
  Rational rValue, {
  required bool combination,
  required int position,
  required _EvaluationBudget budget,
}) {
  CalculatorException domain() => CalculatorException(
    CalculatorErrorCode.math,
    'Combinatorics arguments or intermediate product outside supported domain',
    position: position,
  );
  final n = nValue.numerator;
  final r = rValue.numerator;
  if (!nValue.isInteger ||
      !rValue.isInteger ||
      n < BigInt.zero ||
      n >= _combinatoricsInputLimit ||
      r < BigInt.zero ||
      r > n) {
    throw domain();
  }
  // For nCr, the smaller falling product realizes the handbook's OR between
  // n!/r! and n!/(n-r)!. A reduced final result alone does not prove validity.
  final complement = n - r;
  final count = combination && complement < r ? complement : r;
  // falling(n,k) >= k! for n>=k; 70! already exceeds 10^100. Reject before
  // converting a potentially large count or entering an unbounded loop.
  if (count > BigInt.from(69)) throw domain();
  final iterations = count.toInt();
  var falling = BigInt.one;
  var denominator = BigInt.one;
  for (var i = 0; i < iterations; i++) {
    budget.consume(position);
    falling *= n - BigInt.from(i);
    if (falling >= _combinatoricsProductLimit) throw domain();
    if (combination) {
      budget.consume(position);
      denominator *= BigInt.from(i + 1);
    }
  }
  if (combination) {
    budget.consume(position);
    return Rational(falling ~/ denominator);
  }
  return Rational(falling);
}
