using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Interfaces;
using Microsoft.Extensions.Logging;

namespace DatabaseDeletor.Application.Commands;

public sealed partial class ValidateExclusionsHandler : IRequestHandler<ValidateExclusionsCommand, ExclusionAnalysisResult>
{
    private readonly IExclusionValidator _validator;
    private readonly ILogger<ValidateExclusionsHandler> _logger;

    public ValidateExclusionsHandler(IExclusionValidator validator, ILogger<ValidateExclusionsHandler> logger)
    {
        _validator = validator;
        _logger = logger;
    }

    public async Task<ExclusionAnalysisResult> HandleAsync(ValidateExclusionsCommand request, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        LogValidating(request.ExcludedTables.Count);

        var result = await _validator.ValidateAsync(
            request.ConnectionString,
            request.SelectedTables,
            request.ExcludedTables,
            ct).ConfigureAwait(false);

        if (result.IsValid)
            LogValid();
        else
            LogConflicts(result.Conflicts.Count);

        return result;
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Validating {ExcludedCount} table exclusion(s)")]
    private partial void LogValidating(int excludedCount);

    [LoggerMessage(Level = LogLevel.Information, Message = "Exclusion validation passed — no FK conflicts")]
    private partial void LogValid();

    [LoggerMessage(Level = LogLevel.Warning, Message = "Exclusion validation found {ConflictCount} FK conflict(s)")]
    private partial void LogConflicts(int conflictCount);
}
