# Tasten und Bedienung des fx-991DE X

Stand: 25.10.2026. Spezifikation aus den bereitgestellten Anleitungen; noch keine Implementierung und noch kein am Originalemulator gemessener Befund.

## Quellen und Belegkonvention

- **H**: `reference/originals/fx-87_991DEX_DE.pdf`, gemeinsame Bedienungsanleitung fx-87DE X/fx-991DE X. Maßgebliche Quelle; ausschließlich die Belegung des fx-991DE X übernehmen.
- **K**: `reference/originals/Kurzanleitung_FX-991DE X.pdf`, ergänzende Bedienbeispiele.
- **A**: `reference/originals/FX-991DE X Bedienung und Aufgabenbeispiele.pdf`, ergänzende Unterrichtsbeispiele.

Alle Seitenangaben sind **PDF-Seiten ab 1**. Bei H liegt die gedruckte Seitenzahl in diesen Abschnitten um eins darunter. Tasten werden mit lesbaren Namen statt mit den unzuverlässig extrahierten Symbolfont-Zeichen bezeichnet. `SHIFT → MENU` bedeutet nacheinander drücken, nicht gleichzeitig. Die Bezeichnung `=` meint die Ausführen-/Bestätigen-Taste, `ALPHA → CALC` dagegen das Eingabezeichen `=`.

## Grundprinzip und Anzeige

SHIFT aktiviert die gelbe Zweitbelegung, ALPHA die rote Drittbelegung. Beide sind einmalige Umschaltungen: Der jeweilige Anzeigeindikator verschwindet nach der nächsten Taste. Violette Beschriftungen gehören zum Modus Komplexe Zahlen, blaue Beschriftungen zum Modus Basis-N; sie sind keine weiteren allgemeinen SHIFT-Ebenen. [H, PDF-S. 4–5]

Die Anzeige trennt Ausdruck, Ergebnis und Statusindikatoren. Sichtbare Zustände sind unter anderem SHIFT, ALPHA, Winkeleinheit D/R/G, FIX, SCI, Speicher M ungleich null, Bereitschaft zur Variablenzuweisung nach STO und natürliche Eingabe. Hinzu kommen Fortsetzungs-, Verlauf- und Zwischenresultatindikatoren. Seitlich abgeschnittene Ausdrücke und Ergebnisse werden mit Links/Rechts verschoben; zur Ausdrucksverschiebung kann nach der Ergebnisanzeige zuerst AC nötig sein. [H, PDF-S. 5]

## Zentrale Bedientasten

