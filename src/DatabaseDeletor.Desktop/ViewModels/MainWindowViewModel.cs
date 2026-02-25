using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;

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
    private ViewModelBase _currentStep;

    public ConnectionStepViewModel ConnectionStep { get; }
    public ConditionsStepViewModel ConditionsStep { get; }
    public AnalysisStepViewModel AnalysisStep { get; }
    public SummaryStepViewModel SummaryStep { get; }
    public ExecutionStepViewModel ExecutionStep { get; }

    public bool CanGoBack => CurrentStepIndex > 0 && !ExecutionStep.IsExecuting;
    public bool CanGoNext => CurrentStepIndex < 4 && !ExecutionStep.IsExecuting;
    public bool IsLastStep => CurrentStepIndex == 4;

    public IReadOnlyList<string> StepTitles { get; } =
    [
        "1. Connection & Tables",
        "2. Root Table & Conditions",
        "3. Dependency Analysis",
        "4. Summary",
        "5. Execution"
    ];

    public MainWindowViewModel(
        ConnectionStepViewModel connectionStep,
        AnalysisStepViewModel analysisStep,
        ConditionsStepViewModel conditionsStep,
        SummaryStepViewModel summaryStep,
        ExecutionStepViewModel executionStep)
    {
        ConnectionStep = connectionStep;
        AnalysisStep = analysisStep;
        ConditionsStep = conditionsStep;
        SummaryStep = summaryStep;
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
                await AnalysisStep.AnalyzeCommand.ExecuteAsync(
                    (ConnectionStep.ConnectionString,
                     ConditionsStep.EffectiveRootTable,
                     ConnectionStep.GetSelectedTables(),
                     ConnectionStep.GetExcludedTables())).ConfigureAwait(true);
                break;

            case 2: // Analysis → Summary
                if (!AnalysisStep.IsValid || AnalysisStep.Graph is null) return;
                CurrentStepIndex++;
                UpdateCurrentStep();
                await SummaryStep.GeneratePlanCommand.ExecuteAsync(
                    (ConnectionStep.ConnectionString,
                     AnalysisStep.Graph,
                     ConditionsStep.EffectiveRootTable!,
                     ConditionsStep.WhereClause)).ConfigureAwait(true);
                break;

            case 3: // Summary → Execution
                if (SummaryStep.Plan is null) return;
                CurrentStepIndex++;
                UpdateCurrentStep();
                await ExecutionStep.ExecuteCommand.ExecuteAsync(
                    (ConnectionStep.ConnectionString, SummaryStep.Plan)).ConfigureAwait(true);
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
            4 => ExecutionStep,
            _ => ConnectionStep
        };
    }
}
