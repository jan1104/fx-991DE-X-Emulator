# Periodische Ergebnisse, Setup und S⇔D

Vertrag vom 02.11.2026 vormittags, vor der Umsetzung dieses Apppakets festgelegt. Der bereits geprüfte [Core-Formatter](PERIODENDARSTELLUNG.md) wird an die bestehende Einstellung **Periodische Darstellung** angebunden. Die Werkzeugleiste und SHIFT → MENU verwenden weiterhin denselben Zustand. Der Quellenbefund H, physische PDF-S. 12–13/16, belegt den grundlegenden Bruch-/Perioden-/Dezimalwechsel; die folgenden Grenzen und Detailregeln sind eigene begrenzte Prototypentscheidungen, kein vollständiger Originalvergleich.

## Zyklus und direkte Dezimalausgabe

Bei **Norm 1/2** und eingeschalteter Periodendarstellung durchläuft S⇔D für periodische rationale Ergebnisse drei gewünschte Darstellungen:

`Bruch → exakte Periode → gerundeter Dezimalwert → Bruch`.

Beispiel: `1/6 → 0,1(6) → 0,1666666667 → 1/6`. Der Controller behält einen eindeutigen gewünschten Darstellungsmodus; identische Texte werden nicht zur Zustandsbestimmung zurückgeparst. Im Display wird nur die Periode überstrichen. Der kanonische Text mit Klammern bleibt als eigene Textrepräsentation verfügbar.

Endliche Werte und ganze Zahlen behalten den bisherigen zweistufigen Wechsel. Auch bei **Fix/Sci** oder ausgeschalteter Periodendarstellung gilt weiterhin `Bruch ↔ gerundeter Dezimalwert`; die festgelegte Präzisionsausgabe wird nicht von einer Periode übergangen. Eingabe/Ausgabe mit Dezimalvorgabe sowie SHIFT → `=` liefern weiterhin direkt den gerundeten Dezimalwert. Dies gilt in beiden Eingabearten.

SHIFT → S⇔D behält seinen vorhandenen Vertrag: dieselbe gemischte/unechte Bruchform wie im Setup wählen und zur Bruchansicht wechseln. Die Periodendarstellung verändert weder den Ergebniswert noch Ans oder den Ausdruck. Jede Sitzung behält ihren eigenen Entwurf und gewünschten Darstellungszustand.

## Lebendige globale Einstellungen

Wird **Periodische Darstellung → Aus** gewählt, während eine Sitzung die Periodenansicht angefordert hat, wechselt deren gewünschte Darstellung sofort auf den gerundeten Dezimalwert. Gleiches gilt beim Wechsel zu Fix oder Sci. Beide vorhandenen Ergebnissnapshots werden normalisiert, weil diese Einstellungen für beide Eingabearten gelten. Rechenwerte, Ans und Editor bleiben erhalten. Inaktive Bearbeitungs-/Fehlerzustände werden nicht ausgewertet oder verändert.

Das Zurückschalten zu Norm oder Perioden-Ein wählt nicht automatisch eine neue Ergebnisdarstellung. Der nächste S⇔D-Druck bestimmt den Wechsel. Der Setup-Punkt verliert seinen bisherigen Hinweis „in Vorbereitung“; noch nicht implementierte andere Setup-Bereiche behalten ihre Kennzeichnung.

## Grenzen und Ausgabeprobleme

Der Appversuch verwendet das bestehende Core-Standardbudget von 100 erzeugten Nachkommastellen und 2048 Ausgabezeichen. Eine noch nicht vollständig erkannte Entwicklung erzeugt `expansionLimit`: Der Bruch bleibt exakt sichtbar, ergänzt um einen verständlichen Hinweis. Der gewünschte Periodenmodus bleibt erhalten; ein weiterer S⇔D-Druck öffnet den gerundeten Dezimalwert. Es wird keine unvollständige Periode angezeigt.

Tatsächliche Werte-/Zeichenlimitfehler werden weiterhin als separate Anzeigeprobleme behandelt. Sie dürfen nicht als ungefangene Ausnahme des Tastendrucks auftreten, keinen Rechenfehler in die Sitzung schreiben und keine Grenze durch einen vermeintlich erfolgreichen Ersatzwert verschleiern. Die Auswahl kann den Periodenmodus beibehalten, während erst der sichere Textabruf den Ausgabehinweis auslöst; S⇔D bleibt danach bedienbar.

## Gemeinsames Ausgabemodell und Ansicht

`CalculatorResultPresentation` bündelt Text, optionales Core-Expansionsobjekt, fertig formatierten `periodPrefix` und optionalen Rückfallgrund. `resultText` bleibt als kompatibler Textabruf erhalten. Die Rechnerseite ruft das gemeinsame Modell einmal je Aufbau ab. Gruppierung, Vorzeichen, Ganzteil, Komma und Vorperiode werden im Controller vorbereitet; der neue Ansichtsbaustein führt keine zweite Zahlenformatierung durch und zerlegt keinen Ergebnisstring.

Bei einer Periode zeichnet die Ansicht Präfix und genau die wiederholten Ziffern mit Überstrich. Vorperiode, Vorzeichen und Ganzteil werden nicht überstrichen. Eine assistive Beschreibung benennt ausdrücklich die Periode. Andere Ergebnisse behalten die vorhandene Textansicht. Kontrast, horizontaler Bildlauf und 320-Pixel-Ansichten müssen weiterhin funktionieren. Für die neue Rich-Text-Ansicht kann der sichtbare Text ohne Klammern über `textSpan` abgerufen werden; es gibt keine versteckten Testkopien des Ergebniswidgets.

## Prüfung und nächster Schritt

Neue Controllerfälle prüfen Zyklus, Rückfälle, direkte Dezimalausgabe, beide Eingabearten, globale Normalisierung und exaktes Ans. Neue Widgetfälle prüfen Tasten-/Setup-Bedienung, Überstrich und Semantik, Ausgabehinweise sowie Kontrast und schmale Darstellung. Der bestehende Cloud-Test-/Web-Build bleibt der tatsächliche Ausführungsweg; bekannte blockierte lokale Tests werden nicht erneut gestartet. Ergebnisse und geprüfte Revision werden im [Entwicklungsstand](ENTWICKLUNGSSTAND.md) dokumentiert. Eine Vorschau mit echter Periodenansicht soll zusätzlich erzeugt und visuell geprüft werden.
