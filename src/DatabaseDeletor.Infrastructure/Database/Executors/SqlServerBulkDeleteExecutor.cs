using Dapper;
using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Enums;
using DatabaseDeletor.Domain.Interfaces;
using Microsoft.Data.SqlClient;

namespace DatabaseDeletor.Infrastructure.Database.Executors;

public sealed class SqlServerBulkDeleteExecutor : IBulkDeleteExecutor
{
    private const int BatchSize = 10000;

    public DatabaseProvider Provider => DatabaseProvider.SqlServer;

    public async Task<long> ExecuteDeleteAsync(
        string connectionString,
        DeletionStep deletionStep,
        IProgress<long>? progress = null,
        CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(deletionStep);

        var connection = new SqlConnection(connectionString);
        await using (connection.ConfigureAwait(false))
        {
            await connection.OpenAsync(ct).ConfigureAwait(false);

            long totalDeleted = 0;

            if (deletionStep.EstimatedRowCount > BatchSize)
            {
                int batchDeleted;
                do
                {
                    ct.ThrowIfCancellationRequested();

                    var topSql = AddTopClause(deletionStep.DeleteSql, BatchSize);
                    batchDeleted = await connection.ExecuteAsync(topSql).ConfigureAwait(false);
                    totalDeleted += batchDeleted;
                    progress?.Report(totalDeleted);
                }
                while (batchDeleted >= BatchSize);
            }
            else
            {
                totalDeleted = await connection.ExecuteAsync(deletionStep.DeleteSql).ConfigureAwait(false);
                progress?.Report(totalDeleted);
            }

            return totalDeleted;
        }
    }

    private static string AddTopClause(string deleteSql, int batchSize)
    {
        return deleteSql.Replace("DELETE FROM", $"DELETE TOP ({batchSize}) FROM", StringComparison.OrdinalIgnoreCase);
    }
}
