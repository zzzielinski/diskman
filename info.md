# Diskman - analiza projektu

## Cel projektu

Diskman ma być lekką, open source'ową aplikacją dla macOS, która działa stale w tle, monitoruje aktualnie podłączone dyski i pokazuje ich zajętość w estetycznych widgetach inspirowanych Apple Liquid Glass.

Projekt ma mieć trzy widoczne części:

1. Aplikacja działająca w tle, odpowiedzialna za zbieranie danych o dyskach.
2. Widgety na pulpit macOS:
   - mały widget z okrągłymi wskaźnikami procentowymi dla dysków,
   - duży widget z rozpisanym paskiem zajętości, kategoriami i legendą.
3. Ikona w pasku menu macOS z podstawowymi opcjami: `Quit Diskman`, `Language`, `About`, `Refresh`, ewentualnie `Launch at Login` i szybkie ustawienia widoczności dysków.

Docelowa nazwa repozytorium: `diskman`.

## Założenia UX

Styl ma iść w stronę Apple'owego szkła: półprzezroczystość, rozmycie tła, miękkie światło, spokojny kontrast i animacje reagujące na pointer. Nie kopiujemy dosłownie zrzutów ekranu, tylko bierzemy z nich logikę:

- zrzut z ustawień macOS: poziomy pasek zajętości podzielony na kategorie,
- zrzut od peryferiów: okrągłe wskaźniki procentowe,
- zrzut z paska menu: mała, systemowa ikona w menu barze.

Interfejs powinien być bardziej dopracowany niż surowy systemowy wykres:

- czytelne ikony dysków: internal SSD, external drive, network disk, removable/USB,
- spokojna paleta kategorii, bez krzykliwego efektu "random rainbow",
- subtelne glass/tint zależne od tapety i trybu jasny/ciemny,
- brak ciężkich kart wewnątrz kart,
- stabilne wymiary elementów, żeby widget nie przeskakiwał przy zmianie danych,
- status "ostatnia aktualizacja" tylko w dużym widoku lub w menu, żeby mały widget pozostał czysty.

## Ważne ograniczenie: "real time" a WidgetKit

Oficjalny widget macOS nie działa jak zwykły proces renderujący UI w każdej sekundzie. WidgetKit dostaje od aplikacji dane przez timeline/snapshot, a system decyduje, kiedy dokładnie odświeżyć widok. To oznacza:

- prawdziwy monitoring w czasie rzeczywistym robimy w głównej aplikacji menu bar,
- widget pokazuje ostatni zapisany snapshot,
- po zmianie dysków aplikacja wymusza odświeżenie przez `WidgetCenter.reloadAllTimelines()`,
- dodatkowo robimy okresowe odświeżanie, np. co 30-60 sekund w aplikacji i co kilka minut w timeline widgetu,
- nie obiecujemy sekundowej dokładności w samym WidgetKit, bo macOS może ograniczać częstotliwość.

Jeśli później będziemy chcieli naprawdę "live" widok na pulpicie, alternatywą jest osobny floating desktop panel w AppKit/SwiftUI. To jednak nie byłby natywny widget dodawany przez system, tylko okno przypięte do pulpitu. Na start lepsza jest droga natywna: WidgetKit plus background collector.

## Technologie

Rekomendowany stack:

- Swift 6 lub aktualny Swift z Xcode.
- SwiftUI dla UI aplikacji, widgetów i ekranu About/Settings.
- WidgetKit dla natywnych widgetów na pulpit i Notification Center.
- AppKit przez `NSStatusItem` dla ikony i menu w górnym pasku macOS.
- Foundation `FileManager` i `URLResourceValues` do listowania wolumenów i pobierania pojemności.
- Disk Arbitration do szybkiej reakcji na mount/unmount/eject oraz zmiany nazw wolumenów.
- App Groups do współdzielenia snapshotu danych między aplikacją a widget extension.
- ServiceManagement `SMAppService` do opcji `Launch at Login`.
- OSLog do logów diagnostycznych.
- Swift Package Manager dla warstwy core i testów jednostkowych.

Liquid Glass:

