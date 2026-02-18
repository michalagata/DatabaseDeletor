using DatabaseDeletor.Application.Commands;
using DatabaseDeletor.Cli;
using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Interfaces;
using Microsoft.Extensions.DependencyInjection;

namespace DatabaseDeletor.Cli.Tests;

public sealed class DeletionServiceTests
{
    private static TableInfo CreateTable(string schema = "dbo", string name = "Users") =>
        new() { Schema = schema, Name = name };

    private static DependencyGraph CreateGraph(params TableInfo[] tables)
    {
        var graph = new DependencyGraph();
        foreach (var t in tables)
            graph.AddTable(t);
        return graph;
    }

    private static DeletionPlan CreatePlan(TableInfo rootTable, string? whereClause = "Id = 1")
    {
        return new DeletionPlan
        {
            RootTable = rootTable,
            WhereClause = whereClause,
            Steps =
            [
                new DeletionStep
                {
                    Order = 0,
                    Table = rootTable,
                    DeleteSql = $"DELETE FROM {rootTable.FullName} WHERE {whereClause}",
                    EstimatedRowCount = 100
                }
            ]
        };
    }

    private static DeletionReport CreateReport(TableInfo rootTable)
    {
        return new DeletionReport
        {
            PlanId = Guid.NewGuid(),
            RootTable = rootTable,
            StartedAt = DateTime.UtcNow.AddSeconds(-1),
            CompletedAt = DateTime.UtcNow,
            Results =
            [
                new DeletionStepResult
                {
                    Table = rootTable,
                    DeletedCount = 100,
                    Duration = TimeSpan.FromMilliseconds(500)
                }
            ]
        };
    }

    private static (IServiceProvider Services, IMediator Mediator, ISqlParser Parser)
        CreateServiceProvider(TableInfo rootTable, DependencyGraph graph, DeletionPlan plan, DeletionReport report)
    {
        var mediator = Substitute.For<IMediator>();
        var parser = Substitute.For<ISqlParser>();

        parser.Parse(Arg.Any<string>())
            .Returns(new ParsedQuery
            {
                Schema = rootTable.Schema,
                TableName = rootTable.Name,
                WhereClause = plan.WhereClause
            });

        mediator.SendAsync(Arg.Any<AnalyzeDependenciesCommand>(), Arg.Any<CancellationToken>())
            .Returns(Task.FromResult(graph));
        mediator.SendAsync(Arg.Any<GenerateDeletionPlanCommand>(), Arg.Any<CancellationToken>())
            .Returns(Task.FromResult(plan));
        mediator.SendAsync(Arg.Any<ExecuteDeletionCommand>(), Arg.Any<CancellationToken>())
            .Returns(Task.FromResult(report));

        var services = new ServiceCollection();
        services.AddSingleton(mediator);
        services.AddSingleton(parser);
        var sp = services.BuildServiceProvider();

        return (sp, mediator, parser);
    }

