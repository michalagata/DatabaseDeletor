using DatabaseDeletor.Domain.Entities;

namespace DatabaseDeletor.Domain.Interfaces;

public interface IDependencyAnalyzer
{
    Task<DependencyGraph> AnalyzeAsync(
        string connectionString,
        string schema,
        string tableName,
        CancellationToken ct = default);
}
