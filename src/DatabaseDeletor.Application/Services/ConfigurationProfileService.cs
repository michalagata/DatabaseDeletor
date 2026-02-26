using System.Text.Json;
using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Enums;

namespace DatabaseDeletor.Application.Services;

public interface IConfigurationProfileService
{
    string ExportToJson(DeletionProfile profile);
    DeletionProfile ImportFromJson(string json);
    Task ExportToFileAsync(DeletionProfile profile, string filePath, CancellationToken ct = default);
    Task<DeletionProfile> ImportFromFileAsync(string filePath, CancellationToken ct = default);
}

public sealed class ConfigurationProfileService : IConfigurationProfileService
{
    private static readonly JsonSerializerOptions SerializerOptions = new()
    {
        WriteIndented = true,
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase
    };

    public string ExportToJson(DeletionProfile profile)
    {
        ArgumentNullException.ThrowIfNull(profile);
        return JsonSerializer.Serialize(profile, SerializerOptions);
    }

    public DeletionProfile ImportFromJson(string json)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(json);

        DeletionProfile profile;
        try
        {
            profile = JsonSerializer.Deserialize<DeletionProfile>(json, SerializerOptions)
                ?? throw new InvalidOperationException("Deserialized profile is null.");
        }
        catch (JsonException ex)
        {
            throw new InvalidOperationException("Invalid JSON format for configuration profile.", ex);
        }

        Validate(profile);
        return profile;
    }

    public async Task ExportToFileAsync(DeletionProfile profile, string filePath, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(profile);
        ArgumentException.ThrowIfNullOrWhiteSpace(filePath);

        var json = ExportToJson(profile);
        await File.WriteAllTextAsync(filePath, json, ct).ConfigureAwait(false);
    }

    public async Task<DeletionProfile> ImportFromFileAsync(string filePath, CancellationToken ct = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(filePath);

        if (!File.Exists(filePath))
            throw new FileNotFoundException($"Configuration file not found: {filePath}", filePath);

        var json = await File.ReadAllTextAsync(filePath, ct).ConfigureAwait(false);
        return ImportFromJson(json);
    }

    private static void Validate(DeletionProfile profile)
    {
        if (!string.Equals(profile.Version, DeletionProfile.CurrentVersion, StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException(
                $"Unsupported profile version '{profile.Version}'. Expected '{DeletionProfile.CurrentVersion}'.");
        }

        ValidateDeletionSettings(profile.DeletionSettings);
    }

    private static void ValidateDeletionSettings(DeletionSettingsProfile settings)
    {
        if (!Enum.TryParse<DeletionMode>(settings.Mode, ignoreCase: true, out _))
        {
            throw new InvalidOperationException(
                $"Invalid deletion mode '{settings.Mode}'. Valid values: {string.Join(", ", Enum.GetNames<DeletionMode>())}.");
        }

        if (settings.BatchSize < DeletionOptions.MinBatchSize || settings.BatchSize > DeletionOptions.MaxBatchSize)
        {
            throw new InvalidOperationException(
                $"Batch size {settings.BatchSize} is out of range. Must be between {DeletionOptions.MinBatchSize} and {DeletionOptions.MaxBatchSize:N0}.");
        }
    }
}
