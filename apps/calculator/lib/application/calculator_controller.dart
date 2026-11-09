import 'package:calculator_core/calculator_core.dart';

import 'calculator_settings.dart';
import 'key_layout.dart';
export 'calculator_settings.dart';

/// One immutable rendering decision, shared by visual text and accessibility.
/// [periodPrefix] already includes sign, grouping and non-repeating digits.
final class CalculatorResultPresentation {
  final String text;
  final RationalDecimalExpansion? expansion;
  final String? periodPrefix;
  final RationalDisplayFallbackReason? fallbackReason;

  const CalculatorResultPresentation({
    required this.text,
    this.expansion,
    this.periodPrefix,
    this.fallbackReason,
  });
}

final class CalculatorMenuItem {
  final String id, label, capabilityStatus;
  final bool selected;
  const CalculatorMenuItem(
    this.id,
    this.label, {
    this.selected = false,
    this.capabilityStatus = 'Verfügbar',
  });
}

final class _MenuPosition {
  final String page;
  int selection = 0;
  _MenuPosition(this.page);
}

/// Synchronous, widget-independent application controller. The UI redraws after
/// commands; there is no platform persistence or background timer here.
final class CalculatorController {
  CalculatorController() : this._(CalculatorMemory());

  CalculatorController._(this.memory)
    : session = CalculatorSession(memory: memory),
      structured = StructuredCalculatorSession(memory: memory);

  /// One exact register state per controller, shared by both input modes.
  final CalculatorMemory memory;
  final CalculatorSession session;
  final StructuredCalculatorSession structured;
  CalculatorSettings _settings = const CalculatorSettings();
  CalculatorSettings get settings => _settings;
  bool get fractions => settings.fractions;
  bool shift = false;
  bool _alpha = false;
  bool get alpha => _alpha;
  bool poweredOn = true;
  String notice = '';
  Object? _storeCandidate;
  Rational? _recallValue;
  bool _recallSelected = false;
  bool get storePending => _storeCandidate != null;
  bool get recallOpen => _recallValue != null;
  bool get recallSelected => _recallSelected;

  String? get recallPreviewText {
    final value = _recallValue;
    if (value == null) return null;
    try {
      return _decimal(value, const CalculatorSettings());
    } on CalculatorException {
      return 'Anzeige zu groß';
    }
  }

  final List<_MenuPosition> _menu = [];
  bool get menuOpen => _menu.isNotEmpty;
  String get _page => _menu.last.page;
  bool get memoryResetPending => menuOpen && _page == 'reset-memory';
  int get menuOffset => menuOpen ? (_menu.last.selection ~/ 4) * 4 : 0;
  int get menuSelection => menuOpen ? _menu.last.selection - menuOffset : 0;
  String get menuTitle => !menuOpen
      ? ''
      : switch (_page) {
          'setup' => 'Einstellungen',
          'mode' => 'Rechenmodus',
          'reset' => 'RESET',
          'reset-memory' => 'Speicher löschen?',
          'io' => 'Eingabe/Ausgabe',
          'angle' => 'Winkeleinheit',
          'number' => 'Zahlenformat',
          'fix' => 'Fix: Nachkommastellen',
          'sci' => 'Sci: signifikante Stellen',
          'norm' => 'Norm',
          'prefix' => 'Dezimalpräfixe',
          'fraction' => 'Bruchergebnis',
          'complex' => 'Komplexe Zahlen',
          'frequency' => 'Häufigkeit',
          'sheetAuto' => 'Automatische Berechnung',
          'sheetCell' => 'Zelle anzeigen',
          'solutions' => 'Komplexe Lösungen',
          'table' => 'Wertetabelle',
          'period' => 'Periodische Darstellung',
          'separator' => '1000er-Trennung',
          'text' => 'Mehrzeilengröße',
          'qr' => 'QR-Code-Version',
          'off' => 'Automatisch ausschalten',
          'contrast' => 'Kontrast ◀ ▶',
          _ => '',
        };
  List<CalculatorMenuItem> get menuItems => menuOpen
      ? List.unmodifiable(_allItems.skip(menuOffset).take(4))
      : const [];

