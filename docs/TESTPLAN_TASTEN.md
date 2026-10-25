# Prüfplan für jede physische Taste

Stand: 25.10.2026. **Planungsstand: alle Fälle `planned`; keine Taste wurde hierdurch als implementiert oder bestanden geprüft.** Geprüft wurden nur Aufbau und Vollständigkeit der CSV-Datei. Es liegt noch keine Messreihe am Originalemulator vor.

## Verbindliches Tasteninventar

[`tests/reference/key_coverage.csv`](../tests/reference/key_coverage.csv) enthält genau eine Zeile je physischer Taste mit stabiler `key_id`: **50 Zeilen**, darunter **zehn einzelne Ziffern** und **vier einzelne Pfeilrichtungen**. Der Vierwegeblock wird deshalb als vier Tasten geführt. Zählung: vier Kopftasten + vier Pfeile + vier Tasten der ersten Funktionsreihe + drei Reihen zu sechs Tasten + vier Reihen zu fünf Tasten = 50.

Grundlage ist der bereits visuell geprüfte Katalog [`TASTEN_UND_BEDIENUNG.md`](TASTEN_UND_BEDIENUNG.md): Tastaturbild K, PDF-S. 1, und die dort dokumentierten H-Belege. Die PDFs werden für diesen Prüfplan nicht neu vollständig ausgewertet. `KEY_EQUALS` ist die Ausführtaste; das Gleichheitszeichen im Ausdruck entsteht über `KEY_ALPHA`, `KEY_CALC`. `KEY_NEGATE` ist das negative Vorzeichen und bleibt von `KEY_SUBTRACT` getrennt.

CSV-Konventionen:

- UTF-8, Komma als Spaltentrenner, reguläre CSV-Anführungszeichen und genau neun Spalten. Listen innerhalb einer Zelle sind durch Semikolon getrennt. Mit `csv.DictReader` lesbar.
- `primary`, `shift`, `alpha` benennen die dokumentierten Funktionen; das ist keine Beschränkung auf genau einen Bildschirm.
- `mode_overrides` nennt bestätigte Umbelegungen im Basis-N- und Komplexmodus.
- **`unknown_reference` bedeutet nicht wirkungslos.** Für unbedruckte Kombinationen und unbekannte Modusbelegungen fehlt ein verlässlicher Sollwert; diese werden später gezielt beobachtet und separat bewertet.
- `contexts_to_test` ist eine Prüfliste, keine Behauptung, dass die jeweilige Rechenfunktion in jedem Kontext zulässig sei.
- Alle Zeilen haben `status=planned`. Der Inventarstatus wird nicht durch einen einzelnen erfolgreichen Teiltest zum Gesamtstatus „bestanden“.

## Wie aus jeder Zeile konkrete Fälle entstehen

Jede Taste bekommt Fälle mit IDs nach dem Schema `KT_<key_id>_<family>_<context>_<variant>`, beispielsweise `KT_KEY_DEL_base_editor_math_middle`. Die Namen bezeichnen künftige Tests, keine schon vorhandenen ausführbaren Tests. Wiederverwendete Rechenbeispiele dürfen auf bestehende Fälle aus [`REFERENZTESTS.md`](REFERENZTESTS.md) verweisen; deren IDs bleiben unverändert.

Für jeden Fall festhalten: Modus und Setup, Ausdruck/Ergebnis, Cursor und Fokus, ausgewählte Menü-/Tabellenzelle, SHIFT-/ALPHA-Zustand, Ans, Variablen A–F/M/x/y, Verlauf sowie relevante Modusdaten. Danach exakt geordnete Tastenereignisse, erwartete Änderungen und ausdrücklich unveränderte Daten erfassen. Zusätzlich Beleg, Herkunft des Sollwerts (`manual`, später `observed_original` oder eigene Produktentscheidung), Eingabekanal und Testplattform dokumentieren. Bei numerischen Näherungen sind begründete Toleranzen erforderlich; eine gerundete Anzeige ist kein vollständiger Nachweis des internen Werts.

