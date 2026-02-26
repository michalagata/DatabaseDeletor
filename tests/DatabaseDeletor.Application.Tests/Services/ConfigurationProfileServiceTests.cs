using DatabaseDeletor.Application.Services;
using DatabaseDeletor.Domain.Entities;

namespace DatabaseDeletor.Application.Tests.Services;

public sealed class ConfigurationProfileServiceTests
{
    private readonly ConfigurationProfileService _sut = new();

    [Fact]
    public void ExportToJson_ValidProfile_ReturnsValidJson()
    {
        var profile = CreateTestProfile();

        var json = _sut.ExportToJson(profile);

        json.Should().Contain("\"version\"");
        json.Should().Contain("\"connectionString\"");
        json.Should().Contain("\"deletionSettings\"");
    }

    [Fact]
    public void ImportFromJson_ValidJson_ReturnsProfile()
    {
        var profile = CreateTestProfile();
        var json = _sut.ExportToJson(profile);

        var result = _sut.ImportFromJson(json);

        result.Version.Should().Be("1.0");
        result.ConnectionString.Should().Be("Server=localhost;Database=Test");
        result.Sql.Should().Be("DELETE FROM dbo.Orders WHERE Status = 'Cancelled'");
    }

    [Fact]
    public void RoundTrip_ExportThenImport_ValuesMatch()
    {
        var original = CreateTestProfile();

        var json = _sut.ExportToJson(original);
        var restored = _sut.ImportFromJson(json);

        restored.Version.Should().Be(original.Version);
        restored.ConnectionString.Should().Be(original.ConnectionString);
        restored.Sql.Should().Be(original.Sql);
        restored.ExcludedTables.Should().BeEquivalentTo(original.ExcludedTables);
        restored.DeletionSettings.Mode.Should().Be(original.DeletionSettings.Mode);
        restored.DeletionSettings.BatchSize.Should().Be(original.DeletionSettings.BatchSize);
        restored.DeletionSettings.UseTransaction.Should().Be(original.DeletionSettings.UseTransaction);
    }

    [Fact]
    public void RoundTrip_WithScope_PreservesWhereConditions()
    {
        var original = new DeletionProfile
        {
            ConnectionString = "Server=localhost",
            Scope = new ScopeProfile
            {
                RootTable = "dbo.Orders",
                ScopeMode = "WhereCondition",
                WhereConditions =
                [
                    new WhereConditionProfile { Column = "Status", Operator = "=", Value = "'Cancelled'", LogicalOperator = "AND" },
                    new WhereConditionProfile { Column = "CreatedDate", Operator = "<", Value = "'2024-01-01'", LogicalOperator = "AND" }
                ]
            }
        };

        var json = _sut.ExportToJson(original);
        var restored = _sut.ImportFromJson(json);

        restored.Scope.Should().NotBeNull();
        restored.Scope!.WhereConditions.Should().HaveCount(2);
        restored.Scope.WhereConditions[0].Column.Should().Be("Status");
        restored.Scope.WhereConditions[1].Column.Should().Be("CreatedDate");
    }

    [Fact]
    public void ImportFromJson_InvalidJson_Throws()
    {
        var action = () => _sut.ImportFromJson("not valid json {{{");

        action.Should().Throw<InvalidOperationException>()
            .WithMessage("*Invalid JSON*");
    }

    [Fact]
    public void ImportFromJson_EmptyString_Throws()
    {
        var action = () => _sut.ImportFromJson("");

        action.Should().Throw<ArgumentException>();
    }

    [Fact]
    public void ImportFromJson_InvalidVersion_Throws()
    {
        var json = """
        {
            "version": "99.0",
            "connectionString": "Server=localhost",
            "deletionSettings": { "mode": "BatchDelete", "batchSize": 10000, "useTransaction": false }
        }
        """;

        var action = () => _sut.ImportFromJson(json);

        action.Should().Throw<InvalidOperationException>()
            .WithMessage("*Unsupported profile version*");
    }

    [Fact]
    public void ImportFromJson_InvalidBatchSize_TooSmall_Throws()
    {
        var json = """
        {
            "version": "1.0",
            "connectionString": "Server=localhost",
            "deletionSettings": { "mode": "BatchDelete", "batchSize": 5, "useTransaction": false }
        }
        """;

        var action = () => _sut.ImportFromJson(json);

        action.Should().Throw<InvalidOperationException>()
            .WithMessage("*Batch size*out of range*");
    }

    [Fact]
    public void ImportFromJson_InvalidBatchSize_TooLarge_Throws()
    {
        var json = """
        {
            "version": "1.0",
            "connectionString": "Server=localhost",
            "deletionSettings": { "mode": "BatchDelete", "batchSize": 99999999, "useTransaction": false }
        }
        """;

        var action = () => _sut.ImportFromJson(json);

        action.Should().Throw<InvalidOperationException>()
            .WithMessage("*Batch size*out of range*");
    }

    [Fact]
    public void ImportFromJson_InvalidDeletionMode_Throws()
    {
        var json = """
        {
            "version": "1.0",
            "connectionString": "Server=localhost",
            "deletionSettings": { "mode": "InvalidMode", "batchSize": 10000, "useTransaction": false }
        }
        """;

        var action = () => _sut.ImportFromJson(json);

        action.Should().Throw<InvalidOperationException>()
            .WithMessage("*Invalid deletion mode*");
    }

    [Fact]
    public void ExportToJson_NullProfile_Throws()
    {
        var action = () => _sut.ExportToJson(null!);

        action.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public async Task ExportToFileAsync_WritesJsonFile()
    {
        var profile = CreateTestProfile();
        var tempFile = Path.GetTempFileName();
        try
        {
            await _sut.ExportToFileAsync(profile, tempFile);

            var content = await File.ReadAllTextAsync(tempFile);
            content.Should().Contain("\"version\"");
            content.Should().Contain("\"connectionString\"");
        }
        finally
        {
            File.Delete(tempFile);
        }
    }

    [Fact]
    public async Task ImportFromFileAsync_ReadsJsonFile()
    {
        var profile = CreateTestProfile();
        var tempFile = Path.GetTempFileName();
        try
        {
            await _sut.ExportToFileAsync(profile, tempFile);
            var result = await _sut.ImportFromFileAsync(tempFile);

            result.ConnectionString.Should().Be("Server=localhost;Database=Test");
        }
        finally
        {
            File.Delete(tempFile);
        }
    }

    [Fact]
    public async Task ImportFromFileAsync_FileNotFound_Throws()
    {
        var action = () => _sut.ImportFromFileAsync("/nonexistent/path/config.json");

        await action.Should().ThrowAsync<FileNotFoundException>();
    }

    [Fact]
    public void ImportFromJson_MinimalValidProfile_Succeeds()
    {
        var json = """
        {
            "version": "1.0",
            "connectionString": "",
            "deletionSettings": { "mode": "BatchDelete", "batchSize": 10000, "useTransaction": false }
        }
        """;

        var result = _sut.ImportFromJson(json);

        result.Version.Should().Be("1.0");
    }

    private static DeletionProfile CreateTestProfile() => new()
    {
        ConnectionString = "Server=localhost;Database=Test",
        Sql = "DELETE FROM dbo.Orders WHERE Status = 'Cancelled'",
        ExcludedTables = ["dbo.AuditLog", "dbo.SystemConfig"],
        DeletionSettings = new DeletionSettingsProfile
        {
            Mode = "BatchDelete",
            BatchSize = 5000,
            UseTransaction = true
        }
    };
}
