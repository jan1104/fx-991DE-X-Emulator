# Strukturierter Brucheditor: erster Core-Prototyp

Stand: 27.10.2026. Dies ist der erste unabhängige Baustein für natürliche Eingabe, noch keine neue App-Bedienart. Die bisherige lineare Sitzung und die 25 aktiven Bildschirmaktionen bleiben unverändert.

## Daten und Bedienvertrag

`FractionEditor` im Dart-Core verwaltet einen unveränderlichen Baum aus `EditorSequence`, atomaren `EditorText`-Tokens und `EditorFraction` mit getrennten Zähler-/Nennerfeldern. Alte Snapshots bleiben lesbar und unverändert. Der Cursor besteht aus einem Feldpfad und einem Tokenoffset; er benötigt weder Pixel noch Flutter.

- `insertText()` fügt genau eine Ziffer, einen Grundoperator, eine Klammer, Dezimalzeichen oder das atomare Token `Ans` ein. Andere Eingaben werden vor der Zustandsänderung abgewiesen.
- `insertFraction()` fügt am Cursor eine leere Bruchvorlage ein und betritt deren Zähler. Vorhandene Nachbarn werden dabei nicht automatisch in den Bruch übernommen.
- Rechts durchläuft Zähler, Nenner und anschließend die Elternsequenz; Links läuft umgekehrt. An den äußersten Grenzen bleibt der Cursor stehen. Verschachtelte Brüche folgen denselben Regeln.
- DEL entfernt den vollständigen vorherigen Knoten im aktuellen Feld. Unmittelbar hinter einem Bruch entfernt es damit dessen ganzen Teilbaum; am Feldanfang bleibt alles erhalten. Es findet kein automatisches Zusammenziehen mit dem Elternfeld statt.
- `clear()` leert Baum und Cursor.

Diese Navigations-/Löschregeln sind bewusst kleine eigene Prototypentscheidungen. Sie sind nicht durch Beobachtung der Originalsoftware bestätigt und noch kein vollständiger Nachbau der natürlichen Casio-Eingabe. Handbuchbezüge und geplante Bruchfälle wurden bereits in [TASTEN_UND_BEDIENUNG.md](TASTEN_UND_BEDIENUNG.md) und [REFERENZTESTS.md](REFERENZTESTS.md) dokumentiert; sie werden hier nicht als zusätzlich bestanden ausgegeben.

## Rechnung und Grenzen

`toExpression()` projiziert einen Bruch als vollständig geklammerten Operanden `((Zähler)/(Nenner))`. `evaluate(answer: ...)` verwendet die vorhandene exakte rationale Auswertung; es gibt keine zweite Rechenimplementierung. Leere Root/Zähler/Nenner sind Syntaxfehler statt stillschweigender Nullen. Division durch null und weitere mathematische Fehler kommen aus dem bestehenden Evaluator. Auswerten verändert den Editor nicht und speichert kein Ans automatisch.

Klammern müssen in jeder Sequenz für sich ausgeglichen sein. Ein ungültiger Zähler `1)` und Nenner `(2` darf nicht durch die Projektionsklammern zu einer scheinbar gültigen Rechnung werden. Diese Feldgrenze wird bereits vor der Parserauswertung geprüft.

Der Editor begrenzt sich auf 256 Gesamtknoten und 16 verschachtelte Brüche. Überschreitungen werfen `CalculatorException(limit)` und erhalten den alten Snapshot. Ungültige Tokens werfen `ArgumentError`. Dies sind eigene Schutzbudgets, keine belegten Gerätegrenzen. Die nachgelagerte lineare Parserauswertung hat zusätzlich eigene Längen-, Token- und Tiefenlimits; nicht jeder maximal große Editorbaum muss auswertbar sein.

Die lineare Grammatik bleibt begrenzt: Produkte sollten mit `*` eingegeben werden. Zahlen vor einer öffnenden Klammer erlauben die bisherige implizite Multiplikation; unmittelbar nach einer schließenden Klammer folgt eine Zahl/Ans ohne Operator weiterhin als Syntaxfehler. Der Prototyp erweitert die allgemeinen Vorrangregeln des Parsers nicht. Fehlerpositionen sind Offsets der projizierten Zeichenkette und noch keine Zuordnung zu einem Feldpfad.

Nicht enthalten sind gemischte Brüche, Wurzeln, hochgestellte Eingabefelder, Auswahl/Übernahme vorhandener Operanden, vertikale Cursorbewegung, Ergebnisphasen, Modusumschaltung und Flutter-Darstellung. Auch die Taste `KEY_FRACTION` bleibt in der App bis zur gesonderten Anbindung deaktiviert.

## Nächster Schritt

Ein Flutter-Widget für Baum, Bruchstrich, leere Felder und Pfadcursor ergänzen und geometrisch sowie visuell prüfen. Erst danach die Bruchtaste über eine ausdrücklich getrennte strukturierte Sitzung anbinden; Fehlerpfade, Ans und die bestehenden linearen Übergänge dabei gemeinsam festlegen. Das Modell ist absichtlich noch keine stabile öffentliche Langzeit-API.
