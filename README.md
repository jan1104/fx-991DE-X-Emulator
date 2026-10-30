# Casio fx-991DE X Emulator

Eigenständiger, inoffizieller Nachbau des Bedien- und Rechenverhaltens des fx-991DE X. Die Originalsoftware soll zunächst technisch untersucht werden; eigene Implementierung und Referenzmaterial bleiben getrennt.

## Stand am 30.10.2026

Ein unabhängiger Dart-Rechenkern und eine Flutter-Oberfläche für lineare und natürliche Brucheingabe sind vorhanden. Neu ist ein unabhängiger Formatter für gekürzte Brüche und exakt endliche Dezimalzahlen mit ausdrücklichen Rückfallgründen und Ausgabegrenzen. **575 Coretests bestehen.** Der Formatter verändert noch keine Sitzung oder App. Der tatsächliche aktuelle Prüfstand steht im [Entwicklungsstand](docs/ENTWICKLUNGSSTAND.md). Die Appanbindung sieht 27 Primäraktionen in Linear und 30 in Brüche vor; ihre Ausführungsprüfung bleibt durch Windows Code Integrity blockiert. Die zuletzt bestandenen 144 App-/Mappingtests gehören zum Stand vor Quadrat und Kehrwert. Native Builds und Original-Programmdateien sind weiterhin offen.

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
- [Flutter-Oberfläche, Werkzeugstand und Buildgrenzen](docs/FLUTTER_PROTOTYP.md)
- [Plattformvergleich: Flutter, Tauri und Compose](docs/PLATTFORMWAHL.md)

Zielplattformen sind Android, iPhone/iPad, Windows, macOS und Linux. Die gemeinsame Flutter-Ansicht ist im Testengine geprüft und die fünf Plattformgerüste sind erzeugt. Native Builds und Gerätetests stehen aus.

`packages/calculator_core/` enthält den unabhängigen Core, `apps/calculator/` dessen Flutter-Oberfläche. Die umfangreichen Inventare unter `tests/reference/` bleiben Planungsdaten; sie sind nicht vollständig implementiert oder bestanden.

## Referenzen

Die unveränderten PDFs liegen unter `reference/originals/`, ihre extrahierten Texte und Prüfbilder unter `tmp/pdfs/`. Auf ausdrücklichen Nutzerwunsch vom 25.10.2026 wird der gesamte aktuelle Projektstand einschließlich dieser Dateien und des ursprünglichen Projektauftrags auf GitHub gesichert. Die MIT-Lizenz des Projekts erteilt keine Rechte an den fremden Anleitungen; deren bestehende Rechte bleiben unberührt.

Die Ignore-Regeln bleiben für neu hinzukommende Referenzen und temporäre Dateien bestehen. Der aktuell freigegebene Bestand ist ausdrücklich versioniert. Später gelieferte Original-Programmdateien werden dadurch nicht automatisch zur Veröffentlichung freigegeben. Ältere Analysedokumente beschreiben den ursprünglichen lokalen, ausgeschlossenen Stand; diese ausdrückliche Freigabe ist die spätere Ausnahme.

Für eine erneute lokale Auswertung: Python mit den Abhängigkeiten aus `tools/requirements.txt` verwenden, dann `python tools/inspect_manuals.py` ausführen. Das Werkzeug liest nur lokale PDFs, startet sie nicht und schreibt Ergebnisse ausschließlich nach `tmp/pdfs/`. PDF-Symbole können in der Textextraktion fehlerhaft erscheinen; Tasten und Formeln zusätzlich visuell prüfen.

Alle Arbeiten erfolgen zunächst lokal. Kein Push ohne ausdrückliche Freigabe.
