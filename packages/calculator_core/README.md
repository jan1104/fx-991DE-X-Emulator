# Unabhängiger Rechenkern

Erster lauffähiger Prototyp als reines Dart-Paket, unabhängig von Flutter und Betriebssystemzugriffen in der Bibliothek.

Implementiert sind gekürzte BigInt-Brüche, exakte Punkt-/Komma-Dezimaleingabe mit optionalem Dezimalexponenten, Ausdrucksbaum und lineare Auswertung von Grundoperatoren, Klammern und ganzzahligen Potenzen. Potenzen sind rechtsassoziativ und binden vor negativem Vorzeichen. Implizite Multiplikation ist zunächst nur vor einer öffnenden Klammer möglich und bindet vor expliziter Multiplikation/Division. Beispiele: `-2^2=-4`, `2/3+(1+1/2)=13/6`, `0,1+0,2=3/10`.

`evaluate("Abs(2-7)*2")` ergänzt exakte rationale Beträge mit ausdrücklichen Argumentklammern. Parser und Evaluator unterstützen `Abs(...)`; beide Sitzungen ergänzen `ACTION_ABS`, Math mit `EditorAbsolute.argument`, Linear mit atomischem `Abs(`-Präfix und ausdrücklichem Abschluss. Vertrag und abgegrenzter Prüfstand: [BETRAG.md](../../docs/BETRAG.md), Editorvertrag: [BETRAG_EDITOR.md](../../docs/BETRAG_EDITOR.md).

Das Paket hat keine externen Laufzeitabhängigkeiten; `package:test` ist nur Entwicklungsabhängigkeit. SDK und Testversion stehen in `../../tools/toolchain.json`, die konkrete Auflösung in `pubspec.lock`.

`formatRational(value, format: RationalDisplayFormat.exactDecimal)` ergänzt eine reine exakte Ausgabe mit deutschem Komma. Endliche Dezimalbrüche werden ohne Gleitkomma und Rundung erzeugt; bei periodischer oder zu langer Entwicklung bleibt der gekürzte Bruch mit ausdrücklich gemeldetem Rückfallgrund erhalten. Das Zeichenlimit gilt auch für diesen Rückfall. Der Dienst verändert weder Werte noch Sitzungen und bindet noch keine S⇔D-Taste an. Vertrag und Beispiele: [EXAKTE_AUSGABE.md](../../docs/EXAKTE_AUSGABE.md).

Beide Sitzungen ergänzen eine ausdrückliche Ergebniswahl über `selectResultDisplayFormat(...)`; ihr Snapshot veröffentlicht `resultDisplayFormat` und liefert über `formatResult()` den Text bei Bedarf. Ergebnis und Ans bleiben exakt. Außerhalb der Ergebnisphase ist die Wahl wirkungslos und der Textabruf liefert `null`. Die App bindet diese API noch nicht an. Übergänge, Rückfallgründe und Ausgabeprobleme sind im [Sitzungsvertrag](../../docs/DARSTELLUNGSWAHL.md) festgelegt.

Mit Dart 3.13.7 im Paketordner:

```text
dart pub get --enforce-lockfile
dart analyze
dart test
dart run bin/calculate.dart "2/3 + (1+1/2)"
```

Alternativ unter PowerShell vom Repository aus: `./tools/test_core.ps1 -DartPath <Pfad-zu-dart.exe>`. Das CLI ist nur ein Demonstrationsadapter; die Bibliothek selbst verwendet kein `dart:io`.

Zusätzlich implementiert: `CalculatorSession` mit 33 semantischen Aktionen einschließlich `KEY_SQUARE`, `KEY_RECIPROCAL` und den sekundären Aktionen `ACTION_CUBE`, `ACTION_PERCENT`, `ACTION_FACTORIAL`, `ACTION_PERMUTATION`, `ACTION_COMBINATION`, `ACTION_ABS`, unveränderlichen Snapshots, linearem Cursor und atomarem Ans-Token, AC/DEL sowie Ergebnis- und Fehlerübergängen. Aufruf etwa `session.pressId('KEY_7')`; unterstützte IDs und Prototypregeln stehen im [Bedienprototyp](../../docs/SESSION_PROTOTYP.md) und [QUADRIEREN.md](../../docs/QUADRIEREN.md). Siehe auch [Kehrwertvertrag](../../docs/KEHRWERT.md) und [Kubieren](../../docs/KUBIEREN.md) sowie [Prozent](../../docs/PROZENT.md) und [Fakultät](../../docs/FAKULTAET.md) sowie [Kombinatorik](../../docs/KOMBINATORIK.md). `evaluate('Ans+1', answer: vorherigerWert)` bindet Ans ausdrücklich, ohne globalen Speicher.

