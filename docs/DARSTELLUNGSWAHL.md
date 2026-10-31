# Darstellungswahl in den beiden Core-Sitzungen

Vertrag vom 31.10.2026, vor der Implementierung festgelegt. Der unabhängige [exakte Formatter](EXAKTE_AUSGABE.md) erhält eine ausdrückliche Auswahl in der linearen und strukturierten Sitzung. Es gibt in diesem Paket keine Appanbindung und keine neue physische Tastenbelegung. Die folgenden Regeln sind vorbereitet und lesend geprüft; ihre Ausführung ist durch den neuen Windows-Code-Integrity-Block des Dart-Teststarts noch offen.

## Zustand und Auswahl

Beide unveränderlichen Snapshots ergänzen `resultDisplayFormat`, anfangs `RationalDisplayFormat.fraction`. `session.selectResultDisplayFormat(format)` wählt während der Ergebnisphase zwischen Bruch und exakt endlichem Dezimalversuch. Der neue Snapshot erhält denselben Ergebniswert, Ans, Ausdruck, Cursor und sämtliche vorhandenen Metadaten. Alte Snapshots behalten ihre alte Wahl.

Die gleiche bereits gewählte Darstellung ist ein identischer No-op. Während Bearbeitung oder Fehlerphase ist jede Darstellungswahl ebenfalls ein identischer No-op. Sie wertet keine unfertige Eingabe aus, öffnet keinen Fehlercursor und umgeht keine Fehlersperre. In diesen Phasen bleibt der Darstellungsmodus Bruch.

Eine echte Bearbeitung einschließlich Pfeilwiederaufnahme, DEL, Ziffer, Operator oder AC setzt die Wahl auf Bruch zurück. Ein neu berechnetes Ergebnis beginnt ebenfalls als Bruch. `=` nach einem Ergebnis bleibt hingegen wie bisher wirkungslos und erhält die Wahl. Die strukturierte eigene Aktion **Als Zähler** bleibt nach Ergebnis und Fehler identisch wirkungslos; sie setzt dabei die Wahl nicht zurück. Die Eingabearten bleiben voneinander unabhängig.

## Textabruf und Ausgabeprobleme

`snapshot.formatResult(maxDecimalPlaces: 100, maxOutputCharacters: 2048)` liefert den `RationalDisplay` zum Ergebnis und zur gewählten Darstellung. Außerhalb der Ergebnisphase liefert die Methode `null`; es findet dann keine Formatierung und auch keine Prüfung der ungenutzten Ausgabeparameter statt. Während der Ergebnisphase gelten die Parametergrenzen und Fehler des vorhandenen Formatters.

Die Auswahl selbst erzeugt keinen Text. Dadurch können auch große gültige Ergebnisse gewählt und gespeichert bleiben, ohne dass ein Ausgabeproblem den Rechenzustand beschädigt. Ein `limit` beim späteren Textabruf oder ein ungültiger Ausgabeparameter verändert weder Sitzung noch Ergebnis, Ans oder Fehlerphase. Ein Aufrufer muss ein Ausgabeproblem getrennt behandeln; es wird nicht als Rechenfehler in der Sitzung gespeichert.

Bei einem periodischen oder zu langen Dezimalversuch bleibt die **gewünschte** Wahl `exactDecimal` erhalten. Der zurückgegebene Text kann dennoch als Bruch mit einem ausdrücklich gemeldeten Rückfallgrund vorliegen. Gewünschtes und tatsächliches Format sind daher getrennte Informationen.

| Schritt | Gewünschtes Format | Ausgabe / Zustand |
|---|---|---|
| `1/8 =` | Bruch | `1/8` |
| Dezimal wählen | exakt dezimal | `0,125`, Ans bleibt `1/8` |
| `=` | exakt dezimal | weiterhin `0,125` |
| Text mit Zeichenbudget 4 abrufen | exakt dezimal | Ausgabelimit; Rechenzustand unverändert |
| Bruch wählen | Bruch | `1/8` |
| `× 8 =` | Bruch | Ergebnis und Ans `1` |
| `1/3 =`, Dezimal wählen | exakt dezimal | Text `1/3`, tatsächliches Format Bruch, Grund `periodic` |

## Abgrenzung und Prüfplan

Diese explizite Core-API ist ein eigener begrenzter Vertrag. Sie bildet noch keinen originalen S⇔D-/Periodenzyklus ab; Periodenschreibweise, Rundung, Fix/Sci/Norm und gemischte Brüche bleiben offen. Der vorhandene Quellenbeleg für den Originalwechsel bleibt H, physische PDF-S. 12–13/16. Eine neue PDF-Gesamtanalyse ist nicht erforderlich.

Corefälle unter `packages/calculator_core/test/session_display_test.dart` prüfen beide Sitzungen: Wahl und unveränderliche Vorgängersnapshots, echte Bruch-/Dezimaltexte, gewünschtes gegenüber tatsächlichem Format, exakte Ans-Fortsetzung, unveränderte Editor-/Fehlerziele, No-ops, Ausgabefehler und Rücksetzen durch echte Bedienübergänge. Tatsächliche Ergebnisse stehen im [Entwicklungsstand](ENTWICKLUNGSSTAND.md).

Die App verwendet diese API noch nicht. Die bekannten offenen Quadrat-/Kehrwerttests und Vorschauen sind nach Wiederherstellung einer richtlinienkonformen Flutter-Testumgebung zuerst auszuführen; erst danach folgt die überprüfbare Appanbindung der Darstellungswahl.
