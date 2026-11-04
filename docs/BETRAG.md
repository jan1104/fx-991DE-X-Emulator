# Betragsfunktion: Core, Argumentfeld und App

Vertrag vom 04.11.2026. H, physische PDF-S. 21, belegt die Betragsfunktion über SHIFT → ( und `|2−7| × 2 = 10`. Im Handbuch verlässt Math das Argument per Rechtspfeil, während Linear die Funktionsklammer mit `)` abschließt. Der Editor ergänzt dafür einen eigenen `EditorAbsolute`-Knoten mit Argumentfeld und natürlichen Betragsstrichen.

Nach der getrennt geprüften Core-Auswertung ist jetzt SHIFT → ( in beiden Eingabearten angebunden. Math betritt ein eigenes Argumentfeld und verlässt es per Rechtspfeil; Linear fügt das atomische Präfix `Abs(` ein und schließt es ausdrücklich mit `)`. Der [übernommene Editorvertrag](BETRAG_EDITOR.md) legt Navigation, Löschen, Projektion und Grenzen fest. Das Core-Tastenenum umfasst 33 Aktionen; die App behält 50 physische Tasten und 31/34 Primärbelegungen. Das Fehlen der Originalsoftware blockiert diese eigene Implementierung nicht.

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

Gezielte Corefälle prüfen unabhängige exakte Ergebnisse, geschachtelte Argumente, Ans, AST-/Fehlerpositionen, falsche Funktionsnamen, Klammerfehler und Ressourcenränder. Die Appprüfung ergänzt echte Betragsbedienfolgen in Math und Linear; drei neue Vorschauszenarien prüfen Handbuchrechnung, negativen Bruch und leeres Argument. Die erfolgreiche tatsächliche Core-Ausführung und App-Regression stehen für die geprüfte Revision im [Entwicklungsstand](ENTWICKLUNGSSTAND.md). Der frühere Editorentwurf wird im Folgepaket als Umsetzungsvertrag übernommen; dessen tatsächlicher Abnahmestand steht im Entwicklungsstand. Originalvergleich und native Gerätetests bleiben offen.
