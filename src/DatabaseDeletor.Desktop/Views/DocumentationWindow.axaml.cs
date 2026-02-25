using System.IO;
using Avalonia.Controls;
using Avalonia.Interactivity;
using Serilog;

namespace DatabaseDeletor.Desktop.Views;

public partial class DocumentationWindow : Window
{
    public DocumentationWindow()
    {
        InitializeComponent();
        LoadReadme();
    }

    private void LoadReadme()
    {
        var readmePath = Path.Combine(AppContext.BaseDirectory, "README.md");

        if (File.Exists(readmePath))
        {
            MarkdownViewer.Markdown = File.ReadAllText(readmePath);
        }
        else
        {
            Log.Warning("README.md not found at {Path}", readmePath);
            MarkdownViewer.Markdown = "*Documentation file (README.md) not found.*";
        }
    }

    private void OnCloseClick(object? sender, RoutedEventArgs e)
    {
        Close();
    }
}
