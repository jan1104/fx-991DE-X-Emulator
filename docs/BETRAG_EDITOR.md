# Entwurf: strukturiertes Argumentfeld für Betrag

Stand 04.11.2026, Architekturprüfung auf Basis `0cf9078`. **Dieses Dokument ist ein Umsetzungsentwurf, keine implementierte Editor-/Appfunktion und kein bestandener Bediennachweis.** Im aktuellen Arbeitspaket wird nur die getrennte Core-Auswertung von `Abs(...)` ergänzt. Die bestehende SHIFT-Belegung liefert bis zur späteren Anbindung weiterhin ihren Vorbereitungsstatus.

Quelle für den späteren Bedienfall ist H, physische PDF-S. 21: `|2−7| × 2 = 10`. Die vorhandene Extraktion zeigt in Math den Austritt per Rechtspfeil und in Linear eine schließende Klammer. Alle nachstehenden Cursor-/Löschdetails sind ausdrücklich eigene, noch zu prüfende Prototypentscheidungen. Quelle und bisheriger Umfang: [Tasteninventar](TASTEN_UND_BEDIENUNG.md), [strukturierte Sitzung](STRUKTURIERTE_SITZUNG.md), [vertikale Navigation](VERTIKALE_NAVIGATION.md).

## Modellvorschlag und Kompatibilität

Zunächst einen konkreten unveränderlichen `EditorAbsolute`-Knoten mit genau einem `EditorSequence argument` ergänzen. Eine frei benennbare `EditorFunction` würde bereits Signaturen, Aritäten und weitere Funktionsarten festschreiben; dafür liegt hier noch kein Vertrag vor. Der vollständige Betragsknoten zählt wie ein Bruch als ein Atom in seiner Elternsequenz. Sein Inhalt bleibt ein eigener bearbeitbarer Unterbaum.

Als kleine kompatible Erweiterung wird `FractionField.argument` **hinter** `numerator` und `denominator` vorgeschlagen. `EditorStep.nodeIndex`, die bisherigen Enumwerte, Bruchpfade und Cursoroffsets bleiben erhalten. Der historische Typname beschreibt danach nicht mehr alle Felder; eine allgemeine Umbenennung ist ein getrenntes API-Vorhaben. Eine ungeprüfte Dart-Typaliaslösung wird nicht vorausgesetzt.

Alle Feldzugriffe müssen Knotenart und Feld gemeinsam prüfen: Bruch/Zähler, Bruch/Nenner oder Betrag/Argument. Ein gemeinsamer privater Lese-/Ersetzungshelfer vermeidet neue verstreute Casts. Ein Betrag mit Zählerpfad und ein Bruch mit Argumentpfad sind ungültig. Die heutige Abkürzung „nicht Zähler bedeutet Nenner“ darf an keiner Pfadstelle bestehen bleiben.

Vorgeschlagene Editoroperation: `insertAbsolute()` fügt eine leere Vorlage am aktuellen Cursor ein und betritt deren Argument bei Offset 0. Sie übernimmt keine Nachbarzeichen. Der direkte Knotenbau bleibt privat. Alle Ressourcenprüfungen erfolgen vor Veröffentlichung des neuen Snapshots.

## Navigation und Löschen

| Ausgang | Aktion | Vorgeschlagenes Ziel |
|---|---|---|
| Cursor vor einem Betragsknoten | Rechts | Anfang seines Arguments |
| Cursor hinter einem Betragsknoten | Links | Ende seines Arguments |
| Innerhalb des Arguments | Links/Rechts | Bisherige Tokenbewegung, einschließlich verschachtelter Brüche/Beträge |
| Argumentende | Rechts | Elternsequenz unmittelbar hinter dem gesamten Betragsknoten |
| Argumentanfang | Links | Elternsequenz unmittelbar vor dem Betragsknoten |
| Nichtleeres Argument, Offset größer 0 | DEL | Vorherigen Text-/Unterbaumknoten entfernen, wie bisher im Bruchfeld |
| Nichtleeres Argument, Offset 0 | DEL | Keine Änderung; Feldgrenze bleibt geschützt |
| Leeres Argument, Offset 0 | DEL | Gesamte leere Betragsvorlage entfernen; Cursor in der Elternsequenz am vorherigen Knotenplatz |
| Elternsequenz unmittelbar hinter einem Betrag | DEL | Ganzen Betragsknoten einschließlich Argument atomar entfernen, entsprechend heutigem Löschen eines Bruchknotens |