  void openSetup() => _open('setup');
  void openModeMenu() => _open('mode');
  void _open(String page) {
    _closeMemoryDialog();
    poweredOn = true;
    shift = false;
    _alpha = false;
    notice = '';
    _menu
      ..clear()
      ..add(_MenuPosition(page));
  }

  void menuBack() {
    if (menuOpen) _menu.removeLast();
  }

  void menuMove(int delta) {
    if (!menuOpen || memoryResetPending) return;
    _menu.last.selection = (_menu.last.selection + delta).clamp(
      0,
      _allItems.length - 1,
    );
  }

  void selectInputOutput(CalculatorInputOutput value) {
    _closeMemoryDialog();
    _alpha = false;
    _settings = settings.copyWith(inputOutput: value);
  }

  void _closeMemoryDialog() {
    if (storePending || recallOpen) shift = false;
    switch (_storeCandidate) {
      case LinearMemoryAssignment():
        session.cancelMemoryAssignment();
      case StructuredMemoryAssignment():
        structured.cancelMemoryAssignment();
    }
    _storeCandidate = null;
    _recallValue = null;
    _recallSelected = false;
  }

  void _pressMemoryDialog(String id) {
    if (id == 'KEY_AC') {
      _closeMemoryDialog();
      return;
    }
    final candidate = _storeCandidate;
    if (candidate != null) {
      if (id != 'KEY_M_PLUS') return;
      _storeCandidate = null;
      final committed = switch (candidate) {
        LinearMemoryAssignment() => session.commitMemoryAssignment(candidate),
        StructuredMemoryAssignment() => structured.commitMemoryAssignment(
          candidate,
        ),
        _ => false,
      };
      if (committed && settings.decimalOutput) {
        _selectDisplay(RationalDisplayFormat.exactDecimal);
      } else if (!committed && phase != CalculatorPhase.error) {
        notice = 'Wert erneut mit STO vorbereiten';
      }
      return;
    }
    if (id == 'KEY_M_PLUS') {
      _recallSelected = true;
    } else if (id == 'KEY_EQUALS' && recallSelected) {
      final current = memory.snapshot.memory;
      if (current != _recallValue) {
        _recallValue = current;
        _recallSelected = false;
        return;
      }
      _closeMemoryDialog();
      if (fractions) {
        structured.recallMemory();
      } else {
        session.recallMemory();
      }
      if (settings.decimalOutput) {
        _selectDisplay(RationalDisplayFormat.exactDecimal);
      }
    }
  }

  /// Unsupported arithmetic remains visibly unavailable on the physical skin.
  /// The modifier keys share the calculation and dialog routing below.
  bool isKeyEnabled(String id) {
    if (id == 'KEY_ON') return true;
    if (!poweredOn) return false;
    if (id == 'KEY_SHIFT' || id == 'KEY_MENU') return true;
    if (storePending || recallOpen) {
      return id == 'KEY_AC' ||
          id == 'KEY_M_PLUS' ||
          (storePending && id == 'KEY_STO') ||
          (recallOpen && id == 'KEY_EQUALS');
    }
    if (menuOpen) {
      if (memoryResetPending) {
        return const {'KEY_AC', 'KEY_LEFT', 'KEY_EQUALS'}.contains(id);
      }
      if (const {
        'KEY_AC',
        'KEY_LEFT',
        'KEY_UP',
        'KEY_DOWN',
        'KEY_EQUALS',
      }.contains(id))
        return true;
      if (_page == 'contrast' && id == 'KEY_RIGHT') return true;
      if (RegExp(r'^KEY_[1-4]$').hasMatch(id)) {
        return int.parse(id.substring(4)) <= menuItems.length;
      }
      return false;
    }
    if (id == 'KEY_ALPHA') return true;
    if (id == 'KEY_SD' || id == 'KEY_M_PLUS' || id == 'KEY_STO') return true;
    if (fractions && const {'KEY_FRACTION', 'KEY_UP', 'KEY_DOWN'}.contains(id))
      return true;
    return CalculatorKey.fromId(id) != null;
  }

