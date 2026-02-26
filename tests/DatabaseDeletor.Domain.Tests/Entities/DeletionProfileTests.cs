using DatabaseDeletor.Domain.Entities;

namespace DatabaseDeletor.Domain.Tests.Entities;

public sealed class DeletionProfileTests
{
    [Fact]
    public void DefaultProfile_HasCorrectVersion()
    {
        var profile = new DeletionProfile();

        profile.Version.Should().Be("1.0");
    }

    [Fact]
    public void DefaultProfile_HasEmptyConnectionString()
    {
        var profile = new DeletionProfile();

        profile.ConnectionString.Should().BeEmpty();
    }

    [Fact]
    public void DefaultProfile_HasNullSql()
    {
        var profile = new DeletionProfile();

        profile.Sql.Should().BeNull();
    }

    [Fact]
    public void DefaultProfile_HasEmptyExcludedTables()
    {
        var profile = new DeletionProfile();

        profile.ExcludedTables.Should().BeEmpty();
    }

    [Fact]
    public void DefaultProfile_HasDefaultDeletionSettings()
    {
        var profile = new DeletionProfile();

        profile.DeletionSettings.Mode.Should().Be("BatchDelete");
        profile.DeletionSettings.BatchSize.Should().Be(DeletionOptions.DefaultBatchSize);
        profile.DeletionSettings.UseTransaction.Should().BeFalse();
    }

    [Fact]
    public void DefaultProfile_HasNullScope()
    {
        var profile = new DeletionProfile();

        profile.Scope.Should().BeNull();
    }

    [Fact]
    public void Profile_WithAllFields_RetainsValues()
    {
        var profile = new DeletionProfile
        {
            ConnectionString = "Server=localhost;Database=Test",
            Sql = "DELETE FROM dbo.Orders WHERE Status = 'Cancelled'",
            ExcludedTables = ["dbo.AuditLog", "dbo.SystemConfig"],
            DeletionSettings = new DeletionSettingsProfile
            {
                Mode = "SingleRowDelete",
                BatchSize = 5000,
                UseTransaction = true
            },
            Scope = new ScopeProfile
            {
                RootTable = "dbo.Orders",
                ScopeMode = "WhereCondition",
                WhereConditions =
                [
                    new WhereConditionProfile
                    {
                        Column = "Status",
                        Operator = "=",
                        Value = "'Cancelled'",
                        LogicalOperator = "AND"
                    }
                ],
                CustomSql = null
            }
        };

        profile.ConnectionString.Should().Be("Server=localhost;Database=Test");
        profile.Sql.Should().Be("DELETE FROM dbo.Orders WHERE Status = 'Cancelled'");
        profile.ExcludedTables.Should().HaveCount(2);
        profile.DeletionSettings.Mode.Should().Be("SingleRowDelete");
        profile.DeletionSettings.BatchSize.Should().Be(5000);
        profile.DeletionSettings.UseTransaction.Should().BeTrue();
        profile.Scope.Should().NotBeNull();
        profile.Scope!.RootTable.Should().Be("dbo.Orders");
        profile.Scope.ScopeMode.Should().Be("WhereCondition");
        profile.Scope.WhereConditions.Should().HaveCount(1);
        profile.Scope.WhereConditions[0].Column.Should().Be("Status");
    }

    [Fact]
    public void CurrentVersion_IsOne()
    {
        DeletionProfile.CurrentVersion.Should().Be("1.0");
    }

    [Fact]
    public void WhereConditionProfile_Defaults_AreCorrect()
    {
        var condition = new WhereConditionProfile();

        condition.Column.Should().BeEmpty();
        condition.Operator.Should().Be("=");
        condition.Value.Should().BeEmpty();
        condition.LogicalOperator.Should().Be("AND");
    }

    [Fact]
    public void ScopeProfile_Defaults_AreCorrect()
    {
        var scope = new ScopeProfile();

        scope.RootTable.Should().BeEmpty();
        scope.ScopeMode.Should().Be("DeleteAll");
        scope.WhereConditions.Should().BeEmpty();
        scope.CustomSql.Should().BeNull();
    }

    [Fact]
    public void DeletionSettingsProfile_Defaults_AreCorrect()
    {
        var settings = new DeletionSettingsProfile();

        settings.Mode.Should().Be("BatchDelete");
        settings.BatchSize.Should().Be(DeletionOptions.DefaultBatchSize);
        settings.UseTransaction.Should().BeFalse();
    }
}