Ein gemeinsamer Ausgangszustand für einfache Rechentests ist Berechnungen, Math → Math, Gradmaß, Norm 1 und die sonstigen dokumentierten Vorgaben. Vor Persistenztests gezielt unterschiedliche Speicherwerte setzen und nachher auslesen; ein Reset vor dem Nachmessen würde den zu prüfenden Zustand zerstören. Lineare Tests starten ausdrücklich in Lin. → Linear. Für Zufallstests den Zustandsvergleich auf unveränderliche Daten begrenzen und gegebenenfalls später einen eigenen deterministischen Test-Zufallsgenerator verwenden.

### Pflichtfamilien für alle 50 Tasten

| CSV-Familie | Konkrete Prüfung | Abnahmekriterium bzw. offene Referenz |
|---|---|---|
| `base` | Primärtaste in einem geeigneten Ausgangszustand einzeln aktivieren, danach einen unterscheidbaren Folgeschritt ausführen. | Funktion, sichtbare Ausgabe und Zustandsänderung passen zum belegten Sollwert. |
| `shift_once` | SHIFT, Taste T, anschließend eine zweite Funktionstaste ohne SHIFT; dasselbe aus frischem Zustand wiederholen. | Für belegte Belegungen wirkt die gelbe Funktion einmal; der Indikator erlischt. Wiederholtes SHIFT und unbedruckte Kombinationen zunächst `unknown_reference`. |
| `alpha_once` | ALPHA, T, danach Funktionstaste ohne ALPHA. | Für belegte Belegungen wirkt die rote Funktion einmal; danach normale Belegung. Unbedruckte Kombinationen erhalten keinen erfundenen No-op-Sollwert. |
| `context_dispatch` | Jede Taste direkt, nach SHIFT und nach ALPHA in natürlichem Editor, linearem Editor, Hauptmenü, Setup, Ergebnis- und Fehleranzeige prüfen. | Der Kontext bestimmt die Aktion. Unbekannte Kombinationen werden als offene Referenz erfasst, nicht pauschal ignoriert oder als bestanden gezählt. |
| `memory_sideeffects` | Vorher/Nachher von Ans, A–F, M, x/y, Verlauf und betroffenen Modusdaten vergleichen. | Nur belegte oder ausdrücklich spezifizierte Änderungen sind zulässig; Aufräumen erst nach dem Vergleich. |
| `input_parity` | Dieselbe Folge über Bildschirmtaste per Maus, per Touch und über eine festgelegte Hardware-Tastenzuordnung auslösen. | Bei gleicher semantischer Aktion entstehen dieselben Kernzustände; Plattform- und Kanalnachweis separat. |
| `dedup_focus` | Press/Release bzw. Pointer-/Click-Kette, Fokuswechsel, Abbruch einer Berührung und gemischte Kanäle prüfen. | Ein einzelnes abgeschlossenes Benutzerereignis erzeugt genau eine Aktion; kein Verlust, keine doppelte Berechnung und kein unbeabsichtigtes Scrollen/Bedienen anderer Ansichten. Details unten. |

Die sechs Grundkontexte ergeben zunächst **50 × 3 Aktivierungsarten × 6 Kontexte = 900 zu bewertende Kombinationen**. Das ist eine Planungsmatrix, keine Zahl bestandener oder bereits spezifizierter Tests. Für jeden Eintrag muss später ein belegter Sollwert, eine offene Beobachtungsfrage oder eine begründete Nichtanwendbarkeit vorliegen. Die zusätzlichen CSV-Kontexte und Bediensequenzen kommen hinzu. Nichtanwendbarkeit darf nicht allein aus einem fehlenden Aufdruck abgeleitet werden.

Kontext-Fixtures: leerer und nichtleerer Math-Editor; linearer Editor mit Cursor in der Mitte; Hauptmenü mit bekannter Auswahl; Setup mit Untermenü; Ergebnis von `1 ÷ 7`; Fehler aus `1 ÷ 0 =`. Grenzfälle mit vollem Editor, linker/rechter Cursorgrenze und Menürand werden zusätzlich geführt. Fehlertexte und Cursorverhalten müssen getrennt von der Berechnung geprüft werden.

## Primär- und Zusatzfunktionen mit unterscheidbaren Beispielen

Diese Fälle vervollständigen die generischen Familien. Zahlenbeispiele ohne eigenen Handbuchbeleg sind **eigene mathematische Prüfvektoren** auf Basis der dokumentierten Funktion, keine gemessenen Originalergebnisse. „Vorlage füllen“ ist hier eine semantische Beschreibung; die späteren Tastenfälle müssen die einzelnen Pfeil-/Ziffernereignisse vollständig angeben und den Cursor nach jedem Schritt prüfen.

