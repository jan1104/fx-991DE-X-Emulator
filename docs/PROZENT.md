# Prozent über SHIFT und Ans

Vertrag vom 02.11.2026 abends. Das vorhandene Tasteninventar belegt SHIFT → Ans als `%` (H, physische PDF-S. 13). Die vorhandene Handbuchtextextraktion beschreibt Prozent als nachgestellte Funktion (H, PDF-S. 10) und liefert drei konkrete Rechnungen (H, PDF-S. 13):

| Eingabe | Exakter Erwartungswert |
|---|---|
| `150*20%` | 30 |
| `660/880%` | 75 |
| `3500-3500*25%` | 2625 |

## Begrenzter eigener Rechenvertrag

Ein `%` teilt seinen unmittelbaren Basisausdruck exakt durch 100. Es ist ein eigenständiges Postfixtoken und kein als Text angehängtes `/100`. Deshalb ergibt `660/880%` den Ausdruck `660/(880/100)`. Eine automatische kaufmännische Umdeutung von `150+20%` zu einer Erhöhung um 20 Prozent erfolgt nicht: Unser Ausdruck bedeutet `150+20/100 = 751/5`. Für die Erhöhung oder Verringerung ist der Grundwert wie im Handbuchbeispiel ausdrücklich zu multiplizieren.

Die vorhandene Prototypgrammatik bleibt erhalten: Postfixe werden in Eingabereihenfolge vor gewöhnlichem rechtsassoziativem `^` aufgebaut, Vorzeichen stehen außerhalb. Damit ergeben sich beispielsweise `20%% = 1/500`, `20%² = 1/25`, `20²% = 4`, `-20% = -1/5`, `(1/2)% = 1/200` und `2%⁻¹ = 50`. Kombinationen mit gewöhnlichen Potenzen folgen dieser eigenen Grammatik; `2^3%` führt zum bisher nicht unterstützten nichtganzzahligen Exponenten. Die Quellenbelege beweisen keine vollständige Originalkompatibilität dieser gemischten Schreibweisen. Ein natürlicher Exponentenfeldeditor bleibt offen.

Der Parser erzeugt einen Divisionsbaum mit Nenner 100 und Fehlerposition am Prozentzeichen. Evaluator und bisherige Zeichen-, Token-, Tiefen-, Knoten- und Größenbudgets bleiben erhalten. Ein eingefügtes Prozentzeichen ist genau ein Editortoken und ein UTF-16-Zeichen. Ohne Basis wird erst bei `=` ein Syntaxfehler gemeldet. Nach einem Ergebnis beginnt Prozent mit exakt gebundenem `Ans%`; weder gerundete Anzeige noch sichtbare Periode ersetzen den gespeicherten Wert. Fehlerphase, Pfeilwiederaufnahme, DEL und Bruchfelder folgen den bestehenden Sitzungsregeln.

`CalculatorKey.percent` mit ID `ACTION_PERCENT` ist eine sekundäre semantische Aktion. Das Core-Enum hat damit 29 Aktionen, die strukturierte Sitzung zusätzlich drei lokale Bruch-/Richtungsaktionen. Der physische Umfang bleibt 50 Tasten und 31/34 Primärbelegungen in Linear/Math. Die Zählerübernahme errät weiterhin keine ungruppierte Postfixkette; geschlossene Gruppen sind explizit übernehmbar.

## App und Prüfung

SHIFT → Ans sendet Prozent an die aktive Sitzung und verbraucht SHIFT. Ans allein behält seine bisherige Wirkung. Menü, ausgeschalteter Zustand und SHIFT-Abwahl behalten ihre bisherigen Regeln. Die natürliche Formelbeschreibung nennt `%` „Prozent“. Eine neue direkte Hardwarezuordnung ist nicht Bestandteil dieses Pakets.

Gezielte Coreprüfungen und unabhängige Controller-/Widgetfälle prüfen die drei Handbuchrechnungen, exakte Werte, Zustandsübergänge, Cursor und Grenzen. Die ausgeführte und visuell geprüfte zusätzliche Vorschau führt `150`, ×, `20`, SHIFT, Ans, `=` über die sichtbaren Tasten aus. Tatsächliche Testausführung und visuelle Prüfung sind im [Entwicklungsstand](ENTWICKLUNGSSTAND.md) für die geprüfte Revision festgehalten. Originalvergleich und native Gerätetests bleiben offen.
