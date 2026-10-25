# Geplante Referenztests

Stand: 25.10.2026. Quelle für sämtliche Fälle: `reference/originals/fx-87_991DEX_DE.pdf` (RJA532713-001V01). Die Seitenangaben sind **physische PDF-Seiten, 1-basiert**, nicht die gedruckten Seitenzahlen. Zielmodell ist fx-991DE X.

**Status aller Fälle: geplant, nicht ausgeführt.** Es gibt noch keine getestete Implementierung und keine bestätigte Messung an der alten Emulatorsoftware. Die Eingaben sind lesbare mathematische Abläufe, noch keine vollständigen physischen Tastensequenzen. Bei späterer Automatisierung müssen Modus, Setup und Speicherzustand explizit gesetzt werden.

„Beispiel“ bedeutet: Erwartung steht im Anleitungstext. „Abgeleitet“ bedeutet: die Erwartung ergibt sich aus einer dort beschriebenen Regel; sie ist kein bereits beobachteter Screenshot. Numerische Toleranzen müssen pro Funktion festgelegt werden. Exakte Darstellungen sind zusätzlich strukturell zu prüfen; ein ungefähr richtiger Zahlenwert allein genügt nicht.

## P0: Kernrechnen, Darstellung und Speicher

| ID | Voraussetzungen und Aktion | Erwartung | Art / PDF-Seite |
|---|---|---|---|
| K01 | Gradmaß; `4×sin(30)×(30+10×3)` | 120 | Beispiel, S. 10 |
| K02 | Allgemeiner Modus; `(-2)^2` und `-2^2` | 4 bzw. −4; Vorzeichen ist kein Bestandteil der Potenzbasis ohne Klammern | Abgeleitet, S. 11 |
| K03 | Math→Math; `2/3 + 1 1/2` | Unechter Bruch 13/6; gekürzt | Beispiel, S. 13 |
| K04 | Allgemeiner Modus; `150×20%` | 30 | Beispiel, S. 13 |
| K05 | Allgemeiner Modus; `3500−3500×25%` | 2625 | Beispiel, S. 13 |
| K06 | `2°20′30″ + 0°9′30″`; danach DMS/Dezimal umschalten | 2°30′0″, dann 2,5, zurück zu 2°30′0″ | Beispiel, S. 13-14 |
| K07 | `3+3 : 3×3`; zweimal ausführen | Zuerst 6, danach 9; Zwischenzustand sichtbar | Beispiel, S. 14 |
| K08 | Präfixanzeige ein; `999k+25k`; ENG | 1,024M, danach 1024k | Beispiel, S. 14 |
| K09 | Division mit Rest `5 ÷R 2` | Quotient 2, Rest 1; Ans enthält nur 2 | Beispiel + Regel, S. 14-15 |
| K10 | `1014`, anschließend FACT | 2×3×13²; FACT erneut oder `=` liefert unzerlegten Wert | Beispiel, S. 15 |
| K11 | Nacheinander `2+2`, `3+3`, im Verlauf zurückblättern | Ergebnisse 4 und 6; ältere Rechnung mit Ergebnis 4 erreichbar | Beispiel, S. 17 |
| K12 | `4×3+2`; Ausdruck per Replay zu `4×3−7` bearbeiten | Erst 14, danach 5 | Beispiel, S. 17 |
| K13 | `123+456`; danach `789−Ans` | 579, danach 210 | Beispiel, S. 17 |
| K14 | `3+5` nach A speichern; `A×10`; A abrufen | 8 gespeichert, Produkt 80, Abruf weiterhin 8 | Beispiel, S. 17 |
| K15 | M=0; `10×5` mit M+; `10+5` mit M−; M abrufen | M=35; Speicherindikator aktiv | Beispiel + Regel, S. 18 |
| K16 | A=8 setzen; AC; Modus wechseln; aus-/einschalten | A bleibt 8; getrennt prüfen, dass Verlauf bei Moduswechsel/ON gelöscht ist | Abgeleitet, S. 17-18 |
| K17 | Gradmaß; `sin(30)` | Math→Math: 1/2 | Beispiel, S. 18 |
| K18 | `log₂(16)` und `log(1000)` | 4 und 3 | Beispiel, S. 19 |
| K19 | Fix 3, Math→Dezim.; `10/3×3` und `Rnd(10/3)×3` | 10,000 bzw. 9,999; Anzeige-Rundung allein verändert Zwischenwert nicht wie Rnd | Beispiel, S. 22 |
| K20 | `RndFix(1,23456;4)` | 1,2346 | Beispiel, S. 22 |
| K21 | `GCD(28;35)` und `LCM(9;15)` | 7 und 45 | Beispiel, S. 22 |
| K22 | `Int(-3,5)` und `Intg(-3,5)` | −3 und −4 | Beispiel, S. 22 |
| K23 | Norm 1 bzw. Norm 2; `1/200` als Dezimalergebnis | 5×10^-3 bzw. 0,005 | Beispiel, S. 8 |
| K24 | Fix 3; `100/7` mit Dezimalauswertung | 14,286 | Beispiel, S. 8 |
| K25 | `(5+3)!`; `10 nPr 4`; `10 nCr 4` | 40320; 5040; 210 | Beispiel, S. 21 |
| K26 | `Ran#` und `RanInt#(1;6)` mehrfach ausführen | Ran# im Bereich 0,000-0,999; RanInt# ganzzahlig von 1 bis 6 einschließlich; kein bestimmter Zufallswert vorgeschrieben | Abgeleitet, S. 21 |
| K27 | CONST → Lichtgeschwindigkeit c₀ | 299792458 | Beispiel, S. 47 |

