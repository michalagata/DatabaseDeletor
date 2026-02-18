using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Interfaces;
using Microsoft.Extensions.Logging;

namespace DatabaseDeletor.Application.Commands;

public sealed class AnalyzeDependenciesHandler : IRequestHandler<AnalyzeDependenciesCommand, DependencyGraph>
{
    private readonly IDependencyAnalyzer _analyzer;
    private readonly ILogger<AnalyzeDependenciesHandler> _logger;

    public AnalyzeDependenciesHandler(IDependencyAnalyzer analyzer, ILogger<AnalyzeDependenciesHandler> logger)
    {
        _analyzer = analyzer;
        _logger = logger;
    }

    public async Task<DependencyGraph> HandleAsync(AnalyzeDependenciesCommand request, CancellationToken ct = default)
    {
        _logger.LogInformation(
            "Analyzing dependencies for table {Schema}.{Table}",
            request.Schema, request.TableName);

        var graph = await _analyzer.AnalyzeAsync(
            request.ConnectionString,
            request.Schema,
            request.TableName,
            ct).ConfigureAwait(false);

        _logger.LogInformation(
            "Found {TableCount} related tables for {Schema}.{Table}",
            graph.Tables.Count, request.Schema, request.TableName);

        return graph;
    }
}
