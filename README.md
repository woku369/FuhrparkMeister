# FuhrparkMeister

Fuhrparkverwaltung für **Autos, Anhänger, Motorräder, Wohnwagen und Fahrräder** – als Android-App (Flutter).

---

## Projektstruktur

```
├── app/          # Flutter-App (Android)
│   └── lib/
│       ├── models/      # Vehicle, TireSet, Inspection, Vignette, Insurance, VehicleDocument
│       ├── database/    # SQLite-Zugriff (sqflite)
│       ├── providers/   # FuhrparkProvider (State, CRUD, Erinnerungen)
│       ├── services/    # NotificationService (flutter_local_notifications)
│       ├── screens/     # Home, Fahrzeug-Formular, Fahrzeug-Detail (Tabs), Termine
│       └── widgets/     # gemeinsame UI-Bausteine
└── ROADMAP.md
```

---

## Features

- **Fahrzeugverwaltung**: Auto, Anhänger, Motorrad, Wohnwagen, Fahrrad – mit Marke, Modell, Kennzeichen, Fahrgestellnummer, Baujahr, Farbe, Kaufdatum
- **Prüftermine mit Erinnerung**: §57a-Begutachtung (Pickerl), Anhängerprüfung, Service, Fahrrad-Check, Sonstiges – lokale Push-Erinnerung X Tage vorher (konfigurierbar)
- **Reifenverwaltung**: benötigte Dimension pro Fahrzeug ("was brauche ich"), erfasste Reifensätze mit Saison, Dimension, Hersteller, Profiltiefe und Status montiert/im Lager ("was ist drauf"), Wechseltermin ("wann")
- **Vignetten**: Jahr, Gültigkeitszeitraum, Preis, digital/klassisch – Erinnerung 14 Tage vor Ablauf
- **Versicherungen**: Gesellschaft, Polizzennummer, Art (Haftpflicht/Teilkasko/Vollkasko), jährliche Fälligkeit, Prämie – Erinnerung 14 Tage vorher
- **Dokumenten-Galerie**: Fotos von Zulassungsschein, Polizze, Rechnungen etc. je Fahrzeug, kategorisiert, lokal gespeichert
- **Termine-Übersicht**: alle offenen Fälligkeiten fahrzeugübergreifend, farblich nach Dringlichkeit sortiert
- **Offline-fähig**: lokale SQLite-Datenbank, keine Cloud-Anbindung

---

## App einrichten (Flutter)

### Voraussetzungen
- Flutter SDK ≥ 3.22
- Android Studio oder VS Code mit Flutter-Extension

### Erstmaliges Setup

Dieses Repo enthält den kompletten Dart-Quellcode (`app/lib/`) und die `pubspec.yaml`, aber **keinen generierten `android/`-Ordner** – der wurde in der Build-Umgebung nicht erzeugt, weil dort kein Flutter-SDK installiert ist. Vor dem ersten Build einmalig:

```bash
cd app
flutter create . --platforms=android --org at.kraeutermeister
flutter pub get
```

`flutter create .` ergänzt in einem bestehenden Projekt nur die fehlenden Plattform-Ordner (hier `android/`) und lässt `lib/` unangetastet.

Danach in `android/app/src/main/AndroidManifest.xml` prüfen, dass folgende Berechtigungen vorhanden sind (werden von den Plugins meist automatisch per Manifest-Merge ergänzt, ein manueller Blick schadet aber nicht):

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.CAMERA"/>
```

### Starten / Bauen

```bash
flutter run                    # auf angeschlossenem Android-Gerät
flutter build apk --release    # installierbare APK
```

Die fertige APK liegt danach unter `app/build/app/outputs/flutter-apk/app-release.apk`.

---

## Datenmodell (Kurzüberblick)

| Tabelle | Zweck |
|---|---|
| `vehicles` | Stammdaten je Fahrzeug (inkl. Soll-Reifendimension) |
| `tire_sets` | Reifensätze je Fahrzeug (Saison, Dimension, montiert/im Lager, Wechseltermin) |
| `inspections` | Prüftermine mit Erinnerungsvorlauf |
| `vignettes` | Vignetten je Fahrzeug und Jahr |
| `insurances` | Versicherungspolizzen je Fahrzeug |
| `documents` | Foto-Galerie je Fahrzeug (Pfad auf lokalem Dateisystem) |

Alle Kind-Tabellen hängen per `ON DELETE CASCADE` an `vehicles` – Fahrzeug löschen entfernt automatisch alle zugehörigen Daten.

---

## Bekannte Einschränkungen

- **Nicht in dieser Umgebung gebaut/getestet**: In der Cloud-Session, die diesen Code erzeugt hat, war kein Flutter-SDK verfügbar. Der Dart-Code wurde sorgfältig nach Konventionen des Schwester-Repos `zeiterfassung` geschrieben, aber weder `flutter pub get` noch `flutter analyze` noch ein echter Build konnten hier ausgeführt werden. Vor dem ersten Release-Build lokal `flutter analyze` laufen lassen.
- **Zeitzone für Erinnerungen** ist fest auf `Europe/Vienna` codiert.
- **Kein NAS-Sync**: Anders als bei `zeiterfassung` gibt es (noch) keine Backend-Synchronisation – alle Daten liegen ausschließlich lokal auf dem Gerät. Siehe `ROADMAP.md`.
- **iOS**: nicht Ziel dieser App (analog zu den anderen Meister-Apps im Portfolio).
