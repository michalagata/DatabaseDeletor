using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Enums;
using DatabaseDeletor.Domain.Interfaces;
using Microsoft.Extensions.Logging;

namespace DatabaseDeletor.Infrastructure.Services;

public sealed partial class ExclusionValidator : IExclusionValidator
{
    private readonly IDatabaseProviderResolver _providerResolver;
    private readonly IEnumerable<ISchemaIntrospector> _introspectors;
    private readonly ILogger<ExclusionValidator> _logger;

    public ExclusionValidator(
        IDatabaseProviderResolver providerResolver,
        IEnumerable<ISchemaIntrospector> introspectors,
        ILogger<ExclusionValidator> logger)
    {
        _providerResolver = providerResolver;
        _introspectors = introspectors;
        _logger = logger;
    }

    public async Task<ExclusionAnalysisResult> ValidateAsync(
        string connectionString,
        IReadOnlyList<TableInfo> selectedTables,
        IReadOnlyList<TableInfo> excludedTables,
        CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(selectedTables);
        ArgumentNullException.ThrowIfNull(excludedTables);

        if (excludedTables.Count == 0)
        {
            return new ExclusionAnalysisResult
            {
                IsValid = true,
                Conflicts = [],
                Recommendations = [],
                Suggestions = []
            };
        }

        var provider = _providerResolver.Resolve(connectionString);
        var introspector = GetIntrospector(provider);

        LogValidating(excludedTables.Count, selectedTables.Count);

        var excludedSet = new HashSet<TableInfo>(excludedTables);
        var selectedSet = new HashSet<TableInfo>(selectedTables);
        var conflicts = new List<ExclusionConflict>();
        var recommendations = new List<string>();
        var suggestions = new List<ResolutionSuggestion>();

        foreach (var selectedTable in selectedTables)
        {
            ct.ThrowIfCancellationRequested();

            var outgoingFks = await introspector.GetForeignKeysAsync(
                connectionString, selectedTable.Schema, selectedTable.Name, ct).ConfigureAwait(false);

            foreach (var fk in outgoingFks)
            {
                if (excludedSet.Contains(fk.ReferencedTable))
                {
                    conflicts.Add(new ExclusionConflict
                    {
                        ExcludedTable = fk.ReferencedTable,
                        DependentTable = selectedTable,
                        ForeignKey = fk,
                        Reason = $"Selected table {selectedTable.FullName} has FK '{fk.ConstraintName}' referencing excluded table {fk.ReferencedTable.FullName}",
                        Recommendation = $"Include {fk.ReferencedTable.FullName} in deletion or exclude {selectedTable.FullName} from deletion"
                    });

                    suggestions.Add(new ResolutionSuggestion
                    {
                        Action = ResolutionAction.IncludeInDeletion,
                        TargetTable = fk.ReferencedTable,
                        Description = $"Add {fk.ReferencedTable.FullName} back to the deletion set to satisfy FK '{fk.ConstraintName}'"
                    });
                }
            }

            var incomingFks = await introspector.GetReferencingForeignKeysAsync(
                connectionString, selectedTable.Schema, selectedTable.Name, ct).ConfigureAwait(false);

            foreach (var fk in incomingFks)
            {
                if (excludedSet.Contains(fk.ReferencingTable)
                    && !string.Equals(fk.DeleteRule, "CASCADE", StringComparison.OrdinalIgnoreCase))
                {
                    conflicts.Add(new ExclusionConflict
                    {
                        ExcludedTable = fk.ReferencingTable,
                        DependentTable = selectedTable,
                        ForeignKey = fk,
                        Reason = $"Excluded table {fk.ReferencingTable.FullName} references selected table {selectedTable.FullName} via FK '{fk.ConstraintName}' (delete rule: {fk.DeleteRule})",
                        Recommendation = $"Include {fk.ReferencingTable.FullName} in deletion or use CASCADE delete rule on FK '{fk.ConstraintName}'"
                    });

                    suggestions.Add(new ResolutionSuggestion
                    {
                        Action = ResolutionAction.IncludeInDeletion,
                        TargetTable = fk.ReferencingTable,
                        Description = $"Add {fk.ReferencingTable.FullName} back to the deletion set to satisfy FK '{fk.ConstraintName}'"
                    });

                    suggestions.Add(new ResolutionSuggestion
                    {
                        Action = ResolutionAction.ExcludeFromDeletion,
                        TargetTable = selectedTable,
                        Description = $"Remove {selectedTable.FullName} from the deletion set to avoid conflict with excluded {fk.ReferencingTable.FullName}"
                    });
                }
            }
        }

        if (conflicts.Count > 0)
        {
            recommendations.Add("Resolve FK conflicts before proceeding with deletion.");

            var excludedTablesInConflict = conflicts
                .Select(c => c.ExcludedTable.FullName)
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToList();

            foreach (var tableName in excludedTablesInConflict)
            {
                recommendations.Add($"Consider including table {tableName} in the deletion set.");
            }
        }

        LogValidationComplete(conflicts.Count);

        return new ExclusionAnalysisResult
        {
            IsValid = conflicts.Count == 0,
            Conflicts = conflicts,
            Recommendations = recommendations,
            Suggestions = suggestions
        };
    }

    private ISchemaIntrospector GetIntrospector(DatabaseProvider provider) =>
        _introspectors.FirstOrDefault(i => i.Provider == provider)
        ?? throw new InvalidOperationException($"No schema introspector registered for provider {provider}");

    [LoggerMessage(Level = LogLevel.Information, Message = "Validating {ExcludedCount} excluded table(s) against {SelectedCount} selected table(s)")]
    private partial void LogValidating(int excludedCount, int selectedCount);

    [LoggerMessage(Level = LogLevel.Information, Message = "Exclusion validation complete: {ConflictCount} conflict(s) found")]
    private partial void LogValidationComplete(int conflictCount);
}
