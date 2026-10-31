# Exakte rationale Bruch- und Dezimalausgabe

Vertrag vom 30.10.2026, vor der Implementierung festgelegt. Dieses Paket ergänzt ausschließlich einen unabhängigen Formatierungsdienst im Dart-Core. Die vorhandenen Sitzungen, Tastenzuordnungen und Flutter-Anzeigen werden in diesem Schritt nicht verändert.

## Quellen und Abgrenzung

Das bestehende Quelleninventar belegt den Originalwechsel über S⇔D und den Setup-abhängigen Zyklus Bruch/Periode/gerundete Dezimalanzeige (H, physische PDF-S. 12–13/16; [Tasten und Bedienung](TASTEN_UND_BEDIENUNG.md)). Der erste eigene Dienst deckt ausschließlich gekürzte Brüche und **exakt endliche** Dezimaldarstellungen ab. Er ist keine vollständige Implementierung dieser Originaltaste. Periodenschreibweise, Rundung, Fix/Sci/Norm, gemischte Brüche und originalgetreue Anzeigegrenzen bleiben offen.

Die Ausgabe verwendet kein `double` und keinen gerundeten Zwischenwert. Der mathematische `Rational`-Wert bleibt unverändert; insbesondere kann eine spätere Anzeigeumschaltung Ans nicht durch angezeigte Ziffern ersetzen.

## Schnittstelle und Verhalten

`formatRational(value, format: ..., maxDecimalPlaces: 100, maxOutputCharacters: 2048)` liefert ein unveränderliches `RationalDisplay` mit Text, tatsächlich gewähltem Format und optionalem Rückfallgrund. `RationalDisplayFormat.fraction` ist die Vorgabe, `exactDecimal` wählt den exakten Dezimalversuch.

Im Bruchmodus entspricht die Ausgabe dem gekürzten Wert: `-3/2`, `1/3`, bei Nenner 1 nur die ganze Zahl. Im Dezimalmodus gelten deutsches Komma, ASCII-Minus, führende Null vor dem Komma und keine unnötigen Endnullen. Null lautet `0`; ein negatives Nullformat entsteht nicht. Ganze Zahlen brauchen weder Komma noch Nachkommastellen.

Ein vollständig gekürzter Bruch hat genau dann eine endliche Dezimalentwicklung, wenn der Nenner nur die Primfaktoren 2 und 5 enthält. Die benötigte Stellenzahl ist das Maximum ihrer Exponenten. Für einen anderen Restfaktor wird der ursprüngliche gekürzte Bruch ausgegeben und `periodic` gemeldet; es wird keine Periode erzeugt und keine gerundete Zahl als exakt ausgegeben.

Die Faktoren 2 und 5 werden jeweils höchstens bis zum Stellenbudget plus eins untersucht. Sobald einer der Exponenten das Budget überschreitet, erfolgt der Bruchrückfall mit `decimalPlacesLimit`. Diese Ressourcenentscheidung hat Vorrang vor der weiteren Untersuchung möglicher periodischer Restfaktoren. Beispielsweise ergibt `1/(2^101*3)` bei Budget 100 den Limitgrund, ohne zu behaupten, der Bruch wäre endlich.

| Wert | Dezimalwunsch | Ergebnis |
|---|---|---|
| `1/2` | Standardbudget | `0,5`, exakt dezimal |
| `-3/2` | Standardbudget | `-1,5`, exakt dezimal |
| `1/40` | drei Stellen | `0,025`, exakt dezimal |
| `1/40` | zwei Stellen | `1/40`, Stellenlimit |
| `1/3` | Standardbudget | `1/3`, periodisch |
| `6/15` | Standardbudget | `0,4`, nach Kürzung |
| `123` | null Stellen | `123`, exakt dezimal |
| `1/2` | null Stellen | `1/2`, Stellenlimit |

`maxDecimalPlaces` liegt zwischen 0 und 1000, `maxOutputCharacters` zwischen 1 und 10000. Ungültige Parameter erzeugen `ArgumentError`. Das Zeichenbudget umfasst sämtliche ausgegebenen Zeichen einschließlich Minus, Komma und Bruchstrich und gilt auch für den Bruchrückfall. Passt die gewählte exakte Darstellung nicht hinein, entsteht `CalculatorException` mit `limit`; es wird weder still abgeschnitten noch auf eine ungenaue Darstellung gewechselt. Eine vollständig erzeugte, übergroße Zahl soll durch eine Größenprüfung vor dem Textaufbau vermieden werden.

## Prüfung und nächster Schritt

Eigene Coretests prüfen Werte, Kürzung, Vorzeichen, Stellen- und Zeichenränder, Parameterfehler, große Ganzzahlen jenseits der Gleitkommagenauigkeit und mathematische Rückumwandlung endlicher Dezimaltexte. Sie prüfen zusätzlich, dass Formatierung keine Sitzung oder deren Ans verändert. Tatsächliche Ausführung und Zahlen stehen im [Entwicklungsstand](ENTWICKLUNGSSTAND.md). Die Originalkataloge bleiben Planungsdaten.

Fortschreibung 31.10.2026: Die ausdrückliche Auswahl des Darstellungsmodus ist für beide Sitzungsmodelle vorbereitet, ihre Ausführungsprüfung ist inzwischen ebenfalls blockiert; [DARSTELLUNGSWAHL.md](DARSTELLUNGSWAHL.md) legt die Übergänge fest. Ergebniswert und Ans bleiben unabhängig vom formatierten Text. Eine Appanbindung soll erst nach Wiederherstellung der richtlinienkonformen Flutter-Testausführung erfolgen, damit die derzeit offenen Quadrat-/Kehrwertprüfungen zuerst abgeschlossen werden können.