| Taste/Familie | Konkreter Prüfvektor |
|---|---|
| KEY_0 bis KEY_9, `digits` | Für jede Ziffer d separat: AC, `1`, d, `=` → 10+d, also beispielsweise `KEY_1, KEY_0` → 10. Zusätzlich d in Zähler/Nenner, linearem Cursorinneren und passendem sichtbaren nummerierten Menüpunkt prüfen. Die Menünummer 0 muss keine gültige Wahl sein: unbekannte oder fehlende Nummern separat referenzieren. |
| KEY_ADD/SUBTRACT/MULTIPLY/DIVIDE, `operators` | `8+3=11`, `8−3=5`, `8×3=24`, `8÷2=4`; anschließend ein Operator nach dem Ergebnis und Ans-Fortsetzung prüfen. Multiplikation/Division zusätzlich mit natürlichen Vorlagen und ausgelassenem Multiplikationszeichen. |
| KEY_NEGATE, `precedence` | `KEY_NEGATE, KEY_2, KEY_SQUARE, KEY_EQUALS` → −4; `KEY_LPAREN, KEY_NEGATE, KEY_2, KEY_RPAREN, KEY_SQUARE, KEY_EQUALS` → 4. Subtraktion und Vorzeichen nicht verwechseln. |
| KEY_LPAREN/RPAREN, `parentheses` | `(2+3)×4=20`; Gradmaß: `sin(30)+15=15,5`. Die schließende Klammer vor `+15` ist entscheidend. SHIFT → `(` mit −5 liefert Abs=5; SHIFT → `)` trennt Funktionsargumente; ALPHA → `)` liefert Variable x. |
| KEY_FRACTION, `templates`, `remainder` | Vorlage 2/3 plus Vorlage 1/6 → 5/6; SHIFT-Vorlage 1 1/2 → 3/2 bei d/c; `5 ALPHA Bruch 2 =` → Quotient 2, Rest 1, Ans=2. [H, PDF-S. 13–15] |
| KEY_SQRT, `templates`, `repeating_decimal` | √9=3; SHIFT-Wurzel mit 8 → 2; `0, ALPHA √ 3` erzeugt periodische 0,3 und entspricht 1/3, nicht 0,3. Natürliche Darstellung und Endposition des Periodenfelds prüfen. |
| KEY_SQUARE/POWER, `powers`, `templates` | `3 x² =9`, SHIFT x² → 27, Potenzvorlage 2^5 → 32, SHIFT-Potenzvorlage fünfte Wurzel aus 32 → 2. |
| KEY_LOG_BASE/LN/NEGATE, `log_exp` | log zur Basis 2 von 8 → 3; SHIFT KEY_LOG_BASE mit 2 → 100; ln(1)=0; SHIFT LN mit 0 → 1; SHIFT NEGATE liefert log(100)=2. |
| KEY_RECIPROCAL, `factorial` | Kehrwert von 4 → 1/4; SHIFT x⁻¹ mit 5! → 120. Zusätzlich 0 als Kehrwert-Fehler und ungültiges Fakultätsargument prüfen. |
| KEY_SIN/COS/TAN, `angle_units` | Grad: sin30=1/2, cos60=1/2, tan45=1; inverse SHIFT-Funktionen mit 1/2,1/2,1 → 30,60,45. Sinus zusätzlich in Rad mit π/6 und in Gon mit 100 → 1. |
| KEY_DMS, `dms_fact` | 2°30′0″ ↔ 2,5; nach `1014 =`, SHIFT DMS → 2×3×13², erneut SHIFT DMS → 1014. [H, PDF-S. 14–15] |
| KEY_X/INTEGRAL, `templates` | x=2 zuweisen, x+1 → 3; Σ(x+1), x=1…5 → 20, Π(x+1) → 720. Integral x von 0 bis 1 → ungefähr 0,5, Ableitung x² bei x=3 → ungefähr 6. Grenzen, Ausdruck und Auswertungspunkt dürfen nicht vertauscht sein. |
| KEY_MULTIPLY/DIVIDE, `combinatorics`, `integer_functions` | `10 SHIFT × 4 =` → 5040; `10 SHIFT ÷ 4 =` → 210. ALPHA ×: GCD(28;35)=7; ALPHA ÷: LCM(9;15)=45. [H, PDF-S. 21–22] |
| KEY_ADD/SUBTRACT, `coordinates`, `integer_functions` | Grad: Pol(√2;√2) → r=2, θ=45 und x/y entsprechend gesetzt; Rec(√2;45) → x=1,y=1. Int(−3,5)=−3, Intg(−3,5)=−4. [H, PDF-S. 21–22] |
| KEY_0, `rounding` | Fix3: Rnd(10÷3)×3 → 9,999, dagegen 10÷3×3 → 10,000; ALPHA 0: RndFix(1,23456;4) → 1,2346. [H, PDF-S. 22] |
| KEY_DECIMAL, `decimal_random` | `1,25+0,5=1,75`; zweites Komma bzw. Komma in Basis-N zunächst gemäß Referenz behandeln. Ran# liegt im dokumentierten Bereich und hat die definierte Stellenstruktur; RanInt(1;6) ist ganzzahlig und zwischen 1 und 6. Nicht einen bestimmten Zufallswert erwarten. [H, PDF-S. 21] |
| KEY_EXP10, `scientific_constants` | `1,2 ×10ˣ 3 =` → 1200; Exponentvorzeichen separat prüfen. SHIFT EXP10 ÷ 6 → π/6; `LN, ALPHA, EXP10, ), =` → ln(e) ungefähr 1. Anzeigeformat und numerische Toleranz unterscheiden. |
| KEY_7/8, `constant_conversion` | SHIFT7 öffnet CONST und wählt einen eindeutig benannten Eintrag, z.B. c₀; SHIFT8 nach Wert 1 öffnet CONV, cm→in liefert ungefähr 0,3937007874. Symbol/Einheitenrichtung und Rückkehrzustand zusätzlich prüfen, nicht nur eine Menüposition. |
| KEY_ANS, `answer_memory`, `percent` | `14×13=182`, danach `÷7=` → 26. Ans ausdrücklich in `789−Ans` nach `123+456=579` → 210. `150×20 SHIFT Ans =` → 30. [H, PDF-S. 13,17] |

