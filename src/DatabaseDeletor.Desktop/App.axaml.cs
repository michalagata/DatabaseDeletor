using System.Globalization;
using System.IO;
using Avalonia;
using Avalonia.Controls.ApplicationLifetimes;
using Avalonia.Markup.Xaml;
using DatabaseDeletor.Application;
using DatabaseDeletor.Application.Configuration;
using DatabaseDeletor.Desktop.ViewModels;
using DatabaseDeletor.Desktop.Views;
using DatabaseDeletor.Infrastructure;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Serilog;

namespace DatabaseDeletor.Desktop;

public partial class App : Avalonia.Application
{
    public static IServiceProvider Services { get; private set; } = null!;

    public override void Initialize()
    {
        AvaloniaXamlLoader.Load(this);

        Log.Logger = new LoggerConfiguration()
            .MinimumLevel.Information()
            .WriteTo.File(Path.Combine(AppContext.BaseDirectory, "logs", "database-deletor-desktop-.log"),
                rollingInterval: RollingInterval.Day,
                outputTemplate: "{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} [{Level:u3}] {Message:lj}{NewLine}{Exception}",
                formatProvider: CultureInfo.InvariantCulture)
            .Enrich.WithThreadId()
            .Enrich.WithEnvironmentName()
            .CreateLogger();

        var configuration = new ConfigurationBuilder()
            .SetBasePath(AppContext.BaseDirectory)
            .AddJsonFile("appsettings.json", optional: true, reloadOnChange: false)
            .Build();

        var serviceCollection = new ServiceCollection();
        serviceCollection.AddSingleton<IConfiguration>(configuration);
        serviceCollection.Configure<ExclusionOptions>(configuration.GetSection(ExclusionOptions.SectionName));
        serviceCollection.AddApplication();
        serviceCollection.AddInfrastructure();
        serviceCollection.AddLogging(builder => builder.AddSerilog());
        serviceCollection.AddTransient<MainWindowViewModel>();
        serviceCollection.AddTransient<ConnectionStepViewModel>();
        serviceCollection.AddTransient<AnalysisStepViewModel>();
        serviceCollection.AddTransient<ConditionsStepViewModel>();
        serviceCollection.AddTransient<SummaryStepViewModel>();
        serviceCollection.AddTransient<ExecutionStepViewModel>();
        Services = serviceCollection.BuildServiceProvider();
    }

    public override void OnFrameworkInitializationCompleted()
    {
        if (ApplicationLifetime is IClassicDesktopStyleApplicationLifetime desktop)
        {
            desktop.ShutdownRequested += (_, _) => Log.CloseAndFlush();

            desktop.MainWindow = new MainWindow
            {
                DataContext = Services.GetRequiredService<MainWindowViewModel>()
            };
        }

        base.OnFrameworkInitializationCompleted();
    }
}
