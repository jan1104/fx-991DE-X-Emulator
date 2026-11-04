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

final class EditorAbsolute extends EditorNode {
  final EditorSequence argument;
  const EditorAbsolute._(this.argument);
}

// The historical enum name remains compatible with existing fraction paths.
enum FractionField { numerator, denominator, argument }

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

/// Immutable source positions for one parenthesized parser projection.
/// Offsets count UTF-16 code units, just like the parser's error positions.
final class EditorProjection {
  final String expression;
  final List<EditorCursor> _cursors;

  EditorProjection._(this.expression, Iterable<EditorCursor> cursors)
    : _cursors = List.unmodifiable(cursors);

  /// Maps a character to its owning structural token/field. The final offset
  /// maps to the root end, not the end of an innermost fraction field.
  EditorCursor cursorAt(int offset) {
    if (offset < 0 || offset > expression.length) {
      throw ArgumentError.value(offset, 'offset', 'Outside projection');
    }
    return _cursors[offset];
  }
}

/// A structural diagnostic that cannot be expressed as a parser offset.
final class EditorProjectionException implements Exception {
  final CalculatorException error;
  final EditorCursor cursor;
  const EditorProjectionException(this.error, this.cursor);

  @override
  String toString() => error.toString();
}

/// Prototype navigation rules are explicit, not measured original behavior.
/// Every edit creates a new immutable tree; rejected edits preserve the snapshot.
final class FractionEditor {
  FractionEditor();