Zum erneuten Bearbeiten eines nichtleeren Betrags dient Links; DEL außerhalb des Knotens wird nicht zugleich zur Navigation umgedeutet. Vorherige Snapshots behalten den vollständigen alten Unterbaum.

Auf/Ab behält die bisherige Regel des **unmittelbaren letzten Pfadschritts**. Ist dieser ein Argument, passiert nichts; es wird nicht zu einem äußeren Bruch gesprungen. Befindet sich der Cursor in einem Bruch innerhalb des Arguments, wechseln Auf/Ab dessen Zähler/Nenner. Befindet sich ein Betrag im Zähler eines äußeren Bruchs, muss der Cursor den Betrag zunächst per Links/Rechts verlassen, bevor der äußere Bruch gewechselt wird. Beim Auflösen der Vorfahren dürfen dabei Betragsschritte durchlaufen werden, ohne sie als Bruch zu casten.

In Math schließt Rechts das strukturelle Argument. `KEY_RPAREN` bleibt eine Benutzerklammer innerhalb des aktiven Feldes und ist kein heimlicher Feldabschluss: Ein zuvor dort eingegebenes `(` lässt sich schließen; ein verwaistes `)` ergibt die bestehende Feldklammerdiagnose. In Linear wird die explizite schließende Klammer eingegeben. Eine zusätzliche Math-`)`-Austrittsregel gehört nicht zum ersten Paket.

## Projektion und Fehlerziel

Für Math wird ein Betrag einheitlich als `(Abs(<Argumentprojektion>))` serialisiert. Die äußere Gruppierung folgt dem bestehenden Bruchprinzip: Nachbarn wie `2` und ein vollständiger Betragsknoten ergeben eine gültige implizite Multiplikation `2(Abs(...))`. Der Corevertrag, der ein nacktes `2Abs(...)` ablehnt, bleibt damit erhalten. Die Ansicht zeigt nur senkrechte Betragsstriche, keine technischen Projektionsklammern.

Die Source-Map muss jedes erzeugte UTF-16-Zeichen belegen:

| Erzeugter Bereich | Editorziel |
|---|---|
| Äußere öffnende Gruppierung `(` | Elternsequenz vor dem Betragsknoten |
| Funktionspräfix `Abs(` | Anfang des Argumentfeldes |
| Zeichen des Arguments | Rekursiv dessen vorhandene Token-/Bruch-/Betragspfade |
| Funktionsschluss `)` | Ende des Argumentfeldes |
| Äußerer Gruppierungsschluss `)` | Elternsequenz hinter dem Betragsknoten |

Die finale Position am Gesamtende bleibt wie heute das Wurzelende. Ein leeres Argument löst bereits bei der Projektion `EditorProjectionException` mit `syntax` und dem Argumentcursor Offset 0 aus; es wird nicht als null ausgefüllt. Benutzerklammern werden für jedes Feld gesondert balanciert, damit sie generierte Funktions-/Bruchklammern nicht schließen können. Arithmetische Fehler im Argument, etwa ein Nullnenner in einem enthaltenen Bruch, behalten über dessen vorhandene Source-Map ihr genaues Feldziel.

Die Sitzung soll weiterhin bei Fehlern Baum und aktuellen Cursor unverändert halten und `errorCursor` gesondert setzen. Erst die erste Pfeilaktion öffnet genau dieses Ziel; die nächste führt die tatsächliche Bewegung aus. Die bestehende `_execute()`-Trennung zwischen Projektionsdiagnose und Parser-/Evaluatorposition bleibt verwendbar.

## Aktionen, Ans und lineare Eingabe

Für die spätere Anbindung wird eine sekundäre Aktion `ACTION_ABS` vorgeschlagen, die der Appcontroller aus SHIFT → `KEY_LPAREN` erzeugt. SHIFT wird wie bei den anderen Zusatzbelegungen verbraucht; Menü und OFF greifen vor der mathematischen Weiterleitung. Der physische Umfang bleibt 50 Tasten, die Primärbelegung `(` unverändert. Das Core-Enum bleibt in diesem reinen Parsepaket bei 32 Aktionen; die spätere Aktion würde es auf 33 erweitern.

