using Microsoft.Extensions.Options;

namespace DatabaseDeletor.Api.Configuration;

#pragma warning disable CA1812 // Internal class instantiated via HttpClientFactory when configured
internal sealed class NoExternalCommunicationHandler : DelegatingHandler
#pragma warning restore CA1812
{
    private readonly IOptionsMonitor<FeatureToggles> _toggles;

    public NoExternalCommunicationHandler(IOptionsMonitor<FeatureToggles> toggles)
    {
        _toggles = toggles;
    }

    protected override Task<HttpResponseMessage> SendAsync(
        HttpRequestMessage request,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(request);

        if (_toggles.CurrentValue.NoExternalCommunication)
        {
            throw new InvalidOperationException(
                $"Outbound HTTP is disabled (NoExternalCommunication=true). Blocked request to {request.RequestUri}");
        }

        return base.SendAsync(request, cancellationToken);
    }
}
