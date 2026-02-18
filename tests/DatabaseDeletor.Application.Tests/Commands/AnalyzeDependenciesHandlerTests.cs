namespace DatabaseDeletor.Application.Tests.Commands;

using DatabaseDeletor.Application.Commands;
using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Interfaces;
using Microsoft.Extensions.Logging;

public sealed class AnalyzeDependenciesHandlerTests
{
    private readonly IDependencyAnalyzer _analyzer = Substitute.For<IDependencyAnalyzer>();
    private readonly ILogger<AnalyzeDependenciesHandler> _logger = Substitute.For<ILogger<AnalyzeDependenciesHandler>>();
    private readonly AnalyzeDependenciesHandler _sut;

    public AnalyzeDependenciesHandlerTests()
    {
        _sut = new AnalyzeDependenciesHandler(_analyzer, _logger);
    }

    [Fact]
    public async Task HandleAsync_ValidCommand_ReturnsGraph()
    {
        var graph = new DependencyGraph();
        graph.AddTable(new TableInfo { Schema = "dbo", Name = "Users" });

        _analyzer.AnalyzeAsync("conn", "dbo", "Users", Arg.Any<CancellationToken>())
            .Returns(graph);

        var command = new AnalyzeDependenciesCommand("conn", "dbo", "Users");

        var result = await _sut.HandleAsync(command);

        result.Should().BeSameAs(graph);
    }

    [Fact]
    public async Task HandleAsync_NullRequest_ThrowsArgumentNullException()
    {
        var act = () => _sut.HandleAsync(null!);

        await act.Should().ThrowAsync<ArgumentNullException>();
    }

    [Fact]
    public async Task HandleAsync_CallsAnalyzerWithCorrectParameters()
    {
        var graph = new DependencyGraph();
        _analyzer.AnalyzeAsync("conn", "sales", "Orders", Arg.Any<CancellationToken>())
            .Returns(graph);

        var command = new AnalyzeDependenciesCommand("conn", "sales", "Orders");

        await _sut.HandleAsync(command);

        await _analyzer.Received(1).AnalyzeAsync("conn", "sales", "Orders", Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task HandleAsync_PropagatesCancellationToken()
    {
        using var cts = new CancellationTokenSource();
        var ct = cts.Token;
        var graph = new DependencyGraph();

        _analyzer.AnalyzeAsync("conn", "dbo", "Users", ct).Returns(graph);

        var command = new AnalyzeDependenciesCommand("conn", "dbo", "Users");

        await _sut.HandleAsync(command, ct);

        await _analyzer.Received(1).AnalyzeAsync("conn", "dbo", "Users", ct);
    }
}
