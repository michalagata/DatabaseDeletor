using Dapper;
using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Enums;
using DatabaseDeletor.Domain.Exceptions;
using DatabaseDeletor.Domain.Interfaces;
using Microsoft.Data.SqlClient;

namespace DatabaseDeletor.Infrastructure.Database.Introspectors;

public sealed class SqlServerSchemaIntrospector : ISchemaIntrospector
{
    public DatabaseProvider Provider => DatabaseProvider.SqlServer;

    public async Task<TableInfo> GetTableInfoAsync(string connectionString, string schema, string tableName, CancellationToken ct = default)
    {
        var connection = new SqlConnection(connectionString);
        await using (connection.ConfigureAwait(false))
        {
            await connection.OpenAsync(ct).ConfigureAwait(false);

            var exists = await connection.ExecuteScalarAsync<int>(
                "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = @Schema AND TABLE_NAME = @Table",
                new { Schema = schema, Table = tableName }).ConfigureAwait(false);

            if (exists == 0)
                throw new SchemaIntrospectionException($"Table {schema}.{tableName} does not exist.");

            var rowCount = await GetRowCountAsync(connectionString, schema, tableName, null, ct).ConfigureAwait(false);

            return new TableInfo { Schema = schema, Name = tableName, RowCount = rowCount };
        }
    }

    public async Task<IReadOnlyList<ForeignKeyInfo>> GetForeignKeysAsync(string connectionString, string schema, string tableName, CancellationToken ct = default)
    {
        var connection = new SqlConnection(connectionString);
        await using (connection.ConfigureAwait(false))
        {
            await connection.OpenAsync(ct).ConfigureAwait(false);

            const string sql = """
                SELECT
                    fk.name AS ConstraintName,
                    sch1.name AS ReferencingSchema,
                    t1.name AS ReferencingTable,
                    c1.name AS ReferencingColumn,
                    sch2.name AS ReferencedSchema,
                    t2.name AS ReferencedTable,
                    c2.name AS ReferencedColumn,
                    fk.delete_referential_action_desc AS DeleteRule
                FROM sys.foreign_keys fk
                INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
                INNER JOIN sys.tables t1 ON fkc.parent_object_id = t1.object_id
                INNER JOIN sys.schemas sch1 ON t1.schema_id = sch1.schema_id
                INNER JOIN sys.columns c1 ON fkc.parent_object_id = c1.object_id AND fkc.parent_column_id = c1.column_id
                INNER JOIN sys.tables t2 ON fkc.referenced_object_id = t2.object_id
                INNER JOIN sys.schemas sch2 ON t2.schema_id = sch2.schema_id
                INNER JOIN sys.columns c2 ON fkc.referenced_object_id = c2.object_id AND fkc.referenced_column_id = c2.column_id
                WHERE sch1.name = @Schema AND t1.name = @Table
                """;

            var results = await connection.QueryAsync<dynamic>(sql, new { Schema = schema, Table = tableName }).ConfigureAwait(false);

            return results.Select(r => new ForeignKeyInfo
            {
                ConstraintName = r.ConstraintName,
                ReferencingTable = new TableInfo { Schema = r.ReferencingSchema, Name = r.ReferencingTable },
                ReferencingColumn = r.ReferencingColumn,
                ReferencedTable = new TableInfo { Schema = r.ReferencedSchema, Name = r.ReferencedTable },
                ReferencedColumn = r.ReferencedColumn,
                DeleteRule = r.DeleteRule
            }).ToList();
        }
    }

    public async Task<IReadOnlyList<ForeignKeyInfo>> GetReferencingForeignKeysAsync(string connectionString, string schema, string tableName, CancellationToken ct = default)
    {
        var connection = new SqlConnection(connectionString);
        await using (connection.ConfigureAwait(false))
        {
            await connection.OpenAsync(ct).ConfigureAwait(false);

            const string sql = """
                SELECT
                    fk.name AS ConstraintName,
                    sch1.name AS ReferencingSchema,
                    t1.name AS ReferencingTable,
                    c1.name AS ReferencingColumn,
                    sch2.name AS ReferencedSchema,
                    t2.name AS ReferencedTable,
                    c2.name AS ReferencedColumn,
                    fk.delete_referential_action_desc AS DeleteRule
                FROM sys.foreign_keys fk
                INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
                INNER JOIN sys.tables t1 ON fkc.parent_object_id = t1.object_id
                INNER JOIN sys.schemas sch1 ON t1.schema_id = sch1.schema_id
                INNER JOIN sys.columns c1 ON fkc.parent_object_id = c1.object_id AND fkc.parent_column_id = c1.column_id
                INNER JOIN sys.tables t2 ON fkc.referenced_object_id = t2.object_id
                INNER JOIN sys.schemas sch2 ON t2.schema_id = sch2.schema_id
                INNER JOIN sys.columns c2 ON fkc.referenced_object_id = c2.object_id AND fkc.referenced_column_id = c2.column_id
                WHERE sch2.name = @Schema AND t2.name = @Table
                """;

            var results = await connection.QueryAsync<dynamic>(sql, new { Schema = schema, Table = tableName }).ConfigureAwait(false);

            return results.Select(r => new ForeignKeyInfo
            {
                ConstraintName = r.ConstraintName,
                ReferencingTable = new TableInfo { Schema = r.ReferencingSchema, Name = r.ReferencingTable },
                ReferencingColumn = r.ReferencingColumn,
                ReferencedTable = new TableInfo { Schema = r.ReferencedSchema, Name = r.ReferencedTable },
                ReferencedColumn = r.ReferencedColumn,
                DeleteRule = r.DeleteRule
            }).ToList();
        }
    }

    public async Task<long> GetRowCountAsync(string connectionString, string schema, string tableName, string? whereClause = null, CancellationToken ct = default)
    {
        var connection = new SqlConnection(connectionString);
        await using (connection.ConfigureAwait(false))
        {
            await connection.OpenAsync(ct).ConfigureAwait(false);

            var sql = string.IsNullOrEmpty(whereClause)
                ? $"SELECT COUNT_BIG(*) FROM [{schema}].[{tableName}]"
                : $"SELECT COUNT_BIG(*) FROM [{schema}].[{tableName}] WHERE {whereClause}";

            return await connection.ExecuteScalarAsync<long>(sql).ConfigureAwait(false);
        }
    }
}
