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

CalculatorKey key(String character) => switch (character) {
  '%' => CalculatorKey.percent,
  '-' => CalculatorKey.subtract,
  '+' => CalculatorKey.add,
  '*' => CalculatorKey.multiply,
  '/' => CalculatorKey.divide,
  '(' => CalculatorKey.leftParenthesis,
  ')' => CalculatorKey.rightParenthesis,
  _ => CalculatorKey.fromId('KEY_$character')!,
};

void enterLinear(CalculatorSession session, String source) {
  for (final character in source.split('')) {
    session.press(key(character));
  }
}

void enterStructured(StructuredCalculatorSession session, String source) {
  for (final character in source.split('')) {
    session.press(key(character));
  }
}

void main() {
  // H PDF p.13: three independent percent examples. Other entries specify the
  // own prototype grammar; mixed powers are not original-compatibility proofs.
  for (final (input, expected) in [
    ('150*20%', '30'),
    ('660/880%', '75'),
    ('3500-3500*25%', '2625'),
    ('25%', '1/4'),
    ('25%%', '1/400'),
    ('0%', '0'),
    ('-25%', '-1/4'),
    ('(-25)%', '-1/4'),
    ('(2/3)%', '1/150'),
    ('0,1%', '1/1000'),
    ('200+10%', '2001/10'),
    ('200-10%', '1999/10'),
    ('20%²', '1/25'),
    ('20²%', '4'),
    ('20%³', '1/125'),
    ('20³%', '80'),
    ('20%⁻¹', '5'),
    ('20⁻¹%', '1/2000'),
    ('20%^2', '1/25'),
    ('2%^2', '1/2500'),
    ('2^100%', '2'),
    ('2^3^2', '512'),
    ('50%(2)', '1'),
    ('2(50)%', '1'),
  ]) {
    test('exact percent and own postfix grammar $input', () {
      expect(evaluate(input).toString(), expected);
    });
  }

  test('percent AST divides by exactly 100 at its own source position', () {
    final square = parseExpression('20%²') as BinaryExpression;
    final percent = square.left as BinaryExpression;
    expect(square.operator, BinaryOperator.power);
    expect(square.position, 3);
    expect(percent.operator, BinaryOperator.divide);
    expect(percent.position, 2);
    expect((percent.left as NumberExpression).value, Rational.fromInt(20));
    expect((percent.right as NumberExpression).value, Rational.fromInt(100));
    expect(percent.right.position, 2);
  });

  test(
    'own postfix grammar keeps percent inside the ordinary power operand',
    () {
      // This is the current own parser contract, not an observed Casio result.
      expect(
        () => evaluate('2^3%'),
        throwsA(error(CalculatorErrorCode.unsupported, 1)),
      );
    },
  );

  test('percent is a secondary semantic postfix and not a physical key ID', () {
    expect(CalculatorKey.values, hasLength(33));
    expect(CalculatorKey.values.map((key) => key.id).toSet(), hasLength(33));
    expect(CalculatorKey.fromId('ACTION_PERCENT'), CalculatorKey.percent);
    expect(CalculatorKey.fromId('KEY_PERCENT'), isNull);
    expect(CalculatorKey.percent.text, '%');
    expect(CalculatorKey.percent.isPostfixOperator, isTrue);
    expect(CalculatorKey.percent.isBinaryOperator, isFalse);
  });

  for (final input in ['%', '1+%', '(%)', '2^%', '2%3']) {
    test('invalid percent placement $input reports syntax', () {
      expect(() => evaluate(input), throwsA(error(CalculatorErrorCode.syntax)));
    });
  }

  test('following syntax and reciprocal-zero point at their own token', () {
    expect(
      () => evaluate('2%+*3'),
      throwsA(error(CalculatorErrorCode.syntax, 3)),
    );
    expect(() => evaluate('0%⁻¹'), throwsA(error(CalculatorErrorCode.math, 2)));
    expect(
      () => evaluate('Ans%'),
      throwsA(error(CalculatorErrorCode.unsupported, 0)),
    );
    expect(
      evaluate(
        'Ans%',
        answer: Rational(BigInt.from(-2), BigInt.from(3)),
      ).toString(),
      '-1/150',
    );
  });

  test(
    'percent leaves character, token and evaluation-depth limits intact',
    () {
      expect(evaluate('${' ' * 2046}1%').toString(), '1/100');
      expect(
        () => evaluate('${' ' * 2047}1%'),
        throwsA(error(CalculatorErrorCode.limit)),
      );
      expect(
        () => parseExpression('1${'%' * 512}'),
        throwsA(error(CalculatorErrorCode.limit, 512)),
      );
      expect(
        () => evaluate('1${'%' * 300}'),
        throwsA(error(CalculatorErrorCode.limit)),
      );
    },
  );

  test(
    'linear percent continues exact negative Ans without rewriting text',
    () {
      final session = CalculatorSession();
      enterLinear(session, '-2/3');
      final before = session.press(CalculatorKey.equals);
      final pending = session.pressId('ACTION_PERCENT');
      expect(pending.tokens, ['Ans', '%']);
      expect(pending.cursor, 2);
      expect(pending.answer, same(before.answer));
      final result = session.press(CalculatorKey.equals);
      expect(result.result.toString(), '-1/150');
      expect(session.press(CalculatorKey.equals), same(result));
      expect(before.answer.toString(), '-2/3');
      expect(session.press(CalculatorKey.delete).expression, 'Ans');
      expect(session.snapshot.answer.toString(), '-1/150');
    },
  );

  test(
    'percent division enforces the exact rational size budget at percent',
    () {
      final nearLimit = Rational(BigInt.one, BigInt.one << 99995);
      expect(evaluate('Ans', answer: nearLimit), nearLimit);
      expect(
        () => evaluate('Ans%', answer: nearLimit),
        throwsA(error(CalculatorErrorCode.limit, 3)),
      );
    },
  );

  test('linear percent inserts and deletes one token at a middle cursor', () {
    final session = CalculatorSession();
    enterLinear(session, '20+3');
    session.press(CalculatorKey.left);
    session.press(CalculatorKey.left);
    expect(session.pressId('ACTION_PERCENT').expression, '20%+3');
    expect(session.press(CalculatorKey.delete).expression, '20+3');
    expect(session.snapshot.cursor, 2);
  });

  test(
    'linear empty percent defers error, freezes and recovers at error site',
    () {
      final session = CalculatorSession();
      enterLinear(session, '7');
      session.press(CalculatorKey.equals);
      session.press(CalculatorKey.clear);
      expect(session.pressId('ACTION_PERCENT').expression, '%');
      final failed = session.press(CalculatorKey.equals);
      expect(failed.error!.code, CalculatorErrorCode.syntax);
      expect(session.pressId('ACTION_PERCENT'), same(failed));
      expect(session.press(CalculatorKey.left).cursor, 0);
      session.press(CalculatorKey.digit2);
      expect(session.press(CalculatorKey.equals).result.toString(), '1/50');
      expect(failed.answer, Rational.fromInt(7));
    },
  );

  test('linear full-input percent is rejected atomically', () {
    final session = CalculatorSession();
    for (var i = 0; i < 2048; i++) {
      session.press(CalculatorKey.digit1);
    }
    final before = session.snapshot;
    final failed = session.pressId('ACTION_PERCENT');
    expect(failed.phase, CalculatorPhase.error);
    expect(failed.error!.code, CalculatorErrorCode.limit);
    expect(failed.tokens, before.tokens);
    expect(failed.cursor, before.cursor);
    expect(before.phase, CalculatorPhase.editing);
  });

  test(
    'structured percent preserves exact Ans and immutable editor snapshots',
    () {
      final session = StructuredCalculatorSession();
      enterStructured(session, '-2/3');
      final before = session.press(CalculatorKey.equals);
      final pending = session.pressId('ACTION_PERCENT');
      expect(
        FractionEditor.fromSnapshot(pending.editor).toExpression(),
        'Ans%',
      );
      expect(pending.editor.root.nodes, hasLength(2));
      expect(pending.answer, same(before.answer));
      expect(session.press(CalculatorKey.equals).result.toString(), '-1/150');
      expect(FractionEditor.fromSnapshot(before.editor).toExpression(), '-2/3');
      expect(
        FractionEditor.fromSnapshot(session.press(CalculatorKey.delete).editor)
            .toExpression(),
        'Ans',
      );
    },
  );

  test('structured percent syntax freezes until navigation or AC', () {
    final session = StructuredCalculatorSession();
    expect(session.pressId('ACTION_PERCENT').phase, CalculatorPhase.editing);
    final failed = session.press(CalculatorKey.equals);
    expect(failed.error!.code, CalculatorErrorCode.syntax);
    expect(session.pressId('ACTION_PERCENT'), same(failed));
    expect(failed.errorCursor!.offset, 0);
    expect(session.press(CalculatorKey.left).editor.cursor.offset, 0);
    session.press(CalculatorKey.digit2);
    expect(session.press(CalculatorKey.equals).result.toString(), '1/50');
    expect(session.press(CalculatorKey.clear).editor.root.nodes, isEmpty);
  });

  test('percent source-map and following syntax remain in numerator field', () {
    final session = StructuredCalculatorSession()..pressId('KEY_FRACTION');
    enterStructured(session, '2%+*3');
    session.pressId('KEY_DOWN');
    session.pressId('KEY_1');
    final projection = FractionEditor.fromSnapshot(session.snapshot.editor)
        .project();
    expect(projection.expression, '((2%+*3)/(1))');
    expect(projection.cursorAt(3).offset, 1);
    expect(projection.cursorAt(3).path.single.field, FractionField.numerator);
    final failed = session.press(CalculatorKey.equals);
    expect(failed.error!.position, 5);
    expect(failed.errorCursor!.offset, 3);
    expect(failed.errorCursor!.path.single.field, FractionField.numerator);
    expect(failed.editor.cursor.path.single.field, FractionField.denominator);
    final restored = session.press(CalculatorKey.left);
    expect(restored.editor.cursor.path.single.field, FractionField.numerator);
    expect(restored.editor.cursor.offset, 3);
  });

  test('percent applies inside or outside the whole structured fraction', () {
    final editor = FractionEditor()
      ..insertFraction()
      ..insertText('2')
      ..insertText('%')
      ..moveDown()
      ..insertText('3');
    expect(editor.evaluate().toString(), '1/150');
    editor.moveToRootEnd();
    editor.insertText('%');
    expect(editor.toExpression(), '((2%)/(3))%');
    expect(editor.evaluate().toString(), '1/15000');
    expect(editor.project().cursorAt(10).path, isEmpty);
    editor.deleteBackward();
    expect(editor.toExpression(), '((2%)/(3))');
  });

  test('percent editor-node limit preserves previous immutable editor', () {
    final editor = FractionEditor();
    final session = StructuredCalculatorSession();
    for (var i = 0; i < 256; i++) {
      editor.insertText('1');
      session.press(CalculatorKey.digit1);
    }
    final before = editor.snapshot;
    final beforeSession = session.snapshot;
    expect(
      () => editor.insertText('%'),
      throwsA(error(CalculatorErrorCode.limit)),
    );
    expect(editor.snapshot, same(before));
    final failed = session.pressId('ACTION_PERCENT');
    expect(failed.error!.code, CalculatorErrorCode.limit);
    expect(failed.editor, same(beforeSession.editor));
  });

  test('whole percent terms need explicit grouping for fraction capture', () {
    final editor = FractionEditor()
      ..insertText('2')
      ..insertText('%');
    final before = editor.snapshot;
    expect(
      editor.wrapPreviousAtomInFraction,
      throwsA(error(CalculatorErrorCode.unsupported)),
    );
    expect(editor.snapshot, same(before));
    editor.clear();
    for (final text in ['(', '2', '%', ')']) {
      editor.insertText(text);
    }
    editor.wrapPreviousAtomInFraction();
    editor.insertText('3');
    expect(editor.evaluate().toString(), '1/150');
  });
}
