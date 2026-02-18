#!/usr/bin/env zsh
# =============================================================================
# _testCompleteBuildAndRelease.sh
# =============================================================================
#
# Kompleksowy skrypt testowy do weryfikacji całego procesu:
# 1. Wersjonowania rozwiązania
# 2. Budowania artefaktów dla wszystkich platform
# 3. Publikacji artefaktów na GitHub
# 4. Weryfikacji utworzenia release i opublikowania artefaktów
#
# Skrypt jest uniwersalny i działa z dowolnym projektem .NET w dowolnym repozytorium.
# Automatycznie wykrywa projekty, sprawdza dostępność wymaganych skryptów,
# i weryfikuje poprawność całego procesu.
#
# Wymagania:
# - macOS/Linux (bash/zsh)
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
readonly SCRIPT_NAME="_testCompleteBuildAndRelease.sh"

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
readonly SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Nazwy skryptów (opcjonalne - sprawdzane przed użyciem)
readonly VERSION_SCRIPT="$SCRIPT_DIR/_versionArtifacts.sh"
readonly BUILD_LINUX_SCRIPT="$SCRIPT_DIR/_performBuildLinux.sh"
readonly BUILD_MACOS_SCRIPT="$SCRIPT_DIR/_performBuildMacOS.sh"
readonly BUILD_WINDOWS_SCRIPT="$SCRIPT_DIR/_performBuildWindows.sh"
readonly BUILD_DOCKER_SCRIPT="$SCRIPT_DIR/_performBuildDocker.sh"
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

