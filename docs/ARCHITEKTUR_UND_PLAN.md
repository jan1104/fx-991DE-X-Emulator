# Architekturvorschlag und Entwicklungsplan

Entwurf vom 25.10.2026, fortgeschrieben bis 06.11.2026. Die folgende Architektur ist das Zielbild; tatsächliche Implementierung und Prüfungen stehen im [Entwicklungsstand](ENTWICKLUNGSSTAND.md).

Der unabhängige Dart-Core und die Flutter-Hauptansicht mit linearer und strukturierter Brucheingabe sind inzwischen im Testengine geprüft. Native Builds und echte Zielsystemtests bleiben offen.

## Ziel und Grenzen

Eine unabhängige Verhaltensnachbildung soll Eingabe, Anzeige, Zustände und mathematische Ergebnisse des fx-991DE X möglichst weit abdecken. Eine CPU-/Firmwareemulation ist durch die bisherigen Quellen weder notwendig noch technisch belegt. Die PDF-Anleitungen reichen für eine erste Funktionsspezifikation; sie belegen keine interne Architektur des früheren PC-Emulators.

## Vorgeschlagene Bausteine

Die konkrete Ordneraufteilung, Schnittstellen und Reihenfolge ohne Original-Programmdateien sind in [PROJEKTSTRUKTUR.md](PROJEKTSTRUKTUR.md) festgelegt. Der Dart-Core enthält exakte rationale Auswertung, beide Sitzungsmodelle und den Brucheditor. Die Flutter-App bindet diese Bausteine mit natürlicher Eingabeanzeige, Fehlerstellen und vier Richtungsaktionen an. Der vollständige Formeleditor bleibt ein Ziel.

| Baustein | Verantwortung |
|---|---|
| Eingabeadapter | Bildschirmtasten und später PC-Tastatur in identische Tastensignale übersetzen |
| Zustandsmaschine | Modus, Menü, Cursor, SHIFT/ALPHA, Variablen, Speicher, Verlauf, Setup und Fehlerzustände verwalten |
| Ausdruckseditor | Strukturierte Brüche, Wurzeln, Potenzen, Integrale und Cursorfelder statt bloßer Textverkettung |
| Parser und Rechenkern | Prioritäten, explizite/implizite Multiplikation, exakte rationale Werte und numerische Verfahren |
| Moduldienste | Komplexe Zahlen, Basis-N, Matrizen, Vektoren, Statistik, Verteilungen, Gleichungen und Tabellen |
| Formatierung und Anzeige | Deutsches Dezimalkomma, exakte/approximative Ausgabe, Fix/Sci/Norm, Indikatoren und Fehlerposition |
| Referenzprüfung | Wiederholbare Sequenzen aus Ausgangszustand, Tasten, Anzeige und erwartetem Zustand |

Die neue Nutzeranforderung umfasst Android, iPhone/iPad, Windows, macOS und Linux aus gemeinsamem Quellcode. Nach Recherche ist Flutter mit einem unabhängigen Dart-Rechenkern die bevorzugte Richtung; der frühere TypeScript-/Browser-Vorschlag wird damit ersetzt. Vor umfangreicher Implementierung folgt ein begrenzter Machbarkeitstest für Tastatur, Formeleditor sowie Windows-/Android-Builds. Konkrete Bibliotheken und SDK-Versionen bleiben bis dahin offen. Begründung, Alternativen, Reddit-/Forenquellen und Build-Voraussetzungen stehen in [PLATTFORMWAHL.md](PLATTFORMWAHL.md).

Der Rechenkern soll ohne Oberfläche testbar sein. Exakte rationale Ergebnisse und Näherungswerte müssen getrennt repräsentiert werden. Eine gewöhnliche Gleitkommaauswertung allein deckt Brüche, Wurzeldarstellung und Anzeigegrenzen nicht ab. Anzeigerundung darf interne Werte nicht unbemerkt verändern. Zufallsfunktionen benötigen für Tests kontrollierbare Zufallsquellen.

## Priorisierte Arbeitspakete