| Taste/Folge | Bedeutung und Kontext | Beleg |
|---|---|---|
| ON | Einschalten; löscht den Berechnungsverlauf. Kein allgemeines Speicherlöschen. | H 4, 17–18 |
| SHIFT → AC (OFF) | Ausschalten. Ans, Variablen und M bleiben erhalten; einzelne Modusdaten haben eigene Löschregeln. | H 4, 18, 42 |
| MENU | Hauptmenü der Rechenmodi öffnen. | H 6–7; K 2 |
| SHIFT → MENU (SETUP) | Geräteeinstellungen öffnen. | H 8–9 |
| OPTN | Kontextmenü des gegenwärtigen Modus bzw. Editors öffnen. Die Einträge und Nummern ändern sich mit dem Kontext. | H 6, 18–19, 26–28, 43 |
| SHIFT → OPTN (QR) | QR-Anzeige des aktuellen unterstützten Bildschirms erzeugen. | H 22–23 |
| SHIFT / ALPHA | Einmalige Zweit-/Drittbelegung aktivieren. | H 4–5 |
| Pfeile Links/Rechts | Cursor bewegen; Ausdruck aus Ergebnisanzeige zur Bearbeitung zurückholen; horizontale Anzeige verschieben. Links führt im Untermenü eine Ebene zurück. | H 5–6, 17 |
| Pfeile Auf/Ab | Menüs scrollen, Auswahl bewegen oder Berechnungsverlauf durchlaufen; Bedeutung richtet sich nach dem Bildschirm. | H 6, 17 |
| `=` | Ausdruck ausführen, Menüauswahl bzw. Editorwert bestätigen, nächste Mehrfachanweisung ausführen. | H 7, 10, 14 |
| SHIFT → `=` (≈) | Die Berechnung direkt mit dezimalem Ergebnis ausführen. | H 9, 13 |
| DEL | Bei gewöhnlicher Ausdruckseingabe Zeichen links vom Cursor löschen; in bestimmten Tabelleneditoren dagegen ganze Zeile löschen. | K 4; H 27 |
| SHIFT → DEL (INS) | Bei linearer Eingabe zwischen Einfügen und Überschreiben wechseln; bei natürlicher Eingabe bestehenden Ausdruck als Argument einer anschließend eingefügten Funktion übernehmen. | H 12 |
| ALPHA → DEL (UNDO) | In natürlicher Eingabe letzte Tastenoperation rückgängig machen; erneute Ausführung stellt sie wieder her. | H 12 |
| AC | Menü ohne Auswahl schließen; laufende Berechnung abbrechen; CALC/SOLVE beenden. Bei Fehleranzeige Meldung und fehlerhaften Ausdruck löschen. In Editoren gelten eigene Rückkehrregeln. | H 6, 18, 24–25, 47 |
| STO → Variablentaste | Wert zuweisen; dafür kein zusätzliches ALPHA drücken. | H 17–18 |
| SHIFT → STO (RECALL) | Variablenübersicht öffnen, Variable auswählen und mit `=` abrufen; AC schließt ohne Abruf. Übersicht zeigt Werte in Norm 1. | H 17–18 |
| ALPHA → Variablentaste | Variable als Bestandteil eines Ausdrucks eingeben. | H 17–18 |
| Ans | Letztes Rechenergebnis in den Ausdruck einsetzen. Nach einer Rechnung kann ein Operator direkt mit Ans weiterrechnen. | H 17 |
| M+ / SHIFT → M+ (M−) | Ergebnis zum unabhängigen Speicher M addieren bzw. davon abziehen; angezeigtes Ergebnis ist der gerade berechnete Summand, nicht zwingend der neue M-Inhalt. | H 18 |
| S⇔D | Ergebnisdarstellung umschalten, soweit für den Wert zulässig; mit aktivierter Periodendarstellung gegebenenfalls Zyklus Bruch/Periode/Dezimal. | H 12–13, 16 |
| SHIFT → S⇔D | Zwischen unechtem und gemischtem Bruch umschalten. | H 13 |
| ENG / SHIFT → ENG | Technische Notation in Schritten von drei Exponentenstellen verschieben, mit SHIFT in Gegenrichtung; bei aktivierten Dezimalpräfixen entsprechende Präfixdarstellung. | H 14 |
| CALC | Variablenwerte eines Ausdrucks abfragen und auswerten, in Berechnungen und Komplexe Zahlen. | H 24 |
| SHIFT → CALC (SOLVE) | Numerischen Gleichungslöser im Modus Berechnungen starten. | H 25 |
| ALPHA → CALC (`=`) | Gleichheitszeichen als Ausdrucksbestandteil eingeben, beispielsweise für SOLVE. | H 25 |
| SHIFT → 9 (RESET) | Resetmenü: Setupdaten, Speicher oder Alle initialis.; danach mit `=` bestätigen. | H 3, 10, 18; K 5 |

**Wichtig für die Implementierung:** AC, DEL, `=`, Pfeile und OPTN sind keine globalen Aktionen mit nur einer Bedeutung. Sie müssen vom aktiven Bildschirm, Editor und Eingabezustand ausgewertet werden.

## Mathematische Eingabetasten und belegte Zusatzbelegungen

Die folgende Tabelle beschreibt belegte Funktionen. Die räumliche Zuordnung und farbigen Aufdrucke wurden zusätzlich am Titelbild von K, PDF-S. 1, visuell geprüft. Fehlende Einträge in dieser Funktionstabelle sind keine Aussage, dass die Taste keine Zusatzbelegung besitzt.

