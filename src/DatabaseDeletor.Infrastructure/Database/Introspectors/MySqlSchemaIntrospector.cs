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
        await using var connection = new MySqlConnection(connectionString);
        await connection.OpenAsync(ct).ConfigureAwait(false);

        var exists = await connection.ExecuteScalarAsync<long>(
            "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = @Schema AND table_name = @Table",
            new { Schema = schema, Table = tableName }).ConfigureAwait(false);

        if (exists == 0)
            throw new SchemaIntrospectionException($"Table {schema}.{tableName} does not exist.");

        var rowCount = await GetRowCountAsync(connectionString, schema, tableName, null, ct).ConfigureAwait(false);

        return new TableInfo { Schema = schema, Name = tableName, RowCount = rowCount };
    }

    public async Task<IReadOnlyList<ForeignKeyInfo>> GetForeignKeysAsync(string connectionString, string schema, string tableName, CancellationToken ct = default)
    {
        await using var connection = new MySqlConnection(connectionString);
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

    public async Task<IReadOnlyList<ForeignKeyInfo>> GetReferencingForeignKeysAsync(string connectionString, string schema, string tableName, CancellationToken ct = default)
    {
        await using var connection = new MySqlConnection(connectionString);
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

    public async Task<long> GetRowCountAsync(string connectionString, string schema, string tableName, string? whereClause = null, CancellationToken ct = default)
    {
        await using var connection = new MySqlConnection(connectionString);
        await connection.OpenAsync(ct).ConfigureAwait(false);

        var sql = string.IsNullOrEmpty(whereClause)
            ? $"SELECT COUNT(*) FROM `{schema}`.`{tableName}`"
            : $"SELECT COUNT(*) FROM `{schema}`.`{tableName}` WHERE {whereClause}";

        return await connection.ExecuteScalarAsync<long>(sql).ConfigureAwait(false);
    }
}
