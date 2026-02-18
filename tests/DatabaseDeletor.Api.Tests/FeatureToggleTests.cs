using DatabaseDeletor.Api.Configuration;

namespace DatabaseDeletor.Api.Tests;

public sealed class FeatureToggleTests
{
    [Fact]
    public void Defaults_SwaggerEnabled_IsTrue()
    {
        var toggles = new FeatureToggles();
        toggles.SwaggerEnabled.Should().BeTrue();
    }

    [Fact]
    public void Defaults_HealthCheckEnabled_IsTrue()
    {
        var toggles = new FeatureToggles();
        toggles.HealthCheckEnabled.Should().BeTrue();
    }

    [Fact]
    public void Defaults_DeletionEndpointsEnabled_IsTrue()
    {
        var toggles = new FeatureToggles();
        toggles.DeletionEndpointsEnabled.Should().BeTrue();
    }

    [Fact]
    public void Defaults_AnalysisEndpointsEnabled_IsTrue()
    {
        var toggles = new FeatureToggles();
        toggles.AnalysisEndpointsEnabled.Should().BeTrue();
    }

    [Fact]
    public void Defaults_NoExternalCommunication_IsFalse()
    {
        var toggles = new FeatureToggles();
        toggles.NoExternalCommunication.Should().BeFalse();
    }

    [Fact]
    public void SectionName_IsCorrect()
    {
        FeatureToggles.SectionName.Should().Be("FeatureToggles");
    }
}
