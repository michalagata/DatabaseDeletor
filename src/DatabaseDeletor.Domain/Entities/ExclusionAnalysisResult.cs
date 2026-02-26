namespace DatabaseDeletor.Domain.Entities;

public sealed class ExclusionAnalysisResult
{
    public required bool IsValid { get; init; }
    public required IReadOnlyList<ExclusionConflict> Conflicts { get; init; }
    public required IReadOnlyList<string> Recommendations { get; init; }
    public required IReadOnlyList<ResolutionSuggestion> Suggestions { get; init; }
}
