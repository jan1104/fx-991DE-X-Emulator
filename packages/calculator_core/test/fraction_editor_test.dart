import 'package:calculator_core/calculator_core.dart';
import 'package:test/test.dart';

// These cases specify the independent prototype editor contract. They are not
// observations of the original calculator's natural-input cursor behaviour.
void write(FractionEditor editor, String text) {
  for (final character in text.split('')) {
    editor.insertText(character);
  }
}

void appendFraction(
  FractionEditor editor,
  String numerator,
  String denominator,
) {
  editor.insertFraction();
  write(editor, numerator);
  editor.moveRight();
  write(editor, denominator);
  editor.moveRight();
}

List<Object> tree(EditorSequence sequence) => [
  for (final node in sequence.nodes)
    switch (node) {
      EditorText(:final text) => {'text': text},
      EditorAbsolute(:final argument) => {'absolute': tree(argument)},
      EditorFraction(:final numerator, :final denominator) => {
        'numerator': tree(numerator),
        'denominator': tree(denominator),
      },
    },
];

Object stateOf(FractionEditorSnapshot snapshot) => {
  'tree': tree(snapshot.root),
  'path': [
    for (final step in snapshot.cursor.path) (step.nodeIndex, step.field),
  ],
  'offset': snapshot.cursor.offset,
};

void expectCursor(
  FractionEditor editor,
  int offset, [
  List<(int, FractionField)> path = const [],
]) {
  expect(editor.snapshot.cursor.offset, offset);
  expect([
    for (final step in editor.snapshot.cursor.path)
      (step.nodeIndex, step.field),
  ], path);
}

Matcher calculatorError(CalculatorErrorCode code) => throwsA(
  isA<CalculatorException>().having((error) => error.code, 'code', code),
);