## P1: Weitere Modi und numerische Verfahren

| ID | Voraussetzungen und Aktion | Erwartung | Art / PDF-Seite |
|---|---|---|---|
| E01 | Allgemeiner Modus, CALC; Ausdruck `3A+B`, Werte A=5, B=10 | 25 | Aus Beispiel abgeleitet, S. 24 |
| E02 | Integral von ln(x) für x=1 bis e | 1 innerhalb festzulegender numerischer Toleranz | Beispiel, S. 20 |
| E03 | Bogenmaß; Ableitung von sin(x) an x=π/2 | Ausgabe 0 gemäß Beispiel; intern numerisches Verfahren, keine allgemeine Exaktheitszusage | Beispiel, S. 20 |
| E04 | Summe und Produkt von (x+1), x=1 bis 5 | Summe 20, Produkt 720 | Beispiel, S. 20-21 |
| E05 | Komplexer Modus, a+bi; `(1+i)^4+(1−i)^2` | −4−2i | Beispiel, S. 23 |
| E06 | Komplexer Modus; `Conjg(2+3i)`, ReP/ImP desselben Werts | 2−3i; Realteil 2, Imaginärteil 3 | Beispiel, S. 24 |
| E07 | Komplexer Modus, Gradmaß; `Arg(1+i)` | 45° | Beispiel, S. 24 |
| E08 | Basis-N, DEC; `15×37`, dann HEX | Dezimal 555, Hexanzeige 0000022B | Beispiel, S. 30 |
| E09 | Basis-N, DEC; `d10+h10+b10+o10` | 36 | Beispiel, S. 30 |
| E10 | Basis-N, BIN; `1010 and 1100` | 32-Bit-Ergebnis mit Endbits 1000, übrige Bits null | Beispiel, S. 30 |
| E11 | Basis-N, BIN; `Not(1010)` | 32-Bit-Muster FFFFFFF5 in Hexinterpretation, binär 28 Einsen gefolgt von 0101 | Beispiel, S. 30 |
| E12 | Gleichung/Funkt, lineares System `x+2y=3`, `2x+3y=4` | x=−1, y=2 | Beispiel, S. 31-32 |
| E13 | Gleichung/Funkt, Polynom `x²+2x−2=0` | Lösungen −1+√3 und −1−√3; Extrempunkt (−1,−3) | Beispiel, S. 32; Formeln und Extrempunkt visuell bestätigt |
| E14 | Tabellen, f=x²+1/2, g=x²−1/2; Start −1, Ende 1, Schritt 0,5 | Fünf x-Werte −1/−0,5/0/0,5/1. f=1,5/0,75/0,5/0,75/1,5; g=0,5/−0,25/−0,5/−0,25/0,5 | Aus Beispiel abgeleitet, S. 34 |
| E15 | Verteilungsmodus, Normaldichte; x=36, σ=2, μ=35 | Anzeige laut Beispiel 0,1760326634; Genauigkeitsanspruch der Anleitung nur sechs signifikante Stellen | Beispiel, S. 40-41 |
| E16 | Berechn prüf; `3<π<4` | Wahr; Ans=1 | Beispiel + Regel, S. 38-39 |

