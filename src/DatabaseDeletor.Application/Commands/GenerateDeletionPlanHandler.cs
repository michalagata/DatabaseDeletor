using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Interfaces;
using Microsoft.Extensions.Logging;

namespace DatabaseDeletor.Application.Commands;

public sealed partial class GenerateDeletionPlanHandler : IRequestHandler<GenerateDeletionPlanCommand, DeletionPlan>
{
    private readonly IDeletionPlanGenerator _planGenerator;
    private readonly ILogger<GenerateDeletionPlanHandler> _logger;

    public GenerateDeletionPlanHandler(IDeletionPlanGenerator planGenerator, ILogger<GenerateDeletionPlanHandler> logger)
    {
        _planGenerator = planGenerator;
        _logger = logger;
    }

    public async Task<DeletionPlan> HandleAsync(GenerateDeletionPlanCommand request, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        LogGenerating(request.RootTable.FullName, request.WhereClause ?? "(all rows)");

        var plan = await _planGenerator.GenerateAsync(
            request.ConnectionString,
            request.Graph,
            request.RootTable,
            request.WhereClause,
            ct).ConfigureAwait(false);

        LogGenerated(plan.Steps.Count, plan.TotalEstimatedRows);

        return plan;
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Generating deletion plan for {Table} with WHERE: {Where}")]
    private partial void LogGenerating(string table, string where);

    [LoggerMessage(Level = LogLevel.Information, Message = "Deletion plan generated: {StepCount} steps, ~{RowCount} estimated rows")]
    private partial void LogGenerated(int stepCount, long rowCount);
}
