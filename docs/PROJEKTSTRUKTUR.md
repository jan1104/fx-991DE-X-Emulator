# Konkrete Projektstruktur

Stand: 25.10.2026. Flutter/Dart ist die vom Nutzer gewählte Richtung; langfristige Stabilität und fünf Zielplattformen sind Anforderungen. Die Original-Programmdateien werden später geliefert. Sie sind für die Planung und eine erste eigene Implementierung nach Handbuch keine Voraussetzung.

## Was jetzt angelegt ist

Die beiden künftigen Entwicklungsbereiche `apps/calculator/` und `packages/calculator_core/` sind mit eigenen README-Dateien vorbereitet. `tests/reference/` beschreibt die geplante Referenzprüfung. Dort liegt noch kein ausführbarer Emulatorcode. Die im nächsten Abschnitt dargestellten `lib/`, `test/`, Plattformordner und Paketdateien sind das Zielbild; sie werden erst beim jeweiligen Arbeitspaket angelegt. Flutter und Dart wurden bei der lokalen Befehlsprüfung nicht im PATH gefunden. Eine vollständige Suche nach anderen Installationen wurde nicht durchgeführt.

Vor dem ersten SDK-basierten Arbeitspaket werden Werkzeugverfügbarkeit und Versionen geprüft. Es werden keine handgeschriebenen Plattform-Builddateien als bereits geprüfte Flutter-Projekte ausgegeben.

## Zielbild des Repositorys

Ein Repository, eine Flutter-App und zunächst ein unabhängiges Dart-Paket reichen aus. Die erste Version benötigt keine eigenen Pakete für jede Rechenart und kein zusätzliches Monorepo-Verwaltungswerkzeug.

```text
fx-991DE-X-Emulator/
  README.md
  AGENTS.md
  LICENSE
  .gitignore

  apps/
    calculator/                  Eine App für alle fünf Betriebssysteme
      README.md
      pubspec.yaml               Später: Flutter-Abhängigkeiten + lokaler Core
      pubspec.lock               Später: aufgelöste App-Abhängigkeiten festhalten
      analysis_options.yaml      Später: gemeinsame Qualitätsregeln
      lib/
        main.dart                Einstieg und Zusammensetzen der App
        application/             Verbindung zwischen Oberfläche und Kern
        presentation/
          calculator/            Rechneransicht, Display und Bildschirmtasten
          editor/                Formelansicht und sichtbarer Cursor
          menus/                 MENU, SETUP und kontextbezogene Optionen
          theme/                 Eigene Farben, Größen und Darstellungsregeln
        platform/                Tastatur, Zwischenablage, Dateizugriff
      assets/                    Ausschließlich eigene/freigegebene Ressourcen
      test/                      Widget-, Fokus- und Darstellungstests
      integration_test/          Durchgängige Abläufe der echten App
      android/                   Später vom Flutter-Werkzeug erzeugt
      ios/                       Später vom Flutter-Werkzeug erzeugt
      windows/                   Später vom Flutter-Werkzeug erzeugt
      macos/                     Später vom Flutter-Werkzeug erzeugt
      linux/                     Später vom Flutter-Werkzeug erzeugt

  packages/
    calculator_core/             Dart ohne Flutter und Betriebssystemzugriffe
      README.md
      pubspec.yaml
      lib/
        calculator_core.dart     Kleine, ausdrücklich freigegebene Paket-API
        src/
          numbers/               Exakte Brüche und Näherungswerte
          expressions/           Ausdrucksbaum und Auswertungsregeln
          editor/                Bearbeiten und logische Cursorposition
          state/                 Modi, Setup, Speicher und Bedienübergänge
          evaluation/            Auswertung und numerische Verfahren
          formatting/            Strukturierte, UI-unabhängige Ausgabe
          modes/                 Später die einzelnen Rechenanwendungen
      test/                      Rechen-, Editor- und Zustandstests

  tests/
    reference/
      README.md
      scenarios/                 Später eigene maschinenlesbare Referenzfälle

  docs/                          Quellenanalyse, Entscheidungen, Fortschritt
  tools/                         Lokale Analyse- und später Build-Hilfen
  reference/
    originals/                   Unveränderte fremde Referenzen, Git-ignoriert
      software/                  Später bereitgestellte Programmdateien
  tmp/                           Extraktionen, Prüfbilder, Scratchdaten; ignoriert
```

