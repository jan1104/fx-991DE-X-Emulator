# Prüfplan für jede Rechenfunktion

Stand: 25.10.2026. **Planung, keine ausgeführten Emulatorprüfungen.** Die maschinenlesbare Matrix liegt unter [function_coverage.csv](../tests/reference/function_coverage.csv). Sie enthält 243 Einträge mit durchgehend `status=planned`. Die vorhandenen 56 Referenzfälle bleiben als Beispiele erhalten und werden über K-/E-/G-IDs verknüpft. Diese Verknüpfung bedeutet noch keine vollständige Testabdeckung.

## Umfang und Aussage der Matrix

Jede Zeile benennt eine Funktion oder eine ausdrücklich getrennte Variante: beispielsweise sin/cos/tan jeweils separat, alle inversen und hyperbolischen Funktionen separat, die sieben Verteilungen separat und alle zwölf Kombinationen aus Ungleichungsgrad und Vergleichsrichtung separat. Alle 13 Modi des Funktionskatalogs sind vertreten. Darstellung, gemeinsame Speicherzustände und QR-Export werden zusätzlich geführt; QR ist keine mathematische Rechenfunktion.

Die Matrix ist ein nachvollziehbarer **Ausgangskatalog**, kein Beweis absoluter Vollständigkeit. Die Menüeinträge aller Konstanten und gerichteten Umrechnungen sind noch nicht als Einzelzeilen transkribiert. Einige Setup-/Editoraktionen, Bytegrenzen, Statistik-Konventionen und nicht in den bisherigen Quellen katalogisierte Optionen bleiben ausdrücklich offen. Ein aggregierter Enumerationseintrag darf nicht als bestandener Test für alle seine späteren Datensätze zählen.

Quelle `H` bezeichnet `reference/originals/fx-87_991DEX_DE.pdf`. Seiten sind physische, 1-basierte PDF-Seiten. `source` belegt die Existenz bzw. Regel einer Funktion. Die mathematischen Beispiele, Grenz- und Fehlerideen in dieser neuen Matrix sind **eigene abgeleitete Testvorschläge**, soweit nicht ein verknüpfter Fall in REFERENZTESTS.md ausdrücklich als Handbuchbeispiel klassifiziert ist. Ungeklärte Erwartungen sind mit „bestätigen“ oder „charakterisieren“ markiert und dürfen nicht ungeprüft zu Muss-Anforderungen werden.

## Pro Funktion erforderliche Prüfungen

Aus jeder Zeile werden mehrere ausführbare Fixtures. Die CSV enthält Ideen, noch keine serialisierten Tastensequenzen und noch keinen ausführbaren Testadapter.

1. **Normalfall:** expliziter Modus, Setup, Ausgangsspeicher und Eingabe; Sollwert von einer unabhängigen Quelle; Ausgabeform und Speichernebenwirkungen getrennt prüfen.
2. **Grenzfälle:** Null, Vorzeichen, kleinste/größte dokumentierte Werte, unmittelbar unter/auf/über einem Grenzwert, wiederholte oder singuläre Fälle. Dezimale Grenzwerte als Strings/Rationalwerte erzeugen; binäre Fließkomma-`nextafter`-Werte allein bilden die Rechner-Eingabegrenze nicht ab.
3. **Ungültige Eingabe:** Domäne, Syntax, Dimension, Modus oder Kapazität verletzen. Erwartete Fehlerklasse und Erhalt/Änderung von Ans, Variablen, Editorposition und Modusspeicher protokollieren. Eine Ausnahme im Testprozess ist kein bestandenes Fehlerverhalten.
4. **Varianten:** relevante Winkel-/Zahlen-/Ein-Ausgabeformate, Dimensionen und Modelltypen parametrisieren. Nicht jede Funktion unterstützt jeden Modus; zulässige Kombinationen sind explizit zuzulassen, unzulässige zu prüfen.
5. **Schnittstelle:** denselben Auftrag einmal direkt an den Dart-Kern und einmal als semantische Eingabefolge ausführen. Ein korrekter Funktionswert bei falscher Tasten-/Menüzuordnung ist kein bestandener Bedienablauf.
6. **Gezielte Eigenschaften:** Identitäten, Skalierung, Symmetrie, Monotonie und Roundtrips nur ergänzend verwenden. Sie ersetzen keine unabhängigen festen Sollwerte.

