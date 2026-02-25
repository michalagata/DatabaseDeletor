namespace DatabaseDeletor.Application.Tests.Commands;

using DatabaseDeletor.Application.Commands;
using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Enums;
using DatabaseDeletor.Domain.Interfaces;
using Microsoft.Extensions.Logging;

public sealed class GetColumnsHandlerTests
{
    private readonly IDatabaseProviderResolver _providerResolver = Substitute.For<IDatabaseProviderResolver>();
    private readonly ISchemaIntrospector _introspector = Substitute.For<ISchemaIntrospector>();
    private readonly ILogger<GetColumnsHandler> _logger = Substitute.For<ILogger<GetColumnsHandler>>();
    private readonly GetColumnsHandler _sut;

    public GetColumnsHandlerTests()
    {
        _introspector.Provider.Returns(DatabaseProvider.SqlServer);
        _providerResolver.Resolve(Arg.Any<string>()).Returns(DatabaseProvider.SqlServer);
        _sut = new GetColumnsHandler(_providerResolver, [_introspector], _logger);
    }

    [Fact]
    public async Task HandleAsync_ValidCommand_ReturnsColumns()
    {
        var columns = new List<ColumnInfo>
        {
            new() { Name = "Id", DataType = "int", IsNullable = false, IsPrimaryKey = true },
            new() { Name = "Name", DataType = "nvarchar", IsNullable = true, IsPrimaryKey = false }
        };

        _introspector.GetColumnsAsync("conn", "dbo", "Users", Arg.Any<CancellationToken>())
            .Returns(columns);

        var command = new GetColumnsCommand("conn", "dbo", "Users");
        var result = await _sut.HandleAsync(command);

        result.Should().HaveCount(2);
        result[0].Name.Should().Be("Id");
        result[0].IsPrimaryKey.Should().BeTrue();
        result[1].Name.Should().Be("Name");
        result[1].IsNullable.Should().BeTrue();
    }

    [Fact]
    public async Task HandleAsync_NullRequest_ThrowsArgumentNullException()
    {
        var act = () => _sut.HandleAsync(null!);
        await act.Should().ThrowAsync<ArgumentNullException>();
    }

    [Fact]
    public async Task HandleAsync_NoMatchingIntrospector_ThrowsInvalidOperationException()
    {
        _providerResolver.Resolve(Arg.Any<string>()).Returns(DatabaseProvider.PostgreSql);

        var command = new GetColumnsCommand("conn", "dbo", "Users");
        var act = () => _sut.HandleAsync(command);

        await act.Should().ThrowAsync<InvalidOperationException>()
            .WithMessage("*PostgreSql*");
    }

    [Fact]
    public async Task HandleAsync_CallsIntrospectorWithCorrectParameters()
    {
        IReadOnlyList<ColumnInfo> columns = [];
        _introspector.GetColumnsAsync("conn", "sales", "Orders", Arg.Any<CancellationToken>())
            .Returns(columns);

        var command = new GetColumnsCommand("conn", "sales", "Orders");
        await _sut.HandleAsync(command);

        await _introspector.Received(1).GetColumnsAsync("conn", "sales", "Orders", Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task HandleAsync_PropagatesCancellationToken()
    {
        using var cts = new CancellationTokenSource();
        var ct = cts.Token;
        IReadOnlyList<ColumnInfo> columns = [];

        _introspector.GetColumnsAsync("conn", "dbo", "Users", ct).Returns(columns);

        var command = new GetColumnsCommand("conn", "dbo", "Users");
        await _sut.HandleAsync(command, ct);

        await _introspector.Received(1).GetColumnsAsync("conn", "dbo", "Users", ct);
    }
}
