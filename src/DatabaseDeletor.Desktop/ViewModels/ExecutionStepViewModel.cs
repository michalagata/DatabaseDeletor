using System.Collections.ObjectModel;
using System.Globalization;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using DatabaseDeletor.Application.Commands;
using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Interfaces;
using Serilog;

namespace DatabaseDeletor.Desktop.ViewModels;

public sealed partial class ExecutionStepViewModel : ViewModelBase
{
    private readonly IMediator _mediator;

    [ObservableProperty]
    private bool _isExecuting;

    [ObservableProperty]
    private bool _isCompleted;

    [ObservableProperty]
    private double _overallPercentage;

    [ObservableProperty]
    private string _currentStepDescription = string.Empty;

    [ObservableProperty]
    private long _totalDeletedRows;

    [ObservableProperty]
    private bool _hasErrors;

    [ObservableProperty]
    private string? _errorMessage;

    public ObservableCollection<string> LogEntries { get; } = [];

    public DeletionReport? Report { get; private set; }

    public ExecutionStepViewModel(IMediator mediator)
    {
        _mediator = mediator;
    }

    [RelayCommand]
    private async Task ExecuteAsync(
        (string ConnectionString, DeletionPlan Plan) args,
        CancellationToken ct)
    {
        IsExecuting = true;
        IsCompleted = false;
        HasErrors = false;
        ErrorMessage = null;
        OverallPercentage = 0;
        TotalDeletedRows = 0;
        LogEntries.Clear();

        try
        {
            var progress = new Progress<DeletionProgress>(p =>
            {
                OverallPercentage = p.OverallPercentage;
                TotalDeletedRows = p.TotalDeletedRows;
                CurrentStepDescription = $"Step {p.CurrentStep}/{p.TotalSteps}: {p.CurrentTable.FullName}";

                LogEntries.Insert(0, string.Format(CultureInfo.InvariantCulture,
                    "[{0:HH:mm:ss}] {1} — {2:N0}/{3:N0} rows",
                    DateTime.Now, p.CurrentTable.FullName, p.DeletedRowsInStep, p.EstimatedRowsInStep));
            });

            Report = await _mediator.SendAsync(
                new ExecuteDeletionCommand(args.ConnectionString, args.Plan, progress), ct).ConfigureAwait(true);

            TotalDeletedRows = Report.TotalDeletedRows;
            HasErrors = Report.HasErrors;

            if (HasErrors)
            {
                foreach (var result in Report.Results.Where(r => !r.Success))
                {
                    LogEntries.Insert(0, $"ERROR: {result.Table.FullName} — {result.ErrorMessage}");
                }
            }

            LogEntries.Insert(0, string.Format(CultureInfo.InvariantCulture,
                "Completed: {0:N0} rows deleted in {1:hh\\:mm\\:ss\\.fff}",
                Report.TotalDeletedRows, Report.TotalDuration));

            OverallPercentage = 100;
            IsCompleted = true;
        }
        catch (OperationCanceledException)
        {
            LogEntries.Insert(0, "Operation cancelled by user.");
        }
#pragma warning disable CA1031 // UI error handler: catch-all is intentional
        catch (Exception ex)
        {
            Log.Fatal(ex, "Deletion execution failed");
            ErrorMessage = ex.Message;
            LogEntries.Insert(0, $"FATAL: {ex.Message}");
        }
#pragma warning restore CA1031
        finally
        {
            IsExecuting = false;
        }
    }
}