Jeder konkrete Fall braucht später mindestens: stabile `case_id`, `function_id`, Parameter, Ausgangszustand, Aktionen, unabhängige erwartete Werte/Strukturen, Quelle mit Evidenztyp, Fehlerbudget, erwartete Zustandsänderungen und getrennte Ergebnisse für Core, Oberfläche und optionalen Originalvergleich.

## Unabhängige Orakel

Der unabhängige Dart-Kern unter `packages/calculator_core` wird gegen außerhalb dieses Kerns erzeugte, versionierte Referenzdaten geprüft. Der Plan setzt keine bereits installierte Referenzbibliothek oder vorhandenes Dart-SDK voraus.

| Klasse | Primäres Orakel | Ergänzende Prüfung |
|---|---|---|
| Ganzzahlen, Brüche, Kombinatorik, GCD/LCM, Basis-N | Python-Ganzzahlen und exakte rationale Rechnungen aus Rohwerten; 32-Bit-Maske explizit | Algebraische Eigenschaften und H-Beispiele |
| Transzendente reelle/komplexe Funktionen | Mindestens 80 Dezimalstellen in einer externen, versionierten Referenz, z. B. mpmath; kritische Fälle mit 120 Stellen wiederholen | Analytische Sonderwerte und Symmetrien; Zweigbereiche kontrollieren |
| Rundung und Darstellung | Separater Decimal-/Rational-Formatter mit bestätigter Tie-Regel | Exakte Anzeige- und Strukturprüfung, einschließlich Bruch/Wurzel/π und Indikatoren |
| Integral | Analytische Stammfunktion für Hauptfixtures; unabhängige hochpräzise Quadratur anderen Typs für weitere Fälle | Zerlegung des Intervalls nur Zusatzprüfung |
| Ableitung | Analytische oder extern symbolisch abgeleitete Funktion | Skalierungs- und Schrittweitenempfindlichkeit; keine Kopie des gleichen Differenzenverfahrens |
| SOLVE und Polynome | Bekannte analytische Wurzeln bzw. unabhängig isolierte hochpräzise Wurzeln | Skaliertes Residuum, Anzahl/Multiplizität und Anfangswertabhängigkeit |
| Statistik | Exakte gewichtete Rohdatensummen und separater Zwei-Pass-Algorithmus; Konventionen explizit | Ausgeschriebene Daten gegen Häufigkeitsdarstellung |
| Regression | Analytisch erzeugte Daten sowie unabhängiger HP-QR/SVD-Fit | Residuen auf zusätzlichen Punkten; degenerierte Fälle und Konditionierung |
| Verteilungen | HP-erf/erfc bzw. Kombinatorik mit HP-exp; Quantil über unabhängige monotone Suche | Normierung/Monotonie als Zusatz; Tails stabil berechnen |
| Matrix/Vektor | Exakte rationale Komponentenrechnung; HP-Verfahren für numerisch schwierige Fälle | Residuum, Rang und Winkelkonvention; REF nicht blind auf eine einzige Textform festlegen |
| Tabellenkalkulation und Speicher | Eigenes kleines Referenzmodell für Zellen, Referenzverschiebung und Zustandsübergänge | Spezifische feste Werte; kein Vergleich einer DUT-Ausgabe mit einem Snapshot derselben Ausgabe |

Referenzdaten dürfen weder durch Aufruf der zu prüfenden Funktion noch durch Import ihrer Tabellen erzeugt werden. Ein zweiter Wrapper um denselben Algorithmus ist kein unabhängiges Orakel. Auch ein Roundtrip kann zwei sich gegenseitig aufhebende Fehler enthalten. Referenzgenerator, Versionsstand, Präzision und Datenhash werden später mit den Fixtures festgehalten.

## Numerische Toleranzklassen

