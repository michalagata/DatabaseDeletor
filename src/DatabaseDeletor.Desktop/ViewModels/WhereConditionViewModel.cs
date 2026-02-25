using System.Collections.ObjectModel;
using System.Globalization;
using CommunityToolkit.Mvvm.ComponentModel;
using DatabaseDeletor.Domain.Entities;

namespace DatabaseDeletor.Desktop.ViewModels;

public sealed partial class WhereConditionViewModel : ObservableObject
{
    [ObservableProperty]
    private ColumnInfo? _selectedColumn;

    [ObservableProperty]
    private string _selectedOperator = "=";

    [ObservableProperty]
    private string _value = string.Empty;

    [ObservableProperty]
    private string _logicalOperator = "AND";

    public ObservableCollection<ColumnInfo> AvailableColumns { get; } = [];

    public static IReadOnlyList<string> Operators { get; } =
    [
        "=", "!=", "<", ">", "<=", ">=", "LIKE", "NOT LIKE", "IN", "NOT IN", "IS NULL", "IS NOT NULL", "BETWEEN"
    ];

    public static IReadOnlyList<string> LogicalOperators { get; } = ["AND", "OR"];

    public bool IsUnaryOperator => SelectedOperator is "IS NULL" or "IS NOT NULL";

    partial void OnSelectedOperatorChanged(string value)
    {
        OnPropertyChanged(nameof(IsUnaryOperator));
    }

    public string ToSqlFragment()
    {
        if (SelectedColumn is null)
            return string.Empty;

        var column = SelectedColumn.Name;

        return SelectedOperator switch
        {
            "IS NULL" => string.Format(CultureInfo.InvariantCulture, "{0} IS NULL", column),
            "IS NOT NULL" => string.Format(CultureInfo.InvariantCulture, "{0} IS NOT NULL", column),
            "IN" or "NOT IN" => string.Format(CultureInfo.InvariantCulture, "{0} {1} ({2})", column, SelectedOperator, Value),
            "BETWEEN" => string.Format(CultureInfo.InvariantCulture, "{0} BETWEEN {1}", column, Value),
            _ => string.Format(CultureInfo.InvariantCulture, "{0} {1} {2}", column, SelectedOperator, Value)
        };
    }
}
