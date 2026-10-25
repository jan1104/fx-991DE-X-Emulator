# Funktionsumfang des fx-991DE X

Stand: 25.10.2026. Grundlage: `reference/originals/fx-87_991DEX_DE.pdf`, Bedienungsanleitung RJA532713-001V01. **Alle Seitenangaben nennen die physische PDF-Seite (1-basiert); die gedruckte Seitenzahl ist ab PDF-Seite 2 jeweils um eins kleiner.** Die Anleitung beschreibt zwei Modelle. Ziel dieses Projekts ist ausschließlich der fx-991DE X.

## Aussagekraft und Entwicklungsstatus

Die nachstehenden Eigenschaften sind durch die Anleitung belegt. Sie beschreiben den Hardware-Rechner; ein gleiches Verhalten der alten PC-Emulatorsoftware ist noch nicht nachgewiesen. Original-Programmdateien wurden hierfür nicht analysiert. Die Textauswertung kann grafische Formeln und Tastensymbole verlieren; unklare Anzeige- und Tastenfeinheiten müssen anhand gerenderter Seiten und später am Referenzprogramm bestätigt werden.

Es ist noch keine Rechnerfunktion implementiert oder am Nachbau getestet. Die Prioritäten P0/P1/P2 unten sind unsere Entwicklungsentscheidung, keine Aussage von Casio und kein Ausschluss aus dem langfristigen Ziel.

## Modusmatrix und Modellabgrenzung

Die Anleitung nennt 13 Modi für den fx-991DE X. Sieben sind für beide Modelle beschrieben; sechs weitere ausdrücklich nur für den fx-991DE X (PDF S. 6-7).

| Modus | Gemeinsame Funktion beider Modelle | Zusatz nur fx-991DE X | Priorität |
|---|---|---|---|
| Berechnungen | Allgemeine Ausdrücke, Brüche, Funktionen, CALC | Numerische Integration, numerische Ableitung, SOLVE | P0 Grundrechnen, P1 Erweiterungen |
| Komplexe Zahlen | - | Komplexe Arithmetik und Koordinatenformen | P1 |
| Basis-N | Binär, oktal, dezimal, hexadezimal und Logik | - | P1 |
| Matrizen | - | Matrixeditor und Matrixoperationen | P2 |
| Vektorrechnung | - | Vektoreditor und Vektoroperationen | P2 |
| Statistik | Einzelvariable, Regressionen, Häufigkeiten | Normalverteilungsfunktionen P/Q/R und Standardisierung im Statistik-Modus | P1 |
| Verteilungsfkt. | Sieben Verteilungsberechnungen | - | P1 |
| Tabellenkalk. | Zellraster, Formeln, Referenzen und Neuberechnung | - | P2 |
| Tabellen | Wertetabelle für eine oder zwei Funktionen | - | P1 |
| Gleichung/Funkt | - | Lineare Systeme und Polynome | P1 |
| Ungleichungen | - | Polynome vom Grad 2 bis 4 | P2 |
| Berechn prüf | Gleichheiten und Ungleichheiten prüfen | - | P1 |
| Verhältnisse | - | Unbekannten eines Verhältnisses bestimmen | P2 |

Wichtig: Der eigenständige **Verteilungsfkt.-Modus gehört beiden Modellen**. Die Einschränkung auf den fx-991DE X auf PDF S. 29 betrifft die zusätzlichen Normalverteilungsfunktionen innerhalb des Statistik-Modus. Auch Summe und Produkt sind für beide Modelle dokumentiert; ihre Tasten unterscheiden sich (PDF S. 20-21).

## P0: Eingabe, Darstellung und Zustände

