using DatabaseDeletor.Cli;
using DatabaseDeletor.Domain.Entities;

namespace DatabaseDeletor.Cli.Tests;

public sealed class ConsoleRendererTests
{
    private static TableInfo TestTable => new() { Schema = "dbo", Name = "Users" };

    [Fact]
    public void WriteDeletionPlan_NullPlan_ThrowsArgumentNullException()
    {
        var act = () => ConsoleRenderer.WriteDeletionPlan(null!);
        act.Should().Throw<ArgumentNullException>().WithParameterName("plan");
    }

    [Fact]
    public void WriteDeletionReport_NullReport_ThrowsArgumentNullException()
    {
        var act = () => ConsoleRenderer.WriteDeletionReport(null!);
        act.Should().Throw<ArgumentNullException>().WithParameterName("report");
    }

    [Fact]
    public void WriteDeletionPlan_WithValidPlan_DoesNotThrow()
    {
        var plan = new DeletionPlan
        {
            RootTable = TestTable,
            WhereClause = "Id = 1",
            Steps =
            [
                new DeletionStep
                {
                    Order = 0,
                    Table = TestTable,
                    DeleteSql = "DELETE FROM dbo.Users WHERE Id = 1",
                    EstimatedRowCount = 1
                }
            ]
        };

        var act = () => ConsoleRenderer.WriteDeletionPlan(plan);
        act.Should().NotThrow();
    }

    [Fact]
    public void WriteDeletionReport_WithValidReport_DoesNotThrow()
    {
        var report = new DeletionReport
        {
            RootTable = TestTable,
            StartedAt = DateTime.UtcNow.AddSeconds(-1),
            CompletedAt = DateTime.UtcNow,
            Results =
            [
                new DeletionStepResult
                {
                    Table = TestTable,
                    DeletedCount = 10,
                    Duration = TimeSpan.FromMilliseconds(100)
                }
            ]
        };

        var act = () => ConsoleRenderer.WriteDeletionReport(report);
        act.Should().NotThrow();
    }

    [Fact]
    public void WriteDeletionReport_WithErrors_DoesNotThrow()
    {
        var report = new DeletionReport
        {
            RootTable = TestTable,
            StartedAt = DateTime.UtcNow.AddSeconds(-1),
            CompletedAt = DateTime.UtcNow,
            Results =
            [
                new DeletionStepResult
                {
                    Table = TestTable,
                    DeletedCount = 0,
                    Duration = TimeSpan.FromMilliseconds(50),
                    ErrorMessage = "FK constraint violation"
                }
            ]
        };

        var act = () => ConsoleRenderer.WriteDeletionReport(report);
        act.Should().NotThrow();
    }

    [Fact]
    public void WriteDeletionPlan_WithLongSql_DoesNotThrow()
    {
        var longSql = "DELETE FROM dbo.Users WHERE Id IN (SELECT Id FROM dbo.Users WHERE CreatedDate < '2024-01-01' AND Status = 'Inactive')";

        var plan = new DeletionPlan
        {
            RootTable = TestTable,
            WhereClause = "Id IN (...)",
            Steps =
            [
                new DeletionStep
                {
                    Order = 0,
                    Table = TestTable,
                    DeleteSql = longSql,
                    EstimatedRowCount = 5000
                }
            ]
        };

        var act = () => ConsoleRenderer.WriteDeletionPlan(plan);
        act.Should().NotThrow();
    }
}
