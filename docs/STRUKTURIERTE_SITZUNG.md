# Brüche im Hauptrechner

Stand: 27.10.2026. Die strukturierte Sitzung und die natürliche Formelansicht sind nun in der Hauptrechnerseite verbunden. Dies ist ein eigener Bedienprototyp, kein bereits vollständig kompatibler Math-Eingabemodus des Originals.

## Eingabe auswählen

Die App startet weiterhin mit **Linear**. Der sichtbare Schalter **Brüche** aktiviert eine getrennte strukturierte Sitzung. Beide Eingabearten behalten ihre Entwürfe, Ergebnisse, Fehler und jeweils eigenes Ans beim Wechsel. Es gibt keine automatische Konvertierung oder Übernahme. Die Oberfläche erklärt diese Trennung direkt am Schalter. Das ist eine eigene Prototypregel; eine spätere Annäherung an das Original-Setup bleibt offen.

Die Tastatur hat weiterhin 50 Plätze. In Linear sind die bisherigen 25 Primäraktionen aktiv. In Brüche kommen `KEY_FRACTION`, `KEY_UP` und `KEY_DOWN` hinzu, insgesamt 28 Aktionen. SHIFT/ALPHA und weitere Vorlagen bleiben deaktiviert. Hardware-Auf/Ab sind ausschließlich im Bruchmodus zugeordnet; ein Hardwarekürzel für die Bruchvorlage ist noch nicht vergeben. Bewegungsregeln: [VERTIKALE_NAVIGATION.md](VERTIKALE_NAVIGATION.md).

## Beispiele

`Bruch` bezeichnet die Bildschirmtaste `□/□`, `Rechts` die Taste `▶` oder Hardwarepfeil rechts.

- `Bruch, 1, Rechts, 3, Rechts, +, Bruch, 1, Rechts, 6, =` ergibt exakt `1/2`. Das letzte Rechts vor `=` ist nicht nötig, weil die ganze Formel ausgewertet wird.
- `Bruch, 1, Rechts, Bruch, 2, Rechts, 3, =` ergibt exakt `3/2`, also `1/(2/3)`.
- Nach einem Ergebnis startet ein Grundoperator mit dem exakten Ans weiter. Eine neue Ziffer oder Bruchvorlage beginnt eine neue Eingabe. Das gespeicherte Ans bleibt bis zur nächsten erfolgreichen Rechnung erhalten.

Die Ergebniszeile zeigt weiterhin `n/d`; nur die Eingabe verwendet natürliche Bruchstriche. Es werden keine gerundeten Bruchwerte in den Rechenkern zurückgeführt.

## Zustandsregeln

`StructuredCalculatorSession` im Core kapselt den Editor und veröffentlicht ausschließlich unveränderliche `StructuredCalculatorSnapshot`-Daten: Editorbaum/Cursor, Phase, Ans, Ergebnis oder strukturierten Fehler. Der lineare Controller und sein 25-Tasten-Enum bleiben unabhängig.

| Aktion | Wirkung |
|---|---|
| `KEY_FRACTION` während Eingabe | Fügt eine leere Bruchvorlage ein, Cursor im Zähler; keine automatische Übernahme benachbarter Tokens |
| Eigene Appaktion `ACTION_WRAP_FRACTION` / Als Zähler | Übernimmt das vorherige zulässige Atom als Zähler, Cursor im leeren Nenner; nur während der Bearbeitung wirksam |
| Links/Rechts während Eingabe | Tiefendurchlauf durch Zähler, Nenner und Elternfeld gemäß Editorvertrag |
| Auf/Ab während Eingabe | Wechsel zwischen den unmittelbar zugehörigen Zähler-/Nennerfeldern mit begrenztem Tokenoffset; kein automatischer Aufstieg |
| DEL | Entfernt vorherigen Knoten vollständig; am Feldanfang keine Zusammenziehung |
| AC | Leert Eingabe/Ergebnis/Fehler der aktiven Sitzung, erhält deren Ans |
| `=` bei leerer Wurzel | Keine Änderung |
| `=` bei leerem Bruchfeld | Syntaxfehler, keine implizite Null |
| `=` bei gültiger Formel | Exaktes Ergebnis und Ans, unveränderter Ausdruck |
| Erster Pfeil nach Ergebnis | Bearbeitung am Ende der Wurzelsequenz, noch keine zusätzliche Bewegung |
| DEL nach Ergebnis | Bearbeitung am Wurzelende und Löschen des vorherigen Knotens |
| Erster Pfeil nach Fehler | Hebt den Fehler auf und öffnet das über die Source-Map markierte Feld ohne zusätzliche Bewegung |
| Andere Eingabe bei Fehler | Bleibt gesperrt, bis Pfeil oder AC verwendet wird |
| Unbekannte Tasten-ID | Expliziter Unsupported-Fehler ohne Zustandsänderung |