  void selectMenuItem(int index) {
    if (!menuOpen) return;
    final visible = menuItems;
    if (index < 0 || index >= visible.length)
      throw RangeError.index(index, visible);
    final id = visible[index].id;
    if (_page == 'reset') {
      if (id == 'reset-memory') _menu.add(_MenuPosition(id));
      return;
    }
    if (_page == 'setup') {
      _menu.add(_MenuPosition(id));
      return;
    }
    if (_page == 'mode') {
      notice = id == 'calculate' ? '' : 'Für diesen Modus noch in Vorbereitung';
      _menu.clear();
      return;
    }
    if (_page == 'number') {
      _menu.add(_MenuPosition(id));
      return;
    }
    if (_page == 'contrast') return;
    _choose(id);
    menuBack();
  }

  void pressId(String id) {
    if (id == 'KEY_ON') {
      _closeMemoryDialog();
      poweredOn = true;
      shift = false;
      _alpha = false;
      _menu.clear();
      session.pressId('KEY_AC');
      structured.pressId('KEY_AC');
      notice = '';
      return;
    }
    if (!poweredOn) return;
    if (id == 'KEY_SHIFT') {
      _alpha = false;
      shift = !shift;
      return;
    }
    if (id == 'KEY_ALPHA') {
      if (isKeyEnabled(id)) {
        shift = false;
        _alpha = !_alpha;
        notice = '';
      }
      return;
    }
    final shifted = shift;
    final alphaWasActive = alpha;
    shift = false;
    _alpha = false;
    if (shifted && id == 'KEY_AC') {
      _closeMemoryDialog();
      poweredOn = false;
      _menu.clear();
      return;
    }
    if (id == 'KEY_MENU') {
      shifted ? openSetup() : openModeMenu();
      return;
    }
    if (menuOpen) {
      if (id == 'KEY_AC') {
        _menu.clear();
        return;
      }
      if (memoryResetPending && id != 'KEY_LEFT') {
        if (id == 'KEY_EQUALS' && !shifted) {
          session.cancelMemoryAssignment();
          structured.cancelMemoryAssignment();
          memory.clearMemory();
          _menu.clear();
          notice = 'Speicher gelöscht';
        }
        return;
      }
      if (_page == 'contrast' && (id == 'KEY_LEFT' || id == 'KEY_RIGHT')) {
        _settings = settings.copyWith(
          contrast: (settings.contrast + (id == 'KEY_RIGHT' ? 1 : -1)).clamp(
            0,
            10,
          ),
        );
      } else if (id == 'KEY_LEFT') {
        menuBack();
      } else if (id == 'KEY_UP' || id == 'KEY_DOWN') {
        menuMove(id == 'KEY_UP' ? -1 : 1);
      } else if (id == 'KEY_EQUALS') {
        selectMenuItem(menuSelection);
      } else if (RegExp(r'^KEY_[1-4]$').hasMatch(id)) {
        final index = int.parse(id.substring(4)) - 1;
        if (index < menuItems.length) selectMenuItem(index);
      }
      return;
    }
    notice = '';
    if (storePending || recallOpen) {
      _pressMemoryDialog(id);
      return;
    }
    if (alphaWasActive && id != 'KEY_AC') {
      if (id == 'KEY_M_PLUS') {
        _pressCore('ACTION_MEMORY');
      } else {
        notice = 'Diese ALPHA-Belegung ist noch in Vorbereitung';
      }
      return;
    }
    if (id == 'KEY_STO') {
      if (shifted) {
        _recallValue = memory.snapshot.memory;
      } else {
        _storeCandidate = fractions
            ? structured.prepareMemoryAssignment()
            : session.prepareMemoryAssignment();
      }
      return;
    }
    if (id == 'KEY_M_PLUS') {
      final operation = shifted
          ? MemoryOperation.subtract
          : MemoryOperation.add;
      fractions
          ? structured.applyMemory(operation)
          : session.applyMemory(operation);
      if (settings.decimalOutput) {
        _selectDisplay(RationalDisplayFormat.exactDecimal);
      }
      return;
    }
    if (shifted) {
      if (id == 'KEY_9') {
        _open('reset');
        return;
      }
      if (id == 'KEY_LPAREN') {
        _pressCore('ACTION_ABS');
        return;
      }
      if (id == 'KEY_MULTIPLY') {
        _pressCore('ACTION_PERMUTATION');
        return;
      }
      if (id == 'KEY_DIVIDE') {
        _pressCore('ACTION_COMBINATION');
        return;
      }
      if (id == 'KEY_RECIPROCAL') {
        _pressCore('ACTION_FACTORIAL');
        return;
      }
      if (id == 'KEY_ANS') {
        _pressCore('ACTION_PERCENT');
        return;
      }
      if (id == 'KEY_SQUARE') {
        _pressCore('ACTION_CUBE');
        return;
      }
      if (id == 'KEY_SD') {
        if (phase == CalculatorPhase.result) {
          _settings = settings.copyWith(
            fractionForm: settings.fractionForm == CalculatorFractionForm.mixed
                ? CalculatorFractionForm.improper
                : CalculatorFractionForm.mixed,
          );
          _selectDisplay(RationalDisplayFormat.fraction);
        }
        return;
      }
      if (id == 'KEY_EQUALS') {
        _pressCore(id);
        _selectDisplay(RationalDisplayFormat.exactDecimal);
        return;
      }
      if (calculatorRows.any((row) => row.any((key) => key.id == id))) {
        notice = 'Diese SHIFT-Belegung ist noch in Vorbereitung';
        return;
      }
      throw CalculatorException(
        CalculatorErrorCode.unsupported,
        'Unbekannte Taste $id',
      );
    }
    if (id == 'KEY_SD') {
      _toggleDisplay();
      return;
    }
    final previousPhase = phase;
    _pressCore(id);
    if (id == 'KEY_EQUALS' &&
        previousPhase != CalculatorPhase.result &&
        settings.decimalOutput) {
      _selectDisplay(RationalDisplayFormat.exactDecimal);
    }
  }