## Heikle Tasten: vollständige Bedienfolgen und Zustandskontrollen

Die folgenden Folgen verwenden Tastenbeschriftungen. A-Taste meint KEY_NEGATE, B-Taste KEY_DMS, M-Taste KEY_M_PLUS. Jede Folge beginnt aus dem ausdrücklich genannten Zustand; getrennte Unterfälle erneut herstellen.

1. **SHIFT/ALPHA einmalig und Wechsel:** Im leeren Math-Editor `SHIFT, SIN, 0, ), +, SIN, 0, ), =` → 0, wobei die zweite SIN-Eingabe `sin` und nicht `sin⁻¹` erzeugt. `ALPHA, KEY_NEGATE, +, KEY_NEGATE, 2` muss zunächst Variable A und dann das negative Vorzeichen liefern; Ausdruck und Indikatoren vor Ausführung prüfen. Die Folgen SHIFT–SHIFT, ALPHA–ALPHA, SHIFT–ALPHA und ALPHA–SHIFT bleiben ohne Messung `unknown_reference`; nicht aus der allgemeinen Einmalregel frei ableiten.
2. **DEL/INS/UNDO:** Math-Editor `1,2,3`, Links, DEL: Zeichen links der belegten Cursorposition löschen, Ausdruck und Cursor prüfen; Links an der Grenze darf keinen Indexfehler erzeugen. In Lin. → Linear `123`, Cursor auf die Position des mittleren Zeichens setzen, SHIFT DEL, `9`: mittleres Zeichen überschreiben; erneut SHIFT DEL und `8`: einfügen. In Math-Eingabe einen einzelnen bekannten Schritt ausführen, ALPHA DEL rückgängig, nochmals ALPHA DEL wiederherstellen. In Statistik Daten `[11,22,33]`, Zeile 2 markieren, DEL: komplette Zeile 22 löschen, Nachbarzeilen korrekt nachrücken. [H 12,27; K 4]
3. **AC und Fehler:** `1÷0=` erzeugt Fehler; Links bzw. Rechts bringt den unverlorenen Ausdruck zum Editieren an die Fehlerstelle. Aus demselben Fehlerzustand AC löscht den fehlerhaften Ausdruck. Untermenü öffnen, AC: Menü ohne Auswahl verlassen. CALC/SOLVE-Dialog öffnen, AC: Sitzung beenden. Während einer hinreichend langen eigenen Rechenaufgabe AC: Abbruch muss angenommen werden; kein hängender Busy-Zustand. Die genaue Abbruchanzeige und Ans-Wirkung sind noch am Original zu messen. [H 6,18,24–25,47]
4. **STO/RECALL/M+:** `0,STO,M`; `10,×,5,M+` → Anzeige 50, M=50; `10,+,5,SHIFT,M+` → Anzeige 15, M=35. `SHIFT,STO,M,=` → 35. `3,+,5,STO,A` → A=8; `ALPHA,A,×,1,0,=` → 80. Für A–F, M, x, y jeweils unterschiedliche Werte setzen, speichern und abrufen; nach STO keine zusätzliche ALPHA-Aktion einfügen. RECALL mit AC schließen darf keinen Abruf vortäuschen. [H 17–18]
5. **MENU/SETUP/ON/OFF/RESET:** A=8, M=35 und mindestens zwei Verlaufseinträge vorbereiten. MENU, anderen Modus wählen: Verlauf leer, A/M erhalten. SHIFT MENU, Ausgabeformat ändern: Verlauf leer, A/M erhalten. SHIFT AC, ON: wieder an, A/M erhalten. Aus gefüllter Tabellenkalkulation ON, OFF/ON und Moduswechsel getrennt prüfen: Zellen werden gelöscht. Für jede Resetvariante frischen Zustand anlegen: SHIFT9,1,= initialisiert Setup außer Kontrast; SHIFT9,2,= löscht Speicher; SHIFT9,3,= initialisiert umfassend außer Kontrast. Kontrast vorab erkennbar verstellen und nachher prüfen. [H 3–4,10,17–18,42]
6. **Pfeile und Navigation:** `2+2=`, `3+3=`; Auf/Ab bewegt sich im Verlauf, Links/Rechts öffnet Rechnung zur Bearbeitung. Reihenfolge, Endanschläge und Cursorposition protokollieren; kein unbelegtes Wrap-around erfinden. Hauptmenü: alle erreichbaren Symbole mit Pfeilen ansteuern, `=` öffnet das markierte. Setup: über den sichtbaren Seitenrand hinaus scrollen; Links im Untermenü geht zurück. In einer gemischten Bruch-/Integralvorlage SHIFT Links/Rechts springt vor/hinter die gesamte Vorlage. [H 6–7,11–12,17]
7. **S⇔D und ENG:** Math → Math, Period. Darst. Ein: `1÷7=` → 1/7, S⇔D → periodische 0,142857, erneut → gerundete Dezimalform, erneut → 1/7. `3÷2=` und SHIFT S⇔D wechseln unechten/gemischten Bruch. `1234=,ENG` → 1,234×10³; Gegenrichtung mit SHIFT ENG. Wechsel zu Komplexe Zahlen: `1,+,ENG,=` → 1+i; SHIFT ENG erzeugt ∠, keine technische Exponentenverschiebung. [H 13–16,23]
8. **CALC/SOLVE und Eingabe-`=`:** `3,ALPHA,A,+,ALPHA,B,CALC,5,=,10,=,=` → 25. CALC erneut, nur einen Parameter ändern und erneut ausführen; AC beendet. Im Berechnungen-Modus `x²+B`, ALPHA CALC, `0`, SHIFT CALC; x-Startwert 1 und B=−2 eingeben, x als Lösungsvariable markieren, `=` → Näherung an √2 mit Residuum. Negative Anfangswerte als eigenen Fall; ein einzelnes Ergebnis ist kein Nachweis sämtlicher Nullstellen. [H 24–25]
9. **Ausführen statt Gleichheitszeichen:** Math → Math, `1÷7 SHIFT =` liefert direkt dezimal. `3+3,ALPHA INTEGRAL,3×3,=` zeigt zuerst 6, weiteres `=` zeigt 9. Aus Editor mit einem einzigen Tap auf `=` muss genau eine Teilrechnung ausgeführt werden; ein gedoppeltes Ereignis würde diesen Fehler sofort sichtbar machen. Im Menü bestätigt dieselbe Taste die Auswahl, im Zahleneditor einen Wert. [H 9,14]
10. **OPTN/QR:** OPTN im leeren Berechnungen-Modus zeigt andere Einträge als in Statistik oder Tabellenkalkulation. SHIFT OPTN aus Ergebnisanzeige öffnet QR; AC oder erneut SHIFT OPTN schließt. Mehrteilige QR-Anzeige mit Auf bzw. `=` weiterschalten; Links/Rechts ändert hier den QR-Kontrast. Inhaltserzeugung und heutige Erreichbarkeit eines externen Webdiensts getrennt bewerten. [H 22–23]
11. **Basis-N als Umbelegung:** Basis-N, DEC, `15×37=` → 555, HEX → 0000022B. Im Hex-Modus die sechs physischen Tasten KEY_NEGATE/DMS/RECIPROCAL/SIN/COS/TAN direkt als A–F verwenden; kein ALPHA voraussetzen. BIN und OCT mit denselben Basiswechsel-Tasten prüfen. Danach Berechnungen öffnen und erneut Quadrat/Potenz/log/ln bzw. Vorzeichen/Trigonometrie prüfen: keine Modusbelegung darf hängenbleiben. [H 29–30]
12. **Wertetabelle und Tabellenkalkulation:** In der Wertetabelle eine x-Zelle mit bekanntem Vorgänger wählen: `+` oder `=` übernimmt Vorgänger plus Inkre, `−` Vorgänger minus Inkre; f/g werden in derselben Zeile aktualisiert. In Tabellenkalkulation in einer Zelle `ALPHA CALC,A,1,+,7,=` als Formel =A1+7 eingeben; OPTN → Zelle bearbeit. wechselt zum Textcursor, Pfeile und DEL bearbeiten diesen Text. Zifferntaste ohne Bearbeitungsmodus und Texteingabe im Bearbeitungsmodus nicht verwechseln. [H 34–35,43]

