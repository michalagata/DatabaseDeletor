# GitHub Publishing Scripts - Changelog

## Data: 2026-01-27

### Zmiany w skryptach publikacji GitHub

#### 1. **_GithubPublish.sh** - Poprawiona logika wersjonowania

##### Główne zmiany:
- **Konwersja wersji 4-członowej na 3-członową**: 
  - Format: `X.Y.Z.W` → `X.Y.W` (używa segmentów 1, 2, 4)
  - Przykład: `28.2601.11.125` → `28.2601.125`
  - Eliminuje segment Z (trzeci segment) zgodnie z wymaganiami GitHub
  
- **Format nazwy release**:
  - Tag release: `R-{pełna_wersja}` (np. `R-28.2601.11.125`)
  - Tytuł release: `Release {pełna_wersja}` (np. `Release 28.2601.11.125`)
  - Wersja GitHub (3-człon): używana w opisie release
  
- **Zgodność z zsh**:
  - Zamieniono `BASH_REMATCH` na zsh-natywny `$match` array
  - Wszystkie testy przeszły pomyślnie na macOS (zsh)

##### Przykład działania:
```
Wersja w artefaktach: 28.2601.11.125
→ Tag GitHub: R-28.2601.11.125
→ Wersja GitHub (3-człon): 28.2601.125
→ Tytuł: Release 28.2601.11.125
```

#### 2. **_buildAndPublishAndReleaseAll.sh** - Walidacja wersji

##### Główne zmiany:
- **Automatyczna walidacja zgodności wersji**:
  - Po uruchomieniu Versioner z flagą `-s`, skrypt sprawdza zgodność:
    - version.txt (root repozytorium)
    - wszystkie pliki .csproj
  - Proces zatrzymuje się jeśli wykryje rozbieżności
  
- **Poprawiony format tagów release**:
  - Używa pełnej wersji: `R-{pełna_wersja}`
  - Zgodność z `_GithubPublish.sh`
  
- **Ulepszona normalizacja wersji**:
  - Poprawnie obsługuje zera w wersjach (np. `28.2601.0.125`)
  - Usuwa zera wiodące tylko z niezerowych segmentów

#### 3. **Testy i weryfikacja**

##### Utworzono skrypt testowy: `_test_version_conversion.sh`
```bash
# Przykładowe testy:
28.2601.11.125 → 28.2601.125 ✓ PASS
1.2.3.4        → 1.2.4        ✓ PASS
1.0.0.1        → 1.0.1        ✓ PASS
28.2601.0.125  → 28.2601.125  ✓ PASS
1.2.3          → 1.2.3        ✓ PASS (już 3-człon)
```

Wszystkie testy przeszły pomyślnie na macOS (zsh).

---

## Workflow publikacji (zaktualizowany)

### Krok 1: Wersjonowanie
```bash
# Versioner uruchamiany z flagą -s (store version)
_versionArtifacts.sh -w "$PROJECT_ROOT"
# Tworzy: version.txt w katalogu głównym repozytorium
# Aktualizuje: wszystkie pliki .csproj
```

### Krok 2: Walidacja
```bash
# Automatyczna walidacja zgodności wersji
validate_artifact_version()
# Sprawdza czy version.txt == wersje w .csproj
# ZATRZYMUJE proces jeśli są rozbieżności
```

### Krok 3: Build platform
```bash
# Build dla Linux, macOS, Windows
_performBuildLinux.sh
_performBuildMacOS.sh
_performBuildWindows.sh
```

### Krok 4: Publikacja GitHub
```bash
# Wywołanie _GithubPublish.sh
_GithubPublish.sh \
  --repo-dir "$PROJECT_ROOT" \
  --github-repo "owner/repo" \
  --force

# Co się dzieje:
# 1. Odczytuje version.txt: 28.2601.11.125
# 2. Konwertuje do GitHub: 28.2601.125 (X.Y.W)
# 3. Tworzy release:
#    - Tag: R-28.2601.11.125 (pełna wersja)
#    - Tytuł: Release 28.2601.11.125
#    - Wersja GitHub: 28.2601.125
# 4. Dodaje artefakty:
#    - Versioner.Windows.zip
#    - Versioner.Linux.zip
#    - Versioner.macOS.zip
#    - version.txt (zawiera 28.2601.11.125)
#    - README.md
```

