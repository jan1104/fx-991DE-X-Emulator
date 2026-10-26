import 'dart:convert';
import 'dart:io';

import 'package:calculator_core/calculator_core.dart';
import 'package:test/test.dart';

void main() {
  test('G07 seed key sequence: linear projection and math error class only', () {
    // This replays the shared physical-key IDs. It deliberately does not claim
    // Math->Math setup, localized display, error cursor or complete UI coverage.
    final data = jsonDecode(
      File('../../tests/reference/scenarios/seed_cases.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    final cases = data['cases'] as List<dynamic>;
    final example = cases.cast<Map<String, dynamic>>().singleWhere(
      (entry) => entry['id'] == 'G07-key-division-zero',
    );
    expect(example['kind'], 'keys');
    final session = CalculatorSession();
    for (final step
        in (example['steps'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      session.pressId(step['press'] as String);
    }
    final expected = example['expected'] as Map<String, dynamic>;
    expect(expected['screen'], 'error');
    expect(
      (expected['error'] as Map<String, dynamic>)['category'],
      'math_error',
    );
    expect(session.snapshot.phase, CalculatorPhase.error);
    expect(session.snapshot.error?.code, CalculatorErrorCode.math);
    expect(session.snapshot.expression, '1/0');
  });
}
