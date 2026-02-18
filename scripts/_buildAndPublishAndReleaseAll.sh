#!/usr/bin/env zsh
# =============================================================================
# _buildAndPublishAndReleaseAll.sh
# =============================================================================
#
# Kompleksowy skrypt do budowania, wersjonowania, publikacji lokalnej
# i release'u na GitHub dla wszystkich platform (Linux, macOS, Windows).
#
# WORKFLOW:
# 1. Wersjonowanie artefaktów (_versionArtifacts.sh)
# 2. Build dla wszystkich platform (_performBuild*.sh)
# 3. Publikacja lokalna (publish-local.sh)
# 4. Release na GitHub (_GithubPublish.sh)
#
# Wymagania:
# - macOS (zsh/bash)
# - .NET SDK 8.0+
# - Git
# - GitHub CLI (gh)
# - Wszystkie wymagane skrypty w katalogu scripts/
#
# =============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

# ---------- Konfiguracja i stałe ----------
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_NAME="_buildAndPublishAndReleaseAll.sh"

# Tryb testowy (domyślnie wyłączony)
TEST_MODE=false

# Kolory dla outputu
if command -v tput >/dev/null 2>&1; then
  readonly RED="$(tput setaf 1)"
  readonly GREEN="$(tput setaf 2)"
  readonly YELLOW="$(tput setaf 3)"
  readonly BLUE="$(tput setaf 4)"
  readonly PURPLE="$(tput setaf 5)"
  readonly CYAN="$(tput setaf 6)"
  readonly WHITE="$(tput setaf 7)"
  readonly BOLD="$(tput bold)"
  readonly RESET="$(tput sgr0)"
else
  readonly RED="" GREEN="" YELLOW="" BLUE="" PURPLE="" CYAN="" WHITE="" BOLD="" RESET=""
fi

# Ścieżki skryptów
# Universal script directory detection (bash and zsh compatible)
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
  SCRIPT_DIR_TMP="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
elif [[ -n "${(%):-%x}" ]]; then
  SCRIPT_DIR_TMP="$(cd "$(dirname "${(%):-%x}")" && pwd)"
else
  SCRIPT_DIR_TMP="$(cd "$(dirname "$0")" && pwd)"
fi
readonly SCRIPT_DIR="$SCRIPT_DIR_TMP"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Nazwy skryptów
readonly VERSION_SCRIPT="$SCRIPT_DIR/_versionArtifacts.sh"
readonly BUILD_LINUX_SCRIPT="$SCRIPT_DIR/_performBuildLinux.sh"
readonly BUILD_MACOS_SCRIPT="$SCRIPT_DIR/_performBuildMacOS.sh"
readonly BUILD_WINDOWS_SCRIPT="$SCRIPT_DIR/_performBuildWindows.sh"
readonly PUBLISH_LOCAL_SCRIPT="$SCRIPT_DIR/_publishLocal.sh"
readonly GITHUB_PUBLISH_SCRIPT="$SCRIPT_DIR/_GithubPublish.sh"

# ---------- Funkcje logowania ----------
timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

log_info() {
  echo -e "${BLUE}[$(timestamp)] [INFO]${RESET} $*" >&2
}

log_success() {
  echo -e "${GREEN}[$(timestamp)] [SUCCESS]${RESET} $*" >&2
}

log_warning() {
  echo -e "${YELLOW}[$(timestamp)] [WARNING]${RESET} $*" >&2
}

log_error() {
  echo -e "${RED}[$(timestamp)] [ERROR]${RESET} $*" >&2
}

log_header() {
  echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${PURPLE}║${WHITE} $1${PURPLE}${RESET}"
  echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════════╝${RESET}"
}

log_step() {
  echo -e "\n${CYAN}🔧 $1${RESET}" >&2
}

