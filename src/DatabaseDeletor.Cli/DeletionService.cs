using DatabaseDeletor.Application.Commands;
using DatabaseDeletor.Application.Helpers;
using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Interfaces;
using Microsoft.Extensions.DependencyInjection;
using Serilog;

namespace DatabaseDeletor.Cli;

internal sealed class DeletionService
{
    private readonly IServiceProvider _services;

    public DeletionService(IServiceProvider services)
    {
        _services = services;
    }

    public async Task RunAsync(
        string connectionString,
        string sql,
        bool skipConfirmation,
        string[] excludedTableNames,
        IReadOnlyList<TableInfo> globalExcludedTables,
        CancellationToken ct)
    {
        var mediator = _services.GetRequiredService<IMediator>();
        var sqlParser = _services.GetRequiredService<ISqlParser>();

        ConsoleRenderer.WriteHeader();

        // Report global exclusions (from appsettings.json)
        if (globalExcludedTables.Count > 0)
            ConsoleRenderer.WriteGlobalExcludedTables(globalExcludedTables);

        // Step 1: Parse SQL
        ConsoleRenderer.WriteStep(1, "Parsing SQL query...");
        var parsed = sqlParser.Parse(sql);
        ConsoleRenderer.WriteInfo($"Target table: {parsed.Schema}.{parsed.TableName}");
        if (parsed.WhereClause is not null)
            ConsoleRenderer.WriteInfo($"WHERE clause: {parsed.WhereClause}");
        else
            ConsoleRenderer.WriteWarning("No WHERE clause — ALL rows will be targeted for deletion.");

        // Parse CLI-provided exclusions (now supports comma-separated)
        var cliExcludedTables = TableNameParser.Parse(excludedTableNames);
        if (cliExcludedTables.Count > 0)
            ConsoleRenderer.WriteExcludedTables(cliExcludedTables);

        // Merge global + CLI exclusions (deduplicated)
        var allExcludedTables = globalExcludedTables
            .Concat(cliExcludedTables)
            .Distinct()
            .ToList();

        // Step 2: Analyze dependencies
        ConsoleRenderer.WriteStep(2, "Analyzing table dependencies...");
        var graph = await mediator.SendAsync(
            new AnalyzeDependenciesCommand(connectionString, parsed.Schema, parsed.TableName), ct).ConfigureAwait(false);

        ConsoleRenderer.WriteInfo($"Found {graph.Tables.Count} related table(s).");

        // Step 2.5: Validate exclusions (if any)
        if (allExcludedTables.Count > 0)
        {
            ConsoleRenderer.WriteStep(3, "Validating table exclusions...");
            var selectedTables = graph.Tables.Where(t => !allExcludedTables.Contains(t)).ToList();
            var exclusionResult = await mediator.SendAsync(
                new ValidateExclusionsCommand(connectionString, selectedTables, allExcludedTables), ct).ConfigureAwait(false);

            if (!exclusionResult.IsValid)
            {
                ConsoleRenderer.WriteExclusionConflictReport(exclusionResult);
                return;
            }

            ConsoleRenderer.WriteInfo("Exclusion validation passed — no FK conflicts.");
            graph = graph.FilterExcludedTables(allExcludedTables);
            ConsoleRenderer.WriteInfo($"Filtered graph: {graph.Tables.Count} table(s) remaining after exclusions.");
        }

        // Step 3: Generate deletion plan
        var planStep = allExcludedTables.Count > 0 ? 4 : 3;
        ConsoleRenderer.WriteStep(planStep, "Generating deletion plan...");
        var rootTable = graph.Tables.First(t =>
            string.Equals(t.Schema, parsed.Schema, StringComparison.OrdinalIgnoreCase) &&
            string.Equals(t.Name, parsed.TableName, StringComparison.OrdinalIgnoreCase));

        var plan = await mediator.SendAsync(
            new GenerateDeletionPlanCommand(connectionString, graph, rootTable, parsed.WhereClause), ct).ConfigureAwait(false);

        // Step 4: Display plan and confirm
        ConsoleRenderer.WriteDeletionPlan(plan);

        if (!skipConfirmation)
        {
            ConsoleRenderer.WriteStep(planStep + 1, "Awaiting confirmation...");
            if (!ConsoleRenderer.ConfirmDeletion())
            {
                ConsoleRenderer.WriteWarning("Deletion cancelled by user.");
                Log.Information("Deletion cancelled by user confirmation");
                return;
            }
        }

        // Step 5: Execute deletion with progress bar
        ConsoleRenderer.WriteStep(planStep + 2, "Executing deletion...");
        var report = await ConsoleRenderer.ExecuteWithProgressBar(async progress =>
        {
            return await mediator.SendAsync(
                new ExecuteDeletionCommand(connectionString, plan, progress), ct).ConfigureAwait(false);
        }, plan.TotalEstimatedRows).ConfigureAwait(false);

        // Step 6: Display report
        ConsoleRenderer.WriteStep(planStep + 3, "Generating report...");
        ConsoleRenderer.WriteDeletionReport(report);

        Log.Information("Deletion completed. Total deleted: {Count} rows in {Duration}",
            report.TotalDeletedRows, report.TotalDuration);
    }
}
