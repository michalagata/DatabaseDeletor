using System.Collections.ObjectModel;

namespace DatabaseDeletor.Domain.Entities;

public sealed class DependencyTreeNode
{
    public required TableInfo Table { get; init; }
    public ForeignKeyInfo? ParentForeignKey { get; init; }
    public int Depth { get; init; }
    public Collection<DependencyTreeNode> Children { get; } = [];
}
