using System.Data.Common;
using System.Diagnostics;
using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Enums;
using DatabaseDeletor.Domain.Interfaces;
using Microsoft.Extensions.Logging;

namespace DatabaseDeletor.Infrastructure.Services;

public sealed partial class DeletionExecutor : IDeletionExecutor
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
        ArgumentNullException.ThrowIfNull(plan);

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

            LogStepStarting(i + 1, plan.Steps.Count, step.Table.FullName);

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

                LogStepCompleted(i + 1, plan.Steps.Count, deletedCount, step.Table.FullName, stepWatch.Elapsed);
            }
            catch (DbException ex)
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

                LogStepFailed(ex, i + 1, plan.Steps.Count, step.Table.FullName);
            }
        }

        var completedAt = DateTime.UtcNow;
        plan.Status = results.Exists(r => r.ErrorMessage is not null)
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

    [LoggerMessage(Level = LogLevel.Information, Message = "Step {Step}/{Total}: Deleting from {Table}...")]
    private partial void LogStepStarting(int step, int total, string table);

    [LoggerMessage(Level = LogLevel.Information, Message = "Step {Step}/{Total}: Deleted {Count} rows from {Table} in {Duration}")]
    private partial void LogStepCompleted(int step, int total, long count, string table, TimeSpan duration);

    [LoggerMessage(Level = LogLevel.Error, Message = "Step {Step}/{Total}: Failed to delete from {Table}")]
    private partial void LogStepFailed(Exception ex, int step, int total, string table);
}
