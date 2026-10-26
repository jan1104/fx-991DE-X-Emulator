# Linearer Bedienprototyp

Stand: 26.10.2026. Implementiert im unabhängigen Dart-Paket, ohne Flutter oder Betriebssystemzugriff in der Bibliothek. Dies ist ein begrenzter Entwicklungsprototyp, kein Nachweis vollständiger fx-991DE-X-Bedienkompatibilität.

## Schnittstelle

`CalculatorSession()` hält einen eigenen Rechnerzustand. `press(CalculatorKey)` oder `pressId('KEY_7')` verarbeitet genau eine semantische Taste und liefert den aktuellen `CalculatorSnapshot`. Eine UI kann später dieselbe Aktion für Touch, Maus oder Hardware verwenden. Eingabekanäle und Fokus werden damit noch nicht getestet.

Ein Snapshot enthält Phase (`editing`, `result`, `error`), unveränderliche Eingabetokens, logischen Cursor, `answer`, optionales Ergebnis und optionalen strukturierten Fehler. `expression` verbindet die Tokens für die lineare Anzeige; `cursorOffset` liefert den Stringoffset, während `cursor` ganze Tokens zählt. `Ans` ist ein einzelnes logisches Token mit drei sichtbaren Zeichen. Ältere Snapshots bleiben nach weiteren Tastendrücken unverändert. Sitzungen teilen keinen globalen Zustand.

Der Parser akzeptiert zusätzlich einen ausdrücklich übergebenen Ans-Kontext: `evaluate('Ans^2', answer: wert)`. Ans wird als strukturierter Zahlenoperand gebunden, nicht durch Einfügen einer Dezimal- oder Bruchzeichenfolge. So wird beispielsweise bei Ans=−1/2 aus Ans² korrekt 1/4 und nicht −1/4. Ohne Kontext wird Ans ausdrücklich als nicht unterstützt gemeldet.

## Unterstützte Primäraktionen

25 Schlüssel aus dem bestehenden Tasteninventar:

- Ziffern `KEY_0` bis `KEY_9`.
- `KEY_ADD`, `KEY_SUBTRACT`, `KEY_MULTIPLY`, `KEY_DIVIDE`, `KEY_POWER`.
- `KEY_NEGATE`, `KEY_DECIMAL`, `KEY_LPAREN`, `KEY_RPAREN`, `KEY_ANS`.
- `KEY_LEFT`, `KEY_RIGHT`, `KEY_DEL`, `KEY_AC`, `KEY_EQUALS`.

Das ist keine Abdeckung aller Belegungen dieser Tasten. Beispielsweise sind SHIFT/ALPHA und die gelben/roten Funktionen weiterhin offen. Unbekannte oder noch nicht unterstützte IDs wie `KEY_MENU` lösen einen strukturierten Unsupported-Fehler aus, ohne die Sitzung zu verändern.

## Übergänge

| Ausgangslage / Aktion | Ergebnis |
|---|---|
| Eingabe / Texttaste | Token am logischen Cursor einfügen; Dezimaltaste erzeugt Komma |
| Eingabe / Links oder Rechts | Cursor innerhalb der Tokengrenzen verschieben |
| Eingabe / DEL | Token links vom Cursor löschen; am Anfang keine Änderung |
| Eingabe / `=` | Ausdruck mit dem vorhandenen Core und aktuellem Ans auswerten; Erfolg aktualisiert Ergebnis und Ans |
| Ergebnis / binärer Operator | Neue Eingabe `Ans` plus Operator beginnen, exakten Antwortwert erhalten |
| Ergebnis / andere Texttaste | Neue Eingabe mit diesem Token beginnen |
| Beliebige Phase / AC | Eingabe, Ergebnis und Fehler leeren; Ans erhalten |
| Fehler / Links oder Rechts | Unveränderte Eingabe an der Fehlerposition wieder öffnen; Stringoffset auf logischen Tokenrand abbilden |
| Fehler / andere unterstützte Taste | Fehleranzeige beibehalten, außer AC |

