using Dapper;
using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Enums;
using DatabaseDeletor.Domain.Interfaces;
using Npgsql;

namespace DatabaseDeletor.Infrastructure.Database.Executors;

public sealed class PostgreSqlBulkDeleteExecutor : IBulkDeleteExecutor
{
    private const int BatchSize = 10000;

    public DatabaseProvider Provider => DatabaseProvider.PostgreSql;

    public async Task<long> ExecuteDeleteAsync(
        string connectionString,
        DeletionStep deletionStep,
        IProgress<long>? progress = null,
        CancellationToken ct = default)
    {
        await using var connection = new NpgsqlConnection(connectionString);
        await connection.OpenAsync(ct).ConfigureAwait(false);

        long totalDeleted = 0;

        if (step.EstimatedRowCount > BatchSize)
        {
            int batchDeleted;
            do
            {
                ct.ThrowIfCancellationRequested();

                var batchSql = BuildBatchDeleteSql(step.DeleteSql, BatchSize);
                batchDeleted = await connection.ExecuteAsync(batchSql).ConfigureAwait(false);
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

    private static string BuildBatchDeleteSql(string deleteSql, int batchSize)
    {
        var tableName = ExtractTableName(deleteSql);
        var whereClause = ExtractWhereClause(deleteSql);

        var ctidWhere = string.IsNullOrEmpty(whereClause)
            ? $"ctid IN (SELECT ctid FROM {tableName} LIMIT {batchSize})"
            : $"ctid IN (SELECT ctid FROM {tableName} WHERE {whereClause} LIMIT {batchSize})";

        return $"DELETE FROM {tableName} WHERE {ctidWhere}";
    }

    private static string ExtractTableName(string deleteSql)
    {
        var fromIndex = deleteSql.IndexOf("FROM", StringComparison.OrdinalIgnoreCase) + 4;
        var rest = deleteSql[fromIndex..].Trim();
        var spaceIndex = rest.IndexOf(' ');
        return spaceIndex > 0 ? rest[..spaceIndex] : rest;
    }

    private static string? ExtractWhereClause(string deleteSql)
    {
        var whereIndex = deleteSql.IndexOf("WHERE", StringComparison.OrdinalIgnoreCase);
        return whereIndex > 0 ? deleteSql[(whereIndex + 5)..].Trim() : null;
    }
}
