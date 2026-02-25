# Current State

## Active Task
Add configurable deletion settings: DeletionMode, batch size, transaction wrapping — R-1.7.0

## Status
completed

## Completion
100% — Committed, pushed, release published on GitHub

## Last Action
Published R-1.7.0 release with DeletionMode enum, DeletionOptions entity, configurable executors, Desktop Deletion Settings step, CLI --deletion-mode/--use-transaction/--batch-size wired through.

## Next Step
None — release fully completed.

## Files Modified This Session
- `src/DatabaseDeletor.Domain/Enums/DeletionMode.cs` — NEW: BatchDelete/SingleRowDelete/DirectDelete enum
- `src/DatabaseDeletor.Domain/Entities/DeletionOptions.cs` — NEW: Mode, BatchSize, UseTransaction, EffectiveBatchSize, IsValid
- `src/DatabaseDeletor.Domain/Interfaces/IBulkDeleteExecutor.cs` — added DeletionOptions, DbConnection?, DbTransaction? params
- `src/DatabaseDeletor.Domain/Interfaces/IDeletionExecutor.cs` — added DeletionOptions param
- `src/DatabaseDeletor.Infrastructure/Database/Executors/SqlServerBulkDeleteExecutor.cs` — mode-based execution, configurable batch size
- `src/DatabaseDeletor.Infrastructure/Database/Executors/PostgreSqlBulkDeleteExecutor.cs` — same
- `src/DatabaseDeletor.Infrastructure/Database/Executors/MySqlBulkDeleteExecutor.cs` — same
- `src/DatabaseDeletor.Infrastructure/Database/Executors/OracleBulkDeleteExecutor.cs` — same
- `src/DatabaseDeletor.Infrastructure/Services/DeletionExecutor.cs` — transaction wrapping, DeletionOptions passthrough
- `src/DatabaseDeletor.Application/Commands/ExecuteDeletionCommand.cs` — added DeletionOptions field
- `src/DatabaseDeletor.Application/Commands/ExecuteDeletionHandler.cs` — pass DeletionOptions through
- `src/DatabaseDeletor.Cli/Program.cs` — --deletion-mode, --use-transaction, --batch-size wired
- `src/DatabaseDeletor.Cli/DeletionService.cs` — DeletionOptions param
- `src/DatabaseDeletor.Cli/ConsoleRenderer.cs` — WriteDeletionSettings method
- `src/DatabaseDeletor.Desktop/ViewModels/DeletionSettingsStepViewModel.cs` — NEW: step ViewModel
- `src/DatabaseDeletor.Desktop/Views/DeletionSettingsStepView.axaml` — NEW: step View
- `src/DatabaseDeletor.Desktop/Views/DeletionSettingsStepView.axaml.cs` — NEW: code-behind
- `src/DatabaseDeletor.Desktop/ViewModels/MainWindowViewModel.cs` — 6 steps, DeletionSettings inserted
- `src/DatabaseDeletor.Desktop/ViewModels/ExecutionStepViewModel.cs` — tuple includes DeletionOptions
- `src/DatabaseDeletor.Desktop/Views/MainWindow.axaml` — DataTemplate for DeletionSettingsStepViewModel
- `src/DatabaseDeletor.Desktop/Views/ExecutionStepView.axaml` — Step 6 label
- `src/DatabaseDeletor.Desktop/App.axaml.cs` — registered DeletionSettingsStepViewModel
- `tests/DatabaseDeletor.Domain.Tests/Enums/DeletionModeTests.cs` — NEW: 5 tests
- `tests/DatabaseDeletor.Domain.Tests/Entities/DeletionOptionsTests.cs` — NEW: 11 tests
- `tests/DatabaseDeletor.Application.Tests/Commands/ExecuteDeletionHandlerTests.cs` — updated for DeletionOptions
- `tests/DatabaseDeletor.Infrastructure.Tests/Services/DeletionExecutorTests.cs` — updated + new test
- `tests/DatabaseDeletor.Cli.Tests/DeletionServiceTests.cs` — updated + new test
- `version.txt` — 1.6.0 → 1.7.0

## Open Decisions
- None

## Blockers (NEEDS INPUT)
- None

## Git State
- Branch: master
- Last commit: 3f4a44d Add configurable deletion settings: DeletionMode, batch size, transaction wrapping, v1.7.0
- Pushed to: origin/main
- Release: R-1.7.0 (PUBLISHED, 5 assets)

## Loaded Rules
- general.md, dotnet.md

## User Preferences (This Session)
- Commit, push, and release only when explicitly asked
- Separate version numbers for bugfix releases (never reuse a version)
