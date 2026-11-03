# Fakultät über SHIFT und x⁻¹

Vertrag vom 03.11.2026. Die vorhandenen Quellen belegen SHIFT → x⁻¹ als Fakultät (H, physische PDF-S. 19/21/29), das Beispiel `(5+3)! = 40320` (H, PDF-S. 21) und die Domäne ganzer Zahlen von 0 bis 69 (H, PDF-S. 51). Vorhandene Quellenanalysen werden dafür nicht wiederholt.

## Rechenvertrag

`!` ist ein eigenes Postfixtoken. Der Parser erzeugt einen unären Fakultätsknoten mit der Position des Ausrufezeichens und dem vollständigen vorherigen Basisausdruck. Der Evaluator wertet diesen zunächst exakt rational aus. Nur gekürzte ganze Werte von 0 bis 69 sind zulässig; negative, nichtganze und größere Werte ergeben einen Mathematikfehler am Ausrufezeichen. Eine gebrochene Schreibweise wie `(6/3)!` ist zulässig, weil der ausgewertete Wert ganz ist. Ein vorgelagerter Fehler, etwa Division durch null, behält seine eigene Fehlerposition.

`0! = 1`, `1! = 1`, `5! = 120`, `(5+3)! = 40320`. Die Berechnung erfolgt mit BigInt ohne Gleitkomma oder Gammafortsetzung. Die Domänenprüfung erfolgt vor Umwandlung in eine kleine Schleifenzahl. Pro Fakultät sind höchstens 68 Multiplikationen nötig; jede zählt zusätzlich zu den AST-Besuchen gegen das bestehende gemeinsame Arbeitsbudget 2048. Die vorhandenen Tiefen-, Eingabe-, Knoten- und Wertebitbudgets bleiben bestehen. Eine Überschreitung des Arbeitsbudgets ist ein Ressourcenfehler, die einzelne Eingabe 70 dagegen ein Domänenfehler.

Die eigene Prototypgrammatik bleibt erhalten: Postfixe bauen sich von links nach rechts vor gewöhnlichem rechtsassoziativem `^` auf, ein Vorzeichen steht außerhalb. Daher `-5! = -120`, aber `(-5)!` ist ein Mathematikfehler. `3!! = 720`; `4!!` ergibt exakt `24!`, erst `4!!!` scheitert an der Domäne. Gemischte Ketten wie `3!² = 36`, `3²! = 362880`, `50%!` als Domänenfehler und `5!% = 6/5` folgen dieser eigenen Grammatik. Diese Ketten sind keine nachgewiesenen Originalabläufe. Doppeltes `!` bezeichnet bei uns wiederholte Fakultät und keine Doppelfakultät.

## Sitzung und App

`CalculatorKey.factorial` mit ID `ACTION_FACTORIAL` ist eine sekundäre semantische Aktion. Das Core-Enum wächst auf 30 Aktionen, die strukturierte Sitzung ergänzt weiterhin drei lokale Bruch-/Richtungsaktionen. Es bleiben 50 physische Tasten und 31/34 Primärbelegungen in Linear/Math.

Während der Bearbeitung fügt die Aktion genau ein Editortoken am aktuellen Cursor ein, auch innerhalb eines Bruchfelds. Ohne Basis entsteht erst bei `=` ein Syntaxfehler. Nach einem Ergebnis beginnt die Aktion mit exakt gebundenem `Ans!`; eine gerundete oder periodische Anzeige wird nicht zur Eingabe gemacht. Fehlerphase, Pfeilwiederaufnahme, AC und DEL folgen den bestehenden Regeln. Unmarkierte Postfixketten werden weiterhin nicht automatisch als Zähler übernommen; geschlossene Gruppen bleiben explizit übernehmbar.

SHIFT → x⁻¹ sendet die Aktion an die aktive Sitzung und verbraucht SHIFT. x⁻¹ allein berechnet weiterhin den Kehrwert. Menü, ausgeschalteter Zustand und SHIFT-Abwahl behalten ihre Regeln. Die natürliche Formelbeschreibung nennt `!` „Fakultät“. Eine neue direkte Hardwarezuordnung gehört nicht zu diesem Paket.

## Prüfung

Corefälle prüfen Handbuchbeispiel und Randwerte, unabhängige mathematische Erwartungen, exaktes Ans, Syntax-/Domänenfehler, Quellpositionen, Cursor/Felder und Ressourcenbudgets. Unabhängige Controller-/Widgetfälle betätigen die sichtbaren Tasten in beiden Eingabearten. Eine zusätzliche Vorschau soll `(5+3)! = 40320` zeigen. Tatsächliche Ausführung und visuelle Prüfung stehen anschließend im [Entwicklungsstand](ENTWICKLUNGSSTAND.md). Bis dahin sind neue Fälle vorbereitet. Originalvergleich, vollständige Anzeige-/Rundungskompatibilität und native Gerätetests bleiben offen.
