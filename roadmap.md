# Diskman - roadmapa projektu

Ten plik jest robocza mapa projektu. Aktualizujemy go po kazdym wiekszym kroku, zeby bylo jasne, co juz dziala, co jest w trakcie i co blokuje kolejne etapy.

Statusy:

- `[ ]` do zrobienia
- `[~]` w trakcie
- `[x]` gotowe
- `[!]` zablokowane albo wymaga decyzji

## Cel MVP

Pierwsza dzialajaca wersja Diskman ma:

- dzialac jako aplikacja macOS w pasku menu,
- stale zbierac informacje o podlaczonych dyskach,
- zapisywac snapshot danych dla widgetow,
- pokazywac maly widget z okraglymi wskaznikami wolnego miejsca,
- pokazywac duzy widget z paskiem `used/free`,
- miec menu z `Refresh`, `Language`, `About`, `Quit Diskman`,
- wspierac jezyk systemowy oraz reczny wybor `English` / `Polski`,
- dac sie zbudowac lokalnie i zainstalowac z GitHub Release przez prosty terminalowy skrypt.

## Etap 0 - Fundament repo

- [x] Zainicjalizowac lokalne repo git w katalogu projektu.
- [x] Podpiac remote `https://github.com/zzzielinski/diskman.git`.
- [x] Ustalic glowna galaz: `main`.
- [x] Dodac `.gitignore` dla Xcode, SwiftPM, build artefaktow i macOS.
- [x] Dodac podstawowy `README.md`.
- [x] Dodac licencje open source.
- [x] Ustalic bundle identifier: `com.zzzielinski.diskman`.
- [x] Ustalic minimalny deployment target dla MVP: macOS 26+ jako primary target.
- [x] Wypchnac pierwsza wersje dokumentacji na GitHub.

Done kiedy:

- repo lokalne i GitHub sa zsynchronizowane,
- `README.md`, `info.md`, `roadmap.md`, `.gitignore` i licencja sa w `main`,
- da sie zaczac tworzyc projekt Xcode bez balaganu w strukturze.

## Etap 1 - Szkielet aplikacji macOS

- [x] Utworzyc projekt Xcode `Diskman`.
- [x] Dodac target aplikacji macOS `DiskmanApp`.
- [x] Dodac target `DiskmanWidgets` dla WidgetKit.
- [x] Dodac modul/core package `DiskmanCore`.
- [x] Skonfigurowac App Group dla aplikacji i widget extension.
- [x] Dodac podstawowa aplikacje menu bar bez glownego okna.
- [x] Dodac `NSStatusItem` z ikona w pasku menu.
- [x] Dodac minimalne menu:
  - [x] `Refresh Now`
  - [x] `Language`
  - [x] `About Diskman`
  - [x] `Quit Diskman`
- [x] Dodac placeholder ekranu About.

Done kiedy:

- aplikacja uruchamia sie lokalnie,
- widac ikone Diskman w menu barze,
- `Quit Diskman` zamyka aplikacje,
- target widgetu kompiluje sie razem z aplikacja.

## Etap 2 - Core danych o dyskach

- [x] Zdefiniowac modele:
  - [x] `DiskSnapshot`
  - [x] `VolumeSnapshot`
  - [x] `VolumeKind`
  - [x] `StorageCategorySnapshot`
  - [x] `StorageCategoryID`
- [x] Zrobic `ByteFormatter` dla GB/GiB i lokalizowanych stringow.
- [x] Zrobic `VolumeProvider` oparty o `FileManager.mountedVolumeURLs`.
- [x] Pobierac dla kazdego wolumenu:
  - [x] nazwe,
  - [x] lokalizowana nazwe, jesli system ja zwroci,
  - [x] mount path,
  - [x] total bytes,
  - [x] available bytes,
  - [x] used bytes,
  - [x] file system description,
  - [x] informacje browsable/internal/ejectable/removable, jesli dostepne.
- [x] Odfiltrowac techniczne wolumeny, ktorych uzytkownik nie powinien widziec.
- [x] Dodac klasyfikacje:
  - [x] internal,
  - [x] external,
  - [x] removable,
  - [x] network,
  - [x] disk image,
  - [x] unknown.
- [x] Dodac testy jednostkowe dla obliczania procentow i formatowania bajtow.

Done kiedy:

- core potrafi zwrocic poprawna liste widocznych dyskow,
- dla kazdego dysku mamy `used/free/total`,
- testy core przechodza lokalnie.

## Etap 3 - Snapshot i komunikacja z widgetem

