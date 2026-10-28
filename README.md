# Casio fx-991DE X Emulator

Eigenständiger, inoffizieller Nachbau des Bedien- und Rechenverhaltens des fx-991DE X. Die Originalsoftware soll zunächst technisch untersucht werden; eigene Implementierung und Referenzmaterial bleiben getrennt.

## Stand am 28.10.2026

Ein unabhängiger Dart-Rechenkern und eine Flutter-Oberfläche sind implementiert: exakte Brüche/Dezimalzahlen, Grundoperatoren, Klammern, ganzzahlige Potenzen, Cursor und Ans. Die Hauptansicht bietet **Linear** mit 25 aktiven Primäraktionen und **Brüche** mit 28, einschließlich Bruchvorlage und aller vier Pfeilrichtungen. Verschachtelte Bruchfelder, natürliche Eingabeanzeige und Cursor-Nachführung sind angebunden. Eine Source-Map markiert Fehlerfelder und öffnet sie per Pfeiltaste zum Bearbeiten. Beide Eingabearten behalten eigene Entwürfe und Ans; dies ist eine eigene Prototypregel. 336 Coretests und 112 App-/Mappingtests bestehen; native App-Builds sind noch offen. Original-Programmdateien liegen weiterhin nicht vor. Details, Grenzen und nächste Schritte stehen im [Entwicklungsstand](docs/ENTWICKLUNGSSTAND.md).

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
- [Flutter-Oberfläche, Werkzeugstand und Buildgrenzen](docs/FLUTTER_PROTOTYP.md)
- [Plattformvergleich: Flutter, Tauri und Compose](docs/PLATTFORMWAHL.md)

Zielplattformen sind Android, iPhone/iPad, Windows, macOS und Linux. Die gemeinsame Flutter-Ansicht ist im Testengine geprüft und die fünf Plattformgerüste sind erzeugt. Native Builds und Gerätetests stehen aus.

`packages/calculator_core/` enthält den unabhängigen Core, `apps/calculator/` dessen Flutter-Oberfläche. Die umfangreichen Inventare unter `tests/reference/` bleiben Planungsdaten; sie sind nicht vollständig implementiert oder bestanden.

## Referenzen

Die unveränderten PDFs liegen unter `reference/originals/`, ihre extrahierten Texte und Prüfbilder unter `tmp/pdfs/`. Auf ausdrücklichen Nutzerwunsch vom 25.10.2026 wird der gesamte aktuelle Projektstand einschließlich dieser Dateien und des ursprünglichen Projektauftrags auf GitHub gesichert. Die MIT-Lizenz des Projekts erteilt keine Rechte an den fremden Anleitungen; deren bestehende Rechte bleiben unberührt.

Die Ignore-Regeln bleiben für neu hinzukommende Referenzen und temporäre Dateien bestehen. Der aktuell freigegebene Bestand ist ausdrücklich versioniert. Später gelieferte Original-Programmdateien werden dadurch nicht automatisch zur Veröffentlichung freigegeben. Ältere Analysedokumente beschreiben den ursprünglichen lokalen, ausgeschlossenen Stand; diese ausdrückliche Freigabe ist die spätere Ausnahme.

Für eine erneute lokale Auswertung: Python mit den Abhängigkeiten aus `tools/requirements.txt` verwenden, dann `python tools/inspect_manuals.py` ausführen. Das Werkzeug liest nur lokale PDFs, startet sie nicht und schreibt Ergebnisse ausschließlich nach `tmp/pdfs/`. PDF-Symbole können in der Textextraktion fehlerhaft erscheinen; Tasten und Formeln zusätzlich visuell prüfen.

Alle Arbeiten erfolgen zunächst lokal. Kein Push ohne ausdrückliche Freigabe.
