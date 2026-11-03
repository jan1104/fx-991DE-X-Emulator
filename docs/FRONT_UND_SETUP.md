# Rechnerfront und gemeinsames Setup

Stand 02.11.2026. Der Nutzer beauftragt ausdrücklich weitere Produktarbeit trotz der bekannten lokalen Testblockade: eine Front nach Webreferenz sowie ein Einstellungsmenü in der Werkzeugleiste mit denselben Einstellungen wie über die Rechnertasten. Die frühere interne Arbeitsreihenfolge, bis zur Testfreigabe keine weiteren Produktänderungen anzuhäufen, wird für dieses beauftragte Paket entsprechend angepasst. Prüfgrenzen bleiben ausdrücklich dokumentiert.

## Visuelle Referenz

Verwendet wurde die [Vorderansicht des fx-991DE X bei Conrad](https://www.conrad.at/de/p/casio-fx-991de-x-classwiz-technisch-wissenschaftlicher-rechner-schwarz-display-stellen-12-solarbetrieben-1369694.html), am 02.11.2026 aus dem Web abgerufen und tatsächlich angesehen. Die lokale Referenz liegt ignoriert unter `reference/originals/web/fx991-front.jpg`, SHA-256 `c628c1d2d16766df46f3fdc5ea66f88ef1fa6d07d45f824233bffb0c3369ed5f`. Sie ist kein Appasset und wird nicht neu in Git aufgenommen.

Die Front wird mit eigenen Flutter-Widgets gezeichnet: dunkler Körper mit silbernem Rand, Solarfeld, grünliches LCD, zentrale vier Richtungstasten, runde obere Tasten, helle Zifferntasten und blaue DEL/AC. Alle 50 vorhandenen Tasten-IDs bleiben erhalten. Goldene und magentafarbene Zweitbelegungen orientieren die Bedienung; ihre Beschriftung bedeutet keine vollständige Implementierung dieser Funktionen. Die Ansichten enthalten den Hinweis „Eigenständiger Emulator · in Entwicklung“.

Bei schmaler Breite wird vertikal gescrollt. Die Tasten erhalten mindestens 44 logische Pixel je Richtung, statt das ganze Gerät unbedienbar klein zu skalieren. Ein Öffnen des Setup über die Werkzeugleiste oder Tasten führt zum Display zurück, auch wenn vorher unten auf der Tastatur gearbeitet wurde. Aktuelle Vorschaubilder werden inzwischen durch den GitHub-Lauf erzeugt; die erste Bildprüfung fand eine separate Schriftzuordnungs-Lücke des Vorschauhelfers. Nach Korrektur wurden Front und Setup bei 420×1600 mit lesbaren Beschriftungen visuell geprüft. Die genaue Revision und Grenzen sind im [Entwicklungsstand](ENTWICKLUNGSSTAND.md) dokumentiert.

## Eine Steuerung für beide Wege

`CalculatorController` besitzt beide bestehenden Rechensitzungen und einen unveränderlichen `CalculatorSettings`-Wert. Werkzeugleistenknopf **Einstellungen** und **SHIFT → MENU** rufen denselben Menüzustand auf. Es gibt keine voneinander unabhängigen Einstellungen im Gerät und in der Werkzeugleiste.

Im Display werden jeweils bis zu vier Menüzeilen angezeigt. Berührung und Zifferntasten 1–4 wählen dieselben sichtbaren Einträge. Auf/Ab bewegen die Markierung und blättern, `=` wählt die Markierung, Links geht zurück und AC schließt ohne Änderung der Rechnung. Die sichtbare Nummerierung ist eine eigene begrenzte Listenbedienung; sie behauptet keine vollständige Gleichheit sämtlicher Original-Menüseiten.

Die vier Eingabe-/Ausgabearten, die drei Winkeleinheiten und alle 17 Setup-Bereiche aus dem vorhandenen Quelleninventar sind auswählbar. Vorgabe ist Math → Math. Die zusätzlichen Schalter Linear/Brüche unter dem Gerät verändern denselben Eingabe-/Ausgabewert. Beide Eingabearten behalten wie bisher ihre getrennten Entwürfe und Ans. Einstellungen gelten in der laufenden App; sie werden noch nicht über Neustarts hinweg gespeichert.

| Einstellung | Aktuelle vorgesehene Wirkung |
|---|---|
| Eingabe/Ausgabe | Natürlicher oder linearer Editor; Bruch- oder Dezimalwunsch bei neuen Ergebnissen |
| Zahlenformat | Fix 0–9, Sci 0–9, Norm 1/2 auf die Dezimalanzeige |
| Bruchergebnis | Unechter oder gemischter Bruch; dieselbe Auswahl über SHIFT → S⇔D |
| 1000er-Trennung | Punkte im Ganzteil der Ergebnisanzeige |
| Mehrzeilengröße | Schriftgröße der Eingabeansicht |
| Kontrast | Lesefarbe des LCD; eigene Skala 0–10 mit eigener Vorgabe 5 |
| Periodische Darstellung | Exakte Periodenansicht mit Überstrich im Norm-S⇔D-Zyklus; Aus und Fix/Sci unterdrücken den Periodenschritt |
| Winkeleinheit | D/R/G gespeichert und als Status angezeigt; Trigonometrie noch offen |
| Präfixe, komplexe Zahlen, Statistik, Tabellenkalkulation, komplexe Lösungen, Wertetabelle, QR, automatisches Ausschalten | Auswahl gespeichert; betroffene Rechen-/Ausgabefunktion noch in Vorbereitung und im Menü so gekennzeichnet |

MENU zeigt außerdem die 13 bekannten Modi; die Auswahl eines noch fehlenden Modus meldet dessen Vorbereitungsstatus und simuliert keinen Moduswechsel. ON, SHIFT-Verriegelung, SHIFT → AC als OFF, S⇔D sowie SHIFT → `=` als Dezimalwunsch sind im Appcontroller vorbereitet. SHIFT → x² ergänzt Kubieren als sekundäre Aktion; [KUBIEREN.md](KUBIEREN.md) beschreibt Bindung und Grenzen. SHIFT → Ans ergänzt Prozent; [PROZENT.md](PROZENT.md) beschreibt die Handbuchbeispiele und eigenen Grammatikgrenzen. SHIFT → x⁻¹ ergänzt Fakultät in der belegten Ganzzahldomäne 0 bis 69; [FAKULTAET.md](FAKULTAET.md) beschreibt Fehler und Arbeitsbudgets. SHIFT → ×/÷ ergänzt nPr/nCr; [KOMBINATORIK.md](KOMBINATORIK.md) beschreibt Argument- und Zwischenwertgrenzen. Weitere fehlende SHIFT-Belegungen liefern eine Meldung ohne Änderung der Rechnung; ALPHA bleibt deaktiviert. Außerhalb des Menüs sind 31 Primäraktionen in Linear und 34 in Math vorgesehen.

## Dezimalanzeige und Werteerhalt

Die neue Appanzeige berechnet Fix/Sci/Norm mit BigInt-Ganzzahldivision. Die eigene Rundungsregel ist „bei genau halbem Abstand vom Nullpunkt weg“. Norm verwendet zehn signifikante Stellen und die bereits dokumentierten Norm-Schwellen; Sci 0 bedeutet im Prototyp zehn signifikante Stellen. Ein Rundungsübertrag an der oberen Norm-Schwelle wird als wissenschaftliche Darstellung ausgegeben. Ein auf Null gerundetes negatives Ergebnis erhält kein Minus.

Das ist ausschließlich Ausgabe. Ergebnis und Ans bleiben die exakten Rationalwerte. Der bisherige reine Core-Formatter `formatRational` behält seinen Vertrag ohne Rundung; der Appcontroller verwendet einen eigenen begrenzten Anzeigepfad für den über S⇔D oder Setup gewählten Dezimalwunsch. Periodische Ergebnisse können dort gerundet angezeigt werden; der exakte Periodenformatter ist inzwischen als zusätzlicher Norm-S⇔D-Schritt angebunden; [PERIODEN_APP.md](PERIODEN_APP.md) legt Zyklus und Grenzen fest. Originale Genauigkeits-/Anzeigegrenzen sind damit nicht vollständig nachgewiesen.

## Test- und Browserweg

Lokal bestehen Formatprüfung und statische Analyse. Die ursprünglichen 28 Controllerfälle und elf Widgetfälle sind ausgeführt. Der spätere Perioden-Schritt ergänzt 50 Fälle; der anschließende Kubier-Schritt weitere 28. Der Prozent-Schritt ergänzt 24 Appfälle. Fakultät ergänzt 26 Appfälle. nPr/nCr ergänzt 30 Appfälle. Der aktuelle erfolgreiche Cloud-Lauf umfasst 869 Core- und 398 Appfälle sowie 15 separate Vorschauen. Bestehende Widgetfälle wählen ihren Eingabemodus jetzt ausdrücklich und berücksichtigen die zusätzlichen Primäraktionen. Der neue Math-Startmodus wird separat geprüft. Die bestehenden Windows-Code-Integrity-Sperren werden weder umgangen noch durch wiederholte Teststarts provoziert.

Der lokale Workflow [verify-and-build-web.yml](../.github/workflows/verify-and-build-web.yml) bereitet einen unabhängigen GitHub-Testlauf vor. Er verwendet den festgehaltenen Flutter-Tag und prüft dessen Revision, führt Core-/Apptests aus und erstellt erst danach einen Web-Build derselben Flutter-App. Die Web-Startdateien werden dabei mit dem offiziellen Flutter-Werkzeug erzeugt. Eine zusätzliche Vorschauausgabe ist vorbereitet. Es gibt keine zweite HTML-Rechnerimplementierung und kein automatisches öffentliches Hosting.

Der Workflow wurde nach ausdrücklicher Freigabe auf GitHub hochgeladen und erfolgreich ausgeführt: Core-/Apptests, Web-Build und acht Vorschauszenarien bestanden. Die erste Bildprüfung fand Platzhalter-Testschrift in der Ausgabe; deshalb wurde die Schriftzuordnung korrigiert und erneut geprüft. Genaue Revisionen, Ergebnisse und visuelle Grenzen stehen im [Entwicklungsstand](ENTWICKLUNGSSTAND.md). Die weiterhin unveränderte Windows-Sicherheitsrichtlinie betrifft die lokalen SDK-Programme und verhindert diesen unabhängigen Cloud-Test nicht.

Ein erfolgreicher Lauf stellt unter GitHub Actions ein `fx991-browser-…`-Artefakt bereit. Nach Entpacken lässt es sich über einen lokalen HTTP-Server im Browser öffnen; `index.html` per Doppelklick ist kein zuverlässiger Flutter-Web-Testweg. Native Installationspakete bleiben ein separates Arbeitspaket.