Seit 28.10.2026 ordnet eine Source-Map Parseroffsets den natürlichen Feldern zu. Die Fehlerphase erhält den alten Bearbeitungscursor und veröffentlicht daneben `errorCursor`; der erste Pfeil übernimmt das markierte Ziel. Positionslose Eingabe-/Ressourcenfehler verwenden weiterhin den bisherigen Cursor als Rückkehrstelle. Baum und Ans bleiben erhalten. Zuordnungsregeln und Grenzen: [FEHLERPOSITIONEN.md](FEHLERPOSITIONEN.md).

## Anzeige und Cursor

Das strukturierte Eingabefeld ist in der Hauptansicht 104 logische Pixel hoch und kann in beiden Achsen scrollen. Nach einer Eingabe oder Navigation führt `FractionExpressionView(followCursor: true)` den Cursor innerhalb dieser beiden inneren Scrollbereiche nach. Der äußere Seiten-/Tastaturbildlauf wird dafür nicht verschoben. Bei Ergebnis-/Fehlerphase ist der Cursor verborgen; manuelles Scrollen zur Inspektion bleibt möglich.

Die Rechtecke für Cursor und leere Felder melden eine Baseline innerhalb ihrer vollständigen Layoutgröße. Dadurch werden ihre Oberkanten nicht durch eine nach oben verschobene Baselinebox abgeschnitten. Die Schriftvergrößerung des Betriebssystems wird im Formelwidget berücksichtigt; der feste Displayausschnitt bleibt scrollbar. In der Fehlerphase folgt der Bildlauf dem roten Fehlermarker, nicht dem verborgenen alten Bearbeitungscursor.

## Prüfung und offene Punkte

Die konkreten vollständigen Testzahlen und Laufbedingungen stehen im [Entwicklungsstand](ENTWICKLUNGSSTAND.md). Die zusätzlichen Corefälle liegen unter `packages/calculator_core/test/structured_session_test.dart`, die durchgängigen Widgetabläufe unter `apps/calculator/test/structured_calculator_widget_test.dart`. Sie prüfen unseren Vertrag und den Flutter-Testengine, keine native Installation und keinen Originalvergleich.

Der explizite Vorschauhelfer `apps/calculator/tool/render_preview.dart` erzeugt jetzt beide Hauptansichten bei 420×1100 mit demselben Ergebnis `1/2`. Lokale ignorierte Artefakte: `build/reports/calculator-prototype.png` und `build/reports/calculator-fractions.png`. Die früheren reinen Komponentenbilder bleiben als eigene QA-Helfer verfügbar.

Die explizite Übernahme einfacher Atome ist als zusätzliche Appaktion ergänzt, siehe [BRUCHUEBERNAHME.md](BRUCHUEBERNAHME.md). Offen bleiben unter anderem geometrische Spalten/Vorfahrensuche, gemischte Brüche, geschlossene Gruppen/allgemeine Termauswahl, Wurzeln und natürliche Exponentenfelder, gemeinsame originale Setup-/Speicherregeln sowie native Windows-/Android-/Apple-/Linux-Prüfungen. Details zum Editorbaum: [BRUCHEDITOR_PROTOTYP.md](BRUCHEDITOR_PROTOTYP.md).
