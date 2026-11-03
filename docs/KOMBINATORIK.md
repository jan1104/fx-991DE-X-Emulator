# Permutationen und Kombinationen

Vertrag vom 03.11.2026 mittags. Vorhandene Quellen belegen SHIFT → × als nPr, SHIFT → ÷ als nCr sowie `10 nPr 4 = 5040` und `10 nCr 4 = 210` (H, physische PDF-S. 21). Die Prioritätentabelle ordnet nPr/nCr unter impliziter und über gewöhnlicher Multiplikation/Division ein; gleichrangige Operatoren arbeiten von links nach rechts (H, PDF-S. 10–11). Vorhandene Analysen wurden nicht vollständig wiederholt. Die bisher nur extrahierte Domänentabelle wurde gezielt auf der gerenderten PDF-S. 51 visuell kontrolliert.

## Argumente und Zwischenwertgrenzen

Beide Argumente werden zuerst exakt rational ausgewertet. Nach Kürzung müssen sie ganz sein und `0 ≤ n < 10^10`, `0 ≤ r ≤ n` erfüllen. Ein ungültiges Argument ergibt einen Mathematikfehler am nPr-/nCr-Operator; ein bereits bei der Argumentberechnung auftretender Fehler behält seine eigene Position.

Die visuell bestätigte Tabelle begrenzt für nPr `n!/(n−r)!` auf Werte kleiner als `10^100`. Für nCr muss mindestens einer der Zwischenquotienten `n!/r!` oder `n!/(n−r)!` kleiner als `10^100` sein. Der zulässige Endwert allein reicht deshalb bei nCr nicht aus. Beispielsweise ist `200 nCr 100` trotz mathematisch kleinerem Endwert nicht in dieser belegten Domäne. Es wird keine Gleitkomma- oder Gammafortsetzung verwendet.

Für nPr wird das fallende Produkt `F(n,r) = n·(n−1)·…·(n−r+1)` direkt berechnet. Für nCr setzt die eigene Implementierung `k = min(r,n−r)`: Das kleinere der beiden Zwischenprodukte ist `F(n,k)`. Weil alle Faktoren positive ganze Zahlen sind, gilt die ODER-Bedingung genau dann, wenn dieses kleinere Produkt die Grenze einhält. Danach ist das exakte Ergebnis `F(n,k)/k!`. Leere Produkte ergeben 1, also auch `0 nPr 0`, `0 nCr 0` und `n nCr n`.

Ist die nötige Faktorzahl größer als 69, ist der Zwischenwert bereits nachweislich unzulässig: `F(n,k) ≥ k! ≥ 70! > 10^100`. Die Prüfung erfolgt vor einer Umwandlung in eine Schleifenzahl. Die übrigen Fälle benötigen höchstens 69 Durchläufe. Akzeptierte Zwischenprodukte sind kleiner als `10^100`; ein unmittelbar danach geprüftes Produkt hat höchstens 110 Ziffern, weil auch n kleiner als `10^10` ist. Das Produkt wird nach jeder Multiplikation auf die strikte Grenze geprüft. Große Eingaben führen daher nicht zu Milliarden Schleifendurchläufen. n bleibt BigInt.

Jede Produktmultiplikation zählt gegen das gemeinsame Arbeitsbudget 2048; bei nCr zusätzlich jede Nennerproduktmultiplikation und die abschließende exakte Division. Eine einzelne Domänenverletzung ist ein Mathematikfehler, ein ausgeschöpftes gemeinsames Arbeitsbudget ein Ressourcenfehler. Bisherige Zeichen-, Token-, Editor-, Tiefen- und Wertebitbudgets bleiben bestehen. Die exakte Rechnung belegt noch keine identische Originalrundung.

## Grammatik und Bedienung

`nPr` und `nCr` sind jeweils ein semantischer Operator und ein einzelnes Editortoken mit drei UTF-16-Zeichen. Der Parser baut binäre Knoten auf und speichert die Position des `n`. Beide Operatoren binden gleich stark und linksassoziativ, schwächer als implizite Multiplikation und stärker als gewöhnliches ×/÷. Die vorhandenen Vorzeichen-, Postfix- und Potenzregeln bleiben erhalten.

| Eigener Ausdruck | Erwarteter Wert |
|---|---|
| `2*5nCr2` | 20 |
| `10nPr2*3` | 270 |
| `2(3)nPr2` | 30 |
| `5nCr2nPr2` | 90 |
| `2^3nPr2` | 56 |

Diese gemischten Ausdrücke spezifizieren unsere Grammatik; sie sind keine beobachteten Originalabläufe. DEL entfernt einen ganzen Operator, Pfeile überspringen ihn als ein Token. Eine fehlende rechte Seite führt erst bei `=` zum Syntaxfehler. Nach einem Ergebnis beginnen die neuen Binäraktionen mit exakt gebundenem Ans; Ergebnisrundung und Periodenanzeige ersetzen den gespeicherten Wert nicht. Fehlerphase, Pfeilwiederaufnahme und Bruchfelder folgen den bisherigen Sitzungsregeln.

Die sekundären Aktionen `ACTION_PERMUTATION` und `ACTION_COMBINATION` erweitern das Core-Enum auf 32 Aktionen. Es bleiben 50 physische App-Tasten und 31/34 Primärbelegungen in Linear/Math. SHIFT → ×/÷ sendet die jeweilige Aktion und verbraucht SHIFT. ×/÷ allein bleiben gewöhnliche Multiplikation/Division. Menü, OFF und SHIFT-Abwahl behalten ihre Regeln. Die natürliche Formelbeschreibung nennt „Permutation“ und „Kombination“. Neue direkte Hardwarezuordnungen gehören nicht zum Paket. Die eigene Zählerübernahme errät weiterhin keine ungruppierten Operatorketten.

## Prüfung

Corefälle prüfen unabhängige mathematische Werte und Identitäten, die Handbuchbeispiele, Zwischenwertgrenzen, Symmetrie, Prioritäten, exaktes Ans, Token-/Quellpositionen, Cursor, Fehlerphasen und Ressourcenbudgets. Unabhängige Controller-/Widgetfälle betätigen SHIFT und die sichtbaren ×/÷-Tasten in beiden Eingabearten. Zwei zusätzliche ausgeführte und visuell geprüfte Vorschauen zeigen `10 nPr 4 = 5040` und `10 nCr 4 = 210`. Tatsächliche Ausführung und visuelle Grenzen sind im [Entwicklungsstand](ENTWICKLUNGSSTAND.md) für die geprüfte Revision festgehalten. Native Gerätetests und Originalvergleich bleiben offen.
