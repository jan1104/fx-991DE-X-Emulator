import 'package:calculator_core/calculator_core.dart';
import 'package:flutter/services.dart';

/// Extra navigation of the structured prototype. The caller enables this only
/// in fractions mode; the linear key registry deliberately stays unchanged.
String? mapStructuredNavigation(
  KeyEvent event, {
  required bool modified,
  bool includeRepeats = false,
}) {
  if (modified ||
      (event is! KeyDownEvent && !(includeRepeats && event is KeyRepeatEvent)))
    return null;
  return switch (event.logicalKey) {
    LogicalKeyboardKey.arrowUp => 'KEY_UP',
    LogicalKeyboardKey.arrowDown => 'KEY_DOWN',
    _ => null,
  };
}

/// Only assigned prototype shortcuts. Unsupported keys retain normal OS use.
CalculatorKey? mapKeyboardEvent(
  KeyEvent event, {
  required bool modified,
  bool includeRepeats = false,
}) {
  if (modified ||
      (event is! KeyDownEvent &&
          !(includeRepeats && event is KeyRepeatEvent))) {
    return null;
  }
  final character = event.character;
  if (character != null && character.length == 1) {
    final digit = int.tryParse(character);
    if (digit != null && digit >= 0 && digit <= 9) {
      return CalculatorKey.fromId('KEY_$digit');
    }
    final key = switch (character) {
      '+' => CalculatorKey.add,
      '-' || '−' => CalculatorKey.subtract,
      '*' || '×' => CalculatorKey.multiply,
      '/' || '÷' => CalculatorKey.divide,
      '^' => CalculatorKey.power,
      '.' || ',' => CalculatorKey.decimal,
      '(' => CalculatorKey.leftParenthesis,
      ')' => CalculatorKey.rightParenthesis,
      _ => null,
    };
    if (key != null) return key;
  }
  return switch (event.logicalKey) {
    LogicalKeyboardKey.enter ||
    LogicalKeyboardKey.numpadEnter => CalculatorKey.equals,
    LogicalKeyboardKey.backspace ||
    LogicalKeyboardKey.delete => CalculatorKey.delete,
    LogicalKeyboardKey.escape => CalculatorKey.clear,
    LogicalKeyboardKey.arrowLeft => CalculatorKey.left,
    LogicalKeyboardKey.arrowRight => CalculatorKey.right,
    _ => null,
  };
}
