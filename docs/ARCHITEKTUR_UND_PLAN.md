# Architekturvorschlag und Entwicklungsplan

Stand: 25.10.2026. Dies ist ein Entwurf, keine bereits vorhandene Implementierung.

## Ziel und Grenzen

Eine unabhängige Verhaltensnachbildung soll Eingabe, Anzeige, Zustände und mathematische Ergebnisse des fx-991DE X möglichst weit abdecken. Eine CPU-/Firmwareemulation ist durch die bisherigen Quellen weder notwendig noch technisch belegt. Die PDF-Anleitungen reichen für eine erste Funktionsspezifikation; sie belegen keine interne Architektur des früheren PC-Emulators.

## Vorgeschlagene Bausteine

Die konkrete Ordneraufteilung, Schnittstellen und Reihenfolge ohne Original-Programmdateien sind in [PROJEKTSTRUKTUR.md](PROJEKTSTRUKTUR.md) festgelegt. Vorbereitet sind ein Flutter-App-Bereich, ein reiner Dart-Core-Bereich und ein Referenztestbereich; ausführbarer Emulatorcode existiert noch nicht.

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
| P0 | Flutter/Dart-Machbarkeitstest für fünf Zielsysteme | Gemeinsamer Kern und UI-Ansatz geprüft; tatsächlich erreichbare Windows-/Android-Builds und übrige offene Zieltests dokumentiert | Nächstes unabhängiges Paket |
| P1 | Minimaler Zustandskern und strukturierter Editor | ON/AC/DEL, Cursor, SHIFT/ALPHA, MENU/SETUP und Ergebniszustand geprüft | Offen |
| P1 | Grundrechnen mit Prioritäten, Brüchen, Ans und Winkeln | Geplante Referenzfälle samt Fehlern und Anzeigewechsel bestehen | Offen |
| P2 | Wissenschaftliche Funktionen, CALC, numerische Ableitung/Integral/SOLVE | Genauigkeit und problematische Eingaben reproduzierbar geprüft | Offen |
| P2 | Gleichungen, komplexe Zahlen, Basis-N | Grenzen und Modusunterschiede geprüft | Offen |
| P3 | Matrizen, Vektoren, Statistik, Verteilungen | Pro Modul typische und ungültige Eingaben geprüft | Offen |
| P3 | Wertetabelle, Tabellenkalkulation, Ungleichungen, Verhältnisse, Nachprüfung | Zustände und Kapazitätsgrenzen geprüft | Offen |
| P4 | Konstanten, Umrechnungen, QR und PC-Komfortfunktionen | Historische Datenstände und externe Schnittstellen entschieden | Offen |
| P4 | Reproduzierbarer Build und Paketierung | Saubere lokale Installation und Testlauf reproduzierbar | Offen |

Es werden jetzt noch keine Emulatorfunktionen behauptet oder ungeprüft implementiert. Der nächste eigenständig mögliche Entwicklungsschritt ist die Spezifikation des minimalen Zustandskerns aus dem Tasten- und Testkatalog. Für die technische Rekonstruktion des alten PC-Programms fehlen weiterhin dessen Dateien.

## Risiken und offene Entscheidungen

- **Bestätigt:** H deckt zwei Modelle ab; unkritische Übernahme würde falsche Grenzen erzeugen. Nur fx-991DE X ist Zielmodell.
- **Bestätigt:** Symbolfonts beeinträchtigen Textextraktion; vollständige Formeln und Tastenfolgen müssen visuell verifiziert werden.
- **Offen:** Rundung, Genauigkeit, exakte Vereinfachung und numerische Randfälle erfordern zusätzliche Beobachtungen. Mathematische Gleichwertigkeit garantiert keine identische Anzeige.
- **Offen:** Originalsoftware könnte zusätzliche PC-Funktionen besitzen; aus den Rechnerhandbüchern nicht ableitbar.
- **Offen:** QR-Erzeugung und historische Webdienste sind für den lokalen Kern unabhängig zu spezifizieren. Aktuelle Erreichbarkeit wurde nicht untersucht.
- **Entscheidungsvorschlag:** Historische Konstantenstände für Kompatibilität festhalten; eine spätere Aktualisierung als eigene Option behandeln.
- **Bestätigt:** Originale sind lokal gespeichert und ignoriert; eine spätere Veröffentlichung braucht gesonderte Prüfung und ausdrückliche Nutzerfreigabe. Es erfolgte kein Push.

## Prüfstand

In dieser Phase sind Dateiidentität, Lesbarkeit, lokale Extraktion und Git-Ausschluss prüfbar. Referenztests beschreiben künftige Prüfungen; es gibt noch keinen Emulator, keinen Build und keine bestandenen mathematischen Implementierungstests.
