using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using DatabaseDeletor.Application.Commands;
using DatabaseDeletor.Application.Configuration;
using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Interfaces;
using Microsoft.Extensions.Options;

namespace DatabaseDeletor.Desktop.ViewModels;

public sealed partial class ConnectionStepViewModel : ViewModelBase
{
    private readonly IMediator _mediator;
    private readonly IReadOnlyList<TableInfo> _globalExcludedTables;

    [ObservableProperty]
    [NotifyCanExecuteChangedFor(nameof(ConnectCommand))]
    private string _connectionString = string.Empty;

    [ObservableProperty]
    private bool _isConnecting;

    [ObservableProperty]
    private string? _errorMessage;

    [ObservableProperty]
    private bool _isConnected;

    public ObservableCollection<TableSelectionItem> Tables { get; } = [];

    public ConnectionStepViewModel(IMediator mediator, IOptions<ExclusionOptions> exclusionOptions)
    {
        ArgumentNullException.ThrowIfNull(exclusionOptions);
        _mediator = mediator;
        _globalExcludedTables = exclusionOptions.Value.GetParsedTables();
    }

    private bool CanConnect() => !string.IsNullOrWhiteSpace(ConnectionString) && !IsConnecting;

    [RelayCommand(CanExecute = nameof(CanConnect))]
    private async Task ConnectAsync(CancellationToken ct)
    {
        IsConnecting = true;
        ErrorMessage = null;
        Tables.Clear();
        IsConnected = false;

        try
        {
            var tables = await _mediator.SendAsync(
                new GetAllTablesCommand(ConnectionString), ct).ConfigureAwait(true);

            foreach (var table in tables)
            {
                var isGlobal = _globalExcludedTables.Contains(table);
                Tables.Add(new TableSelectionItem(table, isSelected: !isGlobal, isGloballyExcluded: isGlobal));
            }

            IsConnected = true;
        }
#pragma warning disable CA1031 // UI error handler: catch-all is intentional
        catch (Exception ex)
        {
            ErrorMessage = $"Connection failed: {ex.Message}";
        }
#pragma warning restore CA1031
        finally
        {
            IsConnecting = false;
        }
    }

    [RelayCommand]
    private void SelectAll()
    {
        foreach (var item in Tables)
        {
            if (!item.IsGloballyExcluded)
                item.IsSelected = true;
        }
    }

    [RelayCommand]
    private void DeselectAll()
    {
        foreach (var item in Tables)
        {
            if (!item.IsGloballyExcluded)
                item.IsSelected = false;
        }
    }

    public IReadOnlyList<TableInfo> GetSelectedTables() =>
        Tables.Where(t => t.IsSelected).Select(t => t.Table).ToList();

    public IReadOnlyList<TableInfo> GetExcludedTables() =>
        Tables.Where(t => !t.IsSelected).Select(t => t.Table).ToList();
}