## Eingabekanäle, Fokus und doppelte Auslösung

Dies sind **eigene Qualitätsanforderungen der geplanten App**, keine Behauptung über Maus-/Touchverhalten des alten Casio-Emulators.

- Jede virtuelle Taste bekommt eine eindeutige semantische Aktion mit derselben `key_id`. Maus, Touch und spätere Hardwarekürzel sollen auf diese Aktion führen. Noch nicht festgelegte Hardwarekürzel werden als nicht zugeordnet dokumentiert; die Originalsoftware-Kürzel sind unbekannt.
- Pro Taste: Maus herunter/hoch auf derselben Taste; Touch beginnen/beenden auf derselben Taste; Hardware-KeyDown/KeyUp für die zugeordnete Aktion. Ein vollständiger kurzer Tastendruck bewirkt genau eine Aktion. Entscheidend ist der Aktionszähler, nicht nur der sichtbare Zahlenwert.
- Gegenprobe: PointerDown, PointerUp und zusätzlich vom Framework erzeugtes Click darf zusammen keine zweite Aktion erzeugen. Gleiches gilt für Hardware-KeyDown plus KeyUp. `M+` und eine Mehrfachanweisung machen eine Verdoppelung besonders sichtbar.
- Berührung vor dem Loslassen abbrechen oder aus dem Ziel bewegen; als Produktentscheidung soll eine abgebrochene Betätigung keine später eintreffende Rechenaktion erzeugen. Drag- und Cancel-Verhalten ist ausdrücklich zu spezifizieren und dann separat zu testen.
- Rechner fokussieren, Taste auslösen; Fokus auf einen App-Dialog bzw. ein anderes bearbeitbares Feld setzen, gleiche Hardwaretaste auslösen: keine unbeabsichtigte Rechneraktion. Fokus zurückholen, erneut drücken: genau eine Aktion. Fokusverlust bei gedrückter Taste darf keinen hängenden Modifier oder eine unendliche Wiederholung hinterlassen.
- Nach Öffnen/Schließen von MENU, SETUP, QR und Dialogen muss Hardwareeingabe wieder dem sichtbaren Kontext folgen. Ein Fokusring oder ein Screenreader-Fokus darf den rechnerinternen Cursor nicht stillschweigend ersetzen.
- Zwei schnelle, absichtliche Betätigungen müssen zwei Aktionen ergeben; Deduplizierung darf keine zweite echte Eingabe verschlucken. Langhalten und Betriebssystem-KeyRepeat sind eigene Fälle. Vor Festlegung der Wiederholungsregeln keine Originaltreue behaupten.
- Mehrere Finger und gemischte Touch-/Hardwareereignisse: Reihenfolge protokollieren, keine zufällige Doppelauslösung oder dauerhaft aktive SHIFT/ALPHA-Ebene. Gleichzeitig eintreffende Eingaben brauchen eine dokumentierte eigene Reihenfolgeregel; Originalverhalten bleibt bis zur Messung offen.

