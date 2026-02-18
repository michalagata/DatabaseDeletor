using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Interfaces;
using Microsoft.Extensions.Logging;

namespace DatabaseDeletor.Application.Commands;

public sealed class GenerateDeletionPlanHandler : IRequestHandler<GenerateDeletionPlanCommand, DeletionPlan>
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
        _logger.LogInformation(
            "Generating deletion plan for {Table} with WHERE: {Where}",
            request.RootTable.FullName, request.WhereClause ?? "(all rows)");

        var plan = await _planGenerator.GenerateAsync(
            request.ConnectionString,
            request.Graph,
            request.RootTable,
            request.WhereClause,
            ct).ConfigureAwait(false);

        _logger.LogInformation(
            "Deletion plan generated: {StepCount} steps, ~{RowCount} estimated rows",
            plan.Steps.Count, plan.TotalEstimatedRows);

        return plan;
    }
}
