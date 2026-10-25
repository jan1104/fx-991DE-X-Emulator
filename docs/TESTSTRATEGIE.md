# Teststrategie: jede Taste und jede Rechenfunktion

Stand: 25.10.2026. Dies ist der Prüfplan für die eigene Implementierung. Es gibt noch keinen laufenden Emulator, keinen Dart-Testadapter und keinen ausgeführten Originalvergleich. Katalogprüfungen sind keine bestandenen Rechnerprüfungen.

## Wie Vollständigkeit nachgewiesen werden soll

Eine Liste bestandener Beispiele reicht nicht. Zwei Inventare bilden die Grundlage:

- [Tastenmatrix](../tests/reference/key_coverage.csv): jede der 50 physischen Tasten einschließlich der vier Pfeilrichtungen und jeder Ziffer einzeln; zusätzlich SHIFT-, ALPHA- und Modusbelegungen.
- [Funktionsmatrix](../tests/reference/function_coverage.csv): benannte Rechenfunktionen und Varianten mit Normalfall, Grenzen, ungültiger Eingabe und unabhängiger Referenz.

Zu jeder Inventarposition werden später konkrete Test-IDs und Ergebnisse verknüpft. Die CSVs sind derzeit Planung, keine Ausführungsberichte. Eine Inventarzeile mit einer Testidee ist noch kein implementierter Test. Noch nicht einzeln aufgelistete Konstanten und Umrechnungen bleiben eine ausdrücklich offene Enumerationsaufgabe.

Vertiefungen: [Tastenprüfplan](TESTPLAN_TASTEN.md), [Funktionsprüfplan](TESTPLAN_FUNKTIONEN.md), [56 Handbuch-Referenzfälle](REFERENZTESTS.md).

## Vier getrennte Prüfebenen

| Ebene | Was wird geprüft? | Beispiel |
|---|---|---|
| Mathematik | Zahlenwert, Rechenbereich, Fehler, Genauigkeit | 2/3 + 1 1/2 = 13/6 exakt |
| Bedienkern | Wirkung einer Aktion im jeweiligen Rechnerzustand | SHIFT öffnet eine Zusatzbelegung; nach der belegten Folgetaste ist die Umschaltung verbraucht |
| Oberfläche | Taste löst genau eine Aktion aus, Fokus/Cursor und Anzeige stimmen | Touch, Mausklick und Tastaturereignis erreichen denselben Kernbefehl |
| Zielsystem | Tatsächliche Installation, Darstellung und Bedienung auf dem Betriebssystem | Derselbe Fall läuft auf Android und Windows mit passender Anzeige |

Ein Test des Rechenkerns kann eine falsch verdrahtete Bildschirmtaste nicht erkennen. Ein korrektes Bildschirmfoto beweist wiederum weder einen korrekten internen Wert noch erhaltene Variablen.

## Prüfmatrix für jede Taste

Für jede Taste werden zunächst alle **belegten** Primär-, SHIFT-, ALPHA- und Moduswirkungen erfasst. Aufdrucklose Kombinationen bleiben bis zur Beobachtung unbekannt; es wird keine Wirkungslosigkeit erfunden.

Jede zu prüfende Belegung erhält Ausgangszustand, Tastenfolge und erwarteten Endzustand. Besonders wichtig sind die Kontexte Eingabe, Ergebnis, Hauptmenü, Untermenü, Setup, Dateneditor, Fehleranzeige und laufende Berechnung. Nicht jede Taste ist in jedem Kontext sinnvoll: dokumentierte Nichtanwendbarkeit mit Grund erfassen, statt fehlende Fälle als bestanden zu zählen.

Pflichtübergänge, zusätzlich zu üblichen Einzeltastentests:

- SHIFT/ALPHA aktivieren, Statusindikator sehen, belegte Folgetaste ausführen, Umschaltung kontrollieren.
- Alle Ziffern einzeln als Ziffern und als angebotene Menüauswahl prüfen; nicht aus einem erfolgreichen Test der 1 auf alle Ziffern schließen.
- Pfeile in verschachtelten Brüchen, Potenzen und Wurzeln; leere Felder, Anfang/Ende, horizontal abgeschnittene Ausdrücke und Verlauf.
- AC gegenüber DEL: Menü verlassen, Eingabe löschen, Fehler behandeln und Berechnung abbrechen; Variablen und Ans separat prüfen.
- STO, RECALL und ALPHA-Variable unterscheiden; M+/M− und Ans mit ihren Nebenwirkungen prüfen.
- MENU/SETUP/OPTN abhängig vom aktiven Modus; Rückkehr ohne Auswahl; verlorene/erhaltene Modusdaten.
- Ein kurzer Touch erzeugt genau eine Aktion. Langes Halten, Wiederholung und gleichzeitige Tasten nur entsprechend ausdrücklich festgelegter App-Regel bzw. späterer Referenzbeobachtung testen.
- Physische Tastatur: Fokus, Tab-Navigation, Sondertasten, wiederholte key-down-Ereignisse, Einfügen und Loslassen. Die PC-Tastenzuordnung ist unsere eigene App-Entscheidung, bis Original-PC-Kürzel vorliegen.

