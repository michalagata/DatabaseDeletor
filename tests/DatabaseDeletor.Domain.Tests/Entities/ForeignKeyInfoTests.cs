namespace DatabaseDeletor.Domain.Tests.Entities;

using DatabaseDeletor.Domain.Entities;

public sealed class ForeignKeyInfoTests
{
    private static TableInfo UsersTable => new() { Schema = "dbo", Name = "Users" };
    private static TableInfo OrdersTable => new() { Schema = "dbo", Name = "Orders" };

    [Fact]
    public void ConstraintName_ReturnsAssignedValue()
    {
        var fk = new ForeignKeyInfo
        {
            ConstraintName = "FK_Orders_Users",
            ReferencingTable = OrdersTable,
            ReferencingColumn = "UserId",
            ReferencedTable = UsersTable,
            ReferencedColumn = "Id",
            DeleteRule = "NO ACTION"
        };

        fk.ConstraintName.Should().Be("FK_Orders_Users");
    }

    [Fact]
    public void ReferencingTable_ReturnsAssignedValue()
    {
        var fk = new ForeignKeyInfo
        {
            ConstraintName = "FK_Orders_Users",
            ReferencingTable = OrdersTable,
            ReferencingColumn = "UserId",
            ReferencedTable = UsersTable,
            ReferencedColumn = "Id",
            DeleteRule = "NO ACTION"
        };

        fk.ReferencingTable.Name.Should().Be("Orders");
        fk.ReferencingTable.Schema.Should().Be("dbo");
    }

    [Fact]
    public void ReferencedTable_ReturnsAssignedValue()
    {
        var fk = new ForeignKeyInfo
        {
            ConstraintName = "FK_Orders_Users",
            ReferencingTable = OrdersTable,
            ReferencingColumn = "UserId",
            ReferencedTable = UsersTable,
            ReferencedColumn = "Id",
            DeleteRule = "NO ACTION"
        };

        fk.ReferencedTable.Name.Should().Be("Users");
        fk.ReferencedTable.Schema.Should().Be("dbo");
    }

    [Fact]
    public void ReferencingColumn_ReturnsAssignedValue()
    {
        var fk = new ForeignKeyInfo
        {
            ConstraintName = "FK_Orders_Users",
            ReferencingTable = OrdersTable,
            ReferencingColumn = "UserId",
            ReferencedTable = UsersTable,
            ReferencedColumn = "Id",
            DeleteRule = "CASCADE"
        };

        fk.ReferencingColumn.Should().Be("UserId");
    }

    [Fact]
    public void ReferencedColumn_ReturnsAssignedValue()
    {
        var fk = new ForeignKeyInfo
        {
            ConstraintName = "FK_Orders_Users",
            ReferencingTable = OrdersTable,
            ReferencingColumn = "UserId",
            ReferencedTable = UsersTable,
            ReferencedColumn = "Id",
            DeleteRule = "CASCADE"
        };

        fk.ReferencedColumn.Should().Be("Id");
    }

    [Fact]
    public void DeleteRule_ReturnsAssignedValue()
    {
        var fk = new ForeignKeyInfo
        {
            ConstraintName = "FK_Orders_Users",
            ReferencingTable = OrdersTable,
            ReferencingColumn = "UserId",
            ReferencedTable = UsersTable,
            ReferencedColumn = "Id",
            DeleteRule = "CASCADE"
        };

        fk.DeleteRule.Should().Be("CASCADE");
    }

    [Theory]
    [InlineData("NO ACTION")]
    [InlineData("CASCADE")]
    [InlineData("SET NULL")]
    [InlineData("SET DEFAULT")]
    public void DeleteRule_AcceptsAllStandardValues(string deleteRule)
    {
        var fk = new ForeignKeyInfo
        {
            ConstraintName = "FK_Test",
            ReferencingTable = OrdersTable,
            ReferencingColumn = "UserId",
            ReferencedTable = UsersTable,
            ReferencedColumn = "Id",
            DeleteRule = deleteRule
        };

        fk.DeleteRule.Should().Be(deleteRule);
    }
}
