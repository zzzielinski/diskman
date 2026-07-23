# Diskman

Diskman to open source aplikacja na macOS działająca w pasku menu oraz jako rozszerzenie WidgetKit. Pokazuje podłączone dyski, wolne lub użyte miejsce, paski zajętości i opcjonalne szacunkowe kategorie danych bez otwierania Ustawień systemowych.

Pomysł urodził się z irytacji, że macOS nie ma prostego, ładnego widgetu pokazującego stan dysków na pulpicie. Diskman jest właśnie tym brakującym kawałkiem: ma siedzieć w tle, odświeżać snapshot danych i podawać widgetom aktualny stan nośników.

## Co Robi

- Pokazuje dyski wewnętrzne, zewnętrzne, sieciowe i obrazy dysków.
- Udostępnia mały, średni i duży widget macOS.
- Pozwala kliknąć dysk w widżecie i otworzyć go w Finderze.
- Pokazuje procent wolnego albo użytego miejsca.
- Obsługuje jednostki GB i GiB.
- Ma opcjonalne kategorie danych: wyłączone, podstawowe albo szacunkowe.
- Działa offline i zapisuje snapshot lokalnie w App Group, żeby widgety miały z czego czytać.
- Ma polski i angielski interfejs.
- Może startować automatycznie po zalogowaniu.

## Zrzuty Ekranu

Zrzuty ekranu zostaną dodane po finalnym sprawdzeniu wyglądu aplikacji i widgetów.

## Instalacja

Najprostsza instalacja pobiera najnowszy GitHub Release i kopiuje `Diskman.app` do `~/Applications`:

```bash
curl -fsSL https://raw.githubusercontent.com/zzzielinski/diskman/main/scripts/install.sh | bash
```

Instalacja i od razu uruchomienie aplikacji:

```bash
curl -fsSL https://raw.githubusercontent.com/zzzielinski/diskman/main/scripts/install.sh | bash -s -- --open
```

Instalator:

- pobiera `Diskman.app.zip` z najnowszego release,
- zamyka uruchomionego Diskmana, jeśli działa,
- usuwa starą rejestrację widgetu,
- kopiuje aplikację do wybranego folderu,
- rejestruje aplikację i rozszerzenie widgetu w macOS,
- odświeża cache widgetów i ikon.

## Instalacja W Customowym Folderze

Domyślne miejsce instalacji to `~/Applications`. Możesz wskazać własny folder przez `DISKMAN_INSTALL_DIR`.

Przykład instalacji do `/Applications`:

```bash
curl -fsSL https://raw.githubusercontent.com/zzzielinski/diskman/main/scripts/install.sh \
  | DISKMAN_INSTALL_DIR="/Applications" bash
```

Instalacja do własnego folderu:

```bash
curl -fsSL https://raw.githubusercontent.com/zzzielinski/diskman/main/scripts/install.sh \
  | DISKMAN_INSTALL_DIR="$HOME/Tools" bash
```

Instalacja do customowego folderu i od razu uruchomienie:

```bash
curl -fsSL https://raw.githubusercontent.com/zzzielinski/diskman/main/scripts/install.sh \
  | DISKMAN_INSTALL_DIR="$HOME/Tools" bash -s -- --open
```

Instalacja do `/Applications` może wymagać uprawnień administratora, jeśli konto nie ma tam prawa zapisu.

## Otwieranie Aplikacji

Jeśli Diskman jest zainstalowany w domyślnym miejscu:

```bash
curl -fsSL https://raw.githubusercontent.com/zzzielinski/diskman/main/scripts/open.sh | bash
```

To samo bez skryptu:

```bash
open "$HOME/Applications/Diskman.app"
```

Jeśli Diskman jest zainstalowany w customowym folderze:

```bash
curl -fsSL https://raw.githubusercontent.com/zzzielinski/diskman/main/scripts/open.sh \
  | DISKMAN_INSTALL_DIR="$HOME/Tools" bash
```

To samo bez skryptu:

```bash
open "$HOME/Tools/Diskman.app"
```

## Po Instalacji

Po uruchomieniu Diskman pojawia się w pasku menu. Z menu możesz wymusić odświeżenie, odbudować dane dla widgetów, wejść w ustawienia albo zamknąć aplikację.

Widget dodajesz standardowo z galerii widgetów macOS. Jeśli po aktualizacji macOS dalej pokazuje starą ikonę albo starą wersję widgetu, uruchom ponownie instalator. Skrypt odświeża rejestrację WidgetKit oraz cache ikon.

## Ustawienia

### Język

`System` używa języka macOS. `English` i `Polski` wymuszają konkretny język tylko dla Diskmana.

### Motyw

`System` dopasowuje wygląd do macOS. `Jasny` i `Ciemny` wymuszają tryb aplikacji niezależnie od systemu.

### Tryb Procentów

`Wolne` pokazuje procent wolnego miejsca. `Użyte` pokazuje procent zajętego miejsca.

Ten wybór wpływa na widgety, w tym mały widget z okręgami. Przykład: jeśli dysk ma 70% zajęte i 30% wolne, tryb `Wolne` pokaże 30%, a tryb `Użyte` pokaże 70%.

### Jednostki Pamięci

`GB` używa jednostek dziesiętnych, czyli 1 GB = 1 000 000 000 bajtów.

`GiB` używa jednostek binarnych, czyli 1 GiB = 1 073 741 824 bajty.

### Kategorie

`Wyłączone` pokazuje tylko podstawowe informacje o dysku, bez segmentów kategorii.

