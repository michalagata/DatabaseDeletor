using Dapper;
using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Enums;
using DatabaseDeletor.Domain.Interfaces;
using Oracle.ManagedDataAccess.Client;

namespace DatabaseDeletor.Infrastructure.Database.Executors;

public sealed class OracleBulkDeleteExecutor : IBulkDeleteExecutor
{
    private const int BatchSize = 10000;

    public DatabaseProvider Provider => DatabaseProvider.Oracle;

    public async Task<long> ExecuteDeleteAsync(
        string connectionString,
        DeletionStep deletionStep,
        IProgress<long>? progress = null,
        CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(deletionStep);

        using var connection = new OracleConnection(connectionString);
        await connection.OpenAsync(ct).ConfigureAwait(false);

        long totalDeleted = 0;

        if (deletionStep.EstimatedRowCount > BatchSize)
        {
            int batchDeleted;
            do
            {
                ct.ThrowIfCancellationRequested();

                var batchSql = AddRowNumLimit(deletionStep.DeleteSql, BatchSize);
                batchDeleted = await connection.ExecuteAsync(batchSql).ConfigureAwait(false);
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

    private static string AddRowNumLimit(string deleteSql, int batchSize)
    {
        if (deleteSql.Contains("WHERE", StringComparison.OrdinalIgnoreCase))
        {
            return $"{deleteSql} AND ROWNUM <= {batchSize}";
        }

        return $"{deleteSql} WHERE ROWNUM <= {batchSize}";
    }
}
