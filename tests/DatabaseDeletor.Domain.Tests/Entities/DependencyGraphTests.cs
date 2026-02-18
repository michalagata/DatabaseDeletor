namespace DatabaseDeletor.Domain.Tests.Entities;

using DatabaseDeletor.Domain.Entities;

public sealed class DependencyGraphTests
{
    private static TableInfo CreateTable(string schema, string name) =>
        new() { Schema = schema, Name = name };

    private static ForeignKeyInfo CreateForeignKey(
        TableInfo referencing, string referencingCol,
        TableInfo referenced, string referencedCol,
        string constraintName = "FK_Test",
        string deleteRule = "NO ACTION") =>
        new()
        {
            ConstraintName = constraintName,
            ReferencingTable = referencing,
            ReferencingColumn = referencingCol,
            ReferencedTable = referenced,
            ReferencedColumn = referencedCol,
            DeleteRule = deleteRule
        };

    [Fact]
    public void AddTable_AddsTableToGraph()
    {
        var graph = new DependencyGraph();
        var table = CreateTable("dbo", "Users");

        graph.AddTable(table);

        graph.Tables.Should().HaveCount(1);
        graph.Tables.Should().Contain(table);
    }

    [Fact]
    public void AddTable_DuplicateTable_DoesNotAddTwice()
    {
        var graph = new DependencyGraph();
        var table = CreateTable("dbo", "Users");

        graph.AddTable(table);
        graph.AddTable(table);

        graph.Tables.Should().HaveCount(1);
    }

    [Fact]
    public void AddTable_NullTable_ThrowsArgumentNullException()
    {
        var graph = new DependencyGraph();

        var act = () => graph.AddTable(null!);

        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public void AddForeignKey_AddsBothTablesAndRelationship()
    {
        var graph = new DependencyGraph();
        var orders = CreateTable("dbo", "Orders");
        var users = CreateTable("dbo", "Users");
        var fk = CreateForeignKey(orders, "UserId", users, "Id");

        graph.AddForeignKey(fk);

        graph.Tables.Should().HaveCount(2);
        graph.Tables.Should().Contain(orders);
        graph.Tables.Should().Contain(users);
    }

    [Fact]
    public void AddForeignKey_NullForeignKey_ThrowsArgumentNullException()
    {
        var graph = new DependencyGraph();

        var act = () => graph.AddForeignKey(null!);

        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public void GetIncomingReferences_ReturnsReferencesToTable()
    {
        var graph = new DependencyGraph();
        var users = CreateTable("dbo", "Users");
        var orders = CreateTable("dbo", "Orders");
        var fk = CreateForeignKey(orders, "UserId", users, "Id");

        graph.AddForeignKey(fk);

        var incoming = graph.GetIncomingReferences(users);

        incoming.Should().HaveCount(1);
        incoming[0].ReferencingTable.Should().Be(orders);
    }

    [Fact]
    public void GetOutgoingReferences_ReturnsReferencesFromTable()
    {
        var graph = new DependencyGraph();
        var users = CreateTable("dbo", "Users");
        var orders = CreateTable("dbo", "Orders");
        var fk = CreateForeignKey(orders, "UserId", users, "Id");

        graph.AddForeignKey(fk);

        var outgoing = graph.GetOutgoingReferences(orders);

        outgoing.Should().HaveCount(1);
        outgoing[0].ReferencedTable.Should().Be(users);
    }

    [Fact]
    public void GetIncomingReferences_UnknownTable_ReturnsEmpty()
    {
        var graph = new DependencyGraph();
        var unknown = CreateTable("dbo", "Unknown");

        var incoming = graph.GetIncomingReferences(unknown);

        incoming.Should().BeEmpty();
    }

    [Fact]
    public void GetTopologicalDeletionOrder_SingleTable_ReturnsSingleTable()
    {
        var graph = new DependencyGraph();
        var table = CreateTable("dbo", "Users");
        graph.AddTable(table);

        var order = graph.GetTopologicalDeletionOrder(table);

        order.Should().HaveCount(1);
        order[0].Should().Be(table);
    }

    [Fact]
    public void GetTopologicalDeletionOrder_ParentChild_ChildDeletedFirst()
    {
        var graph = new DependencyGraph();
        var users = CreateTable("dbo", "Users");
        var orders = CreateTable("dbo", "Orders");
        var fk = CreateForeignKey(orders, "UserId", users, "Id");

        graph.AddForeignKey(fk);

        var order = graph.GetTopologicalDeletionOrder(users);

        order.Should().HaveCount(2);
        order[0].Should().Be(orders);
        order[1].Should().Be(users);
    }

    [Fact]
    public void GetTopologicalDeletionOrder_ThreeLevels_DeletesLeafFirst()
    {
        var graph = new DependencyGraph();
        var users = CreateTable("dbo", "Users");
        var orders = CreateTable("dbo", "Orders");
        var orderItems = CreateTable("dbo", "OrderItems");

        graph.AddForeignKey(CreateForeignKey(orders, "UserId", users, "Id", "FK_Orders_Users"));
        graph.AddForeignKey(CreateForeignKey(orderItems, "OrderId", orders, "Id", "FK_Items_Orders"));

        var order = graph.GetTopologicalDeletionOrder(users);

        order.Should().HaveCount(3);
        order[0].Should().Be(orderItems);
        order[1].Should().Be(orders);
        order[2].Should().Be(users);
    }

    [Fact]
    public void GetTopologicalDeletionOrder_CircularReference_HandledGracefully()
    {
        var graph = new DependencyGraph();
        var a = CreateTable("dbo", "A");
        var b = CreateTable("dbo", "B");

        graph.AddForeignKey(CreateForeignKey(b, "AId", a, "Id", "FK_B_A"));
        graph.AddForeignKey(CreateForeignKey(a, "BId", b, "Id", "FK_A_B"));

        var order = graph.GetTopologicalDeletionOrder(a);

        order.Should().HaveCount(2);
        order.Should().Contain(a);
        order.Should().Contain(b);
    }
}