| Bereich | Nachzubildendes Verhalten | Beleg |
|---|---|---|
| Ausdruckseingabe | Operatorrangfolge, Klammern, negative Vorzeichen, implizite Multiplikation, Vorlagen für Brüche/Potenzen/Wurzeln, Cursorbewegung und nachträgliches Bearbeiten | PDF S. 10-12 |
| Operatorrangfolge | Potenzen vor negativem Vorzeichen; implizite Multiplikation vor gewöhnlicher Multiplikation/Division. Kein ungeprüftes Übernehmen der Rangfolge einer Programmiersprache | PDF S. 10-11 |
| Eingabe/Ausgabe | Math→Math, Math→Dezim., Lin.→Linear, Lin.→Dezim.; exakte Darstellung als Bruch, Wurzel oder π soweit unterstützt, sonst Dezimalwert | PDF S. 7-9, 12-13 |
| Anzeigeformate | Fix 0-9 Nachkommastellen, Sci-Auswahl 0-9, Norm 1/2; unechter/gemischter Bruch, periodische Darstellung, Tausendertrennung, technische Notation und Dezimalpräfixe | PDF S. 8-9, 12-16 |
| Winkel | Gradmaß (Vorgabe), Bogenmaß, Gon; explizite Winkelkennzeichnung und Umrechnung | PDF S. 8, 19, 21 |
| Verlauf | Frühere Ausdrücke/Ergebnisse durchblättern und zur Bearbeitung zurückholen; Verlauf wird u. a. bei ON, Moduswechsel und Wechsel des Ein-/Ausgabeformats gelöscht | PDF S. 17 |
| Speicher | Ans sowie A, B, C, D, E, F, M, x, y; Zuweisung, Abruf, M+/M−. M ist zugleich eine normale Variable | PDF S. 17-18 |
| Persistenz | Ans, M und Variablen bleiben bei AC, Moduswechsel und Ausschalten erhalten; von Verlauf und modusspezifischen Daten getrennt behandeln | PDF S. 18 |
| Mehrfachanweisungen | Mit Doppelpunkt getrennte Rechnungen nacheinander auswerten; im linearen Format nächste Zeile | PDF S. 14 |
| Fehler und Abbruch | Laufende Berechnung mit AC abbrechen; bei Fehlermeldung mit Pfeiltaste zur Fehlerstelle, mit AC Ausdruck löschen | PDF S. 18, 47-49 |

### Elementare und wissenschaftliche Funktionen

- Grundrechenarten, gekürzte Brüche, Prozent, Grad/Minuten/Sekunden, Division mit Rest und Primfaktorzerlegung (PDF S. 13-15).
- Direkte und inverse Kreis- sowie Hyperbelfunktionen; Potenzen, Quadrat-/Kubik-/allgemeine Wurzeln, Kehrwert; Exponential- und Logarithmusfunktionen einschließlich freier Basis (PDF S. 18-19).
- Betrag, Fakultät, Permutationen und Kombinationen; Pol/Rec-Koordinatenumwandlung mit Nebenwirkung auf x/y (PDF S. 21).
- Bereichssumme und Bereichsprodukt; Zufallszahl Ran# sowie ganzzahlige RanInt#; Rnd, RndFix, GCD, LCM, Int und Intg (PDF S. 20-22).
- Technische Exponenten und elf Präfixe: m, μ, n, p, f, k, M, G, T, P, E (PDF S. 14).
- 47 wissenschaftliche Konstanten und Einheitenumwandlungen. Für historische Kompatibilität die in dieser Anleitung genannten CODATA-2010-Werte und Umwandlungsgrundlagen NIST SP 811 (2008) verwenden, nicht ungeprüft heutige Werte einsetzen (PDF S. 46-47).

### Zahlen- und Darstellungsgrenzen

| Eigenschaft | Dokumentierter Wert | Beleg |
|---|---|---|
| Rechenbereich | 0 oder Beträge von 10^-99 bis 9,999999999 × 10^99 | PDF S. 50 |
| Interne Rechnung | 15 Stellen; üblicher Genauigkeitsanspruch ±1 an der 10. Stelle für eine einzelne Rechnung, Fehler können sich akkumulieren | PDF S. 50 |
| Norm 1 | Exponentialanzeige für 0 < Betrag < 10^-2 oder Betrag ≥ 10^10 | PDF S. 8 |
| Norm 2 | Exponentialanzeige für 0 < Betrag < 10^-9 oder Betrag ≥ 10^10 | PDF S. 8 |
| Primfaktorzerlegung | Positive ganze Zahl mit höchstens 10 Ziffern; nicht vollständig zerlegbare Faktoren können geklammert bleiben. Einschränkungen u. a. Primfaktor ≥ 1018081 oder mindestens zwei Primfaktoren mit mehr als drei Ziffern | PDF S. 15 |
| Fakultät | Ganze Eingaben von 0 bis 69 | PDF S. 51 |
| Gemischte Bruchdarstellung | Ganzzahl, Zähler, Nenner und Trennzeichen zusammen höchstens 10 Stellen | PDF S. 13, 51 |
| π-Ergebnisdarstellung | Grundsätzlich Betrag < 10^6, mit dokumentierten Einschränkungen durch interne Fehler | PDF S. 52 |

