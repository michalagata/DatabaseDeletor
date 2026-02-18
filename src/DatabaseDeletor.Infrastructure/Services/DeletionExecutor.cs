using System.Diagnostics;
using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Enums;
using DatabaseDeletor.Domain.Interfaces;
using Microsoft.Extensions.Logging;

namespace DatabaseDeletor.Infrastructure.Services;

public sealed class DeletionExecutor : IDeletionExecutor
{
    private readonly IDatabaseProviderResolver _providerResolver;
    private readonly IEnumerable<IBulkDeleteExecutor> _executors;
    private readonly ILogger<DeletionExecutor> _logger;

    public DeletionExecutor(
        IDatabaseProviderResolver providerResolver,
        IEnumerable<IBulkDeleteExecutor> executors,
        ILogger<DeletionExecutor> logger)
    {
        _providerResolver = providerResolver;
        _executors = executors;
        _logger = logger;
    }

    public async Task<DeletionReport> ExecuteAsync(
        string connectionString,
        DeletionPlan plan,
        IProgress<DeletionProgress>? progress = null,
        CancellationToken ct = default)
    {
        var provider = _providerResolver.Resolve(connectionString);
        var executor = GetExecutor(provider);

        plan.Status = DeletionStatus.Executing;
        var startedAt = DateTime.UtcNow;
        var results = new List<DeletionStepResult>();
        long totalDeleted = 0;

        for (var i = 0; i < plan.Steps.Count; i++)
        {
            ct.ThrowIfCancellationRequested();

            var step = plan.Steps[i];
            var stepWatch = Stopwatch.StartNew();

            _logger.LogInformation(
                "Step {Step}/{Total}: Deleting from {Table}...",
                i + 1, plan.Steps.Count, step.Table.FullName);

            try
            {
                var stepProgress = new Progress<long>(deletedInStep =>
                {
                    progress?.Report(new DeletionProgress
                    {
                        CurrentStep = i + 1,
                        TotalSteps = plan.Steps.Count,
                        CurrentTable = step.Table,
                        DeletedRowsInStep = deletedInStep,
                        EstimatedRowsInStep = step.EstimatedRowCount,
                        TotalDeletedRows = totalDeleted + deletedInStep,
                        TotalEstimatedRows = plan.TotalEstimatedRows
                    });
                });

                var deletedCount = await executor.ExecuteDeleteAsync(
                    connectionString, step, stepProgress, ct).ConfigureAwait(false);

                stepWatch.Stop();
                step.ActualDeletedCount = deletedCount;
                step.IsCompleted = true;
                step.Duration = stepWatch.Elapsed;
                totalDeleted += deletedCount;

                results.Add(new DeletionStepResult
                {
                    Table = step.Table,
                    DeletedCount = deletedCount,
                    Duration = stepWatch.Elapsed
                });

                _logger.LogInformation(
                    "Step {Step}/{Total}: Deleted {Count} rows from {Table} in {Duration}",
                    i + 1, plan.Steps.Count, deletedCount, step.Table.FullName, stepWatch.Elapsed);
            }
            catch (Exception ex)
            {
                stepWatch.Stop();
                step.ErrorMessage = ex.Message;
                step.Duration = stepWatch.Elapsed;

                results.Add(new DeletionStepResult
                {
                    Table = step.Table,
                    DeletedCount = 0,
                    Duration = stepWatch.Elapsed,
                    ErrorMessage = ex.Message
                });

                _logger.LogError(ex, "Step {Step}/{Total}: Failed to delete from {Table}", i + 1, plan.Steps.Count, step.Table.FullName);
            }
        }

        var completedAt = DateTime.UtcNow;
        plan.Status = results.Any(r => r.ErrorMessage is not null)
            ? DeletionStatus.Failed
            : DeletionStatus.Completed;

        return new DeletionReport
        {
            PlanId = plan.Id,
            RootTable = plan.RootTable,
            Results = results,
            StartedAt = startedAt,
            CompletedAt = completedAt
        };
    }

    private IBulkDeleteExecutor GetExecutor(DatabaseProvider provider) =>
        _executors.FirstOrDefault(e => e.Provider == provider)
        ?? throw new InvalidOperationException($"No bulk delete executor registered for provider {provider}");
}
