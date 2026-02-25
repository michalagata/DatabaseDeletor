namespace DatabaseDeletor.Infrastructure.Tests.Services;

using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Enums;
using DatabaseDeletor.Domain.Interfaces;
using DatabaseDeletor.Infrastructure.Services;
using Microsoft.Extensions.Logging;

public sealed class DeletionExecutorTests
{
    private sealed class TestDbException(string message) : System.Data.Common.DbException(message);

    private static readonly DeletionOptions DefaultOptions = new();

    private readonly IDatabaseProviderResolver _providerResolver = Substitute.For<IDatabaseProviderResolver>();
    private readonly IBulkDeleteExecutor _bulkExecutor = Substitute.For<IBulkDeleteExecutor>();
    private readonly IDbConnectionFactory _connectionFactory = Substitute.For<IDbConnectionFactory>();
    private readonly ILogger<DeletionExecutor> _logger = Substitute.For<ILogger<DeletionExecutor>>();
    private readonly DeletionExecutor _sut;

    public DeletionExecutorTests()
    {
        _bulkExecutor.Provider.Returns(DatabaseProvider.SqlServer);
        _connectionFactory.Provider.Returns(DatabaseProvider.SqlServer);
        _providerResolver.Resolve(Arg.Any<string>()).Returns(DatabaseProvider.SqlServer);

        _sut = new DeletionExecutor(_providerResolver, [_bulkExecutor], [_connectionFactory], _logger);
    }

    [Fact]
    public async Task ExecuteAsync_SingleStep_ReturnsReportWithResults()
    {
        var rootTable = new TableInfo { Schema = "dbo", Name = "Users" };
        var plan = new DeletionPlan
        {
            RootTable = rootTable,
            WhereClause = null,
            Steps = [new DeletionStep { Order = 0, Table = rootTable, DeleteSql = "DELETE FROM Users", EstimatedRowCount = 100 }]
        };

        _bulkExecutor.ExecuteDeleteAsync("conn", Arg.Any<DeletionStep>(), Arg.Any<DeletionOptions>(), null, null, Arg.Any<IProgress<long>>(), Arg.Any<CancellationToken>())
            .Returns(100L);

        var result = await _sut.ExecuteAsync("conn", plan, DefaultOptions);

        result.Results.Should().HaveCount(1);
        result.Results[0].DeletedCount.Should().Be(100);
        result.Results[0].Success.Should().BeTrue();
        result.TotalDeletedRows.Should().Be(100);
    }

    [Fact]
    public async Task ExecuteAsync_NullPlan_ThrowsArgumentNullException()
    {
        var act = () => _sut.ExecuteAsync("conn", null!, DefaultOptions);

        await act.Should().ThrowAsync<ArgumentNullException>();
    }

    [Fact]
    public async Task ExecuteAsync_AllStepsSucceed_StatusIsCompleted()
    {
        var rootTable = new TableInfo { Schema = "dbo", Name = "Users" };
        var plan = new DeletionPlan
        {
            RootTable = rootTable,
            WhereClause = null,
            Steps = [new DeletionStep { Order = 0, Table = rootTable, DeleteSql = "DELETE FROM Users", EstimatedRowCount = 50 }]
        };

        _bulkExecutor.ExecuteDeleteAsync(Arg.Any<string>(), Arg.Any<DeletionStep>(), Arg.Any<DeletionOptions>(), null, null, Arg.Any<IProgress<long>>(), Arg.Any<CancellationToken>())
            .Returns(50L);

        await _sut.ExecuteAsync("conn", plan, DefaultOptions);

        plan.Status.Should().Be(DeletionStatus.Completed);
    }

    [Fact]
    public async Task ExecuteAsync_StepFails_StatusIsFailed()
    {
        var rootTable = new TableInfo { Schema = "dbo", Name = "Users" };
        var plan = new DeletionPlan
        {
            RootTable = rootTable,
            WhereClause = null,
            Steps = [new DeletionStep { Order = 0, Table = rootTable, DeleteSql = "DELETE FROM Users", EstimatedRowCount = 50 }]
        };

        _bulkExecutor.ExecuteDeleteAsync(Arg.Any<string>(), Arg.Any<DeletionStep>(), Arg.Any<DeletionOptions>(), null, null, Arg.Any<IProgress<long>>(), Arg.Any<CancellationToken>())
            .Returns<long>(_ => throw new TestDbException("FK violation"));

        await _sut.ExecuteAsync("conn", plan, DefaultOptions);

        plan.Status.Should().Be(DeletionStatus.Failed);
    }

