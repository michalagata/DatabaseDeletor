using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using DatabaseDeletor.Domain.Entities;

namespace DatabaseDeletor.Desktop.ViewModels;

public sealed partial class ConditionsStepViewModel : ViewModelBase
{
    [ObservableProperty]
    private TableInfo? _selectedReferenceTable;

    [ObservableProperty]
    private string _whereClause = string.Empty;

    [ObservableProperty]
    private bool _deleteAll = true;

    public ObservableCollection<TableInfo> AvailableTables { get; } = [];

    public void LoadTables(DependencyGraph graph)
    {
        ArgumentNullException.ThrowIfNull(graph);
        AvailableTables.Clear();
        foreach (var table in graph.Tables)
        {
            AvailableTables.Add(table);
        }

        SelectedReferenceTable = AvailableTables.FirstOrDefault();
    }

    partial void OnDeleteAllChanged(bool value)
    {
        if (value)
            WhereClause = string.Empty;
    }
}
