import '../editor/fraction_editor.dart';
import '../errors.dart';
import '../evaluation/evaluator.dart' as arithmetic;
import '../formatting/rational_display.dart';
import '../numbers/rational.dart';
import 'calculator_memory.dart';
import 'calculator_session.dart';

/// An immutable structured-input view with its own editor and result display.
/// Ans reflects the shared memory at the time this snapshot is obtained.
final class StructuredCalculatorSnapshot {
  final FractionEditorSnapshot editor;
  final CalculatorPhase phase;
  final Rational answer;
  final Rational? result;

  /// Error positions, if present, refer to the projected parser expression.
  /// They are not editor-path offsets and must not be used as such.
  final CalculatorException? error;
  final EditorCursor? errorCursor;
  final RationalDisplayFormat resultDisplayFormat;

  const StructuredCalculatorSnapshot._({
    required this.editor,
    required this.phase,
    required this.answer,
    this.result,
    this.error,
    this.errorCursor,
    this.resultDisplayFormat = RationalDisplayFormat.fraction,
  });

  /// Formats only a present result. Outside the result phase, budgets are not
  /// inspected. A formatting failure never becomes a calculator/session error.
  RationalDisplay? formatResult({
    int maxDecimalPlaces = 100,
    int maxOutputCharacters = 2048,
  }) {
    final value = result;
    if (phase != CalculatorPhase.result || value == null) return null;
    return formatRational(
      value,
      format: resultDisplayFormat,
      maxDecimalPlaces: maxDecimalPlaces,
      maxOutputCharacters: maxOutputCharacters,
    );
  }
}

/// A prepared exact value, usable only by its originating session.
/// Preparation does not publish a result or modify the memory registers.
final class StructuredMemoryAssignment {
  const StructuredMemoryAssignment._(this.value, this._owner, this._origin);

  final Rational value;
  final StructuredCalculatorSession _owner;
  final StructuredCalculatorSnapshot _origin;
}

/// Prototype controller for structured fractions, with exact Ans continuation.
///
/// The editor is private. All public state is immutable, and failed commands
/// retain the complete previous tree and cursor. These navigation rules are
/// explicit prototype decisions, not measured Casio behavior.
final class StructuredCalculatorSession {
  StructuredCalculatorSession({CalculatorMemory? memory})
    : memory = memory ?? CalculatorMemory() {
    _synchronizeAnswer();
  }

  final CalculatorMemory memory;
  StructuredMemoryAssignment? _preparedAssignment;

  StructuredCalculatorSnapshot _snapshot = StructuredCalculatorSnapshot._(
    editor: FractionEditor().snapshot,
    phase: CalculatorPhase.editing,
    answer: Rational.fromInt(0),
  );

  StructuredCalculatorSnapshot get snapshot {
    _synchronizeAnswer();
    return _snapshot;
  }

  void _synchronizeAnswer() {
    final answer = memory.snapshot.answer;
    if (_snapshot.answer != answer) {
      _snapshot = StructuredCalculatorSnapshot._(
        editor: _snapshot.editor,
        phase: _snapshot.phase,
        answer: answer,
        result: _snapshot.result,
        error: _snapshot.error,
        errorCursor: _snapshot.errorCursor,
        resultDisplayFormat: _snapshot.resultDisplayFormat,
      );
    }
  }

  /// Selects the requested representation without evaluating or formatting it.
  /// Fallback output may be a fraction while this choice stays exactDecimal.
  StructuredCalculatorSnapshot selectResultDisplayFormat(
    RationalDisplayFormat format,
  ) {
    _synchronizeAnswer();
    if (_snapshot.phase != CalculatorPhase.result ||
        _snapshot.resultDisplayFormat == format) {
      return _snapshot;
    }
    return _snapshot = StructuredCalculatorSnapshot._(
      editor: _snapshot.editor,
      phase: _snapshot.phase,
      answer: _snapshot.answer,
      result: _snapshot.result,
      error: _snapshot.error,
      errorCursor: _snapshot.errorCursor,
      resultDisplayFormat: format,
    );
  }