`Podstawowe` pokazuje prosty podział na użyte i dostępne miejsce. To najpewniejszy tryb, bo opiera się na danych z macOS o pojemności wolumenu.

`Szacunkowe` próbuje rozbić użyte miejsce na kategorie, takie jak aplikacje, dokumenty, developer, zdjęcia, wiadomości, dane systemowe i inne. To są szacunki, nie identyczne dane jak w Ustawieniach systemowych macOS.

### Głęboki Skan Folderów

Głęboki skan sprawdza dodatkowe foldery użytkownika, między innymi Dokumenty, Zdjęcia, Wiadomości i Pobrane. macOS może wymagać Pełnego dostępu do dysku, żeby Diskman mógł odczytać część tych lokalizacji.

Przycisk `Otwórz Pełny dostęp do dysku` prowadzi do ustawień prywatności macOS. Po nadaniu dostępu warto użyć `Odbuduj dane`.

### Widoczność Dysków

W tej sekcji wybierasz, jakie typy wolumenów mają pojawiać się w aplikacji i widgetach:

- `Wewnętrzne`: wbudowany dysk Maca.
- `Zewnętrzne`: podłączone nośniki USB, Thunderbolt i podobne.
- `Sieciowe`: zamontowane udziały sieciowe.
- `Obrazy dysków`: zamontowane pliki `.dmg` i podobne obrazy.

### Uruchamiaj Przy Logowaniu

Włącza automatyczne uruchamianie Diskmana po zalogowaniu do macOS. Aplikacja działa wtedy w tle i aktualizuje dane dla widgetów.

### Odświeżanie, Snapshot I Odbudowa Danych

`Odświeżanie Automatyczne` oznacza, że Diskman cyklicznie sprawdza wolumeny oraz reaguje na zdarzenia Disk Arbitration, na przykład podłączenie albo odłączenie dysku.

`Snapshot Udostępniony` oznacza, że aplikacja zapisuje lokalny snapshot w App Group, z którego czytają widgety.

`Odbuduj dane` wymusza świeży odczyt i zapis snapshotu. Użyj tego po zmianie ustawień, nadaniu Pełnego dostępu do dysku albo gdy widget jeszcze pokazuje starsze dane.

## Jakich Danych Używa Diskman

Diskman działa lokalnie i offline. Nie wysyła danych do żadnego API, nie zbiera analityki i nie wymaga internetu do działania.

Aplikacja czyta lokalne dane macOS:

- nazwę wolumenu,
- ścieżkę montowania,
- typ wolumenu,
- całkowitą pojemność,
- dostępne miejsce,
- ważne dostępne miejsce zgłaszane przez macOS,
- użyte miejsce wyliczone z pojemności i dostępnego miejsca.

Przy kategoriach szacunkowych Diskman może skanować wybrane lokalne foldery, żeby policzyć rozmiary plików. Wyniki są zapisywane lokalnie w cache i opisane jako szacunkowe, bo macOS nie udostępnia aplikacjom dokładnie tych samych prywatnych kategorii, które pokazuje w Ustawieniach systemowych.

## Odinstalowanie

Odinstalowanie aplikacji, ustawień, snapshotów widgetów, cache i logów:

```bash
curl -fsSL https://raw.githubusercontent.com/zzzielinski/diskman/main/scripts/uninstall.sh | bash
```

Podgląd tego, co zostanie usunięte:

```bash
curl -fsSL https://raw.githubusercontent.com/zzzielinski/diskman/main/scripts/uninstall.sh | bash -s -- --dry-run
```

Usunięcie aplikacji z zachowaniem lokalnych danych:

```bash
curl -fsSL https://raw.githubusercontent.com/zzzielinski/diskman/main/scripts/uninstall.sh | bash -s -- --keep-data
```

Odinstalowanie Diskmana z customowego folderu:

```bash
curl -fsSL https://raw.githubusercontent.com/zzzielinski/diskman/main/scripts/uninstall.sh \
  | bash -s -- --app "$HOME/Tools/Diskman.app"
```

Skrypt odinstalowania celowo pomija lokalny folder roboczy projektu.

## Build Ze Źródeł

Sklonuj repozytorium:

```bash
git clone https://github.com/zzzielinski/diskman.git
cd diskman
```

Lista schematów Xcode:

```bash
xcodebuild -list -project Diskman.xcodeproj
```

Build aplikacji i widgetu bez code signing:

```bash
xcodebuild \
  -project Diskman.xcodeproj \
  -scheme DiskmanApp \
  -configuration Debug \
  -destination platform=macOS \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Testy core:

```bash
cd DiskmanCore
swift test
```

## Release Build

Utworzenie paczki `.zip` i checksumy SHA-256:

```bash
./scripts/package-release.sh
```

Wyniki:

```text
build/release/Diskman.app.zip
build/release/Diskman.app.zip.sha256
```

Instalacja i uruchomienie lokalnego builda:

```bash
./scripts/package-release.sh
./scripts/install.sh --zip build/release/Diskman.app.zip --open
```

Aktualne buildy release są podpisane ad-hoc, ale nie są notarized. macOS może pokazać standardowe ostrzeżenie Gatekeeper przy pierwszym uruchomieniu.

## Struktura Projektu

```text
DiskmanApp/       aplikacja macOS, menu, ustawienia i okno informacji
DiskmanWidgets/   rozszerzenie WidgetKit
DiskmanCore/      wspólne modele, monitoring dysków, cache, lokalizacja i skan kategorii
scripts/          instalacja, odinstalowanie i pakowanie release
```

## Licencja

Diskman jest udostępniony na licencji MIT. Szczegóły są w pliku [LICENSE](LICENSE).