  void _pressCore(String id) =>
      fractions ? structured.pressId(id) : session.pressId(id);
  CalculatorPhase get phase =>
      fractions ? structured.snapshot.phase : session.snapshot.phase;
  Rational? get result =>
      fractions ? structured.snapshot.result : session.snapshot.result;
  RationalDisplayFormat get _displayFormat => fractions
      ? structured.snapshot.resultDisplayFormat
      : session.snapshot.resultDisplayFormat;
  void _selectDisplay(RationalDisplayFormat format) {
    fractions
        ? structured.selectResultDisplayFormat(format)
        : session.selectResultDisplayFormat(format);
  }

  void _toggleDisplay() {
    if (phase != CalculatorPhase.result) return;
    if (_displayFormat == RationalDisplayFormat.exactRecurringDecimal) {
      _selectDisplay(RationalDisplayFormat.exactDecimal);
    } else if (_displayFormat == RationalDisplayFormat.exactDecimal) {
      _selectDisplay(RationalDisplayFormat.fraction);
    } else if (result!.isInteger) {
      // Integers never have a period, even when their full exact text exceeds
      // the output budget. Rounded Sci/Norm can still render such a value.
      _selectDisplay(RationalDisplayFormat.exactDecimal);
    } else if (_recurringEnabled) {
      // A classification limit must not escape a key event. Preserve the exact
      // request and let resultPresentation report the separate output problem;
      // the next S/D still advances to the rounded representation.
      try {
        final display = formatRational(
          result!,
          format: RationalDisplayFormat.exactRecurringDecimal,
        );
        final hasPeriod =
            display.expansion?.repeatingDigits.isNotEmpty ?? false;
        _selectDisplay(
          hasPeriod ||
                  display.fallbackReason ==
                      RationalDisplayFallbackReason.expansionLimit
              ? RationalDisplayFormat.exactRecurringDecimal
              : RationalDisplayFormat.exactDecimal,
        );
      } on CalculatorException {
        _selectDisplay(RationalDisplayFormat.exactRecurringDecimal);
      }
    } else {
      _selectDisplay(RationalDisplayFormat.exactDecimal);
    }
  }

