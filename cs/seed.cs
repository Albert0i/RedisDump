
#:package Dapper@2.1.66
#:package Npgsql@9.0.3

using Dapper;
using Npgsql;

const string connectionString = "Host=localhost;Port=5432;Username=postgres;Password=postgres";

using var connection = new NpgsqlConnection(connectionString);
await connection.OpenAsync();

using var transaction = connection.BeginTransaction();

Console.WriteLine("Creating tables...");

await connection.ExecuteAsync(@"
    CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        name TEXT NOT NULL
    );
");

Console.WriteLine("Inserting users...");

for (int i = 1; i <= 10_000; i++)
{
    await connection.ExecuteAsync(
        "INSERT INTO users (name) VALUES (@Name);",
        new { Name = $"User {i}" });

    if (i % 1000 == 0)
    {
        Console.WriteLine($"Inserted {i} users...");
    }
}

transaction.Commit();

Console.WriteLine("Done!");
