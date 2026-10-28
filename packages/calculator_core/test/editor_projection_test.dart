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

void fraction(FractionEditor editor, String numerator, String denominator) {
  editor.insertFraction();
  text(editor, numerator);
  editor.moveRight();
  text(editor, denominator);
  editor.moveRight();
}

EditorProjectionException diagnostic(FractionEditor editor) {
  try {
    editor.project();
  } on EditorProjectionException catch (error) {
    return error;
  }
  throw StateError('Expected projection diagnostic');
}

void main() {
  group('projection source map', () {
    test('each generated fraction character belongs to the intended field', () {
      final editor = FractionEditor();
      fraction(editor, '1', '2');
      final before = editor.snapshot;
      final projection = editor.project();
      expect(projection.expression, '((1)/(2))');
      for (final offset in [0, 1, 2]) {
        at(projection.cursorAt(offset), [(0, FractionField.numerator)], 0);
      }
      at(projection.cursorAt(3), [(0, FractionField.numerator)], 1);
      at(projection.cursorAt(4), [(0, FractionField.denominator)], 1);
      for (final offset in [5, 6]) {
        at(projection.cursorAt(offset), [(0, FractionField.denominator)], 0);
      }
      for (final offset in [7, 8]) {
        at(projection.cursorAt(offset), [(0, FractionField.denominator)], 1);
      }
      at(projection.cursorAt(9), [], 1);
      expect(identical(editor.snapshot, before), isTrue);
    });

    test('Ans characters all map to the start of the same atomic token', () {
      final editor = FractionEditor()..insertText('1');
      editor.insertText('+');
      editor.insertText('Ans');
      final projection = editor.project();
      expect(projection.expression, '1+Ans');
      at(projection.cursorAt(0), [], 0);
      at(projection.cursorAt(1), [], 1);
      for (final offset in [2, 3, 4]) {
        at(projection.cursorAt(offset), [], 2);
      }
      at(projection.cursorAt(5), [], 3);
    });

    test('nested synthetic operators map to their own denominator end', () {
      final editor = FractionEditor()..insertFraction();
      text(editor, '1');
      editor.moveRight();
      fraction(editor, '2', '3');
      final projection = editor.project();
      expect(projection.expression, '((1)/(((2)/(3))))');
      at(projection.cursorAt(4), [(0, FractionField.denominator)], 1);
      at(projection.cursorAt(10), [
        (0, FractionField.denominator),
        (0, FractionField.denominator),
      ], 1);
      at(projection.cursorAt(projection.expression.length), [], 1);
      // Every mapping is a valid cursor in the tree it describes.
      for (var offset = 0; offset <= projection.expression.length; offset++) {
        FractionEditor.fromSnapshot(editor.snapshot)
            .moveTo(projection.cursorAt(offset));
      }
    });

    test(
      'adjacent fraction fields and surrounding root tokens stay separate',
      () {
        final editor = FractionEditor();
        text(editor, '2*');
        fraction(editor, '1', '2');
        fraction(editor, '3', '4');
        text(editor, '+5');
        final projection = editor.project();
        expect(projection.expression, '2*((1)/(2))((3)/(4))+5');
        at(projection.cursorAt(2), [(2, FractionField.numerator)], 0);
        at(projection.cursorAt(11), [(3, FractionField.numerator)], 0);
        at(projection.cursorAt(20), [], 4);
        at(projection.cursorAt(21), [], 5);
        at(projection.cursorAt(22), [], 6);
      },
    );

    test('rejects invalid offsets instead of clamping or wrapping', () {
      final projection = (FractionEditor()..insertText('1')).project();
      for (final offset in [-1, 2, 1000000]) {
        expect(() => projection.cursorAt(offset), throwsArgumentError);
      }
    });

    test('old projection, paths and source snapshots remain immutable', () {
      final editor = FractionEditor();
      fraction(editor, '1', '2');
      final old = editor.project();
      final cursor = old.cursorAt(4);
      editor.clear();
      editor.insertText('9');
      expect(old.expression, '((1)/(2))');
      at(cursor, [(0, FractionField.denominator)], 1);
      expect(() => cursor.path.clear(), throwsUnsupportedError);
      expect(() => editor.moveTo(cursor), throwsArgumentError);
      expect(editor.toExpression(), '9');
    });
  });

  group('projection diagnostics retain structural locations', () {
    test(
      'empty root has a root-zero diagnostic and old wrappers stay compatible',
      () {
        final editor = FractionEditor();
        final error = diagnostic(editor);
        expect(error.error.code, CalculatorErrorCode.syntax);
        at(error.cursor, [], 0);
        expect(editor.toExpression, throwsA(isA<CalculatorException>()));
        expect(editor.evaluate, throwsA(isA<CalculatorException>()));
      },
    );

    test('nested empty numerator is diagnosed instead of the outer root', () {
      final editor = FractionEditor()..insertFraction();
      text(editor, '1');
      editor.moveRight();
      editor.insertFraction();
      final before = editor.snapshot;
      final error = diagnostic(editor);
      at(error.cursor, [
        (0, FractionField.denominator),
        (0, FractionField.numerator),
      ], 0);
      expect(identical(editor.snapshot, before), isTrue);
    });

    test('nested empty denominator is distinct from its numerator', () {
      final editor = FractionEditor()..insertFraction();
      text(editor, '1');
      editor.moveRight();
      editor.insertFraction();
      text(editor, '2');
      final error = diagnostic(editor);
      at(error.cursor, [
        (0, FractionField.denominator),
        (0, FractionField.denominator),
      ], 0);
    });

    test('extra close parenthesis points to that field token', () {
      final editor = FractionEditor();
      fraction(editor, '1)', '(2');
      final error = diagnostic(editor);
      at(error.cursor, [(0, FractionField.numerator)], 1);
      expect(error.error.code, CalculatorErrorCode.syntax);
    });

    test('missing close parenthesis points to its own field end', () {
      final editor = FractionEditor();
      fraction(editor, '1', '(2');
      final error = diagnostic(editor);
      at(error.cursor, [(0, FractionField.denominator)], 2);
    });

    test('balanced global injection still fails field-local validation', () {
      final editor = FractionEditor();
      fraction(editor, '1)/(2', '3');
      final error = diagnostic(editor);
      at(error.cursor, [(0, FractionField.numerator)], 1);
    });
  });

  group('validated moveTo', () {
    test('accepts a matching foreign cursor but shares no mutable editor', () {
      final source = FractionEditor();
      fraction(source, '1', '234');
      final target = FractionEditor();
      fraction(target, '9', '876');
      final cursor = source.project().cursorAt(4);
      final oldTarget = target.snapshot;
      target.moveTo(cursor);
      at(target.snapshot.cursor, [(0, FractionField.denominator)], 3);
      expect(identical(target.snapshot.root, oldTarget.root), isTrue);
      target.deleteBackward();
      expect(target.toExpression(), '((9)/(87))');
      expect(source.toExpression(), '((1)/(234))');
    });

    test('rejects a foreign root offset atomically', () {
      final source = FractionEditor();
      text(source, '123');
      final target = FractionEditor()..insertText('4');
      final before = target.snapshot;
      expect(() => target.moveTo(source.snapshot.cursor), throwsArgumentError);
      expect(identical(target.snapshot, before), isTrue);
    });

    test('rejects a foreign field offset atomically', () {
      final source = FractionEditor();
      fraction(source, '123', '4');
      final target = FractionEditor();
      fraction(target, '1', '2');
      final before = target.snapshot;
      final cursor = source.project().cursorAt(5);
      at(cursor, [(0, FractionField.numerator)], 3);
      expect(() => target.moveTo(cursor), throwsArgumentError);
      expect(identical(target.snapshot, before), isTrue);
    });

    test('rejects a path into text and an absent fraction atomically', () {
      final source = FractionEditor();
      fraction(source, '1', '2');
      fraction(source, '3', '4');
      final one = FractionEditor();
      fraction(one, '5', '6');
      final textOnly = FractionEditor()..insertText('7');
      for (final entry in [
        (textOnly, source.project().cursorAt(0)),
        (one, source.project().cursorAt(9)),
      ]) {
        final before = entry.$1.snapshot;
        expect(() => entry.$1.moveTo(entry.$2), throwsArgumentError);
        expect(identical(entry.$1.snapshot, before), isTrue);
      }
    });

    test('checks every nested path step before changing the snapshot', () {
      final source = FractionEditor()..insertFraction();
      source.insertFraction();
      source.insertText('1');
      source.moveRight();
      source.insertText('2');
      source.moveRight();
      source.moveRight();
      source.insertText('3');
      final target = FractionEditor();
      fraction(target, '4', '5');
      final before = target.snapshot;
      final cursor = source.project().cursorAt(2);
      expect(cursor.path, hasLength(2));
      expect(() => target.moveTo(cursor), throwsArgumentError);
      expect(identical(target.snapshot, before), isTrue);
    });
  });
}
