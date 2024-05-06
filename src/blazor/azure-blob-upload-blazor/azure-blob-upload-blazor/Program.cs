using Azure.Identity;
using Azure.Storage.Blobs;
using azure_blob_upload_blazor.Components;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents().AddCircuitOptions(options => { options.DetailedErrors = true; })
    .AddInteractiveWebAssemblyComponents();

builder.Services.AddSingleton(x =>
{
    string storageUrl = builder.Configuration["AZURE_STORAGE_ENDPOINT"];

    return new BlobServiceClient(new Uri(storageUrl), new ChainedTokenCredential(
        new AzureCliCredential(),
        new AzureDeveloperCliCredential(),
        new ManagedIdentityCredential()
    ));
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseWebAssemblyDebugging();
}
else
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();

app.UseStaticFiles();
app.UseAntiforgery();

app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode()
    .AddInteractiveWebAssemblyRenderMode()
    .AddAdditionalAssemblies(typeof(azure_blob_upload_blazor.Client._Imports).Assembly);

app.Run();
