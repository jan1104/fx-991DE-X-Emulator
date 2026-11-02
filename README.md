# Casio fx-991DE X Emulator

Eigenständiger, inoffizieller Nachbau des Bedien- und Rechenverhaltens des fx-991DE X. Die Originalsoftware soll zunächst technisch untersucht werden; eigene Implementierung und Referenzmaterial bleiben getrennt.

## Stand am 02.11.2026

Die Rechnerfront wurde anhand einer Web-Vorderansicht neu mit eigenen Widgets aufgebaut. Einstellungsmenü und SHIFT → MENU verwenden denselben Controller und dieselben 17 Setup-Bereiche. Math/Linear, Anzeigeformat, Bruchform, Trennung, Schriftgröße und Kontrast sind angebunden; noch fehlende Modusfunktionen werden gekennzeichnet.

Der unabhängige GitHub-Lauf für `6eb59d2` hat **756 Coretests und 342 App-/Bedientests bestanden**, die Browser-Version gebaut und zwölf separate Vorschauszenarien ausgeführt. Prozent über SHIFT → Ans ist anhand der drei Handbuchbeispiele und exaktem Ans geprüft. SHIFT → x² kubiert jetzt exakt, einschließlich verketteter Postfixe und Ans. Periodische Ergebnisse sind jetzt sichtbar: S⇔D wechselt bei Norm und eingeschalteter Periodendarstellung zwischen Bruch, exakter Periode mit Überstrich und gerundetem Dezimalwert. Der Setup-Schalter wirkt direkt; Ans bleibt exakt. Front und Periodenansicht wurden als gerenderte Testengine-Bilder geprüft. Die genaue Revision steht im [Entwicklungsstand](docs/ENTWICKLUNGSSTAND.md). Browserdateien stehen unter [GitHub Actions](https://github.com/jan1104/fx-991DE-X-Emulator/actions) bereit. Native Builds und Originalvergleich bleiben offen. Die lokale Windows-Testblockade wurde nicht verändert. Bedienung: [Front und Setup](docs/FRONT_UND_SETUP.md), [Perioden in der App](docs/PERIODEN_APP.md), [Kubieren](docs/KUBIEREN.md), [Prozent](docs/PROZENT.md).

Eigene Projektänderungen dürfen seit der Freigabe vom 02.11. selbstständig gepusht werden; automatische neue Arbeitsläufe beginnen ausschließlich alle sechs Stunden. Die bereits veröffentlichten Originalreferenzen bleiben erhalten; neue fremde Originaldateien bleiben ohne gesonderte Freigabe lokal.

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
- [Kubieren über SHIFT → x²](docs/KUBIEREN.md)
- [Prozent über SHIFT → Ans](docs/PROZENT.md)
- [Exakte Bruch-/Dezimalausgabe und Grenzen](docs/EXAKTE_AUSGABE.md)
- [Darstellungswahl in beiden Core-Sitzungen](docs/DARSTELLUNGSWAHL.md)
- [Begrenzte exakte Periodendarstellung](docs/PERIODENDARSTELLUNG.md)
- [Perioden, Setup und S⇔D in der App](docs/PERIODEN_APP.md)
- [Rechnerfront und gemeinsames Einstellungsmenü](docs/FRONT_UND_SETUP.md)
- [Flutter-Oberfläche, Werkzeugstand und Buildgrenzen](docs/FLUTTER_PROTOTYP.md)
- [Plattformvergleich: Flutter, Tauri und Compose](docs/PLATTFORMWAHL.md)

Zielplattformen sind Android, iPhone/iPad, Windows, macOS und Linux. Die gemeinsame Flutter-Ansicht ist im Testengine geprüft und die fünf Plattformgerüste sind erzeugt. Native Builds und Gerätetests stehen aus.

`packages/calculator_core/` enthält den unabhängigen Core, `apps/calculator/` dessen Flutter-Oberfläche. Die umfangreichen Inventare unter `tests/reference/` bleiben Planungsdaten; sie sind nicht vollständig implementiert oder bestanden.

## Referenzen

Die unveränderten PDFs liegen unter `reference/originals/`, ihre extrahierten Texte und Prüfbilder unter `tmp/pdfs/`. Auf ausdrücklichen Nutzerwunsch vom 25.10.2026 wird der gesamte aktuelle Projektstand einschließlich dieser Dateien und des ursprünglichen Projektauftrags auf GitHub gesichert. Die MIT-Lizenz des Projekts erteilt keine Rechte an den fremden Anleitungen; deren bestehende Rechte bleiben unberührt.

Die Ignore-Regeln bleiben für neu hinzukommende Referenzen und temporäre Dateien bestehen. Der aktuell freigegebene Bestand ist ausdrücklich versioniert. Später gelieferte Original-Programmdateien werden dadurch nicht automatisch zur Veröffentlichung freigegeben. Ältere Analysedokumente beschreiben den ursprünglichen lokalen, ausgeschlossenen Stand; diese ausdrückliche Freigabe ist die spätere Ausnahme.

Für eine erneute lokale Auswertung: Python mit den Abhängigkeiten aus `tools/requirements.txt` verwenden, dann `python tools/inspect_manuals.py` ausführen. Das Werkzeug liest nur lokale PDFs, startet sie nicht und schreibt Ergebnisse ausschließlich nach `tmp/pdfs/`. PDF-Symbole können in der Textextraktion fehlerhaft erscheinen; Tasten und Formeln zusätzlich visuell prüfen.

Eigene Projektänderungen werden lokal entwickelt und dürfen nach der ausdrücklichen Freigabe vom 02.11.2026 selbstständig gepusht werden. Automatische neue Arbeitsläufe beginnen ausschließlich alle sechs Stunden. Neue fremde Originaldateien bleiben ohne gesonderte Freigabe lokal.