  bool get _recurringEnabled =>
      settings.recurringDisplay &&
      settings.numberFormat == CalculatorNumberFormat.norm;

  void _normalizeUnavailablePeriodChoices() {
    if (_recurringEnabled) return;
    if (session.snapshot.resultDisplayFormat ==
        RationalDisplayFormat.exactRecurringDecimal) {
      session.selectResultDisplayFormat(RationalDisplayFormat.exactDecimal);
    }
    if (structured.snapshot.resultDisplayFormat ==
        RationalDisplayFormat.exactRecurringDecimal) {
      structured.selectResultDisplayFormat(RationalDisplayFormat.exactDecimal);
    }
  }

  String get displayStatus => [
    switch (settings.angleUnit) {
      CalculatorAngleUnit.degrees => 'D',
      CalculatorAngleUnit.radians => 'R',
      CalculatorAngleUnit.gradians => 'G',
    },
    if (shift) 'SHIFT',
    if (alpha) 'ALPHA',
    if (storePending) 'STO',
    if (memory.snapshot.hasMemory) 'M',
    if (fractions) 'Math',
    if (settings.numberFormat == CalculatorNumberFormat.fix) 'FIX',
    if (settings.numberFormat == CalculatorNumberFormat.sci) 'SCI',
  ].join('  ');

  /// Display-only rounding: exact integer division, ties away from zero.
  /// The rational result and Ans remain the sessions' original values.
  String get resultText => resultPresentation.text;

  CalculatorResultPresentation get resultPresentation {
    final value = result;
    if (phase != CalculatorPhase.result || value == null) {
      return const CalculatorResultPresentation(text: '');
    }
    String text;
    RationalDecimalExpansion? expansion;
    RationalDisplayFallbackReason? fallbackReason;
    String? periodPrefix;
    if (_displayFormat == RationalDisplayFormat.fraction) {
      text = formatRational(value).text;
      if (settings.fractionForm == CalculatorFractionForm.mixed &&
          !value.isInteger &&
          value.numerator.abs() > value.denominator) {
        final n = value.numerator.abs(), d = value.denominator;
        text = '${value.numerator.isNegative ? '-' : ''}${n ~/ d} ${n % d}/$d';
      }
    } else if (_displayFormat == RationalDisplayFormat.exactRecurringDecimal) {
      final display = formatRational(
        value,
        format: RationalDisplayFormat.exactRecurringDecimal,
      );
      text = display.text;
      expansion = display.expansion;
      fallbackReason = display.fallbackReason;
      if (expansion != null && expansion.repeatingDigits.isNotEmpty) {
        final integerText =
            '${expansion.negative ? '-' : ''}${expansion.integerDigits}';
        final grouped = settings.thousandsSeparator
            ? _group(integerText)
            : integerText;
        periodPrefix = '$grouped,${expansion.nonRepeatingDigits}';
      }
    } else {
      text = _decimal(value, settings);
    }
    if (settings.thousandsSeparator) text = _group(text);
    if (text.length > 2048)
      throw const CalculatorException(
        CalculatorErrorCode.limit,
        'Anzeige zu lang',
      );
    return CalculatorResultPresentation(
      text: text,
      expansion: expansion,
      periodPrefix: periodPrefix,
      fallbackReason: fallbackReason,
    );
  }

