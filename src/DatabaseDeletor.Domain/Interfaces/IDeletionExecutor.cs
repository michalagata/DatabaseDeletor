using DatabaseDeletor.Domain.Entities;

namespace DatabaseDeletor.Domain.Interfaces;

public interface IDeletionExecutor
{
    Task<DeletionReport> ExecuteAsync(
        string connectionString,
        DeletionPlan plan,
        DeletionOptions options,
        IProgress<DeletionProgress>? progress = null,
        CancellationToken ct = default);
}
