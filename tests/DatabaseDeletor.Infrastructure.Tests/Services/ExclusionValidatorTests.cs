namespace DatabaseDeletor.Infrastructure.Tests.Services;

using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Enums;
using DatabaseDeletor.Domain.Interfaces;
using DatabaseDeletor.Infrastructure.Services;
using Microsoft.Extensions.Logging;

public sealed class ExclusionValidatorTests
{
    private readonly IDatabaseProviderResolver _providerResolver = Substitute.For<IDatabaseProviderResolver>();
    private readonly ISchemaIntrospector _introspector = Substitute.For<ISchemaIntrospector>();
    private readonly ILogger<ExclusionValidator> _logger = Substitute.For<ILogger<ExclusionValidator>>();
    private readonly ExclusionValidator _sut;

    public ExclusionValidatorTests()
    {
        _introspector.Provider.Returns(DatabaseProvider.SqlServer);
        _providerResolver.Resolve(Arg.Any<string>()).Returns(DatabaseProvider.SqlServer);

        _sut = new ExclusionValidator(_providerResolver, [_introspector], _logger);
    }

    [Fact]
    public async Task ValidateAsync_NoExcludedTables_ReturnsValidWithEmptySuggestions()
    {
        var selected = new List<TableInfo>
        {
            new() { Schema = "dbo", Name = "Users" }
        };

        var result = await _sut.ValidateAsync("conn", selected, [], CancellationToken.None);

        result.IsValid.Should().BeTrue();
        result.Suggestions.Should().BeEmpty();
        result.Conflicts.Should().BeEmpty();
    }

    [Fact]
    public async Task ValidateAsync_OutgoingFkConflict_GeneratesIncludeSuggestion()
    {
        // Orders (selected) has an FK referencing Customers (excluded).
        var orders = new TableInfo { Schema = "dbo", Name = "Orders" };
        var customers = new TableInfo { Schema = "dbo", Name = "Customers" };

        var outgoingFk = new ForeignKeyInfo
        {
            ConstraintName = "FK_Orders_Customers",
            ReferencingTable = orders,
            ReferencingColumn = "CustomerId",
            ReferencedTable = customers,
            ReferencedColumn = "Id",
            DeleteRule = "NO ACTION"
        };

        _introspector.GetForeignKeysAsync("conn", "dbo", "Orders", Arg.Any<CancellationToken>())
            .Returns(new List<ForeignKeyInfo> { outgoingFk });

        _introspector.GetReferencingForeignKeysAsync("conn", "dbo", "Orders", Arg.Any<CancellationToken>())
            .Returns(new List<ForeignKeyInfo>());

        var result = await _sut.ValidateAsync("conn", [orders], [customers], CancellationToken.None);

        result.IsValid.Should().BeFalse();
        result.Conflicts.Should().HaveCount(1);

        result.Suggestions.Should().HaveCount(1);
        result.Suggestions[0].Action.Should().Be(ResolutionAction.IncludeInDeletion);
        result.Suggestions[0].TargetTable.Should().Be(customers);
    }

    [Fact]
    public async Task ValidateAsync_IncomingFkConflict_GeneratesBothSuggestions()
    {
        // Users (selected) is referenced by Audit (excluded) via a non-CASCADE FK.
        var users = new TableInfo { Schema = "dbo", Name = "Users" };
        var audit = new TableInfo { Schema = "dbo", Name = "Audit" };

        var incomingFk = new ForeignKeyInfo
        {
            ConstraintName = "FK_Audit_Users",
            ReferencingTable = audit,
            ReferencingColumn = "UserId",
            ReferencedTable = users,
            ReferencedColumn = "Id",
            DeleteRule = "NO ACTION"
        };

        _introspector.GetForeignKeysAsync("conn", "dbo", "Users", Arg.Any<CancellationToken>())
            .Returns(new List<ForeignKeyInfo>());

        _introspector.GetReferencingForeignKeysAsync("conn", "dbo", "Users", Arg.Any<CancellationToken>())
            .Returns(new List<ForeignKeyInfo> { incomingFk });

        var result = await _sut.ValidateAsync("conn", [users], [audit], CancellationToken.None);

        result.IsValid.Should().BeFalse();
        result.Conflicts.Should().HaveCount(1);

        result.Suggestions.Should().HaveCount(2);

        result.Suggestions.Should().Contain(s =>
            s.Action == ResolutionAction.IncludeInDeletion &&
            s.TargetTable.Equals(audit));

        result.Suggestions.Should().Contain(s =>
            s.Action == ResolutionAction.ExcludeFromDeletion &&
            s.TargetTable.Equals(users));
    }
}
