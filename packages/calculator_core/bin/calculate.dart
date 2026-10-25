import 'dart:io';

import 'package:calculator_core/calculator_core.dart';

void main(List<String> arguments) {
  if (arguments.isEmpty) {
    stderr.writeln('Usage: dart run bin/calculate.dart "2/3 + 1/6"');
    exitCode = 64;
    return;
  }
  try {
    stdout.writeln(evaluate(arguments.join(' ')));
  } on CalculatorException catch (error) {
    stderr.writeln(error);
    exitCode = 2;
  }
}
