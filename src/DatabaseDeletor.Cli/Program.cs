using System.CommandLine;
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
        outputTemplate: "{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} [{Level:u3}] {Message:lj}{NewLine}{Exception}")
    .Enrich.WithThreadId()
    .Enrich.WithEnvironmentName()
    .CreateLogger();

try
{
    var rootCommand = new RootCommand("DatabaseDeletor - Mass database deletion tool with dependency analysis");

    var connectionStringOption = new Option<string>(
        aliases: ["--connection-string", "-c"],
        description: "Full database connection string")
    { IsRequired = true };

    var sqlOption = new Option<string>(
        aliases: ["--sql", "-s"],
        description: "SQL query targeting the table (DELETE FROM or SELECT FROM)")
    { IsRequired = true };

    var noConfirmOption = new Option<bool>(
        aliases: ["--no-confirm", "-y"],
        description: "Skip confirmation prompt and execute immediately");

    var batchSizeOption = new Option<int>(
        aliases: ["--batch-size", "-b"],
        description: "Batch size for bulk deletion operations",
        getDefaultValue: () => 10000);

    var verboseOption = new Option<bool>(
        aliases: ["--verbose", "-v"],
        description: "Enable verbose logging output");

    rootCommand.AddOption(connectionStringOption);
    rootCommand.AddOption(sqlOption);
    rootCommand.AddOption(noConfirmOption);
    rootCommand.AddOption(batchSizeOption);
    rootCommand.AddOption(verboseOption);

    rootCommand.SetHandler(async (context) =>
    {
        var connectionString = context.ParseResult.GetValueForOption(connectionStringOption)!;
        var sql = context.ParseResult.GetValueForOption(sqlOption)!;
        var noConfirm = context.ParseResult.GetValueForOption(noConfirmOption);
        var verbose = context.ParseResult.GetValueForOption(verboseOption);
        var ct = context.GetCancellationToken();

        if (verbose)
        {
            Log.Logger = new LoggerConfiguration()
                .MinimumLevel.Debug()
                .WriteTo.Console(outputTemplate: "{Timestamp:HH:mm:ss.fff} [{Level:u3}] {Message:lj}{NewLine}{Exception}")
                .WriteTo.File("logs/database-deletor-.log",
                    rollingInterval: RollingInterval.Day,
                    outputTemplate: "{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} [{Level:u3}] {Message:lj}{NewLine}{Exception}")
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
            await deletionService.RunAsync(connectionString, sql, noConfirm, ct);
        }
        catch (OperationCanceledException)
        {
            ConsoleRenderer.WriteError("Operation cancelled by user.");
            context.ExitCode = 1;
        }
        catch (Exception ex)
        {
            Log.Error(ex, "Fatal error during deletion operation");
            ConsoleRenderer.WriteError($"Error: {ex.Message}");
            context.ExitCode = 1;
        }
    });

    return await rootCommand.InvokeAsync(args);
}
catch (Exception ex)
{
    Log.Fatal(ex, "Application terminated unexpectedly");
    return 1;
}
finally
{
    await Log.CloseAndFlushAsync();
}
