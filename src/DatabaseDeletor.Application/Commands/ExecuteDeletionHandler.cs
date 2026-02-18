using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Interfaces;
using Microsoft.Extensions.Logging;

namespace DatabaseDeletor.Application.Commands;

public sealed class ExecuteDeletionHandler : IRequestHandler<ExecuteDeletionCommand, DeletionReport>
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
        _logger.LogInformation(
            "Executing deletion plan {PlanId} with {StepCount} steps",
            request.Plan.Id, request.Plan.Steps.Count);

        var report = await _executor.ExecuteAsync(
            request.ConnectionString,
            request.Plan,
            request.Progress,
            ct).ConfigureAwait(false);

        if (report.HasErrors)
        {
            _logger.LogWarning(
                "Deletion completed with errors. {Deleted} rows deleted across {Tables} tables",
                report.TotalDeletedRows, report.Results.Count);
        }
        else
        {
            _logger.LogInformation(
                "Deletion completed successfully. {Deleted} rows deleted across {Tables} tables in {Duration}",
                report.TotalDeletedRows, report.Results.Count, report.TotalDuration);
        }

        return report;
    }
}
