import 'package:calculator_core/calculator_core.dart';
import 'package:test/test.dart';

Matcher code(CalculatorErrorCode value, {int? position}) =>
    isA<CalculatorException>()
        .having((error) => error.code, 'code', value)
        .having(
          (error) => position == null || error.position == position,
          'position',
          isTrue,
        );

CalculatorKey key(String text) => switch (text) {
  '-' => CalculatorKey.subtract,
  '+' => CalculatorKey.add,
  '/' => CalculatorKey.divide,
  '*' => CalculatorKey.multiply,
  '(' => CalculatorKey.leftParenthesis,
  ')' => CalculatorKey.rightParenthesis,
  '³' => CalculatorKey.cube,
  '²' => CalculatorKey.square,
  _ => CalculatorKey.fromId('KEY_$text')!,
};
void linear(CalculatorSession session, String source) {
  for (final char in source.split('')) {
    session.press(key(char));
  }
}

void structured(StructuredCalculatorSession session, String source) {
  for (final char in source.split('')) {
    session.press(key(char));
  }
}

void main() {
  final arithmetic = <String, String>{
    '2³': '8',
    '2³³': '512',
    '0³': '0',
    '-2³': '-8',
    '(-2)³': '-8',
    '-2³²': '-64',
    '(-2)³²': '64',
    '(2/3)³': '8/27',
    '(-2/3)³': '-8/27',
    '0,1³': '1/1000',
    '2³⁻¹²': '1/64',
    '2⁻¹³²': '1/64',
    '2³^2': '64',
    '2^2³': '256',
    '2^3^2': '512',
    '2^-3': '1/8',
    '2³(4)': '32',
    '2(3)³': '54',
  };
  for (final entry in arithmetic.entries) {
    test('exact cubing and binding ${entry.key}', () {
      expect(evaluate(entry.key).toString(), entry.value);
    });
  }

  test('mixed postfix AST is left-built with each exact UTF16 position', () {
    final square = parseExpression('2³⁻¹²') as BinaryExpression;
    final reciprocal = square.left as BinaryExpression;
    final cube = reciprocal.left as BinaryExpression;
    expect(square.position, 4);
    expect((square.right as NumberExpression).value, Rational.fromInt(2));
    expect(reciprocal.position, 2);
    expect((reciprocal.right as NumberExpression).value, Rational.fromInt(-1));
    expect(cube.position, 1);
    expect(cube.operator, BinaryOperator.power);
    expect((cube.right as NumberExpression).value, Rational.fromInt(3));
    expect(cube.right.position, 1);
    expect((cube.left as NumberExpression).value, Rational.fromInt(2));
  });

  test('semantic registry has no new physical cube ID and postfix classes are precise', () {
    expect(CalculatorKey.values, hasLength(32));
    expect(CalculatorKey.values.map((key) => key.id).toSet(), hasLength(32));
    expect(CalculatorKey.fromId('ACTION_CUBE'), CalculatorKey.cube);
    expect(CalculatorKey.fromId('KEY_CUBE'), isNull);
    expect(CalculatorKey.cube.text, '³');
    expect(CalculatorKey.cube.isBinaryOperator, isFalse);
    expect(CalculatorKey.values.where((key) => key.isPostfixOperator).toSet(), {
      CalculatorKey.square,
      CalculatorKey.reciprocal,
      CalculatorKey.cube,
      CalculatorKey.percent,
      CalculatorKey.factorial,
    });
  });

  for (final source in ['³', '1+³', '(³)', '2^³', '2³3']) {
    test('invalid cube placement $source defers to explicit syntax', () {
      expect(() => evaluate(source), throwsA(code(CalculatorErrorCode.syntax)));
    });
  }

  test('cube and following syntax retain their own character offsets', () {
    expect(
      () => evaluate('2³+*3'),
      throwsA(code(CalculatorErrorCode.syntax, position: 3)),
    );
    expect(
      () => evaluate('0³⁻¹'),
      throwsA(code(CalculatorErrorCode.math, position: 2)),
    );
    expect(
      evaluate(
        'Ans³',
        answer: Rational(BigInt.from(-2), BigInt.from(3)),
      ).toString(),
      '-8/27',
    );
    expect(
      () => evaluate('Ans³'),
      throwsA(code(CalculatorErrorCode.unsupported, position: 0)),
    );
  });

  test(
    'parser character, token and evaluation depth limits still apply to cube',
    () {
      expect(evaluate('${' ' * 2046}1³'), Rational.fromInt(1));
      expect(
        () => evaluate('${' ' * 2047}1³'),
        throwsA(code(CalculatorErrorCode.limit)),
      );
      expect(
        () => parseExpression('1${'³' * 512}'),
        throwsA(code(CalculatorErrorCode.limit, position: 512)),
      );
      expect(
        () => evaluate('1${'³' * 300}'),
        throwsA(code(CalculatorErrorCode.limit)),
      );
    },
  );

  test(
    'integer power size guard points at the cube that would exceed its budget',
    () {
      expect(evaluate('2${'³' * 10}').numerator.bitLength, 59050);
      expect(
        () => evaluate('2${'³' * 11}'),
        throwsA(code(CalculatorErrorCode.limit, position: 11)),
      );
    },
  );

  test('linear result seeds one grouped exact negative Ans and preserves snapshots', () {
    final session = CalculatorSession();
    linear(session, '-2/3');
    final old = session.press(CalculatorKey.equals);
    final edit = session.pressId('ACTION_CUBE');
    expect(edit.tokens, ['Ans', '³']);
    expect(edit.expression, 'Ans³');
    expect(edit.cursor, 2);
    expect(edit.answer, same(old.answer));
    final result = session.press(CalculatorKey.equals);
    expect(result.result.toString(), '-8/27');
    expect(old.answer.toString(), '-2/3');
    expect(session.press(CalculatorKey.equals), same(result));
  });

  test('linear cube inserts at cursor and DEL removes only the cube token', () {
    final session = CalculatorSession();
    linear(session, '2+3');
    session.press(CalculatorKey.left);
    session.press(CalculatorKey.left);
    expect(session.pressId('ACTION_CUBE').expression, '2³+3');
    expect(session.press(CalculatorKey.equals).result, Rational.fromInt(11));
    session.press(CalculatorKey.left);
    expect(session.snapshot.cursor, 4);
    session.press(CalculatorKey.left);
    session.press(CalculatorKey.left);
    expect(session.press(CalculatorKey.delete).expression, '2+3');
  });

  test(
    'linear empty cube has no implicit Ans; errors freeze and AC preserves Ans',
    () {
      final session = CalculatorSession();
      linear(session, '7');
      session.press(CalculatorKey.equals);
      session.press(CalculatorKey.clear);
      final inserted = session.pressId('ACTION_CUBE');
      expect(inserted.expression, '³');
      expect(inserted.answer, Rational.fromInt(7));
      final failure = session.press(CalculatorKey.equals);
      expect(failure.error!.code, CalculatorErrorCode.syntax);
      expect(session.pressId('ACTION_CUBE'), same(failure));
      final cleared = session.press(CalculatorKey.clear);
      expect(cleared.expression, '');
      expect(cleared.answer, Rational.fromInt(7));
    },
  );

  test('linear 2048-character insertion bound is atomic for cube', () {
    final session = CalculatorSession();
    for (var i = 0; i < 2048; i++) {
      session.press(CalculatorKey.digit1);
    }
    final before = session.snapshot;
    final failed = session.pressId('ACTION_CUBE');
    expect(failed.phase, CalculatorPhase.error);
    expect(failed.error!.code, CalculatorErrorCode.limit);
    expect(failed.expression, before.expression);
    expect(failed.cursor, before.cursor);
    expect(before.phase, CalculatorPhase.editing);
  });

  test(
    'structured negative Ans cubing remains exact and old editor is immutable',
    () {
      final session = StructuredCalculatorSession();
      structured(session, '-2/3');
      final before = session.press(CalculatorKey.equals);
      final pending = session.pressId('ACTION_CUBE');
      expect(
        FractionEditor.fromSnapshot(pending.editor).toExpression(),
        'Ans³',
      );
      expect(pending.editor.root.nodes, hasLength(2));
      expect(pending.answer, same(before.answer));
      final result = session.press(CalculatorKey.equals);
      expect(result.result.toString(), '-8/27');
      expect(FractionEditor.fromSnapshot(before.editor).toExpression(), '-2/3');
      expect(session.press(CalculatorKey.equals), same(result));
    },
  );

  test(
    'structured empty cube defers syntax and error ignores subsequent cubing',
    () {
      final session = StructuredCalculatorSession();
      final pending = session.pressId('ACTION_CUBE');
      expect(pending.phase, CalculatorPhase.editing);
      expect(FractionEditor.fromSnapshot(pending.editor).toExpression(), '³');
      final failed = session.press(CalculatorKey.equals);
      expect(failed.error!.code, CalculatorErrorCode.syntax);
      expect(session.pressId('ACTION_CUBE'), same(failed));
      expect(failed.errorCursor!.offset, 0);
      session.press(CalculatorKey.left);
      expect(session.snapshot.editor.cursor.offset, 0);
      session.press(CalculatorKey.clear);
      expect(session.snapshot.editor.root.nodes, isEmpty);
    },
  );

  test('cube projection maps its numerator token and subsequent error independently', () {
    final session = StructuredCalculatorSession()..pressId('KEY_FRACTION');
    structured(session, '2³+*3');
    session.pressId('KEY_DOWN');
    session.pressId('KEY_1');
    final editor = FractionEditor.fromSnapshot(session.snapshot.editor);
    final projection = editor.project();
    expect(projection.expression, '((2³+*3)/(1))');
    expect(projection.cursorAt(3).offset, 1);
    expect(projection.cursorAt(3).path.single.field, FractionField.numerator);
    final failed = session.press(CalculatorKey.equals);
    expect(failed.error!.position, 5);
    expect(failed.errorCursor!.path.single.field, FractionField.numerator);
    expect(failed.errorCursor!.offset, 3);
    expect(failed.editor.cursor.path.single.field, FractionField.denominator);
    final recovered = session.pressId('KEY_LEFT');
    expect(recovered.editor.cursor.path.single.field, FractionField.numerator);
    expect(recovered.editor.cursor.offset, 3);
  });

  test(
    'cube after an entire fraction uses the grouped fraction as its base',
    () {
      final editor = FractionEditor()
        ..insertFraction()
        ..insertText('2')
        ..moveDown()
        ..insertText('3')
        ..moveToRootEnd()
        ..insertText('³');
      expect(editor.toExpression(), '((2)/(3))³');
      expect(editor.evaluate().toString(), '8/27');
      final projection = editor.project();
      expect(
        projection.cursorAt(projection.expression.length - 1).path,
        isEmpty,
      );
      expect(projection.cursorAt(projection.expression.length - 1).offset, 1);
      editor.deleteBackward();
      expect(editor.toExpression(), '((2)/(3))');
    },
  );

  test(
    'editor node limit rejects cube atomically without changing old snapshots',
    () {
      final editor = FractionEditor();
      for (var i = 0; i < 256; i++) {
        editor.insertText('1');
      }
      final before = editor.snapshot;
      expect(
        () => editor.insertText('³'),
        throwsA(code(CalculatorErrorCode.limit)),
      );
      expect(editor.snapshot, same(before));
      final session = StructuredCalculatorSession();
      for (var i = 0; i < 256; i++) {
        session.press(CalculatorKey.digit1);
      }
      final old = session.snapshot;
      final failed = session.pressId('ACTION_CUBE');
      expect(failed.phase, CalculatorPhase.error);
      expect(failed.editor, same(old.editor));
      expect(failed.answer, same(old.answer));
      expect(failed.error!.code, CalculatorErrorCode.limit);
    },
  );

  test(
    'wrapping never guesses a full cube term but explicit closed groups work',
    () {
      final editor = FractionEditor()
        ..insertText('2')
        ..insertText('³');
      final before = editor.snapshot;
      expect(
        editor.wrapPreviousAtomInFraction,
        throwsA(code(CalculatorErrorCode.unsupported)),
      );
      expect(editor.snapshot, same(before));
      editor.clear();
      for (final token in ['(', '2', '³', ')']) {
        editor.insertText(token);
      }
      editor.wrapPreviousAtomInFraction();
      editor.insertText('3');
      expect(editor.evaluate().toString(), '8/3');
    },
  );

  test(
    'cube is a text token even in a field at the maximum template depth',
    () {
      final editor = FractionEditor();
      for (var i = 0; i < 16; i++) {
        editor.insertFraction();
      }
      editor.insertText('2');
      final before = editor.snapshot;
      editor.insertText('³');
      expect(editor.snapshot.cursor.path, before.cursor.path);
      expect(editor.snapshot.cursor.path.length, 16);
      expect(editor.snapshot.cursor.offset, 2);
      expect(before.cursor.offset, 1);
      final atLimit = editor.snapshot;
      expect(editor.insertFraction, throwsA(code(CalculatorErrorCode.limit)));
      expect(editor.snapshot, same(atLimit));
    },
  );

  test('structured result navigation restores root end and DEL removes one old cube', () {
    final session = StructuredCalculatorSession();
    structured(session, '2³');
    final result = session.press(CalculatorKey.equals);
    expect(result.answer, Rational.fromInt(8));
    final reopened = session.press(CalculatorKey.left);
    expect(reopened.editor.cursor.offset, 2);
    expect(FractionEditor.fromSnapshot(reopened.editor).toExpression(), '2³');
    final deleted = session.press(CalculatorKey.delete);
    expect(FractionEditor.fromSnapshot(deleted.editor).toExpression(), '2');
    expect(deleted.answer, same(result.answer));
    session.pressId('ACTION_CUBE');
    session.press(CalculatorKey.equals);
    final directDelete = session.press(CalculatorKey.delete);
    expect(
      FractionEditor.fromSnapshot(directDelete.editor).toExpression(),
      '2',
    );
    expect(directDelete.answer, Rational.fromInt(8));
    expect(FractionEditor.fromSnapshot(result.editor).toExpression(), '2³');
  });
}
