# Current State

## Active Task
Add copyright notice, Help/About/Documentation windows — R-1.6.0 release

## Status
completed

## Completion
100% — Committed, pushed, release published on GitHub

## Last Action
Published R-1.6.0 release with Help/About window, Documentation viewer, and CLI copyright banner.

## Next Step
None — release fully completed.

## Files Modified This Session
- `Directory.Packages.props` — added Markdown.Avalonia.Tight 11.0.2
- `src/DatabaseDeletor.Cli/Program.cs` — copyright banner at startup
- `src/DatabaseDeletor.Desktop/DatabaseDeletor.Desktop.csproj` — Markdown.Avalonia.Tight, README.md + version.txt as Content
- `src/DatabaseDeletor.Desktop/Views/AboutWindow.axaml` — NEW: About window with copyright + version
- `src/DatabaseDeletor.Desktop/Views/AboutWindow.axaml.cs` — NEW: code-behind with version loading + Documentation link
- `src/DatabaseDeletor.Desktop/Views/DocumentationWindow.axaml` — NEW: Markdown viewer window
- `src/DatabaseDeletor.Desktop/Views/DocumentationWindow.axaml.cs` — NEW: code-behind loading README.md
- `src/DatabaseDeletor.Desktop/Views/MainWindow.axaml` — Help button in bottom bar
- `src/DatabaseDeletor.Desktop/Views/MainWindow.axaml.cs` — OnHelpClick handler
- `version.txt` — bumped 1.5.0 → 1.6.0

## Open Decisions
- None

## Blockers (NEEDS INPUT)
- None

## Git State
- Branch: master
- Last commit: 824bc98 Add copyright notice, Help/About window, and Documentation viewer, v1.6.0
- Pushed to: origin/main
- Release: R-1.6.0 (PUBLISHED, 5 assets)

## Loaded Rules
- general.md, dotnet.md

## User Preferences (This Session)
- Commit, push, and release only when explicitly asked
- Separate version numbers for bugfix releases (never reuse a version)
