# Flutter-Oberflächenprototyp

Stand: 27.10.2026, begonnen am 26.10.2026. Ein gemeinsamer Flutter-Einstieg unter `apps/calculator/` bindet die zuvor geprüfte `CalculatorSession` an. Es wurden keine Originaldateien verändert und keine Casio-Grafiken oder Firmware in die Oberfläche übernommen.

## Umsetzung

- `lib/main.dart`: Material-App und eigenes Farbschema.
- `lib/application/key_layout.dart`: 50 eindeutige Tastenplätze mit IDs aus dem bestehenden Inventar; 25 unterstützte Primäraktionen aktiv, 25 übrige Plätze deaktiviert.
- `lib/application/keyboard_mapping.dart`: begrenzte Hardwarezuordnung mit Modifier-/Wiederholungsregeln.
- `lib/presentation/calculator/calculator_page.dart`: Anzeige, sichtbarer Cursor, Ergebnis, Ans und verständliche deutsche Fehlertexte. Kein globaler Rechnerzustand; die Sitzung gehört zur Ansicht.
- Offizielle Flutter-Plattformgerüste für Android, iOS, Windows, macOS und Linux; lokaler Core über relative Paketabhängigkeit. Keine zusätzliche direkte Laufzeitbibliothek neben Flutter und dem eigenen Core.

Die Tastenanordnung ist eine eigene, kompakte Prototypansicht und noch keine maßstabsgetreue Nachbildung des Gehäuses. Formeln erscheinen linear; Brüche als n/d. Sichtbar deaktivierte Funktionen werden nicht als implementiert ausgegeben. Header und Fußzeile kennzeichnen den Grundrechen-/Prototypumfang. Native Templates enthalten noch die Flutter-Standardicons.

## Werkzeugstand

Das SDK wurde auf den offiziellen Flutter-Release-Tag **3.47.8** fixiert: `737ba8f885dc774b53b442759999a312c9461e4e`, Engine `cf636b1dfb818dd6a3ff16e390e93b1a036969c8`, enthaltenes Dart **3.13.7**. Quelle ist ausschließlich [Flutter auf GitHub](https://github.com/flutter/flutter/tree/3.47.8), installiert außerhalb des Repositorys unter `C:\Users\jpohl\.cache\fx991-toolchains\flutter-3.47.8`. Analytics ist deaktiviert; der globale PATH blieb unverändert.

Der bisher übliche direkte Windows-Releaseindex lieferte HTTP 404; weitere direkte Archivabfragen waren nicht erfolgreich. Statt eines unbestätigten Drittanbieterpakets wurde deshalb der offizielle Tag geklont und mit dem offiziellen Flutter-Bootstrap initialisiert. Der Checkout ist absichtlich am Tag fixiert; `flutter doctor` bezeichnet den Git-Kanal daher als `[user-branch]`. Die Framework-/Dart-Versionen sind in `tools/toolchain.json` und im Prüfhelfer festgehalten. Kein unbeaufsichtigtes `flutter upgrade` ausführen.

Die Plattformdateien wurden mit `flutter create --platforms=android,ios,windows,macos,linux --project-name fx991_calculator --org dev.fx991 --no-pub .` erzeugt. Eigene vorhandene App-Quellen wurden erhalten. Der generierte Counter-Beispieltest wurde nach Prüfung entfernt; an seiner Stelle stehen passende Rechnerprüfungen. Die spätere Paket-/Store-Identität und eigene Appicons sind noch vor Veröffentlichung festzulegen.

Anleitungen: [manuelle Installation](https://docs.flutter.dev/install/manual), [Plattformintegration und Build-Hosts](https://docs.flutter.dev/platform-integration).

## Was tatsächlich getestet wurde

Abschließender Prüfhelferlauf mit Versions-/Revisionskontrolle und erzwungener Lockdatei: Formatprüfung und statische Analyse ohne Befund, **60 App-/Mappingtests bestanden**. Die 181 früheren Coretests werden getrennt geführt.

Widgettests simulieren Eingabeereignisse im Flutter-Testengine auf Windows; sie sind keine Eingabe auf einem echten Android-/Apple-Gerät.

- 50 eindeutige Bildschirmtasten, davon genau 25 aktiv und 25 deaktiviert.
- Einmalige Klickauslösung, lineare Grundrechnung, exakte Brüche und Ans-Fortsetzung.
- Fehleranzeige, AC, Cursor/DEL und atomarer Ans-Token.
- Zuordnung physischer KeyDown-/KeyUp-Ereignisse, Modifier und Wiederholungen; Enter mit Fokus auf einer Zifferntaste.
- Layoutgrößen 320×568 und 800×600 ohne Renderoverflow; nötiger vertikaler Bildlauf bleibt möglich.
- Repräsentative tatsächlich gezeichnete Tastenflächen mindestens 48 Pixel hoch und 44 Pixel breit bei der schmalen Prüfgröße.

Ein Regressionstest fand einen konkreten Fehler: Enter-KeyRepeat konnte nach einer Rechnung den gerade fokussierten Ziffernbutton über den Flutter-Standardshortcut aktivieren. Zugeordnete Wiederholungsereignisse werden jetzt am Eingabeadapter konsumiert, ohne eine neue Rechneraktion auszulösen. Der ursprüngliche Test bleibt bestehen.

Die visuelle Vorschau wurde separat bei 420×900 erzeugt und geprüft (`build/reports/calculator-prototype.png`, ignoriertes lokales Artefakt). Dabei wurden zunächst zu schmale gezeichnete Buttonflächen korrigiert und für Richtungs-/Wechselsymbole Material-Icons verwendet. Der Vorschauhelfer lädt lesbare Fonts ausdrücklich statt der normalen Ahem-Testschrift; keine Windows-Schrift wird als Projektasset verteilt. Das Bild zeigt die vollständige Tastatur und das Ergebnis `1/3+1/6 = 1/2` ohne abgeschnittene Elemente oder fehlende Icons.

Die gesonderte Vorschauerzeugung ist kein zusätzlicher allgemeiner Gerätetest. Ein anfänglich wartender Vorschauaufruf wurde beendet und die native Bildcodierung in `tester.runAsync` verlegt; danach lief der Helfer erfolgreich. Die reguläre Testsuite lädt keine Systemschrift und bleibt damit von diesem lokalen QA-Schritt unabhängig.

## Buildgrenzen und nächste Schritte

`flutter doctor -v` fand lokal kein Android-SDK und keine Visual-Studio-C++-Werkzeuge. Die jeweiligen nativen Builds sind daher noch offen. iOS/macOS und Linux wurden unter Windows nicht gebaut. Die fünf Plattformgerüste und erfolgreiche Widgettests rechtfertigen keine Aussage „auf allen Systemen getestet“.

Als nächstes: natürlichen Formeleditor-Prototyp auf dem gemeinsamen Core entwickeln und die konkreten Windows-/Android-Buildvoraussetzungen als eigenes Paket angehen. Modifier/Menüs und Speicherfunktionen bleiben weitere getrennte Pakete. Noch nicht verfügbare Geräte und Plattformen im Status sichtbar halten. Die früheren Tasten-/Funktionsinventare bleiben Planungsdaten und werden nicht pauschal als bestanden markiert.
