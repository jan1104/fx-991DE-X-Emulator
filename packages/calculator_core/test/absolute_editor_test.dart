import 'package:calculator_core/calculator_core.dart';
import 'package:test/test.dart';

void write(FractionEditor e, String source) {
  for (final token in source.split('')) {
    e.insertText(token);
  }
}

Matcher code(CalculatorErrorCode code) =>
    isA<CalculatorException>().having((e) => e.code, 'code', code);
String expression(FractionEditor e) => e.toExpression();
List<Object> path(EditorCursor c) => [
  for (final s in c.path) (s.nodeIndex, s.field),
  c.offset,
];
FractionEditor absolute(String source) {
  final editor = FractionEditor()..insertAbsolute();
  write(editor, source);
  return editor;
}

void keys(CalculatorSession s, List<String> ids) {
  for (final id in ids) {
    s.pressId(id);
  }
}

void skeys(StructuredCalculatorSession s, List<String> ids) {
  for (final id in ids) {
    s.pressId(id);
  }
}

void main() {
  test('field enum preserves the two original values and appends argument', () {
    expect(FractionField.numerator.index, 0);
    expect(FractionField.denominator.index, 1);
    expect(FractionField.argument.index, 2);
  });
  test(
    'new secondary action is neither binary nor postfix and has atomic text',
    () {
      expect(CalculatorKey.values, hasLength(34));
      expect(CalculatorKey.fromId('ACTION_ABS'), CalculatorKey.absolute);
      expect(CalculatorKey.absolute.text, 'Abs(');
      expect(CalculatorKey.absolute.isBinaryOperator, isFalse);
      expect(CalculatorKey.absolute.isPostfixOperator, isFalse);
      expect(CalculatorKey.fromId('KEY_ABS'), isNull);
    },
  );
  test('insertion creates an immutable one-field template and enters it', () {
    final e = FractionEditor();
    final before = e.snapshot;
    e.insertAbsolute();
    final node = e.snapshot.root.nodes.single as EditorAbsolute;
    expect(node.argument.nodes, isEmpty);
    expect(path(e.snapshot.cursor), [(0, FractionField.argument), 0]);
    expect(before.root.nodes, isEmpty);
    expect(() => node.argument.nodes.clear(), throwsUnsupportedError);
    expect(() => e.snapshot.root.nodes.clear(), throwsUnsupportedError);
  });
  test('structured editor rejects a loose prefix token atomically', () {
    final editor = FractionEditor();
    final before = editor.snapshot;
    expect(() => editor.insertText('Abs('), throwsArgumentError);
    expect(editor.snapshot, same(before));
  });
  test('empty argument is a targeted structural syntax error', () {
    final e = FractionEditor()..insertAbsolute();
    final old = e.snapshot;
    try {
      e.project();
      fail('Expected an empty argument error');
    } on EditorProjectionException catch (d) {
      expect(d.error.code, CalculatorErrorCode.syntax);
      expect(path(d.cursor), [(0, FractionField.argument), 0]);
    }
    expect(e.toExpression, throwsA(code(CalculatorErrorCode.syntax)));
    expect(e.snapshot, same(old));
  });
  for (final (source, expected) in [
    ('2-7', '5'),
    ('-2/3', '2/3'),
    ('0', '0'),
    ('1+2', '3'),
  ]) {
    test('structured argument evaluates exactly: $source', () {
      final e = absolute(source);
      expect(e.evaluate().toString(), expected);
      expect(expression(e), '(Abs($source))');
    });
  }
  test('handbook right exit makes multiplication outside the argument', () {
    final e = absolute('2-7');
    e.moveRight();
    write(e, '*2');
    expect(expression(e), '(Abs(2-7))*2');
    expect(e.evaluate(), Rational.fromInt(10));
    expect(e.snapshot.cursor.path, isEmpty);
  });
  test(
    'adjacent scalar and structured absolute retain implicit multiplication',
    () {
      final e = FractionEditor();
      write(e, '2');
      e.insertAbsolute();
      write(e, '-3');
      expect(expression(e), '2(Abs(-3))');
      expect(e.evaluate(), Rational.fromInt(6));
    },
  );
  test('left and right enter and leave exactly one argument', () {
    final e = absolute('23');
    e.moveRight();
    expect(path(e.snapshot.cursor), [1]);
    e.moveLeft();
    expect(path(e.snapshot.cursor), [(0, FractionField.argument), 2]);
    e.moveLeft();
    e.moveLeft();
    expect(path(e.snapshot.cursor), [(0, FractionField.argument), 0]);
    e.moveLeft();
    expect(path(e.snapshot.cursor), [0]);
    e.moveRight();
    expect(path(e.snapshot.cursor), [(0, FractionField.argument), 0]);
  });
  test('nested argument exit leaves only its immediate template', () {
    final e = FractionEditor()
      ..insertAbsolute()
      ..insertAbsolute();
    write(e, '-3');
    e.moveRight();
    expect(path(e.snapshot.cursor), [(0, FractionField.argument), 1]);
    write(e, '-5');
    expect(e.evaluate(), Rational.fromInt(2));
    e.moveRight();
    expect(path(e.snapshot.cursor), [1]);
    e.moveLeft();
    expect(path(e.snapshot.cursor), [(0, FractionField.argument), 3]);
  });
  test('up and down do not escape an argument into an outer fraction', () {
    final e = FractionEditor()
      ..insertFraction()
      ..insertAbsolute();
    write(e, '3');
    final old = e.snapshot;
    e.moveDown();
    expect(e.snapshot, same(old));
    e.moveUp();
    expect(e.snapshot, same(old));
    e.moveRight();
    e.moveDown();
    write(e, '2');
    expect(e.evaluate().toString(), '3/2');
  });
  test('fraction navigation resolves argument ancestors and clamps fields', () {
    final e = FractionEditor()
      ..insertAbsolute()
      ..insertFraction();
    write(e, '12');
    e.moveDown();
    expect(e.snapshot.cursor.offset, 0);
    write(e, '3');
    e.moveUp();
    expect(e.snapshot.cursor.offset, 1);
    expect(e.snapshot.cursor.path.last.field, FractionField.numerator);
    e.moveDown();
    expect(e.snapshot.cursor.offset, 1);
    expect(e.evaluate(), Rational.fromInt(4));
  });
  test('DEL at empty argument start removes only its own template', () {
    final e = FractionEditor();
    write(e, '2+');
    e.insertAbsolute();
    final old = e.snapshot;
    e.deleteBackward();
    expect(expression(e), '2+');
    expect(path(e.snapshot.cursor), [2]);
    expect(old.root.nodes.last, isA<EditorAbsolute>());
  });
  test(
    'DEL at nonempty argument start is protected and does not delete parent',
    () {
      final e = absolute('5');
      e.moveLeft();
      final before = e.snapshot;
      e.deleteBackward();
      expect(e.snapshot, same(before));
      expect(expression(e), '(Abs(5))');
    },
  );
  test(
    'DEL inside argument removes one token and preserves prior snapshots',
    () {
      final e = absolute('-25');
      final old = e.snapshot;
      e.deleteBackward();
      expect(expression(e), '(Abs(-2))');
      expect(FractionEditor.fromSnapshot(old).toExpression(), '(Abs(-25))');
    },
  );
  test('DEL outside removes complete nonempty subtree atomically', () {
    final e = absolute('2-7');
    e.moveRight();
    final old = e.snapshot;
    e.deleteBackward();
    expect(e.snapshot.root.nodes, isEmpty);
    expect(path(e.snapshot.cursor), [0]);
    expect(FractionEditor.fromSnapshot(old).evaluate(), Rational.fromInt(5));
  });
  test('DEL of nested empty argument keeps surrounding argument', () {
    final e = absolute('3');
    e.insertAbsolute();
    e.deleteBackward();
    expect(expression(e), '(Abs(3))');
    expect(path(e.snapshot.cursor), [(0, FractionField.argument), 1]);
  });
  test('projection maps every generated function boundary separately', () {
    final e = absolute('2-7');
    final p = e.project();
    expect(p.expression, '(Abs(2-7))');
    expect(path(p.cursorAt(0)), [0]);
    for (final offset in [1, 2, 3, 4]) {
      expect(path(p.cursorAt(offset)), [(0, FractionField.argument), 0]);
    }
    expect(path(p.cursorAt(5)), [(0, FractionField.argument), 0]);
    expect(path(p.cursorAt(6)), [(0, FractionField.argument), 1]);
    expect(path(p.cursorAt(7)), [(0, FractionField.argument), 2]);
    expect(path(p.cursorAt(8)), [(0, FractionField.argument), 3]);
    expect(path(p.cursorAt(9)), [1]);
    expect(path(p.cursorAt(10)), [1]);
  });
  for (final input in [')', '(']) {
    test('user parentheses cannot consume generated delimiters: $input', () {
      final e = absolute(input);
      expect(
        e.project,
        throwsA(
          isA<EditorProjectionException>().having(
            (d) => d.cursor.path.last.field,
            'field',
            FractionField.argument,
          ),
        ),
      );
    });
  }
  test('matching user parentheses remain within an argument', () {
    final e = absolute('(2-7)*2');
    expect(e.evaluate(), Rational.fromInt(10));
  });
  test(
    'argument cursors are rejected on a fraction at the same node index',
    () {
      final a = absolute('1');
      final b = FractionEditor()..insertFraction();
      final old = b.snapshot;
      expect(() => b.moveTo(a.snapshot.cursor), throwsArgumentError);
      expect(b.snapshot, same(old));
    },
  );
  test(
    'fraction cursors are rejected on an absolute at the same node index',
    () {
      final a = absolute('1');
      final b = FractionEditor()..insertFraction();
      final old = a.snapshot;
      expect(() => a.moveTo(b.snapshot.cursor), throwsArgumentError);
      expect(a.snapshot, same(old));
    },
  );
  test(
    'older too-long argument offsets are rejected without changing state',
    () {
      final e = absolute('123');
      final cursor = e.snapshot.cursor;
      e.deleteBackward();
      final old = e.snapshot;
      expect(() => e.moveTo(cursor), throwsArgumentError);
      expect(e.snapshot, same(old));
    },
  );
  test('full absolute node can be captured as a numerator', () {
    final e = absolute('2-7');
    e.moveRight();
    e.wrapPreviousAtomInFraction();
    write(e, '2');
    expect(e.evaluate().toString(), '5/2');
    final f = e.snapshot.root.nodes.single as EditorFraction;
    expect(f.numerator.nodes.single, isA<EditorAbsolute>());
  });
  test('fraction capture inside argument stays inside that argument', () {
    final e = absolute('-3');
    e.wrapPreviousAtomInFraction();
    write(e, '2');
    expect(e.evaluate().toString(), '3/2');
    expect(e.snapshot.cursor.path.first.field, FractionField.argument);
  });
  test('postfix outside an absolute is not guessed as a capture term', () {
    final e = absolute('3');
    e.moveRight();
    write(e, '²');
    final old = e.snapshot;
    expect(
      e.wrapPreviousAtomInFraction,
      throwsA(code(CalculatorErrorCode.unsupported)),
    );
    expect(e.snapshot, same(old));
  });
  test('node budget counts descendants of absolute fields', () {
    final e = FractionEditor()..insertAbsolute();
    for (var i = 0; i < 255; i++) {
      e.insertText('1');
    }
    final old = e.snapshot;
    expect(() => e.insertText('2'), throwsA(code(CalculatorErrorCode.limit)));
    expect(e.snapshot, same(old));
    expect(e.insertAbsolute, throwsA(code(CalculatorErrorCode.limit)));
    expect(e.snapshot, same(old));
  });
  test('mixed template depth rejects level seventeen atomically', () {
    final e = FractionEditor();
    for (var i = 0; i < 16; i++) {
      if (i.isEven) {
        e.insertAbsolute();
      } else {
        e.insertFraction();
      }
    }
    final old = e.snapshot;
    expect(e.insertAbsolute, throwsA(code(CalculatorErrorCode.limit)));
    expect(e.snapshot, same(old));
    expect(e.insertFraction, throwsA(code(CalculatorErrorCode.limit)));
    expect(e.snapshot, same(old));
    e.insertText('1');
    expect(e.snapshot.cursor.path, hasLength(16));
  });
  test('capture checks hidden absolute descendants at maximum depth', () {
    final e = FractionEditor();
    for (var i = 0; i < 16; i++) {
      e.insertAbsolute();
    }
    write(e, '1');
    e.moveToRootEnd();
    final old = e.snapshot;
    expect(
      e.wrapPreviousAtomInFraction,
      throwsA(code(CalculatorErrorCode.limit)),
    );
    expect(e.snapshot, same(old));
  });
  test('capture at depth fifteen makes a legal sixteenth template', () {
    final e = FractionEditor();
    for (var i = 0; i < 15; i++) {
      e.insertAbsolute();
    }
    write(e, '1');
    e.moveToRootEnd();
    e.wrapPreviousAtomInFraction();
    write(e, '2');
    expect(e.evaluate().toString(), '1/2');
  });
  test('linear prefix insertion and DEL are atomic four-character actions', () {
    final s = CalculatorSession();
    keys(s, ['KEY_2', 'ACTION_ABS']);
    expect(s.snapshot.tokens, ['2', 'Abs(']);
    expect(s.snapshot.cursorOffset, 5);
    s.press(CalculatorKey.left);
    expect(s.snapshot.cursorOffset, 1);
    s.press(CalculatorKey.right);
    s.press(CalculatorKey.delete);
    expect(s.snapshot.expression, '2');
  });
  test('linear handbook input requires a closing parenthesis', () {
    final s = CalculatorSession();
    keys(s, [
      'ACTION_ABS',
      'KEY_2',
      'KEY_SUBTRACT',
      'KEY_7',
      'KEY_RPAREN',
      'KEY_MULTIPLY',
      'KEY_2',
      'KEY_EQUALS',
    ]);
    expect(s.snapshot.result, Rational.fromInt(10));
  });
  test(
    'linear result continuation binds negative Ans until explicit close',
    () {
      final s = CalculatorSession();
      keys(s, ['KEY_NEGATE', 'KEY_2', 'KEY_DIVIDE', 'KEY_3', 'KEY_EQUALS']);
      final old = s.snapshot;
      s.selectResultDisplayFormat(RationalDisplayFormat.exactDecimal);
      s.pressId('ACTION_ABS');
      expect(s.snapshot.tokens, ['Abs(', 'Ans']);
      expect(s.snapshot.answer.toString(), '-2/3');
      expect(s.snapshot.resultDisplayFormat, RationalDisplayFormat.fraction);
      keys(s, ['KEY_RPAREN', 'KEY_EQUALS']);
      expect(s.snapshot.result.toString(), '2/3');
      expect(old.result.toString(), '-2/3');
    },
  );
  test('linear missing-close syntax freezes and navigation resumes at end', () {
    final s = CalculatorSession();
    keys(s, ['ACTION_ABS', 'KEY_5', 'KEY_EQUALS']);
    final old = s.snapshot;
    expect(old.error!.code, CalculatorErrorCode.syntax);
    expect(s.pressId('ACTION_ABS'), same(old));
    keys(s, ['KEY_LEFT', 'KEY_RPAREN', 'KEY_EQUALS']);
    expect(s.snapshot.result, Rational.fromInt(5));
  });
  test('linear prefix length guard retains input and cursor on rejection', () {
    final s = CalculatorSession();
    for (var i = 0; i < 2046; i++) {
      s.press(CalculatorKey.digit1);
    }
    final old = s.snapshot;
    final failed = s.pressId('ACTION_ABS');
    expect(failed.phase, CalculatorPhase.error);
    expect(failed.error!.code, CalculatorErrorCode.limit);
    expect(failed.tokens, old.tokens);
    expect(failed.cursor, old.cursor);
  });
  test(
    'structured action enters an empty absolute and projects the handbook',
    () {
      final s = StructuredCalculatorSession();
      skeys(s, [
        'ACTION_ABS',
        'KEY_2',
        'KEY_SUBTRACT',
        'KEY_7',
        'KEY_RIGHT',
        'KEY_MULTIPLY',
        'KEY_2',
        'KEY_EQUALS',
      ]);
      expect(s.snapshot.result, Rational.fromInt(10));
      expect(s.snapshot.editor.root.nodes.first, isA<EditorAbsolute>());
    },
  );
  test(
    'structured result continuation binds exact fractional Ans inside field',
    () {
      final s = StructuredCalculatorSession();
      skeys(s, ['KEY_NEGATE', 'KEY_2', 'KEY_DIVIDE', 'KEY_3', 'KEY_EQUALS']);
      final old = s.snapshot;
      s.selectResultDisplayFormat(RationalDisplayFormat.exactDecimal);
      final pending = s.pressId('ACTION_ABS');
      expect(path(pending.editor.cursor), [(0, FractionField.argument), 1]);
      expect(pending.resultDisplayFormat, RationalDisplayFormat.fraction);
      expect(
        FractionEditor.fromSnapshot(pending.editor).toExpression(),
        '(Abs(Ans))',
      );
      expect(s.pressId('KEY_EQUALS').result.toString(), '2/3');
      expect(old.result.toString(), '-2/3');
    },
  );
  test(
    'structured empty argument freezes then resumes exactly in that field',
    () {
      final s = StructuredCalculatorSession();
      skeys(s, ['ACTION_ABS', 'KEY_EQUALS']);
      final failed = s.snapshot;
      expect(failed.error!.code, CalculatorErrorCode.syntax);
      expect(path(failed.errorCursor!), [(0, FractionField.argument), 0]);
      expect(s.pressId('ACTION_ABS'), same(failed));
      skeys(s, ['KEY_RIGHT', 'KEY_5', 'KEY_EQUALS']);
      expect(s.snapshot.result, Rational.fromInt(5));
    },
  );
  test(
    'inner zero denominator maps through absolute ancestors and recovers',
    () {
      final s = StructuredCalculatorSession();
      skeys(s, [
        'ACTION_ABS',
        'KEY_FRACTION',
        'KEY_1',
        'KEY_DOWN',
        'KEY_0',
        'KEY_EQUALS',
      ]);
      final failed = s.snapshot;
      expect(failed.error!.code, CalculatorErrorCode.math);
      expect(path(failed.errorCursor!), [
        (0, FractionField.argument),
        (0, FractionField.denominator),
        1,
      ]);
      skeys(s, ['KEY_LEFT', 'KEY_DEL', 'KEY_2', 'KEY_EQUALS']);
      expect(s.snapshot.result.toString(), '1/2');
    },
  );
  test(
    'structured resource rejection keeps the complete prior editor and Ans',
    () {
      final s = StructuredCalculatorSession();
      for (var i = 0; i < 16; i++) {
        s.pressId('ACTION_ABS');
      }
      final old = s.snapshot;
      final failed = s.pressId('ACTION_ABS');
      expect(failed.error!.code, CalculatorErrorCode.limit);
      expect(failed.editor, same(old.editor));
      expect(failed.answer, same(old.answer));
    },
  );
  test('AC clears templates but retains exact Ans for later function use', () {
    final s = StructuredCalculatorSession();
    skeys(s, ['KEY_NEGATE', 'KEY_5', 'KEY_EQUALS', 'ACTION_ABS', 'KEY_AC']);
    expect(s.snapshot.editor.root.nodes, isEmpty);
    expect(s.snapshot.answer, Rational.fromInt(-5));
    skeys(s, ['ACTION_ABS', 'KEY_ANS', 'KEY_EQUALS']);
    expect(s.snapshot.result, Rational.fromInt(5));
  });
}