Für noch nicht vollständig am Original belegte Details sind folgende **eigene Prototypregeln** ausdrücklich gewählt: Das erste Links/Rechts nach einem Ergebnis öffnet die alte Eingabe am Ende, ohne zusätzlichen Schritt. DEL nach Ergebnis öffnet diese Eingabe und löscht den letzten Token. `=` bei leerer Eingabe oder bereits angezeigtem Ergebnis ist ein No-op; es gibt keine Wiederholung der letzten Operation. Beide Pfeile nach Fehler öffnen zunächst dieselbe gemeldete Fehlerposition. Weitere Korrekturschritte werden anschließend normal verarbeitet. Diese Regeln müssen vor einem Anspruch auf Originaltreue noch abgeglichen werden.

## Fehler und Grenzen

Ein mathematischer oder Syntaxfehler ersetzt den bisherigen Ans-Wert nicht. Die Sitzung kapselt den bekannten `CalculatorException`-Fehler als Snapshot; Entwicklerfehler werden nicht pauschal verschluckt. Nicht unterstützte Tasten-IDs sind API-Fehler und werden vor dem Sitzungsübergang gemeldet.

Eingabe maximal 2048 sichtbare Zeichen; Ans zählt dabei drei Zeichen. Eine weitere Einfügung wird abgelehnt, der vorhandene Ausdruck und Ans bleiben erhalten, und ein Limit-Fehler wird angezeigt. Die Grenzen des bestehenden Parsers/Auswerters (unter anderem Zahlenliteral-, Token-, Exponenten-, Tiefen-, Rechengrößen- und Operationsbudget) gelten bei `=` zusätzlich. Ein erlaubter Editorinhalt muss deshalb nicht zwingend schon auswertbar sein. Dies sind eigene Ressourcenbudgets, keine behaupteten Casio-Grenzen.

## Tatsächliche Prüfung

- 67 Sessiontests prüfen IDs, alle Ziffern, Rechen-/Klammer-/Potenzfolgen, Cursor, atomare Ans-Tokens, unveränderliche Snapshots, Ergebnisübergänge, AC/DEL, Fehlerkorrektur und Limits.
- Drei weitere Evaluatortests prüfen expliziten Ans-Kontext, negative rationale Werte und Fehlerpositionen hinter dem sichtbaren Ans-Token.
- Ein gemeinsamer JSON-Referenzfall wird mit denselben KEY_-IDs abgespielt: `G07-key-division-zero` (`1 ÷ 0 =`). Geprüft sind Ausdruck, Fehlerphase und mathematische Fehlerklasse. Das ist nur die lineare Core-Projektion; Math→Math-Setup, lokalisierte Displaymeldung, sichtbarer Cursor und das Originalprogramm werden nicht mitgeprüft.
- Die unabhängige Codeprüfung fand keine weiteren konkreten Fehler. Das ersetzt keine Tests der noch offenen Funktionen.

Abschließender Gesamtstand: **181 Coretests bestanden** auf Windows x64 mit Dart 3.13.7, Formatprüfung ohne Änderung und statische Analyse ohne Befund. Noch keine reale Bildschirmtastatur, kein Widget-/Gerätetest und kein Originalvergleich.

## Nächster Schritt

Ein kleines Flutter-Grundgerüst kann diese getestete Sitzung anbinden. Die 25 unterstützten Primäraktionen werden dort gemeinsam für Maus/Touch und später Hardware verdrahtet; offene Funktionen bleiben sichtbar als noch nicht verfügbar gekennzeichnet. Danach folgen natürlicher Formeleditor sowie getrennte Arbeitspakete für SHIFT/ALPHA, Menüs und Speicher. Die genaue Reihenfolge wird nach dem UI-Machbarkeitstest fortgeschrieben.
