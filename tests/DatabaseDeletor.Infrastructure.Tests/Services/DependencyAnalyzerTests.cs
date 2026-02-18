namespace DatabaseDeletor.Infrastructure.Tests.Services;

using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Enums;
using DatabaseDeletor.Domain.Interfaces;
using DatabaseDeletor.Infrastructure.Services;
using Microsoft.Extensions.Logging;

public sealed class DependencyAnalyzerTests
{
    private readonly IDatabaseProviderResolver _providerResolver = Substitute.For<IDatabaseProviderResolver>();
    private readonly ISchemaIntrospector _introspector = Substitute.For<ISchemaIntrospector>();
    private readonly ILogger<DependencyAnalyzer> _logger = Substitute.For<ILogger<DependencyAnalyzer>>();
    private readonly DependencyAnalyzer _sut;

    public DependencyAnalyzerTests()
    {
        _introspector.Provider.Returns(DatabaseProvider.SqlServer);
        _providerResolver.Resolve(Arg.Any<string>()).Returns(DatabaseProvider.SqlServer);

        _sut = new DependencyAnalyzer(_providerResolver, [_introspector], _logger);
    }

    [Fact]
    public async Task AnalyzeAsync_SingleTableNoForeignKeys_ReturnsGraphWithOneTable()
    {
        var table = new TableInfo { Schema = "dbo", Name = "Users", RowCount = 100 };

        _introspector.GetTableInfoAsync("conn", "dbo", "Users", Arg.Any<CancellationToken>())
            .Returns(table);
        _introspector.GetReferencingForeignKeysAsync("conn", "dbo", "Users", Arg.Any<CancellationToken>())
            .Returns(new List<ForeignKeyInfo>());

        var result = await _sut.AnalyzeAsync("conn", "dbo", "Users");

        result.Tables.Should().HaveCount(1);
        result.Tables.Should().Contain(table);
    }

    [Fact]
    public async Task AnalyzeAsync_TableWithChild_ReturnsGraphWithBothTables()
    {
        var users = new TableInfo { Schema = "dbo", Name = "Users", RowCount = 100 };
        var orders = new TableInfo { Schema = "dbo", Name = "Orders", RowCount = 200 };

        var fk = new ForeignKeyInfo
        {
            ConstraintName = "FK_Orders_Users",
            ReferencingTable = orders,
            ReferencingColumn = "UserId",
            ReferencedTable = users,
            ReferencedColumn = "Id",
            DeleteRule = "NO ACTION"
        };

        _introspector.GetTableInfoAsync("conn", "dbo", "Users", Arg.Any<CancellationToken>())
            .Returns(users);
        _introspector.GetTableInfoAsync("conn", "dbo", "Orders", Arg.Any<CancellationToken>())
            .Returns(orders);
        _introspector.GetReferencingForeignKeysAsync("conn", "dbo", "Users", Arg.Any<CancellationToken>())
            .Returns(new List<ForeignKeyInfo> { fk });
        _introspector.GetReferencingForeignKeysAsync("conn", "dbo", "Orders", Arg.Any<CancellationToken>())
            .Returns(new List<ForeignKeyInfo>());

        var result = await _sut.AnalyzeAsync("conn", "dbo", "Users");

        result.Tables.Should().HaveCount(2);
        result.Tables.Should().Contain(users);
        result.Tables.Should().Contain(orders);
    }

    [Fact]
    public async Task AnalyzeAsync_CancellationRequested_ThrowsOperationCanceledException()
    {
        using var cts = new CancellationTokenSource();
        await cts.CancelAsync();

        var table = new TableInfo { Schema = "dbo", Name = "Users" };

        _introspector.GetTableInfoAsync("conn", "dbo", "Users", Arg.Any<CancellationToken>())
            .Returns(table);
        _introspector.GetReferencingForeignKeysAsync("conn", "dbo", "Users", Arg.Any<CancellationToken>())
            .Returns(new List<ForeignKeyInfo>());

        var act = () => _sut.AnalyzeAsync("conn", "dbo", "Users", cts.Token);

        await act.Should().ThrowAsync<OperationCanceledException>();
    }

    [Fact]
    public async Task AnalyzeAsync_NoMatchingIntrospector_ThrowsInvalidOperationException()
    {
        _providerResolver.Resolve(Arg.Any<string>()).Returns(DatabaseProvider.Oracle);

        var sut = new DependencyAnalyzer(_providerResolver, [_introspector], _logger);

        var act = () => sut.AnalyzeAsync("conn", "dbo", "Users");

        await act.Should().ThrowAsync<InvalidOperationException>()
            .WithMessage("*No schema introspector*");
    }
}
