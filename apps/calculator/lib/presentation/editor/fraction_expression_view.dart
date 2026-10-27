import 'dart:math' as math;

import 'package:calculator_core/calculator_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Read-only natural fraction view. Editing and calculator phases stay outside.
class FractionExpressionView extends StatelessWidget {
  final FractionEditorSnapshot snapshot;
  final bool showCursor;
  final double fontSize;

  const FractionExpressionView({
    super.key,
    required this.snapshot,
    this.showCursor = true,
    this.fontSize = 24,
  }) : assert(fontSize > 0 && fontSize < double.infinity);

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    final scaledSize = MediaQuery.textScalerOf(context).scale(fontSize);
    final cursorPath = snapshot.cursor.path.fold(
      'root',
      (path, step) =>
          '$path/f${step.nodeIndex}'
          '${step.field == FractionField.numerator ? 'n' : 'd'}',
    );
    return Semantics(
      container: true,
      label: 'Eingabe: ${_describe(snapshot.root)}',
      child: SingleChildScrollView(
        primary: false,
        child: SingleChildScrollView(
          key: const ValueKey('formula-scroll'),
          scrollDirection: Axis.horizontal,
          primary: false,
          child: ExcludeSemantics(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: DefaultTextStyle.merge(
                style: TextStyle(fontSize: fontSize, color: color),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: _sequence(
                    snapshot.root,
                    'root',
                    cursorPath,
                    scaledSize,
                    color,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sequence(
    EditorSequence sequence,
    String path,
    String cursorPath,
    double scaledSize,
    Color color,
  ) {
    Widget caret() => Baseline(
      baseline: scaledSize,
      baselineType: TextBaseline.alphabetic,
      child: SizedBox(
        key: const ValueKey('formula-cursor'),
        width: 3,
        height: scaledSize * 1.25,
        child: ColoredBox(color: color),
      ),
    );
    final children = <Widget>[];
    final active = showCursor && path == cursorPath;
    for (var index = 0; index <= sequence.nodes.length; index++) {
      if (active && index == snapshot.cursor.offset) children.add(caret());
      if (index == sequence.nodes.length) break;
      final node = sequence.nodes[index];
      children.add(switch (node) {
        EditorText(:final text) => Padding(
          padding: EdgeInsets.symmetric(
            horizontal: const {'+', '-', '*', '/', '^'}.contains(text) ? 3 : 0,
          ),
          child: Text(switch (text) {
            '*' => '×',
            '/' => '÷',
            '-' => '−',
            _ => text,
          }),
        ),
        EditorFraction(:final numerator, :final denominator) => _FractionLayout(
          key: ValueKey('fraction-$path/$index'),
          color: color,
          gap: math.max(8, scaledSize * .3),
          axisOffset: scaledSize * .25,
          children: [
            _sequence(
              numerator,
              '$path/f${index}n',
              cursorPath,
              scaledSize,
              color,
            ),
            _sequence(
              denominator,
              '$path/f${index}d',
              cursorPath,
              scaledSize,
              color,
            ),
          ],
        ),
      });
    }
    if (sequence.nodes.isEmpty) {
      children.add(
        Baseline(
          baseline: scaledSize * .85,
          baselineType: TextBaseline.alphabetic,
          child: Container(
            key: ValueKey('placeholder-$path'),
            width: scaledSize * .6,
            height: scaledSize,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(border: Border.all(color: color)),
          ),
        ),
      );
    }
    return Row(
      key: ValueKey('field-$path'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: children,
    );
  }

  static String _describe(EditorSequence sequence) {
    if (sequence.nodes.isEmpty) return 'leeres Feld';
    return sequence.nodes
        .map(
          (node) => switch (node) {
            EditorText(:final text) => switch (text) {
              '*' => 'mal',
              '/' => 'geteilt durch',
              '^' => 'hoch',
              'Ans' => 'Ans',
              _ => text,
            },
            EditorFraction(:final numerator, :final denominator) =>
              'Bruch, Zähler ${_describe(numerator)}, '
                  'Nenner ${_describe(denominator)}, Ende Bruch',
          },
        )
        .join(' ');
  }
}

// Two-child layout measures each field once per layout, including deeply nested
// fractions. No recursive intrinsic-width passes are needed to draw the bar.
class _FractionLayout extends MultiChildRenderObjectWidget {
  final Color color;
  final double gap;
  final double axisOffset;
  const _FractionLayout({
    super.key,
    required this.color,
    required this.gap,
    required this.axisOffset,
    required super.children,
  });

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderFraction(color, gap, axisOffset);

  @override
  void updateRenderObject(BuildContext context, _RenderFraction renderObject) {
    renderObject
      ..color = color
      ..gap = gap
      ..axisOffset = axisOffset;
  }
}

class _FractionParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderFraction extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _FractionParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _FractionParentData> {
  Color _color;
  double _gap;
  double _axisOffset;
  double _barY = 0;
  _RenderFraction(this._color, this._gap, this._axisOffset);

  set color(Color value) {
    if (value == _color) return;
    _color = value;
    markNeedsPaint();
  }

  set axisOffset(double value) {
    if (value == _axisOffset) return;
    _axisOffset = value;
    markNeedsLayout();
  }

  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _FractionParentData) {
      child.parentData = _FractionParentData();
    }
  }

  static Size _naturalSize(Size numerator, Size denominator, double gap) =>
      Size(
        math.max(numerator.width, denominator.width) + 8,
        numerator.height + denominator.height + gap,
      );

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.constrain(
    _naturalSize(
      firstChild!.getDryLayout(const BoxConstraints()),
      lastChild!.getDryLayout(const BoxConstraints()),
      _gap,
    ),
  );

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) =>
      _barY + _axisOffset;

  @override
  double computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) =>
      firstChild!.getDryLayout(const BoxConstraints()).height +
      _gap / 2 +
      _axisOffset;

  @override
  void performLayout() {
    final numerator = firstChild!;
    final denominator = lastChild!;
    numerator.layout(const BoxConstraints(), parentUsesSize: true);
    denominator.layout(const BoxConstraints(), parentUsesSize: true);
    size = constraints.constrain(
      _naturalSize(numerator.size, denominator.size, _gap),
    );
    (numerator.parentData as _FractionParentData).offset = Offset(
      (size.width - numerator.size.width) / 2,
      0,
    );
    (denominator.parentData as _FractionParentData).offset = Offset(
      (size.width - denominator.size.width) / 2,
      numerator.size.height + _gap,
    );
    _barY = numerator.size.height + _gap / 2;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.canvas.drawLine(
      offset + Offset(0, _barY),
      offset + Offset(size.width, _barY),
      Paint()
        ..color = _color
        ..strokeWidth = 1.5,
    );
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
