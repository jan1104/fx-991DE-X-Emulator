# STO und RECALL für M: Umsetzungsvertrag

Stand 08.11.2026. Dieser Vertrag trennt Quellenbelege, eigene Regeln und die Umsetzungsschritte. Der Rechenkern enthält den exakten M-Operanden und die Sitzungsaktionen für STO und RECALL. Die Appdialoge mit Norm-1-Vorschau sind auf `72c1c32` geprüft. Die Auswahl per Tipp auf die M-Zeile ergänzt die physische M+-Taste. [Speicherstand](SPEICHER_M.md), [Prüfstand](ENTWICKLUNGSSTAND.md)

## Quellen und sichere Abgrenzung

H bezeichnet `reference/originals/fx-87_991DEX_DE.pdf`. Für die neu offenen STO-/RECALL-Fragen wurden ausschließlich die physischen PDF-Seiten 17 und 18 visuell geprüft (gedruckte Seiten 16 und 17). Keine erneute Gesamtanalyse. Lokale Prüfbilder liegen ignoriert unter `build/reports/sto-recall-source/`.

| Aussage | Status und Beleg |
|---|---|
| Eine Eingabe kann mit STO und der Variablentaste zugewiesen werden, ohne vorher `=` oder zusätzlich ALPHA zu drücken. | Belegt: `3+5 STO A` zeigt 8, H 17. |
| Die M-Variablentaste ist die physische M+-Taste. | Visuell belegt: `0 STO M+` löscht M und zeigt 0, H 18. |
| SHIFT → STO öffnet eine Variablenübersicht. Auswahl einer Variablen und `=` rufen ihren Wert auf. | Belegt: H 17–18. Für M ist `SHIFT STO M+ =` mit Ergebnis 35 gezeigt. |
| Die Übersicht zeigt Werte stets mit Norm 1. AC schließt sie ohne Abruf. | Ausdrücklich belegt: H 18. |
| M ist derselbe Speicher wie die Variable M. | Ausdrücklich belegt: H 18. Kein zweites M-Register anlegen. |
| Bereitschaft zur Zuweisung besitzt einen eigenen Statusindikator. | Bestehendes Inventar mit Beleg H 5; nicht erneut als neue Seitenprüfung ausgegeben. |
| STO oder bestätigtes RECALL ändern Ans. | Auf H 17–18 nicht ausdrücklich beschrieben. Die allgemeine Aussage zum letzten Rechenergebnis beweist diese Einzelfälle nicht. |
| Zeitpunkt der STO-Auswertung, unpassende Folgetasten, leere Eingaben, Wiederholung und Dialogabbruch über Setup/ON/OFF. | Im geprüften Ausschnitt nicht vollständig festgelegt; eigene Regeln unten. |

Die App unterstützt zunächst ausschließlich M. A–F, x und y erhalten keine erfundenen Nullwerte. ALPHA als Ausdruckseingabe und Resetmenüs bleiben getrennte Pakete. Originalsoftware und Gerät wurden nicht beobachtet.

## Voraussetzung: ein exakter M-Operand

Bei der Vertragsausarbeitung kannte der Parser nur Ans und der Editor noch keinen M-Baustein. Diese Voraussetzung ist inzwischen implementiert und geprüft. Ein bestätigter Abruf darf nicht einfach einen neuen Ergebniswert bei unverändertem altem Ausdruck veröffentlichen: Nach Links/DEL würde dann die falsche Rechnung erscheinen. Ein gerundeter Dezimalersatz wäre bei `1/3` falsch; ausgeschriebene Zähler-/Nennertexte können bei großen zulässigen Speicherwerten die Editorbudgets überschreiten.

Das erste Umsetzungsstück ergänzt deshalb optionalen, ausdrücklich gebundenen `Rational? memoryValue` an den Parser-/Auswertungsgrenzen. Ein Token `M` bindet analog zu Ans einen `NumberExpression` an den übergebenen exakten Wert. Kein globaler Speicher und kein neuer Zahlentyp sind nötig. Ohne Kontext liefert M einen strukturierten Unsupported-Fehler an seiner Quellposition, keinen stillen Nullwert. Die normalen Größen-/Arbeitsbudgets bleiben erhalten.