Die folgenden Profile sind anfängliche **Projekt-Testentscheidungen**, keine zusätzlichen Genauigkeitszusagen des Handbuchs. Pro Fixture werden Profil und Werte vor der Implementierungsprüfung eingefroren. Ein Fehlerbudget darf nicht nachträglich nur vergrößert werden, damit die Implementierung besteht.

H PDF S. 50 nennt 15 interne Stellen und gewöhnlich ±1 an der zehnten Stelle einer einzelnen Rechnung. H S. 40 nennt für Verteilungen sechs signifikante Stellen. Daraus folgt weder bitgenaue Übereinstimmung noch ein universeller Rundungsmodus. Vergleich mit dem mathematischen Orakel und Vergleich mit der historischen Anzeige sind getrennte Ziele.

| Profil | Vorgeschlagene Anfangsregel | Einschränkung |
|---|---|---|
| `exact` | Exakte Ganzzahl, gekürzter Bruch, Bitmuster, Bool, Dimension, Fehlerklasse und Zustandswert müssen gleich sein | Keine Fließkommatoleranz für eigentlich exakte Ergebnisse verwenden |
| `display` | Exakte bestätigte Anzeige/Struktur nach Setup; für gerundete Dezimalzahlen zusätzlich zulässige letzte Anzeigestelle kontrollieren | Tie-Regel, Sci-Parameter 0 und Konvertierbarkeit erst bestätigen; internen Fehler nicht durch Rundung verbergen |
| `scalar` | Bei gut konditionierten Fällen: `abs(y-ref) <= 1e-12*S + 5e-10*abs(ref)` | S ist eine pro Fall festgelegte natürliche Ausgangsskala; nicht pauschal 1 für winzige Werte. Auf praktisch null erwartete Sonderwerte gesondert prüfen |
| `distribution` | Positive, nicht extremale Wahrscheinlichkeiten zunächst relativ `<=1e-5`; exakte kombinatorische Fälle zusätzlich exakt soweit dargestellt | In sehr kleinen Tails kein globaler absoluter Boden, der fälschlich 0 akzeptiert. Exakte 0/1-Endpunkte gesondert; inverse CDF im x-Raum und über unabhängige CDF prüfen |
| `integral` | Für normierte, analytisch lösbare Normalfixtures zunächst absolut `1e-5` bei Standard-tol; für engere tol eigene begründete Budgets | tol aus H ist kein garantierter absoluter Fehler für beliebige Funktionen. Bei großer Auslöschung Skala über Integral des Betrags und Konditionierung dokumentieren |
| `derivative` | Für einfache unitär skalierte analytische Normalfixtures zunächst absolut `1e-8`; sonst pro Fall skalieren | Standard-tol `1e-10` aus H nicht direkt als universelle Ergebnisfehlerschranke missverstehen. Nichtdifferenzierbarkeit separat, keine falsche Genauigkeitsbehauptung |
| `roots` | Gut getrennte einfache Wurzeln zunächst relativer/skalierter Wurzelfehler `1e-8` plus normiertes Residuum `<=1e-10` | Bei Mehrfachwurzeln/nahe singulären Systemen genügt kleines Residuum nicht; Konditionszahl bzw. analytischer Abstand bestimmt zulässige Vorwärtsfehler |
| `linear_algebra` | Exakte rationale Fixtures exakt; numerisch gut konditionierte Fälle zunächst relativer Vorwärtsfehler `1e-10` und normiertes Residuum `1e-12` | Rang/REF-Pivotkonventionen prüfen; für ill-konditionierte Matrizen kein blind identisches Vorwärtsbudget |
| `random` | Bereich, Ganzzahligkeit/Gitter und erlaubte Endpunkte exakt | Keine Forderung einer unbekannten RNG-Folge; statistische Tests mit dokumentiertem Signifikanzniveau separat, nicht zufällig flakende Merge-Sperre |

Bei Rückgabe von NaN/Infinity, falschem Typ, fehlendem Ergebnis oder falscher Fehlerklasse gilt der numerische Vergleich immer als fehlgeschlagen. Exakte Hardware-Rechenbereichsgrenzen und Unterlaufverhalten werden separat geprüft; die Toleranz darf diese Fehler nicht verdecken.

