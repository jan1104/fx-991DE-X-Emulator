# Plattformwahl für Desktop und Mobilgeräte

Recherche: 25.10.2026. Anforderung des Nutzers: gemeinsamer Quellcode für Android, iPhone/iPad, Windows, macOS und Linux; getrennte Builds statt fünf eigenständiger Programme. Browserbetrieb ist optional.

## Empfehlung

**Flutter mit Dart** ist für dieses Projekt die bevorzugte Richtung. Das ist eine begründete technische Empfehlung, noch kein durch einen Projektprototyp bestätigter Befund. Es wurden weder SDKs installiert noch App-Gerüste erzeugt.

Flutter unterstützt die fünf gewünschten Betriebssystemfamilien und zusätzlich Web. Die Oberfläche wird durch die eigene Engine gezeichnet. Für unsere eigene Tastatur, mathematische Anzeige und identische Bedienzustände ist das vorteilhaft: Wir benötigen vor allem eine kontrollierbare Oberfläche, keine große Zahl unterschiedlicher Betriebssystemdienste. Diese Passungsbewertung ist unsere Schlussfolgerung aus den Anforderungen und der [offiziellen Flutter-FAQ](https://docs.flutter.dev/resources/faq).

Die Aussage gilt für unterstützte Betriebssystemversionen und Architekturen, nicht für jedes historische Gerät. Mindestversionen werden bei der Auswahl einer konkreten SDK-Version anhand der [offiziellen Plattformmatrix](https://docs.flutter.dev/reference/supported-platforms) festgehalten.

## Vergleich

| Lösung | Gemeinsame Oberfläche für unsere fünf Ziele | Bewertung für den Emulator |
|---|---|---|
| Flutter / Dart | Ja | Bevorzugt: eigene Zeichnung, gemeinsamer Zustands- und Rechenkern, passend für Touch und eine kontrollierte Rechneranzeige. Formeleditor und mathematische Kompatibilität müssen wir trotzdem entwickeln. |
| Tauri 2 / Weboberfläche, bei Bedarf Rust | Ja | Gute Alternative, besonders bei vorhandener Webanwendung. System-WebViews und zusätzliche Toolchains sind für diese Neuentwicklung abzuwägen. |
| Kotlin + Compose Multiplatform | Ja | Ernsthafte Alternative. Gemeinsame UI für Mobil und Desktop; Desktop verwendet JVM. Würde bei vorhandenen Kotlin-Kenntnissen stärker gewichtet. |
| .NET MAUI | Linux fehlt in Microsofts offizieller Zielliste | Für unsere vollständige Plattformanforderung keine erste Wahl. Diese Aussage betrifft MAUI, nicht sämtliche .NET-Oberflächenframeworks. |

Plattformfakten: [Tauri](https://tauri.app/), [Compose-Kompatibilität](https://kotlinlang.org/docs/multiplatform/compose-compatibility-and-versioning.html), [MAUI-Zielplattformen](https://learn.microsoft.com/en-us/dotnet/maui/supported-platforms?view=net-maui-10.0). Die Rangfolge ist eine Projektentscheidung, kein allgemeines Leistungsranking. Es wurden keine vergleichenden Benchmarks ausgeführt.

Tauri ist keine ungeeignete Lösung: Es unterstützt ebenfalls alle gewünschten Systeme. Sein Rendering hängt von den jeweiligen System-WebViews ab, etwa WKWebView auf Apple-Systemen und WebView2 unter Windows; siehe [offizielles Repository](https://github.com/tauri-apps/tauri). Eine Diskussion im [Tauri-Projektforum vom April 2026](https://github.com/orgs/tauri-apps/discussions/15222) erläutert diese WebView-Architektur ebenfalls. Ein vorhandener TypeScript-Kern würde Tauri attraktiver machen; im aktuellen Repository existiert noch keiner.

## Was Foren und Reddit beitragen

Die folgenden Erfahrungsberichte sind anekdotisch und nicht repräsentativ. Sie ergänzen die offiziellen Plattformangaben, ersetzen aber weder Dokumentation noch einen eigenen Test.

- [Flutter-Desktop-Erfahrungen, Mai 2026](https://www.reddit.com/r/FlutterDev/comments/1tcsn86/challenge_real_world_experience_with_flutter/): Ein Entwickler berichtet von einer Kameraanwendung für alle fünf Zielplattformen. Schwierigkeiten beschreibt er insbesondere bei Mehrfensterfunktionen und nativer Videoverarbeitung. Für unsere zunächst einzelne Rechneransicht ist das eher eine Aufforderung, Desktop früh zu testen, als ein Ausschlussgrund.
- [Flutter-Desktop-Erfahrungen, Juli 2023](https://www.reddit.com/r/FlutterDev/comments/1510boj/did_you_build_production_flutter_desktop_app_what/): Entwickler nennen fehlende Plugin-Unterstützung, Eingabeprobleme und plattformspezifische Anpassungen. Der Beitrag ist älter; daraus lässt sich kein unverändert bestehender Fehler im Jahr 2026 ableiten. Konsequenz für uns: Tastatur, Fokus und verwendete Plugins auf allen Zielen prüfen.
- [Tauri-Mobile-Erfahrungen, Oktober 2026](https://www.reddit.com/r/tauri/comments/1x96i6e/how_is_development_on_mobile/): Die Rückmeldungen unterscheiden einfache Webanwendungen von Apps mit umfangreicher nativer Integration. Einzelne Entwickler berichten von zusätzlichen Android-/iOS-Anpassungen. Unser Offline-Rechner benötigt zunächst wenig native Integration; die Berichte belegen daher keinen pauschalen Ausschluss von Tauri.

Aus diesen wenigen Diskussionen wird kein vermeintlicher Reddit-Konsens abgeleitet. Ausschlaggebend sind die Projektanforderungen und die überprüfbare Plattformabdeckung.

## Einmal programmieren, je Ziel bauen

Gemeinsam bleiben sollen Rechenkern, Parser, Datenmodelle, Zustandsmaschine, Formeleditor und der größte Teil der Oberfläche. Touch, Maus und physische Tastatur werden auf dieselben semantischen Tastenereignisse abgebildet. Anpassungen an Bildschirmgröße, Fokus, Zwischenablage und Paketierung bleiben möglich und müssen getestet werden.

| Ziel | Benötigte Build-Umgebung für Flutter | Vorgehen |
|---|---|---|
| Android | Windows, macOS oder Linux mit Android-Werkzeugen | Entwicklung zunächst vom vorhandenen Windows-PC möglich |
| Windows | Windows mit Windows-Entwicklungswerkzeugen | Lokaler Desktop-Build |
| Linux | Linux mit Linux-Entwicklungswerkzeugen | Später eigener Linux-Build-Rechner bzw. automatisierte Linux-Umgebung |
| macOS | macOS mit Apple-Werkzeugen | Mac als Build-Rechner erforderlich |
| iPhone/iPad | macOS mit Xcode | Apple-Build und Signierung gesondert vorbereiten |

Grundlage: [Flutter-Plattformintegration](https://docs.flutter.dev/platform-integration) und [Deployment-Übersicht](https://docs.flutter.dev/deployment). Es gibt nicht eine fertige Programmdatei, die auf allen Systemen läuft. Derselbe Quellcode wird in passende Pakete übersetzt. Automatisierte Builds auf mehreren Rechnern können später diesen Vorgang bündeln. Das richtet weder automatisch Veröffentlichung ein noch hebt es die Nutzerfreigabe für Pushes auf.

## Vorgeschlagene Umsetzung

1. Plattformunabhängiger Dart-Kern für Zahlen, Ausdrücke und Zustände; keine Flutter-Abhängigkeit im Rechenkern.
2. Flutter-Oberfläche mit eigener Tastatur und strukturierter mathematischer Anzeige. Die Auswahl einer Formelanzeigebibliothek bleibt offen; eine reine Formelanzeige ersetzt keinen interaktiven Editor.
3. Exakte rationale Zahlen auf Basis beliebig großer Ganzzahlen und explizit definierte Näherungsrechnung prüfen. Kein blindes Gleichsetzen von Gleitkommawert und Casio-kompatibler Ausgabe.
4. Tests für Kernrechnung unabhängig von UI und Plattform; zusätzliche Tests für Fokus, Bedienung und Darstellung je Ziel.
5. Zunächst Windows und Android als erreichbare Testziele. macOS, iOS und Linux sind von Anfang an Entwurfsziele, aber erst nach dort ausgeführten Builds und Tests als verifiziert zu melden.

Wichtig für eine optionale Webversion: Dart dokumentiert Unterschiede zwischen nativer und JavaScript-basierter Zahlenrepräsentation. BigInt ist dort als Möglichkeit für beliebig genaue Ganzzahlen genannt. Basis-N-Bitoperationen und Formatierung brauchen explizite Regeln und Tests; Flutter allein garantiert keine identischen Rechenergebnisse. [Dart-Zahlenrepräsentation](https://dart.dev/resources/language/number-representation)

## Langfristige Stabilität als verbindliche Anforderung

Ergänzung auf Nutzerwunsch: Zukunftssicherheit und Stabilität haben Vorrang vor möglichst neuen Framework-Funktionen. Flutter bleibt die bevorzugte Richtung, aber keine Plattformwahl garantiert dauerhafte Unterstützung ohne Wartung.

Flutter empfiehlt den Stable-Kanal für Produktionsversionen. Es gibt eine dokumentierte Kompatibilitätspolitik und Migrationshinweise; inkompatible Änderungen bleiben möglich, insbesondere auch durch Abhängigkeiten. Daraus wird keine mehrjährige LTS-Zusage abgeleitet. Quellen: [Release-Kanäle](https://docs.flutter.dev/install/upgrade), [Kompatibilitätspolitik](https://docs.flutter.dev/release/compatibility-policy).

Für die Umsetzung gelten:

1. Nur stabile SDK- und Bibliotheksversionen für reguläre Entwicklung und Releases; keine experimentellen APIs als Voraussetzung des Rechenkerns.
2. SDK-Version und Abhängigkeiten reproduzierbar festhalten. Aktualisierungen gezielt prüfen, nicht unbeaufsichtigt auf die neueste Hauptversion wechseln. Sicherheits- und notwendige Plattformaktualisierungen trotzdem zeitnah bewerten.
3. Rechenkern als eigenes Dart-Paket ohne Flutter-Imports entwickeln. Oberflächenwechsel soll diesen Kern und seine Referenztests möglichst erhalten. Eine vollständige Unabhängigkeit von Dart wird damit nicht behauptet.
4. Wenige, gepflegte externe Abhängigkeiten verwenden; Mathematik, Datenmodelle und Speicherformate nicht an kurzlebige Oberflächenplugins koppeln.
5. Kern-, Bedien- und Regressionstests aufbauen; Builds und Tests auf allen fünf Zielplattformen vor entsprechenden Freigaben ausführen. Nicht verfügbare Testsysteme ausdrücklich dokumentieren.
6. Grundrechnen und zentrale Bedienfunktionen offline ermöglichen, ohne verpflichtendes Konto, Cloud-Abonnement oder externen Rechendienst. Externe QR-Dienste bleiben optional und getrennt.
7. Eigene Datenformate dokumentieren und versionieren; Quellen, Build-Anleitung und Versionshistorie lokal erhalten. Betriebssystem-Mindestversionen regelmäßig prüfen.

Die geplante automatische Weiterarbeit soll diese Regeln berücksichtigen. Ein erfolgreicher Windows-Build allein ist keine Freigabe für andere Plattformen. Framework-Updates sind eigene überprüfbare Arbeitspakete.

## Nächstes Arbeitspaket: kleiner Machbarkeitstest

Vor umfangreicher Implementierung SDK-Verfügbarkeit und installierte Build-Werkzeuge prüfen, dann einen begrenzten Prototyp erstellen:

- Skaliert eine Rechneransicht auf Desktop und Telefon ohne abgeschnittene Tasten?
- Arbeiten Touch/Maus und physische Tastatur mit denselben Aktionen, einschließlich Fokus und SHIFT/ALPHA?
- Lassen sich verschachtelte Brüche, Wurzeln und Cursorfelder sauber darstellen und bearbeiten?
- Können ein reiner Dart-Kern und einige bestehende Referenzfälle unabhängig von Flutter getestet werden?
- Funktionieren ein Windows-Build und ein Android-Build in der tatsächlich verfügbaren Umgebung?

Abnahme und Abweichungen dokumentieren. Einen nur auf Windows getesteten Prototyp nicht als auf allen Plattformen getestet bezeichnen. Falls der Versuch ein wesentliches Hindernis zeigt, insbesondere beim Editor oder erforderlichen Plugins, Tauri und Compose anhand desselben kleinen Beispiels neu bewerten.
