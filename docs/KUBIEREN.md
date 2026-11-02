# Kubieren über SHIFT und x²

Vertrag vom 02.11.2026 nachmittags. Der vorhandene Quellenbefund belegt SHIFT → x² als x³ (H, physische PDF-S. 19/29; [Tasteninventar](TASTEN_UND_BEDIENUNG.md)). Die Basis-N-Umbelegung DEC und andere SHIFT-Belegungen sind damit nicht implementiert. Es wird keine erneute PDF-Gesamtanalyse benötigt.

## Eigener Core-Vertrag

`³` ist ein eigenständiges Postfixtoken. Es bindet wie Quadrat und Kehrwert an den vorherigen Primärausdruck und wird mit anderen Postfixen in Eingabereihenfolge aufgebaut. Normales `^` bleibt rechtsassoziativ. Kubieren wird nicht durch angehängten Text `^3` ersetzt, weil dies wiederholte Operationen falsch binden würde.

| Eingabe | Erwarteter exakter Wert |
|---|---|
| `3³` | 27 |
| `3³³` | 19683 |
| `-2³²` | −64 |
| `(-2)³²` | 64 |
| `2^3³` | 134217728 |
| `2³^3` | 512 |
| `(1/2)³` | 1/8 |
| `3³⁻¹` oder `3⁻¹³` | 1/27 |
| `0³` | 0 |

Der vorhandene rationale Evaluator berechnet den erzeugten Potenzbaum mit Exponent 3. Die bisherigen Zeichen-, Token-, Editor-, Tiefen- und Größenbudgets gelten weiter. Während der Bearbeitung fügt die semantische Aktion `ACTION_CUBE` ein einzelnes Token am Cursor ein; ohne Basis entsteht erst bei `=` ein Syntaxfehler. Nach einem Ergebnis beginnt die Aktion mit exakt gebundenem `Ans³`, auch bei negativem oder gebrochenem Ans. Fehlerphase, AC, DEL und Pfeilwiederaufnahme folgen den bisherigen Postfixregeln. Die Source-Map behandelt das Zeichen als ein Editortoken mit einem UTF-16-Zeichen.

`CalculatorKey.cube` ist eine zusätzliche **sekundäre semantische Aktion**, kein neuer physischer Tastenplatz. Das Core-Enum umfasst damit 28 Aktionen, die strukturierte Sitzung außerdem drei lokale Bruch-/Richtungsaktionen. Die App behält 50 physische Tasten und 31/34 Primärbelegungen in Linear/Math. Core-Enumgröße und physischer Tastenumfang sind getrennte Größen.

## Bedienung

In der App aktiviert SHIFT den vorhandenen Modifier, der folgende Druck auf x² sendet `ACTION_CUBE` an die aktive Sitzung und hebt den Modifier auf. Ein einzelner Druck auf x² quadriert weiterhin. Ein wiederholter SHIFT-Druck vor der Funktion hebt die Verriegelung wie bisher auf. Bei geöffnetem Menü oder ausgeschaltetem Gerät wird die Rechnung nicht durch Kubieren verändert.

Die natürliche assistive Beschreibung nennt `³` „hoch drei“. Eine neue Hardwarezuordnung für das direkt getippte Unicodezeichen ist nicht vergeben. Die eigene Aktion **Als Zähler** übernimmt weiterhin keine unmarkierte Postfixkette automatisch; eine geschlossene Gruppe wie `(3³)` bleibt übernehmbar. Es gibt noch keinen allgemein editierbaren Exponentenfeldeditor.

## Prüfung

Eigene Corefälle prüfen Bindung, gemischte Ketten, exakte Ans-Werte, Cursor und Feldzuordnung, Fehlerphasen sowie Ressourcenränder. Unabhängige Controller-/Widgetfälle verwenden die sichtbaren SHIFT-/x²-Tasten in beiden Eingabearten und prüfen unveränderte Primärbelegungen, Perioden-Ans, Fehlersperre und schmale Darstellung. Die ausgeführte und visuell geprüfte Vorschau zeigt die tatsächliche Tastenfolge `3`, SHIFT, x², SHIFT, x², `=` mit Ergebnis 19683. Tatsächliche Ausführung, geprüfte Revision und visuelle Grenzen stehen im [Entwicklungsstand](ENTWICKLUNGSSTAND.md). Originale Rundungs-/Bereichsregeln und vollständige Originalabläufe sind nicht nachgewiesen.
