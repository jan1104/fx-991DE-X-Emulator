import 'package:calculator_core/calculator_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../application/key_layout.dart';
import '../../application/keyboard_mapping.dart';
import '../editor/fraction_expression_view.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final _session = CalculatorSession();
  final _structured = StructuredCalculatorSession();
  bool _fractions = false;
  final _focus = FocusNode(debugLabel: 'calculator input');

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _press(CalculatorKey key) => _pressId(key.id);

  void _pressId(String id) => setState(() {
    if (_fractions) {
      _structured.pressId(id);
    } else {
      _session.pressId(id);
    }
  });

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final keyboard = HardwareKeyboard.instance;
    final key = mapKeyboardEvent(
      event,
      modified:
          keyboard.isControlPressed ||
          keyboard.isMetaPressed ||
          keyboard.isAltPressed,
      includeRepeats: true,
    );
    if (key == null) return KeyEventResult.ignored;
    // A mapped repeat must not reach a focused button's default shortcut.
    if (event is KeyRepeatEvent) return KeyEventResult.handled;
    _press(key);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final keyHeight = ((constraints.maxHeight - 272) / 9).clamp(
              48.0,
              56.0,
            );
            return SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Wissenschaftlicher Rechner',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Text(
                              'Prototyp',
                              style: TextStyle(color: Color(0xFF526276)),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(
                              value: false,
                              label: Text(
                                'Linear',
                                key: ValueKey('input-linear'),
                              ),
                            ),
                            ButtonSegment(
                              value: true,
                              label: Text(
                                'Brüche',
                                key: ValueKey('input-fractions'),
                              ),
                            ),
                          ],
                          selected: {_fractions},
                          showSelectedIcon: false,
                          onSelectionChanged: (selection) => setState(() {
                            _fractions = selection.single;
                          }),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Jede Eingabeart behält ihre Rechnung und Ans.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF526276),
                          ),
                        ),
                      ),
                      _display(),
                      const SizedBox(height: 12),
                      ...calculatorRows.map(
                        (row) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: SizedBox(
                            height: keyHeight,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: row
                                  .map(
                                    (definition) => Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 2,
                                        ),
                                        child: _button(definition),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 12, bottom: 4),
                        child: Text(
                          'Grundrechnen verfügbar · weitere Funktionen folgen',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF526276),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );

  Widget _button(CalculatorButtonDefinition definition) {
    final key = CalculatorKey.fromId(definition.id);
    final enabled =
        key != null || (_fractions && definition.id == 'KEY_FRACTION');
    final primary = definition.id == 'KEY_EQUALS';
    final clear = definition.id == 'KEY_AC' || definition.id == 'KEY_DEL';
    return Tooltip(
      message: !enabled
          ? 'Noch nicht verfügbar'
          : definition.id == 'KEY_FRACTION'
          ? 'Bruch einfügen'
          : definition.label,
      child: FilledButton(
        key: ValueKey(definition.id),
        onPressed: enabled ? () => _pressId(definition.id) : null,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          minimumSize: Size.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: primary
              ? const Color(0xFF315F8A)
              : clear
              ? const Color(0xFF965131)
              : const Color(0xFF334457),
          textStyle: TextStyle(
            fontFamily: 'Roboto',
            fontSize: definition.label.length > 3 ? 11 : 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: switch (definition.id) {
            'KEY_LEFT' => const Icon(
              Icons.keyboard_arrow_left,
              semanticLabel: 'Links',
            ),
            'KEY_RIGHT' => const Icon(
              Icons.keyboard_arrow_right,
              semanticLabel: 'Rechts',
            ),
            'KEY_UP' => const Icon(
              Icons.keyboard_arrow_up,
              semanticLabel: 'Auf',
            ),
            'KEY_DOWN' => const Icon(
              Icons.keyboard_arrow_down,
              semanticLabel: 'Ab',
            ),
            'KEY_SD' => const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('S'),
                Icon(Icons.swap_horiz, size: 14),
                Text('D'),
              ],
            ),
            _ => Text(definition.label),
          },
        ),
      ),
    );
  }

  Widget _display() {
    final snapshot = _session.snapshot;
    final expression = snapshot.expression;
    final cursor = snapshot.cursorOffset;
    final structured = _structured.snapshot;
    final phase = _fractions ? structured.phase : snapshot.phase;
    final editing = phase == CalculatorPhase.editing;
    final answer = _fractions ? structured.answer : snapshot.answer;
    final value = _fractions ? structured.result : snapshot.result;
    final error = _fractions ? structured.error : snapshot.error;
    final result = phase == CalculatorPhase.error
        ? switch (error!.code) {
            CalculatorErrorCode.syntax => 'Syntaxfehler',
            CalculatorErrorCode.math => 'Mathem. Fehler',
            CalculatorErrorCode.unsupported => 'Noch nicht verfügbar',
            CalculatorErrorCode.limit => 'Eingabe zu umfangreich',
          }
        : value?.toString() ?? '';
    return Container(
      key: const ValueKey('calculator-display'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB6C2AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _fractions ? 'Berechnungen · Brüche' : 'Berechnungen · Linear',
            style: TextStyle(fontSize: 12, color: Color(0xFF56634D)),
          ),
          const SizedBox(height: 6),
          Text(
            'Ans: $answer',
            key: const ValueKey('display-answer'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF56634D)),
          ),
          const SizedBox(height: 12),
          if (_fractions)
            SizedBox(
              key: const ValueKey('display-structured'),
              height: 104,
              child: FractionExpressionView(
                snapshot: structured.editor,
                showCursor: editing,
                followCursor: true,
              ),
            )
          else
            Semantics(
              label: 'Eingabe',
              value: expression,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text.rich(
                  key: const ValueKey('display-expression'),
                  TextSpan(
                    children: [
                      TextSpan(text: expression.substring(0, cursor)),
                      if (editing)
                        const TextSpan(
                          text: '│',
                          style: TextStyle(color: Color(0xFF315F8A)),
                        ),
                      TextSpan(text: expression.substring(cursor)),
                    ],
                  ),
                  style: const TextStyle(
                    fontSize: 23,
                    color: Color(0xFF1E2D20),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Text(
              result,
              key: const ValueKey('display-result'),
              style: TextStyle(
                fontSize: phase == CalculatorPhase.error ? 21 : 32,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E2D20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
