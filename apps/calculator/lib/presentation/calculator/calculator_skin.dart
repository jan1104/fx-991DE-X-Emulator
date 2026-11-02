import 'package:flutter/material.dart';

import '../../application/key_layout.dart';

/// Drawn entirely with widgets; no device photograph or logo artwork is used.
class CalculatorShell extends StatelessWidget {
  const CalculatorShell({
    required this.display,
    required this.keyboard,
    super.key,
  });

  final Widget display;
  final Widget keyboard;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: const ValueKey('calculator-shell'),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(32),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE1E3E4), Color(0xFF858B90), Color(0xFFE0E2E4)],
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF303235), Color(0xFF17191C)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 18, 8, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _DeviceHeader(),
              const SizedBox(height: 16),
              display,
              const SizedBox(height: 18),
              keyboard,
            ],
          ),
        ),
      ),
    ),
  );
}

class _DeviceHeader extends StatelessWidget {
  const _DeviceHeader();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CASIO',
              style: TextStyle(
                color: Color(0xFFF3F3F3),
                fontSize: 21,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'fx-991DE X',
              style: TextStyle(
                color: Color(0xFFD5D8DB),
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
            Text(
              'EMULATOR',
              style: TextStyle(
                color: Color(0xFFC25C7E),
                fontSize: 10,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
      ExcludeSemantics(
        child: Container(
          key: const ValueKey('solar-panel'),
          width: 126,
          height: 52,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF111214),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF525457)),
          ),
          child: Row(
            children: List.generate(
              4,
              (_) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  color: const Color(0xFF3B2E2F),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

const _shiftLabels = <String, String>{
  'KEY_MENU': 'SETUP',
  'KEY_OPTN': 'QR',
  'KEY_CALC': 'SOLVE',
  'KEY_INTEGRAL': 'd/dx',
  'KEY_X': 'Σ',
  'KEY_FRACTION': '▯ ▯/▯',
  'KEY_SQRT': '∛',
  'KEY_SQUARE': 'x³',
  'KEY_POWER': 'ⁿ√',
  'KEY_LOG_BASE': '10ˣ',
  'KEY_LN': 'eˣ',
  'KEY_NEGATE': 'log',
  'KEY_DMS': 'FACT',
  'KEY_RECIPROCAL': 'x!',
  'KEY_SIN': 'sin⁻¹',
  'KEY_COS': 'cos⁻¹',
  'KEY_TAN': 'tan⁻¹',
  'KEY_STO': 'RECALL',
  'KEY_ENG': '←',
  'KEY_LPAREN': 'Abs',
  'KEY_RPAREN': ';',
  'KEY_SD': 'a b/c ⇔ d/c',
  'KEY_M_PLUS': 'M−',
  'KEY_7': 'CONST',
  'KEY_8': 'CONV',
  'KEY_9': 'RESET',
  'KEY_DEL': 'INS',
  'KEY_AC': 'OFF',
  'KEY_MULTIPLY': 'nPr',
  'KEY_DIVIDE': 'nCr',
  'KEY_ADD': 'Pol',
  'KEY_SUBTRACT': 'Rec',
  'KEY_0': 'Rnd',
  'KEY_DECIMAL': 'Ran#',
  'KEY_EXP10': 'π',
  'KEY_ANS': '%',
  'KEY_EQUALS': '≈',
};

const _alphaLabels = <String, String>{
  'KEY_CALC': '=',
  'KEY_INTEGRAL': ':',
  'KEY_X': 'Π',
  'KEY_FRACTION': '÷R',
  'KEY_SQRT': '‾',
  'KEY_NEGATE': 'A',
  'KEY_DMS': 'B',
  'KEY_RECIPROCAL': 'C',
  'KEY_SIN': 'D',
  'KEY_COS': 'E',
  'KEY_TAN': 'F',
  'KEY_RPAREN': 'x',
  'KEY_SD': 'y',
  'KEY_M_PLUS': 'M',
  'KEY_DEL': 'UNDO',
  'KEY_MULTIPLY': 'GCD',
  'KEY_DIVIDE': 'LCM',
  'KEY_ADD': 'Int',
  'KEY_SUBTRACT': 'Intg',
  'KEY_0': 'RndFix',
  'KEY_DECIMAL': 'RanInt',
  'KEY_EXP10': 'e',
};

class CalculatorKeyboard extends StatelessWidget {
  const CalculatorKeyboard({
    required this.enabled,
    required this.onPressed,
    this.shift = false,
    this.alpha = false,
    super.key,
  });

  final bool Function(String id) enabled;
  final ValueChanged<String> onPressed;
  final bool shift;
  final bool alpha;

  CalculatorButtonDefinition _definition(String id) => calculatorRows
      .expand((row) => row)
      .firstWhere((definition) => definition.id == id);

  Widget _key(String id, {bool round = false}) => _DeviceKey(
    definition: _definition(id),
    enabled: enabled(id),
    onPressed: () => onPressed(id),
    round: round,
    latched: id == 'KEY_SHIFT' && shift || id == 'KEY_ALPHA' && alpha,
  );

  Widget _side(List<String> top, List<String> bottom) => Expanded(
    child: SizedBox(
      height: 150,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              for (final id in top)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _key(id, round: true),
                  ),
                ),
            ],
          ),
          Row(
            children: [
              for (final id in bottom)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _key(id),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _side(['KEY_SHIFT', 'KEY_ALPHA'], ['KEY_OPTN', 'KEY_CALC']),
          const SizedBox(width: 2),
          SizedBox(
            key: const ValueKey('direction-pad'),
            width: 88,
            height: 150,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(46),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF53585C),
                    Color(0xFF181A1C),
                    Color(0xFF757B7E),
                  ],
                ),
                border: Border.all(color: const Color(0xFF7F8587)),
              ),
              child: Column(
                children: [
                  SizedBox(width: 44, height: 44, child: _arrow('KEY_UP')),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: _arrow('KEY_LEFT'),
                      ),
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: _arrow('KEY_RIGHT'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  SizedBox(width: 44, height: 44, child: _arrow('KEY_DOWN')),
                ],
              ),
            ),
          ),
          const SizedBox(width: 2),
          _side(['KEY_MENU', 'KEY_ON'], ['KEY_INTEGRAL', 'KEY_X']),
        ],
      ),
      const SizedBox(height: 8),
      for (final row in calculatorRows.skip(2))
        Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Row(
            children: [
              for (final definition in row)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _key(definition.id),
                  ),
                ),
            ],
          ),
        ),
    ],
  );

  Widget _arrow(String id) => _DeviceKey(
    definition: _definition(id),
    enabled: enabled(id),
    onPressed: () => onPressed(id),
    arrow: true,
    round: true,
  );
}