Dies ist keine vollständige Tabelle aller Funktionsdomänen. PDF S. 50-52 ist vor der Implementierung der jeweiligen Funktion zusätzlich zu prüfen. 15 interne Stellen allein spezifizieren weder Rundungsmodus noch das vollständige Rechenformat; bitgenaue Übereinstimmung ist damit nicht bewiesen.

## P1: Erweiterte Rechenfunktionen und Modi

### Numerik und Variablenauswertung

- **CALC:** Ausdruck einmal eingeben und Variablenwerte abfragen, einschließlich Mehrfachanweisungen; im allgemeinen Modus und beim fx-991DE X zusätzlich im komplexen Modus (PDF S. 24).
- **SOLVE, nur fx-991DE X:** Newton-Verfahren im allgemeinen Modus, Anfangswert und Lösungsvariable, Anzeige des Residuums linke minus rechte Seite; liefert ggf. nur eine Lösung und kann trotz vorhandener Lösung scheitern. Fortsetzen oder Abbrechen nach begrenztem Suchlauf gehört zum Ablauf (PDF S. 25-26).
- **Integral/Ableitung, nur fx-991DE X:** Gauß-Kronrod-Integration und zentrale Differenzenapproximation. Vorgabetoleranzen 10^-5 bzw. 10^-10; Anleitung empfiehlt tol ≥ 10^-14. Trigonometrische Integranden mit Bogenmaß auswerten; Abbruch/Fehler bei schwierigen Funktionen dokumentieren (PDF S. 19-20, 49).

### Komplexe Zahlen

Kartesische und polare Eingabe/Ausgabe; arithmetische Operationen, ganzzahlige Potenzen, Konjugation, Betrag, Argument, Real-/Imaginärteil und explizite Formatkonvertierung. Ergebniswinkel: −180° < θ ≤ 180°. Zahlenform und Winkelmodus sind getrennte Einstellungen (PDF S. 23-24).

### Basis-N

32-Bit-Berechnungen mit DEC/HEX/BIN/OCT, gemischten Basisspezifikatoren, Basisumwandlung und and/or/xor/xnor/Not/Neg. Dezimaler Wertebereich −2147483648 bis 2147483647; negative Binär-/Oktal-/Hexwerte in Zweierkomplementdarstellung. Keine Bruch- und Exponenteneingaben; nichtganzzahlige Ergebnisteile werden abgeschnitten (PDF S. 29-30).

### Statistik und Verteilungen

Statistik: Einzelvariable sowie sieben Regressionstypen (linear, quadratisch, logarithmisch, exponentiell mit e, exponentiell mit freier Basis, Potenz, invers). Häufigkeitsspalte optional; Summen, Mittelwerte, Populations-/Stichprobenstreuung, Minima/Maxima, Quartile/Median, Regressionskoeffizienten und Schätzwerte. Datenkapazität: 160/80/53 Zeilen bei 1/2/3 Spalten (PDF S. 26-29).

Verteilungsmodus: Normaldichte, kumulative Normalverteilung, inverse kumulative Normalverteilung (linker Schwanz), Binomialdichte/-kumulation, Poissondichte/-kumulation. Diskrete Verteilungen mit Einzelwert oder Liste; bis zu 45 Listeneinträge. Die Anleitung beansprucht sechs signifikante Stellen Genauigkeit, obwohl Ergebnisse mehr Ziffern anzeigen können (PDF S. 39-42).

### Gleichungen, Tabellen und Nachprüfung

