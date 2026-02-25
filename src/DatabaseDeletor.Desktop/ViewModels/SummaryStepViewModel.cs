using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using DatabaseDeletor.Application.Commands;
using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Interfaces;
using Serilog;

namespace DatabaseDeletor.Desktop.ViewModels;

public sealed partial class SummaryStepViewModel : ViewModelBase
{
    private readonly IMediator _mediator;

    [ObservableProperty]
    private bool _isGenerating;

    [ObservableProperty]
    private string? _errorMessage;

    [ObservableProperty]
    private long _totalEstimatedRows;

    [ObservableProperty]
    private bool _planReady;

    public DeletionPlan? Plan { get; private set; }
    public ObservableCollection<DeletionStep> Steps { get; } = [];

    public SummaryStepViewModel(IMediator mediator)
    {
        _mediator = mediator;
    }

    [RelayCommand]
    private async Task GeneratePlanAsync(
        (string ConnectionString, DependencyGraph Graph, TableInfo RootTable, string? WhereClause) args,
        CancellationToken ct)
    {
        IsGenerating = true;
        ErrorMessage = null;
        Steps.Clear();
        PlanReady = false;

        try
        {
            Plan = await _mediator.SendAsync(
                new GenerateDeletionPlanCommand(args.ConnectionString, args.Graph, args.RootTable, args.WhereClause), ct).ConfigureAwait(true);

            foreach (var step in Plan.Steps)
                Steps.Add(step);

            TotalEstimatedRows = Plan.TotalEstimatedRows;
            PlanReady = true;
        }
#pragma warning disable CA1031 // UI error handler: catch-all is intentional
        catch (Exception ex)
        {
            Log.Error(ex, "Deletion plan generation failed");
            ErrorMessage = $"Plan generation failed: {ex.Message}";
        }
#pragma warning restore CA1031
        finally
        {
            IsGenerating = false;
        }
    }
}
