/// Limited, platform-independent exact arithmetic. Not a complete emulator.
library;

export 'src/errors.dart';
export 'src/expressions/expression.dart';
export 'src/expressions/parser.dart' show parseExpression;
export 'src/evaluation/evaluator.dart' show evaluate, evaluateExpression;
export 'src/numbers/rational.dart';
