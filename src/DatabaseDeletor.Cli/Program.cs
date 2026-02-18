using System.CommandLine;
using System.Globalization;
using DatabaseDeletor.Application;
using DatabaseDeletor.Cli;
using DatabaseDeletor.Infrastructure;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Serilog;

Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()
    .WriteTo.File("logs/database-deletor-.log",
        rollingInterval: RollingInterval.Day,
        outputTemplate: "{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} [{Level:u3}] {Message:lj}{NewLine}{Exception}",
        formatProvider: CultureInfo.InvariantCulture)
    .Enrich.WithThreadId()
    .Enrich.WithEnvironmentName()
    .CreateLogger();

#pragma warning disable CA1031 // Last-resort exception handler for application entry point
try
{
    var connectionStringOption = new Option<string>("--connection-string", "-c")
    {
        Description = "Full database connection string",
        Required = true
    };

    var sqlOption = new Option<string>("--sql", "-s")
    {
        Description = "SQL query targeting the table (DELETE FROM or SELECT FROM)",
        Required = true
    };

    var noConfirmOption = new Option<bool>("--no-confirm", "-y")
    {
        Description = "Skip confirmation prompt and execute immediately"
    };

    var batchSizeOption = new Option<int>("--batch-size", "-b")
    {
        Description = "Batch size for bulk deletion operations",
        DefaultValueFactory = _ => 10000
    };

    var verboseOption = new Option<bool>("--verbose", "-v")
    {
        Description = "Enable verbose logging output"
    };

    var rootCommand = new RootCommand("DatabaseDeletor - Mass database deletion tool with dependency analysis");
    rootCommand.Add(connectionStringOption);
    rootCommand.Add(sqlOption);
    rootCommand.Add(noConfirmOption);
    rootCommand.Add(batchSizeOption);
    rootCommand.Add(verboseOption);

    rootCommand.SetAction(async (ParseResult result, CancellationToken ct) =>
    {
        var connectionString = result.GetRequiredValue(connectionStringOption);
        var sql = result.GetRequiredValue(sqlOption);
        var noConfirm = result.GetValue(noConfirmOption);
        var verbose = result.GetValue(verboseOption);

        if (verbose)
        {
            Log.Logger = new LoggerConfiguration()
                .MinimumLevel.Debug()
                .WriteTo.Console(
                    outputTemplate: "{Timestamp:HH:mm:ss.fff} [{Level:u3}] {Message:lj}{NewLine}{Exception}",
                    formatProvider: CultureInfo.InvariantCulture)
                .WriteTo.File("logs/database-deletor-.log",
                    rollingInterval: RollingInterval.Day,
                    outputTemplate: "{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} [{Level:u3}] {Message:lj}{NewLine}{Exception}",
                    formatProvider: CultureInfo.InvariantCulture)
                .Enrich.WithThreadId()
                .Enrich.WithEnvironmentName()
                .CreateLogger();
        }

        var host = Host.CreateDefaultBuilder()
            .UseSerilog()
            .ConfigureServices(services =>
            {
                services.AddApplication();
                services.AddInfrastructure();
            })
            .Build();

        var deletionService = new DeletionService(host.Services);

        try
        {
            await deletionService.RunAsync(connectionString, sql, noConfirm, ct).ConfigureAwait(false);
        }
        catch (OperationCanceledException)
        {
            ConsoleRenderer.WriteError("Operation cancelled by user.");
        }
    });

    var config = new CommandLineConfiguration(rootCommand);
    return await config.InvokeAsync(args).ConfigureAwait(false);
}
catch (Exception ex)
{
    Log.Fatal(ex, "Application terminated unexpectedly");
    return 1;
}
#pragma warning restore CA1031
finally
{
    await Log.CloseAndFlushAsync().ConfigureAwait(false);
}