| Taste oder Funktionsfamilie | Primär-/Zusatzverhalten | Beleg |
|---|---|---|
| Ziffern 0–9 und Dezimalkomma | Zahlen eingeben; Ziffern wählen außerdem nummerierte Menüpunkte. | H 6, 10, 15 |
| `+`, `−`, `×`, `÷` | Binäre Rechenoperatoren. Negatives Vorzeichen ist eine eigene Taste `(-)` mit anderer Bindungsstärke als Potenzen. | H 10–11 |
| `(-)` | Negatives Vorzeichen; über ALPHA Variable A, über SHIFT allgemeine log-Eingabe. | H 11, 17, 19 |
| Klammern `(` und `)` | Gruppierung/Funktionsargumente; SHIFT → `(` liefert Abs, SHIFT → `)` den Argumenttrenner `;`, ALPHA → `)` die Variable x. | H 11, 18–19, 21 |
| Bruchvorlage | Bruch eingeben; SHIFT: gemischter Bruch; ALPHA: Division mit Rest (÷R). | H 11, 13, 15 |
| Quadratwurzel | Wurzelvorlage; SHIFT: Kubikwurzel; ALPHA: Periodenstrich zur Eingabe periodischer Dezimalzahlen. | H 15, 19; K 1 |
| x² | Quadrieren; SHIFT: x³. Im Basis-N-Modus ist dieselbe physische Taste DEC. | H 19, 29 |
| Potenztaste | Allgemeine Potenz; SHIFT: allgemeine Wurzel. Im Basis-N-Modus dieselbe physische Taste HEX. | H 19, 29 |
| Logarithmus mit Basisvorlage | Logarithmus mit expliziter Basis bei natürlicher Eingabe; SHIFT: Zehnerpotenz 10ˣ. Im Basis-N-Modus dieselbe physische Taste BIN. | H 19, 29; K 1 |
| ln | Natürlicher Logarithmus; SHIFT: Exponentialfunktion zur Basis e. Im Basis-N-Modus dieselbe physische Taste OCT. | H 19, 29 |
| Integral | Bestimmtes numerisches Integral; SHIFT: numerische Ableitung; ALPHA: Doppelpunkt für Mehrfachanweisungen. | H 14, 19–20 |
| x | Direkte Variable x; SHIFT: Summe Σ; ALPHA: Produkt Π beim fx-991DE X. | H 18, 20–21 |
| x⁻¹ | Kehrwert; SHIFT: Fakultät x!; ALPHA: Variable C. | H 19, 21, 29 |
| sin, cos, tan | Trigonometrische Funktionen; SHIFT: jeweilige Umkehrfunktion sin⁻¹, cos⁻¹, tan⁻¹. Die Winkeleinheit ist Teil des Zustands. Die jeweiligen ALPHA-Belegungen sind D, E, F. | H 18, 29; K 1 |
| °′″ | Sexagesimale Eingabe und Umwandlung eines Ergebnisses; SHIFT: Primfaktorzerlegung FACT; ALPHA: Variable B. | H 13–15, 17 |
| `×10ˣ` | Wissenschaftliche Zahleneingabe; SHIFT: π; ALPHA: e. | H 12, 18, 20 |
| `+` Zusatzbelegungen | SHIFT: Pol (kartesisch → polar); ALPHA: Int (Ganzzahlanteil gegen null). | H 21–22 |
| `−` Zusatzbelegungen | SHIFT: Rec (polar → kartesisch); ALPHA: Intg (Abrunden zur nächsten ganzen Zahl). | H 21–22 |
| `×` Zusatzbelegungen | SHIFT: nPr; ALPHA: GCD. | H 21–22 |
| `÷` Zusatzbelegungen | SHIFT: nCr; ALPHA: LCM. | H 21–22 |
| `0` Zusatzbelegungen | SHIFT: Rnd nach aktuellem Zahlenformat; ALPHA: RndFix mit vorgegebener Nachkommastellenzahl. | H 22 |
| Dezimalkomma Zusatzbelegungen | SHIFT: Ran#; ALPHA: RanInt#. | H 21 |
| Ans Zusatzbelegung | SHIFT: Prozentoperator %. | H 13 |
| `7`, `8` Zusatzbelegungen | SHIFT → 7: Konstantenmenü CONST; SHIFT → 8: Einheitenumrechnung CONV. | K 3; H 46–47 |

Hyperbolische Funktionen sind über OPTN erreichbar, nicht durch einen eigenen allgemeinen Hyp-Taster: im Modus Berechnungen OPTN → Hyperbol. Fkt.; für weitere Kontexte können vorherige Menübewegungen nötig sein. OPTN enthält außerdem Winkeleinheiten und Dezimalpräfixe. [H, PDF-S. 18–19; K, PDF-S. 3]

