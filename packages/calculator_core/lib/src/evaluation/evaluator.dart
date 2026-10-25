import '../errors.dart';
import '../expressions/expression.dart';
import '../expressions/parser.dart';
import '../numbers/rational.dart';

Rational evaluate(String source) => evaluateExpression(parseExpression(source));

/// Application resource limits; these are not claimed as Casio hardware limits.
Rational evaluateExpression(Expression expression) =>
    _evaluate(expression, 0, _EvaluationBudget());

final class _EvaluationBudget {
  int visits = 0;
}

Rational _evaluate(Expression expression, int depth, _EvaluationBudget budget) {
  if (++budget.visits > 2048) {
    throw CalculatorException(
      CalculatorErrorCode.limit,
      'Evaluation work budget exceeded',
      position: expression.position,
    );
  }
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
      result = operator == UnaryOperator.negate ? -value : value;
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
      if (operator == BinaryOperator.power) {
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
