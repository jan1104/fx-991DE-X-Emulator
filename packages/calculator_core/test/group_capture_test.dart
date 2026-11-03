import 'package:calculator_core/calculator_core.dart';
import 'package:test/test.dart';

void text(FractionEditor editor, String source) {
  for (final token in source.split('')) {
    editor.insertText(token);
  }
}

void enter(StructuredCalculatorSession session, String source) {
  const ids = {
    '+': 'KEY_ADD',
    '-': 'KEY_SUBTRACT',
    '/': 'KEY_DIVIDE',
    '(': 'KEY_LPAREN',
    ')': 'KEY_RPAREN',
  };
  for (final token in source.split('')) {
    session.pressId(ids[token] ?? 'KEY_$token');
  }
}

void fraction(FractionEditor editor, String top, String bottom) {
  editor.insertFraction();
  text(editor, top);
  editor.moveRight();
  text(editor, bottom);
  editor.moveRight();
}

void appendNested(FractionEditor editor, int depth) {
  for (var index = 0; index < depth; index++) {
    editor.insertFraction();
  }
  editor.insertText('1');
  for (var index = 0; index < depth; index++) {
    editor.moveRight();
    editor.insertText('1');
    editor.moveRight();
  }
}

void at(EditorCursor cursor, List<(int, FractionField)> path, int offset) {
  expect([for (final step in cursor.path) (step.nodeIndex, step.field)], path);
  expect(cursor.offset, offset);
}

Matcher code(CalculatorErrorCode value) => throwsA(
  isA<CalculatorException>().having((error) => error.code, 'code', value),
);

