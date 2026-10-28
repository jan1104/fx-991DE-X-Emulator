# Einen vorhandenen Baustein als Zähler übernehmen

Stand: 28.10.2026. Die eigene Appaktion **Als Zähler** übernimmt einen vorhandenen Baustein in eine neue Bruchvorlage. Sie ist eine zusätzliche explizite Bearbeitungshilfe und verändert die Primärbelegung der physischen Bruchtaste nicht. Eine Original-Kompatibilität dieser Aktion wird nicht behauptet.

## Umfang

In der Eingabeart **Brüche** steht unter der Formel ein Textbutton **Als Zähler** mit einer Erklärung. Er wirkt nur während der Bearbeitung, wenn links vom Cursor ein Token vorhanden ist. In Ergebnis-/Fehlerphase und am Feldanfang ist er deaktiviert; in Linear ist er nicht sichtbar. Ein Hardwarekürzel ist nicht vergeben.

Übernommen wird genau ein zulässiger Baustein unmittelbar links vom Cursor im aktuellen Feld:

- Eine ganze zusammenhängende Folge aus Ziffern und Dezimaltrennern, sofern sie als Dezimalzahl gültig ist. Komma und Punkt bleiben in ihrer bisherigen Schreibweise erhalten. Ein Cursor mitten in einer solchen Folge wird ausdrücklich abgewiesen, statt die Zahl aufzuteilen.
- Das atomare Token `Ans`.
- Ein vollständiger vorhandener Bruchknoten einschließlich seiner verschachtelten Felder.

Der Baustein wird Zähler einer neuen Vorlage mit leerem Nenner. Der Cursor landet am Nenneranfang. Vorherige und nachfolgende Nachbarknoten bleiben erhalten. Ein führendes Minus wird nicht mitgenommen; es bleibt außerhalb des neuen Bruchs. Operatoren, Klammergruppen und vollständige Potenzketten werden nicht automatisch als zusammengehörige Ausdrücke erkannt. Bei `2^3` würde nur die Zahl `3` übernommen, nicht die gesamte Potenz; dieser begrenzte atomare Vertrag ist ausdrücklich kein allgemeiner Termselektor.

Die bisherige Bildschirmtaste `□/□` fügt weiterhin eine **leere** Vorlage am Cursor ein. Sie übernimmt keine Nachbarn. Die 50 physischen Tastenplätze behalten somit ihre bisherige Aktivierung: 28 in Brüche, 25 in Linear. Die zusätzliche Appaktion wird getrennt gezählt.

## Beispiele

| Ausgang unmittelbar vor der Aktion | Weitere Eingabe | Ergebnis |
|---|---|---|
| `12│` | Als Zähler, `3`, `=` | `12/3 = 4` |
| `0,5│` | Als Zähler, `2`, `=` | `(0,5)/2 = 1/4` exakt |
| `2+3│` | Als Zähler, `2`, `=` | `2+3/2 = 7/2`; das Plus wird nicht übernommen |
| `12│+3` | Als Zähler, `2`, `=` | `12/2+3 = 9`; der vorhandene Suffix bleibt erhalten |
| Vorhandener Bruch `1/2`, Cursor direkt dahinter | Als Zähler, `3`, `=` | `(1/2)/3 = 1/6` |
| `12│34` | Als Zähler | Abgewiesen; keine Aufteilung in `12` und `34` |

`│` bezeichnet die logische Cursorposition und ist kein Zeichen der Formel. Bei Dezimalzahl-/Ansübernahme wird kein Ergebnis in gerundeten Text zurückverwandelt.

## Corevertrag und Schutzgrenzen

`FractionEditor.wrapPreviousAtomInFraction()` veröffentlicht erst nach vollständiger Prüfung einen neuen Snapshot. Ein fehlender oder unzulässiger Vorgänger sowie ein Cursor innerhalb einer Zahl führen zu `CalculatorException(unsupported)`. Eine fehlerhafte zusammenhängende Dezimalfolge erzeugt `syntax`. Der alte Baum und Cursor bleiben bei jeder Ablehnung unverändert.

Die Übernahme fügt genau einen Bruchknoten hinzu. Das Budget bleibt bei 256 Gesamtknoten und 16 Verschachtelungsebenen. Beim Übernehmen eines vorhandenen Bruchs wird die Tiefe des **gesamten** Kandidatenbaums geprüft: Alle Nachkommen des übernommenen Knotens rücken um eine Ebene nach innen, auch wenn der aktuelle Cursor selbst an der Wurzel steht. Eine reine Prüfung der Cursorpfadlänge würde diesen Fall übersehen.

`StructuredCalculatorSession.pressId('ACTION_WRAP_FRACTION')` bindet diese eigene Appaktion an. In Ergebnis-/Fehlerphase ist der direkte Coreaufruf wirkungslos und erhält denselben Snapshot. Während der Bearbeitung werden Ablehnungen als bestehende strukturierte Fehlerphase dargestellt, ohne Baum oder Ans zu verlieren. Die lineare Sitzung und ihr 25-Tasten-Enum bleiben unverändert.

## Prüfungen und nächste Grenze

Core- und Widgetfälle sowie tatsächliche Gesamtläufe sind im [Entwicklungsstand](ENTWICKLUNGSSTAND.md) dokumentiert. Geprüft werden gültige Atome, Cursor-/Nachbarknoten, Dezimalfehler, Phasen, unveränderliche Snapshots und die beiden Ressourcenlimits einschließlich versteckter Unterbaumtiefe. Die Katalogdaten zum Original werden dadurch nicht pauschal als bestanden markiert.

Als nächstes eine ausdrücklich begrenzte Übernahme vollständig geschlossener Klammergruppen spezifizieren. Allgemeine Termauswahl, Vorzeichen-/Potenzketten, automatische Übernahme durch die Original-Bruchtaste und Undo/Entpacken bleiben offen.