`CalculatorMemory.calculate` bindet Ans und M aus seinem aktuellen Snapshot. Die strukturierte Sitzung und die eigenständigen Editor-Auswertungswege müssen den Kontext ebenfalls ausdrücklich durchreichen. `EditorText('M')` wird ein zulässiger atomarer Baustein; Projektion, Source-Map, DEL, Navigation und Bruchübernahme behandeln ihn wie den bestehenden Ans-Baustein. Das bedeutet keine Freischaltung von ALPHA oder einer neuen physischen Taste. Zunächst wird auch keine zusätzliche implizite Multiplikation vor M eingeführt: `2*M` ist ausdrücklich; das bisherige `2(M)` bleibt möglich.

Die Sitzungsaktion `recallMemory()` erzeugt einen neuen kohärenten Entwurf aus genau diesem M-Atom und veröffentlicht dessen exaktes Ergebnis. Links öffnet dann M; DEL löscht M. Bei späterer erneuter Auswertung wird M wie eine Variable an den dann aktuellen Speicher gebunden. Die frühere Ergebnisanzeige bleibt dagegen ein unveränderlicher Wert. Alte Snapshots werden nicht rückwirkend geändert.

## STO-Bereitschaft

Eigene Prototypregel: STO bereitet bei einem nichtleeren Entwurf einen exakten Kandidaten durch reine Auswertung vor. Bei bereits angezeigtem Ergebnis wird dieser gespeicherte Ergebniswert übernommen, ohne den Ausdruck erneut auszuwerten. Dabei werden weder Ans noch M geschrieben. Ein Auswertungsfehler verwendet den vorhandenen Sitzungsfehler samt Fehlerziel; es wird keine Bereitschaft eröffnet. Leere Eingabe und bestehende Fehlerphase erzeugen keinen Kandidaten.

Der Kandidat enthält einen unveränderlichen Rationalwert und gehört zum aktiven Entwurf beziehungsweise Ergebnis bei Öffnung. Ein Ausdruck mit Ans oder M wird bei der Vorbereitung genau einmal gebunden. Die Bestätigung darf ihn nicht erneut mit inzwischen geänderten Registern auswerten. Navigation und Bearbeitung sind während der Bereitschaft gesperrt. Wiederholtes STO verändert den Kandidaten nicht.

Zusätzlich hält der Kandidat Herkunftssitzung und ursprünglichen unveränderlichen Editor-/Ergebniszustand fest. Ändert ein direkter Session-API-Aufruf diesen Ursprung während des Dialogs, wird die Bereitschaft ohne Zuweisung abgebrochen und eine neue Vorbereitung verlangt. Ein alter Kandidat 3 darf nicht als Ergebnis eines inzwischen geänderten Entwurfs 9 veröffentlicht werden. Eine bloße Änderung des gemeinsamen Ans/M macht den Kandidaten dagegen nicht ungültig: Sein Wert ist bereits eingefroren. Daher nicht pauschal Snapshotidentität vergleichen, sondern Quelle/Editor, Phase und gegebenenfalls gespeicherten Ergebniswert prüfen.

Die M-Variablentaste bestätigt den Kandidaten. Dieser Tastendruck darf weder M+ noch M− zusätzlich auslösen. Anschließend endet die Bereitschaft und die Sitzung zeigt den gespeicherten Wert als Ergebnis. Eigene Prototypregel: Die bestätigte Zuweisung schreibt Ans auf den Kandidatenwert; das entspricht der bereits vorhandenen `MemoryOperation.store`-API, ist aber keine neu nachgewiesene Originaleigenschaft. `0 STO M` entfernt damit den M-Indikator. Vorbereitungs- oder Bestätigungsfehler dürfen keine Register teilweise ändern.

AC verwirft ausschließlich die Bereitschaft und stellt den vorherigen Entwurf, Cursor, Ergebniswert und dessen Darstellungswahl unverändert dar. Ein zuvor nicht ausgeführter Entwurf bleibt nicht ausgeführt. Die reine Vorbereitung ist vom vorhandenen `applyMemory(store)` zu unterscheiden: Dieser Aufruf würde sofort beide Register schreiben und ist daher zum Öffnen der Bereitschaft ungeeignet.

Diese Erhaltung beschreibt den normalen, gesperrten UI-Ablauf. Ein Abbruch rollt keine zwischenzeitlichen legitimen direkten API-Änderungen von Registern oder Sitzungen zurück. Er schließt nur den Dialog; veraltete Sicherungskopien werden nicht über aktuelle Zustände geschrieben. Dieselbe Regel gilt beim Abbruch der RECALL-Übersicht.

## RECALL-Übersicht

