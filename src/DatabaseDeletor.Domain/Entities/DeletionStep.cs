namespace DatabaseDeletor.Domain.Entities;

public sealed class DeletionStep
{
    public int Order { get; init; }
    public required TableInfo Table { get; init; }
    public required string DeleteSql { get; init; }
    public long EstimatedRowCount { get; init; }
    public long ActualDeletedCount { get; set; }
    public bool IsCompleted { get; set; }
    public TimeSpan Duration { get; set; }
    public string? ErrorMessage { get; set; }
}
