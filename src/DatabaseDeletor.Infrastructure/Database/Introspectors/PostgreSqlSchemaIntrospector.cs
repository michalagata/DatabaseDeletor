using Dapper;
using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Enums;
using DatabaseDeletor.Domain.Exceptions;
using DatabaseDeletor.Domain.Interfaces;
using Npgsql;

namespace DatabaseDeletor.Infrastructure.Database.Introspectors;

public sealed class PostgreSqlSchemaIntrospector : ISchemaIntrospector
{
    public DatabaseProvider Provider => DatabaseProvider.PostgreSql;

    public async Task<TableInfo> GetTableInfoAsync(string connectionString, string schema, string tableName, CancellationToken ct = default)
    {
        var connection = new NpgsqlConnection(connectionString);
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
        var connection = new NpgsqlConnection(connectionString);
        await using (connection.ConfigureAwait(false))
        {
            await connection.OpenAsync(ct).ConfigureAwait(false);

            const string sql = """
                SELECT
                    tc.constraint_name AS ConstraintName,
                    kcu.table_schema AS ReferencingSchema,
                    kcu.table_name AS ReferencingTable,
                    kcu.column_name AS ReferencingColumn,
                    ccu.table_schema AS ReferencedSchema,
                    ccu.table_name AS ReferencedTable,
                    ccu.column_name AS ReferencedColumn,
                    rc.delete_rule AS DeleteRule
                FROM information_schema.table_constraints tc
                JOIN information_schema.key_column_usage kcu
                    ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
                JOIN information_schema.constraint_column_usage ccu
                    ON tc.constraint_name = ccu.constraint_name AND tc.table_schema = ccu.table_schema
                JOIN information_schema.referential_constraints rc
                    ON tc.constraint_name = rc.constraint_name AND tc.table_schema = rc.constraint_schema
                WHERE tc.constraint_type = 'FOREIGN KEY'
                    AND kcu.table_schema = @Schema AND kcu.table_name = @Table
                """;

            var results = await connection.QueryAsync<dynamic>(sql, new { Schema = schema, Table = tableName }).ConfigureAwait(false);

            return results.Select(r => new ForeignKeyInfo
            {
                ConstraintName = r.constraintname,
                ReferencingTable = new TableInfo { Schema = r.referencingschema, Name = r.referencingtable },
                ReferencingColumn = r.referencingcolumn,
                ReferencedTable = new TableInfo { Schema = r.referencedschema, Name = r.referencedtable },
                ReferencedColumn = r.referencedcolumn,
                DeleteRule = r.deleterule
            }).ToList();
        }
    }

    public async Task<IReadOnlyList<ForeignKeyInfo>> GetReferencingForeignKeysAsync(string connectionString, string schema, string tableName, CancellationToken ct = default)
    {
        var connection = new NpgsqlConnection(connectionString);
        await using (connection.ConfigureAwait(false))
        {
            await connection.OpenAsync(ct).ConfigureAwait(false);

            const string sql = """
                SELECT
                    tc.constraint_name AS ConstraintName,
                    kcu.table_schema AS ReferencingSchema,
                    kcu.table_name AS ReferencingTable,
                    kcu.column_name AS ReferencingColumn,
                    ccu.table_schema AS ReferencedSchema,
                    ccu.table_name AS ReferencedTable,
                    ccu.column_name AS ReferencedColumn,
                    rc.delete_rule AS DeleteRule
                FROM information_schema.table_constraints tc
                JOIN information_schema.key_column_usage kcu
                    ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
                JOIN information_schema.constraint_column_usage ccu
                    ON tc.constraint_name = ccu.constraint_name AND tc.table_schema = ccu.table_schema
                JOIN information_schema.referential_constraints rc
                    ON tc.constraint_name = rc.constraint_name AND tc.table_schema = rc.constraint_schema
                WHERE tc.constraint_type = 'FOREIGN KEY'
                    AND ccu.table_schema = @Schema AND ccu.table_name = @Table
                """;

            var results = await connection.QueryAsync<dynamic>(sql, new { Schema = schema, Table = tableName }).ConfigureAwait(false);

            return results.Select(r => new ForeignKeyInfo
            {
                ConstraintName = r.constraintname,
                ReferencingTable = new TableInfo { Schema = r.referencingschema, Name = r.referencingtable },
                ReferencingColumn = r.referencingcolumn,
                ReferencedTable = new TableInfo { Schema = r.referencedschema, Name = r.referencedtable },
                ReferencedColumn = r.referencedcolumn,
                DeleteRule = r.deleterule
            }).ToList();
        }
    }

    public async Task<IReadOnlyList<TableInfo>> GetAllTablesAsync(string connectionString, CancellationToken ct = default)
    {
        var connection = new NpgsqlConnection(connectionString);
        await using (connection.ConfigureAwait(false))
        {
            await connection.OpenAsync(ct).ConfigureAwait(false);

            const string sql = """
                SELECT table_schema AS tableschema, table_name AS tablename
                FROM information_schema.tables
                WHERE table_type = 'BASE TABLE'
                    AND table_schema NOT IN ('pg_catalog', 'information_schema')
                ORDER BY table_schema, table_name
                """;

            var results = await connection.QueryAsync<dynamic>(sql).ConfigureAwait(false);

            return results.Select(r => new TableInfo
            {
                Schema = r.tableschema,
                Name = r.tablename
            }).ToList();
        }
    }

    public async Task<long> GetRowCountAsync(string connectionString, string schema, string tableName, string? whereClause = null, CancellationToken ct = default)
    {
        var connection = new NpgsqlConnection(connectionString);
        await using (connection.ConfigureAwait(false))
        {
            await connection.OpenAsync(ct).ConfigureAwait(false);

            var sql = string.IsNullOrEmpty(whereClause)
                ? $"SELECT COUNT(*) FROM \"{schema}\".\"{tableName}\""
                : $"SELECT COUNT(*) FROM \"{schema}\".\"{tableName}\" WHERE {whereClause}";

            return await connection.ExecuteScalarAsync<long>(sql).ConfigureAwait(false);
        }
    }
}