### Konditionierung und schwierige Fälle

Nahe tan-Polen, inversen Funktionsgrenzen, mehrfachen Wurzeln, singulären Matrizen und bei Auslöschung kleine Eingabeänderungen mit hoher Referenzpräzision untersuchen. Daraus wird eine Konditionsabschätzung und ein begründetes Fallbudget abgeleitet. Aus solchen Fällen entstehen eigene Charakterisierungstests; sie dürfen nicht einfach aus der Suite verschwinden. Das gilt auch für Quartile, Regressionen mit konstanten Daten und den Winkel des Nullvektors.

Ein numerisches Residuum ist nur ein Zusatzbeleg: Eine falsche Mehrfachwurzel oder eine stark fehlerhafte Lösung eines schlecht konditionierten Systems kann trotzdem ein kleines Residuum haben. Bei Wurzelmengen Reihenfolge nur verlangen, wenn belegt; ansonsten mengenweise mit Multiplizitäten zuordnen. Bei Ungleichungen die gesamten Intervalle einschließlich offener/geschlossener Grenzen vergleichen.

## Parametrisierte Vollständigkeit

- Kreisfunktionen und Pol/Rec: Grad/RAD/Gon; explizite Einheiten getrennt; inverse Hauptwerte und Winkelzweige.
- Formatierung: vier Ein-/Ausgabeformate; Fix/Sci-Auswahl 0..9; Norm1/2; beide Bruchformen; Periodendarstellung; Präfixe und ENG in beide Richtungen. Eingabe einer periodischen Zahl und Ausgabe einer Periode sind getrennte Fixture-Varianten derselben katalogisierten Funktion.
- Statistik: ein/zwei Variablen, Freq aus/ein, erlaubte Größen; sieben Regressionstypen. a/b und Schätzwertausgaben pro anwendbarem Typ parametrisieren; c/x1/x2 nur für Quadratik, r nicht ungeprüft dort anbieten.
- Gleichungen: Dimensionen 2/3/4 und Polynomgrade 2/3/4 stehen getrennt in der Matrix. Komplexe Lösungen ein/aus und doppelte Wurzeln zusätzlich.
- Matrizen: jede zulässige Form von 1..4 Zeilen/Spalten für passende Operatoren; rechteckige Fälle ausdrücklich. Vektoren: 2D und 3D. Speicherziele A-D und Antwortspeicher separat parametrisieren.
- Tabellen: f gegen f/g, 45/30-Zeilen-Grenze, Parameter-/Zellenänderung. Tabellenkalkulation: `$A1`, `A$1`, `$A$1`, relative Referenz; Kopieren und Ausschneiden haben unterschiedliche Regeln.
- Ungleichungen: alle Grade 2/3/4 mit >, <, ≥, ≤ sind eigene Zeilen; dazu doppelte Wurzeln und triviale Lösungsräume.
- Verteilungen: alle sieben Typen; bei diskreten Typen Einzelwert und Liste. Wahrscheinlichkeitsgrenzen und nichtganze Daten separat.

Nicht das volle kartesische Produkt blind ausführen: Kern-Domänenfälle je Funktion vollständig, Konfigurationskombinationen risikogewichtet/paarweise ergänzen und bekannte Interaktionen explizit vollständig testen.

## Konstanten und Umrechnungen vollständig enumerieren

Die zwei Zeilen `data.constants` und `data.conversions` sind derzeit **offene Enumerationsaufträge**, keine vollständige atomare Abdeckung. Das H-Referenzblatt S. 54-56 ist der Abgleichrahmen. H S. 46 nennt 47 Konstanten; die tatsächliche transkribierte Menge muss mit dieser Quellenangabe abgeglichen werden. Für Umrechnungen wird hier keine unbestätigte Anzahl erfunden.

