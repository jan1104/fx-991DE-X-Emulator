import 'package:calculator_core/calculator_core.dart';
import 'package:test/test.dart';

void enter(StructuredCalculatorSession session, String source) {
  const keys = {
    '+': 'KEY_ADD',
    '-': 'KEY_SUBTRACT',
    '*': 'KEY_MULTIPLY',
    '/': 'KEY_DIVIDE',
    '^': 'KEY_POWER',
    ',': 'KEY_DECIMAL',
    '(': 'KEY_LPAREN',
    ')': 'KEY_RPAREN',
  };
  for (final character in source.split('')) {
    session.pressId(keys[character] ?? 'KEY_$character');
  }
}

void fraction(StructuredCalculatorSession session, String top, String bottom) {
  session.pressId('KEY_FRACTION');
  enter(session, top);
  session.press(CalculatorKey.right);
  enter(session, bottom);
  session.press(CalculatorKey.right);
}

String expression(StructuredCalculatorSnapshot snapshot) =>
    FractionEditor.fromSnapshot(snapshot.editor).toExpression();

Matcher hasCode(CalculatorErrorCode code) =>
    isA<CalculatorException>().having((error) => error.code, 'code', code);

void main() {
  group('immutable structured state', () {
    test('starts empty with exact zero Ans and no result/error', () {
      final session = StructuredCalculatorSession();
      final initial = session.snapshot;
      expect(initial.editor.root.nodes, isEmpty);
      expect(initial.editor.cursor.path, isEmpty);
      expect(initial.editor.cursor.offset, 0);
      expect(initial.phase, CalculatorPhase.editing);
      expect(initial.answer, Rational.fromInt(0));
      expect(initial.result, isNull);
      expect(initial.error, isNull);
      expect(identical(session.press(CalculatorKey.equals), initial), isTrue);
    });

    test(
      'a restored editor is isolated from its source and sibling editors',
      () {
        final original = FractionEditor()..insertFraction();
        original.insertText('1');
        original.moveRight();
        original.insertText('3');
        final before = original.snapshot;
        final restored = FractionEditor.fromSnapshot(before);
        final sibling = FractionEditor.fromSnapshot(before);
        restored.moveToRootEnd();
        restored.insertText('+');
        restored.insertText('2');
        expect(restored.toExpression(), '((1)/(3))+2');
        expect(original.toExpression(), '((1)/(3))');
        expect(sibling.toExpression(), '((1)/(3))');
        expect(before.cursor.path.single.field, FractionField.denominator);
        expect(before.cursor.offset, 1);
        expect(restored.snapshot.cursor.path, isEmpty);
        expect(restored.snapshot.cursor.offset, 3);
      },
    );

    test('old snapshots and their Ans remain unchanged by later edits', () {
      final session = StructuredCalculatorSession();
      fraction(session, '1', '3');
      final first = session.press(CalculatorKey.equals);
      enter(session, '7');
      session.press(CalculatorKey.equals);
      expect(first.phase, CalculatorPhase.result);
      expect(first.answer.toString(), '1/3');
      expect(first.result.toString(), '1/3');
      expect(expression(first), '((1)/(3))');
      expect(session.snapshot.answer, Rational.fromInt(7));
      expect(() => first.editor.root.nodes.clear(), throwsUnsupportedError);
      expect(() => first.editor.cursor.path.clear(), throwsUnsupportedError);
      final node = first.editor.root.nodes.single as EditorFraction;
      expect(() => node.numerator.nodes.clear(), throwsUnsupportedError);
    });

    test('linear and separate structured sessions do not share Ans', () {
      final first = StructuredCalculatorSession();
      final second = StructuredCalculatorSession();
      final linear = CalculatorSession();
      enter(first, '9');
      first.press(CalculatorKey.equals);
      second.press(CalculatorKey.answer);
      expect(second.press(CalculatorKey.equals).result, Rational.fromInt(0));
      expect(linear.snapshot.answer, Rational.fromInt(0));
      expect(first.snapshot.answer, Rational.fromInt(9));
    });

    test('fraction command does not extend the linear enum or session', () {
      expect(CalculatorKey.values, hasLength(28));
      expect(CalculatorKey.fromId('KEY_FRACTION'), isNull);
      final linear = CalculatorSession();
      expect(
        () => linear.pressId('KEY_FRACTION'),
        throwsA(hasCode(CalculatorErrorCode.unsupported)),
      );
      final structured = StructuredCalculatorSession();
      expect(
        structured.pressId('KEY_FRACTION').editor.root.nodes.single,
        isA<EditorFraction>(),
      );
    });
  });

  group('structured input and evaluation', () {
    test(
      'fractions calculate exactly through numerator/denominator fields',
      () {
        final session = StructuredCalculatorSession();
        fraction(session, '2', '3');
        session.press(CalculatorKey.add);
        fraction(session, '1', '6');
        final result = session.press(CalculatorKey.equals);
        expect(result.phase, CalculatorPhase.result);
        expect(result.result.toString(), '5/6');
        expect(result.answer.toString(), '5/6');
        expect(result.error, isNull);
        expect(expression(result), '((2)/(3))+((1)/(6))');
      },
    );

    test('nested fraction remains in the denominator it was inserted into', () {
      final session = StructuredCalculatorSession();
      session.pressId('KEY_FRACTION');
      enter(session, '1');
      session.press(CalculatorKey.right);
      session.pressId('KEY_FRACTION');
      enter(session, '2');
      session.press(CalculatorKey.right);
      enter(session, '3');
      final before = session.snapshot;
      expect(before.editor.cursor.path, hasLength(2));
      final result = session.press(CalculatorKey.equals);
      expect(result.result.toString(), '3/2');
      expect(identical(result.editor, before.editor), isTrue);
    });

    test(
      'decimal comma and linear operators work inside structural fields',
      () {
        final session = StructuredCalculatorSession();
        fraction(session, '0,1+0,2', '2');
        expect(session.press(CalculatorKey.equals).result.toString(), '3/20');
      },
    );

    test('a negative fraction is grouped correctly as a power base', () {
      final session = StructuredCalculatorSession();
      fraction(session, '-1', '2');
      enter(session, '^2');
      expect(session.press(CalculatorKey.equals).result.toString(), '1/4');
    });

    test(
      'navigation and DEL use field boundaries rather than source offsets',
      () {
        final session = StructuredCalculatorSession();
        session.pressId('KEY_FRACTION');
        enter(session, '12');
        session.press(CalculatorKey.right);
        enter(session, '3');
        session.press(CalculatorKey.left);
        expect(session.snapshot.editor.cursor.offset, 0);
        session.press(CalculatorKey.delete);
        expect(expression(session.snapshot), '((12)/(3))');
        session.press(CalculatorKey.left);
        expect(
          session.snapshot.editor.cursor.path.single.field,
          FractionField.numerator,
        );
        expect(session.snapshot.editor.cursor.offset, 2);
        session.press(CalculatorKey.delete);
        expect(expression(session.snapshot), '((1)/(3))');
      },
    );

    test('Ans is one editor node and can be an exact numerator', () {
      final session = StructuredCalculatorSession();
      fraction(session, '1', '3');
      session.press(CalculatorKey.equals);
      session.pressId('KEY_FRACTION');
      session.press(CalculatorKey.answer);
      expect(session.snapshot.editor.cursor.offset, 1);
      final node = session.snapshot.editor.root.nodes.single as EditorFraction;
      expect(node.numerator.nodes, hasLength(1));
      session.press(CalculatorKey.right);
      enter(session, '2');
      expect(session.press(CalculatorKey.equals).result.toString(), '1/6');
    });
  });

  group('result transitions', () {
    final operations = <CalculatorKey, String>{
      CalculatorKey.add: '7/3',
      CalculatorKey.subtract: '-5/3',
      CalculatorKey.multiply: '2/3',
      CalculatorKey.divide: '1/6',
      CalculatorKey.power: '1/9',
    };
    for (final entry in operations.entries) {
      test('${entry.key.name} starts exact Ans continuation', () {
        final session = StructuredCalculatorSession();
        fraction(session, '1', '3');
        session.press(CalculatorKey.equals);
        final pending = session.press(entry.key);
        expect(pending.phase, CalculatorPhase.editing);
        expect(pending.editor.root.nodes, hasLength(2));
        expect((pending.editor.root.nodes.first as EditorText).text, 'Ans');
        expect(pending.editor.cursor.path, isEmpty);
        expect(pending.editor.cursor.offset, 2);
        expect(pending.answer.toString(), '1/3');
        expect(pending.result, isNull);
        expect(pending.error, isNull);
        enter(session, '2');
        expect(
          session.press(CalculatorKey.equals).result.toString(),
          entry.value,
        );
      });
    }

    for (final key in [
      CalculatorKey.digit7,
      CalculatorKey.decimal,
      CalculatorKey.leftParenthesis,
      CalculatorKey.rightParenthesis,
      CalculatorKey.negate,
      CalculatorKey.answer,
    ]) {
      test('${key.name} starts a fresh root after a result', () {
        final session = StructuredCalculatorSession();
        fraction(session, '1', '3');
        session.press(CalculatorKey.equals);
        final next = session.press(key);
        expect(next.editor.root.nodes, hasLength(1));
        expect((next.editor.root.nodes.single as EditorText).text, key.text);
        expect(next.editor.cursor.path, isEmpty);
        expect(next.editor.cursor.offset, 1);
        expect(next.phase, CalculatorPhase.editing);
        expect(next.answer.toString(), '1/3');
        expect(next.result, isNull);
      });
    }

    test(
      'fraction after result starts a fresh numerator and preserves Ans',
      () {
        final session = StructuredCalculatorSession();
        enter(session, '7');
        session.press(CalculatorKey.equals);
        final next = session.pressId('KEY_FRACTION');
        expect(next.editor.root.nodes.single, isA<EditorFraction>());
        expect(next.editor.cursor.path, hasLength(1));
        expect(next.editor.cursor.path.single.field, FractionField.numerator);
        expect(next.editor.cursor.offset, 0);
        expect(next.answer, Rational.fromInt(7));
        expect(next.result, isNull);
      },
    );

    for (final arrow in [CalculatorKey.left, CalculatorKey.right]) {
      test('first ${arrow.name} after result opens root end, not a field', () {
        final session = StructuredCalculatorSession();
        session.pressId('KEY_FRACTION');
        enter(session, '1');
        session.press(CalculatorKey.right);
        enter(session, '2');
        final success = session.press(CalculatorKey.equals);
        expect(success.editor.cursor.path, hasLength(1));
        final next = session.press(arrow);
        expect(next.phase, CalculatorPhase.editing);
        expect(next.editor.cursor.path, isEmpty);
        expect(next.editor.cursor.offset, 1);
        expect(next.result, isNull);
        expect(next.answer.toString(), '1/2');
        session.press(CalculatorKey.left);
        expect(session.snapshot.editor.cursor.path, hasLength(1));
        expect(
          session.snapshot.editor.cursor.path.single.field,
          FractionField.denominator,
        );
        expect(session.snapshot.editor.cursor.offset, 1);
      });
    }

    test(
      'DEL after result removes the last root node, not its denominator',
      () {
        final session = StructuredCalculatorSession();
        enter(session, '1+');
        session.pressId('KEY_FRACTION');
        enter(session, '1');
        session.press(CalculatorKey.right);
        enter(session, '2');
        session.press(CalculatorKey.equals);
        final next = session.press(CalculatorKey.delete);
        expect(expression(next), '1+');
        expect(next.editor.cursor.path, isEmpty);
        expect(next.editor.cursor.offset, 2);
        expect(next.answer.toString(), '3/2');
        expect(next.result, isNull);
      },
    );

    test('equals after result is a no-op, AC clears while preserving Ans', () {
      final session = StructuredCalculatorSession();
      fraction(session, '2', '3');
      final success = session.press(CalculatorKey.equals);
      expect(identical(session.press(CalculatorKey.equals), success), isTrue);
      final cleared = session.press(CalculatorKey.clear);
      expect(cleared.editor.root.nodes, isEmpty);
      expect(cleared.editor.cursor.path, isEmpty);
      expect(cleared.phase, CalculatorPhase.editing);
      expect(cleared.answer.toString(), '2/3');
      expect(cleared.result, isNull);
      expect(cleared.error, isNull);
      session.press(CalculatorKey.answer);
      expect(session.press(CalculatorKey.equals).result.toString(), '2/3');
    });
  });

  group('errors and atomic limits', () {
    test('an incomplete fraction is an error, not an empty-root no-op', () {
      final session = StructuredCalculatorSession();
      session.pressId('KEY_FRACTION');
      final before = session.snapshot.editor;
      final failure = session.press(CalculatorKey.equals);
      expect(failure.phase, CalculatorPhase.error);
      expect(failure.error?.code, CalculatorErrorCode.syntax);
      expect(failure.result, isNull);
      expect(identical(failure.editor, before), isTrue);
    });

    for (final arrow in [CalculatorKey.left, CalculatorKey.right]) {
      test('first ${arrow.name} after error preserves exact field cursor', () {
        final session = StructuredCalculatorSession();
        enter(session, '7');
        session.press(CalculatorKey.equals);
        session.pressId('KEY_FRACTION');
        enter(session, '1');
        session.press(CalculatorKey.right);
        enter(session, '0');
        final before = session.snapshot.editor;
        final failure = session.press(CalculatorKey.equals);
        expect(failure.error?.code, CalculatorErrorCode.math);
        expect(failure.answer, Rational.fromInt(7));
        expect(failure.result, isNull);
        final restored = session.press(arrow);
        expect(identical(restored.editor.root, before.root), isTrue);
        expect(restored.phase, CalculatorPhase.editing);
        expect(restored.error, isNull);
        expect(
          restored.editor.cursor.path.single.field,
          FractionField.denominator,
        );
        expect(restored.editor.cursor.offset, 1);
        session.press(CalculatorKey.delete);
        enter(session, '2');
        expect(session.press(CalculatorKey.equals).result.toString(), '1/2');
        expect(failure.phase, CalculatorPhase.error);
        expect(failure.error?.code, CalculatorErrorCode.math);
      });
    }

    test('other supported keys, including fraction, do not dismiss errors', () {
      final session = StructuredCalculatorSession();
      fraction(session, '1', '0');
      final failure = session.press(CalculatorKey.equals);
      for (final key in CalculatorKey.values.where(
        (key) =>
            key != CalculatorKey.clear &&
            key != CalculatorKey.left &&
            key != CalculatorKey.right,
      )) {
        expect(identical(session.press(key), failure), isTrue, reason: key.id);
      }
      expect(identical(session.pressId('KEY_FRACTION'), failure), isTrue);
      final cleared = session.press(CalculatorKey.clear);
      expect(cleared.phase, CalculatorPhase.editing);
      expect(cleared.editor.root.nodes, isEmpty);
      expect(cleared.error, isNull);
    });

    test('unsupported IDs never mutate editing, result or error state', () {
      final session = StructuredCalculatorSession();
      for (final phase in CalculatorPhase.values) {
        if (phase == CalculatorPhase.result) {
          enter(session, '5');
          session.press(CalculatorKey.equals);
        } else if (phase == CalculatorPhase.error) {
          fraction(session, '1', '0');
          session.press(CalculatorKey.equals);
        }
        final before = session.snapshot;
        expect(before.phase, phase);
        for (final id in ['', 'KEY_SHIFT', 'KEY_FRAC', 'unknown']) {
          expect(
            () => session.pressId(id),
            throwsA(hasCode(CalculatorErrorCode.unsupported)),
          );
          expect(identical(session.snapshot, before), isTrue);
        }
      }
    });

    test('node limit preserves the old tree, cursor and Ans atomically', () {
      final session = StructuredCalculatorSession();
      enter(session, '7');
      session.press(CalculatorKey.equals);
      session.press(CalculatorKey.clear);
      for (var index = 0; index < FractionEditor.maxNodes; index++) {
        session.press(CalculatorKey.digit1);
      }
      final maximum = session.snapshot.editor;
      final failure = session.pressId('KEY_FRACTION');
      expect(failure.phase, CalculatorPhase.error);
      expect(failure.error?.code, CalculatorErrorCode.limit);
      expect(identical(failure.editor, maximum), isTrue);
      expect(failure.answer, Rational.fromInt(7));
      final restored = session.press(CalculatorKey.left);
      expect(identical(restored.editor.root, maximum.root), isTrue);
      expect(restored.editor.cursor.offset, maximum.cursor.offset);
      session.press(CalculatorKey.delete);
      session.pressId('KEY_FRACTION');
      expect(session.snapshot.phase, CalculatorPhase.editing);
      expect(
        session.snapshot.editor.root.nodes,
        hasLength(FractionEditor.maxNodes),
      );
      expect(session.snapshot.editor.cursor.path, hasLength(1));
    });

    test('depth limit preserves the deepest field without cursor movement', () {
      final session = StructuredCalculatorSession();
      for (var index = 0; index < FractionEditor.maxDepth; index++) {
        session.pressId('KEY_FRACTION');
      }
      final deepest = session.snapshot.editor;
      final failure = session.pressId('KEY_FRACTION');
      expect(failure.phase, CalculatorPhase.error);
      expect(failure.error?.code, CalculatorErrorCode.limit);
      expect(identical(failure.editor, deepest), isTrue);
      final restored = session.press(CalculatorKey.right);
      expect(identical(restored.editor.root, deepest.root), isTrue);
      expect(restored.editor.cursor.path, hasLength(FractionEditor.maxDepth));
      expect(restored.editor.cursor.path.last.field, FractionField.numerator);
      expect(restored.editor.cursor.offset, 0);
    });

    test(
      'parser limits become session errors without discarding valid fields',
      () {
        final session = StructuredCalculatorSession();
        for (var index = 0; index < 70; index++) {
          fraction(session, '1', '1');
        }
        final before = session.snapshot.editor;
        final failure = session.press(CalculatorKey.equals);
        expect(failure.phase, CalculatorPhase.error);
        expect(failure.error?.code, CalculatorErrorCode.limit);
        expect(identical(failure.editor, before), isTrue);
        expect(failure.answer, Rational.fromInt(0));
      },
    );

    test('field-local unbalanced parentheses cannot escape the fraction', () {
      final session = StructuredCalculatorSession();
      fraction(session, '1)/(2', '3');
      final failure = session.press(CalculatorKey.equals);
      expect(failure.phase, CalculatorPhase.error);
      expect(failure.error?.code, CalculatorErrorCode.syntax);
      expect(failure.answer, Rational.fromInt(0));
    });
  });
}
