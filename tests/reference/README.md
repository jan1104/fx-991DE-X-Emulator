# Plattformunabhängige Referenzfälle

Dieser Ordner ist für eigene maschinenlesbare Fälle vorbereitet. Noch keine ausführbare Testsuite und keine bestandenen Emulatorprüfungen.

Ausgangskatalog: [56 geplante Referenztests](../../docs/REFERENZTESTS.md). IDs wie K01 oder E13 bleiben bei der späteren Übernahme erhalten.

Jeder künftige Fall soll enthalten:

- Formatversion und stabile ID.
- Herkunft: Handbuch mit PDF-Seite oder später protokollierte Beobachtung der Originalsoftware.
- Expliziter Ausgangszustand: Modus, Setup und relevante Speicherwerte.
- Semantische Aktionen bzw. mathematischer Auftrag; beide nicht stillschweigend gleichsetzen.
- Erwarteter Wert, Ausgabeform und relevante Speicher-/Zustandsänderungen.
- Bei Näherungsverfahren eine begründete absolute/relative Toleranz.
- Getrennte Nachweise für Quellenprüfung, Implementierungstest und Originalvergleich.

Die Inventare `key_coverage.csv` und `function_coverage.csv` erfassen geplante Prüfungen. Unter `scenarios/seed_cases.json` liegt ein JSON-Formatentwurf mit ersten Beispielen; ein ausführbarer Dart-Testadapter existiert noch nicht. `python tools/check_test_catalogs.py` prüft nur die Struktur und IDs dieser Planungsdaten. Es führt keine Rechnerfunktionen aus und meldet keine Funktion als bestanden.

Siehe [Teststrategie](../../docs/TESTSTRATEGIE.md). Keine Original-PDFs, Screenshots oder proprietären Programmdaten hier ablegen; dafür ist der ignorierte Referenzbereich vorgesehen.