    [Fact]
    public async Task ExecuteAsync_MultipleSteps_ExecutesAllInOrder()
    {
        var rootTable = new TableInfo { Schema = "dbo", Name = "Users" };
        var ordersTable = new TableInfo { Schema = "dbo", Name = "Orders" };

        var plan = new DeletionPlan
        {
            RootTable = rootTable,
            WhereClause = null,
            Steps =
            [
                new DeletionStep { Order = 0, Table = ordersTable, DeleteSql = "DELETE FROM Orders", EstimatedRowCount = 200 },
                new DeletionStep { Order = 1, Table = rootTable, DeleteSql = "DELETE FROM Users", EstimatedRowCount = 100 }
            ]
        };

        _bulkExecutor.ExecuteDeleteAsync(Arg.Any<string>(), Arg.Any<DeletionStep>(), Arg.Any<DeletionOptions>(), null, null, Arg.Any<IProgress<long>>(), Arg.Any<CancellationToken>())
            .Returns(x => ((DeletionStep)x[1]).EstimatedRowCount);

        var result = await _sut.ExecuteAsync("conn", plan, DefaultOptions);

        result.Results.Should().HaveCount(2);
        result.TotalDeletedRows.Should().Be(300);
    }

    [Fact]
    public async Task ExecuteAsync_ReportsProgress()
    {
        var rootTable = new TableInfo { Schema = "dbo", Name = "Users" };
        var plan = new DeletionPlan
        {
            RootTable = rootTable,
            WhereClause = null,
            Steps = [new DeletionStep { Order = 0, Table = rootTable, DeleteSql = "DELETE FROM Users", EstimatedRowCount = 100 }]
        };

        var progressReports = new List<DeletionProgress>();
        var progress = new Progress<DeletionProgress>(p => progressReports.Add(p));

        _bulkExecutor.ExecuteDeleteAsync(Arg.Any<string>(), Arg.Any<DeletionStep>(), Arg.Any<DeletionOptions>(), null, null, Arg.Any<IProgress<long>>(), Arg.Any<CancellationToken>())
            .Returns(100L);

        var result = await _sut.ExecuteAsync("conn", plan, DefaultOptions, progress);

        result.Should().NotBeNull();
    }

    [Fact]
    public async Task ExecuteAsync_CancellationRequested_ThrowsOperationCanceledException()
    {
        using var cts = new CancellationTokenSource();
        await cts.CancelAsync();

        var rootTable = new TableInfo { Schema = "dbo", Name = "Users" };
        var plan = new DeletionPlan
        {
            RootTable = rootTable,
            WhereClause = null,
            Steps = [new DeletionStep { Order = 0, Table = rootTable, DeleteSql = "DELETE FROM Users", EstimatedRowCount = 100 }]
        };

        var act = () => _sut.ExecuteAsync("conn", plan, DefaultOptions, ct: cts.Token);

        await act.Should().ThrowAsync<OperationCanceledException>();
    }

    [Fact]
    public async Task ExecuteAsync_NoMatchingExecutor_ThrowsInvalidOperationException()
    {
        _providerResolver.Resolve(Arg.Any<string>()).Returns(DatabaseProvider.Oracle);

        var rootTable = new TableInfo { Schema = "dbo", Name = "Users" };
        var plan = new DeletionPlan { RootTable = rootTable, WhereClause = null, Steps = [] };

        var sut = new DeletionExecutor(_providerResolver, [_bulkExecutor], [_connectionFactory], _logger);

        var act = () => sut.ExecuteAsync("conn", plan, DefaultOptions);

        await act.Should().ThrowAsync<InvalidOperationException>()
            .WithMessage("*No bulk delete executor*");
    }

    [Fact]
    public async Task ExecuteAsync_PassesDeletionOptionsToExecutor()
    {
        var rootTable = new TableInfo { Schema = "dbo", Name = "Users" };
        var plan = new DeletionPlan
        {
            RootTable = rootTable,
            WhereClause = null,
            Steps = [new DeletionStep { Order = 0, Table = rootTable, DeleteSql = "DELETE FROM Users", EstimatedRowCount = 100 }]
        };

        var customOptions = new DeletionOptions { Mode = DeletionMode.DirectDelete, BatchSize = 5000 };

        _bulkExecutor.ExecuteDeleteAsync(Arg.Any<string>(), Arg.Any<DeletionStep>(), Arg.Any<DeletionOptions>(), null, null, Arg.Any<IProgress<long>>(), Arg.Any<CancellationToken>())
            .Returns(100L);

        await _sut.ExecuteAsync("conn", plan, customOptions);

        await _bulkExecutor.Received(1).ExecuteDeleteAsync(
            "conn",
            Arg.Any<DeletionStep>(),
            customOptions,
            null, null,
            Arg.Any<IProgress<long>>(),
            Arg.Any<CancellationToken>());
    }
}
