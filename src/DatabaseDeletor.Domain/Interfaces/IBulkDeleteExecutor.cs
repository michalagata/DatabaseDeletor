using System.Data.Common;
using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Enums;

namespace DatabaseDeletor.Domain.Interfaces;

public interface IBulkDeleteExecutor
{
    DatabaseProvider Provider { get; }

    Task<long> ExecuteDeleteAsync(
        string connectionString,
        DeletionStep deletionStep,
        DeletionOptions options,
        DbConnection? existingConnection = null,
        DbTransaction? transaction = null,
        IProgress<long>? progress = null,
        CancellationToken ct = default);
}
