# Casio fx-991DE X Emulator

Eigenständiger, inoffizieller Nachbau des Bedien- und Rechenverhaltens des fx-991DE X. Die Originalsoftware soll zunächst technisch untersucht werden; eigene Implementierung und Referenzmaterial bleiben getrennt.

## Stand am 02.11.2026

Die Rechnerfront wurde anhand einer Web-Vorderansicht neu mit eigenen Widgets aufgebaut. Ein Einstellungsmenü in der Werkzeugleiste und SHIFT → MENU verwenden denselben Controller und dieselben 17 Setup-Bereiche. Math/Linear, Anzeigeformat, Bruchform, Trennung, Schriftgröße und Kontrast sind im Code angebunden; noch fehlende Modusfunktionen werden gekennzeichnet. **Statische Analyse und Formatprüfung bestehen; Ausführungs- und Sichtprüfung des neuen Standes sind offen.** Ein GitHub-Test-/Web-Build-Workflow ist lokal vorbereitet, noch nicht ausgeführt. Details: [Front und Setup](docs/FRONT_UND_SETUP.md).

Die lokale Windows-Code-Integrity-Sperre der Testprogramme bleibt unberührt. Die zuletzt bestandenen **575 Coretests gehören zu `655acd8`**, die 144 bestandenen Apptests zum Stand vor Quadrat und Kehrwert. Die neuen Fälle sind nicht ausgeführt. Tatsächlicher Prüfstatus und nächster Schritt stehen im [Entwicklungsstand](docs/ENTWICKLUNGSSTAND.md). Native Builds und Original-Programmdateien bleiben offen.

Die nächste exakte Periodenausgabe ist spezifiziert; 30 eigene Planungsreferenzen wurden mathematisch geprüft. Der Periodenformatter ist noch nicht implementiert. Der gespeicherte Entwicklungsstand bis `873c1ad` wurde am 01.11. auf ausdrücklichen Nutzerwunsch auf GitHub gesichert; neue Arbeiten bleiben zunächst lokal.

## Dokumentation

- [Bestandsaufnahme und Quellen](docs/BESTANDSAUFNAHME.md)
- [Funktionsumfang und Modellgrenzen](docs/FUNKTIONSUMFANG.md)
- [Tasten, Menüs und Bedienabläufe](docs/TASTEN_UND_BEDIENUNG.md)
- [Geplante Referenztests](docs/REFERENZTESTS.md)
- [Teststrategie für alle Tasten und Funktionen](docs/TESTSTRATEGIE.md)
- [Architekturvorschlag und Entwicklungsplan](docs/ARCHITEKTUR_UND_PLAN.md)
- [Konkrete Projektstruktur und Schnittstellen](docs/PROJEKTSTRUKTUR.md)
- [Linearer Bedienprototyp und getestete Übergänge](docs/SESSION_PROTOTYP.md)
- [Strukturierter Brucheditor im Core](docs/BRUCHEDITOR_PROTOTYP.md)
- [Bruchtaste, strukturierte Sitzung und App-Bedienung](docs/STRUKTURIERTE_SITZUNG.md)
- [Fehlerstellen und gezielte Wiederaufnahme](docs/FEHLERPOSITIONEN.md)
- [Auf/Ab zwischen natürlichen Bruchfeldern](docs/VERTIKALE_NAVIGATION.md)
- [Vorhandene Bausteine als Zähler übernehmen](docs/BRUCHUEBERNAHME.md)
- [Quadrieren: Bindung, Coreprüfung und offene Appprüfung](docs/QUADRIEREN.md)
- [Kehrwert: atomare Eingabe, Nullfall und Postfixbindung](docs/KEHRWERT.md)
- [Exakte Bruch-/Dezimalausgabe und Grenzen](docs/EXAKTE_AUSGABE.md)
- [Darstellungswahl in beiden Core-Sitzungen](docs/DARSTELLUNGSWAHL.md)
- [Geplante exakte Periodendarstellung](docs/PERIODENDARSTELLUNG.md)
- [Rechnerfront und gemeinsames Einstellungsmenü](docs/FRONT_UND_SETUP.md)
- [Flutter-Oberfläche, Werkzeugstand und Buildgrenzen](docs/FLUTTER_PROTOTYP.md)
- [Plattformvergleich: Flutter, Tauri und Compose](docs/PLATTFORMWAHL.md)

Zielplattformen sind Android, iPhone/iPad, Windows, macOS und Linux. Die gemeinsame Flutter-Ansicht ist im Testengine geprüft und die fünf Plattformgerüste sind erzeugt. Native Builds und Gerätetests stehen aus.

`packages/calculator_core/` enthält den unabhängigen Core, `apps/calculator/` dessen Flutter-Oberfläche. Die umfangreichen Inventare unter `tests/reference/` bleiben Planungsdaten; sie sind nicht vollständig implementiert oder bestanden.

## Referenzen

Die unveränderten PDFs liegen unter `reference/originals/`, ihre extrahierten Texte und Prüfbilder unter `tmp/pdfs/`. Auf ausdrücklichen Nutzerwunsch vom 25.10.2026 wird der gesamte aktuelle Projektstand einschließlich dieser Dateien und des ursprünglichen Projektauftrags auf GitHub gesichert. Die MIT-Lizenz des Projekts erteilt keine Rechte an den fremden Anleitungen; deren bestehende Rechte bleiben unberührt.

Die Ignore-Regeln bleiben für neu hinzukommende Referenzen und temporäre Dateien bestehen. Der aktuell freigegebene Bestand ist ausdrücklich versioniert. Später gelieferte Original-Programmdateien werden dadurch nicht automatisch zur Veröffentlichung freigegeben. Ältere Analysedokumente beschreiben den ursprünglichen lokalen, ausgeschlossenen Stand; diese ausdrückliche Freigabe ist die spätere Ausnahme.

Für eine erneute lokale Auswertung: Python mit den Abhängigkeiten aus `tools/requirements.txt` verwenden, dann `python tools/inspect_manuals.py` ausführen. Das Werkzeug liest nur lokale PDFs, startet sie nicht und schreibt Ergebnisse ausschließlich nach `tmp/pdfs/`. PDF-Symbole können in der Textextraktion fehlerhaft erscheinen; Tasten und Formeln zusätzlich visuell prüfen.

Alle Arbeiten erfolgen zunächst lokal. Kein Push ohne ausdrückliche Freigabe.