- na macOS Tahoe 26+ używamy SwiftUI `glassEffect(_:in:)`, `Glass`, `GlassEffectContainer` i standardowych komponentów systemowych,
- na starszych systemach używamy fallbacku: `.background(.ultraThinMaterial)`, rounded rectangle, subtelny stroke i cień,
- kod UI powinien być warunkowany availability checks, żeby projekt nie rozpadał się na starszym macOS.

## Minimalne wersje systemu

Proponowany podział:

- najlepsze doświadczenie: macOS Tahoe 26+ ze względu na Liquid Glass,
- minimalne wsparcie techniczne: macOS 14+ lub macOS 15+, bo desktop widgets i współczesny SwiftUI/WidgetKit są tam sensownie dostępne,
- jeśli chcemy zmniejszyć koszt utrzymania MVP, startujemy od macOS 15+ lub 26+ i dopiero później dodajemy fallbacki.

Decyzja MVP:

- `Diskman 0.1`: macOS 26+ jako primary target, żeby projekt od razu wyglądał jak Liquid Glass.
- `Diskman 0.2+`: fallback wizualny dla starszego macOS, jeśli będzie realne zapotrzebowanie.

## Architektura

Proponowane moduły:

```text
Diskman/
  DiskmanApp/               # menu bar app + settings/about
  DiskmanWidgets/           # WidgetKit extension
  DiskmanCore/              # modele, collector, formattery, storage, lokalizacja
  DiskmanCLI/               # opcjonalny helper do debugowania i install scriptów
  scripts/
    install.sh
    uninstall.sh
  README.md
  info.md
```

Warstwy logiczne:

- `DiskMonitor`: monitoruje pojawianie się i znikanie dysków.
- `VolumeProvider`: pobiera listę wolumenów i surowe wartości systemowe.
- `VolumeClassifier`: rozpoznaje typ dysku, np. internal, external, network, removable, Time Machine.
- `StorageSnapshotStore`: zapisuje ostatni snapshot do App Group container jako JSON lub plist.
- `WidgetTimelineProvider`: czyta snapshot i buduje widoki widgetów.
- `CategoryScanner`: opcjonalnie skanuje kategorie zajętości.
- `LocalizationProvider`: wybiera język i mapuje nazwy kategorii.
- `MenuBarController`: obsługuje ikonę, menu i akcje aplikacji.

## Model danych

Przykładowy model core:

```swift
struct DiskSnapshot: Codable, Hashable {
    let generatedAt: Date
    let volumes: [VolumeSnapshot]
}

struct VolumeSnapshot: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let localizedName: String?
    let mountPath: String
    let kind: VolumeKind
    let fileSystemName: String?
    let totalBytes: Int64
    let availableBytes: Int64
    let usedBytes: Int64
    let importantAvailableBytes: Int64?
    let categories: [StorageCategorySnapshot]
}

struct StorageCategorySnapshot: Codable, Hashable, Identifiable {
    let id: StorageCategoryID
    let localizedName: String
    let colorToken: String
    let bytes: Int64
    let confidence: CategoryConfidence
}
```

Ważne: procent w kółku powinien domyślnie oznaczać wolne miejsce, bo tak opisałeś projekt. Możemy też dodać ustawienie `Show free space` / `Show used space`, ale domyślne zachowanie: `availableBytes / totalBytes`.

## Pobieranie listy dysków

Podstawowe API:

- `FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys:options:)`,
- klucze `URLResourceKey`: `volumeNameKey`, `volumeLocalizedNameKey`, `volumeTotalCapacityKey`, `volumeAvailableCapacityKey`, `volumeAvailableCapacityForImportantUsageKey`, `volumeIsBrowsableKey`, `volumeIsInternalKey`, `volumeIsEjectableKey`, `volumeIsRemovableKey`, `volumeLocalizedFormatDescriptionKey`.

Logika:

1. Pobierz wszystkie zamontowane wolumeny.
2. Odfiltruj techniczne/systemowe wolumeny, które nie powinny być pokazywane użytkownikowi:
   - niebrowsable,
   - automounted,
   - synthetic/system helper volumes,
   - mounty bez sensownej pojemności.
