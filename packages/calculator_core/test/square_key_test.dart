import 'package:calculator_core/calculator_core.dart';
import 'package:test/test.dart';

CalculatorKey keyFor(String text) => switch (text) {
  '+' => CalculatorKey.add,
  '-' => CalculatorKey.subtract,
  '*' => CalculatorKey.multiply,
  '/' => CalculatorKey.divide,
  '^' => CalculatorKey.power,
  '²' => CalculatorKey.square,
  '(' => CalculatorKey.leftParenthesis,
  ')' => CalculatorKey.rightParenthesis,
  ',' => CalculatorKey.decimal,
  _ => CalculatorKey.fromId('KEY_$text')!,
};

void linearText(CalculatorSession session, String text) {
  for (final token in text.split('')) {
    session.press(keyFor(token));
  }
}

void structuredText(StructuredCalculatorSession session, String text) {
  for (final token in text.split('')) {
    session.press(keyFor(token));
  }
}

Matcher code(CalculatorErrorCode value) => throwsA(
  isA<CalculatorException>().having((error) => error.code, 'code', value),
);

void main() {
  group('physical square as a distinct postfix operation', () {
    final examples = <String, String>{
      '3²': '9',
      '3²²': '81',
      '3²²²': '6561',
      '-2²': '-4',
      '(-2)²': '4',
      '-2²²': '-16',
      '(-2)²²²': '256',
      '2^3²': '512',
      '2²^3': '64',
      '2^-3²': '1/512',
      '(1/2)²': '1/4',
      '(1/2)²²²': '1/256',
      '0,1²': '1/100',
      '0²': '0',
      '2²(3+1)': '16',
      '1+2²*3': '13',
      '2^3^2': '512',
    };
    for (final entry in examples.entries) {
      test('${entry.key} = ${entry.value}', () {
        expect(evaluate(entry.key).toString(), entry.value);
      });
    }

    test('three squares cannot be replaced by repeated textual ^2', () {
      expect(evaluate('3²²²'), Rational.fromInt(6561));
      expect(evaluate('3^2^2^2'), Rational.fromInt(43046721));
    });

    test(
      'parser builds nested powers with source positions at each postfix',
      () {
        final outer = parseExpression('3²²') as BinaryExpression;
        expect(outer.operator, BinaryOperator.power);
        expect(outer.position, 2);
        expect((outer.right as NumberExpression).value, Rational.fromInt(2));
        expect(outer.right.position, 2);
        final inner = outer.left as BinaryExpression;
        expect(inner.operator, BinaryOperator.power);
        expect(inner.position, 1);
        expect((inner.left as NumberExpression).value, Rational.fromInt(3));
        expect((inner.right as NumberExpression).value, Rational.fromInt(2));
        expect(inner.right.position, 1);
      },
    );

    test('K02 mathematical sign/grouping examples with postfix projection', () {
      // REFERENZTESTS K02, H PDF S. 11. These are arithmetic projections,
      // not evidence about original calculator key timing or UI behavior.
      expect(evaluate('-2²'), Rational.fromInt(-4));
      expect(evaluate('(-2)²'), Rational.fromInt(4));
    });

    test(
      'an explicit negative fractional Ans is one grouped numeric operand',
      () {
        expect(
          evaluate(
            'Ans²',
            answer: Rational(BigInt.from(-1), BigInt.two),
          ).toString(),
          '1/4',
        );
        expect(
          evaluate('Ans²²', answer: Rational.fromInt(-2)),
          Rational.fromInt(16),
        );
        expect(() => evaluate('Ans²'), code(CalculatorErrorCode.unsupported));
      },
    );

    for (final source in ['²', '1+²', '(²)', '2^²', '2²3']) {
      test(
        'invalid postfix placement $source is a structured syntax error',
        () {
          expect(() => evaluate(source), code(CalculatorErrorCode.syntax));
        },
      );
    }

    test('postfix evaluation depth and tokenizer budgets remain enforced', () {
      final deep = '1${List.filled(300, '²').join()}';
      expect(() => evaluate(deep), code(CalculatorErrorCode.limit));
      final many = '1${List.filled(512, '²').join()}';
      expect(() => evaluate(many), code(CalculatorErrorCode.limit));
    });

    test('existing evaluator size checks point to the square operator', () {
      final source =
          '1${List.filled(19, '0').join()}${List.filled(11, '²').join()}';
      try {
        evaluate(source);
        fail('Expected square size limit');
      } on CalculatorException catch (error) {
        expect(error.code, CalculatorErrorCode.limit);
        expect(error.position, 30);
      }
    });
  });

  group('linear square key transitions', () {
    test(
      'registry has 30 unique actions and square is not a binary operator',
      () {
        expect(CalculatorKey.values, hasLength(30));
        expect(
          CalculatorKey.values.map((key) => key.id).toSet(),
          hasLength(30),
        );
        expect(CalculatorKey.fromId('KEY_SQUARE'), CalculatorKey.square);
        expect(CalculatorKey.square.text, '²');
        expect(CalculatorKey.square.isBinaryOperator, isFalse);
      },
    );

    test('pressing square in editing inserts one token and repeated presses square again', () {
      final session = CalculatorSession();
      linearText(session, '3');
      session.pressId('KEY_SQUARE');
      session.pressId('KEY_SQUARE');
      session.pressId('KEY_SQUARE');
      expect(session.snapshot.tokens, ['3', '²', '²', '²']);
      expect(session.snapshot.cursor, 4);
      expect(session.snapshot.cursorOffset, 4);
      expect(
        session.press(CalculatorKey.equals).result,
        Rational.fromInt(6561),
      );
    });

    test('square after a negative result starts Ans² and updates Ans only at equals', () {
      final session = CalculatorSession();
      linearText(session, '-1/2');
      final old = session.press(CalculatorKey.equals);
      final pending = session.pressId('KEY_SQUARE');
      expect(pending.expression, 'Ans²');
      expect(pending.tokens, ['Ans', '²']);
      expect(pending.cursor, 2);
      expect(pending.cursorOffset, 4);
      expect(pending.phase, CalculatorPhase.editing);
      expect(pending.answer.toString(), '-1/2');
      expect(pending.result, isNull);
      final success = session.press(CalculatorKey.equals);
      expect(success.result.toString(), '1/4');
      expect(success.answer.toString(), '1/4');
      expect(old.expression, '-1/2');
      expect(old.answer.toString(), '-1/2');
    });

    test(
      'empty editing never inserts implicit Ans even when Ans already exists',
      () {
        final session = CalculatorSession();
        linearText(session, '7');
        session.press(CalculatorKey.equals);
        session.press(CalculatorKey.clear);
        final pending = session.press(CalculatorKey.square);
        expect(pending.expression, '²');
        expect(pending.phase, CalculatorPhase.editing);
        expect(pending.error, isNull);
        final failed = session.press(CalculatorKey.equals);
        expect(failed.phase, CalculatorPhase.error);
        expect(failed.error?.code, CalculatorErrorCode.syntax);
        expect(failed.error?.position, 0);
        expect(failed.answer, Rational.fromInt(7));
        expect(identical(session.press(CalculatorKey.square), failed), isTrue);
      },
    );

    test(
      'middle-cursor insertion and deletion affect exactly one square token',
      () {
        final session = CalculatorSession();
        linearText(session, '2+3');
        session.press(CalculatorKey.left);
        session.press(CalculatorKey.left);
        final before = session.snapshot;
        session.press(CalculatorKey.square);
        expect(session.snapshot.expression, '2²+3');
        expect(session.snapshot.cursor, 2);
        expect(session.press(CalculatorKey.equals).result, Rational.fromInt(7));
        expect(before.expression, '2+3');
        session.press(CalculatorKey.left);
        for (var index = 0; index < 2; index++) {
          session.press(CalculatorKey.left);
        }
        session.press(CalculatorKey.delete);
        expect(session.snapshot.expression, '2+3');
      },
    );

    test(
      'square respects the exact 2048-character insertion budget atomically',
      () {
        final session = CalculatorSession();
        session.press(CalculatorKey.digit1);
        for (var index = 1; index < 2048; index++) {
          session.press(CalculatorKey.square);
        }
        final before = session.snapshot;
        final failure = session.press(CalculatorKey.square);
        expect(failure.phase, CalculatorPhase.error);
        expect(failure.error?.code, CalculatorErrorCode.limit);
        expect(failure.tokens, before.tokens);
        expect(failure.cursor, before.cursor);
        expect(failure.answer, Rational.fromInt(0));
        expect(before.expression.length, 2048);
      },
    );
  });

  group('structured square and source map', () {
    test('a whole fraction is grouped as the base of a following square', () {
      final session = StructuredCalculatorSession();
      session.pressId('KEY_FRACTION');
      structuredText(session, '2');
      session.pressId('KEY_DOWN');
      structuredText(session, '3');
      session.press(CalculatorKey.right);
      session.pressId('KEY_SQUARE');
      final expression = FractionEditor.fromSnapshot(session.snapshot.editor)
          .toExpression();
      expect(expression, '((2)/(3))²');
      expect(session.press(CalculatorKey.equals).result.toString(), '4/9');
    });

    test(
      'squares can occur independently inside numerator and denominator',
      () {
        final editor = FractionEditor()..insertFraction();
        editor.insertText('2');
        editor.insertText('²');
        editor.moveDown();
        editor.insertText('3');
        editor.insertText('²');
        expect(editor.toExpression(), '((2²)/(3²))');
        expect(editor.evaluate().toString(), '4/9');
        final cursor = editor.project().cursorAt(3);
        expect(cursor.path.single.field, FractionField.numerator);
        expect(cursor.offset, 1);
      },
    );

    test('square after negative structured result starts exact Ans²', () {
      final session = StructuredCalculatorSession();
      structuredText(session, '-2');
      final old = session.press(CalculatorKey.equals);
      final pending = session.press(CalculatorKey.square);
      expect(
        FractionEditor.fromSnapshot(pending.editor).toExpression(),
        'Ans²',
      );
      expect(pending.editor.root.nodes, hasLength(2));
      expect(pending.editor.cursor.path, isEmpty);
      expect(pending.editor.cursor.offset, 2);
      expect(pending.answer, Rational.fromInt(-2));
      expect(pending.result, isNull);
      expect(session.press(CalculatorKey.equals).result, Rational.fromInt(4));
      expect(old.answer, Rational.fromInt(-2));
    });

    test('empty structured editing inserts no implicit Ans and preserves error source', () {
      final session = StructuredCalculatorSession();
      structuredText(session, '7');
      session.press(CalculatorKey.equals);
      session.press(CalculatorKey.clear);
      final pending = session.pressId('KEY_SQUARE');
      expect(pending.phase, CalculatorPhase.editing);
      expect(FractionEditor.fromSnapshot(pending.editor).toExpression(), '²');
      final failure = session.press(CalculatorKey.equals);
      expect(failure.error?.code, CalculatorErrorCode.syntax);
      expect(failure.error?.position, 0);
      expect(failure.errorCursor!.path, isEmpty);
      expect(failure.errorCursor!.offset, 0);
      expect(failure.answer, Rational.fromInt(7));
      expect(identical(session.press(CalculatorKey.square), failure), isTrue);
    });

    test(
      'nested invalid square points to its field token, not generated brackets',
      () {
        final session = StructuredCalculatorSession();
        session.pressId('KEY_FRACTION');
        session.press(CalculatorKey.square);
        session.pressId('KEY_DOWN');
        structuredText(session, '2');
        final failure = session.press(CalculatorKey.equals);
        expect(failure.error?.code, CalculatorErrorCode.syntax);
        expect(failure.error?.position, 2);
        expect(failure.errorCursor!.path.single.field, FractionField.numerator);
        expect(failure.errorCursor!.offset, 0);
        session.press(CalculatorKey.left);
        structuredText(session, '3');
        expect(session.press(CalculatorKey.equals).result.toString(), '9/2');
      },
    );

    test(
      'middle-field insertion keeps denominator and old snapshots unchanged',
      () {
        final editor = FractionEditor()..insertFraction();
        for (final token in ['2', '+', '3']) {
          editor.insertText(token);
        }
        editor.moveDown();
        editor.insertText('7');
        editor.moveUp();
        expect(editor.snapshot.cursor.offset, 1);
        final old = editor.snapshot;
        editor.insertText('²');
        expect(editor.toExpression(), '((2²+3)/(7))');
        expect(editor.evaluate(), Rational.fromInt(1));
        expect(FractionEditor.fromSnapshot(old).toExpression(), '((2+3)/(7))');
      },
    );

    test(
      'wrap after square stays explicitly unsupported, not whole-term capture',
      () {
        final editor = FractionEditor()..insertText('3');
        editor.insertText('²');
        final before = editor.snapshot;
        expect(
          editor.wrapPreviousAtomInFraction,
          code(CalculatorErrorCode.unsupported),
        );
        expect(identical(editor.snapshot, before), isTrue);
      },
    );

    test('explicit parenthesized square group remains capturable', () {
      final editor = FractionEditor();
      for (final token in ['(', '3', '²', ')']) {
        editor.insertText(token);
      }
      editor.wrapPreviousAtomInFraction();
      editor.insertText('2');
      expect(editor.toExpression(), '(((3²))/(2))');
      expect(editor.evaluate().toString(), '9/2');
    });

    test(
      'the 256th node may be a square and the next insertion fails atomically',
      () {
        final session = StructuredCalculatorSession();
        session.press(CalculatorKey.digit1);
        for (var index = 1; index < FractionEditor.maxNodes; index++) {
          session.press(CalculatorKey.square);
        }
        final before = session.snapshot;
        expect(session.press(CalculatorKey.equals).result, Rational.fromInt(1));
        session.press(CalculatorKey.left);
        final full = session.snapshot;
        final failure = session.press(CalculatorKey.square);
        expect(failure.error?.code, CalculatorErrorCode.limit);
        expect(identical(failure.editor, full.editor), isTrue);
        expect(failure.answer, Rational.fromInt(1));
        expect(before.editor.root.nodes, hasLength(FractionEditor.maxNodes));
      },
    );
  });
}
