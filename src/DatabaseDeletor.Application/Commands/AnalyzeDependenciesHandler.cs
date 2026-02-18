using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Interfaces;
using Microsoft.Extensions.Logging;

namespace DatabaseDeletor.Application.Commands;

public sealed partial class AnalyzeDependenciesHandler : IRequestHandler<AnalyzeDependenciesCommand, DependencyGraph>
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
        ArgumentNullException.ThrowIfNull(request);

        LogAnalyzing(request.Schema, request.TableName);

        var graph = await _analyzer.AnalyzeAsync(
            request.ConnectionString,
            request.Schema,
            request.TableName,
            ct).ConfigureAwait(false);

        LogFound(graph.Tables.Count, request.Schema, request.TableName);

        return graph;
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Analyzing dependencies for table {Schema}.{Table}")]
    private partial void LogAnalyzing(string schema, string table);

    [LoggerMessage(Level = LogLevel.Information, Message = "Found {TableCount} related tables for {Schema}.{Table}")]
    private partial void LogFound(int tableCount, string schema, string table);
}
