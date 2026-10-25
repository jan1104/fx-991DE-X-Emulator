# Entwicklungsstand

## 26.10.2026: erstes ausführbares Core-Arbeitspaket

Ausgangsbasis: vollständiger Projektstand `bcd6691` auf `main`, vor Beginn ohne lokale Änderungen. Original-Programmdateien fehlen weiterhin. Die früher freigegebenen und versionierten Referenzen wurden nicht verändert.

### Umgesetzt

- Reines Dart-Paket unter `packages/calculator_core/` mit kleiner öffentlicher API.
- Unveränderliche, kanonisch gekürzte rationale BigInt-Zahlen; exakte Dezimal-/Exponentialzahleneingabe ohne Zwischenumwandlung in binäre Gleitkommazahlen.
- Eigener Ausdrucksbaum, Parser und davon getrennte Auswertung für `+`, `-`, `*`, `/`, Klammern und ganzzahlige Potenzen. Deutsche Dezimalkommas und die Zeichen ×, ÷, − werden unterstützt.
- Strukturierte Fehler für Syntax, mathematische Fehler, noch nicht unterstützte Funktionen und Ressourcenbudgets; Eingabeposition, soweit relevant.
- Einfaches Kommandozeilenbeispiel. Das ist keine Flutter-App und kein fertiger Emulator.
- Reproduzierbarer Prüfaufruf `tools/test_core.ps1`, SDK-Metadaten und Dependency-Lockdatei.

### Werkzeuge und Nachvollziehbarkeit

Flutter und Dart waren nicht im PATH; eine gezielte Suche in üblichen Verzeichnissen fand keine vorhandene Installation. Für das unabhängige Zahlen-/Parserpaket wurde deshalb nur das portable stabile Dart-SDK 3.13.7 von der offiziellen Archivquelle geladen. Lokaler Ort: `C:\Users\jpohl\.cache\fx991-toolchains\dart-3.13.7\dart-sdk\bin\dart.exe`. Keine globale PATH-Änderung und kein SDK im Repository. Analytics wurde deaktiviert. ZIP und offizieller SHA-256-Sidecar wurden vor Ausführung verglichen; Details in `tools/toolchain.json`.

Quelle zur Archivform: [offizielles Dart-SDK-Archiv](https://dart.dev/get-dart/archive). Der erste Sidecar-Abruf mit der Endung `.sha256` existierte nicht; der veröffentlichte `.sha256sum`-Sidecar wurde erfolgreich verwendet. `package:test` 1.33.0 ist explizit festgelegt; transitive Entwicklungsabhängigkeiten werden über `pubspec.lock` mit Hashes fixiert. Externe Laufzeitabhängigkeiten des Core-Pakets: keine.

### Prüfstand

Auf Windows x64 mit Dart 3.13.7 ausgeführt: Formatierung, statische Analyse und Coretests. Der erste Testlauf zeigte fehlerhaft formulierte Exception-Matcher in den Evaluatortests; diese wurden korrigiert. Die Fehlerbehandlung wird tatsächlich über ausgewertete Closures geprüft, nicht nur auf Existenz eines Exception-Typs. Ein zusätzlicher Review fand, dass geteilte Ausdrucksteilbäume das reine Tiefen-/Größenbudget umgehen konnten; ein Gesamtbudget für Auswertungsschritte und ein Regressionstest wurden ergänzt.

Abschließender vollständiger Lauf mit `tools/test_core.ps1`: Lockdatei erzwungen, Formatprüfung ohne Änderungen, statische Analyse ohne Befund und **110 Tests bestanden**. Zusätzlich CLI erfolgreich mit `2/3 + (1+1/2)` → `13/6` ausgeführt; `1/0` liefert strukturierte Fehlermeldung und Exitcode 2. Katalogprüfung weiterhin erfolgreich: 50 Tasten, 243 geplante Prüfpositionen, fünf JSON-Beispiele, 56 Referenz-IDs. Dokumentverknüpfungen und staged Diff werden vor dem lokalen Commit geprüft.

Abgedeckte Fälle: Bruchnormalisierung, Vorzeichen, Nullnenner, exakte große Ganzzahlen über 2^53, Dezimalparsing und dessen Grenzen, Rangfolge/Assoziativität, implizite Multiplikation, Syntaxfehler, Division durch null, nicht unterstützte Funktionen und eigene Ressourcenbudgets. `K02` wird auf Core-Ebene für beide Vorzeichen-/Klammerfälle geprüft; `K03` nur als mathematisch gleichwertiger linearer Ausdruck. Das ist keine Prüfung der gemischten Bruchtaste oder der natürlichen Anzeige. `G07` wird bezüglich Division-durch-null-Fehlerklasse geprüft, nicht bezüglich UI-Fehlertext/Cursor.

Die 50-Tasten-/243-Prüfpositionen-Kataloge bleiben bewusst `planned`; sie sind keine pauschal bestandene Suite. Die fünf JSON-Beispielabläufe werden noch nicht durch einen Dart-Referenzadapter ausgeführt. Keine Originalsoftware- oder Plattformvergleiche durchgeführt. Kein Windows-/Android-/Apple-/Linux-App-Build vorhanden.

### Bewusste Grenzen

Die rationale Zwischenrechnung und ASCII-Ausgabe bilden noch nicht die Casio-internen Stellen-, Bereichs-, Rundungs- oder Anzeigeregeln nach. Beliebig große Ganzzahlen innerhalb eigener Ressourcenbudgets sind ein Entwicklungswerkzeug und keine Kompatibilitätszusage. Nur implizite Faktoren mit öffnender Klammer sind bisher erlaubt; Funktionen/Variablen sind offen. Nichtganzzahlige Potenzen und `0^0` bleiben im Evaluator ausdrücklich nicht unterstützt. Unbekannte Hardware-Domänen werden damit nicht geraten.

### Nächstes abgegrenztes Arbeitspaket

1. Vorhandenen Core verwenden, keine erneute Grundlagenanalyse.
2. Minimalen testbaren Bedienzustand mit Ziffern, Operatoren, `=`, AC/DEL und strukturierten Fehlern hinzufügen. Speicher und SHIFT/ALPHA als nächste getrennte Schritte planen.
3. Anschließend kleines Flutter-Grundgerüst und den Formeleditor-Prototyp angehen; SDK und Windows-/Android-Buildwerkzeuge gezielt prüfen. Noch fehlende Zielumgebungen ausdrücklich ausweisen.
4. Bei späterem Eingang der Originalsoftware deren statische Analyse unabhängig aufnehmen.

Dieser Fortschritt bleibt lokal; die frühere Push-Freigabe galt dem damaligen vollständigen Stand und wird nicht als automatischer Push-Auftrag für neue Arbeit interpretiert.