void main() {
  group('nodes and immutable snapshots', () {
    test('starts with an empty root and a root cursor at zero', () {
      final editor = FractionEditor();
      expect(editor.snapshot.root.nodes, isEmpty);
      expectCursor(editor, 0);
    });

    final accepted = [
      for (var digit = 0; digit <= 9; digit++) '$digit',
      '+',
      '-',
      '*',
      '/',
      '^',
      '(',
      ')',
      ',',
      '.',
      'Ans',
    ];
    for (final token in accepted) {
      test('accepts exactly the text token "$token" as one node', () {
        final editor = FractionEditor();
        editor.insertText(token);
        expect(editor.snapshot.root.nodes, hasLength(1));
        expect((editor.snapshot.root.nodes.single as EditorText).text, token);
        expectCursor(editor, 1);
      });
    }

    for (final invalid in [
      '',
      '12',
      '1+2',
      'ans',
      'ANS',
      ' Ans',
      'Ans ',
      'sin',
      '√',
      '−',
      '@',
      '\n',
      ' ',
    ]) {
      test('rejects "$invalid" atomically inside a fraction field', () {
        final editor = FractionEditor();
        editor.insertFraction();
        editor.insertText('7');
        editor.moveLeft();
        final before = stateOf(editor.snapshot);
        expect(() => editor.insertText(invalid), throwsArgumentError);
        expect(stateOf(editor.snapshot), before);
      });
    }

    test('creating a fraction enters its empty numerator', () {
      final editor = FractionEditor();
      editor.insertFraction();
      final fraction = editor.snapshot.root.nodes.single as EditorFraction;
      expect(fraction.numerator.nodes, isEmpty);
      expect(fraction.denominator.nodes, isEmpty);
      expectCursor(editor, 0, [(0, FractionField.numerator)]);
    });

    test('previous trees and cursors do not change after edits or clear', () {
      final editor = FractionEditor();
      final empty = editor.snapshot;
      editor.insertFraction();
      final template = editor.snapshot;
      final templateState = stateOf(template);
      write(editor, '12');
      final numerator = editor.snapshot;
      final numeratorState = stateOf(numerator);
      editor.moveRight();
      editor.insertText('3');
      editor.clear();
      expect(empty.root.nodes, isEmpty);
      expect(empty.cursor.path, isEmpty);
      expect(empty.cursor.offset, 0);
      expect(stateOf(template), templateState);
      expect(stateOf(numerator), numeratorState);
      expect(editor.snapshot.root.nodes, isEmpty);
      expectCursor(editor, 0);
    });

    test('root nodes, nested nodes, and cursor paths are unmodifiable', () {
      final editor = FractionEditor();
      editor.insertFraction();
      editor.insertText('1');
      final snapshot = editor.snapshot;
      final fraction = snapshot.root.nodes.single as EditorFraction;
      expect(() => snapshot.root.nodes.clear(), throwsUnsupportedError);
      expect(
        () => snapshot.root.nodes[0] = snapshot.root.nodes[0],
        throwsUnsupportedError,
      );
      expect(() => fraction.numerator.nodes.clear(), throwsUnsupportedError);
      expect(() => fraction.denominator.nodes.clear(), throwsUnsupportedError);
      expect(() => snapshot.cursor.path.clear(), throwsUnsupportedError);
      expect(
        () => snapshot.cursor.path[0] = snapshot.cursor.path[0],
        throwsUnsupportedError,
      );
      expectCursor(editor, 1, [(0, FractionField.numerator)]);
      expect((fraction.numerator.nodes.single as EditorText).text, '1');
    });

    test('each editor owns its state independently', () {
      final first = FractionEditor();
      final second = FractionEditor();
      appendFraction(first, '1', '2');
      expect(second.snapshot.root.nodes, isEmpty);
      expectCursor(second, 0);
      second.insertText('8');
      expect(first.toExpression(), '((1)/(2))');
      expect(second.toExpression(), '8');
    });
  });

  group('depth-first cursor movement and deletion', () {
    test('moves through numerator and denominator between root siblings', () {
      final editor = FractionEditor();
      editor.insertText('1');
      appendFraction(editor, '2', '3');
      editor.insertText('4');
      expectCursor(editor, 3);
      editor.moveLeft();
      expectCursor(editor, 2);
      editor.moveLeft();
      expectCursor(editor, 1, [(1, FractionField.denominator)]);
      editor.moveLeft();
      expectCursor(editor, 0, [(1, FractionField.denominator)]);
      editor.moveLeft();
      expectCursor(editor, 1, [(1, FractionField.numerator)]);
      editor.moveLeft();
      expectCursor(editor, 0, [(1, FractionField.numerator)]);
      editor.moveLeft();
      expectCursor(editor, 1);
      editor.moveLeft();
      editor.moveLeft();
      expectCursor(editor, 0);

      editor.moveRight();
      expectCursor(editor, 1);
      editor.moveRight();
      expectCursor(editor, 0, [(1, FractionField.numerator)]);
      editor.moveRight();
      expectCursor(editor, 1, [(1, FractionField.numerator)]);
      editor.moveRight();
      expectCursor(editor, 0, [(1, FractionField.denominator)]);
      editor.moveRight();
      expectCursor(editor, 1, [(1, FractionField.denominator)]);
      editor.moveRight();
      expectCursor(editor, 2);
      editor.moveRight();
      editor.moveRight();
      expectCursor(editor, 3);
    });

    test('empty fields remain separate navigable positions', () {
      final editor = FractionEditor();
      editor.insertFraction();
      expectCursor(editor, 0, [(0, FractionField.numerator)]);
      editor.moveRight();
      expectCursor(editor, 0, [(0, FractionField.denominator)]);
      editor.moveRight();
      expectCursor(editor, 1);
      editor.moveLeft();
      expectCursor(editor, 0, [(0, FractionField.denominator)]);
      editor.moveLeft();
      expectCursor(editor, 0, [(0, FractionField.numerator)]);
      editor.moveLeft();
      expectCursor(editor, 0);
    });

    test('nested traversal preserves every parent index and field', () {
      final editor = FractionEditor();
      editor.insertFraction();
      editor.insertText('1');
      appendFraction(editor, '2', '3');
      editor.insertText('4');
      expectCursor(editor, 3, [(0, FractionField.numerator)]);
      editor.moveLeft();
      editor.moveLeft();
      expectCursor(editor, 1, [
        (0, FractionField.numerator),
        (1, FractionField.denominator),
      ]);
      editor.moveLeft();
      editor.moveLeft();
      expectCursor(editor, 1, [
        (0, FractionField.numerator),
        (1, FractionField.numerator),
      ]);
      editor.moveLeft();
      editor.moveLeft();
      expectCursor(editor, 1, [(0, FractionField.numerator)]);
      editor.moveRight();
      expectCursor(editor, 0, [
        (0, FractionField.numerator),
        (1, FractionField.numerator),
      ]);
    });

    test(
      'insertion and deletion at a middle cursor affect the adjacent node',
      () {
        final editor = FractionEditor();
        write(editor, '123');
        editor.moveLeft();
        editor.moveLeft();
        editor.insertText('4');
        expect(editor.toExpression(), '1423');
        expectCursor(editor, 2);
        editor.deleteBackward();
        expect(editor.toExpression(), '123');
        expectCursor(editor, 1);
      },
    );

    test('Ans occupies one cursor step and deletes without partial text', () {
      final editor = FractionEditor();
      editor.insertText('1');
      editor.insertText('+');
      editor.insertText('Ans');
      expectCursor(editor, 3);
      expect(editor.snapshot.root.nodes, hasLength(3));
      editor.moveLeft();
      expectCursor(editor, 2);
      editor.moveRight();
      editor.deleteBackward();
      expect(editor.toExpression(), '1+');
      expectCursor(editor, 2);
    });

    test('deleting after a fraction removes the entire fraction node', () {
      final editor = FractionEditor();
      editor.insertText('8');
      appendFraction(editor, '1', '2');
      final before = editor.snapshot;
      editor.deleteBackward();
      expect(editor.toExpression(), '8');
      expectCursor(editor, 1);
      expect(before.root.nodes, hasLength(2));
      expect(before.root.nodes.last, isA<EditorFraction>());
    });

    test('deleting at any field start is a no-op rather than a merge', () {
      final editor = FractionEditor();
      editor.insertFraction();
      var before = stateOf(editor.snapshot);
      editor.deleteBackward();
      expect(stateOf(editor.snapshot), before);
      editor.insertText('7');
      editor.moveRight();
      before = stateOf(editor.snapshot);
      editor.deleteBackward();
      expect(stateOf(editor.snapshot), before);
      editor.insertFraction();
      before = stateOf(editor.snapshot);
      editor.deleteBackward();
      expect(stateOf(editor.snapshot), before);
    });

    test('deleting the last field digit leaves the template in place', () {
      final editor = FractionEditor();
      editor.insertFraction();
      editor.insertText('7');
      editor.deleteBackward();
      expectCursor(editor, 0, [(0, FractionField.numerator)]);
      expect(editor.snapshot.root.nodes, hasLength(1));
      final fraction = editor.snapshot.root.nodes.single as EditorFraction;
      expect(fraction.numerator.nodes, isEmpty);
      expect(fraction.denominator.nodes, isEmpty);
    });

    test(
      'root boundaries are stable and clear resets a deeply nested cursor',
      () {
        final editor = FractionEditor();
        editor.moveLeft();
        editor.moveRight();
        editor.deleteBackward();
        expectCursor(editor, 0);
        editor.insertFraction();
        editor.insertFraction();
        editor.insertText('9');
        editor.clear();
        expect(editor.snapshot.root.nodes, isEmpty);
        expectCursor(editor, 0);
      },
    );
  });

  group('serialization and exact fraction evaluation', () {
    test('serializes each fraction with grouped numerator and denominator', () {
      final editor = FractionEditor();
      appendFraction(editor, '1+2', '3+4');
      expect(editor.toExpression(), '((1+2)/(3+4))');
      expect(editor.evaluate().toString(), '3/7');
    });

    test('adds one third and one sixth exactly', () {
      final editor = FractionEditor();
      appendFraction(editor, '1', '3');
      editor.insertText('+');
      appendFraction(editor, '1', '6');
      expect(editor.toExpression(), '((1)/(3))+((1)/(6))');
      expect(editor.evaluate().toString(), '1/2');
    });

    test(
      'fraction grouping preserves surrounding multiplication and power',
      () {
        final editor = FractionEditor();
        write(editor, '3*');
        appendFraction(editor, '1+1', '2+2');
        write(editor, '^2');
        expect(editor.evaluate().toString(), '3/4');
      },
    );

    test('supports a denominator that is itself a fraction', () {
      final editor = FractionEditor();
      editor.insertFraction();
      editor.insertText('1');
      editor.moveRight();
      appendFraction(editor, '2', '3');
      editor.moveRight();
      expect(editor.toExpression(), '((1)/(((2)/(3))))');
      expect(editor.evaluate().toString(), '3/2');
    });

    test(
      'evaluates signed decimals without passing through floating point',
      () {
        final editor = FractionEditor();
        appendFraction(editor, '-0,1', '0.2');
        expect(editor.evaluate().toString(), '-1/2');
      },
    );

    test(
      'Ans uses the supplied exact answer without textual precedence loss',
      () {
        final editor = FractionEditor();
        editor.insertFraction();
        editor.insertText('Ans');
        write(editor, '^2');
        editor.moveRight();
        editor.insertText('2');
        expect(
          editor
              .evaluate(answer: Rational(BigInt.from(-1), BigInt.two))
              .toString(),
          '1/8',
        );
        expect(editor.evaluate(answer: Rational.fromInt(3)).toString(), '9/2');
      },
    );

    test('successful serialization and evaluation never move the cursor', () {
      final editor = FractionEditor();
      appendFraction(editor, '1', '2');
      editor.moveLeft();
      final before = stateOf(editor.snapshot);
      expect(editor.toExpression(), '((1)/(2))');
      expect(editor.evaluate().toString(), '1/2');
      expect(stateOf(editor.snapshot), before);
    });

    test('a completely empty root cannot be serialized or evaluated', () {
      final editor = FractionEditor();
      expect(editor.toExpression, calculatorError(CalculatorErrorCode.syntax));
      expect(editor.evaluate, calculatorError(CalculatorErrorCode.syntax));
      expect(editor.snapshot.root.nodes, isEmpty);
      expectCursor(editor, 0);
    });

    for (final field in FractionField.values) {
      test(
        'empty ${field.name} is a structured syntax error without mutation',
        () {
          final editor = FractionEditor();
          if (field == FractionField.argument) {
            editor.insertAbsolute();
          } else {
            editor.insertFraction();
            if (field == FractionField.numerator) {
              editor.moveRight();
              editor.insertText('2');
            } else {
              editor.insertText('1');
            }
          }
          final before = stateOf(editor.snapshot);
          expect(
            editor.toExpression,
            calculatorError(CalculatorErrorCode.syntax),
          );
          expect(editor.evaluate, calculatorError(CalculatorErrorCode.syntax));
          expect(stateOf(editor.snapshot), before);
        },
      );
    }

    test('nested empty fields cannot be hidden by filled outer sequences', () {
      final editor = FractionEditor();
      editor.insertFraction();
      editor.insertText('1');
      editor.moveRight();
      editor.insertFraction();
      editor.insertText('2');
      final before = stateOf(editor.snapshot);
      expect(editor.toExpression, calculatorError(CalculatorErrorCode.syntax));
      expect(editor.evaluate, calculatorError(CalculatorErrorCode.syntax));
      expect(stateOf(editor.snapshot), before);
    });

    test(
      'zero denominator propagates a math error without destroying input',
      () {
        final editor = FractionEditor();
        appendFraction(editor, '1', '2-2');
        final before = stateOf(editor.snapshot);
        expect(editor.evaluate, calculatorError(CalculatorErrorCode.math));
        expect(stateOf(editor.snapshot), before);
      },
    );

    test(
      'invalid mathematics remains distinct from a structurally empty field',
      () {
        final editor = FractionEditor();
        appendFraction(editor, '1+', '2');
        expect(editor.toExpression(), '((1+)/(2))');
        final before = stateOf(editor.snapshot);
        expect(editor.evaluate, calculatorError(CalculatorErrorCode.syntax));
        expect(stateOf(editor.snapshot), before);
      },
    );

    for (final fields in [('1)', '(2'), ('1)/(2', '3')]) {
      test(
        'parentheses cannot escape fraction fields ${fields.$1}/${fields.$2}',
        () {
          final editor = FractionEditor();
          appendFraction(editor, fields.$1, fields.$2);
          final before = stateOf(editor.snapshot);
          expect(
            editor.toExpression,
            calculatorError(CalculatorErrorCode.syntax),
          );
          expect(editor.evaluate, calculatorError(CalculatorErrorCode.syntax));
          expect(stateOf(editor.snapshot), before);
        },
      );
    }
  });

  group('atomic resource budgets', () {
    test('accepts 256 text nodes and atomically rejects text node 257', () {
      final editor = FractionEditor();
      for (var i = 0; i < 256; i++) {
        editor.insertText('0');
      }
      expect(editor.snapshot.root.nodes, hasLength(256));
      expectCursor(editor, 256);
      final maximum = editor.snapshot;
      final before = stateOf(maximum);
      expect(
        () => editor.insertText('1'),
        calculatorError(CalculatorErrorCode.limit),
      );
      expect(stateOf(editor.snapshot), before);
      expect(stateOf(maximum), before);
      editor.deleteBackward();
      editor.insertText('1');
      expect(editor.snapshot.root.nodes, hasLength(256));
      expect((editor.snapshot.root.nodes.last as EditorText).text, '1');
    });

    test('a fraction counts as one node even when its fields are empty', () {
      final editor = FractionEditor();
      for (var i = 0; i < 255; i++) {
        editor.insertText('0');
      }
      editor.insertFraction();
      expect(editor.snapshot.root.nodes, hasLength(256));
      expectCursor(editor, 0, [(255, FractionField.numerator)]);
      final before = stateOf(editor.snapshot);
      expect(
        () => editor.insertText('1'),
        calculatorError(CalculatorErrorCode.limit),
      );
      expect(stateOf(editor.snapshot), before);
    });

    test('node budget includes nested field nodes and atomic Ans tokens', () {
      final editor = FractionEditor();
      editor.insertFraction();
      for (var i = 0; i < 255; i++) {
        editor.insertText('Ans');
      }
      final fraction = editor.snapshot.root.nodes.single as EditorFraction;
      expect(fraction.numerator.nodes, hasLength(255));
      final before = stateOf(editor.snapshot);
      expect(
        () => editor.insertText('2'),
        calculatorError(CalculatorErrorCode.limit),
      );
      expect(stateOf(editor.snapshot), before);
      editor.moveRight();
      final denominatorBefore = stateOf(editor.snapshot);
      expect(editor.insertFraction, calculatorError(CalculatorErrorCode.limit));
      expect(stateOf(editor.snapshot), denominatorBefore);
    });

    test(
      'rejecting a fraction in the root middle preserves siblings and cursor',
      () {
        final editor = FractionEditor();
        for (var i = 0; i < 256; i++) {
          editor.insertText('${i % 10}');
        }
        editor.moveLeft();
        final before = stateOf(editor.snapshot);
        expect(
          editor.insertFraction,
          calculatorError(CalculatorErrorCode.limit),
        );
        expect(stateOf(editor.snapshot), before);
        expectCursor(editor, 255);
      },
    );

    test(
      'accepts sixteen nested fractions and rejects the seventeenth atomically',
      () {
        final editor = FractionEditor();
        for (var i = 0; i < 16; i++) {
          editor.insertFraction();
        }
        expect(editor.snapshot.cursor.path, hasLength(16));
        final before = stateOf(editor.snapshot);
        expect(
          editor.insertFraction,
          calculatorError(CalculatorErrorCode.limit),
        );
        expect(stateOf(editor.snapshot), before);
        editor.insertText('7');
        expect(editor.snapshot.cursor.path, hasLength(16));
        expect(editor.snapshot.cursor.offset, 1);
      },
    );

    test('depth applies equally through numerator and denominator paths', () {
      final editor = FractionEditor();
      for (var i = 0; i < 16; i++) {
        editor.insertFraction();
        if (i.isEven) editor.moveRight();
      }
      expect(editor.snapshot.cursor.path, hasLength(16));
      final before = stateOf(editor.snapshot);
      expect(editor.insertFraction, calculatorError(CalculatorErrorCode.limit));
      expect(stateOf(editor.snapshot), before);
      editor.clear();
      editor.insertFraction();
      expectCursor(editor, 0, [(0, FractionField.numerator)]);
    });
  });
}