  static String _decimal(Rational value, CalculatorSettings settings) {
    final n = value.numerator.abs(), d = value.denominator;
    if (n.bitLength + d.bitLength > 100000)
      throw const CalculatorException(
        CalculatorErrorCode.limit,
        'Anzeige zu groß',
      );
    final negative = value.numerator.isNegative;
    final exponent = n == BigInt.zero ? 0 : _exponent(n, d);
    if (settings.numberFormat == CalculatorNumberFormat.fix) {
      return _fixed(n, d, settings.fixDigits, negative, trim: false);
    }
    var sci =
        settings.numberFormat == CalculatorNumberFormat.sci ||
        (n != BigInt.zero &&
            (exponent >= 10 || exponent < (settings.norm == 1 ? -2 : -9)));
    // Own Norm prototype rule: a ten-significant-digit carry across 10^10
    // also uses scientific notation rather than an eleven-digit fixed integer.
    if (!sci && exponent == 9 && _round(n, d, 0) >= BigInt.from(10).pow(10)) {
      sci = true;
    }
    final significant = settings.numberFormat == CalculatorNumberFormat.sci
        ? (settings.sciDigits == 0 ? 10 : settings.sciDigits)
        : 10;
    if (!sci)
      return _fixed(
        n,
        d,
        (significant - 1 - exponent).clamp(0, 100),
        negative,
        trim: true,
      );
    var e = exponent;
    final places = significant - 1;
    BigInt rounded = _round(n, d, places - e);
    if (rounded >= BigInt.from(10).pow(significant)) {
      rounded ~/= BigInt.from(10);
      e++;
    }
    var digits = rounded.toString().padLeft(significant, '0');
    var mantissa = significant == 1
        ? digits
        : '${digits[0]},${digits.substring(1)}';
    if (settings.numberFormat == CalculatorNumberFormat.norm)
      mantissa = _trim(mantissa);
    return '${negative && rounded != BigInt.zero ? '-' : ''}$mantissa×10^$e';
  }

  static BigInt _round(BigInt n, BigInt d, int places) {
    if (places >= 0) {
      n *= BigInt.from(10).pow(places);
    } else {
      d *= BigInt.from(10).pow(-places);
    }
    final q = n ~/ d;
    return q + ((n % d) * BigInt.two >= d ? BigInt.one : BigInt.zero);
  }

  static String _fixed(
    BigInt n,
    BigInt d,
    int places,
    bool negative, {
    required bool trim,
  }) {
    // Bound the integer part before converting it into display text.
    if (n ~/ d >= BigInt.from(10).pow(2048))
      throw const CalculatorException(
        CalculatorErrorCode.limit,
        'Anzeige zu lang',
      );
    final rounded = _round(n, d, places);
    var digits = rounded.toString().padLeft(places + 1, '0');
    var text = places == 0
        ? digits
        : '${digits.substring(0, digits.length - places)},${digits.substring(digits.length - places)}';
    if (trim) text = _trim(text);
    return '${negative && rounded != BigInt.zero ? '-' : ''}$text';
  }