| Priorität | Paket | Abnahme | Status |
|---|---|---|---|
| P0 | Originale sichern, Quelleninventar, Modi und Tasten katalogisieren | Identität geprüft, Seitenbelege und offene Punkte dokumentiert | In dieser Analyse bearbeitet |
| P0 | Original-Programmdateien statisch untersuchen | Dateitypen, Abhängigkeiten und Laufzeitplan belegt | Wartet auf Programmdateien |
| P0 | Flutter/Dart-Machbarkeitstest für fünf Zielsysteme | Gemeinsamer Kern und UI-Ansatz geprüft; tatsächlich erreichbare Windows-/Android-Builds und übrige offene Zieltests dokumentiert | Core und erste Flutter-Ansicht im Testengine geprüft; fünf Gerüste erzeugt, native Builds/Gerätetests offen |
| P1 | Minimaler Zustandskern und strukturierter Editor | ON/AC/DEL, Cursor, SHIFT/ALPHA, MENU/SETUP und Ergebniszustand geprüft | Beide Sitzungen, AC/DEL, natürliche Bruchfelder, vier Richtungen und Fehlerziele geprüft; vollständiger Editor/ON/Modifier/Menüs offen |
| P1 | Grundrechnen mit Prioritäten, Brüchen, Ans und Winkeln | Geplante Referenzfälle samt Fehlern und Anzeigewechsel bestehen | Exaktes lineares Grundrechnen/Potenzen und Ans als Prototyp geprüft; Winkel/Anzeige offen |
| P2 | Wissenschaftliche Funktionen, CALC, numerische Ableitung/Integral/SOLVE | Genauigkeit und problematische Eingaben reproduzierbar geprüft | Offen |
| P2 | Gleichungen, komplexe Zahlen, Basis-N | Grenzen und Modusunterschiede geprüft | Offen |
| P3 | Matrizen, Vektoren, Statistik, Verteilungen | Pro Modul typische und ungültige Eingaben geprüft | Offen |
| P3 | Wertetabelle, Tabellenkalkulation, Ungleichungen, Verhältnisse, Nachprüfung | Zustände und Kapazitätsgrenzen geprüft | Offen |
| P4 | Konstanten, Umrechnungen, QR und PC-Komfortfunktionen | Historische Datenstände und externe Schnittstellen entschieden | Offen |
| P4 | Reproduzierbarer Build und Paketierung | Saubere lokale Installation und Testlauf reproduzierbar | Offen |

Linearer Bedienzustand, strukturierte Sitzung, Brucheditor und die neue frontnahe Flutter-Ansicht sind verbunden. Werkzeugleisten-Setup und SHIFT → MENU verwenden dieselbe zentrale Steuerung. Der unabhängige GitHub-Prüfweg hat auf `1d3eecb` 945 Coretests und 438 Appfälle sowie Web-Build und 18 Vorschauszenarien bestanden; Front und Setup wurden in früheren UI-Paketen als Testengine-Bilder visuell geprüft; die neue Betragsansicht wurde zusätzlich mit Handbuchrechnung, hohem Bruch und leerem Argument visuell geprüft. Dadurch sind die zuvor durch lokale Windows-Code-Integrity blockierten neuen Testfälle nachgeholt, ohne lokale Sicherheitsrichtlinien zu ändern. Native Builds und Originalvergleich bleiben offen.

