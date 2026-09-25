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
- [x] Automatische Build-Versionierung (versionCode = GitHub-Actions-Lauf-Nummer) gegen Paketkonflikte bei der Installation
- [x] Fahrzeugfoto (Kamera/Galerie) - Thumbnail am Homescreen, größer in der Übersicht
- [x] PKW-Zusatzfelder: Leistung (kW), Erstzulassung (Monat/Jahr)
- [x] Fahrzeughalter als Stammdatenfeld
- [x] Versicherungs-Zahlungsintervall + korrekte Fälligkeitsberechnung (Hauptfälligkeit ≠ nächster Zahlungstermin, wird jetzt anhand des Intervalls vorgerückt)
- [x] Homescreen: Fahrzeugliste nach Typ gruppiert (Auto, Anhänger, Fahrrad, ...)
- [x] Installierte Build-Version im Homescreen sichtbar (zum Abgleich mit dem Release)
- [x] Backup-Import per Android-Teilen-Dialog ("Öffnen mit FuhrparkMeister") - für gemeinsam genutzten Familien-Fuhrpark: eine Person exportiert und teilt, andere importieren per Antippen statt Datei-Manager-Umweg
- [x] Fester, dauerhafter APK-Signatur-Keystore, direkt im App-Modul referenziert statt über einen sich als nicht zuverlässig erwiesenen impliziten Konventionspfad
- [x] `android/`-Ordner fest im Repo statt bei jedem CI-Lauf neu generiert - reproduzierbare, direkt inspizierbare Builds; Flutter-Version im CI fest gepinnt
- [x] Datenblatt-Export (PDF, DIN A4) pro Fahrzeug für die physische Papierablage - Stammdaten, Termine, Reifen, Vignetten, Versicherungen, ohne Dokumente/Fotos aus der Galerie

## Offen
- [ ] Google-Cloud-Projekt + OAuth-Client gemäß README einrichten und Login/Upload/Restore einmal real durchtesten
- [ ] App-Icon gestalten (aktuell Standard-Flutter-Icon)
- [ ] Laufendes Kilometerstand-Tracking (aktueller Stand über die Zeit, nicht nur Ankaufswert) – aktuell nur einmaliger Wert bei Ankauf
- [ ] Kostenübersicht (Werkstattrechnungen, Treibstoff) – Wartungs-To-Dos haben aktuell kein Kostenfeld
- [ ] Play-Store-Vorbereitung (Signing-Key, Versionierung) falls gewünscht
- [ ] §57a-Regeländerung ab Mai 2027 berücksichtigen [Nutzerangabe, nicht selbst verifiziert]: kein 4-Monate-Überzug nach Fälligkeit mehr, dafür Prüfung bis zu 4 Monate vor Fälligkeit möglich. App kennt aktuell weder Überzugs- noch Vorzieh-Logik (nur Fälligkeitsdatum + Erinnerung X Tage vorher) – rechtzeitig vor Mai 2027 entscheiden, ob/wie das abgebildet werden soll (z. B. Hinweistext im Formular, frühestmöglicher Prüftermin anzeigen).

## Bewusst nicht geplant
- **Echter Merge-Sync / NAS-Backend** (wie bei `zeiterfassung`): FuhrparkMeister wird selten und unregelmäßig genutzt (Datensammlung, keine Live-Erfassung), das rechtfertigt den Aufwand einer feineren Sync-Logik nicht. Der manuelle Google-Drive-Snapshot reicht für dieses Nutzungsprofil dauerhaft, nicht nur als Übergangslösung.
- **Echtzeit-Mehrbenutzer-Sync für den Familien-Fuhrpark**: Auf Nutzerentscheidung hin bewusst nicht umgesetzt (bräuchte ein eigenes Backend). Stattdessen manueller Snapshot-Austausch: eine Person exportiert (lokales ZIP oder Google Drive), teilt die Datei, die anderen importieren sie ("letzter Stand gewinnt", kein Zusammenführen einzelner Änderungen) - passt zum seltenen Nutzungsprofil.
- **Direkter Schreibzugriff auf den öffentlichen Downloads-Ordner**: Seit Android 10 (Scoped Storage) benötigt das entweder ein neues Plugin (MediaStore/SAF) oder eigenen nativen Code. Genau solche Plugins haben zuletzt (`file_picker`) mehrere Build-Anläufe gekostet, weil eine gemeinsame transitive Abhängigkeit (`flutter_plugin_android_lifecycle`) einen höheren `compileSdk` für das jeweilige Plugin-Subprojekt verlangt, den sich vom App-Modul aus nicht zuverlässig überschreiben ließ. Auf Nutzerentscheidung hin bewusst nicht umgesetzt: Export bleibt im App-eigenen Ordner + Android-Systemfreigabe, "In Downloads speichern" geht dort manuell über die Dateien-App im Freigabe-Dialog.