Für jede Konstante entsteht ein Datensatz mit stabiler Symbol-ID, Kategorie, Menüpfad, historischem Dezimalwert, Einheit, Quelle und Rundungsregeln. Kategorien laut Referenzblatt: universell, elektromagnetisch, atomar/nuklear, physikalisch/chemisch, übernommene Werte und andere. Historische CODATA-2010-Werte nicht still durch aktuelle Werte ersetzen. Implementierungsdaten und unabhängige Prüfdaten werden getrennt transkribiert und gegengeprüft.

Für **jede gerichtete** Umrechnung entsteht eine eigene ID mit Ausgangseinheit, Zieleinheit, Kategorie, Faktor/Offset und historischer Grundlage NIST SP 811 (2008). Kategorien: Länge, Fläche, Volumen, Winkel, Masse, Zeit, Geschwindigkeit, Beschleunigung, Drehmoment, Kraft, Druck, Energie, Leistung, Wärmedurchfluss, Temperatur, spezifische Wärme, dynamische/kinematische Viskosität, Magnetismus, Lichtstärke und Radioaktivität. Richtungen getrennt zählen; gleich benannte Einheiten in verschiedenen Kategorien nicht zusammenwerfen. Fahrenheit/Celsius braucht affine Tests mit mindestens 0/32/100/212, keine bloße Skalierung. cal bei 15 °C, calIT und calth unterscheiden.

Ein Abgleichprüfer muss danach jede bestätigte Menü-ID genau einmal in der Datentabelle und mindestens einmal in ausführbaren Testfällen finden; verwaiste Einträge und doppelte IDs lassen die Prüfung scheitern. Bei Konstanten mindestens Einfügen, Weiterrechnen und Anzeigen testen; bei Umrechnungen 0/1/2 und passende negative/Extremwerte. Roundtrips sind nur ergänzend: Zwei falsche inverse Faktoren können gemeinsam einen perfekten Roundtrip liefern.

## Abdeckungsnachweis und Reihenfolge

1. Die CSV zunächst strukturell prüfen: genau die festgelegten Spalten, eindeutige stabile IDs, Pflichtfelder, gültige K-/E-/G-Verweise und durchgehend `planned`.
2. Zu jedem Eintrag konkrete Normal-, Grenz- und Fehlerfixtures erzeugen. Ein nicht anwendbarer Fehlerfall benötigt eine dokumentierte Begründung; ein leerer Test zählt nicht.
3. Erst Kernrechnen, exakte Datenmodelle und Anzeige prüfen, danach P1-/P2-Module gemäß FUNKTIONSUMFANG.md. Jede implementierte Funktion muss mit ihrer Matrix-ID verbunden werden. Umgekehrt dürfen angebotene UI-Funktionen ohne Matrix-ID nicht unbemerkt bleiben.
4. Denominator erst nach Enumeration aller bestätigten Einzelkonstanten und Umrechnungen sowie Menüabgleich freigeben. Aktuell weder „243 Funktionen vollständig“ noch „100 % Funktionsabdeckung“ melden.
5. Ergebnisbericht nach Ebenen trennen: Quellenprüfung, Orakelerzeugung, ausgeführte Coretests, Bedienabläufe und optional Originalvergleich. Codezeilenabdeckung kann ergänzen, ersetzt diese Funktionsprüfung aber nicht.

## Bekannte Restlücken

Die konkrete PDF-Analyse wird hierfür nicht wiederholt. Offen bleiben die vollständigen Konstanten-/Umrechnungstabellen, einzelne grafisch definierte P/Q/R-Flächen und Quartilkonventionen, Rundungshalbpunkte, Sci-Auswahl 0, Abbruch-/Überlauf-/Unterlaufdetails, REF- und 2D-Kreuzproduktdarstellung, Rang-/Wurzelreihenfolgen und genaue Token-Bytekodierung. Vorhandene Tasten-/Bedienpläne werden separat integriert; diese Matrix ersetzt sie nicht.

Weitere Anweisungen/Optionen, die später im Menüabgleich auftauchen, erhalten zusätzliche stabile IDs. Original-Programmdateien liegen noch nicht vor; deren Verhalten kann hier nicht als gemessen gelten. Das blockiert die unabhängigen mathematischen Fixtures und die eigene handbuchbasierte Implementierung nicht.
