import 'package:flutter/material.dart';

import '../../application/calculator_controller.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final CalculatorController controller;
  final VoidCallback onChanged;

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  CalculatorController get controller => widget.controller;

  static const _descriptions = {
    'io': 'Math zeigt Brüche und Formeln wie im Lehrbuch. Linear schreibt in einer Zeile. Die Ausgabe kann als exakter Wert oder dezimal erfolgen.',
    'angle': 'Gradmaß verwendet 360° pro Kreis, Bogenmaß 2π und Gon 400. Relevant für Winkelfunktionen.',
    'number': 'FIX legt Nachkommastellen fest. SCI zeigt eine Zehnerpotenz mit einer festen Anzahl signifikanter Stellen. NORM wechselt je nach Größe zur wissenschaftlichen Schreibweise.',
    'prefix': 'Verwendet technische Präfixe wie k oder m anstelle von Zehnerpotenzen.',
    'fraction': 'd/c zeigt einen unechten Bruch, etwa 7/3. ab/c zeigt denselben Wert als gemischte Zahl, etwa 2 1/3.',
    'complex': 'a+bi zeigt Real- und Imaginärteil. r∠θ zeigt Betrag und Winkel einer komplexen Zahl.',
    'frequency': 'Blendet die Häufigkeitsspalte für mehrfach vorkommende Werte in der Statistik ein.',
    'sheetAuto': 'Berechnet Zellen nach einer Änderung automatisch neu.',
    'sheetCell': 'Zeigt beim Auswählen einer Zelle ihre Formel oder ihren berechneten Wert.',
    'solutions': 'Erlaubt komplexe Ergebnisse beim Lösen von Gleichungen.',
    'table':
        'Erstellt eine Wertetabelle für f(x) oder gemeinsam für f(x) und g(x).',
    'period': 'Zeigt wiederholte Dezimalziffern mit Überstrich. S⇔D wechselt zwischen Bruch, Periode und gerundetem Dezimalwert.',
    'separator': 'Gruppiert die Ziffern großer Zahlen, damit sie leichter zu lesen sind.',
    'text': 'Wählt die Schriftgröße für die mehrzeilige Anzeige.',
    'qr': 'Wählt die QR-Code-Version für den Datenaustausch.',
    'off': 'Legt die Wartezeit bis zum automatischen Ausschalten fest.',
    'contrast': 'Passt die Helligkeit der Schrift im Rechnerdisplay an.',
  };

  void _change(VoidCallback action) {
    setState(action);
    widget.onChanged();
  }

  Widget _choice(String page, {String? label}) {
    final options = controller.setupOptions(page);
    final selected = options.firstWhere((option) => option.selected).id;
    return DropdownButtonFormField<String>(
      key: ValueKey('setting-$page-$selected'),
      initialValue: selected,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label ?? 'Auswahl',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      items: [
        for (final option in options)
          DropdownMenuItem(value: option.id, child: Text(option.label)),
      ],
      onChanged: (value) {
        if (value != null) {
          _change(() => controller.selectSetupOption(page, value));
        }
      },
    );
  }

  Widget _section(CalculatorMenuItem section) {
    final pending = section.capabilityStatus != 'Verfügbar';
    final settings = controller.settings;
    return Card(
      key: ValueKey('settings-section-${section.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(section.label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(_descriptions[section.id]!),
            if (pending) ...[
              const SizedBox(height: 8),
              Text(
                'Vorgabe gespeichert · Funktion noch in Vorbereitung',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (section.id == 'contrast') ...[
              Text('${settings.contrast} / 10'),
              Slider(
                key: const ValueKey('settings-contrast'),
                value: settings.contrast.toDouble(),
                min: 0,
                max: 10,
                divisions: 10,
                label: '${settings.contrast}',
                onChanged: (value) =>
                    _change(() => controller.setContrast(value.round())),
              ),
            ] else ...[
              _choice(section.id),
              if (section.id == 'number') ...[
                const SizedBox(height: 12),
                _choice(
                  settings.numberFormat.name,
                  label: switch (settings.numberFormat) {
                    CalculatorNumberFormat.fix => 'Nachkommastellen',
                    CalculatorNumberFormat.sci => 'Signifikante Stellen',
                    CalculatorNumberFormat.norm => 'Umschaltbereich',
                  },
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    key: const ValueKey('settings-dialog'),
    insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
    title: Row(
      children: [
        const Icon(Icons.tune),
        const SizedBox(width: 12),
        const Expanded(child: Text('Einstellungen')),
        IconButton(
          key: const ValueKey('settings-close'),
          tooltip: 'Schließen',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    ),
    contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    content: SizedBox(
      width: 600,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Änderungen gelten sofort und sind auch über SHIFT → MENU im Rechner einstellbar.',
            ),
            const SizedBox(height: 16),
            for (final section in controller.setupSections.where(
              (section) => section.capabilityStatus == 'Verfügbar',
            ))
              _section(section),
            ExpansionTile(
              key: const ValueKey('settings-pending'),
              tilePadding: const EdgeInsets.symmetric(horizontal: 8),
              title: const Text('Weitere Setup-Vorgaben'),
              subtitle: const Text('Für Funktionen in Vorbereitung'),
              children: [
                for (final section in controller.setupSections.where(
                  (section) => section.capabilityStatus != 'Verfügbar',
                ))
                  _section(section),
              ],
            ),
          ],
        ),
      ),
    ),
    actions: [
      FilledButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Fertig'),
      ),
    ],
  );
}