Im Basis-N-Modus sind A–F direkte Hexadezimalziffern über die Tasten `(-)`, `°′″`, `x⁻¹`, `sin`, `cos`, `tan`; dort nicht erst die allgemeine ALPHA-Variableneingabe anwenden. Die Basisumschalter DEC/HEX/BIN/OCT ändern auch ein bereits vorliegendes Ergebnis. [H, PDF-S. 29–30]

## Physische Tastaturmatrix

Visuelle Referenz: K, PDF-S. 1. Reihen von oben nach unten, innerhalb einer Reihe von links nach rechts. Der Vierwege-Cursorblock liegt zwischen ALPHA und MENU und reicht zwischen die oberen beiden Reihen. `–` bedeutet **kein entsprechender Aufdruck erkennbar**, nicht automatisch „Ereignis immer wirkungslos“. Die tatsächliche Wirkung jeder Belegung hängt weiterhin von Modus und Zustand ab.

| Reihe | Primärtaste(n) | SHIFT, gelber Aufdruck | ALPHA, roter Aufdruck | Modusaufdruck |
|---|---|---|---|---|
| Kopf | SHIFT; ALPHA; MENU; ON | MENU: SETUP | – | – |
| Cursorblock | Links; Auf; Ab; Rechts | – | – | – |
| 1 | OPTN | QR | – | – |
| 1 | CALC | SOLVE | `=` | – |
| 1 | Integral | d/dx | `:` | – |
| 1 | x | Σ | Π | – |
| 2 | Bruch | Gemischter Bruch | ÷R | – |
| 2 | √ | ∛ | Periodenstrich | – |
| 2 | x² | x³ | – | DEC, blau |
| 2 | x hoch beliebig | Allgemeine Wurzel | – | HEX, blau |
| 2 | Logarithmus mit Basis | 10ˣ | – | BIN, blau |
| 2 | ln | eˣ | – | OCT, blau |
| 3 | `(-)` | log | A | A, blau |
| 3 | °′″ | FACT | B | B, blau |
| 3 | x⁻¹ | x! | C | C, blau |
| 3 | sin | sin⁻¹ | D | D, blau |
| 3 | cos | cos⁻¹ | E | E, blau |
| 3 | tan | tan⁻¹ | F | F, blau |
| 4 | STO | RECALL | – | – |
| 4 | ENG | Linkspfeil, Gegenrichtung | – | i direkt, ∠ mit SHIFT; violett |
| 4 | `(` | Abs | – | – |
| 4 | `)` | `;` | x | – |
| 4 | S⇔D | Gemischter/unechter Bruch | y | – |
| 4 | M+ | M− | M | – |
| 5 | 7 | CONST | – | – |
| 5 | 8 | CONV | – | – |
| 5 | 9 | RESET | – | – |
| 5 | DEL | INS | UNDO | – |
| 5 | AC | OFF | – | – |
| 6 | 4; 5; 6 | – | – | – |
| 6 | × | nPr | GCD | – |
| 6 | ÷ | nCr | LCM | – |
| 7 | 1; 2; 3 | – | – | – |
| 7 | + | Pol | Int | – |
| 7 | − | Rec | Intg | – |
| 8 | 0 | Rnd | RndFix | – |
| 8 | Komma | Ran# | RanInt | – |
| 8 | ×10ˣ | π | e | – |
| 8 | Ans | % | – | – |
| 8 | `=` | ≈ | – | – |

Die ENG-Sonderbelegung ist zusätzlich im Text von H, PDF-S. 23 bestätigt: Im Modus Komplexe Zahlen gibt ENG direkt `i` ein, SHIFT → ENG das Winkelsymbol `∠`. Außerhalb dieses Modus ist ENG für technische Notation zuständig. Die blauen A–F bezeichnen Hexadezimalziffern, die roten A–F gespeicherte Variablen. Das sind unterschiedliche Eingabekontexte auf denselben physischen Tasten.

## Hauptmenü des fx-991DE X

MENU öffnet die Modusauswahl; mit Pfeilen markieren und `=` bestätigen. Die Kurzanleitung nennt folgende Kennungen. Das gemeinsame Handbuch belegt dieselben 13 Modusnamen, aber keine pauschale Annahme über Buchstabentasten: A–D sind hier Menükennungen und nicht die Behauptung einer bestimmten PC-Tastenkombination. [H, PDF-S. 6–7; K, PDF-S. 2]

