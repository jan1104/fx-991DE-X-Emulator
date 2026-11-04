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
  'nPr' => CalculatorKey.permutation,
  'nCr' => CalculatorKey.combination,
  '-' => CalculatorKey.subtract,
  '+' => CalculatorKey.add,
  '/' => CalculatorKey.divide,
  '(' => CalculatorKey.leftParenthesis,
  ')' => CalculatorKey.rightParenthesis,
  _ => CalculatorKey.fromId('KEY_$token')!,
};

Iterable<String> tokens(String input) sync* {
  for (var i = 0; i < input.length;) {
    if (input.startsWith('nPr', i) || input.startsWith('nCr', i)) {
      yield input.substring(i, i + 3);
      i += 3;
    } else {
      yield input[i++];
    }
  }
}

void linear(CalculatorSession session, String input) {
  for (final token in tokens(input)) {
    session.press(key(token));
  }
}

void structured(StructuredCalculatorSession session, String input) {
  for (final token in tokens(input)) {
    session.press(key(token));
  }
}

const factorial69 =
    '171122452428141311372468338881272839092270544893520369393648040923257279754140647424000000000000000';
// Large constants independently obtained using Python math.perm/math.comb.
const maxTenPermutation =
    '9999999945000000131999999818500000157772999909794500034169299991590500001275357599893713600003628800';
const maxTenCombination =
    '2755731907242063528439153389136904805382771139162946437987571646712549603526057539653250000001';