- [x] Zrobic `StorageSnapshotStore`.
- [x] Zapisywac snapshot jako JSON albo plist w App Group container.
- [x] Czytac snapshot z aplikacji i widget extension.
- [x] Dodac fallback snapshot dla pustego stanu.
- [x] Dodac obsluge bledow odczytu/zapisu.
- [x] Po zapisaniu snapshotu wolac `WidgetCenter.reloadAllTimelines()`.
- [x] Dodac testy encode/decode snapshotu.

Done kiedy:

- aplikacja zapisuje snapshot po starcie,
- widget moze odczytac snapshot bez uruchamiania aplikacji,
- brak danych pokazuje ladny empty state zamiast crasha.

## Etap 4 - Monitoring w tle

- [x] Dodac `DiskMonitor`.
- [x] Dodac polling co 30-60 sekund dla zmian wolnego miejsca.
- [x] Dodac reczny refresh z menu bar.
- [x] Dodac Disk Arbitration dla mount/unmount/eject.
- [x] Po zdarzeniu dysku odswiezac snapshot.
- [x] Dodac debounce, zeby kilka eventow naraz nie robilo wielu refreshy.
- [x] Dodac OSLog dla waznych eventow.

Done kiedy:

- podlaczenie dysku aktualizuje snapshot,
- odlaczenie dysku aktualizuje snapshot,
- zmiana wolnego miejsca odswieza sie okresowo,
- reczny refresh dziala z menu.

## Etap 5 - Maly widget

- [x] Zrobic widget family dla malego widoku.
- [x] Zbudowac komponent `DiskRingView`.
- [x] Pokazywac procent wolnego miejsca.
- [x] Pokazywac ikone typu dysku.
- [x] Obsluzyc 1, 2, 3 i 4+ dyski.
- [x] Dobrac kolory statusu:
  - [x] ok,
  - [x] warning,
  - [x] critical.
- [x] Dodac glass/fallback material.
- [x] Dodac accessibility labels.
- [ ] Przetestowac jasny i ciemny tryb.

Done kiedy:

- maly widget pokazuje aktualne dyski,
- layout nie przeskakuje przy zmianie procentow,
- widok jest czytelny na pulpicie i w Notification Center.

## Etap 6 - Duzy widget

- [x] Zrobic sredni/duzy wariant widgetu.
- [x] Zbudowac komponent `StorageSegmentBar`.
- [x] Dla MVP pokazywac segmenty:
  - [x] `Used`
  - [x] `Available`
- [x] Pokazywac nazwe dysku.
- [x] Pokazywac tekst `X free of Y`.
- [x] Dodac legende.
- [x] Obsluzyc wiele dyskow w duzym wariancie.
- [x] Dodac empty/error states.
- [x] Dodac accessibility labels dla segmentow.

Done kiedy:

- duzy widget przypomina logika widok z macOS Storage,
- dane sa prawdziwe,
- brak kategorii systemowych jest jasno rozwiazany przez `Used/Available` w MVP.

## Etap 7 - Liquid Glass i design polish

- [ ] Dodac wrapper/modifier `DiskmanGlass`.
- [ ] Na macOS 26+ uzyc `glassEffect(_:in:)`.
- [ ] Na starszych systemach uzyc fallbacku `.ultraThinMaterial`.
- [ ] Dopracowac ksztalty:
  - [ ] ringi,
  - [ ] segment bar,
  - [ ] menu popover,
  - [ ] about/settings.
- [ ] Ustalic finalna palete kolorow kategorii.
- [ ] Dobrac SF Symbols dla typow dyskow.
- [ ] Sprawdzic teksty na PL i EN.
- [ ] Zrobic screenshoty referencyjne.

Done kiedy:

- UI wyglada spojnie z macOS,
- widget nie jest krzykliwy,
- Liquid Glass ma fallback i nie blokuje builda na starszym targetcie, jesli taki wspieramy.

## Etap 8 - Jezyk i lokalizacja

- [ ] Dodac String Catalog albo `Localizable.strings`.
- [ ] Dodac jezyki:
  - [ ] English
  - [ ] Polski
- [ ] Dodac tryb jezyka:
  - [ ] System
  - [ ] English
  - [ ] Polski
- [ ] Zlokalizowac menu bar.
- [ ] Zlokalizowac widgety.
- [ ] Zlokalizowac kategorie MVP:
  - [ ] Used
  - [ ] Available
  - [ ] Other
  - [ ] System Data
- [ ] Zrobic `LocalizationProvider`, zeby widoki nie trzymaly tekstow kategorii na sztywno.

Done kiedy:

- aplikacja odpala sie w jezyku systemu,
- uzytkownik moze wymusic PL albo EN,
- widget i menu uzywaja tych samych tlumaczen.

## Etap 9 - Ustawienia i About

- [ ] Dodac okno/panel Settings.
- [ ] Dodac ustawienie `Launch at Login`.
- [ ] Dodac ustawienie jezyka.
- [ ] Dodac wybor typow dyskow:
  - [ ] internal,
  - [ ] external,
  - [ ] network,
  - [ ] disk images.
- [ ] Dodac ustawienie `show free percent` / `show used percent`.
- [ ] Dodac wybor GB/GiB.
- [ ] Dodac About:
  - [ ] nazwa,
  - [ ] wersja,
  - [ ] link do GitHuba,
  - [ ] licencja,
  - [ ] privacy note.

Done kiedy:

- podstawowe ustawienia sa zapisywane w `UserDefaults`,
- zmiana ustawien odswieza snapshot i widget,
- About jest gotowy pod open source.

## Etap 10 - Kategorie zajetosci

Ten etap nie blokuje MVP. Robimy go dopiero, gdy `used/free` dziala stabilnie.

- [ ] Ustalic zakres scanner kategorii.
- [ ] Dodac tryb `Categories: Off / Basic / Estimated`.
- [ ] Dodac cache wynikow skanowania.
- [ ] Dodac scanner `Applications`.
- [ ] Dodac scanner `Developer`.
- [ ] Dodac scanner `Documents`.
- [ ] Dodac scanner `Photos`.
- [ ] Dodac scanner `Messages`, tylko jesli uprawnienia pozwalaja.
- [ ] Dodac `System Data` / `Other` jako reszte.
- [ ] Dodac confidence label: `Estimated`.
- [ ] Dodac privacy screen opisujacy skanowanie.
- [ ] Dodac testy na sztucznych katalogach.

Done kiedy:

- kategorie sa opcjonalne,
- scanner nie mieli dysku agresywnie,
- uzytkownik rozumie, ze kategorie sa szacowane, a nie identyczne z System Settings.

## Etap 11 - Instalacja i release

- [ ] Dodac `scripts/install.sh`.
- [ ] Dodac `scripts/uninstall.sh`.
- [ ] Dodac build/release instrukcje w README.
- [ ] Dodac GitHub Actions dla builda.
- [ ] Dodac testy w CI.
- [ ] Przygotowac artefakt `Diskman.app.zip`.
- [ ] Dodac checksumy release.
- [ ] Ustalic signing/notarization:
  - [ ] unsigned dev release,
  - [ ] signed release,
  - [ ] notarized release.
- [ ] Przygotowac pierwszy GitHub Release `v0.1.0`.
- [ ] Docelowo przygotowac Homebrew Cask.

Done kiedy:

- uzytkownik moze zainstalowac Diskman przez terminal,
- release ma jasna instrukcje,
- aplikacja uruchamia sie po pobraniu bez recznych krokow poza standardowymi ograniczeniami Gatekeepera.

## Etap 12 - QA przed v0.1

- [ ] Test na glownym dysku systemowym.
- [ ] Test z pendrivem.
- [ ] Test z zewnetrznym SSD.
- [ ] Test z DMG.
- [ ] Test z dyskiem sieciowym.
- [ ] Test odlaczenia dysku podczas pracy.
- [ ] Test niskiego miejsca.
- [ ] Test 4+ dyskow.
- [ ] Test jasny/ciemny tryb.
- [ ] Test jezyka PL/EN/System.
- [ ] Test startu po loginie.
- [ ] Test po restarcie maca.
- [ ] Test widgetu bez uruchomionej aplikacji.

Done kiedy:

- brak crashy w podstawowych scenariuszach,
- dane w widgetach zgadzaja sie z Finder/System Settings w granicach normalnych roznic API,
- README opisuje znane ograniczenia.

## Aktualny status

- [x] Powstal dokument analizy projektu: `info.md`.
- [x] Powstala roadmapa projektu: `roadmap.md`.
- [x] Repo lokalne zostalo zainicjalizowane jako git.
- [x] Repo GitHub `zzzielinski/diskman` istnieje i ma dokumentacje startowa.
- [x] Powstal szkielet projektu Xcode z appka, widgetami i `DiskmanCore`.

## Najblizszy nastepny krok

1. Wizualnie sprawdzic widgety small/medium/large w jasnym i ciemnym trybie.
2. Zaczac Etap 7: Liquid Glass i design polish.
3. Wyciagnac wspolny wrapper/modifier `DiskmanGlass`.
