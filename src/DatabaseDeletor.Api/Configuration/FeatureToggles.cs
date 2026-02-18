namespace DatabaseDeletor.Api.Configuration;

internal sealed class FeatureToggles
{
    public const string SectionName = "FeatureToggles";

    public bool SwaggerEnabled { get; set; } = true;

    public bool HealthCheckEnabled { get; set; } = true;

    public bool DeletionEndpointsEnabled { get; set; } = true;

    public bool AnalysisEndpointsEnabled { get; set; } = true;

    public bool NoExternalCommunication { get; set; }
}
