import '../errors.dart';
import '../evaluation/evaluator.dart' as arithmetic;
import '../formatting/rational_display.dart';
import '../numbers/rational.dart';
import 'calculator_memory.dart';

/// Supported semantic keys of the linear prototype, not the full keyboard.
enum CalculatorKey {
  digit0('KEY_0', '0'),
  digit1('KEY_1', '1'),
  digit2('KEY_2', '2'),
  digit3('KEY_3', '3'),
  digit4('KEY_4', '4'),
  digit5('KEY_5', '5'),
  digit6('KEY_6', '6'),
  digit7('KEY_7', '7'),
  digit8('KEY_8', '8'),
  digit9('KEY_9', '9'),
  add('KEY_ADD', '+'),
  subtract('KEY_SUBTRACT', '-'),
  multiply('KEY_MULTIPLY', '*'),
  divide('KEY_DIVIDE', '/'),
  power('KEY_POWER', '^'),
  square('KEY_SQUARE', '²'),
  reciprocal('KEY_RECIPROCAL', '⁻¹'),
  cube('ACTION_CUBE', '³'),
  percent('ACTION_PERCENT', '%'),
  factorial('ACTION_FACTORIAL', '!'),
  permutation('ACTION_PERMUTATION', 'nPr'),
  combination('ACTION_COMBINATION', 'nCr'),
  absolute('ACTION_ABS', 'Abs('),
  negate('KEY_NEGATE', '-'),
  decimal('KEY_DECIMAL', ','),
  leftParenthesis('KEY_LPAREN', '('),
  rightParenthesis('KEY_RPAREN', ')'),
  left('KEY_LEFT'),
  right('KEY_RIGHT'),
  delete('KEY_DEL'),
  clear('KEY_AC'),
  equals('KEY_EQUALS'),
  answer('KEY_ANS', 'Ans');

  final String id;
  final String? text;
  const CalculatorKey(this.id, [this.text]);

  bool get isPostfixOperator =>
      this == square ||
      this == reciprocal ||
      this == cube ||
      this == percent ||
      this == factorial;

  bool get isBinaryOperator => switch (this) {
    add ||
    subtract ||
    multiply ||
    divide ||
    power ||
    permutation ||
    combination => true,
    _ => false,
  };

  static CalculatorKey? fromId(String id) {
    for (final key in values) {
      if (key.id == id) return key;
    }
    return null;
  }
}

enum CalculatorPhase { editing, result, error }

/// A read-only UI snapshot. Cursor positions count logical tokens, not pixels.
/// Ans is one token even though it occupies three characters in [expression].
final class CalculatorSnapshot {
  final CalculatorPhase phase;
  final List<String> tokens;
  final int cursor;
  final Rational answer;
  final Rational? result;
  final CalculatorException? error;
  final RationalDisplayFormat resultDisplayFormat;

  CalculatorSnapshot._({
    required this.phase,
    required List<String> tokens,
    required this.cursor,
    required this.answer,
    this.result,
    this.error,
  }) : tokens = List<String>.unmodifiable(tokens),
       resultDisplayFormat = RationalDisplayFormat.fraction;

  CalculatorSnapshot._withDisplayFormat(
    CalculatorSnapshot previous,
    this.resultDisplayFormat,
  ) : phase = previous.phase,
      tokens = previous.tokens,
      cursor = previous.cursor,
      answer = previous.answer,
      result = previous.result,
      error = previous.error;

  CalculatorSnapshot._withAnswer(CalculatorSnapshot previous, this.answer)
    : phase = previous.phase,
      tokens = previous.tokens,
      cursor = previous.cursor,
      result = previous.result,
      error = previous.error,
      resultDisplayFormat = previous.resultDisplayFormat;

  /// Formats only a present result. Outside the result phase this is a no-op,
  /// including when the supplied budgets would otherwise be invalid.
  /// Formatter failures do not change the snapshot or the owning session.
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

  String get expression => tokens.join();
  int get cursorOffset =>
      tokens.take(cursor).fold(0, (sum, token) => sum + token.length);
}

/// A frozen, session-owned value awaiting an explicit memory assignment.
/// Preparing it does not execute a memory transaction or alter its origin.
final class LinearMemoryAssignment {
  const LinearMemoryAssignment._(this.value, this._owner, this._origin);

  final Rational value;
  final CalculatorSession _owner;
  final CalculatorSnapshot _origin;
}

/// A small, synchronous linear editor/controller for the general calculation
/// mode. It has no Flutter, platform, modifier, menu or persistence dependency.
final class CalculatorSession {
  CalculatorSession({CalculatorMemory? memory})
    : memory = memory ?? CalculatorMemory() {
    _synchronizeAnswer();
  }

