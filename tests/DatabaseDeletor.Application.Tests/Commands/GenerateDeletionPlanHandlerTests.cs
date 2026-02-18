namespace DatabaseDeletor.Application.Tests.Commands;

using DatabaseDeletor.Application.Commands;
using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Interfaces;
using Microsoft.Extensions.Logging;

public sealed class GenerateDeletionPlanHandlerTests
{
    private readonly IDeletionPlanGenerator _planGenerator = Substitute.For<IDeletionPlanGenerator>();
    private readonly ILogger<GenerateDeletionPlanHandler> _logger = Substitute.For<ILogger<GenerateDeletionPlanHandler>>();
    private readonly GenerateDeletionPlanHandler _sut;

    public GenerateDeletionPlanHandlerTests()
    {
        _sut = new GenerateDeletionPlanHandler(_planGenerator, _logger);
    }

    [Fact]
    public async Task HandleAsync_ValidCommand_ReturnsPlan()
    {
        var graph = new DependencyGraph();
        var rootTable = new TableInfo { Schema = "dbo", Name = "Users" };
        graph.AddTable(rootTable);

        var expectedPlan = new DeletionPlan
        {
            RootTable = rootTable,
            WhereClause = "Id = 1",
            Steps = [new DeletionStep { Order = 0, Table = rootTable, DeleteSql = "DELETE FROM Users WHERE Id = 1", EstimatedRowCount = 1 }]
        };

        _planGenerator.GenerateAsync("conn", graph, rootTable, "Id = 1", Arg.Any<CancellationToken>())
            .Returns(expectedPlan);

        var command = new GenerateDeletionPlanCommand("conn", graph, rootTable, "Id = 1");

        var result = await _sut.HandleAsync(command);

        result.Should().BeSameAs(expectedPlan);
    }

    [Fact]
    public async Task HandleAsync_NullRequest_ThrowsArgumentNullException()
    {
        var act = () => _sut.HandleAsync(null!);

        await act.Should().ThrowAsync<ArgumentNullException>();
    }

    [Fact]
    public async Task HandleAsync_NullWhereClause_PassesNullThrough()
    {
        var graph = new DependencyGraph();
        var rootTable = new TableInfo { Schema = "dbo", Name = "Users" };
        graph.AddTable(rootTable);

        var expectedPlan = new DeletionPlan { RootTable = rootTable, WhereClause = null, Steps = [] };

        _planGenerator.GenerateAsync("conn", graph, rootTable, null, Arg.Any<CancellationToken>())
            .Returns(expectedPlan);

        var command = new GenerateDeletionPlanCommand("conn", graph, rootTable, null);

        var result = await _sut.HandleAsync(command);

        result.WhereClause.Should().BeNull();
    }
}
