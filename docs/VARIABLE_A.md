# Variable A im Rechenkern

Stand 11.11.2026. Dieses Paket ergänzt das exakte Register A, seinen Auswertungskontext und die Speicherinitialisierung. Die App-Bedienung über STO, RECALL und ALPHA folgt als eigenes Paket. [Entwicklungsstand](ENTWICKLUNGSSTAND.md)

## Quellen und Umfang

H beschreibt die Variablen einschließlich A auf den physischen PDF-Seiten 17–18. Die ALPHA-Belegung von A liegt auf der Vorzeichentaste. Speicherinitialisierung löscht die Antwort-, Variablen- und unabhängigen Speicher. Setupinitialisierung erhält die Speicherwerte. Diese Belege sind im vorhandenen Bedieninventar dokumentiert. [Tasten und Bedienung](TASTEN_UND_BEDIENUNG.md)

## Schnittstellen

`CalculatorMemorySnapshot.variableA` beginnt bei null und enthält einen gekürzten exakten Rationalwert. `CalculatorMemory.storeVariableA(value)` weist einen bereits ausgewerteten Wert zu und erhält Ans und M. Der spätere Bedienadapter übernimmt die Auswertung und die Antwortregisterwirkung einer vollständigen STO-Aktion. Dieser Registerzugriff allein bildet keine vollständige Tastensequenz ab.

`parseExpression` und `evaluate` akzeptieren den optionalen Parameter `variableA`. Das Token `A` wird beim Parsen an den übergebenen Wert gebunden. Ein bereits erzeugter Ausdrucksbaum behält seinen Wert nach einer späteren Neuzuweisung. Ohne A-Kontext melden die Funktionen einen strukturierten Unsupported-Fehler an der Position des Tokens. Ein ausdrücklich übergebener Nullwert ist gültig. A wird nur als einzelner Variablenname erkannt. Unbekannte Funktionsnamen wie `ABS` behalten ihre bisherige Fehlerposition am Anfang des Namens.

`CalculatorMemory.calculate(source)` bindet A, Ans und M aus demselben Snapshot. Erfolgreiche Berechnungen aktualisieren Ans und gegebenenfalls M gemäß der vorhandenen Speicheroperation. A bleibt dabei erhalten. Die bisherige Grammatik gilt weiter, etwa `2*A` mit ausdrücklichem Multiplikationszeichen oder `A(2+1)` mit der bereits erlaubten Klammermultiplikation.

`storeVariableA` prüft dasselbe Budget von 100000 Bits für Zähler und Nenner wie die übrigen Speichertransaktionen. Bei Größen- oder Auswertungsfehlern bleibt der vorherige Snapshot erhalten. Das Budget ist eine eigene Ressourcenbegrenzung.

`clearMemory()` setzt Ans, M und A gemeinsam auf null. Die bestehenden App-Aktionen für Speicherreset und vollständige Initialisierung verwenden diesen Dienst. Die Setupinitialisierung erhält A. A beeinflusst den M-Indikator nicht.

## Abnahme und nächster Schritt

Die Coretests prüfen exakte Brüche, Operatorbindung, getrennte Register, Quellpositionen, unveränderliche Ausdrucksbäume und Snapshots, erfolgreiche und fehlgeschlagene Speicheroperationen sowie das Größenbudget. Die bestehenden drei Controller-Abnahmen wurden um A ergänzt. Die tatsächliche Ausführung steht im Entwicklungsstand. [Coretests](../packages/calculator_core/test/variable_a_test.dart), [Prüfstand](ENTWICKLUNGSSTAND.md)

Als nächstes werden A als atomarer Editoroperand und die Kontextübergabe in beiden Eingabesitzungen ergänzt. Danach folgen das Speicherziel A für STO und RECALL sowie ALPHA → Vorzeichentaste in der App.