  final CalculatorMemory memory;
  LinearMemoryAssignment? _pendingAssignment;

  CalculatorSnapshot _snapshot = CalculatorSnapshot._(
    phase: CalculatorPhase.editing,
    tokens: const [],
    cursor: 0,
    answer: Rational.fromInt(0),
  );

  CalculatorSnapshot get snapshot {
    _synchronizeAnswer();
    return _snapshot;
  }

  void _synchronizeAnswer() {
    final answer = memory.snapshot.answer;
    if (_snapshot.answer != answer) {
      _snapshot = CalculatorSnapshot._withAnswer(_snapshot, answer);
    }
  }

  /// Changes only the requested display of the current result. No formatting
  /// or numerical conversion happens until the snapshot's formatResult call.
  CalculatorSnapshot selectResultDisplayFormat(RationalDisplayFormat format) {
    _synchronizeAnswer();
    if (_snapshot.phase != CalculatorPhase.result ||
        _snapshot.resultDisplayFormat == format) {
      return _snapshot;
    }
    return _snapshot = CalculatorSnapshot._withDisplayFormat(_snapshot, format);
  }

  /// Unsupported keys fail explicitly without editing the expression or memory.
  CalculatorSnapshot pressId(String id) {
    _synchronizeAnswer();
    final key = CalculatorKey.fromId(id);
    if (key == null) {
      throw CalculatorException(
        CalculatorErrorCode.unsupported,
        'Key $id is not implemented in this prototype',
      );
    }
    return press(key);
  }

  CalculatorSnapshot press(CalculatorKey key) {
    _synchronizeAnswer();
    if (key == CalculatorKey.clear) {
      _edit(const [], 0);
      return _snapshot;
    }
    // Error recovery is explicit: restore with navigation or discard with AC.
    if (_snapshot.phase == CalculatorPhase.error) {
      if (key == CalculatorKey.left || key == CalculatorKey.right) {
        final offset = _snapshot.error?.position ?? _snapshot.expression.length;
        final cursor = _tokenIndexAt(offset);
        _edit(_snapshot.tokens, cursor);
      }
      return _snapshot;
    }
    if (key == CalculatorKey.left || key == CalculatorKey.right) {
      final cursor = _snapshot.phase == CalculatorPhase.result
          ? _snapshot.tokens.length
          : (_snapshot.cursor + (key == CalculatorKey.left ? -1 : 1)).clamp(
              0,
              _snapshot.tokens.length,
            );
      _edit(_snapshot.tokens, cursor);
      return _snapshot;
    }
    if (key == CalculatorKey.equals) {
      if (_snapshot.phase == CalculatorPhase.editing &&
          _snapshot.tokens.isNotEmpty) {
        _execute();
      }
      return _snapshot;
    }
    if (key == CalculatorKey.delete) {
      final cursor = _snapshot.phase == CalculatorPhase.result
          ? _snapshot.tokens.length
          : _snapshot.cursor;
      final tokens = _snapshot.tokens.toList();
      if (cursor > 0) tokens.removeAt(cursor - 1);
      _edit(tokens, cursor > 0 ? cursor - 1 : 0);
      return _snapshot;
    }
    var tokens = _snapshot.tokens.toList();
    var cursor = _snapshot.cursor;
    if (_snapshot.phase == CalculatorPhase.result) {
      if (key == CalculatorKey.absolute) {
        _edit(['Abs(', 'Ans'], 2);
        return _snapshot;
      }
      tokens = key.isBinaryOperator || key.isPostfixOperator ? ['Ans'] : [];
      cursor = tokens.length;
    }
    final text = key.text!; // All non-text control keys were handled above.
    if (tokens.fold<int>(0, (sum, token) => sum + token.length) + text.length >
        2048) {
      _fail(
        CalculatorException(
          CalculatorErrorCode.limit,
          'Input too long',
          position: _snapshot.cursorOffset,
        ),
      );
      return _snapshot;
    }
    tokens.insert(cursor, text);
    _edit(tokens, cursor + 1);
    return _snapshot;
  }

  void _edit(List<String> tokens, int cursor) {
    _snapshot = CalculatorSnapshot._(
      phase: CalculatorPhase.editing,
      tokens: tokens,
      cursor: cursor,
      answer: _snapshot.answer,
    );
  }