  /// Restores a trusted immutable snapshot produced by this editor.
  /// Later edits do not mutate the supplied snapshot or any other editor.
  FractionEditor.fromSnapshot(FractionEditorSnapshot snapshot) {
    _snapshot = snapshot;
  }

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
    '²',
    '⁻¹',
    '³',
    '%',
    '!',
    'nPr',
    'nCr',
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
      sequence = _child(sequence.nodes[step.nodeIndex], step.field);
    }
    return sequence;
  }

  static EditorSequence _child(EditorNode node, FractionField field) =>
      switch ((node, field)) {
        (EditorFraction(:final numerator), FractionField.numerator) =>
          numerator,
        (EditorFraction(:final denominator), FractionField.denominator) =>
          denominator,
        (EditorAbsolute(:final argument), FractionField.argument) => argument,
        _ => throw ArgumentError('Field does not belong to this template'),
      };

  void insertText(String text) {
    if (!_tokens.contains(text)) {
      throw ArgumentError.value(text, 'text', 'Expected one supported token');
    }
    _insert(EditorText._(text));
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
      enter: FractionField.numerator,
    );
  }

  void insertAbsolute() {
    _insert(
      EditorAbsolute._(EditorSequence._([])),
      enter: FractionField.argument,
    );
  }

  /// Explicitly moves the immediately preceding atom into a new numerator.
  /// Closed parenthesized groups are captured whole. Signs, operators and power
  /// chains outside that group are never inferred as part of the atom.
  /// The denominator starts empty, and all resource checks are atomic.
  void wrapPreviousAtomInFraction() {
    final cursor = _snapshot.cursor;
    if (cursor.offset == 0) {
      throw const CalculatorException(
        CalculatorErrorCode.unsupported,
        'No preceding atom to wrap',
      );
    }
    final nodes = _field.nodes.toList();
    var start = cursor.offset - 1;
    final previous = nodes[start];
    if (_isDecimalToken(previous)) {
      if (cursor.offset < nodes.length &&
          _isDecimalToken(nodes[cursor.offset])) {
        throw const CalculatorException(
          CalculatorErrorCode.unsupported,
          'Cursor inside numeric literal',
        );
      }
      while (start > 0 && _isDecimalToken(nodes[start - 1])) {
        start--;
      }
      final source = nodes
          .sublist(start, cursor.offset)
          .map((node) => (node as EditorText).text)
          .join();
      try {
        Rational.parseDecimal(source);
      } on FormatException {
        throw const CalculatorException(
          CalculatorErrorCode.syntax,
          'The preceding decimal number is malformed',
        );
      } on RangeError {
        throw const CalculatorException(
          CalculatorErrorCode.limit,
          'The preceding number exceeds the input budget',
        );
      }
    } else if (previous is EditorText && previous.text == ')') {
      var balance = 0;
      var opening = -1;
      for (var index = start; index >= 0; index--) {
        final node = nodes[index];
        // Fractions are indivisible atoms here, even when their own fields
        // contain parentheses. Only this sequence's text delimiters count.
        if (node is! EditorText) continue;
        if (node.text == ')') balance++;
        if (node.text == '(') {
          balance--;
          if (balance == 0) {
            opening = index;
            break;
          }
        }
      }
      if (opening < 0) {
        throw const CalculatorException(
          CalculatorErrorCode.syntax,
          'The preceding group has no matching opening parenthesis',
        );
      }
      if (nodes
          .sublist(opening + 1, cursor.offset - 1)
          .every(
            (node) =>
                node is EditorText && (node.text == '(' || node.text == ')'),
          )) {
        throw const CalculatorException(
          CalculatorErrorCode.syntax,
          'The preceding group has no content',
        );
      }
      start = opening;
    } else if (previous is! EditorFraction &&
        previous is! EditorAbsolute &&
        !(previous is EditorText && previous.text == 'Ans')) {
      throw const CalculatorException(
        CalculatorErrorCode.unsupported,
        'Only a preceding number, Ans, fraction or closed group can be wrapped',
      );
    }
    if (_count(_snapshot.root) >= maxNodes) {
      throw const CalculatorException(
        CalculatorErrorCode.limit,
        'Editor node limit reached',
      );
    }
    final numerator = EditorSequence._(nodes.sublist(start, cursor.offset));
    nodes.replaceRange(start, cursor.offset, [
      EditorFraction._(numerator, EditorSequence._([])),
    ]);
    final root = _replace(
      _snapshot.root,
      cursor.path,
      0,
      EditorSequence._(nodes),
    );
    // Wrapping an existing fraction also pushes every descendant down a level.
    // Checking just the active cursor depth would miss those hidden descendants.
    if (_fractionDepth(root) > maxDepth) {
      throw const CalculatorException(
        CalculatorErrorCode.limit,
        'Fraction nesting limit reached',
      );
    }
    _snapshot = FractionEditorSnapshot._(
      root,
      EditorCursor._([
        ...cursor.path,
        EditorStep._(start, FractionField.denominator),
      ], 0),
    );
  }

  static bool _isDecimalToken(EditorNode node) =>
      node is EditorText &&
      node.text.length == 1 &&
      '0123456789.,'.contains(node.text);

  static int _fractionDepth(EditorSequence sequence) {
    var deepest = 0;
    for (final node in sequence.nodes) {
      final depth = switch (node) {
        EditorText() => 0,
        EditorAbsolute(:final argument) => 1 + _fractionDepth(argument),
        EditorFraction(:final numerator, :final denominator) =>
          1 + _max(_fractionDepth(numerator), _fractionDepth(denominator)),
      };
      if (depth > deepest) deepest = depth;
    }
    return deepest;
  }

  static int _max(int a, int b) => a > b ? a : b;

  void _insert(EditorNode node, {FractionField? enter}) {
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
    if (_fractionDepth(root) > maxDepth) {
      throw const CalculatorException(
        CalculatorErrorCode.limit,
        'Template nesting limit reached',
      );
    }
    _snapshot = FractionEditorSnapshot._(
      root,
      enter != null
          ? EditorCursor._([
              ...cursor.path,
              EditorStep._(cursor.offset, enter),
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

  /// Reopens the complete expression after a result, outside all fraction fields.
  void moveToRootEnd() => _move([], _snapshot.root.nodes.length);

  /// Moves only if the whole cursor is valid in the current tree. A cursor may
  /// originate from an older or different immutable snapshot.
  void moveTo(EditorCursor cursor) {
    var sequence = _snapshot.root;
    for (final step in cursor.path) {
      if (step.nodeIndex < 0 || step.nodeIndex >= sequence.nodes.length) {
        throw ArgumentError.value(cursor, 'cursor', 'Invalid fraction path');
      }
      final node = sequence.nodes[step.nodeIndex];
      sequence = _child(node, step.field);
    }
    if (cursor.offset < 0 || cursor.offset > sequence.nodes.length) {
      throw ArgumentError.value(cursor, 'cursor', 'Invalid field offset');
    }
    _move(cursor.path, cursor.offset);
  }

  void deleteBackward() {
    final cursor = _snapshot.cursor;
    if (cursor.offset == 0) {
      if (_field.nodes.isNotEmpty ||
          cursor.path.isEmpty ||
          cursor.path.last.field != FractionField.argument)
        return;
      final parentPath = cursor.path.take(cursor.path.length - 1).toList();
      final index = cursor.path.last.nodeIndex;
      var parent = _snapshot.root;
      for (final step in parentPath) {
        parent = _child(parent.nodes[step.nodeIndex], step.field);
      }
      final nodes = parent.nodes.toList()..removeAt(index);
      _snapshot = FractionEditorSnapshot._(
        _replace(_snapshot.root, parentPath, 0, EditorSequence._(nodes)),
        EditorCursor._(parentPath, index),
      );
      return;
    }
    final nodes = _field.nodes.toList()..removeAt(cursor.offset - 1);
    _snapshot = FractionEditorSnapshot._(
      _replace(_snapshot.root, cursor.path, 0, EditorSequence._(nodes)),
      EditorCursor._(cursor.path, cursor.offset - 1),
    );
  }

  void moveRight() {
    final cursor = _snapshot.cursor;
    if (cursor.offset < _field.nodes.length) {
      final next = _field.nodes[cursor.offset];
      if (next is EditorFraction || next is EditorAbsolute) {
        _move([
          ...cursor.path,
          EditorStep._(
            cursor.offset,
            next is EditorAbsolute
                ? FractionField.argument
                : FractionField.numerator,
          ),
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
      } else if (previous is EditorAbsolute) {
        _move([
          ...cursor.path,
          EditorStep._(cursor.offset - 1, FractionField.argument),
        ], previous.argument.nodes.length);
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

  /// Switches from denominator to numerator of the immediate fraction only.
  /// The logical token offset is clamped to the target field's length.
  void moveUp() => _moveVertically(FractionField.numerator);

  /// Switches from numerator to denominator of the immediate fraction only.
  void moveDown() => _moveVertically(FractionField.denominator);

  void _moveVertically(FractionField destination) {
    final cursor = _snapshot.cursor;
    if (cursor.path.isEmpty ||
        cursor.path.last.field == destination ||
        cursor.path.last.field == FractionField.argument)
      return;
    final parentPath = cursor.path.take(cursor.path.length - 1).toList();
    var parent = _snapshot.root;
    for (final step in parentPath) {
      parent = _child(parent.nodes[step.nodeIndex], step.field);
    }
    final index = cursor.path.last.nodeIndex;
    final target = _child(parent.nodes[index], destination);
    _move([
      ...parentPath,
      EditorStep._(index, destination),
    ], cursor.offset.clamp(0, target.nodes.length));
  }

  void _move(Iterable<EditorStep> path, int offset) {
    _snapshot = FractionEditorSnapshot._(
      _snapshot.root,
      EditorCursor._(path, offset),
    );
  }

  /// Parenthesized projection preserves fractions as operands of powers/products.
  /// Empty fields are errors rather than implicit zeros.
  String toExpression() {
    try {
      return project().expression;
    } on EditorProjectionException catch (diagnostic) {
      // Preserve the existing serialization/evaluation exception contract.
      throw diagnostic.error;
    }
  }

  Rational evaluate({Rational? answer}) =>
      arithmetic.evaluate(toExpression(), answer: answer);

  EditorProjection project() {
    final output = StringBuffer();
    final cursors = <EditorCursor>[];
    _project(_snapshot.root, const [], output, cursors);
    cursors.add(EditorCursor._([], _snapshot.root.nodes.length));
    return EditorProjection._(output.toString(), cursors);
  }

  static Never _projectionError(String message, EditorCursor cursor) {
    throw EditorProjectionException(
      CalculatorException(CalculatorErrorCode.syntax, message),
      cursor,
    );
  }

  static void _project(
    EditorSequence sequence,
    List<EditorStep> path,
    StringBuffer output,
    List<EditorCursor> cursors,
  ) {
    if (sequence.nodes.isEmpty) {
      _projectionError('Empty expression field', EditorCursor._(path, 0));
    }
    // User parentheses belong to this field. They must never consume the
    // grouping delimiters introduced by the fraction projection.
    var parentheses = 0;
    for (var index = 0; index < sequence.nodes.length; index++) {
      final node = sequence.nodes[index];
      if (node is! EditorText) continue;
      if (node.text == '(') parentheses++;
      if (node.text == ')') parentheses--;
      if (parentheses < 0) {
        _projectionError(
          'Unbalanced parentheses in expression field',
          EditorCursor._(path, index),
        );
      }
    }
    if (parentheses != 0) {
      _projectionError(
        'Unbalanced parentheses in expression field',
        EditorCursor._(path, sequence.nodes.length),
      );
    }
    void write(String text, EditorCursor cursor) {
      output.write(text);
      cursors.addAll(List.filled(text.length, cursor));
    }

    for (var index = 0; index < sequence.nodes.length; index++) {
      switch (sequence.nodes[index]) {
        case EditorText(:final text):
          write(text, EditorCursor._(path, index));
        case EditorAbsolute(:final argument):
          final argumentPath = [
            ...path,
            EditorStep._(index, FractionField.argument),
          ];
          write('(', EditorCursor._(path, index));
          write('Abs(', EditorCursor._(argumentPath, 0));
          _project(argument, argumentPath, output, cursors);
          write(')', EditorCursor._(argumentPath, argument.nodes.length));
          write(')', EditorCursor._(path, index + 1));
        case EditorFraction(:final numerator, :final denominator):
          final numeratorPath = [
            ...path,
            EditorStep._(index, FractionField.numerator),
          ];
          final denominatorPath = [
            ...path,
            EditorStep._(index, FractionField.denominator),
          ];
          final numeratorEnd = EditorCursor._(
            numeratorPath,
            numerator.nodes.length,
          );
          final denominatorEnd = EditorCursor._(
            denominatorPath,
            denominator.nodes.length,
          );
          write('((', EditorCursor._(numeratorPath, 0));
          _project(numerator, numeratorPath, output, cursors);
          write(')', numeratorEnd);
          // Evaluator division errors point to this generated operator. Landing
          // at the denominator end permits immediate DEL/edit of a zero value.
          write('/', denominatorEnd);
          write('(', EditorCursor._(denominatorPath, 0));
          _project(denominator, denominatorPath, output, cursors);
          write('))', denominatorEnd);
      }
    }
  }

  static int _count(EditorSequence sequence) => sequence.nodes.fold(
    0,
    (total, node) =>
        total +
        1 +
        switch (node) {
          EditorText() => 0,
          EditorFraction(:final numerator, :final denominator) =>
            _count(numerator) + _count(denominator),
          EditorAbsolute(:final argument) => _count(argument),
        },
  );

  static EditorSequence _replace(
    EditorSequence sequence,
    List<EditorStep> path,
    int depth,
    EditorSequence replacement,
  ) {
    if (depth == path.length) return replacement;
    final step = path[depth];
    final node = sequence.nodes[step.nodeIndex];
    final child = _replace(
      _child(node, step.field),
      path,
      depth + 1,
      replacement,
    );
    final nodes = sequence.nodes.toList();
    nodes[step.nodeIndex] = switch ((node, step.field)) {
      (EditorFraction(:final denominator), FractionField.numerator) =>
        EditorFraction._(child, denominator),
      (EditorFraction(:final numerator), FractionField.denominator) =>
        EditorFraction._(numerator, child),
      (EditorAbsolute(), FractionField.argument) => EditorAbsolute._(child),
      _ => throw ArgumentError('Field does not belong to this template'),
    };
    return EditorSequence._(nodes);
  }
}