| Kennung | Modus |
|---|---|
| 1 | Berechnungen |
| 2 | Komplexe Zahlen |
| 3 | Basis-N |
| 4 | Matrizen |
| 5 | Vektorrechnung |
| 6 | Statistik |
| 7 | Verteilungsfkt. |
| 8 | Tabellenkalk. |
| 9 | Tabellen |
| A | Gleichung/Funkt |
| B | Ungleichungen |
| C | Berechn prüf |
| D | Verhältnisse |

In Listenmenüs wählt die angezeigte Ziffer den Eintrag. Auf/Ab scrollt über den sichtbaren Ausschnitt hinaus; Links führt vom Untermenü zum übergeordneten Menü, AC schließt ohne Wahl. Menünummern nicht unabhängig vom Modus oder von der aktuellen Menüseite fest verdrahten. [H, PDF-S. 6]

## Setup und Vorgaben

Aufruf: SHIFT → MENU. Auf/Ab zur jeweiligen Seite, dann die angezeigte Nummer. Konkrete Scrollfolgen des fx-87DE X dürfen nicht für den fx-991DE X übernommen werden. [H, PDF-S. 8–10]

| Einstellung | Optionen; Vorgabe hervorgehoben | Beleg H, PDF-S. |
|---|---|---|
| Eingabe/Ausgabe | **Math → Math**, Math → Dezim., Lin. → Linear, Lin. → Dezim. | 7–8 |
| Winkeleinheit | **Gradmaß D**, Bogenmaß R, Gon G | 8 |
| Zahlenformat | Fix 0–9 Nachkommastellen, Sci 0–9 als Auswahl, **Norm 1**, Norm 2 | 8 |
| Dezimalpräfixe | Ein, **Aus** | 9 |
| Bruchergebnis | ab/c, **d/c** | 9 |
| Komplexe Zahlen | **a+bi**, r∠θ | 9 |
| Statistik | Häufigkeitsspalte Ein, **Aus** | 9 |
| Tabellenkalk.: Autom. Berechn. | **Ein**, Aus | 9 |
| Tabellenkalk.: Zelle anzeigen | **Formel**, Wert | 9 |
| Gleichung/Funkt | Komplexe Lösungen **Ein**, Aus | 9 |
| Tabellen | f(x), **f(x),g(x)** | 9 |
| Period. Darst. | **Ein**, Aus | 9 |
| 1000er-Trennung | Ein, **Aus** | 9 |
| Mehrzeilengröße | **Normale Schrift** (bis vier Zeilen), Kleine Schrift (bis sechs Zeilen); für lineare Formate | 9 |
| QR Code | Version 3, **Version 11** | 9 |
| Automat Aus | **10 Min**, 60 Min | 9 |
| Kontrast | Mit Links/Rechts verstellen, AC beendet; kein numerischer Standardwert angegeben | 4 |

Norm 1 wechselt bei `0 < |x| < 10⁻²` und bei `|x| ≥ 10¹⁰` zur Exponentialdarstellung; Norm 2 bei `0 < |x| < 10⁻⁹` und bei `|x| ≥ 10¹⁰`. Null wird nicht aufgrund der Ungleichung als Exponentialfall behandelt. Die Anzeige-Rundung ist von einer tatsächlichen Rnd-Operation zu trennen. [H, PDF-S. 8, 22]

## Zustände und Löschregeln

Die Zustände in dieser Tabelle sind ein **Entwurf für die eigene Softwarestruktur**; die beschriebenen Übergänge sind durch die Anleitung belegt. Sie sind keine aus dem Originalprogramm rekonstruierte interne Architektur.

