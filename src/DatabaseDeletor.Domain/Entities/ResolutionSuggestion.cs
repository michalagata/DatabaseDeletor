namespace DatabaseDeletor.Domain.Entities;

public sealed class ResolutionSuggestion
{
    public required ResolutionAction Action { get; init; }
    public required TableInfo TargetTable { get; init; }
    public required string Description { get; init; }
}

public enum ResolutionAction
{
    IncludeInDeletion,
    ExcludeFromDeletion
}
