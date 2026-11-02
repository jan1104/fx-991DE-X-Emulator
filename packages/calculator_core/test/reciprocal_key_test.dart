import 'package:calculator_core/calculator_core.dart';
import 'package:test/test.dart';

CalculatorKey keyFor(String token) => switch (token) {
  '+' => CalculatorKey.add,
  '-' => CalculatorKey.subtract,
  '/' => CalculatorKey.divide,
  '(' => CalculatorKey.leftParenthesis,
  ')' => CalculatorKey.rightParenthesis,
  _ => CalculatorKey.fromId('KEY_$token')!,
};

void linearText(CalculatorSession session, String source) {
  for (final token in source.split('')) {
    session.press(keyFor(token));
  }
}

void structuredText(StructuredCalculatorSession session, String source) {
  for (final token in source.split('')) {
    session.press(keyFor(token));
  }
}

Matcher code(CalculatorErrorCode value) => throwsA(
  isA<CalculatorException>().having((error) => error.code, 'code', value),
);

void main() {
  group('atomic reciprocal postfix grammar', () {
    final cases = <String, String>{
      '2⁻¹': '1/2',
      '2⁻¹⁻¹': '2',
      '2⁻¹⁻¹⁻¹': '1/2',
      '-2⁻¹': '-1/2',
      '(-2)⁻¹': '-1/2',
      '-2⁻¹²': '-1/4',
      '(-2)⁻¹²': '1/4',
      '3²⁻¹': '1/9',
      '3⁻¹²': '1/9',
      '3²⁻¹⁻¹²': '81',
      '(2/3)⁻¹': '3/2',
      '(-2/3)⁻¹': '-3/2',
      '0,1⁻¹': '10',
      '1e-3⁻¹': '1000',
      '4⁻¹^2': '1/16',
      '2^3^2': '512',
      '2⁻¹(6)': '3',
      '1+2⁻¹*3': '5/2',
      '1/2⁻¹': '2',
      '9007199254740993⁻¹': '1/9007199254740993',
    };
    for (final entry in cases.entries) {
      test('${entry.key} = ${entry.value}', () {
        expect(evaluate(entry.key).toString(), entry.value);
      });
    }

    test('mixed AST chain order is explicit even though square and inverse commute', () {
      final reciprocalLast = parseExpression('3²⁻¹') as BinaryExpression;
      expect(reciprocalLast.position, 2);
      expect(
        (reciprocalLast.right as NumberExpression).value,
        Rational.fromInt(-1),
      );
      final squareFirst = reciprocalLast.left as BinaryExpression;
      expect(squareFirst.position, 1);
      expect(
        (squareFirst.right as NumberExpression).value,
        Rational.fromInt(2),
      );
      final squareLast = parseExpression('3⁻¹²') as BinaryExpression;
      expect(squareLast.position, 3);
      expect((squareLast.right as NumberExpression).value, Rational.fromInt(2));
      final reciprocalFirst = squareLast.left as BinaryExpression;
      expect(reciprocalFirst.position, 1);
      expect(
        (reciprocalFirst.right as NumberExpression).value,
        Rational.fromInt(-1),
      );
      expect(reciprocalFirst.right.position, 1);
    });

    test(
      'ordinary power keeps its own current integer-exponent limitation',
      () {
        expect(() => evaluate('2^2⁻¹'), code(CalculatorErrorCode.unsupported));
        expect(() => evaluate('4^2⁻¹'), code(CalculatorErrorCode.unsupported));
      },
    );

    for (final source in ['⁻¹', '1+⁻¹', '(⁻¹)', '2^⁻¹', '2⁻¹3']) {
      test('a reciprocal with invalid placement in $source is syntax', () {
        expect(() => evaluate(source), code(CalculatorErrorCode.syntax));
      });
    }

    for (final (source, position) in [
      ('2⁻', 1),
      ('2¹', 1),
      ('2⁻ ¹', 1),
      ('2⁻1', 1),
      ('2⁻¹¹', 3),
      ('2⁻¹+*3', 4),
    ]) {
      test(
        'malformed token or subsequent syntax in $source keeps UTF16 offset',
        () {
          expect(
            () => evaluate(source),
            throwsA(
              isA<CalculatorException>()
                  .having(
                    (error) => error.code,
                    'code',
                    CalculatorErrorCode.syntax,
                  )
                  .having((error) => error.position, 'position', position),
            ),
          );
        },
      );
    }

    for (final (source, position) in [('0⁻¹', 1), ('0²⁻¹', 2), ('0⁻¹²', 1)]) {
      test('zero reciprocal in $source is math at the reciprocal start', () {
        expect(
          () => evaluate(source),
          throwsA(
            isA<CalculatorException>()
                .having((error) => error.code, 'code', CalculatorErrorCode.math)
                .having((error) => error.position, 'position', position),
          ),
        );
      });
    }

    test('negative rational Ans stays exact and grouped', () {
      expect(
        evaluate(
          'Ans⁻¹',
          answer: Rational(BigInt.from(-2), BigInt.from(3)),
        ).toString(),
        '-3/2',
      );
      expect(
        evaluate(
          'Ans⁻¹²',
          answer: Rational(BigInt.from(-2), BigInt.from(3)),
        ).toString(),
        '9/4',
      );
      expect(() => evaluate('Ans⁻¹'), code(CalculatorErrorCode.unsupported));
    });
  });

  group('postfix resource limits', () {
    test('reciprocal is counted once per token, with the next offset still UTF16', () {
      // A number plus 511 reciprocals is exactly 512 lexer tokens. The parser
      // can build that tree; its later evaluation has a separate depth budget.
      final maximum = '1${List.filled(511, '⁻¹').join()}';
      expect(parseExpression(maximum), isA<BinaryExpression>());
      expect(
        () => parseExpression('$maximum⁻¹'),
        throwsA(
          isA<CalculatorException>()
              .having((error) => error.code, 'code', CalculatorErrorCode.limit)
              .having((error) => error.position, 'position', 1023),
        ),
      );
    });

    test('evaluation rejects deep reciprocal chains without recursive-parser overflow', () {
      expect(
        evaluate('1${List.filled(256, '⁻¹').join()}'),
        Rational.fromInt(1),
      );
      expect(
        () => evaluate('1${List.filled(257, '⁻¹').join()}'),
        code(CalculatorErrorCode.limit),
      );
    });

    for (final prefix in ['1', '12']) {
      test(
        'linear reciprocal insertion near 2048 chars is atomic for prefix $prefix',
        () {
          final session = CalculatorSession();
          linearText(session, prefix);
          for (var index = 0; index < 1023; index++) {
            session.press(CalculatorKey.reciprocal);
          }
          final before = session.snapshot;
          expect(before.expression.length, prefix.length + 2046);
          final failure = session.press(CalculatorKey.reciprocal);
          expect(failure.error?.code, CalculatorErrorCode.limit);
          expect(failure.tokens, before.tokens);
          expect(failure.cursor, before.cursor);
          expect(failure.cursorOffset, before.cursorOffset);
          expect(failure.error?.position, before.cursorOffset);
          expect(failure.expression.endsWith('⁻¹'), isTrue);
        },
      );
    }

    test(
      'structured reciprocal uses one node, including at the 256-node boundary',
      () {
        final session = StructuredCalculatorSession();
        session.press(CalculatorKey.digit1);
        for (var index = 1; index < FractionEditor.maxNodes; index++) {
          session.press(CalculatorKey.reciprocal);
        }
        final maximum = session.snapshot.editor;
        expect(maximum.root.nodes, hasLength(256));
        expect(FractionEditor.fromSnapshot(maximum).toExpression().length, 511);
        expect(session.press(CalculatorKey.equals).result, Rational.fromInt(1));
        session.press(CalculatorKey.left);
        final before = session.snapshot.editor;
        final failure = session.press(CalculatorKey.reciprocal);
        expect(failure.error?.code, CalculatorErrorCode.limit);
        expect(identical(failure.editor, before), isTrue);
        expect(failure.answer, Rational.fromInt(1));
      },
    );
  });

  group('linear reciprocal key', () {
    test(
      'registry matches the physical ID, without classifying it as binary',
      () {
        expect(
          CalculatorKey.fromId('KEY_RECIPROCAL'),
          CalculatorKey.reciprocal,
        );
        expect(CalculatorKey.reciprocal.text, '⁻¹');
        expect(CalculatorKey.reciprocal.isBinaryOperator, isFalse);
        expect(CalculatorKey.values, hasLength(28));
        expect(
          CalculatorKey.values.map((key) => key.id).toSet(),
          hasLength(28),
        );
      },
    );

    test('a result starts exact Ans reciprocal; repeated equals does not repeat it', () {
      final session = CalculatorSession();
      linearText(session, '-2/3');
      final old = session.press(CalculatorKey.equals);
      final pending = session.pressId('KEY_RECIPROCAL');
      expect(pending.tokens, ['Ans', '⁻¹']);
      expect(pending.expression, 'Ans⁻¹');
      expect(pending.cursor, 2);
      expect(pending.cursorOffset, 5);
      expect(pending.answer.toString(), '-2/3');
      expect(pending.result, isNull);
      final success = session.press(CalculatorKey.equals);
      expect(success.result.toString(), '-3/2');
      expect(success.answer.toString(), '-3/2');
      expect(identical(session.press(CalculatorKey.equals), success), isTrue);
      expect(old.answer.toString(), '-2/3');
    });

    test(
      'empty editing has no implicit Ans, with syntax deferred until equals',
      () {
        final session = CalculatorSession();
        linearText(session, '7');
        session.press(CalculatorKey.equals);
        session.press(CalculatorKey.clear);
        final pending = session.press(CalculatorKey.reciprocal);
        expect(pending.expression, '⁻¹');
        expect(pending.phase, CalculatorPhase.editing);
        expect(pending.error, isNull);
        final failure = session.press(CalculatorKey.equals);
        expect(failure.error?.code, CalculatorErrorCode.syntax);
        expect(failure.error?.position, 0);
        expect(failure.answer, Rational.fromInt(7));
        expect(
          identical(session.press(CalculatorKey.reciprocal), failure),
          isTrue,
        );
      },
    );

    test('middle insertion and backward deletion handle the whole two-character token', () {
      final session = CalculatorSession();
      linearText(session, '2+3');
      session.press(CalculatorKey.left);
      session.press(CalculatorKey.left);
      final before = session.snapshot;
      final inserted = session.press(CalculatorKey.reciprocal);
      expect(inserted.expression, '2⁻¹+3');
      expect(inserted.cursor, 2);
      expect(inserted.cursorOffset, 3);
      final deleted = session.press(CalculatorKey.delete);
      expect(deleted.expression, '2+3');
      expect(deleted.cursor, 1);
      expect(deleted.cursorOffset, 1);
      expect(before.expression, '2+3');
      session.press(CalculatorKey.reciprocal);
      expect(session.press(CalculatorKey.equals).result.toString(), '7/2');
    });

    test('zero result reciprocal enters math error without changing Ans', () {
      final session = CalculatorSession();
      session.press(CalculatorKey.digit0);
      session.press(CalculatorKey.equals);
      session.press(CalculatorKey.reciprocal);
      final failure = session.press(CalculatorKey.equals);
      expect(failure.expression, 'Ans⁻¹');
      expect(failure.error?.code, CalculatorErrorCode.math);
      expect(failure.error?.position, 3);
      expect(failure.answer, Rational.fromInt(0));
      expect(identical(session.press(CalculatorKey.square), failure), isTrue);
      expect(
        identical(session.press(CalculatorKey.reciprocal), failure),
        isTrue,
      );
    });
  });

  group('structured reciprocal and source mapping', () {
    test(
      'both superscript character offsets map to the same atomic editor node',
      () {
        final editor = FractionEditor()..insertText('2');
        editor.insertText('⁻¹');
        editor.insertText('+');
        editor.insertText('3');
        final projection = editor.project();
        expect(projection.expression, '2⁻¹+3');
        for (final offset in [1, 2]) {
          final target = projection.cursorAt(offset);
          expect(target.path, isEmpty);
          expect(target.offset, 1);
        }
        expect(projection.cursorAt(3).offset, 2);
        editor.moveLeft();
        editor.moveLeft();
        expect(editor.snapshot.cursor.offset, 2);
        editor.deleteBackward();
        expect(editor.toExpression(), '2+3');
        expect(editor.snapshot.cursor.offset, 1);
      },
    );

    test('nested pair offsets and a following syntax error retain their correct field', () {
      final editor = FractionEditor()..insertFraction();
      for (final token in ['2', '⁻¹', '+', '*', '3']) {
        editor.insertText(token);
      }
      editor.moveDown();
      editor.insertText('1');
      final projection = editor.project();
      expect(projection.expression, '((2⁻¹+*3)/(1))');
      for (final offset in [3, 4]) {
        expect(
          projection.cursorAt(offset).path.single.field,
          FractionField.numerator,
        );
        expect(projection.cursorAt(offset).offset, 1);
      }
      expect(
        () => editor.evaluate(),
        throwsA(
          isA<CalculatorException>()
              .having((error) => error.code, 'code', CalculatorErrorCode.syntax)
              .having((error) => error.position, 'position', 6),
        ),
      );
      expect(projection.cursorAt(6).offset, 3);
    });

    test(
      'after negative rational result structured reciprocal seeds Ans exactly',
      () {
        final session = StructuredCalculatorSession();
        structuredText(session, '-2/3');
        final old = session.press(CalculatorKey.equals);
        final pending = session.pressId('KEY_RECIPROCAL');
        expect(
          FractionEditor.fromSnapshot(pending.editor).toExpression(),
          'Ans⁻¹',
        );
        expect(pending.editor.root.nodes, hasLength(2));
        expect(pending.editor.cursor.offset, 2);
        expect(pending.answer.toString(), '-2/3');
        expect(pending.result, isNull);
        expect(session.press(CalculatorKey.equals).result.toString(), '-3/2');
        expect(old.answer.toString(), '-2/3');
      },
    );

    test(
      'empty structured editing defers missing-base syntax and never seeds Ans',
      () {
        final session = StructuredCalculatorSession();
        structuredText(session, '7');
        session.press(CalculatorKey.equals);
        session.press(CalculatorKey.clear);
        final pending = session.press(CalculatorKey.reciprocal);
        expect(
          FractionEditor.fromSnapshot(pending.editor).toExpression(),
          '⁻¹',
        );
        expect(pending.phase, CalculatorPhase.editing);
        final failure = session.press(CalculatorKey.equals);
        expect(failure.error?.code, CalculatorErrorCode.syntax);
        expect(failure.errorCursor!.path, isEmpty);
        expect(failure.errorCursor!.offset, 0);
        expect(failure.answer, Rational.fromInt(7));
        expect(
          identical(session.press(CalculatorKey.reciprocal), failure),
          isTrue,
        );
      },
    );

    test('zero reciprocal in a denominator maps to its postfix and permits base repair', () {
      final session = StructuredCalculatorSession();
      session.pressId('KEY_FRACTION');
      structuredText(session, '1');
      session.pressId('KEY_DOWN');
      structuredText(session, '0');
      session.press(CalculatorKey.reciprocal);
      session.press(CalculatorKey.right);
      final before = session.snapshot.editor;
      final failure = session.press(CalculatorKey.equals);
      expect(failure.error?.code, CalculatorErrorCode.math);
      expect(failure.error?.position, 7);
      expect(identical(failure.editor, before), isTrue);
      expect(failure.errorCursor!.path.single.field, FractionField.denominator);
      expect(failure.errorCursor!.offset, 1);
      expect(
        identical(session.press(CalculatorKey.reciprocal), failure),
        isTrue,
      );
      session.press(CalculatorKey.left);
      session.press(CalculatorKey.delete);
      structuredText(session, '2');
      expect(session.press(CalculatorKey.equals).result, Rational.fromInt(2));
      expect(failure.editor.cursor.path, isEmpty);
      expect(failure.errorCursor!.offset, 1);
    });

    test('fraction result is one operand of a following reciprocal', () {
      final editor = FractionEditor()..insertFraction();
      editor.insertText('2');
      editor.moveDown();
      editor.insertText('3');
      editor.moveRight();
      editor.insertText('⁻¹');
      expect(editor.toExpression(), '((2)/(3))⁻¹');
      expect(editor.evaluate().toString(), '3/2');
    });

    test(
      'capture does not infer a full reciprocal term, but explicit groups work',
      () {
        final editor = FractionEditor()..insertText('3');
        editor.insertText('⁻¹');
        final before = editor.snapshot;
        expect(
          editor.wrapPreviousAtomInFraction,
          code(CalculatorErrorCode.unsupported),
        );
        expect(identical(editor.snapshot, before), isTrue);
        editor.clear();
        for (final token in ['(', '3', '⁻¹', ')']) {
          editor.insertText(token);
        }
        editor.wrapPreviousAtomInFraction();
        editor.insertText('2');
        expect(editor.evaluate().toString(), '1/6');
      },
    );
  });
}
