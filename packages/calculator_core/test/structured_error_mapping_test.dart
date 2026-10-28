import 'package:calculator_core/calculator_core.dart';
import 'package:test/test.dart';

void enter(StructuredCalculatorSession session, String source) {
  const keys = {
    '+': 'KEY_ADD',
    '*': 'KEY_MULTIPLY',
    '/': 'KEY_DIVIDE',
    '(': 'KEY_LPAREN',
    ')': 'KEY_RPAREN',
  };
  for (final character in source.split('')) {
    session.pressId(keys[character] ?? 'KEY_$character');
  }
}

void fraction(StructuredCalculatorSession session, String top, String bottom) {
  session.pressId('KEY_FRACTION');
  enter(session, top);
  session.press(CalculatorKey.right);
  enter(session, bottom);
  session.press(CalculatorKey.right);
}

void at(EditorCursor? cursor, List<(int, FractionField)> path, int offset) {
  expect(cursor, isNotNull);
  expect([for (final step in cursor!.path) (step.nodeIndex, step.field)], path);
  expect(cursor.offset, offset);
}

void main() {
  group('structural error targets and recovery', () {
    for (final arrow in [CalculatorKey.left, CalculatorKey.right]) {
      test(
        '${arrow.name} moves from a different root cursor to denominator end',
        () {
          final session = StructuredCalculatorSession();
          enter(session, '7');
          session.press(CalculatorKey.equals);
          fraction(session, '1', '0');
          final before = session.snapshot.editor;
          at(before.cursor, [], 1);
          final failure = session.press(CalculatorKey.equals);
          expect(failure.phase, CalculatorPhase.error);
          expect(failure.error?.code, CalculatorErrorCode.math);
          expect(failure.error?.position, 4);
          expect(identical(failure.editor, before), isTrue);
          at(failure.errorCursor, [(0, FractionField.denominator)], 1);
          expect(failure.answer, Rational.fromInt(7));
          final recovered = session.press(arrow);
          at(recovered.editor.cursor, [(0, FractionField.denominator)], 1);
          expect(identical(recovered.editor.root, before.root), isTrue);
          expect(recovered.phase, CalculatorPhase.editing);
          expect(recovered.error, isNull);
          expect(recovered.errorCursor, isNull);
          session.press(CalculatorKey.delete);
          enter(session, '2');
          final success = session.press(CalculatorKey.equals);
          expect(success.result.toString(), '1/2');
          expect(success.errorCursor, isNull);
          // Saved failure metadata and cursor remain unchanged.
          at(failure.editor.cursor, [], 1);
          at(failure.errorCursor, [(0, FractionField.denominator)], 1);
        },
      );
    }

    test('a nested zero denominator does not target the outer fraction', () {
      final session = StructuredCalculatorSession();
      session.pressId('KEY_FRACTION');
      enter(session, '1');
      session.press(CalculatorKey.right);
      fraction(session, '2', '0');
      session.press(CalculatorKey.right);
      at(session.snapshot.editor.cursor, [], 1);
      final failure = session.press(CalculatorKey.equals);
      at(failure.errorCursor, [
        (0, FractionField.denominator),
        (0, FractionField.denominator),
      ], 1);
      session.press(CalculatorKey.right);
      session.press(CalculatorKey.delete);
      enter(session, '3');
      expect(session.press(CalculatorKey.equals).result.toString(), '3/2');
    });

    test('syntax at a generated closing parenthesis targets numerator end', () {
      final session = StructuredCalculatorSession();
      fraction(session, '1+', '2');
      final failure = session.press(CalculatorKey.equals);
      expect(failure.error?.code, CalculatorErrorCode.syntax);
      at(failure.errorCursor, [(0, FractionField.numerator)], 2);
      session.press(CalculatorKey.left);
      enter(session, '3');
      expect(session.press(CalculatorKey.equals).result, Rational.fromInt(2));
    });

    test('text syntax target maps through a preceding atomic Ans node', () {
      final session = StructuredCalculatorSession();
      session.press(CalculatorKey.answer);
      enter(session, '+*2');
      final failure = session.press(CalculatorKey.equals);
      expect(failure.error?.position, 4);
      at(failure.errorCursor, [], 2);
      session.press(CalculatorKey.right);
      at(session.snapshot.editor.cursor, [], 2);
      session.press(CalculatorKey.right);
      session.press(CalculatorKey.delete);
      expect(session.press(CalculatorKey.equals).result, Rational.fromInt(2));
    });

    test('global parser EOF maps to root end, not a field', () {
      final session = StructuredCalculatorSession();
      fraction(session, '1', '2');
      enter(session, '+');
      session.press(CalculatorKey.left);
      final failure = session.press(CalculatorKey.equals);
      at(failure.errorCursor, [], 2);
      session.press(CalculatorKey.right);
      at(session.snapshot.editor.cursor, [], 2);
      enter(session, '1');
      expect(session.press(CalculatorKey.equals).result.toString(), '3/2');
    });

    test('nested empty field diagnostic can differ from the active field', () {
      final session = StructuredCalculatorSession();
      session.pressId('KEY_FRACTION');
      enter(session, '1');
      session.press(CalculatorKey.right);
      session.pressId('KEY_FRACTION');
      session.press(CalculatorKey.right);
      enter(session, '3');
      session.press(CalculatorKey.right);
      session.press(CalculatorKey.right);
      final before = session.snapshot.editor;
      final failure = session.press(CalculatorKey.equals);
      expect(identical(failure.editor, before), isTrue);
      at(failure.errorCursor, [
        (0, FractionField.denominator),
        (0, FractionField.numerator),
      ], 0);
      session.press(CalculatorKey.left);
      enter(session, '2');
      expect(session.press(CalculatorKey.equals).result.toString(), '3/2');
    });

    test(
      'unmatched closing parenthesis targets its token inside numerator',
      () {
        final session = StructuredCalculatorSession();
        fraction(session, '1)', '2');
        final failure = session.press(CalculatorKey.equals);
        at(failure.errorCursor, [(0, FractionField.numerator)], 1);
        session.press(CalculatorKey.right);
        session.press(CalculatorKey.right);
        session.press(CalculatorKey.delete);
        expect(session.press(CalculatorKey.equals).result.toString(), '1/2');
      },
    );

    test('unmatched opening parenthesis targets field end for repair', () {
      final session = StructuredCalculatorSession();
      fraction(session, '1', '(2');
      final failure = session.press(CalculatorKey.equals);
      at(failure.errorCursor, [(0, FractionField.denominator)], 2);
      session.press(CalculatorKey.left);
      enter(session, ')');
      expect(session.press(CalculatorKey.equals).result.toString(), '1/2');
    });

    test('unpositioned edit limit preserves the previous cursor as target', () {
      final session = StructuredCalculatorSession();
      for (var index = 0; index < FractionEditor.maxNodes; index++) {
        session.press(CalculatorKey.digit1);
      }
      session.press(CalculatorKey.left);
      final before = session.snapshot.editor;
      final failure = session.press(CalculatorKey.digit2);
      expect(failure.error?.code, CalculatorErrorCode.limit);
      expect(failure.error?.position, isNull);
      expect(identical(failure.editor, before), isTrue);
      expect(identical(failure.errorCursor, before.cursor), isTrue);
      session.press(CalculatorKey.right);
      at(session.snapshot.editor.cursor, [], FractionEditor.maxNodes - 1);
    });

    test(
      'positioned parser resource errors receive valid structured targets',
      () {
        final session = StructuredCalculatorSession();
        for (var index = 0; index < 70; index++) {
          fraction(session, '1', '1');
        }
        final before = session.snapshot.editor;
        final failure = session.press(CalculatorKey.equals);
        expect(failure.error?.code, CalculatorErrorCode.limit);
        expect(failure.error?.position, isNotNull);
        final editor = FractionEditor.fromSnapshot(before);
        final expected = editor.project().cursorAt(failure.error!.position!);
        at(failure.errorCursor, [
          for (final step in expected.path) (step.nodeIndex, step.field),
        ], expected.offset);
        editor.moveTo(failure.errorCursor!);
        expect(identical(failure.editor, before), isTrue);
      },
    );

    test('AC clears error metadata while saved failures keep theirs', () {
      final session = StructuredCalculatorSession();
      fraction(session, '1', '0');
      final failure = session.press(CalculatorKey.equals);
      expect(failure.errorCursor, isNotNull);
      expect(identical(session.pressId('KEY_FRACTION'), failure), isTrue);
      expect(
        () => session.pressId('KEY_SHIFT'),
        throwsA(isA<CalculatorException>()),
      );
      expect(identical(session.snapshot, failure), isTrue);
      final cleared = session.press(CalculatorKey.clear);
      expect(cleared.error, isNull);
      expect(cleared.errorCursor, isNull);
      expect(cleared.editor.root.nodes, isEmpty);
      at(failure.errorCursor, [(0, FractionField.denominator)], 1);
    });
  });
}
