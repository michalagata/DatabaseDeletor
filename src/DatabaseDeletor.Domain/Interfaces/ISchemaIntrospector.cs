using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Enums;

namespace DatabaseDeletor.Domain.Interfaces;

public interface ISchemaIntrospector
{
    DatabaseProvider Provider { get; }
    Task<TableInfo> GetTableInfoAsync(string connectionString, string schema, string tableName, CancellationToken ct = default);
    Task<IReadOnlyList<ForeignKeyInfo>> GetForeignKeysAsync(string connectionString, string schema, string tableName, CancellationToken ct = default);
    Task<IReadOnlyList<ForeignKeyInfo>> GetReferencingForeignKeysAsync(string connectionString, string schema, string tableName, CancellationToken ct = default);
    Task<long> GetRowCountAsync(string connectionString, string schema, string tableName, string? whereClause = null, CancellationToken ct = default);
    Task<IReadOnlyList<TableInfo>> GetAllTablesAsync(string connectionString, CancellationToken ct = default);
}
