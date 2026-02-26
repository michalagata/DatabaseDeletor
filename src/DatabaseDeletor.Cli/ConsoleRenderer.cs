using System.Globalization;
using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Enums;
using Spectre.Console;

namespace DatabaseDeletor.Cli;

internal static class ConsoleRenderer
{
    public static void WriteHeader()
    {
        AnsiConsole.Write(new FigletText("DB Deletor")
            .Color(Color.Red)
            .Centered());

        AnsiConsole.MarkupLine("[grey]Mass database deletion tool with dependency analysis[/]");
        AnsiConsole.WriteLine();
    }

    public static void WriteDeletionSettings(DeletionOptions options)
    {
        ArgumentNullException.ThrowIfNull(options);

        AnsiConsole.Write(new Rule("[bold cyan]Deletion Settings[/]").RuleStyle("grey"));
        AnsiConsole.MarkupLine($"  [bold]Mode:[/] {Markup.Escape(FormatMode(options.Mode))}");

        if (options.Mode == DeletionMode.BatchDelete)
        {
            AnsiConsole.MarkupLine($"  [bold]Batch Size:[/] {options.BatchSize.ToString("N0", CultureInfo.InvariantCulture)}");
        }

        AnsiConsole.MarkupLine($"  [bold]Transaction:[/] {(options.UseTransaction ? "[yellow]Enabled[/]" : "Disabled")}");

        if (options.UseTransaction)
        {
            AnsiConsole.MarkupLine("  [yellow]![/] [yellow]Warning: large deletions with transactions may cause lock escalation and timeouts[/]");
        }

        AnsiConsole.WriteLine();
    }

    private static string FormatMode(DeletionMode mode) => mode switch
    {
        DeletionMode.BatchDelete => "Batch Delete (splits deletion into configurable batches)",
        DeletionMode.SingleRowDelete => "Single Row Delete (deletes one row at a time)",
        DeletionMode.DirectDelete => "Direct Delete (one SQL statement per table, no batching)",
        _ => mode.ToString()
    };

    public static void WriteStep(int step, string message)
    {
        AnsiConsole.MarkupLine($"[bold blue]Step {step}:[/] {message}");
    }

    public static void WriteInfo(string message)
    {
        AnsiConsole.MarkupLine($"  [green]>[/] {Markup.Escape(message)}");
    }

    public static void WriteWarning(string message)
    {
        AnsiConsole.MarkupLine($"  [yellow]![/] {Markup.Escape(message)}");
    }

    public static void WriteError(string message)
    {
        AnsiConsole.MarkupLine($"  [red]X[/] {Markup.Escape(message)}");
    }

    public static void WriteDeletionPlan(DeletionPlan plan)
    {
        ArgumentNullException.ThrowIfNull(plan);

        AnsiConsole.WriteLine();
        AnsiConsole.Write(new Rule("[bold yellow]Deletion Plan[/]").RuleStyle("grey"));

        var table = new Table()
            .Border(TableBorder.Rounded)
            .AddColumn(new TableColumn("[bold]#[/]").Centered())
            .AddColumn(new TableColumn("[bold]Table[/]"))
            .AddColumn(new TableColumn("[bold]Estimated Rows[/]").RightAligned())
            .AddColumn(new TableColumn("[bold]SQL[/]"));

        foreach (var step in plan.Steps)
        {
            var sqlPreview = step.DeleteSql.Length > 60
                ? step.DeleteSql[..57] + "..."
                : step.DeleteSql;

            table.AddRow(
                (step.Order + 1).ToString(CultureInfo.InvariantCulture),
                Markup.Escape(step.Table.FullName),
                step.EstimatedRowCount.ToString("N0", CultureInfo.InvariantCulture),
                Markup.Escape(sqlPreview));
        }

        AnsiConsole.Write(table);

        AnsiConsole.MarkupLine($"\n  [bold]Total estimated rows to delete:[/] [red]{plan.TotalEstimatedRows.ToString("N0", CultureInfo.InvariantCulture)}[/]");
        AnsiConsole.MarkupLine($"  [bold]Root table:[/] {Markup.Escape(plan.RootTable.FullName)}");
        AnsiConsole.MarkupLine($"  [bold]WHERE clause:[/] {Markup.Escape(plan.WhereClause ?? "(all rows)")}");
        AnsiConsole.WriteLine();
    }

    public static void WriteGlobalExcludedTables(IReadOnlyList<TableInfo> tables)
    {
        AnsiConsole.MarkupLine("[yellow]![/] [bold yellow]Globally excluded tables (via configuration):[/]");
        foreach (var table in tables)
        {
            AnsiConsole.MarkupLine($"    [yellow]-[/] {Markup.Escape(table.FullName)}");
        }
        AnsiConsole.WriteLine();
    }

    public static void WriteExcludedTables(IReadOnlyList<TableInfo> tables)
    {
        AnsiConsole.MarkupLine("  [yellow]![/] CLI-excluded tables:");
        foreach (var table in tables)
        {
            AnsiConsole.MarkupLine($"    [grey]-[/] {Markup.Escape(table.FullName)}");
        }
    }

    public static void WriteConfigLoaded(string path)
    {
        AnsiConsole.MarkupLine($"  [green]>[/] Configuration loaded from: {Markup.Escape(path)}");
    }