  static String _trim(String text) => text.contains(',')
      ? text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r',$'), '')
      : text;
  static int _digits(BigInt n) {
    var lo = 0, hi = 30104;
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      if (n >= BigInt.from(10).pow(mid)) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo + 1;
  }

  static int _exponent(BigInt n, BigInt d) {
    var e = _digits(n) - _digits(d);
    if (e >= 0
        ? n < d * BigInt.from(10).pow(e)
        : n * BigInt.from(10).pow(-e) < d)
      e--;
    return e;
  }

  static String _group(
    String text,
  ) => text.replaceAllMapped(RegExp(r'^(-?)([0-9]+)'), (m) {
    final digits = m[2]!;
    return m[1]! +
        digits
            .split('')
            .asMap()
            .entries
            .map(
              (e) =>
                  '${e.key > 0 && (digits.length - e.key) % 3 == 0 ? '.' : ''}${e.value}',
            )
            .join();
  });

  static const _pending = 'Für diesen Modus noch in Vorbereitung';
  List<CalculatorMenuItem> get _allItems {
    CalculatorMenuItem item(
      String id,
      String label, [
      bool selected = false,
      bool pending = false,
    ]) => CalculatorMenuItem(
      id,
      label,
      selected: selected,
      capabilityStatus: pending ? _pending : 'Verfügbar',
    );
    List<CalculatorMenuItem> toggles(bool value, {bool pending = false}) => [
      item('on', 'Ein', value, pending),
      item('off', 'Aus', !value, pending),
    ];
    switch (_page) {
      case 'reset':
        return [
          item('reset-settings', 'Setupdaten', false, true),
          item('reset-memory', 'Speicher'),
          item('reset-all', 'Alle initialis.', false, true),
        ];
      case 'reset-memory':
        return const [];
      case 'setup':
        return [
          for (final pair in const [
            ['io', 'Eingabe/Ausgabe'],
            ['angle', 'Winkeleinheit'],
            ['number', 'Zahlenformat'],
            ['prefix', 'Dezimalpräfixe'],
            ['fraction', 'Bruchergebnis'],
            ['complex', 'Komplexe Zahlen'],
            ['frequency', 'Häufigkeit'],
            ['sheetAuto', 'Tabellenkalk.: Berechnung'],
            ['sheetCell', 'Tabellenkalk.: Zelle'],
            ['solutions', 'Komplexe Lösungen'],
            ['table', 'Wertetabelle'],
            ['period', 'Periodische Darstellung'],
            ['separator', '1000er-Trennung'],
            ['text', 'Mehrzeilengröße'],
            ['qr', 'QR Code'],
            ['off', 'Automatisch aus'],
            ['contrast', 'Kontrast'],
          ])
            item(
              pair[0],
              pair[1],
              false,
              const {
                'angle',
                'prefix',
                'complex',
                'frequency',
                'sheetAuto',
                'sheetCell',
                'solutions',
                'table',
                'qr',
                'off',
              }.contains(pair[0]),
            ),
        ];
      case 'mode':
        return [
          for (final label in const [
            'Berechnungen',
            'Komplexe Zahlen',
            'Basis-N',
            'Matrizen',
            'Vektorrechnung',
            'Statistik',
            'Verteilungsfkt.',
            'Tabellenkalk.',
            'Tabellen',
            'Gleichung/Funkt',
            'Ungleichungen',
            'Berechn prüf',
            'Verhältnisse',
          ])
            item(
              label == 'Berechnungen' ? 'calculate' : label,
              label,
              label == 'Berechnungen',
              label != 'Berechnungen',
            ),
        ];
      case 'io':
        return [
          for (final option in CalculatorInputOutput.values)
            item(
              option.name,
              const [
                'Math → Math',
                'Math → Dezim.',
                'Lin. → Linear',
                'Lin. → Dezim.',
              ][option.index],
              settings.inputOutput == option,
            ),
        ];
      case 'angle':
        return [
          for (final option in CalculatorAngleUnit.values)
            item(
              option.name,
              const ['Gradmaß D', 'Bogenmaß R', 'Gon G'][option.index],
              settings.angleUnit == option,
              true,
            ),
        ];
      case 'number':
        return [
          for (final option in CalculatorNumberFormat.values)
            item(
              option.name,
              option.name.toUpperCase(),
              settings.numberFormat == option,
            ),
        ];
      case 'fix':
      case 'sci':
        return [
          for (var i = 0; i <= 9; i++)
            item(
              '$i',
              _page == 'sci' && i == 0 ? '0 (10 signifikante Stellen)' : '$i',
              _page == 'fix'
                  ? settings.numberFormat == CalculatorNumberFormat.fix &&
                        settings.fixDigits == i
                  : settings.numberFormat == CalculatorNumberFormat.sci &&
                        settings.sciDigits == i,
            ),
        ];
      case 'norm':
        return [
          item(
            '1',
            'Norm 1',
            settings.numberFormat == CalculatorNumberFormat.norm &&
                settings.norm == 1,
          ),
          item(
            '2',
            'Norm 2',
            settings.numberFormat == CalculatorNumberFormat.norm &&
                settings.norm == 2,
          ),
        ];
      case 'prefix':
        return toggles(settings.engineeringPrefixes, pending: true);
      case 'fraction':
        return [
          item(
            'mixed',
            'ab/c',
            settings.fractionForm == CalculatorFractionForm.mixed,
          ),
          item(
            'improper',
            'd/c',
            settings.fractionForm == CalculatorFractionForm.improper,
          ),
        ];
      case 'complex':
        return [
          item(
            'rectangular',
            'a+bi',
            settings.complexForm == CalculatorComplexForm.rectangular,
            true,
          ),
          item(
            'polar',
            'r∠θ',
            settings.complexForm == CalculatorComplexForm.polar,
            true,
          ),
        ];
      case 'frequency':
        return toggles(settings.frequency, pending: true);
      case 'sheetAuto':
        return toggles(settings.spreadsheetAutoCalculate, pending: true);
      case 'sheetCell':
        return [
          item('formula', 'Formel', settings.spreadsheetShowFormula, true),
          item('value', 'Wert', !settings.spreadsheetShowFormula, true),
        ];
      case 'solutions':
        return toggles(settings.complexSolutions, pending: true);
      case 'table':
        return [
          item('f', 'f(x)', !settings.tableBothFunctions, true),
          item('fg', 'f(x),g(x)', settings.tableBothFunctions, true),
        ];
      case 'period':
        return toggles(settings.recurringDisplay);
      case 'separator':
        return toggles(settings.thousandsSeparator);
      case 'text':
        return [
          item('normal', 'Normale Schrift', !settings.smallText),
          item('small', 'Kleine Schrift', settings.smallText),
        ];
      case 'qr':
        return [
          item('3', 'Version 3', settings.qrVersion == 3, true),
          item('11', 'Version 11', settings.qrVersion == 11, true),
        ];
      case 'off':
        return [
          item('10', '10 Minuten', settings.autoOffMinutes == 10, true),
          item('60', '60 Minuten', settings.autoOffMinutes == 60, true),
        ];
      case 'contrast':
        return [item('contrast', '${settings.contrast} / 10')];
      default:
        return const [];
    }
  }

  void _choose(String id) {
    _settings = switch (_page) {
      'io' => settings.copyWith(
        inputOutput: CalculatorInputOutput.values.byName(id),
      ),
      'angle' => settings.copyWith(
        angleUnit: CalculatorAngleUnit.values.byName(id),
      ),
      'fix' => settings.copyWith(
        numberFormat: CalculatorNumberFormat.fix,
        fixDigits: int.parse(id),
      ),
      'sci' => settings.copyWith(
        numberFormat: CalculatorNumberFormat.sci,
        sciDigits: int.parse(id),
      ),
      'norm' => settings.copyWith(
        numberFormat: CalculatorNumberFormat.norm,
        norm: int.parse(id),
      ),
      'prefix' => settings.copyWith(engineeringPrefixes: id == 'on'),
      'fraction' => settings.copyWith(
        fractionForm: CalculatorFractionForm.values.byName(id),
      ),
      'complex' => settings.copyWith(
        complexForm: CalculatorComplexForm.values.byName(id),
      ),
      'frequency' => settings.copyWith(frequency: id == 'on'),
      'sheetAuto' => settings.copyWith(spreadsheetAutoCalculate: id == 'on'),
      'sheetCell' => settings.copyWith(spreadsheetShowFormula: id == 'formula'),
      'solutions' => settings.copyWith(complexSolutions: id == 'on'),
      'table' => settings.copyWith(tableBothFunctions: id == 'fg'),
      'period' => settings.copyWith(recurringDisplay: id == 'on'),
      'separator' => settings.copyWith(thousandsSeparator: id == 'on'),
      'text' => settings.copyWith(smallText: id == 'small'),
      'qr' => settings.copyWith(qrVersion: int.parse(id)),
      'off' => settings.copyWith(autoOffMinutes: int.parse(id)),
      _ => settings,
    };
    _normalizeUnavailablePeriodChoices();
  }
}