Eigene Projektänderungen dürfen seit der Freigabe vom 02.11. selbstständig gepusht werden. Automatische neue Arbeitsläufe ausschließlich alle sechs Stunden; kein zusätzlicher Dauermonitor. Der exakte Periodenformatter ist inzwischen im Core implementiert; alle 30 unabhängigen Referenzen sind zusätzlich zu den gezielten Ressourcen-/Vertragstests ausgeführt. Periodenschalter und S⇔D-Zyklus sind nun in der App geprüft, mit unverändertem Ans und sichtbarem Periodenstrich. Kubieren über SHIFT → x² ist jetzt mit eigenständigem Core-Vertrag und Bedientests geprüft. Prozent über SHIFT → Ans ist mit den drei vorhandenen Handbuchbeispielen und eigenen Zustands-/Grenztests geprüft. Fakultät über SHIFT → x⁻¹ ist für die belegte Ganzzahldomäne 0 bis 69 mit Domänenfehlern und Arbeitsbudget geprüft. nPr/nCr über SHIFT → ×/÷ sind mit Binärbindung, Argumentdomäne und den visuell geprüften Zwischenwertgrenzen implementiert und getestet. Betrag ist jetzt über SHIFT → ( mit `EditorAbsolute`, Argumentnavigation, Sitzungsaktion und skalierenden natürlichen Betragsstrichen geprüft. Als nächstes Paket wird der unabhängige Speicher M mit M+/M−, gemeinsamen Math-/Linear-Werten und getrennten Löschregeln spezifiziert. Regeln und Grenzen: [BETRAG.md](BETRAG.md), [BETRAG_EDITOR.md](BETRAG_EDITOR.md), [KOMBINATORIK.md](KOMBINATORIK.md), [FAKULTAET.md](FAKULTAET.md), [PROZENT.md](PROZENT.md), [KUBIEREN.md](KUBIEREN.md), [PERIODEN_APP.md](PERIODEN_APP.md), [FRONT_UND_SETUP.md](FRONT_UND_SETUP.md), [PERIODENDARSTELLUNG.md](PERIODENDARSTELLUNG.md), [DARSTELLUNGSWAHL.md](DARSTELLUNGSWAHL.md), [EXAKTE_AUSGABE.md](EXAKTE_AUSGABE.md). Für die technische Rekonstruktion des alten PC-Programms fehlen weiterhin dessen Dateien.

Fortschreibung 04.11.2026 nachmittags: Der Speichervertrag ist in [SPEICHER_M.md](SPEICHER_M.md) festgelegt. Das erste Paket ergänzt einen unabhängigen Core-Dienst für exaktes Ans/M und atomare Ergebnis-, Additions-, Subtraktions- und Speichertransaktionen. Beide Eingabesitzungen und die App sind noch nicht angebunden. Nächster Schritt ist die gemeinsame Speicherinjektion mit getrennten Eingabe-/Anzeigezuständen; sichtbare M-Tasten, STO/RECALL und Resetbedienung brauchen eigene Abnahmen. Tatsächlicher Prüfstand: [Entwicklungsstand](ENTWICKLUNGSSTAND.md).

Fortschreibung 04.11.2026 abends: Beide Eingabesitzungen akzeptieren den gemeinsamen Core-Speicher; der Appcontroller teilt genau eine Instanz zwischen Math und Linear. Snapshot-Ans folgt dem aktuellen Register, gespeicherte Ergebnisse und Entwürfe bleiben getrennt. Die Sitzungs-API `applyMemory` ergänzt atomare Speicheraktionen ohne erneute Auswertung eines angezeigten Ergebnisses. Der GitHub-Lauf auf `2616bd9` bestand 1041 Coretests, 449 Appfälle, Web-Build und 18 Vorschauen. Als nächstes folgen die sichtbare M+/M−-Belegung und der M-Indikator mit eigener App-Abnahme. Vertrag und tatsächlicher Prüfstand: [SPEICHER_M.md](SPEICHER_M.md), [ENTWICKLUNGSSTAND.md](ENTWICKLUNGSSTAND.md).

Fortschreibung 05.11.2026: M+ und SHIFT → M− sind in beiden Eingabearten angebunden, einschließlich M-Status und zugänglicher Beschriftung. Geprüft auf `db6bb60`: 1041 Coretests, 480 Appfälle, Web-Build und 21 Vorschauen. Alle 21 Bilddateien wurden im Artefakt nachgewiesen; drei M-Ansichten sind visuell geprüft. Nächstes begrenztes Paket ist der STO-/RECALL-Vertrag für M; weitere Variablen und Resetmenüs bleiben offen. Umfang und Grenzen: [SPEICHER_M.md](SPEICHER_M.md), [ENTWICKLUNGSSTAND.md](ENTWICKLUNGSSTAND.md).

Fortschreibung 06.11.2026: Der [STO-/RECALL-Vertrag](STO_RECALL_M.md) ist mit gezielter Quellenprüfung und unabhängigem Schnittstellenreview ausgearbeitet. Er trennt Originalbelege und eigene Ans-/Abbruchregeln. Nächste Implementierung ist der exakte M-Operand in Parser und Editor; erst danach folgen eingefrorene STO-Kandidaten, kohärente Recall-Ergebnisse und der Appdialog. Eine reine Ergebnisänderung bei altem Ausdruck oder sofortiges Speichern beim Öffnen würde die Abnahme verletzen. Neues Paket ausschließlich Dokumentation, unveränderter geprüfter Quellstand.

## Risiken und offene Entscheidungen

- **Bestätigt:** H deckt zwei Modelle ab; unkritische Übernahme würde falsche Grenzen erzeugen. Nur fx-991DE X ist Zielmodell.
- **Bestätigt:** Symbolfonts beeinträchtigen Textextraktion; vollständige Formeln und Tastenfolgen müssen visuell verifiziert werden.
- **Offen:** Rundung, Genauigkeit, exakte Vereinfachung und numerische Randfälle erfordern zusätzliche Beobachtungen. Mathematische Gleichwertigkeit garantiert keine identische Anzeige.
- **Offen:** Originalsoftware könnte zusätzliche PC-Funktionen besitzen; aus den Rechnerhandbüchern nicht ableitbar.
- **Offen:** QR-Erzeugung und historische Webdienste sind für den lokalen Kern unabhängig zu spezifizieren. Aktuelle Erreichbarkeit wurde nicht untersucht.
- **Entscheidungsvorschlag:** Historische Konstantenstände für Kompatibilität festhalten; eine spätere Aktualisierung als eigene Option behandeln.
- **Bestätigt:** Der damalige vollständige Referenzstand wurde am 25.10.2026 mit ausdrücklicher Freigabe gepusht. Später gelieferte Originalsoftware und neue Entwicklungen sind dadurch nicht automatisch zur Veröffentlichung freigegeben.

## Prüfstand

Die früheren Quellen-/Katalogprüfungen werden durch tatsächliche Coretests ergänzt. Die genaue Ausführung und Grenzen stehen in [ENTWICKLUNGSSTAND.md](ENTWICKLUNGSSTAND.md); native App-Builds und Originalvergleich fehlen weiterhin.
