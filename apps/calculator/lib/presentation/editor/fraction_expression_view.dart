import 'dart:math' as math;

import 'package:calculator_core/calculator_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Read-only natural fraction view. Editing and calculator phases stay outside.
class FractionExpressionView extends StatefulWidget {
  final FractionEditorSnapshot snapshot;
  final bool showCursor;
  final double fontSize;
  final bool followCursor;
  final EditorCursor? errorCursor;

  const FractionExpressionView({
    super.key,
    required this.snapshot,
    this.showCursor = true,
    this.fontSize = 24,
    this.followCursor = false,
    this.errorCursor,
  }) : assert(fontSize > 0 && fontSize < double.infinity);

  @override
  State<FractionExpressionView> createState() => _FractionExpressionViewState();
}

class _FractionExpressionViewState extends State<FractionExpressionView> {
  final _horizontal = ScrollController();
  final _vertical = ScrollController();
  final _cursorKey = GlobalKey();
  final _horizontalKey = GlobalKey();
  final _verticalKey = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleReveal();
  }

  @override
  void didUpdateWidget(FractionExpressionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleReveal();
  }

  void _scheduleReveal() {
    if (!widget.followCursor ||
        (!widget.showCursor && widget.errorCursor == null))
      return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !widget.followCursor ||
          (!widget.showCursor && widget.errorCursor == null))
        return;
      final cursor = _cursorKey.currentContext?.findRenderObject();
      if (cursor is! RenderBox || !cursor.hasSize) return;
      final rect = cursor.localToGlobal(Offset.zero) & cursor.size;
      _reveal(_horizontal, _horizontalKey, rect, horizontal: true);
      _reveal(_vertical, _verticalKey, rect, horizontal: false);
    });
  }

  void _reveal(
    ScrollController controller,
    GlobalKey viewportKey,
    Rect cursor, {
    required bool horizontal,
  }) {
    final viewport = viewportKey.currentContext?.findRenderObject();
    if (!controller.hasClients ||
        !controller.position.hasContentDimensions ||
        viewport is! RenderBox ||
        !viewport.hasSize)
      return;
    final visible = viewport.localToGlobal(Offset.zero) & viewport.size;
    final start = horizontal ? cursor.left : cursor.top;
    final end = horizontal ? cursor.right : cursor.bottom;
    final visibleStart = horizontal ? visible.left : visible.top;
    final visibleEnd = horizontal ? visible.right : visible.bottom;
    final delta = start < visibleStart
        ? start - visibleStart - 4
        : end > visibleEnd
        ? end - visibleEnd + 4
        : 0.0;
    if (delta == 0) return;
    final position = controller.position;
    controller.jumpTo(
      (position.pixels + delta).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
    );
  }

  @override
  void dispose() {
    _horizontal.dispose();
    _vertical.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _FormulaContent(
    snapshot: widget.snapshot,
    showCursor: widget.showCursor,
    fontSize: widget.fontSize,
    horizontal: _horizontal,
    vertical: _vertical,
    cursorKey: _cursorKey,
    horizontalKey: _horizontalKey,
    verticalKey: _verticalKey,
    errorCursor: widget.errorCursor,
  );
}

class _FormulaContent extends StatelessWidget {
  final FractionEditorSnapshot snapshot;
  final bool showCursor;
  final double fontSize;
  final ScrollController horizontal;
  final ScrollController vertical;
  final GlobalKey cursorKey;
  final GlobalKey horizontalKey;
  final GlobalKey verticalKey;
  final EditorCursor? errorCursor;
  const _FormulaContent({
    required this.snapshot,
    required this.showCursor,
    required this.fontSize,
    required this.horizontal,
    required this.vertical,
    required this.cursorKey,
    required this.horizontalKey,
    required this.verticalKey,
    required this.errorCursor,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    final scaledSize = MediaQuery.textScalerOf(context).scale(fontSize);
    final target = errorCursor ?? snapshot.cursor;
    final cursorPath = target.path.fold(
      'root',
      (path, step) =>
          '$path/f${step.nodeIndex}'
          '${step.field == FractionField.numerator ? 'n' : 'd'}',
    );
    return Semantics(
      container: true,
      label:
          'Eingabe: ${_describe(snapshot.root)}'
          '${errorCursor == null ? '' : '. Fehlerstelle ${_location(errorCursor!)}'}',
      child: SingleChildScrollView(
        key: verticalKey,
        controller: vertical,
        primary: false,
        child: SizedBox(
          key: horizontalKey,
          child: SingleChildScrollView(
            key: const ValueKey('formula-scroll'),
            controller: horizontal,
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
    final isError = errorCursor != null && path == cursorPath;
    Widget caret() => _BaselineBox(
      baseline: scaledSize,
      child: KeyedSubtree(
        key: cursorKey,
        child: SizedBox(
          key: ValueKey(isError ? 'formula-error' : 'formula-cursor'),
          width: 3,
          height: scaledSize * 1.25,
          child: ColoredBox(color: isError ? const Color(0xFFB3261E) : color),
        ),
      ),
    );
    final children = <Widget>[];
    final active =
        (isError || (showCursor && errorCursor == null)) && path == cursorPath;
    for (var index = 0; index <= sequence.nodes.length; index++) {
      if (active && index == (errorCursor ?? snapshot.cursor).offset)
        children.add(caret());
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
        _BaselineBox(
          baseline: scaledSize * .85,
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
    final field = Row(
      key: ValueKey('field-$path'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: children,
    );
    return isError
        ? Container(
            key: const ValueKey('formula-error-field'),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFB3261E), width: 2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: field,
          )
        : field;
  }

  String _location(EditorCursor cursor) {
    if (cursor.path.isEmpty) {
      return 'in der Eingabe, Position ${cursor.offset + 1}';
    }
    var sequence = snapshot.root;
    final parts = <String>[];
    for (final step in cursor.path) {
      final ordinal = sequence.nodes
          .take(step.nodeIndex + 1)
          .whereType<EditorFraction>()
          .length;
      final field = step.field == FractionField.numerator ? 'Zähler' : 'Nenner';
      parts.add('im $field des $ordinal. Bruchs');
      final fraction = sequence.nodes[step.nodeIndex] as EditorFraction;
      sequence = step.field == FractionField.numerator
          ? fraction.numerator
          : fraction.denominator;
    }
    return '${parts.join(', darin ')}, Position ${cursor.offset + 1}';
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
              '²' => 'zum Quadrat',
              '³' => 'hoch drei',
              '%' => 'Prozent',
              '!' => 'Fakultät',
              '⁻¹' => 'Kehrwert',
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
class _BaselineBox extends SingleChildRenderObjectWidget {
  final double baseline;
  const _BaselineBox({required this.baseline, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderBaselineBox(baseline);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderBaselineBox renderObject,
  ) {
    renderObject.baseline = baseline;
  }
}

// Report a baseline inside the full child box. A Baseline widget would shift a
// baseline-less rectangle upward, leaving part of the caret outside its bounds.
class _RenderBaselineBox extends RenderProxyBox {
  double _baseline;
  _RenderBaselineBox(this._baseline);

  set baseline(double value) {
    if (value == _baseline) return;
    _baseline = value;
    markNeedsLayout();
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) => _baseline;

  @override
  double computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) => _baseline;
}

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
