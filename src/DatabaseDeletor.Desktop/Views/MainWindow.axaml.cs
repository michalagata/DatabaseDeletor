using Avalonia.Controls;
using Avalonia.Interactivity;
using Avalonia.Platform.Storage;
using DatabaseDeletor.Application.Services;
using DatabaseDeletor.Desktop.ViewModels;
using Microsoft.Extensions.DependencyInjection;
using Serilog;

namespace DatabaseDeletor.Desktop.Views;

public partial class MainWindow : Window
{
    private static readonly FilePickerFileType JsonFileType = new("JSON Files")
    {
        Patterns = ["*.json"],
        MimeTypes = ["application/json"]
    };

    public MainWindow()
    {
        InitializeComponent();
    }

    private void OnHelpClick(object? sender, RoutedEventArgs e)
    {
        var aboutWindow = new AboutWindow { WindowStartupLocation = WindowStartupLocation.CenterOwner };
        aboutWindow.Show(this);
    }

#pragma warning disable CA1031 // UI error handler: catch-all is intentional
    private async void OnExportClick(object? sender, RoutedEventArgs e)
    {
        try
        {
            var file = await StorageProvider.SaveFilePickerAsync(new FilePickerSaveOptions
            {
                Title = "Export Configuration",
                DefaultExtension = "json",
                FileTypeChoices = [JsonFileType],
                SuggestedFileName = "DatabaseDeletor-config.json"
            }).ConfigureAwait(true);

            if (file is null) return;

            var vm = DataContext as MainWindowViewModel;
            if (vm is null) return;

            var profile = vm.ExportProfile();
            var profileService = App.Services.GetRequiredService<IConfigurationProfileService>();
            var path = file.Path.LocalPath;

            await profileService.ExportToFileAsync(profile, path).ConfigureAwait(true);
            Log.Information("Configuration exported to {Path}", path);
        }
        catch (Exception ex)
        {
            Log.Error(ex, "Failed to export configuration");
        }
    }

    private async void OnImportClick(object? sender, RoutedEventArgs e)
    {
        try
        {
            var files = await StorageProvider.OpenFilePickerAsync(new FilePickerOpenOptions
            {
                Title = "Import Configuration",
                AllowMultiple = false,
                FileTypeFilter = [JsonFileType]
            }).ConfigureAwait(true);

            if (files.Count == 0) return;

            var vm = DataContext as MainWindowViewModel;
            if (vm is null) return;

            var profileService = App.Services.GetRequiredService<IConfigurationProfileService>();
            var path = files[0].Path.LocalPath;
            var profile = await profileService.ImportFromFileAsync(path).ConfigureAwait(true);

            vm.ImportProfile(profile);
            Log.Information("Configuration imported from {Path}", path);
        }
        catch (Exception ex)
        {
            Log.Error(ex, "Failed to import configuration");
        }
    }
#pragma warning restore CA1031
}