void main() {
  group('closed group capture', () {
    for (final (source, expected) in [
      ('(12)', '4'),
      ('(1+2)', '1'),
      ('((1+2)*3)', '3'),
      ('((1)+(2))', '1'),
    ]) {
      test('captures $source including every parenthesis token', () {
        final editor = FractionEditor();
        text(editor, source);
        final before = editor.snapshot;
        editor.wrapPreviousAtomInFraction();
        final outer = editor.snapshot.root.nodes.single as EditorFraction;
        expect(outer.numerator.nodes.length, source.length);
        expect(outer.denominator.nodes, isEmpty);
        for (var index = 0; index < source.length; index++) {
          expect(
            identical(outer.numerator.nodes[index], before.root.nodes[index]),
            isTrue,
          );
        }
        at(editor.snapshot.cursor, [(0, FractionField.denominator)], 0);
        editor.insertText('3');
        expect(editor.toExpression(), '(($source)/(3))');
        expect(editor.evaluate().toString(), expected);
        expect(FractionEditor.fromSnapshot(before).toExpression(), source);
      });
    }

    test(
      'matching open is local to the final group rather than a preceding one',
      () {
        final editor = FractionEditor();
        text(editor, '(1)(2)');
        editor.wrapPreviousAtomInFraction();
        at(editor.snapshot.cursor, [(3, FractionField.denominator)], 0);
        editor.insertText('3');
        expect(editor.toExpression(), '(1)(((2))/(3))');
        expect(editor.evaluate().toString(), '2/3');
      },
    );

    test(
      'middle capture retains the exact prefix and multiplication suffix',
      () {
        final editor = FractionEditor();
        text(editor, '8+(2+4)*3');
        editor.moveLeft();
        editor.moveLeft();
        final before = editor.snapshot;
        editor.wrapPreviousAtomInFraction();
        at(editor.snapshot.cursor, [(2, FractionField.denominator)], 0);
        editor.insertText('2');
        expect(editor.toExpression(), '8+(((2+4))/(2))*3');
        expect(editor.evaluate(), Rational.fromInt(17));
        expect(FractionEditor.fromSnapshot(before).toExpression(), '8+(2+4)*3');
      },
    );

    test('leading minus remains outside the captured group', () {
      final editor = FractionEditor();
      text(editor, '-(1+2)');
      editor.wrapPreviousAtomInFraction();
      at(editor.snapshot.cursor, [(1, FractionField.denominator)], 0);
      editor.insertText('3');
      expect(editor.toExpression(), '-(((1+2))/(3))');
      expect(editor.evaluate(), Rational.fromInt(-1));
    });

    test('power chain is not taken along with its last parenthesized atom', () {
      final editor = FractionEditor();
      text(editor, '2^(1+2)');
      editor.wrapPreviousAtomInFraction();
      at(editor.snapshot.cursor, [(2, FractionField.denominator)], 0);
      editor.insertText('3');
      expect(editor.toExpression(), '2^(((1+2))/(3))');
      expect(editor.evaluate(), Rational.fromInt(2));
    });

    test('nested field capture leaves its ancestor numerator untouched', () {
      final editor = FractionEditor()..insertFraction();
      text(editor, '8');
      editor.moveDown();
      text(editor, '(1+3)');
      final before = editor.snapshot;
      editor.wrapPreviousAtomInFraction();
      at(editor.snapshot.cursor, [
        (0, FractionField.denominator),
        (0, FractionField.denominator),
      ], 0);
      editor.insertText('2');
      expect(editor.toExpression(), '((8)/((((1+3))/(2))))');
      expect(editor.evaluate(), Rational.fromInt(4));
      expect(
        identical(
          (before.root.nodes.single as EditorFraction).numerator,
          (editor.snapshot.root.nodes.single as EditorFraction).numerator,
        ),
        isTrue,
      );
    });

    test(
      'Ans inside a group remains one node and is not evaluated during capture',
      () {
        final editor = FractionEditor()..insertText('(');
        editor.insertText('Ans');
        text(editor, '+1)');
        editor.wrapPreviousAtomInFraction();
        final numerator =
            (editor.snapshot.root.nodes.single as EditorFraction).numerator;
        expect(numerator.nodes, hasLength(5));
        expect((numerator.nodes[1] as EditorText).text, 'Ans');
        editor.insertText('2');
        expect(
          editor.evaluate(answer: Rational.fromInt(7)),
          Rational.fromInt(4),
        );
      },
    );

    test(
      'fraction fields do not participate in the surrounding group scan',
      () {
        final editor = FractionEditor()..insertText('(');
        fraction(editor, '1)', '(2');
        editor.insertText(')');
        final before = editor.snapshot;
        editor.wrapPreviousAtomInFraction();
        final outer = editor.snapshot.root.nodes.single as EditorFraction;
        expect(
          identical(outer.numerator.nodes[1], before.root.nodes[1]),
          isTrue,
        );
        // Capture is structural; the invalid inner fraction is diagnosed later.
        editor.insertText('3');
        expect(editor.toExpression, code(CalculatorErrorCode.syntax));
        expect(
          FractionEditor.fromSnapshot(before).toExpression,
          code(CalculatorErrorCode.syntax),
        );
      },
    );

    test(
      'balanced but incomplete arithmetic stays structurally capturable',
      () {
        final editor = FractionEditor();
        text(editor, '(1+)');
        editor.wrapPreviousAtomInFraction();
        editor.insertText('2');
        expect(editor.toExpression(), '(((1+))/(2))');
        expect(editor.evaluate, code(CalculatorErrorCode.syntax));
      },
    );

    test('a group with an operator is not classified as entirely empty', () {
      final editor = FractionEditor();
      text(editor, '(+)');
      editor.wrapPreviousAtomInFraction();
      editor.insertText('2');
      expect(editor.toExpression(), '(((+))/(2))');
      expect(editor.evaluate, code(CalculatorErrorCode.syntax));
    });
  });

  group('group diagnostics are atomic and field-local', () {
    for (final source in [')', '1)', '(1))', '())', '(()))']) {
      test('unmatched final closing parenthesis in $source is syntax', () {
        final editor = FractionEditor();
        text(editor, source);
        final before = editor.snapshot;
        expect(
          editor.wrapPreviousAtomInFraction,
          code(CalculatorErrorCode.syntax),
        );
        expect(identical(editor.snapshot, before), isTrue);
      });
    }

    for (final source in ['()', '(())', '((()))', '(()())']) {
      test('parentheses-only group $source has no capturable content', () {
        final editor = FractionEditor();
        text(editor, source);
        final before = editor.snapshot;
        expect(
          editor.wrapPreviousAtomInFraction,
          code(CalculatorErrorCode.syntax),
        );
        expect(identical(editor.snapshot, before), isTrue);
      });
    }

    test(
      'a closing parenthesis cannot find its opening in an ancestor field',
      () {
        final editor = FractionEditor()..insertText('(');
        editor.insertFraction();
        editor.insertText(')');
        final before = editor.snapshot;
        expect(
          editor.wrapPreviousAtomInFraction,
          code(CalculatorErrorCode.syntax),
        );
        expect(identical(editor.snapshot, before), isTrue);
      },
    );

    test('closed subgroup capture does not require the entire field to be balanced', () {
      final editor = FractionEditor();
      text(editor, ')(1)');
      editor.wrapPreviousAtomInFraction();
      at(editor.snapshot.cursor, [(1, FractionField.denominator)], 0);
      editor.insertText('2');
      expect(editor.toExpression, code(CalculatorErrorCode.syntax));
    });

    test('cursor inside numeric literal remains unsupported', () {
      final editor = FractionEditor();
      text(editor, '(12)+345');
      editor.moveLeft();
      final before = editor.snapshot;
      expect(
        editor.wrapPreviousAtomInFraction,
        code(CalculatorErrorCode.unsupported),
      );
      expect(identical(editor.snapshot, before), isTrue);
    });
  });

  group('whole candidate resource limits', () {
    test('group capture uses exactly one additional node', () {
      final editor = FractionEditor()..insertText('(');
      for (var index = 0; index < FractionEditor.maxNodes - 3; index++) {
        editor.insertText('1');
      }
      editor.insertText(')');
      editor.wrapPreviousAtomInFraction();
      expect(
        (editor.snapshot.root.nodes.single as EditorFraction).numerator.nodes,
        hasLength(FractionEditor.maxNodes - 1),
      );
      final maximum = editor.snapshot;
      expect(() => editor.insertText('2'), code(CalculatorErrorCode.limit));
      expect(identical(editor.snapshot, maximum), isTrue);
    });

    test(
      'node budget rejects full-capacity group capture without mutation',
      () {
        final editor = FractionEditor()..insertText('(');
        for (var index = 0; index < FractionEditor.maxNodes - 2; index++) {
          editor.insertText('1');
        }
        editor.insertText(')');
        final before = editor.snapshot;
        expect(
          editor.wrapPreviousAtomInFraction,
          code(CalculatorErrorCode.limit),
        );
        expect(identical(editor.snapshot, before), isTrue);
      },
    );

    for (final depth in [
      FractionEditor.maxDepth - 1,
      FractionEditor.maxDepth,
    ]) {
      test(
        'closed group containing depth$depth subtree obeys global max16',
        () {
          final editor = FractionEditor()..insertText('(');
          appendNested(editor, depth);
          editor.insertText(')');
          final before = editor.snapshot;
          if (depth == FractionEditor.maxDepth) {
            expect(
              editor.wrapPreviousAtomInFraction,
              code(CalculatorErrorCode.limit),
            );
            expect(identical(editor.snapshot, before), isTrue);
          } else {
            editor.wrapPreviousAtomInFraction();
            editor.insertText('1');
            expect(editor.evaluate(), Rational.fromInt(1));
          }
        },
      );
    }

    test('group capture at active level16 cannot create level17', () {
      final editor = FractionEditor();
      for (var index = 0; index < FractionEditor.maxDepth; index++) {
        editor.insertFraction();
      }
      text(editor, '(1)');
      final before = editor.snapshot;
      expect(
        editor.wrapPreviousAtomInFraction,
        code(CalculatorErrorCode.limit),
      );
      expect(identical(editor.snapshot, before), isTrue);
    });

    test(
      'unrelated depth16 sibling does not prevent shallow group capture',
      () {
        final editor = FractionEditor();
        appendNested(editor, FractionEditor.maxDepth);
        text(editor, '+(2)');
        editor.wrapPreviousAtomInFraction();
        editor.insertText('1');
        expect(editor.evaluate(), Rational.fromInt(3));
      },
    );
  });

  group('reparented source map and immutable state', () {
    test('inner generated division maps through the new parent numerator', () {
      final editor = FractionEditor()..insertText('(');
      fraction(editor, '1', '0');
      text(editor, '+2)');
      final before = editor.snapshot;
      final oldProjection = editor.project();
      at(oldProjection.cursorAt(5), [(1, FractionField.denominator)], 1);
      editor.wrapPreviousAtomInFraction();
      editor.insertText('3');
      final projectedSnapshot = editor.snapshot;
      final projection = editor.project();
      expect(projection.expression, '(((((1)/(0))+2))/(3))');
      final target = projection.cursorAt(7);
      at(target, [
        (0, FractionField.numerator),
        (1, FractionField.denominator),
      ], 1);
      at(projection.cursorAt(16), [(0, FractionField.denominator)], 1);
      editor.moveTo(target);
      editor.deleteBackward();
      editor.insertText('2');
      expect(editor.evaluate().toString(), '5/6');
      expect(oldProjection.expression, '(((1)/(0))+2)');
      expect(
        FractionEditor.fromSnapshot(before).toExpression(),
        '(((1)/(0))+2)',
      );
      expect(() => target.path.clear(), throwsUnsupportedError);
      for (var offset = 0; offset <= projection.expression.length; offset++) {
        final restored = FractionEditor.fromSnapshot(projectedSnapshot);
        restored.moveTo(projection.cursorAt(offset));
        expect(
          identical(restored.snapshot.root, projectedSnapshot.root),
          isTrue,
        );
      }
    });
  });

  group('session group action', () {
    test('captures without premature evaluation or Ans changes', () {
      final session = StructuredCalculatorSession();
      enter(session, '7');
      session.press(CalculatorKey.equals);
      enter(session, '(1+)');
      final before = session.snapshot;
      final captured = session.pressId('ACTION_WRAP_FRACTION');
      expect(captured.phase, CalculatorPhase.editing);
      expect(captured.answer, Rational.fromInt(7));
      expect(captured.error, isNull);
      expect(captured.errorCursor, isNull);
      at(captured.editor.cursor, [(0, FractionField.denominator)], 0);
      enter(session, '2');
      final failure = session.press(CalculatorKey.equals);
      expect(failure.error?.code, CalculatorErrorCode.syntax);
      expect(failure.answer, Rational.fromInt(7));
      at(failure.errorCursor!, [(0, FractionField.numerator)], 3);
      expect(FractionEditor.fromSnapshot(before.editor).toExpression(), '(1+)');
    });

    test(
      'group action builds an exact fraction and still does not change keys',
      () {
        final session = StructuredCalculatorSession();
        enter(session, '(1+2)');
        session.pressId('ACTION_WRAP_FRACTION');
        enter(session, '6');
        final success = session.press(CalculatorKey.equals);
        expect(success.result.toString(), '1/2');
        expect(CalculatorKey.values, hasLength(32));
        expect(CalculatorKey.fromId('ACTION_WRAP_FRACTION'), isNull);
        expect(
          identical(session.pressId('ACTION_WRAP_FRACTION'), success),
          isTrue,
        );
      },
    );

    for (final source in [')', '()', '(())']) {
      test(
        'invalid group $source produces recoverable syntax and preserves Ans',
        () {
          final session = StructuredCalculatorSession();
          enter(session, '7');
          session.press(CalculatorKey.equals);
          enter(session, source);
          final before = session.snapshot.editor;
          final failure = session.pressId('ACTION_WRAP_FRACTION');
          expect(failure.phase, CalculatorPhase.error);
          expect(failure.error?.code, CalculatorErrorCode.syntax);
          expect(failure.answer, Rational.fromInt(7));
          expect(identical(failure.editor, before), isTrue);
          expect(
            identical(session.pressId('ACTION_WRAP_FRACTION'), failure),
            isTrue,
          );
          final restored = session.pressId('KEY_DOWN');
          expect(restored.phase, CalculatorPhase.editing);
          expect(restored.error, isNull);
          expect(restored.errorCursor, isNull);
          at(restored.editor.cursor, [], source.length);
        },
      );
    }
  });
}
