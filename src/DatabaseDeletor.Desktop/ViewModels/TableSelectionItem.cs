using CommunityToolkit.Mvvm.ComponentModel;
using DatabaseDeletor.Domain.Entities;

namespace DatabaseDeletor.Desktop.ViewModels;

public sealed partial class TableSelectionItem : ObservableObject
{
    [ObservableProperty]
    private bool _isSelected;

    public TableInfo Table { get; }
    public string FullName => Table.FullName;
    public bool IsGloballyExcluded { get; }

    public TableSelectionItem(TableInfo table, bool isSelected = false, bool isGloballyExcluded = false)
    {
        Table = table;
        IsGloballyExcluded = isGloballyExcluded;
        _isSelected = isGloballyExcluded ? false : isSelected;
    }
}