Ein separater `FractionEditor` ergänzt strukturierte Bruchvorlagen, verschachtelte Zähler-/Nennerfelder, einen Pfadcursor und exakte Auswertung über den bisherigen Parser. `StructuredCalculatorSession` ergänzt die 33 Coreaktionen sowie drei lokale Bruch-/Richtungsaktionen `KEY_FRACTION`, `KEY_UP`, `KEY_DOWN`, exaktes Ans und Ergebnis-/Fehlerphasen. Die Flutter-App bindet ihn als getrennte Eingabeart an; die semantischen Aktionen sind von den 50 physischen App-Tasten und deren 31/34 Primärbelegungen zu unterscheiden. Regeln und Grenzen stehen in [STRUKTURIERTE_SITZUNG.md](../../docs/STRUKTURIERTE_SITZUNG.md).

`FractionEditor.project()` ergänzt eine unveränderliche Source-Map; strukturelle Diagnosen liefern Feldcursor, und `moveTo()` validiert deren Wiederaufnahme. Die Sitzung veröffentlicht Fehlerziele separat als `errorCursor`. Bestehende `toExpression()`-/`evaluate()`-Aufrufer erhalten weiterhin die bisherigen Ausnahmetypen. Details: [FEHLERPOSITIONEN.md](../../docs/FEHLERPOSITIONEN.md).

`wrapPreviousAtomInFraction()` übernimmt eine vollständige Zahl, Ans, einen vorhandenen Bruch oder eine geschlossene Textklammergruppe als Zähler. Die eigene Sitzungsaktion `ACTION_WRAP_FRACTION` wirkt nur während der Bearbeitung und verändert weder das physische Tastenregister noch die lineare Sitzung. Knoten- und gesamte Unterbaumtiefe werden vor Veröffentlichung geprüft. Regeln: [BRUCHUEBERNAHME.md](../../docs/BRUCHUEBERNAHME.md).

Die Flutter-Oberfläche verwendet beide Sitzungen. Noch nicht implementiert: vollständiger natürlicher Formeleditor, Variablen/M-Speicher, vollständige SHIFT-/ALPHA-Belegungen, vollständige Modusmenüs und Casio-Ausgaberegeln, trigonometrische Funktionen und weitere Modi. Eingabelänge, Verschachtelung und Rechengröße sind mit eigenen Ressourcenbudgets begrenzt; diese sind keine Casio-Hardwaregrenzen. `0^0` und nichtganzzahlige Potenzen werden im Evaluator vorerst als nicht unterstützt gemeldet. Das Zahlenmodell allein verwendet für die nullte Potenz die algebraische Konvention 1.

Der tatsächliche Prüfstand steht in [ENTWICKLUNGSSTAND.md](../../docs/ENTWICKLUNGSSTAND.md). Die umfangreichen Referenzkataloge bleiben Planungsdaten; eine bestandene Coreprüfung bedeutet keinen bestandenen UI-/Originalvergleich.

Siehe [Projektstruktur](../../docs/PROJEKTSTRUKTUR.md).


## Begrenzte exakte Periodenausgabe

`formatRational(value, format: RationalDisplayFormat.exactRecurringDecimal, maxGeneratedDigits: 100)` ergänzt einen exakten Restzyklus-Formatter. Beispiel: `1/6` wird `0,1(6)`, `1/11` wird `0,(09)` und `1/8` bleibt `0,125`. Erfolgreiche Aufrufe liefern zusätzlich die unveränderlichen Komponenten unter `display.expansion`; endliche Ausgaben melden tatsächlich `exactDecimal`. Bei unvollständiger Entwicklung bleibt der gekürzte Bruch mit `expansionLimit`, ohne unvollständiges DTO.

Die beiden Stellenbudgets sind unabhängig: `maxGeneratedDigits` gilt nur im neuen Modus, `maxDecimalPlaces` nur im bisherigen endlichen Modus. Alle Parameter werden vor wertabhängiger Arbeit validiert. Die 100000-Bit-Summengrenze gilt nur im neuen Modus; das vollständige Zeichenbudget gilt auch für Bruchrückfälle. Vertrag: [PERIODENDARSTELLUNG.md](../../docs/PERIODENDARSTELLUNG.md). Appcontroller und sichtbarer Periodenschalter verwenden den Formatter inzwischen im Norm-S⇔D-Zyklus; [Appvertrag](../../docs/PERIODEN_APP.md). Tatsächlicher Prüfstand: [ENTWICKLUNGSSTAND.md](../../docs/ENTWICKLUNGSSTAND.md).
