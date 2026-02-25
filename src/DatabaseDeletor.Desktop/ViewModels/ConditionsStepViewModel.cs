using System.Collections.ObjectModel;
using System.Text;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using DatabaseDeletor.Application.Commands;
using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Interfaces;

namespace DatabaseDeletor.Desktop.ViewModels;

public sealed partial class ConditionsStepViewModel : ViewModelBase
{
    private readonly IMediator _mediator;
    private readonly ISqlParser _sqlParser;
    private string _connectionString = string.Empty;

    [ObservableProperty]
    private TableInfo? _selectedReferenceTable;

    [ObservableProperty]
    private DeletionScopeMode _scopeMode = DeletionScopeMode.DeleteAll;

    [ObservableProperty]
    private string _customSqlQuery = string.Empty;

    [ObservableProperty]
    private string? _customSqlError;

    [ObservableProperty]
    private string _whereClausePreview = string.Empty;

    [ObservableProperty]
    private bool _isLoadingColumns;

    public ObservableCollection<TableInfo> AvailableTables { get; } = [];
    public ObservableCollection<ColumnInfo> AvailableColumns { get; } = [];
    public ObservableCollection<WhereConditionViewModel> Conditions { get; } = [];

    public ConditionsStepViewModel(IMediator mediator, ISqlParser sqlParser)
    {
        _mediator = mediator;
        _sqlParser = sqlParser;
    }

    public void LoadTables(IReadOnlyList<TableInfo> selectedTables, string connectionString)
    {
        ArgumentNullException.ThrowIfNull(selectedTables);
        _connectionString = connectionString;
        AvailableTables.Clear();
        foreach (var table in selectedTables)
        {
            AvailableTables.Add(table);
        }

        SelectedReferenceTable ??= AvailableTables.FirstOrDefault();
    }

    partial void OnSelectedReferenceTableChanged(TableInfo? value)
    {
        if (value is not null && !string.IsNullOrEmpty(_connectionString))
        {
            _ = LoadColumnsAsync(value);
        }
    }

    partial void OnScopeModeChanged(DeletionScopeMode value)
    {
        if (value == DeletionScopeMode.DeleteAll)
        {
            WhereClausePreview = string.Empty;
            CustomSqlError = null;
        }
        else if (value == DeletionScopeMode.WhereCondition)
        {
            UpdateWhereClausePreview();
        }
    }

    private async Task LoadColumnsAsync(TableInfo table)
    {
        IsLoadingColumns = true;
        AvailableColumns.Clear();

        try
        {
            var columns = await _mediator.SendAsync(
                new GetColumnsCommand(_connectionString, table.Schema, table.Name)).ConfigureAwait(true);

            foreach (var col in columns)
            {
                AvailableColumns.Add(col);
            }

            foreach (var condition in Conditions)
            {
                condition.AvailableColumns.Clear();
                foreach (var col in columns)
                    condition.AvailableColumns.Add(col);
            }
        }
#pragma warning disable CA1031 // UI error handler: catch-all is intentional
        catch
        {
            // Column loading is non-critical; user can still use CustomSql mode
        }
#pragma warning restore CA1031
        finally
        {
            IsLoadingColumns = false;
        }
    }

    [RelayCommand]
    private void AddCondition()
    {
        var condition = new WhereConditionViewModel();
        foreach (var col in AvailableColumns)
            condition.AvailableColumns.Add(col);

        condition.PropertyChanged += (_, _) => UpdateWhereClausePreview();
        Conditions.Add(condition);
        UpdateWhereClausePreview();
    }

    [RelayCommand]
    private void RemoveCondition(WhereConditionViewModel? condition)
    {
        if (condition is not null)
        {
            Conditions.Remove(condition);
            UpdateWhereClausePreview();
        }
    }

    private void UpdateWhereClausePreview()
    {
        if (Conditions.Count == 0)
        {
            WhereClausePreview = string.Empty;
            return;
        }

        var sb = new StringBuilder();
        for (int i = 0; i < Conditions.Count; i++)
        {
            var fragment = Conditions[i].ToSqlFragment();
            if (string.IsNullOrEmpty(fragment))
                continue;

            if (sb.Length > 0)
                sb.Append(' ').Append(Conditions[i].LogicalOperator).Append(' ');

            sb.Append(fragment);
        }

        WhereClausePreview = sb.ToString();
    }

    public string? WhereClause
    {
        get
        {
            return ScopeMode switch
            {
                DeletionScopeMode.DeleteAll => null,
                DeletionScopeMode.WhereCondition => string.IsNullOrWhiteSpace(WhereClausePreview) ? null : WhereClausePreview,
                DeletionScopeMode.CustomSql => ExtractWhereFromCustomSql(),
                _ => null
            };
        }
    }

    public TableInfo? EffectiveRootTable
    {
        get
        {
            if (ScopeMode != DeletionScopeMode.CustomSql)
                return SelectedReferenceTable;

            if (string.IsNullOrWhiteSpace(CustomSqlQuery))
                return SelectedReferenceTable;

            try
            {
                var parsed = _sqlParser.Parse(CustomSqlQuery);
                var match = AvailableTables.FirstOrDefault(t =>
                    string.Equals(t.Schema, parsed.Schema, StringComparison.OrdinalIgnoreCase)
                    && string.Equals(t.Name, parsed.TableName, StringComparison.OrdinalIgnoreCase));
                return match ?? SelectedReferenceTable;
            }
#pragma warning disable CA1031 // UI error handler: catch-all is intentional
            catch
            {
                return SelectedReferenceTable;
            }
#pragma warning restore CA1031
        }
    }

    private string? ExtractWhereFromCustomSql()
    {
        if (string.IsNullOrWhiteSpace(CustomSqlQuery))
            return null;

        try
        {
            var parsed = _sqlParser.Parse(CustomSqlQuery);
            CustomSqlError = null;
            return parsed.WhereClause;
        }
#pragma warning disable CA1031 // UI error handler: catch-all is intentional
        catch (Exception ex)
        {
            CustomSqlError = ex.Message;
            return null;
        }
#pragma warning restore CA1031
    }
}
