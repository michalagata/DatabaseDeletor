using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Interfaces;

namespace DatabaseDeletor.Application.Commands;

public sealed record GenerateDeletionPlanCommand(
    string ConnectionString,
    DependencyGraph Graph,
    TableInfo RootTable,
    string? WhereClause) : IRequest<DeletionPlan>;
