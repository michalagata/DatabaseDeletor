namespace DatabaseDeletor.Infrastructure.Tests.Services;

using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Enums;
using DatabaseDeletor.Domain.Interfaces;
using DatabaseDeletor.Infrastructure.Services;
using Microsoft.Extensions.Logging;

public sealed class DeletionPlanGeneratorTests
{
    private readonly IDatabaseProviderResolver _providerResolver = Substitute.For<IDatabaseProviderResolver>();
    private readonly ISchemaIntrospector _introspector = Substitute.For<ISchemaIntrospector>();
    private readonly ILogger<DeletionPlanGenerator> _logger = Substitute.For<ILogger<DeletionPlanGenerator>>();
    private readonly DeletionPlanGenerator _sut;

    public DeletionPlanGeneratorTests()
    {
        _introspector.Provider.Returns(DatabaseProvider.SqlServer);
        _providerResolver.Resolve(Arg.Any<string>()).Returns(DatabaseProvider.SqlServer);

        _sut = new DeletionPlanGenerator(_providerResolver, [_introspector], _logger);
    }

    [Fact]
    public async Task GenerateAsync_SingleTable_GeneratesSingleStep()
    {
        var rootTable = new TableInfo { Schema = "dbo", Name = "Users" };
        var graph = new DependencyGraph();
        graph.AddTable(rootTable);

        _introspector.GetRowCountAsync("conn", "dbo", "Users", null, Arg.Any<CancellationToken>())
            .Returns(100L);

        var plan = await _sut.GenerateAsync("conn", graph, rootTable, null);

        plan.Steps.Should().HaveCount(1);
        plan.Steps[0].Table.Should().Be(rootTable);
        plan.RootTable.Should().Be(rootTable);
        plan.WhereClause.Should().BeNull();
    }

    [Fact]
    public async Task GenerateAsync_WithWhereClause_IncludesWhereInRootTableSql()
    {
        var rootTable = new TableInfo { Schema = "dbo", Name = "Users" };
        var graph = new DependencyGraph();
        graph.AddTable(rootTable);

        _introspector.GetRowCountAsync("conn", "dbo", "Users", "Id = 1", Arg.Any<CancellationToken>())
            .Returns(1L);

        var plan = await _sut.GenerateAsync("conn", graph, rootTable, "Id = 1");

        plan.Steps[0].DeleteSql.Should().Contain("WHERE Id = 1");
    }

    [Fact]
    public async Task GenerateAsync_WithChildTable_GeneratesCorrectOrder()
    {
        var users = new TableInfo { Schema = "dbo", Name = "Users" };
        var orders = new TableInfo { Schema = "dbo", Name = "Orders" };

        var graph = new DependencyGraph();
        graph.AddForeignKey(new ForeignKeyInfo
        {
            ConstraintName = "FK_Orders_Users",
            ReferencingTable = orders,
            ReferencingColumn = "UserId",
            ReferencedTable = users,
            ReferencedColumn = "Id",
            DeleteRule = "NO ACTION"
        });

        _introspector.GetRowCountAsync(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string?>(), Arg.Any<CancellationToken>())
            .Returns(50L);

        var plan = await _sut.GenerateAsync("conn", graph, users, null);

        plan.Steps.Should().HaveCount(2);
        plan.Steps[0].Table.Should().Be(orders);
        plan.Steps[1].Table.Should().Be(users);
    }

    [Fact]
    public async Task GenerateAsync_NullGraph_ThrowsArgumentNullException()
    {
        var rootTable = new TableInfo { Schema = "dbo", Name = "Users" };

        var act = () => _sut.GenerateAsync("conn", null!, rootTable, null);

        await act.Should().ThrowAsync<ArgumentNullException>();
    }

    [Fact]
    public async Task GenerateAsync_SqlServerProvider_UsesSquareBracketQuoting()
    {
        var rootTable = new TableInfo { Schema = "dbo", Name = "Users" };
        var graph = new DependencyGraph();
        graph.AddTable(rootTable);

        _introspector.GetRowCountAsync(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string?>(), Arg.Any<CancellationToken>())
            .Returns(100L);

        var plan = await _sut.GenerateAsync("conn", graph, rootTable, null);

        plan.Steps[0].DeleteSql.Should().Contain("[dbo].[Users]");
    }

    [Fact]
    public async Task GenerateAsync_PostgreSqlProvider_UsesDoubleQuoteQuoting()
    {
        _providerResolver.Resolve(Arg.Any<string>()).Returns(DatabaseProvider.PostgreSql);
        _introspector.Provider.Returns(DatabaseProvider.PostgreSql);

        var sut = new DeletionPlanGenerator(_providerResolver, [_introspector], _logger);

        var rootTable = new TableInfo { Schema = "public", Name = "users" };
        var graph = new DependencyGraph();
        graph.AddTable(rootTable);

        _introspector.GetRowCountAsync(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string?>(), Arg.Any<CancellationToken>())
            .Returns(100L);

        var plan = await sut.GenerateAsync("conn", graph, rootTable, null);

        plan.Steps[0].DeleteSql.Should().Contain("\"public\".\"users\"");
    }

    [Fact]
    public async Task GenerateAsync_EstimatedRowCounts_ArePopulated()
    {
        var rootTable = new TableInfo { Schema = "dbo", Name = "Users" };
        var graph = new DependencyGraph();
        graph.AddTable(rootTable);

        _introspector.GetRowCountAsync("conn", "dbo", "Users", null, Arg.Any<CancellationToken>())
            .Returns(42L);

        var plan = await _sut.GenerateAsync("conn", graph, rootTable, null);

        plan.Steps[0].EstimatedRowCount.Should().Be(42);
        plan.TotalEstimatedRows.Should().Be(42);
    }
}