- Lineare Gleichungssysteme mit 2, 3 oder 4 Unbekannten; Polynome der Grade 2, 3 oder 4; schaltbare komplexe Lösungen. Bei quadratischen Polynomen zusätzlich Extrempunktkoordinaten. Wechsel des Gleichungstyps setzt Koeffizienten auf null (PDF S. 31-32).
- Wertetabelle f(x) oder f(x),g(x), mit Start/Ende/Schrittweite, bearbeitbaren x-Zellen und fortsetzbaren Zeilen. Höchstens 45 Zeilen für f(x), 30 für f(x),g(x). Erstellung verändert Variable x; Änderung der Ein-/Ausgabeeinstellung löscht die Funktionsdefinitionen (PDF S. 34-35).
- Wahr/Falsch-Prüfung einfacher und verketteter Vergleiche; Ergebnis setzt Ans auf 1 bzw. 0. Unzulässige Vergleichsketten lösen Syntaxfehler aus; keine Zusage einer allgemeinen symbolischen Beweisführung (PDF S. 38-39).

## P2: Weitere Zielmodule

| Modul | Umfang und wesentliche Zustände | Beleg |
|---|---|---|
| Matrizen | MatA-D, MatAns, 1-4 Zeilen und Spalten; Addition, Multiplikation, Determinante, Transponieren, Einheitsmatrix, Inverse, Quadrat/Kubik, elementweiser Betrag, REF/RREF | PDF S. 32-34 |
| Vektoren | VctA-D, VctAns; 2D/3D; Addition, Skalar-/Kreuzprodukt, Betrag, Winkel, Einheitsvektor | PDF S. 35-37 |
| Ungleichungen | Polynome Grad 2/3/4 mit >, <, ≥, ≤; Intervalle sowie keine Lösung/alle reellen Zahlen; Koeffizienteneditor | PDF S. 37-38 |
| Verhältnisse | A/B = X/D oder A/B = C/X; null als Koeffizient führt zu mathematischem Fehler, AC setzt Koeffizienten auf eins | PDF S. 38 |
| Tabellenkalkulation | A1:E45 (45×5), Konstanten und Formeln, relative/absolute Referenzen, Kopieren/Füllen, Bereichsfunktionen, automatische/manuelle Neuberechnung | PDF S. 42-46 |
| Tabellenkalkulationsgrenzen | 1700 Bytes Gesamtkapazität; Konstanten bis 10 Bytes, Formelinhalt bis 49 Bytes plus 11 Bytes Zellaufwand; Datenverlust bei Verlassen des Modus, Ausschalten oder ON | PDF S. 42, 49 |
| QR-Funktion | QR-Version 3 oder 11, Erzeugung aus unterstützten Ansichten; Datenmenge kann mehrere Codes erfordern. Öffnen des alten Casio-Webdiensts ist eine externe Abhängigkeit, deren heutige Verfügbarkeit hier nicht geprüft wurde | PDF S. 9, 22-23 |

## Offene Abgrenzungen

1. Die Anleitung belegt das Rechnerverhalten, aber keine Programmiersprache, PC-Abhängigkeit, Firmwarestruktur oder Emulatorarchitektur.
2. Screenshotaufnahme, PC-Tastaturbelegung, Fenstergrößen, Sitzungsdateien und weitere Desktopfunktionen der alten Emulatorsoftware bleiben bis zur Programmanalyse unbekannt.
3. Genaue Token-/Bytekodierung, numerischer Datentyp, Rundungsmodus, Vergleichstoleranzen, RNG und QR-Nutzdatenformat sind noch zu ermitteln. Keine Übereinstimmung behaupten, bevor Referenzmessungen vorliegen.
4. Hardwaremerkmale wie Solarversorgung und Batteriewechsel werden dokumentiert, benötigen für einen funktionalen Software-Nachbau aber zunächst keine physikalische Simulation.
5. Priorisiert wird zunächst ein überprüfbarer allgemeiner Rechenmodus mit korrektem Editor, Speicher, Anzeige und Fehlerverhalten; danach folgen die P1- und P2-Module.

Konkrete Referenzfälle und ihr Ausführungsstatus stehen in [REFERENZTESTS.md](REFERENZTESTS.md).