## P2 und Grenzen: Zustände, Fehler und Datenmodelle

| ID | Voraussetzungen und Aktion | Erwartung | Art / PDF-Seite |
|---|---|---|---|
| G01 | Matrizen; MatA=[[2,1],[1,1]]; Det(MatA) | 1 | Beispiel, S. 33 |
| G02 | Vektoren; VctA=(1,2), VctB=(3,4), Addition | VctAns=(4,6) | Aus Beispiel abgeleitet, S. 35 |
| G03 | Ungleichungen; x²≥0 bzw. x²<0 | Alle reellen Zahlen bzw. keine Lösung | Beispiel, S. 37-38 |
| G04 | Verhältnisse; A/B=X/D mit A=1,B=2,D=10 | X=5 | Beispiel, S. 38 |
| G05 | Verhältnisse; einen benötigten Koeffizienten auf 0 setzen | Mathem. Fehler, auch wenn eine vereinfachte algebraische Interpretation möglich wäre | Abgeleitet, S. 38 |
| G06 | Berechn prüf; `5≤6≥4` und `4<6≠8` | Jeweils Syntaxfehler | Beispiel, S. 39 |
| G07 | Allgemeiner Modus; `1/0` | Mathem. Fehler. Pfeiltaste führt zur fehlerhaften Rechnung; AC löscht sie | Beispiel + Regel, S. 47-48 |
| G08 | SOLVE auf Ausdruck ohne Variable anwenden | Variablenfehler | Abgeleitet, S. 48 |
| G09 | Tabellenmodus nur f(x), mehr als 45 Zeilen anfordern; mit f/g mehr als 30 | Bereichsfehler | Abgeleitet, S. 35, 48 |
| G10 | Tabellenkalkulation; Zelle A1 mit Formel `=A1` | Zirkelbezug | Beispiel, S. 49 |
| G11 | Tabellenkalkulation; A1 befüllen, Modus verlassen und zurückkehren | Zellinhalte gelöscht; unabhängig von erhaltenen allgemeinen Variablen | Abgeleitet, S. 42 |
| G12 | Statistikeditor mit 1/2/3 Spalten befüllen | Dokumentierte Kapazität 160/80/53 Zeilen; Verhalten beim Überschreiten anschließend am Referenzgerät bestimmen | Regel, S. 26 |
| G13 | Allgemeiner Modus; `70!` | Mathem. Fehler wegen Überschreitung des dokumentierten Fakultäts-Eingabebereichs | Abgeleitet, S. 48, 51 |

## Vor der Testautomatisierung zu klären

- Die exakte Tastensequenz zu jedem mathematischen Fall anhand der sichtbaren Tastatur und Menüs ergänzen; PDF-Schriftzeichen nicht direkt als Tastencodes behandeln.
- Anzeige, Rechenwert und Speichernebenwirkungen getrennt vergleichen. Bei exakten Ergebnissen zusätzlich Bruch-/Wurzel-/π-Struktur prüfen.
- Numerische Verfahren mit geeigneten absoluten und relativen Fehlerschranken sowie Abbruchpfaden testen. SOLVE benötigt Anfangswert und Lösungsvariable; eine allgemeine Garantie auf alle Lösungen wäre falsch.
- Weitere Tests für Statistikquartile, Streuung und Regression, komplexe Zweige, Grenzüberläufe, implizite Multiplikation sowie Matrix-/Vektorfehler nach visueller Verifikation der passenden Originalbeispiele aufnehmen.
- Die alten Konstantenwerte und Umrechnungen als versionierte Referenzdaten behandeln. Historische Kompatibilität nicht durch stilles Aktualisieren auf neuere Standards verändern.
- Kein Fall ist als bestanden zu markieren, bevor er gegen die tatsächliche Implementierung ausgeführt und mit Quelle bzw. Referenzmessung verglichen wurde.
