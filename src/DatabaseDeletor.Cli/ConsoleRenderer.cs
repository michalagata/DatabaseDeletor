using DatabaseDeletor.Domain.Entities;
using Spectre.Console;

namespace DatabaseDeletor.Cli;

public static class ConsoleRenderer
{
    public static void WriteHeader()
    {
        AnsiConsole.Write(new FigletText("DB Deletor")
            .Color(Color.Red)
            .Centered());

        AnsiConsole.MarkupLine("[grey]Mass database deletion tool with dependency analysis[/]");
        AnsiConsole.WriteLine();
    }

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
                (step.Order + 1).ToString(),
                Markup.Escape(step.Table.FullName),
                step.EstimatedRowCount.ToString("N0"),
                Markup.Escape(sqlPreview));
        }

        AnsiConsole.Write(table);

        AnsiConsole.MarkupLine($"\n  [bold]Total estimated rows to delete:[/] [red]{plan.TotalEstimatedRows:N0}[/]");
        AnsiConsole.MarkupLine($"  [bold]Root table:[/] {Markup.Escape(plan.RootTable.FullName)}");
        AnsiConsole.MarkupLine($"  [bold]WHERE clause:[/] {Markup.Escape(plan.WhereClause ?? "(all rows)")}");
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

                report = await action(progress);

                overallTask.Value = overallTask.MaxValue;
                currentStepTask.Value = currentStepTask.MaxValue;
            });

        return report!;
    }

    public static void WriteDeletionReport(DeletionReport report)
    {
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
                result.DeletedCount.ToString("N0"),
                result.Duration.ToString(@"hh\:mm\:ss\.fff"),
                status);
        }

        AnsiConsole.Write(table);

        AnsiConsole.WriteLine();
        AnsiConsole.MarkupLine($"  [bold]Total rows deleted:[/] [green]{report.TotalDeletedRows:N0}[/]");
        AnsiConsole.MarkupLine($"  [bold]Total duration:[/] {report.TotalDuration:hh\\:mm\\:ss\\.fff}");
        AnsiConsole.MarkupLine($"  [bold]Status:[/] {(report.HasErrors ? "[red]Completed with errors[/]" : "[green]Success[/]")}");
        AnsiConsole.WriteLine();
    }
}
