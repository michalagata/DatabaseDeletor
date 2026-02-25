using System.IO;
using Avalonia.Controls;
using Avalonia.Interactivity;

namespace DatabaseDeletor.Desktop.Views;

public partial class AboutWindow : Window
{
    public AboutWindow()
    {
        InitializeComponent();

        var versionFile = Path.Combine(AppContext.BaseDirectory, "version.txt");
        var version = File.Exists(versionFile) ? File.ReadAllText(versionFile).Trim() : "unknown";
        VersionText.Text = $"Version {version}";
    }

    private void OnDocumentationClick(object? sender, RoutedEventArgs e)
    {
        var docWindow = new DocumentationWindow { WindowStartupLocation = WindowStartupLocation.CenterOwner };
        docWindow.Show(this);
    }

    private void OnCloseClick(object? sender, RoutedEventArgs e)
    {
        Close();
    }
}