Die fünf Plattformordner enthalten die benötigten Start- und Buildumgebungen, keine fünf getrennten Rechenprogramme. Eine Browserversion bleibt optional und bekommt bei Bedarf einen zusätzlichen Flutter-Zielordner.

## Abhängigkeitsrichtung

```text
Flutter-Oberfläche / Eingabeadapter
                 |
                 v
App-Anwendungssteuerung
                 |
                 v
calculator_core: Aktionen -> Zustand / Auswertung -> strukturierte Ausgabe
```

`apps/calculator` darf das lokale Core-Paket verwenden. Der Core importiert keine Dateien aus der App und kennt keine Widgets, Pixel, Dateipfade, Zwischenablage, Netzwerkverbindungen oder Android-/Apple-/Windows-APIs. Zunächst wird kein weiterer State-Management-Unterbau vorausgesetzt. Die Auswahl folgt dem Prototypbedarf.

## Verantwortlichkeiten und Schnittstellen

Die folgenden Namen sind Entwurfsbegriffe, noch keine implementierten Klassen:

| Begriff | Vertrag |
|---|---|
| `CalculatorAction` | Semantische Aktion wie Ziffer, Links, SHIFT, Bestätigen oder Menüauswahl. Kennt keine PC-Tastencodes oder Widget-IDs. |
| `CalculatorState` | Konsistenter Zustand aus aktuellem Modus, Bildschirm, Setup, Eingabe, Cursor, Variablen, Ans und Verlauf; von außen nicht beliebig veränderbar. |
| `Expression` | Gemeinsamer strukturierter Ausdruck für Editor und Auswertung: Brüche, Wurzeln, Potenzen und Funktionsargumente. |
| `CursorPosition` | Logischer Pfad und Feldposition im Ausdruck; unabhängig von Fenstergröße und Schriftpixeln. |
| `NumericValue` | Getrennte Repräsentation exakter Werte und numerischer Näherungen. Brüche werden nicht für die Anzeige vorzeitig in Gleitkomma verwandelt. |
| `DisplayModel` | Ausdrücke/Ergebnisse, Formatvorgaben und Indikatoren als Daten. Die Oberfläche zeichnet sie. |
| `EvaluationResult` | Wert oder definierter Fehler mit Zuordnung zur problematischen Eingabe. Keine weitergereichte rohe Laufzeit-Ausnahme als Benutzeranzeige. |

Alle Eingaben laufen über dieselbe Aktionsebene: Touch auf `7`, Mausklick auf `7` und PC-Taste `7` ergeben dieselbe Ziffernaktion. Erst der Kern entscheidet anhand des Bildschirms, ob daraus eine Zahl oder eine Menüauswahl wird. SHIFT/ALPHA werden dort verwaltet, nicht in unabhängigen Bildschirmtasten.

Der Ausdruckseditor ist Teil des Kerns, das Zeichnen der Formel Teil der App. Dadurch lassen sich Einfügen, Löschen, Vorlagenwechsel und Cursorbewegungen ohne gestartete Flutter-Oberfläche prüfen. Für lineare Eingabe und strukturierte Eingabe wird eine gemeinsame Ausdrucksrepräsentation angestrebt; die genaue Tokenisierung ist im Prototyp zu prüfen.

