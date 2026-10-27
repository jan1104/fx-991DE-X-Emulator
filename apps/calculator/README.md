# Plattformübergreifende Rechner-App

Erster Flutter-Oberflächenprototyp mit gemeinsamem Dart-Core. Die Plattformgerüste für Android, iPhone/iPad, Windows, macOS und Linux sind mit Flutter 3.47.8 erzeugt. Native App-Pakete sind noch nicht gebaut oder auf Geräten getestet.

Die Hauptansicht zeigt 50 Tastenplätze; 25 Primäraktionen sind aktiv und mit `packages/calculator_core` verbunden. Weitere Funktionen sind sichtbar deaktiviert. Verfügbar sind lineare Rechnung mit exakten Brüchen, Ans, Cursor, DEL/AC und lokalisierte Fehleranzeigen. Die natürliche Eingabe in der Hauptansicht, SHIFT/ALPHA, Menüs und die weiteren Rechenmodi fehlen noch.

Zusätzlich liegt eine separat prüfbare `FractionExpressionView` für die natürliche Anzeige verschachtelter Core-Bruchfelder vor. Bruchstriche, leere Felder und Pfadcursor sind enthalten; die Komponente ist noch nicht in die Hauptansicht eingebaut. Details im [Brucheditor-Prototyp](../../docs/BRUCHEDITOR_PROTOTYP.md).

Die Oberfläche skaliert in der Breite und kann bei geringer Höhe vertikal gescrollt werden. Zugeordnete Hardwaretasten: Ziffern, `+ - * / ^ ( )`, Komma/Punkt, Enter, Links/Rechts, Backspace/Entf und Escape. Nicht zugeordnete Tasten und Ctrl/Alt/Meta-Kombinationen bleiben unbehandelt. Haltewiederholungen zugeordneter Ereignisse werden konsumiert, ohne weitere Rechneraktion. Tab und Space bleiben für die normale Fokus-/Buttonbedienung verfügbar. Für Ans und das eigene Vorzeichen existiert noch keine eigene Hardwarezuordnung.

## Prüfen

Framework- und Dart-Version sind in `../../tools/toolchain.json` fixiert, App-Abhängigkeiten in `pubspec.lock`. Das lokale SDK liegt unter `C:\Users\jpohl\.cache\fx991-toolchains\flutter-3.47.8`; keine globale PATH-Änderung und kein SDK im Repository.

Vom Repository aus unter PowerShell:

```powershell
./tools/test_app.ps1 -FlutterPath 'C:\Users\jpohl\.cache\fx991-toolchains\flutter-3.47.8\bin\flutter.bat'
```

Oder im App-Ordner mit dieser SDK-Version: `flutter pub get --enforce-lockfile`, `flutter analyze`, `flutter test`. Der Prüfhelfer speichert Testausgaben im ignorierten `build/reports/flutter-tests.log` des Repositorys. Dies sind Widget-/Mappingtests, keine Betriebssystem-Installationstests.

## Lokale visuelle Vorschau

Im App-Ordner `flutter test tool/render_preview.dart` ausführen. Der explizite QA-Helfer erzeugt `build/reports/calculator-prototype.png` im Repository und prüft dabei das exakte Ergebnis 1/2. Für lesbare Vorschau lädt er lokal eine Systemschrift; unter Windows standardmäßig Segoe UI, alternativ Dateipfad über `PREVIEW_FONT`. Diese Schrift wird nicht in das Projekt kopiert. Die mit Flutter erzeugten Material-Icons werden aus den Testassets geladen. Die Vorschau ist keine native Anwendung und wird nicht als eigener weiterer Gerätetest gezählt.

`flutter test tool/render_fraction_preview.dart --no-pub` erzeugt separat `build/reports/fraction-view.png` mit leerer Bruchvorlage, Bruchsumme, Verschachtelung und Pfadcursor. Das ist eine QA-Seite für den neuen Anzeigebaustein; die Rechnerroute bleibt unverändert.

## Native Builds

Die lokale Werkzeugprüfung fand noch kein Android-SDK und keine Visual-Studio-C++-Buildwerkzeuge. Deshalb stehen Windows- und Android-App-Builds aus. Nach Einrichtung der jeweiligen Werkzeuge sind `flutter run -d windows` bzw. Android-Geräte-/Buildtests möglich. macOS-/iOS-Builds benötigen einen Mac; Linux-Builds eine passende Linux-Umgebung. Die erzeugten Plattformordner allein sind kein Nachweis, dass diese Ziele getestet wurden. Die mit Flutter erzeugten Standard-Appicons sind Platzhalter für die spätere Paketierung.

Verbindlicher Entwurf: [Projektstruktur](../../docs/PROJEKTSTRUKTUR.md). Die Originalsoftware ist keine Voraussetzung für das erste eigene Grundgerüst.
