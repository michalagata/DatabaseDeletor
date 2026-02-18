using System.Globalization;
using DatabaseDeletor.Application;
using DatabaseDeletor.Infrastructure;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

builder.Host.UseSerilog((_, configuration) =>
{
    configuration
        .MinimumLevel.Information()
        .Enrich.FromLogContext()
        .Enrich.WithEnvironmentName()
        .WriteTo.Console(formatProvider: CultureInfo.InvariantCulture);
});

builder.Services.AddApplication();
builder.Services.AddInfrastructure();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new() { Title = "DatabaseDeletor API", Version = "v1" });
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.MapGet("/health", () => Results.Ok(new { Status = "Healthy", Timestamp = DateTime.UtcNow }))
    .WithName("HealthCheck")
    .WithTags("Health");

app.Run();

namespace DatabaseDeletor.Api
{
#pragma warning disable CA1812, CA1852 // Partial Program class required for WebApplicationFactory<Program> in integration tests
    internal sealed partial class Program;
#pragma warning restore CA1812, CA1852
}
