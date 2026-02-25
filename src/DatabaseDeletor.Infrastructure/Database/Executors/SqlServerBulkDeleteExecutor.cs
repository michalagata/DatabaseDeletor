using System.Data.Common;
using Dapper;
using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Enums;
using DatabaseDeletor.Domain.Interfaces;
using Microsoft.Data.SqlClient;

namespace DatabaseDeletor.Infrastructure.Database.Executors;

public sealed class SqlServerBulkDeleteExecutor : IBulkDeleteExecutor
{
    public DatabaseProvider Provider => DatabaseProvider.SqlServer;

    public async Task<long> ExecuteDeleteAsync(
        string connectionString,
        DeletionStep deletionStep,
        DeletionOptions options,
        DbConnection? existingConnection = null,
        DbTransaction? transaction = null,
        IProgress<long>? progress = null,
        CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(deletionStep);
        ArgumentNullException.ThrowIfNull(options);

        if (existingConnection is not null)
        {
            return await ExecuteOnConnectionAsync(existingConnection, transaction, deletionStep, options, progress, ct).ConfigureAwait(false);
        }

        var connection = new SqlConnection(connectionString);
        await using (connection.ConfigureAwait(false))
        {
            await connection.OpenAsync(ct).ConfigureAwait(false);
            return await ExecuteOnConnectionAsync(connection, transaction, deletionStep, options, progress, ct).ConfigureAwait(false);
        }
    }

    private static async Task<long> ExecuteOnConnectionAsync(
        DbConnection connection, DbTransaction? transaction,
        DeletionStep step, DeletionOptions options, IProgress<long>? progress, CancellationToken ct)
    {
        if (connection.State != System.Data.ConnectionState.Open)
            await connection.OpenAsync(ct).ConfigureAwait(false);

        return options.Mode switch
        {
            DeletionMode.DirectDelete => await ExecuteDirectAsync(connection, transaction, step, progress, ct).ConfigureAwait(false),
            DeletionMode.SingleRowDelete => await ExecuteBatchAsync(connection, transaction, step, 1, progress, ct).ConfigureAwait(false),
            _ => await ExecuteBatchAsync(connection, transaction, step, options.EffectiveBatchSize, progress, ct).ConfigureAwait(false),
        };
    }

    private static async Task<long> ExecuteDirectAsync(
        DbConnection connection, DbTransaction? transaction,
        DeletionStep step, IProgress<long>? progress, CancellationToken ct)
    {
        var cmd = new CommandDefinition(step.DeleteSql, transaction: transaction, cancellationToken: ct);
        var deleted = await connection.ExecuteAsync(cmd).ConfigureAwait(false);
        progress?.Report(deleted);
        return deleted;
    }

    private static async Task<long> ExecuteBatchAsync(
        DbConnection connection, DbTransaction? transaction,
        DeletionStep step, int batchSize, IProgress<long>? progress, CancellationToken ct)
    {
        long totalDeleted = 0;

        if (step.EstimatedRowCount > batchSize)
        {
            int batchDeleted;
            do
            {
                ct.ThrowIfCancellationRequested();

                var topSql = AddTopClause(step.DeleteSql, batchSize);
                var cmd = new CommandDefinition(topSql, transaction: transaction, cancellationToken: ct);
                batchDeleted = await connection.ExecuteAsync(cmd).ConfigureAwait(false);
                totalDeleted += batchDeleted;
                progress?.Report(totalDeleted);
            }
            while (batchDeleted >= batchSize);
        }
        else
        {
            var cmd = new CommandDefinition(step.DeleteSql, transaction: transaction, cancellationToken: ct);
            totalDeleted = await connection.ExecuteAsync(cmd).ConfigureAwait(false);
            progress?.Report(totalDeleted);
        }

        return totalDeleted;
    }

    private static string AddTopClause(string deleteSql, int batchSize)
    {
        return deleteSql.Replace("DELETE FROM", $"DELETE TOP ({batchSize}) FROM", StringComparison.OrdinalIgnoreCase);
    }
}
