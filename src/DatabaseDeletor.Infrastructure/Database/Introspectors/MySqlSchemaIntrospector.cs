using Dapper;
using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Enums;
using DatabaseDeletor.Domain.Exceptions;
using DatabaseDeletor.Domain.Interfaces;
using MySqlConnector;

namespace DatabaseDeletor.Infrastructure.Database.Introspectors;

public sealed class MySqlSchemaIntrospector : ISchemaIntrospector
{
    public DatabaseProvider Provider => DatabaseProvider.MySql;

    public async Task<TableInfo> GetTableInfoAsync(string connectionString, string schema, string tableName, CancellationToken ct = default)
    {
        var connection = new MySqlConnection(connectionString);
        await using (connection.ConfigureAwait(false))
        {
            await connection.OpenAsync(ct).ConfigureAwait(false);

            var exists = await connection.ExecuteScalarAsync<long>(
                "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = @Schema AND table_name = @Table",
                new { Schema = schema, Table = tableName }).ConfigureAwait(false);

            if (exists == 0)
                throw new SchemaIntrospectionException($"Table {schema}.{tableName} does not exist.");

            var rowCount = await GetRowCountAsync(connectionString, schema, tableName, null, ct).ConfigureAwait(false);

            return new TableInfo { Schema = schema, Name = tableName, RowCount = rowCount };
        }
    }

