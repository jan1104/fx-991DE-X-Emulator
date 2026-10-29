import 'package:calculator_core/calculator_core.dart';
import 'package:test/test.dart';

void text(FractionEditor editor, String source) {
  for (final token in source.split('')) {
    editor.insertText(token);
  }
}

void enter(StructuredCalculatorSession session, String source) {
  for (final token in source.split('')) {
    session.pressId(switch (token) {
      '+' => 'KEY_ADD',
      '-' => 'KEY_SUBTRACT',
      '/' => 'KEY_DIVIDE',
      ',' => 'KEY_DECIMAL',
      _ => 'KEY_$token',
    });
  }
}

void at(EditorCursor cursor, List<(int, FractionField)> path, int offset) {
  expect([for (final step in cursor.path) (step.nodeIndex, step.field)], path);
  expect(cursor.offset, offset);
}

Matcher errorCode(CalculatorErrorCode code) => throwsA(
  isA<CalculatorException>().having((error) => error.code, 'code', code),
);

EditorFraction wrapped(FractionEditor editor, int index) =>
    editor.snapshot.root.nodes[index] as EditorFraction;

FractionEditor nested(int depth) {
  final editor = FractionEditor();
  for (var index = 0; index < depth; index++) {
    editor.insertFraction();
  }
  editor.insertText('1');
  for (var index = 0; index < depth; index++) {
    editor.moveRight();
    editor.insertText('1');
    editor.moveRight();
  }
  return editor;
}

