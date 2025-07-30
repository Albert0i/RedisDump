
#:package Flurl.Http@4.0.2

using Flurl.Http;
using System;
using System.Threading.Tasks;

public class Program
{
    public static async Task Main()
    {
        try
        {
            var response = await "https://jsonplaceholder.typicode.com/posts/1"
                .WithHeader("Accept", "application/json")
                .WithHeader("User-Agent", "dotnet-script")
                .GetAsync();

            var json = await response.GetStringAsync();
            Console.WriteLine(json);
        }
        catch (Flurl.Http.FlurlHttpException ex)
        {
            Console.WriteLine($"HTTP error: {ex.Message}");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Unhandled error: {ex.Message}");
        }
    }
}
