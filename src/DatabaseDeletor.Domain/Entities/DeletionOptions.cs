using DatabaseDeletor.Domain.Enums;

namespace DatabaseDeletor.Domain.Entities;

public sealed record DeletionOptions
{
    public const int MinBatchSize = 100;
    public const int MaxBatchSize = 1_000_000;
    public const int DefaultBatchSize = 10_000;

    public DeletionMode Mode { get; init; } = DeletionMode.BatchDelete;
    public int BatchSize { get; init; } = DefaultBatchSize;
    public bool UseTransaction { get; init; }

    public int EffectiveBatchSize => Mode switch
    {
        DeletionMode.BatchDelete => BatchSize,
        DeletionMode.SingleRowDelete => 1,
        DeletionMode.DirectDelete => 0,
        _ => BatchSize
    };

    public bool IsValid => Mode != DeletionMode.BatchDelete
        || (BatchSize >= MinBatchSize && BatchSize <= MaxBatchSize);
}
