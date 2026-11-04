# Betragsfunktion: Core und getrennter Editorvertrag

Vertrag vom 04.11.2026. H, physische PDF-S. 21, belegt die Betragsfunktion über SHIFT → ( und `|2−7| × 2 = 10`. Im Handbuch verlässt Math das Argument per Rechtspfeil, während Linear die Funktionsklammer mit `)` abschließt. Der vorhandene Editor hat bisher Text- und Bruchknoten, aber kein eigenes Funktionsargument. Ein bloß eingefügter Text würde die natürliche Feldnavigation nicht abbilden.

Dieses Paket ergänzt deshalb zunächst die exakte Core-Auswertung von `Abs(...)` und einen konkreten [Entwurf für das Argumentfeld](BETRAG_EDITOR.md). Die sichtbare App-Taste, der lineare Aktionsadapter und das natürliche Betragsfeld folgen als eigenes Paket. Die App behält ihre bisherigen Primär-/SHIFT-Belegungen, das Core-Tastenenum unverändert 32 Aktionen; SHIFT → ( meldet weiterhin den Vorbereitungsstatus. Das Fehlen der Originalsoftware blockiert diese eigene Implementierung nicht.

## Auswertungsvertrag

Der Parser erkennt genau den Funktionsnamen `Abs`, eine öffnende Klammer, einen vollständigen Ausdruck und eine ausdrückliche schließende Klammer. Leerraum zwischen Tokens ist zulässig. Leere Argumente oder fehlende Klammern sind Syntaxfehler. Die eingeschränkte implizite Multiplikation bleibt unverändert: `2*Abs(-3)` ist gültig, `2Abs(-3)` nicht. Der hier zwingende Klammerabschluss behauptet noch keine vollständige Originalkompatibilität automatischer Abschlüsse.

Ein unärer AST-Knoten `UnaryOperator.absolute` trägt die Position des `A`. Der rationale Operand wird zunächst über den vorhandenen Evaluator ausgewertet. Ein negativer Wert wird exakt negiert, ein nichtnegativer bleibt unverändert; Ergebnis und Ans-Kontext werden nicht gerundet und kein Gleitkomma verwendet. Operandfehler behalten ihre Position. Eine zusätzliche Mathematikdomäne ist für rationale Beträge nicht nötig. Komplexe Zahlen und deren Betrag sind nicht Bestandteil des aktuellen Zahlenmodells.

| Ausdruck | Exakter Erwartungswert |
|---|---|
| `Abs(2-7)*2` | 10 |
| `Abs(-2/3)` | 2/3 |
| `Abs(0)` | 0 |
| `Abs(Abs(-3)-5)` | 2 |
| `-Abs(-5)` | −5 |
| `Abs(-3)²` | 9 |
| `2^Abs(-3)` | 8 |
| `Abs(-5)nCr2` | 10 |

Die bisherigen Vorzeichen-, Postfix-, Potenz- und Binärregeln gelten unverändert; gemischte Beispiele spezifizieren unsere Grammatik und sind keine protokollierten Originalabläufe. Ein ausdrücklich übergebener negativer Ans-Wert bleibt ein einzelner rationaler Kontextwert in `Abs(Ans)`.

## Grenzen und Prüfung

Die bestehenden Limits für Eingabezeichen (2048), Tokens (512), Parserrekursion, Auswertungstiefe, Wertebits und gemeinsames Arbeitsbudget (2048) bleiben erhalten. Ein Betragsknoten verbraucht wie andere AST-Knoten einen Besuch. Auch direkte öffentliche ASTs werden durch den vorhandenen Evaluator begrenzt. Neue Abhängigkeiten oder Werkzeugversionen sind dafür nicht erforderlich.

Gezielte Corefälle prüfen unabhängige exakte Ergebnisse, geschachtelte Argumente, Ans, AST-/Fehlerpositionen, falsche Funktionsnamen, Klammerfehler und Ressourcenränder. Die vorhandenen App-Tests und 15 Vorschauszenarien prüfen die Regression des bisherigen sichtbaren Umfangs; sie sind keine App-Betragsprüfung. Die erfolgreiche tatsächliche Core-Ausführung und App-Regression stehen für die geprüfte Revision im [Entwicklungsstand](ENTWICKLUNGSSTAND.md). Der Editorentwurf ist Planungsarbeit und kein implementiertes oder bestandenes Betragsfeld. Originalvergleich und native Gerätetests bleiben offen.
