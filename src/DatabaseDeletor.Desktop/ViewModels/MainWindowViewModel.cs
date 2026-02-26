using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Enums;

namespace DatabaseDeletor.Desktop.ViewModels;

public sealed partial class MainWindowViewModel : ViewModelBase
{
    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(CanGoBack))]
    [NotifyPropertyChangedFor(nameof(CanGoNext))]
    [NotifyPropertyChangedFor(nameof(IsLastStep))]
    [NotifyCanExecuteChangedFor(nameof(GoBackCommand))]
    [NotifyCanExecuteChangedFor(nameof(GoNextCommand))]
    private int _currentStepIndex;

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(CanGoBack))]
    [NotifyPropertyChangedFor(nameof(CanGoNext))]
    [NotifyCanExecuteChangedFor(nameof(GoBackCommand))]
    [NotifyCanExecuteChangedFor(nameof(GoNextCommand))]
    private bool _isBusy;

    [ObservableProperty]
    private ViewModelBase _currentStep;

    public ConnectionStepViewModel ConnectionStep { get; }
    public ConditionsStepViewModel ConditionsStep { get; }
    public AnalysisStepViewModel AnalysisStep { get; }
    public SummaryStepViewModel SummaryStep { get; }
    public DeletionSettingsStepViewModel DeletionSettingsStep { get; }
    public ExecutionStepViewModel ExecutionStep { get; }

    public bool CanGoBack => CurrentStepIndex > 0 && !ExecutionStep.IsExecuting && !IsBusy;
    public bool CanGoNext => CurrentStepIndex < 5 && !ExecutionStep.IsExecuting && !IsBusy;
    public bool IsLastStep => CurrentStepIndex == 5;

    public IReadOnlyList<string> StepTitles { get; } =
    [
        "1. Connection & Tables",
        "2. Root Table & Conditions",
        "3. Dependency Analysis",
        "4. Summary",
        "5. Deletion Settings",
        "6. Execution"
    ];

    public MainWindowViewModel(
        ConnectionStepViewModel connectionStep,
        AnalysisStepViewModel analysisStep,
        ConditionsStepViewModel conditionsStep,
        SummaryStepViewModel summaryStep,
        DeletionSettingsStepViewModel deletionSettingsStep,
        ExecutionStepViewModel executionStep)
    {
        ConnectionStep = connectionStep;
        AnalysisStep = analysisStep;
        ConditionsStep = conditionsStep;
        SummaryStep = summaryStep;
        DeletionSettingsStep = deletionSettingsStep;
        ExecutionStep = executionStep;
        _currentStep = connectionStep;
    }

    [RelayCommand(CanExecute = nameof(CanGoBack))]
    private void GoBack()
    {
        if (CurrentStepIndex > 0)
        {
            CurrentStepIndex--;
            UpdateCurrentStep();
        }
    }

    [RelayCommand(CanExecute = nameof(CanGoNext))]
    private async Task GoNextAsync(CancellationToken ct)
    {
        switch (CurrentStepIndex)
        {
            case 0: // Connection → Conditions
                if (!ConnectionStep.IsConnected) return;
                ConditionsStep.LoadTables(ConnectionStep.GetSelectedTables(), ConnectionStep.ConnectionString);
                CurrentStepIndex++;
                UpdateCurrentStep();
                break;

            case 1: // Conditions → Analysis
                if (ConditionsStep.EffectiveRootTable is null) return;
                CurrentStepIndex++;
                UpdateCurrentStep();
                IsBusy = true;
                try
                {
                    await AnalysisStep.AnalyzeCommand.ExecuteAsync(
                        (ConnectionStep.ConnectionString,
                         ConditionsStep.EffectiveRootTable,
                         ConnectionStep.GetSelectedTables(),
                         ConnectionStep.GetExcludedTables())).ConfigureAwait(true);
                }
                finally
                {
                    IsBusy = false;
                }

                break;

            case 2: // Analysis → Summary
                if (!AnalysisStep.IsValid || AnalysisStep.Graph is null) return;
                CurrentStepIndex++;
                UpdateCurrentStep();
                IsBusy = true;
                try
                {
                    await SummaryStep.GeneratePlanCommand.ExecuteAsync(
                        (ConnectionStep.ConnectionString,
                         AnalysisStep.Graph,
                         ConditionsStep.EffectiveRootTable!,
                         ConditionsStep.WhereClause)).ConfigureAwait(true);
                }
                finally
                {
                    IsBusy = false;
                }

                break;

            case 3: // Summary → Deletion Settings
                if (SummaryStep.Plan is null) return;
                CurrentStepIndex++;
                UpdateCurrentStep();
                break;

            case 4: // Deletion Settings → Execution
                if (DeletionSettingsStep.HasValidationErrors) return;
                CurrentStepIndex++;
                UpdateCurrentStep();
                IsBusy = true;
                try
                {
                    var deletionOptions = DeletionSettingsStep.ToDeletionOptions();
                    await ExecutionStep.ExecuteCommand.ExecuteAsync(
                        (ConnectionStep.ConnectionString, SummaryStep.Plan!, deletionOptions)).ConfigureAwait(true);
                }
                finally
                {
                    IsBusy = false;
                }

                break;
        }
    }

    [RelayCommand]
    private void Reset()
    {
        CurrentStepIndex = 0;
        UpdateCurrentStep();
    }

    private void UpdateCurrentStep()
    {
        CurrentStep = CurrentStepIndex switch
        {
            0 => ConnectionStep,
            1 => ConditionsStep,
            2 => AnalysisStep,
            3 => SummaryStep,
            4 => DeletionSettingsStep,
            5 => ExecutionStep,
            _ => ConnectionStep
        };
    }

    public DeletionProfile ExportProfile()
    {
        var conditions = ConditionsStep.Conditions
            .Where(c => c.SelectedColumn is not null)
            .Select(c => new WhereConditionProfile
            {
                Column = c.SelectedColumn!.Name,
                Operator = c.SelectedOperator,
                Value = c.Value,
                LogicalOperator = c.LogicalOperator
            })
            .ToList();

        var scope = new ScopeProfile
        {
            RootTable = ConditionsStep.SelectedReferenceTable?.FullName ?? string.Empty,
            ScopeMode = ConditionsStep.ScopeMode.ToString(),
            WhereConditions = conditions,
            CustomSql = ConditionsStep.ScopeMode == DeletionScopeMode.CustomSql
                ? ConditionsStep.CustomSqlQuery
                : null
        };

        var excludedTables = ConnectionStep.GetExcludedTables()
            .Select(t => t.FullName)
            .ToList();

        return new DeletionProfile
        {
            ConnectionString = ConnectionStep.ConnectionString,
            ExcludedTables = excludedTables,
            DeletionSettings = new DeletionSettingsProfile
            {
                Mode = DeletionSettingsStep.SelectedMode.ToString(),
                BatchSize = DeletionSettingsStep.BatchSize,
                UseTransaction = DeletionSettingsStep.UseTransaction
            },
            Scope = scope
        };
    }

    public void ImportProfile(DeletionProfile profile)
    {
        ArgumentNullException.ThrowIfNull(profile);

        ConnectionStep.SetConnectionString(profile.ConnectionString);

        if (Enum.TryParse<DeletionMode>(profile.DeletionSettings.Mode, true, out var mode))
        {
            DeletionSettingsStep.ImportSettings(profile.DeletionSettings);
        }

        if (profile.Scope is not null)
        {
            ConditionsStep.ImportConditions(profile.Scope);
        }

        CurrentStepIndex = 0;
        UpdateCurrentStep();
    }
}