Math muss `ACTION_ABS` vor der allgemeinen `editor.insertText(key.text!)`-Stelle abfangen und `insertAbsolute()` aufrufen. `Abs(` wird nicht als Textknoten in den strukturierten Editor aufgenommen. Im Bearbeitungszustand entsteht ein leeres Argument. Als eigene Ergebnisfortsetzung wird vorgeschlagen: nach einem Ergebnis eine neue Betragsvorlage mit einem atomaren exakten `Ans` im Argument beginnen und den Cursor an dessen Ende stellen. Ein gerundeter Anzeigetext darf nicht eingesetzt werden. AC vor der Aktion beginnt dagegen ein leeres Argument. Diese Fortsetzung ist noch keine Originalbeobachtung und muss vor Implementierung als öffentliche Regel übernommen werden.

Linear kann dieselbe Aktion während der Bearbeitung ein logisches Präfixtoken `Abs(` mit vier UTF-16-Zeichen einfügen. Die bestehende Tokenliste kann einen solchen String schon darstellen, aber `CalculatorKey`, Längenprüfung, Fehlerfortsetzung und Ergebnisregel müssen die neue Aktion ausdrücklich behandeln. Ein nacktes Hinzufügen von `text: 'Abs('` genügt nicht: Die heutige allgemeine Ergebnisregel würde den alten Ausdruck löschen und kein Ans binden. Für die vorgeschlagene Fortsetzung wären die Tokens `['Abs(', 'Ans']` und anschließend die vom Nutzer eingegebene `)` vorgesehen. DEL auf dem Präfix entfernt alle vier Zeichen als ein Token; ein danach verbliebener Abschluss darf einen normalen Syntaxfehler ergeben. Eine automatisch eingefügte lineare Abschlussklammer gehört nicht zum ersten Paket.

Ergebnis-/Fehlerphase, Ausgabeformatwahl und unabhängige Math-/Linearentwürfe bleiben getrennt. Der Controller-Fehlercode wird in Tests am Snapshot geprüft, der übersetzte sichtbare Fehlertext in Widgettests.

## Atome, Grenzen und unveränderliche Bäume

`wrapPreviousAtomInFraction()` soll einen vollständigen `EditorAbsolute` links vom Cursor als zulässiges Atom übernehmen. Es bleibt eine rein strukturelle Operation ohne Auswertung. Der Unterbaum wandert vollständig in den neuen Zähler, der Cursor in den leeren Nenner. Innerhalb des Arguments wirkt die gleiche Aktion nur auf das dortige vorherige Atom. Ein nachgestelltes `²`, `!`, `%` oder eine offene Operatorkette wird weiterhin nicht als kompletter Term erraten.

`maxNodes = 256` zählt alle Text-, Bruch- und Betragsknoten einschließlich ihrer Nachkommen. `maxDepth = 16` begrenzt künftig die gesamte Verschachtelung von Vorlagen, nicht nur Brüche: Jeder Bruch und jeder Betrag erhöht die Vorlagentiefe um eins; Zähler, Nenner und Argument sind Sequenzen. `_fractionDepth` wird dafür zu einer vollständigen Vorlagentiefenprüfung erweitert oder passend umbenannt. Das Übernehmen eines vorhandenen Betrags/Bruchs als Zähler muss den vollständigen neu erzeugten Baum prüfen, weil unsichtbare Nachkommen ebenfalls eine Ebene tiefer gelangen. Alte Bruchtiefenfälle bleiben gültig.

Einfügen, Ersetzen und Übernahme bauen zuerst einen Kandidaten. Erst nach Knoten-/Tiefenprüfung wird der neue Snapshot veröffentlicht. Ungültige Pfade aus einem alten oder fremden Snapshot werden vor einer Cursorbewegung abgewiesen. Fehlgeschlagene Befehle verändern weder alten Baum noch Cursor oder Ans. Bestehende Parser-/Evaluatorbudgets gelten zusätzlich für die längere Projektion.

## Konkrete Änderungsstellen

Die Zeilen sind Anker des geprüften Ausgangsstands; vor Änderungen über die Methodennamen erneut auffinden.

