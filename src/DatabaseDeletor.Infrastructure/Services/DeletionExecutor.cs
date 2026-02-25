using System.Data;
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
    private readonly IEnumerable<IDbConnectionFactory> _connectionFactories;
    private readonly ILogger<DeletionExecutor> _logger;

    public DeletionExecutor(
        IDatabaseProviderResolver providerResolver,
        IEnumerable<IBulkDeleteExecutor> executors,
        IEnumerable<IDbConnectionFactory> connectionFactories,
        ILogger<DeletionExecutor> logger)
    {
        _providerResolver = providerResolver;
        _executors = executors;
        _connectionFactories = connectionFactories;
        _logger = logger;
    }

    public async Task<DeletionReport> ExecuteAsync(
        string connectionString,
        DeletionPlan plan,
        DeletionOptions options,
        IProgress<DeletionProgress>? progress = null,
        CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(plan);
        ArgumentNullException.ThrowIfNull(options);

        var provider = _providerResolver.Resolve(connectionString);
        var executor = GetExecutor(provider);

        if (options.UseTransaction)
        {
            return await ExecuteWithTransactionAsync(connectionString, plan, options, provider, executor, progress, ct).ConfigureAwait(false);
        }

        return await ExecuteWithoutTransactionAsync(connectionString, plan, options, executor, progress, ct).ConfigureAwait(false);
    }

    private async Task<DeletionReport> ExecuteWithTransactionAsync(
        string connectionString,
        DeletionPlan plan,
        DeletionOptions options,
        DatabaseProvider provider,
        IBulkDeleteExecutor executor,
        IProgress<DeletionProgress>? progress,
        CancellationToken ct)
    {
        var factory = _connectionFactories.FirstOrDefault(f => f.Provider == provider)
            ?? throw new InvalidOperationException($"No connection factory registered for provider {provider}");

        var dbConnection = factory.CreateConnection(connectionString);
        if (dbConnection is not DbConnection connection)
            throw new InvalidOperationException($"Connection factory for {provider} did not return a DbConnection");

        await using (connection.ConfigureAwait(false))
        {
            await connection.OpenAsync(ct).ConfigureAwait(false);
            var transaction = await connection.BeginTransactionAsync(ct).ConfigureAwait(false);

            try
            {
                LogTransactionStarted();

                var report = await ExecuteStepsAsync(
                    connectionString, plan, options, executor, progress, connection, transaction, ct).ConfigureAwait(false);

                if (report.HasErrors)
                {
                    LogTransactionRollingBack();
                    await transaction.RollbackAsync(ct).ConfigureAwait(false);
                }
                else
                {
                    LogTransactionCommitting();
                    await transaction.CommitAsync(ct).ConfigureAwait(false);
                }

                return report;
            }
            catch
            {
                LogTransactionRollingBack();
                await transaction.RollbackAsync(ct).ConfigureAwait(false);
                throw;
            }
            finally
            {
                await transaction.DisposeAsync().ConfigureAwait(false);
            }
        }
    }

    private async Task<DeletionReport> ExecuteWithoutTransactionAsync(
        string connectionString,
        DeletionPlan plan,
        DeletionOptions options,
        IBulkDeleteExecutor executor,
        IProgress<DeletionProgress>? progress,
        CancellationToken ct)
    {
        return await ExecuteStepsAsync(
            connectionString, plan, options, executor, progress, null, null, ct).ConfigureAwait(false);
    }

    private async Task<DeletionReport> ExecuteStepsAsync(
        string connectionString,
        DeletionPlan plan,
        DeletionOptions options,
        IBulkDeleteExecutor executor,
        IProgress<DeletionProgress>? progress,
        DbConnection? connection,
        DbTransaction? transaction,
        CancellationToken ct)
    {
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
                    connectionString, step, options, connection, transaction, stepProgress, ct).ConfigureAwait(false);

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

                if (options.UseTransaction)
                    throw;
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

    [LoggerMessage(Level = LogLevel.Information, Message = "Transaction started for deletion batch")]
    private partial void LogTransactionStarted();

    [LoggerMessage(Level = LogLevel.Information, Message = "Committing transaction...")]
    private partial void LogTransactionCommitting();

    [LoggerMessage(Level = LogLevel.Warning, Message = "Rolling back transaction...")]
    private partial void LogTransactionRollingBack();
}
