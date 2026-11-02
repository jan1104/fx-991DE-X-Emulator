# Entwicklungsstand

## 02.11.2026 abends: Prozent über SHIFT → Ans

Ausgangsbasis `32ffbdc`, Arbeitskopie vor Beginn sauber. Der planmäßige Sechs-Stunden-Lauf nimmt das im letzten Lauf vorgeschlagene Paket auf. Die vorhandenen Quellen belegen die Belegung, die nachgestellte Prozentfunktion und die drei Rechnungen `150*20% = 30`, `660/880% = 75`, `3500-3500*25% = 2625`. Der vor der Umsetzung festgehaltene Vertrag [PROZENT.md](PROZENT.md) trennt diese Belege von eigenen Prototypregeln für gemischte Postfix-/Potenzketten. Keine vollständige Originalkompatibilität solcher Schreibweisen behauptet.

Ein Subagent ergänzte Core und 45 neue vorbereitete Corefälle, ein zweiter unabhängig 24 Controller-/Widgetfälle. Der Hauptagent verbindet SHIFT → Ans mit `ACTION_PERCENT`, ergänzt die natürliche Beschreibung „Prozent“ und eine Vorschau für das erste Handbuchbeispiel. Die neue sekundäre Aktion verändert weder die 50 physischen Tasten noch die 31/34 Primärbelegungen; das Core-Enum wächst auf 29 semantische Aktionen. Die Tests gelten vor der Cloud-Ausführung als vorbereitet. Bekannte blockierte lokale Teststarts werden nicht wiederholt und Sicherheitsrichtlinien bleiben unverändert.

Formatprüfung und statische Analyse von Core und vollständiger App bestanden. Der Hauptagent prüfte die Produktionsdiffs, Registryänderungen und neue Testannahmen. Beide Planungskatalogprüfer bestanden ebenfalls; sie führen keine Rechnungen aus. Tatsächliche Prüfungen, Revision und nächster Schritt werden nach dem GitHub-Test-/Web-Build ergänzt. Originaldateien und Werkzeugversionen bleiben unverändert; kein Hosting oder Release.