    [Fact]
    public async Task RunAsync_WithSkipConfirmation_ExecutesDeletion()
    {
        // Arrange
        var table = CreateTable();
        var graph = CreateGraph(table);
        var plan = CreatePlan(table);
        var report = CreateReport(table);
        var (sp, mediator, _) = CreateServiceProvider(table, graph, plan, report);
        var sut = new DeletionService(sp);

        // Act
        await sut.RunAsync("Server=.;Database=TestDb", "DELETE FROM dbo.Users WHERE Id = 1", skipConfirmation: true, CancellationToken.None);

        // Assert — all three commands were sent
        await mediator.Received(1).SendAsync(Arg.Any<AnalyzeDependenciesCommand>(), Arg.Any<CancellationToken>());
        await mediator.Received(1).SendAsync(Arg.Any<GenerateDeletionPlanCommand>(), Arg.Any<CancellationToken>());
        await mediator.Received(1).SendAsync(Arg.Any<ExecuteDeletionCommand>(), Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task RunAsync_ParsesSqlFirst()
    {
        // Arrange
        var table = CreateTable();
        var graph = CreateGraph(table);
        var plan = CreatePlan(table);
        var report = CreateReport(table);
        var (sp, _, parser) = CreateServiceProvider(table, graph, plan, report);
        var sut = new DeletionService(sp);

        // Act
        await sut.RunAsync("conn", "DELETE FROM dbo.Users WHERE Id = 1", skipConfirmation: true, CancellationToken.None);

        // Assert
        parser.Received(1).Parse("DELETE FROM dbo.Users WHERE Id = 1");
    }

    [Fact]
    public async Task RunAsync_SendsCorrectAnalyzeCommand()
    {
        // Arrange
        var table = CreateTable("dbo", "Orders");
        var graph = CreateGraph(table);
        var plan = CreatePlan(table);
        var report = CreateReport(table);
        var (sp, mediator, _) = CreateServiceProvider(table, graph, plan, report);
        var sut = new DeletionService(sp);

        // Act
        await sut.RunAsync("conn", "DELETE FROM dbo.Orders WHERE Id = 1", skipConfirmation: true, CancellationToken.None);

        // Assert
        await mediator.Received(1).SendAsync(
            Arg.Is<AnalyzeDependenciesCommand>(c =>
                c.Schema == "dbo" && c.TableName == "Orders"),
            Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task RunAsync_PassesProgressToExecutionCommand()
    {
        // Arrange
        var table = CreateTable();
        var graph = CreateGraph(table);
        var plan = CreatePlan(table);
        var report = CreateReport(table);
        var (sp, mediator, _) = CreateServiceProvider(table, graph, plan, report);
        var sut = new DeletionService(sp);

        // Act
        await sut.RunAsync("conn", "DELETE FROM dbo.Users WHERE Id = 1", skipConfirmation: true, CancellationToken.None);

        // Assert — ExecuteDeletionCommand was sent with a progress handler
        await mediator.Received(1).SendAsync(
            Arg.Is<ExecuteDeletionCommand>(c => c.Progress != null),
            Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task RunAsync_WhenCancelled_ThrowsOperationCanceledException()
    {
        // Arrange
        var table = CreateTable();
        var graph = CreateGraph(table);
        var plan = CreatePlan(table);
        var report = CreateReport(table);
        var mediator = Substitute.For<IMediator>();
        var parser = Substitute.For<ISqlParser>();

        parser.Parse(Arg.Any<string>())
            .Returns(new ParsedQuery { Schema = "dbo", TableName = "Users", WhereClause = "Id = 1" });

        mediator.SendAsync(Arg.Any<AnalyzeDependenciesCommand>(), Arg.Any<CancellationToken>())
            .Returns<DependencyGraph>(call => throw new OperationCanceledException());

        var services = new ServiceCollection();
        services.AddSingleton(mediator);
        services.AddSingleton(parser);
        var sp = services.BuildServiceProvider();
        var sut = new DeletionService(sp);

        // Act & Assert
        await Assert.ThrowsAsync<OperationCanceledException>(() =>
            sut.RunAsync("conn", "DELETE FROM dbo.Users", skipConfirmation: true, CancellationToken.None));
    }

    [Fact]
    public async Task RunAsync_WithNoWhereClause_StillExecutes()
    {
        // Arrange
        var table = CreateTable();
        var graph = CreateGraph(table);
        var plan = CreatePlan(table, whereClause: null);
        var report = CreateReport(table);
        var (sp, mediator, parser) = CreateServiceProvider(table, graph, plan, report);

        // Override parser to return null WHERE clause
        parser.Parse(Arg.Any<string>())
            .Returns(new ParsedQuery { Schema = "dbo", TableName = "Users", WhereClause = null });

        var sut = new DeletionService(sp);

        // Act
        await sut.RunAsync("conn", "DELETE FROM dbo.Users", skipConfirmation: true, CancellationToken.None);

        // Assert
        await mediator.Received(1).SendAsync(Arg.Any<ExecuteDeletionCommand>(), Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task RunAsync_WithMultipleTables_AnalyzesCorrectly()
    {
        // Arrange
        var usersTable = CreateTable("dbo", "Users");
        var ordersTable = CreateTable("dbo", "Orders");
        var graph = CreateGraph(usersTable, ordersTable);
        var plan = CreatePlan(usersTable);
        var report = CreateReport(usersTable);
        var (sp, mediator, _) = CreateServiceProvider(usersTable, graph, plan, report);
        var sut = new DeletionService(sp);

        // Act
        await sut.RunAsync("conn", "DELETE FROM dbo.Users WHERE Id = 1", skipConfirmation: true, CancellationToken.None);

        // Assert — the analyze command was sent
        await mediator.Received(1).SendAsync(Arg.Any<AnalyzeDependenciesCommand>(), Arg.Any<CancellationToken>());
    }
}
