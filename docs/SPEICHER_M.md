# Unabhängiger Speicher M

Stand 09.11.2026. Die App unterstützt M+, SHIFT → M−, STO und RECALL für M. ALPHA → M+ setzt M als Operand ein. Die Bedienfolge und der Prüfstand stehen im aktuellen Vertrag. Die folgenden Fortschreibungen dokumentieren die früheren Pakete. [STO-/RECALL-Vertrag](STO_RECALL_M.md)

Fortschreibung 06.11.2026 morgens: Der exakte M-Operand in Parser und Editor ist auf `ea35068` geprüft (1109 Coretests, 480 Appfälle, Web-Build, 21 bestehende Vorschauen). `memoryValue:` bindet M unabhängig von Ans; Speichertransaktionen bleiben atomar. Die neue STO-/RECALL-Oberfläche und ihre Kandidaten-/Ladeaktionen bleiben das folgende Paket. [Prüfstand](ENTWICKLUNGSSTAND.md), [Vertrag](STO_RECALL_M.md).

Fortschreibung 06.11.2026: Der konkrete [STO-/RECALL-Vertrag für M](STO_RECALL_M.md) ist ausgearbeitet. Vor der Dialoganbindung wird ein exakter M-Operand im Core benötigt, damit ein Abruf auch beim späteren Bearbeiten den richtigen Ausdruck behält. Quellenbelege, eigene Ans-Regeln und geplante Abnahmen sind dort getrennt ausgewiesen. Dies ergänzt die Planung; die folgenden bestandenen M+/M−-Prüfungen bleiben unverändert.

## App-Belegung: Vertrag vom 05.11.2026

Abgeschlossen geprüft auf `db6bb60` im [GitHub-Lauf 42081398723](https://github.com/jan1104/fx-991DE-X-Emulator/actions/runs/42081398723): **1041 Coretests, 480 Appfälle, Web-Build und 21 Vorschauen bestanden**. 31 neue Appfälle sind enthalten. Drei getrennte M-Bilder wurden visuell geprüft; Bildbestand und Grenzen stehen im [Entwicklungsstand](ENTWICKLUNGSSTAND.md). STO/RECALL und das Resetmenü bleiben offen.

Dieses Paket verbindet die vorhandene physische Taste `KEY_M_PLUS` mit M+ und ihre SHIFT-Belegung mit M−. Beide Eingabearten verwenden dieselbe Sitzungs-API und denselben Speicher. Während einer nichtleeren Eingabe wird gerechnet und der Summand übernommen; nach einer Ergebnisanzeige wird der gespeicherte Wert verwendet. Leere Entwürfe und Fehlerphasen schreiben nichts. SHIFT wird auch bei einer solchen wirkungslosen Aktion verbraucht. Die bestehenden Menü- und OFF-Sperren gelten vor der Speicheraktion.

Der Bildschirm zeigt weiterhin das berechnete Ergebnis, nicht den M-Gesamtwert. Bei Math → Dezimal und Linear → Dezimal wird der normale Dezimalwunsch auch nach M+/M− angewandt; in den anderen Eingabearten beginnt die neue Ergebnisanzeige mit Bruchwahl. Fix/Sci/Norm und S⇔D bleiben reine Ausgabe. Ans und M werden nicht gerundet. Die Handbuchfolge `10 × 5 M+`, dann `10 + 5 SHIFT M+` muss somit M = 35, Anzeige/Ans = 15 ergeben. Quelle aus dem vorhandenen Inventar: H, physische PDF-S. 18.

Der Status erhält das Zeichen `M`, genau wenn der exakte Speicher ungleich null ist. Negative Werte setzen ihn ebenfalls; exakte Aufhebung entfernt ihn. Die zugängliche Beschriftung des Status ergänzt „Unabhängiger Speicher M belegt“. OFF blendet das Display aus und behält den Zustand innerhalb des Controllers; ON und AC erhalten die Register. Der Indikator ist keine zusätzliche Speicherwertanzeige und verändert keine Berechnung.

Das physische Register bleibt bei 50 Plätzen, das Core-Tastenenum bei 33 Aktionen. Eine weitere Primärbelegung erhöht die aktiven Plätze von 31/34 auf 32 in Linear und 35 in Math. M− verwendet den bestehenden Bildschirm-SHIFT-Zustand; es wird kein neuer PC-Tastaturkurzbefehl erfunden. Die zugeordneten Ziffern-/Operator-/Enter-Ereignisse bleiben unverändert. Die noch deaktivierten ALPHA-/STO-/RECALL-/RESET-Funktionen werden dadurch nicht freigeschaltet. Originalvergleich, natives Gerät und Persistenz über einen Appneustart bleiben offen. Der tatsächliche Test- und Vorschauprüfstand steht im [Entwicklungsstand](ENTWICKLUNGSSTAND.md).

## Gemeinsame Sitzungsspeicher: Vertrag vom 04.11.2026 abends

Abgeschlossen geprüft auf `2616bd9` im [GitHub-Lauf 41919856832](https://github.com/jan1104/fx-991DE-X-Emulator/actions/runs/41919856832): **1041 Coretests, 449 Appfälle, Web-Build und 18 bestehende Vorschauen bestanden**. Die 57 neuen Corefälle und elf neuen Controllerfälle sind darin enthalten. Die sichtbare M-Tastenbelegung ist weiterhin offen.

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
