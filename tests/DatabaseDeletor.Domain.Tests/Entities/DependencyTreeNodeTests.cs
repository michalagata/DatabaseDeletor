namespace DatabaseDeletor.Domain.Tests.Entities;

using DatabaseDeletor.Domain.Entities;

public sealed class DependencyTreeNodeTests
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
    public void BuildDependencyTree_SingleTable_ReturnsSingleNode()
    {
        var graph = new DependencyGraph();
        var table = CreateTable("dbo", "Users");
        graph.AddTable(table);

        var tree = graph.BuildDependencyTree(table);

        tree.Table.Should().Be(table);
        tree.Children.Should().BeEmpty();
        tree.Depth.Should().Be(0);
        tree.ParentForeignKey.Should().BeNull();
    }

    [Fact]
    public void BuildDependencyTree_TwoLevels_RootHasChildren()
    {
        var graph = new DependencyGraph();
        var users = CreateTable("dbo", "Users");
        var orders = CreateTable("dbo", "Orders");
        var fk = CreateForeignKey(orders, "UserId", users, "Id", "FK_Orders_Users");

        graph.AddForeignKey(fk);

        var tree = graph.BuildDependencyTree(users);

        tree.Table.Should().Be(users);
        tree.Depth.Should().Be(0);
        tree.Children.Should().HaveCount(1);
        tree.Children[0].Table.Should().Be(orders);
        tree.Children[0].Depth.Should().Be(1);
        tree.Children[0].ParentForeignKey.Should().Be(fk);
        tree.Children[0].Children.Should().BeEmpty();
    }

    [Fact]
    public void BuildDependencyTree_ThreeLevels_NestedChildren()
    {
        var graph = new DependencyGraph();
        var users = CreateTable("dbo", "Users");
        var orders = CreateTable("dbo", "Orders");
        var orderItems = CreateTable("dbo", "OrderItems");

        graph.AddForeignKey(CreateForeignKey(orders, "UserId", users, "Id", "FK_Orders_Users"));
        graph.AddForeignKey(CreateForeignKey(orderItems, "OrderId", orders, "Id", "FK_Items_Orders"));

        var tree = graph.BuildDependencyTree(users);

        tree.Table.Should().Be(users);
        tree.Depth.Should().Be(0);
        tree.Children.Should().HaveCount(1);

        var ordersNode = tree.Children[0];
        ordersNode.Table.Should().Be(orders);
        ordersNode.Depth.Should().Be(1);
        ordersNode.Children.Should().HaveCount(1);

        var itemsNode = ordersNode.Children[0];
        itemsNode.Table.Should().Be(orderItems);
        itemsNode.Depth.Should().Be(2);
        itemsNode.Children.Should().BeEmpty();
    }

    [Fact]
    public void BuildDependencyTree_CircularReference_HandledGracefully()
    {
        var graph = new DependencyGraph();
        var a = CreateTable("dbo", "A");
        var b = CreateTable("dbo", "B");

        graph.AddForeignKey(CreateForeignKey(b, "AId", a, "Id", "FK_B_A"));
        graph.AddForeignKey(CreateForeignKey(a, "BId", b, "Id", "FK_A_B"));

        var tree = graph.BuildDependencyTree(a);

        tree.Table.Should().Be(a);
        tree.Children.Should().HaveCount(1);
        tree.Children[0].Table.Should().Be(b);
        // B's child should be A again but with no further recursion (visited set prevents it)
        tree.Children[0].Children.Should().HaveCount(1);
        tree.Children[0].Children[0].Table.Should().Be(a);
        tree.Children[0].Children[0].Children.Should().BeEmpty();
    }

    [Fact]
    public void BuildDependencyTree_MultipleChildren_AllPresent()
    {
        var graph = new DependencyGraph();
        var users = CreateTable("dbo", "Users");
        var orders = CreateTable("dbo", "Orders");
        var addresses = CreateTable("dbo", "Addresses");

        graph.AddForeignKey(CreateForeignKey(orders, "UserId", users, "Id", "FK_Orders_Users"));
        graph.AddForeignKey(CreateForeignKey(addresses, "UserId", users, "Id", "FK_Addresses_Users"));

        var tree = graph.BuildDependencyTree(users);

        tree.Table.Should().Be(users);
        tree.Children.Should().HaveCount(2);
        tree.Children.Select(c => c.Table).Should().Contain(orders);
        tree.Children.Select(c => c.Table).Should().Contain(addresses);
    }

    [Fact]
    public void BuildDependencyTree_NullRootTable_ThrowsArgumentNullException()
    {
        var graph = new DependencyGraph();

        var act = () => graph.BuildDependencyTree(null!);

        act.Should().Throw<ArgumentNullException>();
    }
}
