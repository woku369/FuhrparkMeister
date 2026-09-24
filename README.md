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
│       ├── services/    # NotificationService, DriveSyncService, DocumentStorage
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
- **Offline-fähig**: lokale SQLite-Datenbank als primärer Datenspeicher
- **Lokales ZIP-Backup**: Export/Import ohne jede Einrichtung – Export öffnet die Android-Systemfreigabe (Downloads, E-Mail, andere Cloud-Apps, ...), Import liest eine solche Datei wieder ein
- **Backup & Geräte-Sync über Google Drive**: manueller Voll-Snapshot (Datenbank + Dokumenten-Fotos) in einen eigenen Drive-Ordner hoch- und herunterladen, für Nutzung auf mehreren Geräten

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

Außerdem verlangt `flutter_local_notifications` **Core Library Desugaring** – ohne das bricht `flutter build apk` mit `Execution failed for task ':app:checkReleaseAarMetadata'` ab. An `android/app/build.gradle.kts` anhängen:

```kotlin
android {
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

### Starten / Bauen

```bash
flutter run                    # auf angeschlossenem Android-Gerät
flutter build apk --release    # installierbare APK
```

Die fertige APK liegt danach unter `app/build/app/outputs/flutter-apk/app-release.apk`.

**Update-Fähigkeit / Signierschlüssel:** Damit eine neu gebaute APK die alte auf dem Handy als Update ersetzt (statt "Installation fehlgeschlagen" wegen unterschiedlicher Signatur), müssen beide mit demselben Debug-Key signiert sein. Im Repo liegt dafür ein fester, dauerhafter Debug-Keystore unter `ci/debug.keystore` (Standard-Passwörter `android`/`androiddebugkey`, wie Androids eigener Debug-Keystore – unkritisch, da nur für Sideload-Installationen, nicht für den Play Store). Die CI-Pipeline nutzt ihn automatisch. Für lokale Builds, die mit den CI-Builds austauschbar bleiben sollen, einmalig:

```bash
mkdir -p ~/.android
cp ../ci/debug.keystore ~/.android/debug.keystore   # aus app/ heraus; Windows: %USERPROFILE%\.android\debug.keystore
```

Ohne diesen Schritt signiert die lokale Toolchain mit dem automatisch erzeugten, geräteeigenen Debug-Key – dann lassen sich lokale und CI-gebaute APKs nicht gegenseitig als Update installieren.

### Alternative: APK ohne eigenen PC/Flutter-Installation bauen (z. B. vom Handy aus)

Ein GitHub-Actions-Workflow (`.github/workflows/build-apk.yml`) baut die APK bei jedem Push auf diesen Branch automatisch in der Cloud – auf dem Handy selbst ist dafür kein Flutter nötig:

1. Auf GitHub im Tab **Actions** den Workflow „APK bauen" öffnen und **Run workflow** antippen (geht auch über die GitHub-App oder den mobilen Browser, ganz ohne PC)
2. Nach ca. 3–5 Minuten ist der Build fertig
3. Die APK liegt danach direkt zum Download unter **Releases → „FuhrparkMeister – aktueller Build"** (Tag `latest-apk`) – auf dem Handy antippen, herunterladen, „Installation aus unbekannten Quellen" erlauben, installieren
4. Alternativ liegt die APK auch als Artefakt am jeweiligen Actions-Lauf (verfällt nach 90 Tagen, braucht GitHub-Login und muss entzippt werden – der Release-Download unter Punkt 3 ist der einfachere Weg)

---

## Cloud-Sync einrichten (Google Drive)

Die App nutzt die Google-Drive-API mit dem eingeschränkten Scope `drive.file` –
sie sieht dadurch **nur** die Dateien, die sie selbst in einem eigenen
`FuhrparkMeister`-Ordner in deinem Drive anlegt, nichts anderes im Google-Konto.
Dafür muss einmalig ein eigenes Google-Cloud-Projekt eingerichtet werden
(kann Claude nicht für dich erledigen, da es dein persönliches Google-Konto
betrifft):

1. **Google-Cloud-Projekt anlegen** unter [console.cloud.google.com](https://console.cloud.google.com)
2. **Drive API aktivieren**: *APIs & Dienste → Bibliothek* → „Google Drive API" suchen → aktivieren
3. **OAuth-Zustimmungsbildschirm konfigurieren**: *APIs & Dienste → OAuth consent screen* → „Extern" → App-Name, Support-E-Mail eintragen, dich selbst als **Testnutzer** hinzufügen
4. **SHA-1-Fingerabdruck ermitteln**:
   ```bash
   cd app/android && ./gradlew signingReport
   ```
   (Abschnitt „Variant: debug" → SHA-1 kopieren; für die spätere Release-APK denselben Schritt mit dem Release-Keystore wiederholen)
5. **OAuth-Client-ID erstellen**: *APIs & Dienste → Anmeldedaten → Anmeldedaten erstellen → OAuth-Client-ID* → Typ „Android" → Package-Name (`applicationId` aus `app/android/app/build.gradle`, per Default `at.kraeutermeister.fuhrparkmeister`) + SHA-1 eintragen

### Wichtiger Hinweis zum Testmodus
[Vermutung/Hinweis, Stand der Recherche September 2026, bitte in der aktuellen Google-Cloud-Console gegenprüfen]: Solange der OAuth-Zustimmungsbildschirm auf **„Testing"** steht, laufen ausgestellte Tokens nach **7 Tagen** ab – du müsstest dich dann in der App neu anmelden. Um das zu vermeiden, den Zustimmungsbildschirm auf **„In Produktion"** stellen; bei einem reinen Privat-Tool mit dem eingeschränkten `drive.file`-Scope ist dafür nach bisherigem Kenntnisstand keine Google-Verifizierung nötig, es kann aber weiterhin eine „Unverifizierte App"-Warnung erscheinen, die man beim Login manuell bestätigt. Da sich Googles Richtlinien hierzu ändern können, im Zweifel die aktuelle Google-Cloud-Dokumentation zum OAuth-Zustimmungsbildschirm konsultieren.

### Nutzung in der App
*Backup & Cloud-Sync* (Wolken-Symbol oben rechts im Home-Screen) → „Anmelden" → **Backup jetzt hochladen** bzw. **Backup wiederherstellen**. Es ist ein vollständiger Schnappschuss ohne automatischen Merge: vor dem Gerätewechsel hochladen, auf dem Zielgerät herunterladen.

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
- **Cloud-Sync ist manuell, kein Merge**: Der Google-Drive-Sync überschreibt beim Hochladen/Herunterladen jeweils den kompletten Gegenstand ("letzter Stand gewinnt"). Werden auf zwei Geräten parallel Änderungen gemacht, ohne dazwischen zu synchronisieren, gehen die zuletzt nicht hochgeladenen Änderungen beim nächsten Download verloren. Für einen echten Merge bräuchte es eine feinere Sync-Logik (siehe `ROADMAP.md`).
- **iOS**: nicht Ziel dieser App (analog zu den anderen Meister-Apps im Portfolio).
