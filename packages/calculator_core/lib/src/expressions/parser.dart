import '../errors.dart';
import '../numbers/rational.dart';
import 'expression.dart';

/// Parses the prototype's limited linear grammar, without executing code.
Expression parseExpression(
  String source, {
  Rational? answer,
  Rational? memoryValue,
}) => _Parser(source, answer, memoryValue).parse();

enum _Kind {
  number,
  answer,
  memory,
  absolute,
  plus,
  minus,
  times,
  divide,
  power,
  square,
  reciprocal,
  cube,
  percent,
  factorial,
  permutation,
  combination,
  left,
  right,
  end,
}

final class _Token {
  final _Kind kind;
  final String text;
  final int position;
  const _Token(this.kind, this.text, this.position);
}

final class _Parser {
  final String source;
  final Rational? answer;
  final Rational? memoryValue;
  final List<_Token> tokens = [];
  int cursor = 0;
  int depth = 0;
  static final _number = RegExp(
    r'(?:[0-9]+(?:[.,][0-9]*)?|[.,][0-9]+)(?:[eE][+-]?[0-9]+)?',
  );
  static final _space = RegExp(r'\s');
  _Parser(this.source, this.answer, this.memoryValue);

  CalculatorException _syntax(String message, int position) =>
      CalculatorException(
        CalculatorErrorCode.syntax,
        message,
        position: position,
      );

  Expression parse() {
    if (source.length > 2048) {
      throw const CalculatorException(
        CalculatorErrorCode.limit,
        'Input too long',
      );
    }
    _tokenize();
    final result = _sum();
    if (_current.kind != _Kind.end) {
      throw _syntax('Unexpected token', _current.position);
    }
    return result;
  }

  void _tokenize() {
    var position = 0;
    while (position < source.length) {
      final char = source[position];
      if (_space.hasMatch(char)) {
        position++;
        continue;
      }
      if (tokens.length >= 512) {
        throw CalculatorException(
          CalculatorErrorCode.limit,
          'Too many tokens',
          position: position,
        );
      }
      if (source.startsWith('nPr', position) ||
          source.startsWith('nCr', position)) {
        final text = source.substring(position, position + 3);
        tokens.add(
          _Token(
            text == 'nPr' ? _Kind.permutation : _Kind.combination,
            text,
            position,
          ),
        );
        position += 3;
        continue;
      }
      if (source.startsWith('Abs', position)) {
        tokens.add(_Token(_Kind.absolute, 'Abs', position));
        position += 3;
        continue;
      }
      if (source.startsWith('Ans', position)) {
        tokens.add(_Token(_Kind.answer, 'Ans', position));
        position += 3;
        continue;
      }
      // One postfix token spans two UTF-16 code units. Neither superscript
      // character is accepted on its own or merged with the following token.
      if (source.startsWith('⁻¹', position)) {
        tokens.add(_Token(_Kind.reciprocal, '⁻¹', position));
        position += 2;
        continue;
      }
      final match = _number.matchAsPrefix(source, position);
      if (match != null) {
        final text = match.group(0)!;
        tokens.add(_Token(_Kind.number, text, position));
        position += text.length;
        if (position < source.length &&
            (source[position] == 'e' || source[position] == 'E')) {
          throw _syntax('Incomplete decimal exponent', position);
        }
        continue;
      }
      final kind = switch (char) {
        'M' => _Kind.memory,
        '+' => _Kind.plus,
        '-' || '−' => _Kind.minus,
        '*' || '×' => _Kind.times,
        '/' || '÷' => _Kind.divide,
        '^' => _Kind.power,
        '²' => _Kind.square,
        '³' => _Kind.cube,
        '%' => _Kind.percent,
        '!' => _Kind.factorial,
        '(' => _Kind.left,
        ')' => _Kind.right,
        _ => null,
      };
      if (kind == null) {
        final unsupported = RegExp(r'[A-Za-z√]').hasMatch(char);
        throw CalculatorException(
          unsupported
              ? CalculatorErrorCode.unsupported
              : CalculatorErrorCode.syntax,
          unsupported ? 'Feature not implemented' : 'Invalid character',
          position: position,
        );
      }
      tokens.add(_Token(kind, char, position));
      position++;
    }
    tokens.add(_Token(_Kind.end, '', source.length));
  }

  _Token get _current => tokens[cursor];
  _Token _take() => tokens[cursor++];

  Expression _sum() {
    var result = _product();
    while (_current.kind == _Kind.plus || _current.kind == _Kind.minus) {
      final token = _take();
      result = BinaryExpression(
        token.kind == _Kind.plus ? BinaryOperator.add : BinaryOperator.subtract,
        result,
        _product(),
        token.position,
      );
    }
    return result;
  }