  /// Prepares one exact operand without writing Ans or M. Repeated preparation
  /// preserves a valid candidate, including after a shared-register change.
  LinearMemoryAssignment? prepareMemoryAssignment() {
    _synchronizeAnswer();
    final pending = _pendingAssignment;
    if (pending != null && _assignmentOriginMatches(pending)) return pending;
    _pendingAssignment = null;
    if (_snapshot.phase == CalculatorPhase.error ||
        (_snapshot.phase == CalculatorPhase.editing &&
            _snapshot.tokens.isEmpty)) {
      return null;
    }
    try {
      final registers = memory.snapshot;
      final value = _snapshot.phase == CalculatorPhase.result
          ? _snapshot.result!
          : arithmetic.evaluate(
              _snapshot.expression,
              answer: registers.answer,
              memoryValue: registers.memory,
            );
      return _pendingAssignment = LinearMemoryAssignment._(
        value,
        this,
        _snapshot,
      );
    } on CalculatorException catch (error) {
      _fail(error);
      return null;
    }
  }

  bool _assignmentOriginMatches(LinearMemoryAssignment candidate) {
    final origin = candidate._origin;
    return identical(candidate._owner, this) &&
        origin.phase == _snapshot.phase &&
        identical(origin.tokens, _snapshot.tokens) &&
        origin.cursor == _snapshot.cursor &&
        origin.result == _snapshot.result;
  }

  /// Assigns only the current candidate from this unchanged session origin.
  /// Rejection never restores an old editor or rolls back shared registers.
  bool commitMemoryAssignment(LinearMemoryAssignment candidate) {
    _synchronizeAnswer();
    if (!identical(candidate._owner, this) ||
        !identical(candidate, _pendingAssignment)) {
      return false;
    }
    if (!_assignmentOriginMatches(candidate)) {
      _pendingAssignment = null;
      return false;
    }
    try {
      final value = memory.acceptResult(
        candidate.value,
        operation: MemoryOperation.store,
      );
      _publishResult(value);
      return true;
    } on CalculatorException catch (error) {
      _fail(error);
      return false;
    }
  }

  /// Cancels only the prepared action; neither editor nor registers are restored.
  void cancelMemoryAssignment() => _pendingAssignment = null;

  /// Loads the current exact M as a fresh, coherent expression and result.
  /// Later editing opens M, rather than the expression preceding the recall.
  CalculatorSnapshot recallMemory() {
    _synchronizeAnswer();
    _pendingAssignment = null;
    try {
      final value = memory.calculate('M');
      return _snapshot = CalculatorSnapshot._(
        phase: CalculatorPhase.result,
        tokens: const ['M'],
        cursor: 1,
        answer: value,
        result: value,
      );
    } on CalculatorException catch (error) {
      _fail(error);
      return _snapshot;
    }
  }

  /// Commits the current operand, not a reevaluation of a displayed result.
  /// Empty editors and error phases are unchanged; AC remains editor-only.
  CalculatorSnapshot applyMemory(MemoryOperation operation) {
    _synchronizeAnswer();
    if (_snapshot.phase == CalculatorPhase.error ||
        (_snapshot.phase == CalculatorPhase.editing &&
            _snapshot.tokens.isEmpty)) {
      return _snapshot;
    }
    if (_snapshot.phase == CalculatorPhase.editing) {
      _execute(operation: operation);
    } else {
      try {
        final value = memory.acceptResult(
          _snapshot.result!,
          operation: operation,
        );
        _publishResult(value);
      } on CalculatorException catch (error) {
        _fail(error);
      }
    }
    return _snapshot;
  }

  void _execute({MemoryOperation operation = MemoryOperation.result}) {
    try {
      final value = memory.calculate(
        _snapshot.expression,
        operation: operation,
      );
      _publishResult(value);
    } on CalculatorException catch (error) {
      _fail(error);
    }
  }

  void _publishResult(Rational value) {
    _pendingAssignment = null;
    _snapshot = CalculatorSnapshot._(
      phase: CalculatorPhase.result,
      tokens: _snapshot.tokens,
      cursor: _snapshot.tokens.length,
      answer: value,
      result: value,
    );
  }

  void _fail(CalculatorException error) {
    _pendingAssignment = null;
    _snapshot = CalculatorSnapshot._(
      phase: CalculatorPhase.error,
      tokens: _snapshot.tokens,
      cursor: _snapshot.cursor,
      answer: _snapshot.answer,
      error: error,
    );
  }

  int _tokenIndexAt(int offset) {
    var position = 0;
    for (var index = 0; index < _snapshot.tokens.length; index++) {
      if (position + _snapshot.tokens[index].length > offset) return index;
      position += _snapshot.tokens[index].length;
    }
    return _snapshot.tokens.length;
  }
}
