# Fehlerstellen in natürlichen Bruchfeldern

Stand: 28.10.2026. Die strukturierte Sitzung ordnet Fehler der Parserprojektion jetzt einem logischen Feldpfad und Tokenoffset zu. Diese Zuordnung ist eine eigene nachvollziehbare Bedienregel, kein gemessener Original-Fehlercursor.

## Projektion und Zuordnung

`FractionEditor.project()` liefert `EditorProjection`: den bisherigen vollständig geklammerten Ausdruck und eine unveränderliche Source-Map. `cursorAt(offset)` akzeptiert UTF-16-Offsets von 0 bis einschließlich Ausdruckslänge. Außerhalb des Bereichs entsteht `ArgumentError`. Der letzte Offset bezeichnet das Ende der Wurzelsequenz.

| Stelle der Projektion | Strukturelles Ziel |
|---|---|
| Zeichen eines Texttokens | Anfang dieses Tokens; alle drei Zeichen von `Ans` bleiben atomar |
| Öffnung `((` einer Bruchvorlage | Zähleranfang |
| Abschluss des Zählers | Zählerende |
| Erzeugtes `/` zwischen Zähler und Nenner | Nennerende; bei `1/0` lässt sich die Null unmittelbar mit DEL entfernen |
| Öffnung des Nenners | Nenneranfang |
| Beide letzten Bruch-Abschlussklammern | Nennerende |
| Ende des vollständigen Ausdrucks | Wurzelende |

Leere Felder und unausgeglichene Klammern entstehen bereits vor dem Parser. `EditorProjectionException` enthält dafür den bisherigen `CalculatorException` und zusätzlich den strukturellen Cursor: leeres Feld am Anfang, überzählige schließende Klammer am Tokenanfang, fehlende schließende Klammer am Feldende. Die bisherigen Methoden `toExpression()` und `evaluate()` entpacken diese Diagnose weiterhin als `CalculatorException`; ihre bestehenden Aufrufer müssen keinen neuen Ausnahmetyp behandeln.

Bei mehreren Problemen folgt die Prüfung ihrer dokumentierten Traversierung: zunächst Klammerbalance der aktuellen Sequenz, dann Projektion der Kinder in Eingabereihenfolge. Es wird keine global erste fehlerhafte Bildschirmstelle garantiert. Eine explizit eingegebene Division `/` ist ein gewöhnliches Texttoken; nur das von der Bruchvorlage erzeugte `/` erhält die spezielle Nennerregel.

## Sitzung und Wiederaufnahme

`StructuredCalculatorSnapshot.errorCursor` ist nur während eines Fehlers gesetzt. Der vorherige Editorbaum und sein Bearbeitungscursor bleiben bis zur Wiederaufnahme unverändert. Die erste Links-/Rechtsaktion öffnet die Bearbeitung genau am markierten Ziel, ohne zusätzlich einen Schritt zu bewegen. Weitere Pfeile verwenden wieder die gewöhnliche Feldnavigation. Eine erfolgreiche Rechnung, AC oder eine aufgehobene Fehlerphase entfernt die Fehlermetadaten.

`FractionEditor.moveTo(cursor)` validiert den kompletten Pfad und Offset gegen den aktuellen Baum, bevor es einen neuen Snapshot veröffentlicht. Ein Cursor aus einem anderen, inzwischen unpassenden Baum wird atomar abgewiesen. Die Source-Map gehört immer zu ihrem unveränderten Projektionsbaum; sie ist keine allgemeine Dokumentversionierung.

Fehler ohne Parserposition, etwa ein Eingabelimit, verwenden den bisherigen Bearbeitungscursor als Rückkehrstelle. Diese Stelle ist dann eine Bearbeitungshilfe und keine behauptete exakte mathematische Ursache. Ans bleibt bei allen Fehlern unverändert. Die lineare Sitzung erhält durch dieses Paket keine neuen Regeln.

## Sichtbare Hilfe

Die natürliche Formelansicht zeigt den betroffenen Feldbereich mit rotem Rahmen und einen roten Marker am zugeordneten Offset. Der normale Bearbeitungscursor bleibt während der Fehlerphase verborgen. Ein zusätzlicher Text erklärt Links/Rechts und AC. Die assistive Formelbeschreibung nennt die Fehlerstelle und deren Feldhierarchie; reale Screenreaderprüfungen bleiben offen.

Bei benachbarten Brüchen nennt die Ansage die Bruchnummer innerhalb des jeweiligen Felds, etwa „im Nenner des 2. Bruchs“. Dabei werden tatsächliche Bruchknoten gezählt, nicht sämtliche Text-/Operatorpositionen. Verschachtelte Ziele erhalten diese Zuordnung auf jeder Pfadebene.

Die Cursor-Nachführung richtet sich in dieser Phase auf den Fehlermarker. Sie verändert ausschließlich die zwei inneren Scrollpositionen des Formeldisplays. Bei sehr großen Feldern muss nicht der gesamte rote Rahmen gleichzeitig sichtbar sein; der Marker ist das Scrollziel.

Der explizite lokale Vorschauhelfer `apps/calculator/tool/render_preview.dart` ergänzt den Fall `1/(2/0)` und schreibt `build/reports/calculator-error.png` (ignoriert). Das Bild ist eine Testengine-Vorschau, kein Nachweis einer nativen Anwendung.

## Weiter offen

Die Source-Map identifiziert die vom Parser/Evaluator gemeldete Stelle, keine allgemeine mathematische Ursachenanalyse. Vertikale Navigation, gemischte Brüche, Übernahme bestehender Operanden in Vorlagen und weitere natürliche Funktionen bleiben getrennte Arbeitspakete. Die bestehenden Handbuchinventare werden durch diese eigenen Komponententests nicht pauschal als Original-kompatibel freigegeben.
