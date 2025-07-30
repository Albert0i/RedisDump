#:package StackExchange.Redis@2.6.66

using StackExchange.Redis;
using System;
using System.Threading.Tasks;

public class Program
{
    public static async Task Main()
    {
        try
        {
            // 🔐 Connection details
            string host = "your.redis.host";      // e.g., "127.0.0.1"
            int port = 6379;                      // default Redis port
            string password = "yourPassword";     // replace with your actual password

            // 🧩 Build connection string
            string connectionString = $"{host}:{port},password={password}";

            // 🔌 Connect to Redis
            var redis = await ConnectionMultiplexer.ConnectAsync(connectionString);
            var db = redis.GetDatabase();

            // 🗂️ Define the hash key
            string hashKey = "myhash";

            // 📥 Get all fields and values
            HashEntry[] entries = await db.HashGetAllAsync(hashKey);

            // 🖨️ Print each field-value pair
            if (entries.Length == 0)
            {
                Console.WriteLine($"Hash key '{hashKey}' not found or empty.");
            }
            else
            {
                Console.WriteLine($"Contents of hash '{hashKey}':");
                foreach (var entry in entries)
                {
                    Console.WriteLine($"  {entry.Name}: {entry.Value}");
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error: {ex.Message}");
        }
    }
}
