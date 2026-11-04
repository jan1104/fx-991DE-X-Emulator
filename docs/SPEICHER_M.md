# Unabhängiger Speicher M

## Gemeinsame Sitzungsspeicher: Vertrag vom 04.11.2026 abends

Das Folgepaket bindet `CalculatorMemory` an beide Eingabesitzungen. Die Konstruktoren akzeptieren optional `memory:`; ohne Übergabe bleibt jede Sitzung unabhängig. Der Appcontroller erzeugt ein eigenes Speicherobjekt und übergibt es an Math und Linear. Jeder neue Controller beginnt unabhängig bei null. Eine Persistenz über einen Appneustart ist weiterhin nicht enthalten.

Der Snapshotabruf und jeder öffentliche zustandsabhängige Sitzungsaufruf übernehmen den aktuellen Ans aus diesem Speicher. Nur bei abweichendem Ans wird dafür ein neuer Snapshot erzeugt. Vorher ausgegebene Snapshots bleiben unverändert. Eingabebaum beziehungsweise Tokens, Cursor, Fehler und Fehlerziel, gespeicherter Ergebniswert und dessen Darstellungswahl bleiben erhalten. Das ist eine gezielte Änderung der früheren Prototypregel mit getrennten Ans-Registern; alte Wechseltests werden entsprechend präzisiert. Ein Wechsel über die Werkzeugleiste und über das Setupmenü verwendet denselben gemeinsamen Speicher.

`applyMemory(operation)` ist zunächst eine Core-Sitzungsaktion ohne neue physische Tastenbelegung. Während der Bearbeitung wertet sie einen nichtleeren Entwurf mit dem aktuellen Ans aus und übernimmt ihn mit der gewünschten Speicheroperation. Bei Ergebnisanzeige verwendet sie ausschließlich den gespeicherten Ergebniswert. Insbesondere wird ein Ausdruck mit `Ans` nach einer zwischenzeitlichen Rechnung der anderen Sitzung nicht erneut ausgewertet. Das angezeigte Ergebnis bleibt der Summand, Ans wird dieser Wert und M wird gemäß Operation geändert. Eine erfolgreiche Speicheraktion beginnt wie eine neue Berechnung mit Bruchdarstellung. Ein leerer Entwurf und eine Fehlerphase lassen den Speicher unverändert. Eingabefehler verwenden die vorhandene Fehlerzuordnung; eine Speichergrenze ohne Ausdrucksposition erhält im Math-Editor den aktuellen Cursor als Fehlerziel.

AC entfernt weiterhin nur den aktiven Entwurf. Setup-/Darstellungsänderungen löschen weder Ans noch M. Ein ausdrückliches `memory.clearMemory()` setzt beide Register auf null; bestehende Ergebnisanzeigen werden dabei nicht zu neuen Rechnungen. Ein solcher Core-Aufruf ist noch kein implementiertes RESET-Menü. OFF/ON bewahrt den Speicher innerhalb desselben Controllers, keine Speicherung über einen Prozessneustart.

Die sichtbare M+/M−-Taste und der M-Indikator folgen als eigenes App-Paket. Das Register kann bis dahin nur über die Core-API verändert werden. STO/RECALL, Variable M im Parser und Resetmenüs bleiben offen. Tatsächliche Prüfungen werden nach dem GitHub-Lauf im [Entwicklungsstand](ENTWICKLUNGSSTAND.md) ausgewiesen.

## Erstes abgegrenztes Paket vom 04.11.2026 nachmittags

Das erste Paket begann mit einem eigenen Core-Speicherzustand, noch ohne Sitzungsanbindung. M+, M−, STO, RECALL und ein sichtbarer M-Indikator bleiben in der App offen. Der tatsächliche Prüfstand steht im [Entwicklungsstand](ENTWICKLUNGSSTAND.md).

