import 'package:calculator_core/calculator_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../application/calculator_controller.dart';
import '../../application/keyboard_mapping.dart';
import '../editor/fraction_expression_view.dart';
import 'calculator_skin.dart';
import 'recurring_result_view.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final _controller = CalculatorController();
  final _focus = FocusNode(debugLabel: 'calculator input');
  final _pageScroll = ScrollController();

  @override
  void dispose() {
    _focus.dispose();
    _pageScroll.dispose();
    super.dispose();
  }

  void _revealDisplay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageScroll.hasClients) return;
      _pageScroll.animateTo(
        0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  void _openSetup() {
    setState(_controller.openSetup);
    _revealDisplay();
  }

  void _pressId(String id) {
    final menuWasOpen = _controller.menuOpen;
    final recallWasOpen = _controller.recallOpen;
    final storeWasPending = _controller.storePending;
    final recallWasSelected = _controller.recallSelected;
    setState(() => _controller.pressId(id));
    if ((!menuWasOpen && _controller.menuOpen) ||
        recallWasOpen != _controller.recallOpen ||
        storeWasPending != _controller.storePending ||
        recallWasSelected != _controller.recallSelected) {
      _revealDisplay();
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final keyboard = HardwareKeyboard.instance;
    final modified =
        keyboard.isControlPressed ||
        keyboard.isMetaPressed ||
        keyboard.isAltPressed;
    final navigation = (_controller.fractions || _controller.menuOpen)
        ? mapStructuredNavigation(
            event,
            modified: modified,
            includeRepeats: true,
          )
        : null;
    if (navigation != null) {
      if (event is! KeyRepeatEvent) _pressId(navigation);
      return KeyEventResult.handled;
    }
    final key = mapKeyboardEvent(
      event,
      modified: modified,
      includeRepeats: true,
    );
    if (key == null) return KeyEventResult.ignored;
    if (event is! KeyRepeatEvent) _pressId(key.id);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: _focus,
    autofocus: true,
    onKeyEvent: _onKey,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('FX991 Emulator', style: TextStyle(fontSize: 18)),
        actions: [
          IconButton(
            key: const ValueKey('toolbar-settings'),
            tooltip: 'Einstellungen · SHIFT MENU',
            onPressed: _openSetup,
            icon: const Icon(Icons.tune),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _pageScroll,
          key: const ValueKey('calculator-page-scroll'),
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CalculatorShell(
                    display: _display(),
                    keyboard: CalculatorKeyboard(
                      enabled: _controller.isKeyEnabled,
                      onPressed: _pressId,
                      shift: _controller.shift,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: false,
                          label: Text('Linear', key: ValueKey('input-linear')),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text(
                            'Brüche',
                            key: ValueKey('input-fractions'),
                          ),
                        ),
                      ],
                      selected: {_controller.fractions},
                      showSelectedIcon: false,
                      onSelectionChanged:
                          _controller.menuOpen || !_controller.poweredOn
                          ? null
                          : (selection) => setState(() {
                              final decimal =
                                  _controller.settings.decimalOutput;
                              _controller.selectInputOutput(
                                selection.single
                                    ? decimal
                                          ? CalculatorInputOutput.mathDecimal
                                          : CalculatorInputOutput.mathMath
                                    : decimal
                                    ? CalculatorInputOutput.linearDecimal
                                    : CalculatorInputOutput.linearLinear,
                              );
                            }),
                    ),
                  ),
                  if (_controller.fractions) _fractionTool(),
                  const Padding(
                    padding: EdgeInsets.only(top: 14),
                    child: Text(
                      'Eigenständiger Emulator · in Entwicklung',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Color(0xFF667078)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _fractionTool() {
    final snapshot = _controller.structured.snapshot;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Tooltip(
            message: 'Zahl, Ans, Bruch, Betrag oder Klammergruppe links vom Cursor übernehmen',
            child: TextButton.icon(
              key: const ValueKey('action-wrap-fraction'),
              onPressed:
                  !_controller.menuOpen &&
                      !_controller.recallOpen &&
                      !_controller.storePending &&
                      _controller.poweredOn &&
                      snapshot.phase == CalculatorPhase.editing &&
                      snapshot.editor.cursor.offset > 0
                  ? () => _pressId('ACTION_WRAP_FRACTION')
                  : null,
              icon: const Icon(Icons.wrap_text),
              label: const Text('Als Zähler'),
            ),
          ),
          const Text(
            'Zahl, Ans, Bruch, Betrag oder Klammergruppe links vom Cursor übernehmen.',
            style: TextStyle(fontSize: 11, color: Color(0xFF667078)),
          ),
        ],
      ),
    );
  }

  Widget _display() {
    final snapshot = _controller.session.snapshot;
    final structured = _controller.structured.snapshot;
    final fractions = _controller.fractions;
    final phase = fractions ? structured.phase : snapshot.phase;
    final editing = phase == CalculatorPhase.editing;
    final error = fractions ? structured.error : snapshot.error;
    final answer = fractions ? structured.answer : snapshot.answer;
    final expression = snapshot.expression;
    final cursor = snapshot.cursorOffset;
    final contrast = _controller.settings.contrast;
    final ink = Color.lerp(
      const Color(0xFF52634B),
      const Color(0xFF132116),
      contrast / 10,
    )!;
    final fontSize = _controller.settings.smallText ? 19.0 : 23.0;
    var resultText = '';
    CalculatorResultPresentation? presentation;
    String? outputError;
    if (!_controller.menuOpen &&
        !_controller.recallOpen &&
        _controller.poweredOn) {
      try {
        if (phase == CalculatorPhase.error) {
          resultText = switch (error!.code) {
            CalculatorErrorCode.syntax => 'Syntaxfehler',
            CalculatorErrorCode.math => 'Mathem. Fehler',
            CalculatorErrorCode.unsupported => 'Noch nicht verfügbar',
            CalculatorErrorCode.limit => 'Eingabe zu umfangreich',
          };
        } else {
          presentation = _controller.resultPresentation;
          resultText = presentation.text;
        }
      } on CalculatorException {
        outputError = 'Ergebnisanzeige zu umfangreich';
      }
    }
    final expansion = presentation?.expansion;
    final periodPrefix = presentation?.periodPrefix;
    final resultStyle = TextStyle(
      fontSize: phase == CalculatorPhase.error ? 18 : 30,
      fontWeight: FontWeight.w600,
      color: ink,
    );
    return Container(
      key: const ValueKey('calculator-display'),
      constraints: const BoxConstraints(minHeight: 204),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFCCDCC5),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFF0A0D0B), width: 5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x88000000),
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: !_controller.poweredOn
          ? const SizedBox(height: 174)
          : DefaultTextStyle(
              style: TextStyle(
                color: ink,
                fontFamily: 'monospace',
                fontSize: 14,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _controller.displayStatus,
                    key: const ValueKey('display-status'),
                    semanticsLabel: _controller.memory.snapshot.hasMemory
                        ? '${_controller.displayStatus}, Unabhängiger Speicher M belegt'
                        : _controller.displayStatus,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  if (_controller.menuOpen)
                    _menu()
                  else if (_controller.recallOpen)
                    _recallOverview(ink)
                  else ...[
                    if (_controller.storePending)
                      Semantics(
                        liveRegion: true,
                        child: const Text(
                          'M+ speichert · AC bricht ab',
                          key: ValueKey('display-store-prompt'),
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    if (_controller.notice.isNotEmpty)
                      Text(
                        _controller.notice,
                        key: const ValueKey('display-notice'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    Text(
                      fractions
                          ? 'Berechnungen · Brüche'
                          : 'Berechnungen · Linear',
                      style: const TextStyle(fontSize: 10),
                    ),
                    Text(
                      'Ans: $answer',
                      key: const ValueKey('display-answer'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10),
                    ),
                    const SizedBox(height: 8),
                    if (fractions)
                      SizedBox(
                        key: const ValueKey('display-structured'),
                        height: 104,
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: Theme.of(context).colorScheme
                                .copyWith(onSurface: ink),
                          ),
                          child: FractionExpressionView(
                            snapshot: structured.editor,
                            showCursor: editing && !_controller.storePending,
                            followCursor: true,
                            errorCursor: structured.errorCursor,
                            fontSize: fontSize,
                          ),
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
                                if (editing && !_controller.storePending)
                                  const TextSpan(text: '│'),
                                TextSpan(text: expression.substring(cursor)),
                              ],
                            ),
                            style: TextStyle(fontSize: fontSize, color: ink),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (fractions && phase == CalculatorPhase.error)
                      const Text(
                        'Links/Rechts oder Auf/Ab öffnen die markierte Stelle. AC löscht die Eingabe.',
                        key: ValueKey('display-error-help'),
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8A201C),
                        ),
                      ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child:
                          periodPrefix != null &&
                              expansion != null &&
                              expansion.repeatingDigits.isNotEmpty
                          ? RecurringResultView(
                              periodPrefix: periodPrefix,
                              repeatingDigits: expansion.repeatingDigits,
                              canonicalText: resultText,
                              style: resultStyle,
                            )
                          : Text(
                              resultText,
                              key: const ValueKey('display-result'),
                              style: resultStyle,
                            ),
                    ),
                    if (presentation?.fallbackReason ==
                        RationalDisplayFallbackReason.expansionLimit)
                      const Text(
                        'Periode zu lang; Bruch bleibt exakt. S⇔D zeigt den Dezimalwert.',
                        key: ValueKey('display-period-limit'),
                        style: TextStyle(fontSize: 11),
                      ),
                    if (outputError != null)
                      Text(
                        outputError,
                        key: const ValueKey('display-format-error'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8A201C),
                        ),
                      ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _recallOverview(Color ink) {
    final selected = _controller.recallSelected;
    return Column(
      key: const ValueKey('display-recall'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'RECALL · Norm 1',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 5),
        Semantics(
          selected: selected,
          child: TextButton(
            key: const ValueKey('display-recall-select'),
            onPressed: () => _pressId('KEY_M_PLUS'),
            style: TextButton.styleFrom(
              foregroundColor: ink,
              backgroundColor: selected ? const Color(0xFFAFBFA7) : null,
              alignment: Alignment.centerLeft,
              minimumSize: const Size(44, 44),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            ),
            child: Row(
              children: [
                const Text('M = '),
                Expanded(
                  child: Text(
                    _controller.recallPreviewText ?? 'Anzeige zu umfangreich',
                    key: const ValueKey('display-recall-value'),
                  ),
                ),
                if (selected) const Icon(Icons.check, size: 16),
              ],
            ),
          ),
        ),
        Semantics(
          liveRegion: true,
          child: Text(
            selected
                ? '= ruft ab · AC schließt'
                : 'M mit M+ wählen · AC schließt',
            key: const ValueKey('display-recall-prompt'),
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _menu() => Column(
    key: const ValueKey('calculator-menu'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              _controller.menuTitle,
              key: const ValueKey('menu-title'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            key: const ValueKey('menu-back'),
            tooltip: 'Zurück · Links',
            onPressed: () => setState(_controller.menuBack),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.arrow_back, size: 18),
          ),
          IconButton(
            key: const ValueKey('menu-close'),
            tooltip: 'Menü schließen · AC',
            onPressed: () => _pressId('KEY_AC'),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
      for (final (index, item) in _controller.menuItems.indexed)
        Semantics(
          selected: index == _controller.menuSelection,
          child: Tooltip(
            message: item.capabilityStatus,
            child: TextButton(
              key: ValueKey('setup-item-${item.id}'),
              onPressed: () =>
                  setState(() => _controller.selectMenuItem(index)),
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                foregroundColor: const Color(0xFF172318),
                backgroundColor: index == _controller.menuSelection
                    ? const Color(0xFFAFBFA7)
                    : Colors.transparent,
                shape: const RoundedRectangleBorder(),
                alignment: Alignment.centerLeft,
              ),
              child: Row(
                children: [
                  Text(
                    '${index + 1}: ',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.label, style: const TextStyle(fontSize: 13)),
                        if (item.capabilityStatus != 'Verfügbar')
                          Text(
                            item.capabilityStatus,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF53614F),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (item.selected) const Icon(Icons.check, size: 16),
                ],
              ),
            ),
          ),
        ),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            key: const ValueKey('menu-page-up'),
            tooltip: 'Vorherige Einträge',
            onPressed: () => setState(() => _controller.menuMove(-1)),
            icon: const Icon(Icons.keyboard_arrow_up),
          ),
          Text(
            '${_controller.menuOffset + 1}–${_controller.menuOffset + _controller.menuItems.length}',
            style: const TextStyle(fontSize: 10),
          ),
          IconButton(
            key: const ValueKey('menu-page-down'),
            tooltip: 'Weitere Einträge',
            onPressed: () => setState(() => _controller.menuMove(1)),
            icon: const Icon(Icons.keyboard_arrow_down),
          ),
        ],
      ),
    ],
  );
}
