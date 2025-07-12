using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using HelloGraphFunction.Services;

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureServices(services =>
    {
        // Add Application Insights for monitoring
        services.AddApplicationInsightsTelemetryWorkerService();
        services.ConfigureFunctionsApplicationInsights();
        
        // Add HTTP client for external API calls
        services.AddHttpClient();
        
        // Register Graph service with dependency injection
        services.AddScoped<IGraphService, GraphService>();
        
        // Add logging
        services.AddLogging(builder =>
        {
            builder.AddConsole();
            builder.AddApplicationInsights();
        });
    })
    .Build();

host.Run();
