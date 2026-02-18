using DatabaseDeletor.Domain.Enums;

namespace DatabaseDeletor.Domain.Entities;

public sealed class DeletionPlan
{
    public Guid Id { get; } = Guid.NewGuid();
    public required TableInfo RootTable { get; init; }
    public required string? WhereClause { get; init; }
    public required IReadOnlyList<DeletionStep> Steps { get; init; }
    public DeletionStatus Status { get; set; } = DeletionStatus.PlanGenerated;
    public DateTime CreatedAt { get; } = DateTime.UtcNow;
    public long TotalEstimatedRows => Steps.Sum(s => s.EstimatedRowCount);
}
