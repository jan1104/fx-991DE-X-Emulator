import '../errors.dart';
import '../evaluation/evaluator.dart';
import '../numbers/rational.dart';

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

  bool get isBinaryOperator => switch (this) {
    add || subtract || multiply || divide || power => true,
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

  CalculatorSnapshot._({
    required this.phase,
    required List<String> tokens,
    required this.cursor,
    required this.answer,
    this.result,
    this.error,
  }) : tokens = List<String>.unmodifiable(tokens);

  String get expression => tokens.join();
  int get cursorOffset =>
      tokens.take(cursor).fold(0, (sum, token) => sum + token.length);
}

/// A small, synchronous linear editor/controller for the general calculation
/// mode. It has no Flutter, platform, modifier, menu or persistence dependency.
final class CalculatorSession {
  CalculatorSnapshot _snapshot = CalculatorSnapshot._(
    phase: CalculatorPhase.editing,
    tokens: const [],
    cursor: 0,
    answer: Rational.fromInt(0),
  );

  CalculatorSnapshot get snapshot => _snapshot;

  /// Unsupported keys fail explicitly and do not alter the previous state.
  CalculatorSnapshot pressId(String id) {
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
      tokens =
          key.isBinaryOperator ||
              key == CalculatorKey.square ||
              key == CalculatorKey.reciprocal
          ? ['Ans']
          : [];
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

  void _execute() {
    try {
      final value = evaluate(_snapshot.expression, answer: _snapshot.answer);
      _snapshot = CalculatorSnapshot._(
        phase: CalculatorPhase.result,
        tokens: _snapshot.tokens,
        cursor: _snapshot.tokens.length,
        answer: value,
        result: value,
      );
    } on CalculatorException catch (error) {
      _fail(error);
    }
  }

  void _fail(CalculatorException error) {
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