void main() {
  group('explicit preceding atom capture', () {
    for (final (source, expected) in [
      ('123', '123/2'),
      ('0012', '6'),
      ('1.25', '5/8'),
      ('1,25', '5/8'),
      ('.5', '1/4'),
      (',5', '1/4'),
      ('1.', '1/2'),
      ('1,', '1/2'),
    ]) {
      test(
        'captures the full valid decimal $source without rewriting tokens',
        () {
          final editor = FractionEditor();
          text(editor, source);
          final before = editor.snapshot;
          editor.wrapPreviousAtomInFraction();
          final fraction = wrapped(editor, 0);
          expect(fraction.denominator.nodes, isEmpty);
          expect(
            fraction.numerator.nodes
                .map((node) => (node as EditorText).text)
                .join(),
            source,
          );
          for (var index = 0; index < source.length; index++) {
            expect(
              identical(
                fraction.numerator.nodes[index],
                before.root.nodes[index],
              ),
              isTrue,
            );
          }
          at(editor.snapshot.cursor, [(0, FractionField.denominator)], 0);
          expect(editor.snapshot.root.nodes, hasLength(1));
          expect(before.root.nodes, hasLength(source.length));
          editor.insertText('2');
          expect(editor.toExpression(), '(($source)/(2))');
          expect(editor.evaluate().toString(), expected);
        },
      );
    }

    test('captures Ans atomically and leaves following siblings in place', () {
      final editor = FractionEditor()..insertText('Ans');
      text(editor, '+2');
      editor.moveLeft();
      editor.moveLeft();
      final before = editor.snapshot;
      editor.wrapPreviousAtomInFraction();
      expect(wrapped(editor, 0).numerator.nodes, hasLength(1));
      expect(
        (wrapped(editor, 0).numerator.nodes.single as EditorText).text,
        'Ans',
      );
      expect(
        identical(
          wrapped(editor, 0).numerator.nodes.single,
          before.root.nodes.first,
        ),
        isTrue,
      );
      editor.insertText('2');
      expect(editor.toExpression(), '((Ans)/(2))+2');
      expect(editor.evaluate(answer: Rational.fromInt(6)), Rational.fromInt(5));
    });

    test('captures an entire existing fraction subtree as one atom', () {
      final editor = nested(1);
      final original = editor.snapshot;
      editor.wrapPreviousAtomInFraction();
      final outer = wrapped(editor, 0);
      expect(outer.numerator.nodes, hasLength(1));
      expect(
        identical(outer.numerator.nodes.single, original.root.nodes.single),
        isTrue,
      );
      editor.insertText('3');
      expect(editor.toExpression(), '((((1)/(1)))/(3))');
      expect(editor.evaluate().toString(), '1/3');
      expect(FractionEditor.fromSnapshot(original).toExpression(), '((1)/(1))');
    });

    test(
      'capture in the middle preserves operators and both sibling ranges',
      () {
        final editor = FractionEditor();
        text(editor, '12+34+56');
        for (var index = 0; index < 3; index++) {
          editor.moveLeft();
        }
        final before = editor.snapshot;
        editor.wrapPreviousAtomInFraction();
        at(editor.snapshot.cursor, [(3, FractionField.denominator)], 0);
        editor.insertText('2');
        expect(editor.toExpression(), '12+((34)/(2))+56');
        expect(editor.evaluate(), Rational.fromInt(85));
        expect(FractionEditor.fromSnapshot(before).toExpression(), '12+34+56');
      },
    );

    test('nested capture modifies only the current field', () {
      final editor = FractionEditor()..insertFraction();
      text(editor, '8');
      editor.moveDown();
      text(editor, '12');
      final before = editor.snapshot;
      editor.wrapPreviousAtomInFraction();
      at(editor.snapshot.cursor, [
        (0, FractionField.denominator),
        (0, FractionField.denominator),
      ], 0);
      editor.insertText('3');
      expect(editor.toExpression(), '((8)/(((12)/(3))))');
      expect(editor.evaluate(), Rational.fromInt(2));
      final oldOuter = before.root.nodes.single as EditorFraction;
      final newOuter = editor.snapshot.root.nodes.single as EditorFraction;
      expect(identical(oldOuter.numerator, newOuter.numerator), isTrue);
    });

    test('a preceding sign stays outside the captured positive number', () {
      final editor = FractionEditor();
      text(editor, '-12');
      editor.wrapPreviousAtomInFraction();
      expect((editor.snapshot.root.nodes.first as EditorText).text, '-');
      at(editor.snapshot.cursor, [(1, FractionField.denominator)], 0);
      editor.insertText('3');
      expect(editor.toExpression(), '-((12)/(3))');
      expect(editor.evaluate(), Rational.fromInt(-4));
    });

    test(
      'does not guess a whole power chain when its last number is selected',
      () {
        final editor = FractionEditor();
        text(editor, '2^3');
        editor.wrapPreviousAtomInFraction();
        at(editor.snapshot.cursor, [(2, FractionField.denominator)], 0);
        editor.insertText('1');
        expect(editor.toExpression(), '2^((3)/(1))');
        expect(editor.evaluate(), Rational.fromInt(8));
      },
    );
  });

  group('rejected capture is atomic', () {
    for (final source in ['', '+', '-', '*', '/', '^', '(']) {
      test('does not capture a predecessor from "$source"', () {
        final editor = FractionEditor();
        text(editor, source);
        final before = editor.snapshot;
        expect(
          editor.wrapPreviousAtomInFraction,
          errorCode(CalculatorErrorCode.unsupported),
        );
        expect(identical(editor.snapshot, before), isTrue);
      });
    }

    test(
      'offset zero inside a field does not capture a parent or ancestor',
      () {
        final editor = FractionEditor()..insertText('2');
        editor.insertFraction();
        final before = editor.snapshot;
        expect(
          editor.wrapPreviousAtomInFraction,
          errorCode(CalculatorErrorCode.unsupported),
        );
        expect(identical(editor.snapshot, before), isTrue);
      },
    );

    for (final source in ['.', ',', '1..2', '1,,2', '1.2,3', '1,2.3']) {
      test(
        'malformed contiguous decimal $source is syntax, not partial capture',
        () {
          final editor = FractionEditor();
          text(editor, source);
          final before = editor.snapshot;
          expect(
            editor.wrapPreviousAtomInFraction,
            errorCode(CalculatorErrorCode.syntax),
          );
          expect(identical(editor.snapshot, before), isTrue);
        },
      );
    }

    for (final (source, offset) in [('1234', 2), ('1,25', 2), ('.5', 1)]) {
      test(
        'cursor inside $source at $offset cannot split the numeric literal',
        () {
          final editor = FractionEditor();
          text(editor, source);
          while (editor.snapshot.cursor.offset > offset) {
            editor.moveLeft();
          }
          final before = editor.snapshot;
          expect(
            editor.wrapPreviousAtomInFraction,
            errorCode(CalculatorErrorCode.unsupported),
          );
          expect(identical(editor.snapshot, before), isTrue);
        },
      );
    }
  });

  group('capture resource budgets include every descendant', () {
    test(
      'capture adds exactly one node and accepts the last available node',
      () {
        final editor = FractionEditor();
        for (var index = 0; index < FractionEditor.maxNodes - 1; index++) {
          editor.insertText('1');
        }
        editor.wrapPreviousAtomInFraction();
        expect(
          wrapped(editor, 0).numerator.nodes,
          hasLength(FractionEditor.maxNodes - 1),
        );
        final maximum = editor.snapshot;
        expect(
          () => editor.insertText('2'),
          errorCode(CalculatorErrorCode.limit),
        );
        expect(identical(editor.snapshot, maximum), isTrue);
      },
    );

    test(
      'capture at full node capacity rejects without discarding the number',
      () {
        final editor = FractionEditor();
        for (var index = 0; index < FractionEditor.maxNodes; index++) {
          editor.insertText('1');
        }
        final before = editor.snapshot;
        expect(
          editor.wrapPreviousAtomInFraction,
          errorCode(CalculatorErrorCode.limit),
        );
        expect(identical(editor.snapshot, before), isTrue);
      },
    );

    test(
      'wrapping a root subtree at depth 15 reaches depth 16 successfully',
      () {
        final editor = nested(FractionEditor.maxDepth - 1);
        editor.wrapPreviousAtomInFraction();
        editor.insertText('1');
        expect(editor.evaluate(), Rational.fromInt(1));
      },
    );

    test(
      'wrapping root depth-16 subtree cannot hide its depth behind cursor0',
      () {
        final editor = nested(FractionEditor.maxDepth);
        final before = editor.snapshot;
        expect(before.cursor.path, isEmpty);
        expect(
          editor.wrapPreviousAtomInFraction,
          errorCode(CalculatorErrorCode.limit),
        );
        expect(identical(editor.snapshot, before), isTrue);
      },
    );

    test(
      'wrapping a nested subtree checks ancestors plus the entire subtree',
      () {
        final editor = nested(FractionEditor.maxDepth);
        editor.moveLeft();
        editor.moveLeft();
        editor.moveLeft();
        at(editor.snapshot.cursor, [(0, FractionField.numerator)], 1);
        final before = editor.snapshot;
        expect(
          editor.wrapPreviousAtomInFraction,
          errorCode(CalculatorErrorCode.limit),
        );
        expect(identical(editor.snapshot, before), isTrue);
      },
    );

    test(
      'a depth-16 branch elsewhere does not prevent shallow number capture',
      () {
        final editor = nested(FractionEditor.maxDepth);
        text(editor, '+2');
        editor.wrapPreviousAtomInFraction();
        at(editor.snapshot.cursor, [(2, FractionField.denominator)], 0);
        editor.insertText('1');
        expect(editor.evaluate(), Rational.fromInt(3));
      },
    );

    test('number capture at active depth16 cannot create level17', () {
      final editor = FractionEditor();
      for (var index = 0; index < FractionEditor.maxDepth; index++) {
        editor.insertFraction();
      }
      editor.insertText('1');
      final before = editor.snapshot;
      expect(
        editor.wrapPreviousAtomInFraction,
        errorCode(CalculatorErrorCode.limit),
      );
      expect(identical(editor.snapshot, before), isTrue);
    });
  });

  group('explicit structured-session app action', () {
    test(
      'action captures while editing, preserves Ans and is not a physical key',
      () {
        final session = StructuredCalculatorSession();
        enter(session, '7');
        session.press(CalculatorKey.equals);
        enter(session, '12');
        final before = session.snapshot;
        final wrapped = session.pressId('ACTION_WRAP_FRACTION');
        at(wrapped.editor.cursor, [(0, FractionField.denominator)], 0);
        expect(wrapped.phase, CalculatorPhase.editing);
        expect(wrapped.answer, Rational.fromInt(7));
        expect(wrapped.result, isNull);
        expect(wrapped.error, isNull);
        expect(wrapped.errorCursor, isNull);
        enter(session, '3');
        expect(session.press(CalculatorKey.equals).result, Rational.fromInt(4));
        expect(FractionEditor.fromSnapshot(before.editor).toExpression(), '12');
        expect(CalculatorKey.values, hasLength(26));
        expect(CalculatorKey.fromId('ACTION_WRAP_FRACTION'), isNull);
        expect(
          () => CalculatorSession().pressId('ACTION_WRAP_FRACTION'),
          errorCode(CalculatorErrorCode.unsupported),
        );
      },
    );

    test(
      'action after result is an identical no-op, not an implicit Ans capture',
      () {
        final session = StructuredCalculatorSession();
        enter(session, '12');
        final success = session.press(CalculatorKey.equals);
        expect(
          identical(session.pressId('ACTION_WRAP_FRACTION'), success),
          isTrue,
        );
      },
    );

    test(
      'action after error is an identical no-op preserving diagnostic target',
      () {
        final session = StructuredCalculatorSession();
        enter(session, '1/0');
        final failure = session.press(CalculatorKey.equals);
        expect(
          identical(session.pressId('ACTION_WRAP_FRACTION'), failure),
          isTrue,
        );
        expect(session.snapshot.error?.code, CalculatorErrorCode.math);
        expect(
          identical(session.snapshot.errorCursor, failure.errorCursor),
          isTrue,
        );
      },
    );

    for (final (source, code) in [
      ('', CalculatorErrorCode.unsupported),
      ('1+', CalculatorErrorCode.unsupported),
      ('1,,2', CalculatorErrorCode.syntax),
    ]) {
      test(
        'capture failure for "$source" retains tree, cursor and previous Ans',
        () {
          final session = StructuredCalculatorSession();
          enter(session, '7');
          session.press(CalculatorKey.equals);
          session.press(CalculatorKey.clear);
          enter(session, source);
          final before = session.snapshot;
          final failure = session.pressId('ACTION_WRAP_FRACTION');
          expect(failure.phase, CalculatorPhase.error);
          expect(failure.error?.code, code);
          expect(failure.result, isNull);
          expect(failure.answer, Rational.fromInt(7));
          expect(identical(failure.editor, before.editor), isTrue);
          expect(identical(failure.errorCursor, before.editor.cursor), isTrue);
          final recovered = session.pressId('KEY_UP');
          expect(recovered.phase, CalculatorPhase.editing);
          expect(recovered.error, isNull);
          expect(recovered.errorCursor, isNull);
        },
      );
    }

    test('session inside-number capture is unsupported and atomic', () {
      final session = StructuredCalculatorSession();
      enter(session, '1234');
      session.press(CalculatorKey.left);
      final before = session.snapshot.editor;
      final failure = session.pressId('ACTION_WRAP_FRACTION');
      expect(failure.error?.code, CalculatorErrorCode.unsupported);
      expect(identical(failure.editor, before), isTrue);
      at(failure.errorCursor!, [], 3);
    });

    test(
      'session capacity failure is a limit error with recoverable old input',
      () {
        final session = StructuredCalculatorSession();
        for (var index = 0; index < FractionEditor.maxNodes; index++) {
          session.press(CalculatorKey.digit1);
        }
        final before = session.snapshot.editor;
        final failure = session.pressId('ACTION_WRAP_FRACTION');
        expect(failure.error?.code, CalculatorErrorCode.limit);
        expect(identical(failure.editor, before), isTrue);
        session.press(CalculatorKey.right);
        session.press(CalculatorKey.delete);
        expect(
          session.pressId('ACTION_WRAP_FRACTION').phase,
          CalculatorPhase.editing,
        );
      },
    );
  });
}
