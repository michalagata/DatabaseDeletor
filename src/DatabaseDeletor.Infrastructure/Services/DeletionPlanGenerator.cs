using System.Data.Common;
using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Enums;
using DatabaseDeletor.Domain.Interfaces;
using Microsoft.Extensions.Logging;

namespace DatabaseDeletor.Infrastructure.Services;

public sealed partial class DeletionPlanGenerator : IDeletionPlanGenerator
{
    private readonly IDatabaseProviderResolver _providerResolver;
    private readonly IEnumerable<ISchemaIntrospector> _introspectors;
    private readonly ILogger<DeletionPlanGenerator> _logger;

    public DeletionPlanGenerator(
        IDatabaseProviderResolver providerResolver,
        IEnumerable<ISchemaIntrospector> introspectors,
        ILogger<DeletionPlanGenerator> logger)
    {
        _providerResolver = providerResolver;
        _introspectors = introspectors;
        _logger = logger;
    }

    public async Task<DeletionPlan> GenerateAsync(
        string connectionString,
        DependencyGraph graph,
        TableInfo rootTable,
        string? whereClause,
        CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(graph);

        var provider = _providerResolver.Resolve(connectionString);
        var introspector = GetIntrospector(provider);

        var deletionOrder = graph.GetTopologicalDeletionOrder(rootTable);

        LogDeletionOrder(string.Join(" -> ", deletionOrder.Select(t => t.FullName)));

        var steps = new List<DeletionStep>();
        var order = 0;

        foreach (var table in deletionOrder)
        {
            ct.ThrowIfCancellationRequested();

            var deleteSql = BuildDeleteSql(provider, graph, table, rootTable, whereClause);
            var estimatedCount = await EstimateRowCount(introspector, connectionString, table, graph, rootTable, whereClause, ct).ConfigureAwait(false);

            steps.Add(new DeletionStep
            {
                Order = order++,
                Table = table,
                DeleteSql = deleteSql,
                EstimatedRowCount = estimatedCount
            });
        }

        return new DeletionPlan
        {
            RootTable = rootTable,
            WhereClause = whereClause,
            Steps = steps
        };
    }

    private static string BuildDeleteSql(DatabaseProvider provider, DependencyGraph graph, TableInfo table, TableInfo rootTable, string? whereClause)
    {
        var quotedTable = QuoteTableName(provider, table);

        if (table.Equals(rootTable))
        {
            return string.IsNullOrEmpty(whereClause)
                ? $"DELETE FROM {quotedTable}"
                : $"DELETE FROM {quotedTable} WHERE {whereClause}";
        }

        var incomingFks = graph.GetOutgoingReferences(table);
        var fkToRoot = incomingFks.FirstOrDefault(fk => fk.ReferencedTable.Equals(rootTable));

        if (fkToRoot is not null && !string.IsNullOrEmpty(whereClause))
        {
            var quotedRootTable = QuoteTableName(provider, rootTable);
            var quotedRefCol = QuoteColumnName(provider, fkToRoot.ReferencingColumn);
            var quotedRefedCol = QuoteColumnName(provider, fkToRoot.ReferencedColumn);

            return $"DELETE FROM {quotedTable} WHERE {quotedRefCol} IN (SELECT {quotedRefedCol} FROM {quotedRootTable} WHERE {whereClause})";
        }

        return $"DELETE FROM {quotedTable}";
    }

    private static async Task<long> EstimateRowCount(ISchemaIntrospector introspector, string connectionString, TableInfo table, DependencyGraph graph, TableInfo rootTable, string? whereClause, CancellationToken ct)
    {
        try
        {
            if (table.Equals(rootTable))
            {
                return await introspector.GetRowCountAsync(connectionString, table.Schema, table.Name, whereClause, ct).ConfigureAwait(false);
            }

            return await introspector.GetRowCountAsync(connectionString, table.Schema, table.Name, null, ct).ConfigureAwait(false);
        }
        catch (DbException)
        {
            return table.RowCount;
        }
    }

    private static string QuoteTableName(DatabaseProvider provider, TableInfo table) => provider switch
    {
        DatabaseProvider.SqlServer => $"[{table.Schema}].[{table.Name}]",
        DatabaseProvider.PostgreSql => $"\"{table.Schema}\".\"{table.Name}\"",
        DatabaseProvider.MySql => $"`{table.Schema}`.`{table.Name}`",
        DatabaseProvider.Oracle => $"\"{table.Schema.ToUpperInvariant()}\".\"{table.Name.ToUpperInvariant()}\"",
        _ => $"{table.Schema}.{table.Name}"
    };

    private static string QuoteColumnName(DatabaseProvider provider, string column) => provider switch
    {
        DatabaseProvider.SqlServer => $"[{column}]",
        DatabaseProvider.PostgreSql => $"\"{column}\"",
        DatabaseProvider.MySql => $"`{column}`",
        DatabaseProvider.Oracle => $"\"{column.ToUpperInvariant()}\"",
        _ => column
    };

    private ISchemaIntrospector GetIntrospector(DatabaseProvider provider) =>
        _introspectors.FirstOrDefault(i => i.Provider == provider)
        ?? throw new InvalidOperationException($"No schema introspector registered for provider {provider}");

    [LoggerMessage(Level = LogLevel.Information, Message = "Deletion order: {Order}")]
    private partial void LogDeletionOrder(string order);
}
