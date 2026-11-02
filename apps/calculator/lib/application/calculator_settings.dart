/// Session-only preferences. Pending calculation modes do not gain numerical
/// capabilities merely because their preferences can already be stored.
enum CalculatorInputOutput {
  mathMath,
  mathDecimal,
  linearLinear,
  linearDecimal,
}

enum CalculatorAngleUnit { degrees, radians, gradians }

enum CalculatorNumberFormat { fix, sci, norm }

enum CalculatorFractionForm { improper, mixed }

enum CalculatorComplexForm { rectangular, polar }

final class CalculatorSettings {
  final CalculatorInputOutput inputOutput;
  final CalculatorAngleUnit angleUnit;
  final CalculatorNumberFormat numberFormat;
  final int fixDigits, sciDigits, norm;
  final bool engineeringPrefixes;
  final CalculatorFractionForm fractionForm;
  final CalculatorComplexForm complexForm;
  final bool frequency, spreadsheetAutoCalculate, spreadsheetShowFormula;
  final bool complexSolutions, tableBothFunctions, recurringDisplay;
  final bool thousandsSeparator, smallText;
  final int qrVersion, autoOffMinutes, contrast;

  const CalculatorSettings({
    this.inputOutput = CalculatorInputOutput.mathMath,
    this.angleUnit = CalculatorAngleUnit.degrees,
    this.numberFormat = CalculatorNumberFormat.norm,
    this.fixDigits = 3,
    this.sciDigits = 3,
    this.norm = 1,
    this.engineeringPrefixes = false,
    this.fractionForm = CalculatorFractionForm.improper,
    this.complexForm = CalculatorComplexForm.rectangular,
    this.frequency = false,
    this.spreadsheetAutoCalculate = true,
    this.spreadsheetShowFormula = true,
    this.complexSolutions = true,
    this.tableBothFunctions = true,
    this.recurringDisplay = true,
    this.thousandsSeparator = false,
    this.smallText = false,
    this.qrVersion = 11,
    this.autoOffMinutes = 10,
    this.contrast = 5,
  }) : assert(fixDigits >= 0 && fixDigits <= 9),
       assert(sciDigits >= 0 && sciDigits <= 9),
       assert(norm == 1 || norm == 2),
       assert(qrVersion == 3 || qrVersion == 11),
       assert(autoOffMinutes == 10 || autoOffMinutes == 60),
       assert(contrast >= 0 && contrast <= 10);

  bool get fractions =>
      inputOutput == CalculatorInputOutput.mathMath ||
      inputOutput == CalculatorInputOutput.mathDecimal;
  bool get decimalOutput =>
      inputOutput == CalculatorInputOutput.mathDecimal ||
      inputOutput == CalculatorInputOutput.linearDecimal;

  CalculatorSettings copyWith({
    CalculatorInputOutput? inputOutput,
    CalculatorAngleUnit? angleUnit,
    CalculatorNumberFormat? numberFormat,
    int? fixDigits,
    int? sciDigits,
    int? norm,
    bool? engineeringPrefixes,
    CalculatorFractionForm? fractionForm,
    CalculatorComplexForm? complexForm,
    bool? frequency,
    bool? spreadsheetAutoCalculate,
    bool? spreadsheetShowFormula,
    bool? complexSolutions,
    bool? tableBothFunctions,
    bool? recurringDisplay,
    bool? thousandsSeparator,
    bool? smallText,
    int? qrVersion,
    int? autoOffMinutes,
    int? contrast,
  }) => CalculatorSettings(
    inputOutput: inputOutput ?? this.inputOutput,
    angleUnit: angleUnit ?? this.angleUnit,
    numberFormat: numberFormat ?? this.numberFormat,
    fixDigits: fixDigits ?? this.fixDigits,
    sciDigits: sciDigits ?? this.sciDigits,
    norm: norm ?? this.norm,
    engineeringPrefixes: engineeringPrefixes ?? this.engineeringPrefixes,
    fractionForm: fractionForm ?? this.fractionForm,
    complexForm: complexForm ?? this.complexForm,
    frequency: frequency ?? this.frequency,
    spreadsheetAutoCalculate:
        spreadsheetAutoCalculate ?? this.spreadsheetAutoCalculate,
    spreadsheetShowFormula:
        spreadsheetShowFormula ?? this.spreadsheetShowFormula,
    complexSolutions: complexSolutions ?? this.complexSolutions,
    tableBothFunctions: tableBothFunctions ?? this.tableBothFunctions,
    recurringDisplay: recurringDisplay ?? this.recurringDisplay,
    thousandsSeparator: thousandsSeparator ?? this.thousandsSeparator,
    smallText: smallText ?? this.smallText,
    qrVersion: qrVersion ?? this.qrVersion,
    autoOffMinutes: autoOffMinutes ?? this.autoOffMinutes,
    contrast: contrast ?? this.contrast,
  );
}
