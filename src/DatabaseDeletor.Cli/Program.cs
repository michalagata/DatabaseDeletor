using System.CommandLine;
using System.Globalization;
using DatabaseDeletor.Application;
using DatabaseDeletor.Application.Configuration;
using DatabaseDeletor.Application.Services;
using DatabaseDeletor.Cli;
using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Enums;
using DatabaseDeletor.Infrastructure;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;
using Serilog;

Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()
    .WriteTo.File(Path.Combine(AppContext.BaseDirectory, "logs", "database-deletor-.log"),
        rollingInterval: RollingInterval.Day,
        outputTemplate: "{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} [{Level:u3}] {Message:lj}{NewLine}{Exception}",
        formatProvider: CultureInfo.InvariantCulture)
    .Enrich.WithThreadId()
    .Enrich.WithEnvironmentName()
    .CreateLogger();

#pragma warning disable CA1303 // Startup banner — no localization needed
Console.WriteLine("DatabaseDeletor CLI");
Console.WriteLine("(c) 2026 Michael Agata, Anubisworks. All Rights Reserved!");
Console.WriteLine();
#pragma warning restore CA1303

#pragma warning disable CA1031 // Last-resort exception handler for application entry point
try
{
    var connectionStringOption = new Option<string>("--connection-string", "-c")
    {
        Description = "Full database connection string"
    };

    var sqlOption = new Option<string>("--sql", "-s")
    {
        Description = "SQL query targeting the table (DELETE FROM or SELECT FROM)"
    };

    var noConfirmOption = new Option<bool>("--no-confirm", "-y")
    {
        Description = "Skip confirmation prompt and execute immediately"
    };

    var batchSizeOption = new Option<int>("--batch-size", "-b")
    {
        Description = "Batch size for bulk deletion (100-1000000, default: 10000, only for BatchDelete mode)",
        DefaultValueFactory = _ => DeletionOptions.DefaultBatchSize
    };

    var deletionModeOption = new Option<DeletionMode>("--deletion-mode", "-m")
    {
        Description = "Deletion mode: BatchDelete, SingleRowDelete, or DirectDelete (default: BatchDelete)",
        DefaultValueFactory = _ => DeletionMode.BatchDelete
    };

    var useTransactionOption = new Option<bool>("--use-transaction", "-t")
    {
        Description = "Wrap entire deletion in a single transaction (default: false)"
    };

    var excludeTablesOption = new Option<string[]>("--exclude-tables", "-e")
    {
        Description = "Tables to exclude from deletion (schema.table format, comma-separated or multiple flags)"
    };

    var verboseOption = new Option<bool>("--verbose", "-v")
    {
        Description = "Enable verbose logging output"
    };

    var configOption = new Option<string>("--config")
    {
        Description = "Path to JSON configuration file to load (overrides --connection-string, --sql, --exclude-tables, --deletion-mode, --batch-size, --use-transaction)"
    };

    var exportConfigOption = new Option<string>("--export-config")
    {
        Description = "Path to save current configuration as JSON (exports config and exits, no deletion)"
    };

    var rootCommand = new RootCommand("DatabaseDeletor - Mass database deletion tool with dependency analysis");
    rootCommand.Add(connectionStringOption);
    rootCommand.Add(sqlOption);
    rootCommand.Add(noConfirmOption);
    rootCommand.Add(batchSizeOption);
    rootCommand.Add(deletionModeOption);
    rootCommand.Add(useTransactionOption);
    rootCommand.Add(excludeTablesOption);
    rootCommand.Add(verboseOption);
    rootCommand.Add(configOption);
    rootCommand.Add(exportConfigOption);

    rootCommand.SetAction(async (ParseResult result, CancellationToken ct) =>
    {
        var configPath = result.GetValue(configOption);
        var exportConfigPath = result.GetValue(exportConfigOption);
        var verbose = result.GetValue(verboseOption);

        if (verbose)
        {
            Log.Logger = new LoggerConfiguration()
                .MinimumLevel.Debug()
                .WriteTo.Console(
                    outputTemplate: "{Timestamp:HH:mm:ss.fff} [{Level:u3}] {Message:lj}{NewLine}{Exception}",
                    formatProvider: CultureInfo.InvariantCulture)
                .WriteTo.File(Path.Combine(AppContext.BaseDirectory, "logs", "database-deletor-.log"),
                    rollingInterval: RollingInterval.Day,
                    outputTemplate: "{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} [{Level:u3}] {Message:lj}{NewLine}{Exception}",
                    formatProvider: CultureInfo.InvariantCulture)
                .Enrich.WithThreadId()
                .Enrich.WithEnvironmentName()
                .CreateLogger();
        }

        var host = Host.CreateDefaultBuilder()
            .UseSerilog()
            .ConfigureServices((ctx, services) =>
            {
                services.AddApplication();
                services.AddInfrastructure();
                services.Configure<ExclusionOptions>(ctx.Configuration.GetSection(ExclusionOptions.SectionName));
            })
            .Build();

        var profileService = host.Services.GetRequiredService<IConfigurationProfileService>();

        // Load config from JSON file if --config is specified
        string connectionString;
        string sql;
        string[] excludeTables;
        DeletionMode deletionMode;
        int batchSize;
        bool useTransaction;

        if (!string.IsNullOrEmpty(configPath))
        {
            DeletionProfile profile;
            try
            {
                profile = await profileService.ImportFromFileAsync(configPath, ct).ConfigureAwait(false);
            }
            catch (Exception ex) when (ex is FileNotFoundException or InvalidOperationException)
            {
                ConsoleRenderer.WriteError($"Failed to load config: {ex.Message}");
                return;
            }

            ConsoleRenderer.WriteConfigLoaded(configPath);

            // Config values as base; CLI --connection-string, --sql, --exclude-tables override if provided
            connectionString = result.GetValue(connectionStringOption) ?? profile.ConnectionString;
            sql = result.GetValue(sqlOption) ?? profile.Sql ?? string.Empty;
            excludeTables = result.GetValue(excludeTablesOption) ?? profile.ExcludedTables.ToArray();

            // Deletion settings from config (use CLI --deletion-mode/--batch-size/--use-transaction to override
            // only when config is NOT used; when config IS used, config values take priority for settings)
            deletionMode = Enum.TryParse<DeletionMode>(profile.DeletionSettings.Mode, true, out var m) ? m : DeletionMode.BatchDelete;
            batchSize = profile.DeletionSettings.BatchSize;
            useTransaction = profile.DeletionSettings.UseTransaction;
        }
        else
        {
            connectionString = result.GetValue(connectionStringOption) ?? string.Empty;
            sql = result.GetValue(sqlOption) ?? string.Empty;
            excludeTables = result.GetValue(excludeTablesOption) ?? [];
            deletionMode = result.GetValue(deletionModeOption);
            batchSize = result.GetValue(batchSizeOption);
            useTransaction = result.GetValue(useTransactionOption);
        }

        // Handle --export-config: build profile from params and save
        if (!string.IsNullOrEmpty(exportConfigPath))
        {
            var exportProfile = new DeletionProfile
            {
                ConnectionString = connectionString,
                Sql = string.IsNullOrEmpty(sql) ? null : sql,
                ExcludedTables = excludeTables.Length > 0 ? excludeTables : [],
                DeletionSettings = new DeletionSettingsProfile
                {
                    Mode = deletionMode.ToString(),
                    BatchSize = batchSize,
                    UseTransaction = useTransaction
                }
            };

            try
            {
                await profileService.ExportToFileAsync(exportProfile, exportConfigPath, ct).ConfigureAwait(false);
                ConsoleRenderer.WriteConfigExported(exportConfigPath);
            }
            catch (Exception ex) when (ex is IOException or UnauthorizedAccessException)
            {
                ConsoleRenderer.WriteError($"Failed to export config: {ex.Message}");
            }

            return;
        }

        // Validate required params for deletion
        if (string.IsNullOrEmpty(connectionString))
        {
            ConsoleRenderer.WriteError("Connection string is required. Use --connection-string or --config.");
            return;
        }

        if (string.IsNullOrEmpty(sql))
        {
            ConsoleRenderer.WriteError("SQL query is required. Use --sql or --config.");
            return;
        }

        var noConfirm = result.GetValue(noConfirmOption);

        var deletionOptions = new DeletionOptions
        {
            Mode = deletionMode,
            BatchSize = batchSize,
            UseTransaction = useTransaction
        };

        if (!deletionOptions.IsValid)
        {
            ConsoleRenderer.WriteError(
                $"Invalid batch size: {batchSize}. Must be between {DeletionOptions.MinBatchSize} and {DeletionOptions.MaxBatchSize}.");
            return;
        }

        var exclusionOptions = host.Services.GetRequiredService<IOptions<ExclusionOptions>>();
        var globalExcludedTables = exclusionOptions.Value.GetParsedTables();

        var deletionService = new DeletionService(host.Services);

        try
        {
            await deletionService.RunAsync(connectionString, sql, noConfirm, excludeTables, globalExcludedTables, deletionOptions, ct).ConfigureAwait(false);
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