  Expression _product() {
    var result = _combinatorics();
    while (_current.kind == _Kind.times || _current.kind == _Kind.divide) {
      final token = _take();
      result = BinaryExpression(
        token.kind == _Kind.times
            ? BinaryOperator.multiply
            : BinaryOperator.divide,
        result,
        _combinatorics(),
        token.position,
      );
    }
    return result;
  }

  // nPr/nCr bind below implicit multiplication and above explicit products.
  // Both binary operations associate from left to right.
  Expression _combinatorics() {
    var result = _implicitProduct();
    while (_current.kind == _Kind.permutation ||
        _current.kind == _Kind.combination) {
      final token = _take();
      result = BinaryExpression(
        token.kind == _Kind.permutation
            ? BinaryOperator.permutation
            : BinaryOperator.combination,
        result,
        _implicitProduct(),
        token.position,
      );
    }
    return result;
  }

  // Restricted implicit multiplication binds more strongly than explicit / or *.
  // At this stage only an opening parenthesis can introduce the implicit factor.
  Expression _implicitProduct() {
    var result = _unary();
    while (_current.kind == _Kind.left) {
      final position = _current.position;
      result = BinaryExpression(
        BinaryOperator.multiply,
        result,
        _unary(),
        position,
      );
    }
    return result;
  }

  Expression _unary() {
    depth++;
    if (depth > 64) {
      throw CalculatorException(
        CalculatorErrorCode.limit,
        'Expression too deeply nested',
        position: _current.position,
      );
    }
    try {
      if (_current.kind == _Kind.plus || _current.kind == _Kind.minus) {
        final token = _take();
        return UnaryExpression(
          token.kind == _Kind.plus ? UnaryOperator.plus : UnaryOperator.negate,
          _unary(),
          token.position,
        );
      }
      var result = _primary();
      // Postfix actions compose from left to right, before ordinary ^.
      // They are not textual rewrites, which would change repeated-key binding.
      while (_current.kind == _Kind.square ||
          _current.kind == _Kind.reciprocal ||
          _current.kind == _Kind.cube ||
          _current.kind == _Kind.percent ||
          _current.kind == _Kind.factorial) {
        final token = _take();
        if (token.kind == _Kind.factorial) {
          result = UnaryExpression(
            UnaryOperator.factorial,
            result,
            token.position,
          );
          continue;
        }
        result = BinaryExpression(
          token.kind == _Kind.percent
              ? BinaryOperator.divide
              : BinaryOperator.power,
          result,
          NumberExpression(
            Rational.fromInt(switch (token.kind) {
              _Kind.square => 2,
              _Kind.cube => 3,
              _Kind.percent => 100,
              _ => -1,
            }),
            token.position,
          ),
          token.position,
        );
      }
      if (_current.kind == _Kind.power) {
        final token = _take();
        return BinaryExpression(
          BinaryOperator.power,
          result,
          _unary(),
          token.position,
        );
      }
      return result;
    } finally {
      depth--;
    }
  }

  Expression _primary() {
    final token = _current;
    if (token.kind == _Kind.absolute) {
      _take();
      if (_current.kind != _Kind.left) {
        throw _syntax('Abs requires an opening parenthesis', _current.position);
      }
      _take();
      final operand = _sum();
      if (_current.kind != _Kind.right) {
        throw _syntax('Missing closing parenthesis', _current.position);
      }
      _take();
      return UnaryExpression(UnaryOperator.absolute, operand, token.position);
    }
    if (token.kind == _Kind.answer) {
      if (answer == null) {
        throw CalculatorException(
          CalculatorErrorCode.unsupported,
          'Ans requires an explicit answer context',
          position: token.position,
        );
      }
      _take();
      return NumberExpression(answer!, token.position);
    }
    if (token.kind == _Kind.memory) {
      if (memoryValue == null) {
        throw CalculatorException(
          CalculatorErrorCode.unsupported,
          'M requires an explicit memory context',
          position: token.position,
        );
      }
      _take();
      return NumberExpression(memoryValue!, token.position);
    }
    if (token.kind == _Kind.number) {
      _take();
      try {
        return NumberExpression(
          Rational.parseDecimal(token.text),
          token.position,
        );
      } on RangeError {
        throw CalculatorException(
          CalculatorErrorCode.limit,
          'Numeric literal too large',
          position: token.position,
        );
      } on FormatException {
        throw _syntax('Invalid number', token.position);
      }
    }
    if (token.kind == _Kind.left) {
      _take();
      final result = _sum();
      if (_current.kind != _Kind.right) {
        throw _syntax('Missing closing parenthesis', _current.position);
      }
      _take();
      return result;
    }
    throw _syntax('Expected a number or parenthesis', token.position);
  }
}
