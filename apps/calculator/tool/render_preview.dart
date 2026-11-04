import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fx991_calculator/main.dart';

// Visual QA helper, invoked explicitly; it is not part of the ordinary suite.
void main() {
  for (final scenario in [
    'linear',
    'fractions',
    'error',
    'capture',
    'group',
    'square',
    'cube',
    'percent',
    'factorial',
    'permutation',
    'combination',
    'absolute',
    'absolute-fraction',
    'absolute-error',
    'front',
    'settings',
    'periodic',
    'periodic-negative',
  ]) {
    final structured = scenario != 'linear';
    final error = scenario == 'error';
    final capture = scenario == 'capture';
    final group = scenario == 'group';
    final square = scenario == 'square';
    final cube = scenario == 'cube';
    final percent = scenario == 'percent';
    final factorial = scenario == 'factorial';
    final permutation = scenario == 'permutation';
    final combinatorics = permutation || scenario == 'combination';
    final absolute = scenario.startsWith('absolute');
    final absoluteFraction = scenario == 'absolute-fraction';
    final absoluteError = scenario == 'absolute-error';
    final periodic = scenario.startsWith('periodic');
    final negativePeriod = scenario == 'periodic-negative';
    testWidgets('render the calculator preview: $scenario', (tester) async {
      tester.view.physicalSize = const Size(420, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      // Local visual QA only: load a system font without bundling it with the app.
      // Normal widget tests deliberately keep the deterministic Flutter test font.
      await tester.runAsync(() async {
        final fontPath =
            Platform.environment['PREVIEW_FONT'] ??
            'C:/Windows/Fonts/segoeui.ttf';
        final bytes = await File(fontPath).readAsBytes();
        await ui.loadFontFromList(
          Uint8List.fromList(bytes),
          fontFamily: 'Roboto',
        );
        await ui.loadFontFromList(
          Uint8List.fromList(bytes),
          fontFamily: 'monospace',
        );
        await ui.loadFontFromList(
          await File('build/unit_test_assets/fonts/MaterialIcons-Regular.otf')
              .readAsBytes(),
          fontFamily: 'MaterialIcons',
        );
      });
      const boundaryKey = ValueKey('preview-boundary');
      await tester.pumpWidget(
        const RepaintBoundary(key: boundaryKey, child: CalculatorApp()),
      );
      if (!structured) {
        await tester.ensureVisible(find.byKey(const ValueKey('input-linear')));
        await tester.tap(find.byKey(const ValueKey('input-linear')));
        await tester.pumpAndSettle();
      }
      if (structured) {
        await tester.tap(find.byKey(const ValueKey('input-fractions')));
        await tester.pumpAndSettle();
      }
      for (final id
          in absolute
              ? [
                  'KEY_SHIFT',
                  'KEY_LPAREN',
                  if (absoluteFraction) ...[
                    'KEY_NEGATE',
                    'KEY_FRACTION',
                    'KEY_1',
                    'KEY_DOWN',
                    'KEY_2',
                    'KEY_RIGHT',
                    'KEY_RIGHT',
                  ] else if (!absoluteError) ...[
                    'KEY_2',
                    'KEY_SUBTRACT',
                    'KEY_7',
                    'KEY_RIGHT',
                    'KEY_MULTIPLY',
                    'KEY_2',
                  ],
                  'KEY_EQUALS',
                ]
              : combinatorics
              ? [
                  'KEY_1',
                  'KEY_0',
                  'KEY_SHIFT',
                  permutation ? 'KEY_MULTIPLY' : 'KEY_DIVIDE',
                  'KEY_4',
                  'KEY_EQUALS',
                ]
              : factorial
              ? [
                  'KEY_LPAREN',
                  'KEY_5',
                  'KEY_ADD',
                  'KEY_3',
                  'KEY_RPAREN',
                  'KEY_SHIFT',
                  'KEY_RECIPROCAL',
                  'KEY_EQUALS',
                ]
              : percent
              ? [
                  'KEY_1',
                  'KEY_5',
                  'KEY_0',
                  'KEY_MULTIPLY',
                  'KEY_2',
                  'KEY_0',
                  'KEY_SHIFT',
                  'KEY_ANS',
                  'KEY_EQUALS',
                ]
              : cube
              ? [
                  'KEY_3',
                  'KEY_SHIFT',
                  'KEY_SQUARE',
                  'KEY_SHIFT',
                  'KEY_SQUARE',
                  'KEY_EQUALS',
                ]
              : periodic
              ? [
                  if (negativePeriod) 'KEY_NEGATE',
                  'KEY_FRACTION',
                  'KEY_1',
                  'KEY_DOWN',
                  if (negativePeriod) ...['KEY_1', 'KEY_2'] else 'KEY_6',
                  'KEY_EQUALS',
                  'KEY_SD',
                ]
              : square
              ? ['KEY_3', 'KEY_SQUARE', 'KEY_SQUARE', 'KEY_EQUALS']
              : group
              ? [
                  'KEY_LPAREN',
                  'KEY_2',
                  'KEY_ADD',
                  'KEY_4',
                  'KEY_RPAREN',
                  'action-wrap-fraction',
                  'KEY_3',
                  'KEY_EQUALS',
                ]
              : capture
              ? [
                  'KEY_1',
                  'KEY_2',
                  'action-wrap-fraction',
                  'KEY_3',
                  'KEY_EQUALS',
                ]
              : error
              ? [
                  'KEY_FRACTION',
                  'KEY_1',
                  'KEY_RIGHT',
                  'KEY_FRACTION',
                  'KEY_2',
                  'KEY_RIGHT',
                  'KEY_0',
                  'KEY_RIGHT',
                  'KEY_RIGHT',
                  'KEY_EQUALS',
                ]
              : structured
              ? [
                  'KEY_FRACTION',
                  'KEY_1',
                  'KEY_DOWN',
                  'KEY_3',
                  'KEY_RIGHT',
                  'KEY_ADD',
                  'KEY_FRACTION',
                  'KEY_1',
                  'KEY_RIGHT',
                  'KEY_6',
                  'KEY_UP',
                  'KEY_DOWN',
                  'KEY_RIGHT',
                  'KEY_EQUALS',
                ]
              : [
                  'KEY_1',
                  'KEY_DIVIDE',
                  'KEY_3',
                  'KEY_ADD',
                  'KEY_1',
                  'KEY_DIVIDE',
                  'KEY_6',
                  'KEY_EQUALS',
                ]) {
        await tester.ensureVisible(find.byKey(ValueKey(id)));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey(id)));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      final output = tester.widget<Text>(
        find.byKey(const ValueKey('display-result')),
      );
      expect(
        output.data ?? output.textSpan!.toPlainText(),
        absolute
            ? absoluteError
                  ? 'Syntaxfehler'
                  : absoluteFraction
                  ? '1/2'
                  : '10'
            : combinatorics
            ? permutation
                  ? '5040'
                  : '210'
            : factorial
            ? '40320'
            : percent
            ? '30'
            : cube
            ? '19683'
            : periodic
            ? negativePeriod
                  ? '-0,083'
                  : '0,16'
            : square
            ? '81'
            : group
            ? '2'
            : capture
            ? '4'
            : error
            ? 'Mathem. Fehler'
            : '1/2',
      );
      if (periodic) {
        final span = output.textSpan! as TextSpan;
        final repeating = span.children!.last as TextSpan;
        expect(repeating.style!.decoration, TextDecoration.overline);
      }
      if (error || absoluteError) {
        expect(find.byKey(const ValueKey('formula-error')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('display-error-help')),
          findsOneWidget,
        );
      }
      if (scenario == 'settings') {
        await tester.tap(find.byKey(const ValueKey('toolbar-settings')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('calculator-menu')), findsOneWidget);
      }
      await tester.ensureVisible(
        find.byKey(const ValueKey('calculator-display')),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(boundaryKey),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File(
          absolute
              ? '../../build/reports/calculator-$scenario.png'
              : combinatorics
              ? '../../build/reports/calculator-$scenario.png'
              : factorial
              ? '../../build/reports/calculator-factorial.png'
              : percent
              ? '../../build/reports/calculator-percent.png'
              : cube
              ? '../../build/reports/calculator-cube.png'
              : periodic
              ? '../../build/reports/calculator-$scenario.png'
              : scenario == 'settings'
              ? '../../build/reports/calculator-settings.png'
              : scenario == 'front'
              ? '../../build/reports/calculator-front.png'
              : square
              ? '../../build/reports/calculator-square.png'
              : group
              ? '../../build/reports/calculator-group-capture.png'
              : capture
              ? '../../build/reports/calculator-capture.png'
              : error
              ? '../../build/reports/calculator-error.png'
              : structured
              ? '../../build/reports/calculator-fractions.png'
              : '../../build/reports/calculator-prototype.png',
        );
        await file.parent.create(recursive: true);
        await file.writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    });
  }
}
