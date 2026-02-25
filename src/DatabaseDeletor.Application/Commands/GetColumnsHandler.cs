using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Interfaces;
using Microsoft.Extensions.Logging;

namespace DatabaseDeletor.Application.Commands;

public sealed partial class GetColumnsHandler : IRequestHandler<GetColumnsCommand, IReadOnlyList<ColumnInfo>>
{
    private readonly IDatabaseProviderResolver _providerResolver;
    private readonly IEnumerable<ISchemaIntrospector> _introspectors;
    private readonly ILogger<GetColumnsHandler> _logger;

    public GetColumnsHandler(
        IDatabaseProviderResolver providerResolver,
        IEnumerable<ISchemaIntrospector> introspectors,
        ILogger<GetColumnsHandler> logger)
    {
        _providerResolver = providerResolver;
        _introspectors = introspectors;
        _logger = logger;
    }

    public async Task<IReadOnlyList<ColumnInfo>> HandleAsync(GetColumnsCommand request, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        var provider = _providerResolver.Resolve(request.ConnectionString);
        var introspector = _introspectors.FirstOrDefault(i => i.Provider == provider)
            ?? throw new InvalidOperationException($"No schema introspector registered for provider {provider}");

        LogFetchingColumns(request.Schema, request.TableName, provider);

        var columns = await introspector.GetColumnsAsync(
            request.ConnectionString, request.Schema, request.TableName, ct).ConfigureAwait(false);

        LogColumnsFound(columns.Count);

        return columns;
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Fetching columns for {Schema}.{TableName} using {Provider} provider")]
    private partial void LogFetchingColumns(string schema, string tableName, DatabaseDeletor.Domain.Enums.DatabaseProvider provider);

    [LoggerMessage(Level = LogLevel.Information, Message = "Found {ColumnCount} columns")]
    private partial void LogColumnsFound(int columnCount);
}