3. Zachowaj główny dysk systemowy, dyski zewnętrzne, pendrive'y, karty SD, dyski sieciowe i obrazy DMG, jeśli są browsable.
4. Dla każdego wolumenu oblicz:
   - total,
   - available,
   - used,
   - free percent,
   - used percent,
   - rodzaj dysku,
   - display name.
5. Snapshot zapisz do współdzielonego kontenera.
6. Poproś WidgetKit o refresh.

Fallback:

- jeśli `URLResourceValues` nie odda pełnych danych, użyć `statfs`.

## Reakcja na zmiany w czasie działania

Potrzebujemy trzech mechanizmów, bo każdy łapie trochę inne przypadki:

- Disk Arbitration:
  - mount,
  - unmount,
  - eject,
  - zmiana nazwy/description dysku.
- Periodic polling:
  - np. co 30 sekund,
  - łapie zmianę wolnego miejsca nawet bez mount/unmount.
- Manual refresh:
  - opcja w menu bar,
  - przydatne do debugowania i dla użytkownika.

Flow:

```text
Disk event albo timer
  -> VolumeProvider.refresh()
  -> DiskSnapshot
  -> StorageSnapshotStore.write()
  -> WidgetCenter.reloadAllTimelines()
  -> menu bar popover/status updates
```

## Kategorie zajętości

To jest najtrudniejsza część projektu.

macOS Settings pokazuje kategorie typu Applications, Documents, Developer, Photos, Messages, System Data. Apple nie udostępnia stabilnego publicznego API, które pozwala aplikacji zewnętrznej pobrać dokładnie te same kategorie i te same lokalizowane nazwy z panelu Storage. Dlatego nie powinniśmy udawać, że w MVP da się 1:1 sklonować System Settings.

Proponowane podejście:

### MVP

Pokazujemy dla każdego dysku:

- użyte,
- wolne,
- purgeable/important/opportunistic available, jeśli API zwróci dane,
- typ dysku.

Duży widget ma pasek:

- `Used`,
- `Available`,
- opcjonalnie `Purgeable/Available for opportunistic usage`, jeśli wartości są sensowne.

### Wersja 0.2

Dodajemy własny, ostrożny scanner kategorii:

- Applications: `/Applications`, `~/Applications`, pliki `.app`,
- Developer: `~/Developer`, Xcode DerivedData, SwiftPM cache, node_modules, repozytoria,
- Photos: biblioteki Photos, obrazy i wideo w znanych lokalizacjach,
- Documents: Documents, Desktop, Downloads i typy dokumentów,
- Messages: załączniki Messages, jeśli użytkownik nada uprawnienia,
- System Data: reszta lub kategorie nierozpoznane.

Scanner musi być:

- opt-in,
- throttlowany,
- cache'owany,
- odporny na permission denied,
- z informacją o dokładności, np. `Estimated`.

Nie skanujemy agresywnie całego dysku bez zgody użytkownika. To byłoby wolne, energożerne i prywatnościowo średnie.

## Lokalizacja i język

Priorytet:

1. Automatycznie wykryj język systemu przez `Locale.current` / `Bundle.main.preferredLocalizations`.
2. Użyj `Localizable.strings` albo String Catalog (`.xcstrings`) dla UI aplikacji, menu i kategorii.
3. Pozwól użytkownikowi wymusić język:
   - `System`,
   - `English`,
   - `Polski`.

Kategorie nie powinny być hardcodowane jako tekst w widokach. W kodzie używamy stabilnych ID:

```swift
enum StorageCategoryID: String, Codable {
    case applications
    case documents
    case developer
    case photos
    case messages
    case systemData
    case other
    case used
    case available
}
```

Widok prosi `LocalizationProvider` o nazwę dla ID. Dzięki temu w przyszłości można dodać kolejne języki bez ruszania logiki.

Jeśli macOS zwróci lokalizowaną nazwę wolumenu przez `volumeLocalizedNameKey`, używamy jej. Nazw kategorii z System Settings raczej nie pobierzemy publicznym API, więc tłumaczymy własne kategorie.

## Mały widget

Cel: szybki podgląd wolnego miejsca.

Układ:

- glass container,
- maksymalnie 3-4 dyski w jednym widoku,
- każdy dysk jako okrągły progress ring,
- ikona w środku,
- procent pod spodem,
- minimalny tekst, np. tylko procent albo skrócona nazwa przy hover/large accessibility label.

