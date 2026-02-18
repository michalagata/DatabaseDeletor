using DatabaseDeletor.Application.Commands;
using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Interfaces;
using Microsoft.Extensions.DependencyInjection;
using Serilog;

namespace DatabaseDeletor.Cli;

public sealed class DeletionService
{
    private readonly IServiceProvider _services;

    public DeletionService(IServiceProvider services)
    {
        _services = services;
    }

    public async Task RunAsync(string connectionString, string sql, bool skipConfirmation, CancellationToken ct)
    {
        var mediator = _services.GetRequiredService<IMediator>();
        var sqlParser = _services.GetRequiredService<ISqlParser>();

        ConsoleRenderer.WriteHeader();

        // Step 1: Parse SQL
        ConsoleRenderer.WriteStep(1, "Parsing SQL query...");
        var parsed = sqlParser.Parse(sql);
        ConsoleRenderer.WriteInfo($"Target table: {parsed.Schema}.{parsed.TableName}");
        if (parsed.WhereClause is not null)
            ConsoleRenderer.WriteInfo($"WHERE clause: {parsed.WhereClause}");
        else
            ConsoleRenderer.WriteWarning("No WHERE clause — ALL rows will be targeted for deletion.");

        // Step 2: Analyze dependencies
        ConsoleRenderer.WriteStep(2, "Analyzing table dependencies...");
        var graph = await mediator.SendAsync(
            new AnalyzeDependenciesCommand(connectionString, parsed.Schema, parsed.TableName), ct);

        ConsoleRenderer.WriteInfo($"Found {graph.Tables.Count} related table(s).");

        // Step 3: Generate deletion plan
        ConsoleRenderer.WriteStep(3, "Generating deletion plan...");
        var rootTable = graph.Tables.First(t =>
            string.Equals(t.Schema, parsed.Schema, StringComparison.OrdinalIgnoreCase) &&
            string.Equals(t.Name, parsed.TableName, StringComparison.OrdinalIgnoreCase));

        var plan = await mediator.SendAsync(
            new GenerateDeletionPlanCommand(connectionString, graph, rootTable, parsed.WhereClause), ct);

        // Step 4: Display plan and confirm
        ConsoleRenderer.WriteDeletionPlan(plan);

        if (!skipConfirmation)
        {
            ConsoleRenderer.WriteStep(4, "Awaiting confirmation...");
            if (!ConsoleRenderer.ConfirmDeletion())
            {
                ConsoleRenderer.WriteWarning("Deletion cancelled by user.");
                Log.Information("Deletion cancelled by user confirmation");
                return;
            }
        }

        // Step 5: Execute deletion with progress bar
        ConsoleRenderer.WriteStep(5, "Executing deletion...");
        var report = await ConsoleRenderer.ExecuteWithProgressBar(async progress =>
        {
            return await mediator.SendAsync(
                new ExecuteDeletionCommand(connectionString, plan, progress), ct);
        }, plan.TotalEstimatedRows);

        // Step 6: Display report
        ConsoleRenderer.WriteStep(6, "Generating report...");
        ConsoleRenderer.WriteDeletionReport(report);

        Log.Information("Deletion completed. Total deleted: {Count} rows in {Duration}",
            report.TotalDeletedRows, report.TotalDuration);
    }
}
