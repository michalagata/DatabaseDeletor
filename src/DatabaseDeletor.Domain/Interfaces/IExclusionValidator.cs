using DatabaseDeletor.Domain.Entities;

namespace DatabaseDeletor.Domain.Interfaces;

public interface IExclusionValidator
{
    Task<ExclusionAnalysisResult> ValidateAsync(
        string connectionString,
        IReadOnlyList<TableInfo> selectedTables,
        IReadOnlyList<TableInfo> excludedTables,
        CancellationToken ct = default);
}
