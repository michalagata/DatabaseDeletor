using Dapper;
using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Enums;
using DatabaseDeletor.Domain.Exceptions;
using DatabaseDeletor.Domain.Interfaces;
using Oracle.ManagedDataAccess.Client;

namespace DatabaseDeletor.Infrastructure.Database.Introspectors;

public sealed class OracleSchemaIntrospector : ISchemaIntrospector
{
    public DatabaseProvider Provider => DatabaseProvider.Oracle;

    public async Task<TableInfo> GetTableInfoAsync(string connectionString, string schema, string tableName, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(schema);
        ArgumentNullException.ThrowIfNull(tableName);

        using var connection = new OracleConnection(connectionString);
        await connection.OpenAsync(ct).ConfigureAwait(false);

        var exists = await connection.ExecuteScalarAsync<int>(
            "SELECT COUNT(*) FROM ALL_TABLES WHERE OWNER = :Schema AND TABLE_NAME = :Table",
            new { Schema = schema.ToUpperInvariant(), Table = tableName.ToUpperInvariant() }).ConfigureAwait(false);

        if (exists == 0)
            throw new SchemaIntrospectionException($"Table {schema}.{tableName} does not exist.");

        var rowCount = await GetRowCountAsync(connectionString, schema, tableName, null, ct).ConfigureAwait(false);

        return new TableInfo { Schema = schema, Name = tableName, RowCount = rowCount };
    }

    public async Task<IReadOnlyList<ForeignKeyInfo>> GetForeignKeysAsync(string connectionString, string schema, string tableName, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(schema);
        ArgumentNullException.ThrowIfNull(tableName);

        using var connection = new OracleConnection(connectionString);
        await connection.OpenAsync(ct).ConfigureAwait(false);

        const string sql = """
            SELECT
                ac.CONSTRAINT_NAME AS ConstraintName,
                ac.OWNER AS ReferencingSchema,
                ac.TABLE_NAME AS ReferencingTable,
                acc.COLUMN_NAME AS ReferencingColumn,
                rc.OWNER AS ReferencedSchema,
                rc.TABLE_NAME AS ReferencedTable,
                rcc.COLUMN_NAME AS ReferencedColumn,
                ac.DELETE_RULE AS DeleteRule
            FROM ALL_CONSTRAINTS ac
            JOIN ALL_CONS_COLUMNS acc ON ac.CONSTRAINT_NAME = acc.CONSTRAINT_NAME AND ac.OWNER = acc.OWNER
            JOIN ALL_CONSTRAINTS rc ON ac.R_CONSTRAINT_NAME = rc.CONSTRAINT_NAME AND ac.R_OWNER = rc.OWNER
            JOIN ALL_CONS_COLUMNS rcc ON rc.CONSTRAINT_NAME = rcc.CONSTRAINT_NAME AND rc.OWNER = rcc.OWNER
            WHERE ac.CONSTRAINT_TYPE = 'R'
                AND ac.OWNER = :Schema AND ac.TABLE_NAME = :Table
            """;

        var results = await connection.QueryAsync<dynamic>(sql,
            new { Schema = schema.ToUpperInvariant(), Table = tableName.ToUpperInvariant() }).ConfigureAwait(false);

        return results.Select(r => new ForeignKeyInfo
        {
            ConstraintName = r.CONSTRAINTNAME,
            ReferencingTable = new TableInfo { Schema = r.REFERENCINGSCHEMA, Name = r.REFERENCINGTABLE },
            ReferencingColumn = r.REFERENCINGCOLUMN,
            ReferencedTable = new TableInfo { Schema = r.REFERENCEDSCHEMA, Name = r.REFERENCEDTABLE },
            ReferencedColumn = r.REFERENCEDCOLUMN,
            DeleteRule = r.DELETERULE ?? "NO ACTION"
        }).ToList();
    }

