import 'package:calculator_core/calculator_core.dart';
import 'package:test/test.dart';

Matcher error(CalculatorErrorCode code, [int? position]) =>
    isA<CalculatorException>()
        .having((e) => e.code, 'code', code)
        .having(
          (e) => position == null || e.position == position,
          'position',
          true,
        );

CalculatorKey key(String token) => switch (token) {
  '!' => CalculatorKey.factorial,
  '-' => CalculatorKey.subtract,
  '+' => CalculatorKey.add,
  '*' => CalculatorKey.multiply,
  '/' => CalculatorKey.divide,
  '(' => CalculatorKey.leftParenthesis,
  ')' => CalculatorKey.rightParenthesis,
  _ => CalculatorKey.fromId('KEY_$token')!,
};

void linear(CalculatorSession session, String input) {
  for (final token in input.split('')) {
    session.press(key(token));
  }
}

void structured(StructuredCalculatorSession session, String input) {
  for (final token in input.split('')) {
    session.press(key(token));
  }
}

const factorial69 =
    '171122452428141311372468338881272839092270544893520369393648040923257279754140647424000000000000000';

void main() {
  // H physical PDF page 21 supplies (5+3)!=40320; the domain 0..69 is H p.51.
  // Remaining combinations fix our prototype grammar, not original observations.
  for (final (input, expected) in [
    ('0!', '1'),
    ('1!', '1'),
    ('5!', '120'),
    ('(5+3)!', '40320'),
    ('10!', '3628800'),
    ('20!', '2432902008176640000'),
    ('69!', factorial69),
    ('-5!', '-120'),
    ('(-0)!', '1'),
    ('(12/3)!', '24'),
    ('3!!', '720'),
    ('2²!', '24'),
    ('3!²', '36'),
    ('3!³', '216'),
    ('3!⁻¹', '1/6'),
    ('0!%', '1/100'),
    ('100%!', '1'),
    ('2^3!', '64'),
    ('2!^3', '8'),
    ('2^3^2', '512'),
    ('2(3)!', '12'),
    ('2!(3)', '6'),
  ]) {
    test('exact factorial and own postfix grammar $input', () {
      expect(evaluate(input).toString(), expected);
    });
  }

  test('all 70 supported integers satisfy the factorial recurrence', () {
    var previous = BigInt.one;
    for (var n = 0; n <= 69; n++) {
      final actual = evaluate('$n!');
      expect(actual.isInteger, isTrue);
      if (n > 0) previous *= BigInt.from(n);
      expect(actual.numerator, previous, reason: '$n!');
    }
    expect(previous.toString(), factorial69);
  });

  for (final input in [
    '70!',
    '(-1)!',
    '(1/2)!',
    '69,1!',
    '1e100!',
    '50%!',
    '4⁻¹!',
    '3!!!',
  ]) {
    test('factorial rejects out-of-domain argument $input as math', () {
      expect(() => evaluate(input), throwsA(error(CalculatorErrorCode.math)));
    });
  }

  test('factorial is an explicit unary AST at its own UTF16 position', () {
    final square = parseExpression('3!²') as BinaryExpression;
    final factorial = square.left as UnaryExpression;
    expect(square.position, 2);
    expect(factorial.operator, UnaryOperator.factorial);
    expect(factorial.position, 1);
    expect((factorial.operand as NumberExpression).value, Rational.fromInt(3));
    final negated = parseExpression('-5!') as UnaryExpression;
    expect(negated.operator, UnaryOperator.negate);
    expect(
      (negated.operand as UnaryExpression).operator,
      UnaryOperator.factorial,
    );
  });

  test(
    'factorial domain and operand failures keep distinct source positions',
    () {
      expect(
        () => evaluate('(-5)!'),
        throwsA(error(CalculatorErrorCode.math, 4)),
      );
      expect(
        () => evaluate('(1/0)!'),
        throwsA(error(CalculatorErrorCode.math, 2)),
      );
      expect(
        () => evaluate('2!+*3'),
        throwsA(error(CalculatorErrorCode.syntax, 3)),
      );
      expect(
        () => evaluate('Ans!'),
        throwsA(error(CalculatorErrorCode.unsupported, 0)),
      );
      expect(
        () => evaluate('Ans!', answer: Rational.fromInt(70)),
        throwsA(error(CalculatorErrorCode.math, 3)),
      );
      expect(
        evaluate(
          'Ans!',
          answer: Rational(BigInt.from(12), BigInt.from(3)),
        ).toString(),
        '24',
      );
    },
  );

  for (final input in ['!', '1+!', '(!)', '2^!', '2!3']) {
    test('factorial syntax requires a base $input', () {
      expect(() => evaluate(input), throwsA(error(CalculatorErrorCode.syntax)));
    });
  }

  test('factorial is secondary semantic action and participates in postfix continuation', () {
    expect(CalculatorKey.values, hasLength(33));
    expect(CalculatorKey.values.map((key) => key.id).toSet(), hasLength(33));
    expect(CalculatorKey.fromId('ACTION_FACTORIAL'), CalculatorKey.factorial);
    expect(CalculatorKey.fromId('KEY_FACTORIAL'), isNull);
    expect(CalculatorKey.factorial.text, '!');
    expect(CalculatorKey.factorial.isBinaryOperator, isFalse);
    expect(CalculatorKey.factorial.isPostfixOperator, isTrue);
  });

  test('shared work budget charges bounded factorial multiplications', () {
    final accepted = List.filled(28, '69!').join('+');
    expect(
      evaluate(accepted).numerator,
      BigInt.parse(factorial69) * BigInt.from(28),
    );
    final rejected = List.filled(29, '69!').join('+');
    expect(
      () => evaluate(rejected),
      throwsA(error(CalculatorErrorCode.limit, rejected.length - 1)),
    );
    // Each invocation owns its budget; one large job cannot poison the next.
    expect(evaluate('69!').toString(), factorial69);
  });

  test('factorial input token and evaluation-depth budgets remain bounded', () {
    expect(evaluate('${' ' * 2046}1!').toString(), '1');
    expect(
      () => evaluate('${' ' * 2047}1!'),
      throwsA(error(CalculatorErrorCode.limit)),
    );
    expect(
      () => parseExpression('1${'!' * 512}'),
      throwsA(error(CalculatorErrorCode.limit, 512)),
    );
    expect(evaluate('1${'!' * 256}').toString(), '1');
    expect(
      () => evaluate('1${'!' * 257}'),
      throwsA(error(CalculatorErrorCode.limit)),
    );
  });

  test(
    'direct public unary AST validates huge domain before integer conversion',
    () {
      final expression = UnaryExpression(
        UnaryOperator.factorial,
        NumberExpression(Rational(BigInt.one << 1000), 7),
        9,
      );
      expect(
        () => evaluateExpression(expression),
        throwsA(error(CalculatorErrorCode.math, 9)),
      );
      expect(
        evaluateExpression(
          UnaryExpression(
            UnaryOperator.plus,
            NumberExpression(Rational.fromInt(5), 0),
            0,
          ),
        ),
        Rational.fromInt(5),
      );
    },
  );

  test('linear result factorial binds exact Ans and DEL removes one token', () {
    final session = CalculatorSession();
    linear(session, '12/3');
    final old = session.press(CalculatorKey.equals);
    final pending = session.pressId('ACTION_FACTORIAL');
    expect(pending.expression, 'Ans!');
    expect(pending.tokens, ['Ans', '!']);
    expect(pending.answer, same(old.answer));
    expect(session.press(CalculatorKey.equals).result, Rational.fromInt(24));
    expect(session.press(CalculatorKey.delete).expression, 'Ans');
    expect(old.expression, '12/3');
    expect(old.result, Rational.fromInt(4));
  });

  test('linear domain failure keeps previous Ans and freezes until cursor recovery', () {
    final session = CalculatorSession();
    linear(session, '5');
    session.press(CalculatorKey.equals);
    session.press(CalculatorKey.clear);
    linear(session, '70!');
    final failed = session.press(CalculatorKey.equals);
    expect(failed.error!.code, CalculatorErrorCode.math);
    expect(failed.error!.position, 2);
    expect(failed.answer, Rational.fromInt(5));
    expect(session.pressId('ACTION_FACTORIAL'), same(failed));
    final reopened = session.press(CalculatorKey.left);
    expect(reopened.cursor, 2);
    session.press(CalculatorKey.delete);
    expect(session.snapshot.expression, '7!');
    expect(session.press(CalculatorKey.equals).result, Rational.fromInt(5040));
  });

  test('empty linear factorial defers syntax and AC clears only input', () {
    final session = CalculatorSession();
    expect(session.pressId('ACTION_FACTORIAL').phase, CalculatorPhase.editing);
    final failed = session.press(CalculatorKey.equals);
    expect(failed.error!.code, CalculatorErrorCode.syntax);
    expect(session.pressId('ACTION_FACTORIAL'), same(failed));
    expect(session.press(CalculatorKey.clear).expression, isEmpty);
  });

  test(
    'structured result continuation retains reduced exact Ans and old snapshot',
    () {
      final session = StructuredCalculatorSession();
      structured(session, '12/3');
      final old = session.press(CalculatorKey.equals);
      final pending = session.pressId('ACTION_FACTORIAL');
      expect(
        FractionEditor.fromSnapshot(pending.editor).toExpression(),
        'Ans!',
      );
      expect(pending.editor.root.nodes, hasLength(2));
      expect(pending.answer, same(old.answer));
      expect(session.press(CalculatorKey.equals).result, Rational.fromInt(24));
      expect(
        FractionEditor.fromSnapshot(session.press(CalculatorKey.delete).editor)
            .toExpression(),
        'Ans',
      );
      expect(FractionEditor.fromSnapshot(old.editor).toExpression(), '12/3');
    },
  );

  test(
    'structured fractional Ans fails at factorial without corrupting Ans',
    () {
      final session = StructuredCalculatorSession();
      structured(session, '1/2');
      session.press(CalculatorKey.equals);
      session.pressId('ACTION_FACTORIAL');
      final failed = session.press(CalculatorKey.equals);
      expect(failed.error!.code, CalculatorErrorCode.math);
      expect(failed.error!.position, 3);
      expect(failed.errorCursor!.offset, 1);
      expect(failed.answer.toString(), '1/2');
      expect(session.pressId('ACTION_FACTORIAL'), same(failed));
      expect(session.press(CalculatorKey.left).editor.cursor.offset, 1);
      session.press(CalculatorKey.right);
      expect(
        FractionEditor.fromSnapshot(session.press(CalculatorKey.delete).editor)
            .toExpression(),
        'Ans',
      );
    },
  );

  test('factorial in numerator maps domain error to field cursor', () {
    final session = StructuredCalculatorSession()..pressId('KEY_FRACTION');
    structured(session, '70!');
    session.pressId('KEY_DOWN');
    session.pressId('KEY_2');
    final projection = FractionEditor.fromSnapshot(session.snapshot.editor)
        .project();
    expect(projection.expression, '((70!)/(2))');
    expect(projection.cursorAt(4).path.single.field, FractionField.numerator);
    expect(projection.cursorAt(4).offset, 2);
    final failed = session.press(CalculatorKey.equals);
    expect(failed.error!.position, 4);
    expect(failed.errorCursor!.path.single.field, FractionField.numerator);
    expect(failed.errorCursor!.offset, 2);
    expect(failed.editor.cursor.path.single.field, FractionField.denominator);
    final reopened = session.press(CalculatorKey.left);
    expect(reopened.editor.cursor.path.single.field, FractionField.numerator);
    expect(reopened.editor.cursor.offset, 2);
  });

  test('factorial applies to selected field or whole reduced fraction', () {
    final editor = FractionEditor()
      ..insertFraction()
      ..insertText('4')
      ..insertText('!')
      ..moveDown()
      ..insertText('3');
    expect(editor.evaluate(), Rational.fromInt(8));
    editor.moveToRootEnd();
    editor.insertText('!');
    expect(editor.toExpression(), '((4!)/(3))!');
    expect(editor.evaluate(), Rational.fromInt(40320));
    expect(editor.project().cursorAt(10).path, isEmpty);
    editor.deleteBackward();
    expect(editor.evaluate(), Rational.fromInt(8));
  });

  test(
    'factorial editor-node limit is atomic and retains previous snapshots',
    () {
      final editor = FractionEditor();
      final session = StructuredCalculatorSession();
      for (var i = 0; i < 256; i++) {
        editor.insertText('1');
        session.press(CalculatorKey.digit1);
      }
      final before = editor.snapshot;
      final beforeSession = session.snapshot;
      expect(
        () => editor.insertText('!'),
        throwsA(error(CalculatorErrorCode.limit)),
      );
      expect(editor.snapshot, same(before));
      final failed = session.pressId('ACTION_FACTORIAL');
      expect(failed.error!.code, CalculatorErrorCode.limit);
      expect(failed.editor, same(beforeSession.editor));
    },
  );

  test('factorial capture requires an explicit closed group', () {
    final editor = FractionEditor()
      ..insertText('3')
      ..insertText('!');
    final before = editor.snapshot;
    expect(
      editor.wrapPreviousAtomInFraction,
      throwsA(error(CalculatorErrorCode.unsupported)),
    );
    expect(editor.snapshot, same(before));
    editor.clear();
    for (final token in ['(', '3', '!', ')']) {
      editor.insertText(token);
    }
    editor.wrapPreviousAtomInFraction();
    editor.insertText('2');
    expect(editor.evaluate(), Rational.fromInt(3));
  });
}
