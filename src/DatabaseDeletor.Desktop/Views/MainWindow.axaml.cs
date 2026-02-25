using Avalonia.Controls;
using Avalonia.Interactivity;

namespace DatabaseDeletor.Desktop.Views;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
    }

    private void OnHelpClick(object? sender, RoutedEventArgs e)
    {
        var aboutWindow = new AboutWindow { WindowStartupLocation = WindowStartupLocation.CenterOwner };
        aboutWindow.Show(this);
    }
}
