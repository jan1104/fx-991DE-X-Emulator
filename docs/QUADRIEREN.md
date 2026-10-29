# Quadriertaste und Operandbindung

Stand: 29.10.2026. `KEY_SQUARE` ist im Core beider Sitzungen implementiert und geprüft. Die Appanbindung ist vorbereitet und statisch analysiert; ihre Ausführungsprüfung ist durch eine Windows-Code-Integrity-Richtlinie blockiert. Das vorhandene Tasteninventar belegt x² als Quadrieren (H, physische PDF-S. 19/29); SHIFT-Kubieren und die DEC-Belegung im Basis-N-Modus sind damit noch nicht implementiert. Der bereits dokumentierte Referenzfall K02 trennt Vorzeichen und geklammerte Potenzbasis. Weitere Original-Bedien-/Rundungsdetails wurden nicht neu gemessen.

## Rechenvertrag

Die Taste fügt das eigenständige Postfixzeichen `²` ein. Der Parser bindet es wiederholt an den unmittelbar vorherigen Primärausdruck: Zahl, ausdrücklich gebundenes Ans oder geklammerter Ausdruck. Die geklammerte Projektion eines natürlichen Bruchs ist ebenfalls ein solcher Operand.

Das ist keine blinde Textersetzung durch `^2`. Wiederholte Quadrattasten bleiben dadurch wiederholte Quadrierungen; die bestehende Rechtsassoziativität von `^` wird nicht versehentlich darauf übertragen.

| Eingabe | Erwartung des Prototyps |
|---|---|
| `3²` | 9 |
| `3²²` | 81, also `(3²)²` |
| `-2²` | −4; das Vorzeichen bleibt außerhalb |
| `(-2)²` | 4 |
| `2^3²` | 512, also `2^(3²)` |
| `2²^3` | 64, also `(2²)^3` |
| Natürlicher Bruch `1/2`, dahinter `²` | `1/4` exakt |

Postfixquadrate werden vor dem folgenden normalen `^` verarbeitet; dessen rechter Operand verwendet wieder dieselben Regeln. Der vorhandene Evaluator berechnet den daraus erzeugten Potenzbaum mit Exponent 2. Es gibt keinen zweiten Gleitkomma-Rechenweg und keine neue externe Abhängigkeit.

## Sitzung und Anzeige

Während der Bearbeitung wird `²` am Token-Cursor eingefügt. Ohne vorherigen Operanden ist das zunächst eine unvollständige Eingabe; erst `=` meldet den Syntaxfehler. Eine leere Eingabe wird dabei nicht automatisch mit Ans aufgefüllt. Nach einem **erfolgreichen Ergebnis** startet die Quadriertaste dagegen ausdrücklich `Ans²`; `=` führt die Rechnung aus und aktualisiert Ans. Ein negatives oder gebrochenes Ans bleibt ein exakter Zahlenoperand und wird nicht als ungeklammerter Text eingesetzt.

AC/DEL, Cursorbewegung, Fehlerphase und die eigene Wahl Linear/Brüche verwenden ihre bisherigen Regeln. In der Fehlerphase bleibt die Taste wie die anderen Texteingaben gesperrt. Die Source-Map behandelt `²` als gewöhnliches einzelnes Token; Fehlerziele und Ressourcenfehler werden weiterhin strukturiert angezeigt.

Die Hauptansicht hat weiterhin 50 physische Tastenplätze. Linear bietet nun 26 aktive Primäraktionen, Brüche 29. Die eigene Appaktion **Als Zähler** bleibt davon getrennt. Ein neues Hardwarekürzel für x² ist nicht vergeben; das bestehende Hardware-Mapping wird nicht ausgeweitet.

Die natürliche Ansicht zeichnet das hochgestellte Unicodezeichen und nennt es in der assistiven Beschreibung „zum Quadrat“. Dies ist noch kein allgemeiner Editor für frei bearbeitbare hochgestellte Exponentenfelder. Vollständige Potenz-/Quadratketten werden von **Als Zähler** nicht automatisch als ein Term ausgewählt; eine ausdrücklich geklammerte Gruppe wie `(3²)` lässt sich über den vorhandenen Gruppenvertrag übernehmen.

## Prüfung und Grenzen

Die bestandenen Coretests prüfen unter anderem die obigen Werte, exakte Brüche/Ans, wiederholtes Quadrieren, Vorzeichen, Cursoreinfügung, leere Eingabe, Fehlerwiederaufnahme und die bestehenden Ressourcenbudgets. K02 wird als mathematische Projektion mit `²` ergänzt; das ist kein Nachweis originaler Display-/Setupabläufe. 25 neue Widgetfälle sind geschrieben, aber nicht ausgeführt. Die zuletzt bestandenen 144 Apptests gehören zum Vorgängerstand. Tatsächliche Gesamtzahlen, Diagnose und Werkzeuge stehen im [Entwicklungsstand](ENTWICKLUNGSSTAND.md).

Der vorbereitete Vorschauhelfer `apps/calculator/tool/render_preview.dart` enthält jetzt die Bildschirmaktionen `3`, x², x², `=`. Sobald der Fluttercompiler wieder in einer richtlinienkonformen Umgebung ausführbar ist, soll er `build/reports/calculator-square.png` erzeugen. Diese neue Vorschau wurde noch nicht erstellt oder visuell geprüft. Native Installation und echte Screenreader-/Geräteprüfung bleiben ebenfalls offen.

Als nächstes die Kehrwerttaste mit Definitionsbereich, Nullfall und klarer Operandbindung als begrenzte Primäraktion spezifizieren. Kubieren, weitere SHIFT-/ALPHA-Belegungen, allgemeine Exponentenfelder und originale Rundungs-/Bereichsregeln bleiben offen.