void main() {
  // H PDF p.21 supplies 10 nPr 4 and 10 nCr 4. H p.51 specifies argument
  // and intermediate falling-product limits, not just a limit on final nCr.
  for (final (input, expected) in [
    ('10nPr4', '5040'),
    ('10nCr4', '210'),
    ('0nPr0', '1'),
    ('0nCr0', '1'),
    ('5nPr0', '1'),
    ('5nCr0', '1'),
    ('5nCr5', '1'),
    ('5nPr5', '120'),
    ('5nPr2', '20'),
    ('5nCr2', '10'),
    ('5nCr3', '10'),
    ('70nPr1', '70'),
    ('69nPr69', factorial69),
    ('100nCr50', '100891344545564193334812497256'),
    ('9999999999nPr0', '1'),
    ('9999999999nCr9999999999', '1'),
    ('9999999999nPr1', '9999999999'),
    ('9999999999nCr1', '9999999999'),
    ('9999999999nPr10', maxTenPermutation),
    ('9999999999nCr10', maxTenCombination),
    ('(20/2)nCr(8/2)', '210'),
    ('2*5nCr2', '20'),
    ('10nPr2*3', '270'),
    ('100/5nCr2', '10'),
    ('2(3)nPr2', '30'),
    ('2^3nPr2', '56'),
    ('10nPr2^2', '5040'),
    ('5nCr2nPr2', '90'),
    ('-(5nPr2)', '-20'),
    ('10 nCr 4', '210'),
  ]) {
    test('exact combinatorics and binding $input', () {
      expect(evaluate(input).toString(), expected);
    });
  }

  for (final input in [
    '-5nPr2',
    '5nCr-1',
    '5nCr6',
    '(1/2)nCr0',
    '5nPr(1/2)',
    '10000000000nPr0',
    '1e100nCr0',
    '70nPr70',
    '9999999999nPr11',
    '9999999999nCr11',
    '200nCr100',
    '1000000000nCr500000000',
  ]) {
    test('argument or intermediate domain rejects $input', () {
      expect(() => evaluate(input), throwsA(error(CalculatorErrorCode.math)));
    });
  }

  test('nCr intermediate bound is distinct from the final binomial result', () {
    // 200 choose 100 = 90548514656103281165404177077484163874504589675413336841320
    // is below 10^100, but BOTH relevant falling products exceed the H51 limit.
    expect(
      () => evaluate('200nCr100'),
      throwsA(error(CalculatorErrorCode.math, 3)),
    );
    expect(evaluate('100nCr50').toString(), '100891344545564193334812497256');
    expect(evaluate('100nCr99'), Rational.fromInt(100));
    expect(evaluate('100nCr1'), Rational.fromInt(100));
  });

  test(
    'binary AST is left-associated and uses the operator start position',
    () {
      final outer = parseExpression('5nCr2nPr2') as BinaryExpression;
      expect(outer.operator, BinaryOperator.permutation);
      expect(outer.position, 5);
      final inner = outer.left as BinaryExpression;
      expect(inner.operator, BinaryOperator.combination);
      expect(inner.position, 1);
      expect((inner.left as NumberExpression).value, Rational.fromInt(5));
      expect((inner.right as NumberExpression).value, Rational.fromInt(2));
    },
  );

  test(
    'registry distinguishes binary actions from physical and postfix keys',
    () {
      expect(CalculatorKey.values, hasLength(33));
      expect(CalculatorKey.values.map((key) => key.id).toSet(), hasLength(33));
      expect(
        CalculatorKey.fromId('ACTION_PERMUTATION'),
        CalculatorKey.permutation,
      );
      expect(
        CalculatorKey.fromId('ACTION_COMBINATION'),
        CalculatorKey.combination,
      );
      expect(CalculatorKey.fromId('KEY_NPR'), isNull);
      expect(CalculatorKey.permutation.isBinaryOperator, isTrue);
      expect(CalculatorKey.combination.isBinaryOperator, isTrue);
      expect(CalculatorKey.permutation.isPostfixOperator, isFalse);
      expect(CalculatorKey.combination.isPostfixOperator, isFalse);
    },
  );

  for (final input in ['nPr2', '2nCr', '2nPrnCr1', '2+nCr1', '(nPr)']) {
    test('binary combinatorics syntax requires both operands $input', () {
      expect(() => evaluate(input), throwsA(error(CalculatorErrorCode.syntax)));
    });
  }

  test('operator spelling is exact and errors retain source positions', () {
    for (final input in ['2npr1', '2NCR1', '2nP1']) {
      expect(
        () => evaluate(input),
        throwsA(error(CalculatorErrorCode.unsupported, 1)),
      );
    }
    expect(
      () => evaluate('5nPr+*2'),
      throwsA(error(CalculatorErrorCode.syntax, 5)),
    );
    expect(
      () => evaluate('(1/0)nPr2'),
      throwsA(error(CalculatorErrorCode.math, 2)),
    );
    expect(
      () => evaluate('5nCr(1/0)'),
      throwsA(error(CalculatorErrorCode.math, 6)),
    );
    expect(
      () => evaluate('Ans nPr 2'),
      throwsA(error(CalculatorErrorCode.unsupported, 0)),
    );
    expect(
      evaluate('Ans nCr 2', answer: Rational.fromInt(5)),
      Rational.fromInt(10),
    );
  });

  test('shared work budget includes bounded permutation products', () {
    final accepted = List.filled(28, '69nPr69').join('+');
    expect(
      evaluate(accepted).numerator,
      BigInt.parse(factorial69) * BigInt.from(28),
    );
    final rejected = List.filled(29, '69nPr69').join('+');
    expect(() => evaluate(rejected), throwsA(error(CalculatorErrorCode.limit)));
    expect(evaluate('10nPr4'), Rational.fromInt(5040));
  });

  test('shared combination work includes denominator and exact division', () {
    final expected = BigInt.parse('100891344545564193334812497256');
    expect(
      evaluate(List.filled(19, '100nCr50').join('+')).numerator,
      expected * BigInt.from(19),
    );
    expect(
      () => evaluate(List.filled(20, '100nCr50').join('+')),
      throwsA(error(CalculatorErrorCode.limit)),
    );
  });

  test('three-letter tokens still obey character and token budgets', () {
    expect(evaluate('${' ' * 2043}1nCr0'), Rational.fromInt(1));
    expect(
      () => evaluate('${' ' * 2044}1nCr0'),
      throwsA(error(CalculatorErrorCode.limit)),
    );
    expect(evaluate('1${'nCr1' * 255}'), Rational.fromInt(1));
    expect(
      () => parseExpression('1${'nCr1' * 256}'),
      throwsA(error(CalculatorErrorCode.limit, 1024)),
    );
  });

  test(
    'linear result uses exact Ans and deletes the entire operator token',
    () {
      final session = CalculatorSession();
      linear(session, '20/2');
      final old = session.press(CalculatorKey.equals);
      final pending = session.pressId('ACTION_PERMUTATION');
      expect(pending.tokens, ['Ans', 'nPr']);
      expect(pending.expression, 'AnsnPr');
      expect(pending.cursor, 2);
      expect(pending.cursorOffset, 6);
      session.press(CalculatorKey.digit4);
      expect(
        session.press(CalculatorKey.equals).result,
        Rational.fromInt(5040),
      );
      expect(old.result, Rational.fromInt(10));
      session.press(CalculatorKey.left);
      session.press(CalculatorKey.left);
      final deleted = session.press(CalculatorKey.delete);
      expect(deleted.expression, 'Ans4');
      expect(deleted.tokens, ['Ans', '4']);
    },
  );

  test(
    'linear domain errors preserve Ans and freeze until explicit navigation',
    () {
      final session = CalculatorSession();
      linear(session, '7');
      session.press(CalculatorKey.equals);
      session.press(CalculatorKey.clear);
      linear(session, '5nCr6');
      final failed = session.press(CalculatorKey.equals);
      expect(failed.error!.code, CalculatorErrorCode.math);
      expect(failed.error!.position, 1);
      expect(failed.answer, Rational.fromInt(7));
      expect(session.pressId('ACTION_COMBINATION'), same(failed));
      session.press(CalculatorKey.left);
      expect(session.snapshot.phase, CalculatorPhase.editing);
      expect(session.press(CalculatorKey.clear).answer, Rational.fromInt(7));
    },
  );

  test(
    'structured result continuation preserves reduced exact Ans and old tree',
    () {
      final session = StructuredCalculatorSession();
      structured(session, '20/2');
      final old = session.press(CalculatorKey.equals);
      final pending = session.pressId('ACTION_COMBINATION');
      expect(pending.editor.root.nodes, hasLength(2));
      expect(
        FractionEditor.fromSnapshot(pending.editor).toExpression(),
        'AnsnCr',
      );
      session.press(CalculatorKey.digit4);
      expect(session.press(CalculatorKey.equals).result, Rational.fromInt(210));
      expect(FractionEditor.fromSnapshot(old.editor).toExpression(), '20/2');
      session.press(CalculatorKey.left);
      session.press(CalculatorKey.left);
      expect(
        FractionEditor.fromSnapshot(session.press(CalculatorKey.delete).editor)
            .toExpression(),
        'Ans4',
      );
    },
  );

  test(
    'fractional Ans is bound as one value and rejected without rounding',
    () {
      final session = StructuredCalculatorSession();
      structured(session, '1/2');
      session.press(CalculatorKey.equals);
      session.pressId('ACTION_COMBINATION');
      session.press(CalculatorKey.digit0);
      final failed = session.press(CalculatorKey.equals);
      expect(failed.error!.code, CalculatorErrorCode.math);
      expect(failed.error!.position, 3);
      expect(failed.answer.toString(), '1/2');
      expect(session.pressId('ACTION_PERMUTATION'), same(failed));
    },
  );

  test(
    'editor projection maps all three operator characters to one field token',
    () {
      final editor = FractionEditor()
        ..insertFraction()
        ..insertText('5')
        ..insertText('nCr')
        ..insertText('2')
        ..moveDown()
        ..insertText('2');
      final projection = editor.project();
      expect(projection.expression, '((5nCr2)/(2))');
      for (final position in [3, 4, 5]) {
        expect(projection.cursorAt(position).offset, 1);
        expect(
          projection.cursorAt(position).path.single.field,
          FractionField.numerator,
        );
      }
      expect(projection.cursorAt(6).offset, 2);
      expect(editor.evaluate(), Rational.fromInt(5));
      editor.moveTo(projection.cursorAt(6));
      editor.deleteBackward();
      expect(editor.toExpression(), '((52)/(2))');
    },
  );

  test('structured field domain failure points to binary operator and recovers there', () {
    final session = StructuredCalculatorSession()..pressId('KEY_FRACTION');
    structured(session, '5nCr6');
    session.pressId('KEY_DOWN');
    session.pressId('KEY_2');
    final failed = session.press(CalculatorKey.equals);
    expect(failed.error!.position, 3);
    expect(failed.errorCursor!.path.single.field, FractionField.numerator);
    expect(failed.errorCursor!.offset, 1);
    expect(session.pressId('ACTION_COMBINATION'), same(failed));
    final restored = session.press(CalculatorKey.left);
    expect(restored.editor.cursor.path.single.field, FractionField.numerator);
    expect(restored.editor.cursor.offset, 1);
  });

  test('editor node limit rejects a whole combinatorics token atomically', () {
    final editor = FractionEditor();
    for (var i = 0; i < 256; i++) {
      editor.insertText('1');
    }
    final before = editor.snapshot;
    expect(
      () => editor.insertText('nCr'),
      throwsA(error(CalculatorErrorCode.limit)),
    );
    expect(editor.snapshot, same(before));
  });

  test('binary operator itself cannot be captured as a numerator atom', () {
    final editor = FractionEditor()
      ..insertText('5')
      ..insertText('nCr');
    final before = editor.snapshot;
    expect(
      editor.wrapPreviousAtomInFraction,
      throwsA(error(CalculatorErrorCode.unsupported)),
    );
    expect(editor.snapshot, same(before));
    editor.clear();
    for (final token in ['(', '5', 'nCr', '2', ')']) {
      editor.insertText(token);
    }
    editor.wrapPreviousAtomInFraction();
    editor.insertText('2');
    expect(editor.evaluate(), Rational.fromInt(5));
  });
}
