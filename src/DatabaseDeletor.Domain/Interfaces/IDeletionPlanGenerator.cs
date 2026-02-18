using DatabaseDeletor.Domain.Entities;

namespace DatabaseDeletor.Domain.Interfaces;

public interface IDeletionPlanGenerator
{
    Task<DeletionPlan> GenerateAsync(
        string connectionString,
        DependencyGraph graph,
        TableInfo rootTable,
        string? whereClause,
        CancellationToken ct = default);
}