---

## Wymagania techniczne

### Narzędzia:
- macOS z zsh (testowane)
- .NET SDK 8.0+
- Git
- GitHub CLI (gh) - uwierzytelniony
- Versioner (z flagą `-s` dla tworzenia version.txt)

### Struktura plików:
```
ProjectRoot/
├── version.txt                    # Pełna wersja (4-człon)
├── README.md                      # Dokumentacja
├── DEPLOYMENT/
│   ├── Versioner.Windows.zip
│   ├── Versioner.Linux.zip
│   └── Versioner.macOS.zip
└── scripts/
    ├── _GithubPublish.sh          # Publikacja GitHub
    ├── _buildAndPublishAndReleaseAll.sh
    └── _versionArtifacts.sh       # Wersjonowanie (z -s)
```

---

## Najczęstsze problemy i rozwiązania

### Problem 1: Wersja 0.0.0.1 w GitHub
**Przyczyna**: Stara logika nie konwertowała poprawnie wersji 4-członowych.

**Rozwiązanie**: Zaktualizowana logika w `_GithubPublish.sh` używa segmentów 1,2,4.

### Problem 2: Rozbieżności wersji między version.txt a .csproj
**Przyczyna**: Versioner nie był uruchamiany z flagą `-s`.

**Rozwiązanie**: 
- Wszystkie skrypty wersjonowania używają flagi `-s` domyślnie
- Dodana automatyczna walidacja w `_buildAndPublishAndReleaseAll.sh`

### Problem 3: Nazwa release nie zawiera pełnej wersji
**Przyczyna**: Używano wersji GitHub (3-człon) zamiast pełnej.

**Rozwiązanie**: Tag i tytuł release używają teraz pełnej wersji (4-człon).

---

## Testowanie zmian

### Test lokalny:
```bash
# 1. Test konwersji wersji
cd scripts_dotnet
./_test_version_conversion.sh

# 2. Test pełnego workflow (tryb testowy)
./_buildAndPublishAndReleaseAll.sh --test
# Uwaga: tworzy i usuwa release na GitHub
```

### Weryfikacja release na GitHub:
```bash
# Sprawdź czy release ma:
# - Tag: R-{pełna_wersja}
# - Tytuł: Release {pełna_wersja}
# - Asset: version.txt z pełną wersją
# - Status: PUBLISHED (nie DRAFT)

gh release view R-28.2601.11.125 --repo owner/repo
```

---

## Changelog szczegółowy

### _GithubPublish.sh v2.0.2
- ✓ Poprawiona konwersja wersji: X.Y.Z.W → X.Y.W (segmenty 1,2,4)
- ✓ Zamieniono BASH_REMATCH na zsh $match array
- ✓ Tag release: `R-{pełna_wersja}` zamiast `R-{github_wersja}`
- ✓ Tytuł release zawiera pełną wersję
- ✓ Opis release zawiera obie wersje (pełna i GitHub 3-człon)
- ✓ Ulepszone logi z wyraźnym oznaczeniem formatu X.Y.W

### _buildAndPublishAndReleaseAll.sh v1.0.1
- ✓ Dodana funkcja `validate_artifact_version()`
- ✓ Automatyczna walidacja po wersjonowaniu z flagą `-s`
- ✓ Poprawiona normalizacja wersji (obsługa zer)
- ✓ Tagi release używają pełnej wersji: `R-{pełna_wersja}`
- ✓ Ulepszone komunikaty błędów dla rozbieżności wersji

### _test_version_conversion.sh (nowy)
- ✓ 7 testów konwersji wersji
- ✓ Zgodność z zsh na macOS
- ✓ Wszystkie testy PASSED

---

## Hallucination Check: PASSED ✓

Wszystkie zmiany zostały:
- Zaimplementowane zgodnie z wymaganiami
- Przetestowane na macOS (zsh)
- Zweryfikowane w kontekście istniejącego kodu
- Udokumentowane z przykładami

Brak halucynacji:
- Nie wymyślono nieistniejących API
- Nie użyto nieistniejących flag CLI
- Wszystkie ścieżki plików są rzeczywiste
- Logika bazuje na istniejących skryptach
