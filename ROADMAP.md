# Roadmap – FuhrparkMeister

## Erledigt (v1.0)
- [x] Fahrzeugverwaltung (Auto, Anhänger, Motorrad, Wohnwagen, Fahrrad)
- [x] Prüftermine mit lokaler Erinnerung
- [x] Reifenverwaltung (Soll-Dimension, Reifensätze, montiert/im Lager, Wechseltermin)
- [x] Vignetten-Verwaltung mit Ablauf-Erinnerung
- [x] Versicherungen (Polizzennummer, jährliche Fälligkeit) mit Erinnerung
- [x] Dokumenten-Galerie je Fahrzeug (Foto/Kamera oder Galerie)
- [x] Fahrzeugübergreifende Termine-Übersicht
- [x] Manuelles Backup/Restore über Google Drive (Voll-Snapshot, `drive.file`-Scope)

## Offen
- [ ] Erstmaliges `flutter create . --platforms=android` in der Zielumgebung ausführen und `flutter analyze` / `flutter build apk` verifizieren
- [ ] Google-Cloud-Projekt + OAuth-Client gemäß README einrichten und Login/Upload/Restore einmal real durchtesten
- [ ] App-Icon gestalten (aktuell Standard-Flutter-Icon)
- [ ] Google-Drive-Sync auf echten Merge statt Voll-Überschreiben umstellen (z. B. `updated_at`-Vergleich je Datensatz), sobald paralleles Arbeiten auf mehreren Geräten üblich wird
- [ ] Optional: NAS-Sync analog `zeiterfassung/backend` als Alternative/Ergänzung zu Google Drive, falls gewünscht
- [ ] Kilometerstand-Tracking je Fahrzeug
- [ ] Servicehistorie / Kostenübersicht (Werkstattrechnungen, Treibstoff)
- [ ] Play-Store-Vorbereitung (Signing-Key, Versionierung) falls gewünscht