| Zustand/Daten | Belegte Übergänge oder Persistenz | Beleg H, PDF-S. |
|---|---|---|
| Ausdruck bearbeiten | Natürliche Vorlagen haben mehrere Eingabefelder; Rechts wechselt weiter. SHIFT+Rechts/Links springt bei bestimmten Vorlagen hinter/vor die ganze Vorlage. `=` führt aus. | 10–12 |
| Ergebnis anzeigen | S⇔D ändert die Darstellung, Links/Rechts holt den Ausdruck zum Editieren zurück, Operator setzt mit Ans fort. | 12–13, 17 |
| Verlauf | Auf/Ab durchsucht frühere Rechnungen. Löschen durch ON, Moduswechsel, Änderung Eingabe/Ausgabe, Reset Setupdaten oder Alle initialis. | 17 |
| Ans, A–F, M, x, y | Bleiben bei AC, Moduswechsel und Ausschalten erhalten. Mit RESET → Speicher löschbar. M ist zugleich der unabhängige Speicher und die Variable M. | 17–18 |
| Bereitschaft STO | Nächste passende Variablentaste bestimmt das Speicherziel; eigener Indikator. | 5, 17 |
| CALC-Dialog | Variablen werden abgefragt, mit `=` bestätigt; erneut CALC erlaubt neue Werte. AC beendet. Innerhalb des Dialogs lineare Eingabeverfahren verwenden. | 24; K 8 |
| SOLVE-Dialog | Anfangswerte/Parameter und Lösungsvariable wählen; `=` startet. Ergebnis zeigt Variable, Dezimallösung und L−R. Bei Fortfahren-Abfrage setzt `=` fort, AC bricht ab. | 25 |
| Statistik-Editor | AC wechselt zur statistischen Rechenanzeige, OPTN → Daten zurück. Modus verlassen, 1-/2-Variablenart wechseln oder Freq-Setup ändern löscht Dateneingaben. | 26–27 |
| Wertetabelle | x-Zelle ändern aktualisiert f/g in derselben Zeile; `+` bzw. `=` übernimmt vorheriges x plus Schritt, `−` vorheriges x minus Schritt. Eingabe/Ausgabe-Wechsel löscht definierte Funktionen. | 34–35 |
| Tabellenkalkulation | Alle Zellinhalte gehen bei Modus verlassen, Ausschalten oder ON verloren. Konstanten sind berechnete Werte ohne führendes `=`, Formeln beginnen mit `=`. | 42–43 |
| Fehleranzeige | Links/Rechts führt zum Ausdruck an die Fehlerstelle; AC entfernt Meldung und fehlerhaften Ausdruck. | 47 |
| QR-Anzeige | Unterstützte Bildschirme: Setup, Menü, Fehler, Ergebnis, Tabelle. Bei mehreren Codes mit Auf oder `=` vorblättern. | 22–23 |
| Ausschalten/Automat Aus | OFF oder Inaktivitätsdauer; ON schaltet wieder ein. Persistenz gemäß Datentyp, nicht pauschal alles speichern. | 4, 9, 18, 42 |

Resetvarianten: SHIFT → 9 → **1 Setupdaten** → `=` stellt Modus/Setup außer Kontrast zurück; SHIFT → 9 → **2 Speicher** → `=` löscht Antwort-, Variablen- und unabhängigen Speicher; SHIFT → 9 → **3 Alle initialis.** → `=` initialisiert umfassend ebenfalls ohne Kontrast. Eine reine Setupinitialisierung ist nicht mit vollständigem Speicherlöschen gleichzusetzen. [H, PDF-S. 3, 10, 17–18]

## Durchgängige Bedienabläufe als Referenz

