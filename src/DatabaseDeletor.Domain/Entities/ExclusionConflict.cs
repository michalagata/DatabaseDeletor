namespace DatabaseDeletor.Domain.Entities;

public sealed class ExclusionConflict
{
    public required TableInfo ExcludedTable { get; init; }
    public required TableInfo DependentTable { get; init; }
    public required ForeignKeyInfo ForeignKey { get; init; }
    public required string Reason { get; init; }
    public required string Recommendation { get; init; }
}