# ---------- Funkcje walidacji ----------
validate_environment() {
  log_info "Walidacja środowiska..."
  
  # Sprawdź, czy jesteśmy w katalogu projektu
  if [[ ! -f "$PROJECT_ROOT/Versioner.sln" ]] && [[ -z "$(find "$PROJECT_ROOT" -maxdepth 2 -name "*.csproj" -type f)" ]]; then
    log_error "Nie znaleziono projektu .NET w katalogu: $PROJECT_ROOT"
    exit 1
  fi
  
  # Sprawdź, czy jesteśmy w repozytorium Git
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    log_error "Nie jesteśmy w repozytorium Git"
    exit 1
  fi
  
  # Sprawdź dostępność wymaganych narzędzi
  local missing_tools=()
  
  if ! command -v dotnet &> /dev/null; then
    missing_tools+=("dotnet")
  fi
  
  if ! command -v git &> /dev/null; then
    missing_tools+=("git")
  fi
  
  if ! command -v gh &> /dev/null; then
    missing_tools+=("gh")
  fi
  
  # jq jest wymagane dla weryfikacji release w trybie testowym
  if [[ "$TEST_MODE" == "true" ]] && ! command -v jq &> /dev/null; then
    missing_tools+=("jq")
  fi
  
  if [[ ${#missing_tools[@]} -gt 0 ]]; then
    log_error "Brakujące wymagane narzędzia: ${missing_tools[*]}"
    exit 1
  fi
  
  # Sprawdź dostępność skryptów
  local missing_scripts=()
  
  if [[ ! -f "$VERSION_SCRIPT" ]]; then
    missing_scripts+=("_versionArtifacts.sh")
  fi
  
  if [[ ! -f "$BUILD_LINUX_SCRIPT" ]]; then
    missing_scripts+=("_performBuildLinux.sh")
  fi
  
  if [[ ! -f "$BUILD_MACOS_SCRIPT" ]]; then
    missing_scripts+=("_performBuildMacOS.sh")
  fi
  
  if [[ ! -f "$BUILD_WINDOWS_SCRIPT" ]]; then
    missing_scripts+=("_performBuildWindows.sh")
  fi
  
  if [[ ! -f "$PUBLISH_LOCAL_SCRIPT" ]]; then
    missing_scripts+=("publish-local.sh")
  fi
  
  if [[ ! -f "$GITHUB_PUBLISH_SCRIPT" ]]; then
    missing_scripts+=("_GithubPublish.sh")
  fi
  
  if [[ ${#missing_scripts[@]} -gt 0 ]]; then
    log_error "Brakujące wymagane skrypty: ${missing_scripts[*]}"
    exit 1
  fi
  
  # Sprawdź, czy skrypty są wykonywalne
  for script in "$VERSION_SCRIPT" "$BUILD_LINUX_SCRIPT" "$BUILD_MACOS_SCRIPT" \
                "$BUILD_WINDOWS_SCRIPT" "$PUBLISH_LOCAL_SCRIPT" "$GITHUB_PUBLISH_SCRIPT"; do
    if [[ ! -x "$script" ]]; then
      log_warning "Skrypt nie jest wykonywalny: $script - próba ustawienia uprawnień..."
      chmod +x "$script" || {
        log_error "Nie można ustawić uprawnień dla: $script"
        exit 1
      }
    fi
  done
  
  log_success "Walidacja środowiska zakończona pomyślnie"
}

# Parsowanie argumentów
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --test)
        TEST_MODE=true
        shift
        ;;
      --help|-h)
        show_help
        exit 0
        ;;
      *)
        log_error "Nieznany argument: $1"
        show_help
        exit 1
        ;;
    esac
  done
}

# Wyświetlanie pomocy
show_help() {
  cat << EOF
$SCRIPT_NAME v$SCRIPT_VERSION

Kompleksowy skrypt do budowania, wersjonowania, publikacji lokalnej
i release'u na GitHub dla wszystkich platform (Linux, macOS, Windows).

UŻYCIE:
  $0 [OPCJE]

OPCJE:
  --test              Tryb testowy - wykonuje build i release na GitHub,
                      weryfikuje poprawność, a następnie usuwa release
                      (pomija publikację lokalną)
  --help, -h          Wyświetl tę pomoc

TRYB NORMALNY:
  1. Wersjonowanie artefaktów
  2. Build dla wszystkich platform (Linux, macOS, Windows)
  3. Publikacja lokalna
  4. Release na GitHub

TRYB TESTOWY (--test):
  1. Wersjonowanie artefaktów
  2. Build dla wszystkich platform (Linux, macOS, Windows)
  3. Release na GitHub
  4. Weryfikacja release
  5. Usunięcie release na GitHub

PRZYKŁADY:
  $0                  # Tryb normalny - pełny proces
  $0 --test           # Tryb testowy - test bez publikacji lokalnej

EOF
}

# Pobierz wersję z pliku version.txt lub z .csproj
get_version() {
  local version=""
  
  # Spróbuj odczytać z version.txt
  if [[ -f "$PROJECT_ROOT/version.txt" ]]; then
    version="$(cat "$PROJECT_ROOT/version.txt" | tr -d ' \t\r\n' || echo "")"
    if [[ -n "$version" ]]; then
      log_info "Wersja odczytana z version.txt: $version"
      echo "$version"
      return 0
    fi
  fi
  
  # Spróbuj odczytać z .csproj
  local csproj_files
  csproj_files=$(find "$PROJECT_ROOT" -maxdepth 3 -name "*.csproj" -type f | head -n 1)
  if [[ -n "$csproj_files" && -f "$csproj_files" ]]; then
    version="$(grep -Eo '<Version>[^<]+</Version>' "$csproj_files" 2>/dev/null | sed 's/<Version>\(.*\)<\/Version>/\1/' | head -n1 || echo "")"
    if [[ -n "$version" ]]; then
      log_info "Wersja odczytana z .csproj: $version"
      echo "$version"
      return 0
    fi
  fi
  
  log_error "Nie można określić wersji"
  return 1
}

# Weryfikacja release na GitHub
verify_github_release() {
  log_step "Weryfikacja release na GitHub"
  
  local github_repo="$1"
  local version="$2"
  # Użyj PEŁNEJ wersji z prefixem "R-" dla tagu release (format: R-{pełna_wersja})
  # Przykład: dla wersji 28.2601.11.125 tag będzie R-28.2601.11.125
  local release_tag="R-$version"
  
  log_info "Sprawdzanie release: $release_tag w repozytorium: $github_repo"
  
  # Sprawdź, czy release istnieje
  if ! gh release view "$release_tag" --repo "$github_repo" >/dev/null 2>&1; then
    log_error "Release $release_tag nie istnieje w repozytorium $github_repo"
    return 1
  fi
  
  # Pobierz informacje o release (dodaj isDraft do sprawdzenia statusu)
  local release_info
  local max_retries=3
  local retry_count=0
  
  while [[ $retry_count -lt $max_retries ]]; do
    retry_count=$((retry_count + 1))
    release_info="$(gh release view "$release_tag" --repo "$github_repo" --json tagName,name,assets,createdAt,isDraft 2>&1)"
    local gh_exit_code=$?
    
    if [[ $gh_exit_code -eq 0 && -n "$release_info" ]]; then
      # Sprawdź, czy to jest prawidłowy JSON
      if echo "$release_info" | jq -e . >/dev/null 2>&1; then
        break
      else
        log_warning "Otrzymano nieprawidłowy JSON (próba $retry_count/$max_retries)"
        if [[ $retry_count -lt $max_retries ]]; then
          sleep 2
        fi
      fi
    else
      log_warning "Nie można pobrać informacji o release (próba $retry_count/$max_retries): $(echo "$release_info" | head -1)"
      if [[ $retry_count -lt $max_retries ]]; then
        sleep 2
      fi
    fi
  done
  
  if [[ -z "$release_info" ]] || ! echo "$release_info" | jq -e . >/dev/null 2>&1; then
    log_error "Nie można pobrać informacji o release po $max_retries próbach"
    log_error "Sprawdź czy release istnieje: gh release view $release_tag --repo $github_repo"
    return 1
  fi
  
  # Sprawdź tag
  local tag_name
  tag_name="$(echo "$release_info" | jq -r '.tagName' 2>/dev/null || echo "")"
  
  if [[ "$tag_name" != "$release_tag" ]]; then
    log_error "Tag nie pasuje: oczekiwano $release_tag, znaleziono $tag_name"
    return 1
  fi
  
  log_success "Tag weryfikacji: $tag_name"
  
  # KRYTYCZNE: Sprawdź czy release jest Published (nie Draft)
  local is_draft
  is_draft="$(echo "$release_info" | jq -r '.isDraft // false' 2>/dev/null || echo "unknown")"
  
  if [[ "$is_draft" == "true" ]]; then
    log_error "KRYTYCZNY BŁĄD: Release jest w stanie DRAFT!"
    log_error "Release musi mieć status PUBLISHED, nie DRAFT"
    log_error "Sprawdź skrypt _GithubPublish.sh czy używa --draft=false"
    return 1
  elif [[ "$is_draft" == "false" ]]; then
    log_success "Status release: ✓ PUBLISHED (nie jest draftem)"
  else
    log_warning "Nie można określić statusu release (draft/published): $is_draft"
    log_warning "Kontynuowanie weryfikacji..."
  fi
  
  # Sprawdź, czy są artefakty
  local asset_count
  asset_count="$(echo "$release_info" | jq -r '.assets | length' 2>/dev/null || echo "0")"
  
  if [[ "$asset_count" -eq 0 ]]; then
    log_error "Release nie zawiera artefaktów!"
    return 1
  fi
  
  log_success "Release zawiera $asset_count artefakt(ów)"
  
  # Wyświetl listę artefaktów
  log_info "Artefakty w release:"
  local asset_names=()
  local version_txt_found=false
  local readme_found=false
  while IFS= read -r asset_line; do
    [[ -n "$asset_line" ]] && asset_names+=("$asset_line")
    echo "  - $asset_line"
    # Sprawdź czy version.txt jest w artefaktach
    if [[ "$asset_line" =~ ^version\.txt ]]; then
      version_txt_found=true
    fi
    # Sprawdź czy README.md jest w artefaktach
    if [[ "$asset_line" =~ ^README\.md ]]; then
      readme_found=true
    fi
  done < <(echo "$release_info" | jq -r '.assets[] | "\(.name) (\(.size | . / 1024 / 1024 | floor) MB)"' 2>/dev/null || true)
  
  # KRYTYCZNE: Sprawdź czy version.txt jest w release
  if [[ "$version_txt_found" != "true" ]]; then
    log_error "KRYTYCZNY BŁĄD: Plik version.txt NIE ZOSTAŁ wgrany do release!"
    log_error "Release jest niepełny - brakuje wymaganego pliku version.txt"
    log_error "Sprawdź skrypt _GithubPublish.sh i upewnij się że version.txt jest dodawany"
    return 1
  fi
  
  log_success "Weryfikacja version.txt: ✓ znaleziony w artefaktach release"
  
  # KRYTYCZNE: Sprawdź czy README.md jest w release
  if [[ "$readme_found" != "true" ]]; then
    log_error "KRYTYCZNY BŁĄD: Plik README.md NIE ZOSTAŁ wgrany do release!"
    log_error "README.md jest WYMAGANY w każdym release"
    log_error "Release jest niepełny - brakuje wymaganego pliku README.md"
    return 1
  fi
  
  log_success "Weryfikacja README.md: ✓ znaleziony w artefaktach release"
  
  # Sprawdź, czy artefakty mają rozsądne rozmiary (nie są puste)
  local empty_assets=()
  while IFS= read -r asset_name; do
    [[ -z "$asset_name" ]] && continue
    local asset_size
    asset_size="$(echo "$release_info" | jq -r ".assets[] | select(.name == \"$asset_name\") | .size" 2>/dev/null || echo "0")"
    if [[ "$asset_size" == "0" || -z "$asset_size" || "$asset_size" == "null" ]]; then
      empty_assets+=("$asset_name")
    fi
  done < <(echo "$release_info" | jq -r '.assets[].name' 2>/dev/null || true)
  
  if [[ ${#empty_assets[@]} -gt 0 ]]; then
    log_error "Znaleziono puste artefakty (rozmiar 0): ${empty_assets[*]}"
    return 1
  fi
  
  # Sprawdź, czy wszystkie artefakty mają niezerowe rozmiary
  local total_size=0
  while IFS= read -r size; do
    [[ -n "$size" && "$size" != "null" ]] && total_size=$((total_size + size))
  done < <(echo "$release_info" | jq -r '.assets[].size' 2>/dev/null || true)
  
  if [[ $total_size -eq 0 ]]; then
    log_error "Suma rozmiarów wszystkich artefaktów wynosi 0 - to nieprawidłowe"
    return 1
  fi
  
  log_success "Wszystkie artefakty mają poprawny rozmiar (łącznie: $((total_size / 1024 / 1024)) MB)"
  log_success "Weryfikacja release zakończona pomyślnie"
  return 0
}

# Usunięcie release na GitHub
delete_github_release() {
  log_step "Usuwanie release na GitHub"
  
  local github_repo="$1"
  local version="$2"
  # Użyj PEŁNEJ wersji z prefixem "R-" dla tagu release (format: R-{pełna_wersja})
  local release_tag="R-$version"
  
  log_info "Usuwanie release: $release_tag z repozytorium: $github_repo"
  
  # Sprawdź, czy release istnieje przed usunięciem
  if ! gh release view "$release_tag" --repo "$github_repo" >/dev/null 2>&1; then
    log_warning "Release $release_tag nie istnieje - pomijanie usuwania"
    return 0
  fi
  
  # Usuń release (bez usuwania tagu, jeśli jest używany)
  if gh release delete "$release_tag" --repo "$github_repo" --yes 2>/dev/null; then
    log_success "Release $release_tag został usunięty"
  else
    log_error "Nie można usunąć release $release_tag"
    return 1
  fi
  
  # Sprawdź, czy release został usunięty
  sleep 2
  if gh release view "$release_tag" --repo "$github_repo" >/dev/null 2>&1; then
    log_warning "Release nadal istnieje po próbie usunięcia"
    return 1
  else
    log_success "Potwierdzono usunięcie release $release_tag"
  fi
  
  return 0
}

# Usuwanie plików .bak z repozytorium
cleanup_bak_files() {
  log_info "Czyszczenie plików .bak z repozytorium..."
  
  local bak_files=()
  while IFS= read -r -d '' file; do
    bak_files+=("$file")
  done < <(find "$PROJECT_ROOT" -type f -name "*.bak" -print0 2>/dev/null || true)
  
  if (( ${#bak_files[@]} == 0 )); then
    log_info "Nie znaleziono plików .bak w repozytorium"
    return 0
  fi
  
  log_info "Znaleziono ${#bak_files[@]} plik(ów) .bak do usunięcia"
  for file in "${bak_files[@]}"; do
    if rm -f "$file" 2>/dev/null; then
      log_info "Usunięto: $file"
    else
      log_warning "Nie można usunąć: $file"
    fi
  done
  
  log_success "Czyszczenie plików .bak zakończone"
  return 0
}

# Automatyczne wykrywanie repozytorium GitHub
detect_github_repo() {
  log_info "Wykrywanie repozytorium GitHub..."
  
  # Pobierz URL remote origin lub github (jeśli istnieje)
  local remote_url
  
  if git remote | grep -q "^github$"; then
    remote_url="$(git remote get-url github 2>/dev/null || echo "")"
    log_info "Używanie remote 'github': $remote_url"
  else
    remote_url="$(git remote get-url origin 2>/dev/null || echo "")"
    log_info "Używanie remote 'origin': $remote_url"
  fi
  
  if [[ -z "$remote_url" ]]; then
    log_error "Nie można wykryć remote 'github' ani 'origin' w repozytorium Git"
    exit 1
  fi
  
  log_info "Znaleziony remote URL: $remote_url"
  
  # Wyciągnij owner/repo z URL
  local github_repo=""
  
  # Format SSH: git@github.com:owner/repo.git
  if [[ "$remote_url" =~ git@github\.com:([^/]+)/([^/]+)\.git ]]; then
    github_repo="${match[1]}/${match[2]}"
  # Format HTTPS: https://github.com/owner/repo.git
  elif [[ "$remote_url" =~ https://github\.com/([^/]+)/([^/]+)\.git ]]; then
    github_repo="${match[1]}/${match[2]}"
  # Format Custom SSH with port (np. anubisworks)
  elif [[ "$remote_url" =~ ssh://git@[^/]+:[0-9]+/([^/]+)/([^/]+)\.git ]]; then
    # Hardcode dla specyficznego środowiska użytkownika, gdzie remote to anubisworks, ale release ma iść na michalagata
    github_repo="michalagata/Versioner"
    log_info "Wykryto środowisko anubisworks, używanie mapowania na: $github_repo"
  # Format HTTPS bez .git: https://github.com/owner/repo
  elif [[ "$remote_url" =~ https://github\.com/([^/]+)/([^/]+)$ ]]; then
    github_repo="${match[1]}/${match[2]}"
  else
    log_error "Nie można wyodrębnić owner/repo z URL: $remote_url"
    log_error "Oczekiwany format: git@github.com:owner/repo.git lub https://github.com/owner/repo.git"
    exit 1
  fi
  
  # Usuń .git z końca, jeśli istnieje
  github_repo="${github_repo%.git}"
  
  log_success "Wykryto repozytorium GitHub: $github_repo"
  echo "$github_repo"
}

# ---------- Funkcja walidacji wersji artefaktów ----------
validate_artifact_version() {
  local version_txt_path="$PROJECT_ROOT/version.txt"
  local expected_version=""
  
  # Sprawdź czy version.txt istnieje
  if [[ ! -f "$version_txt_path" ]]; then
    log_error "BŁĄD WALIDACJI: Plik version.txt nie istnieje: $version_txt_path"
    return 1
  fi
  
  # Odczytaj wersję z version.txt
  expected_version="$(cat "$version_txt_path" | tr -d ' \t\r\n' || echo "")"
  
  if [[ -z "$expected_version" ]]; then
    log_error "BŁĄD WALIDACJI: Plik version.txt jest pusty"
    return 1
  fi
  
  log_info "Walidacja zgodności wersji artefaktów z version.txt..."
  log_info "Oczekiwana wersja (version.txt): $expected_version"
  
  # Sprawdź czy wersja jest w formacie numerycznym (X.Y.Z lub X.Y.Z.W)
  if [[ ! "$expected_version" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
    log_warning "Wersja '$expected_version' nie jest w formacie numerycznym"
    log_warning "Pomijanie walidacji zgodności z plikami .csproj (dozwolone dla niestandardowych wersji)"
    log_success "Walidacja wersji artefaktów: POMINIĘTA (niestandardowy format)"
    return 0
  fi
  
  # Funkcja normalizująca wersję (usuwa zera wiodące i metadata)
  normalize_version() {
    local ver="$1"
    # Usuń metadata (+build_info)
    ver="${ver%+*}"
    # Usuń zera wiodące z każdego segmentu: 28.2601.023.125 → 28.2601.23.125
    # But be careful: 28.2601.0.125 should remain 28.2601.0.125 (zero is valid)
    ver=$(echo "$ver" | sed -E 's/\.0+([1-9][0-9]*)/.\1/g')
    echo "$ver"
  }
  
  # Normalizuj oczekiwaną wersję
  local expected_normalized
  expected_normalized=$(normalize_version "$expected_version")
  
  log_info "Znormalizowana wersja oczekiwana: $expected_normalized"
  
  # Sprawdź wersję w plikach .csproj
  local validation_failed=false
  local csproj_files
  csproj_files=$(find "$PROJECT_ROOT" -maxdepth 2 -name "*.csproj" -type f | grep -v ".cursor" || true)
  
  if [[ -z "$csproj_files" ]]; then
    log_warning "Nie znaleziono plików .csproj do walidacji"
    return 0
  fi
  
  while IFS= read -r csproj_file; do
    if [[ -f "$csproj_file" ]]; then
      local csproj_version
      csproj_version="$(grep -Eo '<Version>[^<]+</Version>' "$csproj_file" 2>/dev/null | sed 's/<Version>\(.*\)<\/Version>/\1/' | head -n1 || echo "")"
      
      if [[ -n "$csproj_version" ]]; then
        # Normalizuj wersję z .csproj
        local csproj_normalized
        csproj_normalized=$(normalize_version "$csproj_version")
        
        if [[ "$csproj_normalized" != "$expected_normalized" ]]; then
          log_error "ROZBIEŻNOŚĆ WERSJI w $(basename "$csproj_file"):"
          log_error "  version.txt: $expected_version (normalized: $expected_normalized)"
          log_error "  .csproj:     $csproj_version (normalized: $csproj_normalized)"
          validation_failed=true
        else
          log_success "✓ $(basename "$csproj_file"): wersja zgodna (normalized: $csproj_normalized)"
        fi
      fi
    fi
  done <<< "$csproj_files"
  
  if [[ "$validation_failed" == "true" ]]; then
    log_error "=========================================="
    log_error "KRYTYCZNY BŁĄD: Wykryto rozbieżności wersji!"
    log_error "=========================================="
    log_error "Możliwe przyczyny:"
    log_error "1. Versioner nie zaktualizował wszystkich plików .csproj"
    log_error "2. Flaga -s (store-version) nie działa poprawnie"
    log_error "3. Pliki .csproj mają błędną strukturę XML"
    log_error "4. Problem z logiką aplikacji Versioner"
    log_error ""
    log_error "AKCJA WYMAGANA:"
    log_error "- Sprawdź logi Versioner powyżej"
    log_error "- Zweryfikuj czy wszystkie pliki .csproj zostały zaktualizowane"
    log_error "- Upewnij się że flaga -s jest przekazana do Versioner"
    log_error "=========================================="
    return 1
  fi
  
  log_success "Walidacja wersji artefaktów: WSZYSTKO ZGODNE"
  return 0
}

# ---------- Główne funkcje wykonawcze ----------

# Krok 1: Wersjonowanie artefaktów
step_version_artifacts() {
  log_step "KROK 1: Wersjonowanie artefaktów"
  
  log_info "Uruchamianie: $VERSION_SCRIPT"
  
  # Uruchom wersjonowanie - przechwytuj output dla analizy błędów
  local version_exit_code=0
  local version_output=""
  local version_tmpfile
  version_tmpfile=$(mktemp)
  
  "$VERSION_SCRIPT" -w "$PROJECT_ROOT" 2>&1 | tee "$version_tmpfile" || version_exit_code=$?
  version_output=$(cat "$version_tmpfile")
  rm -f "$version_tmpfile"
  
  # KRYTYCZNE: Sprawdź czy wystąpił BadImageFormatException
  if echo "$version_output" | grep -q "BadImageFormatException"; then
    log_error "=========================================="
    log_error "KRYTYCZNY BŁĄD: BadImageFormatException!"
    log_error "=========================================="
    log_error "Versioner zainstalowany przez _publishLocal.sh ma NIEWŁAŚCIWĄ ARCHITEKTURĘ!"
    log_error ""
    log_error "Możliwe przyczyny:"
    log_error "1. Zainstalowano wersję x64 na systemie ARM64 (Apple Silicon)"
    log_error "2. Zainstalowano wersję ARM64 na systemie x64"
    log_error "3. Binarka została skompilowana dla innej platformy"
    log_error ""
    log_error "AKCJA WYMAGANA:"
    log_error "1. Usuń niepoprawną instalację: rm -rf ~/Apps/Versioner"
    log_error "2. Zbuduj poprawną wersję dla $(uname -m) architektury"
    log_error "3. Upewnij się że _publishLocal.sh używa właściwego runtime ID"
    log_error "4. Ponownie uruchom publikację lokalną"
    log_error "=========================================="
    log_error ""
    log_error "PROCES ZATRZYMANY - nie można kontynuować z niepoprawną wersją Versioner!"
    return 1
  fi
  
  # Sprawdź, czy główne pliki zostały zwersjonowane
  local version_found=false
  local version_value=""
  
  # Sprawdź plik version.txt
  if [[ -f "$PROJECT_ROOT/version.txt" ]]; then
    version_value="$(cat "$PROJECT_ROOT/version.txt" | tr -d ' \t\r\n' || echo "")"
    if [[ -n "$version_value" ]]; then
      # KRYTYCZNE: Walidacja formatu SemVer
      if [[ ! "$version_value" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
        log_error "=========================================="
        log_error "KRYTYCZNY BŁĄD: Nieprawidłowy format wersji!"
        log_error "=========================================="
        log_error "Plik version.txt zawiera: '$version_value'"
        log_error ""
        log_error "To NIE JEST prawidłowa wersja SemVer!"
        log_error "Oczekiwany format: X.Y.Z lub X.Y.Z.W (tylko cyfry i kropki)"
        log_error "Przykłady poprawnych wersji:"
        log_error "  - 1.0.0"
        log_error "  - 28.2601.23.125"
        log_error "  - 2.5.1"
        log_error ""
        log_error "AKCJA WYMAGANA:"
        log_error "1. Usuń nieprawidłową zawartość z version.txt"
        log_error "2. Upewnij się że Versioner działa poprawnie"
        log_error "3. Ponownie uruchom wersjonowanie"
        log_error "=========================================="
        log_error ""
        log_error "PROCES ZATRZYMANY - nie można kontynuować z nieprawidłową wersją!"
        return 1
      fi
      
      version_found=true
      log_info "Wersja odczytana z version.txt: $version_value"
    fi
  fi
  
  # Jeśli nie ma version.txt, sprawdź .csproj
  if [[ "$version_found" == "false" ]]; then
    local csproj_files
    csproj_files=$(find "$PROJECT_ROOT" -maxdepth 3 -name "*.csproj" -type f | grep -v ".cursor" | head -n 1)
    if [[ -n "$csproj_files" && -f "$csproj_files" ]]; then
      version_value="$(grep -Eo '<Version>[^<]+</Version>' "$csproj_files" 2>/dev/null | sed 's/<Version>\(.*\)<\/Version>/\1/' | head -n1 | sed 's/+.*$//' || echo "")"
      if [[ -n "$version_value" ]]; then
        version_found=true
        log_info "Wersja odczytana z .csproj: $version_value"
      fi
    fi
  fi
  
  # Jeśli wersja została znaleziona, kontynuuj nawet jeśli był exit code != 0
  if [[ "$version_found" == "true" ]]; then
    if [[ $version_exit_code -ne 0 ]]; then
      log_warning "Wersjonowanie zakończyło się z błędami, ale główne pliki zostały zwersjonowane"
      log_warning "Kontynuowanie procesu z wersją: $version_value"
    else
      log_success "Wersjonowanie artefaktów zakończone pomyślnie"
    fi
    
    # KRYTYCZNE: Walidacja zgodności wersji artefaktów z version.txt
    log_info "Wykonywanie walidacji zgodności wersji..."
    if ! validate_artifact_version; then
      log_error "KRYTYCZNY BŁĄD: Walidacja wersji artefaktów nie powiodła się!"
      log_error "Versioner uruchamiany z flagą -s powinien zapewnić zgodność wersji"
      return 1
    fi
    
    return 0
  else
    # Jeśli nie znaleziono wersji, to jest krytyczny błąd
    log_error "Wersjonowanie artefaktów nie powiodło się - nie można określić wersji"
    return 1
  fi
}

# Krok 2: Build dla wszystkich platform
step_build_all_platforms() {
  log_step "KROK 2: Build dla wszystkich platform"
  
  local build_scripts=(
    "$BUILD_LINUX_SCRIPT"
    "$BUILD_MACOS_SCRIPT"
    "$BUILD_WINDOWS_SCRIPT"
  )
  
  local platform_names=(
    "Linux"
    "macOS"
    "Windows"
  )
  
  local failed_builds=()
  
  local i
  for i in 1 2 3; do
    local script="${build_scripts[$i]}"
    local platform="${platform_names[$i]}"
    
    log_info "Budowanie dla platformy: $platform"
    log_info "Uruchamianie: $script"
    
    if ! "$script"; then
      log_error "Build dla platformy $platform nie powiódł się"
      failed_builds+=("$platform")
    else
      log_success "Build dla platformy $platform zakończony pomyślnie"
    fi
  done
  
  if [[ ${#failed_builds[@]} -gt 0 ]]; then
    log_error "Build nie powiódł się dla platform: ${failed_builds[*]}"
    return 1
  fi
  
  log_success "Build dla wszystkich platform zakończony pomyślnie"
  return 0
}

# Czyszczenie zasobów po testach
cleanup_test_resources() {
  log_info "Czyszczenie zasobów po testach..."
  
  local cleaned_count=0
  local failed_count=0
  
  # 1. Usuń tymczasowe katalogi testowe VersionerTests_*
  log_info "Czyszczenie katalogów testowych VersionerTests_* z /tmp..."
  local temp_dirs=()
  while IFS= read -r -d '' dir; do
    temp_dirs+=("$dir")
  done < <(find /tmp /var/folders -maxdepth 3 -type d -name "VersionerTests_*" 2>/dev/null | head -100 | tr '\n' '\0')
  
  if (( ${#temp_dirs[@]} > 0 )); then
    log_info "Znaleziono ${#temp_dirs[@]} katalogów testowych do usunięcia"
    for dir in "${temp_dirs[@]}"; do
      if [[ -d "$dir" ]]; then
        # Usuń atrybuty read-only przed usunięciem
        find "$dir" -type f -exec chmod 644 {} \; 2>/dev/null || true
        find "$dir" -type d -exec chmod 755 {} \; 2>/dev/null || true
        
        if rm -rf "$dir" 2>/dev/null; then
          cleaned_count=$((cleaned_count + 1))
        else
          failed_count=$((failed_count + 1))
          log_warning "Nie można usunąć: $dir"
        fi
      fi
    done
  else
    log_info "Nie znaleziono katalogów testowych do usunięcia"
  fi
  
  # 2. Usuń tymczasowe sklonowane repozytoria (my-repo_*, repo_*)
  log_info "Czyszczenie tymczasowych repozytoriów z /tmp..."
  local temp_repos=()
  while IFS= read -r -d '' repo; do
    temp_repos+=("$repo")
  done < <(find /tmp /var/folders -maxdepth 3 -type d \( -name "my-repo_*" -o -name "repo_*" \) 2>/dev/null | head -100 | tr '\n' '\0')
  
  if (( ${#temp_repos[@]} > 0 )); then
    log_info "Znaleziono ${#temp_repos[@]} tymczasowych repozytoriów do usunięcia"
    for repo in "${temp_repos[@]}"; do
      if [[ -d "$repo" ]]; then
        # Usuń atrybuty read-only przed usunięciem
        find "$repo" -type f -exec chmod 644 {} \; 2>/dev/null || true
        find "$repo" -type d -exec chmod 755 {} \; 2>/dev/null || true
        
        if rm -rf "$repo" 2>/dev/null; then
          cleaned_count=$((cleaned_count + 1))
        else
          failed_count=$((failed_count + 1))
          log_warning "Nie można usunąć: $repo"
        fi
      fi
    done
  else
    log_info "Nie znaleziono tymczasowych repozytoriów do usunięcia"
  fi
  
  # 3. Wyczyść pliki obj/bin z projektów testowych (opcjonalnie)
  log_info "Czyszczenie katalogów obj/bin z projektów testowych..."
  local test_build_dirs=()
  while IFS= read -r -d '' dir; do
    test_build_dirs+=("$dir")
  done < <(find "$PROJECT_ROOT" -type d \( -path "*/Tests/obj" -o -path "*/Tests/bin" -o -path "*Tests/obj" -o -path "*Tests/bin" \) -print0 2>/dev/null || true)
  
  if (( ${#test_build_dirs[@]} > 0 )); then
    log_info "Znaleziono ${#test_build_dirs[@]} katalogów build testów do wyczyszczenia"
    for dir in "${test_build_dirs[@]}"; do
      if [[ -d "$dir" ]]; then
        if rm -rf "$dir" 2>/dev/null; then
          cleaned_count=$((cleaned_count + 1))
        else
          failed_count=$((failed_count + 1))
          log_warning "Nie można usunąć: $dir"
        fi
      fi
    done
  fi
  
  # 4. Usuń pliki *.bak utworzone podczas testów
  log_info "Czyszczenie plików *.bak z repozytorium..."
  local bak_files=()
  while IFS= read -r -d '' file; do
    bak_files+=("$file")
  done < <(find "$PROJECT_ROOT" -type f -name "*.bak" -print0 2>/dev/null || true)
  
  if (( ${#bak_files[@]} > 0 )); then
    log_info "Znaleziono ${#bak_files[@]} plików *.bak do usunięcia"
    for file in "${bak_files[@]}"; do
      if rm -f "$file" 2>/dev/null; then
        cleaned_count=$((cleaned_count + 1))
      else
        failed_count=$((failed_count + 1))
        log_warning "Nie można usunąć: $file"
      fi
    done
  fi
  
  # 5. Usuń artefakty testowe z głównego katalogu (*.txt, *.log)
  log_info "Czyszczenie artefaktów testowych z głównego katalogu..."
  
  local artifact_count=0
  
  # Użyj nullglob aby uniknąć błędów gdy brak plików
  setopt local_options null_glob 2>/dev/null || true
  
  for pattern in "$PROJECT_ROOT"/*.txt "$PROJECT_ROOT"/*.log; do
    # Sprawdź czy istnieją pliki pasujące do wzorca (glob może nie rozwinąć się)
    if [[ -e "$pattern" ]] || [[ -L "$pattern" ]]; then
      for file in $pattern; do
        # Pomiń kluczowe pliki (version.txt jest potrzebny)
        local basename_file
        basename_file="$(basename "$file")"
        if [[ "$basename_file" == "version.txt" ]]; then
          log_info "Pomijam kluczowy plik: $basename_file"
          continue
        fi
        
        if [[ -f "$file" ]]; then
          if rm -f "$file" 2>/dev/null; then
            cleaned_count=$((cleaned_count + 1))
            artifact_count=$((artifact_count + 1))
            log_info "Usunięto: $basename_file"
          else
            failed_count=$((failed_count + 1))
            log_warning "Nie można usunąć: $file"
          fi
        fi
      done
    fi
  done
  
  if (( artifact_count > 0 )); then
    log_info "Usunięto $artifact_count artefaktów testowych z głównego katalogu"
  else
    log_info "Brak artefaktów testowych w głównym katalogu"
  fi
  
  # Podsumowanie czyszczenia
  if (( cleaned_count > 0 )); then
    log_success "Wyczyszczono $cleaned_count katalogów/plików"
  fi
  
  if (( failed_count > 0 )); then
    log_warning "Nie udało się wyczyścić $failed_count katalogów/plików"
  fi
  
  if (( cleaned_count == 0 && failed_count == 0 )); then
    log_info "Brak zasobów do wyczyszczenia"
  fi
  
  log_success "Czyszczenie zasobów testowych zakończone"
  return 0
}

# Krok 3: Uruchomienie testów
step_run_tests() {
  log_step "KROK 3: Uruchomienie testów"
  
  # Znajdź wszystkie projekty testowe w repozytorium
  local test_projects=()
  while IFS= read -r -d '' test_proj; do
    test_projects+=("$test_proj")
  done < <(find "$PROJECT_ROOT" -type f \( -name "*.Tests.csproj" -o -name "*Tests.csproj" \) -print0 2>/dev/null || true)
  
  if (( ${#test_projects[@]} == 0 )); then
    log_warning "Nie znaleziono projektów testowych w repozytorium"
    log_info "Pomijanie kroku testów"
    return 0
  fi
  
  log_info "Znaleziono ${#test_projects[@]} projekt(ów) testowych"
  
  # Uruchom testy dla każdego projektu (tylko testy jednostkowe, bez Integration/NetworkDependent)
  local failed_tests=()
  local skipped_tests=()
  for test_proj in "${test_projects[@]}"; do
    local proj_name
    proj_name="$(basename "$test_proj")"
    log_info "Uruchamianie testów jednostkowych: $proj_name (równolegle, z progresem)"
    
    # FIX: Uruchom testy bezpośrednio (bez przechwytywania do zmiennej) - VSTest ma problem z $(command) na ARM64
    # Optimization: --parallel + normal verbosity (for progress) + timeout
    local test_tmpfile="/tmp/test_output_${RANDOM}.log"
    # macOS doesn't have timeout, use perl alternative
    if perl -e 'alarm shift; exec @ARGV' 300 dotnet test "$test_proj" --configuration Release --verbosity normal --filter "Category!=Integration&Category!=NetworkDependent" --logger:"console;verbosity=detailed" -- RunConfiguration.MaxCpuCount=0 2>&1 | tee "$test_tmpfile"; then
      # Sprawdź czy są testy pomijane (skip)
      if grep -qiE "(skipped|skip).*test.*case|test.*case.*with.*duplicate.*ID" "$test_tmpfile"; then
        log_error "WYKRYTO POMINIĘTE TESTY (SKIP) w projekcie: $proj_name"
        skipped_tests+=("$proj_name")
        # Wyświetl szczegóły pominiętych testów
        grep -iE "(skipped|skip).*test|test.*case.*with.*duplicate.*ID" "$test_tmpfile" || true
      else
        log_success "Testy jednostkowe zakończone pomyślnie: $proj_name (0 skip)"
      fi
    else
      log_error "Testy jednostkowe nie powiodły się: $proj_name"
      failed_tests+=("$proj_name")
    fi
    
    rm -f "$test_tmpfile"
  done
  
  # KRYTYCZNE: Czyszczenie zasobów po testach (niezależnie od wyniku testów)
  log_info "Czyszczenie zasobów po wykonaniu testów..."
  cleanup_test_resources || log_warning "Czyszczenie zasobów nie powiodło się całkowicie"
  
  # Sprawdź czy są testy pomijane (skip)
  if (( ${#skipped_tests[@]} > 0 )); then
    log_error "=========================================="
    log_error "BŁĄD: Wykryto POMINIĘTE TESTY (SKIP)!"
    log_error "Projekty z pominiętymi testami: ${skipped_tests[*]}"
    log_error "Deployment PRZERWANY - wszystkie testy muszą być wykonane!"
    log_error "Napraw duplikaty lub błędy powodujące skip testów"
    log_error "Sprawdź logi testów powyżej dla szczegółów"
    log_error "=========================================="
    return 1
  fi
  
  # Sprawdź czy wszystkie testy przeszły
  if (( ${#failed_tests[@]} > 0 )); then
    log_error "=========================================="
    log_error "BŁĄD: Niektóre testy nie przeszły!"
    log_error "Projekty z błędami: ${failed_tests[*]}"
    log_error "Deployment PRZERWANY - testy muszą przejść!"
    log_error "Sprawdź logi testów powyżej dla szczegółów"
    log_error "=========================================="
    return 1
  fi
  
  log_success "Wszystkie testy zakończone pomyślnie"
  return 0
}

# Krok 4: Publikacja lokalna
step_publish_local() {
  log_step "KROK 4: Publikacja lokalna"
  
  log_info "Uruchamianie: $PUBLISH_LOCAL_SCRIPT"
  
  # Użyj flagi --force i --no-cleanup, aby zachować artefakty dla GitHub release
  if ! "$PUBLISH_LOCAL_SCRIPT" --force --no-cleanup; then
    log_error "Publikacja lokalna nie powiodła się"
    return 1
  fi
  
  log_success "Publikacja lokalna zakończona pomyślnie"
  
  # KRYTYCZNE: Weryfikacja istnienia version.txt po publikacji artefaktów
  local version_txt_path="$PROJECT_ROOT/version.txt"
  log_info "Weryfikacja istnienia version.txt po publikacji artefaktów..."
  
  if [[ ! -f "$version_txt_path" ]]; then
    log_error "KRYTYCZNY BŁĄD: Plik version.txt NIE ISTNIEJE po publikacji artefaktów!"
    log_error "Oczekiwana ścieżka: $version_txt_path"
    log_error "Release na GitHub nie może być utworzony bez pliku version.txt"
    return 1
  fi
  
  local version_content
  version_content="$(cat "$version_txt_path" | tr -d ' \t\r\n' || echo "")"
  
  if [[ -z "$version_content" ]]; then
    log_error "KRYTYCZNY BŁĄD: Plik version.txt jest pusty po publikacji!"
    log_error "Ścieżka: $version_txt_path"
    return 1
  fi
  
  log_success "Weryfikacja version.txt po publikacji: OK (wersja: $version_content)"
  return 0
}

# Krok 5: Release na GitHub
step_github_release() {
  log_step "KROK 5: Release na GitHub"
  
  # Sprawdź czy version.txt istnieje (wymagane przez _GithubPublish.sh)
  local version_txt_path="$PROJECT_ROOT/version.txt"
  if [[ ! -f "$version_txt_path" ]]; then
    log_error "KRYTYCZNY BŁĄD: Plik version.txt nie istnieje!"
    log_error "Ścieżka: $version_txt_path"
    return 1
  fi
  
  # Sprawdź czy README.md istnieje (wymagane przez _GithubPublish.sh)
  local readme_path="$PROJECT_ROOT/README.md"
  if [[ ! -f "$readme_path" ]]; then
    log_error "KRYTYCZNY BŁĄD: Plik README.md nie istnieje!"
    log_error "Ścieżka: $readme_path"
    return 1
  fi
  
  # Wykryj repozytorium GitHub
  local github_repo
  github_repo="$(detect_github_repo)"
  log_info "Repozytorium GitHub: $github_repo"
  
  # Sprawdź czy _GithubPublish.sh istnieje
  local github_publish_script="$SCRIPT_DIR/_GithubPublish.sh"
  if [[ ! -f "$github_publish_script" ]]; then
    log_error "KRYTYCZNY BŁĄD: Skrypt _GithubPublish.sh nie istnieje!"
    log_error "Ścieżka: $github_publish_script"
    return 1
  fi
  
  # Wywołaj _GithubPublish.sh z flagą --force (automatyczne nadpisanie release jeśli istnieje)
  log_info "Wywołanie _GithubPublish.sh..."
  
  # Wywołaj z pełnym redirectem stdout/stderr
  if "$github_publish_script" \
    --repo-dir "$PROJECT_ROOT" \
    --github-repo "$github_repo" \
    --force 2>&1; then
    log_success "Release na GitHub zakończony pomyślnie (_GithubPublish.sh)"
    return 0
  else
    log_error "Nie udało się utworzyć release na GitHub (_GithubPublish.sh zwrócił błąd)"
    return 1
  fi
}

# ---------- Główna funkcja ----------
main() {
  # Parsowanie argumentów
  parse_arguments "$@"
  
  if [[ "$TEST_MODE" == "true" ]]; then
    log_header "🧪 BUILD AND PUBLISH AND RELEASE ALL - TRYB TESTOWY 🧪"
  else
    log_header "🚀 BUILD AND PUBLISH AND RELEASE ALL 🚀"
  fi
  
  echo -e "${WHITE}Projekt: ${CYAN}$PROJECT_ROOT${RESET}"
  echo -e "${WHITE}Skrypt: ${CYAN}$SCRIPT_NAME v$SCRIPT_VERSION${RESET}"
  echo -e "${WHITE}Tryb: ${CYAN}$([[ "$TEST_MODE" == "true" ]] && echo "TESTOWY" || echo "NORMALNY")${RESET}"
  echo -e "${WHITE}Data: ${CYAN}$(timestamp)${RESET}"
  echo ""
  
  # KROK 0: Usuń pliki .bak z repozytorium
  cleanup_bak_files
  
  # Walidacja środowiska
  validate_environment
  
  # Krok 1: Wersjonowanie
  if ! step_version_artifacts; then
    log_error "Proces przerwany: wersjonowanie nie powiodło się"
    exit 1
  fi
  
  # Pobierz wersję po wersjonowaniu
  local version
  version="$(get_version)" || {
    log_error "Nie można określić wersji"
    exit 1
  }
  
  log_info "Wersja projektu: $version"
  
  # Krok 2: Build dla wszystkich platform
  if ! step_build_all_platforms; then
    log_error "Proces przerwany: build nie powiódł się"
    exit 1
  fi
  
  # Krok 3: Uruchomienie testów
  if ! step_run_tests; then
    log_error "Proces przerwany: testy nie przeszły"
    exit 1
  fi
  
  # Jeśli powyższe zakończyły się sukcesem, kontynuuj:
  
  if [[ "$TEST_MODE" == "true" ]]; then
    # TRYB TESTOWY: pomiń publikację lokalną
    
    log_info "Tryb testowy: pomijanie publikacji lokalnej"
    
    # Krok 4: Release na GitHub
    local github_repo
    github_repo="$(detect_github_repo)"
    
    if ! step_github_release; then
      log_error "Proces przerwany: release na GitHub nie powiódł się"
      exit 1
    fi
    
    # Krok 4: Weryfikacja release (z retry, jeśli potrzebne)
    log_step "KROK 4: Weryfikacja release na GitHub"
    log_info "Czekanie 3 sekundy na propagację release na GitHub..."
    sleep 3
    
    local verify_attempts=0
    local max_verify_attempts=5
    local verify_success=false
    
    while [[ $verify_attempts -lt $max_verify_attempts ]]; do
      verify_attempts=$((verify_attempts + 1))
      log_info "Próba weryfikacji $verify_attempts/$max_verify_attempts..."
      
      if verify_github_release "$github_repo" "$version"; then
        verify_success=true
        break
      else
        if [[ $verify_attempts -lt $max_verify_attempts ]]; then
          log_warning "Weryfikacja nie powiodła się, czekanie 5 sekund przed ponowną próbą..."
          sleep 5
        fi
      fi
    done
    
    if [[ "$verify_success" != "true" ]]; then
      log_error "Proces przerwany: weryfikacja release nie powiodła się po $max_verify_attempts próbach"
      exit 1
    fi
    
    # Krok 5: Usunięcie release na GitHub
    if ! delete_github_release "$github_repo" "$version"; then
      log_error "Proces przerwany: usunięcie release nie powiodło się"
      exit 1
    fi
    
    # Podsumowanie trybu testowego
    log_header "✅ TRYB TESTOWY ZAKOŃCZONY POMYŚLNIE!"
    log_success "🎉 Test build, publish i release zakończony sukcesem!"
    echo ""
    echo -e "${WHITE}Wykonane kroki (tryb testowy):${RESET}"
    echo -e "${GREEN}  ✓${RESET} Wersjonowanie artefaktów"
    echo -e "${GREEN}  ✓${RESET} Build dla wszystkich platform (Linux, macOS, Windows)"
    echo -e "${GREEN}  ✓${RESET} Uruchomienie testów"
    echo -e "${YELLOW}  ⊘${RESET} Publikacja lokalna (pominięta w trybie testowym)"
    echo -e "${GREEN}  ✓${RESET} Release na GitHub (z weryfikacją version.txt)"
    echo -e "${GREEN}  ✓${RESET} Weryfikacja release i artefaktów"
    echo -e "${GREEN}  ✓${RESET} Usunięcie release na GitHub"
    echo ""
    log_info "Wszystkie testy zakończone pomyślnie - można uruchomić tryb normalny"
    
  else
    # TRYB NORMALNY
    
    # Krok 3: Publikacja lokalna
    if ! step_publish_local; then
      log_error "Proces przerwany: publikacja lokalna nie powiodła się"
      exit 1
    fi
    
    # Krok 4: Release na GitHub
    if ! step_github_release; then
      log_error "Proces przerwany: release na GitHub nie powiódł się"
      exit 1
    fi
    
    # Krok 6: Weryfikacja release (z retry, jeśli potrzebne)
    log_step "KROK 6: Weryfikacja release na GitHub"
    log_info "Czekanie 3 sekundy na propagację release na GitHub..."
    sleep 3
    
    local github_repo
    github_repo="$(detect_github_repo)"
    
    local verify_attempts=0
    local max_verify_attempts=5
    local verify_success=false
    
    while [[ $verify_attempts -lt $max_verify_attempts ]]; do
      verify_attempts=$((verify_attempts + 1))
      log_info "Próba weryfikacji $verify_attempts/$max_verify_attempts..."
      
      if verify_github_release "$github_repo" "$version"; then
        verify_success=true
        break
      else
        if [[ $verify_attempts -lt $max_verify_attempts ]]; then
          log_warning "Weryfikacja nie powiodła się, czekanie 5 sekund przed ponowną próbą..."
          sleep 5
        fi
      fi
    done
    
    if [[ "$verify_success" != "true" ]]; then
      log_error "Proces przerwany: weryfikacja release nie powiodła się po $max_verify_attempts próbach"
      exit 1
    fi
    
    # Podsumowanie trybu normalnego
    log_header "✅ WSZYSTKIE KROKI ZAKOŃCZONE POMYŚLNIE!"
    log_success "🎉 Proces build, publish i release zakończony sukcesem!"
    echo ""
    echo -e "${WHITE}Wykonane kroki:${RESET}"
    echo -e "${GREEN}  ✓${RESET} Wersjonowanie artefaktów (z version.txt)"
    echo -e "${GREEN}  ✓${RESET} Build dla wszystkich platform (Linux, macOS, Windows)"
    echo -e "${GREEN}  ✓${RESET} Uruchomienie wszystkich testów"
    echo -e "${GREEN}  ✓${RESET} Publikacja lokalna"
    echo -e "${GREEN}  ✓${RESET} Release na GitHub (z version.txt jako asset)"
    echo -e "${GREEN}  ✓${RESET} Weryfikacja release i artefaktów (w tym version.txt)"
    echo ""
  fi
  
  return 0
}

# ---------- Punkt wejścia skryptu ----------

# Uruchom główną funkcję z wszystkimi argumentami
main "$@"

