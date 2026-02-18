using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Enums;
using DatabaseDeletor.Domain.Interfaces;
using Microsoft.Extensions.Logging;

namespace DatabaseDeletor.Infrastructure.Services;

public sealed class DependencyAnalyzer : IDependencyAnalyzer
{
    private readonly IDatabaseProviderResolver _providerResolver;
    private readonly IEnumerable<ISchemaIntrospector> _introspectors;
    private readonly ILogger<DependencyAnalyzer> _logger;

    public DependencyAnalyzer(
        IDatabaseProviderResolver providerResolver,
        IEnumerable<ISchemaIntrospector> introspectors,
        ILogger<DependencyAnalyzer> logger)
    {
        _providerResolver = providerResolver;
        _introspectors = introspectors;
        _logger = logger;
    }

    public async Task<DependencyGraph> AnalyzeAsync(string connectionString, string schema, string tableName, CancellationToken ct = default)
    {
        var provider = _providerResolver.Resolve(connectionString);
        var introspector = GetIntrospector(provider);

        _logger.LogInformation("Analyzing dependencies for {Schema}.{Table} using {Provider}", schema, tableName, provider);

        var graph = new DependencyGraph();
        var visited = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var queue = new Queue<(string Schema, string Table)>();

        queue.Enqueue((schema, tableName));

        while (queue.Count > 0)
        {
            var (currentSchema, currentTable) = queue.Dequeue();
            var key = $"{currentSchema}.{currentTable}";

            if (!visited.Add(key))
                continue;

            ct.ThrowIfCancellationRequested();

            var tableInfo = await introspector.GetTableInfoAsync(connectionString, currentSchema, currentTable, ct).ConfigureAwait(false);
            graph.AddTable(tableInfo);

            _logger.LogDebug("Processing table {Table} ({RowCount} rows)", tableInfo.FullName, tableInfo.RowCount);

            var referencingFks = await introspector.GetReferencingForeignKeysAsync(connectionString, currentSchema, currentTable, ct).ConfigureAwait(false);

            foreach (var fk in referencingFks)
            {
                graph.AddForeignKey(fk);
                var refKey = $"{fk.ReferencingTable.Schema}.{fk.ReferencingTable.Name}";

                if (!visited.Contains(refKey))
                {
                    queue.Enqueue((fk.ReferencingTable.Schema, fk.ReferencingTable.Name));
                }
            }
        }

        _logger.LogInformation("Dependency analysis complete: {TableCount} tables found", graph.Tables.Count);

        return graph;
    }

    private ISchemaIntrospector GetIntrospector(DatabaseProvider provider) =>
        _introspectors.FirstOrDefault(i => i.Provider == provider)
        ?? throw new InvalidOperationException($"No schema introspector registered for provider {provider}");
}
