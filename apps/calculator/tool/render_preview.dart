import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fx991_calculator/main.dart';

// Visual QA helper, invoked explicitly; it is not part of the ordinary suite.
void main() {
  for (final structured in [false, true]) {
    testWidgets('render the calculator preview: structured=$structured', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(420, 1100);
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
          await File('build/unit_test_assets/fonts/MaterialIcons-Regular.otf')
              .readAsBytes(),
          fontFamily: 'MaterialIcons',
        );
      });
      const boundaryKey = ValueKey('preview-boundary');
      await tester.pumpWidget(
        const RepaintBoundary(key: boundaryKey, child: CalculatorApp()),
      );
      if (structured) {
        await tester.tap(find.byKey(const ValueKey('input-fractions')));
        await tester.pumpAndSettle();
      }
      for (final id
          in structured
              ? [
                  'KEY_FRACTION',
                  'KEY_1',
                  'KEY_RIGHT',
                  'KEY_3',
                  'KEY_RIGHT',
                  'KEY_ADD',
                  'KEY_FRACTION',
                  'KEY_1',
                  'KEY_RIGHT',
                  'KEY_6',
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
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('display-result'))).data,
        '1/2',
      );
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
          structured
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