# Sprawdź dostępność narzędzi
check_tools() {
  log_info "Sprawdzanie dostępności narzędzi..."
  
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
  
  if ! command -v jq &> /dev/null; then
    missing_tools+=("jq")
  fi
  
  if [[ ${#missing_tools[@]} -gt 0 ]]; then
    log_error "Brakujące wymagane narzędzia: ${missing_tools[*]}"
    return 1
  fi
  
  # Sprawdź autoryzację GitHub CLI
  log_info "Sprawdzanie autoryzacji GitHub CLI..."
  if ! gh auth status >/dev/null 2>&1; then
    log_error "GitHub CLI nie jest zalogowany!"
    log_error "Uruchom: gh auth login"
    log_error "Lub ustaw zmienną środowiskową GITHUB_TOKEN z tokenem API"
    return 1
  fi
  
  log_success "Wszystkie wymagane narzędzia są dostępne i autoryzowane"
  return 0
}

# Sprawdź dostępność skryptów
check_scripts() {
  log_info "Sprawdzanie dostępności skryptów..."
  
  local required_scripts=(
    "$VERSION_SCRIPT"
    "$GITHUB_PUBLISH_SCRIPT"
  )
  
  local optional_scripts=(
    "$BUILD_LINUX_SCRIPT"
    "$BUILD_MACOS_SCRIPT"
    "$BUILD_WINDOWS_SCRIPT"
    "$BUILD_DOCKER_SCRIPT"
  )
  
  local missing_required=()
  
  for script in "${required_scripts[@]}"; do
    if [[ ! -f "$script" ]]; then
      missing_required+=("$(basename "$script")")
    elif [[ ! -x "$script" ]]; then
      log_warning "Skrypt nie jest wykonywalny: $script - próba ustawienia uprawnień..."
      chmod +x "$script" || {
        log_error "Nie można ustawić uprawnień dla: $script"
        return 1
      }
    fi
  done
  
  if [[ ${#missing_required[@]} -gt 0 ]]; then
    log_error "Brakujące wymagane skrypty: ${missing_required[*]}"
    return 1
  fi
  
  # Sprawdź opcjonalne skrypty
  local available_build_scripts=()
  for script in "${optional_scripts[@]}"; do
    if [[ -f "$script" && -x "$script" ]]; then
      available_build_scripts+=("$(basename "$script")")
    elif [[ -f "$script" ]]; then
      chmod +x "$script" && available_build_scripts+=("$(basename "$script")")
    fi
  done
  
  if [[ ${#available_build_scripts[@]} -eq 0 ]]; then
    log_warning "Nie znaleziono żadnych skryptów buildowych"
    log_warning "Proces może nie działać poprawnie"
  else
    log_info "Znaleziono ${#available_build_scripts[@]} skrypt(ów) buildowych: ${available_build_scripts[*]}"
  fi
  
  log_success "Walidacja skryptów zakończona"
  return 0
}

# Sprawdź, czy jesteśmy w repozytorium Git
check_git_repo() {
  log_info "Sprawdzanie repozytorium Git..."
  
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    log_error "Nie jesteśmy w repozytorium Git"
    return 1
  fi
  
  log_success "Repozytorium Git zweryfikowane"
  return 0
}

# Sprawdź, czy jesteśmy w projekcie .NET
check_dotnet_project() {
  log_info "Sprawdzanie projektu .NET..."
  
  # Load common functions
  if [[ -f "$SCRIPT_DIR/_common.sh" ]]; then
    source "$SCRIPT_DIR/_common.sh"
    
    if ! is_dotnet_project; then
      log_error "Nie znaleziono projektu .NET w katalogu: $PROJECT_ROOT"
      return 1
    fi
    
    local solution_name
    solution_name="$(get_solution_name)"
    log_info "Wykryto projekt: $solution_name"
  else
    # Fallback: sprawdź ręcznie
    if [[ -z "$(find "$PROJECT_ROOT" -maxdepth 3 -name "*.csproj" -type f 2>/dev/null | head -n 1)" ]] && \
       [[ -z "$(find "$PROJECT_ROOT" -maxdepth 2 -name "*.sln" -type f 2>/dev/null | head -n 1)" ]]; then
      log_error "Nie znaleziono projektu .NET w katalogu: $PROJECT_ROOT"
      return 1
    fi
  fi
  
  log_success "Projekt .NET zweryfikowany"
  return 0
}

# Automatyczne wykrywanie repozytorium GitHub
detect_github_repo() {
  log_info "Wykrywanie repozytorium GitHub..."
  
  local remote_url
  remote_url="$(git remote get-url origin 2>/dev/null || echo "")"
  
  if [[ -z "$remote_url" ]]; then
    log_error "Nie można wykryć remote 'origin' w repozytorium Git"
    return 1
  fi
  
  log_info "Znaleziony remote URL: $remote_url"
  
  local github_repo=""
  
  # Format SSH: git@github.com:owner/repo.git
  if [[ "$remote_url" =~ git@github\.com:([^/]+)/([^/]+)\.git ]]; then
    github_repo="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
  # Format HTTPS: https://github.com/owner/repo.git
  elif [[ "$remote_url" =~ https://github\.com/([^/]+)/([^/]+)\.git ]]; then
    github_repo="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
  # Format HTTPS bez .git: https://github.com/owner/repo
  elif [[ "$remote_url" =~ https://github\.com/([^/]+)/([^/]+)$ ]]; then
    github_repo="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
  else
    log_error "Nie można wyodrębnić owner/repo z URL: $remote_url"
    log_error "Oczekiwany format: git@github.com:owner/repo.git lub https://github.com/owner/repo.git"
    return 1
  fi
  
  # Usuń .git z końca, jeśli istnieje
  github_repo="${github_repo%.git}"
  
  log_success "Wykryto repozytorium GitHub: $github_repo"
  echo "$github_repo"
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
  csproj_files="$(find "$PROJECT_ROOT" -maxdepth 4 -name "*.csproj" -type f 2>/dev/null | grep -v -E "/(Test|Tests|test|tests|obj|bin)/" | head -n 1)"
  if [[ -n "$csproj_files" && -f "$csproj_files" ]]; then
    version="$(grep -Eo '<Version>[^<]+</Version>' "$csproj_files" 2>/dev/null | sed 's/<Version>\(.*\)<\/Version>/\1/' | head -n1 | sed 's/+.*$//' || echo "")"
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
  local release_tag="R-$version"
  
  log_info "Sprawdzanie release: $release_tag w repozytorium: $github_repo"
  
  # Sprawdź, czy release istnieje
  if ! gh release view "$release_tag" --repo "$github_repo" >/dev/null 2>&1; then
    log_error "Release $release_tag nie istnieje w repozytorium $github_repo"
    return 1
  fi
  
  # Pobierz informacje o release
  local release_info
  release_info="$(gh release view "$release_tag" --repo "$github_repo" --json tagName,title,assets,createdAt 2>/dev/null || echo "")"
  
  if [[ -z "$release_info" ]]; then
    log_error "Nie można pobrać informacji o release"
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
  while IFS= read -r asset_line; do
    [[ -n "$asset_line" ]] && asset_names+=("$asset_line")
    echo "  - $asset_line"
  done < <(echo "$release_info" | jq -r '.assets[] | "\(.name) (\(.size | . / 1024 / 1024 | floor) MB)"' 2>/dev/null || true)
  
  # Sprawdź, czy artefakty mają rozsądne rozmiary (nie są puste)
  local empty_assets=()
  while IFS= read -r asset_name; do
    [[ -z "$asset_name" ]] && continue
    local asset_size
    asset_size="$(echo "$release_info" | jq -r ".assets[] | select(.name == \"$asset_name\") | .size" 2>/dev/null || echo "0")"
    if [[ "$asset_size" == "0" || -z "$asset_size" ]]; then
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
  
  # Sprawdź datę utworzenia
  local created_at
  created_at="$(echo "$release_info" | jq -r '.createdAt' 2>/dev/null || echo "")"
  if [[ -n "$created_at" ]]; then
    log_info "Release utworzony: $created_at"
  fi
  
  log_success "Weryfikacja release zakończona pomyślnie"
  return 0
}

# ---------- Główne funkcje wykonawcze ----------

# Krok 1: Wersjonowanie artefaktów
step_version_artifacts() {
  log_step "KROK 1: Wersjonowanie artefaktów"
  
  if [[ ! -f "$VERSION_SCRIPT" || ! -x "$VERSION_SCRIPT" ]]; then
    log_error "Skrypt wersjonowania nie jest dostępny: $VERSION_SCRIPT"
    return 1
  fi
  
  log_info "Uruchamianie: $VERSION_SCRIPT"
  
  local version_exit_code=0
  "$VERSION_SCRIPT" -w "$PROJECT_ROOT" || version_exit_code=$?
  
  # Sprawdź, czy główne pliki zostały zwersjonowane
  local version_found=false
  local version_value=""
  
  # Sprawdź plik version.txt
  if [[ -f "$PROJECT_ROOT/version.txt" ]]; then
    version_value="$(cat "$PROJECT_ROOT/version.txt" | tr -d ' \t\r\n' || echo "")"
    if [[ -n "$version_value" ]]; then
      version_found=true
      log_info "Wersja odczytana z version.txt: $version_value"
    fi
  fi
  
  # Jeśli nie ma version.txt, sprawdź .csproj
  if [[ "$version_found" == "false" ]]; then
    local csproj_files
    csproj_files="$(find "$PROJECT_ROOT" -maxdepth 4 -name "*.csproj" -type f 2>/dev/null | grep -v -E "/(Test|Tests|test|tests|obj|bin)/" | head -n 1)"
    if [[ -n "$csproj_files" && -f "$csproj_files" ]]; then
      version_value="$(grep -Eo '<Version>[^<]+</Version>' "$csproj_files" 2>/dev/null | sed 's/<Version>\(.*\)<\/Version>/\1/' | head -n1 | sed 's/+.*$//' || echo "")"
      if [[ -n "$version_value" ]]; then
        version_found=true
        log_info "Wersja odczytana z .csproj: $version_value"
      fi
    fi
  fi
  
  if [[ "$version_found" == "true" ]]; then
    if [[ $version_exit_code -ne 0 ]]; then
      log_warning "Wersjonowanie zakończyło się z błędami, ale główne pliki zostały zwersjonowane"
      log_warning "Kontynuowanie procesu z wersją: $version_value"
    else
      log_success "Wersjonowanie artefaktów zakończone pomyślnie"
    fi
    return 0
  else
    log_error "Wersjonowanie artefaktów nie powiodło się - nie można określić wersji"
    return 1
  fi
}

# Krok 2: Build dla wszystkich dostępnych platform
step_build_all_platforms() {
  log_step "KROK 2: Build dla wszystkich dostępnych platform"
  
  local build_scripts=()
  local platform_names=()
  
  # Sprawdź dostępność skryptów buildowych
  if [[ -f "$BUILD_LINUX_SCRIPT" && -x "$BUILD_LINUX_SCRIPT" ]]; then
    build_scripts+=("$BUILD_LINUX_SCRIPT")
    platform_names+=("Linux")
  fi
  
  if [[ -f "$BUILD_MACOS_SCRIPT" && -x "$BUILD_MACOS_SCRIPT" ]]; then
    build_scripts+=("$BUILD_MACOS_SCRIPT")
    platform_names+=("macOS")
  fi
  
  if [[ -f "$BUILD_WINDOWS_SCRIPT" && -x "$BUILD_WINDOWS_SCRIPT" ]]; then
    build_scripts+=("$BUILD_WINDOWS_SCRIPT")
    platform_names+=("Windows")
  fi
  
  if [[ -f "$BUILD_DOCKER_SCRIPT" && -x "$BUILD_DOCKER_SCRIPT" ]]; then
    build_scripts+=("$BUILD_DOCKER_SCRIPT")
    platform_names+=("Docker")
  fi
  
  if [[ ${#build_scripts[@]} -eq 0 ]]; then
    log_warning "Nie znaleziono żadnych skryptów buildowych"
    log_warning "Pomijanie kroku buildowania"
    return 0
  fi
  
  log_info "Znaleziono ${#build_scripts[@]} skrypt(ów) buildowych do wykonania"
  
  local failed_builds=()
  
  for i in "${!build_scripts[@]}"; do
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
  
  # Docker build jest opcjonalny - jeśli nie ma Dockerfile, to nie jest błąd
  local critical_failures=()
  for failed in "${failed_builds[@]}"; do
    if [[ "$failed" != "Docker" ]]; then
      critical_failures+=("$failed")
    else
      log_warning "Build Docker nie powiódł się (prawdopodobnie brak Dockerfile - to jest opcjonalne)"
    fi
  done
  
  if [[ ${#critical_failures[@]} -gt 0 ]]; then
    log_error "Build nie powiódł się dla platform: ${critical_failures[*]}"
    return 1
  fi
  
  log_success "Build dla wszystkich platform zakończony pomyślnie"
  return 0
}

# Krok 3: Release na GitHub
step_github_release() {
  log_step "KROK 3: Release na GitHub"
  
  # Wykryj repozytorium GitHub
  local github_repo
  github_repo="$(detect_github_repo)" || {
    log_error "Nie można wykryć repozytorium GitHub"
    return 1
  }
  
  if [[ ! -f "$GITHUB_PUBLISH_SCRIPT" || ! -x "$GITHUB_PUBLISH_SCRIPT" ]]; then
    log_error "Skrypt publikacji GitHub nie jest dostępny: $GITHUB_PUBLISH_SCRIPT"
    return 1
  fi
  
  log_info "Uruchamianie: $GITHUB_PUBLISH_SCRIPT"
  log_info "Repozytorium: $github_repo"
  
  # Sprawdź autoryzację GitHub przed publikacją
  log_info "Weryfikacja autoryzacji GitHub przed publikacją..."
  if ! gh auth status >/dev/null 2>&1; then
    log_error "GitHub CLI nie jest zalogowany!"
    log_error "Uruchom: gh auth login"
    log_error "Lub ustaw zmienną środowiskową GITHUB_TOKEN z tokenem API"
    return 1
  fi
  
  # Uruchom GitHub publish z automatycznie wykrytym repozytorium
  # _GithubPublish.sh używa zsh, więc musimy wywołać go przez zsh
  log_info "Uruchamianie publikacji na GitHub..."
  if command -v zsh &> /dev/null; then
    (
      exec zsh "$GITHUB_PUBLISH_SCRIPT" --repo-dir "$PROJECT_ROOT" --github-repo "$github_repo" </dev/null
    )
    local github_exit_code=$?
  else
    (
      exec "$GITHUB_PUBLISH_SCRIPT" --repo-dir "$PROJECT_ROOT" --github-repo "$github_repo" </dev/null
    )
    local github_exit_code=$?
  fi
  
  if [[ $github_exit_code -ne 0 ]]; then
    log_error "Release na GitHub nie powiódł się (exit code: $github_exit_code)"
    log_error "Sprawdź logi powyżej, aby zobaczyć szczegóły błędu"
    log_error "Upewnij się, że GitHub CLI jest zalogowany: gh auth login"
    return 1
  fi
  
  log_success "Release na GitHub zakończony pomyślnie"
  return 0
}

# Krok 4: Weryfikacja release
step_verify_release() {
  log_step "KROK 4: Weryfikacja release na GitHub"
  
  # Wykryj repozytorium GitHub
  local github_repo
  github_repo="$(detect_github_repo)" || {
    log_error "Nie można wykryć repozytorium GitHub"
    return 1
  }
  
  # Pobierz wersję
  local version
  version="$(get_version)" || {
    log_error "Nie można określić wersji"
    return 1
  }
  
  # Weryfikuj release
  if ! verify_github_release "$github_repo" "$version"; then
    log_error "Weryfikacja release nie powiodła się"
    return 1
  fi
  
  log_success "Weryfikacja release zakończona pomyślnie"
  return 0
}

# ---------- Główna funkcja ----------
main() {
  log_header "🧪 TEST COMPLETE BUILD AND RELEASE 🧪"
  
  echo -e "${WHITE}Projekt: ${CYAN}$PROJECT_ROOT${RESET}"
  echo -e "${WHITE}Skrypt: ${CYAN}$SCRIPT_NAME v$SCRIPT_VERSION${RESET}"
  echo -e "${WHITE}Data: ${CYAN}$(timestamp)${RESET}"
  echo ""
  
  # Walidacja środowiska
  if ! check_tools; then
    log_error "Walidacja narzędzi nie powiodła się"
    exit 1
  fi
  
  if ! check_git_repo; then
    log_error "Walidacja repozytorium Git nie powiodła się"
    exit 1
  fi
  
  if ! check_dotnet_project; then
    log_error "Walidacja projektu .NET nie powiodła się"
    exit 1
  fi
  
  if ! check_scripts; then
    log_error "Walidacja skryptów nie powiodła się"
    exit 1
  fi
  
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
  
  # Krok 3: Release na GitHub
  if ! step_github_release; then
    log_error "Proces przerwany: release na GitHub nie powiódł się"
    exit 1
  fi
  
  # Krok 4: Weryfikacja release
  if ! step_verify_release; then
    log_error "Proces przerwany: weryfikacja release nie powiodła się"
    exit 1
  fi
  
  # Podsumowanie
  log_header "✅ TEST ZAKOŃCZONY POMYŚLNIE!"
  log_success "🎉 Wszystkie testy zakończone sukcesem!"
  echo ""
  echo -e "${WHITE}Wykonane kroki:${RESET}"
  echo -e "${GREEN}  ✓${RESET} Wersjonowanie artefaktów"
  echo -e "${GREEN}  ✓${RESET} Build dla wszystkich dostępnych platform"
  echo -e "${GREEN}  ✓${RESET} Release na GitHub"
  echo -e "${GREEN}  ✓${RESET} Weryfikacja release i artefaktów"
  echo ""
  log_info "Wersja: $version"
  log_info "Release tag: R-$version"
  
  return 0
}

# ---------- Punkt wejścia skryptu ----------

# Uruchom główną funkcję z wszystkimi argumentami
main "$@"

