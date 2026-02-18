namespace DatabaseDeletor.Domain.Entities;

public sealed class DependencyGraph
{
    private readonly Dictionary<TableInfo, List<ForeignKeyInfo>> _incomingReferences = new();
    private readonly Dictionary<TableInfo, List<ForeignKeyInfo>> _outgoingReferences = new();
    private readonly HashSet<TableInfo> _tables = new();

    public IReadOnlySet<TableInfo> Tables => _tables;

    public void AddTable(TableInfo table)
    {
        ArgumentNullException.ThrowIfNull(table);
        _tables.Add(table);
        _incomingReferences.TryAdd(table, []);
        _outgoingReferences.TryAdd(table, []);
    }

    public void AddForeignKey(ForeignKeyInfo fk)
    {
        ArgumentNullException.ThrowIfNull(fk);

        AddTable(fk.ReferencingTable);
        AddTable(fk.ReferencedTable);

        _outgoingReferences[fk.ReferencingTable].Add(fk);
        _incomingReferences[fk.ReferencedTable].Add(fk);
    }

    public IReadOnlyList<ForeignKeyInfo> GetIncomingReferences(TableInfo table) =>
        _incomingReferences.TryGetValue(table, out var refs) ? refs : [];

    public IReadOnlyList<ForeignKeyInfo> GetOutgoingReferences(TableInfo table) =>
        _outgoingReferences.TryGetValue(table, out var refs) ? refs : [];

    public IReadOnlyList<TableInfo> GetTopologicalDeletionOrder(TableInfo rootTable)
    {
        var visited = new HashSet<TableInfo>();
        var result = new List<TableInfo>();

        void Visit(TableInfo table)
        {
            if (!visited.Add(table))
                return;

            foreach (var fk in GetIncomingReferences(table))
            {
                Visit(fk.ReferencingTable);
            }

            result.Add(table);
        }

        Visit(rootTable);
        return result;
    }
}
