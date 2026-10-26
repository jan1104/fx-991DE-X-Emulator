import 'package:flutter/material.dart';

import 'presentation/calculator/calculator_page.dart';

void main() => runApp(const CalculatorApp());

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Wissenschaftlicher Rechner',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF315F8A)),
      scaffoldBackgroundColor: const Color(0xFFE9EDF1),
    ),
    home: const CalculatorPage(),
  );
}
