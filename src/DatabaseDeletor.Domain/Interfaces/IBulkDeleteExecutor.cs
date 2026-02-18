using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Enums;

namespace DatabaseDeletor.Domain.Interfaces;

public interface IBulkDeleteExecutor
{
    DatabaseProvider Provider { get; }

    Task<long> ExecuteDeleteAsync(
        string connectionString,
        DeletionStep deletionStep,
        IProgress<long>? progress = null,
        CancellationToken ct = default);
}
