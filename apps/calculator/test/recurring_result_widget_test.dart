import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fx991_calculator/main.dart';
import 'package:fx991_calculator/presentation/calculator/recurring_result_view.dart';

Finder keyed(String id) => find.byKey(ValueKey(id));

Future<void> boot(
  WidgetTester tester, {
  bool fractions = true,
  Size size = const Size(800, 1000),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(const CalculatorApp());
  await tester.pumpAndSettle();
  if (!fractions) await tap(tester, 'input-linear');
}

Future<void> tap(WidgetTester tester, String id) async {
  await tester.ensureVisible(keyed(id));
  await tester.pumpAndSettle();
  await tester.tap(keyed(id));
  await tester.pumpAndSettle();
}

Future<void> sequence(WidgetTester tester, List<String> ids) async {
  for (final id in ids) {
    await tap(tester, id);
  }
}

Future<void> calculate(
  WidgetTester tester,
  String numerator,
  String denominator,
) async {
  await tap(tester, 'KEY_AC');
  if (numerator.startsWith('-')) await tap(tester, 'KEY_NEGATE');
  for (final digit in numerator.replaceFirst('-', '').split('')) {
    await tap(tester, 'KEY_$digit');
  }
  await tap(tester, 'KEY_DIVIDE');
  for (final digit in denominator.split('')) {
    await tap(tester, 'KEY_$digit');
  }
  await tap(tester, 'KEY_EQUALS');
}

Future<void> openSetting(WidgetTester tester, String id) async {
  await sequence(tester, ['KEY_SHIFT', 'KEY_MENU']);
  for (
    var step = 0;
    keyed('setup-item-$id').evaluate().isEmpty && step < 17;
    step++
  ) {
    await tap(tester, 'menu-page-down');
  }
  await tap(tester, 'setup-item-$id');
}

Future<void> chooseToggle(
  WidgetTester tester,
  String setting,
  bool value,
) async {
  await openSetting(tester, setting);
  await tap(tester, value ? 'setup-item-on' : 'setup-item-off');
  await tap(tester, 'menu-close');
}

Text result(WidgetTester tester) =>
    tester.widget<Text>(keyed('display-result'));
String answer(WidgetTester tester) =>
    tester.widget<Text>(keyed('display-answer')).data!;

void expectPeriod(
  WidgetTester tester,
  String prefix,
  String period,
  String canonical,
) {
  final view = tester.widget<RecurringResultView>(
    find.byType(RecurringResultView),
  );
  expect(view.periodPrefix, prefix);
  expect(view.repeatingDigits, period);
  expect(view.canonicalText, canonical);
  final output = result(tester);
  expect(output.data, isNull);
  final span = output.textSpan! as TextSpan;
  expect(span.children, hasLength(2));
  final start = span.children![0] as TextSpan;
  final repeat = span.children![1] as TextSpan;
  expect(start.text, prefix);
  expect(start.style?.decoration, isNull);
  expect(repeat.text, period);
  expect(repeat.style!.decoration, TextDecoration.overline);
  expect(span.toPlainText(), '$prefix$period');
}

void main() {
  for (final (prefix, period, canonical) in [
    ('0,', '3', '0,(3)'),
    ('0,0', '1', '0,0(1)'),
    ('-0,08', '3', '-0,08(3)'),
    ('1.234,', '09', '1.234,(09)'),
  ]) {
    testWidgets('only the supplied period receives an overline: $canonical', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RecurringResultView(
                periodPrefix: prefix,
                repeatingDigits: period,
                canonicalText: canonical,
                style: const TextStyle(fontSize: 30),
              ),
            ),
          ),
        );
        expectPeriod(tester, prefix, period, canonical);
        final spoken = find.bySemanticsLabel('$prefix Periode $period');
        expect(spoken, findsOneWidget);
        expect(tester.getSemantics(spoken).getSemanticsData().value, canonical);
        expect(keyed('display-result'), findsOneWidget);
      } finally {
        semantics.dispose();
      }
    });
  }

  for (final fractions in [false, true]) {
    final mode = fractions ? 'Math' : 'Linear';
    testWidgets(
      '$mode S⇔D cycles exact fraction, period, rounded and fraction',
      (tester) async {
        await boot(tester, fractions: fractions);
        await calculate(tester, '1', '6');
        expect(result(tester).data, '1/6');
        await tap(tester, 'KEY_SD');
        expectPeriod(tester, '0,1', '6', '0,1(6)');
        expect(answer(tester), 'Ans: 1/6');
        await tap(tester, 'KEY_SD');
        expect(result(tester).data, '0,1666666667');
        expect(find.byType(RecurringResultView), findsNothing);
        await tap(tester, 'KEY_SD');
        expect(result(tester).data, '1/6');
      },
    );

    for (final (n, d, prefix, period, canonical) in [
      ('-1', '12', '-0,08', '3', '-0,08(3)'),
      ('1', '90', '0,0', '1', '0,0(1)'),
    ]) {
      testWidgets('$mode preserves sign and zero preperiod for $n/$d', (
        tester,
      ) async {
        await boot(tester, fractions: fractions);
        await calculate(tester, n, d);
        await tap(tester, 'KEY_SD');
        expectPeriod(tester, prefix, period, canonical);
        expect(answer(tester), 'Ans: $n/$d');
      });
    }

    testWidgets(
      '$mode finite values and integers retain plain Text and two states',
      (tester) async {
        await boot(tester, fractions: fractions);
        for (final (n, d, fraction, decimal) in [
          ('1', '8', '1/8', '0,125'),
          ('7', '1', '7', '7'),
        ]) {
          await calculate(tester, n, d);
          await tap(tester, 'KEY_SD');
          expect(result(tester).data, decimal);
          expect(find.byType(RecurringResultView), findsNothing);
          await tap(tester, 'KEY_SD');
          expect(result(tester).data, fraction);
        }
      },
    );

    testWidgets(
      '$mode Period Aus normalizes an existing period and disables the third state',
      (tester) async {
        await boot(tester, fractions: fractions);
        await calculate(tester, '1', '6');
        await tap(tester, 'KEY_SD');
        expect(find.byType(RecurringResultView), findsOneWidget);
        await chooseToggle(tester, 'period', false);
        expect(result(tester).data, '0,1666666667');
        await tap(tester, 'KEY_SD');
        expect(result(tester).data, '1/6');
        await tap(tester, 'KEY_SD');
        expect(result(tester).data, '0,1666666667');
        expect(find.byType(RecurringResultView), findsNothing);
        expect(answer(tester), 'Ans: 1/6');
      },
    );

    testWidgets(
      '$mode long period falls back visibly and next S⇔D remains usable',
      (tester) async {
        await boot(tester, fractions: fractions);
        await calculate(tester, '1', '109');
        await tap(tester, 'KEY_SD');
        expect(result(tester).data, '1/109');
        expect(find.byType(RecurringResultView), findsNothing);
        expect(keyed('display-period-limit'), findsOneWidget);
        expect(answer(tester), 'Ans: 1/109');
        await tap(tester, 'KEY_SD');
        expect(result(tester).data, '9,174311927×10^-3');
        expect(keyed('display-period-limit'), findsNothing);
        await tap(tester, 'KEY_SD');
        expect(result(tester).data, '1/109');
      },
    );

    testWidgets(
      '$mode continuing from a period uses the exact Ans and clears decoration',
      (tester) async {
        await boot(tester, fractions: fractions);
        await calculate(tester, '1', '3');
        await tap(tester, 'KEY_SD');
        await sequence(tester, ['KEY_MULTIPLY', 'KEY_3', 'KEY_EQUALS']);
        expect(result(tester).data, '1');
        expect(answer(tester), 'Ans: 1');
        expect(find.byType(RecurringResultView), findsNothing);
        expect(keyed('display-period-limit'), findsNothing);
      },
    );
  }

  for (final format in ['fix', 'sci']) {
    testWidgets(
      '$format suppresses period display while keeping an exact result',
      (tester) async {
        await boot(tester);
        await calculate(tester, '1', '6');
        await tap(tester, 'KEY_SD');
        await openSetting(tester, 'number');
        await tap(tester, 'setup-item-$format');
        await tap(tester, 'setup-item-3');
        await tap(tester, 'menu-close');
        expect(find.byType(RecurringResultView), findsNothing);
        expect(
          tester.widget<Text>(keyed('display-status')).data,
          contains(format.toUpperCase()),
        );
        expect(answer(tester), 'Ans: 1/6');
        await tap(tester, 'KEY_SD');
        expect(result(tester).data, '1/6');
        await tap(tester, 'KEY_SD');
        expect(result(tester).data, isNot('1/6'));
        expect(find.byType(RecurringResultView), findsNothing);
      },
    );
  }

  testWidgets(
    'focused S⇔D does not cycle again on mapped Enter or Enter repeat',
    (tester) async {
      await boot(tester);
      await calculate(tester, '1', '6');
      await tap(tester, 'KEY_SD');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expectPeriod(tester, '0,1', '6', '0,1(6)');
    },
  );

  testWidgets(
    'grouped prefix and contrast remain consistent with canonical semantics',
    (tester) async {
      await boot(tester);
      await chooseToggle(tester, 'separator', true);
      await calculate(tester, '3703', '3');
      await tap(tester, 'KEY_SD');
      expectPeriod(tester, '1.234,', '3', '1.234,(3)');
      final before = result(tester).style!.color;
      await openSetting(tester, 'contrast');
      await tap(tester, 'KEY_RIGHT');
      await tap(tester, 'menu-close');
      expect(result(tester).style!.color, isNot(before));
      expectPeriod(tester, '1.234,', '3', '1.234,(3)');
      expect(answer(tester), 'Ans: 3703/3');
    },
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets('96-digit overline scrolls at 320px with text scale $scale', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await boot(tester, size: const Size(320, 568));
      await calculate(tester, '1', '97');
      await tap(tester, 'KEY_SD');
      final view = tester.widget<RecurringResultView>(
        find.byType(RecurringResultView),
      );
      expect(view.periodPrefix, '0,');
      expect(view.repeatingDigits.length, 96);
      expect(
        find.ancestor(
          of: keyed('display-result'),
          matching: find.byType(SingleChildScrollView),
        ),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
      expect(answer(tester), 'Ans: 1/97');
    });
  }
}
