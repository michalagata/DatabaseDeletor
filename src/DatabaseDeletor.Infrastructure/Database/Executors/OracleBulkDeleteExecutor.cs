using System.Data.Common;
using Dapper;
using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Enums;
using DatabaseDeletor.Domain.Interfaces;
using Oracle.ManagedDataAccess.Client;

namespace DatabaseDeletor.Infrastructure.Database.Executors;

public sealed class OracleBulkDeleteExecutor : IBulkDeleteExecutor
{
    public DatabaseProvider Provider => DatabaseProvider.Oracle;

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

        using var connection = new OracleConnection(connectionString);
        await connection.OpenAsync(ct).ConfigureAwait(false);
        return await ExecuteOnConnectionAsync(connection, transaction, deletionStep, options, progress, ct).ConfigureAwait(false);
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

                var batchSql = AddRowNumLimit(step.DeleteSql, batchSize);
                var cmd = new CommandDefinition(batchSql, transaction: transaction, cancellationToken: ct);
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

    private static string AddRowNumLimit(string deleteSql, int batchSize)
    {
        if (deleteSql.Contains("WHERE", StringComparison.OrdinalIgnoreCase))
        {
            return $"{deleteSql} AND ROWNUM <= {batchSize}";
        }

        return $"{deleteSql} WHERE ROWNUM <= {batchSize}";
    }
}
