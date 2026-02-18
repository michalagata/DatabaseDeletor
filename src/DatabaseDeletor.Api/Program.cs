using System.Globalization;
using DatabaseDeletor.Api.Configuration;
using DatabaseDeletor.Application;
using DatabaseDeletor.Infrastructure;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

// --- Serilog ---
builder.Host.UseSerilog((context, configuration) =>
{
    configuration
        .ReadFrom.Configuration(context.Configuration)
        .Enrich.FromLogContext()
        .Enrich.WithEnvironmentName()
        .WriteTo.Console(formatProvider: CultureInfo.InvariantCulture);
});

// --- Feature Toggles ---
builder.Services.AddAppSettingsValidation(builder.Configuration);

var toggles = builder.Configuration
    .GetSection(FeatureToggles.SectionName)
    .Get<FeatureToggles>() ?? new FeatureToggles();

// --- Application / Infrastructure DI ---
builder.Services.AddApplication();
builder.Services.AddInfrastructure();

// --- OpenTelemetry (conditional on NoExternalCommunication) ---
if (!toggles.NoExternalCommunication)
{
    builder.Services.AddOpenTelemetry()
        .ConfigureResource(r => r.AddService("DatabaseDeletor.Api"))
        .WithTracing(tracing => tracing
            .AddAspNetCoreInstrumentation()
            .AddHttpClientInstrumentation()
            .AddOtlpExporter())
        .WithMetrics(metrics => metrics
            .AddAspNetCoreInstrumentation()
            .AddHttpClientInstrumentation()
            .AddOtlpExporter());
}

// --- Swagger ---
if (toggles.SwaggerEnabled)
{
    builder.Services.AddEndpointsApiExplorer();
    builder.Services.AddSwaggerGen(c =>
    {
        c.SwaggerDoc("v1", new() { Title = "DatabaseDeletor API", Version = "v1" });
    });
}

var app = builder.Build();

// --- Swagger Middleware ---
if (toggles.SwaggerEnabled)
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// --- Health Check ---
if (toggles.HealthCheckEnabled)
{
    app.MapGet("/health", () => Results.Ok(new { Status = "Healthy", Timestamp = DateTime.UtcNow }))
        .WithName("HealthCheck")
        .WithTags("Health");
}

app.Run();

namespace DatabaseDeletor.Api
{
#pragma warning disable CA1812, CA1852, CA1515 // Partial Program class required for WebApplicationFactory<Program> in integration tests
    public sealed partial class Program;
#pragma warning restore CA1812, CA1852, CA1515
}
