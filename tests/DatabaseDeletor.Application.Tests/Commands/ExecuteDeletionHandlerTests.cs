namespace DatabaseDeletor.Application.Tests.Commands;

using DatabaseDeletor.Application.Commands;
using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Interfaces;
using Microsoft.Extensions.Logging;

public sealed class ExecuteDeletionHandlerTests
{
    private static readonly DeletionOptions DefaultOptions = new();

    private readonly IDeletionExecutor _executor = Substitute.For<IDeletionExecutor>();
    private readonly ILogger<ExecuteDeletionHandler> _logger = Substitute.For<ILogger<ExecuteDeletionHandler>>();
    private readonly ExecuteDeletionHandler _sut;

    public ExecuteDeletionHandlerTests()
    {
        _sut = new ExecuteDeletionHandler(_executor, _logger);
    }

    [Fact]
    public async Task HandleAsync_ValidCommand_ReturnsReport()
    {
        var rootTable = new TableInfo { Schema = "dbo", Name = "Users" };
        var plan = new DeletionPlan
        {
            RootTable = rootTable,
            WhereClause = null,
            Steps = [new DeletionStep { Order = 0, Table = rootTable, DeleteSql = "DELETE FROM Users", EstimatedRowCount = 100 }]
        };

        var expectedReport = new DeletionReport
        {
            RootTable = rootTable,
            Results = [new DeletionStepResult { Table = rootTable, DeletedCount = 100, Duration = TimeSpan.FromSeconds(1) }],
            StartedAt = DateTime.UtcNow.AddSeconds(-1),
            CompletedAt = DateTime.UtcNow
        };

        _executor.ExecuteAsync("conn", plan, DefaultOptions, null, Arg.Any<CancellationToken>())
            .Returns(expectedReport);

        var command = new ExecuteDeletionCommand("conn", plan, DefaultOptions);

        var result = await _sut.HandleAsync(command);

        result.Should().BeSameAs(expectedReport);
    }

    [Fact]
    public async Task HandleAsync_NullRequest_ThrowsArgumentNullException()
    {
        var act = () => _sut.HandleAsync(null!);

        await act.Should().ThrowAsync<ArgumentNullException>();
    }

    [Fact]
    public async Task HandleAsync_WithProgress_PassesProgressToExecutor()
    {
        var rootTable = new TableInfo { Schema = "dbo", Name = "Users" };
        var plan = new DeletionPlan { RootTable = rootTable, WhereClause = null, Steps = [] };
        var progress = new Progress<DeletionProgress>();

        var expectedReport = new DeletionReport
        {
            RootTable = rootTable,
            Results = [],
            StartedAt = DateTime.UtcNow,
            CompletedAt = DateTime.UtcNow
        };

        _executor.ExecuteAsync("conn", plan, DefaultOptions, progress, Arg.Any<CancellationToken>())
            .Returns(expectedReport);

        var command = new ExecuteDeletionCommand("conn", plan, DefaultOptions, progress);

        await _sut.HandleAsync(command);

        await _executor.Received(1).ExecuteAsync("conn", plan, DefaultOptions, progress, Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task HandleAsync_ReportWithErrors_StillReturnsReport()
    {
        var rootTable = new TableInfo { Schema = "dbo", Name = "Users" };
        var plan = new DeletionPlan { RootTable = rootTable, WhereClause = null, Steps = [] };

        var reportWithErrors = new DeletionReport
        {
            RootTable = rootTable,
            Results =
            [
                new DeletionStepResult { Table = rootTable, DeletedCount = 0, Duration = TimeSpan.FromSeconds(1), ErrorMessage = "FK violation" }
            ],
            StartedAt = DateTime.UtcNow.AddSeconds(-1),
            CompletedAt = DateTime.UtcNow
        };

        _executor.ExecuteAsync("conn", plan, DefaultOptions, null, Arg.Any<CancellationToken>())
            .Returns(reportWithErrors);

        var command = new ExecuteDeletionCommand("conn", plan, DefaultOptions);

        var result = await _sut.HandleAsync(command);

        result.HasErrors.Should().BeTrue();
    }
}
