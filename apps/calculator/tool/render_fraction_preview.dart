import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:calculator_core/calculator_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fx991_calculator/presentation/editor/fraction_expression_view.dart';

// Explicit local visual QA, separate from normal widget tests and app routing.
void main() {
  testWidgets('render natural fraction view examples', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      final path =
          Platform.environment['PREVIEW_FONT'] ??
          'C:/Windows/Fonts/segoeui.ttf';
      await ui.loadFontFromList(
        Uint8List.fromList(await File(path).readAsBytes()),
        fontFamily: 'Roboto',
      );
    });
    void fraction(FractionEditor editor, String n, String d) {
      editor.insertFraction();
      editor.insertText(n);
      editor.moveRight();
      editor.insertText(d);
      editor.moveRight();
    }

    final empty = FractionEditor()..insertFraction();
    final sum = FractionEditor();
    fraction(sum, '1', '3');
    sum.insertText('+');
    fraction(sum, '1', '6');
    final nested = FractionEditor()
      ..insertFraction()
      ..insertText('1')
      ..moveRight();
    fraction(nested, '2', '3');
    nested.moveRight();
    nested.insertText('+');
    fraction(nested, '1', '2');
    final active = nested.snapshot;
    nested.moveLeft();
    nested.moveLeft();
    expect(sum.evaluate().toString(), '1/2');
    expect(nested.evaluate().toString(), '2');
    Widget example(
      String title,
      FractionEditorSnapshot snapshot, {
      bool cursor = true,
      String? result,
    }) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            FractionExpressionView(snapshot: snapshot, showCursor: cursor),
            if (result != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(result, style: const TextStyle(fontSize: 20)),
              ),
          ],
        ),
      ),
    );
    const boundaryKey = ValueKey('fraction-preview');
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            fontFamily: 'Roboto',
            colorSchemeSeed: Colors.indigo,
          ),
          home: Scaffold(
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Natürliche Bruchdarstellung',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  example('Leere Vorlage · Cursor im Zähler', empty.snapshot),
                  example(
                    'Exakte Summe',
                    sum.snapshot,
                    cursor: false,
                    result: '= 1/2',
                  ),
                  example(
                    'Verschachtelte Brüche',
                    active,
                    cursor: false,
                    result: '= 2',
                  ),
                  example(
                    'Cursor im Nenner des zweiten Bruchs',
                    nested.snapshot,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(boundaryKey),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('../../build/reports/fraction-view.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
  });
}
