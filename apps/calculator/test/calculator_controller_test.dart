import 'package:calculator_core/calculator_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fx991_calculator/application/calculator_controller.dart';
import 'package:fx991_calculator/application/key_layout.dart';

// Prepared controller unit tests. No widget binding or original emulator.
void chooseVisible(CalculatorController c, String id) {
  for (var guard = 0; guard < 80; guard++) {
    final index = c.menuItems.indexWhere((item) => item.id == id);
    if (index >= 0) {
      c.selectMenuItem(index);
      return;
    }
    c.menuMove(1);
  }
  fail('Menu item $id not found in ${c.menuTitle}');
}

void setting(CalculatorController c, List<String> path) {
  c.openSetup();
  for (final id in path) {
    chooseVisible(c, id);
  }
  c.pressId('KEY_AC');
}

void calculate(CalculatorController c, String expression) {
  c.pressId('KEY_AC');
  for (final character in expression.split('')) {
    c.pressId(switch (character) {
      '+' => 'KEY_ADD',
      '-' => 'KEY_SUBTRACT',
      '*' => 'KEY_MULTIPLY',
      '/' => 'KEY_DIVIDE',
      '^' => 'KEY_POWER',
      '(' => 'KEY_LPAREN',
      ')' => 'KEY_RPAREN',
      '.' || ',' => 'KEY_DECIMAL',
      _ => 'KEY_$character',
    });
  }
  c.pressId('KEY_EQUALS');
}

