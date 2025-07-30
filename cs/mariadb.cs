#:package MySqlConnector@2.3.5

using MySqlConnector;
using System;
using System.Threading.Tasks;

public class Program
{
    public static async Task Main()
    {
        try
        {
            // 🔐 Connection details
            string server = "your.mariadb.host";      // e.g., "127.0.0.1"
            int port = 3306;                          // default MariaDB port
            string database = "your_database";
            string user = "your_username";
            string password = "your_password";

            // 🧩 Build connection string
            string connectionString = $"Server={server};Port={port};Database={database};User={user};Password={password};";

            // 🔌 Connect to MariaDB
            using var connection = new MySqlConnection(connectionString);
            await connection.OpenAsync();

            // 📄 SQL query
            string query = "SELECT id, textChi, visited FROM documents WHERE id = 100";

            using var command = new MySqlCommand(query, connection);
            using var reader = await command.ExecuteReaderAsync();

            // 🖨️ Print results
            if (!reader.HasRows)
            {
                Console.WriteLine("No matching records found.");
            }
            else
            {
                while (await reader.ReadAsync())
                {
                    int id = reader.GetInt32(0);
                    string textChi = reader.GetString(1);
                    bool visited = reader.GetBoolean(2);

                    Console.WriteLine($"ID: {id}");
                    Console.WriteLine($"TextChi: {textChi}");
                    Console.WriteLine($"Visited: {visited}");
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error: {ex.Message}");
        }
    }
}
