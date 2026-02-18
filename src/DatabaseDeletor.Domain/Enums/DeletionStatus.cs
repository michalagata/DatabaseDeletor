namespace DatabaseDeletor.Domain.Enums;

public enum DeletionStatus
{
    Pending,
    AnalyzingDependencies,
    PlanGenerated,
    AwaitingConfirmation,
    Executing,
    Completed,
    Failed,
    Cancelled
}
