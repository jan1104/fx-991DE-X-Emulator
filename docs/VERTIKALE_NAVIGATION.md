# Auf/Ab in natürlichen Bruchfeldern

Stand: 28.10.2026. Auf/Ab ist als eigene begrenzte Prototypregel im strukturierten Editor, der Sitzung und der App angebunden. Es gibt noch keinen nachgewiesenen Originalvergleich der geometrischen Casio-Cursorbewegung.

## Festgelegte Bewegung

| Ausgang | Aktion | Ziel |
|---|---|---|
| Zähler eines Bruchs | Ab | Nenner desselben unmittelbar umschließenden Bruchs |
| Nenner eines Bruchs | Auf | Zähler desselben unmittelbar umschließenden Bruchs |
| Zähler | Auf | Keine Bewegung |
| Nenner | Ab | Keine Bewegung |
| Wurzelsequenz außerhalb einer Vorlage | Auf oder Ab | Keine Bewegung |

Das Ziel erhält den bisherigen logischen Tokenoffset, begrenzt auf seine Feldlänge. Leere Felder erhalten Offset 0; `Ans` und komplette Bruchknoten zählen jeweils als ein Token. Es wird keine Pixelspalte gemessen oder bevorzugte Spalte gespeichert. Beispiel: Zähleroffset 5 wechselt in einen einstelligen Nenner zu Offset 1; Auf führt anschließend zu Zähleroffset 1 zurück.

Bei Verschachtelung wird ausschließlich der letzte Feldpfadschritt umgeschaltet. Auf aus einem inneren Zähler steigt nicht automatisch zu einer äußeren Vorlage auf. Die bestehende Links-/Rechtsnavigation ermöglicht weiterhin das Betreten und Verlassen verschachtelter Brüche. Einfügen und Löschen verändern diese Bewegungsregel nicht.

`FractionEditor.moveUp()` und `moveDown()` ändern weder Zahlenwerte noch Baum, frühere Snapshots oder andere Editorinstanzen. `StructuredCalculatorSession.pressId()` akzeptiert dafür `KEY_UP` und `KEY_DOWN`; der lineare `CalculatorKey`-Katalog bleibt bei seinen bisherigen 25 Einträgen.

## Ergebnis und Fehler

Die erste beliebige Pfeilaktion nach einem Ergebnis öffnet die Bearbeitung am Wurzelende ohne zusätzlichen Bewegungsschritt. Nach einem Fehler öffnet sie das separat markierte Source-Map-Ziel; erst die nächste Pfeilaktion führt wieder die eigentliche Bewegung aus. Ans bleibt erhalten, Ergebnis-/Fehlermetadaten werden beim Wiederöffnen gelöscht. Für positionslose Fehler gilt die bisherige Cursor-Rückfallregel.

Diese Regeln erweitern die vorhandene Links-/Rechts-Wiederaufnahme konsistent auf Auf/Ab. Es gibt weiterhin keinen Verlauf über Auf/Ab in der Wurzelsequenz.

## App und Hardware

Die Hauptansicht behält 50 Tastenplätze. In **Brüche** sind nun 28 Primäraktionen aktiv, einschließlich der beiden vertikalen Pfeile; in **Linear** bleiben es 25 und Auf/Ab sind dort deaktiviert.

Hardware-Up/Down werden ausschließlich in Brüche an die strukturierte Sitzung weitergeleitet. Der zusätzliche Mapper `mapStructuredNavigation()` liefert stabile Tasten-IDs und verändert den bisherigen linearen Mapper nicht. Zugeordnete Haltewiederholungen werden konsumiert, ohne weitere Bewegung auszulösen. Ctrl/Alt/Meta-Kombinationen und nicht zugeordnete Tasten bleiben unbehandelt. In Linear bleiben Hardware-Up/Down für die normale Oberfläche verfügbar und werden nicht an den Core geschickt.

Die innere Cursor-Nachführung gilt auch nach Feldwechseln. Sie scrollt den Formelausschnitt bei Bedarf; den äußeren Seiten-/Tastaturbildlauf verändert sie nicht. Der Fehlerhinweis nennt nun alle vier Richtungen als Möglichkeit zur Wiederaufnahme.

## Prüfumfang und nächste Schritte

Coretests liegen unter `packages/calculator_core/test/vertical_navigation_test.dart`; Appabläufe unter `apps/calculator/test/vertical_navigation_test.dart`. Zusätzliche Mappingtests prüfen Ereignisphasen, Wiederholungen und Modifier. Die tatsächlichen Gesamtläufe und Werkzeugstände stehen im [Entwicklungsstand](ENTWICKLUNGSSTAND.md). Diese Tests sind keine native Geräteprüfung und keine Messung des Originalverhaltens.

Als nächstes die Übernahme vorhandener Operanden in eine Bruchvorlage spezifizieren und begrenzt umsetzen. Bevorzugte geometrische Spalten, automatischer Aufstieg zu Vorfahren und Verlauf bleiben getrennte spätere Entscheidungen. Bestehende Editorregeln: [BRUCHEDITOR_PROTOTYP.md](BRUCHEDITOR_PROTOTYP.md), [STRUKTURIERTE_SITZUNG.md](STRUKTURIERTE_SITZUNG.md).
