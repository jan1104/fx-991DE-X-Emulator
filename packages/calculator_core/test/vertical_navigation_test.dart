import 'package:calculator_core/calculator_core.dart';
import 'package:test/test.dart';

void at(EditorCursor cursor, List<(int, FractionField)> path, int offset) {
  expect([for (final step in cursor.path) (step.nodeIndex, step.field)], path);
  expect(cursor.offset, offset);
}

void text(FractionEditor editor, String source) {
  for (final token in source.split('')) {
    editor.insertText(token);
  }
}

void enter(StructuredCalculatorSession session, String source) {
  for (final token in source.split('')) {
    session.pressId(switch (token) {
      '+' => 'KEY_ADD',
      '/' => 'KEY_DIVIDE',
      _ => 'KEY_$token',
    });
  }
}

void fraction(StructuredCalculatorSession session, String top, String bottom) {
  session.pressId('KEY_FRACTION');
  enter(session, top);
  session.press(CalculatorKey.right);
  enter(session, bottom);
}

void main() {
  group('immediate fraction field navigation', () {
    test('up and down do nothing in empty and nonempty root sequences', () {
      final editor = FractionEditor();
      for (final content in ['', '123']) {
        text(editor, content);
        editor.moveLeft();
        final before = editor.snapshot;
        editor.moveUp();
        expect(identical(editor.snapshot, before), isTrue);
        editor.moveDown();
        expect(identical(editor.snapshot, before), isTrue);
      }
    });

    test(
      'equal length fields preserve the logical offset and whole expression',
      () {
        final editor = FractionEditor()..insertFraction();
        text(editor, '123');
        editor.moveRight();
        text(editor, '456');
        editor.moveLeft();
        final before = editor.snapshot;
        editor.moveUp();
        at(editor.snapshot.cursor, [(0, FractionField.numerator)], 2);
        expect(editor.toExpression(), '((123)/(456))');
        expect(identical(editor.snapshot.root, before.root), isTrue);
        editor.moveDown();
        at(editor.snapshot.cursor, [(0, FractionField.denominator)], 2);
        expect(editor.evaluate().toString(), '41/152');
        at(before.cursor, [(0, FractionField.denominator)], 2);
      },
    );

    test(
      'shorter field clamps and returning does not restore a preferred column',
      () {
        final editor = FractionEditor()..insertFraction();
        text(editor, '12345');
        editor.moveRight();
        text(editor, '67');
        editor.moveUp();
        at(editor.snapshot.cursor, [(0, FractionField.numerator)], 2);
        editor.moveRight();
        editor.moveRight();
        at(editor.snapshot.cursor, [(0, FractionField.numerator)], 4);
        editor.moveDown();
        at(editor.snapshot.cursor, [(0, FractionField.denominator)], 2);
        editor.moveUp();
        at(editor.snapshot.cursor, [(0, FractionField.numerator)], 2);
        expect(editor.toExpression(), '((12345)/(67))');
      },
    );

    test(
      'moving to a longer field preserves both zero and interior offsets',
      () {
        final editor = FractionEditor()..insertFraction();
        text(editor, '12');
        editor.moveRight();
        text(editor, '34567');
        editor.moveUp();
        at(editor.snapshot.cursor, [(0, FractionField.numerator)], 2);
        editor.moveLeft();
        editor.moveDown();
        at(editor.snapshot.cursor, [(0, FractionField.denominator)], 1);
        editor.moveLeft();
        editor.moveUp();
        at(editor.snapshot.cursor, [(0, FractionField.numerator)], 0);
        editor.moveDown();
        at(editor.snapshot.cursor, [(0, FractionField.denominator)], 0);
      },
    );

    test('up from numerator and down from denominator are exact no-ops', () {
      final editor = FractionEditor()..insertFraction();
      text(editor, '1');
      final numerator = editor.snapshot;
      editor.moveUp();
      expect(identical(editor.snapshot, numerator), isTrue);
      editor.moveRight();
      text(editor, '2');
      final denominator = editor.snapshot;
      editor.moveDown();
      expect(identical(editor.snapshot, denominator), isTrue);
    });

    test(
      'empty destination clamps to zero without replacing its field tree',
      () {
        final editor = FractionEditor()..insertFraction();
        text(editor, '12');
        final numerator = editor.snapshot;
        editor.moveDown();
        at(editor.snapshot.cursor, [(0, FractionField.denominator)], 0);
        expect(identical(editor.snapshot.root, numerator.root), isTrue);
        editor.moveUp();
        at(editor.snapshot.cursor, [(0, FractionField.numerator)], 0);
        at(numerator.cursor, [(0, FractionField.numerator)], 2);
        editor.clear();
        editor.insertFraction();
        editor.moveDown();
        text(editor, '34');
        editor.moveUp();
        at(editor.snapshot.cursor, [(0, FractionField.numerator)], 0);
      },
    );

    test('Ans occupies one token, not three text columns', () {
      final editor = FractionEditor()..insertFraction();
      editor.insertText('Ans');
      editor.moveDown();
      text(editor, '123');
      editor.moveUp();
      at(editor.snapshot.cursor, [(0, FractionField.numerator)], 1);
      editor.moveDown();
      at(editor.snapshot.cursor, [(0, FractionField.denominator)], 1);
      expect(editor.toExpression(), '((Ans)/(123))');
    });

    test(
      'nested movement replaces only the last step and keeps sibling indices',
      () {
        final editor = FractionEditor();
        text(editor, '8+');
        editor.insertFraction();
        text(editor, '9+');
        editor.insertFraction();
        text(editor, '123');
        editor.moveDown();
        text(editor, '45');
        final before = editor.snapshot;
        editor.moveUp();
        at(editor.snapshot.cursor, [
          (2, FractionField.numerator),
          (2, FractionField.numerator),
        ], 2);
        editor.moveDown();
        at(editor.snapshot.cursor, [
          (2, FractionField.numerator),
          (2, FractionField.denominator),
        ], 2);
        expect(identical(editor.snapshot.root, before.root), isTrue);
        expect(
          identical(
            editor.snapshot.cursor.path.first,
            before.cursor.path.first,
          ),
          isTrue,
        );
        expect(() => before.cursor.path.clear(), throwsUnsupportedError);
      },
    );

    test(
      'no ancestor search when the immediate fraction forbids that direction',
      () {
        final editor = FractionEditor()..insertFraction();
        text(editor, '1');
        editor.moveDown();
        editor.insertFraction();
        text(editor, '2');
        final innerNumerator = editor.snapshot;
        editor.moveUp();
        expect(identical(editor.snapshot, innerNumerator), isTrue);
        at(editor.snapshot.cursor, [
          (0, FractionField.denominator),
          (0, FractionField.numerator),
        ], 1);
        editor.moveDown();
        text(editor, '3');
        final innerDenominator = editor.snapshot;
        editor.moveDown();
        expect(identical(editor.snapshot, innerDenominator), isTrue);
      },
    );

    test('navigation is available at maximum depth without adding nodes', () {
      final editor = FractionEditor();
      for (var index = 0; index < FractionEditor.maxDepth; index++) {
        editor.insertFraction();
      }
      editor.insertText('1');
      final before = editor.snapshot;
      editor.moveDown();
      expect(editor.snapshot.cursor.path, hasLength(FractionEditor.maxDepth));
      expect(editor.snapshot.cursor.path.last.field, FractionField.denominator);
      expect(editor.snapshot.cursor.offset, 0);
      expect(identical(editor.snapshot.root, before.root), isTrue);
      editor.moveUp();
      expect(editor.snapshot.cursor.path.last.field, FractionField.numerator);
      expect(editor.snapshot.cursor.offset, 0);
    });

    test(
      'navigation is available at maximum node count without adding nodes',
      () {
        final editor = FractionEditor()..insertFraction();
        for (var index = 1; index < FractionEditor.maxNodes; index++) {
          editor.insertText('1');
        }
        final before = editor.snapshot;
        editor.moveDown();
        at(editor.snapshot.cursor, [(0, FractionField.denominator)], 0);
        editor.moveUp();
        at(editor.snapshot.cursor, [(0, FractionField.numerator)], 0);
        expect(identical(editor.snapshot.root, before.root), isTrue);
      },
    );
  });

  group('structured session vertical actions', () {
    test('linear enum remains 25 and rejects both vertical action IDs', () {
      expect(CalculatorKey.values, hasLength(25));
      final linear = CalculatorSession();
      for (final id in ['KEY_UP', 'KEY_DOWN']) {
        expect(CalculatorKey.fromId(id), isNull);
        final before = linear.snapshot;
        expect(() => linear.pressId(id), throwsA(isA<CalculatorException>()));
        expect(identical(linear.snapshot, before), isTrue);
      }
      // The structured session accepts the 25 enum IDs and three local IDs.
      final structured = StructuredCalculatorSession();
      for (final id in ['KEY_UP', 'KEY_DOWN']) {
        expect(structured.pressId(id).phase, CalculatorPhase.editing);
        expect(structured.snapshot.editor.root.nodes, isEmpty);
      }
    });

    test('editing switches fields and evaluates the same exact arithmetic', () {
      final session = StructuredCalculatorSession();
      session.pressId('KEY_FRACTION');
      enter(session, '123');
      session.pressId('KEY_DOWN');
      enter(session, '45');
      session.pressId('KEY_UP');
      at(session.snapshot.editor.cursor, [(0, FractionField.numerator)], 2);
      session.pressId('KEY_DOWN');
      at(session.snapshot.editor.cursor, [(0, FractionField.denominator)], 2);
      expect(session.press(CalculatorKey.equals).result.toString(), '41/15');
    });

    for (final id in ['KEY_UP', 'KEY_DOWN']) {
      test('$id after result reopens root end without additional movement', () {
        final session = StructuredCalculatorSession();
        fraction(session, '1', '3');
        final success = session.press(CalculatorKey.equals);
        at(success.editor.cursor, [(0, FractionField.denominator)], 1);
        final edit = session.pressId(id);
        expect(edit.phase, CalculatorPhase.editing);
        at(edit.editor.cursor, [], 1);
        expect(edit.answer.toString(), '1/3');
        expect(edit.result, isNull);
        expect(edit.error, isNull);
        expect(edit.errorCursor, isNull);
        final next = session.pressId(id);
        at(next.editor.cursor, [], 1);
        expect(identical(next.editor.root, success.editor.root), isTrue);
        at(success.editor.cursor, [(0, FractionField.denominator)], 1);
      });

      test(
        '$id after math error restores target without vertical movement',
        () {
          final session = StructuredCalculatorSession();
          enter(session, '7');
          session.press(CalculatorKey.equals);
          fraction(session, '1', '0');
          session.press(CalculatorKey.right);
          final before = session.snapshot.editor;
          final failure = session.press(CalculatorKey.equals);
          at(failure.editor.cursor, [], 1);
          at(failure.errorCursor!, [(0, FractionField.denominator)], 1);
          final restored = session.pressId(id);
          at(restored.editor.cursor, [(0, FractionField.denominator)], 1);
          expect(restored.phase, CalculatorPhase.editing);
          expect(restored.answer, Rational.fromInt(7));
          expect(restored.error, isNull);
          expect(restored.errorCursor, isNull);
          expect(restored.result, isNull);
          expect(identical(restored.editor.root, before.root), isTrue);
          session.press(CalculatorKey.delete);
          enter(session, '2');
          expect(session.press(CalculatorKey.equals).result.toString(), '1/2');
          at(failure.errorCursor!, [(0, FractionField.denominator)], 1);
        },
      );

      test('$id after empty-field error recovers before navigating', () {
        final session = StructuredCalculatorSession();
        session.pressId('KEY_FRACTION');
        session.pressId('KEY_DOWN');
        enter(session, '2');
        final failure = session.press(CalculatorKey.equals);
        expect(failure.error?.code, CalculatorErrorCode.syntax);
        at(failure.errorCursor!, [(0, FractionField.numerator)], 0);
        final restored = session.pressId(id);
        at(restored.editor.cursor, [(0, FractionField.numerator)], 0);
        expect(restored.errorCursor, isNull);
        enter(session, '1');
        expect(session.press(CalculatorKey.equals).result.toString(), '1/2');
      });

      test('$id recovers an edit-limit error at the previous cursor', () {
        final session = StructuredCalculatorSession();
        for (var index = 0; index < FractionEditor.maxNodes; index++) {
          session.press(CalculatorKey.digit1);
        }
        final before = session.snapshot.editor;
        final failure = session.pressId('KEY_FRACTION');
        expect(failure.error?.code, CalculatorErrorCode.limit);
        final restored = session.pressId(id);
        at(restored.editor.cursor, [], FractionEditor.maxNodes);
        expect(identical(restored.editor.root, before.root), isTrue);
        expect(restored.error, isNull);
        expect(restored.errorCursor, isNull);
        session.press(CalculatorKey.delete);
        session.press(CalculatorKey.digit2);
        expect(session.snapshot.phase, CalculatorPhase.editing);
        expect(
          session.snapshot.editor.root.nodes,
          hasLength(FractionEditor.maxNodes),
        );
      });
    }

    test(
      'repeated bounded editing navigation leaves Ans and tree unchanged',
      () {
        final session = StructuredCalculatorSession();
        enter(session, '5');
        session.press(CalculatorKey.equals);
        fraction(session, '1', '2');
        final before = session.snapshot;
        for (var index = 0; index < 20; index++) {
          session.pressId('KEY_UP');
          session.pressId('KEY_UP');
          session.pressId('KEY_DOWN');
          session.pressId('KEY_DOWN');
        }
        at(session.snapshot.editor.cursor, [(0, FractionField.denominator)], 1);
        expect(session.snapshot.answer, Rational.fromInt(5));
        expect(
          identical(session.snapshot.editor.root, before.editor.root),
          isTrue,
        );
        expect(session.snapshot.error, isNull);
        expect(session.snapshot.errorCursor, isNull);
        expect(session.snapshot.result, isNull);
      },
    );
  });
}