Logika prezentacji:

- jeśli jest jeden dysk: większy ring,
- jeśli są 2-3 dyski: równe ringi,
- jeśli więcej niż 4: pokaż 3 najważniejsze i czwarty slot jako `+N`,
- kolor ringu:
  - zielony: dużo wolnego miejsca,
  - żółty: ostrzeżenie,
  - czerwony: mało wolnego miejsca,
  - neutralny niebiesko/szary dla dysków sieciowych lub offline cache.

Progi:

- >= 25% free: ok,
- 10-25% free: warning,
- < 10% free: critical.

## Duży widget

Cel: bardziej szczegółowa rozpiska podobna do macOS Storage.

Układ:

- nazwa dysku,
- `X GB free of Y GB` albo lokalizowany odpowiednik,
- segmentowany pasek zajętości,
- legenda kategorii,
- lista kilku dysków albo szczegóły jednego wybranego dysku.

Proponowane warianty:

- `systemMedium`: 1 wybrany dysk z paskiem i legendą,
- `systemLarge`: 2-3 dyski, każdy z własnym paskiem,
- konfiguracja widgetu przez App Intent: wybór dysku albo `All disks`.

Pasek:

- segmenty sortowane malejąco po rozmiarze,
- minimalna szerokość wizualna dla małych segmentów, ale tooltip/accessibility powinny mieć prawdziwe wartości,
- wolne miejsce po prawej jako osobny neutralny segment,
- etykieta centralna tylko wtedy, gdy się mieści.

## Menu bar

Ikona w górnym pasku macOS:

- symbol SF Symbols, np. `externaldrive`, `internaldrive`, `chart.pie`,
- stan ostrzegawczy, gdy któryś dysk ma mało miejsca,
- menu:
  - `Refresh Now`,
  - `Open Settings`,
  - `Language`,
    - `System`,
    - `English`,
    - `Polski`,
  - `Show Internal Drives`,
  - `Show External Drives`,
  - `Show Network Volumes`,
  - `Launch at Login`,
  - `About Diskman`,
  - `Quit Diskman`.

Można też dodać kliknięcie ikony jako mały popover z listą dysków i mini paskami.

## Ustawienia

Pierwszy zakres:

- język,
- launch at login,
- które typy dysków pokazywać,
- domyślny dysk dla dużego widgetu,
- free percent vs used percent,
- jednostki: decimal GB albo binary GiB,
- tryb kategorii:
  - Off,
  - Basic,
  - Estimated scanner.

Drugi zakres:

- cache scanner,
- reset cache,
- privacy screen z opisem, co jest skanowane,
- eksport diagnostyczny bez danych osobowych.

## Prywatność i uprawnienia

Diskman powinien być bardzo spokojny prywatnościowo:

- domyślnie nie wysyła żadnych danych,
- nie ma backendu,
- nie zbiera analytics,
- snapshot dla widgetu zawiera tylko nazwy dysków, ścieżki mount pointów i rozmiary,
- scanner kategorii jest opcjonalny,
- jeśli scanner wymaga dostępu do katalogów użytkownika, pokazujemy jasny komunikat,
- jeśli używamy API objętych Required Reason API, dodajemy `PrivacyInfo.xcprivacy` z właściwym powodem.

Warto w README dodać osobną sekcję `Privacy`.

## Dystrybucja open source

Repo:

```text
github.com/<owner>/diskman
```

Instalacja "jak prosi z GitHuba":

Opcja MVP:

```bash
curl -fsSL https://raw.githubusercontent.com/<owner>/diskman/main/scripts/install.sh | bash
```

Co robi `install.sh`:

1. Wykrywa architekturę macOS.
2. Pobiera najnowszy release z GitHub Releases.
3. Rozpakowuje `Diskman.app`.
4. Przenosi aplikację do `/Applications` albo `~/Applications`.
5. Uruchamia aplikację.
6. Wyświetla instrukcję dodania widgetu na pulpit.

Docelowo lepsza opcja:

```bash
brew install --cask diskman
```

Do tego potrzebny będzie Homebrew tap albo PR do Homebrew Cask, gdy projekt będzie stabilny.

