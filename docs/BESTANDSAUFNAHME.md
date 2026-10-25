# Bestandsaufnahme und Quellen

Stand: 25.10.2026. Arbeitsordner: `D:\depot\fx-991DE-X-Emulator`.

## Ausgangslage vor Änderungen

Das bestehende Git-Repository enthielt ausschließlich `README.md` und `LICENSE` (MIT), Ausgangscommit `95ed4c9`. Die Arbeitskopie hatte keine gemeldeten Änderungen. Es gab keinen Emulatorcode, keine Build-Konfiguration, keine Tests und keine Original-Programmdateien. Folglich sind Architektur, Programmiersprache, Ressourcenformate, Laufzeitabhängigkeiten und Lizenzverhalten des ursprünglichen PC-Emulators unbekannt.

## Lokale Originale

Die folgenden Dateien wurden bytegetreu aus dem Downloads-Ordner nach `reference/originals/` kopiert. Die SHA-256-Werte ermöglichen eine spätere Identitätsprüfung. Die Dateinamen sind unverändert. Der Ordner ist von Git ausgeschlossen.

| Kürzel | Dateiname | Seiten | Bytes | SHA-256 |
|---|---|---:|---:|---|
| H | fx-87_991DEX_DE.pdf | 58 | 951982 | `24c832d5fc335f691e86d60c28b64323da8942ba42800687d1cfab419ec5531d` |
| A | FX-991DE X Bedienung und Aufgabenbeispiele.pdf | 47 | 1751372 | `13e48fc6cffd7bcb806151cb9982a30d51e6c18cc4bc3630e8052c08c52ce68c` |
| K | Kurzanleitung_FX-991DE X.pdf | 16 | 1780497 | `538acbe953cdad8306a5fa4172f180d893f28eda89bd014efb8e0407772f64b7` |

H ist die gemeinsame Bedienungsanleitung für fx-87DE X und fx-991DE X; modellspezifische Einschränkungen müssen beachtet werden. A enthält Anwendungsbeispiele und Screenshots. K enthält eine vollständige Geräteabbildung auf PDF-Seite 1 und kompakte Bedienabläufe. Für Konflikte wird zunächst H als primäre Verhaltensreferenz verwendet; Abweichungen bleiben dokumentiert und sind später am Gerät/Originalprogramm zu prüfen.

Alle Seitenbelege in unseren Dokumenten meinen physische PDF-Seiten ab 1. Bei H liegt die gedruckte Seitennummer normalerweise um eins darunter. Quellen wurden als Daten behandelt; Bedienanweisungen darin wurden nicht am lokalen System ausgeführt.

## Durchgeführte Untersuchung

- Text aller 121 PDF-Seiten mit pypdf 6.10.0 extrahiert; Seitenmarker erhalten.
- Dateigrößen, Metadaten, Seitenzahlen und SHA-256 erfasst; lokales Manifest unter `tmp/pdfs/manifest.json`.
- K PDF-Seiten 1–3 sowie H PDF-Seiten 6, 32 und 34 mit Poppler gerendert und Hauptagent-seitig visuell geprüft: vollständige Geräteabbildung, natürliche Eingabeschablonen, Moduswahl, Setup, Menübedienung, Gleichungslösungen und Wertetabelle.
- Zwei Subagenten bearbeiteten getrennt Funktionskatalog/Referenztests und Tastatur/Bedienzustände. Ergebnisse wurden vom Hauptagenten gelesen und ausgewählte kritische Werte und grafische Formeln gegen die Quellen geprüft; keine vollständige visuelle Prüfung aller 121 Seiten.

Die Textextraktion enthält Symbolfont-Zeichen, die ohne visuelle Prüfung keine zuverlässige Tastenfolge ergeben. Screenshots sind Beispiele für Anzeigen, kein Nachweis des internen Programmcodes. Die Handbücher beschreiben den Rechner; zusätzliche Funktionen des früheren PC-Emulators (Fenster, Tastaturkürzel, Export, Aufzeichnung, Dateiformate) sind damit nicht belegt.

Quellenkonflikt: A PDF-Seite 2 nennt 40 physikalische Konstanten; H PDF-Seite 46 ausdrücklich 47 vorprogrammierte wissenschaftliche Konstanten. Der Funktionskatalog verwendet den spezifischen Wert aus H. Weitere Abweichungen der Kurzunterlagen sind im Tastenkatalog festgehalten.

## Struktur nach Vorbereitung

```text
README.md                  Einstieg und Status
AGENTS.md                  Dauerhafte Arbeitsregeln
LICENSE                    Bestehende Lizenz für eigene Beiträge
docs/                      Eigene Auswertung und Planung
tools/inspect_manuals.py    Wiederverwendbare lokale PDF-Auswertung
tools/requirements.txt     Analyseabhängigkeit
reference/originals/       Unveränderte Referenzen, lokal und ignoriert
tmp/pdfs/                  Extraktion/Manifest/Prüfbilder, lokal und ignoriert
```

## Verifikation dieses Arbeitspakets

- Alle drei PDF-Kopien per SHA-256 mit den Downloads-Originalen verglichen: identisch.
- PDF-Auswertung nach der letzten Werkzeugkorrektur erneut erfolgreich ausgeführt: 58 + 47 + 16 Seiten.
- Lokalen Git-Ausschluss der drei PDFs, des Projektauftrags und des Extraktionsmanifests geprüft: aktiv; keine Referenzdatei wird bereits von Git verfolgt.
- Relative Dokumentlinks geprüft: alle Ziele vorhanden. `git diff --check`: ohne Befund.
- Keine unbekannte ausführbare Originalsoftware gestartet; kein Git-Push und keine Veröffentlichung.

## Noch ausstehende Programmanalyse

1. Bereitgestellte Installations-/Programmdateien inventarisieren, unverändert sichern und hashen; Archivverzeichnisse vor Ausführung lesen.
2. Dateisignaturen statt nur Endungen prüfen; ausführbare Dateien, Bibliotheken, Konfiguration, Ressourcen und mögliche Daten-/ROM-Dateien getrennt erfassen.
3. Bei Windows-Programmen PE-Header, Architektur, Imports, Versionsressourcen und eingebettete Manifeste auswerten. .NET-Metadaten nur prüfen, wenn vorhanden; keine Technologie vorwegnehmen.
4. Strings und Ressourcen gezielt zur Erklärung von Dateien und Schnittstellen untersuchen. Kein Schutzmechanismus wird umgangen.
5. Erst nach statischer Prüfung geeignete isolierte Laufzeitumgebung bestimmen; Startzustand, Tastenfolgen, Ausgaben und Dateizugriffe protokollieren.
6. Beobachtungen in unabhängige Verhaltenstests übersetzen. Keine Übernahme proprietärer Binärdateien, Grafiken oder Firmware in eigene Quellen.

Derzeit fehlen dafür die Original-Programmdateien. Hardwarefunktionen, PC-Emulatorfunktionen und eigene Komfortfunktionen müssen getrennte Anforderungen bleiben.
