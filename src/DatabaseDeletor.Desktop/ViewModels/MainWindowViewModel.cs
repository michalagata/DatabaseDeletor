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
    public AnalysisStepViewModel AnalysisStep { get; }
    public ConditionsStepViewModel ConditionsStep { get; }
    public SummaryStepViewModel SummaryStep { get; }
    public ExecutionStepViewModel ExecutionStep { get; }

    public bool CanGoBack => CurrentStepIndex > 0 && !ExecutionStep.IsExecuting;
    public bool CanGoNext => CurrentStepIndex < 4 && !ExecutionStep.IsExecuting;
    public bool IsLastStep => CurrentStepIndex == 4;

    public IReadOnlyList<string> StepTitles { get; } =
    [
        "1. Connection & Tables",
        "2. Dependency Analysis",
        "3. Conditions",
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
            case 0:
                if (!ConnectionStep.IsConnected) return;
                CurrentStepIndex++;
                UpdateCurrentStep();
                await AnalysisStep.AnalyzeCommand.ExecuteAsync(
                    (ConnectionStep.ConnectionString,
                     ConnectionStep.GetSelectedTables(),
                     ConnectionStep.GetExcludedTables())).ConfigureAwait(true);
                break;

            case 1:
                if (!AnalysisStep.IsValid || AnalysisStep.Graph is null) return;
                ConditionsStep.LoadTables(AnalysisStep.Graph);
                CurrentStepIndex++;
                UpdateCurrentStep();
                break;

            case 2:
                if (ConditionsStep.SelectedReferenceTable is null || AnalysisStep.Graph is null) return;
                CurrentStepIndex++;
                UpdateCurrentStep();
                var whereClause = ConditionsStep.DeleteAll ? null : ConditionsStep.WhereClause;
                await SummaryStep.GeneratePlanCommand.ExecuteAsync(
                    (ConnectionStep.ConnectionString,
                     AnalysisStep.Graph,
                     ConditionsStep.SelectedReferenceTable,
                     string.IsNullOrWhiteSpace(whereClause) ? null : whereClause)).ConfigureAwait(true);
                break;

            case 3:
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
            1 => AnalysisStep,
            2 => ConditionsStep,
            3 => SummaryStep,
            4 => ExecutionStep,
            _ => ConnectionStep
        };
    }
}