Der erste [Cloud-Lauf 41536377552](https://github.com/jan1104/fx-991DE-X-Emulator/actions/runs/41536377552) bestand 755 Corefälle und scheiterte an genau einer alten Editorfixture: `%` war dort noch als abzulehnendes Eingabetoken aufgelistet. Der Hauptagent ersetzte diesen Eintrag durch das weiterhin nicht unterstützte `!`. Die neue Prozentannahme wird bereits durch eigene Feld-/Rechentests geprüft; keine Produktionserwartung wurde abgeschwächt. Appprüfung, Web-Build und Vorschauen wurden im ersten Lauf wegen des Corefehlers korrekt übersprungen.

### Abschließender Prüfstand

[GitHub-Lauf 41536642968](https://github.com/jan1104/fx-991DE-X-Emulator/actions/runs/41536642968) für **`6eb59d2dab7dcca31060499c3046e202b9dd17b6`** bestand auf Ubuntu 24.04 vollständig: **756 Coretests, 342 App-/Controller-/Widgettests, Web-Release-Build und zwölf separate Vorschauszenarien bestanden**. Die Zahlen stammen aus dem vollständigen Joblog; der optionale Vorschauschritt wurde ausdrücklich auf Erfolg geprüft. Die 45 neuen Core- und 24 Appfälle sind darin enthalten. SDK-/Revisionskontrolle, erzwungene Lockdateien, Formatierung und statische Analyse bestanden mit unveränderten Werkzeugversionen.

Der Hauptagent lud die Vorschauen herunter und prüfte `calculator-percent.png` bei 420×1600 visuell: natürliche Formel `150 × 20%`, Ergebnis und Ans 30, Prozentbeschriftung über Ans sowie Front-/Tastentexte sind lesbar und ohne sichtbare Überlagerung. Die ungruppierte Prozentkette ist erwartungsgemäß nicht direkt als Zähler übernehmbar. Dies ist Linux-Testengine-QA, kein manueller Browser-/Geräte-/Screenreader-Test und kein Originalvergleich. Lokale Dateien liegen ignoriert unter `build/reports/github-41536642968/previews/`.

[Browser-Artefakt](https://github.com/jan1104/fx-991DE-X-Emulator/actions/runs/41536642968/artifacts/13183613675) und [zwölf Vorschauen](https://github.com/jan1104/fx-991DE-X-Emulator/actions/runs/41536642968/artifacts/13183623418) gehören genau zur genannten Revision. Die Planungskataloge und relativen Links in 31 Dokumenten wurden zusätzlich geprüft, ohne dies als weitere Rechnerfunktionstests zu zählen. Ein anschließender reiner Dokumentationscommit startet per `[skip ci]` keinen redundanten Volltest.

### Nächster Schritt

Im nächsten Sechs-Stunden-Lauf Fakultät über SHIFT → x⁻¹ als begrenztes Paket spezifizieren und prüfen. Das vorhandene Inventar belegt die Taste (H, PDF-S. 19/21/29), das Beispiel `(5+3)! = 40320` (H, PDF-S. 21) und ganzzahlige Eingaben von 0 bis 69 (H, PDF-S. 51). Vor Umsetzung müssen Domänenfehler, Ans, Postfixbindung und Größen-/Arbeitsbudgets festgelegt werden. Weitere wissenschaftliche Funktionen, Originalvergleich und native Builds bleiben getrennt offen. Kein zusätzlicher automatischer Arbeitsbeginn vor dem Zeitplan, keine neue Veröffentlichung fremder Originale, kein Hosting oder Release.

## 02.11.2026 nachmittags: Kubieren über SHIFT → x²

Ausgangsbasis `9181b7b`, Arbeitskopie vor Beginn sauber. Das nächste planmäßige Paket ergänzt die bereits belegte SHIFT-Belegung x³. Der Vertrag steht in [KUBIEREN.md](KUBIEREN.md); keine Originaldateien oder SDK-Versionen wurden verändert.

Ein Subagent ergänzte das Postfixtoken `³`, die sekundäre Aktion `ACTION_CUBE`, beide Sitzungen und 40 vorbereitete Corefälle. Ein zweiter ergänzte unabhängig 28 Controller-/Widgetfälle und prüfte die Coreänderungen lesend. Der Hauptagent prüfte die Diffs, verband SHIFT → x² mit der Aktion und ergänzte die natürliche Beschreibung „hoch drei“ sowie eine Vorschau für `3³³ = 19683`. Ein alter Test für eine weiterhin unbelegte SHIFT-Taste verwendet jetzt die tatsächlich unbelegte Potenztaste. Bestehende Registry-Erwartungen wurden gezielt um die neue semantische Aktion erweitert; die 50 physischen Tasten und 31/34 Primärbelegungen bleiben bestehen.

Postfixketten binden in Eingabereihenfolge vor normalem `^`. Negative und gebrochene Ans-Werte bleiben exakt; Fehlerphase, Cursor, DEL, Bruchfelder und Ressourcenbudgets folgen den bestehenden Verträgen. Formatierung und statische Analyse von Core und App bestanden. Keine bekannten blockierten lokalen Tests erneut gestartet. Tatsächliche Ausführung und visuelle Prüfung folgen über den bestehenden GitHub-Test-/Web-Build; bis dahin sind die neuen Fälle vorbereitet, nicht als bestanden gemeldet.

### Abschließender Prüfstand

[GitHub-Lauf 41480260905](https://github.com/jan1104/fx-991DE-X-Emulator/actions/runs/41480260905) für **`c078d7d586e6635a09e70d99193c91c8c56395b0`** bestand auf Ubuntu 24.04 mit dem unveränderten dokumentierten Werkzeugstand vollständig: **711 Coretests, 318 App-/Controller-/Widgettests, Web-Release-Build und elf separate Vorschauszenarien bestanden**. Das vollständige Joblog bestätigt die Zahlen; auch der separat behandelte Vorschauschritt ist ausdrücklich erfolgreich. Die 40 neuen Core- und 28 neuen Appfälle sind in diesen Summen enthalten. Format-/Analyseprüfung, SDK-Revisionskontrolle und erzwungene Lockdateien bestanden ebenfalls.

Der Hauptagent lud das Vorschauartefakt herunter und prüfte `calculator-cube.png` bei 420×1600: natürliche Formel `3³³`, exaktes Ergebnis und Ans 19683, lesbare Front-/Tastenbeschriftung und keine sichtbare Überlagerung. Die Ansicht markiert **Als Zähler** für die ungruppierte Postfixkette erwartungsgemäß als nicht verfügbar. Dies ist Linux-Testengine-QA, kein manueller Browser-/Gerätetest, Screenreader-Test oder Originalvergleich. Dateien liegen lokal ignoriert unter `build/reports/github-41480260905/previews/`.

[Browser-Artefakt](https://github.com/jan1104/fx-991DE-X-Emulator/actions/runs/41480260905/artifacts/13159297317) und [elf Vorschauen](https://github.com/jan1104/fx-991DE-X-Emulator/actions/runs/41480260905/artifacts/13158334702) gehören genau zur genannten Revision. Beide Planungskatalogprüfer sowie die relativen Links in 30 Dokumenten wurden zusätzlich geprüft; dies sind keine weiteren Rechnerfunktionstests. Der anschließende reine Dokumentationscommit verändert keinen Produktcode und startet per `[skip ci]` keinen redundanten Volltest.

### Nächster Schritt

Im nächsten Sechs-Stunden-Lauf ein weiteres begrenztes Paket aus dem noch offenen wissenschaftlichen Funktionsumfang spezifizieren, beispielsweise Prozent über SHIFT → Ans. Die Quellenbelegung ist vor der Implementierung anhand des vorhandenen Inventars zu prüfen. Kein zusätzlicher automatischer Arbeitsbeginn vor dem Sechs-Stunden-Zeitplan.

## 02.11.2026 vormittags: Perioden in der App und wirksamer Setup-Schalter

Ausgangsbasis `75d7abe`, Arbeitskopie vor Beginn sauber. Im nächsten planmäßigen Sechs-Stunden-Lauf wird die bereits dokumentierte Appanbindung des exakten Core-Formatters umgesetzt. Der Vertrag wurde vor der Umsetzung in [PERIODEN_APP.md](PERIODEN_APP.md) festgelegt; vorhandene PDF-Analysen wurden nicht wiederholt.

### Umgesetzt und geprüft

- Bei Norm und eingeschalteter Periodendarstellung wechselt S⇔D für periodische Werte zwischen exaktem Bruch, exakter Periode und gerundetem Dezimalwert. Endliche Werte, ganze Zahlen, Fix/Sci und Perioden-Aus behalten ihren zweistufigen Wechsel. Direkte Dezimalausgabe nach SHIFT → `=` oder über die Eingabe-/Ausgabevorgabe bleibt erhalten.
- Der vorhandene Setup-Schalter ist wirksam und nicht mehr als in Vorbereitung gekennzeichnet. Aus oder Fix/Sci normalisieren beide gespeicherten Periodenwünsche auf gerundet; Ergebnis, Ans und Editor bleiben erhalten.
- Ein unveränderliches gemeinsames Präsentationsobjekt liefert Text, Core-Komponenten, vollständig formatiertes Präfix und Rückfallgrund. Die Ansicht überstreicht genau die periodischen Ziffern und nennt die Periode assistiv. Bei zu langer Entwicklung bleibt der exakte Bruch mit Hinweis sichtbar; weitere S⇔D-Wechsel funktionieren.

Ein Subagent entwickelte Controller und 26 neue Controllerfälle, ein zweiter die Ansicht und 24 neue Widgetfälle. Der Hauptagent prüfte die Diffs und ergänzte zwei vorbereitete Vorschauszenarien für `1/6` und `-1/12`. Die bisherigen SHIFT-S⇔D-Erwartungen wurden gezielt an die nun vorgeschaltete Periode angepasst; die Prüfung weiterhin fehlender Modi bleibt bestehen. Beim Review wurde außerdem verhindert, dass ein großer ganzzahliger Wert unnötig durch den Periodenformatter läuft und dadurch statt direkter wissenschaftlicher Dezimalausgabe zunächst einen Ausgabegrenzfehler erhält. Dafür sind beide Eingabearten gezielt abgedeckt.

Normale Appanalyse ohne Befund, Formatierung über 25 Dateien erfolgreich. Keine bekannten blockierten lokalen Tests gestartet und keine SDK-/Abhängigkeits- oder Sicherheitsrichtlinien geändert. Die tatsächliche Prüfung erfolgt anschließend über den bestehenden GitHub-Test-/Web-Build und wird nach Abschluss ergänzt.

Der erste [Cloud-Lauf 41428457937](https://github.com/jan1104/fx-991DE-X-Emulator/actions/runs/41428457937) bestand den Core, scheiterte aber in vier neuen Semantikfällen am Testende: Ein mit `ensureSemantics()` angelegter Handle wurde erst im allgemeinen Tear-down und damit nach der Flutter-Abschlussprüfung freigegeben. Die konkreten Text-/Semantikerwartungen hatten davor keinen Fehler gemeldet. Der Hauptagent ersetzte ausschließlich diese Test-Aufräumstelle durch `try/finally` mit rechtzeitiger Freigabe. Produktionscode und Erwartungen wurden dafür nicht verändert oder abgeschwächt. Die übrigen 286 Appfälle bestanden bereits im ersten Lauf; Web-Build und Vorschauen wurden wegen der fehlgeschlagenen Appsuite dort korrekt übersprungen.

### Abschließender Prüfstand

[GitHub-Lauf 41429023354](https://github.com/jan1104/fx-991DE-X-Emulator/actions/runs/41429023354) für **`a9aaa7ae04f7486bef5469502e2f45d3face7f80`** bestand auf Ubuntu 24.04 mit unverändertem dokumentiertem Flutter/Dart vollständig: **671 Coretests, 290 App-/Controller-/Widgettests, Web-Release-Build und zehn separate Vorschauszenarien bestanden**. Die 50 neuen Appfälle sind darin enthalten, nicht zusätzlich zu zählen. SDK-/Revisionskontrolle, erzwungene Lockdateien, Formatierung und statische Analyse gehören zum erfolgreichen Lauf.

Der Hauptagent lud die Vorschauen herunter und prüfte `calculator-periodic.png` und `calculator-periodic-negative.png` bei jeweils 420×1600: `1/6` erscheint als `0,16` mit Überstrich nur über der 6; `-1/12` als `-0,083` mit Überstrich nur über der 3. Vorperiode und Minus sind lesbar und nicht überstrichen, der Strich ist nicht abgeschnitten. Dies ist gerenderte Linux-Testengine-QA, kein manueller Browser-/Geräte-/Screenreader-Test oder Originalvergleich. Lokale Dateien liegen ignoriert unter `build/reports/github-41429023354/previews/`.

Das [Browser-Artefakt](https://github.com/jan1104/fx-991DE-X-Emulator/actions/runs/41429023354/artifacts/13134190597) und die [Vorschauen](https://github.com/jan1104/fx-991DE-X-Emulator/actions/runs/41429023354/artifacts/13133516926) gehören genau zur genannten Revision. Der nachfolgende reine Dokumentationscommit verändert keinen Produktcode und löst per `[skip ci]` keinen redundanten Volltest aus.

### Nächster Schritt

Im nächsten Sechs-Stunden-Lauf als begrenztes Paket die bereits beschriftete SHIFT-x²-Belegung für Kubieren anhand des vorhandenen Quelleninventars spezifizieren, im Core mit eindeutiger Postfixbindung ergänzen und mit Controller-/Bedientests verbinden. Weitere SHIFT-/ALPHA-Belegungen und fehlende Rechenmodi bleiben getrennte Pakete. Kein zusätzlicher automatischer Arbeitsbeginn vor dem Zeitplan; keine neue Veröffentlichung fremder Originale oder öffentliches Hosting. Originalvergleich, native Builds und noch fehlende andere Rechnerfunktionen werden dadurch nicht ergänzt.

## 02.11.2026 früh: begrenzter exakter Periodenformatter im Core

Ausgangsbasis `c2b5d68`, Arbeitskopie vor Beginn sauber. Im planmäßigen Sechs-Stunden-Lauf wird das bereits spezifizierte nächste Paket aus [PERIODENDARSTELLUNG.md](PERIODENDARSTELLUNG.md) umgesetzt. Appcontroller, Setupbelegung, sichtbarer S⇔D-Zyklus und lokale Sicherheitsrichtlinien werden in diesem Paket nicht geändert.

### Umgesetzt und geprüft

`formatRational` ergänzt den Modus `exactRecurringDecimal`, das separate Ziffernbudget `maxGeneratedDigits`, den Rückfallgrund `expansionLimit` und das unveränderliche Ausgabeobjekt `RationalDecimalExpansion`. Exakte Restzyklen liefern kleinste Periode und Vorperiode; endliche Entwicklungen bleiben exakt dezimal. Abschluss und Restwiederholung werden vor dem Budgetabbruch geprüft. Wertebit-Summe, begrenzte Restmap und vollständiges Zeichenbudget schützen die neue Ausgabe; die bisherigen Modi behalten ihre Verträge.

Ein Subagent implementierte den Formatter und 24 neue gezielte Fälle. Ein zweiter ergänzte unabhängig einen Adapter für alle 30 vorhandenen, unverändert geplanten mathematischen Referenzen und prüfte den Produktionsdiff lesend. Der Hauptagent prüfte Code, API-Kompatibilität und Testannahmen ebenfalls. Der bestehende Ganzzahltest über alle Formate wurde gezielt um das tatsächliche endliche Format des neuen Modus ergänzt. Statische Core-Analyse und Formatierung bestanden; keine lokalen Tests wurden gestartet. Die tatsächliche Ausführungsprüfung erfolgte anschließend über den bestehenden GitHub-Test-/Web-Build; Ergebnis siehe unten.

Die 30 Planfixtures bleiben `planned`: Der neue Dart-Adapter ist die davon getrennte Implementierungsprüfung. Die 2040 zusätzlichen Rückumwandlungen in einem der gezielten Fälle sind keine zusätzlichen Einzeltests. Originalvergleich, Rundung und eine sichtbare Periodenanzeige in der App sind damit nicht abgedeckt.

### Tatsächliche Cloud-Prüfung

[GitHub-Lauf 41387340158](https://github.com/jan1104/fx-991DE-X-Emulator/actions/runs/41387340158) für **`eb53686ae7f937c76aa5d1319054a3989d49f5bf`** bestand auf Ubuntu 24.04 mit dem unveränderten dokumentierten Flutter/Dart-Stand vollständig: **671 Coretests, 240 App-/Bedientests, Web-Release-Build und acht separate Vorschauszenarien bestanden**. Die Zahlen stammen aus dem vollständigen Joblog; die 30 unabhängigen Referenzfälle wurden tatsächlich als Darttests ausgeführt. Neben den 24 neuen gezielten und 30 Referenzfällen entstehen fünf weitere Fälle durch die bestehenden Parameterprüfungen über den zusätzlichen Enumwert. Die Vorschauläufe werden nicht zu den 240 normalen Apptests addiert.

SDK-/Revisionsprüfung, erzwungene Lockdateien, Formatprüfung und statische Analyse sind Teil des erfolgreichen CI-Laufs. Die Planungskataloge wurden weiterhin getrennt geprüft. Keine neuen Abhängigkeiten oder Werkzeugversionen, keine lokale Testwiederholung und keine Änderung einer Sicherheitsrichtlinie. Appquellen und Anzeigeverhalten blieben in diesem Paket unverändert, daher wurde die bereits vorliegende manuelle Bildprüfung nicht als neue visuelle QA ausgegeben.

### Nächster Schritt

Im nächsten planmäßigen Lauf die Anbindung an den vorhandenen App-Controller und das Setup „Periodische Darstellung“ als eigenes Paket spezifizieren und prüfen: gewünschte gegenüber tatsächlicher Darstellung, S⇔D-Zyklus, Ausgabegrenzen und unverändertes Ans. Bis zu dieser Anbindung bleibt die sichtbare Periodenoption im Appmenü als in Vorbereitung gekennzeichnet. Kein zusätzlicher automatischer Arbeitsbeginn vor dem Sechs-Stunden-Zeitplan. Eigene Änderungen wurden autorisiert gepusht; nachfolgende reine Berichtspflege startet per `[skip ci]` keinen redundanten Volltest.

## 02.11.2026: Selbstständige Pushs freigegeben, Sechs-Stunden-Takt bestätigt

Der Nutzer gibt eigene Projektänderungen ausdrücklich für selbstständige Pushs frei und bestätigt, dass automatische neue Arbeitsläufe ausschließlich alle sechs Stunden beginnen sollen. AGENTS.md und die bestehende aktive Automatik wurden entsprechend aktualisiert; es wurde keine zusätzliche Automatik angelegt. Die bestehende Wiederholungsregel bleibt alle sechs Stunden. Manuelle Nutzeraufträge wie der aktuelle Push werden direkt bearbeitet. Die Freigabe umfasst eigene Quellen, Tests und Dokumentation, keine neue Veröffentlichung fremder Originaldateien oder Bereitstellung als öffentliches Hosting.

Der neue Front-/Setup-Stand und die bisher lokale Periodenplanung wurden bis `2f984b9` auf `main` gepusht. [GitHub-Lauf 41368348364](https://github.com/jan1104/fx-991DE-X-Emulator/actions/runs/41368348364) hat auf Ubuntu 24.04 mit dem festgehaltenen Flutter/Dart-Stand tatsächlich **612 Coretests, 240 App-/Controller-/Widgettests und acht separate Vorschauszenarien bestanden**; außerdem wurde die Browser-Version gebaut und als Artefakt gespeichert. Die Zahlen stammen aus dem vollständigen Joblog, die Vorschauen werden nicht zusätzlich zu den 240 normalen Apptests gezählt. Damit sind auch die vorher offenen 37 Sitzungsfälle sowie die Quadrat-/Kehrwertfälle erstmals ausgeführt. Die lokale Windows-Testblockade bleibt unverändert.

Die erste visuelle Durchsicht der heruntergeladenen Front-/Setup-PNGs fand Platzhalter-Testschrift als Kästchen, obwohl alle Abläufe bestanden. Deshalb wurde mit `9c874c7` die Appschrift ausdrücklich auf Roboto gesetzt und im Vorschauhelfer die verwendete Schrift zusätzlich als monospace registriert. Bei der zweiten Bildprüfung war das LCD lesbar, die Tastentexte verwendeten aber noch die Platzhalterschrift. Mit `e0568b9` wurde deshalb auch deren Schriftfamilie ausdrücklich festgelegt. Die heruntergeladenen Artefakte des ersten Laufs liegen lokal ignoriert unter `build/reports/github-41368348364/`.

Der abschließende [Lauf 41369221697](https://github.com/jan1104/fx-991DE-X-Emulator/actions/runs/41369221697) für **`e0568b99a032be253312961395af55d23757ccb5`** bestand vollständig: 612 Coretests, 240 Appfälle, Web-Release-Build und acht separate Vorschauszenarien. Der Hauptagent prüfte die neu heruntergeladenen Dateien `calculator-front.png` und `calculator-settings.png` bei 420×1600 tatsächlich visuell: LCD mit natürlichem `1/3+1/6=1/2`, Tastenbeschriftungen und vierzeiliges Setup sind lesbar; die gesamte Front und die zusätzlichen Eingabeschalter passen ohne sichtbare Überlagerung. Dies ist Linux-Testengine-QA, kein manueller Browser-/Gerätetest und kein Originalvergleich. Lokale Bilder liegen ignoriert unter `build/reports/github-41369221697/previews/`.

Das [Browser-Artefakt](https://github.com/jan1104/fx-991DE-X-Emulator/actions/runs/41369221697/artifacts/13108976095) und die [Vorschauen](https://github.com/jan1104/fx-991DE-X-Emulator/actions/runs/41369221697/artifacts/13108692048) gehören exakt zu dieser geprüften Revision. Der reine nachfolgende Dokumentationscommit ändert keinen Produktcode und startet per dokumentiertem `[skip ci]` keinen redundanten Volltest.

Nächste automatische Produktarbeit erst im Sechs-Stunden-Takt: anhand des nun tatsächlich geprüften Standes das nächste begrenzte Paket, beispielsweise den bereits spezifizierten exakten Periodenformatter, umsetzen und über denselben Cloud-Prüfweg testen. Die lokale Windows-Sicherheitsrichtlinie bleibt unberührt. Kein neues Hosting oder Software-Release wurde angelegt.

## 02.11.2026: Frontnaher Rechner und gemeinsames Einstellungsmenü

Ausgangsbasis `d657e39`, Arbeitskopie vor Beginn sauber. Der Nutzer fordert ausdrücklich weitere Softwarearbeit, eine Front nach einem Webbild sowie ein Einstellungsmenü oben mit denselben Einstellungen wie über die Rechnertasten. Die fehlende Originalsoftware blockiert dieses eigene Implementierungspaket nicht. Die bisherige interne Zurückstellung weiterer Produktänderungen wird damit für diesen Auftrag angepasst; die offenen Ausführungsprüfungen werden nicht als bestanden ausgegeben.

### Im Code umgesetzt

- Tatsächlich angesehene Web-Vorderansicht lokal als ignorierte Referenz gesichert. Die neue Front entsteht ausschließlich aus eigenen Flutter-Widgets: dunkles Gehäuse, silberner Rand, Solarfeld, LCD, zentrale Richtungstasten, obere Rundtasten, helle Ziffern und blaue DEL/AC. Das Foto wird kein veröffentlichtes Appasset.
- Zentrale `CalculatorController`-/`CalculatorSettings`-Steuerung. Werkzeugleiste und SHIFT → MENU öffnen dasselbe Setup. Alle 17 inventarisierten Bereiche sind auswählbar; vier sichtbare Zeilen, Berührung, Ziffern, Pfeile, `=` und AC verwenden denselben Menüzustand.
- Tatsächliche Anzeigeanbindung für Eingabe-/Ausgabeart, Fix/Sci/Norm, Bruchform, Tausendertrennung, Schriftgröße und Kontrast. Weitere noch fehlende Modi behalten gespeicherte Optionen mit sichtbarem Vorbereitungsstatus. Die Auswahl allein simuliert keine Trigonometrie, Statistik, Perioden- oder QR-Funktion.
- S⇔D, SHIFT → S⇔D, SHIFT → `=` sowie ON und SHIFT → AC werden im Controller behandelt. Die Anzeige rundet mit BigInt-Ganzzahldivision; Ergebnis und Ans bleiben exakt. Math → Math ist jetzt Startvorgabe. Vorgesehen sind 34 aktive Primäraktionen in Math und 31 in Linear, bei weiterhin 50 physischen Plätzen.
- Ein Öffnen des Menüs führt automatisch zum Display zurück, auch nach Arbeit unten auf der Tastatur. Der äußere Fokus umfasst die Werkzeugleiste. Kleine Ansichten scrollen bei mindestens 44×44 logischen Pixeln je Taste.

Details, Quellenbeleg und Grenzen: [FRONT_UND_SETUP.md](FRONT_UND_SETUP.md). Es gibt keine aktuelle gerenderte Frontvorschau und keine Behauptung vollständiger Originalkompatibilität.

### Prüfung und Korrekturen

Ein Subagent entwickelte Steuerung, Settings und 28 neue Controllerfälle; ein zweiter Front, Menüansicht und neun Widgetfälle. Der Hauptagent prüfte Produktionscode und Sollwerte lesend, ergänzte zwei weitere Widgetfälle zur Sichtbarkeit des Setup nach Scrollen und zur tatsächlichen Kontrastwirkung auf natürliche Brüche und passte sechs bestehende Widgetdateien gezielt an: explizite lineare Testausgangslage, neue Primäraktionen und weiterhin deaktiviertes ALPHA. Alte Quadrat-/Kehrwertprüfungen werden nicht durch neue Implementierungserwartungen ersetzt. Der Vorschauhelfer erhält neue Front-/Setup-Szenarien und 420×1600 als vorbereitete Größe.

Bei der Durchsicht wurden drei konkrete Verhaltensprobleme vor Abschluss korrigiert: fehlende SHIFT-Belegungen dürfen keine unbehandelte Ausnahme in der UI auslösen; SHIFT → S⇔D muss die gemeinsame Bruchform ändern; ein Norm-Rundungsübertrag an die obere Darstellungsgrenze braucht wissenschaftliche Ausgabe. Dazu wurden gezielte Fälle vorbereitet. Der Hauptagent ergänzte außerdem die automatische Sichtbarmachung des Displays beim Menüöffnen und verband die Kontrastfarbe mit dem Theme der natürlichen Formelansicht.

Die abschließende normale Appanalyse `flutter analyze --no-pub` bestand ohne Befund. Formatkontrolle: 22 Dateien ohne Änderung. Ein erster Formatierungsaufruf verwendete versehentlich repo-relative Pfade bei bereits gesetztem App-Arbeitsordner und fand keine Dateien; der korrekte Aufruf wurde nachgeholt. Es wurden keine bekannten blockierten Testprogramme erneut gestartet. Die **39 neuen App-/Controllerfälle sind vorbereitet, aber nicht ausgeführt**. Die vorher offenen 37 Core- und 57 Appfälle bleiben ebenfalls unausgeführt; frühere 575 Core-/144 App-Ergebnisse sind weiterhin ausschließlich historische Prüfstände. Keine neuen nativen Builds oder visuelle QA behauptet.

### Konkreter unabhängiger Testweg

Der lokale GitHub-Actions-Workflow `.github/workflows/verify-and-build-web.yml` verwendet die dokumentierte Flutter-Version samt Revisionsprüfung, validiert Referenzpläne und führt die vollständigen Core-/Appsuiten aus. Anschließend erzeugt das offizielle Flutter-Werkzeug den Web-Einstieg derselben App; ein erfolgreicher Web-Build wird als herunterladbares Artefakt gespeichert. Eine zusätzliche Vorschauausgabe ist vorbereitet. Es gibt keine zweite HTML-Rechnerimplementierung und kein automatisches Hosting. Die verwendeten GitHub-Actions-Versionen sind auf die anhand offizieller Tagrefs geprüften Commit-IDs festgelegt.

Der Workflow wurde noch nicht hochgeladen oder ausgeführt. Ein lokaler Versuch, YAML mit Python zu parsen, scheiterte am fehlenden optionalen `yaml`-Modul; keine zusätzliche Abhängigkeit wurde dafür installiert. Die Workflowdatei wurde lesend geprüft. Katalog-, Planungsdaten-, Dokumentlink- und Diffprüfungen ergänzen die verfügbaren Prüfungen. Eine erfolgreiche Cloud-Ausführung, Browserdatei oder neue Vorschau existiert noch nicht.

### Nächster Schritt

Nach ausdrücklicher Freigabe dieses neuen Pushs den konkreten Testworkflow auf GitHub ausführen, tatsächliche Fehler beheben, Browserartefakt und Front-/Setup-Vorschauen prüfen und dem Nutzer den testbaren Stand bereitstellen. Bis dahin keine Cloud-Ergebnisse behaupten und die unveränderte lokale Sicherheitsrichtlinie nicht umgehen. Neue Originalreferenz bleibt lokal; kein neuer Push in diesem Arbeitspaket.

## 01.11.2026: Periodenausgabe spezifiziert und Planungsreferenzen geprüft

Ausgangsbasis `873c1ad`, Arbeitskopie vor Beginn sauber. Der Nutzer ließ die bis zu diesem Commit gespeicherten 14 Entwicklungscommits am 01.11. ausdrücklich auf GitHub sichern; der Push auf `main` wurde bestätigt. Das folgende neue Planungspaket bleibt lokal und wird dadurch nicht automatisch erneut zur Veröffentlichung freigegeben.

### Abgeschlossenes Planungspaket

- [PERIODENDARSTELLUNG.md](PERIODENDARSTELLUNG.md) legt den zukünftigen Modus `exactRecurringDecimal` fest: eigene Klammernotation, Vorperiode und kleinste Periode, endlicher Abschluss, strukturierte Ausgabe und exakte unveränderte Werte.
- Die Reihenfolge von Restabschluss, Zykluserkennung und Budgetprüfung ist festgelegt, einschließlich Erfolg genau am Ziffernrand. Getrennte Ziffern-, Wertegrößen- und Zeichenlimits begrenzen Arbeit und Speicher. Der vorhandene endliche Modus wird nicht stillschweigend geändert.
- 30 ausschließlich geplante eigene Sollfälle unter `tests/reference/formatting/recurring_decimal_planned.json`. Sie bleiben vom vorhandenen Tastenszenarioschema und den Original-Inventaren getrennt. Es gibt in diesem Paket keine neue Dart-Implementierung, Appanbindung oder Tastenbelegung.

Ein Subagent schrieb den Vertrag, ein zweiter die unabhängigen Sollfälle und deren Planvalidator. Der Hauptagent prüfte beide, legte die additive API-Signatur und den zukünftigen DTO-Typ abschließend im Entwurf fest und ergänzte die Zuordnung zwischen Plan-JSON und DTO. Die mathematische Referenz rekonstruiert den Wert mit geschlossenen Bruchformeln aus den vorgegebenen Ziffern; sie berechnet die Ziffern nicht mit dem geplanten Produktalgorithmus.

### Tatsächliche Prüfung

Der neue Python-Prüfer `tools/check_recurring_decimal_plan.py` bestätigte abschließend die mathematische Konsistenz und Budgetmetadaten aller **30 Planfixtures**. Dies sind keine bestandenen Produktfälle. Der Hauptagent fand vor Abschluss drei Prüflücken: uneinheitlicher Formatname, fehlende Prüfung der kürzesten Vorperiode und unzureichende Nullkanonisierung. Diese wurden korrigiert. Sechs flüchtige absichtlich fehlerhafte Kopien wurden vom Subagenten erwartungsgemäß mit `ValueError` zurückgewiesen; sie werden nicht als neue Produkt- oder Referenzfälle gezählt oder gespeichert. Der Hauptagent ergänzte zusätzlich die Prüfung der Plan-Schemaversion.

Der bestehende Katalogprüfer bestand unverändert: 50 Tasten, 243 Funktionspositionen, fünf Beispielabläufe und 56 Handbuchfall-IDs, weiterhin ausschließlich Planung. Lokale Dokumentlinks und Diffkontrolle wurden ebenfalls geprüft.

Keine blockierten Dart-/Flutter-Teststarts wiederholt, keine SDK- oder Sicherheitsrichtlinien geändert und keine neue Laufzeitprüfung behauptet. Die 37 Sitzungsfälle und 57 Appfälle bleiben unausgeführt. Die letzten bestandenen 575 Coretests gehören weiterhin zu `655acd8`, die 144 Apptests zum Stand vor Quadrat und Kehrwert. Original-Programmdateien und native Builds bleiben offen.

### Nächster Schritt

Nach einer nachweislichen Änderung der ausführbaren Testumgebung zuerst die offenen Sitzungs-/Gesamttests nachholen. Danach lässt sich der spezifizierte Periodenformatter als begrenztes reines Core-Paket mit den unabhängigen Planreferenzen implementieren und tatsächlich prüfen. Bis dahin keine weiteren ungeprüften Produktänderungen auf diese offene Prüfgrundlage stapeln und keine wiederholten blockierten Teststarts. Neue Originale weiterhin lokal halten; kein neuer Push.

## 31.10.2026: Darstellungswahl vorbereitet, neuer Core-Testblock

Ausgangsbasis `655acd8`, Arbeitskopie vor Beginn sauber. Das nächste dokumentierte Paket verbindet die exakte Ausgabe mit einer ausdrücklichen Wahl in beiden Core-Sitzungen. Der Vertrag wurde zuerst in [DARSTELLUNGSWAHL.md](DARSTELLUNGSWAHL.md) festgelegt. **Die neue Anbindung ist vorbereitet und statisch geprüft; ihre Ausführungsprüfung bleibt offen.**

### Vorbereitet

- Beide Snapshots erhalten `resultDisplayFormat` und den bedarfsweisen Textabruf `formatResult()`. `selectResultDisplayFormat(...)` verändert ausschließlich die gewünschte Darstellung eines vorhandenen Ergebnisses.
- Gleiche Wahl sowie Wahl während Bearbeitung/Fehler sind identische No-ops. Neue Bearbeitung oder Auswertung beginnt wieder im Bruchformat. Vorhandene Ergebnis-No-ops behalten die Wahl.
- Gewünschtes Dezimalformat bleibt auch bei tatsächlicher Bruchausgabe erhalten. Textabruf und mögliche Ausgabeprobleme sollen Ergebniswert, Ans, Editor und Fehlerphase unverändert lassen. Auswahl selbst formatiert nicht.

Keine Appänderungen, zusätzlichen physischen Belegungen oder SDK-/Abhängigkeitsänderungen. S⇔D, Periodendarstellung und originale Rundungsregeln sind dadurch nicht implementiert. Die bisherigen 27/30 Primäraktionen bleiben unverändert.

### Tatsächlicher Prüfstatus und neuer Block

Ein Subagent bereitete den Produktionscode und 37 neue Fälle unter `packages/calculator_core/test/session_display_test.dart` vor. Ein zweiter prüfte unabhängig den Vertrag und die Produktionsdiffs lesend, ohne konkreten Befund. Der Hauptagent prüfte die Änderungen ebenfalls lesend. Die Fälle sind für Werteerhalt, alte Snapshots, Phasen-/No-op-Regeln, echte Bruch-/Dezimaltexte, Ausgabeprobleme, Fehlerziele und unabhängige Sitzungen geschrieben; **kein neuer Fall wurde ausgeführt**.

Der erste gezielte Testaufruf mit dem bisher verwendeten Dart 3.13.7 scheiterte bereits vor Testausführung: `ProcessStarter::StartForExec failed`, Windows meldete eine blockierende Anwendungssteuerungsrichtlinie; Werkzeug-Exitcode −1. Die Prozessmeldung allein nennt keine konkrete Datei. Der Hauptagent bestätigte lesend im Protokoll `Microsoft-Windows-CodeIntegrity/Operational` die zeitgleichen Ereignisse 3077/3033 am 31.10.2026 um 19:01:13: Der portable SDK-Prozess `dart.exe` versuchte `dartvm.exe` aus demselben SDK zu laden; Signatur-/Integritätsanforderungen der Richtlinie wurden nicht erfüllt. Daraus wird kein konkretes Sicherheitsprodukt oder Grund der neuen Blockierung abgeleitet.

Lokale ignorierte Belege: `build/reports/session-display-blocked.log` mit Testaufruf und Prozessmeldung sowie `build/reports/session-display-code-integrity.log` mit der lesenden Ereignisabfrage. Kein Wiederholungsversuch, alternativer Testlauf, SDK-Umbau oder Eingriff in Sicherheitsrichtlinien. Der vollständige Core-Prüfhelfer wurde wegen des bereits belegten Blocks nicht gestartet.

Die separate normale statische Analyse `dart analyze packages/calculator_core` bestand nach Korrektur einer Warnung zu einem ungenutzten privaten optionalen Parameter ohne Befund. Die abschließende Formatkontrolle des Subagenten meldete drei Dateien ohne Änderung. Diese Schritte ersetzen keine Testausführung. Lokale Dokumentlinkprüfung und Diffkontrolle bestanden.

Die **575 bestandenen Coretests gehören ausschließlich zum Vorgängerstand `655acd8`**. Für den neuen Stand wird keine bestandene Core-Gesamtzahl angegeben. Die bereits offenen 25 Quadrat- und 32 Kehrwert-Widgetfälle wurden ebenso nicht ausgeführt; 144 bestandene Apptests gehören zum Stand vor diesen beiden Tasten. Keine neue Vorschau, kein nativer Build und kein Originalvergleich.

### Nächster Schritt

Sobald eine richtlinienkonform ausführbare Umgebung vorhanden ist, zuerst die 37 vorbereiteten Sitzungsfälle und den vollständigen Core-Prüfhelfer ausführen; danach die bereits offenen Appfälle und Vorschauen nachholen. Ohne diese Umgebungsänderung keine wiederholten blockierten Teststarts. Unabhängig davon ist eine begrenzte exakte Periodendarstellung zunächst spezifizierbar: Vorperiode/Periode, Restzykluserkennung und getrennte Arbeits-/Ausgabegrenzen. Die Appanbindung bleibt zurückgestellt. Originaldateien und Sicherheitsrichtlinien unverändert, kein Push.

## 30.10.2026 vormittags: unabhängige exakte Ausgabeformatierung

Ausgangsbasis `d8aa34e`, Arbeitskopie vor Beginn sauber. Das dokumentierte nächste Paket trennt die Ausgabeformatierung von Rechenwerten und Bedienzuständen. Der Vertrag wurde zuerst in [EXAKTE_AUSGABE.md](EXAKTE_AUSGABE.md) festgelegt, anschließend der begrenzte Core-Dienst implementiert. Es gab keine erneute PDF-Gesamtanalyse.

### Neu umgesetzt

- Öffentliche reine Funktion `formatRational` und unveränderliches `RationalDisplay`: gekürzter Bruch oder exakt endlicher Dezimaltext mit deutschem Komma, ausdrücklich ausgewiesenem tatsächlichem Format und optionalem Rückfallgrund.
- Prüfung des gekürzten Nenners auf Faktoren 2 und 5. Nicht endliche Entwicklungen bleiben Brüche mit Grund `periodic`; zu viele erforderliche Stellen führen zum Grund `decimalPlacesLimit`. Die dokumentierte frühe Budgetentscheidung hat Vorrang vor noch ungeprüften periodischen Restfaktoren.
- Keine Gleitkommaumwandlung oder Rundung. Stellenbudget 0–1000, Zeichenbudget 1–10000, standardmäßig 100/2048. Das Zeichenbudget umfasst auch Vorzeichen, Komma und Bruchstrich sowie Rückfalltexte. Vorabprüfungen begrenzen den Textaufbau auch für große öffentliche Rationalwerte außerhalb der Evaluatorgrenzen.

Die vorhandenen Sitzungen, Tastenzuordnungen, Appdateien und deren 27/30 Primäraktionen bleiben in diesem Paket unverändert. Der Dienst bindet noch keine S⇔D-Taste an. Originaler Perioden-/Dezimalzyklus, Fix/Sci/Norm, Rundung und gemischte Brüche sind ausdrücklich nicht abgedeckt.

### Prüfung

Ein Subagent implementierte den Dienst und 59 neue Corefälle. Ein zweiter prüfte unabhängig Quellenabgrenzung, feste mathematische Sollwerte und anschließend den Produktionscode lesend. Der Review fand keinen konkreten Rechen- oder Ressourcenfehler; sein Hinweis zur Priorität der Rückfallgründe wurde in die öffentliche API-Dokumentation aufgenommen. Der Hauptagent prüfte Code, Tests und Dokumentlinks.

Feste Solltexte umfassen unter anderem `3/40→0,075`, `7/250→0,028`, `-1/8→-0,125` und große Zähler jenseits der Gleitkommagenauigkeit. Die Tests trennen das Maximum der Faktorenexponenten von deren Summe, prüfen beide Rückfallgründe und die Parameter-/Zeichenränder bis 1000 Nachkommastellen und 10000 Ausgabezeichen. 343 zusätzliche exakte Rückumwandlungen liegen innerhalb eines Tests und werden nicht als 343 Einzeltests gezählt. Beide Sitzungsmodelle behalten nach Formatierung einschließlich Ausgabeproblemen ihren exakten Ergebniswert, Ans und Bearbeitungszustand.

Abschließender vollständiger Core-Prüfhelfer mit Dart 3.13.7 auf Windows: SDK-Vergleich und erzwungene Lockdatei erfolgreich, 25 Dateien ohne Formatänderung, statische Analyse ohne Befund und **575 Coretests bestanden**. Der vorherige gezielte Lauf mit 59 Fällen wird nicht addiert. Log lokal unter `build/reports/core-tests.log`.

Keine App-Ausführung, App-Neuanalyse oder Vorschau wurde in diesem reinen Core-Paket vorgenommen. Der bekannte Windows-Code-Integrity-Block wurde nicht erneut provoziert oder umgangen. Die 25 Quadrat- und 32 Kehrwert-Widgetfälle bleiben nicht ausgeführt; 144 bestandene Apptests gehören weiterhin zum Stand vor diesen beiden Tasten. Native Builds und Originalvergleich bleiben offen.

### Nächster Schritt

Die ausdrückliche Darstellungswahl in beiden Sitzungsmodellen spezifizieren und mit unverändertem exaktem Ergebnis/Ans sowie Ergebnis-, Bearbeitungs- und Fehlerphasen prüfen. Die Appanbindung zurückstellen, bis eine richtlinienkonform ausführbare Flutter-Testumgebung verfügbar ist; dann die bestehenden offenen Appfälle und Vorschauen zuerst nachholen. Originaldateien und SDKs bleiben unverändert, kein Push.

## 30.10.2026: Kehrwerttaste mit atomarem Zwei-Zeichen-Token

Ausgangsbasis `796831a`, Arbeitskopie vor Beginn sauber. Das nächste dokumentierte Arbeitspaket ergänzt `KEY_RECIPROCAL` unabhängig von der weiterhin blockierten Flutter-Testausführung.

### Neu umgesetzt

- Der Lexer erkennt `⁻¹` als einen zusammenhängenden Postfixoperator mit korrekten UTF-16-Positionen. Quadrat und Kehrwert werden in Eingabereihenfolge aufgebaut; normale Potenzen bleiben rechtsassoziativ. Der unveränderte exakte Evaluator berechnet den Exponenten −1 und meldet bei Null einen mathematischen Fehler.
- Beide Sitzungen und der natürliche Editor behandeln das Token atomar. Nach Ergebnis startet die Taste `Ans⁻¹`, während der Bearbeitung erfolgt normale Cursoreinfügung. Ohne Basis entsteht erst bei `=` ein Syntaxfehler. Fehlerfreeze, Ans-Erhalt und gezielte Wiederaufnahme bleiben erhalten.
- Das gemeinsame Register aktiviert im vorbereiteten Appcode 27 Primäraktionen in Linear und 30 in Brüche bei weiterhin 50 physischen Plätzen. Die natürliche assistive Beschreibung nennt das Token „Kehrwert“. Es gibt kein neues Hardwarekürzel.

Vertrag, Beispiele und Grenzen stehen in [KEHRWERT.md](KEHRWERT.md). Bestehende Quellenbelege H 19/21/29 werden verwendet, ohne die abgeschlossene PDF-Gesamtanalyse zu wiederholen. SHIFT-Fakultät, ALPHA-C und die Hexadezimalbelegung bleiben offen. Ganze Postfixketten werden weiterhin nicht automatisch als Zähler übernommen.

### Prüfung

Ein Subagent implementierte den Core samt 54 neuen Fällen; ein zweiter bereitete unabhängig 32 Widgetfälle vor und passte ausschließlich aktuelle Inventarzähler in fünf vorhandenen App-Testdateien an. Der Hauptagent ergänzte die Semantik und prüfte Produktions- und Testdiffs. Die neuen Corefälle prüfen insbesondere AST-Reihenfolge, exakte negative Bruchwerte, beide Zeichenoffsets desselben Tokens, anschließende Syntaxpositionen, atomaren DEL, Nullfehler und Source-Map-Wiederaufnahme. Zeichenlänge, Lexertokenzahl, Editorknotenzahl und Auswertungstiefe werden getrennt geprüft.

Eine neue Core-Testannahme erwartete zunächst `4^2⁻¹=2`. Der bestehende rationale Evaluator unterstützt nichtganzzahlige Exponenten jedoch ausdrücklich noch nicht; der Test wurde auf diesen vorhandenen Vertrag korrigiert. Keine Wurzelfunktion oder Sonderbehandlung wurde dafür hinzugefügt.

Abschließender vollständiger Core-Prüfhelfer mit Dart 3.13.7 auf Windows: SDK-Vergleich und erzwungene Lockdatei erfolgreich, 23 Dateien ohne Formatänderung, statische Analyse ohne Befund und **516 Coretests bestanden**. Der direkte Subagentenlauf wird nicht addiert. Log lokal unter `build/reports/core-tests.log`.

Der normale Aufruf `flutter analyze --no-pub` bestand ohne Befund. Die neue Widgetdatei wurde formatiert; die abschließende App-Formatkontrolle meldete 17 Dateien ohne Änderungen. Ein erster Formatierungsaufruf verwendete versehentlich repo-relative Pfade bei bereits gesetztem App-Arbeitsordner und fand keine Dateien; der korrekte Aufruf wurde nachgeholt. Diese statischen Prüfungen führen keine Widgetfälle aus.

Der am 29.10. dokumentierte Windows-Code-Integrity-Block des Flutter-Testcompilers wurde nicht erneut provoziert oder umgangen. **32 neue Kehrwertfälle und 25 Quadratfälle sind vorbereitet, aber nicht ausgeführt; die aktuelle vollständige Appsuite ist offen.** Die zuletzt bestandenen 144 Apptests gehören zum Vorgängerstand vor Quadrat und Kehrwert. Es wurde keine neue Vorschau erzeugt und keine neue visuelle Prüfung behauptet. Katalogprüfung (50 Tasten, 243 Funktionspositionen, fünf Beispielabläufe, 56 Handbuchfall-IDs), Dokumentlinks und Diffkontrolle ergänzen die tatsächlich ausführbaren Prüfungen.

### Nächster Schritt

Sobald eine richtlinienkonform ausführbare Flutter-Testumgebung vorhanden ist, Quadrat-/Kehrwertfälle, vollständigen App-Prüfhelfer und Vorschauen zuerst nachholen. Unabhängig davon eine ausdrücklich ausgelöste exakte Bruch-/Dezimalanzeige spezifizieren: endliche gegenüber periodischen Dezimalbrüchen, verlustfreier Ans-Erhalt und Ausgabegrenzen vor der Implementierung festlegen. Kubieren/SHIFT, allgemeine Exponentenfelder, native Builds und Originalvergleich bleiben offen. Keine Originaldateien oder SDKs verändert, kein Push.

## 29.10.2026: Quadriertaste mit expliziter Postfixbindung

Ausgangsbasis `97bc352`, Arbeitskopie vor Beginn sauber. Das dokumentierte nächste Arbeitspaket bindet die vorhandene physische x²-Taste in beiden Sitzungen und der Hauptansicht an.

### Neu umgesetzt

- Eigenständiger Postfixoperator `²` im vorhandenen Lexer/Parser. Wiederholungen werden links aufgebaut; `3²²` ergibt 81. Die bestehenden normalen Potenzen bleiben rechtsassoziativ. Der bestehende exakte Evaluator wird unverändert wiederverwendet.
- `CalculatorKey.square` und strukturiertes Texttoken. Nach Ergebnis beginnt die Taste mit exakt gebundenem `Ans²`; während der Bearbeitung fügt sie `²` am Cursor ein. Ohne Basis entsteht erst bei `=` ein Syntaxfehler.
- Das Register löst im vorbereiteten Appcode 26 Primäraktionen in Linear und 29 in Brüche auf; weiterhin 50 physische Plätze. Eigene Appaktionen und Hardwarezuordnung bleiben getrennt. Die natürliche Semantik nennt den Operator „zum Quadrat“. Die praktische Appprüfung dieses Standes ist noch offen.

Die Operandbindung und Grenzen sind in [QUADRIEREN.md](QUADRIEREN.md) dokumentiert. Der vorhandene Quellenbefund H 19/29 und Referenzfall K02 werden verwendet; es findet keine erneute Gesamtanalyse der PDFs statt.

### Prüfung

Ein Subagent implementierte Parser und Sitzungen samt 43 neuen Coretests; ein zweiter schrieb 25 neue Widgetfälle und passte vier bestehende App-Inventarerwartungen gezielt an. Die Coretests trennen insbesondere `-2²=-4`, `(-2)²=4`, `3²²=81`, `2^3²=512` und `2²^3=64`. K02 ist als mathematische Projektion ergänzt, ohne einen Original-Display-/Setupvergleich zu behaupten. Zwei neue Testannahmen wurden präzisiert: Ein Größenlimit wird erst beim elften Quadrat erreicht; ein Cursoroffset war durch die bestehende vertikale Navigation bereits auf 1 geklemmt. Der Produktionscode bestand danach unverändert.

Abschließender vollständiger Core-Prüfhelfer mit Dart 3.13.7 auf Windows: SDK-Vergleich und erzwungene Lockdatei erfolgreich, 22 Dateien ohne Formatänderung, statische Analyse ohne Befund und **462 Coretests bestanden**. Der vorherige direkte Subagentenlauf wird nicht addiert. Log lokal unter `build/reports/core-tests.log`.

Der Versuch des gezielten Widgettests scheiterte bereits beim Laden vor der Testausführung: Windows blockierte das Flutter-SDK-Programm `dartaotruntime.exe`, das den `frontend_server_aot.dart.snapshot` starten sollte. Der hängende Testloader wurde beendet. Der Hauptagent bestätigte den Vorgang lesend im Ereignisprotokoll `Microsoft-Windows-CodeIntegrity/Operational`: Ereignisse 3077 und 3033 am 29.10.2026 um 02:06:45. Daraus wird weder eine genaue Ursache der neuen Blockierung noch ein konkretes Windows-Sicherheitsprodukt abgeleitet. Die Richtlinie und SDK-Dateien bleiben unverändert. Fehlerbeleg lokal unter `build/reports/square-flutter-blocked.log`.

Eine abschließende Diffkontrolle fand außerdem eine unbeabsichtigte globale `e`→`x`-Ersetzung in einer bestehenden App-Testdatei. Ursache war ein einzelnes Ersetzungspaar, das das PowerShell-Skript des Subagenten als zwei einzelne Strings statt als Paar behandelte. Der Hauptagent stellte ausschließlich diese eigene Testdatei aus der sauberen Ausgangsbasis wieder her und änderte nur den erwarteten Zähler 28→29. Die anderen App-Diffs wurden gezielt geprüft. Das ist ein korrigierter Testbearbeitungsfehler, kein gemessener Produktfehler.

Nach dieser Korrektur bestand die unabhängige App-Formatprüfung mit dem vorhandenen Dartformatter (16 Dateien, unverändert) sowie der normale Aufruf `flutter analyze --no-pub` ohne Befund. Dieser statische Prüfschritt benötigt keinen Start des blockierten Testcompilers und ersetzt keine Widgettests. Die **25 neuen Widgetfälle und die aktuelle vollständige Appsuite sind nicht ausgeführt**; die 144 bestandenen Apptests des Vorgängerstands werden nicht als Ergebnis dieses Standes ausgegeben. Der erweiterte Vorschauhelfer wurde nicht ausgeführt, eine Quadratvorschau nicht erzeugt und keine neue visuelle Prüfung behauptet. Katalog- und lokale Dokumentlinkprüfung ergänzen die verfügbaren Prüfungen.

### Nächster Schritt

Sobald eine richtlinienkonform ausführbare Flutter-Testumgebung wieder vorhanden ist, zuerst die vorbereiteten Appfälle, den vollständigen App-Prüfhelfer und die neue Vorschau nachholen. Bis dahin ist unabhängig davon die Kehrwerttaste im Core mit Definitionsbereich, Nullfall und klarer Operandbindung das nächste begrenzte Arbeitspaket. Kubieren/SHIFT, weitere Belegungen, freie natürliche Exponentenfelder, native Builds und Originalvergleich bleiben offen. Kein Push und keine Originaldateien verändert.
## 28.10.2026 abends: geschlossene Klammergruppen als Zähler übernehmen

Ausgangsbasis `8524099`, Arbeitskopie vor Beginn sauber. Die vorhandene explizite Appaktion **Als Zähler** übernimmt nun zusätzlich eine geschlossene Klammergruppe direkt links vom Cursor.

### Neu umgesetzt

- Rückwärtssuche nach der passenden Textklammer ausschließlich im aktuellen Feld; enthaltene Bruchknoten bleiben atomar, verschachtelte Textgruppen samt Originalklammern erhalten.
- Übernahme der gesamten Gruppe in den Zähler einer neuen Vorlage mit leerem Nenner. Präfix, Suffix und äußere Vorzeichen/Operatoren bleiben außerhalb.
- Atomare Syntaxablehnung nicht geschlossener und inhaltloser Gruppen; die bestehende Knoten-/Gesamttiefenprüfung gilt unverändert für alle übernommenen Unterbäume.
- Die App erklärt die zusätzliche Klammergruppenunterstützung. Button, Aktivierungsphasen, physische Bruchtaste und 28/25 aktive Primärbelegungen bleiben unverändert.

Dies ist weiterhin eine eigene begrenzte Editorregel. Eine balancierte, aber arithmetisch unfertige Gruppe wie `(1+)` bleibt übernehmbar und erzeugt erst bei `=` den bisherigen Syntaxfehler. Es gibt keine Vorabauswertung oder automatische Potenz-/Vorzeichenauswahl. Vertrag und Beispiele stehen in [BRUCHUEBERNAHME.md](BRUCHUEBERNAHME.md).

### Prüfung

Ein Subagent erweiterte den Core samt 37 gezielten Tests; ein zweiter ergänzte 15 unabhängige UI-Fälle. Der bisher in der UI explizit abgewiesene gültige Gruppenfall bleibt entsprechend der bewusst erweiterten Spezifikation als Erfolgsfall erhalten; im Core wurde eine überholte Ablehnungszeile entfernt. Die sonstige Ablehnungsabdeckung bleibt bestehen. Geprüft werden insbesondere verschachtelte Gruppen, enthaltene Brüche, erhaltene Nachbarn, Source-Map-Ziele nach der Übernahme, beide Schutzgrenzen und 320-Pixel-Layout. Ein zusätzlicher Read-only-Review der UI-Textänderung meldete keinen konkreten Befund.

Im ersten neuen Source-Map-Test war eine erwartete Projektionsklammer falsch gezählt; die Testannahme wurde korrigiert, der Produktionscode blieb dafür unverändert. Die Fälle für arithmetisch unvollständige Gruppen prüfen ausdrücklich den späteren Syntaxfehler und dessen Bearbeitung, statt die Editorübernahme als mathematischen Erfolg auszugeben.

Abschließender vollständiger Core-Prüfhelfer mit Dart 3.13.7 auf Windows: SDK-Vergleich und erzwungene Lockdatei erfolgreich, 21 Dateien ohne Formatänderung, statische Analyse ohne Befund und **419 Coretests bestanden**. Der vorherige direkte Subagentenlauf wird nicht addiert. Log lokal unter `build/reports/core-tests.log`.

Abschließender vollständiger App-Prüfhelfer mit unverändertem Flutter 3.47.8 / Dart 3.13.7: SDK-/Revisionsvergleich, erzwungene Lockdatei, 15 Dateien ohne Formatänderung, statische Analyse ohne Befund und **144 App-/Mappingtests bestanden**. Log lokal unter `build/reports/flutter-tests.log`. Die gezielten Subagentenläufe werden nicht zusätzlich gezählt. Kein konkreter Produktfehler wurde in diesem Paket gefunden. Katalog- und lokale Dokumentlinkprüfung ergänzen die ausführbaren Prüfungen.

Der explizite Vorschauhelfer bestand in fünf Szenarien. Die neue lokale ignorierte Datei `build/reports/calculator-group-capture.png` wurde bei 420×1100 visuell geprüft: `(2+4)` wird über den tatsächlichen Button übernommen, als vollständiger Zähler über 3 angezeigt und mit Ergebnis 2 ausgewertet. Die erweiterte Erklärung ist lesbar umgebrochen, die vollständige Tastatur bleibt sichtbar. Dies ist ein Testengine-QA-Szenario, kein nativer Gerätetest. Die Systemschrift wird nur lokal geladen.

### Nächster Schritt

Die Quadriertaste mit eindeutiger Operandbindung und passenden Referenz-/Bedientests als eigenes begrenztes Paket spezifizieren. Allgemeine Termauswahl, vollständige Potenzketten, automatische Original-Bruchtastenübernahme und Undo/Entpacken bleiben offen. Native Builds, echte Geräte-/Screenreaderprüfungen und Originalvergleich werden dadurch nicht ergänzt. Kein Push, keine Originaldateien verändert.
## 28.10.2026 nachmittags: vorhandene Atome als Zähler übernehmen

Ausgangsbasis `ef379f7`, Arbeitskopie vor Beginn sauber. Das nächste dokumentierte Arbeitspaket ergänzt eine ausdrücklich ausgelöste Übernahme vorhandener Bausteine in eine neue Bruchvorlage.

### Neu umgesetzt

- `FractionEditor.wrapPreviousAtomInFraction()` übernimmt eine vollständige Zahl, ein atomisches Ans oder einen vorhandenen Bruch direkt links vom Cursor als Zähler. Der Nenner bleibt leer und erhält den Cursor.
- Vor-/Nachbarn und Vorzeichen bleiben außerhalb der Vorlage erhalten. Ein Cursor mitten in einer Zahl wird abgewiesen; Operatoren, Gruppen und ganze Potenzketten werden nicht geraten. Die Regeln sind eigene begrenzte Prototypentscheidungen.
- Die neue eigene Appaktion **Als Zähler** ist in Brüche sichtbar und nur während der Bearbeitung hinter einem Token aktiv. Die physische Bruchtaste bleibt eine leere Vorlage; 50 Plätze und 28/25 aktive Primärbelegungen bleiben unverändert.
- Atomare Prüfung beider Ressourcenlimits. Beim Übernehmen bestehender Brüche wird die maximale Tiefe des gesamten Kandidatenbaums geprüft, einschließlich aller übernommenen Nachkommen.

Spezifikation, Beispiele und Grenzen stehen in [BRUCHUEBERNAHME.md](BRUCHUEBERNAHME.md). Ergebnis-/Fehlerphase verändern sich durch einen direkten Aufruf der neuen Aktion nicht. Die lineare Sitzung bleibt unverändert.

### Prüfung

Ein Subagent implementierte den Core samt 47 neuen Tests; ein zweiter schrieb 17 unabhängige durchgängige UI-Fälle. Der Core-Agent prüfte den Appdiff anschließend ohne konkrete Befunde. Die UI-Fälle prüfen unter anderem `12/3=4`, `(0,5)/2=1/4`, `2+3/2=7/2`, Übernahme eines ganzen Bruchs, atomisches Ans, Suffixerhalt, Verschachtelung und 320-Pixel-Layout. Hinzu kommen abgewiesene Operatoren/Gruppen/Zahlensplits/fehlerhafte Dezimalzahlen, deaktivierte Phasen und die unveränderte physische Tastatur. Es wird kein originaler Casio-Tastenablauf nachgewiesen.

Ein erster Core-Teillauf zeigte eine fehlende Zuordnung von `/` im neuen Testhelfer; diese wurde ergänzt. Der Produktionscode benötigte dafür keine Korrektur. Die Tiefentests prüfen insbesondere erlaubte 15→16 Ebenen, abgewiesene 16→17 Ebenen am Wurzel- und verschachtelten Cursor sowie einen tiefen Geschwisterzweig, der eine flache Übernahme nicht verhindern darf.

Abschließender vollständiger Core-Prüfhelfer mit Dart 3.13.7 auf Windows: SDK-Vergleich und erzwungene Lockdatei erfolgreich, 20 Dateien ohne Formatänderung, statische Analyse ohne Befund und **383 Coretests bestanden**. Log lokal unter `build/reports/core-tests.log`. Der vorherige direkte Subagentenlauf wird nicht addiert.

Abschließender vollständiger App-Prüfhelfer mit unverändertem Flutter 3.47.8 / Dart 3.13.7: SDK-/Revisionsvergleich, erzwungene Lockdatei, 14 Dateien ohne Formatänderung, statische Analyse ohne Befund und **129 App-/Mappingtests bestanden**. Log lokal unter `build/reports/flutter-tests.log`. Die Katalog-/Dokumentlinkprüfung ergänzt diese ausführbaren Prüfungen. Kein konkreter Produktfehler wurde in diesem Paket gefunden.

Der explizite Vorschauhelfer bestand in vier Szenarien. Die neue lokale ignorierte Datei `build/reports/calculator-capture.png` wurde bei 420×1100 visuell geprüft: Die tatsächliche Buttonfolge `12`, **Als Zähler**, `3`, `=` zeigt die natürliche Vorlage `12/3` und das Ergebnis 4, die Erklärung der Appaktion sowie die unveränderte vollständige Tastatur. Der Button ist nach dem Ergebnis korrekt deaktiviert. Dies ist ein QA-Szenario im Testengine, kein nativer Gerätetest. Die Systemschrift wird weiterhin nur lokal geladen.

### Nächster Schritt

Die explizite Übernahme vollständig geschlossener Klammergruppen als eigenes begrenztes Paket spezifizieren. Allgemeine Termauswahl, vollständige Potenzketten, automatische Übernahme durch die Original-Bruchtaste und Undo/Entpacken bleiben offen. Native Builds, echte Geräte-/Screenreaderprüfungen und Originalvergleich wurden nicht ergänzt. Kein Push, keine Originaldateien verändert.

## 28.10.2026 morgens: vertikale Bruchfeldnavigation

Ausgangsbasis `80301dc`, Arbeitskopie vor Beginn sauber. Das dokumentierte nächste Arbeitspaket ergänzt Auf/Ab durchgängig im vorhandenen strukturierten Editor, der Sitzung und der Hauptansicht.

### Neu umgesetzt

- Auf wechselt vom Nenner in den unmittelbar zugehörigen Zähler, Ab in Gegenrichtung. Der logische Tokenoffset wird auf die Zielfeldlänge begrenzt. Leere Felder und verschachtelte Brüche folgen derselben Regel; es wird keine Pixelspalte oder Vorfahrensuche behauptet.
- Die strukturierte Sitzung akzeptiert `KEY_UP`/`KEY_DOWN` zusätzlich. Erste Pfeilaktionen nach Ergebnis beziehungsweise Fehler öffnen wie Links/Rechts das Wurzelende beziehungsweise Source-Map-Ziel ohne zusätzliche Bewegung.
- Die Hauptansicht bietet in Brüche jetzt 28 statt 26 aktive Primäraktionen; Linear bleibt bei 25. Hardware-Up/Down werden ausschließlich im Bruchmodus verarbeitet, Modifier bleiben unzugeordnet und Haltewiederholungen erzeugen keine weitere Bewegung.
- Die bestehende innere Cursor-Nachführung bleibt auch bei vertikalen Feldwechseln wirksam. Der Fehlerhinweis nennt alle vier Richtungen zur Wiederaufnahme.

Die Regeln sind ausdrücklich eigene Prototypentscheidungen. Details, Grenzen und Beispiele stehen in [VERTIKALE_NAVIGATION.md](VERTIKALE_NAVIGATION.md).

### Prüfung

Ein Subagent implementierte den Core und 22 neue Tests. Der andere schrieb unabhängig zwölf durchgängige Appfälle; der Hauptagent ergänzte drei fokussierte Mappingtests. Der Core-Agent prüfte den Appadapter zusätzlich ohne Änderungen und ohne konkrete Befunde. Geprüft werden insbesondere unterschiedliche Feldlängen, leere Felder, verschachtelte Pfade ohne automatischen Aufstieg, atomarer Ans-Offset, unveränderliche Snapshots, beide Ressourcenlimits, Ergebnis-/Fehlerwiederaufnahme und die Trennung zum linearen Modus. Die Hardwareprüfung verwendet einen tatsächlich fokussierten Ziffernbutton und kontrolliert, dass Wiederholungen weder den Cursor noch den Fokus bewegen. Der bestehende strukturierte Inventartest wurde gezielt von 26 auf 28 aktive Aktionen aktualisiert.

Abschließender vollständiger Core-Prüfhelfer mit Dart 3.13.7 auf Windows: SDK-Vergleich und erzwungene Lockdatei erfolgreich, 19 Dateien ohne Formatänderung, statische Analyse ohne Befund und **336 Coretests bestanden**. Log lokal unter `build/reports/core-tests.log`. Der vorherige direkte Subagentenlauf wird nicht nochmals gezählt.

Abschließender vollständiger App-Prüfhelfer mit unverändertem Flutter 3.47.8 / Dart 3.13.7: SDK-/Revisionsvergleich, erzwungene Lockdatei, 13 Dateien ohne Formatänderung, statische Analyse ohne Befund und **112 App-/Mappingtests bestanden**. Log lokal unter `build/reports/flutter-tests.log`. Keine konkreten Produktfehler wurden in diesem Paket gefunden. Die Katalog-/Dokumentlinkprüfung ergänzt diese ausführbaren Prüfungen.

Der explizite Vorschauhelfer bestand erneut für Linear, Brüche und Fehler. Die Bruchrechnung benutzt jetzt auch Auf-/Ab-Feldwechsel und bestätigt weiterhin `1/2`. Die lokale ignorierte Vorschau `build/reports/calculator-fractions.png` wurde bei 420×1100 visuell geprüft: alle vier Pfeile sind aktiv und lesbar, Formel und Ergebnis bleiben korrekt dargestellt. Dies ist kein nativer Gerätetest.

### Nächster Schritt

Übernahme bestehender Operanden in eine Bruchvorlage spezifizieren und als eigenes begrenztes Paket umsetzen. Geometrische Spalten, Vorfahrensuche, Verlauf und weitere natürliche Vorlagen bleiben offen. Native Builds, echte Geräte-/Screenreaderprüfungen und Originalvergleich wurden dadurch nicht ergänzt. Kein Push, keine Originaldateien verändert.

## 28.10.2026: strukturierte Fehlerstellen und gezielte Wiederaufnahme

Ausgangsbasis `82f533e`, Arbeitskopie vor Beginn sauber. Das nächste dokumentierte Paket ergänzt die Source-Map zwischen linearem Parserausdruck und natürlichen Bruchfeldern; die bisherige Editor- und Rechenimplementierung bleibt Grundlage.

### Neu umgesetzt

- Unveränderliche `EditorProjection` mit UTF-16-Offsetzuordnung zu Feldpfad/Tokenoffset, einschließlich generierter Bruchklammern und atomarem Ans.
- Feldbezogene Diagnosen für leere Eingabefelder und unausgeglichene Klammern; die bisherigen `toExpression()`-/`evaluate()`-Aufrufer erhalten weiterhin `CalculatorException`.
- Separates `errorCursor` im strukturierten Snapshot. Während der Fehlerphase bleibt der ursprüngliche Bearbeitungscursor unverändert; die erste Links-/Rechtsaktion öffnet das markierte Ziel ohne zusätzlichen Schritt. Ein validiertes `moveTo()` schützt vor unpassenden Fremdpfaden.
- Roter Fehlermarker, Feldrahmen, verständlicher Bearbeitungshinweis und assistive Fehlerstellenbeschreibung in der Hauptansicht. Die vorhandene interne Cursor-Nachführung zeigt jetzt bei Fehlern den Marker, ohne den äußeren Seitenbildlauf zu verändern.

Die Zuordnungsregeln sind eigene dokumentierte Prototypentscheidungen. Beispielsweise führt das von einer Bruchvorlage erzeugte `/` zum Nennerende; ein ausdrücklich eingegebenes `/` bleibt ein gewöhnliches Token. Positionslose Ressourcenfehler verwenden den bisherigen Cursor als Rückkehrhilfe. Details und verbleibende Grenzen stehen in [FEHLERPOSITIONEN.md](FEHLERPOSITIONEN.md).

### Tatsächliche Prüfung

Ein Subagent implementierte die Core-Erweiterung samt 29 neuen Tests, ein zweiter schrieb neun zusätzliche durchgängige UI-Fälle. Ein weiterer UI-Regressionstest des Hauptagenten ergänzt die eindeutige gesprochene Zuordnung bei benachbarten Brüchen. Die Tests prüfen unter anderem synthetische Zeichen, Ans, tiefe Feldpfade, leere Felder, Klammern, gültige/ungültige Cursor aus anderen Snapshots und Grenzen der Projektionsoffsets. UI-Abläufe markieren ein Fehlerfeld auch dann, wenn sich der bisherige Cursor anderswo befindet, öffnen es per Pfeil und reparieren die Rechnung. Hinzu kommen AC/Moduswechsel, Semantik sowie horizontale und vertikale Fehler-Nachführung.

Zwei anfängliche Testannahmen wurden präzisiert: Ein Core-Testhelfer verglich eine Liste innerhalb eines Records per Identität statt deren Inhalt; ein UI-Test verlangte Scrolloffset exakt null, obwohl der zusätzliche Feldrahmen fünf Pixel Überlauf erzeugte. Die korrigierten Assertions prüfen Pfad-/Offsetwerte beziehungsweise sichtbaren Marker und korrekte Scrollrichtung. Daraus wird kein Produktfehler abgeleitet.

Der zusätzliche Read-only-Review des Core-Agenten fand eine tatsächliche Mehrdeutigkeit in der assistiven Ausgabe: Feldnamen allein unterschieden benachbarte Brüche nicht. Die Ansage zählt nun auf jeder Pfadebene die tatsächlichen Bruchknoten, beispielsweise „im Nenner des 2. Bruchs“. Der neue Regressionstest prüft diesen Fall mit `1/2+1/0`.

Abschließender Core-Prüfhelfer mit Dart 3.13.7 auf Windows: SDK-Vergleich und erzwungene Lockdatei erfolgreich, 18 Dateien ohne Formatänderung, statische Analyse ohne Befund und **314 Coretests bestanden**. Der vorherige direkte Subagentenlauf wird nicht nochmals gezählt. Log lokal unter `build/reports/core-tests.log`.

Nach der Semantikkorrektur bestand der vollständige App-Prüfhelfer mit unverändertem Flutter 3.47.8 / Dart 3.13.7: SDK-/Revisionsvergleich, erzwungene Lockdatei, zwölf Dateien ohne Formatänderung, statische Analyse ohne Befund und **97 App-/Mappingtests bestanden**. Der vorherige Lauf mit 96 Tests wird nicht addiert. Log lokal unter `build/reports/flutter-tests.log`. Die Katalog- und lokale Dokumentlinkprüfung ergänzen die ausführbaren Prüfungen.

Der explizite Vorschauhelfer bestand in drei Szenarien (Linear, Brüche, Fehler). Die neue lokale ignorierte Datei `build/reports/calculator-error.png` wurde bei 420×1100 visuell geprüft: Bei `1/(2/0)` ist der rote Marker am inneren Nenner samt Bearbeitungshinweis und mathematischem Fehler sichtbar. Die hohe Formel wird im festen 104-Pixel-Ausschnitt intern nach unten gescrollt; ihr oberer Teil ist dabei bewusst außerhalb des sichtbaren Bereichs und lässt sich manuell wieder erreichen. Es wird kein vollständiges gleichzeitiges Anzeigen beliebig hoher Formeln behauptet. Keine native Installation oder echte Screenreaderprüfung in diesem Paket.

### Nächster Schritt

Vertikale Feldnavigation für Zähler/Nenner spezifizieren und als eigenes Paket über Core, Bildschirmtasten und Hardwareadapter prüfen. Danach Übernahme bestehender Operanden in Bruchvorlagen und weitere natürliche Vorlagen. Die Source-Map ist eine Zuordnung gemeldeter Stellen, keine allgemeine Ursachenanalyse oder Originalkompatibilitätszusage. Native Builds, echte Screenreader-/Gerätetests und Originalvergleich bleiben offen. Kein Push, keine Originaldateien verändert.

## 27.10.2026 abends: Bruchtaste und strukturierte Sitzung in der Hauptansicht

Ausgangsbasis `33b8c24`, Arbeitskopie vor Beginn sauber. Das nächste dokumentierte Arbeitspaket verbindet die bereits geprüften Core-/Darstellungsbausteine zu durchgängigen Bedienabläufen.

### Neu umgesetzt

- `StructuredCalculatorSession` mit unveränderlichen Snapshots, exaktem Ans, Ergebnis-/Fehlerphasen und den 25 bisherigen Primäraktionen plus `KEY_FRACTION`.
- Expliziter App-Schalter **Linear / Brüche**. Linear bleibt beim Start aktiv und unverändert bei 25 unterstützten Tasten; Brüche aktiviert 26. Beide Eingabearten erhalten ihre eigenen Entwürfe, Fehler, Ergebnisse und Ans. Die Oberfläche erklärt diese eigene Prototypentscheidung; es gibt noch keine originale Math-/Linear-Setupnachbildung.
- Natürliche Bruchansicht mit Zähler-/Nennernavigation, DEL/AC, exakter Auswertung, Ans-Fortsetzung und pfadtreuer Wiederaufnahme nach Fehlern. Parseroffsets werden nicht als Editorpositionen fehlinterpretiert.
- Cursor-Nachführung über zwei interne Scrollcontroller. Lange und hohe Formeln bleiben im 104-Pixel-Display bedienbar, ohne den äußeren Seitenbildlauf automatisch zu verschieben.

Schnittstelle, Bedienfolgen und Grenzen stehen in [STRUKTURIERTE_SITZUNG.md](STRUKTURIERTE_SITZUNG.md). Die Ergänzung der Editor-API (`fromSnapshot`, `moveToRootEnd`) verändert keine früheren Snapshots und keinen linearen Controller.

### Tatsächliche Prüfung

Ein Subagent implementierte Core-Sitzung und 36 neue Tests, ein zweiter schrieb unabhängig 14 neue durchgängige Widgettests. Der Core-Agent prüfte anschließend die Appänderungen ohne konkurrierende Änderungen. Die UI-Fälle prüfen unter anderem `1/3+1/6=1/2`, `1/(2/3)=3/2`, Moduswechsel mit erhaltenem Zustand, Ans-Fortsetzung, leere Bruchfelder, Division durch null samt Korrektur, Hardwarepfeile, 320×568 sowie horizontale und vertikale Cursor-Nachführung.

Ein neuer Test fand einen konkreten Darstellungsfehler: Nach 80 Hardwareziffern ragte die Cursoroberkante um zwei Pixel aus dem Display, obwohl die Scrollposition bereits am Anfang lag. Ein gewöhnliches Baseline-Widget hatte das rechteckige Kind nach oben aus seinen Layoutgrenzen verschoben. Cursor und Platzhalter melden jetzt ihre Baseline innerhalb der vollständigen Kindgröße über einen kleinen RenderProxyBox-Baustein. Der unveränderte Regressionstest besteht anschließend, einschließlich Rückwärtsnavigation und unverändertem äußeren Scrolloffset.

Abschließender Core-Prüfhelfer mit Dart 3.13.7 auf Windows: Versionsvergleich und erzwungene Lockdatei erfolgreich, 16 Dateien ohne Formatänderung, statische Analyse ohne Befund und **285 Coretests bestanden**. Log lokal unter `build/reports/core-tests.log`. Der vorherige direkte Lauf des Subagenten wird nicht zusätzlich zur Gesamtzahl gezählt.

Abschließender vollständiger App-Prüfhelfer mit Flutter 3.47.8 / Dart 3.13.7: SDK-/Revisionsvergleich und erzwungene Lockdatei erfolgreich, elf Dateien ohne Formatänderung, statische Analyse ohne Befund und **87 App-/Mappingtests bestanden**. Log lokal unter `build/reports/flutter-tests.log`. Die bisherigen 73 Tests bleiben enthalten. Katalog- und lokale Dokumentlinkprüfung erfolgen ergänzend; die ursprünglichen vollständigen Inventare bleiben Planungsdaten.

Der erweiterte explizite Vorschauhelfer lief für beide Hauptansichten erfolgreich. Die Bilder `build/reports/calculator-prototype.png` und `build/reports/calculator-fractions.png` (lokal ignoriert) wurden bei 420×1100 visuell geprüft: Schalter, Trennungshinweis, jeweils korrektes Ergebnis `1/2`, vollständige Tastatur und natürliche Bruchanzeige sind lesbar. Dies sind zwei QA-Szenarien im Testengine, keine neuen nativen Gerätetests. Die Systemschrift bleibt ausschließlich lokal.

### Nächster Schritt und Grenzen

Fehlerpositionen strukturell auf Felder abbilden und die markierte Stelle gezielt wieder öffnen. Danach vertikale Feldnavigation und Übernahme bestehender Operanden in Vorlagen spezifizieren; weitere Vorlagen/Modifier getrennt behandeln. Die zwei Eingabearten teilen weiterhin kein Ans, ihre Regeln sind noch eigene Prototypregeln. Native Builds, echte Gerätetests und Originalvergleich bleiben offen. Originaldateien wurden nicht verändert, kein Push.

## 27.10.2026: natürliche Bruchansicht als Flutter-Komponente

Ausgangsbasis `41bafda`, Arbeitskopie vor Beginn sauber. Das im letzten Paket dokumentierte nächste Arbeitspaket ist umgesetzt: eine eigenständige lesende Ansicht für die unveränderlichen Brucheditor-Snapshots. Hauptrechnerroute, aktive Tasten und Core bleiben unverändert.

### Neu umgesetzt

- `FractionExpressionView` zeichnet verschachtelte Brüche mit getrennten Feldern, Bruchstrichen, leeren Platzhaltern und dem aktuellen Pfadcursor. Der Cursor lässt sich für Ergebnis-/Vorschauansichten ausblenden.
- Ein eigener Zwei-Kind-Renderbaustein misst die Felder ohne rekursive IntrinsicWidth-Durchläufe. Zähler/Nenner sind zentriert; auch verschieden hohe benachbarte Brüche behalten eine gemeinsame mathematische Achse.
- Horizontales Scrollen für lange Formeln und vertikales Scrollen für hohe Formeln bei begrenztem Platz; Textvergrößerung skaliert Cursor und Platzhalter mit.
- Zusammenhängende deutsche Formelbeschreibung für assistive Ausgabe, ohne die dekorativen Texte zusätzlich einzeln vorzulesen. Echte Screenreader-/Geräteprüfung ist weiterhin offen.

Die lesende Ansicht verändert weder den Editor noch frühere Snapshots. Details, eigene Darstellungsregeln und Grenzen stehen im [Brucheditor-Prototyp](BRUCHEDITOR_PROTOTYP.md).

### Prüfung und visuelle Kontrolle

Ein Subagent schrieb 13 eigenständige Widgettests anhand des Darstellungsvertrags. Geprüft werden unter anderem Feldgeometrie und tatsächlich gezeichnete Linie, gemeinsame Achse ungleich hoher Nachbarbrüche, Pfadcursorwechsel, leere Felder, alte Snapshots, Semantik, tatsächliches horizontales Scrollen bei 320 Pixel Breite, doppelte Textskalierung und 16 verschachtelte Brüche in einem begrenzten 320×240-Bereich. Ein zweiter Subagent prüfte den Produktionscode einschließlich relevanter lokaler Flutter-Renderdefinitionen ohne konkurrierende Änderungen.

Abschließender vollständiger Lauf von `tools/test_app.ps1` mit dem unveränderten Flutter 3.47.8 / Dart 3.13.7 auf Windows: Versions-/Revisionsvergleich und erzwungene Lockdatei erfolgreich, zehn Dateien ohne Formatänderung, statische Analyse ohne Befund und **73 App-/Mappingtests bestanden**. Log lokal unter `build/reports/flutter-tests.log`. Die 249 Coretests aus dem vorherigen Paket wurden für diesen reinen App-Baustein nicht erneut ausgeführt; der Core wurde nicht verändert. Katalog- und lokale Dokumentlinkprüfung ergänzen die tatsächlichen Tests.

Der erste Analyseaufruf fand eine im verwendeten Flutter abstrakte ParentData-Basisklasse; eine eigene konkrete ParentData-Klasse korrigiert das. Ein anfänglich zu strenger Semantiktest erwartete keine Nachfahren; der notwendige Scroll-Semantikknoten wird jetzt zugelassen, zusätzliche gesprochene Textduplikate bleiben verboten. Es wird daraus kein Produktfehler abgeleitet.

Der explizite QA-Helfer `tool/render_fraction_preview.dart` lief erfolgreich und erzeugte die lokal ignorierte Vorschau `build/reports/fraction-view.png` bei 420×900. Die endgültige Darstellung wurde visuell geprüft: leere Vorlage, `1/3+1/6=1/2`, verschachtelte `1/(2/3)+1/2=2` und Cursor im zweiten Nenner sind lesbar und ohne abgeschnittene Felder. Bei der visuellen Prüfung wurden die Operatorabstände vergrößert. Die Systemschrift wird nur lokal geladen, nicht als Asset verteilt. Die QA-Seite ist kein neuer Appmodus und zählt nicht als zusätzlicher Gerätetest.

### Nächster Schritt

Eine strukturierte Sitzung mit Ergebnis-/Fehlerzuständen und Ans ergänzen, anschließend die Bruchtaste und Formelansicht in der Hauptrechnerseite gemeinsam anbinden. Dabei Umschaltung zur linearen Eingabe, Fehlerpositionen und Cursor-Nachführung ausdrücklich festlegen und über echte UI-Tastenfolgen prüfen. Die Bruchtaste ist bis dahin weiterhin deaktiviert. Wurzeln, gemischte Brüche, Modifier/Menüs, native Builds und echte Plattformtests sind offen. Keine Originaldateien geändert und kein Push.

## 27.10.2026: strukturierter Brucheditor im Core

Ausgangsbasis `68870aa`, Arbeitskopie vor Beginn sauber. Das nächste abgegrenzte Paket aus dem Entwicklungsplan ist als unabhängiges Editor-Modell umgesetzt; es ersetzt die geprüfte lineare App-Sitzung noch nicht.

### Neu umgesetzt

- Unveränderliche Sequenzen, Textknoten und verschachtelte Bruchvorlagen mit getrennten Zähler-/Nennerfeldern.
- Pfadcursor, bidirektionale Feldnavigation, Einfügen, DEL und vollständiges Leeren ohne Flutter-Abhängigkeit.
- Geklammertes Überführen in den bestehenden Parser und exakte Auswertung einschließlich ausdrücklich übergebenem Ans.
- Eigene Knoten-/Tiefenbudgets mit atomarer Ablehnung; leere Felder und feldübergreifend unausgeglichene Klammern werden explizit abgewiesen.

Ein konkreter Projektionsfehler wurde während der Umsetzung erkannt und vor Abschluss abgesichert: Ungültige Klammern aus Zähler und Nenner konnten sich in der linearen Projektion sonst gegenseitig schließen. Jede Sequenz prüft jetzt ihre Klammerbalance unabhängig. Zwei Regressionen prüfen, dass solche Eingaben Syntaxfehler bleiben. Die genauen eigenen Bedienregeln und Grenzen stehen in [BRUCHEDITOR_PROTOTYP.md](BRUCHEDITOR_PROTOTYP.md).

### Tatsächliche Prüfung

Ein Subagent schrieb anhand des API-/Bedienvertrags 68 zusätzliche Tests, ein zweiter prüfte den Produktionscode ohne konkurrierende Änderungen. Der erste Review übersah zunächst die Klammergrenze; die spätere Ergänzung wurde gesondert geprüft. Der vollständige Core-Prüfhelfer bestand mit Dart 3.13.7 auf Windows: Lockdatei erzwungen, 14 Dateien ohne Formatänderung, statische Analyse ohne Befund und **249 Coretests bestanden**. Log lokal unter `build/reports/core-tests.log`.

Die Tests prüfen insbesondere verschachtelte Feldpfade, Rückwärtsnavigation, atomare Ans-/Bruchlöschung, alte Snapshots, beide Klammerregressionen, exakte Werte wie `1/3+1/6=1/2` und `1/(2/3)=3/2` sowie beide Ressourcenlimits. Dies ist ein Nachweis unseres Editorvertrags, kein Originalvergleich und kein Nachweis der Bildschirm-Bruchtaste. Die 50-/243-Referenzinventare bleiben Planungsdaten.

Nach der API-Erweiterung wurde auch `tools/test_app.ps1` vollständig ausgeführt: Lockdatei/SDK-Prüfung erfolgreich, Formatierung unverändert, statische Analyse ohne Befund und **60 App-/Mappingtests erneut bestanden**. Katalogprüfung erfolgreich (50 Tasten, 243 Prüfpositionen, fünf Abläufe, 56 Handbuch-IDs). Keine UI-Änderung, neue Screenshotprüfung oder native Builds in diesem Paket.

### Nächster Schritt und Grenzen

Als nächstes die strukturierte Formelansicht in Flutter mit Bruchstrich, Platzhaltern und Pfadcursor implementieren und visuell/geometrisch prüfen. Anschließend eigene strukturierte Sitzung und Bruchtaste anbinden; Ergebnis-/Fehlerübergänge, Ans und Moduswechsel dabei ausdrücklich festlegen. Gemischte Brüche, Wurzeln, vertikale Navigation und Zuordnung von Parserfehlern zu Feldpfaden sind offen. Windows-/Android-Buildwerkzeuge und native Gerätetests bleiben getrennt offen. Keine neuen Originaldateien vorhanden, kein Push.

## 27.10.2026: erste Flutter-Oberfläche

Begonnen mit dem automatischen Arbeitspaket am späten 26.10.2026, Ausgangsbasis `8ad6abd`, Arbeitskopie zuvor sauber. Das vorhandene Core-/Sessionpaket wurde wiederverwendet und nicht erneut implementiert.

### Neu umgesetzt

- Eigenständige Flutter-Ansicht mit Anzeige für Eingabe, Cursor, Ans, Ergebnis und deutsche Fehlerkategorien.
- 50 Tastenplätze aus dem bestehenden Inventar; 25 unterstützte Primäraktionen sind aktiv, 25 weitere sichtbar deaktiviert.
- Verbindung zur geprüften Sitzung, Bildschirmtasten und begrenzter Hardwareadapter; Tab/Space behalten die normale Fokusbedienung.
- Responsive Breite und vertikaler Bildlauf für kleinere Fenster/Telefone; ausreichend hohe gezeichnete Buttonflächen.
- Offiziell erzeugte Gerüste für Android, iOS, Windows, macOS und Linux, App-Lockdatei und versionierter Prüfhelfer `tools/test_app.ps1`.

### Werkzeuge und Prüfung

Flutter wurde außerhalb des Repositorys am offiziellen Release-Tag 3.47.8 eingerichtet, Revision `737ba8f885dc774b53b442759999a312c9461e4e`, Dart 3.13.7. Das direkte Archiv-Verzeichnis war nicht verfügbar; der offizielle GitHub-Tag und Bootstrap funktionierten. Analytics aus, kein globaler PATH-Eingriff. Die Tag-Fixierung wird von `flutter doctor` als Git-Kanal `[user-branch]` angezeigt. Details in [FLUTTER_PROTOTYP.md](FLUTTER_PROTOTYP.md).

Abschließender App-Prüflauf: SDK-/Revisionsvergleich, erzwungene Lockdatei, unveränderte Formatierung, statische Analyse ohne Befund und **60 Widget-/Keyboard-Mappingtests bestanden**. Die 181 Coretests des vorherigen Pakets bleiben der unveränderte Core-Nachweis; sie werden nicht als neue Gerätetests umgedeutet. Alle 50 App-IDs wurden zusätzlich mit der Referenz-CSV abgeglichen. Katalog- und Dokumentlinkprüfung ohne Befund.

Ein konkreter Erstlauf-Fehler wurde durch den Subagenten nachgewiesen: Enter-Wiederholung konnte nach Ausführen eine fokussierte Zifferntaste aktivieren. Der Appadapter konsumiert zugeordnete Wiederholungsereignisse jetzt ohne neue Rechneraktion; der Regressionstest besteht. Eine separate visuelle Prüfung deckte zu schmale gezeichnete Tastenflächen auf; die Reihen strecken ihre Buttons jetzt auf die vorgesehene Höhe. Ein geometrischer Regressionstest prüft repräsentative Flächen bei 320 Pixel Breite.

Die explizite visuelle Vorschau wurde bei 420×900 gerendert und nach Korrekturen geprüft. Datei: `build/reports/calculator-prototype.png` (lokal, ignoriert). Sie zeigt die vollständige Tastatur und `1/3+1/6 = 1/2`, lesbare Beschriftungen und Richtungsicons. Die Vorschauerzeugung prüft zusätzlich einen Rechenablauf, wird aber nicht als weiterer allgemeiner Geräte-/Plattformtest gezählt. Native Bildcodierung läuft im QA-Helfer außerhalb der künstlichen Testuhr; Systemfont nur lokal geladen, nicht als Projektasset übernommen.

### Verbleibende Grenzen / nächste Schritte

Die lokale Diagnose fand weder ein Android-SDK noch Visual-Studio-C++-Buildwerkzeuge. Windows-/Android-App-Pakete wurden daher noch nicht gebaut. iOS/macOS und Linux wurden nicht auf den jeweiligen Betriebssystemen geprüft. Plattformgerüste und Widgets im Testengine sind kein Nachweis einer nativen Installation.

Natürlicher Formeleditor, SHIFT/ALPHA, Menüs, Variablen/M-Speicher und weitere Modi bleiben offen. Nächstes unabhängiges Paket ist der natürliche Editor-Prototyp; die fehlenden Windows-/Android-Buildwerkzeuge sind getrennt zu behandeln. Standard-Appicons und Paketkennung sind vor einer Veröffentlichung noch festzulegen. Original-Programmdateien fehlen weiterhin, blockieren diesen Eigenbau aber nicht. Neue Änderungen bleiben lokal; kein Push.

## 26.10.2026: linearer Bedienzustand und Ans

Ausgangsbasis: lokaler Commit `3e23d37`, Arbeitskopie vor Beginn sauber. Dieses Paket ergänzt die Bedienebene, ohne Flutter/SDKs nachzuinstallieren oder Originalsoftware abzuwarten.

### Neu umgesetzt

- `CalculatorSession`, semantische `CalculatorKey`-IDs und unveränderliche Snapshots für Eingabe-, Ergebnis- und Fehlerphase.
- 25 Primäraktionen: alle Ziffern, Grundoperatoren, Potenz/Vorzeichen/Komma/Klammern, Links/Rechts, DEL/AC, `=` und Ans.
- Linearer Token-Cursor mit atomarem Ans; getrennte Stringoffsets für spätere Anzeige und Fehlerpositionen.
- Exaktes Ans als ausdrücklich gebundener Zahlenoperand. Erfolgreiche Rechnungen aktualisieren Ans; AC und Fehler erhalten ihn. Operatoren nach Ergebnis setzen mit Ans fort.
- Explizite Unsupported-Meldung für noch nicht implementierte Tasten-IDs, statt unbekannte Belegungen vorzutäuschen.
- Ein gemeinsamer JSON-Referenzfall wird als lineare Core-Projektion über KEY_-IDs abgespielt; noch kein vollständiger universeller Referenzadapter.

### Tatsächlich geprüft

67 neue Sessiontests, drei zusätzliche Ans-Evaluatortests und ein JSON-Projektionsfall ergänzen die vorherigen 110 Tests. Abschließender vollständiger Prüfaufruf mit stabilem Dart 3.13.7 auf Windows x64: **181 Tests bestanden**, Lockdatei erzwungen, Formatierung unverändert, statische Analyse ohne Befund. Ein Subagent schrieb die Sessiontests anhand des Schnittstellenvertrags; ein zweiter prüfte Code und Übergänge unabhängig und meldete keine konkreten Fehler. Katalog- und Dokumentlinkprüfungen erfolgen ergänzend vor dem lokalen Commit.

Ein früher gebündelter Aufruf meldete einen Testfehler, dessen Einzelursache durch die damalige gekürzte Ausgabe nicht gesichert wurde. Der direkte vollständige Testlauf und der abschließende vollständige Prüfaufruf bestanden anschließend ohne Quelländerung. Der Prüfhelfer bewahrt Testausgaben nun unter dem ignorierten `build/reports/core-tests.log` auf, um einen möglichen Wiederholungsfall vollständig diagnostizieren zu können. Daraus wird keine bereits erklärte Fehlerursache abgeleitet.

### Umfang und Grenzen

Die 25 Primäraktionen sind keine vollständig getesteten 25 Originaltasten mit allen Zusatzbelegungen. SHIFT/ALPHA, Menüs, ON/OFF, Variablen/M-Speicher, Verlauf, natürlicher Formeleditor, Casio-Formatierung und die Flutter-Oberfläche bleiben offen. Eigene Regeln für DEL/Navigation nach Ergebnis und wiederholtes `=` sind als Prototypentscheidungen in [SESSION_PROTOTYP.md](SESSION_PROTOTYP.md) ausgewiesen. Keine Gerätetests, keine neuen App-Builds, kein Originalvergleich.

Der gemeinsame Fall `G07-key-division-zero` prüft nur die Tastenfolge, lineare Eingabe und mathematische Fehlerklasse. Math→Math-Setup, lokalisierter Text und sichtbarer Fehlercursor sind nicht implementiert. Die übrigen Inventare/JSON-Fälle bleiben Planungsdaten; kein pauschales Hochsetzen der Abdeckungswerte.

### Nächster Schritt

Ein kleines Flutter-Grundgerüst an die vorhandene Sitzung anbinden und Windows-/Android-Buildwerkzeuge gezielt prüfen. Danach Formeleditor-Prototyp und getrennte Modifier-/Menü-/Speicherpakete. Das vollständige Originalprogramm bleibt eine spätere zusätzliche Referenz. Dieser neue Fortschritt bleibt lokal; kein weiterer Push ohne Nutzerfreigabe.

## 26.10.2026: erstes ausführbares Core-Arbeitspaket

Ausgangsbasis: vollständiger Projektstand `bcd6691` auf `main`, vor Beginn ohne lokale Änderungen. Original-Programmdateien fehlen weiterhin. Die früher freigegebenen und versionierten Referenzen wurden nicht verändert.

### Umgesetzt

- Reines Dart-Paket unter `packages/calculator_core/` mit kleiner öffentlicher API.
- Unveränderliche, kanonisch gekürzte rationale BigInt-Zahlen; exakte Dezimal-/Exponentialzahleneingabe ohne Zwischenumwandlung in binäre Gleitkommazahlen.
- Eigener Ausdrucksbaum, Parser und davon getrennte Auswertung für `+`, `-`, `*`, `/`, Klammern und ganzzahlige Potenzen. Deutsche Dezimalkommas und die Zeichen ×, ÷, − werden unterstützt.
- Strukturierte Fehler für Syntax, mathematische Fehler, noch nicht unterstützte Funktionen und Ressourcenbudgets; Eingabeposition, soweit relevant.
- Einfaches Kommandozeilenbeispiel. Das ist keine Flutter-App und kein fertiger Emulator.
- Reproduzierbarer Prüfaufruf `tools/test_core.ps1`, SDK-Metadaten und Dependency-Lockdatei.

### Werkzeuge und Nachvollziehbarkeit

Flutter und Dart waren nicht im PATH; eine gezielte Suche in üblichen Verzeichnissen fand keine vorhandene Installation. Für das unabhängige Zahlen-/Parserpaket wurde deshalb nur das portable stabile Dart-SDK 3.13.7 von der offiziellen Archivquelle geladen. Lokaler Ort: `C:\Users\jpohl\.cache\fx991-toolchains\dart-3.13.7\dart-sdk\bin\dart.exe`. Keine globale PATH-Änderung und kein SDK im Repository. Analytics wurde deaktiviert. ZIP und offizieller SHA-256-Sidecar wurden vor Ausführung verglichen; Details in `tools/toolchain.json`.

Quelle zur Archivform: [offizielles Dart-SDK-Archiv](https://dart.dev/get-dart/archive). Der erste Sidecar-Abruf mit der Endung `.sha256` existierte nicht; der veröffentlichte `.sha256sum`-Sidecar wurde erfolgreich verwendet. `package:test` 1.33.0 ist explizit festgelegt; transitive Entwicklungsabhängigkeiten werden über `pubspec.lock` mit Hashes fixiert. Externe Laufzeitabhängigkeiten des Core-Pakets: keine.

### Prüfstand

Auf Windows x64 mit Dart 3.13.7 ausgeführt: Formatierung, statische Analyse und Coretests. Der erste Testlauf zeigte fehlerhaft formulierte Exception-Matcher in den Evaluatortests; diese wurden korrigiert. Die Fehlerbehandlung wird tatsächlich über ausgewertete Closures geprüft, nicht nur auf Existenz eines Exception-Typs. Ein zusätzlicher Review fand, dass geteilte Ausdrucksteilbäume das reine Tiefen-/Größenbudget umgehen konnten; ein Gesamtbudget für Auswertungsschritte und ein Regressionstest wurden ergänzt.

Abschließender vollständiger Lauf mit `tools/test_core.ps1`: Lockdatei erzwungen, Formatprüfung ohne Änderungen, statische Analyse ohne Befund und **110 Tests bestanden**. Zusätzlich CLI erfolgreich mit `2/3 + (1+1/2)` → `13/6` ausgeführt; `1/0` liefert strukturierte Fehlermeldung und Exitcode 2. Katalogprüfung weiterhin erfolgreich: 50 Tasten, 243 geplante Prüfpositionen, fünf JSON-Beispiele, 56 Referenz-IDs. Dokumentverknüpfungen und staged Diff werden vor dem lokalen Commit geprüft.

Abgedeckte Fälle: Bruchnormalisierung, Vorzeichen, Nullnenner, exakte große Ganzzahlen über 2^53, Dezimalparsing und dessen Grenzen, Rangfolge/Assoziativität, implizite Multiplikation, Syntaxfehler, Division durch null, nicht unterstützte Funktionen und eigene Ressourcenbudgets. `K02` wird auf Core-Ebene für beide Vorzeichen-/Klammerfälle geprüft; `K03` nur als mathematisch gleichwertiger linearer Ausdruck. Das ist keine Prüfung der gemischten Bruchtaste oder der natürlichen Anzeige. `G07` wird bezüglich Division-durch-null-Fehlerklasse geprüft, nicht bezüglich UI-Fehlertext/Cursor.

Die 50-Tasten-/243-Prüfpositionen-Kataloge bleiben bewusst `planned`; sie sind keine pauschal bestandene Suite. Die fünf JSON-Beispielabläufe werden noch nicht durch einen Dart-Referenzadapter ausgeführt. Keine Originalsoftware- oder Plattformvergleiche durchgeführt. Kein Windows-/Android-/Apple-/Linux-App-Build vorhanden.

### Bewusste Grenzen

Die rationale Zwischenrechnung und ASCII-Ausgabe bilden noch nicht die Casio-internen Stellen-, Bereichs-, Rundungs- oder Anzeigeregeln nach. Beliebig große Ganzzahlen innerhalb eigener Ressourcenbudgets sind ein Entwicklungswerkzeug und keine Kompatibilitätszusage. Nur implizite Faktoren mit öffnender Klammer sind bisher erlaubt; Funktionen/Variablen sind offen. Nichtganzzahlige Potenzen und `0^0` bleiben im Evaluator ausdrücklich nicht unterstützt. Unbekannte Hardware-Domänen werden damit nicht geraten.

### Nächstes abgegrenztes Arbeitspaket

1. Vorhandenen Core verwenden, keine erneute Grundlagenanalyse.
2. Minimalen testbaren Bedienzustand mit Ziffern, Operatoren, `=`, AC/DEL und strukturierten Fehlern hinzufügen. Speicher und SHIFT/ALPHA als nächste getrennte Schritte planen.
3. Anschließend kleines Flutter-Grundgerüst und den Formeleditor-Prototyp angehen; SDK und Windows-/Android-Buildwerkzeuge gezielt prüfen. Noch fehlende Zielumgebungen ausdrücklich ausweisen.
4. Bei späterem Eingang der Originalsoftware deren statische Analyse unabhängig aufnehmen.

Dieser Fortschritt bleibt lokal; die frühere Push-Freigabe galt dem damaligen vollständigen Stand und wird nicht als automatischer Push-Auftrag für neue Arbeit interpretiert.
