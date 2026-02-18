namespace DatabaseDeletor.Domain.Entities;

public sealed class DeletionReport
{
    public Guid PlanId { get; init; }
    public required TableInfo RootTable { get; init; }
    public required IReadOnlyList<DeletionStepResult> Results { get; init; }
    public DateTime StartedAt { get; init; }
    public DateTime CompletedAt { get; init; }
    public TimeSpan TotalDuration => CompletedAt - StartedAt;
    public long TotalDeletedRows => Results.Sum(r => r.DeletedCount);
    public bool HasErrors => Results.Any(r => r.ErrorMessage is not null);
}
