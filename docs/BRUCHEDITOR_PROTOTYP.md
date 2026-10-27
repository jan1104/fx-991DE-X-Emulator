# Strukturierter Brucheditor: erster Core-Prototyp

Stand: 27.10.2026. Der unabhängige Editor und seine natürliche Flutter-Ansicht sind inzwischen über eine getrennte strukturierte Sitzung in der Hauptansicht nutzbar. Die bisherige lineare Sitzung bleibt als eigene Eingabeart erhalten. Aktuelle Integration und eigene Bedienregeln: [STRUKTURIERTE_SITZUNG.md](STRUKTURIERTE_SITZUNG.md).

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

Nicht im Editorbaustein enthalten sind gemischte Brüche, Wurzeln, hochgestellte Eingabefelder, Auswahl/Übernahme vorhandener Operanden und vertikale Cursorbewegung. Ergebnisphasen und Wahl der Eingabeart sind inzwischen in der strukturierten Sitzung beziehungsweise App ergänzt. Die Taste `KEY_FRACTION` ist in der Hauptansicht nach Wahl von **Brüche** aktiv; in Linear bleibt sie deaktiviert.

## Lesende Flutter-Formelansicht

`apps/calculator/lib/presentation/editor/fraction_expression_view.dart` stellt einen bestehenden Snapshot als natürliche Formel dar. `FractionExpressionView(snapshot: editor.snapshot)` zeichnet Bruchstriche, verschachtelte Felder, Rahmen für leere Felder und genau einen Pfadcursor. Mit `showCursor: false` lässt sich die Formel ohne Cursor darstellen. Die Komponente selbst verändert keine Rechendaten; die Hauptansicht verbindet sie inzwischen mit der strukturierten Sitzung.

Ein eigener Zwei-Kind-Renderbaustein misst Zähler und Nenner, zentriert die Felder und zeichnet den Bruchstrich. Die äußeren mathematischen Achsen bleiben auch bei unterschiedlich hohen Nachbarbrüchen ausgerichtet. Rekursive IntrinsicWidth-Durchläufe werden vermieden. Die Textvergrößerung wird auch auf Cursor und Platzhalter angewendet. Breite Formeln können horizontal, hohe Formeln bei begrenzter Höhe vertikal gescrollt werden. Mit `followCursor: true` wird der Cursor nach Eingabe/Navigation in den beiden inneren Scrollbereichen sichtbar gehalten; die Hauptansicht verwendet diese Option.

Für assistive Ausgabe enthält die Ansicht eine zusammenhängende deutsche Formelbeschreibung mit expliziten Zähler-/Nennergrenzen. Einzelne dekorative Text-/Cursorwidgets werden nicht zusätzlich vorgelesen. Dies ist ein Widget-Semantiknachweis; Prüfung mit echten Screenreadern, Fokussteuerung einzelner Felder und gesprochene Cursorposition bleiben offen.

Die lokale visuelle Prüfung lässt sich im Appordner mit `flutter test tool/render_fraction_preview.dart --no-pub` aufrufen. Sie erzeugt `build/reports/fraction-view.png` im Repository (ignoriert). Wie der bisherige Vorschauhelfer lädt sie ausschließlich lokal eine Systemschrift, ohne sie als Appasset zu verteilen. Die QA-Seite ist kein neuer Appmodus und kein nativer Gerätetest.

## Nächster Schritt

Fehlerpositionen auf Feldpfade abbilden und deren gezielte Wiederaufnahme prüfen. Vertikale Navigation, gemischte Brüche und Übernahme vorhandener Operanden bleiben weitere Pakete. Das Modell ist absichtlich noch keine stabile öffentliche Langzeit-API.