    public async Task<IReadOnlyList<ForeignKeyInfo>> GetForeignKeysAsync(string connectionString, string schema, string tableName, CancellationToken ct = default)
    {
        var connection = new MySqlConnection(connectionString);
        await using (connection.ConfigureAwait(false))
        {
            await connection.OpenAsync(ct).ConfigureAwait(false);

            const string sql = """
                SELECT
                    kcu.CONSTRAINT_NAME AS ConstraintName,
                    kcu.TABLE_SCHEMA AS ReferencingSchema,
                    kcu.TABLE_NAME AS ReferencingTable,
                    kcu.COLUMN_NAME AS ReferencingColumn,
                    kcu.REFERENCED_TABLE_SCHEMA AS ReferencedSchema,
                    kcu.REFERENCED_TABLE_NAME AS ReferencedTable,
                    kcu.REFERENCED_COLUMN_NAME AS ReferencedColumn,
                    rc.DELETE_RULE AS DeleteRule
                FROM information_schema.KEY_COLUMN_USAGE kcu
                JOIN information_schema.REFERENTIAL_CONSTRAINTS rc
                    ON kcu.CONSTRAINT_NAME = rc.CONSTRAINT_NAME AND kcu.TABLE_SCHEMA = rc.CONSTRAINT_SCHEMA
                WHERE kcu.TABLE_SCHEMA = @Schema AND kcu.TABLE_NAME = @Table
                    AND kcu.REFERENCED_TABLE_NAME IS NOT NULL
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
        var connection = new MySqlConnection(connectionString);
        await using (connection.ConfigureAwait(false))
        {
            await connection.OpenAsync(ct).ConfigureAwait(false);

            const string sql = """
                SELECT
                    kcu.CONSTRAINT_NAME AS ConstraintName,
                    kcu.TABLE_SCHEMA AS ReferencingSchema,
                    kcu.TABLE_NAME AS ReferencingTable,
                    kcu.COLUMN_NAME AS ReferencingColumn,
                    kcu.REFERENCED_TABLE_SCHEMA AS ReferencedSchema,
                    kcu.REFERENCED_TABLE_NAME AS ReferencedTable,
                    kcu.REFERENCED_COLUMN_NAME AS ReferencedColumn,
                    rc.DELETE_RULE AS DeleteRule
                FROM information_schema.KEY_COLUMN_USAGE kcu
                JOIN information_schema.REFERENTIAL_CONSTRAINTS rc
                    ON kcu.CONSTRAINT_NAME = rc.CONSTRAINT_NAME AND kcu.TABLE_SCHEMA = rc.CONSTRAINT_SCHEMA
                WHERE kcu.REFERENCED_TABLE_SCHEMA = @Schema AND kcu.REFERENCED_TABLE_NAME = @Table
                    AND kcu.REFERENCED_TABLE_NAME IS NOT NULL
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

    public async Task<IReadOnlyList<TableInfo>> GetAllTablesAsync(string connectionString, CancellationToken ct = default)
    {
        var connection = new MySqlConnection(connectionString);
        await using (connection.ConfigureAwait(false))
        {
            await connection.OpenAsync(ct).ConfigureAwait(false);

            const string sql = """
                SELECT TABLE_SCHEMA AS TableSchema, TABLE_NAME AS TableName
                FROM information_schema.TABLES
                WHERE TABLE_TYPE = 'BASE TABLE'
                    AND TABLE_SCHEMA = DATABASE()
                ORDER BY TABLE_SCHEMA, TABLE_NAME
                """;

            var results = await connection.QueryAsync<dynamic>(sql).ConfigureAwait(false);

            return results.Select(r => new TableInfo
            {
                Schema = r.TableSchema,
                Name = r.TableName
            }).ToList();
        }
    }

    public async Task<IReadOnlyList<ColumnInfo>> GetColumnsAsync(string connectionString, string schema, string tableName, CancellationToken ct = default)
    {
        var connection = new MySqlConnection(connectionString);
        await using (connection.ConfigureAwait(false))
        {
            await connection.OpenAsync(ct).ConfigureAwait(false);

            const string sql = """
                SELECT
                    c.COLUMN_NAME AS ColumnName,
                    c.DATA_TYPE AS DataType,
                    CASE WHEN c.IS_NULLABLE = 'YES' THEN 1 ELSE 0 END AS IsNullable,
                    CASE WHEN pk.COLUMN_NAME IS NOT NULL THEN 1 ELSE 0 END AS IsPrimaryKey
                FROM information_schema.COLUMNS c
                LEFT JOIN (
                    SELECT ku.TABLE_SCHEMA, ku.TABLE_NAME, ku.COLUMN_NAME
                    FROM information_schema.TABLE_CONSTRAINTS tc
                    JOIN information_schema.KEY_COLUMN_USAGE ku
                        ON tc.CONSTRAINT_NAME = ku.CONSTRAINT_NAME AND tc.TABLE_SCHEMA = ku.TABLE_SCHEMA
                    WHERE tc.CONSTRAINT_TYPE = 'PRIMARY KEY'
                ) pk ON c.TABLE_SCHEMA = pk.TABLE_SCHEMA AND c.TABLE_NAME = pk.TABLE_NAME AND c.COLUMN_NAME = pk.COLUMN_NAME
                WHERE c.TABLE_SCHEMA = @Schema AND c.TABLE_NAME = @Table
                ORDER BY c.ORDINAL_POSITION
                """;

            var results = await connection.QueryAsync<dynamic>(sql, new { Schema = schema, Table = tableName }).ConfigureAwait(false);

            return results.Select(r => new ColumnInfo
            {
                Name = r.ColumnName,
                DataType = r.DataType,
                IsNullable = (long)r.IsNullable == 1,
                IsPrimaryKey = (long)r.IsPrimaryKey == 1
            }).ToList();
        }
    }

    public async Task<long> GetRowCountAsync(string connectionString, string schema, string tableName, string? whereClause = null, CancellationToken ct = default)
    {
        var connection = new MySqlConnection(connectionString);
        await using (connection.ConfigureAwait(false))
        {
            await connection.OpenAsync(ct).ConfigureAwait(false);

            var sql = string.IsNullOrEmpty(whereClause)
                ? $"SELECT COUNT(*) FROM `{schema}`.`{tableName}`"
                : $"SELECT COUNT(*) FROM `{schema}`.`{tableName}` WHERE {whereClause}";

            return await connection.ExecuteScalarAsync<long>(sql).ConfigureAwait(false);
        }
    }
}
