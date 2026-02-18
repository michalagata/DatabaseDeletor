namespace DatabaseDeletor.Domain.Entities;

public sealed class ForeignKeyInfo
{
    public required string ConstraintName { get; init; }
    public required TableInfo ReferencingTable { get; init; }
    public required string ReferencingColumn { get; init; }
    public required TableInfo ReferencedTable { get; init; }
    public required string ReferencedColumn { get; init; }
    public required string DeleteRule { get; init; }
}