Ważne dla macOS:

- najlepiej podpisywać i notarizować aplikację,
- bez notarizacji Gatekeeper może ostrzegać użytkowników,
- open source nie wyklucza podpisywania, ale wymaga konta Apple Developer.

## Build i release

Proponowany pipeline GitHub Actions:

- build na `macos-latest`,
- testy `DiskmanCore`,
- archiwizacja `.app`,
- podpisywanie, jeśli dostępne sekrety,
- notarization, jeśli dostępne sekrety,
- tworzenie `.zip` albo `.dmg`,
- publikacja GitHub Release.

Artefakty:

- `Diskman.app.zip`,
- checksum `SHA256SUMS`,
- opcjonalnie `.dmg`,
- `install.sh`.

## Testy

Testy jednostkowe:

- formatowanie bajtów,
- obliczanie procentów,
- sortowanie dysków,
- mapowanie kategorii,
- lokalizacja kategorii,
- zapis i odczyt snapshotu.

Testy integracyjne/manualne:

- dysk wewnętrzny,
- pendrive/USB SSD,
- DMG,
- dysk sieciowy,
- eject podczas działania aplikacji,
- zmiana języka,
- brak uprawnień do skanowania,
- bardzo mało miejsca,
- więcej niż 4 dyski.

## Roadmapa

### 0.1 - MVP

- menu bar app,
- wykrywanie dysków,
- snapshot do App Group,
- mały widget z ringami,
- duży widget z paskiem used/free,
- język System/English/Polski,
- instalacja przez GitHub Release i `install.sh`.

### 0.2 - Kategorie basic

- podstawowy scanner kategorii,
- cache wyników,
- szacowana legenda w dużym widgetcie,
- ustawienia prywatności.

### 0.3 - Dopieszczenie UX

- App Intent do wyboru konkretnego dysku w widgetcie,
- lepsze ikony,
- ostrzeżenia o niskim miejscu,
- popover w menu barze,
- Homebrew cask.

### 1.0

- podpisany i notarizowany release,
- stabilne API core,
- kompletna dokumentacja,
- sensowne testy i manual QA matrix,
- dopracowany wygląd Liquid Glass.

## Ryzyka techniczne

Największe ryzyka:

- WidgetKit nie daje pełnego real-time renderingu.
- Kategorie macOS Storage nie są publicznie dostępne 1:1.
- Skanowanie katalogów może być wolne i wymagać uprawnień.
- Liquid Glass wymaga nowego SDK/systemu, więc potrzebny jest fallback albo wysoki deployment target.
- App Group i WidgetKit wymagają poprawnej konfiguracji signing/capabilities.
- Dystrybucja poza App Store wymaga uwagi przy podpisywaniu i notarization.

## Decyzje proponowane na start

1. Budujemy natywną aplikację macOS w SwiftUI + AppKit menu bar.
2. Widgety robimy przez WidgetKit, a background collector działa w głównej aplikacji.
3. MVP pokazuje realne dane o dyskach: total, used, free, percent.
4. Kategorie robimy najpierw jako `Used/Available`, a dopiero potem dokładamy estimated category scanner.
5. Język jest oparty o system, z override `English` / `Polski`.
6. Repo nazywa się `diskman`, a instalacja idzie przez GitHub Releases i `scripts/install.sh`.

## Źródła techniczne

- Apple Developer: SwiftUI `Glass` i Liquid Glass: https://developer.apple.com/documentation/swiftui/glass
- Apple Developer: `glassEffect(_:in:)`: https://developer.apple.com/documentation/swiftui/view/glasseffect%28_%3Ain%3A%29
- Apple Developer: WidgetKit na macOS: https://developer.apple.com/documentation/widgetkit
- Apple Developer: `FileManager.mountedVolumeURLs`: https://developer.apple.com/documentation/foundation/filemanager/mountedvolumeurls%28includingresourcevaluesforkeys%3Aoptions%3A%29
- Apple Developer: volume capacity keys: https://developer.apple.com/documentation/foundation/urlresourcekey
- Apple Developer: Disk Arbitration: https://developer.apple.com/documentation/diskarbitration
- Apple Support: macOS Tahoe 26: https://support.apple.com/en-us/122727
