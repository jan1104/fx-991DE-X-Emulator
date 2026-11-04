# Unabhängiger Speicher M

## Abgegrenztes Paket vom 04.11.2026

Dieses Paket beginnt mit einem eigenen Core-Speicherzustand. Die bestehenden Math-/Linear-Sitzungen und App-Tasten verwenden ihn noch nicht. M+, M−, STO, RECALL und ein sichtbarer M-Indikator bleiben in der App offen. Der tatsächliche Prüfstand steht im [Entwicklungsstand](ENTWICKLUNGSSTAND.md).

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

## Nächstes Integrationspaket

Ein Appcontroller soll genau ein Speicherobjekt an beide Eingabesitzungen übergeben. Jeder Controller muss weiterhin unabhängig bleiben. Ans in Sitzungssnapshots darf nach Wechsel der Eingabeart nicht aus einem veralteten lokalen Zustand stammen. Bestehende Ausdrucksentwürfe und Ergebnisanzeigen sollen beim Wechsel erhalten bleiben; ihre gespeicherten Anzeigewerte sind von dem aktuellen gemeinsamen Ans zu unterscheiden. Die konkrete Snapshot-/Injektionsschnittstelle wird vor dieser Änderung festgelegt.

Die Abnahme umfasst mindestens: M+/M− in beiden Eingabearten; die Handbuchfolge mit M = 35 und Anzeige 15; gemeinsame exakte Drittel und Ans über einen Math-/Linear-Wechsel; AC und reine Setupänderung erhalten den Speicher; fehlerhafte Eingaben und übergroße kumulierte Werte schreiben nichts; Speicherreset löscht Ans und M, ohne Setup zu verstellen; zwei Controller teilen keine Werte. Der M-Indikator muss bei negativem M gesetzt und nach exakter Aufhebung oder `0 STO M` gelöscht sein. Ein optionaler Status über die Werkzeugleiste muss denselben Zustand verwenden.

RESET-Menü, STO-/RECALL-Bedienung, Variable M als Ausdrucksoperand, weitere Variablen, Ausschaltpersistenz und umfassende Initialisierung bleiben eigenständige Integrationsaufgaben. Bis dahin wird keine sichtbare M-Taste freigeschaltet und keine vollständige Speicherkompatibilität gemeldet.