  /// Fraction and vertical-navigation IDs are local to this session; the
  /// linear key enum stays unchanged.
  StructuredCalculatorSnapshot pressId(String id) {
    _synchronizeAnswer();
    if (id == 'ACTION_WRAP_FRACTION') {
      if (_snapshot.phase != CalculatorPhase.editing) return _snapshot;
      return _apply((editor) => editor.wrapPreviousAtomInFraction());
    }
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
    _synchronizeAnswer();
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

    if (key == CalculatorKey.absolute) {
      return _apply((editor) {
        final continuing = _snapshot.phase == CalculatorPhase.result;
        if (continuing) editor.clear();
        editor.insertAbsolute();
        if (continuing) editor.insertText('Ans');
      });
    }

    return _apply((editor) {
      if (_snapshot.phase == CalculatorPhase.result) {
        editor.clear();
        if (key.isBinaryOperator || key.isPostfixOperator) {
          editor.insertText('Ans');
        }
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

  bool _assignmentOriginMatches(StructuredMemoryAssignment candidate) =>
      identical(candidate._owner, this) &&
      candidate._origin.phase == _snapshot.phase &&
      identical(candidate._origin.editor, _snapshot.editor) &&
      candidate._origin.result == _snapshot.result;

  /// Freezes an operand without assigning M or updating Ans. Repeated calls
  /// reuse the candidate while its source is unchanged. Shared-register or
  /// display-choice changes alone do not invalidate an already frozen value.
  StructuredMemoryAssignment? prepareMemoryAssignment() {
    _synchronizeAnswer();
    final prepared = _preparedAssignment;
    if (prepared != null && _assignmentOriginMatches(prepared)) {
      return prepared;
    }
    _preparedAssignment = null;
    if (_snapshot.phase == CalculatorPhase.error ||
        (_snapshot.phase == CalculatorPhase.editing &&
            _snapshot.editor.root.nodes.isEmpty)) {
      return null;
    }
    EditorProjection? projection;
    try {
      final Rational value;
      if (_snapshot.phase == CalculatorPhase.result) {
        value = _snapshot.result!;
      } else {
        projection = FractionEditor.fromSnapshot(_snapshot.editor).project();
        final registers = memory.snapshot;
        value = arithmetic.evaluate(
          projection.expression,
          answer: registers.answer,
          memoryValue: registers.memory,
        );
      }
      return _preparedAssignment = StructuredMemoryAssignment._(
        value,
        this,
        _snapshot,
      );
    } on EditorProjectionException catch (diagnostic) {
      _fail(diagnostic.error, cursor: diagnostic.cursor);
    } on CalculatorException catch (error) {
      final position = error.position;
      _fail(
        error,
        cursor: position == null
            ? _snapshot.editor.cursor
            : projection!.cursorAt(position),
      );
    }
    return null;
  }

  /// Commits only this session's current candidate. Stale or foreign values
  /// never restore an old editor or undo direct register changes.
  bool commitMemoryAssignment(StructuredMemoryAssignment candidate) {
    _synchronizeAnswer();
    if (!identical(candidate._owner, this) ||
        !identical(candidate, _preparedAssignment)) {
      return false;
    }
    _preparedAssignment = null;
    if (!_assignmentOriginMatches(candidate)) return false;
    try {
      memory.acceptResult(candidate.value, operation: MemoryOperation.store);
      _publishResult(candidate.value);
      return true;
    } on CalculatorException catch (error) {
      _fail(error);
      return false;
    }
  }

  /// Aborts preparation only; it does not roll back any session or register.
  void cancelMemoryAssignment() => _preparedAssignment = null;

  /// Loads the current exact M as a fresh coherent M expression. The shown
  /// result is frozen, while later editing binds M to its then-current value.
  StructuredCalculatorSnapshot recallMemory() {
    _synchronizeAnswer();
    _preparedAssignment = null;
    try {
      final editor = FractionEditor()..insertText('M');
      final registers = memory.snapshot;
      final value = editor.evaluate(
        answer: registers.answer,
        memoryValue: registers.memory,
      );
      memory.acceptResult(value);
      return _snapshot = StructuredCalculatorSnapshot._(
        editor: editor.snapshot,
        phase: CalculatorPhase.result,
        answer: value,
        result: value,
      );
    } on CalculatorException catch (error) {
      return _fail(error);
    }
  }

  /// Commits the current operand while preserving error recovery and drafts.
  /// A displayed result is reused exactly, even if shared Ans has since changed.
  StructuredCalculatorSnapshot applyMemory(MemoryOperation operation) {
    _synchronizeAnswer();
    if (_snapshot.phase == CalculatorPhase.error ||
        (_snapshot.phase == CalculatorPhase.editing &&
            _snapshot.editor.root.nodes.isEmpty)) {
      return _snapshot;
    }
    if (_snapshot.phase == CalculatorPhase.editing) {
      return _execute(operation: operation);
    }
    try {
      final value = memory.acceptResult(
        _snapshot.result!,
        operation: operation,
      );
      return _publishResult(value);
    } on CalculatorException catch (error) {
      return _fail(error);
    }
  }

  StructuredCalculatorSnapshot _execute({
    MemoryOperation operation = MemoryOperation.result,
  }) {
    EditorProjection? projection;
    try {
      projection = FractionEditor.fromSnapshot(_snapshot.editor).project();
      final registers = memory.snapshot;
      final value = arithmetic.evaluate(
        projection.expression,
        answer: registers.answer,
        memoryValue: registers.memory,
      );
      memory.acceptResult(value, operation: operation);
      return _publishResult(value);
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

  StructuredCalculatorSnapshot _publishResult(Rational value) {
    _preparedAssignment = null;
    return _snapshot = StructuredCalculatorSnapshot._(
      editor: _snapshot.editor,
      phase: CalculatorPhase.result,
      answer: value,
      result: value,
    );
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
  }) {
    _preparedAssignment = null;
    return _snapshot = StructuredCalculatorSnapshot._(
      editor: _snapshot.editor,
      phase: CalculatorPhase.error,
      answer: _snapshot.answer,
      error: error,
      errorCursor: cursor ?? _snapshot.editor.cursor,
    );
  }
}