1. **Exakt und dezimal:** Berechnungen, Setup Math → Math, `1 ÷ 7 =` ergibt `1/7`. S⇔D schaltet bei aktivierter Periodendarstellung auf Periode `142857`, danach auf gerundete Dezimalanzeige und zurück zum Bruch. SHIFT → `=` liefert direkt dezimal. [H, PDF-S. 13, 16]
2. **Ausdruck korrigieren:** `4 × 3 + 2 =` ergibt 14. Links/Rechts öffnet denselben Ausdruck zur Bearbeitung; `+ 2` durch `− 7` ersetzen und erneut `=` ergibt 5. Dies ist Bearbeiten des Ausdrucks, nicht bloß eine Rechenoperation auf 14. [H, PDF-S. 17]
3. **Variable:** `3 + 5`, STO, A-Taste speichert 8. ALPHA, A-Taste, `× 10 =` ergibt 80. SHIFT → STO zeigt die Übersicht; A auswählen, `=` ruft 8 ab. `0`, STO, A löscht den A-Wert. [H, PDF-S. 17–18]
4. **Unabhängiger Speicher:** M mit `0 STO M` auf null setzen; `10 × 5 M+`, dann `10 + 5 SHIFT M+` führt zu M = 35. Der zweite Vorgang zeigt 15, RECALL M danach 35. [H, PDF-S. 18]
5. **CALC:** Ausdruck `3A+B` eingeben; CALC; A = 5, B = 10 jeweils bestätigen, ausführen: 25. Erneutes CALC dient der Variation; AC beendet die Sitzung. [H, PDF-S. 24; K, PDF-S. 8]
6. **SOLVE:** Ausdruck `x²+B=0` eingeben (`=` im Ausdruck über ALPHA → CALC). SHIFT → CALC; x-Anfangswert 1, B = −2; x als Lösungsvariable markieren und ausführen. Ergebnis ist eine Näherung an √2; L−R ist ein Residuum und keine Garantie für alle Lösungen. Andere Anfangswerte können andere Lösungen ergeben. [H, PDF-S. 25]
7. **Wertetabelle:** Modus Tabellen; f(x) und gegebenenfalls g(x) eingeben; Start, Ende, Inkre bestätigen; Tabelle erzeugen. Eine x-Zelle editieren aktualisiert zugehörige Funktionswerte. AC kehrt zur Funktionseingabe zurück. [H, PDF-S. 34–35]
8. **Statistik:** Statistik wählen, 1 Variable oder Regressionstyp bestimmen, Werte mit `=` in den Editor eingeben. AC öffnet die Rechenanzeige, OPTN zeigt kontextgerechte Auswertungen. DEL löscht im Editor eine ganze Zeile. [H, PDF-S. 26–28]
9. **Gleichungssystem:** Gleichung/Funkt, Gleichungssysteme, 2–4 Unbekannte auswählen; Koeffizienten einzeln mit `=` bestätigen; Lösungen mit Pfeilen durchlaufen. Für diesen Modus keine SOLVE-Startwertlogik verwenden. [H, PDF-S. 31–32; K, PDF-S. 6]
10. **Zellenformel:** Tabellenkalkulation, Zelle wählen; `ALPHA → CALC` erzeugt führendes `=`, danach etwa `A1+7` eingeben und bestätigen. Für spätere Bearbeitung OPTN → Zelle bearbeit. nutzen; bloße Neueingabe und Bearbeitungsmodus sind unterschiedliche Aktionen. [H, PDF-S. 43]

## Offene Punkte und Quellenkonflikte

- Die physische Tastaturmatrix wurde am Titelbild von K geprüft. Ein späterer Abgleich mit dem tatsächlichen Gerät bzw. der Originalemulator-Oberfläche bleibt erforderlich. Textauszüge verlieren Tastensymbole, Positionen und Farben; vermeintliche Buchstaben wie `q`, `r`, `p` in K/A sind Fontkodierungen und keine PC-Tasten.
- Die K-Kurzanleitung zählt auf PDF-S. 4 acht Variablen ohne M. H nennt auf PDF-S. 17 ausdrücklich neun Variablen einschließlich M; dieser vollständige Satz ist maßgeblich.
- K, PDF-S. 9 bezeichnet die SHIFT-Belegung der Integraltaste im Fließtext missverständlich erneut als Integration. H, PDF-S. 19–20 unterscheidet eindeutig Integral direkt und Ableitung mit SHIFT.
- K, PDF-S. 4 gibt beim gemischten Bruch eine auffällige Symbolfolge an. Verbindlich ist H, PDF-S. 13: SHIFT → S⇔D.
- Pfeilrichtungen können in Symbolfont-Auszügen irreführend sein. Keine universelle Annahme „Auf ist historisch zurück“ aus der gedruckten Pfeilform ableiten; Tastenereignisse und tatsächliche Reihenfolge am Gerät/Originalemulator prüfen. H, PDF-S. 17 belegt das Blättern mit beiden vertikalen Pfeilen.
- Nicht geklärt: Tastenwiederholung, Zeitverhalten, gleichzeitige Tasten, exakte Cursorposition nach allen Sonderaktionen, Verhalten bei ungültigen SHIFT/ALPHA-Folgen sowie Desktop-Tastaturkürzel des alten Emulators.
- Die Anleitungen beschreiben den Taschenrechner. Fenstergröße, Skalierung, Bildschirmkopie, Tastendruckhistorie oder weitere Zusatzfunktionen einer PC-Emulatorsoftware können daraus nicht bestätigt werden.
- QR-Webdienste sind externe Abhängigkeiten. Die Dokumente belegen deren damalige Verwendung, nicht deren heutige Verfügbarkeit. Hier wurde keine aktuelle Netzfunktion geprüft.
