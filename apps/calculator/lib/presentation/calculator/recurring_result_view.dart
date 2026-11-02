import 'package:flutter/material.dart';

/// Displays the controller's exact components without parsing or arithmetic.
class RecurringResultView extends StatelessWidget {
  const RecurringResultView({
    required this.periodPrefix,
    required this.repeatingDigits,
    required this.canonicalText,
    this.style,
    super.key,
  });

  final String periodPrefix;
  final String repeatingDigits;
  final String canonicalText;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$periodPrefix Periode $repeatingDigits',
    value: canonicalText,
    child: ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: periodPrefix),
              TextSpan(
                text: repeatingDigits,
                style: const TextStyle(decoration: TextDecoration.overline),
              ),
            ],
          ),
          key: const ValueKey('display-result'),
          softWrap: false,
          style: style,
        ),
      ),
    ),
  );
}