SHIFT → STO öffnet eine eigene Übersicht nur für das implementierte M. Ihre Vorschau und die Auswahl schreiben weder Ans noch M. Die M+-Taste wählt in diesem Kontext die Variable M und führt keine Addition aus. Erst `=` bestätigt den Abruf. Eigene Regel: Ohne vorherige M-Auswahl bleibt `=` wirkungslos; die Oberfläche erklärt die nötige Auswahl. AC schließt ohne Abruf und erhält den ursprünglichen Sitzungszustand.

Die Vorschau verwendet Norm 1 unabhängig von Fix, Sci, Norm 2, Bruchwahl und Periodenschalter der Rechnung. Dafür muss der vorhandene App-Dezimalformatter reine Formatierung mit ausdrücklich übergebenen Vorgaben ermöglichen. Das globale Setup darf nicht kurzzeitig umgeschaltet werden; ein Anzeigeproblem bleibt ein Vorschauproblem und verändert keine Register. Die eigene Rundungsregel des bisherigen Formatters wird dadurch nicht zur vollständig nachgewiesenen Casio-Genauigkeit.

Eigene Prototypregel: Bestätigtes RECALL setzt Ans auf den exakten M-Wert, verändert M selbst nicht und startet die im vorigen Abschnitt beschriebene kohärente Ergebnisanzeige mit M als Ausdruck. Die reguläre Eingabe-/Ausgabewahl gilt für diese Ergebnisanzeige; die Norm-1-Sonderregel gehört ausschließlich zur Übersicht.

Die Vorschau hält den M-Wert bei Öffnung fest. Falls M durch einen direkten API-Aufruf zwischen Öffnen und Bestätigung geändert wurde, wird bei `=` die Vorschau aktualisiert und die Auswahl aufgehoben, ohne Register zu schreiben. Erneute Auswahl/Bestätigung verwendet den neuen Wert. Das ist eine eigene Konsistenzregel für die öffentliche Controller-/Core-API; die normale synchrone Oberfläche verändert M im offenen Dialog nicht.

## Zustände und Eingaberouting

Ein eigener Controllerzustand unterscheidet normale Rechnung, STO-Bereitschaft mit Kandidat und RECALL-Übersicht mit Vorschau/Auswahl. Der bestehende SHIFT-Schalter ersetzt diesen Zustand nicht.

| Zustand / Aktion | Wirkung | Registeränderung |
|---|---|---|
| Normal, STO | Kandidat vorbereiten; danach STO-Status oder regulärer Eingabefehler | Keine |
| STO, M-Variablentaste | Kandidaten zuweisen und Bereitschaft schließen | M und gemäß Prototypregel Ans |
| STO, nochmals STO | Bereitschaft mit demselben Kandidaten erhalten | Keine |
| Normal, SHIFT → STO | M-Übersicht öffnen | Keine |
| RECALL, M-Variablentaste | M auswählen | Keine |
| RECALL, `=` nach Auswahl | Gültigkeit der Vorschau prüfen, dann exakten M-Abruf veröffentlichen | Nur Ans, gemäß Prototypregel |
| STO/RECALL, AC | Abbrechen; früheren Sitzungszustand erhalten | Keine |
| STO/RECALL, sonstige Rechentaste | Nicht an gewöhnliche Rechen-/M-Aktionen weiterreichen | Keine |

ON und SHIFT → AC (OFF) bleiben globale Aktionen und beenden einen offenen Dialog. ON behält seine bestehende Editorlöschung, OFF seine Registererhaltung. Öffnen von Setup/Modusmenü, Werkzeugleistenaktionen und direkter Eingabeartwechsel brechen einen offenen Dialog ebenfalls ohne Zuweisung/Abruf ab. Insbesondere darf `selectInputOutput` den Dialog nicht umgehen. SHIFT wird nach der nächsten Zielaktion verbraucht; ein eventuell gesetztes SHIFT darf die Variablenauswahl nicht in M− verwandeln. Der globale OFF-Pfad muss weiterhin erreichbar sein. Diese Routingregeln müssen vor dem gewöhnlichen M+/M−-Zweig greifen.

## Geplante Abnahmefälle

Diese Liste ist ein Umsetzungsauftrag, keine bestandene Testsuite.

