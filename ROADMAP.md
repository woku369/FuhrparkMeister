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
- [x] Lokales ZIP-Backup (Export/Import ohne Google-Konto)
- [x] Wartungs-To-Dos je Fahrzeug (unabhängig von Prüfterminen)
- [x] Wartungshistorie-Export (erledigte Prüfungen + To-Dos, teilbar) als Merkliste für z. B. Fahrzeugverkauf
- [x] Kilometerstand bei Ankauf, Anzahl Vorbesitzer als Fahrzeug-Stammdaten

## Offen
- [ ] Erstmaliges `flutter create . --platforms=android` in der Zielumgebung ausführen und `flutter analyze` / `flutter build apk` verifizieren
- [ ] Google-Cloud-Projekt + OAuth-Client gemäß README einrichten und Login/Upload/Restore einmal real durchtesten
- [ ] App-Icon gestalten (aktuell Standard-Flutter-Icon)
- [ ] Laufendes Kilometerstand-Tracking (aktueller Stand über die Zeit, nicht nur Ankaufswert) – aktuell nur einmaliger Wert bei Ankauf
- [ ] Kostenübersicht (Werkstattrechnungen, Treibstoff) – Wartungs-To-Dos haben aktuell kein Kostenfeld
- [ ] Play-Store-Vorbereitung (Signing-Key, Versionierung) falls gewünscht
- [ ] §57a-Regeländerung ab Mai 2027 berücksichtigen [Nutzerangabe, nicht selbst verifiziert]: kein 4-Monate-Überzug nach Fälligkeit mehr, dafür Prüfung bis zu 4 Monate vor Fälligkeit möglich. App kennt aktuell weder Überzugs- noch Vorzieh-Logik (nur Fälligkeitsdatum + Erinnerung X Tage vorher) – rechtzeitig vor Mai 2027 entscheiden, ob/wie das abgebildet werden soll (z. B. Hinweistext im Formular, frühestmöglicher Prüftermin anzeigen).

## Bewusst nicht geplant
- **Echter Merge-Sync / NAS-Backend** (wie bei `zeiterfassung`): FuhrparkMeister wird selten und unregelmäßig genutzt (Datensammlung, keine Live-Erfassung), das rechtfertigt den Aufwand einer feineren Sync-Logik nicht. Der manuelle Google-Drive-Snapshot reicht für dieses Nutzungsprofil dauerhaft, nicht nur als Übergangslösung.
