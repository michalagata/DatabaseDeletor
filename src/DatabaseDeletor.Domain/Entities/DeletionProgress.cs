namespace DatabaseDeletor.Domain.Entities;

public sealed class DeletionProgress
{
    public required int CurrentStep { get; init; }
    public required int TotalSteps { get; init; }
    public required TableInfo CurrentTable { get; init; }
    public required long DeletedRowsInStep { get; init; }
    public required long EstimatedRowsInStep { get; init; }
    public required long TotalDeletedRows { get; init; }
    public required long TotalEstimatedRows { get; init; }

    public double OverallPercentage => TotalEstimatedRows > 0
        ? (double)TotalDeletedRows / TotalEstimatedRows * 100
        : 0;
}