## Prüfmatrix für jede Rechenfunktion

Pro Funktion sind mindestens folgende Kategorien zu beurteilen, soweit anwendbar:

1. Einfacher, unabhängig überprüfbarer Normalfall.
2. Null, Eins, negative Werte, Brüche und große/kleine Beträge.
3. Werte direkt auf sowie knapp innerhalb/außerhalb der dokumentierten Definitions- und Kapazitätsgrenzen.
4. Ungültige Argumentzahl, fehlendes Feld, Syntaxfehler oder unzulässiger Zahlen-/Objekttyp.
5. Relevante Einstellungen: Winkel, Math/Linear, exakte/dezimale Ausgabe, Fix/Sci/Norm und komplex/reell.
6. Ergebnisformat und Nebenwirkungen auf Speicher, Variablen, Ans oder Tabellen.
7. Mindestens eine vollständige Bedienfolge über die sichtbare Eingabe; Kernfälle zusätzlich direkt und schneller testen.

Konkrete Kombinationen werden risikobasiert ausgewählt. Winkelumrechnung wird für alle drei Winkelmaße vollständig geprüft, Basis-N für alle vier Basen und Vorzeichenfälle. Unabhängige Anzeige-/Größeneinstellungen können paarweise kombiniert werden. Kritische Kombinationen bleiben Pflichtfälle; Paarabdeckung ist kein Ersatz für sie.

## Woher kommen die erwarteten Ergebnisse?

Die Referenz wird pro Fall angegeben und darf nicht einfach dieselbe Implementierung ein zweites Mal aufrufen:

| Referenzart | Verwendung | Einschränkung |
|---|---|---|
| Handbuchbeispiel | Numerischer Wert, angezeigte Form, Bedienzustand | Grafische Formeln und Symbolfonts visuell bestätigen |
| Exakte mathematische Ableitung | Brüche, ganzzahlige Funktionen, einfache Matrizen/Gleichungen | Herleitung dokumentieren; keine Rundungs-/Anzeigeregel daraus erfinden |
| Unabhängige Hochpräzisionsrechnung | Numerische Funktionen und schwierige Werte | Werkzeug und Version festhalten; nicht dieselbe Routine wie im Produkt verwenden |
| Mathematische Eigenschaften | Zusätzliche viele Fälle, etwa A·I=A oder Norm eines Einheitsvektors | Mehrere falsche Funktionen können dieselbe Identität erfüllen; nur ergänzende Evidenz |
| Späterer Originalvergleich | Exakte Bedien-, Rundungs- und Fehlerkompatibilität | Original kann selbst numerische Grenzen haben; mathematische und kompatible Erwartung getrennt berichten |

Für Zufallsfunktionen zunächst Intervall, Typ, Randfälle und kontrollierbare Testzufallsquelle prüfen. Die Original-Zahlenfolge ist unbekannt. Verteilungstests benötigen feste, dokumentierte Kriterien und sind ergänzend; zufällige schwankende Tests dürfen keine zuverlässige Freigabeschranke vortäuschen.

## Zahlenwert ist nicht gleich Anzeige

Exakte rationale Werte werden ohne Toleranz verglichen. Bei Näherungen wird je Funktion vor dem Test eine absolute und relative Toleranz begründet. Ein übliches Vergleichskriterium ist `|actual-reference| <= abs_tol + rel_tol*|reference|`; konkrete Toleranzen werden nicht pauschal für alle Funktionen gesetzt. Nahe null ist der absolute Anteil nötig. Grenzfälle, schlecht konditionierte Matrizen und numerische Nullstellen werden gesondert behandelt.

Bei SOLVE sowohl normiertes Residuum als auch Nähe zu einer erwarteten Wurzel prüfen, soweit diese zuverlässig bekannt ist. Ein kleines Residuum allein kann bei ungünstiger Skalierung irreführen. Unterschiedliche Startwerte und das Verfehlen einer Lösung gehören dazu. Nicht alle mathematischen Lösungen als garantierte SOLVE-Ausgabe verlangen.

Zusätzlich die tatsächliche Ausgabe prüfen: Bruch/Wurzel/π, Dezimalkomma, Exponent, Rundung, Präfix, Periodenstrich und Statusindikatoren. Bei Grafiktests feste Schrift und feste Prüfgröße verwenden; betriebssystembedingte Kantenglättung nicht mit einem mathematischen Fehler verwechseln. Strukturierte Ausgabedaten bleiben die primäre prüfbare Darstellung. Interaktive Cursor- und Fokusprüfungen ergänzen Bildvergleiche.

