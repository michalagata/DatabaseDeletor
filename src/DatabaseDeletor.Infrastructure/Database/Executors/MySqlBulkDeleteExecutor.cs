using Dapper;
using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Enums;
using DatabaseDeletor.Domain.Interfaces;
using MySqlConnector;

namespace DatabaseDeletor.Infrastructure.Database.Executors;

public sealed class MySqlBulkDeleteExecutor : IBulkDeleteExecutor
{
    private const int BatchSize = 10000;

    public DatabaseProvider Provider => DatabaseProvider.MySql;

    public async Task<long> ExecuteDeleteAsync(
        string connectionString,
        DeletionStep deletionStep,
        IProgress<long>? progress = null,
        CancellationToken ct = default)
    {
        await using var connection = new MySqlConnection(connectionString);
        await connection.OpenAsync(ct).ConfigureAwait(false);

        long totalDeleted = 0;

        if (step.EstimatedRowCount > BatchSize)
        {
            int batchDeleted;
            do
            {
                ct.ThrowIfCancellationRequested();

                var limitSql = AddLimitClause(step.DeleteSql, BatchSize);
                batchDeleted = await connection.ExecuteAsync(limitSql).ConfigureAwait(false);
                totalDeleted += batchDeleted;
                progress?.Report(totalDeleted);
            }
            while (batchDeleted >= BatchSize);
        }
        else
        {
            totalDeleted = await connection.ExecuteAsync(step.DeleteSql).ConfigureAwait(false);
            progress?.Report(totalDeleted);
        }

        return totalDeleted;
    }

    private static string AddLimitClause(string deleteSql, int batchSize)
    {
        return $"{deleteSql} LIMIT {batchSize}";
    }
}
