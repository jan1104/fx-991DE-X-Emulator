import 'package:calculator_core/calculator_core.dart';
import 'package:test/test.dart';

Matcher errorCode(CalculatorErrorCode code) => throwsA(
  isA<CalculatorException>().having((error) => error.code, 'code', code),
);

void main() {
  group('exact expression evaluation', () {
    final cases = <String, String>{
      '2+3*4': '14',
      '(2+3)*4': '20',
      '8-3-2': '3',
      '8/2/2': '2',
      '2/3 + (1+1/2)': '13/6', // K03 mathematical equivalent, not key replay.
      '-2^2': '-4', // K02 precedence rule.
      '(-2)^2': '4',
      '2^3^2': '512',
      '2^-3': '1/8',
      '(-2)^-3': '-1/8',
      '0,1+0,2': '3/10',
      '.5+1.': '3/2',
      '1.25e-2 + 0.0075': '1/50',
      '9007199254740993+1': '9007199254740994',
      '2(3+4)': '14',
      '(2+1)(4-2)': '6',
      '6/2(1+2)': '1', // Restricted implicit product binds before explicit /.
      '6/2*(1+2)': '9',
      '1−2×3÷2': '-2',
      '+2 + -3': '-1',
    };
    for (final entry in cases.entries) {
      test(
        entry.key,
        () => expect(evaluate(entry.key).toString(), entry.value),
      );
    }
  });
  group('structured failures', () {
    for (final input in [
      '',
      ' ',
      '1+',
      '()',
      '(1+2',
      '1+2)',
      '2 3',
      '1,2.3',
      '1e',
      '2**3',
    ]) {
      test(
        'syntax: $input',
        () => expect(
          () => evaluate(input),
          errorCode(CalculatorErrorCode.syntax),
        ),
      );
    }
    for (final input in ['1/0', '1/(2-2)', '0^-1']) {
      test(
        'math: $input',
        () =>
            expect(() => evaluate(input), errorCode(CalculatorErrorCode.math)),
      );
    }
    for (final input in ['sin(30)', '2^(1/2)', '0^0', '√5']) {
      test(
        'unsupported: $input',
        () => expect(
          () => evaluate(input),
          errorCode(CalculatorErrorCode.unsupported),
        ),
      );
    }
    final limitedInputs = [
      '2^1001',
      '1e1001',
      '${'(' * 65}1${')' * 65}',
      '1' * 2049,
      '(1e1000)^1000',
    ];
    for (final (index, input) in limitedInputs.indexed) {
      test(
        'resource limit $index',
        () =>
            expect(() => evaluate(input), errorCode(CalculatorErrorCode.limit)),
      );
    }
    test('error position identifies division operator', () {
      expect(
        () => evaluate('12/(3-3)'),
        throwsA(
          isA<CalculatorException>().having(
            (error) => error.position,
            'position',
            2,
          ),
        ),
      );
    });
  });
  test('parser keeps structure and evaluation is separate', () {
    final expression = parseExpression('2+3*4');
    expect(expression, isA<BinaryExpression>());
    expect(evaluateExpression(expression), Rational.fromInt(14));
  });
  test('shared AST cannot evade total evaluation work budget', () {
    Expression expression = NumberExpression(Rational.fromInt(0), 0);
    for (var i = 0; i < 50; i++) {
      expression = BinaryExpression(
        BinaryOperator.add,
        expression,
        expression,
        0,
      );
    }
    expect(
      () => evaluateExpression(expression),
      errorCode(CalculatorErrorCode.limit),
    );
    // The budget belongs to one evaluation, not to the process or expression.
    expect(evaluate('2+3'), Rational.fromInt(5));
  });
  group('explicit answer context', () {
    test('requires a caller-supplied answer instead of a hidden global', () {
      expect(
        () => evaluate('Ans+1'),
        errorCode(CalculatorErrorCode.unsupported),
      );
      expect(
        evaluate('Ans+1', answer: Rational.fromInt(4)),
        Rational.fromInt(5),
      );
    });
    test('negative rational Ans remains a single structured operand', () {
      final answer = Rational(BigInt.from(-1), BigInt.from(2));
      expect(
        evaluate('Ans^2', answer: answer),
        Rational(BigInt.one, BigInt.from(4)),
      );
      expect(evaluate('2/Ans', answer: answer), Rational.fromInt(-4));
    });
    test(
      'error positions refer to visible Ans text, not substituted digits',
      () {
        expect(
          () => evaluate('Ans/0', answer: Rational.fromInt(12345)),
          throwsA(
            isA<CalculatorException>().having(
              (error) => error.position,
              'position',
              3,
            ),
          ),
        );
      },
    );
  });
}
