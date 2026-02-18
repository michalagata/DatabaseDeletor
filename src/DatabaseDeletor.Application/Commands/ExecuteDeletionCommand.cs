using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Interfaces;

namespace DatabaseDeletor.Application.Commands;

public sealed record ExecuteDeletionCommand(
    string ConnectionString,
    DeletionPlan Plan,
    IProgress<DeletionProgress>? Progress = null) : IRequest<DeletionReport>;
