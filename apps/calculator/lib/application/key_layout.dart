/// Visual keyboard inventory; support is resolved through the core registry.
final class CalculatorButtonDefinition {
  final String id;
  final String label;
  const CalculatorButtonDefinition(this.id, this.label);
}

const calculatorRows = <List<CalculatorButtonDefinition>>[
  [
    CalculatorButtonDefinition('KEY_SHIFT', 'SHIFT'),
    CalculatorButtonDefinition('KEY_ALPHA', 'ALPHA'),
    CalculatorButtonDefinition('KEY_LEFT', '◀'),
    CalculatorButtonDefinition('KEY_UP', '▲'),
    CalculatorButtonDefinition('KEY_MENU', 'MENU'),
    CalculatorButtonDefinition('KEY_ON', 'ON'),
  ],
  [
    CalculatorButtonDefinition('KEY_OPTN', 'OPTN'),
    CalculatorButtonDefinition('KEY_CALC', 'CALC'),
    CalculatorButtonDefinition('KEY_DOWN', '▼'),
    CalculatorButtonDefinition('KEY_RIGHT', '▶'),
    CalculatorButtonDefinition('KEY_INTEGRAL', '∫'),
    CalculatorButtonDefinition('KEY_X', 'x'),
  ],
  [
    CalculatorButtonDefinition('KEY_FRACTION', '□/□'),
    CalculatorButtonDefinition('KEY_SQRT', '√'),
    CalculatorButtonDefinition('KEY_SQUARE', 'x²'),
    CalculatorButtonDefinition('KEY_POWER', 'x^□'),
    CalculatorButtonDefinition('KEY_LOG_BASE', 'log'),
    CalculatorButtonDefinition('KEY_LN', 'ln'),
  ],
  [
    CalculatorButtonDefinition('KEY_NEGATE', '(−)'),
    CalculatorButtonDefinition('KEY_DMS', '°′″'),
    CalculatorButtonDefinition('KEY_RECIPROCAL', 'x⁻¹'),
    CalculatorButtonDefinition('KEY_SIN', 'sin'),
    CalculatorButtonDefinition('KEY_COS', 'cos'),
    CalculatorButtonDefinition('KEY_TAN', 'tan'),
  ],
  [
    CalculatorButtonDefinition('KEY_STO', 'STO'),
    CalculatorButtonDefinition('KEY_ENG', 'ENG'),
    CalculatorButtonDefinition('KEY_LPAREN', '('),
    CalculatorButtonDefinition('KEY_RPAREN', ')'),
    CalculatorButtonDefinition('KEY_SD', 'S⇔D'),
    CalculatorButtonDefinition('KEY_M_PLUS', 'M+'),
  ],
  [
    CalculatorButtonDefinition('KEY_7', '7'),
    CalculatorButtonDefinition('KEY_8', '8'),
    CalculatorButtonDefinition('KEY_9', '9'),
    CalculatorButtonDefinition('KEY_DEL', 'DEL'),
    CalculatorButtonDefinition('KEY_AC', 'AC'),
  ],
  [
    CalculatorButtonDefinition('KEY_4', '4'),
    CalculatorButtonDefinition('KEY_5', '5'),
    CalculatorButtonDefinition('KEY_6', '6'),
    CalculatorButtonDefinition('KEY_MULTIPLY', '×'),
    CalculatorButtonDefinition('KEY_DIVIDE', '÷'),
  ],
  [
    CalculatorButtonDefinition('KEY_1', '1'),
    CalculatorButtonDefinition('KEY_2', '2'),
    CalculatorButtonDefinition('KEY_3', '3'),
    CalculatorButtonDefinition('KEY_ADD', '+'),
    CalculatorButtonDefinition('KEY_SUBTRACT', '−'),
  ],
  [
    CalculatorButtonDefinition('KEY_0', '0'),
    CalculatorButtonDefinition('KEY_DECIMAL', ','),
    CalculatorButtonDefinition('KEY_EXP10', '×10ˣ'),
    CalculatorButtonDefinition('KEY_ANS', 'Ans'),
    CalculatorButtonDefinition('KEY_EQUALS', '='),
  ],
];
