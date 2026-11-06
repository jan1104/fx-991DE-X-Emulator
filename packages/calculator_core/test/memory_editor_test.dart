import 'package:calculator_core/calculator_core.dart';
import 'package:test/test.dart';

List<Object> path(EditorCursor cursor) => [
  for (final step in cursor.path) (step.nodeIndex, step.field),
  cursor.offset,
];

Matcher failure(CalculatorErrorCode code, int position) =>
    isA<CalculatorException>()
        .having((error) => error.code, 'code', code)
        .having((error) => error.position, 'position', position);

void main() {
  test('M is one immutable editor atom and projects without substitution', () {
    final editor = FractionEditor()..insertText('M');
    final snapshot = editor.snapshot;
    expect(snapshot.root.nodes, hasLength(1));
    expect((snapshot.root.nodes.single as EditorText).text, 'M');
    expect(path(snapshot.cursor), [1]);
    expect(editor.toExpression(), 'M');
    expect(() => snapshot.root.nodes.clear(), throwsUnsupportedError);
  });

  test('horizontal movement and DEL operate on the whole M atom', () {
    final editor = FractionEditor()
      ..insertText('M')
      ..insertText('+')
      ..insertText('1')
      ..moveLeft()
      ..moveLeft();
    expect(path(editor.snapshot.cursor), [1]);
    editor.moveLeft();
    expect(path(editor.snapshot.cursor), [0]);
    editor.moveRight();
    editor.deleteBackward();
    expect(editor.toExpression(), '+1');
    expect(path(editor.snapshot.cursor), [0]);
  });

  for (final token in ['m', 'MM', 'M+1', 'AnsM']) {
    test('only atomic uppercase M is accepted: $token', () {
      final editor = FractionEditor()..insertText('M');
      final before = editor.snapshot;
      expect(() => editor.insertText(token), throwsArgumentError);
      expect(editor.snapshot, same(before));
    });
  }

  test(
    'exact memory and answer contexts are independent in one expression',
    () {
      final editor = FractionEditor()
        ..insertText('M')
        ..insertText('+')
        ..insertText('Ans');
      final before = editor.snapshot;
      expect(
        editor
            .evaluate(
              memoryValue: Rational(BigInt.one, BigInt.from(3)),
              answer: Rational(BigInt.one, BigInt.from(6)),
            )
            .toString(),
        '1/2',
      );
      expect(
        editor.evaluate(
          memoryValue: Rational.fromInt(9),
          answer: Rational.fromInt(-2),
        ),
        Rational.fromInt(7),
      );
      expect(editor.snapshot, same(before));
      expect(editor.toExpression(), 'M+Ans');
    },
  );

  test('M can be the captured numerator without capturing a leading sign', () {
    final editor = FractionEditor()
      ..insertText('-')
      ..insertText('M')
      ..wrapPreviousAtomInFraction();
    final fraction = editor.snapshot.root.nodes[1] as EditorFraction;
    expect((editor.snapshot.root.nodes.first as EditorText).text, '-');
    expect((fraction.numerator.nodes.single as EditorText).text, 'M');
    expect(fraction.denominator.nodes, isEmpty);
    expect(path(editor.snapshot.cursor), [(1, FractionField.denominator), 0]);
    editor.insertText('2');
    expect(
      editor
          .evaluate(memoryValue: Rational(BigInt.one, BigInt.from(3)))
          .toString(),
      '-1/6',
    );
  });

  test('captured M keeps its source cursor in the numerator', () {
    final editor = FractionEditor()
      ..insertText('M')
      ..wrapPreviousAtomInFraction()
      ..insertText('2');
    final projection = editor.project();
    expect(projection.expression, '((M)/(2))');
    final target = projection.cursorAt(2);
    expect(path(target), [(0, FractionField.numerator), 0]);
    editor.moveTo(target);
    editor.moveRight();
    expect(path(editor.snapshot.cursor), [(0, FractionField.numerator), 1]);
    editor.deleteBackward();
    expect(
      (editor.snapshot.root.nodes.single as EditorFraction).numerator.nodes,
      isEmpty,
    );
  });

  test('nested absolute and fraction fields bind M without text expansion', () {
    final editor = FractionEditor()
      ..insertAbsolute()
      ..insertFraction()
      ..insertText('M')
      ..moveDown()
      ..insertText('Ans');
    final projection = editor.project();
    expect(path(projection.cursorAt(projection.expression.indexOf('M'))), [
      (0, FractionField.argument),
      (0, FractionField.numerator),
      0,
    ]);
    expect(
      editor.evaluate(
        memoryValue: Rational(BigInt.from(-2), BigInt.from(3)),
        answer: Rational(BigInt.one, BigInt.from(6)),
      ),
      Rational.fromInt(4),
    );
    editor.moveUp();
    expect(path(editor.snapshot.cursor), [
      (0, FractionField.argument),
      (0, FractionField.numerator),
      1,
    ]);
    editor.moveRight();
    expect(path(editor.snapshot.cursor), [
      (0, FractionField.argument),
      (0, FractionField.denominator),
      0,
    ]);
  });

  test(
    'missing memory context reports M source position and preserves editor',
    () {
      final editor = FractionEditor()
        ..insertText('1')
        ..insertText('+')
        ..insertText('M');
      final before = editor.snapshot;
      expect(
        () => editor.evaluate(answer: Rational.fromInt(5)),
        throwsA(failure(CalculatorErrorCode.unsupported, 2)),
      );
      expect(path(editor.project().cursorAt(2)), [2]);
      expect(editor.snapshot, same(before));
    },
  );

  test('missing nested M context targets its denominator atom', () {
    final editor = FractionEditor()
      ..insertFraction()
      ..insertText('1')
      ..moveDown()
      ..insertText('M');
    final projection = editor.project();
    final offset = projection.expression.indexOf('M');
    expect(
      () => editor.evaluate(),
      throwsA(failure(CalculatorErrorCode.unsupported, offset)),
    );
    expect(path(projection.cursorAt(offset)), [
      (0, FractionField.denominator),
      0,
    ]);
  });

  test('zero-valued M denominator maps division error to denominator end', () {
    final editor = FractionEditor()
      ..insertFraction()
      ..insertText('1')
      ..moveDown()
      ..insertText('M');
    final projection = editor.project();
    final offset = projection.expression.indexOf('/');
    expect(
      () => editor.evaluate(memoryValue: Rational.fromInt(0)),
      throwsA(failure(CalculatorErrorCode.math, offset)),
    );
    expect(path(projection.cursorAt(offset)), [
      (0, FractionField.denominator),
      1,
    ]);
  });

  test('large admissible M occupies one node and one projected character', () {
    final editor = FractionEditor()..insertText('M');
    final edge = Rational(BigInt.one << 99998);
    expect(editor.evaluate(memoryValue: edge), edge);
    expect(editor.snapshot.root.nodes, hasLength(1));
    expect(editor.toExpression(), 'M');
  });

  test('large rational M stays exact without expanding denominator digits', () {
    final editor = FractionEditor()..insertText('M');
    final edge = Rational(BigInt.one, BigInt.one << 99998);
    expect(editor.evaluate(memoryValue: edge), edge);
    expect(editor.project().expression, 'M');
    expect(path(editor.snapshot.cursor), [1]);
  });

  test('oversized M result fails without changing token or cursor', () {
    final editor = FractionEditor()..insertText('M');
    final before = editor.snapshot;
    expect(
      () => editor.evaluate(memoryValue: Rational(BigInt.one << 99999)),
      throwsA(failure(CalculatorErrorCode.limit, 0)),
    );
    expect(editor.snapshot, same(before));
  });

  test(
    'restored snapshots keep M while later edits and contexts stay separate',
    () {
      final original = FractionEditor()..insertText('M');
      final frozen = original.snapshot;
      final restored = FractionEditor.fromSnapshot(frozen)
        ..insertText('+')
        ..insertText('1');
      expect(original.toExpression(), 'M');
      expect(restored.toExpression(), 'M+1');
      expect(
        original.evaluate(memoryValue: Rational.fromInt(2)),
        Rational.fromInt(2),
      );
      expect(
        restored.evaluate(memoryValue: Rational.fromInt(8)),
        Rational.fromInt(9),
      );
      expect((frozen.root.nodes.single as EditorText).text, 'M');
      expect(path(frozen.cursor), [1]);
    },
  );

  test('wrapping M at the full editor budget is rejected atomically', () {
    final editor = FractionEditor();
    for (var count = 0; count < FractionEditor.maxNodes; count++) {
      editor.insertText('M');
    }
    final before = editor.snapshot;
    expect(
      editor.wrapPreviousAtomInFraction,
      throwsA(
        isA<CalculatorException>().having(
          (error) => error.code,
          'code',
          CalculatorErrorCode.limit,
        ),
      ),
    );
    expect(editor.snapshot, same(before));
  });
}
