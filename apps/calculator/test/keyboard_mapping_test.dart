import 'package:calculator_core/calculator_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fx991_calculator/application/keyboard_mapping.dart';

KeyDownEvent down({
  String? character,
  LogicalKeyboardKey logicalKey = LogicalKeyboardKey.keyA,
}) => KeyDownEvent(
  physicalKey: PhysicalKeyboardKey.keyA,
  logicalKey: logicalKey,
  character: character,
  timeStamp: Duration.zero,
);

void main() {
  group('prototype character mapping', () {
    for (var digit = 0; digit <= 9; digit++) {
      test('maps digit $digit through its stable key ID', () {
        final mapped = mapKeyboardEvent(
          down(character: '$digit'),
          modified: false,
        );
        expect(mapped?.id, 'KEY_$digit');
      });
    }

    final characters = <String, CalculatorKey>{
      '+': CalculatorKey.add,
      '-': CalculatorKey.subtract,
      '−': CalculatorKey.subtract,
      '*': CalculatorKey.multiply,
      '×': CalculatorKey.multiply,
      '/': CalculatorKey.divide,
      '÷': CalculatorKey.divide,
      '^': CalculatorKey.power,
      '.': CalculatorKey.decimal,
      ',': CalculatorKey.decimal,
      '(': CalculatorKey.leftParenthesis,
      ')': CalculatorKey.rightParenthesis,
    };
    for (final entry in characters.entries) {
      test('maps the typed character ${entry.key}', () {
        expect(
          mapKeyboardEvent(down(character: entry.key), modified: false),
          entry.value,
        );
      });
    }

    for (final character in ['a', 'sin', 'Ans', '√', '%', '', ' 1', '12']) {
      test('does not invent a shortcut for "$character"', () {
        expect(
          mapKeyboardEvent(down(character: character), modified: false),
          isNull,
        );
      });
    }
  });

  group('logical controls and event filtering', () {
    final controls = <LogicalKeyboardKey, CalculatorKey>{
      LogicalKeyboardKey.enter: CalculatorKey.equals,
      LogicalKeyboardKey.numpadEnter: CalculatorKey.equals,
      LogicalKeyboardKey.backspace: CalculatorKey.delete,
      LogicalKeyboardKey.delete: CalculatorKey.delete,
      LogicalKeyboardKey.escape: CalculatorKey.clear,
      LogicalKeyboardKey.arrowLeft: CalculatorKey.left,
      LogicalKeyboardKey.arrowRight: CalculatorKey.right,
    };
    for (final entry in controls.entries) {
      test('maps ${entry.key.keyLabel} without a character', () {
        expect(
          mapKeyboardEvent(down(logicalKey: entry.key), modified: false),
          entry.value,
        );
      });
    }

    for (final key in [
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.tab,
      LogicalKeyboardKey.space,
      LogicalKeyboardKey.f1,
    ]) {
      test('unsupported logical key ${key.keyLabel} remains unhandled', () {
        expect(
          mapKeyboardEvent(down(logicalKey: key), modified: false),
          isNull,
        );
      });
    }

    test('a modifier blocks character and control shortcuts', () {
      for (final event in [
        down(character: '1'),
        down(character: '+'),
        down(logicalKey: LogicalKeyboardKey.enter),
        down(logicalKey: LogicalKeyboardKey.backspace),
      ]) {
        expect(mapKeyboardEvent(event, modified: true), isNull);
      }
    });

    test('KeyUp and KeyRepeat never become additional actions', () {
      final events = <KeyEvent>[
        const KeyUpEvent(
          physicalKey: PhysicalKeyboardKey.digit1,
          logicalKey: LogicalKeyboardKey.digit1,
          timeStamp: Duration.zero,
        ),
        const KeyRepeatEvent(
          physicalKey: PhysicalKeyboardKey.digit1,
          logicalKey: LogicalKeyboardKey.digit1,
          character: '1',
          timeStamp: Duration.zero,
        ),
        const KeyUpEvent(
          physicalKey: PhysicalKeyboardKey.enter,
          logicalKey: LogicalKeyboardKey.enter,
          timeStamp: Duration.zero,
        ),
        const KeyRepeatEvent(
          physicalKey: PhysicalKeyboardKey.enter,
          logicalKey: LogicalKeyboardKey.enter,
          timeStamp: Duration.zero,
        ),
      ];
      for (final event in events) {
        expect(mapKeyboardEvent(event, modified: false), isNull);
      }
    });
  });
}