Die Prüfung erfolgt später getrennt im reinen Dart-Kern (semantische Aktionen/Zustände), in Flutter-Widgettests (Trefferflächen, Fokus, Ereignisweiterleitung) und in Plattform-/Gerätetests. Alle fünf vorgesehenen Plattformen erhalten nach Verfügbarkeit einen eigenen Nachweis. Ein Touchtest auf Windows ersetzt weder Android- noch iOS-Prüfung; ein synthetischer Widget-Tap ersetzt keine Prüfung an echter Hardware. Maus/Touch/Hardware werden pro Plattform als geprüft, offen oder tatsächlich nicht verfügbar ausgewiesen.

## Originalmessung und Abnahme

Sobald Originaldateien verfügbar und statisch geprüft sind, werden unbekannte Abläufe in geeigneter isolierter Umgebung beobachtet. Vor jeder Messreihe Modell, Emulatorversion, Dateihash, Modus, Setup und Eingangsspeicher notieren. Kurze Tastensequenzen mit Zustand/Anzeige nach jedem Schritt protokollieren; proprietäre Screenshots und Originalkomponenten bleiben im lokalen ignorierten Referenzbereich. In die eigenen versionierten Fälle gehören nur eigene Beschreibungen und Messwerte.

Bei Widerspruch zwischen Handbuch und Beobachtung beide Befunde behalten; die Softwareversion und eine mögliche Abweichung der Originalsoftware erfassen. Ein bisher unbekannter No-op wird erst nach reproduzierbarer Beobachtung als solcher beschrieben. Nichtbeobachtbare interne Speicherwirkungen bleiben offen. Jede neue Feststellung muss als Sollwert durch einen zweiten Durchlauf oder eine passende Gegenprobe abgesichert werden, bevor sie einen Regressionstest begründet.

