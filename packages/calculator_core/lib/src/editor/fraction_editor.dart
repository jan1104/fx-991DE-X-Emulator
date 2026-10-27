import '../errors.dart';
import '../evaluation/evaluator.dart' as arithmetic;
import '../numbers/rational.dart';

/// A small structural input model, independent of layout and calculator modes.
sealed class EditorNode {
  const EditorNode();
}

final class EditorText extends EditorNode {
  final String text;
  const EditorText._(this.text);
}

final class EditorSequence {
  final List<EditorNode> nodes;
  EditorSequence._(Iterable<EditorNode> nodes)
    : nodes = List.unmodifiable(nodes);
}

final class EditorFraction extends EditorNode {
  final EditorSequence numerator;
  final EditorSequence denominator;
  const EditorFraction._(this.numerator, this.denominator);
}

enum FractionField { numerator, denominator }

final class EditorStep {
  final int nodeIndex;
  final FractionField field;
  const EditorStep._(this.nodeIndex, this.field);
}

final class EditorCursor {
  final List<EditorStep> path;
  final int offset;
  EditorCursor._(Iterable<EditorStep> path, this.offset)
    : path = List.unmodifiable(path);
}

final class FractionEditorSnapshot {
  final EditorSequence root;
  final EditorCursor cursor;
  const FractionEditorSnapshot._(this.root, this.cursor);
}

/// Prototype navigation rules are explicit, not measured original behavior.
/// Every edit creates a new immutable tree; rejected edits preserve the snapshot.
final class FractionEditor {
  static const maxNodes = 256;
  static const maxDepth = 16;
  static const _tokens = {
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '+',
    '-',
    '*',
    '/',
    '^',
    '(',
    ')',
    ',',
    '.',
    'Ans',
  };

  FractionEditorSnapshot _snapshot = FractionEditorSnapshot._(
    EditorSequence._([]),
    EditorCursor._([], 0),
  );
  FractionEditorSnapshot get snapshot => _snapshot;

  EditorSequence get _field {
    var sequence = _snapshot.root;
    for (final step in _snapshot.cursor.path) {
      final fraction = sequence.nodes[step.nodeIndex] as EditorFraction;
      sequence = step.field == FractionField.numerator
          ? fraction.numerator
          : fraction.denominator;
    }
    return sequence;
  }

  void insertText(String text) {
    if (!_tokens.contains(text)) {
      throw ArgumentError.value(text, 'text', 'Expected one supported token');
    }
    _insert(EditorText._(text), enter: false);
  }

  void insertFraction() {
    if (_snapshot.cursor.path.length >= maxDepth) {
      throw const CalculatorException(
        CalculatorErrorCode.limit,
        'Fraction nesting limit reached',
      );
    }
    _insert(
      EditorFraction._(EditorSequence._([]), EditorSequence._([])),
      enter: true,
    );
  }

  void _insert(EditorNode node, {required bool enter}) {
    if (_count(_snapshot.root) >= maxNodes) {
      throw const CalculatorException(
        CalculatorErrorCode.limit,
        'Editor node limit reached',
      );
    }
    final cursor = _snapshot.cursor;
    final nodes = _field.nodes.toList()..insert(cursor.offset, node);
    final root = _replace(
      _snapshot.root,
      cursor.path,
      0,
      EditorSequence._(nodes),
    );
    _snapshot = FractionEditorSnapshot._(
      root,
      enter
          ? EditorCursor._([
              ...cursor.path,
              EditorStep._(cursor.offset, FractionField.numerator),
            ], 0)
          : EditorCursor._(cursor.path, cursor.offset + 1),
    );
  }

  void clear() {
    _snapshot = FractionEditorSnapshot._(
      EditorSequence._([]),
      EditorCursor._([], 0),
    );
  }

  void deleteBackward() {
    final cursor = _snapshot.cursor;
    if (cursor.offset == 0) return;
    final nodes = _field.nodes.toList()..removeAt(cursor.offset - 1);
    _snapshot = FractionEditorSnapshot._(
      _replace(_snapshot.root, cursor.path, 0, EditorSequence._(nodes)),
      EditorCursor._(cursor.path, cursor.offset - 1),
    );
  }