    public async Task<IReadOnlyList<ForeignKeyInfo>> GetReferencingForeignKeysAsync(string connectionString, string schema, string tableName, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(schema);
        ArgumentNullException.ThrowIfNull(tableName);

        using var connection = new OracleConnection(connectionString);
        await connection.OpenAsync(ct).ConfigureAwait(false);

        const string sql = """
            SELECT
                ac.CONSTRAINT_NAME AS ConstraintName,
                ac.OWNER AS ReferencingSchema,
                ac.TABLE_NAME AS ReferencingTable,
                acc.COLUMN_NAME AS ReferencingColumn,
                rc.OWNER AS ReferencedSchema,
                rc.TABLE_NAME AS ReferencedTable,
                rcc.COLUMN_NAME AS ReferencedColumn,
                ac.DELETE_RULE AS DeleteRule
            FROM ALL_CONSTRAINTS ac
            JOIN ALL_CONS_COLUMNS acc ON ac.CONSTRAINT_NAME = acc.CONSTRAINT_NAME AND ac.OWNER = acc.OWNER
            JOIN ALL_CONSTRAINTS rc ON ac.R_CONSTRAINT_NAME = rc.CONSTRAINT_NAME AND ac.R_OWNER = rc.OWNER
            JOIN ALL_CONS_COLUMNS rcc ON rc.CONSTRAINT_NAME = rcc.CONSTRAINT_NAME AND rc.OWNER = rcc.OWNER
            WHERE ac.CONSTRAINT_TYPE = 'R'
                AND rc.OWNER = :Schema AND rc.TABLE_NAME = :Table
            """;

        var results = await connection.QueryAsync<dynamic>(sql,
            new { Schema = schema.ToUpperInvariant(), Table = tableName.ToUpperInvariant() }).ConfigureAwait(false);

        return results.Select(r => new ForeignKeyInfo
        {
            ConstraintName = r.CONSTRAINTNAME,
            ReferencingTable = new TableInfo { Schema = r.REFERENCINGSCHEMA, Name = r.REFERENCINGTABLE },
            ReferencingColumn = r.REFERENCINGCOLUMN,
            ReferencedTable = new TableInfo { Schema = r.REFERENCEDSCHEMA, Name = r.REFERENCEDTABLE },
            ReferencedColumn = r.REFERENCEDCOLUMN,
            DeleteRule = r.DELETERULE ?? "NO ACTION"
        }).ToList();
    }

    public async Task<IReadOnlyList<TableInfo>> GetAllTablesAsync(string connectionString, CancellationToken ct = default)
    {
        using var connection = new OracleConnection(connectionString);
        await connection.OpenAsync(ct).ConfigureAwait(false);

        const string sql = """
            SELECT OWNER AS TABLESCHEMA, TABLE_NAME AS TABLENAME
            FROM ALL_TABLES
            WHERE OWNER = SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA')
            ORDER BY OWNER, TABLE_NAME
            """;

        var results = await connection.QueryAsync<dynamic>(sql).ConfigureAwait(false);

        return results.Select(r => new TableInfo
        {
            Schema = r.TABLESCHEMA,
            Name = r.TABLENAME
        }).ToList();
    }

    public async Task<long> GetRowCountAsync(string connectionString, string schema, string tableName, string? whereClause = null, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(schema);
        ArgumentNullException.ThrowIfNull(tableName);

        using var connection = new OracleConnection(connectionString);
        await connection.OpenAsync(ct).ConfigureAwait(false);

        var sql = string.IsNullOrEmpty(whereClause)
            ? $"SELECT COUNT(*) FROM \"{schema.ToUpperInvariant()}\".\"{tableName.ToUpperInvariant()}\""
            : $"SELECT COUNT(*) FROM \"{schema.ToUpperInvariant()}\".\"{tableName.ToUpperInvariant()}\" WHERE {whereClause}";

        return await connection.ExecuteScalarAsync<long>(sql).ConfigureAwait(false);
    }
}