Abnahme bedeutet später:

1. Alle 50 IDs sind im Inventar eindeutig und von den jeweiligen Eingabeadaptern adressierbar; keine der zehn Ziffern und keine Pfeilrichtung fehlt.
2. Jede bestätigte Primär-, SHIFT-, ALPHA- und Modusbelegung besitzt mindestens einen aussagekräftigen Funktionsfall und einen Zustands-/Nebenwirkungsfall. Bloßes Anklicken oder Sichtbarkeit zählt nicht als funktionale Abdeckung.
3. Alle Zeilen durchlaufen die sieben Pflichtfamilien; die sechs Grundkontexte sowie zusätzlichen CSV-Kontexte sind bewertet. Unbekannte Originalfälle bleiben sichtbar offen und werden nicht als bestanden oder unbegründet nicht anwendbar gezählt.
4. SHIFT-/ALPHA-Einmaligkeit, Moduswechsel, Fehlerkorrektur, Speicherpersistenz und destruktive Aktionen wurden mit unterscheidbaren Vorher-/Nachherwerten geprüft.
5. Pro unterstützter Plattform/Eingabekanal liegen getrennte Fokus- und Doppelauslösungsnachweise vor. Noch nicht verfügbare Plattformen sind eine verbleibende Einschränkung.
6. Sollwertprüfung am Handbuch, eigener Implementierungstest und Originalvergleich sind getrennt nachvollziehbar. Numerische Tests, Anzeige-/Cursorprüfungen und Ereignistests ergänzen sich; kein einzelner grüner Rechentest beweist eine ganze Taste.

Bis dahin bleibt die CSV vollständig `planned`. Der nächste technische Schritt ist ein kleiner zustandsbasierter Testadapter für stabile `key_id`-Aktionen, der zunächst SHIFT/ALPHA, Ziffern, Pfeile, DEL/AC und `=` sowie Vorher-/Nachher-Snapshots prüfbar macht. Dieser Adapter wurde mit dem vorliegenden Plan noch nicht implementiert.
