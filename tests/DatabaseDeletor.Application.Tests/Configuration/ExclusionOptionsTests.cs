using DatabaseDeletor.Application.Configuration;

namespace DatabaseDeletor.Application.Tests.Configuration;

public sealed class ExclusionOptionsTests
{
    [Fact]
    public void GetParsedTables_EmptyString_ReturnsEmpty()
    {
        var options = new ExclusionOptions { GlobalExcludedTables = "" };
        var result = options.GetParsedTables();
        Assert.Empty(result);
    }

    [Fact]
    public void GetParsedTables_SingleTable_ReturnsSingle()
    {
        var options = new ExclusionOptions { GlobalExcludedTables = "dbo.AuditLog" };
        var result = options.GetParsedTables();
        Assert.Single(result);
        Assert.Equal("dbo", result[0].Schema);
        Assert.Equal("AuditLog", result[0].Name);
    }

    [Fact]
    public void GetParsedTables_MultipleTables_ReturnsAll()
    {
        var options = new ExclusionOptions { GlobalExcludedTables = "dbo.AuditLog,dbo.SystemConfig,public.migrations" };
        var result = options.GetParsedTables();
        Assert.Equal(3, result.Count);
        Assert.Equal("AuditLog", result[0].Name);
        Assert.Equal("SystemConfig", result[1].Name);
        Assert.Equal("migrations", result[2].Name);
    }

    [Fact]
    public void GetParsedTables_WithSpaces_TrimsCorrectly()
    {
        var options = new ExclusionOptions { GlobalExcludedTables = " dbo.AuditLog , dbo.SystemConfig " };
        var result = options.GetParsedTables();
        Assert.Equal(2, result.Count);
        Assert.Equal("AuditLog", result[0].Name);
        Assert.Equal("SystemConfig", result[1].Name);
    }

    [Fact]
    public void SectionName_IsExclusion()
    {
        Assert.Equal("Exclusion", ExclusionOptions.SectionName);
    }

    [Fact]
    public void GetParsedTables_DefaultValue_ReturnsEmpty()
    {
        var options = new ExclusionOptions();
        var result = options.GetParsedTables();
        Assert.Empty(result);
    }
}
