using System.Net;
using Microsoft.AspNetCore.Mvc.Testing;

namespace DatabaseDeletor.Api.Tests;

public sealed class SwaggerTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public SwaggerTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task SwaggerJson_IsAccessible()
    {
        // Arrange
        var client = _factory.CreateClient();

        // Act
        var response = await client.GetAsync(new Uri("/swagger/v1/swagger.json", UriKind.Relative));

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task SwaggerJson_ContainsApiTitle()
    {
        // Arrange
        var client = _factory.CreateClient();

        // Act
        var response = await client.GetAsync(new Uri("/swagger/v1/swagger.json", UriKind.Relative));
        var content = await response.Content.ReadAsStringAsync();

        // Assert
        content.Should().Contain("DatabaseDeletor API");
    }

    [Fact]
    public async Task SwaggerJson_ContainsHealthCheckEndpoint()
    {
        // Arrange
        var client = _factory.CreateClient();

        // Act
        var response = await client.GetAsync(new Uri("/swagger/v1/swagger.json", UriKind.Relative));
        var content = await response.Content.ReadAsStringAsync();

        // Assert
        content.Should().Contain("/health");
    }
}