  void moveRight() {
    final cursor = _snapshot.cursor;
    if (cursor.offset < _field.nodes.length) {
      if (_field.nodes[cursor.offset] is EditorFraction) {
        _move([
          ...cursor.path,
          EditorStep._(cursor.offset, FractionField.numerator),
        ], 0);
      } else {
        _move(cursor.path, cursor.offset + 1);
      }
    } else if (cursor.path.isNotEmpty) {
      final step = cursor.path.last;
      final parent = cursor.path.take(cursor.path.length - 1).toList();
      if (step.field == FractionField.numerator) {
        _move([
          ...parent,
          EditorStep._(step.nodeIndex, FractionField.denominator),
        ], 0);
      } else {
        _move(parent, step.nodeIndex + 1);
      }
    }
  }

  void moveLeft() {
    final cursor = _snapshot.cursor;
    if (cursor.offset > 0) {
      final previous = _field.nodes[cursor.offset - 1];
      if (previous is EditorFraction) {
        _move([
          ...cursor.path,
          EditorStep._(cursor.offset - 1, FractionField.denominator),
        ], previous.denominator.nodes.length);
      } else {
        _move(cursor.path, cursor.offset - 1);
      }
    } else if (cursor.path.isNotEmpty) {
      final step = cursor.path.last;
      final parent = cursor.path.take(cursor.path.length - 1).toList();
      if (step.field == FractionField.denominator) {
        _move([
          ...parent,
          EditorStep._(step.nodeIndex, FractionField.numerator),
        ], 0);
        _move(_snapshot.cursor.path, _field.nodes.length);
      } else {
        _move(parent, step.nodeIndex);
      }
    }
  }

  void _move(Iterable<EditorStep> path, int offset) {
    _snapshot = FractionEditorSnapshot._(
      _snapshot.root,
      EditorCursor._(path, offset),
    );
  }

  /// Parenthesized projection preserves fractions as operands of powers/products.
  /// Empty fields are errors rather than implicit zeros.
  String toExpression() => _serialize(_snapshot.root);

  Rational evaluate({Rational? answer}) =>
      arithmetic.evaluate(toExpression(), answer: answer);

  static String _serialize(EditorSequence sequence) {
    if (sequence.nodes.isEmpty) {
      throw const CalculatorException(
        CalculatorErrorCode.syntax,
        'Empty expression field',
      );
    }
    // User parentheses belong to this field. They must never consume the
    // grouping delimiters introduced by the fraction projection.
    var parentheses = 0;
    for (final node in sequence.nodes) {
      if (node is! EditorText) continue;
      if (node.text == '(') parentheses++;
      if (node.text == ')') parentheses--;
      if (parentheses < 0) {
        throw const CalculatorException(
          CalculatorErrorCode.syntax,
          'Unbalanced parentheses in expression field',
        );
      }
    }
    if (parentheses != 0) {
      throw const CalculatorException(
        CalculatorErrorCode.syntax,
        'Unbalanced parentheses in expression field',
      );
    }
    return sequence.nodes
        .map(
          (node) => switch (node) {
            EditorText(:final text) => text,
            EditorFraction(:final numerator, :final denominator) =>
              '((${_serialize(numerator)})/(${_serialize(denominator)}))',
          },
        )
        .join();
  }

  static int _count(EditorSequence sequence) => sequence.nodes.fold(
    0,
    (total, node) =>
        total +
        1 +
        (node is EditorFraction
            ? _count(node.numerator) + _count(node.denominator)
            : 0),
  );

  static EditorSequence _replace(
    EditorSequence sequence,
    List<EditorStep> path,
    int depth,
    EditorSequence replacement,
  ) {
    if (depth == path.length) return replacement;
    final step = path[depth];
    final fraction = sequence.nodes[step.nodeIndex] as EditorFraction;
    final numerator = step.field == FractionField.numerator
        ? _replace(fraction.numerator, path, depth + 1, replacement)
        : fraction.numerator;
    final denominator = step.field == FractionField.denominator
        ? _replace(fraction.denominator, path, depth + 1, replacement)
        : fraction.denominator;
    final nodes = sequence.nodes.toList();
    nodes[step.nodeIndex] = EditorFraction._(numerator, denominator);
    return EditorSequence._(nodes);
  }
}