    public static void WriteConfigExported(string path)
    {
        AnsiConsole.MarkupLine($"  [green]>[/] Configuration exported to: {Markup.Escape(path)}");
    }

    public static void WriteExclusionConflictReport(ExclusionAnalysisResult result)
    {
        ArgumentNullException.ThrowIfNull(result);

        AnsiConsole.WriteLine();
        AnsiConsole.Write(new Rule("[bold red]Exclusion Conflicts Detected[/]").RuleStyle("red"));

        var table = new Table()
            .Border(TableBorder.Rounded)
            .AddColumn(new TableColumn("[bold]Excluded Table[/]"))
            .AddColumn(new TableColumn("[bold]Dependent Table[/]"))
            .AddColumn(new TableColumn("[bold]FK Constraint[/]"))
            .AddColumn(new TableColumn("[bold]Reason[/]"));

        foreach (var conflict in result.Conflicts)
        {
            table.AddRow(
                Markup.Escape(conflict.ExcludedTable.FullName),
                Markup.Escape(conflict.DependentTable.FullName),
                Markup.Escape(conflict.ForeignKey.ConstraintName),
                Markup.Escape(conflict.Reason));
        }

        AnsiConsole.Write(table);

        if (result.Recommendations.Count > 0)
        {
            AnsiConsole.WriteLine();
            AnsiConsole.MarkupLine("[bold yellow]Recommendations:[/]");
            foreach (var rec in result.Recommendations)
            {
                AnsiConsole.MarkupLine($"  [yellow]>[/] {Markup.Escape(rec)}");
            }
        }

        AnsiConsole.WriteLine();
        AnsiConsole.MarkupLine("[bold red]Cannot proceed with deletion due to FK conflicts. Resolve the conflicts above and retry.[/]");
        AnsiConsole.WriteLine();
    }

    public static bool ConfirmDeletion()
    {
        return AnsiConsole.Confirm(
            "[bold red]Are you sure you want to proceed with the deletion?[/]",
            defaultValue: false);
    }

    public static async Task<DeletionReport> ExecuteWithProgressBar(
        Func<IProgress<DeletionProgress>, Task<DeletionReport>> action,
        long totalEstimatedRows)
    {
        DeletionReport? report = null;

        await AnsiConsole.Progress()
            .AutoClear(false)
            .HideCompleted(false)
            .Columns(
                new TaskDescriptionColumn(),
                new ProgressBarColumn(),
                new PercentageColumn(),
                new RemainingTimeColumn(),
                new SpinnerColumn())
            .StartAsync(async ctx =>
            {
                var overallTask = ctx.AddTask("[green]Overall Progress[/]", maxValue: totalEstimatedRows > 0 ? totalEstimatedRows : 1);
                var currentStepTask = ctx.AddTask("[blue]Current Step[/]", maxValue: 100);

                var progress = new Progress<DeletionProgress>(p =>
                {
                    overallTask.Value = p.TotalDeletedRows;
                    overallTask.Description = $"[green]Overall: {p.CurrentStep}/{p.TotalSteps}[/]";

                    if (p.EstimatedRowsInStep > 0)
                    {
                        currentStepTask.MaxValue = p.EstimatedRowsInStep;
                        currentStepTask.Value = p.DeletedRowsInStep;
                    }

                    currentStepTask.Description = $"[blue]{Markup.Escape(p.CurrentTable.FullName)}[/]";
                });

                report = await action(progress).ConfigureAwait(false);

                overallTask.Value = overallTask.MaxValue;
                currentStepTask.Value = currentStepTask.MaxValue;
            }).ConfigureAwait(false);

        return report!;
    }

    public static void WriteDeletionReport(DeletionReport report)
    {
        ArgumentNullException.ThrowIfNull(report);

        AnsiConsole.WriteLine();
        AnsiConsole.Write(new Rule("[bold green]Deletion Report[/]").RuleStyle("grey"));

        var table = new Table()
            .Border(TableBorder.Rounded)
            .AddColumn(new TableColumn("[bold]Table[/]"))
            .AddColumn(new TableColumn("[bold]Deleted Rows[/]").RightAligned())
            .AddColumn(new TableColumn("[bold]Duration[/]").RightAligned())
            .AddColumn(new TableColumn("[bold]Status[/]").Centered());

        foreach (var result in report.Results)
        {
            var status = result.Success
                ? "[green]OK[/]"
                : $"[red]FAILED: {Markup.Escape(result.ErrorMessage!)}[/]";

            table.AddRow(
                Markup.Escape(result.Table.FullName),
                result.DeletedCount.ToString("N0", CultureInfo.InvariantCulture),
                result.Duration.ToString(@"hh\:mm\:ss\.fff", CultureInfo.InvariantCulture),
                status);
        }

        AnsiConsole.Write(table);

        AnsiConsole.WriteLine();
        AnsiConsole.MarkupLine($"  [bold]Total rows deleted:[/] [green]{report.TotalDeletedRows.ToString("N0", CultureInfo.InvariantCulture)}[/]");
        AnsiConsole.MarkupLine($"  [bold]Total duration:[/] {report.TotalDuration.ToString(@"hh\:mm\:ss\.fff", CultureInfo.InvariantCulture)}");
        AnsiConsole.MarkupLine($"  [bold]Status:[/] {(report.HasErrors ? "[red]Completed with errors[/]" : "[green]Success[/]")}");
        AnsiConsole.WriteLine();
    }
}