39 neue Speicherfälle sind im unabhängigen [GitHub-Lauf 41852962881](https://github.com/jan1104/fx-991DE-X-Emulator/actions/runs/41852962881) für `12b64e7` bestanden: insgesamt 984 Coretests, 438 Appfälle, Web-Build und 18 bestehende Vorschauszenarien. Dies bestätigt den Core-Dienst und die Regression des bisherigen Appumfangs, keine M-Bedienung in der App.

Die vorhandene Quellenanalyse belegt: M+ addiert das gerade berechnete Ergebnis, M− subtrahiert es. Der angezeigte Wert ist der Summand, nicht der neue Speicherinhalt. Nach `10 × 5 M+` und `10 + 5 SHIFT M+` enthält M den Wert 35, während die zweite Rechnung 15 zeigt. M wird mit `0 STO M` gelöscht. Ans und M bleiben bei AC, Moduswechsel und Ausschalten erhalten; Speicherinitialisierung löscht beide. Eine reine Setupinitialisierung löscht sie nicht. Quellen: H, physische PDF-S. 17–18; Setup-/Resetabgrenzung H, PDF-S. 3 und 10. Die bereits dokumentierte Analyse wird hier übernommen, kein neuer Originalvergleich behauptet. Siehe [Tasten und Bedienung](TASTEN_UND_BEDIENUNG.md).

## Core-Vertrag

`CalculatorMemory` besitzt einen unveränderlichen `CalculatorMemorySnapshot` mit exaktem `answer` (Ans), `memory` (M) und abgeleitetem `hasMemory` (M ungleich null). Jede Instanz ist unabhängig; es gibt keinen globalen Zustand oder Plattformzugriff. Beide Werte beginnen bei null.

| Operation | Neuer Ans | Neuer M | Rückgabewert |
|---|---|---|---|
| `MemoryOperation.result` | berechneter Wert | unverändert | berechneter Wert |
| `MemoryOperation.add` | berechneter Wert | alter M + Wert | berechneter Wert |
| `MemoryOperation.subtract` | berechneter Wert | alter M − Wert | berechneter Wert |
| `MemoryOperation.store` | berechneter Wert | berechneter Wert | berechneter Wert |

`calculate(source, operation: ...)` verwendet den vorhandenen Parser/Evaluator und bindet Ans an den bisherigen Speicherstand. `acceptResult(value, operation: ...)` übernimmt ein bereits ausgewertetes exaktes Ergebnis, damit die spätere strukturierte Sitzung ihre vorhandene Projektion und Fehlerzuordnung behalten kann. Diese Methoden sind Rechenkernaufrufe, keine bereits implementierten Tastensignale. Insbesondere ist `store` hier eine ausdrückliche Wertzuweisung; STO-Bereitschaft und Variablenauswahl sind noch nicht umgesetzt.

Auswertung und Speicheraktualisierung sind atomar: Erst wenn der Wert und der neue M-Kandidat gültig sind, wird ein neuer Snapshot veröffentlicht. Bei Syntax-, Mathematik-, Unsupported- oder Ressourcenfehler bleibt auch die bisherige Snapshotidentität erhalten. Der Aufrufer kann dann seine eigene Fehlerphase setzen; eine solche Anzeige gehört nicht zum Speicherobjekt. Frühere Snapshots bleiben unverändert.

Die bestehenden Parser-/Auswertungsbudgets gelten weiterhin. Zusätzlich dürfen Zähler- und Nennerbitlänge eines übernommenen Werts beziehungsweise des gekürzten neuen M zusammen höchstens 100000 betragen. Die Grenze wird auch beim direkten `acceptResult` geprüft. Die Summe kann trotz gültigem Einzelwert diese Grenze überschreiten. Dann scheitert die gesamte Transaktion mit `CalculatorErrorCode.limit`, ohne Ans vorab zu überschreiben. Die Speichergrenze hat keine Ausdrucksposition; die spätere Sitzung muss sie der Speicheraktion zuordnen. Dies ist ein eigenes Ressourcenbudget, keine behauptete Casio-Zahlbereichsgrenze. Exakte rationale Addition erfolgt ohne Anzeigeformatierung oder Gleitkommarundung.

`clearMemory()` setzt in diesem Paket Ans und M auf null. Es existieren noch keine weiteren Variablen. Der Name bezeichnet ausschließlich Speicherinitialisierung und darf nicht für AC oder eine Setupinitialisierung aufgerufen werden. Persistenz über einen Prozessneustart ist nicht enthalten.

## Ursprüngliche Integrationsplanung und verbleibende Abnahme

Ein Appcontroller soll genau ein Speicherobjekt an beide Eingabesitzungen übergeben. Jeder Controller muss weiterhin unabhängig bleiben. Ans in Sitzungssnapshots darf nach Wechsel der Eingabeart nicht aus einem veralteten lokalen Zustand stammen. Bestehende Ausdrucksentwürfe und Ergebnisanzeigen sollen beim Wechsel erhalten bleiben; ihre gespeicherten Anzeigewerte sind von dem aktuellen gemeinsamen Ans zu unterscheiden. Die konkrete Snapshot-/Injektionsschnittstelle wird vor dieser Änderung festgelegt.

Die Abnahme umfasst mindestens: M+/M− in beiden Eingabearten; die Handbuchfolge mit M = 35 und Anzeige 15; gemeinsame exakte Drittel und Ans über einen Math-/Linear-Wechsel; AC und reine Setupänderung erhalten den Speicher; fehlerhafte Eingaben und übergroße kumulierte Werte schreiben nichts; Speicherreset löscht Ans und M, ohne Setup zu verstellen; zwei Controller teilen keine Werte. Der M-Indikator muss bei negativem M gesetzt und nach exakter Aufhebung oder `0 STO M` gelöscht sein. Ein optionaler Status über die Werkzeugleiste muss denselben Zustand verwenden.

RESET-Menü, STO-/RECALL-Bedienung, Variable M als Ausdrucksoperand, weitere Variablen, Ausschaltpersistenz und umfassende Initialisierung bleiben eigenständige Integrationsaufgaben. Bis dahin wird keine sichtbare M-Taste freigeschaltet und keine vollständige Speicherkompatibilität gemeldet.