## Fehler, Grenzen und lange Bedienfolgen

- Division durch null, unvollständige Eingaben, unerlaubte Funktionsbereiche, numerischer Überlauf, Dimensionsfehler und Zirkelbezüge.
- Grenze minus eins, Grenze und Grenze plus eins bei Zeilen, Spalten, Graden und Speicherlimits. Byte-Limits nicht mit der Anzahl von Unicode-Zeichen gleichsetzen; Originalkodierung bleibt teilweise offen.
- Reproduzierbar erzeugte gültige und ungültige Ausdrücke mit fester Startzahl. Laufzeit, Verschachtelung und Datenmenge begrenzen; Hänger und unbehandelte Ausnahmen als Fehler erfassen.
- Lange Aktionsfolgen mit Bearbeiten, Speichern, Moduswechsel, Reset und Wiederholung; Fehlerfall möglichst auf die kürzeste reproduzierende Folge reduzieren.
- Lang laufende Berechnungen abbrechen. Danach muss eine neue Berechnung funktionieren; ein verspätetes altes Ergebnis darf die neue Anzeige nicht überschreiben.

## Ablauf ohne Originalsoftware

Jetzt: Inventare pflegen, Handbuchfälle verifizieren, Erwartungen herleiten, Format und Adapter vorbereiten. Anschließend die Tests gemeinsam mit den ersten Kern-/UI-Funktionen implementieren. Noch nicht verfügbare Funktionstests als offen führen, statt sie durch eine Ersatzrechnung scheinbar bestehen zu lassen.

Später: Originaldateien statisch prüfen, geeignete isolierte Laufzeit festlegen, dieselben Ausgangszustände und Bedienfolgen beobachten. Ergebnisse mit Programmversion, Einstellungen und Quellenbeleg protokollieren. Fremde Screenshots/Extraktionen bleiben im ignorierten Referenz-/Tempbereich. Ungeklärte Unterschiede werden als offene Kompatibilitätsfälle geführt.

## Ausführung und Freigaben

| Zeitpunkt | Umfang |
|---|---|
| Bei Änderung am Kern | Betroffene Kernfälle plus schnelle Regression für bereits implementierte Funktionen |
| Bei Änderung der Oberfläche | Betroffene Widget-/Fokustests und repräsentative vollständige Tastensequenzen |
| Vor Plattformfreigabe | Zugehöriger realer Build, Installation und Bedien-/Anzeigetests auf diesem Zielsystem |
| Vor SDK-/Abhängigkeitswechsel | Referenzfälle und betroffene Plattformtests erneut; Unterschiede dokumentieren |

Messgrößen getrennt ausweisen: Inventar erfasst, Testfall konkretisiert, Test implementiert, Test ausgeführt, bestanden, Originalvergleich erfolgt. Code-Zeilenabdeckung allein beweist keine Funktions- oder Tastenabdeckung. Ein Build allein beweist keine korrekte Rechnung.

Für einen als unterstützt gemeldeten Umfang muss jede enthaltene Funktion und Tastenbelegung passende Prüfungen besitzen. Offene und nicht anwendbare Positionen bleiben sichtbar. Eine Freigabe für alle fünf Betriebssysteme darf erst nach entsprechenden Zielprüfungen behauptet werden.

## Maschinenlesbare erste Beispiele

Unter `tests/reference/scenarios/seed_cases.json` liegen erste geplante Fälle als Formatentwurf. Mathematische Aufträge und physische Tastensequenzen sind verschiedene Fallarten. Die semantischen Tasten-IDs stammen aus der Tastenmatrix; Anzeige- und Speichererwartungen stehen getrennt vom Zahlenwert.

`python tools/check_test_catalogs.py` prüft nur IDs, Felder und Verknüpfungen der Kataloge. Das Werkzeug ist kein Rechen- oder UI-Testadapter und bewertet keine Emulatorfunktion als bestanden. Ein vollständiger Bericht über tatsächlich ausgeführte Fälle ist erst später möglich.

## Geprüfter Planungsstand

Am 25.10.2026 erfolgreich mit dem Katalogprüfer gelesen: 50 eindeutige physische Tasten, 243 geplante Funktions-/Prüfpositionen, fünf maschinenlesbare Beispielabläufe und gültige Verknüpfungen zu den 56 bisherigen Handbuchfällen. Dokumentlinks und `git diff --check` ebenfalls ohne Befund. Die beiden Subagenten lieferten getrennte Tasten- und Funktionspläne; der Hauptagent prüfte die Dokumente und ausgewählte mathematische Sollwerte. Alle Prüfpositionen bleiben `planned`. Insbesondere sind die Einzelkonstanten und gerichteten Umrechnungen noch zu enumerieren; daraus wird keine vollständige Funktionsabdeckung abgeleitet.
