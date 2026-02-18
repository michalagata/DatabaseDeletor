using DatabaseDeletor.Api.Configuration;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;

namespace DatabaseDeletor.Api.Tests;

public sealed class AppSettingsValidatorTests
{
    [Fact]
    public void AddAppSettingsValidation_NullConfiguration_ThrowsArgumentNullException()
    {
        var services = new ServiceCollection();
        var act = () => services.AddAppSettingsValidation(null!);
        act.Should().Throw<ArgumentNullException>().WithParameterName("configuration");
    }

    [Fact]
    public void AddAppSettingsValidation_EmptyConfig_RegistersFeatureTogglesWithDefaults()
    {
        var services = new ServiceCollection();
        var config = new ConfigurationBuilder()
            .AddInMemoryCollection()
            .Build();

        services.AddAppSettingsValidation(config);

        var sp = services.BuildServiceProvider();
        var options = sp.GetRequiredService<IOptions<FeatureToggles>>();

        options.Value.Should().NotBeNull();
        options.Value.SwaggerEnabled.Should().BeTrue();
        options.Value.HealthCheckEnabled.Should().BeTrue();
        options.Value.DeletionEndpointsEnabled.Should().BeTrue();
        options.Value.AnalysisEndpointsEnabled.Should().BeTrue();
        options.Value.NoExternalCommunication.Should().BeFalse();
    }

    [Fact]
    public void AddAppSettingsValidation_WithFeatureTogglesSection_BindsCorrectly()
    {
        var services = new ServiceCollection();
        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["FeatureToggles:SwaggerEnabled"] = "false",
                ["FeatureToggles:NoExternalCommunication"] = "true"
            })
            .Build();

        services.AddAppSettingsValidation(config);

        var sp = services.BuildServiceProvider();
        var options = sp.GetRequiredService<IOptions<FeatureToggles>>();

        options.Value.SwaggerEnabled.Should().BeFalse();
        options.Value.NoExternalCommunication.Should().BeTrue();
    }

    [Fact]
    public void AddAppSettingsValidation_ReturnsServiceCollection()
    {
        var services = new ServiceCollection();
        var config = new ConfigurationBuilder().AddInMemoryCollection().Build();

        var result = services.AddAppSettingsValidation(config);

        result.Should().BeSameAs(services);
    }

    [Fact]
    public void AddAppSettingsValidation_WithPartialConfig_DefaultsUnsetProperties()
    {
        var services = new ServiceCollection();
        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["FeatureToggles:SwaggerEnabled"] = "false"
            })
            .Build();

        services.AddAppSettingsValidation(config);

        var sp = services.BuildServiceProvider();
        var options = sp.GetRequiredService<IOptions<FeatureToggles>>();

        options.Value.SwaggerEnabled.Should().BeFalse();
        options.Value.HealthCheckEnabled.Should().BeTrue();
        options.Value.DeletionEndpointsEnabled.Should().BeTrue();
    }
}
