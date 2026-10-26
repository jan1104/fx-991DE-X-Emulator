import 'package:calculator_core/calculator_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fx991_calculator/application/key_layout.dart';
import 'package:fx991_calculator/main.dart';

Finder button(String id) => find.byKey(ValueKey(id));

String expression(WidgetTester tester) => tester
    .widget<Text>(find.byKey(const ValueKey('display-expression')))
    .textSpan!
    .toPlainText();

String result(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const ValueKey('display-result'))).data!;

String answer(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const ValueKey('display-answer'))).data!;

Future<void> pumpCalculator(
  WidgetTester tester, {
  Size size = const Size(800, 900),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const CalculatorApp());
  await tester.pumpAndSettle();
}

Future<void> tapKey(WidgetTester tester, String id) async {
  final target = button(id);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> tapKeys(WidgetTester tester, List<String> ids) async {
  for (final id in ids) {
    await tapKey(tester, id);
  }
}

Future<void> hardwareKey(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  String? character,
}) async {
  await tester.sendKeyDownEvent(key, character: character);
  await tester.pump();
  await tester.sendKeyUpEvent(key);
  await tester.pump();
}

void main() {
  testWidgets('painted key surfaces remain usable on a narrow phone', (
    tester,
  ) async {
    await pumpCalculator(tester, size: const Size(320, 568));
    for (final id in ['KEY_LEFT', 'KEY_7', 'KEY_EQUALS']) {
      final material = find
          .descendant(of: button(id), matching: find.byType(Material))
          .first;
      final size = tester.getSize(material);
      expect(size.height, greaterThanOrEqualTo(48), reason: id);
      expect(size.width, greaterThanOrEqualTo(44), reason: id);
    }
  });
  testWidgets('renders exactly 50 unique keys, 25 enabled and 25 disabled', (
    tester,
  ) async {
    await pumpCalculator(tester);
    final definitions = calculatorRows.expand((row) => row).toList();
    expect(definitions, hasLength(50));
    expect(definitions.map((key) => key.id).toSet(), hasLength(50));
    var enabled = 0;
    var disabled = 0;
    for (final definition in definitions) {
      final finder = button(definition.id);
      expect(finder, findsOneWidget);
      final widget = tester.widget<FilledButton>(finder);
      final supported = CalculatorKey.fromId(definition.id) != null;
      expect(widget.onPressed != null, supported, reason: definition.id);
      if (widget.onPressed == null) {
        disabled++;
      } else {
        enabled++;
      }
    }
    expect(enabled, 25);
    expect(disabled, 25);
    expect(find.byType(FilledButton), findsNWidgets(50));
    expect(expression(tester), '│');
    expect(result(tester), '');
    expect(answer(tester), 'Ans: 0');
    expect(tester.takeException(), isNull);
  });

  testWidgets('one button tap inserts exactly one digit or operator', (
    tester,
  ) async {
    await pumpCalculator(tester);
    await tapKey(tester, 'KEY_1');
    expect(expression(tester), '1│');
    await tapKey(tester, 'KEY_ADD');
    expect(expression(tester), '1+│');
    await tapKey(tester, 'KEY_2');
    expect(expression(tester), '1+2│');
    await tapKey(tester, 'KEY_EQUALS');
    expect(expression(tester), '1+2');
    expect(result(tester), '3');
    expect(answer(tester), 'Ans: 3');
  });

  testWidgets('button entry computes exact fractions', (tester) async {
    await pumpCalculator(tester);
    await tapKeys(tester, [
      'KEY_1',
      'KEY_DIVIDE',
      'KEY_3',
      'KEY_ADD',
      'KEY_1',
      'KEY_DIVIDE',
      'KEY_6',
      'KEY_EQUALS',
    ]);
    expect(result(tester), '1/2');
    expect(answer(tester), 'Ans: 1/2');
  });

  testWidgets(
    'operator after result continues with exact Ans and AC retains it',
    (tester) async {
      await pumpCalculator(tester);
      await tapKeys(tester, ['KEY_1', 'KEY_DIVIDE', 'KEY_3', 'KEY_EQUALS']);
      await tapKey(tester, 'KEY_MULTIPLY');
      expect(expression(tester), 'Ans*│');
      await tapKeys(tester, ['KEY_6', 'KEY_EQUALS']);
      expect(result(tester), '2');
      await tapKey(tester, 'KEY_AC');
      expect(expression(tester), '│');
      expect(result(tester), '');
      expect(answer(tester), 'Ans: 2');
      await tapKeys(tester, ['KEY_ANS', 'KEY_EQUALS']);
      expect(result(tester), '2');
    },
  );

  testWidgets('division error can be restored at its position and corrected', (
    tester,
  ) async {
    await pumpCalculator(tester);
    await tapKeys(tester, ['KEY_1', 'KEY_DIVIDE', 'KEY_0', 'KEY_EQUALS']);
    expect(result(tester), 'Mathem. Fehler');
    expect(expression(tester), '1/0');
    await tapKey(tester, 'KEY_9');
    expect(expression(tester), '1/0');
    expect(result(tester), 'Mathem. Fehler');
    await tapKey(tester, 'KEY_LEFT');
    expect(expression(tester), '1│/0');
    expect(result(tester), '');
    await tapKeys(tester, [
      'KEY_RIGHT',
      'KEY_RIGHT',
      'KEY_DEL',
      'KEY_2',
      'KEY_EQUALS',
    ]);
    expect(result(tester), '1/2');
    expect(answer(tester), 'Ans: 1/2');
  });

  testWidgets('AC clears an error without losing the previous answer', (
    tester,
  ) async {
    await pumpCalculator(tester);
    await tapKeys(tester, ['KEY_7', 'KEY_EQUALS']);
    await tapKeys(tester, ['KEY_1', 'KEY_DIVIDE', 'KEY_0', 'KEY_EQUALS']);
    expect(result(tester), 'Mathem. Fehler');
    expect(answer(tester), 'Ans: 7');
    await tapKey(tester, 'KEY_AC');
    expect(expression(tester), '│');
    expect(result(tester), '');
    expect(answer(tester), 'Ans: 7');
  });

  testWidgets('cursor movement and DEL remove the token left of the caret', (
    tester,
  ) async {
    await pumpCalculator(tester);
    await tapKeys(tester, ['KEY_1', 'KEY_2', 'KEY_3', 'KEY_LEFT']);
    expect(expression(tester), '12│3');
    await tapKey(tester, 'KEY_DEL');
    expect(expression(tester), '1│3');
    await tapKeys(tester, ['KEY_4', 'KEY_EQUALS']);
    expect(result(tester), '143');
  });

  testWidgets('Ans is displayed and deleted as one logical token', (
    tester,
  ) async {
    await pumpCalculator(tester);
    await tapKeys(tester, ['KEY_ANS', 'KEY_LEFT']);
    expect(expression(tester), '│Ans');
    await tapKey(tester, 'KEY_RIGHT');
    expect(expression(tester), 'Ans│');
    await tapKey(tester, 'KEY_DEL');
    expect(expression(tester), '│');
  });

  testWidgets('disabled SHIFT remains visible and has no effect', (
    tester,
  ) async {
    await pumpCalculator(tester);
    await tapKeys(tester, ['KEY_1', 'KEY_2']);
    expect(tester.widget<FilledButton>(button('KEY_SHIFT')).onPressed, isNull);
    await tapKey(tester, 'KEY_SHIFT');
    expect(expression(tester), '12│');
    expect(result(tester), '');
    expect(answer(tester), 'Ans: 0');
  });

  testWidgets('hardware Down inserts once and Up and Repeat insert nothing', (
    tester,
  ) async {
    await pumpCalculator(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.digit1, character: '1');
    await tester.pump();
    expect(expression(tester), '1│');
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.digit1, character: '1');
    await tester.pump();
    expect(expression(tester), '1│');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.digit1);
    await tester.pump();
    expect(expression(tester), '1│');
    await hardwareKey(tester, LogicalKeyboardKey.digit2, character: '2');
    expect(expression(tester), '12│');
  });

  testWidgets('hardware arithmetic, Enter, Backspace and Escape are wired', (
    tester,
  ) async {
    await pumpCalculator(tester);
    await hardwareKey(tester, LogicalKeyboardKey.digit1, character: '1');
    await hardwareKey(tester, LogicalKeyboardKey.equal, character: '+');
    await hardwareKey(tester, LogicalKeyboardKey.digit2, character: '2');
    await hardwareKey(tester, LogicalKeyboardKey.enter);
    expect(result(tester), '3');
    await hardwareKey(tester, LogicalKeyboardKey.escape);
    expect(expression(tester), '│');
    expect(answer(tester), 'Ans: 3');
    await hardwareKey(tester, LogicalKeyboardKey.digit4, character: '4');
    await hardwareKey(tester, LogicalKeyboardKey.digit5, character: '5');
    await hardwareKey(tester, LogicalKeyboardKey.backspace);
    expect(expression(tester), '4│');
  });

  testWidgets(
    'Ctrl plus a digit is ignored and releasing Ctrl restores input',
    (tester) async {
      await pumpCalculator(tester);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await hardwareKey(tester, LogicalKeyboardKey.digit1, character: '1');
      expect(expression(tester), '│');
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      await hardwareKey(tester, LogicalKeyboardKey.digit1, character: '1');
      expect(expression(tester), '1│');
    },
  );

  testWidgets('Enter with a button focused executes instead of activating it', (
    tester,
  ) async {
    await pumpCalculator(tester);
    await tapKeys(tester, ['KEY_1', 'KEY_ADD', 'KEY_2']);
    final buttonLabel = tester.element(
      find.descendant(of: button('KEY_2'), matching: find.text('2')),
    );
    final focusedButton = Focus.of(buttonLabel);
    focusedButton.requestFocus();
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, same(focusedButton));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(expression(tester), '1+2');
    expect(result(tester), '3');
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(expression(tester), '1+2');
    expect(result(tester), '3');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(expression(tester), '1+2');
    expect(result(tester), '3');
    expect(answer(tester), 'Ans: 3');
    // A second physical press is a separate event; result '=' is idempotent.
    await hardwareKey(tester, LogicalKeyboardKey.enter);
    expect(result(tester), '3');
    expect(expression(tester), '1+2');
  });

  for (final size in [const Size(320, 568), const Size(800, 600)]) {
    testWidgets(
      'layout ${size.width}x${size.height} scrolls without overflow',
      (tester) async {
        await pumpCalculator(tester, size: size);
        expect(tester.takeException(), isNull);
        await tapKeys(tester, ['KEY_1', 'KEY_ADD', 'KEY_2', 'KEY_EQUALS']);
        expect(result(tester), '3');
        await tester.ensureVisible(button('KEY_EQUALS'));
        await tester.pumpAndSettle();
        expect(button('KEY_EQUALS').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(button('KEY_SHIFT'));
        await tester.pumpAndSettle();
        expect(button('KEY_SHIFT').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
