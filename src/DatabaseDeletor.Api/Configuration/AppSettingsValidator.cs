using Microsoft.Extensions.Options;

namespace DatabaseDeletor.Api.Configuration;

internal static class AppSettingsValidator
{
    public static IServiceCollection AddAppSettingsValidation(this IServiceCollection services, IConfiguration configuration)
    {
        ArgumentNullException.ThrowIfNull(configuration);

        services.AddOptions<FeatureToggles>()
            .Bind(configuration.GetSection(FeatureToggles.SectionName))
            .ValidateDataAnnotations()
            .ValidateOnStart();

        return services;
    }
}