| ID | Ablauf / Abnahme | Herkunft der Erwartung |
|---|---|---|
| SM01 | `0 STO M` löscht zuvor belegtes M, zeigt 0, entfernt M-Status. | Rechnung/Tasten H 18; Ans-Regel eigener Prototyp. |
| SM02 | `3+5 STO M`: Öffnen schreibt nichts; M-Auswahl bestätigt exakt 8. | Zuweisungsmechanik H 17–18, Vorbereitung eigener Prototyp. |
| SM03 | STO nach älterem Ergebnis mit inzwischen neuerem gemeinsamen Ans speichert das angezeigte Ergebnis, ohne erneute Auswertung. | Eigener Sitzungskontext. |
| SM04 | STO-Kandidat `Ans+1` wird einmal vorbereitet; Bestätigung bindet nicht erneut. | Eigene Atomaritätsregel. |
| SM05 | AC nach STO erhält Register, Entwurf, Cursor, Phase, Darstellung und alte Snapshots. | Eigene Abbruchregel. |
| SM06 | Syntax-/Mathematik-/Ressourcenfehler erzeugen keine Zuweisung und behalten die vorhandene Fehlerkorrektur. | Eigene Fehlergrenzen. |
| RM01 | Handbuchfolge ergibt M = 35; `SHIFT STO M+ =` ruft exakt 35 auf. | H 18; Ans-Regel eigener Prototyp. |
| RM02 | Öffnen, Auswahl und AC schreiben nichts; M-Taste in der Übersicht addiert nicht. | AC H 18; Routing eigener Prototyp. |
| RM03 | Vorschau trotz Fix/Sci/Norm 2 stets Norm 1; Setup und bestehende Ergebnisdarstellung unverändert. | Norm 1 H 18; Zustandsisolierung eigener Prototyp. |
| RM04 | Abruf von `1/3`, negativem M, null und großem zulässigem Rationalwert bleibt exakt, ohne Dezimalersatz. | Eigenes Rationalmodell und Budgets. |
| RM05 | Nach Abruf öffnen Links/DEL tatsächlich M; Operatorfortsetzung verwendet bestätigtes Ans. | Eigene kohärente Sitzungsregel. |
| RM06 | Geänderter M-Wert während Übersicht aktualisiert Vorschau und verlangt erneute Auswahl, ohne Teiländerungen. | Eigene API-Konsistenzregel. |
| CM01 | Math/Linear teilen Werte, zwei Controller bleiben unabhängig. Beide Eingabearten und alle vier IO-Wahlen prüfen. | Bestehender Projektvertrag. |
| CM02 | Menü/OFF/ON, direkter Eingabeartwechsel und wiederholte/abweichende Tasten lassen keine zweite Speicheraktion durch. Direkte Ursprungsänderung bricht STO ab; reine Ans-/M-Änderung nicht. Abbruch rollt externe Änderungen nicht zurück. | Eigener Routing-/API-Vertrag. |
| CM03 | M-Token: fehlender Kontext, Vorzeichen, Klammern, Postfix, Bruchübernahme, Source-Map und Größenbudget gezielt prüfen. | Neue Core-Abnahme. |
| CM04 | Dialogtext, STO-/M-Indikator, Semantik, 320-Pixel-Breite, Hardware-Ereignisse und klare Trennung noch fehlender Variablen prüfen. | Neue App-Abnahme. |

## Umsetzungsreihenfolge

1. **M-Operand im Core:** expliziter Kontext in Parser/Auswertung, Weitergabe in Speicher und strukturierten APIs, atomarer Editorbaustein samt Capture/Source-Map; unabhängige Tests. Noch keine neue ALPHA-/STO-Tastenfreischaltung.
2. **Sitzungsaktionen für STO und RECALL.** `prepareMemoryAssignment()` liefert bei gültiger Eingabe einen sitzungseigenen Kandidaten mit exaktem Wert. `commitMemoryAssignment()` übernimmt einen gültigen Kandidaten einmalig und meldet Erfolg als `bool`. `cancelMemoryAssignment()` verwirft den Kandidaten. Eine neue Ausführung derselben Sitzung verbraucht die Vorbereitung auch bei gleichem Ergebnis. `recallMemory()` lädt M als eigenen Ausdruck und aktualisiert Ans gemäß der Prototypregel.
3. **Zuweisung und Abruf in der App.** Eigener Dialogzustand, Norm-1-Vorschauformatierung und priorisiertes Eingaberouting. Controller- und Widgettests prüfen die Tastenfolgen. Eigene Vorschauen dokumentieren die Dialoge.

Eine bloße Verwendung von `applyMemory(store)` beim Öffnen oder eine Recall-Anzeige mit dem alten Ausdruck erfüllt diesen Vertrag nicht. Fehlende Originalsoftware blockiert diese eigene Implementierung nicht; offene Kompatibilitätsfragen bleiben als solche dokumentiert.
