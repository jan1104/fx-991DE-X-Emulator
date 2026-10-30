# Kehrwerttaste und atomare Postfixeingabe

Stand: 30.10.2026. Die Primäraktion `KEY_RECIPROCAL` ergänzt den eigenen rationalen Rechenkern. Das vorhandene Inventar belegt x⁻¹ als Kehrwert (H, physische PDF-S. 19/21/29). SHIFT-Fakultät, ALPHA-Variable C und Hexadezimalbelegungen werden dadurch nicht umgesetzt. Ein Originalvergleich ist weiterhin offen.

## Rechenvertrag

`⁻¹` ist ein einzelnes logisches Editortoken aus zwei UTF-16-Zeichen. Der Lexer erkennt ausschließlich die zusammenhängende Zeichenfolge; ein alleinstehendes hochgestelltes Minus oder eine alleinstehende hochgestellte Eins ist kein gültiger Operator. Cursor und DEL behandeln das vollständige Token atomar, Parserpositionen bleiben Zeichenoffsets.

Quadrat und Kehrwert binden als Postfixoperatoren an den vorherigen Primärausdruck und werden in Eingabereihenfolge aufgebaut. Ein folgendes gewöhnliches `^` und dessen Rechtsassoziativität behalten den bestehenden Vertrag. Der Evaluator verwendet dafür die vorhandene exakte ganzzahlige Potenz mit Exponent −1.

| Eingabe | Eigene Erwartung |
|---|---|
| `4⁻¹` | `1/4` |
| `4⁻¹⁻¹` | `4` |
| `-2⁻¹` | `-1/2` |
| `(-2)⁻¹` | `-1/2` |
| `(2/3)⁻¹` | `3/2` |
| `2²⁻¹` oder `2⁻¹²` | `1/4` |
| `2^2⁻¹` | nicht unterstützte nichtganzzahlige Potenz |
| `2⁻¹^2` | `1/4` |
| `0⁻¹` | mathematischer Fehler am Kehrwertoperator |

Diese Beispiele spezifizieren den begrenzten Prototyp. Sie sind kein Nachweis aller originalen Prioritäts-, Anzeige- oder Bereichsregeln.

## Bedienung und Grenzen

Während der Bearbeitung fügt die Taste das Token am Cursor ein. Eine leere Eingabe erhält zunächst nur `⁻¹`; erst `=` meldet den fehlenden Operanden. Nach einem erfolgreichen Ergebnis beginnt die Taste dagegen mit `Ans⁻¹`. Auch negatives und gebrochenes Ans bleibt ein ausdrücklich gebundener Zahlenwert. Null als Ans erzeugt den gleichen mathematischen Fehler. Fehlerphase, AC, Pfeilwiederaufnahme und unverändertes Ans bei Fehlern folgen den vorhandenen Sitzungsregeln.

Natürliche Bruchfelder erlauben das Token ebenso. Die Source-Map ordnet beide Zeichen demselben Editortoken zu. Ein Kehrwert hinter einem vollständigen Bruch wirkt auf dessen geklammerte Projektion. Die eigene Aktion **Als Zähler** wählt weiterhin keine vollständigen Postfixketten automatisch aus; für eine solche Übernahme eine geschlossene Gruppe wie `(4⁻¹)` verwenden.

Das gemeinsame Register aktiviert in der vorbereiteten App 27 Primäraktionen in Linear und 30 in Brüche, bei unverändert 50 physischen Plätzen. Die natürliche assistive Beschreibung nennt das Token „Kehrwert“. Es gibt kein neues Hardwarekürzel und keinen allgemeinen Exponentenfeldeditor.

## Prüfstatus

Corefälle unter `packages/calculator_core/test/reciprocal_key_test.dart` und vorbereitete Widgetfälle unter `apps/calculator/test/reciprocal_key_test.dart` prüfen beziehungsweise planen diese Regeln. Tatsächliche Prüfläufe und Zahlen stehen im [Entwicklungsstand](ENTWICKLUNGSSTAND.md). Der bekannte Windows-Code-Integrity-Block des Flutter-Testcompilers wird nicht umgangen; Appausführung und neue visuelle Prüfung bleiben offen. Die zuletzt ausgeführten 144 Apptests gehören zum Stand vor Quadrat und Kehrwert.

Nach Wiederherstellung einer richtlinienkonform ausführbaren Testumgebung zuerst Quadrat-/Kehrwertfälle, vollständige Appsuite und Vorschauen ausführen. Unabhängig davon kann als nächstes eine ausdrücklich ausgelöste exakte Bruch-/Dezimalanzeige spezifiziert werden; Rundung und nicht endliche Dezimalbrüche brauchen dabei einen eigenen Vertrag.
