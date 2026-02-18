using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Interfaces;
using Microsoft.Extensions.Logging;

namespace DatabaseDeletor.Application.Commands;

public sealed partial class ExecuteDeletionHandler : IRequestHandler<ExecuteDeletionCommand, DeletionReport>
{
    private readonly IDeletionExecutor _executor;
    private readonly ILogger<ExecuteDeletionHandler> _logger;

    public ExecuteDeletionHandler(IDeletionExecutor executor, ILogger<ExecuteDeletionHandler> logger)
    {
        _executor = executor;
        _logger = logger;
    }

    public async Task<DeletionReport> HandleAsync(ExecuteDeletionCommand request, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        LogExecuting(request.Plan.Id, request.Plan.Steps.Count);

        var report = await _executor.ExecuteAsync(
            request.ConnectionString,
            request.Plan,
            request.Progress,
            ct).ConfigureAwait(false);

        if (report.HasErrors)
        {
            LogCompletedWithErrors(report.TotalDeletedRows, report.Results.Count);
        }
        else
        {
            LogCompleted(report.TotalDeletedRows, report.Results.Count, report.TotalDuration);
        }

        return report;
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Executing deletion plan {PlanId} with {StepCount} steps")]
    private partial void LogExecuting(Guid planId, int stepCount);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Deletion completed with errors. {Deleted} rows deleted across {Tables} tables")]
    private partial void LogCompletedWithErrors(long deleted, int tables);

    [LoggerMessage(Level = LogLevel.Information, Message = "Deletion completed successfully. {Deleted} rows deleted across {Tables} tables in {Duration}")]
    private partial void LogCompleted(long deleted, int tables, TimeSpan duration);
}
