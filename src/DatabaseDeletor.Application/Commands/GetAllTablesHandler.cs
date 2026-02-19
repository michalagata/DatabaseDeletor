using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Interfaces;
using Microsoft.Extensions.Logging;

namespace DatabaseDeletor.Application.Commands;

public sealed partial class GetAllTablesHandler : IRequestHandler<GetAllTablesCommand, IReadOnlyList<TableInfo>>
{
    private readonly IDatabaseProviderResolver _providerResolver;
    private readonly IEnumerable<ISchemaIntrospector> _introspectors;
    private readonly ILogger<GetAllTablesHandler> _logger;

    public GetAllTablesHandler(
        IDatabaseProviderResolver providerResolver,
        IEnumerable<ISchemaIntrospector> introspectors,
        ILogger<GetAllTablesHandler> logger)
    {
        _providerResolver = providerResolver;
        _introspectors = introspectors;
        _logger = logger;
    }

    public async Task<IReadOnlyList<TableInfo>> HandleAsync(GetAllTablesCommand request, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        var provider = _providerResolver.Resolve(request.ConnectionString);
        var introspector = _introspectors.FirstOrDefault(i => i.Provider == provider)
            ?? throw new InvalidOperationException($"No schema introspector registered for provider {provider}");

        LogFetchingTables(provider);

        var tables = await introspector.GetAllTablesAsync(request.ConnectionString, ct).ConfigureAwait(false);

        LogTablesFound(tables.Count);

        return tables;
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Fetching all tables using {Provider} provider")]
    private partial void LogFetchingTables(DatabaseDeletor.Domain.Enums.DatabaseProvider provider);

    [LoggerMessage(Level = LogLevel.Information, Message = "Found {TableCount} tables")]
    private partial void LogTablesFound(int tableCount);
}
