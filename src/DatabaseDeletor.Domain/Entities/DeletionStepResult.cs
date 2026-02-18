namespace DatabaseDeletor.Domain.Entities;

public sealed class DeletionStepResult
{
    public required TableInfo Table { get; init; }
    public long DeletedCount { get; init; }
    public TimeSpan Duration { get; init; }
    public string? ErrorMessage { get; init; }
    public bool Success => ErrorMessage is null;
}
