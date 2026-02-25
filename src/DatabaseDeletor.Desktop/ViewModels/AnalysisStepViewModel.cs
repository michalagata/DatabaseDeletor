using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using DatabaseDeletor.Application.Commands;
using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Interfaces;

namespace DatabaseDeletor.Desktop.ViewModels;

public sealed partial class AnalysisStepViewModel : ViewModelBase
{
    private readonly IMediator _mediator;

    [ObservableProperty]
    private bool _isAnalyzing;

    [ObservableProperty]
    private bool _isValid;

    [ObservableProperty]
    private bool _analysisComplete;

    [ObservableProperty]
    private string? _errorMessage;

    [ObservableProperty]
    private int _tableCount;

    public ObservableCollection<ExclusionConflict> Conflicts { get; } = [];
    public ObservableCollection<string> Recommendations { get; } = [];

    public DependencyGraph? Graph { get; private set; }

    public AnalysisStepViewModel(IMediator mediator)
    {
        _mediator = mediator;
    }

    [RelayCommand]
    private async Task AnalyzeAsync(
        (string ConnectionString, TableInfo RootTable, IReadOnlyList<TableInfo> SelectedTables, IReadOnlyList<TableInfo> ExcludedTables) args,
        CancellationToken ct)
    {
        IsAnalyzing = true;
        AnalysisComplete = false;
        ErrorMessage = null;
        Conflicts.Clear();
        Recommendations.Clear();
        Graph = null;

        try
        {
            if (args.SelectedTables.Count == 0)
            {
                ErrorMessage = "No tables selected for deletion.";
                return;
            }

            Graph = await _mediator.SendAsync(
                new AnalyzeDependenciesCommand(args.ConnectionString, args.RootTable.Schema, args.RootTable.Name), ct).ConfigureAwait(true);

            TableCount = Graph.Tables.Count;

            if (args.ExcludedTables.Count > 0)
            {
                var exclusionResult = await _mediator.SendAsync(
                    new ValidateExclusionsCommand(args.ConnectionString, args.SelectedTables, args.ExcludedTables), ct).ConfigureAwait(true);

                IsValid = exclusionResult.IsValid;

                foreach (var conflict in exclusionResult.Conflicts)
                    Conflicts.Add(conflict);

                foreach (var rec in exclusionResult.Recommendations)
                    Recommendations.Add(rec);

                if (IsValid)
                    Graph = Graph.FilterExcludedTables(args.ExcludedTables);
            }
            else
            {
                IsValid = true;
            }

            AnalysisComplete = true;
        }
#pragma warning disable CA1031 // UI error handler: catch-all is intentional
        catch (Exception ex)
        {
            ErrorMessage = $"Analysis failed: {ex.Message}";
        }
#pragma warning restore CA1031
        finally
        {
            IsAnalyzing = false;
        }
    }
}
