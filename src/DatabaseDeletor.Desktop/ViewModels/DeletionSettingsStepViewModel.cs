using System.ComponentModel.DataAnnotations;
using CommunityToolkit.Mvvm.ComponentModel;
using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Enums;

namespace DatabaseDeletor.Desktop.ViewModels;

public sealed partial class DeletionSettingsStepViewModel : ViewModelBase
{
    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(IsBatchMode))]
    [NotifyPropertyChangedFor(nameof(ModeSummary))]
    [NotifyPropertyChangedFor(nameof(HasValidationErrors))]
    private DeletionMode _selectedMode = DeletionMode.BatchDelete;

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(BatchSizeError))]
    [NotifyPropertyChangedFor(nameof(HasValidationErrors))]
    [NotifyPropertyChangedFor(nameof(ModeSummary))]
    private int _batchSize = DeletionOptions.DefaultBatchSize;

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(ModeSummary))]
    private bool _useTransaction;

    public bool IsBatchMode => SelectedMode == DeletionMode.BatchDelete;

    public string? BatchSizeError
    {
        get
        {
            if (!IsBatchMode) return null;
            if (BatchSize < DeletionOptions.MinBatchSize)
                return $"Batch size must be at least {DeletionOptions.MinBatchSize}";
            if (BatchSize > DeletionOptions.MaxBatchSize)
                return $"Batch size must be at most {DeletionOptions.MaxBatchSize:N0}";
            return null;
        }
    }

    public bool HasValidationErrors => BatchSizeError is not null;

    public string ModeSummary
    {
        get
        {
            var mode = SelectedMode switch
            {
                DeletionMode.BatchDelete => $"Batch Delete ({BatchSize:N0} rows per batch)",
                DeletionMode.SingleRowDelete => "Single Row Delete (1 row at a time)",
                DeletionMode.DirectDelete => "Direct Delete (no batching)",
                _ => SelectedMode.ToString()
            };

            var tx = UseTransaction ? "Enabled" : "Disabled";
            return $"Mode: {mode} | Transaction: {tx}";
        }
    }

    public IReadOnlyList<DeletionMode> AvailableModes { get; } =
    [
        DeletionMode.BatchDelete,
        DeletionMode.SingleRowDelete,
        DeletionMode.DirectDelete
    ];

    public DeletionOptions ToDeletionOptions() => new()
    {
        Mode = SelectedMode,
        BatchSize = IsBatchMode ? BatchSize : DeletionOptions.DefaultBatchSize,
        UseTransaction = UseTransaction
    };
}