class _DeviceKey extends StatelessWidget {
  const _DeviceKey({
    required this.definition,
    required this.enabled,
    required this.onPressed,
    this.round = false,
    this.arrow = false,
    this.latched = false,
  });

  final CalculatorButtonDefinition definition;
  final bool enabled;
  final VoidCallback onPressed;
  final bool round;
  final bool arrow;
  final bool latched;

  @override
  Widget build(BuildContext context) {
    final id = definition.id;
    final numeric =
        RegExp(r'^KEY_[0-9]$').hasMatch(id) ||
        const {
          'KEY_MULTIPLY',
          'KEY_DIVIDE',
          'KEY_ADD',
          'KEY_SUBTRACT',
          'KEY_DECIMAL',
          'KEY_EXP10',
          'KEY_ANS',
          'KEY_EQUALS',
        }.contains(id);
    final blue = id == 'KEY_DEL' || id == 'KEY_AC';
    final foreground = numeric ? const Color(0xFF161B21) : Colors.white;
    final background = blue
        ? const Color(0xFF254E94)
        : numeric
        ? const Color(0xFFE9E9E7)
        : round
        ? const Color(0xFF51565A)
        : const Color(0xFF34373A);
    final button = Tooltip(
      message: enabled
          ? (id == 'KEY_FRACTION' ? 'Bruch einfügen' : definition.label)
          : '${definition.label} · Noch nicht verfügbar',
      child: FilledButton(
        key: ValueKey(id),
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 44),
          fixedSize: const Size.fromHeight(44),
          padding: const EdgeInsets.symmetric(horizontal: 1),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: latched ? const Color(0xFF797044) : background,
          foregroundColor: foreground,
          disabledBackgroundColor: background.withValues(alpha: .75),
          disabledForegroundColor: foreground.withValues(alpha: .45),
          side: BorderSide(
            color: latched ? const Color(0xFFE8CC76) : const Color(0xFF73777A),
            width: latched ? 2 : .7,
          ),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(round ? 24 : 7),
          ),
          textStyle: TextStyle(
            fontFamily: 'Roboto',
            fontSize: numeric ? 24 : 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: FittedBox(fit: BoxFit.scaleDown, child: _label(id)),
      ),
    );
    if (arrow) return button;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 18,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  id == 'KEY_SHIFT' ? 'SHIFT' : _shiftLabels[id] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: const TextStyle(fontSize: 9, color: Color(0xFFE0C97C)),
                ),
              ),
              if (_alphaLabels.containsKey(id) || id == 'KEY_ALPHA')
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Text(
                      id == 'KEY_ALPHA' ? 'ALPHA' : _alphaLabels[id]!,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFFE66E9A),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 44, width: double.infinity, child: button),
      ],
    );
  }

  Widget _label(String id) => switch (id) {
    'KEY_UP' => const Icon(Icons.keyboard_arrow_up, semanticLabel: 'Auf'),
    'KEY_DOWN' => const Icon(Icons.keyboard_arrow_down, semanticLabel: 'Ab'),
    'KEY_LEFT' => const Icon(Icons.keyboard_arrow_left, semanticLabel: 'Links'),
    'KEY_RIGHT' => const Icon(
      Icons.keyboard_arrow_right,
      semanticLabel: 'Rechts',
    ),
    'KEY_SHIFT' || 'KEY_ALPHA' => const SizedBox(width: 20, height: 20),
    _ => Text(definition.label),
  };
}