Längere Berechnungen wie SOLVE und Integrale bekommen später einen klaren Berechnungsauftrag samt Abbruchkennung. Eine Hintergrundausführung ist Verantwortung der App; das mathematische Verfahren bleibt im Core. Der erste Grundrechenprototyp braucht dafür noch keine aufwendige Job-Infrastruktur.

## Speicher und Daten

- **Rechnerzustand:** Variablen/Ans, Verlauf, Setup und Modusdaten getrennt halten, weil die Handbuch-Löschregeln unterschiedlich sind. Quelle: `TASTEN_UND_BEDIENUNG.md`.
- **App-Sitzung:** Persistenz und Dateioperationen liegen bei der App. Ein späteres Sitzungsformat erhält eine Versionsnummer und dokumentierte Felder. Kein automatisches Speichern aller Daten, wenn dies dem Rechnerverhalten widerspricht.
- **Referenzfälle:** Eigene, überprüfbare Testdaten getrennt von fremden PDFs und Software halten.
- **Originale:** Später direkt nach `reference/originals/software/` kopieren, inventarisieren und hashen. Ausführung ist kein Bestandteil des Imports. Analyseergebnisse kommen in eigene Dokumentation, extrahierte fremde Ressourcen nach `tmp/`.

## Prüfstrategie

| Ort | Was wird geprüft? |
|---|---|
| Core `test/` | Exakte Rechnung, Operatorprioritäten, Rundung, Bereichsfehler, Cursorfelder, Speicher- und Modusübergänge |
| App `test/` | Sichtbare Formel, Bildschirmgrößen, Tasten, Fokus und Eingabeabbildung |
| App `integration_test/` | Bedienfolge vom Ausgangszustand bis zur Anzeige auf einem tatsächlichen Zielsystem |
| `tests/reference/` | Plattformunabhängige Fälle mit stabiler ID, Quellenbeleg, Voraussetzungen und erwarteten Werten/Zuständen |

Die bereits geplanten 56 Fälle werden schrittweise übernommen. Ein vorhandener Testfall ist noch kein bestandener Test. Die künftige Auswertung soll getrennt festhalten: Quelle verstanden, Erwartung visuell bestätigt, Nachbau getestet, Originalsoftware verglichen. Das spätere Originalprogramm ist zusätzliche Vergleichsreferenz, keine Laufzeitabhängigkeit der neuen App.

Der konkrete Abdeckungsplan mit Tasten-/Funktionsinventaren und ersten maschinenlesbaren Beispielen steht in [TESTSTRATEGIE.md](TESTSTRATEGIE.md). Ein Dart-Testadapter ist noch nicht implementiert.

## Reihenfolge ohne Original-Programmdateien

1. Werkzeuge prüfen und stabile SDK-Version festhalten; dann ein minimales Flutter-Projekt und das lokale Dart-Paket erzeugen.
2. Rechenansicht mit Bildschirmtasten und Maus-/Tastaturabbildung erstellen; Größenverhalten auf Telefon und Desktop prüfen.
3. Kleinen Kern mit Ziffern, Grundoperatoren, Klammern, `=`, AC und DEL aufbauen. Einfache Zustands- und Rechentests anbinden.
4. Bruchvorlage, Cursorfelder und exakte rationale Ergebnisse als entscheidenden Formeleditor-Prototyp ergänzen. Mit ausgewählten Handbuchfällen prüfen.
5. Windows-/Android-Builds entsprechend der verfügbaren Werkzeuge prüfen; übrige Zielplattformen ausdrücklich als ungeprüft führen.
6. Erst danach den gesamten Editor, Speicher, Setup und weitere Modi ausbauen. Originalsoftware später parallel als gesondertes Analysepaket aufnehmen.

Eine anfängliche lineare Eingabe ist lediglich ein begrenzter Prototyp, nicht die Behauptung einer funktionsgleichen natürlichen Casio-Eingabe. Die stabile externe Core-API wird erst nach diesem Machbarkeitstest festgeschrieben.
