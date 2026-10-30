/// Limited, platform-independent exact arithmetic. Not a complete emulator.
library;

export 'src/editor/fraction_editor.dart';
export 'src/errors.dart';
export 'src/expressions/expression.dart';
export 'src/expressions/parser.dart' show parseExpression;
export 'src/formatting/rational_display.dart';
export 'src/evaluation/evaluator.dart' show evaluate, evaluateExpression;
export 'src/numbers/rational.dart';
export 'src/state/calculator_session.dart';
export 'src/state/structured_calculator_session.dart';
