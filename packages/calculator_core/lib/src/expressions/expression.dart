import '../numbers/rational.dart';

sealed class Expression {
  final int position;
  const Expression(this.position);
}

final class NumberExpression extends Expression {
  final Rational value;
  const NumberExpression(this.value, super.position);
}

enum UnaryOperator { plus, negate, factorial }

final class UnaryExpression extends Expression {
  final UnaryOperator operator;
  final Expression operand;
  const UnaryExpression(this.operator, this.operand, super.position);
}

enum BinaryOperator { add, subtract, multiply, divide, power }

final class BinaryExpression extends Expression {
  final BinaryOperator operator;
  final Expression left;
  final Expression right;
  const BinaryExpression(this.operator, this.left, this.right, super.position);
}
