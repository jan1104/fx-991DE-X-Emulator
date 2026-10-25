# Unabhängiger Rechenkern

Erster lauffähiger Prototyp als reines Dart-Paket, unabhängig von Flutter und Betriebssystemzugriffen in der Bibliothek.

Implementiert sind gekürzte BigInt-Brüche, exakte Punkt-/Komma-Dezimaleingabe mit optionalem Dezimalexponenten, Ausdrucksbaum und lineare Auswertung von Grundoperatoren, Klammern und ganzzahligen Potenzen. Potenzen sind rechtsassoziativ und binden vor negativem Vorzeichen. Implizite Multiplikation ist zunächst nur vor einer öffnenden Klammer möglich und bindet vor expliziter Multiplikation/Division. Beispiele: `-2^2=-4`, `2/3+(1+1/2)=13/6`, `0,1+0,2=3/10`.

Das Paket hat keine externen Laufzeitabhängigkeiten; `package:test` ist nur Entwicklungsabhängigkeit. SDK und Testversion stehen in `../../tools/toolchain.json`, die konkrete Auflösung in `pubspec.lock`.

Mit Dart 3.13.7 im Paketordner:

```text
dart pub get --enforce-lockfile
dart analyze
dart test
dart run bin/calculate.dart "2/3 + (1+1/2)"
```

Alternativ unter PowerShell vom Repository aus: `./tools/test_core.ps1 -DartPath <Pfad-zu-dart.exe>`. Das CLI ist nur ein Demonstrationsadapter; die Bibliothek selbst verwendet kein `dart:io`.

Noch nicht implementiert: Flutter-Oberfläche, physische Tastensequenzen, natürlicher Formeleditor, Variablen/Ans/Speicher, Zustandsmaschine, Rundungs-/Casio-Ausgaberegeln, trigonometrische Funktionen und weitere Modi. Eingabelänge, Verschachtelung und Rechengröße sind mit eigenen Ressourcenbudgets begrenzt; diese sind keine Casio-Hardwaregrenzen. `0^0` und nichtganzzahlige Potenzen werden im Evaluator vorerst als nicht unterstützt gemeldet. Das Zahlenmodell allein verwendet für die nullte Potenz die algebraische Konvention 1.

Der tatsächliche Prüfstand steht in [ENTWICKLUNGSSTAND.md](../../docs/ENTWICKLUNGSSTAND.md). Die umfangreichen Referenzkataloge bleiben Planungsdaten; eine bestandene Coreprüfung bedeutet keinen bestandenen UI-/Originalvergleich.

Siehe [Projektstruktur](../../docs/PROJEKTSTRUKTUR.md).