| Datei / Anker | Erforderliche spätere Änderung |
|---|---|
| [fraction_editor.dart:21](../packages/calculator_core/lib/src/editor/fraction_editor.dart#L21), `EditorFraction`, `FractionField`, `EditorStep` | `EditorAbsolute(argument)` und expliziten Argumentpfad ergänzen; bestehende Bruchwerte erhalten. |
| [fraction_editor.dart:126](../packages/calculator_core/lib/src/editor/fraction_editor.dart#L126), `_field` | Jeden Vorfahrenschritt nach Knotenart/Feld auflösen; heutigen unbedingten `as EditorFraction` ersetzen. |
| [fraction_editor.dart:144](../packages/calculator_core/lib/src/editor/fraction_editor.dart#L144), `insertFraction`, neues `insertAbsolute`, `_insert` ab 296 | Gemeinsame Tiefe prüfen; Eintrittsfeld nicht weiterhin als Zähler fest verdrahten; Kandidat erst nach vollständiger Prüfung veröffentlichen. |
| [fraction_editor.dart:161](../packages/calculator_core/lib/src/editor/fraction_editor.dart#L161), `wrapPreviousAtomInFraction` | Betrag als vollständiges Atom zulassen; Gruppensuche überspringt weiterhin innere Unterbaumklammern; globale Tiefe vor Veröffentlichung prüfen. |
| [fraction_editor.dart:280](../packages/calculator_core/lib/src/editor/fraction_editor.dart#L280), `_fractionDepth` | Alle Bruch-/Betragsnachkommen berücksichtigen, statt Nicht-Brüche zu überspringen. |
| [fraction_editor.dart:334](../packages/calculator_core/lib/src/editor/fraction_editor.dart#L334), `moveTo` | Knotenart/Feld gemeinsam validieren; fremde Argumentpfade zu Text/Bruch zurückweisen. |
| [fraction_editor.dart:354](../packages/calculator_core/lib/src/editor/fraction_editor.dart#L354), `deleteBackward` | Sonderfall leeres Argument am Feldanfang; außerhalb des Knotens bestehendes atomares Entfernen fortführen. |
| [fraction_editor.dart:364](../packages/calculator_core/lib/src/editor/fraction_editor.dart#L364), `moveRight`, `moveLeft` | Eintritt, Wiedereintritt und Austritt des Arguments ergänzen; Fallunterscheidung für Zähler/Nenner/Argument vollständig machen. |
| [fraction_editor.dart:423](../packages/calculator_core/lib/src/editor/fraction_editor.dart#L423), `_moveVertically` | Argument als unmittelbares Feld ohne Vertikalziel erkennen; Vorfahren über gemeinsamen Feldhelfer auflösen, direkten Bruch-Cast entfernen. |
| [fraction_editor.dart:481](../packages/calculator_core/lib/src/editor/fraction_editor.dart#L481), `_project` | Neuen erschöpfenden Knotenfall, Argumentpfad, leere Feldfehler und alle generierten Zeichenpositionen ergänzen. `project`, `toExpression`, `evaluate` behalten ihre Ausnahmeverträge, erhalten aber gezielte Regressionsfälle. |
| [fraction_editor.dart:550](../packages/calculator_core/lib/src/editor/fraction_editor.dart#L550), `_count`, `_replace` | Argument rekursiv zählen; unveränderlichen Betrag entlang eines Argumentpfads neu aufbauen. Heutigen unbedingten Bruch-Cast in `_replace` ersetzen. |
| [structured_calculator_session.dart:84](../packages/calculator_core/lib/src/state/structured_calculator_session.dart#L84), `pressId`, `press`, `_apply` | Neue Aktion strukturell abfangen, Fehlerphase/Ans-Fortsetzung und atomaren Kandidatenfluss erhalten. `_recoverError` und `_execute` mit neuen Pfaden prüfen. |
| [calculator_session.dart:8](../packages/calculator_core/lib/src/state/calculator_session.dart#L8), `CalculatorKey`, `press` ab 160 | Sekundäre Aktion und lineares atomisches Präfix mit ausdrücklicher Ergebnisfortsetzung ergänzen; nicht als binären/postfixen Operator klassifizieren. `_tokenIndexAt` für Positionen innerhalb von `Abs(` prüfen. |
| [fraction_expression_view.dart:144](../apps/calculator/lib/presentation/editor/fraction_expression_view.dart#L144), `cursorPath` | Eindeutigen Argumentpfad, etwa `/a{index}`, statt pauschal `f…n/d` erzeugen. |
| [fraction_expression_view.dart:190](../apps/calculator/lib/presentation/editor/fraction_expression_view.dart#L190), `_sequence` | Neuen Knotenfall und eigenes skalierbares Betragslayout mit rekursivem Argument ergänzen; Caret, Platzhalter und Fehlerrahmen in diesem Feld erhalten. |
| [fraction_expression_view.dart:288](../apps/calculator/lib/presentation/editor/fraction_expression_view.dart#L288), `_location`, `_describe` | Betragspfad ohne Bruch-Cast durchlaufen; „im Argument des … Betrags“ und „Betrag … Ende Betrag“ ausgeben. |
| [calculator_controller.dart:165](../apps/calculator/lib/application/calculator_controller.dart#L165), `pressId`, `isKeyEnabled` ab 116 | SHIFT → `(` routen; Menü/OFF und unveränderte Primärbelegung prüfen. Kein eigener Einstellungszustand nötig. |
| [calculator_page.dart:170](../apps/calculator/lib/presentation/calculator/calculator_page.dart#L170), `_fractionTool`, `_display` ab 201 | Übernahmetext um vollständige Betragsknoten ergänzen; Ansicht/Fehlercursor weiterhin aus gemeinsamem Snapshot speisen. |

Die Exporte in `calculator_core.dart` exportieren bereits die gesamte Editordatei; ein neuer Editor-Knotentyp benötigt dort keine zusätzliche Einzel-Exportliste. Die bestehende Skin-Beschriftung `KEY_LPAREN: Abs` und die Hardwarepfeile können weiterverwendet werden. Neue Hardwarekürzel, ein neues Setupfeld und zusätzliche physische Tasten sind nicht erforderlich.

## Natürliches Layout und Abnahmeplan

Ein eigenes Ein-Kind-Layout misst das Argument einmal pro Layoutdurchlauf. Zwei vertikale Striche wachsen mit dessen tatsächlicher Höhe, auch bei enthaltenen Brüchen; die Grundlinie folgt dem Argument. Kein rekursiver Intrinsic-Width-Durchlauf und keine Striche als Textzeichen mit festem Zeilenmaß. Leere Argumente zeigen den vorhandenen Feldplatzhalter. Derselbe pfadspezifische Caret bleibt Ziel der horizontalen/vertikalen Nachführung. Fehlerfarbe und Fehlerrahmen gelten im exakten Argument-/Bruchfeld; die Striche dürfen weder Rahmen noch Caret abschneiden. Die zusammenhängende Semantikbeschreibung verhindert doppelte Ansagen dekorativer Striche.

Vor der Implementierung sind diese vorgeschlagenen Regeln als Arbeitsvertrag zu übernehmen; danach in getrennten Core-/Widgetfällen prüfen:

- Handbuchfolge Math: SHIFT → `(`, `2`, `−`, `7`, Rechts, `×`, `2`, `=` ergibt 10. Linear schließt dasselbe Argument mit `)`.
- Verschachtelter Betrag, Betrag im Zähler/Nenner und Bruch im Argument: Pfeile erreichen jedes Feld; Auf/Ab überspringt keine Argumentgrenze.
- Links vom Elternende betritt das Argumentende; Rechts am Argumentende verlässt nur diesen Betrag. Leeres Argument liefert einen gezielten Syntaxfehler, Pfeilwiederaufnahme und anschließende Eingabe beheben ihn.
- DEL am leeren Argumentanfang entfernt nur die leere Vorlage; DEL im nichtleeren Feld und hinter dem ganzen Knoten entsprechen der Tabelle. Frühere Snapshots bleiben unverändert.
- Nach negativem/gebrochenem Ans entsteht ein exaktes `Abs(Ans)`; Fix/Sci oder eine Periodenansicht ändern den Eingabewert nicht.
- Zählerübernahme eines vollständigen Betrags verschiebt den ganzen Unterbaum; offene Postfix-/Operatorketten bleiben abgewiesen. Gemischte Knoten-/Tiefengrenzen werden atomar geprüft.
- Source-Map prüft Präfix, Argument, beide Abschlussbereiche und innere Bruchfehler; fremde/mismatched Pfade werden abgewiesen.
- Widget-/Semantikfälle prüfen Betragsstriche, lange/mehrzeilige Argumente, Schrift-/Kontrastwechsel und 320-Pixel-Ansicht ohne Überlagerung; sichtbarer Fehlertext bleibt ein Ansichtstest.

Dieser Audit hat nur Produktionsquellen und bestehende Dokumentation gelesen. Es wurden keine Produktionsdateien, Tests, Originale oder Werkzeuge verändert, keine Laufzeittests gestartet und kein CI-Lauf ausgelöst. Tatsächlicher Implementierungs- und Prüfstand bleibt im [Entwicklungsstand](ENTWICKLUNGSSTAND.md) dokumentiert.