void main() {
  test('source defaults and private session-only immutable settings', () {
    final c = CalculatorController();
    expect(c.fractions, isTrue);
    expect(c.settings.inputOutput, CalculatorInputOutput.mathMath);
    expect(c.settings.angleUnit, CalculatorAngleUnit.degrees);
    expect(c.settings.numberFormat, CalculatorNumberFormat.norm);
    expect(c.settings.norm, 1);
    expect(c.settings.engineeringPrefixes, isFalse);
    expect(c.settings.fractionForm, CalculatorFractionForm.improper);
    expect(c.settings.complexForm, CalculatorComplexForm.rectangular);
    expect(c.settings.frequency, isFalse);
    expect(c.settings.spreadsheetAutoCalculate, isTrue);
    expect(c.settings.spreadsheetShowFormula, isTrue);
    expect(c.settings.complexSolutions, isTrue);
    expect(c.settings.tableBothFunctions, isTrue);
    expect(c.settings.recurringDisplay, isTrue);
    expect(c.settings.thousandsSeparator, isFalse);
    expect(c.settings.smallText, isFalse);
    expect(c.settings.qrVersion, 11);
    expect(c.settings.autoOffMinutes, 10);
    expect(c.settings.contrast, 5);
    expect(c.resultText, '');
  });

  test('toolbar setup and SHIFT MENU expose identical preferences', () {
    final toolbar = CalculatorController()..openSetup();
    final keys = CalculatorController()
      ..pressId('KEY_SHIFT')
      ..pressId('KEY_MENU');
    expect(keys.shift, isFalse);
    expect(keys.menuTitle, toolbar.menuTitle);
    expect(keys.menuItems.map((i) => i.id), toolbar.menuItems.map((i) => i.id));
    chooseVisible(keys, 'io');
    keys.pressId('KEY_4');
    expect(keys.settings.inputOutput, CalculatorInputOutput.linearDecimal);
    expect(keys.fractions, isFalse);
    expect(toolbar.fractions, isTrue);
  });

  test('four-row paging uses visible digit rows and keeps parent position', () {
    final c = CalculatorController()
      ..openSetup()
      ..menuMove(4);
    expect(c.menuOffset, 4);
    expect(c.menuSelection, 0);
    expect(c.menuItems.first.id, 'fraction');
    c.pressId('KEY_1');
    expect(c.menuTitle, 'Bruchergebnis');
    c.pressId('KEY_1');
    expect(c.settings.fractionForm, CalculatorFractionForm.mixed);
    expect(c.menuTitle, 'Einstellungen');
    expect(c.menuOffset, 4);
  });

  test(
    'up/down selection, equals, bounds, back and invalid visible indices',
    () {
      final c = CalculatorController()..openSetup();
      c.pressId('KEY_DOWN');
      c.pressId('KEY_EQUALS');
      expect(c.menuTitle, 'Winkeleinheit');
      c.menuMove(100);
      c.pressId('KEY_EQUALS');
      expect(c.settings.angleUnit, CalculatorAngleUnit.gradians);
      expect(c.displayStatus, contains('G'));
      c.menuMove(-100);
      expect(c.menuOffset, 0);
      expect(c.menuSelection, 0);
      expect(() => c.selectMenuItem(-1), throwsRangeError);
      expect(() => c.selectMenuItem(4), throwsRangeError);
      c.pressId('KEY_LEFT');
      expect(c.menuOpen, isFalse);
    },
  );

  test(
    'AC leaves settings, result, Ans and expression untouched while menu open',
    () {
      final c = CalculatorController();
      calculate(c, '7/3');
      final before = c.structured.snapshot;
      final settings = c.settings;
      c.openSetup();
      chooseVisible(c, 'angle');
      c.pressId('KEY_AC');
      expect(c.menuOpen, isFalse);
      expect(c.settings, same(settings));
      expect(c.structured.snapshot, same(before));
    },
  );

  test(
    'ON closes and clears both editors while preserving Ans and settings',
    () {
      final c = CalculatorController();
      calculate(c, '2');
      c.selectInputOutput(CalculatorInputOutput.linearLinear);
      calculate(c, '3');
      final settings = c.settings;
      c.openSetup();
      c.pressId('KEY_ON');
      expect(c.settings, same(settings));
      expect(c.menuOpen, isFalse);
      expect(c.session.snapshot.expression, '');
      expect(c.structured.snapshot.editor.root.nodes, isEmpty);
      expect(c.session.snapshot.answer, Rational.fromInt(3));
      expect(c.structured.snapshot.answer, Rational.fromInt(3));
    },
  );

  test('SHIFT OFF ignores keys until ON; latch toggles and unsupported shift is safe', () {
    final c = CalculatorController()..pressId('KEY_SHIFT');
    expect(c.displayStatus, contains('SHIFT'));
    c.pressId('KEY_SHIFT');
    expect(c.shift, isFalse);
    final before = c.structured.snapshot;
    c.pressId('KEY_SHIFT');
    c.pressId('KEY_POWER');
    expect(c.structured.snapshot, same(before));
    expect(c.notice, contains('Vorbereitung'));
    c.pressId('KEY_SHIFT');
    c.pressId('KEY_AC');
    expect(c.poweredOn, isFalse);
    c.pressId('KEY_9');
    expect(c.structured.snapshot, same(before));
    expect(c.isKeyEnabled('KEY_9'), isFalse);
    expect(c.isKeyEnabled('KEY_ON'), isTrue);
    c.pressId('KEY_ON');
    expect(c.poweredOn, isTrue);
  });

  test(
    'physical capability inventory is contextual, ALPHA remains unavailable',
    () {
      final c = CalculatorController();
      int active() => calculatorRows
          .expand((row) => row)
          .where((k) => c.isKeyEnabled(k.id))
          .length;
      expect(active(), 35);
      expect(c.isKeyEnabled('KEY_ALPHA'), isFalse);
      c.selectInputOutput(CalculatorInputOutput.linearLinear);
      expect(active(), 32);
      expect(c.isKeyEnabled('KEY_UP'), isFalse);
      c.openSetup();
      expect(c.isKeyEnabled('KEY_UP'), isTrue);
      expect(c.isKeyEnabled('KEY_SQUARE'), isFalse);
      expect(c.isKeyEnabled('KEY_RIGHT'), isFalse);
    },
  );

  test(
    'unknown ID remains explicitly unsupported without session mutation',
    () {
      final c = CalculatorController();
      final before = c.structured.snapshot;
      expect(
        () => c.pressId('KEY_UNKNOWN'),
        throwsA(isA<CalculatorException>()),
      );
      expect(c.structured.snapshot, same(before));
    },
  );

  test(
    'mode menu lists thirteen modes but unavailable modes do not fake a switch',
    () {
      final c = CalculatorController()..openModeMenu();
      final ids = <String>{};
      for (var i = 0; i < 13; i++) {
        ids.addAll(c.menuItems.map((e) => e.id));
        c.menuMove(1);
      }
      expect(ids.length, 13);
      c.openModeMenu();
      expect(c.menuItems[1].capabilityStatus, contains('Vorbereitung'));
      c.selectMenuItem(1);
      expect(c.notice, contains('Vorbereitung'));
      expect(c.menuOpen, isFalse);
      expect(c.phase, CalculatorPhase.editing);
    },
  );

  for (final option in CalculatorInputOutput.values) {
    test('IO ${option.name} chooses editor and next-result output', () {
      final c = CalculatorController();
      setting(c, ['io', option.name]);
      calculate(c, '1/8');
      final decimal =
          option == CalculatorInputOutput.mathDecimal ||
          option == CalculatorInputOutput.linearDecimal;
      expect(c.resultText, decimal ? '0,125' : '1/8');
      expect(c.result, Rational(BigInt.one, BigInt.from(8)));
      c.pressId('KEY_SD');
      expect(c.resultText, decimal ? '1/8' : '0,125');
      c.pressId('KEY_EQUALS');
      expect(c.resultText, decimal ? '1/8' : '0,125');
    });
  }

  test(
    'IO switching shares Ans but preserves results and immutable settings',
    () {
      final c = CalculatorController();
      final previousSettings = c.settings;
      calculate(c, '2/3');
      final structured = c.structured.snapshot;
      c.selectInputOutput(CalculatorInputOutput.linearLinear);
      calculate(c, '5');
      c.selectInputOutput(CalculatorInputOutput.mathMath);
      expect(c.structured.snapshot.editor, same(structured.editor));
      expect(c.structured.snapshot.result, structured.result);
      expect(c.structured.snapshot.answer, Rational.fromInt(5));
      expect(structured.answer.toString(), '2/3');
      expect(c.resultText, '2/3');
      expect(previousSettings.inputOutput, CalculatorInputOutput.mathMath);
      expect(c.session.snapshot.answer, Rational.fromInt(5));
    },
  );

  test(
    'SHIFT equals requests decimal and SD is harmless during editing/error',
    () {
      final c = CalculatorController()..pressId('KEY_1');
      final editing = c.structured.snapshot;
      c.pressId('KEY_SD');
      expect(c.structured.snapshot, same(editing));
      c.pressId('KEY_DIVIDE');
      c.pressId('KEY_8');
      c.pressId('KEY_SHIFT');
      c.pressId('KEY_EQUALS');
      expect(c.resultText, '0,125');
      calculate(c, '1/0');
      final error = c.structured.snapshot;
      c.pressId('KEY_SD');
      expect(c.structured.snapshot, same(error));
      expect(c.resultText, '');
    },
  );

  test('Fix rounding half away from zero and negative zero suppression', () {
    final c = CalculatorController();
    setting(c, ['number', 'fix', '2']);
    c.selectInputOutput(CalculatorInputOutput.linearDecimal);
    for (final pair in const [
      ['1.005', '1,01'],
      ['-1.005', '-1,01'],
      ['9.999', '10,00'],
      ['-0.0001', '0,00'],
    ]) {
      calculate(c, pair[0]);
      expect(c.resultText, pair[1]);
    }
    expect(c.displayStatus, contains('FIX'));
    setting(c, ['number', 'fix', '3']);
    calculate(c, '-0.0004');
    expect(c.resultText, '0,000');
  });

  test('Fix preserves integers beyond binary floating-point precision', () {
    final c = CalculatorController();
    setting(c, ['number', 'fix', '0']);
    c.selectInputOutput(CalculatorInputOutput.linearDecimal);
    calculate(c, '9007199254740993');
    expect(c.resultText, '9007199254740993');
  });

  test(
    'Sci carries, preserves requested zeros and Sci0 selects ten digits',
    () {
      final c = CalculatorController();
      setting(c, ['number', 'sci', '3']);
      c.selectInputOutput(CalculatorInputOutput.linearDecimal);
      for (final pair in const [
        ['9.999', '1,00×10^1'],
        ['-1/8', '-1,25×10^-1'],
        ['12', '1,20×10^1'],
        ['0', '0,00×10^0'],
      ]) {
        calculate(c, pair[0]);
        expect(c.resultText, pair[1]);
      }
      setting(c, ['number', 'sci', '0']);
      calculate(c, '1/3');
      expect(c.resultText, '3,333333333×10^-1');
    },
  );

  test('Norm thresholds one/two and periodic display rounding', () {
    final c = CalculatorController()
      ..selectInputOutput(CalculatorInputOutput.linearDecimal);
    for (final pair in const [
      ['1/100', '0,01'],
      ['1/1000', '1×10^-3'],
      ['10000000000', '1×10^10'],
      ['1/3', '0,3333333333'],
      ['0', '0'],
    ]) {
      calculate(c, pair[0]);
      expect(c.resultText, pair[1]);
    }
    setting(c, ['number', 'norm', '2']);
    calculate(c, '1/1000');
    expect(c.resultText, '0,001');
    calculate(c, '1/1000000000');
    expect(c.resultText, '0,000000001');
    calculate(c, '1/10000000000');
    expect(c.resultText, '1×10^-10');
  });

  test('Norm carry across the ten-digit boundary uses scientific notation', () {
    final c = CalculatorController()
      ..selectInputOutput(CalculatorInputOutput.linearDecimal);
    for (final norm in ['1', '2']) {
      setting(c, ['number', 'norm', norm]);
      for (final pair in const [
        ['9999999999.9', '1×10^10'],
        ['-9999999999.9', '-1×10^10'],
        ['9999999999.4', '9999999999'],
      ]) {
        calculate(c, pair[0]);
        final before = c.session.snapshot;
        expect(c.resultText, pair[1]);
        expect(c.session.snapshot, same(before));
        expect(before.answer, Rational.parseDecimal(pair[0]));
      }
    }
  });

  for (final io in [
    CalculatorInputOutput.mathMath,
    CalculatorInputOutput.linearLinear,
  ]) {
    test('SHIFT SD ${io.name} shares fraction preference with Setup', () {
      final c = CalculatorController()..selectInputOutput(io);
      final editingSettings = c.settings;
      c.pressId('KEY_SHIFT');
      c.pressId('KEY_SD');
      expect(c.settings, same(editingSettings));
      calculate(c, '-7/3');
      final answer = c.result;
      c.pressId('KEY_SD');
      expect(c.resultText, '-2,(3)');
      c.pressId('KEY_SHIFT');
      c.pressId('KEY_SD');
      expect(c.settings.fractionForm, CalculatorFractionForm.mixed);
      expect(c.resultText, '-2 1/3');
      expect(c.result, same(answer));
      final setup = CalculatorController()..selectInputOutput(io);
      setting(setup, ['fraction', 'mixed']);
      calculate(setup, '-7/3');
      expect(c.resultText, setup.resultText);
      c.openSetup();
      chooseVisible(c, 'fraction');
      expect(c.menuItems.first.selected, isTrue);
      c.pressId('KEY_AC');
      c.pressId('KEY_SHIFT');
      c.pressId('KEY_SD');
      expect(c.settings.fractionForm, CalculatorFractionForm.improper);
      expect(c.resultText, '-7/3');
      expect(c.result, same(answer));
      calculate(c, '1/0');
      final errorSettings = c.settings;
      c.pressId('KEY_SHIFT');
      c.pressId('KEY_SD');
      expect(c.settings, same(errorSettings));
      expect(c.phase, CalculatorPhase.error);
    });
  }

  test(
    'display-only rounding preserves exact Ans continuation and snapshots',
    () {
      final c = CalculatorController()
        ..selectInputOutput(CalculatorInputOutput.linearDecimal);
      setting(c, ['number', 'fix', '2']);
      calculate(c, '1/3');
      final before = c.session.snapshot;
      expect(c.resultText, '0,33');
      expect(c.session.snapshot, same(before));
      expect(before.answer, Rational(BigInt.one, BigInt.from(3)));
      c.pressId('KEY_MULTIPLY');
      c.pressId('KEY_3');
      c.pressId('KEY_EQUALS');
      expect(c.result, Rational.fromInt(1));
      expect(c.resultText, '1,00');
      expect(before.answer, Rational(BigInt.one, BigInt.from(3)));
    },
  );

  test('mixed fraction and thousands grouping affect display only', () {
    final c = CalculatorController();
    setting(c, ['fraction', 'mixed']);
    calculate(c, '-7/3');
    expect(c.resultText, '-2 1/3');
    setting(c, ['separator', 'on']);
    calculate(c, '1234567');
    expect(c.resultText, '1.234.567');
    c.pressId('KEY_SD');
    expect(c.resultText, '1.234.567');
    calculate(c, '-12345/2');
    expect(c.resultText, '-6.172 1/2');
    expect(c.result, Rational(BigInt.from(-12345), BigInt.two));
  });

  test(
    'settings store explicit choices without enabling unavailable modes',
    () {
      final c = CalculatorController();
      for (final path in const [
        ['angle', 'radians'],
        ['prefix', 'on'],
        ['complex', 'polar'],
        ['frequency', 'on'],
        ['sheetAuto', 'off'],
        ['sheetCell', 'value'],
        ['solutions', 'off'],
        ['table', 'f'],
        ['period', 'off'],
        ['qr', '3'],
        ['off', '60'],
      ]) {
        c.openSetup();
        chooseVisible(c, path[0]);
        expect(
          c.menuItems.every(
            (i) => path[0] == 'period'
                ? i.capabilityStatus == 'Verfügbar'
                : i.capabilityStatus.contains('Vorbereitung'),
          ),
          isTrue,
        );
        chooseVisible(c, path[1]);
        c.pressId('KEY_AC');
      }
      expect(c.settings.angleUnit, CalculatorAngleUnit.radians);
      expect(c.settings.engineeringPrefixes, isTrue);
      expect(c.settings.complexForm, CalculatorComplexForm.polar);
      expect(c.settings.frequency, isTrue);
      expect(c.settings.spreadsheetAutoCalculate, isFalse);
      expect(c.settings.spreadsheetShowFormula, isFalse);
      expect(c.settings.complexSolutions, isFalse);
      expect(c.settings.tableBothFunctions, isFalse);
      expect(c.settings.recurringDisplay, isFalse);
      expect(c.settings.qrVersion, 3);
      expect(c.settings.autoOffMinutes, 60);
      calculate(c, '2+3');
      expect(c.result, Rational.fromInt(5));
      expect(c.isKeyEnabled('KEY_SIN'), isFalse);
    },
  );

  test(
    'text preference and own calibrated contrast are bounded and persistent',
    () {
      final c = CalculatorController();
      setting(c, ['text', 'small']);
      expect(c.settings.smallText, isTrue);
      c.openSetup();
      chooseVisible(c, 'contrast');
      for (var i = 0; i < 20; i++) {
        c.pressId('KEY_RIGHT');
      }
      expect(c.settings.contrast, 10);
      for (var i = 0; i < 20; i++) {
        c.pressId('KEY_LEFT');
      }
      expect(c.settings.contrast, 0);
      expect(c.menuOpen, isTrue);
      c.pressId('KEY_AC');
      expect(c.menuOpen, isFalse);
      c.pressId('KEY_ON');
      expect(c.settings.contrast, 0);
    },
  );

  test('large decimal output raises a separate limit without changing result state', () {
    final c = CalculatorController()
      ..selectInputOutput(CalculatorInputOutput.linearDecimal);
    setting(c, ['number', 'fix', '0']);
    calculate(c, '(10^1000)^3');
    final before = c.session.snapshot;
    expect(before.phase, CalculatorPhase.result);
    expect(
      () => c.resultText,
      throwsA(
        isA<CalculatorException>().having(
          (e) => e.code,
          'code',
          CalculatorErrorCode.limit,
        ),
      ),
    );
    expect(c.session.snapshot, same(before));
    setting(c, ['number', 'sci', '3']);
    expect(c.resultText, '1,00×10^3000');
    expect(c.session.snapshot, same(before));
  });
}
