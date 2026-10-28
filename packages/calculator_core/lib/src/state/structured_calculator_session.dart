import '../editor/fraction_editor.dart';
import '../errors.dart';
import '../evaluation/evaluator.dart' as arithmetic;
import '../numbers/rational.dart';
import 'calculator_session.dart';

/// An immutable structured-input state, independent of the linear session.
final class StructuredCalculatorSnapshot {
  final FractionEditorSnapshot editor;
  final CalculatorPhase phase;
  final Rational answer;
  final Rational? result;

  /// Error positions, if present, refer to the projected parser expression.
  /// They are not editor-path offsets and must not be used as such.
  final CalculatorException? error;
  final EditorCursor? errorCursor;

  const StructuredCalculatorSnapshot._({
    required this.editor,
    required this.phase,
    required this.answer,
    this.result,
    this.error,
    this.errorCursor,
  });
}

/// Prototype controller for structured fractions, with exact Ans continuation.
///
/// The editor is private. All public state is immutable, and failed commands
/// retain the complete previous tree and cursor. These navigation rules are
/// explicit prototype decisions, not measured Casio behavior.
final class StructuredCalculatorSession {
  StructuredCalculatorSnapshot _snapshot = StructuredCalculatorSnapshot._(
    editor: FractionEditor().snapshot,
    phase: CalculatorPhase.editing,
    answer: Rational.fromInt(0),
  );

  StructuredCalculatorSnapshot get snapshot => _snapshot;

  /// Fraction and vertical-navigation IDs are local to this session; the
  /// linear key enum stays unchanged.
  StructuredCalculatorSnapshot pressId(String id) {
    if (id == 'KEY_FRACTION') return _pressFraction();
    if (id == 'KEY_UP' || id == 'KEY_DOWN') {
      return _pressVertical(up: id == 'KEY_UP');
    }
    final key = CalculatorKey.fromId(id);
    if (key == null) {
      throw CalculatorException(
        CalculatorErrorCode.unsupported,
        'Key $id is not implemented in this prototype',
      );
    }
    return press(key);
  }

  StructuredCalculatorSnapshot press(CalculatorKey key) {
    if (key == CalculatorKey.clear) {
      return _edit(FractionEditor().snapshot);
    }
    if (_snapshot.phase == CalculatorPhase.error) {
      if (key == CalculatorKey.left || key == CalculatorKey.right) {
        return _recoverError();
      }
      return _snapshot;
    }
    if (key == CalculatorKey.equals) {
      if (_snapshot.phase == CalculatorPhase.editing &&
          _snapshot.editor.root.nodes.isNotEmpty) {
        return _execute();
      }
      return _snapshot;
    }
    if (key == CalculatorKey.left || key == CalculatorKey.right) {
      return _apply((editor) {
        if (_snapshot.phase == CalculatorPhase.result) {
          editor.moveToRootEnd();
        } else if (key == CalculatorKey.left) {
          editor.moveLeft();
        } else {
          editor.moveRight();
        }
      });
    }
    if (key == CalculatorKey.delete) {
      return _apply((editor) {
        if (_snapshot.phase == CalculatorPhase.result) {
          editor.moveToRootEnd();
        }
        editor.deleteBackward();
      });
    }

    return _apply((editor) {
      if (_snapshot.phase == CalculatorPhase.result) {
        editor.clear();
        if (key.isBinaryOperator) editor.insertText('Ans');
      }
      // The supported enum's control keys have all been handled above.
      editor.insertText(key.text!);
    });
  }

  StructuredCalculatorSnapshot _pressFraction() {
    if (_snapshot.phase == CalculatorPhase.error) return _snapshot;
    return _apply((editor) {
      if (_snapshot.phase == CalculatorPhase.result) editor.clear();
      editor.insertFraction();
    });
  }

  StructuredCalculatorSnapshot _pressVertical({required bool up}) {
    if (_snapshot.phase == CalculatorPhase.error) return _recoverError();
    return _apply((editor) {
      if (_snapshot.phase == CalculatorPhase.result) {
        editor.moveToRootEnd();
      } else if (up) {
        editor.moveUp();
      } else {
        editor.moveDown();
      }
    });
  }

  StructuredCalculatorSnapshot _recoverError() {
    final editor = FractionEditor.fromSnapshot(_snapshot.editor);
    editor.moveTo(_snapshot.errorCursor ?? _snapshot.editor.cursor);
    return _edit(editor.snapshot);
  }

  StructuredCalculatorSnapshot _apply(void Function(FractionEditor) command) {
    final candidate = FractionEditor.fromSnapshot(_snapshot.editor);
    try {
      command(candidate);
      return _edit(candidate.snapshot);
    } on CalculatorException catch (error) {
      return _fail(error);
    }
  }

  StructuredCalculatorSnapshot _execute() {
    EditorProjection? projection;
    try {
      projection = FractionEditor.fromSnapshot(_snapshot.editor).project();
      final value = arithmetic.evaluate(
        projection.expression,
        answer: _snapshot.answer,
      );
      return _snapshot = StructuredCalculatorSnapshot._(
        editor: _snapshot.editor,
        phase: CalculatorPhase.result,
        answer: value,
        result: value,
      );
    } on EditorProjectionException catch (diagnostic) {
      return _fail(diagnostic.error, cursor: diagnostic.cursor);
    } on CalculatorException catch (error) {
      final position = error.position;
      return _fail(
        error,
        cursor: position == null
            ? _snapshot.editor.cursor
            : projection!.cursorAt(position),
      );
    }
  }

  StructuredCalculatorSnapshot _edit(FractionEditorSnapshot editor) =>
      _snapshot = StructuredCalculatorSnapshot._(
        editor: editor,
        phase: CalculatorPhase.editing,
        answer: _snapshot.answer,
      );

  StructuredCalculatorSnapshot _fail(
    CalculatorException error, {
    EditorCursor? cursor,
  }) => _snapshot = StructuredCalculatorSnapshot._(
    editor: _snapshot.editor,
    phase: CalculatorPhase.error,
    answer: _snapshot.answer,
    error: error,
    errorCursor: cursor ?? _snapshot.editor.cursor,
  );
}
