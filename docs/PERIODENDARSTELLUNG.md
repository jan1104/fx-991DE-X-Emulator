# Begrenzte exakte Periodendarstellung

Vertrag vom 01.11.2026, umgesetzt am 02.11.2026 als unabhängiger Core-Ausgabemodus `exactRecurringDecimal`. Die geplanten Regeln dieses Dokuments wurden implementiert und im [GitHub-Lauf 41387340158](https://github.com/jan1104/fx-991DE-X-Emulator/actions/runs/41387340158) tatsächlich geprüft: 671 Coretests einschließlich 30 unabhängiger Referenzfälle sowie 240 Appfälle bestanden. Die beschriebene additive Formatter-API ist nun verfügbar. Die sichtbare App-/Setupanbindung ist inzwischen ebenfalls geprüft; [PERIODEN_APP.md](PERIODEN_APP.md) dokumentiert sie. Originalvergleich bleibt offen. Die bisherige [exakte Ausgabe](EXAKTE_AUSGABE.md) und [Darstellungswahl](DARSTELLUNGSWAHL.md) behalten ihren Vertrag.

## Quellen und eigene Festlegungen

Das vorhandene Quelleninventar belegt S⇔D und den Setup-abhängigen Wechsel zwischen Bruch, Periode und gerundeter Dezimalanzeige (H, physische PDF-S. 12–13/16; [Tasten und Bedienung](TASTEN_UND_BEDIENUNG.md)). Die folgenden Algorithmen, Grenzen, Klammernotation und vorläufigen API-Namen sind eigene Entwicklungsentscheidungen. Sie behaupten weder eine vollständige Originaltaste noch originalgetreue Anzeigegrenzen. Neue PDF-Auswertung ist hierfür nicht erforderlich.

Der neue Modus gibt den gekürzten rationalen Wert exakt aus: endliche Dezimalentwicklung oder Vorperiode und kleinste Periode. Er verwendet ausschließlich `BigInt`, keine Gleitkommazahl und keine Rundung. Ergebniswert, Ans, Eingabe, Cursor und alte Snapshots werden durch Formatierung niemals verändert. Ein Ausgabeproblem wird nicht zum Rechenfehler der Sitzung.

## Text und tatsächliches Format

Die eigene Textnotation verwendet Dezimalkomma und runde Klammern ausschließlich um die Periode: `0,(3)`, `0,1(6)`. Die Vorperiode darf leer sein; die Periode enthält mindestens eine Ziffer. Der Ganzteil wird immer ausgegeben, auch als führende `0`. Negative Werte haben genau ein ASCII-Minus vor dem Ganzteil. Negative Null entsteht nicht. Null und ganze Zahlen enthalten weder Komma noch Klammern.

| Wert | Gewünschtes Format | Text | Tatsächliches Format |
|---|---|---|---|
| `1/3` | `exactRecurringDecimal` | `0,(3)` | `exactRecurringDecimal` |
| `1/6` | `exactRecurringDecimal` | `0,1(6)` | `exactRecurringDecimal` |
| `1/12` | `exactRecurringDecimal` | `0,08(3)` | `exactRecurringDecimal` |
| `1/11` | `exactRecurringDecimal` | `0,(09)` | `exactRecurringDecimal` |
| `22/7` | `exactRecurringDecimal` | `3,(142857)` | `exactRecurringDecimal` |
| `-1/6` | `exactRecurringDecimal` | `-0,1(6)` | `exactRecurringDecimal` |
| `3/24` | `exactRecurringDecimal` | `0,125` | `exactDecimal` |
| `0`, `-12` | `exactRecurringDecimal` | `0`, `-12` | `exactDecimal` |

Führende Nullen in Vorperiode oder Periode bleiben erhalten. Es werden keine künstlichen periodischen Neunen für endliche Werte erzeugt. Ein tatsächliches Dezimalformat hat keinen Rückfallgrund. Die gewünschte Sitzungswahl soll auch bei endlichem Text oder Bruchrückfall `exactRecurringDecimal` bleiben; ihre spätere Integration ist ein eigener Umsetzungsschritt.

## Exakte Langdivision und Abschluss am Budgetrand

Aus dem Betrag des Zählers und dem positiven Nenner entstehen per Ganzzahldivision Ganzteil und Anfangsrest. Eine Map ordnet jeden erstmals verwendeten Rest der Position seiner nächsten Nachkommastelle zu. Gleiche Reste erzeugen dieselbe weitere Ziffernfolge; die erste Wiederholung bestimmt daher die Vorperiode und die kleinste Periode, ohne eine Näherung vergleichen zu müssen.

Die Reihenfolge jeder Schleifenrunde ist verbindlich:

1. Ist der aktuelle Rest `0`, endet die Entwicklung erfolgreich und endlich.
2. Steht der Rest bereits in der Map, endet die Entwicklung erfolgreich periodisch. Ziffern vor seiner gespeicherten Position sind die Vorperiode, die folgenden Ziffern die Periode.
3. Ist die Zahl bereits erzeugter Nachkommastellen gleich `maxGeneratedDigits`, endet der Versuch mit Bruchrückfall und neuem Grund `expansionLimit`.
4. Andernfalls den Rest mit dem aktuellen Ziffernindex speichern, `10 * Rest` ganzzahlig durch den Nenner teilen, genau eine Ziffer anhängen und den neuen Rest übernehmen.

Die beiden Abschlussprüfungen erfolgen **vor** Budgetabbruch oder weiterer Ziffernerzeugung. Dadurch gelingt `1/3` mit Budget 1 und `1/6` mit Budget 2; `1/8` gelingt mit Budget 3. `1/6` bei Budget 1 fällt dagegen auf `1/6` mit `expansionLimit` zurück. Budget 0 erlaubt ganze Zahlen einschließlich Null; jeder nichtganzzahlige Wert erhält den Bruchrückfall. Die Map enthält höchstens so viele Einträge wie das Ziffernbudget, nicht zusätzlich einen Eintrag für den abschließenden oder wiederholten Rest.

Bei Budgetabbruch werden weder eine angefangene Dezimalzahl noch eine vermutete Periode ausgegeben. `expansionLimit` unterscheidet nicht zwischen einer noch nicht abgeschlossenen endlichen und einer noch nicht erkannten periodischen Entwicklung. Es ersetzt in diesem Modus keinen vorhandenen Rückfallgrund des bisherigen `exactDecimal`-Modus; dessen Faktorisierungsregeln bleiben unverändert.

## Parameter und Ressourcen

Die Erweiterung verwendet `maxGeneratedDigits: 100`, zulässig 0 bis 1000, und das bestehende `maxOutputCharacters: 2048`, zulässig 1 bis 10000. `maxDecimalPlaces` bleibt mit seinem bisherigen Bereich 0 bis 1000 erhalten. Im gemeinsamen Formatter werden **alle** übergebenen Parameter vor jedem Modus auf ihre Bereiche geprüft; ungültige Parameter erzeugen vor wertabhängiger Arbeit `ArgumentError`, auch wenn ihr Budget im gewählten Modus nicht verwendet wird. Die Erweiterung ändert den sitzungsseitigen Nullabruf ohne Ergebnis nicht.

Die gültigen Budgets wirken getrennt: Nur `exactRecurringDecimal` verwendet `maxGeneratedDigits`, nur `exactDecimal` verwendet `maxDecimalPlaces`; beide verwenden das Zeichenbudget. Insbesondere gelingt `1/8` im neuen Modus mit `maxGeneratedDigits: 3` auch bei `maxDecimalPlaces: 2`, weil dort kein zweites Stellenlimit gilt. Umgekehrt begrenzt `maxGeneratedDigits: 0` einen endlichen Versuch im alten Modus nicht. Der Bruchmodus verwendet keines der beiden Stellenbudgets. Die additive Signatur von `formatRational` ergänzt `int maxGeneratedDigits = 100`; der neue Enumwert lautet `RationalDisplayFormat.exactRecurringDecimal`. Alle bisherigen Argumente und Vorgabewerte bleiben erhalten. Diese additive API ist seit 02.11.2026 verfügbar.

Nur für den neuen Modus gilt zusätzlich: `value.numerator.abs().bitLength + value.denominator.bitLength <= 100000`, entsprechend der bestehenden Größenprüfung im Evaluator. Bei Überschreitung entsteht `CalculatorException.limit`, auch wenn das öffentliche `Rational` unabhängig vom Evaluator erzeugt wurde. Beide Bestandteile gehen in die Summe ein; es ist keine Grenze von jeweils 100000 Bit. Auch ganze Zahlen werden vor Division und Textaufbau hierauf geprüft. Dieser neue Schutz darf vorhandene Bruch-/Endlichformatierung nicht rückwirkend einschränken.

Die Restschlüssel sind kleiner als der Nenner. Mit maximal 1000 Einträgen und höchstens rund 12500 Byte Nutzdaten je Rest ist ihre reine BigInt-Nutzlast auf ungefähr 12,5 MB begrenzt. Map-, BigInt- und Indexobjekte verursachen zusätzlichen Laufzeitspeicher; die Zahl ist kein garantiertes Gesamt-RAM-Limit. Gespeicherte Ziffern benötigen höchstens 1000 Zeichen. Die Zahl der Divisionsschritte ist ebenfalls höchstens 1000. Es werden weder vollständige lange Perioden vorab berechnet noch unbeschränkte Restlisten erzeugt.

Vor der Umwandlung des Ganzteils in Text wird dessen mögliche Zeichenlänge inklusive Vorzeichen begrenzt geprüft, beispielsweise über einen Vergleich mit einer zum Zeichenbudget passenden Zehnerpotenz. Kein übergroßes `BigInt.toString()` und kein unbegrenztes Padding. Für negative echte Brüche benötigt schon der Ganzteiltext `-0` zwei Zeichen. Die vorab berechnete Zehnerpotenz selbst bleibt durch das maximale Zeichenbudget begrenzt.

Das Zeichenbudget umfasst den **gesamten endgültigen Text**: Minus, Ganzteil, Komma, Vorperiode, beide Periodenklammern und Periode; im Bruchrückfall auch Bruchstrich und Nenner. Die fertige Länge wird vor dem Zusammenbau geprüft. Zu lange tatsächliche Ausgabe erzeugt `CalculatorException.limit`; es gibt kein stilles Abschneiden und keinen zusätzlichen Bruchausweg allein wegen des Zeichenbudgets. Zum Beispiel benötigt `0,(3)` fünf Zeichen: bei Budget 4 entsteht ein Fehler, obwohl `1/3` kürzer wäre. Ein fachlich erforderlicher `expansionLimit`-Rückfall darf seinerseits wegen eines zu langen Bruchtexts scheitern. Zwischenziffern bleiben durch `maxGeneratedDigits` begrenzt; eine noch offene Entwicklung wird nicht allein wegen ihrer vorläufigen Textlänge fälschlich als fertige Ausgabe behandelt.

## Strukturierte Ausgabe

Das Ausgabeobjekt enthält zusätzlich `RationalDecimalExpansion? expansion` mit Vorgabewert `null`. Der neue unveränderliche Typ enthält folgende Felder:

| Feld | Bedeutung |
|---|---|
| `negative` | Vorzeichen des Werts; bei Null `false` |
| `integerDigits` | Nichtleerer Ganzteil ohne Vorzeichen, Komma oder unnötige führende Nullen |
| `nonRepeatingDigits` | Vorperiode; bei endlichen Werten sämtliche Nachkommastellen, sonst gegebenenfalls leer |
| `repeatingDigits` | Kleinste Periode; bei endlichen Werten leer |

Damit könnte eine spätere UI den Periodenstrich darstellen, ohne den Klammertext zurückzuparsen. Ziffernfelder enthalten ausschließlich ASCII-Ziffern und bewahren erforderliche führende Nullen. Für ganze Zahlen sind beide Nachkommastellenfelder leer. Bei einem Bruchrückfall soll `expansion` fehlen, damit kein unvollständiger Dezimalversuch als exaktes Modell erscheint. Text und DTO müssen denselben Wert repräsentieren. Nur der neue angefragte Modus liefert zunächst dieses DTO, auch wenn seine Entwicklung endlich ist und das tatsächliche Format deshalb `exactDecimal` lautet. Die bisherigen Modi bleiben bei `expansion == null`. Damit wird ihr bisheriger Ausgabevertrag nicht erweitert; der neue öffentliche Typ heißt `RationalDecimalExpansion`.

## Geplante Referenzen und nächste Schritte

Die unveränderten unabhängigen [Planfixtures](../tests/reference/formatting/recurring_decimal_planned.json) und ihr [Planvalidator](../tools/check_recurring_decimal_plan.py) gehören zu diesem Entwurf. Sie erweitern nicht stillschweigend das bestehende Szenarioschema. Eine erfolgreiche Datenprüfung wäre nur eine Prüfung der Planungsdaten, kein Dart-Implementierungstest und kein Originalvergleich. Die Planungsdaten bleiben unverändert geplant; ihr separater Dart-Adapter hat im oben genannten CI-Lauf alle 30 Erwartungen gegen die Implementierung geprüft.

Das eigene JSON-Schema benennt Komponenten als `sign`, `integerPart`, `preperiod` und `period`. Für das DTO werden daraus `negative = sign < 0`, `integerDigits`, `nonRepeatingDigits` und `repeatingDigits`. Bei Null ist `sign == 0`, Ganzteil `0` und beide Nachkommafelder leer. Die Fixturefelder beschreiben stets die vollständige mathematische Entwicklung, auch wenn der begrenzte Versuch auf Bruch zurückfällt. `expectedFallback` hält dabei den gewählten Rückfallgrund auch dann fest, wenn dessen Bruchtext anschließend am Zeichenbudget scheitert; bei diesem Fehler sind `expectedText` und `expectedFormat` null. Dies ist Planmetadatum, kein zurückgegebener Teil eines fehlgeschlagenen Ausgabeobjekts.

Die Tests prüfen gezielte Fälle für kleinste Perioden, Vorperioden mit Nullen, Kürzung, Vorzeichen, ganze Zahlen, Abschluss genau am Ziffernrand, Budget 0, harte Zeichenlimits einschließlich Klammern und Rückfall, Parameterpriorität, Bitgrenze sowie unveränderte Werte und Snapshots. Die mathematische Rückumwandlung des DTO ist eine unabhängige Referenz: Bei Vorperiode `A` der Länge `a` und Periode `B` der Länge `b` ist der Nachkommawert `A/10^a + B/(10^a*(10^b-1))`; für endliche Werte entfällt der zweite Summand. Führende Nullen zählen bei den Längen mit.

Die spätere Appanbindung und der Originalvergleich bleiben offen; die Core-Laufzeitprüfung ist abgeschlossen. Additive Formatter-Signatur, DTO, Algorithmus, Budgetprioritäten, Rückfallgrund und Textnotation sind durch diesen Plan festgelegt. Die Core-Implementierung ist seit 02.11.2026 geprüft. Die Appanbindung ist nachfolgend geprüft; Originalvergleich ist weiterhin offen; eigene Projektänderungen dürfen nach der bestehenden Freigabe selbstständig gepusht werden.
