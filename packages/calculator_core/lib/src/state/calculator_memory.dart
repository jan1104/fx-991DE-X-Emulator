import '../errors.dart';
import '../evaluation/evaluator.dart';
import '../numbers/rational.dart';

/// Result handling, independent of physical keys and editor state.
enum MemoryOperation { result, add, subtract, store }

/// An immutable view of Ans, independent memory M and variable A.
final class CalculatorMemorySnapshot {
  const CalculatorMemorySnapshot._(this.answer, this.memory, this.variableA);

  final Rational answer;
  final Rational memory;
  final Rational variableA;

  bool get hasMemory => memory.numerator != BigInt.zero;
}

/// Exact memory transactions for one calculator, with no persistence or UI.
///
/// An adapter shares one instance between its Math and Linear editors, and
/// must not call
/// [clearMemory] for AC, a display-format change or setup-only initialization.
final class CalculatorMemory {
  CalculatorMemory()
    : _snapshot = CalculatorMemorySnapshot._(
        Rational.fromInt(0),
        Rational.fromInt(0),
        Rational.fromInt(0),
      );

  CalculatorMemorySnapshot _snapshot;

  CalculatorMemorySnapshot get snapshot => _snapshot;

  /// Evaluates with the previous exact Ans/M/A and commits only on full success.
  /// The returned result is the operand, not the new M total.
  Rational calculate(
    String source, {
    MemoryOperation operation = MemoryOperation.result,
  }) => acceptResult(
    evaluate(
      source,
      answer: _snapshot.answer,
      memoryValue: _snapshot.memory,
      variableA: _snapshot.variableA,
    ),
    operation: operation,
  );

  /// Commits an already evaluated result, e.g. from a structured editor.
  ///
  /// Both the operand and prospective M must fit the same application size
  /// budget as the evaluator. Failure leaves the entire snapshot untouched.
  Rational acceptResult(
    Rational value, {
    MemoryOperation operation = MemoryOperation.result,
  }) {
    _checkSize(value);
    final memory = switch (operation) {
      MemoryOperation.result => _snapshot.memory,
      MemoryOperation.add => _snapshot.memory + value,
      MemoryOperation.subtract => _snapshot.memory - value,
      MemoryOperation.store => value,
    };
    _checkSize(memory);
    _snapshot = CalculatorMemorySnapshot._(value, memory, _snapshot.variableA);
    return value;
  }

  /// Assigns an already evaluated value to A without changing Ans or M.
  /// UI adapters choose when to evaluate an expression and update Ans.
  void storeVariableA(Rational value) {
    _checkSize(value);
    _snapshot = CalculatorMemorySnapshot._(
      _snapshot.answer,
      _snapshot.memory,
      value,
    );
  }

  /// Clears Ans, M and A without touching any editor or setup state.
  void clearMemory() {
    _snapshot = CalculatorMemorySnapshot._(
      Rational.fromInt(0),
      Rational.fromInt(0),
      Rational.fromInt(0),
    );
  }

  static void _checkSize(Rational value) {
    if (value.numerator.bitLength + value.denominator.bitLength > 100000) {
      throw const CalculatorException(
        CalculatorErrorCode.limit,
        'Memory transaction exceeds size budget',
      );
    }
  }
}
