# Plattformübergreifende Rechner-App

Erster Flutter-Oberflächenprototyp mit gemeinsamem Dart-Core. Die Plattformgerüste für Android, iPhone/iPad, Windows, macOS und Linux sind mit Flutter 3.47.8 erzeugt. Native App-Pakete sind noch nicht gebaut oder auf Geräten getestet.

Stand 09.11.2026: Eigene Front nach Webreferenz und gemeinsames Setup über Werkzeugleiste/SHIFT → MENU. Jetzt mit wirksamem Periodenschalter und S⇔D-Zyklus Bruch/Periode/gerundet; nur die wiederholten Ziffern tragen einen Überstrich. 50 physische Tastenplätze, 34 aktive Primäraktionen in Linear und 37 in Math. SHIFT → x² kubiert exakt in beiden Eingabearten; die sekundäre Aktion ergänzt keinen physischen Tastenplatz. Prozent über SHIFT → Ans teilt den unmittelbaren Basisausdruck exakt durch 100. SHIFT → x⁻¹ berechnet Fakultät für ganze Werte von 0 bis 69 mit exaktem Ans und gezielten Domänenfehlern. SHIFT → ×/÷ berechnet nPr/nCr mit belegten Argument- und Zwischenwertgrenzen. Der aktuelle Cloud-Lauf auf `410ecaa` bestätigt 1183 Coretests, 514 App-Tests, Web-Build und 28 Vorschauen. Beide Eingabearten teilen jetzt Ans und M pro Controller; Entwürfe und alte Ergebnisanzeigen bleiben getrennt. SHIFT → ( ist jetzt in Math mit natürlichem Betragsfeld und in Linear mit ausdrücklichem Klammerabschluss angebunden. [Core-Vertrag](../../docs/BETRAG.md), [Editorvertrag](../../docs/BETRAG_EDITOR.md). Handbuchrechnung, Betrag eines negativen Bruchs und leeres Argument wurden als Testengine-Bilder visuell geprüft. Revision und Grenzen: [Entwicklungsstand](../../docs/ENTWICKLUNGSSTAND.md), Bedienung: [PERIODEN_APP.md](../../docs/PERIODEN_APP.md), [KUBIEREN.md](../../docs/KUBIEREN.md), [PROZENT.md](../../docs/PROZENT.md), [FAKULTAET.md](../../docs/FAKULTAET.md), [KOMBINATORIK.md](../../docs/KOMBINATORIK.md).

Die natürliche `FractionExpressionView` ist über `StructuredCalculatorSession` angebunden. Beide Eingabearten behalten beim Umschalten ihre eigenen Entwürfe, Fehler und Ergebnisanzeigen. Ans und M stammen jetzt aus einem gemeinsamen exakten Speicher pro Controller; eine automatische Konvertierung der Entwürfe gibt es nicht. M+ und SHIFT → M− sind angebunden; die Statuszeile zeigt M bei belegtem Speicher. STO und RECALL sind für M angebunden. ALPHA → M+ setzt M als Operand ein. SHIFT → 9 → 2 → = setzt Ans und M nach Bestätigung zurück. SHIFT → 9 → 1 → = stellt die Setup-Standardwerte wieder her und erhält Kontrast und Speicher. [Bedienung und Speichervertrag](../../docs/STO_RECALL_M.md). Der Cursor wird innerhalb des Displays nachgeführt. Eigene Regeln und Beispiele stehen in [STRUKTURIERTE_SITZUNG.md](../../docs/STRUKTURIERTE_SITZUNG.md).

Fehler in natürlichen Feldern werden durch einen roten Marker und Feldrahmen angezeigt. Links/Rechts öffnet die markierte Stelle; AC verwirft die Eingabe. Die Fehler-Nachführung bleibt innerhalb des Displays. Zuordnungsregeln, Rückfallverhalten und Grenzen stehen in [FEHLERPOSITIONEN.md](../../docs/FEHLERPOSITIONEN.md).

Auf/Ab wechselt im Bruchmodus unmittelbar zwischen zugehörigem Zähler und Nenner, mit begrenztem logischem Tokenoffset. Hardware-Up/Down ist nur dort zugeordnet. Auch diese Pfeile öffnen nach einem Fehler zunächst die markierte Stelle. Die lineare Eingabe bleibt unverändert. Details: [VERTIKALE_NAVIGATION.md](../../docs/VERTIKALE_NAVIGATION.md).

Die zusätzliche Appaktion **Als Zähler** übernimmt während der Bearbeitung eine vollständige Zahl, Ans, einen vorhandenen Bruch oder eine geschlossene Klammergruppe unmittelbar links vom Cursor in eine neue Bruchvorlage. Die physische Taste `□/□` bleibt unverändert. Der Button ist in Ergebnis-/Fehlerphase und am Feldanfang deaktiviert; Zahlen werden am Cursor nicht aufgeteilt. Vertrag und Beispiele: [BRUCHUEBERNAHME.md](../../docs/BRUCHUEBERNAHME.md).

Die Oberfläche skaliert in der Breite und kann bei geringer Höhe vertikal gescrollt werden. Zugeordnete Hardwaretasten: Ziffern, `+ - * / ^ ( )`, Komma/Punkt, Enter, Links/Rechts, Backspace/Entf und Escape. Nicht zugeordnete Tasten und Ctrl/Alt/Meta-Kombinationen bleiben unbehandelt. Haltewiederholungen zugeordneter Ereignisse werden konsumiert, ohne weitere Rechneraktion. Tab und Space bleiben für die normale Fokus-/Buttonbedienung verfügbar. Für Ans und das eigene Vorzeichen existiert noch keine eigene Hardwarezuordnung.

## Prüfen

Framework- und Dart-Version sind in `../../tools/toolchain.json` fixiert, App-Abhängigkeiten in `pubspec.lock`. Das lokale SDK liegt unter `C:\Users\jpohl\.cache\fx991-toolchains\flutter-3.47.8`; keine globale PATH-Änderung und kein SDK im Repository.

Vom Repository aus unter PowerShell:

```powershell
./tools/test_app.ps1 -FlutterPath 'C:\Users\jpohl\.cache\fx991-toolchains\flutter-3.47.8\bin\flutter.bat'
```

Oder im App-Ordner mit dieser SDK-Version: `flutter pub get --enforce-lockfile`, `flutter analyze`, `flutter test`. Der Prüfhelfer speichert Testausgaben im ignorierten `build/reports/flutter-tests.log` des Repositorys. Dies sind Widget-/Mappingtests, keine Betriebssystem-Installationstests.

Aktuell benötigt `flutter test` wieder eine richtlinienkonform ausführbare Compilerumgebung. Der blockierte Versuch und der betroffene SDK-Pfad sind lokal unter `build/reports/square-flutter-blocked.log` dokumentiert. Nach Wiederherstellung dieser Voraussetzung zuerst den vollständigen Prüfhelfer ausführen; bestehende Vorab-Screenshots sind kein Nachweis des neuen Quadratstands.

## Lokale visuelle Vorschau

Im App-Ordner `flutter test tool/render_preview.dart` ausführen. Der explizite QA-Helfer erzeugt `build/reports/calculator-prototype.png` und `build/reports/calculator-fractions.png` im Repository bei 420×1100 und prüft jeweils das exakte Ergebnis 1/2. Für lesbare Vorschau lädt er lokal eine Systemschrift; unter Windows standardmäßig Segoe UI, alternativ Dateipfad über `PREVIEW_FONT`. Diese Schrift wird nicht in das Projekt kopiert. Die mit Flutter erzeugten Material-Icons werden aus den Testassets geladen. Die Vorschau ist keine native Anwendung und wird nicht als eigener weiterer Gerätetest gezählt.

Ein drittes Szenario desselben Helfers erzeugt `build/reports/calculator-error.png` mit `1/(2/0)`, mathematischem Fehler, markiertem innerem Nenner und Bearbeitungshinweis.

Ein viertes Szenario erzeugt `build/reports/calculator-capture.png` über `12`, **Als Zähler**, `3`, `=` mit dem Ergebnis 4. Es verwendet die zusätzliche Appaktion tatsächlich über ihren sichtbaren Button.

Ein fünftes Szenario erzeugt `build/reports/calculator-group-capture.png` über `(2+4)`, **Als Zähler**, `3`, `=` mit dem Ergebnis 2. Die Klammergruppe bleibt sichtbar als vollständiger Zähler erhalten.

Ein sechstes Quadrat-Szenario ist vorbereitet (`3`, x², x², `=` → 81), aber wegen des Compilerblocks noch nicht ausgeführt. `calculator-square.png` wurde noch nicht erzeugt oder visuell geprüft.

`flutter test tool/render_fraction_preview.dart --no-pub` erzeugt separat `build/reports/fraction-view.png` mit leerer Bruchvorlage, Bruchsumme, Verschachtelung und Pfadcursor. Das ist eine QA-Seite für den neuen Anzeigebaustein; die Rechnerroute bleibt unverändert.

## Native Builds

Die lokale Werkzeugprüfung fand noch kein Android-SDK und keine Visual-Studio-C++-Buildwerkzeuge. Deshalb stehen Windows- und Android-App-Builds aus. Nach Einrichtung der jeweiligen Werkzeuge sind `flutter run -d windows` bzw. Android-Geräte-/Buildtests möglich. macOS-/iOS-Builds benötigen einen Mac; Linux-Builds eine passende Linux-Umgebung. Die erzeugten Plattformordner allein sind kein Nachweis, dass diese Ziele getestet wurden. Die mit Flutter erzeugten Standard-Appicons sind Platzhalter für die spätere Paketierung.

Verbindlicher Entwurf: [Projektstruktur](../../docs/PROJEKTSTRUKTUR.md). Die Originalsoftware ist keine Voraussetzung für das erste eigene Grundgerüst.


## Browser-Test nach freigegebenem Push

Der Workflow `Tests and browser build` läuft nach einem freigegebenen Push oder manuell unter GitHub Actions. Nach erfolgreichen Tests und Build steht ein `fx991-browser-…`-Artefakt bereit. Das entpackte Verzeichnis per lokalem HTTP-Server bereitstellen, zum Beispiel `python -m http.server 8080 --bind 127.0.0.1 --directory <entpackter-Ordner>`, und `http://127.0.0.1:8080` öffnen. Es gibt noch kein automatisch veröffentlichtes Hosting. Neue Vorschauen werden, falls erfolgreich erzeugt, getrennt als Artefakt gespeichert. Der erste Test-/Build-Lauf ist erfolgreich erfolgt; konkrete Artefakte und Revisionen stehen im Entwicklungsstand.
